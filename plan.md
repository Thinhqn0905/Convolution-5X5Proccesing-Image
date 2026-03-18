# PLAN CHI TIET DO AN: RGB 5x5 CONVOLUTION ENGINE (ZYNQ + D455)

## 1. Muc tieu va pham vi
- Xay dung pipeline 5x5 RGB convolution co kernel nap runtime.
- Hoan tat luong: camera Intel RealSense D455 -> stream du lieu -> xu ly -> xuat anh truoc/sau.
- Duy tri bo test regression cho RTL va doi chieu output.
- Chot duoc tai lieu tong ket cho seminar (demo + report + so lieu).

## 2. Trang thai hien tai (2026-03-18)

## Da hoan thanh
- RTL baseline da co: line buffer 5x5, kernel loader, MAC 25x3, top integration.
- Testbench self-check da co va da regression 5 kernel PASS.
- Pipeline D455 da chay that:
  - Stream lien tuc tren may hien tai.
  - Da luu anh truoc xu ly va sau xu ly.
  - Da xuat hex input/output theo frame.
- Skeleton Vivado da co (create project, run synth/impl, constraints mau).

## Ket qua chay that gan nhat
- D455 stream (8s/kernel):
  - gaussian5: 88 frame, ~10.02 fps
  - sharpen5: 92 frame, ~10.48 fps
  - laplacian5: 90 frame, ~10.21 fps
- RTL regression:
  - identity5, gaussian5, sharpen5, emboss5, laplacian5: PASS
  - valid_count = 144/144 moi case (test 16x16)

## Artifact da tao
- captures/d455/gaussian5/raw + processed + hex_in + hex_out
- captures/d455/sharpen5/raw + processed + hex_in + hex_out
- captures/d455/laplacian5/raw + processed + hex_in + hex_out
- sim/tb_out_<kernel>.hex va sim/expected_<kernel>.hex

## 3. Research tom tat (cho phase camera + FPGA)

## 3.1 Tham khao camera va Python wrapper
Nguon tham khao chinh:
- librealsense Python examples:
  - wrappers/python/examples/opencv_viewer_example.py
  - wrappers/python/examples/align-depth2color.py
  - wrappers/python/examples/frame_queue_example.py

Ket luan ap dung:
- Dung rs.pipeline + rs.config + enable_stream(color, BGR8) la luong co ban on dinh.
- Dung wait_for_frames() theo vong lap cho stream lien tuc.
- Neu can toc do cao hon, uu tien frame queue/multi-thread va giam tan suat ghi file.

## 3.2 Tham khao phan cung so va DSP
Nguon tham khao chinh:
- AMD/Xilinx UG479 (DSP48E1)
- AMD/Xilinx UG902 (synthesis flow)

Ket luan ap dung:
- MAC 25 tap RGB can uu tien pipeline ro rang truoc khi day fmax.
- Gate quan trong cho phase synth: WNS > 0, thong ke DSP/BRAM/Fmax, sau do moi chot throughput.

## 4. Ke hoach phase chi tiet tu hien tai den final

## Phase A - Camera stream + output before/after (DA XONG)
Muc tieu:
- Stream D455 lien tuc va xuat anh truoc/sau xu ly.
Deliverable:
- Script stream camera: python/d455_stream_process.py
- Script orchestration: scripts/run_d455_pipeline.ps1
- Output frame bundles trong captures/d455/*
Tieu chi pass:
- Co anh raw va processed cung frame index.
- Co hex_in va hex_out cung frame index.

## Phase B - RTL regression toan bo kernel (DA XONG)
Muc tieu:
- Xac nhan tinh dung RTL voi bo kernel bat buoc.
Deliverable:
- scripts/run_regression.ps1
- python/prepare_case.py (tao kernel.hex va expected.hex)
Tieu chi pass:
- 5/5 kernel PASS.
- Moi case co 144 output line cho test 16x16.

## Phase C - Test case mo rong can lam tiep (CAN THUC HIEN)
Muc tieu:
- Tang do tin cay truoc khi vao synth/hardware demo.
Cong viec:
1. Them test case reset giua frame.
2. Them test case valid gap/back-pressure.
3. Them test case overflow/saturation voi kernel am/duong lon.
4. Them test 32x32 va 640x480 synthetic profile.
Deliverable:
- File testbench mo rong trong tb/.
- Bao cao pass/fail theo tung case.
Gate pass:
- Khong X/Z khi out_valid=1.
- mismatch_count=0 voi expected stream.

## Phase D - Synthesis va timing closure (CAN THUC HIEN)
Muc tieu:
- Dat gate ky thuat >=250 MP/s (muc thuc dung), huong toi 300 MP/s.
Cong viec:
1. Chay vivado_project/project_create.tcl.
2. Chay vivado_project/run_synth.tcl.
3. Phan tich report: timing_post_route.rpt, util_post_route.rpt, power_post_route.rpt.
4. Toi uu: bo sung pipeline stage neu can, can bang resource.
Deliverable:
- report timing/resource/power.
Gate pass:
- WNS > 0.
- Co cong thuc throughput ro rang theo freq x pixel_per_clock.

## Phase E - Hardware integration realtime (CAN THUC HIEN)
Muc tieu:
- Chay duoc duong camera -> FPGA -> output hien thi/ghi ket qua.
Cong viec:
1. Chon giao tiep runtime kernel (AXI-Lite/UART).
2. Hoan tat wrapper stream input/output.
3. Dong bo format pixel va toc do truyen.
4. Chay demo switch kernel realtime.
Deliverable:
- Video demo truc tiep.
- Log thoi gian va fps he thong.
Gate pass:
- Chuyen kernel khong vo frame.
- He thong chay on dinh trong thoi gian demo.

## Phase F - Bao cao va chot seminar (CAN THUC HIEN)
Muc tieu:
- Chot slide + report day du ky thuat.
Noi dung bat buoc:
1. Kien truc 5x5 va dataflow.
2. Ket qua camera stream truoc/sau.
3. Ket qua regression va waveform checklist.
4. Ket qua synthesis/timing/resource.
5. Bai hoc kinh nghiem va huong mo rong.

## 5. Lenh chay chuan (runbook)

## Camera stream + xuat anh
- scripts/run_d455_pipeline.ps1

## Chay 1 kernel camera ngắn
- C:/Users/ADMIN/AppData/Local/Programs/Python/Python310/python.exe python/d455_stream_process.py --width 640 --height 480 --fps 30 --kernel gaussian5 --duration_sec 5 --max_frames 150 --save_every 10 --out_dir captures/d455/smoke

## Regression RTL
- scripts/run_regression.ps1

## Dem so dong output testbench
- (Get-Content .\sim\tb_out.hex | Measure-Object -Line).Lines

## 6. KPI va gate chap nhan
- Functional:
  - 5 kernel regression PASS.
  - testbench self-check mismatch=0, unknown=0.
- Camera pipeline:
  - Co cap anh before/after cho moi kernel da chay.
  - Co hex input/output frame theo index.
- Synthesis:
  - WNS > 0.
  - Co bang resource DSP/BRAM.
- Demo:
  - Trinh dien switch kernel voi luong du lieu thuc te.

## 7. Rui ro va giam thieu
- FPS camera software thap khi ghi file nhieu:
  - Giam save_every, tach thread ghi file, uu tien xử ly tren FPGA.
- Sai lech mapping output giua software va RTL:
  - Giu nguyen quy tac valid window x>=4, y>=4 trong script expected.
- Timing fail sau synth:
  - Tang pipeline stage, don gian hoa duong valid/control, toi uu ranh gioi module.

## 8. Cong viec tiep theo ngay lap tuc (48h)
1. Them 3 test case mo rong: reset-mid-frame, valid-gap, saturation-stress.
2. Chay synth batch va trich xuat report timing/resource dau tien.
3. Chot interface runtime kernel cho hardware demo (UART hoac AXI-Lite).
