module control_unit (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [3:0] alu_op,
    output reg [1:0] imm_sel,
    output reg pc_sel,
    output reg [1:0] reg_we,
    output reg alu_a_sel,
    output reg alu_b_sel,
    output reg mem_we,
    output reg [1:0] wb_sel
);

    always @(*) begin
        // Default values
        alu_op = 4'b0000;
        imm_sel = 2'b00;
        pc_sel = 1'b0;
        reg_we = 2'b00;
        alu_a_sel = 1'b0;
        alu_b_sel = 1'b0;
        mem_we = 1'b0;
        wb_sel = 2'b00;

        case(opcode)
            7'b0000000: begin // CUSTOM instruction for NPU
                reg_we = 2'b01;
                alu_a_sel = 1'b0;
                alu_b_sel = 1'b0;
                wb_sel = 2'b11; // Special writeback for NPU result
                alu_op = 4'b1111; // Special ALU operation for NPU
            end
            
            7'b0110011: begin // R-type (ADD, SUB, AND, OR, XOR, etc.)
                reg_we = 2'b01;
                alu_a_sel = 1'b0;
                alu_b_sel = 1'b0;
                wb_sel = 2'b00;
                
                case({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_op = 4'b0000; // ADD
                    {7'b0100000, 3'b000}: alu_op = 4'b0001; // SUB
                    {7'b0000000, 3'b111}: alu_op = 4'b0010; // AND
                    {7'b0000000, 3'b110}: alu_op = 4'b0011; // OR
                    {7'b0000000, 3'b100}: alu_op = 4'b0100; // XOR
                    {7'b0000000, 3'b001}: alu_op = 4'b0110; // SLL
                    {7'b0000000, 3'b101}: alu_op = 4'b0111; // SRL
                    {7'b0100000, 3'b101}: alu_op = 4'b1000; // SRA
                    {7'b0000000, 3'b010}: alu_op = 4'b1001; // SLT
                    {7'b0000001, 3'b000}: alu_op = 4'b1010; // MUL
                    default: alu_op = 4'b0000;
                endcase
            end
            
            7'b0010011: begin // I-type (ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI)
                reg_we = 2'b01;
                alu_a_sel = 1'b0;
                alu_b_sel = 1'b1;
                imm_sel = 2'b00;
                wb_sel = 2'b00;
                
                case(funct3)
                    3'b000: alu_op = 4'b0000; // ADDI
                    3'b111: alu_op = 4'b0010; // ANDI
                    3'b110: alu_op = 4'b0011; // ORI
                    3'b100: alu_op = 4'b0100; // XORI
                    3'b001: alu_op = 4'b0110; // SLLI
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            alu_op = 4'b0111; // SRLI
                        else if (funct7 == 7'b0100000)
                            alu_op = 4'b1000; // SRAI
                    end
                    3'b010: alu_op = 4'b1001; // SLTI
                    default: alu_op = 4'b0000;
                endcase
            end
            
            7'b0000011: begin // Load (LW)
                reg_we = 2'b10;
                alu_a_sel = 1'b0;
                alu_b_sel = 1'b1;
                imm_sel = 2'b00;
                wb_sel = 2'b01;
                alu_op = 4'b0000; // ADD
            end
            
            7'b0100011: begin // Store (SW)
                reg_we = 2'b00;
                alu_a_sel = 1'b0;
                alu_b_sel = 1'b1;
                imm_sel = 2'b01;
                mem_we = 1'b1;
                alu_op = 4'b0000; // ADD
            end
            
            7'b1100011: begin // Branch (BEQ, BNE)
                reg_we = 2'b00;
                alu_a_sel = 1'b0;
                alu_b_sel = 1'b0;
                imm_sel = 2'b10;
                wb_sel = 2'b00;
                
                case(funct3)
                    3'b000: alu_op = 4'b0000; // BEQ - Using ADD to check if (a-b)=0
                    3'b001: alu_op = 4'b0001; // BNE - Using SUB to check if (a-b)!=0
                    default: alu_op = 4'b0000;
                endcase
            end
            
            7'b1101111: begin // JAL
                reg_we = 2'b01;
                pc_sel = 1'b1;
                wb_sel = 2'b10;
            end
            
            7'b1100111: begin // JALR
                reg_we = 2'b01;
                alu_a_sel = 1'b0;
                alu_b_sel = 1'b1;
                imm_sel = 2'b00;
                wb_sel = 2'b10;
                alu_op = 4'b0000; // ADD
            end
            
            default: begin
                reg_we = 2'b00;
            end
        endcase
    end

endmodule