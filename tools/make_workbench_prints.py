#!/usr/bin/env python3
"""Draws the pictures Kit's own table is made of, GAME.md 8.1c and STORY.md 3.10, into
assets/textures/:

    tools/make_workbench_prints.py

  kit_maple.png       oiled maple, grayscale around white for the room's maple to be multiplied
                      by: long fine grain along x with the odd darker streak, periodic both ways.
  kit_rule.png        the rule inlaid along the top of every wall on the Workbench: cream, eight
                      cells of the table's grid long, a tick every eighth of a cell, a longer one
                      every half and a number at every cell, so a wall measures the table it is on.
  kit_mark.png        Kit's mark, a K in a ring, as the burn it leaves: white where the wood is
                      untouched, so it is multiplied over the maple top of a box.
  kit_chalkboard.png  the slate on the board behind the bench: Kit's plan of table one in chalk,
                      drawn from Lucky Crossing's own grid, with the sums beside it.
  kit_calculator.png  the face of Kit's pocket calculator, switched on and reading 0.
"""

import pathlib
import re

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "textures"
FONTS = ROOT / "assets" / "fonts"
RNG = np.random.default_rng(20261019)

CREAM = (237, 227, 204)
INK = (43, 42, 48)
BURNT = (96, 76, 62)
RED = (181, 71, 58)
SLATE = (46, 54, 54)
CHALK = (232, 230, 220)


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


def noise(width, height, scale, stretch=1.0):
    """Periodic noise with features about `scale` pixels across, `stretch` times longer along x."""
    white = RNG.normal(size=(height, width))
    fy = np.fft.fftfreq(height)[:, None] / stretch
    fx = np.fft.fftfreq(width)[None, :] * stretch
    target = 1.0 / max(scale, 2.0)
    radius = np.sqrt(fx**2 + fy**2)
    band = np.exp(-((radius - target) ** 2) / (2.0 * (target * 0.7) ** 2))
    band[0, 0] = 0.0
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * band))
    out -= out.mean()
    peak = np.abs(out).max()
    return out / peak if peak > 0 else out


def grain(width, height):
    """Maple's grain as a field around 0: fine streaks along x over a few broader ones."""
    fine = noise(width, height, 5.0, stretch=14.0)
    broad = noise(width, height, 26.0, stretch=8.0)
    return fine * 0.6 + broad * 0.4


def maple():
    size = 512
    field = grain(size, size)
    values = np.clip(0.86 + field * 0.15, 0.0, 1.0)
    Image.fromarray((values * 255.0).astype(np.uint8), mode="L").save(OUT / "kit_maple.png")


def rule():
    cell = 400
    width, height = cell * 8, 128
    face = np.array(CREAM, np.float32)[None, None, :] * (
        0.96 + noise(width, height, 40.0, 3.0)[..., None] * 0.04
    )
    img = Image.fromarray(np.clip(face, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    edge = (138, 106, 68)
    d.rectangle((0, 0, width, 5), fill=edge)
    d.rectangle((0, height - 6, width, height), fill=edge)
    numbers = font("BarlowCondensed-ExtraBold.ttf", 64)
    for i in range(8 * 8):
        x = i * cell / 8
        if i % 8 == 0:
            d.rectangle((x - 4, 0, x + 4, 62), fill=INK)
            if i > 0:
                d.text((x + 14, 92), str(i // 8), font=numbers, fill=INK, anchor="lm")
        elif i % 4 == 0:
            d.rectangle((x - 3, 0, x + 3, 40), fill=INK)
        else:
            d.rectangle((x - 2, 0, x + 2, 22), fill=INK)
    # And the zero, where the first cell starts.
    d.text((14, 92), "0", font=numbers, fill=INK, anchor="lm")
    img.save(OUT / "kit_rule.png")


def mark():
    size = 256
    burn = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(burn)
    d.ellipse((30, 30, size - 30, size - 30), outline=255, width=14)
    d.text((size / 2, size / 2 + 6), "K", font=font("IMFellEnglish-Regular.ttf", 150), fill=255,
           anchor="mm")
    # Burnt in rather than printed: a soft scorch round a darker line.
    scorch = burn.filter(ImageFilter.GaussianBlur(5))
    line = burn.filter(ImageFilter.GaussianBlur(1.2))
    s = np.asarray(scorch).astype(np.float32)[..., None] / 255.0
    ln = np.asarray(line).astype(np.float32)[..., None] / 255.0
    rgb = np.full((size, size, 3), 255.0, np.float32) * (1.0 - s * 0.3)
    rgb = rgb * (1.0 - ln) + np.array(BURNT, np.float32) * ln
    Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").save(OUT / "kit_mark.png")


def lucky_crossing():
    text = (ROOT / "data" / "maps" / "lucky_crossing.tres").read_text()
    grid = re.search(r'grid = "([^"]*)"', text).group(1)
    return grid.split("\n")


def chalk_line(d, points, width=5):
    d.line(points, fill=255, width=width, joint="curve")


def chalkboard():
    width, height = 1536, 768
    face = np.array(SLATE, np.float32)[None, None, :] * (
        0.92 + noise(width, height, 90.0)[..., None] * 0.1
    )
    board = Image.fromarray(np.clip(face, 0, 255).astype(np.uint8), "RGB")
    ink = Image.new("L", (width, height), 0)
    d = ImageDraw.Draw(ink)
    hand = font("Kalam-Regular.ttf", 64)
    small = font("Kalam-Regular.ttf", 40)
    d.text((70, 60), "TABLE No. 1", font=hand, fill=255)
    # Kit's plan of the table, from its own grid: the walls in outline, the Junction a ring.
    rows = lucky_crossing()
    cell = 26
    ox, oy = 90, 190
    for y, row in enumerate(rows):
        for x, glyph in enumerate(row):
            px, py = ox + x * cell, oy + y * cell
            if glyph == "#":
                d.rectangle((px, py, px + cell, py + cell), fill=150)
            elif glyph == "X":
                d.line((px + 4, py + 4, px + cell - 4, py + cell - 4), fill=200, width=3)
                d.line((px + 4, py + cell - 4, px + cell - 4, py + 4), fill=200, width=3)
            elif glyph == "C":
                d.ellipse((px + 8, py + 8, px + cell - 8, py + cell - 8), outline=210, width=3)
    middle = (ox + 16 * cell, oy + 9 * cell)
    d.ellipse((middle[0] - 52, middle[1] - 52, middle[0] + 52, middle[1] + 52), outline=255,
              width=5)
    d.ellipse((middle[0] - 10, middle[1] - 10, middle[0] + 10, middle[1] + 10), fill=230)
    # The dimension line under it, the way a maker marks a drawing.
    base = oy + len(rows) * cell + 30
    chalk_line(d, [(ox, base), (ox + 32 * cell, base)], 4)
    for end, turn in ((ox, 1), (ox + 32 * cell, -1)):
        chalk_line(d, [(end + turn * 18, base - 12), (end, base), (end + turn * 18, base + 12)], 4)
    d.text((ox + 16 * cell, base + 34), "40 m", font=small, fill=255, anchor="mm")
    # The sums, on the right.
    count = "".join(rows).count
    sums = [
        "pot x mult = bank",
        "pits: %d" % (count("X") // 4),
        "pads: %d" % count("C"),
        "jackpots: %d" % (count("K") // 4),
        "",
        "check the wheel!",
    ]
    for i, line in enumerate(sums):
        d.text((1010, 210 + i * 66), line, font=small, fill=235)
    chalk_line(d, [(1000, 300 + 66 * 3), (1420, 300 + 66 * 3)], 3)
    d.text((1380, 680), "K.", font=hand, fill=255, anchor="mm")
    # Chalk is never solid: broken up by the slate's tooth and a little smudged.
    tooth = (noise(width, height, 2.5) > -0.35).astype(np.float32)
    lines = np.asarray(ink.filter(ImageFilter.GaussianBlur(0.8))).astype(np.float32) / 255.0
    smudge = np.asarray(ink.filter(ImageFilter.GaussianBlur(9))).astype(np.float32) / 255.0
    cover = np.clip(lines * (0.55 + 0.45 * tooth) * 0.92 + smudge * 0.12, 0.0, 1.0)[..., None]
    rgb = np.asarray(board).astype(np.float32)
    rgb = rgb * (1.0 - cover) + np.array(CHALK, np.float32) * cover
    Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").save(OUT / "kit_chalkboard.png")


def calculator():
    width, height = 512, 768
    img = Image.new("RGB", (width, height), (214, 205, 182))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((32, 36, width - 32, 220), 22, fill=(46, 44, 46))
    d.rounded_rectangle((60, 66, width - 60, 190), 8, fill=(150, 168, 136))
    digits = font("BarlowCondensed-ExtraBold.ttf", 104)
    d.text((width - 84, 130), "0.", font=digits, fill=(36, 44, 34), anchor="rm")
    keys = font("BarlowCondensed-ExtraBold.ttf", 46)
    labels = ["7", "8", "9", "/", "4", "5", "6", "x", "1", "2", "3", "-", "0", ".", "=", "+"]
    for i, label in enumerate(labels):
        col, row = i % 4, i // 4
        x0 = 52 + col * 106
        y0 = 268 + row * 116
        red = col == 3 or label == "="
        d.rounded_rectangle((x0, y0, x0 + 86, y0 + 90), 14, fill=RED if red else (58, 56, 62))
        d.text((x0 + 43, y0 + 45), label, font=keys, fill=CREAM, anchor="mm")
    img.save(OUT / "kit_calculator.png")


if __name__ == "__main__":
    maple()
    rule()
    mark()
    chalkboard()
    calculator()
    print("prints in", OUT)
