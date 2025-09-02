module memory_interface (
    input clk,
    input rst_n,
    input [31:0] address,
    input [31:0] write_data,
    input we,
    input re,
    output reg [31:0] read_data,
    output reg ready
);

    // Modelo simples de memória com inicialização
    reg [31:0] memory [0:1023]; // 1KB de memória para simulação
    
    // Inicialização da memória com valores padrão
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] = 32'h00000000;
        end
    end

    // Leitura de dados
    always @(posedge clk) begin
        if (!rst_n) begin
            read_data <= 32'h00000000;
            ready <= 1'b0;
        end else begin
            if (re) begin
                read_data <= memory[address[11:2]]; // Acessando words de 32 bits
                ready <= 1'b1;
            end else if (we) begin
                memory[address[11:2]] <= write_data;
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end
        end
    end

endmodule