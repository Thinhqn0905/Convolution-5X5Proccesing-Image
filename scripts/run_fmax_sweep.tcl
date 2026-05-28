# Project-mode Fmax sweep for the Full-HD convolution core.
#
# Usage:
#   vivado.bat -mode batch -source scripts/run_fmax_sweep.tcl
#   vivado.bat -mode batch -source scripts/run_fmax_sweep.tcl -tclargs 150 140 130 120 115 110 108 106 105 100

set part_name "xc7a100tcsg324-1"
set top_name "top_convolution"
if {[info exists ::env(FMAX_SWEEP_OUT_DIR)] && $::env(FMAX_SWEEP_OUT_DIR) ne ""} {
    set out_dir [file normalize $::env(FMAX_SWEEP_OUT_DIR)]
} else {
    set out_dir [file normalize "vivado_project/fmax_sweep"]
}
file mkdir $out_dir

if {[llength $argv] > 0} {
    set freqs_mhz $argv
} else {
    set freqs_mhz [list 150 140 130 120 115 110 108 106 105 100]
}

set srcs [list \
    [file normalize "src/top_convolution.sv"] \
    [file normalize "src/line_buffer_4.sv"] \
    [file normalize "src/kernel_loader.sv"] \
    [file normalize "src/mac_array_25x3.sv"] \
]

set_param general.maxThreads 4

set csv_path [file join $out_dir fmax_sweep_summary.csv]
set csv [open $csv_path "w"]
puts $csv "freq_mhz,period_ns,status,wns_ns,whs_ns,fmax_est_mhz,run_status,timing_report"

set first_pass ""

foreach freq $freqs_mhz {
    set period [expr {1000.0 / double($freq)}]
    set run_dir [file join $out_dir "${freq}MHz"]
    set proj_dir [file join $run_dir project]
    file mkdir $run_dir

    puts "\n=== FMAX_SWEEP: ${freq} MHz period=${period} ns ==="

    catch {close_project}
    create_project "fmax_${freq}" $proj_dir -part $part_name -force
    add_files -norecurse $srcs
    set_property top $top_name [current_fileset]

    set xdc_path [file join $run_dir clock.xdc]
    set xdc [open $xdc_path "w"]
    puts $xdc [format "create_clock -name clk -period %.6f \[get_ports clk\]" $period]
    close $xdc
    add_files -fileset constrs_1 -norecurse $xdc_path

    update_compile_order -fileset sources_1

    set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
    set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap [get_runs impl_1]
    set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
    set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
    set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
    set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

    set run_status "UNKNOWN"
    set status "FAIL"
    set wns -9999.0
    set whs -9999.0
    set fmax_est 0.0
    set timing_rpt [file join $run_dir timing_post_route.rpt]
    set util_rpt [file join $run_dir util_post_route.rpt]

    if {[catch {
        launch_runs synth_1 -jobs 4
        wait_on_run synth_1
        set synth_status [get_property STATUS [get_runs synth_1]]
        if {![string match "*Complete*" $synth_status]} {
            error "synth_1 did not complete: $synth_status"
        }

        launch_runs impl_1 -to_step route_design -jobs 4
        wait_on_run impl_1
        set run_status [get_property STATUS [get_runs impl_1]]

        open_run impl_1
        report_timing_summary -file $timing_rpt
        report_utilization -file $util_rpt

        set setup_paths [get_timing_paths -setup -max_paths 1]
        set hold_paths [get_timing_paths -hold -max_paths 1]

        if {[llength $setup_paths] > 0} {
            set wns [get_property SLACK [lindex $setup_paths 0]]
        }
        if {[llength $hold_paths] > 0} {
            set whs [get_property SLACK [lindex $hold_paths 0]]
        }

        set denom [expr {$period - double($wns)}]
        if {$denom > 0.0} {
            set fmax_est [expr {1000.0 / $denom}]
        }

        if {$wns >= 0.0 && $whs >= 0.0} {
            set status "PASS"
        }
    } msg]} {
        set run_status "ERROR: $msg"
        puts "RUN_ERROR ${freq}MHz: $msg"
    }

    puts [format "RESULT freq=%sMHz status=%s WNS=%.3fns WHS=%.3fns Fmax_est=%.3fMHz run_status=%s" \
        $freq $status $wns $whs $fmax_est $run_status]
    puts $csv [format "%s,%.6f,%s,%.6f,%.6f,%.6f,%s,%s" \
        $freq $period $status $wns $whs $fmax_est $run_status $timing_rpt]
    flush $csv

    catch {close_project}

    if {$status eq "PASS" && $first_pass eq ""} {
        set first_pass $freq
        break
    }
}

close $csv
puts "\nFmax sweep summary: $csv_path"
if {$first_pass ne ""} {
    puts "First passing requested frequency: ${first_pass} MHz"
} else {
    puts "No requested frequency passed timing."
}
