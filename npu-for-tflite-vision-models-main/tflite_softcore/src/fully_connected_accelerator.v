module fully_connected_accelerator #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MAX_INPUT_SIZE = 4096,
    parameter MAX_OUTPUT_SIZE = 1024
) (
    input clk,
    input rst_n,
    
    // Interface de controle
    input [DATA_WIDTH-1:0] cmd,
    input start,
    output reg done,
    output reg ready,
    
    // Interface de memória (corrigida)
    output reg [ADDR_WIDTH-1:0] mem_addr,   // acelerador gera endereço
    input  [DATA_WIDTH-1:0] mem_data_in,    // memória retorna dados
    output reg mem_we,                      // write enable (saída)
    output reg mem_re,                      // read enable (saída)
    output reg [DATA_WIDTH-1:0] mem_data_out, // dados para escrever
    input  mem_ready,                       // memória avisa que está pronta
    
    // Parâmetros da operação
    input [15:0] input_size,
    input [15:0] output_size,
    
    // Resultado
    output reg [DATA_WIDTH-1:0] result
);

    // Estados da FSM
    localparam IDLE         = 3'b000;
    localparam LOAD_INPUT   = 3'b001;
    localparam LOAD_WEIGHTS = 3'b010;
    localparam LOAD_BIAS    = 3'b011;
    localparam COMPUTE      = 3'b100;
    localparam STORE_OUTPUT = 3'b101;
    localparam DONE_STATE   = 3'b110;
    
    reg [2:0] state, next_state;
    
    // Buffers
    reg [7:0] input_buffer [0:4095];     // int8
    reg [7:0] weights_buffer [0:262143]; // int8 (256K)
    reg [31:0] bias_buffer [0:1023];     // int32
    reg [31:0] output_buffer [0:1023];   // int32
    
    // Índices
    reg [15:0] out_idx, in_idx;
    
    // Pipeline MAC
    reg [15:0] mac_a, mac_b;
    reg [31:0] mac_result;
    reg [47:0] accumulator;
    
    // Controle
    reg [15:0] weights_idx;
    reg [15:0] current_iteration;
    
    // Quantização
    // Comentando registradores não utilizados para evitar warnings
    // reg [31:0] input_scale;
    // reg [31:0] weights_scale;
    // reg [31:0] output_scale;
    // reg [7:0] input_zero_point;
    // reg [7:0] weights_zero_point;
    // reg [7:0] output_zero_point;
    
    // Forçar uso dos registradores para evitar remoção
    /*
    initial begin
        input_scale = 0;
        weights_scale = 0;
        output_scale = 0;
        input_zero_point = 0;
        weights_zero_point = 0;
        output_zero_point = 0;
    end
    */
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
            // Removido uso de variáveis não declaradas
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
                if (current_iteration >= input_size)
                    next_state = LOAD_WEIGHTS;
                else
                    next_state = LOAD_INPUT;
            end
            LOAD_WEIGHTS: begin
                if (current_iteration >= input_size * output_size)
                    next_state = LOAD_BIAS;
                else
                    next_state = LOAD_WEIGHTS;
            end
            LOAD_BIAS: begin
                if (current_iteration >= output_size)
                    next_state = COMPUTE;
                else
                    next_state = LOAD_BIAS;
            end
            COMPUTE: begin
                if (out_idx >= output_size)
                    next_state = STORE_OUTPUT;
                else
                    next_state = COMPUTE;
            end
            STORE_OUTPUT: begin
                if (current_iteration >= output_size)
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
    
    // MAC pipeline
    always @(posedge clk) begin
        mac_result <= $signed(mac_a) * $signed(mac_b);
    end
    
    always @(posedge clk) begin
        accumulator <= accumulator + {{16{mac_result[31]}}, mac_result};
    end
    
    // Controle principal
    always @(posedge clk) begin
        if (!rst_n) begin
            out_idx <= 0;
            in_idx <= 0;
            current_iteration <= 0;
            accumulator <= 0;
            mem_we <= 0;
            mem_re <= 0;
            mem_addr <= 0;
            mem_data_out <= 0;
            // Removido uso de variáveis não declaradas
        end else begin
            case(state)
                IDLE: begin
                    out_idx <= 0;
                    in_idx <= 0;
                    current_iteration <= 0;
                    accumulator <= 0;
                    mem_we <= 0;
                    mem_re <= 0;
                end
                
                LOAD_INPUT: begin
                    if (mem_ready && current_iteration < input_size) begin
                        mem_addr <= cmd[31:0] + (current_iteration << 2);
                        mem_re <= 1;
                        current_iteration <= current_iteration + 1;
                    end else begin
                        mem_re <= 0;
                    end
                    
                    if (mem_re && mem_ready) begin
                        if (current_iteration > 0 && current_iteration <= 4096) begin
                            input_buffer[current_iteration - 1] <= mem_data_in[7:0];
                        end
                    end
                end
                
                LOAD_WEIGHTS: begin
                    if (mem_ready && current_iteration < input_size * output_size) begin
                        mem_addr <= cmd[31:0] + (current_iteration << 2);
                        mem_re <= 1;
                        current_iteration <= current_iteration + 1;
                    end else begin
                        mem_re <= 0;
                    end
                    
                    if (mem_re && mem_ready) begin
                        if (current_iteration > 0 && current_iteration <= 262144) begin
                            weights_buffer[current_iteration - 1] <= mem_data_in[7:0];
                        end
                    end
                end
                
                LOAD_BIAS: begin
                    if (mem_ready && current_iteration < output_size) begin
                        mem_addr <= cmd[31:0] + (current_iteration << 2);
                        mem_re <= 1;
                        current_iteration <= current_iteration + 1;
                    end else begin
                        mem_re <= 0;
                    end
                    
                    if (mem_re && mem_ready) begin
                        if (current_iteration > 0 && current_iteration <= 1024) begin
                            bias_buffer[current_iteration - 1] <= mem_data_in;
                        end
                    end
                end
                
                COMPUTE: begin
                    if (out_idx < output_size) begin
                        if (in_idx < input_size) begin
                            weights_idx = out_idx * input_size + in_idx;
                            if (in_idx < 4096 && weights_idx < 262144) begin
                                mac_a <= {{8{input_buffer[in_idx][7]}}, input_buffer[in_idx]};
                                mac_b <= {{8{weights_buffer[weights_idx][7]}}, weights_buffer[weights_idx]};
                            end
                            in_idx <= in_idx + 1;
                        end else begin
                            if (out_idx < 1024) begin
                                accumulator <= accumulator + {{16{bias_buffer[out_idx][31]}}, bias_buffer[out_idx]};
                                output_buffer[out_idx] <= accumulator[31:0];
                            end
                            in_idx <= 0;
                            out_idx <= out_idx + 1;
                            accumulator <= 0;
                        end
                    end
                end
                
                STORE_OUTPUT: begin
                    if (mem_ready && current_iteration < output_size) begin
                        mem_addr <= cmd[31:0] + (current_iteration << 2);
                        if (current_iteration < 1024) begin
                            mem_data_out <= output_buffer[current_iteration];
                        end
                        mem_we <= 1;
                        current_iteration <= current_iteration + 1;
                    end else begin
                        mem_we <= 0;
                    end
                    
                    if (current_iteration == 0) begin
                        result <= output_buffer[0];
                    end
                end
                
                DONE_STATE: begin
                    current_iteration <= 0;
                end
                default: begin
                    // Handle undefined states - return to IDLE
                    current_iteration <= 0;
                end
            endcase
        end
    end

endmodule
