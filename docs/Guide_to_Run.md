# Guide to Run - End-to-End Commands

## 1. Fast Start
- RTL regression:
  - powershell -ExecutionPolicy Bypass -File .\scripts\run_regression.ps1
- Benchmark RTL speed matrix:
  - powershell -ExecutionPolicy Bypass -File .\scripts\benchmark_rtl_speed.ps1 -OutDir captures/benchmark/rtl_speed -Widths @(160,320,640) -Heights @(120,240,480) -Kernels @("gaussian5","sharpen5","laplacian5")
- Timing sweep with SAIF:
  - powershell -ExecutionPolicy Bypass -File .\scripts\sweep_clock_with_saif.ps1 -PeriodsNs @(50.0,40.0,35.0,30.0,27.0,25.0,20.0,16.667) -FrameHex .\captures\benchmark\rtl_speed\640x480\hex_in\frame_000000.hex -Kernel gaussian5 -Width 640 -Height 480 -SaifOut .\sim\activity.saif

## 2. Script-to-Purpose Mapping
- scripts/run_regression.ps1
  - Purpose: full kernel functional regression on RTL testbench.
- scripts/run_sim.ps1
  - Purpose: run a simulation case and collect primary outputs.
- scripts/benchmark_rtl_speed.ps1
  - Purpose: campaign benchmark over resolution/kernel matrix.
- scripts/generate_saif_from_hex.ps1
  - Purpose: build SAIF activity from reproducible frame traffic.
- scripts/run_xsim_saif.ps1
  - Purpose: simulation stage focused on SAIF dump generation.
- scripts/run_power_with_saif.ps1
  - Purpose: Vivado power estimation using SAIF activity.
- scripts/sweep_clock_with_saif.ps1
  - Purpose: timing sweep across target periods with SAIF-aware flow.
- scripts/run_live_multi_kernel_demo.ps1
  - Purpose: camera demo orchestration and consolidated output artifacts.
- scripts/clean_project_generated.ps1
  - Purpose: cleanup generated build/sim artifacts.

## 3. Typical Execution Order for Signoff
1. Functional baseline:
  - run_regression.ps1
2. Benchmark artifact generation:
  - benchmark_rtl_speed.ps1
3. SAIF generation:
  - generate_saif_from_hex.ps1 or run_xsim_saif.ps1
4. Timing sweep:
  - sweep_clock_with_saif.ps1
5. Power report:
  - run_power_with_saif.ps1
6. Optional live demo:
  - run_live_multi_kernel_demo.ps1

## 4. Common Pitfalls
- Do not use mutable smoke/regression frame files for final benchmark decisions.
- Keep width/height/kernel settings synchronized across sim, benchmark, and sweep commands.
- If Vivado reports missing paths, stop and repair before trusting any derived metrics.

## 5. Python Utilities (supporting)
- python/prepare_case.py: generate kernel and expected outputs.
- python/golden_model.py: software reference behavior.
- python/rtl_process_hex_frames.py: process captured frame hex through RTL simulation flow.
- python/signoff_level_a.py: local signoff helper checks.
- python/generate_architecture_ppt.py: generate seminar architecture slide deck.

## 6. Generate Architecture Slide Deck
1. Install Python dependencies:
  - pip install -r python/requirements.txt
2. Generate pptx:
  - python python/generate_architecture_ppt.py --out docs/architecture_convolution_fpga.pptx

## 7. Recommended Deliverables Folder Set
- docs/Spec_FPGA.md
- docs/Performance.md
- docs/RTL_REPORT.md
- docs/DESIGN_HARDWARE.md
- docs/Guide_to_Run.md
