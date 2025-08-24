module register_file (
    input clk,
    input rst_n,
    input [4:0] rd_addr,
    input [4:0] rs1_addr,
    input [4:0] rs2_addr,
    input [31:0] rd_data,
    input we,
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data
);

    reg [31:0] registers [0:31];
    integer i;

    // Initialize registers to zero on reset
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (we && rd_addr != 5'b00000) begin
            registers[rd_addr] <= rd_data;
        end
    end

    // Continuous assignment for reading registers
    always @(*) begin
        rs1_data = (rs1_addr != 5'b00000) ? registers[rs1_addr] : 32'h00000000;
        rs2_data = (rs2_addr != 5'b00000) ? registers[rs2_addr] : 32'h00000000;
    end

endmodule