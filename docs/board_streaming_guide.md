# FPGA Bring-up and Streaming Guide

## 1) Objective

Run real camera data through FPGA datapath (not software-only emulation), and confirm output parity with RTL references.

## 2) Pre-board checklist

1. RTL regression passes all kernels.
2. Vivado timing sweep identifies a timing-clean operating point.
3. SAIF-based power flow completes with no script/path errors.
4. AXI-Lite kernel write/read path is validated.

## 3) Hardware data contract

- Input pixels: 24-bit RGB packed.
- Scan order: row-major, left-to-right, top-to-bottom.
- Kernel size: 5x5.
- Output valid starts after warm-up (x>=4, y>=4).
- Border handling must match host-side reconstruction/comparison rules.

## 4) Bring-up sequence on FPGA

1. Program bitstream.
2. Initialize AXI-Lite registers and load coefficients.
3. Run synthetic frame through AXI stream path.
4. Capture output frame from sink/DMA.
5. Compare FPGA output with RTL expected output for same input.
6. Switch source to live camera stream.

## 5) Kernel loading protocol

For each tap:

1. Write address register.
2. Write coefficient register.
3. Write commit register bit0=1.

Then start/enable stream path.

## 6) Validation gates

- Functional gate:
  - mismatch count is zero against expected stream for known test vectors.
- Throughput gate:
  - sustained frame rate at chosen clock and resolution for >=60s.
- Stability gate:
  - no deadlock/data-loss over long run with kernel switches.
- Recovery gate:
  - stream restart/reset works without full power cycle.

## 7) Debug priorities when output looks wrong

1. Confirm KERNEL_Q and coefficient scale consistency.
2. Read back programmed coefficients.
3. Check valid-count and frame alignment (warm-up offset).
4. Inspect AXI-Lite write ordering and transaction timing.
5. Verify stream backpressure/overflow behavior.

## 8) Practical recommendation from current pre-board data

- Use timing-clean clock point from sweep summary as baseline.
- Improve critical path before pushing to higher frequency targets.
- Keep 320x240 for fast iteration, reserve 640x480 for signoff.
