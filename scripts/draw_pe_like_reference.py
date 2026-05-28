from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT = Path("docs/pe_source_style.png")
W, H = 1500, 1050


def get_font(size: int, bold: bool = False, italic: bool = False) -> ImageFont.FreeTypeFont:
    if bold:
        names = ["arialbd.ttf", "calibrib.ttf"]
    elif italic:
        names = ["ariali.ttf", "calibrii.ttf"]
    else:
        names = ["arial.ttf", "calibri.ttf"]
    for name in names:
        try:
            return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
        except OSError:
            pass
    return ImageFont.load_default()


F_TITLE = get_font(46, True)
F_BLOCK = get_font(36, True)
F_TEXT = get_font(28)
F_SMALL = get_font(22)
F_ITALIC = get_font(24, italic=True)
F_TINY = get_font(18)

img = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(img)


def text(x, y, s, font=F_TEXT, anchor="mm", fill="black"):
    d.text((x, y), s, font=font, anchor=anchor, fill=fill)


def rect(x1, y1, x2, y2, width=5):
    d.rectangle((x1, y1, x2, y2), outline="black", width=width)


def line(points, width=5, arrow=False, dashed=False):
    if dashed:
        for i in range(len(points) - 1):
            x1, y1 = points[i]
            x2, y2 = points[i + 1]
            dx, dy = x2 - x1, y2 - y1
            length = max((dx * dx + dy * dy) ** 0.5, 1)
            ux, uy = dx / length, dy / length
            pos = 0
            while pos < length:
                end = min(pos + 18, length)
                d.line((x1 + ux * pos, y1 + uy * pos, x1 + ux * end, y1 + uy * end), fill="black", width=width)
                pos += 32
    else:
        d.line(points, fill="black", width=width, joint="curve")
    if arrow:
        x1, y1 = points[-2]
        x2, y2 = points[-1]
        if abs(x2 - x1) >= abs(y2 - y1):
            sign = 1 if x2 >= x1 else -1
            poly = [(x2, y2), (x2 - sign * 28, y2 - 15), (x2 - sign * 28, y2 + 15)]
        else:
            sign = 1 if y2 >= y1 else -1
            poly = [(x2, y2), (x2 - 15, y2 - sign * 28), (x2 + 15, y2 - sign * 28)]
        d.polygon(poly, fill="black")


def dot(x, y, r=11):
    d.ellipse((x - r, y - r, x + r, y + r), fill="black")


def bus_slash(x, y, angle="/", size=26, width=4):
    if angle == "/":
        d.line((x - size // 2, y + size // 2, x + size // 2, y - size // 2), fill="black", width=width)
    else:
        d.line((x - size // 2, y - size // 2, x + size // 2, y + size // 2), fill="black", width=width)


def block(x1, y1, x2, y2, label, font=F_BLOCK):
    rect(x1, y1, x2, y2)
    text((x1 + x2) // 2, (y1 + y2) // 2, label, font=font)


# Title
text(70, 45, "PE[i] in mac_array_25x3.sv", F_TITLE, anchor="lm")
text(70, 88, "Conceptual processing element for one 5x5 tap: RGB pixel[i] x coeff[i]", F_SMALL, anchor="lm")

# Outer PE frame
rect(70, 125, 1430, 900, width=6)
text(1295, 795, "PE", get_font(84, True), anchor="mm")

# Top source bus
line([(120, 185), (1380, 185)], width=5)
line([(120, 185), (120, 270)], width=5, arrow=True)
text(150, 228, "From", F_ITALIC, anchor="lm")
text(150, 258, "window_flat", F_ITALIC, anchor="lm")

line([(710, 125), (710, 185)], width=5, arrow=True)
dot(710, 185)
text(735, 145, "valid_in", F_ITALIC, anchor="lm")

# Input extraction and coefficient blocks
block(120, 295, 305, 435, "PIXEL[i]", F_BLOCK)
text(212, 460, "24-bit RGB", F_SMALL)

for x, label in [(460, "R"), (640, "G"), (820, "B")]:
    block(x, 295, x + 145, 435, label, F_BLOCK)
    line([(212, 435), (212, 505), (x + 72, 505), (x + 72, 435)], width=5, arrow=True)
    dot(x + 72, 505)

block(1030, 295, 1215, 435, "K(i)", F_BLOCK)
text(1122, 460, "signed coeff", F_SMALL)
line([(1122, 185), (1122, 295)], width=5, arrow=True)
dot(1122, 185)

# Shared pixel/coefficient buses
line([(212, 505), (1215, 505)], width=5)
line([(1122, 435), (1122, 615)], width=5)
dot(1122, 505)

# Multipliers
for x, label in [(430, "MUL_R"), (645, "MUL_G"), (860, "MUL_B")]:
    block(x, 600, x + 160, 720, label, get_font(28, True))
    line([(x + 80, 505), (x + 80, 600)], width=5, arrow=True)
    line([(1122, 615), (x + 160, 660)], width=5, arrow=True)
    bus_slash(x + 80, 566)
    text(x + 80, 748, "32-bit product", F_TINY)

# Valid/control path
line([(710, 185), (710, 555), (1260, 555), (1260, 650)], width=4, arrow=True)
bus_slash(710, 350, "\\")
text(1225, 585, "Ctrl", F_ITALIC, anchor="mm")

# Stage 1 registers
block(1110, 635, 1335, 790, "STAGE 1\nREG", get_font(30, True))
text(1222, 815, "mul_r_q / mul_g_q / mul_b_q", F_TINY)

for x in [510, 725, 940]:
    line([(x, 720), (x, 840), (1222, 840), (1222, 790)], width=5, arrow=True)
dot(1222, 840)
bus_slash(1040, 840)

# Output to tree
line([(1222, 790), (1222, 940)], width=5, arrow=True)
text(1245, 935, "To Stage-2 adder tree", F_ITALIC, anchor="lm")
bus_slash(1222, 883)

# Source code equations inside frame
rect(115, 735, 395, 860, width=4)
text(255, 765, "Source equations", get_font(22, True))
text(255, 797, "mul_r[i] = R * K(i)", F_TINY)
text(255, 823, "mul_g[i] = G * K(i)", F_TINY)
text(255, 849, "mul_b[i] = B * K(i)", F_TINY)

# Small reduction-tree context outside PE
text(90, 955, "After 25 PE blocks:", F_SMALL, anchor="lm")
block(360, 920, 520, 1000, "S2\n8 sums", get_font(22, True))
block(610, 920, 770, 1000, "S3\n4 sums", get_font(22, True))
block(860, 920, 1020, 1000, "S4\nLo/Hi", get_font(22, True))
block(1110, 920, 1270, 1000, "S5/S6\nQ8 + SAT", get_font(20, True))
line([(250, 960), (360, 960)], width=5, arrow=True)
line([(520, 960), (610, 960)], width=5, arrow=True)
line([(770, 960), (860, 960)], width=5, arrow=True)
line([(1020, 960), (1110, 960)], width=5, arrow=True)

text(70, 1030, "Matches source lines: window/coeff extraction and multiplies in mac_array_25x3.sv lines 111-121; product registers lines 127-144.", F_TINY, anchor="lm")

OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT)
print(OUT)
