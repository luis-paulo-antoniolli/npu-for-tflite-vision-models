`timescale 1ns / 1ps

module tb_control_unit;

    // Sinais de entrada
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    
    // Sinais de saída
    wire [3:0] alu_op;
    wire [1:0] imm_sel;
    wire pc_sel;
    wire [1:0] reg_we;
    wire alu_a_sel;
    wire alu_b_sel;
    wire mem_we;
    wire [1:0] wb_sel;
    
    // Instanciação do módulo Control Unit
    control_unit uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_op),
        .imm_sel(imm_sel),
        .pc_sel(pc_sel),
        .reg_we(reg_we),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        .mem_we(mem_we),
        .wb_sel(wb_sel)
    );
    
    // Processo de teste
    initial begin
        // Inicialização
        $display("Iniciando testbench da Control Unit");
        
        // Teste de instrução R-type (ADD)
        $display("Testando instrução R-type (ADD)...");
        opcode = 7'b0110011;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #10;
        if (alu_op !== 4'b0000) $display("Erro em ADD: alu_op incorreto %b", alu_op);
        else if (reg_we !== 2'b01) $display("Erro em ADD: reg_we incorreto %b", reg_we);
        else $display("ADD: OK");
        
        // Teste de instrução I-type (ADDI)
        $display("Testando instrução I-type (ADDI)...");
        opcode = 7'b0010011;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #10;
        if (alu_op !== 4'b0000) $display("Erro em ADDI: alu_op incorreto %b", alu_op);
        else if (reg_we !== 2'b01) $display("Erro em ADDI: reg_we incorreto %b", reg_we);
        else if (alu_b_sel !== 1'b1) $display("Erro em ADDI: alu_b_sel incorreto %b", alu_b_sel);
        else $display("ADDI: OK");
        
        // Teste de instrução Load (LW)
        $display("Testando instrução Load (LW)...");
        opcode = 7'b0000011;
        funct3 = 3'b010;
        funct7 = 7'b0000000;
        #10;
        if (reg_we !== 2'b10) $display("Erro em LW: reg_we incorreto %b", reg_we);
        else if (wb_sel !== 2'b01) $display("Erro em LW: wb_sel incorreto %b", wb_sel);
        else $display("LW: OK");
        
        // Teste de instrução Store (SW)
        $display("Testando instrução Store (SW)...");
        opcode = 7'b0100011;
        funct3 = 3'b010;
        funct7 = 7'b0000000;
        #10;
        if (mem_we !== 1'b1) $display("Erro em SW: mem_we incorreto %b", mem_we);
        else $display("SW: OK");
        
        // Teste de instrução Branch (BEQ)
        $display("Testando instrução Branch (BEQ)...");
        opcode = 7'b1100011;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #10;
        if (alu_op !== 4'b0000) $display("Erro em BEQ: alu_op incorreto %b", alu_op);
        else $display("BEQ: OK");
        
        // Teste de instrução JAL
        $display("Testando instrução JAL...");
        opcode = 7'b1101111;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #10;
        if (pc_sel !== 1'b1) $display("Erro em JAL: pc_sel incorreto %b", pc_sel);
        else if (reg_we !== 2'b01) $display("Erro em JAL: reg_we incorreto %b", reg_we);
        else if (wb_sel !== 2'b10) $display("Erro em JAL: wb_sel incorreto %b", wb_sel);
        else $display("JAL: OK");
        
        $display("Testbench da Control Unit concluído");
        $finish;
    end

endmodule