# Functional Spec Baseline (Week 1)

## Interfaces
### top_convolution
- Input stream: `in_valid`, `in_pixel[23:0]`
- Output stream: `out_valid`, `out_pixel[23:0]`
- Kernel write interface: `kernel_wr_en`, `kernel_wr_addr[4:0]`, `kernel_wr_data[15:0]`

## Border policy
- Zero-padding at image borders (implicit via cleared line buffers during warm-up)

## Reset behavior
- Synchronous clear of pipeline state and line-buffer state
- Kernel RAM resets to identity-like default (center tap = 1.0 in Qn.4)

## Verification checkpoints
- No X/Z on `out_pixel` when `out_valid=1`
- Kernel programming updates behavior without re-elaboration
- Identity-like kernel reproduces passthrough behavior once warm-up completes
