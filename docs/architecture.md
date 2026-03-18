# Architecture (Detailed)

## 1) Top-level pipeline

Data path (one pixel per valid cycle):

1. line_buffer_4.sv
2. kernel_loader.sv
3. mac_array_25x3.sv
4. top_convolution.sv

Control and integration:

- axi_lite_kernel_ctrl.sv: register writes for runtime kernel updates.
- axi_stream_conv_wrapper.sv: stream handshake and output buffering.

## 2) Module responsibilities

### line_buffer_4.sv

- Builds the 5x5 RGB window from incoming raster stream.
- Asserts valid only when full spatial context is available.
- Determines border behavior indirectly by valid gating.

### kernel_loader.sv

- Stores 25 signed coefficients (5x5).
- Runtime writes: wr_en, wr_addr, wr_data.
- Reset default kernel is identity center tap = (1 << KERNEL_Q).

### mac_array_25x3.sv

- Computes per-channel sum(win * coeff) over 25 taps.
- Uses a pipelined MAC flow:
	- Stage S1: register per-tap products (pixel * coeff).
	- Stage S2: sum products with grouped reduction (5 rows -> lo/hi partials) and register partial accumulators.
	- Stage S3: combine accumulators, normalize by `>>> KERNEL_Q`, saturate to 8-bit, register output pixel.
- Applies arithmetic right shift by KERNEL_Q.
- Saturates each channel to unsigned 8-bit.

### top_convolution.sv

- Connects line buffer, kernel loader, and MAC.
- Default KERNEL_Q is 8.
- Exposes clean streaming-style in/out and kernel write signals.

### axi_lite_kernel_ctrl.sv

- AXI-Lite register map for control/status and kernel write transactions.
- Handles AW+W same-cycle writes and split AW/W transactions safely.
- Generates kernel_wr_en pulse on commit register write.

### axi_stream_conv_wrapper.sv

- Maps AXI-Stream input to top_convolution.
- Buffers output and flags overflow if sink backpressures while core emits.

## 3) Numeric format and scaling

- Pixel: 8-bit unsigned per channel.
- Coefficients: signed 16-bit fixed-point.
- Accumulators: signed 48-bit.
- Normalization: >>> KERNEL_Q, default 8.

Why KERNEL_Q=8:

- gaussian5 coefficients sum to 256, so divide-by-256 keeps brightness.
- KERNEL_Q=4 would multiply effective gain by 16 and clip highlights.

Kernel conventions in prepare_case.py:

- identity5 uses center=256.
- gaussian5 uses Pascal-style coefficients summing to 256.
- sharpen5/laplacian5/emboss5 are scaled for Q8 operation.

## 4) Timing and latency model

- Window-valid starts after line-buffer warm-up.
- MAC uses two internal valid pipeline stages before output register.
- `u_mac_array.valid_out` is 2 cycles behind `u_mac_array.valid_in`.
- Relative to line-buffer valid, output-valid is shifted by 2 cycles.
- Throughput target in architecture is 1 pixel/clock once valid stream is active.

## 5) Expected visual behavior by kernel

- identity5: near exact pass-through (after border policy).
- gaussian5: smoothed image, no global whitening.
- sharpen5: edge emphasis; many near-zero pixels in low-texture areas.
- laplacian5: edge map style output; mostly dark with contour highlights.

## 6) Main failure modes to watch

- Wrong coefficient scaling vs KERNEL_Q.
- AXI-Lite address/write ordering bugs.
- Border/valid-count mismatch between TB and frame reconstruction.
- Output overflow if stream sink cannot accept data in wrapper.
