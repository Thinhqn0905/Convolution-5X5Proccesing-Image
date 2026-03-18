# Board Streaming Guide (D455 Real Data)

## Goal
Run real camera data through FPGA path, not software emulation.

## Reference Architecture
1. D455 color stream on host (RGB/BGR conversion as needed).
2. Host packetizes pixels and sends to programmable logic input interface.
3. FPGA `top_convolution` (through AXI stream wrapper) performs convolution.
4. Host receives processed stream and renders/stores output frames.

## Bring-up Sequence
1. Program FPGA bitstream.
2. Validate control path:
   - write kernel coefficients
   - read back control/status registers
3. Validate stream path with synthetic test pattern.
4. Switch input source to D455 real frames.
5. Compare selected frames against RTL simulation golden artifacts.

## Data Format Contract
- Pixel width: 24-bit packed RGB.
- Scan order: row-major, left-to-right, top-to-bottom.
- Valid policy: output valid only after 5x5 warm-up window.
- Border policy: output zeros for non-valid border region (or host-side crop), keep consistent across all flows.

## Host-side Requirements
1. Stable D455 capture at configured resolution and FPS.
2. Deterministic frame indexing.
3. Backpressure handling if DMA/stream sink is not always ready.
4. Kernel update command path separate from pixel stream.

## Recommended Validation Steps
1. Functional parity test:
   - Same input frame -> RTL sim output and board output should match (except agreed border policy).
2. Throughput test:
   - Measure sustained FPS and dropped frame count for 60s run.
3. Stability test:
   - Run 10+ minutes with periodic kernel switches.
4. Recovery test:
   - Reset/restart stream without power cycle.

## Checklist Before Live Demo
- Bitstream tested at chosen clock with timing-clean reports.
- Kernel switch verified in runtime.
- At least one end-to-end capture folder includes:
  - input frame(s)
  - board output frame(s)
  - compare summary (hash or mismatch count)
