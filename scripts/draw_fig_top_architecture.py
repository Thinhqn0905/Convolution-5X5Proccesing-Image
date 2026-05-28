from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import Circle, FancyArrowPatch, Rectangle


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "paper" / "figures"
OUT_DIR.mkdir(parents=True, exist_ok=True)

W, H = 1900, 760

COLORS = {
    "input": "#eef2ff",
    "line": "#e8f4f2",
    "window": "#e0f2fe",
    "mac": "#f8fafc",
    "kernel": "#ecfdf5",
    "control": "#fff7ed",
    "border": "#111827",
    "wire": "#111827",
    "control_wire": "#7c2d12",
}


def setup():
    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 12,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "svg.fonttype": "none",
        }
    )
    fig, ax = plt.subplots(figsize=(13.8, 5.5), dpi=180)
    ax.set_xlim(0, W)
    ax.set_ylim(H, 0)
    ax.axis("off")
    return fig, ax


def block(ax, x, y, w, h, text, fill, fs=12, lw=1.6):
    ax.add_patch(Rectangle((x, y), w, h, facecolor=fill, edgecolor=COLORS["border"], linewidth=lw))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fs, linespacing=1.25)


def text(ax, x, y, s, fs=11, color="#111827", ha="center"):
    ax.text(x, y, s, ha=ha, va="center", fontsize=fs, color=color, linespacing=1.2)


def ortho_arrow(ax, pts, label=None, label_pos=0.5, color=None, lw=1.8, dashed=False, fs=10):
    color = color or COLORS["wire"]
    style = (0, (5, 4)) if dashed else "solid"
    for a, b in zip(pts[:-2], pts[1:-1]):
        ax.plot([a[0], b[0]], [a[1], b[1]], color=color, linewidth=lw, linestyle=style)
    start, end = pts[-2], pts[-1]
    ax.add_patch(
        FancyArrowPatch(
            start,
            end,
            arrowstyle="-|>",
            mutation_scale=12,
            linewidth=lw,
            linestyle=style,
            color=color,
            shrinkA=0,
            shrinkB=0,
        )
    )
    if label:
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        lx = xs[0] + (xs[-1] - xs[0]) * label_pos
        ly = ys[0] + (ys[-1] - ys[0]) * label_pos
        text(ax, lx, ly - 12, label, fs=fs, color=color)


def draw():
    fig, ax = setup()

    ax.add_patch(Rectangle((70, 70), 1760, 560, fill=False, edgecolor=COLORS["border"], linewidth=2.0))
    text(ax, 94, 100, "Runtime-configurable RGB 5x5 streaming convolution core", fs=14, ha="left")

    block(ax, 120, 250, 165, 120, "AXI4-Stream\nInput\n24-bit RGB", COLORS["input"], fs=10.5)
    block(ax, 390, 225, 230, 170, "Line Buffer\n4-line BRAM\nshift registers", COLORS["line"], fs=11)
    block(ax, 730, 225, 230, 170, "Window\nGenerator\n5x5 window", COLORS["window"], fs=11)
    ax.add_patch(Rectangle((1090, 160), 330, 285, facecolor=COLORS["mac"], edgecolor=COLORS["border"], linewidth=1.6))
    text(ax, 1255, 205, "MAC Array 25x3", fs=12)
    block(ax, 1600, 250, 175, 120, "AXI4-Stream\nOutput\nfiltered RGB", COLORS["input"], fs=10.5)

    # MAC internal stages.
    block(ax, 1125, 245, 260, 56, "S1 Mul  |  S2 Sum  |  S3 Merge", "#f1f5f9", fs=8.1, lw=1.0)
    block(ax, 1125, 325, 260, 56, "S4 Lo/Hi  |  S5 >> 8  |  S6 SAT", "#f1f5f9", fs=8.1, lw=1.0)
    text(ax, 1255, 405, "25 taps x 3 RGB channels", fs=8.3)
    text(ax, 1255, 426, "48-bit accumulation", fs=8.3)

    block(ax, 390, 485, 230, 92, "Kernel Loader\n25 x 16-bit coeff", COLORS["kernel"], fs=10.5)
    block(ax, 730, 480, 300, 100, "AXI4-Lite Kernel Ctrl\nADDR DATA COMMIT STATUS", COLORS["control"], fs=9.0)

    # Main datapath.
    ortho_arrow(ax, [(285, 310), (390, 310)], fs=9)
    text(ax, 337, 286, "in_pixel", fs=8.5)
    ortho_arrow(ax, [(620, 310), (730, 310)], fs=9)
    text(ax, 675, 286, "row taps", fs=8.5)
    ortho_arrow(ax, [(960, 310), (1090, 310)], fs=9)
    text(ax, 1035, 266, "window_flat\n[599:0]", fs=7.3)
    ortho_arrow(ax, [(1420, 310), (1600, 310)], fs=9)
    text(ax, 1510, 286, "out_pixel", fs=8.5)

    # Kernel/control path.
    ortho_arrow(ax, [(1030, 530), (1110, 530), (1110, 420)], color=COLORS["control_wire"], fs=9)
    text(ax, 1128, 472, "kernel_flat[399:0]", fs=8.5, color=COLORS["control_wire"], ha="left")
    ortho_arrow(ax, [(620, 530), (730, 530)], color=COLORS["control_wire"], fs=9)
    text(ax, 675, 508, "kernel write", fs=8.5, color=COLORS["control_wire"])
    ortho_arrow(ax, [(505, 485), (505, 395)], color=COLORS["control_wire"], fs=9)
    text(ax, 530, 438, "kernel coeffs", fs=8.5, color=COLORS["control_wire"], ha="left")

    # Valid/ready note and throughput note.
    text(ax, 120, 430, "valid / ready", fs=8.5, ha="left")
    text(ax, 120, 455, "1 pixel/clock after line-buffer warm-up", fs=9, ha="left")
    text(ax, 120, 480, "Full-HD active-frame capable at 146 MHz", fs=9, ha="left")

    # Fanout marker.
    ax.add_patch(Circle((1110, 420), 4.5, color=COLORS["control_wire"]))

    for ext in ("svg", "pdf", "png"):
        fig.savefig(OUT_DIR / f"fig_top_architecture.{ext}", bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)


if __name__ == "__main__":
    draw()
    for ext in ("svg", "pdf", "png"):
        p = OUT_DIR / f"fig_top_architecture.{ext}"
        print(p, p.stat().st_size)
