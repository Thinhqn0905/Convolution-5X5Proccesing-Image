#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <time.h>
#endif

typedef struct {
    const char *name;
    int coeff[25];
} kernel_t;

static const kernel_t kernels[] = {
    {
        "gaussian5",
        {
            1, 4, 6, 4, 1,
            4, 16, 24, 16, 4,
            6, 24, 36, 24, 6,
            4, 16, 24, 16, 4,
            1, 4, 6, 4, 1,
        },
    },
    {
        "sharpen5",
        {
            0, -16, -16, -16, 0,
            -16, 32, -64, 32, -16,
            -16, -64, 320, -64, -16,
            -16, 32, -64, 32, -16,
            0, -16, -16, -16, 0,
        },
    },
    {
        "laplacian5",
        {
            0, 0, -16, 0, 0,
            0, -16, -32, -16, 0,
            -16, -32, 256, -32, -16,
            0, -16, -32, -16, 0,
            0, 0, -16, 0, 0,
        },
    },
    {
        "sobel_x5",
        {
            -5, -10, 0, 10, 5,
            -20, -40, 0, 40, 20,
            -30, -60, 0, 60, 30,
            -20, -40, 0, 40, 20,
            -5, -10, 0, 10, 5,
        },
    },
    {
        "sobel_y5",
        {
            -5, -20, -30, -20, -5,
            -10, -40, -60, -40, -10,
            0, 0, 0, 0, 0,
            10, 40, 60, 40, 10,
            5, 20, 30, 20, 5,
        },
    },
};

static double seconds_now(void) {
#ifdef _WIN32
    static LARGE_INTEGER freq;
    LARGE_INTEGER counter;
    if (freq.QuadPart == 0) {
        QueryPerformanceFrequency(&freq);
    }
    QueryPerformanceCounter(&counter);
    return (double)counter.QuadPart / (double)freq.QuadPart;
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
#endif
}

static uint32_t lcg_next(uint32_t *state) {
    *state = (*state * 1664525u) + 1013904223u;
    return *state;
}

static uint8_t sat_u8(int v) {
    if (v < 0) {
        return 0;
    }
    if (v > 255) {
        return 255;
    }
    return (uint8_t)v;
}

static void conv5x5_rgb_valid(
    const uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    const int coeff[25]
) {
    memset(dst, 0, (size_t)width * (size_t)height * 3u);

    for (int y = 4; y < height; ++y) {
        for (int x = 4; x < width; ++x) {
            int acc_r = 0;
            int acc_g = 0;
            int acc_b = 0;

            for (int ky = 0; ky < 5; ++ky) {
                const uint8_t *row = src + (((size_t)(y - 4 + ky) * (size_t)width + (size_t)(x - 4)) * 3u);
                const int *krow = coeff + ky * 5;
                for (int kx = 0; kx < 5; ++kx) {
                    int c = krow[kx];
                    const uint8_t *p = row + kx * 3;
                    acc_r += (int)p[0] * c;
                    acc_g += (int)p[1] * c;
                    acc_b += (int)p[2] * c;
                }
            }

            uint8_t *q = dst + (((size_t)y * (size_t)width + (size_t)x) * 3u);
            q[0] = sat_u8(acc_r >> 8);
            q[1] = sat_u8(acc_g >> 8);
            q[2] = sat_u8(acc_b >> 8);
        }
    }
}

static int cmp_double(const void *a, const void *b) {
    double da = *(const double *)a;
    double db = *(const double *)b;
    return (da > db) - (da < db);
}

static uint32_t checksum32(const uint8_t *buf, size_t n) {
    uint32_t s = 2166136261u;
    for (size_t i = 0; i < n; ++i) {
        s ^= buf[i];
        s *= 16777619u;
    }
    return s;
}

static void bench_one(int width, int height, int iterations, int warmup, const kernel_t *kernel) {
    size_t bytes = (size_t)width * (size_t)height * 3u;
    uint8_t *src = (uint8_t *)malloc(bytes);
    uint8_t *dst = (uint8_t *)malloc(bytes);
    double *times = (double *)malloc((size_t)iterations * sizeof(double));
    if (!src || !dst || !times) {
        fprintf(stderr, "allocation failed\n");
        exit(1);
    }

    uint32_t rng = 1234u;
    for (size_t i = 0; i < bytes; ++i) {
        src[i] = (uint8_t)(lcg_next(&rng) >> 24);
    }

    for (int i = 0; i < warmup; ++i) {
        conv5x5_rgb_valid(src, dst, width, height, kernel->coeff);
    }

    for (int i = 0; i < iterations; ++i) {
        double t0 = seconds_now();
        conv5x5_rgb_valid(src, dst, width, height, kernel->coeff);
        double t1 = seconds_now();
        times[i] = t1 - t0;
    }

    qsort(times, (size_t)iterations, sizeof(double), cmp_double);
    double median_s = times[iterations / 2];
    double mean_s = 0.0;
    for (int i = 0; i < iterations; ++i) {
        mean_s += times[i];
    }
    mean_s /= (double)iterations;

    size_t valid_pixels = (size_t)(width - 4) * (size_t)(height - 4);
    printf(
        "%dx%d RGB | %-10s | median=%8.3f ms | mean=%8.3f ms | fps=%8.1f | throughput=%8.1f Mpix/s | checksum=%08x\n",
        width,
        height,
        kernel->name,
        median_s * 1e3,
        mean_s * 1e3,
        1.0 / median_s,
        (double)valid_pixels / median_s / 1e6,
        checksum32(dst, bytes)
    );

    free(src);
    free(dst);
    free(times);
}

int main(int argc, char **argv) {
    int iterations = 20;
    int warmup = 5;
    if (argc > 1) {
        iterations = atoi(argv[1]);
    }
    if (argc > 2) {
        warmup = atoi(argv[2]);
    }

    printf("Naive C 5x5 RGB valid convolution, single thread, Q8 coefficients\n");
    printf("Iterations=%d, warmup=%d\n\n", iterations, warmup);

    const int sizes[][2] = {
        {640, 480},
        {1280, 720},
        {1920, 1080},
    };

    for (size_t k = 0; k < sizeof(kernels) / sizeof(kernels[0]); ++k) {
        for (size_t s = 0; s < sizeof(sizes) / sizeof(sizes[0]); ++s) {
            bench_one(sizes[s][0], sizes[s][1], iterations, warmup, &kernels[k]);
        }
    }

    return 0;
}
