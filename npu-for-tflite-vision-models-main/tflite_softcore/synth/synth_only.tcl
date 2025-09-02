# Script TCL para sintetizar apenas o projeto TFLite Softcore
# FPGA: XCKU5P-FFVB676-2-I

# Definir variáveis do projeto
set project_name "tflite_softcore"
set part "xcku5p-ffvb676-2-i"
set top_module "tflite_softcore"
set src_dir "../src"
set constr_dir "../constraints"

# Criar projeto
create_project $project_name . -part $part -force

# Adicionar arquivos fonte
add_files [glob $src_dir/*.v]
add_files [glob $src_dir/miaow-master/src/*.v]
add_files $constr_dir/tflite_xcku5p.xdc

# Definir módulo principal
set_property top $top_module [current_fileset]

# Configurar fileset para síntese
set_property used_in_synthesis true [get_files [glob $src_dir/*.v]]
set_property used_in_synthesis true [get_files [glob $src_dir/miaow-master/src/*.v]]
set_property used_in_implementation true [get_files [glob $src_dir/*.v]]
set_property used_in_implementation true [get_files [glob $src_dir/miaow-master/src/*.v]]

# Configurar estratégias de síntese
set_property strategy Flow_RuntimeOptimized [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION on [get_runs synth_1]

# Executar apenas síntese
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Verificar se a síntese foi bem-sucedida
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "Síntese falhou"
}

# Abrir run de síntese
open_run synth_1

# Gerar relatório de síntese
report_utilization -file synth_utilization.rpt
report_timing_summary -file synth_timing.rpt
report_clocks -file synth_clocks.rpt

# Mensagem final
puts "=========================================="
puts "Síntese do projeto TFLite Softcore completada com sucesso!"
puts "Relatórios disponíveis em:"
puts "  - synth_utilization.rpt"
puts "  - synth_timing.rpt"
puts "=========================================="