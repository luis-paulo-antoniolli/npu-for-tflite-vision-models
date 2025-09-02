module conv2d_accelerator #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MAX_KERNEL_SIZE = 16,
    parameter MAX_INPUT_CHANNELS = 256,
    parameter MAX_OUTPUT_CHANNELS = 256
) (
    input clk,
    input rst_n,
    
    // Interface de controle
    input [DATA_WIDTH-1:0] cmd,
    input start,
    output reg done,
    output reg ready,
    
    // Interface de memória (CORRIGIDO: direções)
    output reg [ADDR_WIDTH-1:0] mem_addr,
    input      [DATA_WIDTH-1:0] mem_data_in,
    output reg                  mem_we,
    output reg                  mem_re,
    output reg [DATA_WIDTH-1:0] mem_data_out,
    input                       mem_ready,
    
    // Parâmetros da convolução
    input [15:0] input_height,
    input [15:0] input_width,
    input [15:0] input_channels,
    input [15:0] output_height,
    input [15:0] output_width,
    input [15:0] output_channels,
    input [15:0] kernel_height,
    input [15:0] kernel_width,
    input [15:0] stride_h,
    input [15:0] stride_w,
    input [15:0] pad_h,
    input [15:0] pad_w,
    
    // Resultado
    output reg [DATA_WIDTH-1:0] result
);

    // Estados da FSM
    localparam IDLE          = 4'b0000;
    localparam LOAD_INPUT    = 4'b0001;
    localparam LOAD_WEIGHTS  = 4'b0010;
    localparam LOAD_BIAS     = 4'b0011;
    localparam COMPUTE_INIT  = 4'b0100;
    localparam COMPUTE_LOOP  = 4'b0101;
    localparam ACCUMULATE    = 4'b0110;
    localparam ACTIVATION    = 4'b0111;
    localparam STORE_OUTPUT  = 4'b1000;
    localparam DONE_STATE    = 4'b1001;
    
    reg [3:0] state, next_state;
    
    // Buffers (utilizando BRAM)
    (* ram_style = "block" *) reg [7:0]  input_buffer   [0:65535];   // int8
    (* ram_style = "block" *) reg [7:0]  weights_buffer [0:65535];   // int8
    (* ram_style = "block" *) reg [31:0] bias_buffer    [0:255];     // int32

    // ====== OUTPUT BUFFER EM 4 BANCOS (4 x 16k x 32b = 2,097,152 bits total) ======
    // Cada banco ~512 kbits, abaixo do limite de 1,000,000 bits por variável.
    (* ram_style = "block" *) reg [31:0] output_buffer0 [0:16383];
    (* ram_style = "block" *) reg [31:0] output_buffer1 [0:16383];
    (* ram_style = "block" *) reg [31:0] output_buffer2 [0:16383];
    (* ram_style = "block" *) reg [31:0] output_buffer3 [0:16383];

    // Sinais de acesso ao output_buffer bankeado
    reg        ob_we;                 // enable de escrita
    reg [15:0] ob_wr_addr;            // endereço de escrita
    reg [31:0] ob_wr_data;            // dado de escrita
    wire [15:0] ob_rd_addr;           // endereço de leitura
    reg  [31:0] ob_rd_data;           // dado lido (combinacional)
    
    // Registradores para índices (movidos para evitar uso antes da declaração)
    reg [15:0] acc_idx;
    reg [15:0] current_iteration;

    // Leitura combinacional dos bancos (1 porta de leitura "virtual")
    assign ob_rd_addr = (state == STORE_OUTPUT) ? (current_iteration[15:0]) :
                        (state == ACTIVATION)   ? (acc_idx[15:0]) :
                                                   16'd0;

    always @(*) begin
        case (ob_rd_addr[15:14])
            2'b00: ob_rd_data = output_buffer0[ob_rd_addr[13:0]];
            2'b01: ob_rd_data = output_buffer1[ob_rd_addr[13:0]];
            2'b10: ob_rd_data = output_buffer2[ob_rd_addr[13:0]];
            2'b11: ob_rd_data = output_buffer3[ob_rd_addr[13:0]];
        endcase
    end

    // Escrita sequencial nos bancos (1 porta de escrita "virtual")
    always @(posedge clk) begin
        if (ob_we) begin
            case (ob_wr_addr[15:14])
                2'b00: output_buffer0[ob_wr_addr[13:0]] <= ob_wr_data;
                2'b01: output_buffer1[ob_wr_addr[13:0]] <= ob_wr_data;
                2'b10: output_buffer2[ob_wr_addr[13:0]] <= ob_wr_data;
                2'b11: output_buffer3[ob_wr_addr[13:0]] <= ob_wr_data;
                // Removido bloco default que nunca é usado
                /*
                default: begin
                    // Default case to prevent latch inference
                    output_buffer0[ob_wr_addr[13:0]] <= ob_wr_data;
                end
                */
            endcase
        end
    end
    // ==============================================================================

    // Registradores para índices (declarados no início para evitar uso antes da declaração)
    reg [15:0] out_y, out_x, out_c;
    reg [15:0] ker_y, ker_x, in_c;
    
    // Pipeline de MAC
    reg [15:0] mac_a, mac_b;
    reg [31:0] mac_result;
    reg [47:0] accumulator;  // 48 bits para acumulação
    reg [31:0] bias_value;
    
    // Registradores para cálculos
    // CORRIGIDO: signed para permitir comparação com zero (negativo)
    // CORRIGIDO: signed para permitir comparação com zero (negativo)
    reg signed [16:0] in_y, in_x;
    // Reabilitando registradores pois estão sendo usados no código
    reg [15:0] input_idx, weights_idx, output_idx;
    // reg [15:0] total_iterations;
    
    // Forçar uso dos registradores para evitar remoção
    initial begin
        in_y = 0;
        in_x = 0;
        // total_iterations = 0; // Comentado pois foi removido
    end
    
    // Registradores para quantização (não usados integralmente aqui)
    // Removidos para limpar código - não estão sendo usados no datapath
    /*
    reg [31:0] input_scale;
    reg [31:0] weights_scale;
    reg [31:0] output_scale;
    reg [7:0]  input_zero_point;
    reg [7:0]  weights_zero_point;
    reg [7:0]  output_zero_point;
    */
    
    // Inicializar registradores para evitar warnings
    initial begin
        in_y = 0;
        in_x = 0;
        input_idx = 0;
        weights_idx = 0;
        output_idx = 0;
        // total_iterations = 0; // Comentado pois foi removido
    end
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done  <= 0;
            ready <= 1;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    done  <= 0;
                    ready <= 1;
                end
                DONE_STATE: begin
                    done  <= 1;
                    ready <= 1;
                end
                default: begin
                    done  <= 0;
                    ready <= 0;
                end
            endcase
        end
    end
    
    // FSM combinacional
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD_INPUT;
                else
                    next_state = IDLE;
            end
            LOAD_INPUT: begin
                if (current_iteration >= input_height * input_width * input_channels)
                    next_state = LOAD_WEIGHTS;
                else
                    next_state = LOAD_INPUT;
            end
            LOAD_WEIGHTS: begin
                if (current_iteration >= kernel_height * kernel_width * input_channels * output_channels)
                    next_state = LOAD_BIAS;
                else
                    next_state = LOAD_WEIGHTS;
            end
            LOAD_BIAS: begin
                if (current_iteration >= output_channels)
                    next_state = COMPUTE_INIT;
                else
                    next_state = LOAD_BIAS;
            end
            COMPUTE_INIT: begin
                next_state = COMPUTE_LOOP;
            end
            COMPUTE_LOOP: begin
                if (out_y >= output_height)
                    next_state = STORE_OUTPUT;
                else
                    next_state = COMPUTE_LOOP;
            end
            ACCUMULATE: begin
                next_state = ACTIVATION;
            end
            ACTIVATION: begin
                next_state = COMPUTE_LOOP;
            end
            STORE_OUTPUT: begin
                if (current_iteration >= output_height * output_width * output_channels)
                    next_state = DONE_STATE;
                else
                    next_state = STORE_OUTPUT;
            end
            DONE_STATE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Pipeline de MAC
    // Primeiro estágio: multiplicação
    always @(posedge clk) begin
        mac_result <= $signed(mac_a) * $signed(mac_b);
    end
    
    // Segundo estágio: acumulação
    always @(posedge clk) begin
        accumulator <= accumulator + {{16{mac_result[31]}}, mac_result};
    end
    
    // Lógica de controle
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset de índices
            out_y <= 0;
            out_x <= 0;
            out_c <= 0;
            ker_y <= 0;
            ker_x <= 0;
            in_c  <= 0;
            acc_idx <= 0;
            
            // Reset de contadores
            current_iteration <= 0;
            
            // Reset acumulador
            accumulator <= 0;
            bias_value  <= 0;
            
            // Reset sinais de memória
            mem_we      <= 0;
            mem_re      <= 0;
            mem_addr    <= 0;
            mem_data_out<= 0;
            // (CORRIGIDO: não atribuir mem_ready, é input)

            // Reset saída bankeada
            ob_we       <= 0;
            ob_wr_addr  <= 0;
            ob_wr_data  <= 0;
            
            // Reset parâmetros de quantização
            // Removidos para limpar código - não estão sendo usados no datapath
            /*
            input_scale       <= 0;
            weights_scale     <= 0;
            output_scale      <= 0;
            input_zero_point  <= 0;
            weights_zero_point<= 0;
            output_zero_point <= 0;
            */
        end else begin
            // default para escritas no output_buffer
            ob_we <= 0;

            case (state)
                IDLE: begin
                    // Reset todos os índices
                    out_y <= 0;
                    out_x <= 0;
                    out_c <= 0;
                    ker_y <= 0;
                    ker_x <= 0;
                    in_c  <= 0;
                    acc_idx <= 0;
                    current_iteration <= 0;
                    accumulator <= 0;
                    mem_we <= 0;
                    mem_re <= 0;
                end
                
                LOAD_INPUT: begin
                    // Ler dados de entrada
                    if (current_iteration < input_height * input_width * input_channels) begin
                        // Solicita leitura
                        mem_addr <= cmd[31:0] + (current_iteration << 2); // Endereço de entrada
                        mem_re   <= 1;
                        mem_we   <= 0;
                        // Quando memória indicar dado pronto, captura
                        if (mem_ready) begin
                            if (current_iteration < 65536) begin
                                input_buffer[current_iteration] <= mem_data_in[7:0]; // int8
                            end
                            current_iteration <= current_iteration + 1;
                        end
                    end else begin
                        mem_re <= 0;
                    end
                end
                
                LOAD_WEIGHTS: begin
                    // Carregar pesos
                    if (current_iteration < kernel_height * kernel_width * input_channels * output_channels) begin
                        mem_addr <= cmd[31:0] + (current_iteration << 2); // Endereço de pesos
                        mem_re   <= 1;
                        mem_we   <= 0;
                        if (mem_ready) begin
                            if (current_iteration < 65536) begin
                                weights_buffer[current_iteration] <= mem_data_in[7:0]; // int8
                            end
                            current_iteration <= current_iteration + 1;
                        end
                    end else begin
                        mem_re <= 0;
                    end
                end
                
                LOAD_BIAS: begin
                    // Carregar bias
                    if (current_iteration < output_channels) begin
                        mem_addr <= cmd[31:0] + (current_iteration << 2); // Endereço de bias
                        mem_re   <= 1;
                        mem_we   <= 0;
                        if (mem_ready) begin
                            if (current_iteration < 256) begin
                                bias_buffer[current_iteration] <= mem_data_in; // int32
                            end
                            current_iteration <= current_iteration + 1;
                        end
                    end else begin
                        mem_re <= 0;
                    end
                end
                
                COMPUTE_INIT: begin
                    // Inicializar loop de computação
                    out_y <= 0;
                    out_x <= 0;
                    out_c <= 0;
                    ker_y <= 0;
                    ker_x <= 0;
                    in_c  <= 0;
                    acc_idx <= 0;
                    accumulator <= 0;
                    mem_re <= 0;
                    mem_we <= 0;
                end
                
                COMPUTE_LOOP: begin
                    // Loop principal de convolução
                    if (out_y < output_height) begin
                        if (out_x < output_width) begin
                            if (out_c < output_channels) begin
                                // Calcular índices de entrada
                                in_y = $signed(out_y) * $signed(stride_h) + $signed(ker_y) - $signed(pad_h);
                                in_x = $signed(out_x) * $signed(stride_w) + $signed(ker_x) - $signed(pad_w);
                                
                                // Verificar limites
                                if (in_y >= 0 && in_x >= 0 &&
                                    in_y < $signed(input_height) && in_x < $signed(input_width) &&
                                    ker_y < kernel_height && ker_x < kernel_width &&
                                    in_c < input_channels) begin
                                    
                                    // Calcular índices
                                    input_idx   = (in_y * input_width + in_x) * input_channels + in_c;
                                    weights_idx = ((out_c * kernel_height + ker_y) * kernel_width + ker_x) * input_channels + in_c;
                                    
                                    // Configurar MAC (sign-extend de int8 para 16)
                                    if (input_idx < 65536 && weights_idx < 65536) begin
                                        mac_a <= {{8{input_buffer[input_idx][7]}},   input_buffer[input_idx]};
                                        mac_b <= {{8{weights_buffer[weights_idx][7]}}, weights_buffer[weights_idx]};
                                    end
                                    
                                    // Avança no kernel
                                    if (ker_x + 1 < kernel_width) begin
                                        ker_x <= ker_x + 1;
                                    end else begin
                                        ker_x <= 0;
                                        if (ker_y + 1 < kernel_height) begin
                                            ker_y <= ker_y + 1;
                                        end else begin
                                            ker_y <= 0;
                                            if (in_c + 1 < input_channels) begin
                                                in_c <= in_c + 1;
                                            end else begin
                                                in_c <= 0;
                                                // terminou a acumulação para este out_c -> adiciona bias e ativa
                                                if (out_c < 256) begin
                                                    bias_value <= bias_buffer[out_c];
                                                end
                                                // vai para ACCUMULATE/ACTIVATION de forma implícita neste pipeline
                                                // aqui apenas avança o canal de saída
                                                if (out_c + 1 < output_channels) begin
                                                    out_c <= out_c + 1;
                                                end else begin
                                                    out_c <= 0;
                                                    if (out_x + 1 < output_width) begin
                                                        out_x <= out_x + 1;
                                                    end else begin
                                                        out_x <= 0;
                                                        out_y <= out_y + 1;
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end else begin
                                    // Fora dos limites: apenas avança nas dimensões do kernel/canais
                                    if (ker_x + 1 < kernel_width) begin
                                        ker_x <= ker_x + 1;
                                    end else begin
                                        ker_x <= 0;
                                        if (ker_y + 1 < kernel_height) begin
                                            ker_y <= ker_y + 1;
                                        end else begin
                                            ker_y <= 0;
                                            if (in_c + 1 < input_channels) begin
                                                in_c <= in_c + 1;
                                            end else begin
                                                in_c <= 0;
                                                if (out_c < 256) begin
                                                    bias_value <= bias_buffer[out_c];
                                                end
                                                if (out_c + 1 < output_channels) begin
                                                    out_c <= out_c + 1;
                                                end else begin
                                                    out_c <= 0;
                                                    if (out_x + 1 < output_width) begin
                                                        out_x <= out_x + 1;
                                                    end else begin
                                                        out_x <= 0;
                                                        out_y <= out_y + 1;
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                ACCUMULATE: begin
                    // Adicionar bias ao acumulador
                    accumulator <= accumulator + {{16{bias_value[31]}}, bias_value};
                end
                
                ACTIVATION: begin
                    // Aplicar ReLU e escrever no output_buffer (via bancos)
                    ob_wr_addr <= acc_idx;  // 0..65535
                    if (accumulator[47]) begin
                        ob_wr_data <= 32'd0;
                    end else begin
                        ob_wr_data <= accumulator[31:0];
                    end
                    ob_we <= 1'b1;

                    acc_idx <= acc_idx + 1;
                end
                
                STORE_OUTPUT: begin
                    // Ler do buffer bankeado e escrever na memória externa
                    if (current_iteration < output_height * output_width * output_channels) begin
                        mem_addr     <= cmd[31:0] + (current_iteration << 2); // Endereço de saída
                        mem_data_out <= ob_rd_data; // dado lido do banco pelo ob_rd_addr
                        mem_we       <= 1;
                        mem_re       <= 0;
                        if (mem_ready) begin
                            current_iteration <= current_iteration + 1;
                        end
                    end else begin
                        mem_we <= 0;
                    end
                    
                    // Armazenar resultado final (opcional)
                    if (current_iteration == 0) begin
                        // ob_rd_addr==0 quando não estamos em STORE/ACTIVATION; aqui estamos em STORE e current_iteration==0, então ob_rd_addr=0
                        result <= ob_rd_data;
                    end
                end
                
                DONE_STATE: begin
                    // Reset para próxima execução
                    current_iteration <= 0;
                    mem_we <= 0;
                    mem_re <= 0;
                end
                
                default: begin
                    // Mantém valores
                end
            endcase
        end
    end

endmodule
