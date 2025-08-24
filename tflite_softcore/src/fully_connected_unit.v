module fully_connected_unit (
    input clk,
    input rst_n,
    input start,
    input [31:0] input_ptr,
    input [31:0] weights_ptr,
    input [31:0] bias_ptr,
    input [31:0] output_ptr,
    input [31:0] dims,  // [input_size, output_size]
    output reg [31:0] result,
    output reg done,
    output reg ready
);

    // Variáveis para loops
    integer loop_k, loop_idx;
    localparam IDLE = 2'b00;
    localparam LOAD_INPUT = 2'b01;
    localparam LOAD_WEIGHTS = 2'b10;
    localparam LOAD_BIAS = 2'b11;
    localparam COMPUTE = 2'b00; // Reutilizando IDLE
    localparam DONE_STATE = 2'b01; // Reutilizando LOAD_INPUT
    
    reg [1:0] state, next_state;
    
    // Contadores
    reg [31:0] i, j;
    reg [31:0] input_size, output_size;
    
    // Buffers
    reg [31:0] input_buffer [0:255];    // Buffer para entrada
    reg [31:0] weights_buffer [0:1023]; // Buffer para pesos (256x4)
    reg [31:0] bias_buffer [0:255];     // Buffer para bias
    reg [31:0] output_buffer [0:255];   // Buffer para saída
    
    // Acumulador para MAC
    reg [31:0] accumulator;
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
            i <= 0;
            j <= 0;
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
                next_state = LOAD_WEIGHTS;
            end
            LOAD_WEIGHTS: begin
                next_state = LOAD_BIAS;
            end
            LOAD_BIAS: begin
                next_state = COMPUTE;
            end
            COMPUTE: begin
                if (i >= output_size)
                    next_state = DONE_STATE;
                else
                    next_state = COMPUTE;
            end
            DONE_STATE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Lógica de controle
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset dos contadores
            i <= 0;
            j <= 0;
            input_size <= 0;
            output_size <= 0;
            accumulator <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // Parse das dimensões
                    input_size <= dims[31:16];
                    output_size <= dims[15:0];
                end
                
                LOAD_INPUT: begin
                    // Simulação de carga de dados de entrada
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        input_buffer[loop_k] <= 32'h00000001; // Valor de exemplo
                    end
                end
                
                LOAD_WEIGHTS: begin
                    // Simulação de carga de pesos
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        weights_buffer[loop_k] <= 32'h00000001; // Valor de exemplo
                    end
                end
                
                LOAD_BIAS: begin
                    // Simulação de carga de bias
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        bias_buffer[loop_k] <= 32'h00000001; // Valor de exemplo
                    end
                end
                
                COMPUTE: begin
                    // Cálculo da multiplicação matriz-vetor
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        for (loop_idx = 0; loop_idx < 256; loop_idx = loop_idx + 1) begin
                            accumulator[loop_k] <= accumulator[loop_k] + 
                                input_buffer[loop_idx] * weights_buffer[loop_k * 256 + loop_idx];
                        end
                        output_buffer[loop_k] <= accumulator[loop_k] + bias_buffer[loop_k];
                    end
                end
                
                DONE_STATE: begin
                    // Armazenar resultado (exemplo: primeiro elemento)
                    result <= output_buffer[0];
                end
                
                default: begin
                    // Manter valores
                end
            endcase
        end
    end

endmodule