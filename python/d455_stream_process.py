# pyright: reportAttributeAccessIssue=false

import argparse
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
            [0, 0, 16, 0, 0],
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
            [0, -1, -1, -1, 0],
            [-1, 2, -4, 2, -1],
            [-1, -4, 20, -4, -1],
            [-1, 2, -4, 2, -1],
            [0, -1, -1, -1, 0],
        ],
        dtype=np.int32,
    ),
    "emboss5": np.array(
        [
            [-2, -1, 0, 1, 2],
            [-1, 0, 1, 2, 1],
            [0, 1, 2, 1, 0],
            [1, 2, 1, 0, -1],
            [2, 1, 0, -1, -2],
        ],
        dtype=np.int32,
    ),
    "laplacian5": np.array(
        [
            [0, 0, -1, 0, 0],
            [0, -1, -2, -1, 0],
            [-1, -2, 16, -2, -1],
            [0, -1, -2, -1, 0],
            [0, 0, -1, 0, 0],
        ],
        dtype=np.int32,
    ),
}


def sat_u8(val: int) -> int:
    if val < 0:
        return 0
    if val > 255:
        return 255
    return val


def process_rtl_style(rgb: np.ndarray, kernel: np.ndarray, norm_shift: int = 4) -> np.ndarray:
    h, w, _ = rgb.shape
    out_i32 = np.zeros((h, w, 3), dtype=np.int32)

    for c in range(3):
        # anchor=(4,4) matches 5x5 stream-style window reference at current (x,y).
        filtered = cv2.filter2D(
            rgb[:, :, c].astype(np.float32),
            ddepth=cv2.CV_32F,
            kernel=kernel.astype(np.float32),
            anchor=(4, 4),
            borderType=cv2.BORDER_CONSTANT,
        )
        out_i32[:, :, c] = np.right_shift(filtered.astype(np.int32), norm_shift)

    out_i32[:4, :, :] = 0
    out_i32[:, :4, :] = 0
    return np.clip(out_i32, 0, 255).astype(np.uint8)


def write_hex_rgb(path: Path, frame_rgb: np.ndarray) -> None:
    with path.open("w", encoding="ascii") as f:
        for p in frame_rgb.reshape(-1, 3):
            f.write(f"{int(p[0]):02x}{int(p[1]):02x}{int(p[2]):02x}\n")


def save_frame_bundle(base_dir: Path, frame_idx: int, in_rgb: np.ndarray, out_rgb: np.ndarray) -> None:
    raw_dir = base_dir / "raw"
    proc_dir = base_dir / "processed"
    hex_in_dir = base_dir / "hex_in"
    hex_out_dir = base_dir / "hex_out"

    for d in (raw_dir, proc_dir, hex_in_dir, hex_out_dir):
        d.mkdir(parents=True, exist_ok=True)

    stem = f"frame_{frame_idx:06d}"

    cv2.imwrite(str(raw_dir / f"{stem}.png"), cv2.cvtColor(in_rgb, cv2.COLOR_RGB2BGR))
    cv2.imwrite(str(proc_dir / f"{stem}.png"), cv2.cvtColor(out_rgb, cv2.COLOR_RGB2BGR))

    write_hex_rgb(hex_in_dir / f"{stem}.hex", in_rgb)
    write_hex_rgb(hex_out_dir / f"{stem}.hex", out_rgb)


def main() -> None:
    parser = argparse.ArgumentParser(description="Stream Intel RealSense D455 and export pre/post-processed frames")
    parser.add_argument("--width", type=int, default=640)
    parser.add_argument("--height", type=int, default=480)
    parser.add_argument("--fps", type=int, default=30)
    parser.add_argument("--kernel", choices=KERNELS.keys(), default="gaussian5")
    parser.add_argument("--duration_sec", type=float, default=10.0)
    parser.add_argument("--max_frames", type=int, default=300)
    parser.add_argument("--save_every", type=int, default=10)
    parser.add_argument("--out_dir", default="captures/d455")
    parser.add_argument("--norm_shift", type=int, default=4)
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    kernel = KERNELS[args.kernel]

    pipeline_ctor = getattr(rs, "pipeline")
    config_ctor = getattr(rs, "config")
    stream_enum = getattr(rs, "stream")
    format_enum = getattr(rs, "format")

    pipeline = pipeline_ctor()
    config = config_ctor()
    config.enable_stream(getattr(stream_enum, "color"), args.width, args.height, getattr(format_enum, "bgr8"), args.fps)

    print("Starting D455 color stream...")
    profile = pipeline.start(config)
    _ = profile.get_device()

    frame_idx = 0
    saved_idx = 0
    start_t = time.time()

    try:
        while True:
            if args.max_frames > 0 and frame_idx >= args.max_frames:
                break
            if args.duration_sec > 0 and (time.time() - start_t) >= args.duration_sec:
                break

            frames = pipeline.wait_for_frames(timeout_ms=5000)
            color_frame = frames.get_color_frame()
            if not color_frame:
                continue

            bgr = np.asanyarray(color_frame.get_data())
            rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
            out_rgb = process_rtl_style(rgb, kernel, args.norm_shift)

            if frame_idx % args.save_every == 0:
                save_frame_bundle(out_dir, frame_idx, rgb, out_rgb)
                saved_idx += 1

            frame_idx += 1

    finally:
        pipeline.stop()

    elapsed = max(time.time() - start_t, 1e-6)
    print(f"Done. Captured frames={frame_idx}, saved_pairs={saved_idx}, elapsed={elapsed:.2f}s, capture_fps={frame_idx/elapsed:.2f}")
    print(f"Output directory: {out_dir}")


if __name__ == "__main__":
    main()
