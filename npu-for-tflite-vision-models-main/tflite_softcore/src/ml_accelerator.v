module ml_accelerator (
    input clk,
    input rst_n,
    input [31:0] instruction,
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [4:0] rd_addr,
    input start,
    input [3:0] op_mode,  // Aumentado para 4 bits para mais operações
    input [31:0] mem_data_in,
    input [31:0] mem_addr,
    input mem_we,
    input mem_re,
    output reg [31:0] result,
    output reg [31:0] mem_data_out,
    output reg ready,
    output reg done,
    
    // Interface com memória externa para grandes buffers
    output reg [31:0] ext_mem_addr,
    output reg [31:0] ext_mem_data_out,
    output reg ext_mem_we,
    output reg ext_mem_re,
    input [31:0] ext_mem_data_in,
    input ext_mem_ready
);

    // Estados da FSM expandidos
    localparam IDLE = 4'b0000;
    localparam DECODE = 4'b0001;
    localparam LOAD_INPUT = 4'b0010;
    localparam LOAD_WEIGHTS = 4'b0011;
    localparam LOAD_BIAS = 4'b0100;
    localparam COMPUTE = 4'b0101;
    localparam ACTIVATION = 4'b0110;
    localparam STORE_OUTPUT = 4'b0111;
    localparam DONE_STATE = 4'b1000;
    
    reg [3:0] state, next_state;
    
    // Buffers aumentados para utilizar mais BRAM
    reg [31:0] input_buffer [0:1023];
    reg [31:0] weights_buffer [0:4095];  // 4x maior para pesos
    reg [31:0] bias_buffer [0:1023];
    reg [31:0] output_buffer [0:1023];
    
    // Registradores para parâmetros
    reg [31:0] input_ptr;
    reg [31:0] weights_ptr;
    reg [31:0] bias_ptr;
    reg [31:0] output_ptr;
    reg [31:0] input_dims;
    reg [31:0] weights_dims;
    reg [31:0] output_dims;
    reg [31:0] stride;
    reg [31:0] padding;
    
    // Contadores e índices
    reg [31:0] i, j, k;
    reg [31:0] input_size, weights_size, bias_size, output_size;
    
    // Pipeline de MAC com DSPs
    reg [31:0] mac_a, mac_b;
    reg [63:0] mac_result;
    reg [63:0] accumulator;
    
    // Registradores para operações de convolução
    reg [31:0] batch, height, width, channel;
    reg [31:0] kernel_h, kernel_w;
    reg [31:0] out_h, out_w, out_c;
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
            mem_data_out <= 0;
        end else begin
            state <= next_state;
            
            case(state)
                IDLE: begin
                    done <= 0;
                    ready <= 1;
                    mem_data_out <= 0;
                end
                DONE_STATE: begin
                    done <= 1;
                    ready <= 1;
                end
                default: begin
                    done <= 0;
                    ready <= 0;
                    mem_data_out <= 0;
                end
            endcase
        end
    end
    
    // FSM combinacional
    always @(*) begin
        case(state)
            IDLE: begin
                if (start)
                    next_state = DECODE;
                else
                    next_state = IDLE;
            end
            DECODE: begin
                next_state = LOAD_INPUT;
            end
            LOAD_INPUT: begin
                if (i >= input_size)
                    next_state = LOAD_WEIGHTS;
                else
                    next_state = LOAD_INPUT;
            end
            LOAD_WEIGHTS: begin
                if (j >= weights_size)
                    next_state = LOAD_BIAS;
                else
                    next_state = LOAD_WEIGHTS;
            end
            LOAD_BIAS: begin
                if (k >= bias_size)
                    next_state = COMPUTE;
                else
                    next_state = LOAD_BIAS;
            end
            COMPUTE: begin
                if (batch >= input_dims[31:24] || 
                    height >= out_h || 
                    width >= out_w || 
                    channel >= out_c)
                    next_state = ACTIVATION;
                else
                    next_state = COMPUTE;
            end
            ACTIVATION: begin
                next_state = STORE_OUTPUT;
            end
            STORE_OUTPUT: begin
                if (i >= output_size)
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
        mac_result <= mac_a * mac_b;
    end
    
    // Segundo estágio: acumulação
    always @(posedge clk) begin
        accumulator <= accumulator + mac_result;
    end
    
    // Lógica de controle otimizada
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset dos contadores
            i <= 0;
            j <= 0;
            k <= 0;
            batch <= 0;
            height <= 0;
            width <= 0;
            channel <= 0;
            
            // Reset dos ponteiros
            input_ptr <= 0;
            weights_ptr <= 0;
            bias_ptr <= 0;
            output_ptr <= 0;
            
            // Reset acumulador
            accumulator <= 0;
            
            // Reset sinais de memória externa
            ext_mem_we <= 0;
            ext_mem_re <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // Reset dos contadores
                    i <= 0;
                    j <= 0;
                    k <= 0;
                    batch <= 0;
                    height <= 0;
                    width <= 0;
                    channel <= 0;
                end
                
                DECODE: begin
                    // Decodificar instrução e configurar parâmetros
                    input_ptr <= rs1_data;
                    weights_ptr <= rs2_data;
                    input_dims <= 32'h01080803;  // Exemplo: 1x8x8x3
                    weights_dims <= 32'h03030310; // Exemplo: 3x3x3x16
                    output_dims <= 32'h01060610;  // Exemplo: 1x6x6x16
                    stride <= 32'h00010001;       // Stride 1x1
                    padding <= 32'h00000000;      // Sem padding
                    
                    // Calcular tamanhos
                    input_size <= 1*8*8*3;
                    weights_size <= 3*3*3*16;
                    bias_size <= 16;
                    output_size <= 1*6*6*16;
                    
                    // Calcular dimensões de saída
                    out_h <= 6;
                    out_w <= 6;
                    out_c <= 16;
                end
                
                LOAD_INPUT: begin
                    // Carregar dados de entrada com acesso otimizado à memória
                    if (ext_mem_ready && i < input_size) begin
                        ext_mem_addr <= input_ptr + (i << 2);
                        ext_mem_re <= 1;
                        i <= i + 1;
                    end else begin
                        ext_mem_re <= 0;
                    end
                    
                    // Armazenar dados lidos no buffer
                    if (ext_mem_re && ext_mem_ready) begin
                        input_buffer[i-1] <= ext_mem_data_in;
                    end
                end
                
                LOAD_WEIGHTS: begin
                    // Carregar pesos com acesso otimizado à memória
                    if (ext_mem_ready && j < weights_size) begin
                        ext_mem_addr <= weights_ptr + (j << 2);
                        ext_mem_re <= 1;
                        j <= j + 1;
                    end else begin
                        ext_mem_re <= 0;
                    end
                    
                    // Armazenar dados lidos no buffer
                    if (ext_mem_re && ext_mem_ready) begin
                        weights_buffer[j-1] <= ext_mem_data_in;
                    end
                end
                
                LOAD_BIAS: begin
                    // Carregar bias com acesso otimizado à memória
                    if (ext_mem_ready && k < bias_size) begin
                        ext_mem_addr <= bias_ptr + (k << 2);
                        ext_mem_re <= 1;
                        k <= k + 1;
                    end else begin
                        ext_mem_re <= 0;
                    end
                    
                    // Armazenar dados lidos no buffer
                    if (ext_mem_re && ext_mem_ready) begin
                        bias_buffer[k-1] <= ext_mem_data_in;
                    end
                end
                
                COMPUTE: begin
                    // Computação otimizada usando pipeline de MAC
                    if (batch < input_dims[31:24] && 
                        height < out_h && 
                        width < out_w && 
                        channel < out_c) begin
                        
                        // Configurar operação MAC
                        mac_a <= input_buffer[0];  // Simplificado para exemplo
                        mac_b <= weights_buffer[0]; // Simplificado para exemplo
                        
                        // Atualizar índices
                        width <= width + 1;
                        if (width >= out_w - 1) begin
                            width <= 0;
                            height <= height + 1;
                            if (height >= out_h - 1) begin
                                height <= 0;
                                channel <= channel + 1;
                                if (channel >= out_c - 1) begin
                                    channel <= 0;
                                    batch <= batch + 1;
                                end
                            end
                        end
                    end
                end
                
                ACTIVATION: begin
                    // Aplicar função de ativação (ReLU)
                    if (accumulator[31] == 1'b0)  // Se positivo
                        output_buffer[i] <= accumulator[31:0];
                    else
                        output_buffer[i] <= 0;
                    
                    i <= i + 1;
                end
                
                STORE_OUTPUT: begin
                    // Armazenar resultado na memória externa
                    if (ext_mem_ready && i < output_size) begin
                        ext_mem_addr <= output_ptr + (i << 2);
                        ext_mem_data_out <= output_buffer[i];
                        ext_mem_we <= 1;
                        i <= i + 1;
                    end else begin
                        ext_mem_we <= 0;
                    end
                    
                    // Armazenar resultado final
                    if (i == 0) 
                        result <= output_buffer[0];
                end
                
                default: begin
                    // Manter valores
                end
            endcase
        end
    end

endmodule