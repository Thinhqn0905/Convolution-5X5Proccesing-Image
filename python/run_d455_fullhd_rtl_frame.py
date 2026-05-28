import argparse
import hashlib
import json
import re
import subprocess
import time
from pathlib import Path

import cv2
import numpy as np
import pyrealsense2 as rs  # type: ignore[import]


KERNELS = {
    "identity5": np.array(
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 256, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
        ],
        dtype=np.int32,
    ),
    "gaussian5": np.array(
        [
            [1, 4, 6, 4, 1],
            [4, 16, 24, 16, 4],
            [6, 24, 36, 24, 6],
            [4, 16, 24, 16, 4],
            [1, 4, 6, 4, 1],
        ],
        dtype=np.int32,
    ),
    "sharpen5": np.array(
        [
            [0, -16, -16, -16, 0],
            [-16, 32, -64, 32, -16],
            [-16, -64, 320, -64, -16],
            [-16, 32, -64, 32, -16],
            [0, -16, -16, -16, 0],
        ],
        dtype=np.int32,
    ),
    "emboss5": np.array(
        [
            [-32, -16, 0, 16, 32],
            [-16, 0, 16, 32, 16],
            [0, 16, 32, 16, 0],
            [16, 32, 16, 0, -16],
            [32, 16, 0, -16, -32],
        ],
        dtype=np.int32,
    ),
    "laplacian5": np.array(
        [
            [0, 0, -16, 0, 0],
            [0, -16, -32, -16, 0],
            [-16, -32, 256, -32, -16],
            [0, -16, -32, -16, 0],
            [0, 0, -16, 0, 0],
        ],
        dtype=np.int32,
    ),
}


def sha1_file(path: Path) -> str:
    h = hashlib.sha1()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def run_cmd(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    proc = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(
            "Command failed: "
            + " ".join(cmd)
            + "\nSTDOUT:\n"
            + proc.stdout
            + "\nSTDERR:\n"
            + proc.stderr
        )
    return proc


def parse_tb_pass(log: str) -> tuple[str, int, int]:
    m = re.search(r"TB PASS:\s+valid_count=(\d+)\s+expected=(\d+)", log)
    if m:
        return ("PASS", int(m.group(1)), int(m.group(2)))

    m = re.search(r"TB FAIL:\s+valid_count=(\d+)\s+expected=(\d+)", log)
    if m:
        return ("FAIL", int(m.group(1)), int(m.group(2)))

    return ("UNKNOWN", -1, -1)


def capture_d455_rgb(width: int, height: int, fps: int, warmup: int) -> np.ndarray:
    pipeline = rs.pipeline()
    config = rs.config()
    config.enable_stream(rs.stream.color, width, height, rs.format.bgr8, fps)

    pipeline.start(config)
    try:
        frame = None
        for _ in range(max(warmup, 1)):
            frames = pipeline.wait_for_frames(timeout_ms=5000)
            frame = frames.get_color_frame()

        if frame is None:
            raise RuntimeError("No color frame returned by D455")

        bgr = np.asanyarray(frame.get_data())
        return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    finally:
        pipeline.stop()


def write_hex_rgb(path: Path, frame: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    flat = frame.reshape(-1, 3)
    with path.open("w", encoding="ascii") as f:
        for start in range(0, flat.shape[0], 100_000):
            chunk = flat[start : start + 100_000]
            f.write("".join(f"{int(r):02x}{int(g):02x}{int(b):02x}\n" for r, g, b in chunk))


def write_kernel_hex(path: Path, kernel: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii") as f:
        for value in kernel.reshape(-1):
            f.write(f"{int(value) & 0xFFFF:04x}\n")


def read_stream_hex(path: Path) -> np.ndarray:
    values: list[tuple[int, int, int]] = []
    with path.open("r", encoding="ascii") as f:
        for line in f:
            s = line.strip()
            if len(s) == 6:
                values.append((int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)))
    return np.array(values, dtype=np.uint8)


def reconstruct_full_frame(stream: np.ndarray, width: int, height: int, ksize: int = 5) -> np.ndarray:
    frame = np.zeros((height, width, 3), dtype=np.uint8)
    valid_h = height - (ksize - 1)
    valid_w = width - (ksize - 1)
    frame[ksize - 1 :, ksize - 1 :, :] = stream.reshape(valid_h, valid_w, 3)
    return frame


def expected_valid_region(frame: np.ndarray, kernel: np.ndarray, norm_shift: int = 8) -> np.ndarray:
    h, w, _ = frame.shape
    acc = np.zeros((h - 4, w - 4, 3), dtype=np.int32)
    src = frame.astype(np.int32)

    for ky in range(5):
        for kx in range(5):
            acc += src[ky : ky + h - 4, kx : kx + w - 4, :] * int(kernel[ky, kx])

    out = acc >> norm_shift
    return np.clip(out, 0, 255).astype(np.uint8)


def save_png(path: Path, rgb: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    ok = cv2.imwrite(str(path), cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR))
    if not ok:
        raise RuntimeError(f"Failed to write {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Capture one D455 frame, resize to Full HD, and run it through RTL")
    parser.add_argument("--workspace", default=".")
    parser.add_argument("--out_dir", default="captures/d455/fullhd_rtl_frame")
    parser.add_argument("--capture_width", type=int, default=1280)
    parser.add_argument("--capture_height", type=int, default=720)
    parser.add_argument("--capture_fps", type=int, default=30)
    parser.add_argument("--feed_width", type=int, default=1920)
    parser.add_argument("--feed_height", type=int, default=1080)
    parser.add_argument("--warmup", type=int, default=12)
    parser.add_argument("--kernel", choices=sorted(KERNELS.keys()), default="gaussian5")
    parser.add_argument("--compile_only", action="store_true")
    parser.add_argument("--reuse_input", action="store_true")
    args = parser.parse_args()

    ws = Path(args.workspace).resolve()
    out_dir = (ws / args.out_dir).resolve()
    raw_dir = out_dir / "raw"
    feed_dir = out_dir / "feed_rgb"
    processed_dir = out_dir / args.kernel / "processed"
    hex_in_dir = out_dir / "hex_in"
    hex_out_dir = out_dir / args.kernel / "hex_out"
    report_path = out_dir / args.kernel / f"fullhd_rtl_{args.kernel}_report.json"

    frame_stem = "frame_000000"
    raw_png = raw_dir / f"{frame_stem}.png"
    feed_png = feed_dir / f"{frame_stem}.png"
    feed_hex = hex_in_dir / f"{frame_stem}.hex"
    processed_png = processed_dir / f"{frame_stem}.png"
    rtl_hex_out = hex_out_dir / f"{frame_stem}.hex"

    if args.reuse_input and feed_png.exists() and feed_hex.exists():
        feed_rgb = cv2.cvtColor(cv2.imread(str(feed_png), cv2.IMREAD_COLOR), cv2.COLOR_BGR2RGB)
        raw_shape = None
    else:
        raw_rgb = capture_d455_rgb(args.capture_width, args.capture_height, args.capture_fps, args.warmup)
        feed_rgb = cv2.resize(raw_rgb, (args.feed_width, args.feed_height), interpolation=cv2.INTER_LINEAR)
        save_png(raw_png, raw_rgb)
        save_png(feed_png, feed_rgb)
        write_hex_rgb(feed_hex, feed_rgb)
        raw_shape = list(raw_rgb.shape)

    sim_dir = ws / "sim"
    sim_dir.mkdir(parents=True, exist_ok=True)
    sim_in = sim_dir / "fullhd_frame_in.hex"
    sim_kernel = sim_dir / "fullhd_kernel.hex"
    sim_out = sim_dir / "fullhd_frame_out.hex"
    sim_vvp = sim_dir / "fullhd_frame.vvp"

    write_hex_rgb(sim_in, feed_rgb)
    write_kernel_hex(sim_kernel, KERNELS[args.kernel])

    compile_cmd = [
        "iverilog",
        "-g2012",
        "-Wall",
        f"-DTB_IMAGE_W={args.feed_width}",
        f"-DTB_IMAGE_H={args.feed_height}",
        "-o",
        str(sim_vvp),
        "src/top_convolution.sv",
        "src/line_buffer_4.sv",
        "src/kernel_loader.sv",
        "src/mac_array_25x3.sv",
        "tb/tb_fullhd_frame.sv",
    ]
    compile_start = time.perf_counter()
    run_cmd(compile_cmd, ws)
    compile_ms = (time.perf_counter() - compile_start) * 1000.0

    if args.compile_only:
        print(f"Compile completed: {sim_vvp}")
        return

    sim_start = time.perf_counter()
    sim_proc = run_cmd(["vvp", str(sim_vvp)], ws)
    sim_wall_ms = (time.perf_counter() - sim_start) * 1000.0
    sim_log = sim_proc.stdout + "\n" + sim_proc.stderr
    tb_status, tb_valid, tb_expected = parse_tb_pass(sim_log)

    stream = read_stream_hex(sim_out)
    if stream.shape[0] != (args.feed_width - 4) * (args.feed_height - 4):
        raise RuntimeError(f"Unexpected RTL stream length: {stream.shape[0]}")

    out_rgb = reconstruct_full_frame(stream, args.feed_width, args.feed_height)
    save_png(processed_png, out_rgb)
    write_hex_rgb(rtl_hex_out, out_rgb)

    valid_expected = expected_valid_region(feed_rgb, KERNELS[args.kernel])
    mismatch = stream.reshape(args.feed_height - 4, args.feed_width - 4, 3) != valid_expected
    mismatch_pixels = int(np.count_nonzero(np.any(mismatch, axis=2)))
    mismatch_channels = int(np.count_nonzero(mismatch))

    report = {
        "source": "Intel RealSense D455 RGB",
        "capture_resolution": [args.capture_width, args.capture_height],
        "captured_raw_shape": raw_shape,
        "feed_resolution": [args.feed_width, args.feed_height],
        "kernel": args.kernel,
        "kernel_coefficients_q8": KERNELS[args.kernel].tolist(),
        "rtl_tb_status": tb_status,
        "rtl_valid_samples": tb_valid,
        "rtl_expected_valid_samples": tb_expected,
        "golden_compare": "PASS" if mismatch_pixels == 0 else "FAIL",
        "mismatch_pixels": mismatch_pixels,
        "mismatch_channels": mismatch_channels,
        "compile_wall_ms": compile_ms,
        "sim_wall_ms": sim_wall_ms,
        "paths": {
            "raw_png": str(raw_png.relative_to(ws)).replace("\\", "/") if raw_png.exists() else "",
            "feed_png": str(feed_png.relative_to(ws)).replace("\\", "/"),
            "feed_hex": str(feed_hex.relative_to(ws)).replace("\\", "/"),
            "processed_png": str(processed_png.relative_to(ws)).replace("\\", "/"),
            "rtl_hex_out": str(rtl_hex_out.relative_to(ws)).replace("\\", "/"),
            "report_json": str(report_path.relative_to(ws)).replace("\\", "/"),
        },
        "sha1": {
            "feed_png": sha1_file(feed_png),
            "processed_png": sha1_file(processed_png),
            "rtl_hex_out": sha1_file(rtl_hex_out),
        },
    }

    report_path.parent.mkdir(parents=True, exist_ok=True)
    with report_path.open("w", encoding="ascii") as f:
        json.dump(report, f, indent=2)

    print(f"D455 Full HD RTL frame done: kernel={args.kernel}")
    print(f"TB={tb_status} valid={tb_valid}/{tb_expected}")
    print(f"Golden compare={report['golden_compare']} mismatch_pixels={mismatch_pixels}")
    print(f"Processed PNG: {processed_png}")
    print(f"Report JSON: {report_path}")


if __name__ == "__main__":
    main()
