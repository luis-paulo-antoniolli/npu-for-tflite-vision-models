# Diretrizes para Síntese do TFLite Softcore

Este diretório contém scripts e arquivos necessários para sintetizar o projeto TFLite Softcore para FPGAs Xilinx.

## Pré-requisitos

1. Xilinx Vivado 2024.2 ou superior
2. FPGA XCKU5P-FFVB676-2-I (ou compatível)
3. Todos os arquivos Verilog do projeto

## Scripts Disponíveis

### 1. tflite_softcore.tcl
Script principal para sintetizar o projeto com Vivado. Inclui:
- Criação do projeto
- Adição de arquivos fonte
- Configuração de constraints
- Síntese e implementação
- Geração de bitstream

### 2. run_synth.bat
Script para executar a síntese completa com Vivado no Windows.

### 3. synth_yosys.tcl
Script para sintetizar o projeto com Yosys (ferramenta open-source).

## Como Executar a Síntese

### Com Vivado (Recomendado)

1. Abra o Vivado Tcl Console
2. Navegue até este diretório (`cd synth`)
3. Execute: `source tflite_softcore.tcl`

Ou execute o script batch:
```
cd synth
run_synth.bat
```

### Com Yosys (Alternativa open-source)

1. Instale o Yosys
2. Navegue até este diretório
3. Execute: `yosys synth_yosys.tcl`

## Arquivos Gerados

Após a síntese bem-sucedida, os seguintes arquivos serão gerados:

- `tflite_softcore.bit` - Bitstream para programar a FPGA
- `synth_utilization.rpt` - Relatório de utilização de recursos
- `synth_timing.rpt` - Relatório de timing da síntese
- `impl_utilization.rpt` - Relatório de utilização de recursos da implementação
- `impl_timing.rpt` - Relatório de timing da implementação
- `impl_power.rpt` - Relatório de consumo de energia
- `impl_drc.rpt` - Relatório de verificações DRC

## FPGA Alvo

O projeto está otimizado para o FPGA Xilinx Kintex UltraScale+ XCKU5P-FFVB676-2-I com as seguintes características:

- LUTs: 544,320
- FFs: 1,088,640
- DSPs: 1,440
- BRAMs: 2,048
- UltraRAM: 48

## Considerações de Otimização

O script utiliza estratégias de síntese e implementação otimizadas para performance:
- `Flow_PerfOptimized_high` para síntese
- `Performance_Explore` para implementação
- Retiming habilitado
- Otimizações físicas agressivas

## Troubleshooting

### Erros de Síntese
- Verifique se todos os arquivos Verilog estão presentes
- Confirme que o caminho para os arquivos está correto
- Verifique se não há erros de sintaxe nos arquivos

### Erros de Implementação
- Verifique as constraints de timing
- Confirme que o FPGA alvo está correto
- Verifique se há violações de timing

### Problemas com Recursos
- O design pode exceder os recursos disponíveis em FPGAs menores
- Considere otimizar o design ou usar um FPGA maior