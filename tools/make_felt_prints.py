#!/usr/bin/env python3
"""Draws the Sewing Table's felt, GAME.md 8.1c, into assets/textures/:

    tools/make_felt_prints.py

  stitch_bolster.png  the top of a stuffed bolster, one cell (1.25 m) square: oatmeal felt with a
                      plum top-stitch round it 0.3 m in from each seam, laid on in the
                      world's meters so it meets the pinches between the sections of every wall.
  stitch_blocks.png   a stuffed felt block's faces in the 3 by 2 layout a box mesh unwraps to, four
                      times over, one quarter a suit: plum felt, every seam top-stitched in cream
                      and a cream felt suit appliqued on each face.
  quilt_albedo.png    the quilted apron round the table, grayscale about white to be multiplied
                      by its color: diamonds puffed between grooves of running stitch, tiling.
"""

import math
import pathlib

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "textures"
FELT = Image.open(ROOT / "assets" / "textures" / "felt_albedo.png").convert("L")

OATMEAL = (214, 200, 172)
PLUM_THREAD = (112, 52, 86)
PLUM_FELT = (84, 44, 68)
CREAM = (236, 226, 204)


def mottled(color, size):
    """Felt in `color`, its fibers mottled the way the room's own felt is."""
    grain = FELT.resize(size, Image.BILINEAR)
    base = Image.new("RGB", size, color)
    shade = Image.merge("RGB", [grain.point(lambda v: int(255 - (255 - v) * 1.4))] * 3)
    return ImageChops.multiply(base, shade)


def running_stitch(draw, start, end, color, dash, gap, width):
    """A line of running stitch from `start` to `end`: dashes with the felt showing between."""
    length = math.dist(start, end)
    steps = int(length // (dash + gap))
    ux, uy = (end[0] - start[0]) / length, (end[1] - start[1]) / length
    offset = (length - steps * (dash + gap) + gap) * 0.5
    for i in range(steps):
        a = offset + i * (dash + gap)
        b = a + dash
        draw.line(
            [(start[0] + ux * a, start[1] + uy * a), (start[0] + ux * b, start[1] + uy * b)],
            fill=color,
            width=width,
        )


def stitched_square(draw, box, inset, color, dash, gap, width):
    x0, y0, x1, y1 = box
    x0, y0, x1, y1 = x0 + inset, y0 + inset, x1 - inset, y1 - inset
    for start, end in (((x0, y0), (x1, y0)), ((x1, y0), (x1, y1)), ((x1, y1), (x0, y1)),
                       ((x0, y1), (x0, y0))):
        running_stitch(draw, start, end, color, dash, gap, width)


def bolster():
    size = 256
    img = mottled(OATMEAL, (size, size))
    draw = ImageDraw.Draw(img)
    # 1.25 m to the tile: a stitch 7 cm long with 5 cm between, 0.3 m in from each seam, which
    # is on the flat of the bolster's top rather than round its rolled edge.
    px = size / 1.25
    stitched_square(draw, (0, 0, size, size), 0.3 * px, PLUM_THREAD, 0.07 * px, 0.05 * px, 5)
    img.save(OUT / "stitch_bolster.png")


def suit(draw, which, cx, cy, r, color):
    """One suit `r` across its half, drawn from circles and triangles."""
    lobe = r * 0.52
    if which == 0:  # heart
        draw.ellipse((cx - r, cy - r * 0.75, cx - r + lobe * 2, cy - r * 0.75 + lobe * 2), fill=color)
        draw.ellipse((cx + r - lobe * 2, cy - r * 0.75, cx + r, cy - r * 0.75 + lobe * 2), fill=color)
        draw.polygon([(cx - r * 0.97, cy - r * 0.1), (cx + r * 0.97, cy - r * 0.1), (cx, cy + r)],
                     fill=color)
    elif which == 1:  # diamond
        draw.polygon([(cx, cy - r), (cx + r * 0.72, cy), (cx, cy + r), (cx - r * 0.72, cy)],
                     fill=color)
    elif which == 2:  # club
        small = r * 0.42
        for ox, oy in ((0.0, -0.45), (-0.5, 0.12), (0.5, 0.12)):
            x, y = cx + ox * r, cy + oy * r
            draw.ellipse((x - small, y - small, x + small, y + small), fill=color)
        draw.polygon([(cx, cy), (cx + r * 0.32, cy + r), (cx - r * 0.32, cy + r)], fill=color)
    else:  # spade
        draw.ellipse((cx - r, cy - r * 0.15, cx - r + lobe * 2, cy - r * 0.15 + lobe * 2),
                     fill=color)
        draw.ellipse((cx + r - lobe * 2, cy - r * 0.15, cx + r, cy - r * 0.15 + lobe * 2),
                     fill=color)
        draw.polygon([(cx - r * 0.97, cy + r * 0.4), (cx + r * 0.97, cy + r * 0.4), (cx, cy - r)],
                     fill=color)
        draw.polygon([(cx, cy + r * 0.2), (cx + r * 0.32, cy + r), (cx - r * 0.32, cy + r)],
                     fill=color)


def blocks():
    cell = 128
    img = Image.new("RGB", (cell * 6, cell * 4))
    for quarter in range(4):
        qx, qy = (quarter % 2) * cell * 3, (quarter // 2) * cell * 2
        face = mottled(PLUM_FELT, (cell * 3, cell * 2))
        draw = ImageDraw.Draw(face)
        for column in range(3):
            for row in range(2):
                box = (column * cell, row * cell, (column + 1) * cell, (row + 1) * cell)
                stitched_square(draw, box, 13, CREAM, 9, 6, 4)
                # The suit appliqued in cream felt with a darker blanket edge round it.
                cx, cy = box[0] + cell / 2, box[1] + cell / 2
                suit(draw, quarter, cx, cy + 2, 31, (60, 30, 48))
                suit(draw, quarter, cx, cy, 29, CREAM)
        img.paste(face, (qx, qy))
    img.save(OUT / "stitch_blocks.png")


def quilt():
    size = 512
    # One diamond to every 128 pixels each way: the apron tiles this every 4 m, so a diamond is
    # a meter across.
    spacing = 128
    img = Image.new("L", (size, size), 255)
    puff = Image.new("L", (size, size))
    pixels = puff.load()
    for y in range(size):
        for x in range(size):
            u = ((x + y) % spacing) / spacing
            v = ((x - y) % spacing) / spacing
            # Highest in the middle of a diamond, falling to the grooves either side.
            d = min(u, 1.0 - u, v, 1.0 - v) * 2.0
            pixels[x, y] = int(178 + 77 * math.sqrt(max(d, 0.0)))
    img = ImageChops.multiply(img, puff)
    draw = ImageDraw.Draw(img)
    for k in range(-size // spacing - 1, size // spacing * 2 + 2):
        start = k * spacing
        running_stitch(draw, (start, 0), (start + size, size), 222, 10, 7, 3)
        running_stitch(draw, (start, size), (start + size, 0), 222, 10, 7, 3)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    grain = FELT.resize((size, size), Image.BILINEAR)
    img = ImageChops.multiply(img, grain)
    img.save(OUT / "quilt_albedo.png")


if __name__ == "__main__":
    bolster()
    blocks()
    quilt()
    print("felt prints in", OUT)
