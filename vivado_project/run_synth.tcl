# Batch synthesis/implementation script
# Usage example:
# vivado -mode batch -source vivado_project/run_synth.tcl

set proj_name convolution_fpga
set proj_xpr [file normalize "./vivado_project/builds/${proj_name}/${proj_name}.xpr"]
set rpt_dir [file normalize "./vivado_project/reports"]

file mkdir $rpt_dir

if {![file exists $proj_xpr]} {
    puts "Project not found, creating project first..."
    source [file normalize "./vivado_project/project_create.tcl"]
}

open_project $proj_xpr
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

open_run synth_1
report_timing_summary -file [file normalize "${rpt_dir}/timing_post_synth.rpt"]
report_utilization -file [file normalize "${rpt_dir}/util_post_synth.rpt"]

reset_run impl_1
launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1

open_run impl_1
report_timing_summary -file [file normalize "${rpt_dir}/timing_post_route.rpt"]
report_utilization -file [file normalize "${rpt_dir}/util_post_route.rpt"]
report_power -file [file normalize "${rpt_dir}/power_post_route.rpt"]

puts "Synthesis/implementation done. Reports in $rpt_dir"
