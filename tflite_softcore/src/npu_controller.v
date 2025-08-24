module npu_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input clk,
    input rst_n,
    
    // Interface com o softcore
    input [ADDR_WIDTH-1:0] bus_addr,
    input [DATA_WIDTH-1:0] bus_data_in,
    input [2:0] bus_cmd,
    input bus_ready,
    output reg [DATA_WIDTH-1:0] bus_data_out,
    output reg bus_req,
    
    // Interface com memória externa
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_data_out,
    output reg mem_we,
    output reg mem_re,
    input [DATA_WIDTH-1:0] mem_data_in,
    input mem_mem_ready,
    
    // Interface com aceleradores
    output reg [DATA_WIDTH-1:0] accelerator_cmd,
    output reg accelerator_start,
    input accelerator_done,
    input [DATA_WIDTH-1:0] accelerator_result,
    
    // Sinais de controle
    output reg ready,
    output reg done
);

    // Estados da FSM
    localparam IDLE = 3'b000;
    localparam FETCH_CMD = 3'b001;
    localparam CONFIG_ACCELERATOR = 3'b010;
    localparam START_ACCELERATOR = 3'b011;
    localparam WAIT_ACCELERATOR = 3'b100;
    localparam STORE_RESULT = 3'b101;
    localparam DONE_STATE = 3'b110;
    
    reg [2:0] state, next_state;
    
    // Registradores de comando
    reg [DATA_WIDTH-1:0] cmd;
    reg [ADDR_WIDTH-1:0] input_addr;
    reg [ADDR_WIDTH-1:0] weights_addr;
    reg [ADDR_WIDTH-1:0] bias_addr;
    reg [ADDR_WIDTH-1:0] output_addr;
    reg [DATA_WIDTH-1:0] input_size;
    reg [DATA_WIDTH-1:0] weights_size;
    reg [DATA_WIDTH-1:0] bias_size;
    reg [DATA_WIDTH-1:0] output_size;
    
    // Contadores
    reg [DATA_WIDTH-1:0] data_counter;
    
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
                if (bus_cmd == 3'b010 && bus_ready) // Command fetch
                    next_state = FETCH_CMD;
                else
                    next_state = IDLE;
            end
            FETCH_CMD: begin
                next_state = CONFIG_ACCELERATOR;
            end
            CONFIG_ACCELERATOR: begin
                next_state = START_ACCELERATOR;
            end
            START_ACCELERATOR: begin
                next_state = WAIT_ACCELERATOR;
            end
            WAIT_ACCELERATOR: begin
                if (accelerator_done)
                    next_state = STORE_RESULT;
                else
                    next_state = WAIT_ACCELERATOR;
            end
            STORE_RESULT: begin
                next_state = DONE_STATE;
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
            // Reset dos registradores
            cmd <= 0;
            input_addr <= 0;
            weights_addr <= 0;
            bias_addr <= 0;
            output_addr <= 0;
            input_size <= 0;
            weights_size <= 0;
            bias_size <= 0;
            output_size <= 0;
            data_counter <= 0;
            accelerator_start <= 0;
            bus_req <= 0;
            mem_addr <= 0;
            mem_data_out <= 0;
            mem_we <= 0;
            mem_re <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // Reset dos sinais de controle
                    accelerator_start <= 0;
                    bus_req <= 0;
                    mem_we <= 0;
                    mem_re <= 0;
                end
                
                FETCH_CMD: begin
                    // Ler comando da memória
                    if (bus_ready) begin
                        mem_addr <= bus_addr;
                        mem_re <= 1;
                        bus_req <= 1;
                    end
                    
                    // Processar dados lidos
                    if (mem_re && mem_mem_ready) begin
                        case(data_counter)
                            0: cmd <= mem_data_in;
                            1: input_addr <= mem_data_in;
                            2: weights_addr <= mem_data_in;
                            3: bias_addr <= mem_data_in;
                            4: output_addr <= mem_data_in;
                            5: input_size <= mem_data_in;
                            6: weights_size <= mem_data_in;
                            7: bias_size <= mem_data_in;
                            8: output_size <= mem_data_in;
                        endcase
                        data_counter <= data_counter + 1;
                    end
                end
                
                CONFIG_ACCELERATOR: begin
                    // Configurar acelerador
                    accelerator_cmd <= {cmd[7:0], input_addr[23:0]}; // Codificar comando e endereços
                    data_counter <= 0;
                end
                
                START_ACCELERATOR: begin
                    // Iniciar acelerador
                    accelerator_start <= 1;
                end
                
                WAIT_ACCELERATOR: begin
                    // Aguardar conclusão do acelerador
                    accelerator_start <= 0;
                end
                
                STORE_RESULT: begin
                    // Armazenar resultado na memória
                    if (mem_mem_ready && data_counter < output_size) begin
                        mem_addr <= output_addr + (data_counter << 2);
                        mem_data_out <= accelerator_result;
                        mem_we <= 1;
                        data_counter <= data_counter + 1;
                    end else begin
                        mem_we <= 0;
                    end
                    
                    // Retornar resultado para o softcore
                    if (data_counter == 0) 
                        bus_data_out <= accelerator_result;
                end
                
                DONE_STATE: begin
                    // Reset para próximo comando
                    data_counter <= 0;
                end
                
                default: begin
                    // Manter valores
                end
            endcase
        end
    end

endmodule