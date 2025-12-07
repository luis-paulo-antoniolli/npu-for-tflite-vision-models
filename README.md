# TensorFlow Lite NPU para FPGA XCKU5P

## Visão Geral

Este projeto implementa um NPU (Neural Processing Unit) em Verilog otimizado especificamente para o FPGA Xilinx Kintex UltraScale+ XCKU5P-FFVB676-2-I. O design aproveita ao máximo os recursos do FPGA, incluindo 1.440 DSPs, 2.048 MB BRAM e 48 UltraRAM, para acelerar inferências de modelos TensorFlow Lite.

Obs:o projeto ainda apresenta muita instabilidade, portanto não é recomendado utiliza-lo em aplicações críticas.

Fiz este projeto com 17 anos e com auxilio do qwen-coder (era o que tinha disponivel) então peço que tenha paciência com algunas erros crassos.

Peço por sugestões de melhorias e se possivel faça um branch e resolva o problema que com certeza eu irei incorporar sua solução na main.

## Características Otimizadas para XCKU5P

- **Arquitetura**: RISC-V RV32I com pipeline de 5 estágios
- **Aceleradores ML**: Unidades especializadas para Conv2D, DepthwiseConv2D, FullyConnected
- **Memória**: Controlador UltraRAM otimizado para grandes modelos
- **PCIe**: Interface PCIe para comunicação com host
- **DSPs**: Uso intensivo de blocos DSP para operações MAC
- **Pipeline**: Pipeline de 5 estágios para máxima frequência de operação

## Recursos do FPGA XCKU5P Utilizados

- **LUTs**: ~70% de 544.320 slices
- **FFs**: ~60% de 1.088.640 flip-flops
- **DSPs**: ~80% de 1.440 blocos DSP
- **BRAM**: ~90% de 2.048 MB
- **UltraRAM**: 48 blocos para armazenamento de modelos grandes
- **Clock**: Frequência alvo de 250MHz (4ns)

## Estrutura do Projeto

- `src/`: Código-fonte Verilog do NPU
- `testbench/`: Bancos de teste para todos os módulos
- `sim/`: Scripts e documentação para simulação
- `synth/`: Scripts e documentação para síntese em FPGA
- `constraints/`: Arquivos XDC para restrições de timing
- `scripts/`: Scripts de automação (Tcl, Bash)
- `docs/`: Documentação técnica e guia de desenvolvimento

## Começando

### Pré-requisitos

- Xilinx Vivado 2025.1 ou superior
- FPGA XCKU5P-FFVB676-2-I
- TensorFlow Lite Micro toolchain
- Sistema Linux com acesso PCIe

### Compilação Automatizada

```bash
cd scripts
vivado -mode batch -source vivado_build.tcl
```

### Compilação Manual no Vivado

1. Criar novo projeto com part number `xcku5p-ffvb676-2-i`
2. Adicionar todos os arquivos do diretório `src/`
3. Adicionar constraints do diretório `constraints/`
4. Definir `tflite_softcore` como módulo top-level
5. Configurar estratégias de síntese/implantação para performance
6. Executar síntese e implementação

## Arquitetura Otimizada

### Pipeline de 5 Estágios
1. **FETCH**: Busca de instrução com buffer
2. **DECODE**: Decodificação com previsão de branch
3. **EXECUTE**: Execução com unidades especializadas
4. **MEMORY**: Acesso à memória com cache
5. **WRITEBACK**: Escrita no registrador

### Aceleradores ML
- **Conv2D Unit**: Operações de convolução 2D otimizadas
- **DepthwiseConv2D Unit**: Convolução separável por profundidade
- **FullyConnected Unit**: Multiplicação matriz-vetor
- **Activation Units**: ReLU, ReLU6, Softmax

### Memória
- **UltraRAM Controller**: 24MB de memória para modelos grandes
- **BRAM Buffers**: Buffers para dados de entrada/saída
- **DMA Engine**: Transferências de memória otimizadas

## Performance Esperada

- **Frequência**: 250MHz (4ns clock period)
- **Throughput**: Até 1000 inferências/segundo (dependendo do modelo)
- **Latência**: 5-50ms por inferência
- **Utilização**: ~85% dos recursos do FPGA

## Documentação

- [Referência Técnica](docs/technical_reference.md): Documentação detalhada da arquitetura
- [Guia de Desenvolvimento](docs/development_guide.md): Extensão e otimização do NPU
- [Instruções ML](docs/ml_instructions_extension.md): Extensões da ISA para operações ML
- [Runtime Completo](docs/runtime_complete.md): Integração com host e PCIe

## Contribuições

Contribuições são bem-vindas! O projeto está otimizado para o XCKU5P, mas pode ser adaptado para outros FPGAs da família UltraScale+.

## Licença

Este projeto é licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.
