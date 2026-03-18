# convolution_fpga

Programmable RGB 5x5 convolution engine project scaffold (Week 1-2 implementation start).

## Current scope
- Simulation-first workflow with Icarus Verilog + GTKWave
- Streaming RTL baseline for line buffer, kernel loader, MAC, and top integration
- Python tools for synthetic frame generation and golden-model verification

## Quick start
1. Create synthetic test frames:
   - `python python/synthetic_frames.py --out hex --count 10 --width 640 --height 480`
2. Prepare vectors for a selected kernel (example: identity5):
   - `python python/prepare_case.py --in_hex hex/test_frame_0.hex --width 16 --height 16 --kernel identity5 --kernel_out sim/kernel.hex --expected_out sim/expected.hex`
3. Run baseline simulation:
   - `cd tb`
   - `make -f Makefile.sim`
4. Open waveform:
   - `gtkwave ../sim/dump.vcd`

## Regression
- Run all required kernels (identity, gaussian, sharpen, emboss, laplacian):
  - `.\\scripts\\run_regression.ps1`

## D455 camera pipeline
- Realtime multi-kernel flow (capture once, process gaussian/sharpen/laplacian, output one final combined video):
   - `.\\scripts\\run_live_multi_kernel_demo.ps1 -CaptureRoot captures/d455/output_live -Width 640 -Height 480 -FeedWidth 320 -FeedHeight 240 -Frames 12 -Fps 30`

- Clean generated captures/logs while keeping final output:
   - `.\\scripts\\clean_project_generated.ps1 -KeepOutputDir captures/d455/output_live/final`

- Run capture/feed only (no software convolution):
   - `C:/Users/ADMIN/AppData/Local/Programs/Python/Python310/python.exe python/d455_stream_process.py --width 640 --height 480 --fps 30 --feed_width 640 --feed_height 480 --duration_sec 3 --max_frames 1 --save_every 1 --out_dir captures/d455/smoke`

- Run RTL processing for captured feed hex:
   - `C:/Users/ADMIN/AppData/Local/Programs/Python/Python310/python.exe python/rtl_process_hex_frames.py --workspace . --in_dir captures/d455/smoke/hex_in --out_dir captures/d455/smoke --kernel gaussian5 --width 640 --height 480 --python_exe C:/Users/ADMIN/AppData/Local/Programs/Python/Python310/python.exe`

## SAIF power flow (strict)
- Recommended strict flow (auto-detect path issues, fail-fast, one-shot repair):
   - `.\scripts\run_power_with_saif.ps1 -FrameHex .\captures\d455\full640_smoke\hex_in\frame_000000.hex -Kernel gaussian5 -Width 640 -Height 480 -SaifOut .\sim\activity.saif -VivadoBat E:\Vivado\2023.2\bin\vivado.bat`

- Clock sweep with SAIF:
   - `.\scripts\sweep_clock_with_saif.ps1 -PeriodsNs @(30.0,27.0,25.0) -FrameHex .\captures\d455\full640_smoke\hex_in\frame_000000.hex -Kernel gaussian5 -Width 640 -Height 480 -SaifOut .\sim\activity.saif -VivadoBat E:\Vivado\2023.2\bin\vivado.bat`

- If a path error is detected in Vivado output, scripts now stop immediately and print the log path under `vivado_project/reports/`.

Generated artifacts:
- `captures/d455/<kernel>/raw/*.png`
- `captures/d455/<kernel>/feed_rgb/*.png`
- `captures/d455/<kernel>/processed/*.png`
- `captures/d455/<kernel>/hex_in/*.hex`
- `captures/d455/<kernel>/hex_out/*.hex`

Final demo artifact:
- `captures/d455/output_live/final/realtime_comparison_all_kernels.mp4`

## Multi-frame benchmark campaign (640x480)
- Run capture + RTL processing + summary for multiple kernels:
   - `C:/Users/ADMIN/AppData/Local/Programs/Python/Python310/python.exe python/benchmark_campaign.py --workspace . --capture_dir captures/d455/campaign640 --frames 1 --width 640 --height 480 --fps 30 --kernels gaussian5 sharpen5 --python_exe C:/Users/ADMIN/AppData/Local/Programs/Python/Python310/python.exe`

- Outputs:
   - `captures/d455/campaign640/campaign_summary.json`
   - `captures/d455/campaign640/rtl_benchmark_<kernel>.json`
   - `captures/d455/campaign640/rtl_benchmark_<kernel>.csv`

## Speed benchmark (pre-board)
- RTL simulation speed benchmark across resolutions/kernels:
   - `.\\scripts\\benchmark_rtl_speed.ps1 -OutDir captures/benchmark/rtl_speed -Widths @(160,320,640) -Heights @(120,240,480) -Kernels @("gaussian5","sharpen5","laplacian5")`

- Vivado timing/power sweep benchmark (no board needed):
   - `.\\scripts\\sweep_clock_with_saif.ps1 -PeriodsNs @(50.0,40.0,35.0,30.0,25.0) -FrameHex .\\hex\\test_frame_0.hex -Kernel gaussian5 -Width 640 -Height 480 -SaifOut .\\sim\\activity.saif`

- Research summary:
   - `docs/performance_research_2026-03-18.md`

## AXI wrapper baseline test
- Compile and run AXI Stream wrapper testbench:
   - `cd tb`
   - `iverilog -g2012 -Wall -o ..\\sim\\sim_axi.vvp ..\\src\\top_convolution.sv ..\\src\\line_buffer_4.sv ..\\src\\kernel_loader.sv ..\\src\\mac_array_25x3.sv ..\\src\\pipeline_stage.sv ..\\src\\axi_stream_conv_wrapper.sv tb_axi_stream_conv_wrapper.sv`
   - `vvp ..\\sim\\sim_axi.vvp`

## Project layout
- docs/: architecture/spec/simulation notes
- src/: SystemVerilog RTL modules
- tb/: testbenches and sim Makefile
- python/: data generation and golden model tools
- hex/: frame hex files
- sim/: generated simulation outputs
- vivado_project/: reserved for synthesis flow

## Verification and board bring-up docs
- Pre-board verification gates: `docs/pre_board_verification_plan.md`
- Board streaming with real data: `docs/board_streaming_guide.md`
- SAIF power methodology: `docs/saif_power_flow.md`
