from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT = Path("docs/pe_circuit_datapath.png")
W, H = 1800, 1100


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/calibrib.ttf" if bold else "C:/Windows/Fonts/calibri.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


F_TITLE = font(42, True)
F_HEAD = font(28, True)
F = font(22)
F_SMALL = font(18)
F_TINY = font(15)

BG = (248, 250, 252)
INK = (17, 24, 39)
MUTED = (75, 85, 99)
BLUE = (37, 99, 235)
CYAN = (8, 145, 178)
ORANGE = (234, 88, 12)
GREEN = (22, 163, 74)
PINK = (190, 24, 93)
VIOLET = (109, 40, 217)
YELLOW = (202, 138, 4)
RED = (220, 38, 38)
BOX = (255, 255, 255)


img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)


def text(x: int, y: int, s: str, fill=INK, f=F, anchor=None) -> None:
    d.text((x, y), s, fill=fill, font=f, anchor=anchor)


def line(points, fill=INK, width=4, arrow=False) -> None:
    d.line(points, fill=fill, width=width, joint="curve")
    if arrow:
        x1, y1 = points[-2]
        x2, y2 = points[-1]
        # Simple arrow head, enough for mostly horizontal/vertical routes.
        if abs(x2 - x1) >= abs(y2 - y1):
            sign = 1 if x2 >= x1 else -1
            poly = [(x2, y2), (x2 - sign * 18, y2 - 9), (x2 - sign * 18, y2 + 9)]
        else:
            sign = 1 if y2 >= y1 else -1
            poly = [(x2, y2), (x2 - 9, y2 - sign * 18), (x2 + 9, y2 - sign * 18)]
        d.polygon(poly, fill=fill)


def rect(x1, y1, x2, y2, outline=INK, fill=BOX, width=4, radius=18) -> None:
    d.rounded_rectangle((x1, y1, x2, y2), radius=radius, fill=fill, outline=outline, width=width)


def circle(cx, cy, r, outline=INK, fill=BOX, width=4) -> None:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=outline, width=width)


def dff(x, y, w=140, h=86, label="DFF", color=CYAN) -> None:
    rect(x, y, x + w, y + h, outline=color, fill=(236, 254, 255), radius=12)
    text(x + w // 2, y + 18, label, color, F, "ma")
    text(x + 24, y + h // 2 + 12, "D", INK, F_SMALL, "mm")
    text(x + w - 24, y + h // 2 + 12, "Q", INK, F_SMALL, "mm")
    tri = [(x + 8, y + h - 24), (x + 8, y + h - 8), (x + 22, y + h - 16)]
    d.polygon(tri, outline=color, fill=(236, 254, 255))
    d.line((tri[0], tri[1], tri[2], tri[0]), fill=color, width=3)
    text(x + 52, y + h - 18, "clk", MUTED, F_TINY, "mm")


def multiplier(cx, cy, r=46, label="x") -> None:
    circle(cx, cy, r, outline=ORANGE, fill=(255, 247, 237))
    text(cx, cy - 3, label, ORANGE, font(38, True), "mm")


def adder(cx, cy, r=42) -> None:
    circle(cx, cy, r, outline=GREEN, fill=(240, 253, 244))
    line([(cx - 20, cy), (cx + 20, cy)], fill=GREEN, width=5)
    line([(cx, cy - 20), (cx, cy + 20)], fill=GREEN, width=5)


def bus_label(x, y, s, color=BLUE) -> None:
    rect(x, y, x + 220, y + 54, outline=color, fill=(239, 246, 255), radius=12)
    text(x + 110, y + 27, s, color, F, "mm")


text(60, 42, "PE and Reduction Tree in the RGB 5x5 Convolution Core", INK, F_TITLE)
text(
    62,
    96,
    "Derived from src/mac_array_25x3.sv: one implied PE per tap, 25 taps total, 3 color channels in parallel.",
    MUTED,
    F_SMALL,
)

# Single PE area
rect(55, 145, 930, 620, outline=(148, 163, 184), fill=(255, 255, 255), radius=24)
text(88, 178, "One implied PE: tap i", INK, F_HEAD)
text(88, 214, "window_flat[i] supplies one RGB pixel; kernel_flat[i] supplies one signed coefficient.", MUTED, F_SMALL)

bus_label(100, 290, "RGB pixel[i]", BLUE)
bus_label(100, 420, "coeff[i]", VIOLET)
text(125, 355, "R[7:0]  G[7:0]  B[7:0]", MUTED, F_TINY)
text(143, 484, "signed 16-bit Q8", MUTED, F_TINY)

for y, lab, col in [(270, "R", RED), (350, "G", GREEN), (430, "B", BLUE)]:
    line([(320, 318), (370, 318), (370, y), (470, y)], fill=col, width=4, arrow=True)
    text(388, y - 22, lab, col, F_SMALL)

line([(320, 448), (400, 448), (400, 500), (470, 500)], fill=VIOLET, width=4, arrow=True)
line([(400, 448), (400, 350), (470, 350)], fill=VIOLET, width=4, arrow=True)
line([(400, 448), (400, 270), (470, 270)], fill=VIOLET, width=4, arrow=True)
text(410, 462, "fanout", VIOLET, F_TINY)

for y in [270, 350, 430]:
    multiplier(535, y, 42)

line([(577, 270), (675, 270)], fill=RED, width=4, arrow=True)
line([(577, 350), (675, 350)], fill=GREEN, width=4, arrow=True)
line([(577, 430), (675, 430)], fill=BLUE, width=4, arrow=True)

dff(690, 232, label="mul_r_q", color=RED)
dff(690, 312, label="mul_g_q", color=GREEN)
dff(690, 392, label="mul_b_q", color=BLUE)

text(474, 535, "Three 8x16 multipliers per PE", ORANGE, F_SMALL)
text(690, 535, "Stage 1 registers", CYAN, F_SMALL)

# 25-PE array and tree
rect(970, 145, 1745, 620, outline=(148, 163, 184), fill=(255, 255, 255), radius=24)
text(1005, 178, "25 PE array -> pipelined adder tree", INK, F_HEAD)
text(1005, 214, "Each PE emits R/G/B products. The same reduction tree is replicated for R, G and B.", MUTED, F_SMALL)

pe_positions = [(1035, 300), (1125, 300), (1215, 300), (1305, 300), (1395, 300),
                (1035, 390), (1125, 390), (1215, 390), (1305, 390), (1395, 390)]
for idx, (x, y) in enumerate(pe_positions):
    rect(x - 34, y - 28, x + 34, y + 28, outline=ORANGE, fill=(255, 247, 237), radius=10)
    label = f"PE{idx}" if idx < 4 else ("..." if idx == 4 else f"PE{idx+15}")
    text(x, y, label, ORANGE, F_TINY, "mm")

text(1190, 475, "25 total", MUTED, F_SMALL, "mm")

adder(1515, 310, 38)
text(1515, 250, "Stage 2", GREEN, F_SMALL, "mm")
text(1515, 365, "8 sub-groups", MUTED, F_TINY, "mm")
adder(1640, 310, 38)
text(1640, 250, "Stage 3", GREEN, F_SMALL, "mm")
text(1640, 365, "4 groups", MUTED, F_TINY, "mm")

for x, y in pe_positions[:5]:
    line([(x + 34, y), (1477, 310)], fill=(107, 114, 128), width=2, arrow=True)
line([(1553, 310), (1602, 310)], fill=INK, width=4, arrow=True)

# Pipeline bottom
rect(95, 700, 1680, 1000, outline=(148, 163, 184), fill=(255, 255, 255), radius=24)
text(125, 735, "Full datapath timing view", INK, F_HEAD)

stages = [
    (125, 810, 230, 900, "Stage 0", "25 PE\nmultiply", ORANGE),
    (305, 810, 430, 900, "Stage 1", "product\nregisters", CYAN),
    (505, 810, 630, 900, "Stage 2", "8 partial\nsums", GREEN),
    (705, 810, 830, 900, "Stage 3", "4 group\nsums", GREEN),
    (905, 810, 1030, 900, "Stage 4", "Lo / Hi\nmerge", GREEN),
    (1105, 810, 1230, 900, "Stage 5", "final sum\n>>> Q8", YELLOW),
    (1305, 810, 1430, 900, "Stage 6", "saturate\npack RGB", PINK),
]

for x1, y1, x2, y2, head, body, col in stages:
    rect(x1, y1, x2, y2, outline=col, fill=(255, 255, 255), radius=12)
    text((x1 + x2) // 2, y1 + 22, head, col, F_SMALL, "mm")
    for j, part in enumerate(body.split("\n")):
        text((x1 + x2) // 2, y1 + 52 + j * 22, part, INK, F_TINY, "mm")

for i in range(len(stages) - 1):
    x2 = stages[i][2]
    y = (stages[i][1] + stages[i][3]) // 2
    x_next = stages[i + 1][0]
    line([(x2, y), (x_next, y)], fill=INK, width=4, arrow=True)

text(1460, 840, "pixel_out", INK, F)
text(1460, 870, "{b8, g8, r8}", MUTED, F_SMALL)
line([(1430, 855), (1450, 855)], fill=INK, width=4, arrow=True)

text(125, 955, "Note: RTL packs pixel_out as {b8_c, g8_c, r8_c}. Test utilities write/read HEX as RGB RRGGBB for images.", MUTED, F_TINY)
text(125, 982, "PE is conceptual: the source implements PE behavior inside for-loops, not as a separate SystemVerilog module.", MUTED, F_TINY)

OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT)
print(OUT)
