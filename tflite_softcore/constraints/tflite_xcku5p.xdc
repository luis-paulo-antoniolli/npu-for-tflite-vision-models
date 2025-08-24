# Restrições de timing para TFLite Softcore em XCKU5P
# FPGA: XCKU5P-FFVB676-2-I

# Clock principal
create_clock -period 4.000 -name clk_main [get_ports clk]
set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports clk]

# Clock PCIe (se utilizado)
create_clock -period 4.000 -name clk_pcie [get_ports pcie_clk]

# Restrições de entrada/saída
set_property PACKAGE_PIN D7 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property PACKAGE_PIN C7 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# PCIe pins (exemplo)
set_property PACKAGE_PIN E10 [get_ports pcie_rx_valid]
set_property PACKAGE_PIN F10 [get_ports pcie_tx_ready]
# ... (adicionar todos os pins PCIe conforme o design)

# Otimizações para DSPs
set_property DONT_TOUCH true [get_cells -hierarchical -filter {PRIMITIVE_TYPE =~ *MACC*}]
set_property DONT_TOUCH true [get_cells -hierarchical -filter {PRIMITIVE_TYPE =~ *DSP*}]

# Otimizações para BRAM/UltraRAM
set_property RAM_STYLE block [get_nets -hierarchical *buffer*]
set_property RAM_STYLE block [get_nets -hierarchical *mem*]

# Restrições de timing para pipeline crítico
set_multicycle_path -setup -from [get_pins tflite_softcore/pc_reg_reg[*]/C] -to [get_pins tflite_softcore/instruction_f_reg[*]/D] 2
set_multicycle_path -hold -from [get_pins tflite_softcore/pc_reg_reg[*]/C] -to [get_pins tflite_softcore/instruction_f_reg[*]/D] 1

# Restrições para unidades ML
set_multicycle_path -setup -from [get_pins ml_accelerator/accumulator_reg[*]/C] -to [get_pins ml_accelerator/output_buffer_reg[*]/D] 3
set_multicycle_path -hold -from [get_pins ml_accelerator/accumulator_reg[*]/C] -to [get_pins ml_accelerator/output_buffer_reg[*]/D] 2

# Otimizações de área para melhor utilização de recursos
set_property CONTROL_SET_OPT_THRESHOLD 64 [get_cells -hierarchical *]
set_property LUT_REMAP yes [get_cells -hierarchical *]
set_property FANOUT_LIMIT 32 [get_nets -hierarchical *]

# Estratégia de síntese otimizada para performance
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION on [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING on [get_runs synth_1]

# Estratégia de implementação otimizada
set_property STEPS.OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExtraNetDelay_high [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AggressiveFanoutOpt [get_runs impl_1]

# Análise de timing
set_property SLACK_0V_REPORT_FLAG 1 [get_timing_paths]
set_property SLACK_900MV_REPORT_FLAG 1 [get_timing_paths]
set_property SLACK_850MV_REPORT_FLAG 1 [get_timing_paths]

# Relógios cruzados
set_clock_groups -asynchronous -group [get_clocks clk_main] -group [get_clocks clk_pcie]

# Relatório de utilização
report_utilization -file utilization_report.txt