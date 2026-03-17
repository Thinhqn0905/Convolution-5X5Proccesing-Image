# Waveform Checklist (5x5 RGB, 16x16 test)

Use this checklist with GTKWave on `sim/dump.vcd`.

## Signals to inspect

## Testbench-level
- `tb_convolution.clk`
- `tb_convolution.rst`
- `tb_convolution.in_valid`
- `tb_convolution.in_pixel[23:0]`
- `tb_convolution.out_valid`
- `tb_convolution.out_pixel[23:0]`
- `tb_convolution.valid_count`
- `tb_convolution.mismatch_count`
- `tb_convolution.unknown_count`
- `tb_convolution.exp_wr_ptr`
- `tb_convolution.exp_rd_ptr`

## DUT internal
- `tb_convolution.dut.lb_valid`
- `tb_convolution.dut.u_line_buffer.x_count`
- `tb_convolution.dut.u_line_buffer.y_count`
- `tb_convolution.dut.u_line_buffer.valid_out`
- `tb_convolution.dut.u_mac_array.valid_in`
- `tb_convolution.dut.u_mac_array.valid_out`
- `tb_convolution.dut.kernel_wr_en`
- `tb_convolution.dut.kernel_wr_addr`
- `tb_convolution.dut.kernel_wr_data`

## Expected behavior

## Warm-up and valid window
- Kernel size is 5, so line buffer needs 4 pixels history in x and y.
- First line-buffer valid condition is when `x_count>=4` and `y_count>=4`.
- Expected valid samples for a frame is:
  - `(W - 4) * (H - 4)`
  - For 16x16: `12 * 12 = 144`

## Valid alignment through pipeline
- `u_mac_array.valid_out` must be delayed by 1 clock relative to `u_line_buffer.valid_out`.
- `out_valid` must follow this 1-cycle delayed pattern continuously during active output region.

## Kernel programming sanity
- During setup, `kernel_wr_en` must pulse 25 times.
- Center tap index `12` must be written with value `16`.
- All other tap indices must be written with value `0`.

## Output correctness indicators
- While `out_valid=1`, `out_pixel` must never be X/Z.
- `unknown_count` must stay at `0`.
- `mismatch_count` must stay at `0`.
- End-of-test counters must satisfy:
  - `valid_count=144`
  - `exp_rd_ptr=exp_wr_ptr`

## Common wrong patterns and meaning
- `out_valid` never rises:
  - Line-buffer warm-up logic or input valid stream is broken.
- `out_valid` rises but `valid_count` is not 144:
  - Boundary/warm-up condition mismatch.
- `unknown_count>0`:
  - Uninitialized path in kernel/window/data flow.
- `mismatch_count>0` with stable valid:
  - Expected mapping wrong, channel packing mismatch, or kernel write failure.
- `exp_rd_ptr<exp_wr_ptr` at finish:
  - Missing output samples.
- `exp_rd_ptr>exp_wr_ptr` during run:
  - Unexpected extra output samples.

## 5-minute pass/fail checklist
1. Confirm reset deasserts and input stream starts.
2. Confirm kernel writes include index 12 value 16 and others 0.
3. Confirm first valid appears only after warm-up.
4. Confirm `valid_out` in MAC is exactly 1 cycle after line-buffer valid.
5. Confirm no X on `out_pixel` when `out_valid=1`.
6. Confirm final counters: `valid_count=144`, `mismatch_count=0`, `unknown_count=0`.
7. Confirm `tb_out.hex` has 144 lines.
