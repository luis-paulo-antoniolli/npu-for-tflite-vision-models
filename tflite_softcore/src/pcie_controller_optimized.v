module pcie_controller (
    // Interface PCIe
    input pcie_clk,
    input pcie_rst_n,
    input [31:0] pcie_rx_data,
    input pcie_rx_valid,
    output reg [31:0] pcie_tx_data,
    output reg pcie_tx_valid,
    input pcie_tx_ready,
    
    // Interface com softcore
    output reg [31:0] core_cmd,
    output reg core_cmd_valid,
    input core_cmd_ready,
    input [31:0] core_result,
    input core_result_valid,
    
    // Interface de memória DDR4 (utilizando UltraRAM)
    output reg [31:0] ddr_addr,
    output reg [31:0] ddr_data_in,
    output reg ddr_we,
    output reg ddr_re,
    input [31:0] ddr_data_out,
    input ddr_ready,
    
    // Interface com aceleradores ML
    output reg [31:0] ml_cmd,
    output reg ml_cmd_valid,
    input ml_cmd_ready,
    input [31:0] ml_result,
    input ml_result_valid,
    
    // Sinais de controle
    output reg ready,
    output reg done,
    
    // Interrupções
    output reg interrupt
);

    // Estados da FSM expandida
    localparam IDLE = 4'b0000;
    localparam RECEIVE_HEADER = 4'b0001;
    localparam RECEIVE_DATA = 4'b0010;
    localparam PROCESS_CMD = 4'b0011;
    localparam MEM_ACCESS = 4'b0100;
    localparam EXECUTE_MODEL = 4'b0101;
    localparam ML_PROCESS = 4'b0110;
    localparam SEND_RESULT = 4'b0111;
    localparam DONE_STATE = 4'b1000;
    
    reg [3:0] state, next_state;
    
    // Registradores de comando
    reg [31:0] cmd;
    reg [31:0] addr;
    reg [31:0] length;
    reg [31:0] param1;
    reg [31:0] param2;
    
    // Buffer FIFO para dados PCIe (utilizando BRAM)
    reg [31:0] rx_fifo [0:511];  // FIFO de 512 words
    reg [8:0] rx_wr_ptr, rx_rd_ptr;
    wire rx_fifo_full, rx_fifo_empty;
    
    // Buffer FIFO para transmissão (utilizando BRAM)
    reg [31:0] tx_fifo [0:511];  // FIFO de 512 words
    reg [8:0] tx_wr_ptr, tx_rd_ptr;
    wire tx_fifo_full, tx_fifo_empty;
    
    // Contadores
    reg [31:0] data_counter;
    reg [31:0] transfer_size;
    
    // Registradores para DMA
    reg [31:0] dma_src_addr;
    reg [31:0] dma_dst_addr;
    reg [31:0] dma_length;
    reg dma_start;
    reg dma_busy;
    
    // FSM sequencial
    always @(posedge pcie_clk or negedge pcie_rst_n) begin
        if (!pcie_rst_n) begin
            state <= IDLE;
            ready <= 1;
            done <= 0;
            interrupt <= 0;
        end else begin
            state <= next_state;
            
            case(state)
                IDLE: begin
                    ready <= 1;
                    done <= 0;
                    interrupt <= 0;
                end
                DONE_STATE: begin
                    done <= 1;
                    interrupt <= 1;
                end
                default: begin
                    ready <= 0;
                    done <= 0;
                    interrupt <= 0;
                end
            endcase
        end
    end
    
    // FSM combinacional
    always @(*) begin
        case(state)
            IDLE: begin
                if (pcie_rx_valid)
                    next_state = RECEIVE_HEADER;
                else
                    next_state = IDLE;
            end
            RECEIVE_HEADER: begin
                next_state = PROCESS_CMD;
            end
            PROCESS_CMD: begin
                case(cmd[31:24])
                    8'h01: next_state = MEM_ACCESS;     // LOAD_MODEL
                    8'h02: next_state = MEM_ACCESS;     // LOAD_INPUT
                    8'h03: next_state = EXECUTE_MODEL;  // RUN_INFERENCE
                    8'h04: next_state = SEND_RESULT;    // GET_RESULT
                    8'h05: next_state = MEM_ACCESS;     // DMA_TRANSFER
                    8'h06: next_state = ML_PROCESS;     // ML_OPERATION
                    default: next_state = IDLE;
                endcase
            end
            MEM_ACCESS: begin
                if (data_counter >= length)
                    next_state = IDLE;
                else if (pcie_rx_valid && !rx_fifo_full)
                    next_state = MEM_ACCESS;
                else
                    next_state = MEM_ACCESS;
            end
            EXECUTE_MODEL: begin
                if (core_result_valid)
                    next_state = SEND_RESULT;
                else
                    next_state = EXECUTE_MODEL;
            end
            ML_PROCESS: begin
                if (ml_result_valid)
                    next_state = SEND_RESULT;
                else
                    next_state = ML_PROCESS;
            end
            SEND_RESULT: begin
                if (tx_fifo_empty)
                    next_state = DONE_STATE;
                else
                    next_state = SEND_RESULT;
            end
            DONE_STATE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Lógica de FIFO para recepção
    always @(posedge pcie_clk or negedge pcie_rst_n) begin
        if (!pcie_rst_n) begin
            rx_wr_ptr <= 0;
            rx_rd_ptr <= 0;
        end else begin
            // Escrita no FIFO
            if (pcie_rx_valid && !rx_fifo_full) begin
                rx_fifo[rx_wr_ptr] <= pcie_rx_data;
                rx_wr_ptr <= rx_wr_ptr + 1;
            end
            
            // Leitura do FIFO
            if (state == RECEIVE_HEADER && !rx_fifo_empty) begin
                rx_rd_ptr <= rx_rd_ptr + 1;
            end
        end
    end
    
    // Detecção de FIFO cheio/vazio
    assign rx_fifo_full  = ((rx_wr_ptr + 1) == rx_rd_ptr);
    assign rx_fifo_empty = (rx_wr_ptr == rx_rd_ptr);
    
    // Lógica de FIFO para transmissão
    always @(posedge pcie_clk or negedge pcie_rst_n) begin
        if (!pcie_rst_n) begin
            tx_wr_ptr <= 0;
            tx_rd_ptr <= 0;
            pcie_tx_valid <= 0;
        end else begin
            // Escrita no FIFO
            if (state == SEND_RESULT && !tx_fifo_full) begin
                tx_fifo[tx_wr_ptr] <= core_result;  // Simplificado
                tx_wr_ptr <= tx_wr_ptr + 1;
            end
            
            // Leitura do FIFO e transmissão
            if (pcie_tx_ready && !tx_fifo_empty) begin
                pcie_tx_data <= tx_fifo[tx_rd_ptr];
                pcie_tx_valid <= 1;
                tx_rd_ptr <= tx_rd_ptr + 1;
            end else begin
                pcie_tx_valid <= 0;
            end
        end
    end
    
    // Detecção de FIFO cheio/vazio para transmissão
    assign tx_fifo_full  = ((tx_wr_ptr + 1) == tx_rd_ptr);
    assign tx_fifo_empty = (tx_wr_ptr == tx_rd_ptr);
    
    // Lógica de controle otimizada
    always @(posedge pcie_clk or negedge pcie_rst_n) begin
        if (!pcie_rst_n) begin
            // Reset dos registradores
            cmd <= 0;
            addr <= 0;
            length <= 0;
            param1 <= 0;
            param2 <= 0;
            data_counter <= 0;
            transfer_size <= 0;
            dma_start <= 0;
            dma_busy <= 0;
        end else begin
            case(state)
                IDLE: begin
                    data_counter <= 0;
                    dma_start <= 0;
                end
                
                RECEIVE_HEADER: begin
                    if (!rx_fifo_empty) begin
                        case(data_counter)
                            0: cmd <= rx_fifo[rx_rd_ptr];
                            1: addr <= rx_fifo[rx_rd_ptr];
                            2: length <= rx_fifo[rx_rd_ptr];
                            3: param1 <= rx_fifo[rx_rd_ptr];
                        endcase
                        data_counter <= data_counter + 1;
                    end
                end
                
                PROCESS_CMD: begin
                    case(cmd[31:24])
                        8'h01, 8'h02: begin
                            transfer_size <= length;
                            data_counter <= 0;
                        end
                        8'h03: begin
                            core_cmd <= cmd;
                            core_cmd_valid <= 1;
                        end
                        8'h04: begin
                            // Preparar para enviar resultados
                        end
                        8'h05: begin
                            dma_src_addr <= addr;
                            dma_dst_addr <= param1;
                            dma_length <= length;
                            dma_start <= 1;
                        end
                        8'h06: begin
                            ml_cmd <= {cmd[23:0], param1[7:0]};
                            ml_cmd_valid <= 1;
                        end
                        default: begin
                            // Default case to prevent latch inference
                            transfer_size <= 0;
                            data_counter <= 0;
                        end
                    endcase
                end
                
                MEM_ACCESS: begin
                    if (ddr_ready && data_counter < transfer_size) begin
                        if (cmd[31:24] == 8'h01 || cmd[31:24] == 8'h02) begin
                            ddr_addr <= addr + (data_counter << 2);
                            ddr_data_in <= rx_fifo[rx_rd_ptr];
                            ddr_we <= 1;
                        end else begin
                            ddr_addr <= addr + (data_counter << 2);
                            ddr_re <= 1;
                        end
                        data_counter <= data_counter + 1;
                    end else begin
                        ddr_we <= 0;
                        ddr_re <= 0;
                    end
                end
                
                EXECUTE_MODEL: core_cmd_valid <= 0;
                ML_PROCESS: ml_cmd_valid <= 0;
                SEND_RESULT: ; // tx_fifo já é usado
                DONE_STATE: data_counter <= 0;
                default: ;
            endcase
        end
    end
    
    // Controlador DMA simples
    always @(posedge pcie_clk or negedge pcie_rst_n) begin
        if (!pcie_rst_n) begin
            dma_busy <= 0;
        end else begin
            if (dma_start) begin
                dma_busy <= 1;
                dma_start <= 0;
            end else if (data_counter >= dma_length) begin
                dma_busy <= 0;
            end
        end
    end

endmodule
