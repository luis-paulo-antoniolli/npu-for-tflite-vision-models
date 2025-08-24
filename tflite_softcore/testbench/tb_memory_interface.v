`timescale 1ns / 1ps

module tb_memory_interface;

    // Sinais de entrada
    reg clk;
    reg rst_n;
    reg [31:0] address;
    reg [31:0] write_data;
    reg we;
    reg re;
    
    // Sinais de saída
    wire [31:0] read_data;
    wire ready;
    
    // Instanciação do módulo Memory Interface
    memory_interface uut (
        .clk(clk),
        .rst_n(rst_n),
        .address(address),
        .write_data(write_data),
        .we(we),
        .re(re),
        .read_data(read_data),
        .ready(ready)
    );
    
    // Geração de clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Processo de teste
    initial begin
        // Inicialização
        $display("Iniciando testbench da Memory Interface");
        rst_n = 0;
        we = 0;
        re = 0;
        address = 32'h00000000;
        write_data = 32'h00000000;
        
        // Reset
        #10;
        rst_n = 1;
        #10;
        
        // Teste de escrita
        $display("Testando escrita na memória...");
        we = 1;
        address = 32'h00000004;
        write_data = 32'h12345678;
        #10;
        we = 0;
        #10;
        if (!ready) $display("Erro na escrita: ready não está ativo");
        else $display("Escrita: OK");
        
        // Teste de leitura
        $display("Testando leitura da memória...");
        re = 1;
        address = 32'h00000004;
        #10;
        re = 0;
        #10;
        if (!ready) $display("Erro na leitura: ready não está ativo");
        else if (read_data !== 32'h12345678) $display("Erro na leitura: Esperado 12345678, obtido %h", read_data);
        else $display("Leitura: OK");
        
        $display("Testbench da Memory Interface concluído");
        $finish;
    end

endmodule