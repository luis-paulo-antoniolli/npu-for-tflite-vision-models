module immediate_generator (
    input [31:0] instruction,
    input [1:0] imm_sel,
    output reg [31:0] immediate
);

    always @(*) begin
        case(imm_sel)
            2'b00: begin // I-type
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            2'b01: begin // S-type
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            2'b10: begin // B-type
                immediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end
            2'b11: begin // U-type (LUI/AUIPC) or J-type (JAL)
                if (instruction[6:0] == 7'b0110111 || instruction[6:0] == 7'b0010111) begin
                    // U-type
                    immediate = {instruction[31:12], 12'h000};
                end else begin
                    // J-type
                    immediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                end
            end
        endcase
    end

endmodule