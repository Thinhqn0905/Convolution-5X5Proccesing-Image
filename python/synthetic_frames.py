import argparse
from pathlib import Path


def pixel_rgb(x: int, y: int, frame_idx: int) -> tuple[int, int, int]:
    r = (17 * x + 3 * y + 11 * frame_idx) & 0xFF
    g = (5 * x + 13 * y + 29 * frame_idx) & 0xFF
    b = (19 * x + 7 * y + 41 * frame_idx) & 0xFF
    return r, g, b


def write_frame(path: Path, width: int, height: int, frame_idx: int) -> None:
    with path.open("w", encoding="ascii") as f:
        for y in range(height):
            for x in range(width):
                r, g, b = pixel_rgb(x, y, frame_idx)
                f.write(f"{r:02x}{g:02x}{b:02x}\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate deterministic RGB hex test frames.")
    parser.add_argument("--out", required=True, help="Output directory.")
    parser.add_argument("--count", type=int, default=1)
    parser.add_argument("--width", type=int, default=16)
    parser.add_argument("--height", type=int, default=16)
    args = parser.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    for frame_idx in range(args.count):
        write_frame(out_dir / f"test_frame_{frame_idx}.hex", args.width, args.height, frame_idx)

    print(f"Generated {args.count} frame(s) in {out_dir}")


if __name__ == "__main__":
    main()
