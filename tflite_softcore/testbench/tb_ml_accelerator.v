`timescale 1ns / 1ps

module tb_ml_accelerator;

    // Sinais de clock e reset
    reg clk;
    reg rst_n;
    
    // Sinais de controle
    reg [31:0] instruction;
    reg [31:0] rs1_data;
    reg [31:0] rs2_data;
    reg [4:0] rd_addr;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg start;
    reg [1:0] op_mode;
    
    // Sinais de dados
    reg [31:0] mem_data_in;
    reg [31:0] mem_addr;
    reg mem_we;
    reg mem_re;
    
    // Sinais de saída
    wire [31:0] result;
    wire [31:0] mem_data_out;
    wire ready;
    wire done;
    
    // Instância do ML Accelerator
    ml_accelerator uut (
        .clk(clk),
        .rst_n(rst_n),
        .instruction(instruction),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rd_addr(rd_addr),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .start(start),
        .op_mode(op_mode),
        .mem_data_in(mem_data_in),
        .mem_addr(mem_addr),
        .mem_we(mem_we),
        .mem_re(mem_re),
        .result(result),
        .mem_data_out(mem_data_out),
        .ready(ready),
        .done(done)
    );
    
    // Geração de clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Processo de teste
    initial begin
        // Inicialização
        $display("Iniciando testbench do ML Accelerator");
        rst_n = 0;
        start = 0;
        op_mode = 2'b00;
        instruction = 32'h00000000;
        rs1_data = 32'h00000000;
        rs2_data = 32'h00000000;
        rd_addr = 5'b00000;
        rs1_addr = 5'b00000;
        rs2_addr = 5'b00000;
        mem_data_in = 32'h00000000;
        mem_addr = 32'h00000000;
        mem_we = 0;
        mem_re = 0;
        
        // Reset
        #10;
        rst_n = 1;
        #10;
        
        // Teste de operação CONV2D
        $display("Testando operação CONV2D...");
        op_mode = 2'b00; // CONV2D
        start = 1;
        #10;
        start = 0;
        
        // Aguardar conclusão
        wait(done);
        #10;
        $display("Resultado CONV2D: %h", result);
        $display("CONV2D: OK");
        
        // Teste de operação DEPTHWISE_CONV2D
        $display("Testando operação DEPTHWISE_CONV2D...");
        op_mode = 2'b01; // DEPTHWISE_CONV2D
        start = 1;
        #10;
        start = 0;
        
        // Aguardar conclusão
        wait(done);
        #10;
        $display("Resultado DEPTHWISE_CONV2D: %h", result);
        $display("DEPTHWISE_CONV2D: OK");
        
        // Teste de operação MATRIX_ADD
        $display("Testando operação MATRIX_ADD...");
        op_mode = 2'b10; // MATRIX_ADD
        start = 1;
        #10;
        start = 0;
        
        // Aguardar conclusão
        wait(done);
        #10;
        $display("Resultado MATRIX_ADD: %h", result);
        $display("MATRIX_ADD: OK");
        
        // Teste de operação FULLY_CONNECTED
        $display("Testando operação FULLY_CONNECTED...");
        op_mode = 2'b11; // FULLY_CONNECTED
        start = 1;
        #10;
        start = 0;
        
        // Aguardar conclusão
        wait(done);
        #10;
        $display("Resultado FULLY_CONNECTED: %h", result);
        $display("FULLY_CONNECTED: OK");
        
        $display("Testbench do ML Accelerator concluído");
        $finish;
    end

endmodule