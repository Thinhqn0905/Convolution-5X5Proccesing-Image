# Report post-route power for Design B from an existing routed checkpoint.
#
# Usage:
#   set POWER_ACTIVITY_FILE=sim/activity_design_b_200MHz.saif
#   vivado.bat -mode batch -source scripts/report_power_design_b.tcl

if {[info exists ::env(ROUTED_DCP)] && $::env(ROUTED_DCP) ne ""} {
    set routed_dcp [file normalize $::env(ROUTED_DCP)]
} else {
    set routed_dcp [file normalize "vivado_project/fmax_sweep_impl_design_b/200MHz/routed.dcp"]
}

if {[info exists ::env(POWER_RPT)] && $::env(POWER_RPT) ne ""} {
    set power_rpt [file normalize $::env(POWER_RPT)]
} else {
    set power_rpt [file normalize "vivado_project/fmax_sweep_impl_design_b/200MHz/power_post_route_saif.rpt"]
}

set activity_file ""
if {[info exists ::env(POWER_ACTIVITY_FILE)] && $::env(POWER_ACTIVITY_FILE) ne ""} {
    set activity_file [file normalize $::env(POWER_ACTIVITY_FILE)]
}

if {![file exists $routed_dcp]} {
    error "Routed checkpoint not found: $routed_dcp"
}

open_checkpoint $routed_dcp

if {$activity_file ne "" && [file exists $activity_file]} {
    puts "Applying activity data from $activity_file"
    set strip_candidates [list "tb_activity_saif/dut" "/tb_activity_saif/dut" ""]
    set saif_ok 0
    foreach sp $strip_candidates {
        if {$sp eq ""} {
            set rc [catch {read_saif $activity_file} saif_msg]
            puts "SAIF import try: no strip_path => $saif_msg"
        } else {
            set rc [catch {read_saif $activity_file -strip_path $sp} saif_msg]
            puts "SAIF import try: strip_path=$sp => $saif_msg"
        }
        if {$rc == 0} {
            set saif_ok 1
            break
        }
    }
    if {!$saif_ok} {
        puts "WARNING: SAIF import failed for all strip_path candidates; using default activity."
    }
} else {
    puts "No activity file provided; power uses default toggle assumptions."
}

report_power -file $power_rpt
puts "Power report: $power_rpt"
