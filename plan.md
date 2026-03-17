# PLAN ĐỒ ÁN: Programmable RGB 5x5 Convolution Engine  
**Môn học: Seminar Audio-Video (Xử lý ảnh/video + Kỹ thuật IC số SystemVerilog)**  
**Thời gian: 6 tuần**  
**Sinh viên:** Pham Quoc Thinh
**Board:** Zync
**Camera:** Intel RealSense D455 (capture RGB → hex stream)  
**Mục tiêu chính:** Throughput ≥ 300 MPixels/s (4-8 pixel/clock, 120 fps @720p), kernel programmable realtime, pipeline sâu + DSP48E1  

## 0. Trạng thái triển khai hiện tại (2026-03-17)

### Đã hoàn thành
- Khởi tạo cấu trúc dự án: `src/`, `tb/`, `python/`, `docs/`, `scripts/`, `sim/`, `hex/`.
- Có baseline RTL 5x5: `line_buffer_4.sv`, `mac_array_25x3.sv`, `kernel_loader.sv`, `top_convolution.sv`.
- Nâng testbench thành self-check: đọc `hex/test_frame_0.hex`, tự so expected pixel, tạo `sim/tb_out.hex`.
- Testbench đã hỗ trợ kernel/expected từ file (`sim/kernel.hex`, `sim/expected.hex`) để chạy regression nhiều kernel.
- Flow simulation Windows chạy ổn qua `scripts/run_sim.ps1`.
- Đã có `scripts/run_regression.ps1` chạy full bộ kernel: identity, gaussian, sharpen, emboss, laplacian.
- Đã có skeleton Vivado: `vivado_project/project_create.tcl`, `vivado_project/run_synth.tcl`, `vivado_project/constraints.xdc`.
- Checklist xem sóng đã có trong `docs/waveform_checklist.md`.

### Kết quả kiểm chứng gần nhất
- `TB PASS: valid_count=144 expected=144`
- `sim/tb_out.hex` có 144 dòng (đúng với công thức `(W-4)*(H-4)` khi `W=H=16`, `KSIZE=5`).
- Regression 5 kernel đều PASS với 144 mẫu/output case.

### Việc kế tiếp (ưu tiên)
1. Nối testbench với Python golden model cho so sánh pixel-wise nhiều kernel.
2. Tạo regression script (Gaussian/Sharpen/Emboss/Laplacian) và báo cáo mismatch/PSNR.
3. Sau khi regression ổn định mới chuyển synth/timing optimization.

---

## 1. Tổng quan kế hoạch
| Tuần | Phase | Mục tiêu chính | Deliverable | % Hoàn thành |
|------|-------|----------------|-------------|--------------|
| 1    | Research & Design | Block diagram + spec | Diagram + spec doc | 20% |
| 2    | Implementation | RTL modules core | Code SV + sim basic | 40% |
| 3    | Simulation & Verify | Test full pipeline | Testbench pass 95% | 60% |
| 4    | Synthesis & Optimize | Timing closure + report | Utilization report | 75% |
| 5    | Integration & Test | Hardware run | On-board test | 90% |
| 6    | Demo & Report | Final demo + slide | Video + report | 100% |

**Rủi ro & Mitigation**  
- Timing fail → ưu tiên pipeline + floorplan  
- D455 stream → Python hex fixed trước, sau mới realtime  
- Audio add-on (nếu thừa thời gian) → overlay FIR spectrum (tuần 5)

---

## 2. Công cụ sử dụng (ưu tiên open-source để vibe nhanh)

### Simulation (quan trọng nhất – làm trước Vivado)
- **Icarus Verilog (iverilog) + GTKWave** ← **ƯU TIÊN SỐ 1** (vibe kiểm chứng testbench cực nhanh, free, terminal)  
  Lý do: Chạy ngay trên Linux/Windows, waveform đẹp, debug 1 frame trong <10 giây.  
  Command mẫu (dùng mãi trong phase 2-3):
  ```bash
  iverilog -g2012 -Wall top.sv line_buffer.sv mac_array.sv tb_convolution.sv -o sim
  vvp sim
  gtkwave dump.vcd &
Sau khi testbench ổn (vibe OK) → migrate sang Vivado Simulator (để synthesize).

Design & Synthesis

Vivado 2022+ (SystemVerilog full)
Draw.io / Excalidraw (block diagram)
Python 3 + librealsense (capture hex từ D455)
GTKWave (waveform)
OBS Studio (record demo)

Verification

Python golden model (numpy.convolve + PSNR/SSIM)
Vivado Timing/Power Analyzer (sau phase 4)


3. Chi tiết từng Phase
PHASE 1: Research & High-Level Design (Tuần 1)
Mục tiêu: Xác định spec + architecture
Công việc:

Vẽ block diagram (AXI-Stream In → Line Buffer 4 dòng → MAC 25x3 → Normalize → Out)
Define parameter: 5x5 kernel (25×3 regs), fixed-point Q8.4, resolution 640x480
Capture 10 frame test từ D455 (hex 24-bit RGB)

Công cụ:

Draw.io + Python script D455

Nội dung tham khảo:

GitHub: 5usu/convolutions-on-fpga (line buffer + MAC)
Paper: "Energy Efficient Image Convolution on FPGA" (Stanford)
Xilinx UG479 (DSP48E1)
Librealsense Python docs

Milestone: Block diagram + file test_frame_0.hex + spec doc
Script Python capture: (hiện tại chưa có cam chưa cần chạy ngay cái này chỉ thấy nó trả output đứng chức năng)
Pythonimport pyrealsense2 as rs
import numpy as np
pipeline = rs.pipeline()
config = rs.config(); config.enable_stream(rs.stream.color, 640, 480, rs.format.bgr8, 30)
pipeline.start(config)
for i in range(10):
    img = np.asanyarray(pipeline.wait_for_frames().get_color_frame().get_data())
    with open(f'test_frame_{i}.hex', 'w') as f:
        for p in img.reshape(-1,3): f.write(f'{p[2]:02x}{p[1]:02x}{p[0]:02x}\n')
PHASE 2: Module Implementation (Tuần 2)
Mục tiêu: Code đầy đủ RTL
Modules chính:

line_buffer_4.sv (BRAM dual-port)
mac_array_25x3.sv (unroll 25 MAC/channel, DSP48E1)
kernel_loader.sv (AXI-Lite hoặc simple reg)
pipeline_stage.sv (5 stage)
top_convolution.sv

Công cụ:

VSCode + iverilog (test từng module ngay)
Python golden model

Tham khảo:

"High Throughput Spatial Convolution Filters on FPGAs" (Warwick)
"Reconfigurable Convolution Implementation for CNNs"

Milestone: Compile sạch + sim 32x32 frame với iverilog
PHASE 3: Simulation & Verification (Tuần 3) ← PHASE QUAN TRỌNG NHẤT
Mục tiêu: 95% functional correct
Công việc:

Viết testbench đầy đủ (tb_convolution.sv)
Test tất cả kernel (Gaussian, Sharpen, Emboss, Laplacian)
So sánh pixel-wise với Python (PSNR > 30 dB)
Edge case: zero-pad border

Công cụ VIBE:
Bashiverilog -g2012 top.sv tb_convolution.sv -o sim
vvp sim
gtkwave dump.vcd   # ← vibe ngay waveform pipeline
Sau khi vibe OK → chuyển Vivado Simulator.
Tham khảo:

Test vector từ librealsense examples
"A Novel FPGA-based CNN Hardware Accelerator" (arXiv)

Milestone: Testbench pass 95%, tất cả waveform sạch
PHASE 4: Synthesis & Optimization (Tuần 4)
Mục tiêu: Đạt throughput ≥ 300 MP/s
Công việc:

Synthesize → report DSP/BRAM/Freq
Optimize pipeline, resource sharing
Đo throughput: freq × pixels/clock

Công cụ: Vivado Implementation + TCL script
Tham khảo: Xilinx UG902 + UG479
Milestone: Post-PnR: ≥300 MP/s, timing clean (WNS > 0)
PHASE 5: Integration & Hardware Testing (Tuần 5)
Công việc:

Thêm AXI-Stream wrapper + VGA controller
Load kernel realtime (button/uart)
Stream hex từ Python → FPGA

Công cụ: Vivado Hardware Manager + Python UART script
Milestone: Demo realtime 1 clip D455 trên VGA
PHASE 6: Demo & Report (Tuần 6)
Công việc:

Slide 15-20p (architecture 20%, throughput 30%, result 30%)
Record video before/after (switch kernel realtime)
Viết report (PDF)

Công cụ: OBS Studio + LaTeX/Word
Kế hoạch Evaluation & Demo (15 phút seminar):

Setup (2p): D455 → hex → FPGA
Live Demo (10p):
Input video người di chuyển
Nhấn nút switch kernel: Blur → Sharpen → Edge
Split screen VGA: Original | Processed

Results (3p): Chart throughput/resource (DSP < 50%, BRAM < 20%)
Q&A

Metrics đo lường:

Throughput: ≥300 MP/s (Vivado report + counter)
FPS: 60-120 @720p
Quality: PSNR > 30 dB
Resource: DSP/BRAM usage
Latency: <5 ms/frame


4. Folder structure gợi ý
textconvolution_fpga/
├── src/              # .sv files
├── tb/               # testbench
├── hex/              # test_frame_*.hex từ D455
├── sim/              # dump.vcd
├── python/           # golden + capture
├── vivado_project/
└── docs/             # plan.md + report.pdf + slides.pptx
Bắt đầu ngay tuần 1: Chạy script Python capture + vẽ diagram.
Khi nào cần: Mình sẽ gửi skeleton code line_buffer.sv + mac_array.sv + tb_convolution.sv đầy đủ (chạy được iverilog ngay).

Xong viết lại toàn bộ Doc liên quan