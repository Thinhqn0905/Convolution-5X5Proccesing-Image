# Spec FPGA - RGB 5x5 Convolution Engine

## 1. Scope
- Platform: FPGA streaming pipeline with runtime-programmable 5x5 kernel.
- Data type: RGB888 input/output in raster order.
- Processing: signed fixed-point convolution with saturating clamp.
- Integration: AXI-Stream data path + AXI-Lite control path.

## 2. Functional Contract
- Window size: 5x5.
- Valid output region: x >= 4 and y >= 4 (warm-up border is invalid/zero in reconstructed frame).
- Throughput intent: 1 pixel per valid cycle in steady state.
- Kernel update: runtime write through AXI-Lite register interface.
- Numeric format:
  - Pixel: 8-bit unsigned per channel.
  - Coefficient: signed 16-bit.
  - Accumulator: signed 48-bit.
  - Normalization: arithmetic right shift by KERNEL_Q.

## 3. Fixed-Point Baseline
- KERNEL_Q default: 8.
- Identity center tap: 256.
- Gaussian 5x5 sum: 256.
- Expected behavior:
  - gaussian5 keeps average brightness.
  - sharpen5/laplacian5 emphasize edges and naturally produce dark backgrounds with highlighted contours.

## 4. Interface-Level Expectations
- AXI-Lite writes must correctly support:
  - AW and W in same cycle.
  - AW then W in later cycle.
  - W then AW in later cycle.
- AXI-Stream wrapper must preserve data ordering and report overflow when sink backpressure exceeds buffering assumptions.

## 5. Verification Gates
- Gate A (Functional): 5/5 kernels PASS in regression.
- Gate B (Data Path): capture artifacts include raw/feed/processed/hex_in/hex_out.
- Gate C (Stress): reset-mid-frame, valid-gap, saturation stress required before board signoff.
- Gate D (Timing): target clock must be timing-clean (WNS > 0, TNS = 0).
- Gate E (Power): SAIF-based estimation with confidence >= Medium.
- Gate F (Interface): AXI stream/lite backpressure and protocol robustness PASS.

## 6. Stretch Targets
- Primary closed target: 40 MHz clean.
- Stretch targets pending closure: 50 MHz and 60 MHz.

## 7. Key Risks
- AXI backpressure corner cases.
- SAIF activity mismatch reducing power confidence.
- Non-reproducible benchmark inputs if frame source is overwritten by other flows.

## 8. Spec Freeze Note
This document captures the current frozen baseline for pre-board integration and seminar reporting. Any change to KERNEL_Q, valid timing, or AXI behavior must update this file and the waveform checklist together.
