# Script para verificar o design com Yosys

# Ler todos os arquivos Verilog
read_verilog -sv ../src/tflite_softcore.v
read_verilog -sv ../src/control_unit.v
read_verilog -sv ../src/immediate_generator.v
read_verilog -sv ../src/alu.v
read_verilog -sv ../src/npu_top.v
read_verilog -sv ../src/conv2d_accelerator.v
read_verilog -sv ../src/fully_connected_accelerator.v
read_verilog -sv ../src/dwconv2d_unit.v
read_verilog -sv ../src/matadd_unit.v

# Verificar o design
hierarchy -check -top tflite_softcore

# Verificar sintaxe
proc
opt
fsm
opt
memory
opt

# Verificar estatísticas
stat

# Verificar timing
check

echo "Verificação concluída com Yosys!"