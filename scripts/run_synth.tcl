open_project ./vivado_project/builds/convolution_fpga/convolution_fpga.xpr
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1 -name synth_1
report_drc -file ./vivado_project/builds/convolution_fpga/synth_drc_report.txt
puts "Synthesis and DRC report generation completed!"
