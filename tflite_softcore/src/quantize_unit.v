module quantize_unit (
    input clk,
    input rst_n,
    input start,
    input [31:0] input_ptr,
    input [31:0] params,  // [scale, zero_point]
    input [31:0] size,
    output reg [31:0] result,
    output reg done,
    output reg ready
);

    // Variáveis para loops
    integer loop_k;
    localparam IDLE        = 2'b00;
    localparam LOAD_INPUT  = 2'b01;
    localparam QUANTIZE    = 2'b10;
    localparam DONE_STATE  = 2'b11;
    
    reg [1:0] state, next_state;
    
    // Contadores
    reg [31:0] i;
    
    // Buffers
    reg [31:0] input_buffer [0:255];   // Buffer para entrada (float)
    reg [7:0]  output_buffer [0:255];  // Buffer para saída (int8)
    
    // Parâmetros de quantização
    reg [31:0] scale;
    reg [31:0] zero_point;
    
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
                next_state = QUANTIZE;
            end
            QUANTIZE: begin
                if (i >= size)
                    next_state = DONE_STATE;
                else
                    next_state = QUANTIZE;
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
            scale <= 0;
            zero_point <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // Parse dos parâmetros
                    scale <= params[31:16];
                    zero_point <= params[15:0];
                    i <= 0;
                end
                
                LOAD_INPUT: begin
                    // Simulação de carga de dados de entrada
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        input_buffer[loop_k] <= 32'h00000001; // Valor de exemplo
                    end
                end
                
                QUANTIZE: begin
                    // Quantização: output = round(input / scale) + zero_point
                    for (loop_k = 0; loop_k < 256; loop_k = loop_k + 1) begin
                        // Simplificação: apenas converter para int8
                        output_buffer[loop_k] <= input_buffer[loop_k][7:0];
                    end
                    i <= i + 1;
                end
                
                DONE_STATE: begin
                    // Armazenar resultado (exemplo: primeiro elemento)
                    result <= {{24{1'b0}}, output_buffer[0]};
                end
                
                default: begin
                    // Manter valores
                end
            endcase
        end
    end

endmodule
