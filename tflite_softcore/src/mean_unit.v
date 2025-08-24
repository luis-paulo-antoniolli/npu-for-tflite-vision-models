module mean_unit (
    input clk,
    input rst_n,
    input start,
    input [31:0] input_ptr,
    input [31:0] params,       // [dims, axes]
    output reg [31:0] result,
    output reg done,
    output reg ready
);

    // Variáveis para loops
    integer loop_j;
    localparam IDLE        = 2'b00;
    localparam LOAD_DATA   = 2'b01;
    localparam COMPUTE     = 2'b10;
    localparam DONE_STATE  = 2'b11;
    
    reg [1:0] state, next_state;
    
    // Contadores
    reg [31:0] i;
    reg [31:0] data_size;
    
    // Buffers
    reg [31:0] data_buffer [0:255];  // Buffer para dados de entrada
    
    // Acumulador para cálculo da média
    reg [31:0] accumulator;
    reg [31:0] count;
    
    // Registradores para parâmetros
    reg [31:0] dims;
    reg [31:0] axes;
    
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
                    next_state = LOAD_DATA;
                else
                    next_state = IDLE;
            end
            LOAD_DATA: begin
                next_state = COMPUTE;
            end
            COMPUTE: begin
                if (i >= data_size)
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
            data_size <= 0;
            accumulator <= 0;
            count <= 0;
            dims <= 0;
            axes <= 0;
            result <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // Parse dos parâmetros
                    dims <= params[31:16];
                    axes <= params[15:0];
                    data_size <= 32'd256; // Exemplo de tamanho
                    accumulator <= 0;
                    count <= 0;
                end
                
                LOAD_DATA: begin
                    // Simulação de carga de dados de entrada
                    for (loop_j = 0; loop_j < 256; loop_j = loop_j + 1) begin
                        data_buffer[loop_j] <= 32'h00000001; // Valor de exemplo
                    end
                    count <= 32'd256;
                end
                
                COMPUTE: begin
                    // Cálculo da média
                    accumulator <= 0;
                    for (loop_j = 0; loop_j < 256; loop_j = loop_j + 1) begin
                        accumulator <= accumulator + data_buffer[loop_j];
                    end
                end
                
                DONE_STATE: begin
                    // Calcular média final
                    if (count > 0)
                        result <= accumulator / count;
                    else
                        result <= 32'h00000000;
                end
                
                default: begin
                    // Mantém valores
                end
            endcase
        end
    end

endmodule
