# Extensões da ISA para Operações de Machine Learning

Este documento descreve as extensões propostas para a ISA do TFLite Softcore, adicionando instruções especializadas para operações comuns em redes neurais.

## Instruções Adicionadas

### 1. Conv2D (Convolução 2D)

**Codificação:**
- Opcode: CUSTOM_0 (0b0000000)
- Funct3: 0b000
- Funct7: 0b0000000

**Operação:**
Realiza uma operação de convolução 2D entre uma entrada e um filtro.

**Formato:**
```
conv2d rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para os dados de entrada
- rs2: Ponteiro para os pesos do filtro
- rd: Ponteiro para o buffer de saída

### 2. DepthwiseConv2D (Convolução 2D Profundidade-Separável)

**Codificação:**
- Opcode: CUSTOM_0 (0b0000000)
- Funct3: 0b001
- Funct7: 0b0000000

**Operação:**
Realiza uma operação de convolução 2D profundidade-separável.

**Formato:**
```
dwconv2d rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para os dados de entrada
- rs2: Ponteiro para os pesos do filtro
- rd: Ponteiro para o buffer de saída

### 3. DepthwiseConv2D+ReLU6

**Codificação:**
- Opcode: CUSTOM_0 (0b0000000)
- Funct3: 0b010
- Funct7: 0b0000000

**Operação:**
Realiza uma convolução 2D profundidade-separável seguida de ativação ReLU6.

**Formato:**
```
dwconv2d_relu6 rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para os dados de entrada
- rs2: Ponteiro para os pesos do filtro
- rd: Ponteiro para o buffer de saída

### 4. Conv2D+ReLU6

**Codificação:**
- Opcode: CUSTOM_0 (0b0000000)
- Funct3: 0b011
- Funct7: 0b0000000

**Operação:**
Realiza uma convolução 2D seguida de ativação ReLU6.

**Formato:**
```
conv2d_relu6 rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para os dados de entrada
- rs2: Ponteiro para os pesos do filtro
- rd: Ponteiro para o buffer de saída

### 5. Padding

**Codificação:**
- Opcode: CUSTOM_0 (0b0000000)
- Funct3: 0b100
- Funct7: 0b0000000

**Operação:**
Aplica padding aos dados de entrada.

**Formato:**
```
pad rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para os dados de entrada
- rs2: Ponteiro para os parâmetros de padding
- rd: Ponteiro para o buffer de saída

### 6. Add de Matrizes

**Codificação:**
- Opcode: CUSTOM_0 (0b0000000)
- Funct3: 0b101
- Funct7: 0b0000000

**Operação:**
Realiza a soma elemento a elemento de duas matrizes.

**Formato:**
```
matadd rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para a primeira matriz
- rs2: Ponteiro para a segunda matriz
- rd: Ponteiro para a matriz de saída

### 7. Mean (Média)

**Codificação:**
- Opcode: CUSTOM_0 (0b0000000)
- Funct3: 0b110
- Funct7: 0b0000000

**Operação:**
Calcula a média dos elementos de uma matriz.

**Formato:**
```
mean rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para a matriz de entrada
- rs2: Ponteiro para os parâmetros (tamanho, eixos, etc.)
- rd: Registrador para armazenar o resultado escalar

### 8. FullyConnected (Conexão Total)

**Codificação:**
- Opcode: CUSTOM_0 (0b0000000)
- Funct3: 0b111
- Funct7: 0b0000000

**Operação:**
Realiza uma operação de conexão total (multiplicação de matriz por vetor).

**Formato:**
```
fc rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para os dados de entrada
- rs2: Ponteiro para os pesos
- rd: Ponteiro para o buffer de saída

### 9. Softmax

**Codificação:**
- Opcode: CUSTOM_1 (0b0000001)
- Funct3: 0b000
- Funct7: 0b0000000

**Operação:**
Aplica a função softmax aos dados de entrada.

**Formato:**
```
softmax rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para os dados de entrada
- rs2: Ponteiro para parâmetros (dimensões, etc.)
- rd: Ponteiro para o buffer de saída

### 10. Quantize

**Codificação:**
- Opcode: CUSTOM_1 (0b0000001)
- Funct3: 0b001
- Funct7: 0b0000000

**Operação:**
Converte dados de ponto flutuante para ponto fixo (quantização).

**Formato:**
```
quantize rd, rs1, rs2
```

**Descrição:**
- rs1: Ponteiro para os dados de entrada (float32)
- rs2: Ponteiro para os parâmetros de quantização
- rd: Ponteiro para o buffer de saída (int8/int16)

## Considerações de Implementação

### Unidade de Operações Especializadas

Para implementar essas instruções, será necessário adicionar uma unidade de operações especializadas ao softcore:

1. **Unidade de Convolução**: Para operações Conv2D e DepthwiseConv2D
2. **Unidade de Ativação**: Para funções ReLU6
3. **Unidade de Operações Matriciais**: Para Add, Mean, FullyConnected
4. **Unidade de Funções de Ativação Avançadas**: Para Softmax
5. **Unidade de Quantização**: Para conversão float->fixo

### Interface de Memória Estendida

As operações com matrizes exigem acesso eficiente à memória:

1. **DMA**: Para transferências de blocos de memória
2. **Cache especializada**: Para pesos e dados de entrada
3. **Buffering**: Para dados intermediários

### Pipeline Otimizado

As instruções ML podem requerer um pipeline especializado:

1. **Pipeline de carga de dados**: Para buscar entrada, pesos e bias
2. **Pipeline de computação**: Para MACs e operações não-lineares
3. **Pipeline de armazenamento**: Para escrever resultados

## Benefícios das Extensões

1. **Aceleração significativa**: Operações ML executadas em hardware dedicado
2. **Redução de código**: Operações complexas em uma única instrução
3. **Eficiência energética**: Hardware otimizado para operações específicas
4. **Compatibilidade**: Extensão da ISA RISC-V existente

## Próximos Passos

1. Implementar a unidade de controle para as novas instruções
2. Desenvolver as unidades de operação especializadas
3. Criar testbenches para verificar o funcionamento
4. Otimizar o pipeline para melhor desempenho
5. Integrar com o TensorFlow Lite Micro