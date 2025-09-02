module dwconv2d_unit (
    input clk,
    input rst_n,
    input start,
    input [31:0] input_ptr,
    input [31:0] filter_ptr,
    input [31:0] output_ptr,
    input [31:0] input_dims,    // [N, H, W, C]
    input [31:0] filter_dims,   // [KH, KW, C]
    input [31:0] output_dims,   // [N, OH, OW, C]
    input [31:0] stride,
    input [31:0] padding,
    output reg [31:0] result,
    output reg done,
    output reg ready
);

    // Variável para loops
    integer loop_i;
    localparam IDLE = 3'b000;
    localparam LOAD_INPUT = 3'b001;
    localparam LOAD_FILTER = 3'b010;
    localparam COMPUTE = 3'b011;
    localparam STORE_OUTPUT = 3'b100;
    localparam DONE = 3'b101;
    
    reg [2:0] state, next_state;
    
    // Contadores
    reg [31:0] n, h, w, c, kh, kw;
    reg [31:0] oh, ow;
    
    // Buffers
    reg [31:0] input_buffer [0:255];   // Buffer para dados de entrada
    reg [31:0] filter_buffer [0:255];  // Buffer para pesos do filtro
    reg [31:0] output_buffer [0:255];  // Buffer para saída
    
    // Registradores para dimensões
    reg [31:0] N, H, W, C;
    reg [31:0] KH, KW;
    reg [31:0] OH, OW;
    reg [31:0] STRIDE_H, STRIDE_W;
    reg [31:0] PAD_TOP, PAD_BOTTOM, PAD_LEFT, PAD_RIGHT;
    
    // Inicializar registradores para evitar warnings
    initial begin
        N = 0;
        H = 0;
        W = 0;
        C = 0;
        KH = 0;
        KW = 0;
        OH = 0;
        OW = 0;
        STRIDE_H = 0;
        STRIDE_W = 0;
        PAD_TOP = 0;
        PAD_BOTTOM = 0;
        PAD_LEFT = 0;
        PAD_RIGHT = 0;
    end
    
    // Acumulador para MAC
    reg [31:0] accumulator;
    
    // FSM sequencial
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
            n <= 0;
            h <= 0;
            w <= 0;
            c <= 0;
            kh <= 0;
            kw <= 0;
            oh <= 0;
            ow <= 0;
            N <= 0;
            H <= 0;
            W <= 0;
            C <= 0;
            KH <= 0;
            KW <= 0;
            OH <= 0;
            OW <= 0;
            STRIDE_H <= 0;
            STRIDE_W <= 0;
            PAD_TOP <= 0;
            PAD_BOTTOM <= 0;
            PAD_LEFT <= 0;
            PAD_RIGHT <= 0;
            accumulator <= 0;
        end else begin
            state <= next_state;
            
            case(state)
                IDLE: begin
                    done <= 0;
                    ready <= 1;
                end
                DONE: begin
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
                next_state = LOAD_FILTER;
            end
            LOAD_FILTER: begin
                next_state = COMPUTE;
            end
            COMPUTE: begin
                next_state = STORE_OUTPUT;
            end
            STORE_OUTPUT: begin
                next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Lógica de controle
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset dos contadores
            n <= 0;
            h <= 0;
            w <= 0;
            c <= 0;
            kh <= 0;
            kw <= 0;
            oh <= 0;
            ow <= 0;
            
            // Reset dos acumuladores
            accumulator <= 0;
        end else begin
            case(state)
                IDLE: begin
                    // Parse das dimensões
                    N <= input_dims[31:24];
                    H <= input_dims[23:16];
                    W <= input_dims[15:8];
                    C <= input_dims[7:0];
                    
                    KH <= filter_dims[23:16];
                    KW <= filter_dims[15:8];
                    
                    OH <= output_dims[23:16];
                    OW <= output_dims[15:8];
                    
                    STRIDE_H <= stride[31:16];
                    STRIDE_W <= stride[15:0];
                    
                    PAD_TOP <= padding[31:24];
                    PAD_BOTTOM <= padding[23:16];
                    PAD_LEFT <= padding[15:8];
                    PAD_RIGHT <= padding[7:0];
                end
                
                LOAD_INPUT: begin
                    // Simulação de carga de dados de entrada
                    for (loop_i = 0; loop_i < 256; loop_i = loop_i + 1) begin
                        input_buffer[loop_i] <= 32'h00000001; // Valor de exemplo
                    end
                end
                
                LOAD_FILTER: begin
                    // Simulação de carga de pesos do filtro
                    for (loop_i = 0; loop_i < 256; loop_i = loop_i + 1) begin
                        filter_buffer[loop_i] <= 32'h00000001; // Valor de exemplo
                    end
                end
                
                COMPUTE: begin
                    // Lógica de computação da convolução 2D profundidade-separável
                    // Esta é uma implementação simplificada para demonstração
                    if (oh < OH && ow < OW && c < C) begin
                        // Operação MAC simplificada
                        accumulator <= accumulator + (input_buffer[0] * filter_buffer[0]);
                        
                        // Atualização dos contadores
                        kw <= kw + 1;
                        if (kw >= KW) begin
                            kw <= 0;
                            kh <= kh + 1;
                            if (kh >= KH) begin
                                kh <= 0;
                                ow <= ow + 1;
                                if (ow >= OW) begin
                                    ow <= 0;
                                    oh <= oh + 1;
                                    if (oh >= OH) begin
                                        oh <= 0;
                                        c <= c + 1;
                                    end
                                end
                            end
                        end
                    end else begin
                        // Armazenar resultado
                        output_buffer[c] <= accumulator;
                        accumulator <= 0;
                    end
                end
                
                STORE_OUTPUT: begin
                    // Armazenar resultado na memória de saída
                    result <= output_buffer[0]; // Usar índice 0 para evitar problemas
                end
                
                DONE: begin
                    // Reset para próxima execução
                end
                
                default: begin
                    // Manter valores
                end
            endcase
        end
    end

endmodule