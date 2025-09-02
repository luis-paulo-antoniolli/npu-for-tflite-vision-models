`timescale 1ns / 1ps

module tb_alu;

    // Sinais de entrada
    reg [31:0] a;
    reg [31:0] b;
    reg [3:0] op;
    
    // Sinais de saída
    wire [31:0] result;
    wire zero;
    
    // Instanciação do módulo ALU
    alu uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero)
    );
    
    // Processo de teste
    initial begin
        // Inicialização
        $display("Iniciando testbench da ALU");
        
        // Teste de operações básicas
        $display("Testando operações básicas...");
        
        // ADD
        a = 32'h00000005;
        b = 32'h00000003;
        op = 4'b0000; // ADD
        #10;
        if (result !== 32'h00000008) $display("Erro em ADD: Esperado 8, obtido %h", result);
        else $display("ADD: OK");
        
        // SUB
        a = 32'h00000005;
        b = 32'h00000003;
        op = 4'b0001; // SUB
        #10;
        if (result !== 32'h00000002) $display("Erro em SUB: Esperado 2, obtido %h", result);
        else $display("SUB: OK");
        
        // AND
        a = 32'h0000000A;
        b = 32'h00000003;
        op = 4'b0010; // AND
        #10;
        if (result !== 32'h00000002) $display("Erro em AND: Esperado 2, obtido %h", result);
        else $display("AND: OK");
        
        // OR
        a = 32'h0000000A;
        b = 32'h00000003;
        op = 4'b0011; // OR
        #10;
        if (result !== 32'h0000000B) $display("Erro em OR: Esperado B, obtido %h", result);
        else $display("OR: OK");
        
        // XOR
        a = 32'h0000000A;
        b = 32'h00000003;
        op = 4'b0100; // XOR
        #10;
        if (result !== 32'h00000009) $display("Erro em XOR: Esperado 9, obtido %h", result);
        else $display("XOR: OK");
        
        // NOT
        a = 32'h0000000A;
        b = 32'h00000000;
        op = 4'b0101; // NOT
        #10;
        if (result !== 32'hFFFFFFF5) $display("Erro em NOT: Esperado FFFFFFF5, obtido %h", result);
        else $display("NOT: OK");
        
        // SLT
        a = 32'h00000003;
        b = 32'h00000005;
        op = 4'b1001; // SLT
        #10;
        if (result !== 32'h00000001) $display("Erro em SLT: Esperado 1, obtido %h", result);
        else $display("SLT: OK");
        
        // MUL
        a = 32'h00000005;
        b = 32'h00000003;
        op = 4'b1010; // MUL
        #10;
        if (result !== 32'h0000000F) $display("Erro em MUL: Esperado F, obtido %h", result);
        else $display("MUL: OK");
        
        // Teste do flag zero
        $display("Testando flag zero...");
        a = 32'h00000005;
        b = 32'h00000005;
        op = 4'b0001; // SUB
        #10;
        if (zero !== 1'b1) $display("Erro no flag zero: Esperado 1, obtido %b", zero);
        else $display("Flag zero: OK");
        
        $display("Testbench da ALU concluído");
        $finish;
    end

endmodule