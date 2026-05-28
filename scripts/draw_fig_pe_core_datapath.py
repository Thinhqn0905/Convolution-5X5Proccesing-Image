from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import Circle, FancyArrowPatch, Rectangle


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "paper" / "figures"
OUT_DIR.mkdir(parents=True, exist_ok=True)

W, H = 1900, 900

COLORS = {
    "pixel": "#e0f2fe",
    "coeff": "#fef9c3",
    "mul": "#ffedd5",
    "reg": "#f1f5f9",
    "array": "#dcfce7",
    "wire": "#111827",
    "control": "#6b7280",
    "border": "#111827",
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
    fig, ax = plt.subplots(figsize=(13.8, 6.4), dpi=180)
    ax.set_xlim(0, W)
    ax.set_ylim(H, 0)
    ax.axis("off")
    return fig, ax


def block(ax, x, y, w, h, label, fill, fs=11, lw=1.5):
    ax.add_patch(Rectangle((x, y), w, h, facecolor=fill, edgecolor=COLORS["border"], linewidth=lw))
    ax.text(x + w / 2, y + h / 2, label, ha="center", va="center", fontsize=fs, linespacing=1.25)


def label(ax, x, y, s, fs=10, color="#111827", ha="center"):
    ax.text(x, y, s, ha=ha, va="center", fontsize=fs, color=color, linespacing=1.2)


def arrow(ax, pts, text=None, text_xy=None, color=None, lw=1.7, dashed=False, fs=9):
    color = color or COLORS["wire"]
    style = (0, (5, 4)) if dashed else "solid"
    for a, b in zip(pts[:-2], pts[1:-1]):
        ax.plot([a[0], b[0]], [a[1], b[1]], color=color, linewidth=lw, linestyle=style)
    ax.add_patch(
        FancyArrowPatch(
            pts[-2],
            pts[-1],
            arrowstyle="-|>",
            mutation_scale=11,
            linewidth=lw,
            linestyle=style,
            color=color,
            shrinkA=0,
            shrinkB=0,
        )
    )
    if text and text_xy:
        label(ax, text_xy[0], text_xy[1], text, fs=fs, color=color)


def line(ax, pts, color=None, lw=1.7, dashed=False):
    color = color or COLORS["wire"]
    style = (0, (5, 4)) if dashed else "solid"
    for a, b in zip(pts[:-1], pts[1:]):
        ax.plot([a[0], b[0]], [a[1], b[1]], color=color, linewidth=lw, linestyle=style)


def dot(ax, x, y, color=None):
    ax.add_patch(Circle((x, y), 4.5, color=color or COLORS["wire"]))


def draw():
    fig, ax = setup()

    label(ax, 70, 45, "PE[i] datapath in mac_array_25x3.sv", fs=15, ha="left")
    label(ax, 70, 68, "One tap: RGB pixel x signed Q8.8 coefficient", fs=10, ha="left")

    ax.add_patch(Rectangle((55, 95), 1350, 675, fill=False, edgecolor=COLORS["border"], linewidth=2.0))
    label(ax, 72, 115, "Processing Element PE[i]", fs=12, ha="left")

    # PE-local blocks.
    block(ax, 125, 330, 180, 78, "Extract\npixel_i[23:0]", COLORS["pixel"], fs=9.5)
    block(ax, 390, 330, 170, 78, "RGB\nSplitter", COLORS["pixel"], fs=10.5)
    block(ax, 650, 220, 115, 62, "R_i\n[7:0]", COLORS["pixel"], fs=9.5)
    block(ax, 650, 330, 115, 62, "G_i\n[7:0]", COLORS["pixel"], fs=9.5)
    block(ax, 650, 440, 115, 62, "B_i\n[7:0]", COLORS["pixel"], fs=9.5)
    block(ax, 390, 170, 205, 85, "Extract coeff_i\nsigned Q8.8\n[15:0]", COLORS["coeff"], fs=9.0)

    block(ax, 860, 215, 165, 72, "MUL_R\nR_i x coeff_i", COLORS["mul"], fs=9.5)
    block(ax, 860, 330, 165, 72, "MUL_G\nG_i x coeff_i", COLORS["mul"], fs=9.5)
    block(ax, 860, 445, 165, 72, "MUL_B\nB_i x coeff_i", COLORS["mul"], fs=9.5)
    block(ax, 1175, 325, 200, 188, "Stage-1 Product\nRegisters\n\nmul_r_q\nmul_g_q\nmul_b_q", COLORS["reg"], fs=9.3)
    block(ax, 390, 650, 230, 75, "valid pipeline\n6-stage delay", COLORS["reg"], fs=10)

    # Source equations box.
    block(ax, 120, 540, 210, 100, "Source equations\nmul_r = R_i x K_i\nmul_g = G_i x K_i\nmul_b = B_i x K_i", "#ffffff", fs=8.8)

    # Datapath input.
    arrow(ax, [(30, 369), (125, 369)], "window_flat[599:0]", (88, 336), fs=8.7)
    arrow(ax, [(305, 369), (390, 369)], "pixel_i", (348, 348), fs=8.7)
    arrow(ax, [(560, 369), (610, 369), (610, 251), (650, 251)], "R", (622, 235), fs=8.7)
    arrow(ax, [(560, 369), (650, 369)], "G", (605, 351), fs=8.7)
    arrow(ax, [(560, 369), (610, 369), (610, 471), (650, 471)], "B", (622, 489), fs=8.7)

    # RGB to multipliers.
    arrow(ax, [(765, 251), (860, 251)], fs=8.7)
    label(ax, 812, 233, "R_i", fs=8.7)
    arrow(ax, [(765, 361), (860, 361)], fs=8.7)
    label(ax, 812, 343, "G_i", fs=8.7)
    arrow(ax, [(765, 471), (860, 471)], fs=8.7)
    label(ax, 812, 489, "B_i", fs=8.7)

    # Coefficient bus and fanout.
    arrow(ax, [(260, 212), (390, 212)], fs=8.7)
    label(ax, 250, 190, "kernel_flat[399:0]", fs=8.7, ha="right")
    line(ax, [(595, 212), (820, 212), (820, 471)], color="#854d0e", lw=1.7)
    dot(ax, 820, 251, "#854d0e")
    dot(ax, 820, 361, "#854d0e")
    dot(ax, 820, 471, "#854d0e")
    arrow(ax, [(820, 251), (860, 251)], color="#854d0e")
    arrow(ax, [(820, 361), (860, 361)], color="#854d0e")
    arrow(ax, [(820, 471), (860, 471)], "shared coeff_i", (760, 172), color="#854d0e", fs=8.8)

    # Products to stage-1 registers.
    arrow(ax, [(1025, 251), (1095, 251), (1095, 358), (1175, 358)], fs=8.5)
    label(ax, 1110, 228, "prod_r[31:0]", fs=7.6)
    arrow(ax, [(1025, 366), (1175, 366)], fs=8.5)
    label(ax, 1085, 326, "prod_g[31:0]", fs=7.6)
    arrow(ax, [(1025, 481), (1095, 481), (1095, 480), (1175, 480)], fs=8.5)
    label(ax, 1110, 506, "prod_b[31:0]", fs=7.6)

    # Valid/control path.
    arrow(ax, [(30, 688), (390, 688)], "valid_in", (150, 666), color=COLORS["control"], dashed=True, fs=8.8)
    arrow(ax, [(620, 688), (1390, 688)], "valid_out", (700, 666), color=COLORS["control"], dashed=True, fs=8.8)

    # Output to array-level reduction.
    arrow(ax, [(1375, 419), (1490, 419)], fs=8.7)
    label(ax, 1440, 381, "to 25-tap tree", fs=7.2)

    # Outside array-level preview.
    ax.add_patch(Rectangle((1510, 200), 360, 420, fill=False, edgecolor=COLORS["border"], linewidth=1.6))
    label(ax, 1530, 226, "Outside one PE", fs=11, ha="left")
    label(ax, 1530, 249, "after 25 PE outputs per channel", fs=8.5, ha="left")
    stages = [
        ("S2\n8 sums", 1538, 295),
        ("S3\n4 sums", 1695, 295),
        ("S4\nLo/Hi", 1538, 435),
        ("S5\nacc[47:0]\n>> 8", 1695, 435),
        ("S6\nSAT\n[0,255]", 1615, 540),
    ]
    for lab, x, y in stages:
        block(ax, x, y, 110, 70, lab, COLORS["array"], fs=9)
    arrow(ax, [(1648, 330), (1695, 330)])
    arrow(ax, [(1750, 365), (1750, 435)])
    arrow(ax, [(1695, 470), (1648, 470)])
    arrow(ax, [(1593, 505), (1593, 540)])

    label(ax, 70, 815, "Source check: pixel/coeff extraction and products match mac_array_25x3.sv lines 112-127; product registers lines 127-144.", fs=8.5, ha="left")

    for ext in ("svg", "pdf", "png"):
        fig.savefig(OUT_DIR / f"fig_pe_core_datapath.{ext}", bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)


if __name__ == "__main__":
    draw()
    for ext in ("svg", "pdf", "png"):
        p = OUT_DIR / f"fig_pe_core_datapath.{ext}"
        print(p, p.stat().st_size)
