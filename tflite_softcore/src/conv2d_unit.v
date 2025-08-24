module conv2d_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] input_ptr,
    input  wire [31:0] filter_ptr,
    input  wire [31:0] output_ptr,
    input  wire [31:0] input_dims,    // packed [N, H, W, C]
    input  wire [31:0] filter_dims,   // packed [KH, KW, C_in, C_out]
    input  wire [31:0] output_dims,   // packed [N, OH, OW, C_out]
    input  wire [31:0] stride,        // packed [SH, SW]
    input  wire [31:0] padding,       // packed [PT, PB, PL, PR]
    output reg  [31:0] result,
    output reg         done,
    output reg         ready
);

    // States (consistent naming)
    localparam IDLE         = 3'b000;
    localparam LOAD_INPUT   = 3'b001;
    localparam LOAD_FILTER  = 3'b010;
    localparam COMPUTE      = 3'b011;
    localparam STORE_OUTPUT = 3'b100;
    localparam DONE_STATE   = 3'b101;

    reg [2:0] state, next_state;

    // Buffers (example small buffers — adapt size as needed)
    reg [31:0] input_buffer  [0:255];
    reg [31:0] filter_buffer [0:255];
    reg [31:0] output_buffer [0:255];

    // Parsed dimension registers
    reg [31:0] N, H, W, C;
    reg [31:0] KH, KW, C_IN, C_OUT;
    reg [31:0] OH, OW;
    reg [31:0] STRIDE_H, STRIDE_W;
    reg [31:0] PAD_TOP, PAD_BOTTOM, PAD_LEFT, PAD_RIGHT;

    // Counters used in compute
    reg [31:0] n, h, w, c_out;
    reg [31:0] kh, kw, c_in, oh, ow;

    // Misc
    integer loop_i;
    reg [31:0] accumulator;

    // Sequential FSM + outputs (synchronous)
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done  <= 1'b0;
            ready <= 1'b1;

            // reset parsed dims & counters
            N <= 0; H <= 0; W <= 0; C <= 0;
            KH <= 0; KW <= 0; C_IN <= 0; C_OUT <= 0;
            OH <= 0; OW <= 0;
            STRIDE_H <= 0; STRIDE_W <= 0;
            PAD_TOP <= 0; PAD_BOTTOM <= 0; PAD_LEFT <= 0; PAD_RIGHT <= 0;

            n <= 0; h <= 0; w <= 0; c_out <= 0;
            kh <= 0; kw <= 0; c_in <= 0; oh <= 0; ow <= 0;
            accumulator <= 0;
            result <= 0;
        end else begin
            state <= next_state;

            // default outputs
            case (next_state)
                IDLE: begin done <= 1'b0; ready <= 1'b1; end
                DONE_STATE: begin done <= 1'b1; ready <= 1'b1; end
                default: begin done <= 1'b0; ready <= 1'b0; end
            endcase

            // main behavior per state (synchronous updates)
            case (state)
                IDLE: begin
                    // parse packed dims on IDLE entry (non-critical timing)
                    N <= input_dims[31:24];
                    H <= input_dims[23:16];
                    W <= input_dims[15:8];
                    C <= input_dims[7:0];

                    KH <= filter_dims[31:24];
                    KW <= filter_dims[23:16];
                    C_IN <= filter_dims[15:8];
                    C_OUT <= filter_dims[7:0];

                    OH <= output_dims[23:16];
                    OW <= output_dims[15:8];

                    STRIDE_H <= stride[31:16];
                    STRIDE_W <= stride[15:0];

                    PAD_TOP    <= padding[31:24];
                    PAD_BOTTOM <= padding[23:16];
                    PAD_LEFT   <= padding[15:8];
                    PAD_RIGHT  <= padding[7:0];

                    // reset counters & accumulator for next run
                    n <= 0; h <= 0; w <= 0; c_out <= 0;
                    kh <= 0; kw <= 0; c_in <= 0; oh <= 0; ow <= 0;
                    accumulator <= 0;
                end

                LOAD_INPUT: begin
                    // simple fill (simulation/demo). In real hw use DMA/AXI to fill buffers.
                    for (loop_i = 0; loop_i < 256; loop_i = loop_i + 1) begin
                        input_buffer[loop_i] <= 32'h00000001;
                    end
                end

                LOAD_FILTER: begin
                    for (loop_i = 0; loop_i < 256; loop_i = loop_i + 1) begin
                        filter_buffer[loop_i] <= 32'h00000001;
                    end
                end

                COMPUTE: begin
                    // A toy MAC engine: reads index 0 for simplicity. Replace with proper indexing later.
                    if (c_out < C_OUT) begin
                        // perform one MAC per cycle
                        accumulator <= accumulator + (input_buffer[0] * filter_buffer[0]);

                        // increment internal kernel/c_in/ouput position counters (toy update)
                        kw <= kw + 1;
                        if (kw >= KW) begin
                            kw <= 0;
                            kh <= kh + 1;
                            if (kh >= KH) begin
                                kh <= 0;
                                c_in <= c_in + 1;
                                if (c_in >= C_IN) begin
                                    c_in <= 0;
                                    ow <= ow + 1;
                                    if (ow >= OW) begin
                                        ow <= 0;
                                        oh <= oh + 1;
                                        if (oh >= OH) begin
                                            oh <= 0;
                                            c_out <= c_out + 1;
                                            // store the completed accumulator for this output channel
                                            output_buffer[c_out] <= accumulator;
                                            accumulator <= 0;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                STORE_OUTPUT: begin
                    // place a single result on the result port (example)
                    result <= output_buffer[c_out];
                end

                DONE_STATE: begin
                    // idle-like; outputs handled above
                end

                default: begin end
            endcase
        end
    end

    // Combinational next-state logic (clean, no latches)
    always @(*) begin
        next_state = state; // default
        case (state)
            IDLE:         next_state = start ? LOAD_INPUT   : IDLE;
            LOAD_INPUT:   next_state = LOAD_FILTER;
            LOAD_FILTER:  next_state = COMPUTE;
            COMPUTE:      // when done computing all output channels move to STORE_OUTPUT
                next_state = (c_out >= C_OUT) ? STORE_OUTPUT : COMPUTE;
            STORE_OUTPUT: next_state = DONE_STATE;
            DONE_STATE:   next_state = IDLE;
            default:      next_state = IDLE;
        endcase
    end

endmodule
