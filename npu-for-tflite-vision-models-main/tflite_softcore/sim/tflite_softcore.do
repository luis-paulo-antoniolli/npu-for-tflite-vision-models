# Script de simulação para o TFLite Softcore

# Compilar todos os módulos
vlog ../src/*.v
vlog ../src/miaow-master/src/*.v

# Compilar testbenches
vlog ../testbench/tb_tflite_softcore.v

# Iniciar simulação
vsim -novopt work.tb_tflite_softcore

# Adicionar sinais para visualização
add wave -position insertpoint \\
sim:/tb_tflite_softcore/dut/clk \\
sim:/tb_tflite_softcore/dut/rst_n \\
sim:/tb_tflite_softcore/dut/pc_reg \\
sim:/tb_tflite_softcore/dut/instruction_f \\
sim:/tb_tflite_softcore/dut/state \\
sim:/tb_tflite_softcore/dut/npu_start \\
sim:/tb_tflite_softcore/dut/npu_instruction

# Configurar tempo de simulação
run 1000ns

# Salvar forma de onda
write format wave -window .main_pane.waveform