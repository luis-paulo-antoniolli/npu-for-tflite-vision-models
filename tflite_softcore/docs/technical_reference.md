# Documentação Técnica do Softcore TensorFlow Lite

## Visão Geral

O softcore TensorFlow Lite é um processador RISC-V de 32 bits projetado especificamente para executar modelos de machine learning do TensorFlow Lite em FPGAs com recursos limitados. Ele implementa um subconjunto da ISA RV32I com extensões para operações comuns em redes neurais.

## Arquitetura

### Pipeline

O softcore utiliza um pipeline simples de 3 estágios:

1. **Fetch**: Busca da instrução na memória
2. **Decode**: Decodificação da instrução e leitura dos registradores
3. **Execute**: Execução da operação e escrita do resultado

### Registradores

- 32 registradores de 32 bits (x0-x31)
- x0 é sempre zero (hardwired)
- Banco de registradores de leitura dual-port e escrita single-port

### Conjunto de Instruções (ISA)

Implementa um subconjunto da ISA RV32I:

- **Instruções R-type**: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, MUL
- **Instruções I-type**: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, LW
- **Instruções S-type**: SW
- **Instruções B-type**: BEQ, BNE
- **Instruções J-type**: JAL, JALR

### Unidade Lógica Aritmética (ALU)

A ALU implementa operações básicas de aritmética e lógica:

- Operações aritméticas: ADD, SUB, MUL
- Operações lógicas: AND, OR, XOR
- Operações de shift: SLL, SRL, SRA
- Operações de comparação: SLT

### Interface de Memória

- Interface simples para leitura e escrita na memória
- Suporte a operações de load/store word (LW/SW)
- Conectável a diferentes tipos de memória (BRAM, DDR, etc.)

## Módulos Principais

### 1. `tflite_softcore.v`

Módulo top-level que integra todos os componentes do processador.

**Interfaces:**
- `clk`: Clock principal
- `rst_n`: Reset assíncrono ativo baixo
- `pc`: Contador de programa (saída)
- `alu_result`: Resultado da ALU (saída)
- `write_data`: Dados para escrita na memória (saída)
- `address`: Endereço de memória (saída)
- `we`: Write enable para memória (saída)
- `re`: Read enable para memória (saída)
- `ready`: Sinal de ready da memória (entrada)

### 2. `control_unit.v`

Unidade de controle que decodifica as instruções e gera os sinais de controle.

**Sinais de controle gerados:**
- `alu_op`: Operação da ALU
- `imm_sel`: Seleção do tipo de imediato
- `pc_sel`: Seleção do próximo PC
- `reg_we`: Write enable do banco de registradores
- `alu_a_sel`, `alu_b_sel`: Seleção das entradas da ALU
- `mem_we`: Write enable da memória
- `wb_sel`: Seleção dos dados para escrita no registrador

### 3. `register_file.v`

Banco de 32 registradores de 32 bits.

**Interfaces:**
- `clk`: Clock
- `rst_n`: Reset
- `rd_addr`: Endereço do registrador de destino
- `rs1_addr`, `rs2_addr`: Endereços dos registradores fonte
- `rd_data`: Dados para escrita no registrador
- `we`: Write enable
- `rs1_data`, `rs2_data`: Dados lidos dos registradores

### 4. `alu.v`

Unidade lógica aritmética que executa as operações.

**Operações suportadas:**
- 4'b0000: ADD
- 4'b0001: SUB
- 4'b0010: AND
- 4'b0011: OR
- 4'b0100: XOR
- 4'b0101: NOT
- 4'b0110: SLL
- 4'b0111: SRL
- 4'b1000: SRA
- 4'b1001: SLT
- 4'b1010: MUL

### 5. `immediate_generator.v`

Gerador de valores imediatos a partir das instruções.

**Tipos de imediatos suportados:**
- I-type
- S-type
- B-type
- U-type/J-type

### 6. `memory_interface.v`

Interface simples para acesso à memória.

**Interfaces:**
- `clk`: Clock
- `rst_n`: Reset
- `address`: Endereço de memória
- `write_data`: Dados para escrita
- `we`: Write enable
- `re`: Read enable
- `read_data`: Dados lidos da memória
- `ready`: Sinal de ready

## Considerações de Desempenho

### Frequência de Operação

A frequência máxima depende da FPGA alvo e das constraints de timing aplicadas. Em FPGAs médias, espera-se uma frequência entre 50-100 MHz.

### Uso de Recursos

Em uma FPGA Xilinx Artix-7, o softcore utiliza aproximadamente:
- 5000-8000 LUTs
- 2000-4000 FFs
- 10-20 BRAMs
- 4-8 DSPs

### Otimizações Futuras

1. **Pipeline de 5 estágios**: Para melhor desempenho
2. **Cache de instruções/dados**: Para reduzir latência de memória
3. **Unidade de ponto flutuante**: Para maior precisão em cálculos
4. **Extensões vetoriais**: Para operações SIMD em redes neurais

## Integração com TensorFlow Lite Micro

### Requisitos

1. Compilador cruzado para ISA RISC-V
2. Bibliotecas do TensorFlow Lite Micro compiladas para o softcore
3. Sistema de memória adequado para armazenar o modelo

### Processo de Integração

1. Compilar o TFLM para a ISA do softcore
2. Converter o modelo TensorFlow para formato .tflite
3. Carregar o modelo na memória do sistema
4. Executar o código do TFLM no softcore

## Limitações Conhecidas

1. **Desempenho**: Softcores são inerentemente mais lentos que hardcores
2. **Precisão**: Operações de ponto flutuante são implementadas em software
3. **Recursos de memória**: Pode necessitar memória externa para modelos grandes
4. **Debugging**: Dificuldade em debugar código em execução no softcore

## Próximos Passos

1. Implementar extensões da ISA para operações de ponto flutuante
2. Adicionar suporte a interrupções
3. Desenvolver um debugger on-chip
4. Otimizar o pipeline para maior frequência de operação
5. Adicionar suporte a DMA para transferências de memória