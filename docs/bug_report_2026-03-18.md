# Bug Report (Validated)

Date: 2026-03-18

This report captures 3 real bugs found in source and the fix status.

## Bug 1 (Critical): AXI-Lite AW address race

File:

- src/axi_lite_kernel_ctrl.sv

Symptom:

- If AWVALID and WVALID arrive in the same cycle, old latched address can be used.
- Write transaction may update wrong register or wrong coefficient slot.

Root cause:

- awaddr_latched is updated in always_ff (non-blocking), so case decode used previous-cycle value.

Fix applied:

- Added write_addr mux logic using current s_axil_awaddr when AWVALID is asserted.
- Added awaddr_valid tracking to support split AW/W transactions safely.
- Write executes when WVALID and (AWVALID or awaddr_valid).

Expected impact:

- Correct register decoding for both same-cycle and split AXI-Lite writes.

## Bug 2 (Critical): Wrong default normalization for gaussian

Files:

- src/top_convolution.sv
- src/mac_array_25x3.sv
- src/kernel_loader.sv
- src/axi_stream_conv_wrapper.sv
- python/prepare_case.py

Symptom:

- gaussian5 appears over-bright/washed-out due to excessive gain.

Root cause:

- KERNEL_Q default was 4 while gaussian5 coefficient sum is 256.
- Shift-by-4 caused 16x effective gain before clamp.

Fix applied:

- Default KERNEL_Q changed from 4 to 8 in core/wrapper modules.
- identity kernel center coefficient updated to 256 (1 << KERNEL_Q).
- Golden-model kernels in prepare_case.py aligned to Q8.

Expected impact:

- gaussian5 keeps brightness level instead of clipping to white.
- Expected stream and RTL outputs stay consistent.

## Bug 3 (Minor): Dead registers in MAC output stage

File:

- src/mac_array_25x3.sv

Symptom:

- r8/g8/b8 registers were written but never used in final pixel assignment.

Root cause:

- pixel_out used combinational r8_c/g8_c/b8_c directly.

Fix applied:

- Removed unused r8/g8/b8 declarations and assignments.

Expected impact:

- Cleaner RTL, less confusion, no behavior change.

## Verification summary after fixes

- Full RTL regression passes: identity5, gaussian5, sharpen5, emboss5, laplacian5.
- Live combined demo flow still runs and produces final video artifact.
- Visual-spec check: gaussian no longer clips to 255 flood; sharpen/laplacian remain edge-focused.
