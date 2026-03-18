# On-board Realtime Checklist

Updated: 2026-03-18 (post O3/O2 spec-upgrade sweep)

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
  - PASS @ 40.000 MHz (period 25.000 ns): WNS=+0.460 ns, TNS=0.000 ns
  - PASS @ 37.037 MHz (period 27.000 ns): WNS=+2.460 ns, TNS=0.000 ns
  - FAIL @ 50.000 MHz (period 20.000 ns): WNS=-4.540 ns, TNS=-653.446 ns
  - FAIL @ 59.999 MHz (period 16.667 ns): WNS=-7.873 ns, TNS=-1133.350 ns
  - Current clean production point: 40 MHz
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
- Realtime-ready: PARTIAL
- Blocking items:
  1. Stretch-goal timing closure beyond 40 MHz (50/60 MHz still fail)
  2. Full AXI stream/lite handshake hardening and DMA integration test
  3. Power estimation confidence uplift with meaningful activity mapping

## 6) Immediate next actions
1. If targeting >40 MHz, add optional output register slice in stream wrapper and re-run 20 ns / 16.667 ns sweep.
2. Investigate multi-cycle floorplanning constraints for MAC-local paths only if functional protocol remains unchanged.
3. Complete AXI protocol hardening testbench with randomized tready/backpressure and no overflow.
4. Generate mapped SAIF from gate-level/post-synth simulation to improve power confidence.

## 7) Level-A local demo evidence (no board)
- [x] Local stream demo artifacts generated from captured frames:
  - `captures/d455/benchmark640/preview_side_by_side.mp4`
  - `captures/d455/benchmark640/level_a_signoff.md`
  - `captures/d455/benchmark640/level_a_signoff.json`
- [x] Level-A signoff status: PASS
  - parity(raw/feed/processed/hex_in/hex_out) = PASS
  - per-frame TB status = PASS
  - mismatch total = 0
  - unknown total = 0
  - timing baseline check @50ns = PASS
