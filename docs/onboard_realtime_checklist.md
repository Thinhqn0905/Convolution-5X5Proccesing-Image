# On-board Realtime Checklist

Updated: 2026-03-18 (strict SAIF flow)

## 1) Toolchain readiness
- [x] Vivado executable resolved from E:/Vivado/2023.2/bin/vivado.bat
- [x] Batch TCL flow runs from workspace scripts

## 2) Synthesis and implementation execution
- [x] run_synth.tcl executed end-to-end
- [x] Reports generated:
  - vivado_project/reports/timing_post_synth.rpt
  - vivado_project/reports/util_post_synth.rpt
  - vivado_project/reports/timing_post_route.rpt
  - vivado_project/reports/util_post_route.rpt
  - vivado_project/reports/power_post_route.rpt

## 3) Extracted signoff metrics (post-route)
- Bring-up baseline: 20.000 MHz (period 50.000 ns)
- Timing:
  - WNS: +22.577 ns @ 50 ns
  - TNS: 0.000 ns
  - Setup failing endpoints: 0
  - Hold WNS: +0.102 ns
  - Status: PASS @ 50 ns (all user specified timing constraints are met)
- Sweep checkpoint:
  - 40.000 MHz (period 25.000 ns): FAIL (WNS=-1.060 ns, TNS=-121.329 ns)
- Utilization:
  - Slice LUTs: 930 (1.75%)
  - Slice Registers: 203 (0.19%)
  - Block RAM Tile: 1 (0.71%)
  - DSPs: 78 (35.45%)
- Power:
  - Total On-Chip Power: 0.127 W
  - Dynamic: 0.022 W
  - Device Static: 0.105 W
  - Confidence level: Medium
  - Activity annotation: SAIF loaded, design net match is low (~2%)

## 4) Functional gating before realtime
- [x] SAIF activity flow wired end-to-end (D455 hex -> XSIM SAIF -> Vivado report_power)
- [x] Path-error strict handling in scripts (fail-fast + one-shot repair)
- [ ] SAIF mapping coverage high enough for final signoff confidence (current low)

## 5) Final readiness state
- Realtime-ready: NO
- Blocking items:
  1. Timing closure at production clock target (not only bring-up clock)
  2. Full AXI stream/lite handshake hardening and DMA integration test
  3. Power estimation confidence uplift with meaningful activity mapping

## 6) Immediate next actions
1. Raise clock stepwise (20 -> 30 -> 35 -> 40 MHz), re-run impl each step to find first clean production point.
2. Keep pipelining around MAC/output and add optional register slice at wrapper output.
3. Complete AXI protocol hardening testbench with randomized tready/backpressure and no overflow.
4. Generate mapped SAIF from gate-level/post-synth simulation to improve power confidence.
