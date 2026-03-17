# Architecture Baseline (Week 1)

## Data path
1. `line_buffer_4`: builds a 5x5 RGB window from serial input stream.
2. `kernel_loader`: stores 25 signed kernel coefficients in Qn.4.
3. `mac_array_25x3`: performs per-channel 25-tap MAC and normalization.
4. `top_convolution`: ties streaming input/output with runtime kernel writes.

## Numeric format
- Pixel: 8-bit per channel (RGB packed into 24-bit)
- Kernel coefficient: signed 16-bit fixed-point, default Q12.4
- Accumulator: signed 48-bit per channel
- Normalize: arithmetic right-shift by `KERNEL_Q`
- Output clamp: saturate to [0, 255]

## Streaming behavior
- Input: one RGB pixel per valid cycle
- Window valid: asserted after warm-up (`x>=4 && y>=4`)
- Output valid: one cycle after window valid (MAC stage register)

## Throughput formula
- MPixels/s = `f_clk(MHz) * pixels_per_clock`
- Baseline currently targets 1 pixel/clock for bring-up
