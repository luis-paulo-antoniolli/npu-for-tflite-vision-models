# TensorFlow Lite Runtime para FPGA - Documentação Completa

## Visão Geral

Este documento descreve a implementação completa de um runtime para o softcore TensorFlow Lite FPGA que é capaz de:

1. Carregar modelos TFLite (formato FlatBuffer) do host para a FPGA via PCIe
2. Transferir dados de entrada (imagens da câmera) para a FPGA
3. Executar inferência usando o softcore
4. Retornar resultados para o host

## Arquitetura do Sistema

```
[Host (PC)] <--PCIe--> [FPGA] <--Memória--> [Softcore TFLite]
     |                     |
     |                     +--> [Unidades ML Aceleradas]
     |                     |
     |                     +--> [Controlador PCIe]
     |
     +--> [Aplicação Host]
     +--> [Câmera USB]
```

## Componentes Implementados

### 1. Controlador PCIe na FPGA (Verilog)

Responsável por:
- Receber comandos e dados do host via barramento PCIe
- Gerenciar transferências de memória entre host e FPGA
- Coordenar a execução no softcore TFLite

Arquivo: `src/pcie_controller_optimized.v`

### 2. Interface de Memória Estendida (Verilog)

Responsável por:
- Arbitrar acessos à memória entre diferentes componentes
- Gerenciar prioridades de acesso (softcore > PCIe > unidades ML)
- Fornecer interface unificada para acesso à memória

Arquivo: `src/memory_interface_extended.v`

### 3. Controlador de Modelo (Verilog)

Responsável por:
- Gerenciar o ciclo de vida da execução de um modelo
- Carregar modelos TFLite na memória da FPGA
- Coordenar a transferência de dados de entrada e saída

Arquivo: `src/model_controller.v`

### 4. Driver PCIe para Host (C++)

Responsável por:
- Comunicar-se com a FPGA via barramento PCIe
- Transferir modelos TFLite e dados de entrada
- Receber resultados da inferência

Arquivos: 
- `host/pcie_driver.cpp`
- `host/pcie_driver.h`

### 5. Aplicação Host Principal (C++)

Responsável por:
- Coordenar todo o processo de inferência
- Carregar modelos TFLite
- Capturar imagens da câmera
- Enviar dados para FPGA e receber resultados

Arquivo: `host/main.cpp`

### 6. Classe para Captura de Câmera (C++)

Responsável por:
- Inicializar e configurar a câmera USB
- Capturar frames de vídeo
- Pré-processar imagens para inferência

Arquivos:
- `host/camera_capture.cpp`
- `host/camera_capture.h`

### 7. Classe para Manipulação de Modelos TFLite (C++)

Responsável por:
- Carregar modelos TFLite do disco
- Extrair dados do modelo em formato FlatBuffer
- Processar resultados da inferência

Arquivos:
- `host/tflite_model.cpp`
- `host/tflite_model.h`

### 8. Scripts de Build e Integração

Responsável por:
- Automatizar o processo de compilação
- Integrar todos os componentes do sistema
- Criar pacotes de instalação

Arquivos:
- `host/Makefile`
- `scripts/integrate.sh`

## Fluxo de Execução

1. **Inicialização**:
   - Aplicação host é iniciada
   - Driver PCIe é carregado e conecta-se à FPGA
   - Câmera USB é inicializada

2. **Carregamento do Modelo**:
   - Modelo TFLite é carregado do disco
   - Dados do modelo são enviados via PCIe para a FPGA
   - FPGA armazena o modelo em sua memória

3. **Loop de Inferência**:
   - Captura frame da câmera
   - Pré-processa imagem para formato adequado
   - Envia dados de entrada para FPGA via PCIe
   - FPGA executa inferência usando softcore TFLite
   - Resultados são enviados de volta ao host
   - Host processa e exibe resultados

## Comandos PCIe Implementados

| Código | Comando        | Descrição                          |
|--------|----------------|------------------------------------|
| 0x01   | LOAD_MODEL     | Carregar modelo TFLite na FPGA     |
| 0x02   | LOAD_INPUT     | Carregar dados de entrada          |
| 0x03   | RUN_INFERENCE  | Executar inferência no modelo      |
| 0x04   | GET_RESULT     | Obter resultados da inferência     |

## Requisitos de Sistema

### Host (PC):
- Sistema Linux (Ubuntu 18.04 ou superior recomendado)
- GCC 7.0 ou superior
- TensorFlow Lite development libraries
- OpenCV 4.0 ou superior
- Câmera USB compatível

### FPGA:
- FPGA com interface PCIe (Xilinx ou Intel)
- Mínimo de 128MB de memória DDR
- Controlador PCIe implementado
- Softcore TFLite sintetizado

## Compilação e Instalação

### No Host:
```bash
cd host
make
```

### Na FPGA:
- Sintetizar design usando ferramentas do fabricante
- Programar FPGA com bitstream gerado

### Integração Completa:
```bash
./scripts/integrate.sh
```

## Extensões Futuras

1. **Suporte a Quantização**:
   - Implementar unidades para operações com int8/int16
   - Otimizar transferências de dados quantizados

2. **Processamento em Lote**:
   - Adicionar suporte para processar múltiplas imagens simultaneamente
   - Implementar fila de inferência

3. **Otimizações de Memória**:
   - Adicionar cache para pesos do modelo
   - Implementar compressão de modelos

4. **Suporte a Mais Operações**:
   - Adicionar unidades para operações não implementadas
   - Suporte completo ao conjunto de operações TFLite

## Considerações de Desempenho

1. **Latência**:
   - Latência de transferência PCIe: ~1-10ms dependendo do tamanho dos dados
   - Latência de inferência: variável dependendo do modelo e FPGA

2. **Throughput**:
   - Limitado pela taxa de captura da câmera
   - Otimizado por processamento paralelo na FPGA

3. **Uso de Recursos**:
   - FPGA: ~70-80% de LUTs/FFs em FPGA média
   - Host: Uso mínimo de CPU (<5%) durante inferência

## Troubleshooting

### Problemas Comuns:

1. **Dispositivo PCIe não encontrado**:
   - Verificar se o driver está carregado
   - Confirmar conexão física da FPGA

2. **Falha ao carregar modelo**:
   - Verificar formato do arquivo .tflite
   - Confirmar espaço suficiente na memória da FPGA

3. **Imagens não são capturadas**:
   - Verificar conexão da câmera
   - Confirmar permissões de acesso à câmera

### Logs e Debugging:

- Logs da aplicação host disponíveis via stdout/stderr
- Sinais de debug podem ser adicionados aos módulos Verilog
- Análise de performance via profiling do TensorFlow Lite