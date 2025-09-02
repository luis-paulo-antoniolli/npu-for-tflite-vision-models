#!/bin/bash
# Script para sintetizar o projeto com Vivado

# Verificar se Vivado está instalado
if ! command -v vivado >/dev/null 2>&1; then
    echo "Erro: Vivado não encontrado!"
    echo "Por favor, instale o Xilinx Vivado 2024.2 ou superior"
    exit 1
fi

# Navegar para o diretório de síntese
cd synth

# Executar script de síntese
echo "Iniciando síntese com Vivado..."
vivado -mode batch -source tflite_softcore.tcl

# Verificar se a síntese foi bem-sucedida
if [ -f "tflite_softcore.bit" ]; then
    echo "Síntese concluída com sucesso!"
    echo "Bitstream gerado: tflite_softcore.bit"
    
    # Copiar relatórios para diretório principal
    cp synth_utilization.rpt ../
    cp synth_timing.rpt ../
    cp impl_utilization.rpt ../
    cp impl_timing.rpt ../
    cp impl_power.rpt ../
    cp impl_drc.rpt ../
    cp tflite_softcore.bit ../
    
    echo "Relatórios copiados para o diretório principal"
else
    echo "Erro na síntese!"
    exit 1
fi