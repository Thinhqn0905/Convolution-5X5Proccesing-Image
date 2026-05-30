import argparse
import platform
import statistics
import time

import cv2
import numpy as np


KERNELS_Q8 = {
    "gaussian5_filter2d": np.array(
        [
            [1, 4, 6, 4, 1],
            [4, 16, 24, 16, 4],
            [6, 24, 36, 24, 6],
            [4, 16, 24, 16, 4],
            [1, 4, 6, 4, 1],
        ],
        dtype=np.float32,
    )
    / 256.0,
    "sharpen5_filter2d": np.array(
        [
            [0, -16, -16, -16, 0],
            [-16, 32, -64, 32, -16],
            [-16, -64, 320, -64, -16],
            [-16, 32, -64, 32, -16],
            [0, -16, -16, -16, 0],
        ],
        dtype=np.float32,
    )
    / 256.0,
    "laplacian5_filter2d": np.array(
        [
            [0, 0, -16, 0, 0],
            [0, -16, -32, -16, 0],
            [-16, -32, 256, -32, -16],
            [0, -16, -32, -16, 0],
            [0, 0, -16, 0, 0],
        ],
        dtype=np.float32,
    )
    / 256.0,
    "sobel_x5_filter2d": np.array(
        [
            [-5, -10, 0, 10, 5],
            [-20, -40, 0, 40, 20],
            [-30, -60, 0, 60, 30],
            [-20, -40, 0, 40, 20],
            [-5, -10, 0, 10, 5],
        ],
        dtype=np.float32,
    )
    / 256.0,
    "sobel_y5_filter2d": np.array(
        [
            [-5, -20, -30, -20, -5],
            [-10, -40, -60, -40, -10],
            [0, 0, 0, 0, 0],
            [10, 40, 60, 40, 10],
            [5, 20, 30, 20, 5],
        ],
        dtype=np.float32,
    )
    / 256.0,
}


def apply_kernel(image, kernel_name):
    if kernel_name == "gaussian5_blur":
        return cv2.GaussianBlur(image, (5, 5), 0, borderType=cv2.BORDER_REPLICATE)
    return cv2.filter2D(
        image,
        ddepth=-1,
        kernel=KERNELS_Q8[kernel_name],
        borderType=cv2.BORDER_REPLICATE,
    )


def bench_case(width, height, iterations, warmup, threads, kernel_name):
    if threads is not None:
        cv2.setNumThreads(threads)

    image = np.random.default_rng(1234).integers(
        0, 256, size=(height, width, 3), dtype=np.uint8
    )

    for _ in range(warmup):
        apply_kernel(image, kernel_name)

    times = []
    out = image
    for _ in range(iterations):
        t0 = time.perf_counter()
        out = apply_kernel(image, kernel_name)
        t1 = time.perf_counter()
        times.append(t1 - t0)

    checksum = int(out.sum(dtype=np.uint64) & np.uint64(0xFFFFFFFF))
    median_s = statistics.median(times)
    mean_s = statistics.mean(times)
    pixels = width * height
    return {
        "width": width,
        "height": height,
        "kernel": kernel_name,
        "threads": cv2.getNumThreads(),
        "median_ms": median_s * 1e3,
        "mean_ms": mean_s * 1e3,
        "fps": 1.0 / median_s,
        "mpix_s": pixels / median_s / 1e6,
        "checksum": checksum,
    }


def print_result(result):
    print(
        f"{result['width']}x{result['height']} RGB | "
        f"{result['kernel']:<19} | "
        f"threads={result['threads']:>2} | "
        f"median={result['median_ms']:>7.3f} ms | "
        f"mean={result['mean_ms']:>7.3f} ms | "
        f"fps={result['fps']:>8.1f} | "
        f"throughput={result['mpix_s']:>8.1f} Mpix/s | "
        f"checksum={result['checksum']}"
    )


def main():
    parser = argparse.ArgumentParser(
        description="Benchmark CPU 5x5 image filters on RGB uint8 images."
    )
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--warmup", type=int, default=20)
    parser.add_argument(
        "--sizes",
        nargs="*",
        default=["640x480", "1280x720", "1920x1080"],
        help="Image sizes as WIDTHxHEIGHT.",
    )
    args = parser.parse_args()

    print(f"Python:   {platform.python_version()}")
    print(f"OpenCV:   {cv2.__version__}")
    print(f"NumPy:    {np.__version__}")
    print(f"Platform: {platform.platform()}")
    print("Kernels:  RGB uint8, 5x5, BORDER_REPLICATE")
    print("          gaussian5_blur uses OpenCV GaussianBlur; others use OpenCV filter2D.")
    print()

    parsed_sizes = []
    for size in args.sizes:
        width_s, height_s = size.lower().split("x", 1)
        parsed_sizes.append((int(width_s), int(height_s)))

    original_threads = cv2.getNumThreads()
    kernels = [
        "gaussian5_blur",
        "gaussian5_filter2d",
        "sharpen5_filter2d",
        "laplacian5_filter2d",
        "sobel_x5_filter2d",
        "sobel_y5_filter2d",
    ]
    for label, threads in [("OpenCV default threading", original_threads), ("Single thread", 1)]:
        print(label)
        for kernel_name in kernels:
            for width, height in parsed_sizes:
                print_result(
                    bench_case(width, height, args.iterations, args.warmup, threads, kernel_name)
                )
        print()


if __name__ == "__main__":
    main()
