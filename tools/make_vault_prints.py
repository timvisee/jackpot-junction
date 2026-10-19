#!/usr/bin/env python3
"""Draws the pictures the House's glamour room is made of, GAME.md 8.1c, into assets/textures/:

    tools/make_vault_prints.py

  deco_flutes.png         the flutes down a deco wall's body, grayscale around white for the
                          wall's cream to be multiplied by: eight to a run, each a soft groove,
                          the same all the way up so a wall of any height wears them.
  deco_flutes_normal.png  the same flutes as a normal map, for the light to run down them.
  deco_sunburst.png       the gilded sunburst rising behind the poster on the back wall, the
                          title's own: rays of foil round a half sun, nothing between them, so the
                          wall shows through.
"""

import math
import pathlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "textures"

FOIL = (232, 186, 92)
FOIL_DEEP = (176, 128, 52)


def flutes():
    width, height, count = 256, 32, 8
    x = (np.arange(width) + 0.5) / width * count
    # A flute is a groove between two flats: the depth a soft cosine over the middle of each.
    phase = x - np.floor(x)
    groove = np.clip(np.cos((phase - 0.5) * math.pi / 0.42), 0.0, 1.0) ** 1.5
    groove[np.abs(phase - 0.5) > 0.21] = 0.0
    shade = 1.0 - groove * 0.2
    rows = np.repeat(shade[None, :], height, axis=0)
    Image.fromarray((rows * 255.0).astype(np.uint8), mode="L").save(OUT / "deco_flutes.png")
    height_field = -groove
    slope = np.gradient(height_field) * count * 0.35
    normal = np.stack([-slope, np.zeros_like(slope), np.ones_like(slope)], axis=-1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    rgb = ((normal * 0.5 + 0.5) * 255.0).astype(np.uint8)
    rows = np.repeat(rgb[None, :, :], height, axis=0)
    Image.fromarray(rows, "RGB").save(OUT / "deco_flutes_normal.png")


def sunburst():
    width, height = 2048, 1024
    scale = 2
    big = Image.new("RGBA", (width * scale, height * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    cx, cy = width * scale / 2, height * scale
    reach = width * scale * 0.49
    box = (cx - reach, cy - reach, cx + reach, cy + reach)
    # A fan of wedges, foil and nothing by turns, the long ones out to the edge and a short one
    # between each pair, as the title's sunburst is.
    wedges = 15
    step = 180.0 / wedges
    for k in range(wedges):
        start = 180.0 + k * step
        d.pieslice(box, start + step * 0.22, start + step * 0.78, fill=FOIL + (255,))
    short = reach * 0.8
    small = (cx - short, cy - short, cx + short, cy + short)
    for k in range(wedges + 1):
        middle = 180.0 + k * step
        d.pieslice(small, middle - step * 0.1, middle + step * 0.1, fill=FOIL_DEEP + (255,))
    # Clear round the sun, then the sun itself with a ring round it.
    clear = reach * 0.26
    d.ellipse((cx - clear, cy - clear, cx + clear, cy + clear), fill=(0, 0, 0, 0))
    ring = reach * 0.23
    d.ellipse((cx - ring, cy - ring, cx + ring, cy + ring), outline=FOIL + (255,),
              width=int(reach * 0.025))
    for r, fill in ((reach * 0.19, FOIL), (reach * 0.17, FOIL_DEEP), (reach * 0.15, FOIL)):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill + (255,))
    img = big.resize((width, height), Image.LANCZOS)
    img.save(OUT / "deco_sunburst.png")


if __name__ == "__main__":
    flutes()
    sunburst()
    print("prints in", OUT)
