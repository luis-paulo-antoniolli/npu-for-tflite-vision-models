module softmax_unit (
    input clk,
    input rst_n,
    input start,
    input [31:0] input_ptr,
    input [31:0] output_ptr,
    input [31:0] size,
    output reg [31:0] result,
    output reg done,
    output reg ready
);

    // Variáveis para loops
    integer loop_k;
    localparam IDLE = 3'b000;
    localparam LOAD_INPUT = 3'b001;
    localparam FIND_MAX = 3'b010;
    localparam COMPUTE_EXP = 3'b011;
    localparam COMPUTE_SUM = 3'b100;
    localparam COMPUTE_SOFTMAX = 3'b101;
    localparam STORE_OUTPUT = 3'b110;
    localparam DONE_STATE = 3'b111;
    
    reg [2:0] state, next_state;
    
    // Contadores
    reg [31:0] i;
    
    // Buffers
    reg [31:0] input_buffer [0:255];   // Buffer para entrada
    reg [31:0] output_buffer [0:255];  // Buffer para saída
    reg [31:0] exp_buffer [0:255];     // Buffer para valores exponenciais
    
    // Registradores para cálculos
    reg [31:0] max_val;
    reg [31:0] sum_exp;
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
            i <= 0;
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
                next_state = FIND_MAX;
            end
            FIND_MAX: begin
                if (i >= size)
                    next_state = COMPUTE_EXP;
                else
                    next_state = FIND_MAX;
            end
            COMPUTE_EXP: begin
                if (i >= size)
                    next_state = COMPUTE_SUM;
                else
                    next_state = COMPUTE_EXP;
            end
            COMPUTE_SUM: begin
                if (i >= size)
                    next_state = COMPUTE_SOFTMAX;
                else
                    next_state = COMPUTE_SUM;
            end
            COMPUTE_SOFTMAX: begin
                if (i >= size)
                    next_state = STORE_OUTPUT;
                else
                    next_state = COMPUTE_SOFTMAX;
            end
            STORE_OUTPUT: begin
                next_state = DONE_STATE;
            end
            DONE_STATE: begin
                next_state = IDLE;
            end
            // Removido bloco default que nunca é usado
            /*
            default: next_state = IDLE;
            */
        endcase
    end
    
    // Lógica de controle
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset dos contadores
            i <= 0;
            max_val <= 0;
            sum_exp <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // Reset dos contadores
                    i <= 0;
                end
                
                LOAD_INPUT: begin
                    // Simulação de carga de dados de entrada
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        input_buffer[loop_k] <= 32'h00000001; // Valor de exemplo
                    end
                end
                
                FIND_MAX: begin
                    // Encontrar o valor máximo no array
                    max_val <= input_buffer[0];
                    for (loop_k = 1; loop_k < 256; loop_k = loop_k + 1) begin
                        if (input_buffer[loop_k] > max_val)
                            max_val <= input_buffer[loop_k];
                    end
                end
                
                COMPUTE_EXP: begin
                    // Calcular exp(x - max) para estabilidade numérica
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        exp_buffer[loop_k] <= input_buffer[loop_k] - max_val; // Simplificação para exemplo
                    end
                end
                
                COMPUTE_SUM: begin
                    // Calcular a soma das exponenciais
                    sum_exp <= 0;
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        sum_exp <= sum_exp + exp_buffer[loop_k];
                    end
                end
                
                COMPUTE_SOFTMAX: begin
                    // Calcular softmax: exp(x) / sum(exp(x))
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        output_buffer[loop_k] <= exp_buffer[loop_k]; // Simplificação para exemplo
                    end
                end
                
                STORE_OUTPUT: begin
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