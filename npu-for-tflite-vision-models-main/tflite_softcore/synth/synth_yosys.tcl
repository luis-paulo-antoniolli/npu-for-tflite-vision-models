# Script para sintetizar o projeto com Yosys
# FPGA: XCKU5P-FFVB676-2-I

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
read_verilog -sv ../src/miaow-master/src/tflite_softcore.v

# Sintetizar para Xilinx
synth_xilinx -top tflite_softcore -family xc7 -abc9

# Mapear para tecnologia
abc -lut 6

# Verificar estatísticas
stat

# Verificar timing
check

# Escrever netlist
write_verilog -noattr tflite_softcore_yosys.v

# Escrever blif (para ABC)
write_blif tflite_softcore.blif

# Escrever JSON (para outras ferramentas)
write_json tflite_softcore.json

echo "Sintetização concluída com Yosys!"
echo "Arquivos gerados:"
echo "  - tflite_softcore_yosys.v"
echo "  - tflite_softcore.blif"
echo "  - tflite_softcore.json"