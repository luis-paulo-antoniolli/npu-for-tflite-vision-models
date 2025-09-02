module matadd_unit (
    input clk,
    input rst_n,
    input start,
    input [31:0] mat1_ptr,
    input [31:0] mat2_ptr,
    input [31:0] output_ptr,
    input [31:0] matrix_dims,  // [rows, cols]
    output reg [31:0] result,
    output reg done,
    output reg ready
);

    // Variáveis para loops
    integer loop_i, loop_idx;
    localparam IDLE = 3'b000;
    localparam LOAD_MAT1 = 3'b001;
    localparam LOAD_MAT2 = 3'b010;
    localparam COMPUTE = 3'b011;
    localparam DONE_STATE = 3'b100;
    
    reg [2:0] state, next_state;
    
    // Contadores
    reg [31:0] row, col;
    reg [31:0] rows, cols;
        // Acumuladores
    reg [63:0] accumulator;   // maior largura, para evitar overflow na soma
    reg [31:0] mean_result;   // média calculada

    // Buffers
    reg [31:0] mat1_buffer [0:255];  // Buffer para primeira matriz
    reg [31:0] mat2_buffer [0:255];  // Buffer para segunda matriz
    reg [31:0] output_buffer [0:255]; // Buffer para matriz de saída
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
            row <= 0;
            col <= 0;
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
            endcase
        end
    end
    
    // FSM combinacional
    always @(*) begin
        case(state)
            IDLE: begin
                if (start)
                    next_state = LOAD_MAT1;
                else
                    next_state = IDLE;
            end
            LOAD_MAT1: begin
                next_state = LOAD_MAT2;
            end
            LOAD_MAT2: begin
                next_state = COMPUTE;
            end
            COMPUTE: begin
                if (row >= rows || col >= cols)
                    next_state = DONE_STATE;
                else
                    next_state = COMPUTE;
            end
            DONE_STATE: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Lógica de controle
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset dos contadores
            row <= 0;
            col <= 0;
            rows <= 0;
            cols <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // Parse das dimensões
                    rows <= matrix_dims[31:16];
                    cols <= matrix_dims[15:0];
                end
                
                LOAD_MAT1: begin
                    // Simulação de carga da primeira matriz
                    for (loop_i = 0; loop_i < 256; loop_i = loop_i + 1) begin
                        mat1_buffer[loop_i] <= 32'h00000001; // Valor de exemplo
                    end
                end
                
                LOAD_MAT2: begin
                    // Simulação de carga da segunda matriz
                    for (loop_i = 0; loop_i < 256; loop_i = loop_i + 1) begin
                        mat2_buffer[loop_i] <= 32'h00000002; // Valor de exemplo
                    end
                end
                
                COMPUTE: begin
                    // Cálculo da soma elemento a elemento
                    for (loop_i = 0; loop_i < 256; loop_i = loop_i + 1) begin
                        output_buffer[loop_i] <= mat1_buffer[loop_i] + mat2_buffer[loop_i];
                    end
                    
                    // Cálculo da média
                    accumulator <= 0;
                    for (loop_idx = 0; loop_idx < 256; loop_idx = loop_idx + 1) begin
                        accumulator <= accumulator + output_buffer[loop_idx];
                    end
                    mean_result <= accumulator / 32'd256;
                end
                
                default: begin
                    // Manter valores
                end
            endcase
        end
    end
    
    // Registrador para resultado
    always @(posedge clk) begin
        if (state == DONE_STATE) begin
            result <= output_buffer[0]; // Exemplo: primeiro elemento
        end
    end

endmodule