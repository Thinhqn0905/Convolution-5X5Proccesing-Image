# Performance Research and Benchmark (2026-03-18)

## 1) Why simulation FPS is low but FPGA can still be realtime
RTL simulation wall-time (`iverilog`/`vvp` or `xsim`) is software emulation on CPU, not hardware speed.
Real hardware speed is determined by:

- `pixels_per_clock` (current design: ~1)
- `clock_frequency`
- `valid_window_overhead` (5x5 border warm-up)

For 640x480@30fps, required input rate is:

- `640 * 480 * 30 = 9.216 MPixel/s`

Even at 20 MHz if design accepts 1 pixel/clock:

- Peak throughput ~= `20 MPixel/s` > `9.216 MPixel/s`

So low simulation FPS does not automatically mean board realtime is impossible.

## 2) RTL simulation benchmark (this run)
Command used:

```powershell
.\scripts\benchmark_rtl_speed.ps1 -OutDir captures/benchmark/rtl_speed -Widths @(160,320,640) -Heights @(120,240,480) -Kernels @("gaussian5","sharpen5","laplacian5")
```

Summary files:

- `captures/benchmark/rtl_speed/rtl_speed_summary.csv`
- `captures/benchmark/rtl_speed/rtl_speed_summary.json`

Key results:

| Size | Kernel set | Sim wall per frame | Sim FPS | Sim cycles/frame | Estimated HW FPS @20MHz | Estimated HW FPS @40MHz |
|---|---|---:|---:|---:|---:|---:|
| 160x120 | g/s/l | ~5.3-5.6 s | ~0.18 | 19,334 | 1034.4 | 2068.9 |
| 320x240 | g/s/l | ~18.1-18.6 s | ~0.054 | 76,934 | 260.0 | 519.9 |
| 640x480 | g/s/l | ~69.1-71.5 s | ~0.014 | 307,334 | 65.1 | 130.2 |

All tested cases: `TB PASS`.

## 3) Vivado pre-board benchmark sweep (this run)
Command used:

```powershell
.\scripts\sweep_clock_with_saif.ps1 -PeriodsNs @(50.0,40.0,35.0,30.0,25.0) -FrameHex .\hex\test_frame_0.hex -Kernel gaussian5 -Width 640 -Height 480 -SaifOut .\sim\activity.saif
```

Results:

| Period (ns) | Freq (MHz) | WNS (ns) | TNS (ns) | Status |
|---:|---:|---:|---:|---|
| 50.0 | 20.0 | 22.577 | 0 | PASS |
| 40.0 | 25.0 | 12.577 | 0 | PASS |
| 35.0 | 28.571 | 7.451 | 0 | PASS |
| 30.0 | 33.333 | 2.577 | 0 | PASS |
| 25.0 | 40.0 | -1.060 | -121.329 | FAIL |

Conclusion:

- Current clean pre-board operating point: up to about `33.3 MHz`.
- `40 MHz` still fails timing and needs more pipelining/retiming.

## 4) Fastest path to increase speed now
Priority from highest impact to lowest implementation risk:

1. **Use timing-clean clock immediately**: set runtime target around `30-33 MHz` first.
2. **Keep host capture at 640x480 but reduce feed size for validation loops** (`320x240`) to accelerate simulation turn-around.
3. **Separate performance goals**:
   - Functional regression in simulation.
   - Realtime target validated by Vivado timing throughput first.
4. **Push timing to 40 MHz with RTL micro-architecture updates**:
   - add pipeline register slice around MAC accumulation output.
   - reduce long combinational control fanout.
   - review DSP48 chaining depth and register enables.
5. **After timing closure, integrate DMA/AXI stream in block design for real board realtime proof.**

## 5) Clarification about Python role
Python in this repo is orchestrator only:

- capture camera
- prepare vectors
- invoke RTL simulator
- build visualization artifacts

Convolution compute still runs in RTL modules under `src/`.

## 6) Updated script set
Current recommended scripts under `scripts/`:

- `run_live_multi_kernel_demo.ps1` (primary camera->RTL demo)
- `benchmark_rtl_speed.ps1` (systematic RTL speed benchmark)
- `sweep_clock_with_saif.ps1` (pre-board timing sweep)
- `run_power_with_saif.ps1` (power/timing signoff pass)
- `run_regression.ps1` and `run_sim.ps1` (core verification)
- `clean_project_generated.ps1` (cleanup)
