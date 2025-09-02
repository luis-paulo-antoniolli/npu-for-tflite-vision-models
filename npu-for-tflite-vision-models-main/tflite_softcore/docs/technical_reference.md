# Documentação Técnica do TFLite Softcore

## Visão Geral

O TFLite Softcore é um processador RISC-V de 32 bits otimizado especificamente para executar modelos de machine learning do TensorFlow Lite em FPGAs com recursos limitados. Ele implementa um subconjunto da ISA RV32I com extensões para operações comuns em redes neurais.

## Arquitetura

### Pipeline

O softcore utiliza um pipeline simples de 5 estágios:

1. **FETCH**: Busca da instrução na memória
2. **DECODE**: Decodificação da instrução e leitura dos registradores
3. **EXECUTE**: Execução da operação e escrita do resultado
4. **MEMORY**: Acesso à memória (load/store)
5. **WRITEBACK**: Escrita do resultado no banco de registradores

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
- **Instruções Custom**: Extensões para operações ML

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
- `mem_addr`: Endereço de memória
- `mem_data_in`: Dados lidos da memória
- `mem_we`: Write enable para memória
- `mem_re`: Read enable para memória
- `mem_ready`: Sinal de ready da memória
- `mem_data_out`: Dados para escrita na memória
- `mem_req`: Requisição de acesso à memória

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

### 6. `npu_top.v`

Controlador da Neural Processing Unit (NPU) que coordena os aceleradores ML.

**Aceleradores integrados:**
- `conv2d_accelerator`: Acelerador de convolução 2D
- `fully_connected_accelerator`: Acelerador de conexão total
- `dwconv2d_unit`: Unidade de convolução profundidade-separável
- `matadd_unit`: Unidade de soma de matrizes

## Aceleradores ML

### Conv2D Accelerator

Implementa operações de convolução 2D otimizadas com pipeline de MAC (Multiply-Accumulate).

**Características:**
- Buffer de entrada (int8)
- Buffer de pesos (int8)
- Buffer de bias (int32)
- Buffer de saída (int32)
- Quantização de 8 bits
- ReLU activation

### Fully Connected Accelerator

Implementa operações de multiplicação matriz-vetor para camadas totalmente conectadas.

**Características:**
- Buffer de entrada (int8)
- Buffer de pesos (int8)
- Buffer de bias (int32)
- Buffer de saída (int32)
- Quantização de 8 bits

### Depthwise Conv2D Unit

Implementa convolução separável por profundidade, uma operação comum em modelos eficientes.

**Características:**
- Processamento de dados de entrada
- Aplicação de filtros
- Padding automático
- Stride configurável

### Matrix Addition Unit

Implementa soma elemento a elemento de matrizes.

**Características:**
- Operações com matrizes de até 256 elementos
- Buffer para duas matrizes de entrada
- Buffer para matriz de saída

## Considerações de Desempenho

### Frequência de Operação

A frequência máxima depende da FPGA alvo e das constraints de timing aplicadas. Em FPGAs médias, espera-se uma frequência entre 100-250 MHz.

### Uso de Recursos

Em uma FPGA Xilinx Kintex UltraScale+ XCKU5P:
- LUTs: ~70% (381,024 de 544,320)
- FFs: ~60% (653,184 de 1,088,640)
- BRAMs: ~90% (1,843 de 2,048)
- DSPs: ~80% (1,152 de 1,440)
- UltraRAM: 100% (48 de 48)

### Throughput Esperado

- **Modelos pequenos**: 200 inferências/segundo
- **Modelos médios**: 66 inferências/segundo
- **Modelos grandes**: 20 inferências/segundo

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

## Extensões e Otimizações Futuras

### Pipeline Otimizado
- Implementação de pipeline de 5 estágios para melhor frequência
- Detecção e resolução de hazards
- Forwarding de dados

### Memória Cache
- Implementação de cache de instruções
- Implementação de cache de dados
- Controladores de cache otimizados

### Operações Especializadas para ML
- Unidade MAC (Multiply-Accumulate) otimizada
- Unidade de Ativação (ReLU, ReLU6, Softmax)
- Unidade de Normalização (Batch Normalization)

### Interface PCIe
- Controlador PCIe para comunicação com host
- DMA engine para transferências de memória
- Buffer FIFO para rx/tx

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