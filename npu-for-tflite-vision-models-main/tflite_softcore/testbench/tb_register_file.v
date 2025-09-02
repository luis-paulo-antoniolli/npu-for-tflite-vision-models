`timescale 1ns / 1ps

module tb_register_file;

    // Sinais de entrada
    reg clk;
    reg rst_n;
    reg [4:0] rd_addr;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [31:0] rd_data;
    reg we;
    
    // Sinais de saída
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    
    // Instanciação do módulo Register File
    register_file uut (
        .clk(clk),
        .rst_n(rst_n),
        .rd_addr(rd_addr),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_data(rd_data),
        .we(we),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );
    
    // Geração de clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Processo de teste
    initial begin
        // Inicialização
        $display("Iniciando testbench do Register File");
        rst_n = 0;
        we = 0;
        rd_addr = 5'b00000;
        rs1_addr = 5'b00000;
        rs2_addr = 5'b00000;
        rd_data = 32'h00000000;
        
        // Reset
        #10;
        rst_n = 1;
        #10;
        
        // Teste de escrita e leitura
        $display("Testando escrita e leitura...");
        
        // Escrever no registrador 1
        we = 1;
        rd_addr = 5'd1;
        rd_data = 32'h12345678;
        #10;
        we = 0;
        
        // Ler do registrador 1
        rs1_addr = 5'd1;
        #10;
        if (rs1_data !== 32'h12345678) $display("Erro na leitura do registrador 1: Esperado 12345678, obtido %h", rs1_data);
        else $display("Leitura do registrador 1: OK");
        
        // Escrever no registrador 2
        we = 1;
        rd_addr = 5'd2;
        rd_data = 32'h87654321;
        #10;
        we = 0;
        
        // Ler dos registradores 1 e 2
        rs1_addr = 5'd1;
        rs2_addr = 5'd2;
        #10;
        if (rs1_data !== 32'h12345678) $display("Erro na leitura do registrador 1: Esperado 12345678, obtido %h", rs1_data);
        else $display("Leitura do registrador 1: OK");
        
        if (rs2_data !== 32'h87654321) $display("Erro na leitura do registrador 2: Esperado 87654321, obtido %h", rs2_data);
        else $display("Leitura do registrador 2: OK");
        
        // Teste de escrita no registrador 0 (deve ser ignorada)
        $display("Testando escrita no registrador 0...");
        we = 1;
        rd_addr = 5'd0;
        rd_data = 32'hDEADBEEF;
        #10;
        we = 0;
        
        // Tentar ler do registrador 0
        rs1_addr = 5'd0;
        #10;
        if (rs1_data !== 32'h00000000) $display("Erro na leitura do registrador 0: Esperado 00000000, obtido %h", rs1_data);
        else $display("Leitura do registrador 0 (sempre zero): OK");
        
        $display("Testbench do Register File concluído");
        $finish;
    end

endmodule