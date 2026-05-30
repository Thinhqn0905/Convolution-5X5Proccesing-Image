# Post-route Fmax sweep for Design B:
# - addressless SRL line buffer
# - 6-stage MAC
# - coefficient-stationary multicycle path
#
# Usage:
#   vivado.bat -mode batch -source scripts/run_impl_fmax_sweep_design_b.tcl -tclargs 200 190 180 170 160

set part_name "xc7a100tcsg324-1"
set top_name "top_convolution"

if {[info exists ::env(IMPL_FMAX_SWEEP_OUT_DIR)] && $::env(IMPL_FMAX_SWEEP_OUT_DIR) ne ""} {
    set out_dir [file normalize $::env(IMPL_FMAX_SWEEP_OUT_DIR)]
} else {
    set out_dir [file normalize "vivado_project/fmax_sweep_impl_design_b"]
}
file mkdir $out_dir

if {[llength $argv] > 0} {
    set freqs_mhz $argv
} else {
    set freqs_mhz [list 200 190 180 170 160]
}

set srcs [list \
    [file normalize "src/top_convolution.sv"] \
    [file normalize "src/line_buffer_4.sv"] \
    [file normalize "src/kernel_loader.sv"] \
    [file normalize "src/mac_array_25x3.sv"] \
]

set_param general.maxThreads 4

set csv_path [file join $out_dir impl_fmax_sweep_summary.csv]
set csv [open $csv_path "w"]
puts $csv "freq_mhz,period_ns,status,wns_ns,whs_ns,fmax_est_mhz,coeff_regs,mul_dsps,timing_report,util_report"

set first_pass ""

foreach freq $freqs_mhz {
    set period [expr {1000.0 / double($freq)}]
    set run_dir [file join $out_dir "${freq}MHz"]
    file mkdir $run_dir

    puts "\n=== IMPL_FMAX_SWEEP_DESIGN_B: ${freq} MHz period=${period} ns ==="

    set status "FAIL"
    set wns -9999.0
    set whs -9999.0
    set fmax_est 0.0
    set coeff_count 0
    set dsp_count 0
    set timing_rpt [file join $run_dir timing_post_route.rpt]
    set util_rpt [file join $run_dir util_post_route.rpt]
    set synth_rpt [file join $run_dir util_post_synth.rpt]
    set routed_dcp [file join $run_dir routed.dcp]

    if {[catch {
        read_verilog -sv $srcs
        synth_design -top $top_name -part $part_name -flatten_hierarchy rebuilt
        create_clock -name clk -period $period [get_ports clk]

        report_utilization -file $synth_rpt

        set coeff_regs [get_cells -hier -filter {NAME =~ *u_mac_array/coeff_q_reg* && REF_NAME =~ FD*}]
        set mul_dsps [get_cells -hier -filter {NAME =~ *u_mac_array/mul_*_q_reg* && REF_NAME == DSP48E1}]
        set coeff_count [llength $coeff_regs]
        set dsp_count [llength $mul_dsps]

        if {$coeff_count > 0 && $dsp_count > 0} {
            puts [format "Applying coefficient-stationary multicycle: coeff_regs=%d mul_dsps=%d" \
                $coeff_count $dsp_count]
            set_multicycle_path -setup 2 -from $coeff_regs -to $mul_dsps
            set_multicycle_path -hold 1 -from $coeff_regs -to $mul_dsps
        } else {
            puts [format "WARNING: coefficient multicycle not applied: coeff_regs=%d mul_dsps=%d" \
                $coeff_count $dsp_count]
        }

        opt_design -directive ExploreWithRemap
        place_design -directive Explore
        phys_opt_design -directive AggressiveExplore
        route_design -directive Explore

        write_checkpoint -force $routed_dcp
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
        puts "RUN_ERROR ${freq}MHz: $msg"
    }

    puts [format "RESULT freq=%sMHz status=%s WNS=%.3fns WHS=%.3fns Fmax_est=%.3fMHz coeff_regs=%d mul_dsps=%d" \
        $freq $status $wns $whs $fmax_est $coeff_count $dsp_count]
    puts $csv [format "%s,%.6f,%s,%.6f,%.6f,%.6f,%d,%d,%s,%s" \
        $freq $period $status $wns $whs $fmax_est $coeff_count $dsp_count $timing_rpt $util_rpt]
    flush $csv

    catch {close_design}

    if {$status eq "PASS" && $first_pass eq ""} {
        set first_pass $freq
        break
    }
}

close $csv
puts "\nDesign B implementation Fmax sweep summary: $csv_path"
if {$first_pass ne ""} {
    puts "First passing requested frequency: ${first_pass} MHz"
} else {
    puts "No requested frequency passed timing."
}
