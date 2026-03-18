# Output Spec Check (Final Combined Video)

Date: 2026-03-18
Artifact checked:

- captures/d455/output_live/final/realtime_comparison_all_kernels.mp4

Method:

- Read first frame from final 2x2 comparison video.
- Split into quadrants: input, gaussian, sharpen, laplacian.
- Compute basic intensity stats per quadrant.

## Measured stats

- input: mean=42.881, min=0, max=237, p255=0.0000
- gaussian: mean=41.867, min=0, max=238, p255=0.0000
- sharpen: mean=2.903, min=0, max=255, p255=0.0013
- laplacian: mean=0.917, min=0, max=241, p255=0.0000

## Interpretation against output spec

1. gaussian5 is not globally saturated:
   - mean is close to input mean.
   - p255 is zero in sampled frame.
   - this matches expected behavior after KERNEL_Q=8 fix.

2. sharpen5/laplacian5 are mostly dark with sparse highlights:
   - low means are expected for high-pass kernels in dark/low-texture scenes.
   - sparse high values indicate edge response, not full-frame failure.

3. Overall:
   - observed output is consistent with system logic and fixed-point spec.
