# Testbench para o Softcore TensorFlow Lite

Este diretório contém os testbenches para os módulos do softcore.

## Estrutura

- `tb_alu.v`: Testbench para a Unidade Lógica Aritmética
- `tb_register_file.v`: Testbench para o Banco de Registradores
- `tb_control_unit.v`: Testbench para a Unidade de Controle
- `tb_immediate_generator.v`: Testbench para o Gerador de Imediatos
- `tb_memory_interface.v`: Testbench para a Interface de Memória
- `tb_tflite_softcore.v`: Testbench completo para o softcore

## Como Executar os Testbenches

1. Utilize um simulador Verilog como ModelSim, Vivado Simulator ou Icarus Verilog
2. Compile o módulo e seu respectivo testbench
3. Execute a simulação e verifique as formas de onda

Exemplo com Icarus Verilog:
```bash
# Compilar
iverilog -o tb_alu tb_alu.v ../src/alu.v
# Executar
vvp tb_alu
```

Para visualizar as formas de onda:
```bash
# Gerar arquivo VCD
iverilog -o tb_alu tb_alu.v ../src/alu.v
vvp tb_alu
# Visualizar com GTKWave
gtkwave tb_alu.vcd
```