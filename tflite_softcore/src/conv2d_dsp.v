module conv2d_dsp (
    input clk,
    input rst_n,
    
    // Interface de controle
    input start,
    output reg done,
    output reg ready,
    
    // Interface de memória
    input [31:0] input_addr,
    input [31:0] weights_addr,
    input [31:0] output_addr,
    input [31:0] bias_addr,
    
    // Interface com controlador de memória
    output reg [31:0] mem_addr,
    output reg [31:0] mem_data_out,
    output reg mem_we,
    output reg mem_re,
    input [31:0] mem_data_in,
    input mem_ready,
    
    // Parâmetros da convolução
    input [15:0] input_height,
    input [15:0] input_width,
    input [15:0] output_height,
    input [15:0] output_width,
    input [15:0] stride_h,
    input [15:0] stride_w,
    input [15:0] pad_h,
    input [15:0] pad_w,
    
    // Resultado
    output reg [31:0] result
);

    // Estados da FSM
    localparam IDLE          = 4'b0000;
    localparam LOAD_INPUT    = 4'b0001;
    localparam LOAD_WEIGHTS  = 4'b0010;
    localparam LOAD_BIAS     = 4'b0011;
    localparam COMPUTE_INIT  = 4'b0100;
    localparam COMPUTE_LOOP  = 4'b0101;
    localparam ACCUMULATE    = 4'b0110;
    localparam ACTIVATION    = 4'b0111;
    localparam STORE_OUTPUT  = 4'b1000;
    localparam DONE_STATE    = 4'b1001;
    
    reg [3:0] state, next_state;
    
    // Buffers (utilizando BRAM)
    reg [31:0] addr_buffer [0:7];
    reg [31:0] data_buffer [0:7];

    // Buffers de dados
    // Tamanhos genéricos, devem ser ajustados ao seu design
    (* ram_style = "block" *) reg [31:0] input_buffer   [0:65535];  
    (* ram_style = "block" *) reg [31:0] weights_buffer [0:4095];   
    (* ram_style = "block" *) reg [31:0] bias_buffer    [0:255];    
    (* ram_style = "block" *) reg [31:0] output_buffer  [0:65535];  

    // Registradores para índices
    reg [15:0] out_y, out_x, out_c;
    reg [15:0] ker_y, ker_x, in_c;
    reg [15:0] acc_idx;
    
    // Pipeline de MAC com DSP
    reg [31:0] mac_a, mac_b;
    wire [63:0] mac_result;
    reg [63:0] accumulator;
    reg [63:0] bias_value;
    
    // Registradores para cálculos
    reg [15:0] in_y, in_x;
    reg [15:0] input_idx, weights_idx, output_idx;
    reg [15:0] total_iterations;
    reg [15:0] current_iteration;
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
        end else begin
            state <= next_state;
            
            case(state)
                IDLE: begin
                    done <= 0;
                    ready <= 1;
                end
                DONE_STATE: begin
                    done <= 1;
                    ready <= 1;
                end
                default: begin
                    done <= 0;
                    ready <= 0;
                end
            endcase
        end
    end
    
    // FSM combinacional
    always @(*) begin
        case(state)
            IDLE: begin
                if (start)
                    next_state = LOAD_INPUT;
                else
                    next_state = IDLE;
            end
            LOAD_INPUT: begin
                if (current_iteration >= input_height * input_width * 3)
                    next_state = LOAD_WEIGHTS;
                else
                    next_state = LOAD_INPUT;
            end
            LOAD_WEIGHTS: begin
                if (current_iteration >= 3 * 3 * 3 * 16)
                    next_state = LOAD_BIAS;
                else
                    next_state = LOAD_WEIGHTS;
            end
            LOAD_BIAS: begin
                if (current_iteration >= 16)
                    next_state = COMPUTE_INIT;
                else
                    next_state = LOAD_BIAS;
            end
            COMPUTE_INIT: begin
                next_state = COMPUTE_LOOP;
            end
            COMPUTE_LOOP: begin
                if (out_y >= output_height)
                    next_state = STORE_OUTPUT;
                else
                    next_state = COMPUTE_LOOP;
            end
            ACCUMULATE: begin
                next_state = ACTIVATION;
            end
            ACTIVATION: begin
                next_state = COMPUTE_LOOP;
            end
            STORE_OUTPUT: begin
                if (current_iteration >= output_height * output_width * 16)
                    next_state = DONE_STATE;
                else
                    next_state = STORE_OUTPUT;
            end
            DONE_STATE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Pipeline de MAC utilizando DSP primitivo
    assign mac_result = $signed(mac_a) * $signed(mac_b);
    
    always @(posedge clk) begin
        accumulator <= accumulator + mac_result;
    end
    
    // Lógica de controle otimizada
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset de índices
            out_y <= 0;
            out_x <= 0;
            out_c <= 0;
            ker_y <= 0;
            ker_x <= 0;
            in_c <= 0;
            acc_idx <= 0;
            
            // Reset de contadores
            current_iteration <= 0;
            
            // Reset acumulador
            accumulator <= 0;
            bias_value <= 0;
            
            // Reset sinais de memória
            mem_we <= 0;
            mem_re <= 0;
            mem_addr <= 0;
            mem_data_out <= 0;
        end else begin
            case(state)
                IDLE: begin
                    out_y <= 0;
                    out_x <= 0;
                    out_c <= 0;
                    ker_y <= 0;
                    ker_x <= 0;
                    in_c <= 0;
                    acc_idx <= 0;
                    current_iteration <= 0;
                    accumulator <= 0;
                end
                
                LOAD_INPUT: begin
                    if (mem_ready && current_iteration < input_height * input_width * 3) begin
                        mem_addr <= input_addr + (current_iteration << 2);
                        mem_re <= 1;
                        input_buffer[current_iteration] <= mem_data_in;
                        current_iteration <= current_iteration + 1;
                    end else begin
                        mem_re <= 0;
                    end
                end
                
                LOAD_WEIGHTS: begin
                    if (mem_ready && current_iteration < 3 * 3 * 3 * 16) begin
                        mem_addr <= weights_addr + (current_iteration << 2);
                        mem_re <= 1;
                        weights_buffer[current_iteration] <= mem_data_in;
                        current_iteration <= current_iteration + 1;
                    end else begin
                        mem_re <= 0;
                    end
                end
                
                LOAD_BIAS: begin
                    if (mem_ready && current_iteration < 16) begin
                        mem_addr <= bias_addr + (current_iteration << 2);
                        mem_re <= 1;
                        bias_buffer[current_iteration] <= mem_data_in;
                        current_iteration <= current_iteration + 1;
                    end else begin
                        mem_re <= 0;
                    end
                end
                
                COMPUTE_INIT: begin
                    out_y <= 0;
                    out_x <= 0;
                    out_c <= 0;
                    accumulator <= 0;
                end
                
                COMPUTE_LOOP: begin
                    if (out_y < output_height) begin
                        if (out_x < output_width) begin
                            if (out_c < 16) begin
                                in_y = out_y * stride_h + ker_y - pad_h;
                                in_x = out_x * stride_w + ker_x - pad_w;
                                
                                if (in_y < input_height && in_x < input_width && 
                                    in_y >= 0 && in_x >= 0 &&
                                    ker_y < 3 && ker_x < 3 &&
                                    in_c < 3) begin
                                    
                                    input_idx = (in_y * input_width + in_x) * 3 + in_c;
                                    weights_idx = ((out_c * 3 + ker_y) * 3 + ker_x) * 3 + in_c;
                                    
                                    mac_a <= input_buffer[input_idx];
                                    mac_b <= weights_buffer[weights_idx];
                                    
                                    ker_x <= ker_x + 1;
                                end else begin
                                    ker_x <= 0;
                                    ker_y <= ker_y + 1;
                                end
                                
                                if (ker_y >= 3) begin
                                    ker_y <= 0;
                                    in_c <= in_c + 1;
                                end
                                
                                if (in_c >= 3) begin
                                    in_c <= 0;
                                    out_c <= out_c + 1;
                                    bias_value <= {{16{bias_buffer[out_c][31]}}, bias_buffer[out_c]};
                                end
                            end else begin
                                out_c <= 0;
                                out_x <= out_x + 1;
                            end
                        end else begin
                            out_x <= 0;
                            out_y <= out_y + 1;
                        end
                    end
                end
                
                ACCUMULATE: begin
                    accumulator <= accumulator + bias_value;
                end
                
                ACTIVATION: begin
                    if (accumulator[47])  
                        output_buffer[acc_idx] <= 0;
                    else
                        output_buffer[acc_idx] <= accumulator[31:0];
                    
                    acc_idx <= acc_idx + 1;
                end
                
                STORE_OUTPUT: begin
                    if (mem_ready && current_iteration < output_height * output_width * 16) begin
                        mem_addr <= output_addr + (current_iteration << 2);
                        mem_data_out <= output_buffer[current_iteration];
                        mem_we <= 1;
                        current_iteration <= current_iteration + 1;
                    end else begin
                        mem_we <= 0;
                    end
                    
                    if (current_iteration == 0) 
                        result <= output_buffer[0];
                end
                
                DONE_STATE: begin
                    current_iteration <= 0;
                end
            endcase
        end
    end

endmodule
