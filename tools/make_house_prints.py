#!/usr/bin/env python3
"""Draws the prints the House puts on every table, GAME.md 8.1c, into assets/textures/:

    tools/make_house_prints.py

  rail_print.png  the House's rail round every arena, one run 8 m along and a meter up: dark stock
                  with a foil hairline near the top and the foot, and the House's microprint along
                  the middle, as the corner blocks of the HUD carry it (8.1a). The microprint
                  comes round exactly once in the run, its spacing measured to fit, so where one
                  run of the print meets the next along a rail the line carries on rather than
                  breaking off in the middle of a word.
"""

import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "textures"
FONT = ROOT / "assets" / "fonts" / "BarlowCondensed-ExtraBold.ttf"

STOCK = (27, 26, 34)
STOCK_LIT = (39, 37, 47)
FOIL = (242, 193, 78)
FOIL_DEEP = (181, 134, 42)
MICROPRINT = (
    "JACKPOT JUNCTION",
    "LICENSED ON EVERY TABLE",
    "THE HOUSE",
    "DEPT. OF KARTS",
    "NOT VALID AS CURRENCY",
)


def rail():
    w, h = 2048, 256
    img = Image.new("RGB", (w, h), STOCK)
    d = ImageDraw.Draw(img)
    # A little lighter toward the top, as card under a lamp is.
    for y in range(h):
        t = 1.0 - y / h
        c = tuple(int(STOCK[i] + (STOCK_LIT[i] - STOCK[i]) * t * 0.6) for i in range(3))
        d.line([(0, y), (w, y)], fill=c)
    for y, width in ((26, 5), (h - 30, 5)):
        d.rectangle((0, y, w, y + width), fill=FOIL)
        d.line([(0, y + width), (w, y + width)], fill=FOIL_DEEP, width=1)
    font = ImageFont.truetype(str(FONT), 46)
    ink = tuple(int(c * 0.62 + s * 0.38) for c, s in zip(FOIL, STOCK))
    # One round of the phrases with a dot after each, the gaps either side of the dots shared out
    # so the round is the run's width exactly, starting half a gap in so the seam falls in a gap.
    items = []
    for phrase in MICROPRINT:
        items += [phrase, "\u00b7"]
    widths = [d.textlength(item, font=font) for item in items]
    gap = (w - sum(widths)) / len(items)
    x = gap / 2
    for item, width in zip(items, widths):
        d.text((x, h / 2), item, font=font, fill=ink, anchor="lm")
        x += width + gap
    img.save(OUT / "rail_print.png")


if __name__ == "__main__":
    rail()
    print("prints in", OUT)
