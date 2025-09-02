# Diretrizes para Simulação do Softcore TensorFlow Lite

Este documento descreve como simular o softcore TensorFlow Lite utilizando diferentes ferramentas de simulação Verilog.

## Ferramentas de Simulação Suportadas

1. **Icarus Verilog** (gratuito e de código aberto)
2. **ModelSim** (comercial, da Mentor Graphics)
3. **Vivado Simulator** (gratuito com Vivado)
4. **Quartus Simulator** (gratuito com Quartus)

## Simulação com Icarus Verilog

### Instalação

Em sistemas Ubuntu/Debian:
```bash
sudo apt-get install iverilog gtkwave
```

Em sistemas macOS (com Homebrew):
```bash
brew install icarus-verilog gtkwave
```

### Executando Simulações

1. Navegue até o diretório `testbench/`
2. Compile e execute um testbench individual:
   ```bash
   # Compilar
   iverilog -o tb_alu tb_alu.v ../src/alu.v
   # Executar
   vvp tb_alu
   ```

3. Para visualizar as formas de onda:
   ```bash
   # Gerar arquivo VCD
   iverilog -o tb_alu tb_alu.v ../src/alu.v
   vvp tb_alu
   # Visualizar com GTKWave
   gtkwave tb_alu.vcd
   ```

## Simulação com ModelSim

### Configuração do Ambiente

1. Crie uma nova library:
   ```tcl
   vlib work
   ```

2. Compile os arquivos:
   ```tcl
   # Compile o módulo
   vlog ../src/alu.v
   # Compile o testbench
   vlog tb_alu.v
   ```

3. Inicie a simulação:
   ```tcl
   vsim tb_alu
   ```

4. Adicione formas de onda:
   ```tcl
   add wave *
   ```

5. Execute a simulação:
   ```tcl
   run -all
   ```

## Simulação com Vivado Simulator

### Configuração do Ambiente

1. Crie um novo projeto no Vivado
2. Adicione os arquivos de `src/` e `testbench/`
3. Defina o testbench como módulo top-level
4. Execute a simulação no Vivado Simulator

## Scripts de Simulação

### Script para Icarus Verilog

```bash
#!/bin/bash
# script_sim.sh

# Compilar todos os testbenches
echo "Compilando testbenches..."
iverilog -o tb_alu tb_alu.v ../src/alu.v
iverilog -o tb_register_file tb_register_file.v ../src/register_file.v
iverilog -o tb_control_unit tb_control_unit.v ../src/control_unit.v
iverilog -o tb_immediate_generator tb_immediate_generator.v ../src/immediate_generator.v
iverilog -o tb_memory_interface tb_memory_interface.v ../src/memory_interface.v
iverilog -o tb_tflite_softcore tb_tflite_softcore.v ../src/tflite_softcore.v

# Executar simulações
echo "Executando simulações..."
./tb_alu
./tb_register_file
./tb_control_unit
./tb_immediate_generator
./tb_memory_interface
./tb_tflite_softcore

echo "Todas as simulações concluídas."
```

## Análise de Resultados

Após executar as simulações:

1. Verifique se não há mensagens de erro no console
2. Analise os arquivos de forma de onda (.vcd) para verificar o comportamento dos sinais
3. Confirme que todos os testes passaram conforme esperado

## Considerações para Simulações Mais Complexas

1. **Modelos de Memória**: Para simulações mais realistas, pode-se utilizar modelos de memória mais complexos.
2. **Programas de Teste**: Pode-se carregar programas simples na memória para testar a execução de instruções.
3. **Cobertura de Teste**: Ferramentas avançadas permitem análise de cobertura de teste para garantir que todas as partes do design foram exercitadas.

## Dicas para Debugging

1. Use `\$display` para imprimir mensagens durante a simulação
2. Utilize formas de onda para visualizar o comportamento dos sinais
3. Adicione asserts para verificar condições importantes
4. Divida testes complexos em etapas menores

## Considerações Finais

- As simulações são essenciais para verificar o funcionamento correto do softcore antes da síntese
- Testbenches abrangentes ajudam a identificar problemas precocemente no processo de desenvolvimento
- A automação dos testes através de scripts pode agilizar o processo de verificação