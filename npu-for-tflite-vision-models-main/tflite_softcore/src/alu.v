module alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0] op,
    output [31:0] result,
    output zero
);

    reg [31:0] result_reg;
    reg zero_reg;

    always @(*) begin
        case(op)
            4'b0000: result_reg = a + b;         // ADD
            4'b0001: result_reg = a - b;         // SUB
            4'b0010: result_reg = a & b;         // AND
            4'b0011: result_reg = a | b;         // OR
            4'b0100: result_reg = a ^ b;         // XOR
            4'b0101: result_reg = ~a;            // NOT
            4'b0110: result_reg = a << b[4:0];   // SLL
            4'b0111: result_reg = a >> b[4:0];   // SRL
            4'b1000: result_reg = $signed(a) >>> b[4:0]; // SRA
            4'b1001: result_reg = (a < b) ? 32'h1 : 32'h0; // SLT
            4'b1010: result_reg = a * b;         // MUL (simplified)
            4'b1111: result_reg = a + b;         // CUSTOM: Placeholder for NPU operation
            default: result_reg = 32'h00000000;
        endcase
    end

    // Calcular flag zero
    always @(*) begin
        zero_reg = (result_reg == 32'h00000000);
    end

    assign result = result_reg;
    assign zero = zero_reg;

endmodule