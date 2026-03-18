# convolution_fpga

Streaming RGB 5x5 convolution core for FPGA, with simulation-first verification and pre-board timing/power checks.

## 1) What this system guarantees

- Input format: 24-bit RGB (R[23:16], G[15:8], B[7:0]) in raster scan order.
- Window: 5x5 over streaming pixels.
- Border policy: output is valid only after warm-up (x>=4 and y>=4); non-valid border is zero in reconstructed frame.
- Arithmetic: signed 16-bit kernel coefficients, 48-bit accumulators, saturating clamp to [0..255].
- Fixed-point normalization: default KERNEL_Q=8.

## 2) Output-spec interpretation (important)

- gaussian5 should preserve average brightness (not clip to white) when coefficients sum to 256 and shift is 8.
- sharpen5 and laplacian5 are high-pass filters; dark background with bright edges is expected behavior, not failure.
- A "PASS" means RTL output matches golden expected stream and sample counts are consistent.

## 3) Quick run commands

### 3.1 RTL regression (all kernels)

- powershell -ExecutionPolicy Bypass -File .\scripts\run_regression.ps1

### 3.2 Live camera -> one combined demo video

- .\scripts\run_live_multi_kernel_demo.ps1 -CaptureRoot captures/d455/output_live -Width 640 -Height 480 -FeedWidth 320 -FeedHeight 240 -Frames 12 -Fps 30

Final artifact:

- captures/d455/output_live/final/realtime_comparison_all_kernels.mp4

### 3.3 RTL speed benchmark matrix

- .\scripts\benchmark_rtl_speed.ps1 -OutDir captures/benchmark/rtl_speed -Widths @(160,320,640) -Heights @(120,240,480) -Kernels @("gaussian5","sharpen5","laplacian5")

### 3.4 Vivado pre-board timing sweep

- .\scripts\sweep_clock_with_saif.ps1 -PeriodsNs @(50.0,40.0,35.0,30.0,25.0) -FrameHex .\captures\benchmark\rtl_speed\640x480\hex_in\frame_000000.hex -Kernel gaussian5 -Width 640 -Height 480 -SaifOut .\sim\activity.saif

## 4) Current architecture docs

- docs/architecture.md
- docs/board_streaming_guide.md
- docs/bug_report_2026-03-18.md
- docs/output_spec_check_2026-03-18.md

Consolidated seminar/run pack:

- docs/Spec_FPGA.md
- docs/Performance.md
- docs/RTL_REPORT.md
- docs/DESIGN_HARDWARE.md
- docs/Guide_to_Run.md

Architecture slide generator:

- python python/generate_architecture_ppt.py --out docs/architecture_convolution_fpga.pptx

## 5) Current implementation status

- Verified in RTL simulation: identity5, gaussian5, sharpen5, emboss5, laplacian5.
- Gaussian saturation bug fixed by moving to KERNEL_Q=8 and aligned golden kernels.
- AXI-Lite write-address race fixed for AW/W same-cycle and split transactions.
- Pre-board timing reference from sweep artifacts in captures/benchmark/vivado_speed.
- Spec-upgrade status (post O3+O2):
	- 40.000 MHz (25.000 ns): PASS, WNS=+0.460 ns, TNS=0
	- 50.000 MHz (20.000 ns): FAIL, WNS=-4.540 ns, TNS=-653.446 ns
	- 59.999 MHz (16.667 ns): FAIL, WNS=-7.873 ns, TNS=-1133.350 ns

## 6) Repository layout

- src/: SystemVerilog RTL modules
- tb/: simulation testbenches
- scripts/: powershell flows (sim, benchmark, sweep)
- python/: frame prep, golden model, processing, signoff tools
- docs/: architecture and bring-up guides
- captures/: generated benchmark/demo outputs
