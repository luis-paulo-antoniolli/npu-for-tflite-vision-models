# Script para análise de cobertura com Icarus Verilog

# Compilar com opções de cobertura
echo "Compilando com opções de cobertura..."
iverilog -o tflite_softcore_cov -s tb_tflite_softcore \
    -c ../src/tflite_softcore.v \
    -c ../src/control_unit.v \
    -c ../src/immediate_generator.v \
    -c ../src/alu.v \
    -c ../src/npu_top.v \
    -c ../src/conv2d_accelerator.v \
    -c ../src/fully_connected_accelerator.v \
    -c ../src/dwconv2d_unit.v \
    -c ../src/matadd_unit.v \
    -c ../testbench/tb_tflite_softcore.v \
    -fcoverage

# Executar simulação
echo "Executando simulação com cobertura..."
vvp -n tflite_softcore_cov

# Gerar relatório de cobertura
echo "Gerando relatório de cobertura..."
vcd2fst -f tflite_softcore_cov.vcd tflite_softcore_cov.fst
cover -r tflite_softcore_cov.fst

# Gerar relatório em texto
cover report -o coverage_report.txt

# Gerar relatório em HTML
cover report -o coverage_report.html -format html

echo "Relatórios de cobertura gerados:"
echo "  - coverage_report.txt"
echo "  - coverage_report.html"
echo "  - tflite_softcore_cov.fst"