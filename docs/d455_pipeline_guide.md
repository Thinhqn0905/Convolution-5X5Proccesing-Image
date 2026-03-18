# D455 Pipeline Guide

## Muc tieu
Huong dan chay Intel RealSense D455 stream lien tuc va xuat du lieu:
- Anh truoc xu ly (raw)
- Anh sau xu ly (processed)
- Hex input/output theo frame

## Script chinh
- python/d455_stream_process.py
- scripts/run_d455_pipeline.ps1

## Chay nhanh 1 kernel
From workspace root:

```powershell
C:/Users/ADMIN/AppData/Local/Programs/Python/Python310/python.exe python/d455_stream_process.py --width 640 --height 480 --fps 30 --kernel gaussian5 --duration_sec 5 --max_frames 150 --save_every 10 --out_dir captures/d455/smoke
```

## Chay day du 3 kernel + regression

```powershell
.\scripts\run_d455_pipeline.ps1
```

## Thu muc output
Moi kernel co cau truc:
- captures/d455/<kernel>/raw
- captures/d455/<kernel>/processed
- captures/d455/<kernel>/hex_in
- captures/d455/<kernel>/hex_out

Ten file theo frame index, vi du:
- frame_000000.png
- frame_000010.png
- frame_000020.png

## Tieu chi pass can kiem
1. So file trong raw va processed phai bang nhau.
2. So file trong hex_in va hex_out phai bang nhau.
3. Cung frame index phai ton tai day du 4 file (raw/processed/hex_in/hex_out).
4. Sau khi chay xong pipeline, regression script bao 5/5 kernel PASS.

## Test case can thuc hien sau moi lan thay doi
1. identity5 regression
2. gaussian5 regression
3. sharpen5 regression
4. emboss5 regression
5. laplacian5 regression
6. D455 smoke stream 5s

## Luu y hieu nang
- FPS software phu thuoc CPU va tan suat ghi file.
- Neu can fps cao hon:
  - tang save_every
  - giam do phan giai
  - tach thread ghi file
  - day phan tich chap tren FPGA
