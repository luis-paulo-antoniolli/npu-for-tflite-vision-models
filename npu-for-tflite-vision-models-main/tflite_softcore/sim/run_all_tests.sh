#!/bin/bash
# Script para executar todos os testes do projeto

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Testes do TFLite Softcore ===${NC}"

# Verificar se o diretório de testes existe
if [ ! -d "../testbench" ]; then
    echo -e "${RED}Erro: Diretório de testbench não encontrado${NC}"
    exit 1
fi

# Navegar para o diretório de testes
cd ../testbench

# Lista de testbenches
TESTBENCHES=(
    "tb_alu.v"
    "tb_control_unit.v"
    "tb_immediate_generator.v"
    "tb_register_file.v"
    "tb_memory_interface.v"
    "tb_ml_accelerator.v"
    "tb_tflite_softcore.v"
)

# Verificar se Icarus Verilog está instalado
if ! command -v iverilog >/dev/null 2>&1; then
    echo -e "${RED}Erro: Icarus Verilog não encontrado${NC}"
    echo "Por favor, instale com: sudo apt-get install iverilog"
    exit 1
fi

# Verificar se GTKWave está instalado
if ! command -v gtkwave >/dev/null 2>&1; then
    echo -e "${YELLOW}Aviso: GTKWave não encontrado${NC}"
    echo "Instale com: sudo apt-get install gtkwave (opcional)"
fi

# Criar diretório para resultados
mkdir -p ../test_results
cd ../test_results

# Executar cada testbench
for tb in "${TESTBENCHES[@]}"; do
    tb_name=$(basename "$tb" .v)
    echo -e "${YELLOW}Executando teste: $tb_name${NC}"
    
    # Verificar se o arquivo existe
    if [ ! -f "../testbench/$tb" ]; then
        echo -e "${RED}Arquivo não encontrado: $tb${NC}"
        continue
    fi
    
    # Compilar o testbench
    echo "Compilando..."
    iverilog -o "$tb_name" "../testbench/$tb" \
        ../src/alu.v \
        ../src/control_unit.v \
        ../src/immediate_generator.v \
        ../src/register_file.v \
        ../src/memory_interface.v \
        ../src/ml_accelerator.v \
        ../src/tflite_softcore.v \
        ../src/miaow-master/src/tflite_softcore.v \
        2>/dev/null
    
    # Verificar se a compilação foi bem-sucedida
    if [ $? -ne 0 ]; then
        echo -e "${RED}Falha na compilação de $tb_name${NC}"
        continue
    fi
    
    # Verificar se o executável foi criado
    if [ ! -f "$tb_name" ]; then
        echo -e "${RED}Executável não criado: $tb_name${NC}"
        continue
    fi
    
    # Executar o teste
    echo "Executando simulação..."
    timeout 30s vvp "$tb_name" > "${tb_name}_output.log" 2>&1
    
    # Verificar se a simulação foi bem-sucedida
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Teste $tb_name concluído com sucesso${NC}"
        
        # Verificar se há erros no log
        if grep -q "ERROR\|Error\|error" "${tb_name}_output.log"; then
            echo -e "${RED}Erros encontrados no log${NC}"
            grep -i "error" "${tb_name}_output.log"
        else
            echo -e "${GREEN}Nenhum erro encontrado${NC}"
        fi
    else
        echo -e "${RED}Falha na execução de $tb_name${NC}"
        cat "${tb_name}_output.log"
    fi
    
    echo ""
done

# Resumo
echo -e "${BLUE}=== Resumo dos Testes ===${NC}"
echo "Resultados salvos em: ../test_results/"
echo "Logs disponíveis para análise"

echo -e "${GREEN}Testes concluídos!${NC}"