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

## Project layout
- docs/: architecture/spec/simulation notes
- src/: SystemVerilog RTL modules
- tb/: testbenches and sim Makefile
- python/: data generation and golden model tools
- hex/: frame hex files
- sim/: generated simulation outputs
- vivado_project/: reserved for synthesis flow
