module npu_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    input rst_n,
    
    // Interface com o softcore
    input  [ADDR_WIDTH-1:0] bus_addr,
    input  [DATA_WIDTH-1:0] bus_data_in,
    input  [2:0] bus_cmd,
    input  bus_ready,
    output reg [DATA_WIDTH-1:0] bus_data_out,
    output reg bus_req,
    
    // Interface com memória externa
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_data_out,
    output reg mem_we,
    output reg mem_re,
    input  [DATA_WIDTH-1:0] mem_data_in,
    input  mem_mem_ready,
    
    // Sinais de status
    output reg ready,
    output reg done
);

    // Sinais internos para os aceleradores
    reg  [DATA_WIDTH-1:0] conv2d_cmd;
    reg  conv2d_start;
    wire conv2d_done;
    wire [DATA_WIDTH-1:0] conv2d_result;

    reg  [DATA_WIDTH-1:0] fc_cmd;
    reg  fc_start;
    wire fc_done;
    wire [DATA_WIDTH-1:0] fc_result;

    reg  [DATA_WIDTH-1:0] dwconv2d_cmd;
    reg  dwconv2d_start;
    wire dwconv2d_done;
    wire [DATA_WIDTH-1:0] dwconv2d_result;

    reg  [DATA_WIDTH-1:0] matadd_cmd;
    reg  matadd_start;
    wire matadd_done;
    wire [DATA_WIDTH-1:0] matadd_result;
    
    // Sinais para novos aceleradores
    reg  [DATA_WIDTH-1:0] relu6_cmd;
    reg  relu6_start;
    wire relu6_done;
    wire [DATA_WIDTH-1:0] relu6_result;
    
    reg  [DATA_WIDTH-1:0] softmax_cmd;
    reg  softmax_start;
    wire softmax_done;
    wire [DATA_WIDTH-1:0] softmax_result;
    
    reg  [DATA_WIDTH-1:0] quantize_cmd;
    reg  quantize_start;
    wire quantize_done;
    wire [DATA_WIDTH-1:0] quantize_result;
    
    reg  [DATA_WIDTH-1:0] mean_cmd;
    reg  mean_start;
    wire mean_done;
    wire [DATA_WIDTH-1:0] mean_result;
    
    // Sinais para módulos adicionais
    reg  [DATA_WIDTH-1:0] ml_accelerator_cmd;
    reg  ml_accelerator_start;
    wire ml_accelerator_done;
    wire [DATA_WIDTH-1:0] ml_accelerator_result;
    
    reg  [DATA_WIDTH-1:0] conv2d_dsp_cmd;
    reg  conv2d_dsp_start;
    wire conv2d_dsp_done;
    wire [DATA_WIDTH-1:0] conv2d_dsp_result;
    
    // Sinais para novos módulos
    reg  [DATA_WIDTH-1:0] fully_connected_unit_cmd;
    reg  fully_connected_unit_start;
    wire fully_connected_unit_done;
    wire [DATA_WIDTH-1:0] fully_connected_unit_result;
    
    reg  [DATA_WIDTH-1:0] npu_controller_cmd;
    reg  npu_controller_start;
    wire npu_controller_done;
    wire [DATA_WIDTH-1:0] npu_controller_result;
    
    reg  [DATA_WIDTH-1:0] conv2d_unit_cmd;
    reg  conv2d_unit_start;
    wire conv2d_unit_done;
    wire [DATA_WIDTH-1:0] conv2d_unit_result;
    
    // Registradores para controle
    reg [DATA_WIDTH-1:0] current_cmd;
    reg [3:0] current_op;  // Aumentado para 4 bits para acomodar mais operações
    reg operation_start;
    reg operation_done;
    
    // Estado da FSM
    localparam IDLE      = 3'b000;
    localparam DECODE    = 3'b001;
    localparam EXECUTE   = 3'b010;
    localparam WAIT_DONE = 3'b011;
    localparam COMPLETE  = 3'b100;
    
    reg [2:0] state, next_state;
    
    // ========= SINAIS DE MEMÓRIA SEPARADOS =========
    // Sinais para conv2d_accelerator (saídas do módulo)
    wire [ADDR_WIDTH-1:0] conv2d_mem_addr;
    wire [DATA_WIDTH-1:0] conv2d_mem_data_out;
    wire conv2d_mem_we, conv2d_mem_re;
    
    // Sinais para fully_connected_accelerator (saídas do módulo)
    wire [ADDR_WIDTH-1:0] fc_mem_addr;
    wire [DATA_WIDTH-1:0] fc_mem_data_out;
    wire fc_mem_we, fc_mem_re;
    
    // Sinais de memória para ml_accelerator (saídas do módulo)
    wire [ADDR_WIDTH-1:0] ml_accelerator_mem_addr = 0;
    wire [DATA_WIDTH-1:0] ml_accelerator_mem_data_out = 0;
    wire ml_accelerator_mem_we = 0, ml_accelerator_mem_re = 0;
    
    // Sinais de memória externa para ml_accelerator (saídas do módulo)
    wire [ADDR_WIDTH-1:0] ml_accelerator_ext_mem_addr;
    wire [DATA_WIDTH-1:0] ml_accelerator_ext_mem_data_out;
    wire ml_accelerator_ext_mem_we, ml_accelerator_ext_mem_re;
    wire ml_accelerator_ext_mem_ready = 1'b1; // Placeholder
    
    // Sinais de memória para conv2d_dsp (saídas do módulo)
    wire [ADDR_WIDTH-1:0] conv2d_dsp_mem_addr;
    wire [DATA_WIDTH-1:0] conv2d_dsp_mem_data_out;
    wire conv2d_dsp_mem_we, conv2d_dsp_mem_re;
    
    // Sinais para npu_controller (saídas do módulo)
    wire [ADDR_WIDTH-1:0] npu_controller_mem_addr = 0;
    wire [DATA_WIDTH-1:0] npu_controller_mem_data_out = 0;
    wire npu_controller_mem_we = 0, npu_controller_mem_re = 0;
    
    // Registradores para armazenar os valores das saídas
    reg [ADDR_WIDTH-1:0] conv2d_mem_addr_reg;
    reg [DATA_WIDTH-1:0] conv2d_mem_data_out_reg;
    reg conv2d_mem_we_reg, conv2d_mem_re_reg;
    
    reg [ADDR_WIDTH-1:0] fc_mem_addr_reg;
    reg [DATA_WIDTH-1:0] fc_mem_data_out_reg;
    reg fc_mem_we_reg, fc_mem_re_reg;
    
    reg [ADDR_WIDTH-1:0] ml_accelerator_mem_addr_reg;
    reg [DATA_WIDTH-1:0] ml_accelerator_mem_data_out_reg;
    reg ml_accelerator_mem_we_reg, ml_accelerator_mem_re_reg;
    
    reg [ADDR_WIDTH-1:0] conv2d_dsp_mem_addr_reg;
    reg [DATA_WIDTH-1:0] conv2d_dsp_mem_data_out_reg;
    reg conv2d_dsp_mem_we_reg, conv2d_dsp_mem_re_reg;
    
    reg [ADDR_WIDTH-1:0] npu_controller_mem_addr_reg;
    reg [DATA_WIDTH-1:0] npu_controller_mem_data_out_reg;
    reg npu_controller_mem_we_reg, npu_controller_mem_re_reg;
    
    // Atualizar registradores com valores das saídas dos módulos
    always @(posedge clk) begin
        conv2d_mem_addr_reg <= conv2d_mem_addr;
        conv2d_mem_data_out_reg <= conv2d_mem_data_out;
        conv2d_mem_we_reg <= conv2d_mem_we;
        conv2d_mem_re_reg <= conv2d_mem_re;
        
        fc_mem_addr_reg <= fc_mem_addr;
        fc_mem_data_out_reg <= fc_mem_data_out;
        fc_mem_we_reg <= fc_mem_we;
        fc_mem_re_reg <= fc_mem_re;
        
        ml_accelerator_mem_addr_reg <= ml_accelerator_mem_addr;
        ml_accelerator_mem_data_out_reg <= ml_accelerator_mem_data_out;
        ml_accelerator_mem_we_reg <= ml_accelerator_mem_we;
        ml_accelerator_mem_re_reg <= ml_accelerator_mem_re;
        
        conv2d_dsp_mem_addr_reg <= conv2d_dsp_mem_addr;
        conv2d_dsp_mem_data_out_reg <= conv2d_dsp_mem_data_out;
        conv2d_dsp_mem_we_reg <= conv2d_dsp_mem_we;
        conv2d_dsp_mem_re_reg <= conv2d_dsp_mem_re;
        
        npu_controller_mem_addr_reg <= npu_controller_mem_addr;
        npu_controller_mem_data_out_reg <= npu_controller_mem_data_out;
        npu_controller_mem_we_reg <= npu_controller_mem_we;
        npu_controller_mem_re_reg <= npu_controller_mem_re;
    end

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
                COMPLETE: begin
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
                    next_state = DECODE;
                else
                    next_state = IDLE;
            end
            DECODE: begin
                next_state = EXECUTE;
            end
            EXECUTE: begin
                next_state = WAIT_DONE;
            end
            WAIT_DONE: begin
                if (operation_done)
                    next_state = COMPLETE;
                else
                    next_state = WAIT_DONE;
            end
            COMPLETE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Lógica de controle
    always @(posedge clk) begin
        if (!rst_n) begin
            current_cmd <= 0;
            current_op <= 0;
            operation_start <= 0;
            bus_req <= 0;
            mem_addr <= 0;
            mem_data_out <= 0;
            mem_we <= 0;
            mem_re <= 0;
        end else begin
            case(state)
                IDLE: begin
                    operation_start <= 0;
                    bus_req <= 0;
                    mem_we <= 0;
                    mem_re <= 0;
                end
                
                DECODE: begin
                    // Decodificar comando
                    current_cmd <= bus_data_in;
                    current_op <= bus_data_in[DATA_WIDTH-1:DATA_WIDTH-4]; // Opcode nos 4 bits MSB
                    operation_start <= 1;
                    bus_req <= 1;
                end
                
                EXECUTE: begin
                    operation_start <= 0;
                    // Configurar acelerador apropriado
                    case(current_op)
                        4'b0000: begin // Conv2D
                            conv2d_cmd <= current_cmd;
                            conv2d_start <= 1;
                        end
                        4'b0001: begin // Fully Connected
                            fc_cmd <= current_cmd;
                            fc_start <= 1;
                        end
                        4'b0010: begin // Depthwise Conv2D
                            dwconv2d_cmd <= current_cmd;
                            dwconv2d_start <= 1;
                        end
                        4'b0011: begin // Matrix Addition
                            matadd_cmd <= current_cmd;
                            matadd_start <= 1;
                        end
                        4'b0100: begin // ReLU6
                            relu6_cmd <= current_cmd;
                            relu6_start <= 1;
                        end
                        4'b0101: begin // Softmax
                            softmax_cmd <= current_cmd;
                            softmax_start <= 1;
                        end
                        4'b0110: begin // Quantize
                            quantize_cmd <= current_cmd;
                            quantize_start <= 1;
                        end
                        4'b0111: begin // Mean
                            mean_cmd <= current_cmd;
                            mean_start <= 1;
                        end
                        4'b1000: begin // ML Accelerator
                            ml_accelerator_cmd <= current_cmd;
                            ml_accelerator_start <= 1;
                        end
                        4'b1001: begin // Conv2D DSP
                            conv2d_dsp_cmd <= current_cmd;
                            conv2d_dsp_start <= 1;
                        end
                        4'b1010: begin // Fully Connected Unit
                            fully_connected_unit_cmd <= current_cmd;
                            fully_connected_unit_start <= 1;
                        end
                        4'b1011: begin // NPU Controller
                            npu_controller_cmd <= current_cmd;
                            npu_controller_start <= 1;
                        end
                        4'b1100: begin // Conv2D Unit
                            conv2d_unit_cmd <= current_cmd;
                            conv2d_unit_start <= 1;
                        end
                        default: begin
                            conv2d_start <= 0;
                            fc_start <= 0;
                            dwconv2d_start <= 0;
                            matadd_start <= 0;
                            relu6_start <= 0;
                            softmax_start <= 0;
                            quantize_start <= 0;
                            mean_start <= 0;
                            ml_accelerator_start <= 0;
                            conv2d_dsp_start <= 0;
                            fully_connected_unit_start <= 0;
                            npu_controller_start <= 0;
                            conv2d_unit_start <= 0;
                        end
                    endcase
                end
                
                WAIT_DONE: begin
                    // Desativar sinais de start
                    conv2d_start <= 0;
                    fc_start <= 0;
                    dwconv2d_start <= 0;
                    matadd_start <= 0;
                    relu6_start <= 0;
                    softmax_start <= 0;
                    quantize_start <= 0;
                    mean_start <= 0;
                    ml_accelerator_start <= 0;
                    conv2d_dsp_start <= 0;
                    fully_connected_unit_start <= 0;
                    npu_controller_start <= 0;
                    conv2d_unit_start <= 0;
                    
                    // Verificar conclusão
                    case(current_op)
                        4'b0000: operation_done = conv2d_done;
                        4'b0001: operation_done = fc_done;
                        4'b0010: operation_done = dwconv2d_done;
                        4'b0011: operation_done = matadd_done;
                        4'b0100: operation_done = relu6_done;
                        4'b0101: operation_done = softmax_done;
                        4'b0110: operation_done = quantize_done;
                        4'b0111: operation_done = mean_done;
                        4'b1000: operation_done = ml_accelerator_done;
                        4'b1001: operation_done = conv2d_dsp_done;
                        4'b1010: operation_done = fully_connected_unit_done;
                        4'b1011: operation_done = npu_controller_done;
                        4'b1100: operation_done = conv2d_unit_done;
                        default: operation_done = 1'b1;
                    endcase
                    
                    // Retornar resultado
                    if (operation_done) begin
                        case(current_op)
                            4'b0000: bus_data_out <= conv2d_result;
                            4'b0001: bus_data_out <= fc_result;
                            4'b0010: bus_data_out <= dwconv2d_result;
                            4'b0011: bus_data_out <= matadd_result;
                            4'b0100: bus_data_out <= relu6_result;
                            4'b0101: bus_data_out <= softmax_result;
                            4'b0110: bus_data_out <= quantize_result;
                            4'b0111: bus_data_out <= mean_result;
                            4'b1000: bus_data_out <= ml_accelerator_result;
                            4'b1001: bus_data_out <= conv2d_dsp_result;
                            4'b1010: bus_data_out <= fully_connected_unit_result;
                            4'b1011: bus_data_out <= npu_controller_result;
                            4'b1100: bus_data_out <= conv2d_unit_result;
                            default: bus_data_out <= {DATA_WIDTH{1'b0}};
                        endcase
                    end
                end
                
                COMPLETE: begin
                    // Reset para próximo comando
                end
                
                default: begin
                    // Manter valores
                end
            endcase
        end
    end

    // ========= MUX DE MEMÓRIA =========
    always @(*) begin
        case(current_op)
            4'b0000: begin // conv2d
                mem_addr     = conv2d_mem_addr_reg;
                mem_data_out = conv2d_mem_data_out_reg;
                mem_we       = conv2d_mem_we_reg;
                mem_re       = conv2d_mem_re_reg;
            end
            4'b0001: begin // fc
                mem_addr     = fc_mem_addr_reg;
                mem_data_out = fc_mem_data_out_reg;
                mem_we       = fc_mem_we_reg;
                mem_re       = fc_mem_re_reg;
            end
            4'b0010: begin // dwconv2d
                // Não há interface de memória direta para dwconv2d
                mem_addr     = {ADDR_WIDTH{1'b0}};
                mem_data_out = {DATA_WIDTH{1'b0}};
                mem_we       = 1'b0;
                mem_re       = 1'b0;
            end
            4'b0011: begin // matadd
                // Não há interface de memória direta para matadd
                mem_addr     = {ADDR_WIDTH{1'b0}};
                mem_data_out = {DATA_WIDTH{1'b0}};
                mem_we       = 1'b0;
                mem_re       = 1'b0;
            end
            4'b0100: begin // relu6
                // Não há interface de memória direta para relu6
                mem_addr     = {ADDR_WIDTH{1'b0}};
                mem_data_out = {DATA_WIDTH{1'b0}};
                mem_we       = 1'b0;
                mem_re       = 1'b0;
            end
            4'b0101: begin // softmax
                // Não há interface de memória direta para softmax
                mem_addr     = {ADDR_WIDTH{1'b0}};
                mem_data_out = {DATA_WIDTH{1'b0}};
                mem_we       = 1'b0;
                mem_re       = 1'b0;
            end
            4'b0110: begin // quantize
                // Não há interface de memória direta para quantize
                mem_addr     = {ADDR_WIDTH{1'b0}};
                mem_data_out = {DATA_WIDTH{1'b0}};
                mem_we       = 1'b0;
                mem_re       = 1'b0;
            end
            4'b0111: begin // mean
                // Não há interface de memória direta para mean
                mem_addr     = {ADDR_WIDTH{1'b0}};
                mem_data_out = {DATA_WIDTH{1'b0}};
                mem_we       = 1'b0;
                mem_re       = 1'b0;
            end
            4'b1000: begin // ml_accelerator
                mem_addr     = ml_accelerator_mem_addr_reg;
                mem_data_out = ml_accelerator_mem_data_out_reg;
                mem_we       = ml_accelerator_mem_we_reg;
                mem_re       = ml_accelerator_mem_re_reg;
            end
            4'b1001: begin // conv2d_dsp
                mem_addr     = conv2d_dsp_mem_addr_reg;
                mem_data_out = conv2d_dsp_mem_data_out_reg;
                mem_we       = conv2d_dsp_mem_we_reg;
                mem_re       = conv2d_dsp_mem_re_reg;
            end
            4'b1011: begin // npu_controller
                mem_addr     = npu_controller_mem_addr_reg;
                mem_data_out = npu_controller_mem_data_out_reg;
                mem_we       = npu_controller_mem_we_reg;
                mem_re       = npu_controller_mem_re_reg;
            end
            default: begin
                mem_addr     = {ADDR_WIDTH{1'b0}};
                mem_data_out = {DATA_WIDTH{1'b0}};
                mem_we       = 1'b0;
                mem_re       = 1'b0;
            end
        endcase
    end
    
    // Instâncias dos aceleradores
    conv2d_accelerator conv2d_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cmd(conv2d_cmd),
        .start(conv2d_start),
        .done(conv2d_done),
        .ready(),
        .mem_addr(conv2d_mem_addr),
        .mem_data_in(mem_data_in),
        .mem_we(conv2d_mem_we),
        .mem_re(conv2d_mem_re),
        .mem_data_out(conv2d_mem_data_out),
        .mem_ready(mem_mem_ready),
        .input_height(conv2d_cmd[15:0]),      // Exemplo
        .input_width(conv2d_cmd[DATA_WIDTH-1:16]),
        .input_channels(3),
        .output_height(6),
        .output_width(6),
        .output_channels(16),
        .kernel_height(3),
        .kernel_width(3),
        .stride_h(1),
        .stride_w(1),
        .pad_h(0),
        .pad_w(0),
        .result(conv2d_result)
    );
    
    fully_connected_accelerator fc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cmd(fc_cmd),
        .start(fc_start),
        .done(fc_done),
        .ready(),
        .mem_addr(fc_mem_addr),
        .mem_data_in(mem_data_in),
        .mem_we(fc_mem_we),
        .mem_re(fc_mem_re),
        .mem_data_out(fc_mem_data_out),
        .mem_ready(mem_mem_ready),
        .input_size(fc_cmd[15:0]),
        .output_size(fc_cmd[DATA_WIDTH-1:16]),
        .result(fc_result)
    );
    
    dwconv2d_unit dwconv2d_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(dwconv2d_start),
        .input_ptr(dwconv2d_cmd[DATA_WIDTH-1:0]),
        .filter_ptr(dwconv2d_cmd[DATA_WIDTH-1:0]),
        .output_ptr(dwconv2d_cmd[DATA_WIDTH-1:0]),
        .input_dims(32'h01080803),
        .filter_dims(32'h03030310),
        .output_dims(32'h01060610),
        .stride(32'h00010001),
        .padding(32'h00000000),
        .result(dwconv2d_result),
        .done(dwconv2d_done),
        .ready()
    );
    
    matadd_unit matadd_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(matadd_start),
        .mat1_ptr(matadd_cmd[DATA_WIDTH-1:0]),
        .mat2_ptr(matadd_cmd[DATA_WIDTH-1:0]),
        .output_ptr(matadd_cmd[DATA_WIDTH-1:0]),
        .matrix_dims(32'h01000100),
        .result(matadd_result),
        .done(matadd_done),
        .ready()
    );
    
    // Instâncias dos novos aceleradores
    relu6_unit relu6_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(relu6_start),
        .input_data(relu6_cmd[DATA_WIDTH-1:0]),
        .output_data(relu6_result),
        .done(relu6_done),
        .ready()
    );
    
    softmax_unit softmax_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(softmax_start),
        .input_ptr(softmax_cmd[DATA_WIDTH-1:0]),
        .output_ptr(softmax_cmd[DATA_WIDTH-1:0]),
        .size(32'd256),  // Valor de exemplo
        .result(softmax_result),
        .done(softmax_done),
        .ready()
    );
    
    quantize_unit quantize_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(quantize_start),
        .input_ptr(quantize_cmd[DATA_WIDTH-1:0]),
        .params(quantize_cmd[DATA_WIDTH-1:0]),
        .size(32'd256),  // Valor de exemplo
        .result(quantize_result),
        .done(quantize_done),
        .ready()
    );
    
    mean_unit mean_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(mean_start),
        .input_ptr(mean_cmd[DATA_WIDTH-1:0]),
        .params(mean_cmd[DATA_WIDTH-1:0]),
        .result(mean_result),
        .done(mean_done),
        .ready()
    );
    
    // Instâncias dos módulos adicionais
    ml_accelerator ml_accelerator_inst (
        .clk(clk),
        .rst_n(rst_n),
        .instruction(ml_accelerator_cmd),
        .rs1_data(ml_accelerator_cmd), // Placeholder
        .rs2_data(ml_accelerator_cmd), // Placeholder
        .rd_addr(5'd0), // Placeholder
        .start(ml_accelerator_start),
        .op_mode(current_op[3:0]),
        .mem_data_in(mem_data_in),
        .mem_addr(ml_accelerator_mem_addr),
        .mem_we(ml_accelerator_mem_we),
        .mem_re(ml_accelerator_mem_re),
        .result(ml_accelerator_result),
        .mem_data_out(ml_accelerator_mem_data_out),
        .ready(),
        .done(ml_accelerator_done),
        .ext_mem_addr(ml_accelerator_ext_mem_addr),
        .ext_mem_data_out(ml_accelerator_ext_mem_data_out),
        .ext_mem_we(ml_accelerator_ext_mem_we),
        .ext_mem_re(ml_accelerator_ext_mem_re),
        .ext_mem_data_in(mem_data_in),
        .ext_mem_ready(ml_accelerator_ext_mem_ready)
    );
    
    conv2d_dsp conv2d_dsp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(conv2d_dsp_start),
        .done(conv2d_dsp_done),
        .ready(),
        .input_addr(conv2d_dsp_cmd), // Placeholder
        .weights_addr(conv2d_dsp_cmd), // Placeholder
        .output_addr(conv2d_dsp_cmd), // Placeholder
        .bias_addr(conv2d_dsp_cmd), // Placeholder
        .mem_addr(conv2d_dsp_mem_addr),
        .mem_data_out(conv2d_dsp_mem_data_out),
        .mem_we(conv2d_dsp_mem_we),
        .mem_re(conv2d_dsp_mem_re),
        .mem_data_in(mem_data_in),
        .mem_ready(mem_mem_ready),
        .input_height(8), // Placeholder
        .input_width(8), // Placeholder
        .output_height(6), // Placeholder
        .output_width(6), // Placeholder
        .stride_h(1), // Placeholder
        .stride_w(1), // Placeholder
        .pad_h(0), // Placeholder
        .pad_w(0), // Placeholder
        .result(conv2d_dsp_result)
    );
    
    // Instâncias dos novos módulos solicitados
    fully_connected_unit fully_connected_unit_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(fully_connected_unit_start),
        .input_ptr(fully_connected_unit_cmd[DATA_WIDTH-1:0]),
        .weights_ptr(fully_connected_unit_cmd[DATA_WIDTH-1:0]),
        .bias_ptr(fully_connected_unit_cmd[DATA_WIDTH-1:0]),
        .output_ptr(fully_connected_unit_cmd[DATA_WIDTH-1:0]),
        .dims(fully_connected_unit_cmd[DATA_WIDTH-1:0]),
        .result(fully_connected_unit_result),
        .done(fully_connected_unit_done),
        .ready()
    );
    
    npu_controller npu_controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(bus_addr),
        .bus_data_in(bus_data_in),
        .bus_cmd(bus_cmd),
        .bus_ready(bus_ready),
        .bus_data_out(npu_controller_result),
        .bus_req(),
        .mem_addr(npu_controller_mem_addr),
        .mem_data_out(npu_controller_mem_data_out),
        .mem_we(npu_controller_mem_we),
        .mem_re(npu_controller_mem_re),
        .mem_data_in(mem_data_in),
        .mem_mem_ready(mem_mem_ready),
        .accelerator_cmd(),  // Desconectado - porta de saída
        .accelerator_start(),  // Desconectado - porta de saída
        .accelerator_done(1'b0),  // Conectado como entrada
        .accelerator_result(32'd0),  // Conectado como entrada
        .ready(),
        .done(npu_controller_done)
    );
    
    conv2d_unit conv2d_unit_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(conv2d_unit_start),
        .input_ptr(conv2d_unit_cmd[DATA_WIDTH-1:0]),
        .filter_ptr(conv2d_unit_cmd[DATA_WIDTH-1:0]),
        .output_ptr(conv2d_unit_cmd[DATA_WIDTH-1:0]),
        .input_dims(32'h01080803),
        .filter_dims(32'h03030310),
        .output_dims(32'h01060610),
        .stride(32'h00010001),
        .padding(32'h00000000),
        .result(conv2d_unit_result),
        .done(conv2d_unit_done),
        .ready()
    );
    
    // Sinais de memória são atribuídos pelo mux acima

endmodule