TensorFlow Lite NPU para FPGA XCKU5P
Visão Geral
Este projeto implementa uma NPU (Neural Processing Unit) em Verilog especificamente para o FPGA Xilinx Kintex UltraScale+ XCKU5P-FFVB676-2-I. O design aproveita ao máximo os recursos do FPGA, incluindo 1.440 DSPs, 2.048 MB BRAM e 48 UltraRAM, para acelerar inferências de modelos TensorFlow Lite.

Características Otimizadas para XCKU5P
Arquitetura : RISC-V RV32I com pipeline de 5 estágios
Aceleradores ML : Unidades especializadas para Conv2D, DepthwiseConv2D, FullyConnected
Memória : Controlador UltraRAM otimizado para grandes modelos
PCIe : Interface PCIe para comunicação com host
DSPs : Uso intensivo de blocos DSP para operações MAC
Pipeline : Pipeline de 5 estágios para frequência máxima de operação
Recursos do FPGA XCKU5P Utilizados
LUTs : ~70% de 544.320 fatias
FFs : ~60% de 1.088.640 flip-flops
DSPs : ~80% de 1.440 blocos DSP
BRAM : ~90% de 2.048 MB
UltraRAM : 48 blocos para armazenamento de modelos grandes
Clock : Frequência alvo de 250MHz (4ns)
Estrutura do Projeto
src/: Código-fonte Verilog do NPU
testbench/: Bancos de teste para todos os módulos
sim/: Scripts e documentação para simulação
synth/: Scripts e documentação para visão geral em FPGA
constraints/: Arquivos XDC para restrições de tempo
scripts/: Scripts de automação (Tcl, Bash)
docs/: Documentação técnica e guia de desenvolvimento
Começando
Pré-requisitos
Xilinx Vivado 2025.1 ou superior
FPGA XCKU5P-FFVB676-2-I
Conjunto de ferramentas TensorFlow Lite Micro
Sistema Linux com acesso PCIe
Compilação Automatizada
cd scripts
vivado -mode batch -source vivado_build.tcl
Compilação Manual no Vivado
Criar novo projeto com número de peçaxcku5p-ffvb676-2-i
Adicionar todos os arquivos do diretóriosrc/
Adicionar restrições do diretórioconstraints/
Definir tflite_softcorecomo módulo de nível superior
Configurar estratégias de síntese/implantação para desempenho
Execução de síntese e alinhamento
Arquitetura Otimizada
Pipeline de 5 Estágios
FETCH : Busca de instrução com buffer
DECODE : Decodificação com previsão de branch
EXECUTE : Execução com unidades especializadas
MEMÓRIA : Acesso à memória com cache
WRITEBACK : Escrita no registrador
Aceleradores ML
Unidade Conv2D : Operações de convolução 2D otimizadas
Unidade DepthwiseConv2D : Convolução separável por profundidade
Unidade Totalmente Conectada : Multiplicação matriz-vetor
Unidades de ativação : ReLU, ReLU6, Softmax
Memória
Controlador UltraRAM : 24 MB de memória para modelos grandes
BRAM Buffers : Buffers para dados de entrada/saída
DMA Engine : Transferências de memória otimizadas
Performance Esperada
Frequência : 250MHz (período de clock de 4ns)
Taxa de transferência : Até 1000 inferências/segundo (dependendo do modelo)
Latência : 5-50ms por inferência
Utilização : ~85% dos recursos do FPGA
Documentação
Referência Técnica : Documentação específica da arquitetura
Guia de Desenvolvimento : Extensão e Otimização do NPU
Instruções ML : Extensões da ISA para operações ML
Runtime Completo : Integração com host e PCIe
Contribuições
Contribuições são bem-vindas! O projeto é otimizado para o XCKU5P, mas pode ser adaptado para outros FPGAs da família UltraScale+.

licença
Este projeto é licenciado sob a licença MIT - veja o arquivo LICENSE para detalhes.
