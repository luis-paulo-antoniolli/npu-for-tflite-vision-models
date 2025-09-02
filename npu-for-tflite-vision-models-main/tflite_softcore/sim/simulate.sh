#!/bin/bash
# Script para sintetizar o projeto com Icarus Verilog

# Compilar todos os módulos
echo "Compilando módulos..."
iverilog -o tflite_softcore ../src/*.v ../src/miaow-master/src/*.v

# Verificar se a compilação foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Compilação concluída com sucesso!"
    echo "Arquivo gerado: tflite_softcore"
    
    # Executar a simulação
    echo "Executando simulação..."
    vvp tflite_softcore
    
    # Verificar se a simulação foi bem-sucedida
    if [ $? -eq 0 ]; then
        echo "Simulação concluída com sucesso!"
    else
        echo "Erro na simulação!"
        exit 1
    fi
else
    echo "Erro na compilação!"
    exit 1
fi