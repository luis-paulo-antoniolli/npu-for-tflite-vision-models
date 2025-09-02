#!/bin/bash
# Script para verificar o design com Verilator

# Verificar se Verilator está instalado
if ! command -v verilator >/dev/null 2>&1; then
    echo "Erro: Verilator não encontrado!"
    echo "Por favor, instale o Verilator"
    exit 1
fi

# Criar diretório de build
mkdir -p build
cd build

# Executar Verilator para verificar o design
echo "Verificando design com Verilator..."
verilator --lint-only \
    -I../src \
    -I../src/miaow-master/src \
    ../src/tflite_softcore.v \
    ../src/control_unit.v \
    ../src/immediate_generator.v \
    ../src/alu.v \
    ../src/npu_top.v \
    ../src/conv2d_accelerator.v \
    ../src/fully_connected_accelerator.v \
    ../src/dwconv2d_unit.v \
    ../src/matadd_unit.v \
    ../src/miaow-master/src/tflite_softcore.v

# Verificar se a verificação foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Verificação concluída com sucesso!"
    echo "Nenhum erro encontrado no design"
else
    echo "Erros encontrados na verificação!"
    exit 1
fi