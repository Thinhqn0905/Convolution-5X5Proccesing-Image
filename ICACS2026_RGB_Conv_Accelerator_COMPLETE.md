# Design and Post-Route Evaluation of a Runtime-Configurable RGB 5x5 Convolution FPGA Core for Full-HD Image Filtering

**Pham Quoc Thinh, Truong Le Ngoc Quyen, Le Nguyen Anh Tu**  
Faculty of Electronics and Telecommunications, University of Science, VNU-HCM  
Ho Chi Minh City, Vietnam

> Submission note: verify author order, affiliation, and e-mail addresses before submission.

## Abstract

This paper presents a runtime-configurable FPGA core for real-time RGB 5x5 convolution streaming. The proposed design targets image-filtering workloads in which a raster-scanned RGB888 stream is processed with a programmable 25-tap spatial kernel. The architecture integrates a four-line-buffer window generator, a signed fixed-point kernel loader, a fully parallel RGB multiply datapath, a multi-stage reduction tree, 48-bit accumulation, fixed-point normalization, and saturation to RGB888 output. The computational datapath processes one input pixel per clock after the initial line-buffer fill latency. The RTL implementation was written in SystemVerilog and verified against a bit-accurate Python golden model using identity, Gaussian, high-pass sharpen, Laplacian, and emboss kernels. A Full-HD stress test using an Intel RealSense D455 frame resized to a 1920x1080 input feed produced 2,061,616 valid output samples with zero mismatches against the golden reference for all evaluated kernels. Post-route implementation on a Xilinx Artix-7 XC7A100T device reaches 146 MHz, corresponding to 146 Mpixels/s and approximately 70.4 frames/s for 1920x1080 active-frame processing. The implemented convolution datapath uses 2,528 LUTs, 521 flip-flops, 1.5 block RAM tiles, and 96 DSP blocks. These results demonstrate that a compact streaming RTL architecture can provide deterministic Full-HD image-filtering throughput while retaining runtime kernel programmability.

**Keywords:** FPGA, RGB convolution, image filtering, line buffer, fixed-point arithmetic, streaming accelerator, SystemVerilog, Full-HD.

## I. Introduction

Spatial convolution is a fundamental operation in embedded image and video processing. It is widely used for smoothing, sharpening, edge extraction, embossing, feature enhancement, and as a preprocessing stage for higher-level vision pipelines. For an RGB 5x5 filter, each output pixel requires 25 multiplications and 24 additions per color channel, or 75 multiplications and 72 additions for one RGB pixel. At 1920x1080 and 60 frames/s, the active-frame pixel rate is 124.4 Mpixels/s; therefore, a direct RGB 5x5 implementation requires approximately 9.33 billion multiplications per second before considering memory-access overhead.

General-purpose processors and software libraries provide high flexibility, but they are not always ideal for deterministic high-throughput embedded video pipelines. Field-programmable gate arrays (FPGAs) are well suited to this workload because the local-neighborhood nature of 2D convolution can be mapped to line buffers, shift registers, parallel multipliers, and deeply pipelined reduction trees. This allows one-pixel-per-clock streaming once the window generator is filled.

This work presents a SystemVerilog implementation and post-route evaluation of a runtime-configurable RGB888 5x5 convolution core. The focus is not a new convolution algorithm; rather, the contribution is a complete RTL datapath that turns programmable 5x5 RGB convolution into a reusable streaming FPGA core with measured timing, resource usage, power estimation, and image-level verification.

The main contributions are:

1. A streaming RGB888 5x5 convolution datapath with runtime-programmable signed 16-bit coefficients.
2. A four-line-buffer and shift-register window generator that avoids full-frame storage.
3. A fully parallel 25-tap x 3-channel MAC datapath with staged products, hierarchical reduction, 48-bit accumulation, fixed-point normalization, and saturation.
4. A verification flow using SystemVerilog simulation and a bit-accurate Python golden model across five representative kernels.
5. Post-route evaluation on a Xilinx Artix-7 XC7A100T device, including Fmax, resource utilization, preliminary power, and Full-HD frame validation.

## II. Background and Related Work

For a single color channel, a 5x5 spatial convolution can be written as

```text
Y(x,y) = sum_{m=0}^{4} sum_{n=0}^{4} I(x+m,y+n) K(m,n)
```

For RGB888 data, the same kernel is applied independently to the red, green, and blue channels:

```text
Y_c(x,y) = sum_{m=0}^{4} sum_{n=0}^{4} I_c(x+m,y+n) K(m,n), c in {R,G,B}.
```

The design in this work stores coefficients as signed 16-bit fixed-point values with 8 fractional bits. After accumulation, the result is shifted right by 8 bits and clamped to the 8-bit output range.

FPGA-based 2D convolution has been studied extensively because the operation has high arithmetic intensity and regular data reuse. Toledo-Moreo et al. proposed a real-time FPGA architecture for medium-to-large 2D convolution kernels using distributed arithmetic [1]. Kabbai et al. examined FPGA implementation of Gaussian filtering and compared hardware and software image quality using PSNR [2]. Joginipelly and Charalampidis studied separable convolution on FPGA to reduce resource usage and memory bandwidth for suitable kernels [3]. More recent image-filtering architectures continue to investigate low-latency and high-throughput designs; for example, Gould et al. presented a row-by-row feed-forward architecture for image filtering [4], while Campos et al. showed recent FPGA spatial-filter generation targeting 1080p60 video [5]. Commercial work also shows practical demand for 5x5 RGB convolution IP with Full-HD throughput on Xilinx 7-series devices [6].

Compared with fixed-filter implementations, the present work supports runtime coefficient loading. Compared with separable-filter designs, it supports arbitrary 5x5 kernels, including non-separable Laplacian, emboss, and high-pass kernels. The trade-off is higher DSP usage because all taps and RGB channels are computed in parallel to sustain one-pixel-per-clock throughput.

## III. Proposed Architecture

### A. Top-Level Dataflow

The proposed convolution core receives one RGB888 pixel per clock when `in_valid` is asserted. The input stream follows raster-scan order. The top-level datapath consists of:

- `line_buffer_4.sv`: four previous-row buffers and 5x5 window generation.
- `kernel_loader.sv`: runtime storage for 25 signed 16-bit coefficients.
- `mac_array_25x3.sv`: RGB 25-tap multiply and reduction pipeline.
- `top_convolution.sv`: integration of line buffer, kernel loader, and MAC array.

The repository also contains AXI4-Stream and AXI4-Lite wrapper modules for system integration. The post-route timing and resource numbers reported in this paper are measured for the convolution datapath top module, `top_convolution`, with `IMAGE_WIDTH=1920`.

![Hardware architecture](paper/figures/fig_top_architecture.png)

**Fig. 1.** Streaming architecture of the RGB 5x5 convolution core.

### B. Line Buffer and Window Generator

A direct 5x5 convolution requires five adjacent image rows. Storing a complete frame would be inefficient for a streaming FPGA datapath, so the design uses four line buffers to retain the previous four image rows. Together with the current row, these buffers provide five vertically aligned pixels for the current column. A horizontal shift-register structure then forms the complete 5x5 spatial window.

After the initial filling latency, the window generator asserts a valid signal for pixels whose complete 5x5 neighborhood is available. For a 1920x1080 input frame and no padded border output, the number of valid output samples is

```text
(1920 - 4) x (1080 - 4) = 2,061,616 pixels.
```

This matches the Full-HD simulation result used in the verification flow.

### C. Runtime Kernel Loader

The kernel loader stores 25 signed 16-bit coefficients and exports them as a flattened bus to the MAC array. Coefficients are written through `kernel_wr_en`, `kernel_wr_addr`, and `kernel_wr_data`. In the system wrapper, these signals can be driven by the AXI4-Lite control block or by the UART frame parser used for board-level demonstration. The evaluated kernels include identity, Gaussian, high-pass sharpen, Laplacian, and emboss filters.

For brightness-preserving filters, the coefficient sum should equal 256 because the datapath normalizes by an arithmetic right shift of 8 bits. The Gaussian kernel used in this work satisfies this condition. Kernels with a zero or near-zero sum, such as Laplacian and high-pass filters, are expected to produce edge-like outputs and may appear dark after negative values are clamped to zero.

### D. Processing Element and MAC Pipeline

The computational heart of the design is `mac_array_25x3.sv`. For each tap index `i`, the datapath extracts one RGB888 pixel from `window_flat` and one signed coefficient from `kernel_flat`. The pixel is split into three 8-bit channels, and the same coefficient is applied to the R, G, and B channels in parallel:

```text
mul_r[i] = signed({1'b0, px_r}) x coeff
mul_g[i] = signed({1'b0, px_g}) x coeff
mul_b[i] = signed({1'b0, px_b}) x coeff
```

The products are registered before entering the array-level reduction tree. This structure maps multiplication to DSP resources and keeps the critical path shorter than an unregistered product-plus-reduction implementation.

![PE datapath](paper/figures/fig_pe_core_datapath.png)

**Fig. 2.** Processing element datapath for one 5x5 convolution tap.

The reduction tree combines the 25 products per channel through multiple stages. The final accumulator width is 48 bits, which provides headroom for signed kernels and avoids intermediate overflow for the evaluated coefficient ranges. After accumulation, the result is arithmetically shifted right by 8 bits and saturated to `[0,255]` before being repacked as RGB888.

## IV. Implementation and Verification

### A. RTL Implementation

The accelerator was implemented in SystemVerilog. The main design parameters are listed in Table I.

**Table I. Design parameters**

| Parameter | Value |
|---|---:|
| Input/output pixel format | RGB888 |
| Kernel size | 5x5 |
| Number of taps | 25 |
| Color channels | 3 |
| Multiplications per output pixel | 75 |
| Coefficient format | signed 16-bit, Q8 fractional scaling |
| Product register width | 32-bit signed |
| Accumulator width | 48-bit signed |
| Output normalization | arithmetic shift right by 8 |
| Output clamp | saturation to 8-bit unsigned |
| Throughput after fill | 1 pixel/clock |
| Timing top used for post-route results | `top_convolution` |

### B. Verification Methodology

The functional verification flow uses Python to generate input frames, kernel files, and expected output data. The SystemVerilog testbench streams the input pixels into the RTL core and writes the RTL output stream to a HEX file. The output is then compared against the Python golden model on a pixel-by-pixel and channel-by-channel basis.

The following kernels were evaluated:

- `identity5`: center coefficient 256, all other coefficients zero.
- `gaussian5`: symmetric 5x5 Gaussian-like blur, coefficient sum 256.
- `sharpen5`: high-pass/edge-like kernel used as a stress case.
- `laplacian5`: signed edge-detection kernel.
- `emboss5`: directional relief filter.

For Full-HD validation, an Intel RealSense D455 RGB frame was captured at 1280x720 and resized to a 1920x1080 feed before being streamed through the RTL simulation. This test stresses the datapath at the target Full-HD frame size while avoiding an unsupported claim of direct D455-to-FPGA real-time Full-HD capture.

**Table II. Full-HD RTL/golden verification**

| Kernel | RTL status | Golden compare | Valid samples | Mismatch pixels | Mismatch channels |
|---|---:|---:|---:|---:|---:|
| identity5 | PASS | PASS | 2,061,616 | 0 | 0 |
| gaussian5 | PASS | PASS | 2,061,616 | 0 | 0 |
| sharpen5 | PASS | PASS | 2,061,616 | 0 | 0 |
| laplacian5 | PASS | PASS | 2,061,616 | 0 | 0 |
| emboss5 | PASS | PASS | 2,061,616 | 0 | 0 |

No mismatch was observed across the evaluated Full-HD kernel tests.

## V. Experimental Results and Discussion

### A. Timing and Throughput

The design was implemented with Xilinx Vivado 2023.2 targeting the Xilinx Artix-7 `xc7a100tcsg324-1` device. A post-route frequency sweep was performed on `top_convolution` with `IMAGE_WIDTH=1920`. The design passed timing at 146 MHz and failed slightly at 147 MHz, indicating a practical Fmax around 146 MHz for the current implementation flow.

**Table III. Post-route Fmax sweep**

| Clock target | Period | Status | WNS | WHS | Estimated Fmax |
|---:|---:|---:|---:|---:|---:|
| 147 MHz | 6.802721 ns | FAIL | -0.054 ns | +0.098 ns | 145.84 MHz |
| 146 MHz | 6.849315 ns | PASS | +0.041 ns | +0.057 ns | 146.88 MHz |

Because the datapath produces one output pixel per clock after the initial fill latency, the peak active-frame throughput is 146 Mpixels/s. For a 1920x1080 active frame, this corresponds to

```text
146e6 / (1920 x 1080) = 70.4 frames/s.
```

Therefore, the core is sufficient for active-frame Full-HD processing at 60 frames/s. This statement refers to active image pixels only; full video-interface timing with blanking intervals may require a different pixel-clock budget depending on the surrounding video system.

### B. Resource Utilization

The post-route utilization at 146 MHz is shown in Table IV.

**Table IV. Post-route resource utilization on XC7A100T**

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| Slice LUTs | 2,528 | 63,400 | 3.99% |
| LUT as logic | 368 | 63,400 | 0.58% |
| LUT as memory | 2,160 | 19,000 | 11.37% |
| Slice registers | 521 | 126,800 | 0.41% |
| Block RAM tile | 1.5 | 135 | 1.11% |
| DSP blocks | 96 | 240 | 40.00% |

The DSP usage is the main resource cost. This is expected because the design intentionally implements a throughput-oriented datapath: 25 taps are computed for three RGB channels in parallel. Although the conceptual arithmetic requires 75 channel multipliers, Vivado maps the final design to 96 DSP blocks due to inference, register absorption, and arithmetic mapping choices. This is an acceptable trade-off for one-pixel-per-clock throughput, but a future time-multiplexed or separable-filter version could reduce DSP utilization at the cost of throughput or kernel generality.

### C. Quantitative Comparison

Table V summarizes the available quantitative data for representative FPGA convolution and image-filtering implementations. Because prior works use different devices, arithmetic formats, and design goals, the table is intended for positioning rather than direct speedup comparison.

**Table V. Quantitative comparison with FPGA-based convolution/image-filtering implementations**

| Work | Device | Kernel | RGB | Runtime | Fmax | Throughput | LUT | FF | BRAM | DSP | Power |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Toledo-Moreo et al. [1] | FPGA | Large 2D | No/NA | Arch.-config. | -- | Real-time | -- | -- | -- | -- | -- |
| Kabbai et al. [2] | FPGA | Gaussian | No/NA | No | -- | -- | -- | -- | -- | -- | -- |
| Joginipelly et al. [3] | FPGA | Separable | No/NA | Algorithmic | -- | -- | -- | -- | -- | -- | -- |
| Campos et al. [5] | FPGA | Spatial | -- | Generated | -- | 1080p60 | -- | -- | -- | -- | -- |
| FPGA@TUL IP [6] | Xilinx 7-series | up to 5x5 | Yes | Product-config. | -- | Full-HD | -- | -- | -- | -- | -- |
| **This work** | **XC7A100T** | **5x5** | **Yes** | **Yes** | **146 MHz** | **146 Mp/s** | **2528** | **521** | **1.5** | **96** | **0.138 W** |

**Table VI. Measured summary of the proposed core**

| Metric | Value |
|---|---:|
| Post-route Fmax | 146 MHz |
| Peak throughput | 146 Mpixels/s |
| Active 1080p rate | 70.4 frames/s |
| Slice LUTs | 2,528 |
| Slice registers | 521 |
| Block RAM tile | 1.5 |
| DSP blocks | 96 |
| Estimated total power | 0.138 W |

### D. Power Estimate

Vivado Power Analyzer reports a total on-chip power of 0.138 W, with 0.047 W dynamic power and 0.091 W static power. The confidence level is reported as medium; however, the design-net activity match is only 1%. Therefore, the value should be interpreted as a preliminary power estimate rather than final power signoff. A more accurate power result should be produced with a better-matched SAIF/VCD switching-activity flow using realistic image streams.

**Table VII. Preliminary post-route power estimate**

| Metric | Value |
|---|---:|
| Total on-chip power | 0.138 W |
| Dynamic power | 0.047 W |
| Static power | 0.091 W |
| Junction temperature | 25.6 C |
| Confidence level | Medium |
| Design nets matched | 1% |

### E. Discussion

The results show that the proposed architecture is best viewed as a throughput-oriented RGB convolution core. Its low LUT and register usage are achieved by mapping the multiply stage primarily to DSP blocks, while line buffering keeps memory usage small. Compared with fixed-filter implementations, runtime coefficient loading allows the same datapath to execute multiple filters. Compared with separable convolution architectures, the proposed core supports arbitrary 5x5 kernels, including non-separable edge and emboss filters.

The main limitation is DSP consumption. A 5x5 RGB filter with fully parallel channel processing naturally requires many multipliers. For devices with fewer DSP blocks, a serialized or partially time-multiplexed MAC array could reduce DSP usage, but it would reduce the maximum pixel throughput. Another limitation is that the reported Full-HD test is an RTL simulation using a D455-derived frame resized to 1920x1080. It validates the convolution datapath at Full-HD image size, but it is not an end-to-end real-time camera interface measurement.

## VI. Conclusion

This paper presented a runtime-configurable RGB888 5x5 convolution FPGA core for real-time image filtering. The design combines line-buffer-based window generation, runtime kernel loading, full RGB channel parallelism, DSP-based multiplication, hierarchical reduction, fixed-point normalization, and saturation. SystemVerilog simulation with a bit-accurate Python golden model showed zero mismatches for five representative kernels on a Full-HD 1920x1080 input feed. Post-route implementation on an Artix-7 XC7A100T device achieved 146 MHz, corresponding to 146 Mpixels/s and approximately 70.4 active Full-HD frames/s, while using 2,528 LUTs, 521 registers, 1.5 block RAM tiles, and 96 DSP blocks. Future work includes improving switching-activity coverage for power signoff, integrating a direct high-bandwidth camera/video interface, exploring separable and time-multiplexed variants, and extending the architecture to multi-pixel-per-clock processing for higher-resolution video.

## References

[1] F. J. Toledo-Moreo, J. J. Martinez-Alvarez, J. Garrigos-Guerrero, and J. M. Ferrandez-Vicente, "FPGA-based architecture for the real-time computation of 2-D convolution with large kernel size," *Journal of Systems Architecture*, vol. 58, no. 8, pp. 277-285, 2012, doi: 10.1016/j.sysarc.2012.06.002.

[2] L. Kabbai, A. Sghaier, A. Douik, and M. Machhout, "FPGA implementation of filtered image using 2D Gaussian filter," *International Journal of Advanced Computer Science and Applications*, vol. 7, no. 7, 2016, doi: 10.14569/IJACSA.2016.070771.

[3] A. K. Joginipelly and D. Charalampidis, "Efficient separable convolution using field programmable gate arrays," *Microprocessors and Microsystems*, 2019, doi: 10.1016/j.micpro.2019.102852.

[4] J. Gould, R. K. Nelson, and K. K. Parhi, "A Low-Latency Feed-Forward Architecture for Image Filtering via Row-by-Row Processing," *IEEE Transactions on Circuits and Systems I: Regular Papers*, vol. 72, no. 9, pp. 4661-4672, 2025, doi: 10.1109/TCSI.2024.3525418.

[5] N. Campos, E. Edirisinghe, S. Chesnokov, and D. Larkin, "Fast Generation of Custom Floating-Point Spatial Filters on FPGAs," arXiv:2409.05837, 2024.

[6] FPGA@TUL, "Convolution IP core," accessed May 2026. [Online]. Available: https://fpga.tul.cz/convolution-core/
