`timescale 1ns / 1ps

module tb_tflite_softcore;

    // Sinais de entrada
    reg clk;
    reg rst_n;
    
    // Sinais de saída
    wire [31:0] pc;
    wire [31:0] alu_result;
    wire [31:0] write_data;
    wire [31:0] address;
    wire we;
    wire re;
    wire ready;
    
    // Instanciação do módulo TFLite Softcore
    tflite_softcore uut (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc),
        .alu_result(alu_result),
        .write_data(write_data),
        .address(address),
        .we(we),
        .re(re),
        .ready(ready)
    );
    
    // Geração de clock
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Processo de teste
    initial begin
        // Inicialização
        $display("Iniciando testbench do TFLite Softcore");
        rst_n = 0;
        
        // Reset
        #20;
        rst_n = 1;
        #20;
        
        // Executar algumas instruções
        $display("Executando instruções...");
        // O softcore executará as instruções da memória
        // Podemos observar o PC e os resultados
        
        // Aguardar algumas iterações
        repeat(100) @(posedge clk);
        
        $display("PC atual: %h", pc);
        $display("Resultado da ALU: %h", alu_result);
        
        $display("Testbench do TFLite Softcore concluído");
        $finish;
    end

endmodule