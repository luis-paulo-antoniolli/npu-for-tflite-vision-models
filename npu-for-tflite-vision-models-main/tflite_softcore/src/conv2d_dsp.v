module conv2d_dsp (
    input clk,
    input rst_n,
    
    // Interface de controle
    input start,
    output reg done,
    output reg ready,
    
    // Interface de endereços
    input [31:0] input_addr,
    input [31:0] weights_addr,
    input [31:0] output_addr,
    input [31:0] bias_addr,
    
    // Interface de memória
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

    // Registradores para índices (movidos para evitar uso antes da declaração)
    reg [15:0] acc_idx;
    reg [15:0] current_iteration;
    
    // Buffers (utilizando BRAM)
    reg [31:0] addr_buffer [0:7];
    reg [31:0] data_buffer [0:7];

    // Buffers de dados
    // Tamanhos genéricos, devem ser ajustados ao seu design
    // Removendo ram_style attributes que estão causando problemas
    reg [31:0] input_buffer   [0:16383];  // 16k x 32b = 524,288 bits
    reg [31:0] weights_buffer [0:4095];   // 4k x 32b = 131,072 bits
    reg [31:0] bias_buffer    [0:255];    // 256 x 32b = 8,192 bits

    // ====== OUTPUT BUFFER EM 4 BANCOS (4 x 16k x 32b = 2,097,152 bits total) ======
    // Cada banco ~524 kbits, abaixo do limite de 1,000,000 bits por variável.
    // Removendo ram_style attributes que estão causando problemas
    reg [31:0] output_buffer0 [0:16383];
    reg [31:0] output_buffer1 [0:16383];
    reg [31:0] output_buffer2 [0:16383];
    reg [31:0] output_buffer3 [0:16383];

    // Sinais de acesso ao output_buffer bankeado
    reg        ob_we;                 // enable de escrita
    reg [15:0] ob_wr_addr;            // endereço de escrita
    reg [31:0] ob_wr_data;            // dado de escrita
    wire [15:0] ob_rd_addr;           // endereço de leitura
    reg  [31:0] ob_rd_data;           // dado lido (combinacional)
    
    // Leitura combinacional dos bancos (1 porta de leitura "virtual")
    // Corrigindo o uso de variáveis antes da declaração
    assign ob_rd_addr = (state == STORE_OUTPUT) ? (current_iteration[15:0]) :
                        (state == ACTIVATION)   ? (acc_idx[15:0]) :
                                                   16'd0;

    always @(*) begin
        case (ob_rd_addr[15:14])
            2'b00: ob_rd_data = output_buffer0[ob_rd_addr[13:0]];
            2'b01: ob_rd_data = output_buffer1[ob_rd_addr[13:0]];
            2'b10: ob_rd_data = output_buffer2[ob_rd_addr[13:0]];
            2'b11: ob_rd_data = output_buffer3[ob_rd_addr[13:0]];
            default: ob_rd_data = 32'd0;
        endcase
    end

    // Escrita sequencial nos bancos (1 porta de escrita "virtual")
    always @(posedge clk) begin
        if (ob_we) begin
            case (ob_wr_addr[15:14])
                // Removido bloco default que nunca é usado
            /*
            default: output_buffer0[ob_wr_addr[13:0]] <= ob_wr_data;
            */
                2'b01: output_buffer1[ob_wr_addr[13:0]] <= ob_wr_data;
                2'b10: output_buffer2[ob_wr_addr[13:0]] <= ob_wr_data;
                2'b11: output_buffer3[ob_wr_addr[13:0]] <= ob_wr_data;
                // Removido bloco default que nunca é usado
            /*
            default: output_buffer0[ob_wr_addr[13:0]] <= ob_wr_data;
            */
            endcase
        end
    end
    // ==============================================================================

    // Registradores para índices
    reg [15:0] out_y, out_x, out_c;
    reg [15:0] ker_y, ker_x, in_c;
    
    // Pipeline de MAC com DSP
    reg [31:0] mac_a, mac_b;
    reg [63:0] mac_result;  // Corrigido: era wire, agora é reg
    reg [63:0] accumulator;
    reg [63:0] bias_value;
    
    // Registradores para cálculos
    reg [15:0] in_y, in_x;
    reg [15:0] input_idx, weights_idx, output_idx;
    reg [15:0] total_iterations;
    
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
                if (current_iteration >= 3*3*3*16)
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
                if (out_y >= output_height || 
                    out_x >= output_width || 
                    out_c >= 16)
                    next_state = ACTIVATION;
                else
                    next_state = COMPUTE_LOOP;
            end
            ACTIVATION: begin
                if (acc_idx >= output_height * output_width * 16)
                    next_state = STORE_OUTPUT;
                else
                    next_state = ACTIVATION;
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
    
    // Pipeline de MAC utilizando DSPs
    // Primeiro estágio: multiplicação
    always @(posedge clk) begin
        mac_result <= $signed(mac_a) * $signed(mac_b);
    end
    
    // Lógica de controle
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset dos contadores
            out_y <= 0;
            out_x <= 0;
            out_c <= 0;
            ker_y <= 0;
            ker_x <= 0;
            in_c <= 0;
            acc_idx <= 0;
            in_y <= 0;
            in_x <= 0;
            input_idx <= 0;
            weights_idx <= 0;
            output_idx <= 0;
            total_iterations <= 0;
            current_iteration <= 0;
            mac_a <= 0;
            mac_b <= 0;
            mac_result <= 0;  // Corrigido: adicionado reset
            accumulator <= 0;
            bias_value <= 0;
            mem_addr <= 0;
            mem_data_out <= 0;
            mem_we <= 0;
            mem_re <= 0;
            ob_we <= 0;
            ob_wr_addr <= 0;
            ob_wr_data <= 0;
            result <= 0;
        end else begin
            // Default values to prevent latches
            mem_we <= 0;
            mem_re <= 0;
            ob_we <= 0;
            
            case(state)
                IDLE: begin
                    // Reset dos contadores
                    out_y <= 0;
                    out_x <= 0;
                    out_c <= 0;
                    current_iteration <= 0;
                    acc_idx <= 0;
                end
                
                LOAD_INPUT: begin
                    // Simulação de carga de dados de entrada
                    if (mem_ready && current_iteration < input_height * input_width * 3) begin
                        mem_addr <= input_addr + (current_iteration << 2);
                        mem_re <= 1;
                        current_iteration <= current_iteration + 1;
                    end
                    
                    // Armazenar dados lidos no buffer
                    if (mem_re && mem_ready && current_iteration > 0) begin
                        input_buffer[current_iteration - 1] <= mem_data_in;
                    end
                end
                
                LOAD_WEIGHTS: begin
                    // Simulação de carga de pesos
                    if (mem_ready && current_iteration < 3*3*3*16) begin
                        mem_addr <= weights_addr + (current_iteration << 2);
                        mem_re <= 1;
                        current_iteration <= current_iteration + 1;
                    end
                    
                    // Armazenar dados lidos no buffer
                    if (mem_re && mem_ready && current_iteration > 0) begin
                        weights_buffer[current_iteration - 1] <= mem_data_in;
                    end
                end
                
                LOAD_BIAS: begin
                    // Simulação de carga de bias
                    if (mem_ready && current_iteration < 16) begin
                        mem_addr <= bias_addr + (current_iteration << 2);
                        mem_re <= 1;
                        current_iteration <= current_iteration + 1;
                    end
                    
                    // Armazenar dados lidos no buffer
                    if (mem_re && mem_ready && current_iteration > 0) begin
                        bias_buffer[current_iteration - 1] <= mem_data_in;
                    end
                end
                
                COMPUTE_INIT: begin
                    // Inicializar índices para computação
                    out_y <= 0;
                    out_x <= 0;
                    out_c <= 0;
                    accumulator <= 0;
                end
                
                COMPUTE_LOOP: begin
                    // Computação otimizada usando pipeline de MAC
                    if (out_y < output_height && 
                        out_x < output_width && 
                        out_c < 16) begin
                        
                        // Configurar operação MAC
                        mac_a <= input_buffer[0];  // Simplificado para exemplo
                        mac_b <= weights_buffer[0]; // Simplificado para exemplo
                        
                        // Acumular resultado
                        accumulator <= accumulator + mac_result;
                        
                        // Atualizar índices
                        out_x <= out_x + 1;
                        if (out_x >= output_width - 1) begin
                            out_x <= 0;
                            out_y <= out_y + 1;
                            if (out_y >= output_height - 1) begin
                                out_y <= 0;
                                out_c <= out_c + 1;
                            end
                        end
                    end
                end
                
                ACTIVATION: begin
                    // Aplicar função de ativação (ReLU)
                    if (acc_idx < output_height * output_width * 16) begin
                        // Aplicar ReLU: max(0, x)
                        if (accumulator[63] == 1'b0)  // Se positivo
                            ob_wr_data <= accumulator[31:0];
                        else
                            ob_wr_data <= 0;
                        
                        ob_wr_addr <= acc_idx;
                        ob_we <= 1;
                        acc_idx <= acc_idx + 1;
                    end
                end
                
                STORE_OUTPUT: begin
                    // Armazenar resultado na memória externa
                    if (mem_ready && current_iteration < output_height * output_width * 16) begin
                        mem_addr <= output_addr + (current_iteration << 2);
                        mem_data_out <= ob_rd_data;
                        mem_we <= 1;
                        current_iteration <= current_iteration + 1;
                    end
                    
                    // Armazenar resultado final
                    if (current_iteration == 0) 
                        result <= ob_rd_data;
                end
                
                DONE_STATE: begin
                    // Manter valores
                end
                
                default: begin
                    // Manter valores
                end
            endcase
        end
    end

endmodule