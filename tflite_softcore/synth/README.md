# Diretrizes para Síntese do Softcore TensorFlow Lite

Este documento descreve como sintetizar o softcore TensorFlow Lite para FPGAs utilizando ferramentas comerciais como Xilinx Vivado ou Intel Quartus.

## Pré-requisitos

1. Código-fonte do softcore (arquivos em `src/`)
2. Ferramenta de síntese (Xilinx Vivado, Intel Quartus, etc.)
3. FPGA alvo com recursos suficientes (ver seção de requisitos)

## Requisitos de Hardware

### Recursos Mínimos Recomendados

- **LUTs**: ~5000-10000
- **FFs**: ~2000-4000
- **BRAMs**: 10-20 (dependendo do tamanho do modelo TFLite)
- **DSPs**: 4-8 (para operações MAC otimizadas)
- **Pinos de I/O**: 50-100

### FPGA Alvos Testados

- Xilinx Artix-7 (XC7A35TICSG324-1L)
- Intel Cyclone IV (EP4CE30F23C7)

## Scripts de Síntese

### Xilinx Vivado

1. Criar novo projeto no Vivado
2. Adicionar os arquivos de `src/` ao projeto
3. Definir `tflite_softcore` como módulo top-level
4. Configurar as constraints (arquivo .xdc) para o FPGA alvo
5. Executar a síntese e implementação

Exemplo de arquivo de constraints (.xdc):
```
# Clock
create_clock -period 20.000 -name clk [get_ports clk]

# Reset
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
```

### Intel Quartus

1. Criar novo projeto no Quartus
2. Adicionar os arquivos de `src/` ao projeto
3. Definir `tflite_softcore` como módulo top-level
4. Configurar as constraints (arquivo .qsf) para o FPGA alvo
5. Executar a síntese e implementação

## Otimizações para FPGAs

1. **Uso Eficiente de DSPs**: A ALU inclui uma operação de multiplicação que pode utilizar blocos DSP da FPGA.

2. **Hierarquia de Memória**: A interface de memória pode ser conectada a diferentes tipos de memória (BRAM, DDR, etc.) dependendo da aplicação.

3. **Pipelining**: O softcore usa um pipeline simples de 3 estágios que pode ser otimizado com retiming.

4. **Clock Gating**: Em implementações futuras, pode-se adicionar clock gating para reduzir o consumo de energia.

## Análise de Recursos e Timing

Após a síntese, analise os relatórios gerados pela ferramenta:

1. **Relatório de Utilização**: Verifique se os recursos da FPGA estão dentro dos limites.
2. **Relatório de Timing**: Verifique se o caminho crítico atende às restrições de timing.
3. **Relatório de Potência**: Avalie o consumo de potência da implementação.

## Integração com Sistema Externo

O softcore pode ser integrado com outros módulos do sistema através da interface de memória:

- Conexão com memória externa (DDR, SRAM)
- Interface com controladores de periféricos
- Conexão com aceleradores de hardware dedicados

## Considerações Finais

- A frequência máxima de operação dependerá do FPGA alvo e das constraints definidas.
- O desempenho pode ser melhorado com otimizações específicas para a aplicação TFLite.
- Testes extensivos são recomendados após a síntese para garantir o funcionamento correto.