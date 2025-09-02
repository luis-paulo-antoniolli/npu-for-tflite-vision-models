#!/bin/bash
# Script para simular o design com Icarus Verilog

# Verificar se Icarus Verilog está instalado
if ! command -v iverilog >/dev/null 2>&1; then
    echo "Erro: Icarus Verilog não encontrado!"
    echo "Por favor, instale com: sudo apt-get install iverilog"
    exit 1
fi

# Compilar o design
echo "Compilando o design..."
iverilog -o tflite_softcore_tb \
    ../testbench/tb_tflite_softcore.v \
    ../src/tflite_softcore.v \
    ../src/control_unit.v \
    ../src/immediate_generator.v \
    ../src/alu.v \
    ../src/npu_top.v \
    ../src/conv2d_accelerator.v \
    ../src/fully_connected_accelerator.v \
    ../src/dwconv2d_unit.v \
    ../src/matadd_unit.v

# Verificar se a compilação foi bem-sucedida
if [ $? -ne 0 ]; then
    echo "Erro na compilação!"
    exit 1
fi

# Executar a simulação
echo "Executando simulação..."
vvp tflite_softcore_tb

# Verificar se a simulação foi bem-sucedida
if [ $? -ne 0 ]; then
    echo "Erro na simulação!"
    exit 1
fi

echo "Simulação concluída com sucesso!"

# Gerar arquivo VCD se o testebench gerou um
if [ -f "tflite_softcore_tb.vcd" ]; then
    echo "Arquivo VCD gerado: tflite_softcore_tb.vcd"
fi