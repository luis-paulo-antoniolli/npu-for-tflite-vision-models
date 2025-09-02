module memory_controller_ultraram (
    input clk,
    input rst_n,
    
    // Interface com controlador PCIe
    input [31:0] pcie_addr,
    input [31:0] pcie_data_in,
    input pcie_we,
    input pcie_re,
    output wire [31:0] pcie_data_out,
    output reg pcie_ready,
    
    // Interface com softcore
    input [31:0] core_addr,
    input [31:0] core_data_in,
    input core_we,
    input core_re,
    output wire [31:0] core_data_out,
    output reg core_ready,
    
    // Interface com aceleradores ML
    input [31:0] ml_addr,
    input [31:0] ml_data_in,
    input ml_we,
    input ml_re,
    output wire [31:0] ml_data_out,
    output reg ml_ready,
    
    // Sinais de controle
    input [2:0] priority,  // 000=PCIE, 001=CORE, 010=ML
    output reg mem_idle
);

    // Estados da FSM
    localparam IDLE        = 3'b000;
    localparam PCIE_ACCESS = 3'b001;
    localparam CORE_ACCESS = 3'b010;
    localparam ML_ACCESS   = 3'b011;
    localparam REFRESH     = 3'b100;
    
    reg [2:0] state, next_state;
    
    // Registradores para solicitações pendentes
    reg pcie_req_pending;
    reg core_req_pending;
    reg ml_req_pending;
    
    // Buffer para solicitações (FIFO simples)
    reg [31:0] addr_buffer [0:7];
    reg [31:0] data_buffer [0:7];
    reg [2:0]  req_type_buffer [0:7];  // 000=PCIE, 001=CORE, 010=ML
    reg [2:0]  wr_ptr, rd_ptr;
    wire fifo_full, fifo_empty;
    
    // Registradores para dados de saída
    reg [31:0] pcie_data_out_reg;
    reg [31:0] core_data_out_reg;
    reg [31:0] ml_data_out_reg;
    
    // Contador para refresh de memória
    reg [15:0] refresh_counter;
    
    // Interface para UltraRAM (simplificada)
    reg [31:0] mem_addr;
    reg [31:0] mem_data_in;
    reg mem_we;
    reg mem_re;
    wire [31:0] mem_data_out;
    wire mem_ready;
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            pcie_req_pending <= 0;
            core_req_pending <= 0;
            ml_req_pending <= 0;
            mem_idle <= 1;
            refresh_counter <= 0;
        end else begin
            state <= next_state;
            
            case(state)
                IDLE: mem_idle <= 1;
                PCIE_ACCESS, CORE_ACCESS, ML_ACCESS: mem_idle <= 0;
                REFRESH: mem_idle <= 0;
                default: mem_idle <= 0;
            endcase
            
            // Incrementar contador de refresh
            if (refresh_counter < 65535)
                refresh_counter <= refresh_counter + 1;
            else
                refresh_counter <= 0;
        end
    end
    
    // FSM combinacional
    always @(*) begin
        case(state)
            IDLE: begin
                // Arbitragem de prioridade
                case(priority)
                    3'b001: begin
                        if (core_req_pending)      next_state = CORE_ACCESS;
                        else if (pcie_req_pending) next_state = PCIE_ACCESS;
                        else if (ml_req_pending)   next_state = ML_ACCESS;
                        else if (refresh_counter > 60000) next_state = REFRESH;
                        else next_state = IDLE;
                    end
                    3'b000: begin
                        if (pcie_req_pending)      next_state = PCIE_ACCESS;
                        else if (core_req_pending) next_state = CORE_ACCESS;
                        else if (ml_req_pending)   next_state = ML_ACCESS;
                        else if (refresh_counter > 60000) next_state = REFRESH;
                        else next_state = IDLE;
                    end
                    3'b010: begin
                        if (ml_req_pending)        next_state = ML_ACCESS;
                        else if (core_req_pending) next_state = CORE_ACCESS;
                        else if (pcie_req_pending) next_state = PCIE_ACCESS;
                        else if (refresh_counter > 60000) next_state = REFRESH;
                        else next_state = IDLE;
                    end
                    default: begin
                        if (core_req_pending)      next_state = CORE_ACCESS;
                        else if (pcie_req_pending) next_state = PCIE_ACCESS;
                        else if (ml_req_pending)   next_state = ML_ACCESS;
                        else if (refresh_counter > 60000) next_state = REFRESH;
                        else next_state = IDLE;
                    end
                endcase
            end
            PCIE_ACCESS:   next_state = mem_ready ? IDLE : PCIE_ACCESS;
            CORE_ACCESS:   next_state = mem_ready ? IDLE : CORE_ACCESS;
            ML_ACCESS:     next_state = mem_ready ? IDLE : ML_ACCESS;
            REFRESH:       next_state = mem_ready ? IDLE : REFRESH;
            default:       next_state = IDLE;
        endcase
    end
    
    // Lógica de buffer FIFO
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            // Adicionar solicitações ao buffer
            if ((pcie_re || pcie_we) && !fifo_full) begin
                addr_buffer[wr_ptr] <= pcie_addr;
                data_buffer[wr_ptr] <= pcie_data_in;
                req_type_buffer[wr_ptr] <= 3'b000;  // PCIE
                wr_ptr <= wr_ptr + 1;
            end else if ((core_re || core_we) && !fifo_full) begin
                addr_buffer[wr_ptr] <= core_addr;
                data_buffer[wr_ptr] <= core_data_in;
                req_type_buffer[wr_ptr] <= 3'b001;  // CORE
                wr_ptr <= wr_ptr + 1;
            end else if ((ml_re || ml_we) && !fifo_full) begin
                addr_buffer[wr_ptr] <= ml_addr;
                data_buffer[wr_ptr] <= ml_data_in;
                req_type_buffer[wr_ptr] <= 3'b010;  // ML
                wr_ptr <= wr_ptr + 1;
            end
            
            // Remover solicitações processadas
            if (mem_ready && !fifo_empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end
    
    // Detecção de FIFO cheio/vazio
    assign fifo_full  = (wr_ptr == rd_ptr - 1) || (wr_ptr == 3'h7 && rd_ptr == 0);
    assign fifo_empty = (wr_ptr == rd_ptr);
    
    // Lógica de controle de memória otimizada
    always @(posedge clk) begin
        if (!rst_n) begin
            mem_addr <= 0;
            mem_data_in <= 0;
            mem_we <= 0;
            mem_re <= 0;
            pcie_ready <= 0;
            core_ready <= 0;
            ml_ready <= 0;
            pcie_data_out_reg <= 0;
            core_data_out_reg <= 0;
            ml_data_out_reg <= 0;
        end else begin
            // Resetar sinais de controle
            mem_we <= 0;
            mem_re <= 0;
            pcie_ready <= 0;
            core_ready <= 0;
            ml_ready <= 0;
            
            case(state)
                IDLE: begin
                    pcie_req_pending <= pcie_re || pcie_we;
                    core_req_pending <= core_re || core_we;
                    ml_req_pending   <= ml_re || ml_we;
                end
                
                PCIE_ACCESS: begin
                    mem_addr    <= pcie_addr;
                    mem_data_in <= pcie_data_in;
                    mem_we      <= pcie_we;
                    mem_re      <= pcie_re;
                    
                    if (pcie_re && mem_ready) begin
                        pcie_data_out_reg <= mem_data_out;
                        pcie_ready <= 1;
                    end
                    if (pcie_we && mem_ready) begin
                        pcie_ready <= 1;
                    end
                end
                
                CORE_ACCESS: begin
                    mem_addr    <= core_addr;
                    mem_data_in <= core_data_in;
                    mem_we      <= core_we;
                    mem_re      <= core_re;
                    
                    if (core_re && mem_ready) begin
                        core_data_out_reg <= mem_data_out;
                        core_ready <= 1;
                    end
                    if (core_we && mem_ready) begin
                        core_ready <= 1;
                    end
                end
                
                ML_ACCESS: begin
                    mem_addr    <= ml_addr;
                    mem_data_in <= ml_data_in;
                    mem_we      <= ml_we;
                    mem_re      <= ml_re;
                    
                    if (ml_re && mem_ready) begin
                        ml_data_out_reg <= mem_data_out;
                        ml_ready <= 1;
                    end
                    if (ml_we && mem_ready) begin
                        ml_ready <= 1;
                    end
                end
                
                REFRESH: begin
                    mem_addr <= 0;
                    mem_re   <= 1;
                end
            endcase
        end
    end
    
    // Atribuições de saída
    assign pcie_data_out = pcie_data_out_reg;
    assign core_data_out = core_data_out_reg;
    assign ml_data_out   = ml_data_out_reg;
    
    // Modelo simplificado de UltraRAM - Reduzido para evitar erro de violação de acesso
    reg [31:0] ultraram [0:8191];  // 8K elementos (32KB) em vez de 786K elementos
    
    // Lógica de escrita
    always @(posedge clk) begin
        if (mem_we && (mem_addr/32) < 8192) begin  // Proteção de limite
            ultraram[mem_addr/32] <= mem_data_in;
        end
    end
    
    assign mem_data_out = ((mem_addr/32) < 8192) ? ultraram[mem_addr/32] : 32'h00000000;
    assign mem_ready = 1;  // Simulação simplificada - sempre pronto

endmodule
