# HƯỚNG DẪN STREAM DỮ LIỆU VÀ XỬ LÝ ẢNH TRÊN BOARD FPGA ARTY A7 100T
## (Real-Time Hybrid Image Processing & Hardware Streaming Guide)

Tài liệu này hướng dẫn chi tiết các giải pháp thực tế để triển khai hệ thống xử lý ảnh thời gian thực (Real-time Video Processing) sử dụng camera **Intel RealSense D455** kết hợp với board mạch FPGA **Arty A7 100T**.

---

## 1. Phân Tích Băng Thông & Thách Thức Phần Cứng

Khi đưa hệ thống xử lý ảnh lên mạch thật, thách thức lớn nhất không nằm ở tốc độ tính toán của FPGA (RTL Core chạy ở 100MHz cực kỳ nhanh) mà nằm ở **băng thông truyền thông (I/O Bandwidth Bottleneck)**.

### Yêu cầu luồng dữ liệu 1080p @ 60fps (RGB888):
* **Độ phân giải:** $1920 \times 1080$ pixel.
* **Tốc độ khung hình:** 60 frames/giây.
* **Định dạng màu:** RGB 24-bit (3 bytes mỗi pixel).
* **Băng thông thô yêu cầu (Raw Bandwidth):**
  $$\text{Băng thông} = 1920 \times 1080 \times 60 \times 3 \text{ bytes/s} \approx 373.24 \text{ MB/s} \approx 2.98 \text{ Gbps}$$

### Khả năng đáp ứng của các cổng giao tiếp trên Arty A7 100T:

| Cổng Giao Tiếp trên Arty A7 | Băng Thông Lý Thuyết | Băng Thông Thực Tế | Khả năng chạy 1080p@60fps (Raw) |
| :--- | :--- | :--- | :--- |
| **USB-Micro B (UART qua FT2232HQ)** | 12 Mbps (UART max) | ~1.2 MB/s | ❌ Không thể (Thiếu 300 lần băng thông) |
| **Ethernet (10/100 Mbps)** | 100 Mbps | ~10 - 12 MB/s | ❌ Không thể (Thiếu 30 lần băng thông) |
| **PMOD Ports (GPIO thông thường)** | Lên tới 100 MHz | Phụ thuộc vào ngoại vi | ⚠️ Cần module ngoài (như HDMI/USB 3.0 PMOD) |

---

## 2. Phương Án 1: Hybrid Real-Time Streaming (PC làm Host + FPGA xử lý)
> **Phù hợp nhất:** Cho việc trình diễn Seminar, làm đồ án tốt nghiệp mà không tốn thêm chi phí mua phần cứng gắn ngoài.

Trong phương án này, máy tính (PC) sẽ làm Host trung gian điều phối dòng dữ liệu. PC lấy dữ liệu từ Camera D455 qua USB 3.0 tốc độ cao, xử lý tiền giản lược (Downscale/Frame-skip) rồi truyền nhận với FPGA qua UART.

### Sơ đồ khối dòng dữ liệu (Dataflow):
```
  [ Camera D455 ]
         │
         ▼ (USB 3.0: 1080p @ 60fps)
  [ Host PC (Python Script) ]
         │
         ├─► 1. Đọc frame ảnh từ Camera D455 bằng `pyrealsense2`.
         ├─► 2. Giảm độ phân giải (ví dụ về 160x120 hoặc 320x240) để giảm băng thông.
         ├─► 3. Tách kênh màu R, G, B và truyền tuần tự qua UART cổng COM ảo.
         ▼
  [ Board FPGA Arty A7 100T ]
         │
         ├─► 1. Bộ nhận UART RX nhận luồng pixel, chuyển thành giao thức AXI-Stream.
         ├─► 2. RGB Convolution Core (5x5 Line Buffer + MAC Array) tính toán bộ lọc.
         ├─► 3. Chuyển kết quả AXI-Stream ngược lại UART TX.
         ▼
  [ Host PC (Python Script) ]
         │
         ├─► 1. Nhận luồng pixel đã lọc qua cổng COM.
         ├─► 2. Ráp các pixel thành khung ảnh hoàn chỉnh.
         ├─► 3. Dựng hình bằng OpenCV hiển thị so sánh song song giữa ảnh Gốc và ảnh Đã lọc.
```

### Các kỹ thuật tối ưu hóa để chạy mượt mà:
1. **UART Baudrate Tuning:** Cấu hình UART trên FPGA và Python chạy ở tốc độ baud cao nhất mà chip FT2232HQ hỗ trợ ổn định (ví dụ `3,000,000 baud` hoặc `12,000,000 baud`).
2. **Kích thước Frame nhỏ (Downscale):** Sử dụng các kích thước ảnh tiêu chuẩn nhỏ như `160x120` hoặc `320x240`. Với kích thước `160x120` ở tốc độ 3 Mbps, hệ thống có thể đạt tốc độ mượt mà từ **5 - 10 FPS**, hoàn hảo để hiển thị trực tiếp chuyển động trước camera.
3. **Chế độ Single-Frame (On-Demand):** Nhấn một phím trên PC để "chụp" một frame 1080p chất lượng cao, gửi qua UART (mất khoảng 1-2 giây để truyền), FPGA tính toán tức thời và trả về ảnh đã lọc sắc nét.

---

## 3. Phương Án 2: High-Speed Direct Streaming (Không qua PC làm host trung gian)
> **Phù hợp nhất:** Cho các ứng dụng công nghiệp thực tế yêu cầu thời gian thực tuyệt đối (Zero-Latency) ở độ phân giải cao 1080p @ 60fps.

Để đạt được tốc độ 1080p@60fps thô trên FPGA, chúng ta bắt buộc phải bỏ qua đường truyền nối tiếp UART chậm chạp và nạp dữ liệu trực tiếp vào chip thông qua các cổng mở rộng tốc độ cao.

### Giải pháp A: Sử dụng HDMI PMOD (Được khuyên dùng nhất)
* **Nguyên lý:** Kết nối trực tiếp cổng HDMI Out từ camera (hoặc cổng xuất HDMI từ PC đóng vai trò nguồn phát luồng ảnh D455) vào board FPGA thông qua một **Module PMOD HDMI Input** (như Digilent PMOD HDMI).
* **Kết nối phần cứng:**
  ```
  [ Camera / PC ] ──(Cáp HDMI)──► [ PMOD HDMI Input ] ──► [ Cổng PMOD Arty A7 ] ──► [ Artix-7 FPGA ]
  ```
* **Xử lý trên FPGA:**
  1. Sử dụng IP **HDMI Receiver / DVI Decoder** để giải mã luồng tín hiệu HDMI vi sai (TMDS) thành luồng pixel song song chuẩn RGB888 cùng tín hiệu đồng bộ `hsync`, `vsync`, `data_enable`.
  2. Đưa luồng pixel trực tiếp vào Module **RGB 5x5 Convolution Engine** của chúng ta. Nhân chập tính toán tức thì theo xung nhịp pixel clock (148.5 MHz cho 1080p60).
  3. Xuất luồng pixel sau xử lý ra IP **HDMI Transmitter / DVI Encoder** qua cổng xuất **HDMI Output PMOD** lên màn hình máy tính/TV.
* **Ưu điểm:** Độ trễ gần như bằng 0 (chỉ trễ 5 dòng quét do Line Buffer 5x5), xử lý 60 khung hình/giây siêu mượt mà ở độ phân giải Full HD.

### Giải pháp B: Sử dụng USB 3.0 FIFO PMOD (FT600 / FT601)
* **Nguyên lý:** Mua thêm mạch giao tiếp USB 3.0 PMOD gắn chip **FTDI FT600/FT601** (hỗ trợ USB 3.0 SuperSpeed sang bus song song FIFO 16-bit hoặc 32-bit).
* **Băng thông:** Cho phép truyền dữ liệu giữa PC và FPGA với tốc độ cực cao, lên tới **100MB/s - 200MB/s** trên các chân PMOD.
* **Quy trình:** PC stream camera D455 1080p60 -> Gửi dạng Raw/Compressed qua thư viện FT60x D2XX xuống FPGA -> FPGA giải nén/xử lý nhân chập -> Trả ngược dữ liệu đã xử lý về PC hiển thị.

---

## 4. Hướng Dẫn Tích Hợp Block Design Hệ Thống (Phương Án 1 - UART Hybrid)

Dưới đây là sơ đồ khối tích hợp thiết kế hệ thống trên Vivado IP Integrator cho phương án Hybrid chạy thực tế:

```
┌────────────────────────────────────────────────────────────────────────┐
│                          Artix-7 FPGA (Arty A7)                        │
│                                                                        │
│  ┌──────────────┐     AXI-Stream     ┌──────────────────────────────┐  │
│  │   UART RX    ├───────────────────►│                              │  │
│  │ (Custom / IP)│                    │                              │  │
│  └──────┬───────┘                    │   RGB 5x5 Convolution Engine │  │
│         │ (Chân A9 - RX)             │   (axi_stream_conv_wrapper)  │  │
│         │                            │                              │  │
│  ┌──────▼───────┐     AXI-Stream     │                              │  │
│  │   UART TX    │◄───────────────────┤                              │  │
│  │ (Custom / IP)│                    └──────────────┬───────────────┘  │
│  └──────┬───────┘                                   ▲                  │
│         │ (Chân D10 - TX)                           │                  │
│         ▼                                           │ AXI-Lite         │
│     (Cáp USB)                                ┌──────┴───────┐          │
│         │                                    │  AXI-Lite    │          │
│         ▼                                    │  Controller  │          │
│   (Cổng COM ảo)                              └──────┬───────┘          │
│         │                                           ▲                  │
│         ▼                                           │                  │
│   [ Python Host ] ───(Cập nhật Kernel Runtime)──────┘                  │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Các bước thiết lập trên Vivado:
1. **Thiết kế khối giao tiếp UART sang AXI-Stream:**
   * Viết module nhận UART RX: Chuyển dữ liệu serial (1 byte mỗi lần) thành định dạng `AXI-Stream` với tín hiệu `tdata`, `tvalid`, `tready`.
   * Gộp 3 byte liên tiếp nhận được thành 1 pixel RGB888 (24-bit) để cấp cho lõi nhân chập.
2. **Đóng gói IP Convolution Core:**
   * Sử dụng file AXI-Stream wrapper có sẵn [axi_stream_conv_wrapper.sv](file:///e:/PROJECTS/convolution_fpga/src/axi_stream_conv_wrapper.sv) làm IP xử lý trung tâm.
3. **Gán chân vật lý trong file constraints:**
   * Giữ nguyên gán chân `clk` (E3) và `rst` (D9 - BTN0).
   * Gán chân cho `uart_rx` và `uart_tx` tương ứng với giao tiếp USB-UART của board Arty A7:
     ```xdc
     set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports uart_rx]
     set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports uart_tx]
     ```
