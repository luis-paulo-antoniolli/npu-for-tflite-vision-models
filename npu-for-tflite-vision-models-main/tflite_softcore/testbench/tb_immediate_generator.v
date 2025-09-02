`timescale 1ns / 1ps

module tb_immediate_generator;

    // Sinais de entrada
    reg [31:0] instruction;
    reg [1:0] imm_sel;
    
    // Sinais de saída
    wire [31:0] immediate;
    
    // Instanciação do módulo Immediate Generator
    immediate_generator uut (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .immediate(immediate)
    );
    
    // Processo de teste
    initial begin
        // Inicialização
        $display("Iniciando testbench do Immediate Generator");
        
        // Teste de imediato I-type
        $display("Testando imediato I-type...");
        instruction = 32'b00000000000000001000000010010011; // addi x1, x0, 8
        imm_sel = 2'b00;
        #10;
        if (immediate !== 32'h00000008) $display("Erro em I-type: Esperado 00000008, obtido %h", immediate);
        else $display("I-type: OK");
        
        // Teste de imediato S-type
        $display("Testando imediato S-type...");
        instruction = 32'b00000000001000001010000000100011; // sw x2, 8(x1)
        imm_sel = 2'b01;
        #10;
        if (immediate !== 32'h00000008) $display("Erro em S-type: Esperado 00000008, obtido %h", immediate);
        else $display("S-type: OK");
        
        // Teste de imediato B-type
        $display("Testando imediato B-type...");
        instruction = 32'b00000000001000001000000011100011; // beq x1, x2, 8
        imm_sel = 2'b10;
        #10;
        if (immediate !== 32'h00000008) $display("Erro em B-type: Esperado 00000008, obtido %h", immediate);
        else $display("B-type: OK");
        
        // Teste de imediato U-type (LUI)
        $display("Testando imediato U-type (LUI)...");
        instruction = 32'b00000000000000000000000010110111; // lui x1, 0
        imm_sel = 2'b11;
        #10;
        if (immediate !== 32'h00000000) $display("Erro em U-type (LUI): Esperado 00000000, obtido %h", immediate);
        else $display("U-type (LUI): OK");
        
        // Teste de imediato J-type (JAL)
        $display("Testando imediato J-type (JAL)...");
        instruction = 32'b00000000000000000000000011101111; // jal x1, 0
        imm_sel = 2'b11;
        #10;
        if (immediate !== 32'h00000000) $display("Erro em J-type (JAL): Esperado 00000000, obtido %h", immediate);
        else $display("J-type (JAL): OK");
        
        $display("Testbench do Immediate Generator concluído");
        $finish;
    end

endmodule