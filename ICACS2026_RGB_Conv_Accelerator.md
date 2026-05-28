# ICACS 2026 Paper Master Package  
## Runtime-Configurable FPGA RGB 5×5 Convolution Streaming Accelerator

**Mục tiêu:** một file `.md` duy nhất gom toàn bộ kế hoạch biến đồ án lõi gia tốc phần cứng RGB 5×5 convolution thành paper ICACS/IEEE 2 cột, gồm tên đề tài, novelty, nội dung paper, hình cần vẽ, prompt Codex vẽ figure, cách so sánh, bảng benchmark, checklist submit.

---

# 1. Tên đề tài paper

## Tên khuyên dùng

**A Runtime-Configurable FPGA Accelerator for Real-Time RGB 5×5 Convolution Streaming**

## Các tên thay thế

1. **An AXI-Compliant Streaming FPGA Architecture for Runtime-Programmable RGB 5×5 Convolution**
2. **A Pipelined FPGA-Based RGB Convolution Accelerator with Runtime Kernel Loading for Real-Time Image Processing**
3. **A Runtime-Configurable RGB888 Convolution IP Core for Real-Time FPGA Image Filtering**

Tên nên tránh:

```text
A Novel Convolution Algorithm...
The First FPGA RGB Convolution Accelerator...
Ultra-Low-Resource RGB Convolution Core...
```

Vì convolution không mới, và nếu dùng nhiều DSP thì không nên claim “ultra-low-resource”.

---

# 2. Novelty và contribution

## 2.1. Novelty đúng của đề tài

Novelty không nằm ở thuật toán convolution. Novelty nằm ở **hardware architecture + RTL implementation + runtime programmability + verification/benchmark**.

Câu định vị đúng:

```text
The proposed work presents a complete AXI-compliant RGB888 streaming convolution IP core with runtime-programmable 5×5 kernel loading, full RGB channel parallelism, a six-stage pipelined MAC datapath, signed Q8.8 coefficient support, 48-bit accumulation, and saturation-based output normalization.
```

## 2.2. Contribution section LaTeX

```latex
The main contributions of this work are summarized as follows:
\begin{itemize}
    \item A complete AXI-compliant RGB888 streaming convolution IP core for real-time FPGA image processing.
    \item A runtime-programmable $5\times5$ kernel-loading mechanism using signed Q8.8 coefficients and an atomic commit scheme.
    \item A fully parallel RGB MAC datapath with a six-stage pipelined reduction tree and 48-bit accumulation.
    \item An FPGA implementation and verification flow including bit-accurate Python golden-model comparison, timing analysis, resource utilization, and power estimation.
\end{itemize}
```

Nếu RTL chưa có shadow-bank commit thật, sửa câu 2 thành:

```latex
A runtime-programmable $5\times5$ kernel-loading mechanism using signed Q8.8 coefficients and a commit-controlled update interface.
```

---

# 3. Track ICACS phù hợp

Các track hợp:

```text
3. Digital circuits and systems
11. IoT and Embedded systems
12. Circuits and systems for AI algorithms
15. Imaging and image sensors
17. Emerging technologies and technology trends
```

Track nên chọn chính:

```text
Digital circuits and systems
```

Track phụ:

```text
Imaging and image sensors
IoT and Embedded systems
Circuits and systems for AI algorithms
```

---

# 4. Cấu trúc paper IEEE 2 cột 6 trang

```text
Title
Abstract
Keywords
I. Introduction
II. Background and Related Work
III. Proposed Architecture
IV. Implementation and Verification
V. Experimental Results and Discussion
VI. Conclusion
References
```

---

# 5. Template LaTeX IEEE 2 cột

Tạo file `paper/main.tex`:

```latex
\documentclass[conference]{IEEEtran}

\usepackage{cite}
\usepackage{amsmath,amssymb,amsfonts}
\usepackage{graphicx}
\usepackage{textcomp}
\usepackage{xcolor}
\usepackage{booktabs}
\usepackage{multirow}
\usepackage{array}
\usepackage{siunitx}

\begin{document}

\title{A Runtime-Configurable FPGA Accelerator for Real-Time RGB $5\times5$ Convolution Streaming}

\author{
\IEEEauthorblockN{Pham Quoc Thinh, Truong Le Ngoc Quyen, Le Nguyen Anh Tu}
\IEEEauthorblockA{
Faculty of Electronics and Telecommunications\\
University of Science, VNU-HCM\\
Ho Chi Minh City, Vietnam\\
Email: \{student emails here\}
}
}

\maketitle

\begin{abstract}
This paper presents a runtime-configurable FPGA accelerator for real-time RGB $5\times5$ convolution streaming. The proposed architecture integrates an AXI4-Stream data plane, an AXI4-Lite control plane, a four-line-buffer window generator, a signed Q8.8 kernel loader, and a six-stage pipelined MAC datapath. The RGB channels are processed in parallel using DSP-based multipliers, while a 48-bit accumulation path and saturation unit are employed to preserve numerical robustness. The design achieves one-pixel-per-clock throughput and is verified against a bit-accurate Python golden model. FPGA implementation results demonstrate that the proposed architecture is suitable for real-time Full-HD image filtering.
\end{abstract}

\begin{IEEEkeywords}
FPGA, RGB convolution, streaming accelerator, AXI4-Stream, fixed-point arithmetic, image processing, line buffer, hardware accelerator.
\end{IEEEkeywords}

\section{Introduction}
% Motivation, CPU bottleneck, real-time video, FPGA parallelism.
% State contributions.

\section{Background and Related Work}
% 2D convolution, line buffer, window generator, FPGA image filtering.
% Compare fixed-filter cores, HLS cores, CNN accelerators.

\section{Proposed Architecture}
% Top architecture, line buffer/window generator, kernel loader, PE/MAC pipeline.

\section{Implementation and Verification}
% SystemVerilog RTL, Vivado, target FPGA, Python golden model, random tests.

\section{Experimental Results and Discussion}
% LUT, FF, DSP, BRAM, Fmax, power, throughput, FPS, comparison.

\section{Conclusion}
% Summarize contribution and future work.

\bibliographystyle{IEEEtran}
\bibliography{references}

\end{document}
```

---

# 6. Abstract mẫu hoàn chỉnh

```text
This paper presents a runtime-configurable FPGA accelerator for real-time RGB 5×5 convolution streaming. The proposed architecture integrates an AXI4-Stream data plane, an AXI4-Lite control plane, a four-line-buffer window generator, a signed Q8.8 kernel loader, and a six-stage pipelined MAC datapath. The RGB channels are processed in parallel using DSP-based multipliers, while a 48-bit accumulation path and saturation unit are employed to preserve numerical robustness. The design achieves one-pixel-per-clock throughput and is verified against a bit-accurate Python golden model. FPGA implementation results show that the accelerator reaches 146 MHz, corresponding to 146 Mpixels/s, which is sufficient for real-time Full-HD active-frame processing at 60 fps. The proposed design demonstrates a throughput-oriented RTL architecture for programmable image filtering on FPGA.
```

---

# 7. Nội dung từng section

## 7.1. Introduction

Cần nói:

1. CPU/OpenCV bị bottleneck do xử lý tuần tự và memory access.
2. FPGA phù hợp vì spatial parallelism, pipeline, deterministic latency.
3. Real-time video cần throughput lớn.
4. 5×5 convolution cần 25 pixel/window mỗi cycle.
5. Đề tài đề xuất custom RTL core dùng AXI4-Stream/Lite.
6. Nêu contribution.

Đoạn mẫu:

```latex
Real-time image filtering is a fundamental operation in embedded vision systems. Although software libraries such as OpenCV provide flexible implementations, their performance is often limited by sequential memory access and CPU workload when processing high-resolution video streams. FPGA devices provide a suitable platform for such workloads due to their spatial parallelism, deterministic latency, and support for streaming datapaths.
```

## 7.2. Background and Related Work

Cần có công thức:

```latex
Y(x,y)=\sum_{m=0}^{4}\sum_{n=0}^{4}I(x+m,y+n)K(m,n)
```

Với RGB:

```latex
Y_c(x,y)=\sum_{m=0}^{4}\sum_{n=0}^{4}I_c(x+m,y+n)K(m,n), \quad c\in\{R,G,B\}
```

Nội dung:

- 2D convolution.
- RGB888.
- Fixed-point Q8.8.
- Line buffer/window generator.
- Related work: fixed-filter FPGA, HLS-based convolution, CNN accelerator, reconfigurable convolver.

## 7.3. Proposed Architecture

Subsection nên có:

```latex
\subsection{Top-Level Streaming Architecture}
\subsection{Line Buffer and Window Generator}
\subsection{Runtime Kernel Loader}
\subsection{PE Core and MAC Pipeline}
\subsection{Fixed-Point Normalization and Saturation}
```

Đoạn mẫu:

```latex
The proposed accelerator follows a streaming architecture in which one RGB888 pixel is accepted per clock cycle through the AXI4-Stream input interface. A four-line buffer and a shift-register-based window generator reconstruct a $5\times5$ spatial window from the raster-scanned input stream. The generated window is forwarded to a fully pipelined MAC array, while the convolution coefficients are supplied by a runtime-programmable kernel loader through the AXI4-Lite control interface.
```

## 7.4. Implementation and Verification

Nội dung:

- SystemVerilog RTL.
- Vivado synthesis/implementation.
- Python golden model.
- Test multiple kernels: Identity, Gaussian, Sharpen, Laplacian, Emboss.
- Pixel-by-pixel comparison.
- Saturation/overflow tests.

Đoạn mẫu:

```latex
The RTL implementation was described in SystemVerilog and synthesized using Xilinx Vivado. A Python golden model was developed to generate bit-accurate reference outputs for different $5\times5$ kernels. The testbench streams RGB image data into the accelerator and compares the hardware output against the software reference on a pixel-by-pixel basis.
```

Nên viết:

```text
No mismatch was observed across the evaluated test images and kernels.
```

Không nên viết quá mạnh:

```text
0 lỗi trên 100% phép thử.
```

## 7.5. Experimental Results and Discussion

Cần có:

- LUT, FF, DSP, BRAM.
- Fmax.
- WNS.
- Power.
- Latency.
- Throughput.
- FPS.
- Comparison.

Câu 146 MHz:

```latex
The implemented core achieves a maximum operating frequency of 146 MHz. Since the architecture processes one pixel per clock cycle, the peak throughput is 146 Mpixels/s. This throughput is sufficient for real-time Full-HD active-frame processing at 60 frames per second.
```

Lưu ý: không claim HDMI 1080p60 full timing vì pixel clock có blanking thường khoảng 148.5 MHz. Nên claim active-frame Full-HD.

---

# 8. Figure cần vẽ trong paper

Nếu paper 6 trang, nên có 5 hình chính. Nếu còn chỗ, thêm 1–2 hình phụ.

## Figure 1 — Top-level system architecture

Mục đích: cho reviewer hiểu lõi nằm ở đâu trong hệ thống.

Nội dung:

```text
Camera / Image Source
        ↓
AXI4-Stream Input
        ↓
RGB 5×5 Convolution Accelerator
        ↓
AXI4-Stream Output
        ↓
Display / Memory
```

Control path:

```text
CPU / PS
  ↓ AXI4-Lite
Kernel Loader / Register Bank
```

Caption:

```latex
\caption{Top-level system architecture of the proposed AXI-compliant RGB convolution accelerator. The image stream is transferred through AXI4-Stream, while the convolution kernel is configured at runtime through AXI4-Lite.}
```

Độ ưu tiên: cao.

---

## Figure 2 — Accelerator top-level architecture

Mục đích: hình xương sống của paper.

Nội dung:

```text
AXI4-Stream Input
→ Line Buffer
→ Window Generator
→ MAC Array / PE Core
→ Normalize
→ Saturation
→ AXI4-Stream Output
```

Control:

```text
AXI4-Lite
→ Kernel Loader
→ kernel_flat[399:0]
→ MAC Array
```

Caption:

```latex
\caption{Top-level architecture of the proposed RGB $5\times5$ streaming convolution accelerator, including the data plane, control plane, window generator, runtime kernel loader, and pipelined MAC datapath.}
```

Độ ưu tiên: bắt buộc.

---

## Figure 3 — Line buffer + 5×5 window generator

Mục đích: chứng minh hiểu streaming hardware.

Nội dung:

```text
Input pixel stream
      ↓
Line Buffer L0
Line Buffer L1
Line Buffer L2
Line Buffer L3
      ↓
5×5 Shift Register Window
```

Label cần có:

```text
1 pixel/clock
4 BRAM line buffers
5×5 window generated every clock after initial fill
```

Caption:

```latex
\caption{Line-buffer and shift-register-based window generator. Four line buffers store previous image rows, while five-column shift registers generate a valid $5\times5$ window after the initial filling latency.}
```

Độ ưu tiên: rất cao.

---

## Figure 4 — PE core datapath

Mục đích: hình VIP nhất, thể hiện xử lý phần cứng thật.

Nội dung:

```text
window_flat[599:0]
        ↓
Extract pixel_i[23:0]
        ↓
RGB Splitter
        ├── R_i[7:0] → MUL_R
        ├── G_i[7:0] → MUL_G
        └── B_i[7:0] → MUL_B

kernel_flat[399:0]
        ↓
Extract coeff_i[15:0]
        ↓
shared coeff_i fanout to MUL_R/G/B

MUL_R/G/B
        ↓
Stage-1 Product Registers
        ↓
to 25-tap reduction tree
```

Caption:

```latex
\caption{Processing element datapath for one $5\times5$ convolution tap. The PE extracts one RGB888 pixel and one signed Q8.8 coefficient, computes three channel products in parallel, and registers the products before the array-level reduction tree.}
```

Độ ưu tiên: bắt buộc.

---

## Figure 5 — Six-stage MAC pipeline

Mục đích: chứng minh pipeline và timing.

Nội dung:

```text
Stage 1: Multiplication
→ Stage 2: Partial Sum Groups
→ Stage 3: Merge L1
→ Stage 4: Merge L2 / Lo-Hi
→ Stage 5: Accumulate + >> 8
→ Stage 6: Saturation
```

Caption:

```latex
\caption{Six-stage MAC pipeline used in the proposed accelerator. The multiplication stage is mapped to DSP resources, while the following stages perform hierarchical reduction, fixed-point normalization, and saturation.}
```

Độ ưu tiên: cao. Nếu thiếu trang, có thể gộp với PE figure.

---

## Figure 6 — Data precision flow

Mục đích: giải thích bit-width.

Nội dung:

```text
RGB888 pixel: 24-bit
R/G/B channel: 8-bit
Coefficient: signed Q8.8, 16-bit
Product: 8×16
Accumulator: acc[47:0]
Normalize: arithmetic shift >> 8
Saturation: clamp [0,255]
Output: RGB888, 24-bit
```

Có thể dùng bảng thay hình.

---

## Figure 7 — Output image results

Mục đích: chứng minh lõi chạy nhiều kernel.

Nội dung:

```text
Original | Identity | Gaussian | Sharpen | Laplacian | Emboss
```

Caption:

```latex
\caption{Output examples generated by the proposed accelerator using different runtime-loaded $5\times5$ kernels.}
```

Độ ưu tiên: cao.

---

# 9. Nếu chỉ chọn 5 hình

Chọn đúng 5 hình này:

```text
1. Accelerator top-level architecture
2. Line buffer + 5×5 window generator
3. PE core datapath
4. Six-stage MAC pipeline
5. Output image results
```

Nếu cần tiết kiệm trang:

- Gộp PE core và MAC pipeline thành một figure rộng `figure*`.
- Precision flow chuyển thành Table I.
- Top-level system bỏ nếu accelerator architecture đã đủ rõ.

---

# 10. Bảng cần có trong paper

## Table I — Design parameters

```latex
\begin{table}[t]
\centering
\caption{Design Parameters}
\label{tab:design_params}
\begin{tabular}{ll}
\toprule
Parameter & Value \\
\midrule
Input format & RGB888 \\
Kernel size & $5\times5$ \\
Coefficient format & Signed Q8.8, 16-bit \\
Accumulator width & 48-bit \\
Throughput & 1 pixel/clock \\
MAC pipeline latency & 6 cycles \\
Control interface & AXI4-Lite \\
Data interface & AXI4-Stream \\
\bottomrule
\end{tabular}
\end{table}
```

## Table II — FPGA resource utilization

Điền số thật từ Vivado.

```latex
\begin{table}[t]
\centering
\caption{FPGA Resource Utilization}
\label{tab:resource}
\begin{tabular}{lrr}
\toprule
Resource & Used & Utilization \\
\midrule
LUT & xxxx & xx\% \\
FF & xxxx & xx\% \\
DSP48E1 & xx & xx\% \\
BRAM & xx & xx\% \\
\bottomrule
\end{tabular}
\end{table}
```

## Table III — Timing and power

```latex
\begin{table}[t]
\centering
\caption{Timing and Power Results}
\label{tab:timing_power}
\begin{tabular}{ll}
\toprule
Metric & Value \\
\midrule
Target frequency & 100 MHz \\
Achieved Fmax & 146 MHz \\
WNS & xx ns \\
Throughput & 146 Mpixels/s \\
Estimated power & xxx W \\
\bottomrule
\end{tabular}
\end{table}
```

## Table IV — Supported video throughput

```latex
\begin{table}[t]
\centering
\caption{Supported Active-Frame Video Throughput}
\label{tab:fps}
\begin{tabular}{lrr}
\toprule
Resolution & Required Mpixels/s & Supported \\
\midrule
720p@60 & 55.3 & Yes \\
1080p@30 & 62.2 & Yes \\
1080p@60 & 124.4 & Yes \\
4K@30 & 248.8 & No, requires multi-pixel parallelism \\
\bottomrule
\end{tabular}
\end{table}
```

---

# 11. Cách so sánh với người khác

## 11.1. Không so cảm tính

Không viết:

```text
Our design is better than commercial IP.
```

Trừ khi có cùng FPGA, cùng kernel, cùng resolution, cùng clock, cùng setting.

## 11.2. So bằng bảng academic

```latex
\begin{table*}[t]
\centering
\caption{Quantitative comparison with FPGA-based convolution/image-filtering implementations}
\label{tab:quant_comparison}
\scriptsize
\setlength{\tabcolsep}{2.2pt}
\begin{tabular}{lccccccccccc}
\toprule
Work & Device & Kernel & RGB & Runtime & Fmax & Throughput & LUT & FF & BRAM & DSP & Power \\
\midrule
Toledo-Moreo et al.~\cite{toledo2012fpga} & FPGA & Large 2-D & No/NA & Arch.-config. & -- & Real-time & -- & -- & -- & -- & -- \\
Kabbai et al.~\cite{kabbai2016gaussian} & FPGA & Gaussian & No/NA & No & -- & -- & -- & -- & -- & -- & -- \\
Joginipelly et al.~\cite{joginipelly2019separable} & FPGA & Separable & No/NA & Algorithmic & -- & -- & -- & -- & -- & -- & -- \\
Campos et al.~\cite{campos2024spatial} & FPGA & Spatial & -- & Generated & -- & 1080p60 & -- & -- & -- & -- & -- \\
FPGA@TUL IP~\cite{tulconvip} & Xilinx 7-series & up to $5\times5$ & Yes & Product-config. & -- & Full-HD & -- & -- & -- & -- & -- \\
\textbf{This work} & \textbf{XC7A100T} & \textbf{$5\times5$} & \textbf{Yes} & \textbf{Yes} & \textbf{146 MHz} & \textbf{146 Mp/s} & \textbf{2528} & \textbf{521} & \textbf{1.5} & \textbf{96} & \textbf{0.138 W} \\
\bottomrule
\end{tabular}
\end{table*}
```

Important wording before this table:

```latex
Because prior works use different devices, arithmetic formats, and design goals, this table is intended for qualitative positioning rather than direct speedup comparison.
```

Measured summary table for this work:

```latex
\begin{table}[t]
\centering
\caption{Measured Summary of the Proposed Core}
\label{tab:measured_summary}
\begin{tabular}{lr}
\toprule
Metric & Value \\
\midrule
Post-route Fmax & 146 MHz \\
Peak throughput & 146 Mpixels/s \\
Active 1080p rate & 70.4 frames/s \\
Slice LUTs & 2,528 \\
Slice registers & 521 \\
Block RAM tile & 1.5 \\
DSP blocks & 96 \\
Estimated total power & 0.138 W \\
\bottomrule
\end{tabular}
\end{table}
```

## 11.3. Câu comparison an toàn

```latex
Compared with fixed-filter FPGA implementations, the proposed design supports runtime kernel updates through an AXI4-Lite-controlled loader. Compared with time-multiplexed convolution engines, the proposed architecture prioritizes throughput by using a fully parallel RGB datapath, at the cost of higher DSP utilization.
```

---

# 12. Viết về DSP nhiều như thế nào?

Nếu dùng 25×3 multiplier song song:

```text
25 taps × 3 RGB channels = 75 multipliers
```

Câu nên dùng:

```latex
The proposed design intentionally maps the multiplication stage to DSP48E1 blocks to reduce LUT usage and shorten the critical path. This design choice enables a fully parallel $5\times5$ RGB datapath with one-pixel-per-clock throughput.
```

Đoạn discussion đầy đủ:

```latex
The proposed architecture adopts a throughput-oriented design strategy. The multiplication stage is intentionally mapped to DSP48E1 resources to reduce LUT-based arithmetic and shorten the critical path. Since the RGB channels are processed in parallel for a $5\times5$ window, the design requires a large number of multipliers. This resource usage is a deliberate trade-off to sustain one-pixel-per-clock throughput. A resource-reduced version using time-multiplexed MAC units can be explored in future work at the cost of increased latency and reduced throughput.
```

---

# 13. 146 MHz viết sao cho đúng?

Nếu timing sau implementation pass:

```latex
The implemented core achieves a maximum operating frequency of 146 MHz after place-and-route.
```

Nếu chỉ synthesis estimate:

```latex
The synthesized core is estimated to operate at up to 146 MHz.
```

Throughput:

```latex
With one-pixel-per-clock processing, the peak throughput is 146 Mpixels/s.
```

Claim Full-HD an toàn:

```latex
This throughput is sufficient for real-time Full-HD active-frame processing at 60 fps.
```

Không nên viết:

```text
supports all HDMI 1080p60 timing
```

---

# 14. Power report viết sao?

Nếu dùng Vivado Power Analyzer và có SAIF/VCD:

```latex
Power was estimated using Vivado Power Analyzer with post-implementation switching activity.
```

Nếu chưa có switching activity thật:

```latex
Power was estimated using Vivado Power Analyzer under default switching assumptions and should be interpreted as an approximate value.
```

Nếu có 0.143W và 0.265W, phải phân loại:

```text
0.143W = dynamic power?
0.265W = total on-chip power?
```

Không được để hai số mâu thuẫn trong paper.

---

# 15. Prompt vẽ Figure 1 — Top-level system

```text
You are an expert IEEE/ACM hardware-architecture figure designer.

Generate these files:
1. docs/fig_top_system.svg
2. docs/fig_top_system.pdf
3. docs/fig_top_system.png
4. scripts/draw_fig_top_system.py
5. paper/fig_top_system_latex.tex

Draw a publication-ready IEEE-style top-level system architecture for an FPGA RGB 5x5 convolution streaming accelerator.

Style:
- white background
- clean academic vector style
- pastel colors
- black/gray thin borders
- no gradients
- no shadows
- no Mermaid
- use SVG/PDF vector output
- readable in IEEE two-column paper

Architecture:
Camera / image source
→ AXI4-Stream Input
→ RGB 5x5 Convolution Accelerator
→ AXI4-Stream Output
→ Display / memory sink

Control path:
CPU / Processing System
→ AXI4-Lite Control
→ Kernel Loader / Register Bank
→ Accelerator

Labels:
- pixel_in[23:0]
- pixel_out[23:0]
- AXI valid/ready
- AXI4-Lite register writes
- kernel coefficients
- runtime programmable

Use orthogonal wires and clean arrowheads.
Return all generated paths and LaTeX figure snippet.
```

---

# 16. Prompt vẽ Figure 2 — Accelerator architecture

```text
You are an expert IEEE/ACM FPGA architecture figure designer.

Generate:
1. docs/fig_accelerator_architecture.svg
2. docs/fig_accelerator_architecture.pdf
3. docs/fig_accelerator_architecture.png
4. scripts/draw_fig_accelerator_architecture.py
5. paper/fig_accelerator_architecture_latex.tex

Draw the top-level architecture of a runtime-configurable RGB 5x5 convolution streaming accelerator.

Must include:
- AXI4-Stream Input
- Input FIFO or stream interface
- 4-Line Buffer BRAM
- 5x5 Window Generator
- MAC Array 25x3
- Normalize >> 8
- Saturation
- AXI4-Stream Output
- AXI4-Lite Control
- Kernel Loader
- Kernel Register Bank
- kernel_flat[399:0]
- status / overflow flag

Architecture requirements:
- Data plane left-to-right
- Control plane below or above, separated by dashed region
- Kernel bus enters MAC array cleanly
- Show 1 pixel/clock and 6-stage MAC latency
- Show RGB888 and Q8.8 labels

Style:
- IEEE paper style
- white background
- pastel colors
- no Mermaid
- vector SVG/PDF
- no wire crossing
- orthogonal arrows
- readable at two-column width

Also generate LaTeX snippet with \includegraphics.
```

---

# 17. Prompt vẽ Figure 3 — Line buffer + window generator

```text
You are an expert FPGA streaming datapath illustrator.

Generate:
1. docs/fig_line_buffer_window.svg
2. docs/fig_line_buffer_window.pdf
3. docs/fig_line_buffer_window.png
4. scripts/draw_fig_line_buffer_window.py
5. paper/fig_line_buffer_window_latex.tex

Draw a publication-ready figure for the line buffer and 5x5 window generator of an RGB streaming convolution accelerator.

Must show:
- raster-scan pixel input stream
- current pixel row
- four line buffers L0, L1, L2, L3 implemented using BRAM
- five vertical taps corresponding to five adjacent rows
- 5x5 shift-register window
- one new pixel column entering each clock
- old columns shifting left
- output window_flat[599:0]

Labels:
- 1 pixel/clock
- 4 line buffers
- 5x5 window
- RGB888 pixel[23:0]
- initial fill latency
- valid window after row/column warm-up

Style:
- clean IEEE figure
- white background
- minimal colors
- no Mermaid
- vector SVG/PDF
- use arrows to show streaming movement
- use small matrix-like 5x5 window illustration

Generate LaTeX figure snippet and markdown preview.
```

---

# 18. Prompt vẽ Figure 4 — PE core datapath

```text
You are an expert IEEE/ACM hardware-architecture figure designer and FPGA RTL documentation engineer.

Your task is to redraw and polish the PE datapath figure for a paper-quality LaTeX IEEE conference manuscript.

Context:
The current project is an FPGA RGB 5x5 convolution streaming accelerator. The PE corresponds to one tap i in `mac_array_25x3.sv`. It extracts one RGB pixel from `window_flat`, extracts one coefficient from `kernel_flat`, computes three products for R/G/B channels, registers the products in Stage 1, and sends them to the later adder tree stages.

Source files:
- RTL source: `src/mac_array_25x3.sv`
- Existing drawing script: `scripts/draw_pe_like_reference.py`
- Existing generated PNG: `docs/pe_source_style.png`

Important RTL behavior to reflect:
- `window_flat` contains 25 RGB pixels.
- Each `pixel_i` is 24-bit RGB888.
- `pixel_i[23:16]` = R
- `pixel_i[15:8]` = G
- `pixel_i[7:0]` = B
- `kernel_flat` contains 25 signed Q8.8 coefficients.
- Each coefficient is 16-bit signed.
- For tap i:
  - `px_r = pixel_i[23:16]`
  - `px_g = pixel_i[15:8]`
  - `px_b = pixel_i[7:0]`
  - `coeff_i = kernel_flat[...]`
  - `mul_r = px_r * coeff_i`
  - `mul_g = px_g * coeff_i`
  - `mul_b = px_b * coeff_i`
- The three products are captured by Stage-1 product registers.
- Stage-1 outputs go to the array-level reduction/ad-tree stages:
  - S2: 8 partial sums
  - S3: 4 partial sums
  - S4: Lo/Hi merge
  - S5: 48-bit accumulation / normalize >> 8
  - S6: saturation clamp [0,255]

Main goal:
Create a clean publication-ready PE figure that looks like an IEEE/ACM accelerator datapath diagram, not a software block diagram.

Do NOT use Mermaid.
Do NOT use raster-only drawing as the main output.
The main output must be vector SVG and PDF.
PNG is only for quick preview.

Required generated files:
1. `docs/fig_pe_core_datapath.svg`
2. `docs/fig_pe_core_datapath.pdf`
3. `docs/fig_pe_core_datapath.png`
4. `scripts/draw_pe_core_datapath.py`
5. `docs/fig_pe_core_datapath.md`
6. `paper/fig_pe_core_datapath_latex.tex`

Visual style:
- White background
- Academic paper style
- Clean black/gray wires
- Thin but visible borders
- No gradients
- No shadows
- No 3D effects
- Minimal pastel fills
- Large whitespace
- Consistent alignment
- Consistent font
- Similar to professional FPGA/CNN accelerator diagrams
- Readable when scaled to IEEE two-column width
- Avoid wire crossing as much as possible
- Avoid diagonal wires unless necessary
- No giant watermark text
- No decorative icons

Recommended colors:
- Outer PE boundary: white fill, black stroke
- Input extraction blocks: very light blue
- RGB splitter block: light blue
- Coefficient path: light yellow
- Multipliers: light orange
- Stage-1 register: light gray
- Array-level adder tree preview: very light green
- Control/valid path: dashed gray line

Figure layout:
Use landscape layout.

Top title inside figure:
`PE[i] Datapath: One 5x5 Tap for RGB Convolution`

Outer boundary:
Draw one large rectangular boundary labeled:
`Processing Element PE[i]`

Inside the PE boundary, use this clean dataflow:

Left side:
- Input bus `window_flat[599:0]`
- A small extraction block:
  `Extract pixel_i`
  `pixel_i[23:0]`
- Then a central block:
  `RGB Splitter`
- From RGB Splitter, draw three parallel horizontal wires:
  - `R_i[7:0]`
  - `G_i[7:0]`
  - `B_i[7:0]`

Top or upper-left coefficient path:
- Input bus `kernel_flat[399:0]`
- Extraction block:
  `Extract coeff_i`
  `signed Q8.8`
  `coeff_i[15:0]`
- Draw one clean coefficient bus that fans out vertically/horizontally to all three multipliers.
- The coefficient bus must not look like it comes from another multiplier.
- Label the coefficient fanout:
  `shared coeff_i`

Middle:
Draw three vertically stacked multiplier blocks:
- `MUL_R`
  `R_i × coeff_i`
- `MUL_G`
  `G_i × coeff_i`
- `MUL_B`
  `B_i × coeff_i`

Each multiplier output label:
- `prod_r`
- `prod_g`
- `prod_b`

Right side:
Draw one block:
`Stage-1 Product Registers`
with internal labels:
- `mul_r_q`
- `mul_g_q`
- `mul_b_q`

The three multiplier outputs must enter this register block cleanly.

After Stage-1 Reg:
Draw an output bus:
`to 25-tap reduction tree`

Below or to the far right, outside PE boundary, draw a compact array-level preview:
`Array-level MAC Reduction`
containing:
- `S2`
  `8 sums`
- `S3`
  `4 sums`
- `S4`
  `Lo/Hi`
- `S5`
  `acc[47:0]`
  `>> 8`
- `S6`
  `SAT [0,255]`

Important:
Make it visually clear that the lower S2-S6 adder tree is not inside one PE. It receives outputs from 25 PE blocks.

Add label:
`After 25 PE[i] products per channel`

Control path:
- Draw `valid_in` as a dashed gray path, not as a data bus.
- It should go into a small block:
  `valid pipeline`
  `6-stage delay`
- Output label:
  `valid_out`
- Do not let `valid_in` cross through the arithmetic datapath.
- Optional small labels: `clk`, `rst`, `en`
- Keep control path separate from data path.

Wiring rules:
- Use orthogonal wires: horizontal and vertical only.
- Avoid diagonal arrows.
- Avoid overlapping labels and wires.
- Avoid crossing coefficient wires with product wires.
- Use arrowheads only for main dataflow direction.
- Use small black connection dots only where fanout is intentional.
- Do not put connection dots everywhere.
- All wire labels must be readable.

Figure annotation:
Add a small source-equation box in the bottom-left corner of the PE boundary:

`Source equations`
`mul_r[i] = R_i × coeff_i`
`mul_g[i] = G_i × coeff_i`
`mul_b[i] = B_i × coeff_i`

Add a small precision box:
`Precision`
`RGB888 pixel: 24-bit`
`Channel: 8-bit`
`Coeff: signed Q8.8, 16-bit`
`Accumulator: 48-bit`

But keep these boxes small and clean.

Output dimensions:
- SVG viewBox should be approximately `0 0 1800 1050`
- PNG should be at least `1800x1050`
- PDF should preserve vector quality
- Font should be Arial, Helvetica, or Liberation Sans
- Font sizes:
  - Title: 28–34 px
  - Block labels: 18–24 px
  - Signal labels: 14–18 px
  - Notes: 14–16 px
- Stroke width:
  - Main block border: 2.0 px
  - Outer boundary: 3.0 px
  - Wire: 2.0 px
  - Dashed control wire: 1.5 px

Python implementation:
Implement the drawing in `scripts/draw_pe_core_datapath.py`.

Use Python with matplotlib only, or use svgwrite if available.
Prefer generating native SVG directly for clean vector output.
The script must:
- create the SVG
- export a PDF
- export a PNG preview
- validate that files are non-empty
- print output paths and image size
- not depend on internet
- not depend on external assets
- create missing directories automatically

Markdown file:
Create `docs/fig_pe_core_datapath.md` with:
- Title: `PE Core Datapath Figure`
- Embed the SVG:
  `<img src="./fig_pe_core_datapath.svg" width="100%">`
- Short caption:
  `Figure: Processing element PE[i] for one 5x5 convolution tap. The PE extracts one RGB888 pixel and one signed Q8.8 coefficient, computes three channel products, and registers them before the array-level reduction tree.`
- Short notes:
  - `One PE corresponds to one tap i.`
  - `Twenty-five PE outputs are reduced by the MAC adder tree.`
  - `The valid path is shown separately from the data path.`

LaTeX snippet:
Create `paper/fig_pe_core_datapath_latex.tex` with an IEEE-compatible figure environment:

\begin{figure}[t]
    \centering
    \includegraphics[width=\linewidth]{figures/fig_pe_core_datapath.pdf}
    \caption{Processing element datapath for one $5\times5$ convolution tap. The PE extracts one RGB888 pixel and one signed Q8.8 coefficient, computes three channel products in parallel, and registers the products before the array-level reduction tree.}
    \label{fig:pe_core_datapath}
\end{figure}

Also create a two-column version:

\begin{figure*}[t]
    \centering
    \includegraphics[width=0.95\textwidth]{figures/fig_pe_core_datapath.pdf}
    \caption{Detailed PE datapath and its connection to the array-level MAC reduction pipeline.}
    \label{fig:pe_core_datapath_wide}
\end{figure*}

Quality checks:
- check file exists
- check file size > 10 KB
- check PNG dimensions
- ensure no text is outside the figure boundary
- ensure output paths are correct

Very important correctness rules:
- Do not draw `valid_in` as if it is a data input to multipliers.
- Do not draw R/G/B as independent sources; they must come from RGB Splitter.
- Do not draw coefficient wires diagonally crossing multiplier outputs.
- Do not place Stage-1 Reg before the multipliers.
- Do not put S2-S6 inside one PE; they are array-level reduction stages after 25 PE blocks.
- Do not use a huge `PE` watermark.
- Do not label product as 32-bit unless the RTL truly uses 32-bit products. If unsure, label it generically as `product` or verify from RTL.

Return:
1. A concise summary of what was generated.
2. The paths of all generated files.
3. Any assumptions made about product width or signal names.
4. The LaTeX snippet content.
```

---

# 19. Prompt vẽ Figure 5 — Six-stage MAC pipeline

```text
You are an expert IEEE FPGA datapath illustrator.

Generate:
1. docs/fig_mac_pipeline.svg
2. docs/fig_mac_pipeline.pdf
3. docs/fig_mac_pipeline.png
4. scripts/draw_fig_mac_pipeline.py
5. paper/fig_mac_pipeline_latex.tex

Draw a clean six-stage MAC pipeline diagram for an RGB 5x5 convolution accelerator.

Pipeline:
S1: 25x3 DSP48 multipliers
S2: partial sum groups, 8 sums
S3: group merge L1, 4 sums
S4: group merge L2, Lo/Hi
S5: 48-bit accumulation and arithmetic shift >> 8
S6: saturation clamp [0,255]

Requirements:
- show pipeline registers between stages
- show valid signal delayed along pipeline
- show R/G/B channels processed in parallel
- show product/accumulator precision labels
- show latency = 6 cycles
- show throughput = 1 pixel/clock

Style:
- IEEE/ACM conference figure
- white background
- pastel colors
- no Mermaid
- vector SVG/PDF
- orthogonal arrows
- no overlapping labels

Generate LaTeX snippet.
```

---

# 20. Prompt vẽ Figure 6 — Output image results

```text
You are an expert scientific figure generator for IEEE image-processing papers.

Generate a publication-ready result figure from existing images in the project.

Search or use the following expected image outputs if available:
- original image
- identity output
- gaussian output
- sharpen output
- laplacian output
- emboss output

Create:
1. docs/fig_output_results.png
2. docs/fig_output_results.pdf
3. scripts/make_fig_output_results.py
4. paper/fig_output_results_latex.tex

Figure layout:
- one row or two rows
- labels under each image:
  Original, Identity, Gaussian, Sharpen, Laplacian, Emboss
- same size for all images
- white background
- no decorative border
- readable in IEEE paper

Also create a LaTeX snippet:

\begin{figure}[t]
    \centering
    \includegraphics[width=\linewidth]{figures/fig_output_results.pdf}
    \caption{Example output images generated by the proposed accelerator using different runtime-loaded $5\times5$ kernels.}
    \label{fig:output_results}
\end{figure}

If any image file is missing, generate a clear placeholder with the correct label and report which files are missing.
```

---

# 21. Figure quality rules

Nên dùng:

```text
SVG/PDF vector
white background
pastel colors
orthogonal wires
thin black/gray lines
large spacing
font consistent
```

Không dùng:

```text
screenshot mờ
gradient
shadow nặng
3D block
neon/cyberpunk
wire crossing lung tung
valid_in chạy như data bus
```

IEEE LaTeX snippet:

```latex
\begin{figure}[t]
    \centering
    \includegraphics[width=\linewidth]{figures/your_figure.pdf}
    \caption{Your caption here.}
    \label{fig:your_label}
\end{figure}
```

Nếu hình rộng:

```latex
\begin{figure*}[t]
    \centering
    \includegraphics[width=0.95\textwidth]{figures/your_figure.pdf}
    \caption{Your wide caption here.}
    \label{fig:your_wide_label}
\end{figure*}
```

---

# 22. Folder structure nên dùng

```text
convolution_fpga/
├── src/
│   ├── mac_array_25x3.sv
│   ├── line_buffer.sv
│   ├── window_generator.sv
│   ├── kernel_loader.sv
│   └── axi_stream_top.sv
│
├── tb/
│   ├── tb_top.sv
│   └── test_vectors/
│
├── scripts/
│   ├── golden_model.py
│   ├── draw_fig_top_system.py
│   ├── draw_fig_accelerator_architecture.py
│   ├── draw_fig_line_buffer_window.py
│   ├── draw_pe_core_datapath.py
│   ├── draw_fig_mac_pipeline.py
│   └── make_fig_output_results.py
│
├── docs/
│   ├── fig_top_system.svg
│   ├── fig_accelerator_architecture.svg
│   ├── fig_line_buffer_window.svg
│   ├── fig_pe_core_datapath.svg
│   ├── fig_mac_pipeline.svg
│   └── fig_output_results.pdf
│
├── paper/
│   ├── main.tex
│   ├── references.bib
│   ├── figures/
│   │   ├── fig_top_system.pdf
│   │   ├── fig_accelerator_architecture.pdf
│   │   ├── fig_line_buffer_window.pdf
│   │   ├── fig_pe_core_datapath.pdf
│   │   ├── fig_mac_pipeline.pdf
│   │   └── fig_output_results.pdf
│   └── snippets/
│
└── reports/
    ├── utilization.rpt
    ├── timing_summary.rpt
    ├── power.rpt
    └── verification_log.txt
```

---

# 23. README repo mẫu

```md
# Runtime-Configurable FPGA RGB 5x5 Convolution Accelerator

This repository contains the RTL implementation, verification scripts, and paper figures for a runtime-configurable FPGA RGB 5x5 convolution streaming accelerator.

## Features

- RGB888 AXI4-Stream input/output
- Runtime-programmable 5x5 kernel through AXI4-Lite
- Signed Q8.8 coefficient format
- Four-line buffer and 5x5 window generator
- Full-parallel RGB MAC datapath
- Six-stage MAC pipeline
- 48-bit accumulation and saturation
- One-pixel-per-clock throughput

## Project Structure

...
```

---

# 24. Academic wording nên dùng

Thay “siêu thấp” bằng:

```text
low estimated on-chip power
power-efficient under the evaluated configuration
```

Thay “tối ưu cực thấp” bằng:

```text
resource-aware RTL implementation
throughput-oriented architecture with explicit DSP mapping
```

Thay “0 lỗi” bằng:

```text
No mismatch was observed across the evaluated test cases.
```

Thay “cao hơn commercial IP” bằng:

```text
The custom RTL implementation achieves lower latency under the evaluated fixed-function configuration, while commercial IP cores typically provide broader configurability.
```

---

# 25. Đoạn paper mẫu cho PE core

```latex
\subsection{Processing Element Datapath}

Fig.~\ref{fig:pe_core_datapath} illustrates the processing element used for one tap of the $5\times5$ RGB convolution. Each PE extracts one RGB888 pixel and one signed Q8.8 coefficient from the flattened window and kernel buses, respectively. The pixel is split into three 8-bit components corresponding to the R, G, and B channels. The same coefficient is shared across the three channel multipliers, producing three channel-wise products in parallel. These products are registered at the first pipeline stage before being forwarded to the array-level reduction tree.

This organization separates tap-level multiplication from multi-tap accumulation. As a result, the multiplication stage can be mapped directly to DSP resources, while the following stages perform hierarchical reduction and normalization. The explicit stage boundary after multiplication helps reduce the critical path and enables the accelerator to sustain one-pixel-per-clock streaming throughput.
```

---

# 26. Đoạn paper mẫu cho line buffer

```latex
\subsection{Line Buffer and Window Generator}

The input image stream follows a raster-scan order in which pixels arrive from left to right and top to bottom. Since a $5\times5$ convolution requires pixels from five adjacent rows, the proposed architecture employs four line buffers to store previous image rows. Together with the current input row, these buffers provide five vertically aligned pixels at the same column position. A shift-register-based window generator then shifts these vertical pixel columns horizontally to form a complete $5\times5$ window.

After the initial filling latency, the window generator produces one valid $5\times5$ window per clock cycle. This allows the MAC array to operate continuously without repeatedly accessing external memory, which is essential for real-time streaming performance.
```

---

# 27. Đoạn paper mẫu cho kernel loader

Nếu có commit mechanism thật:

```latex
\subsection{Runtime Kernel Loader}

The convolution kernel is configured through an AXI4-Lite control interface. Each coefficient is represented as a signed Q8.8 fixed-point value and stored in an internal kernel register bank. To prevent inconsistent coefficient updates during streaming operation, the design uses a commit mechanism. New coefficients are first written into a temporary register bank and are transferred to the active kernel bank only when a commit command is issued. The active kernel is then provided to the MAC array as a flattened 400-bit bus.
```

Nếu chưa có shadow bank, dùng bản an toàn:

```latex
The coefficient registers are updated through a commit-controlled mechanism, ensuring that software-controlled kernel changes are synchronized with the hardware datapath.
```

---

# 28. Đoạn paper mẫu cho result

```latex
\section{Experimental Results and Discussion}

The proposed accelerator was implemented in SystemVerilog and evaluated using Xilinx Vivado. The design was constrained to a target frequency of 100 MHz and achieved a maximum operating frequency of 146 MHz after implementation. Since the datapath processes one RGB pixel per clock cycle, the resulting peak throughput is 146 Mpixels/s. This is sufficient for real-time Full-HD active-frame processing at 60 fps.

The resource utilization shows that the design primarily uses DSP blocks for the multiplication stage. This is expected because the architecture processes the three RGB channels in parallel for all 25 convolution taps. The DSP-oriented implementation reduces LUT-based arithmetic and supports a short critical path, but it increases DSP utilization. Therefore, the proposed design is best interpreted as a throughput-oriented architecture rather than a DSP-minimized implementation.
```

---

# 29. Future work

Nên ghi:

```latex
Future work includes extending the architecture to multi-pixel-per-clock processing for 4K video, integrating automatic border handling, and exploring time-multiplexed or separable-filter variants to reduce DSP utilization.
```

Các hướng:

```text
1. Multi-pixel-per-clock cho 4K.
2. Automatic zero-padding.
3. Time-multiplexed MAC để giảm DSP.
4. Separable convolution để giảm multiplier.
5. Camera/image sensor integration.
6. Optional secure/encrypted streaming mode.
```

---

# 30. Checklist kỹ thuật

```text
[ ] RTL compile clean
[ ] Simulation pass
[ ] AXI valid/ready verified
[ ] Kernel loader commit verified
[ ] Multiple kernels tested
[ ] Python golden model comparison done
[ ] Saturation/overflow tested
[ ] Synthesis done
[ ] Implementation done
[ ] Timing closed
[ ] Fmax reported correctly
[ ] Resource utilization exported
[ ] Power report exported
[ ] Output images generated
```

---

# 31. Checklist paper

```text
[ ] IEEE template đúng
[ ] Abstract rõ
[ ] Contribution rõ
[ ] Related work có citation
[ ] Architecture figures vector quality
[ ] Tables có số liệu thật
[ ] Không overclaim
[ ] Comparison công bằng
[ ] Grammar kiểm tra
[ ] References đủ
[ ] PDF không lỗi font
[ ] Không vượt 6 trang
```

---

# 32. Checklist figure

```text
[ ] Figure 1: top-level architecture
[ ] Figure 2: accelerator architecture
[ ] Figure 3: line buffer/window generator
[ ] Figure 4: PE core datapath
[ ] Figure 5: MAC pipeline
[ ] Figure 6: output results
[ ] All figures are SVG/PDF, not blurry PNG
[ ] Captions academic
[ ] Figure labels referenced in text
```

---

# 33. Timeline hoàn thiện

Nếu đã có RTL + PPT:

```text
Week 1–2:
- Chốt RTL
- Clean signal naming
- Fix AXI valid/ready
- Verify kernel loader

Week 3–4:
- Python golden model
- Random image tests
- Multiple kernel tests
- Saturation tests

Week 5–6:
- Synthesis/implementation
- Timing/power/utilization reports
- Chốt số liệu

Week 7–8:
- Vẽ figures
- Viết paper draft

Week 9–10:
- Related work
- Comparison table
- Sửa wording academic

Week 11–12:
- Thầy review
- Final polish
- Submit
```

Nhanh: 6–8 tuần có bản student conference ổn. Chỉnh chu: 8–12 tuần.

---

# 34. Trả lời reviewer

## Nếu hỏi novelty

```text
The novelty of this work is not a new convolution algorithm, but a complete RTL-level streaming architecture that integrates runtime 5×5 kernel programming, full-parallel RGB processing, a six-stage MAC pipeline, Q8.8 coefficient support, 48-bit accumulation, and AXI-compliant data/control interfaces. The design is implemented and verified on FPGA with timing, resource, and power results.
```

## Nếu hỏi DSP nhiều

```text
The DSP usage is a deliberate throughput-oriented trade-off. Since the design processes 25 taps for three RGB channels in parallel, the multiplication stage requires a large number of DSP blocks. This enables one-pixel-per-clock throughput and simplifies timing closure. A time-multiplexed version can reduce DSP usage at the cost of lower throughput.
```

## Nếu hỏi 146 MHz đủ 1080p60 không

```text
At one pixel per clock, 146 MHz corresponds to 146 Mpixels/s. The active-frame pixel rate of 1920×1080 at 60 fps is approximately 124.4 Mpixels/s, so the core is sufficient for active-frame Full-HD processing. However, full HDMI timing including blanking may require a higher pixel clock, so the claim is limited to active-frame processing.
```

## Nếu hỏi power

```text
The reported power is obtained from Vivado Power Analyzer under the stated implementation condition. If no switching activity file is used, the value is treated as an estimate and reported accordingly.
```

---

# 35. Kết luận paper mẫu

```latex
This work demonstrates that a carefully designed RTL streaming datapath can provide deterministic high-throughput RGB convolution with runtime kernel programmability. By combining line-buffer-based window generation, DSP-oriented parallel multiplication, pipelined reduction, and fixed-point saturation, the proposed accelerator achieves real-time performance while maintaining a clear and reusable hardware architecture for FPGA-based image processing systems.
```

---

# 37. Figure Generation Rules - Addendum

Mục này là spec bắt buộc để Codex vẽ hình paper ít sai hơn. Khi tạo hoặc regenerate bất kỳ figure nào, dùng flow này trước khi vẽ.

## 37.1. General rules

```text
- Generate vector graphics first: SVG as the source of truth, PDF for LaTeX, PNG only for preview.
- Prefer Python svgwrite with explicit coordinates.
- Use matplotlib only if svgwrite is not available.
- Do not use Mermaid for final paper figures.
- Do not use free-form auto-layout for datapath figures.
- Use orthogonal wiring only: horizontal and vertical segments.
- Separate datapath signals and control signals visually.
- Use white background, clean black/gray wires, minimal pastel fills.
- Use Arial, Helvetica, Liberation Sans, or a similar sans-serif font.
- Avoid gradients, shadows, 3D blocks, decorative icons, and giant watermark text.
- Keep labels readable at IEEE two-column width.
- Avoid text overlap, wire overlap, and ambiguous fanout.
```

## 37.2. Generate and validate workflow

```text
B1. Parse RTL or read the source-backed architecture spec.
B2. Create a structured internal figure spec:
    - blocks
    - boundaries
    - datapath edges
    - control edges
    - forbidden blocks
    - notes and source equations
B3. Render the figure using svgwrite and explicit coordinates.
B4. Export SVG, PDF, and PNG preview.
B5. Validate:
    - file exists
    - file size > 10 KB for SVG/PDF/PNG where applicable
    - PNG dimensions are correct
    - no text is outside the canvas
    - all signal directions match RTL
    - stage ordering matches RTL
    - PE-local logic is not mixed with array-level logic
    - valid/control path is not drawn as arithmetic data
B6. If a correctness rule fails, regenerate before returning.
B7. Export Markdown figure page and LaTeX snippet.
```

## 37.3. Output rules for every figure

For each final paper figure, generate:

```text
docs/<figure_name>.svg
docs/<figure_name>.pdf
docs/<figure_name>.png
scripts/draw_<figure_name>.py
docs/<figure_name>.md
paper/<figure_name>_latex.tex
```

## 37.4. Figure-to-section mapping

```text
Fig. 1: Top-level system overview -> Introduction or Proposed Architecture
Fig. 2: Accelerator architecture -> Proposed Architecture
Fig. 3: Line buffer and 5x5 window generator -> Proposed Architecture
Fig. 4: PE core datapath -> Processing Element and MAC Pipeline
Fig. 5: Six-stage MAC pipeline -> Processing Element and MAC Pipeline
Fig. 6: Output image results -> Verification or Results
```

## 37.5. Global figure correctness constraints

```text
- A control signal must never look like arithmetic data.
- valid_in must be a dashed control path, not an input to multipliers.
- Datapath buses should be solid black or dark gray.
- Control paths should be dashed gray.
- Coefficient fanout must be explicit and must not appear to come from another multiplier.
- Pipeline registers must be placed after the logic they register.
- If a block is outside the current abstraction boundary, draw it outside the boundary or as a separate preview.
- Use connection dots only at intentional fanout points.
- Use arrowheads only for main signal direction.
- Do not draw diagonal coefficient wires crossing product wires.
- Do not place text directly on top of wires.
```

## 37.6. Reviewer-risk checklist

```text
[ ] Does the comparison table avoid unfair speedup claims?
[ ] Are platforms, kernel sizes, precision, and image formats clearly stated?
[ ] Is 146 MHz identified as post-route timing for top_convolution, not necessarily full board top?
[ ] Is 1080p60 described as active-frame processing, not full HDMI timing with blanking?
[ ] Is the D455 test described as capture/resized feed through RTL simulation, not direct FPGA camera ingest?
[ ] Is the power number described as preliminary if activity matching is low?
[ ] Does the PE figure show S2-S6 outside one PE?
[ ] Does valid_in stay on a separate control path?
[ ] Are product width, accumulator width, and normalization consistent with RTL?
[ ] Are all figures readable in two-column IEEE format?
```

## 37.7. Benchmark fairness rules

```text
- Do not claim "better" unless device, frequency, precision, kernel, resolution, and test condition are comparable.
- Prefer "positions the proposed design" over "outperforms".
- Use N/S when a related work does not specify a field.
- Use "not directly comparable" when works target different goals.
- For commercial IP, compare public capability only; do not infer internal LUT/DSP/Fmax.
- Report your own data as post-route, synthesis estimate, simulation, or theoretical throughput explicitly.
```

## 37.8. Figure Spec: PE Core Datapath

```text
Figure title:
PE[i] Datapath for One 5x5 RGB Convolution Tap

Purpose:
Show the internal processing of one PE for one tap i:
pixel extraction, RGB splitting, coefficient extraction, three parallel multipliers, and Stage-1 product registers.

Inside PE boundary:
- window_flat input
- Extract pixel_i
- RGB Splitter
- kernel_flat input
- Extract coeff_i
- MUL_R
- MUL_G
- MUL_B
- Stage-1 Product Registers
- valid pipeline

Outside PE boundary:
- S2: 8 sums
- S3: 4 sums
- S4: Lo/Hi
- S5: acc[47:0] and >> 8
- S6: saturation

Required datapath:
window_flat -> Extract pixel_i -> RGB Splitter -> R/G/B -> MUL_R/G/B -> Stage-1 Product Registers -> to 25-tap reduction tree

kernel_flat -> Extract coeff_i -> shared coeff_i bus -> MUL_R/G/B

valid_in -> valid pipeline -> valid_out

Forbidden mistakes:
- Do not connect valid_in into multipliers.
- Do not draw R/G/B as independent sources.
- Do not place Stage-1 Reg before multipliers.
- Do not draw S2-S6 inside PE.
- Do not draw diagonal coefficient wires crossing multiplier outputs.
- Do not use a giant PE watermark.
```

Structured JSON-like spec to create before rendering:

```json
{
  "figure": "pe_core",
  "blocks": [
    {"id": "pixel_extract", "label": "Extract pixel_i", "x": 140, "y": 300, "w": 190, "h": 90},
    {"id": "rgb_splitter", "label": "RGB Splitter", "x": 410, "y": 300, "w": 180, "h": 90},
    {"id": "coeff_extract", "label": "Extract coeff_i", "x": 410, "y": 180, "w": 210, "h": 90},
    {"id": "mul_r", "label": "MUL_R", "x": 720, "y": 220, "w": 170, "h": 75},
    {"id": "mul_g", "label": "MUL_G", "x": 720, "y": 330, "w": 170, "h": 75},
    {"id": "mul_b", "label": "MUL_B", "x": 720, "y": 440, "w": 170, "h": 75},
    {"id": "stage1", "label": "Stage-1 Product Registers", "x": 1020, "y": 300, "w": 250, "h": 160},
    {"id": "valid_pipe", "label": "valid pipeline", "x": 410, "y": 690, "w": 220, "h": 80}
  ],
  "edges": [
    {"from": "window_flat", "to": "pixel_extract", "label": "window_flat[599:0]", "kind": "data"},
    {"from": "pixel_extract", "to": "rgb_splitter", "label": "pixel_i[23:0]", "kind": "data"},
    {"from": "rgb_splitter", "to": "mul_r", "label": "R_i[7:0]", "kind": "data"},
    {"from": "rgb_splitter", "to": "mul_g", "label": "G_i[7:0]", "kind": "data"},
    {"from": "rgb_splitter", "to": "mul_b", "label": "B_i[7:0]", "kind": "data"},
    {"from": "kernel_flat", "to": "coeff_extract", "label": "kernel_flat[399:0]", "kind": "data"},
    {"from": "coeff_extract", "to": "mul_r", "label": "shared coeff_i", "kind": "data"},
    {"from": "coeff_extract", "to": "mul_g", "label": "shared coeff_i", "kind": "data"},
    {"from": "coeff_extract", "to": "mul_b", "label": "shared coeff_i", "kind": "data"},
    {"from": "mul_r", "to": "stage1", "label": "prod_r", "kind": "data"},
    {"from": "mul_g", "to": "stage1", "label": "prod_g", "kind": "data"},
    {"from": "mul_b", "to": "stage1", "label": "prod_b", "kind": "data"},
    {"from": "valid_in", "to": "valid_pipe", "label": "valid_in", "kind": "control"},
    {"from": "valid_pipe", "to": "valid_out", "label": "valid_out", "kind": "control"}
  ]
}
```

Prompt to regenerate:

```text
Regenerate the PE core figure from scratch using Python svgwrite and explicit coordinates.
First create a structured figure spec with blocks, signals, boundaries, control path, data path, and forbidden mistakes.
Render SVG/PDF/PNG.
Use orthogonal wires only.
Separate PE-local logic from array-level reduction stages.
Validate all signal directions against src/mac_array_25x3.sv before rendering.
Do not use Mermaid.
Do not use free-form auto-layout.
Output:
1. docs/fig_pe_core_datapath.svg
2. docs/fig_pe_core_datapath.pdf
3. docs/fig_pe_core_datapath.png
4. scripts/draw_pe_core_datapath.py
5. docs/fig_pe_core_datapath.md
6. paper/fig_pe_core_datapath_latex.tex
```

## 37.9. Figure Spec: Top Datapath

```text
Required datapath:
RGB888 stream -> line buffer -> 5x5 window -> MAC array -> normalize -> saturation -> RGB888 output

Required control path:
CPU/control -> AXI4-Lite or UART parser -> kernel write signals -> kernel_loader -> kernel_flat -> MAC array

Forbidden mistakes:
- Do not draw CPU/control as part of pixel datapath.
- Do not draw kernel_loader after the MAC.
- Do not imply full-frame buffering.
- Do not claim direct D455 Full-HD real-time ingest unless the surrounding interface is implemented.
```

## 37.10. Figure Spec: Line Buffer and Window Generator

```text
Required datapath:
input RGB pixel -> line buffer chain -> 5 row taps -> horizontal shift registers -> window_flat[599:0]

Required control:
x/y counters -> valid region logic -> lb_valid/window_valid

Forbidden mistakes:
- Do not show a full frame buffer.
- Do not feed window pixels out of raster order.
- Do not draw window_valid into arithmetic multipliers.
```

## 37.11. Figure Spec: Six-Stage MAC Pipeline

```text
Pipeline:
S1: 25 x 3 products, product registers
S2: 8 partial sums per channel
S3: 4 grouped sums per channel
S4: Lo/Hi merge per channel
S5: 48-bit accumulation and arithmetic shift >> 8
S6: saturation clamp [0,255]

Required datapath:
25 PE outputs per channel -> S2 -> S3 -> S4 -> S5 -> S6 -> RGB888 output

Required control:
valid_s1 -> valid_s2 -> valid_s3 -> valid_s4 -> valid_s5 -> valid_out

Forbidden mistakes:
- Do not place S2-S6 inside one PE.
- Do not show only one color channel unless the figure explicitly says single-channel view.
- Do not place saturation before normalization.
- Do not omit valid delay if the figure shows pipeline stages.
```

---

# 38. Ghi nhớ cuối cùng

Cái làm paper có giá trị không phải là:

```text
5×5 convolution
```

Mà là:

```text
cách biến nó thành một IP core phần cứng hoàn chỉnh:
streaming + line buffer + PE datapath + kernel loader + AXI + pipeline + benchmark.
```

Muốn paper nhìn mạnh, cần:

```text
figure đẹp
số liệu chặt
wording academic
comparison công bằng
không overclaim
```

Nếu làm đúng, đề tài đủ sức cho ICACS 2026 student/research session.
