# Restrições de timing para TFLite Softcore em XCKU5P
# FPGA: XCKU5P-FFVB676-2-I

# Clock principal
create_clock -period 4.000 -name clk_main [get_ports clk]
set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports clk]

# Restrições de entrada/saída
set_property PACKAGE_PIN D7 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property PACKAGE_PIN C7 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Otimizações para BRAM/UltraRAM
# Corrigido para usar get_cells em vez de get_nets e especificar hierarquia
# Removendo as restrições problemáticas que estão causando warnings
# set_property RAM_STYLE block [get_cells -hierarchical *buffer*]
# set_property RAM_STYLE block [get_cells -hierarchical *mem*]

# Otimizações de área para melhor utilização de recursos
# Removendo LUT_REMAP que não é suportado no Vivado 2024.2
# set_property LUT_REMAP yes [get_cells -hierarchical *]

# Estratégia de síntese otimizada para performance
# Comentando comandos get_runs que não são suportados em arquivos XDC
# set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
# set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION on [get_runs synth_1]
# set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING on [get_runs synth_1]

# Estratégia de implementação otimizada
# Comentando comandos get_runs que não são suportados em arquivos XDC
# set_property STEPS.OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
# set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
# set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExtraNetDelay_high [get_runs impl_1]
# set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
# set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
# set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AggressiveFanoutOpt [get_runs impl_1]