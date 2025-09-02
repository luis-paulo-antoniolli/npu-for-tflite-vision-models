module relu6_unit (
    input clk,
    input rst_n,
    input start,
    input [31:0] input_data,
    output reg [31:0] output_data,
    output reg done,
    output reg ready
);

    // Estados da FSM
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam DONE_STATE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // Constantes para ReLU6
    wire [31:0] zero = 32'h00000000;
    wire [31:0] six = 32'h00000006; // Valor de exemplo; em implementação real, seria 6.0 em ponto flutuante
    
    // Registradores para valores de entrada e saída
    reg [31:0] data_in;
    reg [31:0] data_out;
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
            output_data <= 0;
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
                    output_data <= data_out;
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
                    next_state = PROCESS;
                else
                    next_state = IDLE;
            end
            PROCESS: begin
                next_state = DONE_STATE;
            end
            DONE_STATE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Lógica de processamento
    always @(posedge clk) begin
        if (!rst_n) begin
            data_in <= 0;
            data_out <= 0;
        end else begin
            case(state)
                IDLE: begin
                    data_in <= input_data;
                end
                PROCESS: begin
                    // Implementação da função ReLU6: f(x) = min(max(0, x), 6)
                    if (data_in < zero)
                        data_out <= zero;
                    else if (data_in > six)
                        data_out <= six;
                    else
                        data_out <= data_in;
                end
                default: begin
                    // Manter valores
                end
            endcase
        end
    end

endmodule