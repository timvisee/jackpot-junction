#!/usr/bin/env python3
"""Draws the prints of the tin kart, GAME.md 8.1b: what the House lithographs on its wind-up racer.

    tools/make_kart_prints.py

Writes into assets/models/tin-kart/:
  hub.png     a pressed wheel's printed face: whitewall, red hub, steel cap
  driver.png  the tin driver's head, wrapped round it: a leather cap, goggles, a printed grin
  litho.png   the body's print over whatever the player's paint is: pinstripes, the House's seal on
              the bonnet, rivets and seams, laid from above (RGBA: clear where the paint shows)

Each ink is laid as a lithograph lays it, a pixel or two out of register with the others, so the
prints read as printed tin rather than as clean vector art. tools/make_kart.py builds the model
that wears them; the litho is the detail layer KartDress.paint puts over the paint.
"""

import math
import pathlib
import random

from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "models" / "tin-kart"

CREAM = (239, 227, 200)
INK = (33, 31, 36)
GOLD = (217, 164, 65)
GOLD_LIGHT = (245, 206, 120)
RED = (192, 57, 43)
STEEL = (176, 178, 184)
SKIN = (238, 202, 164)
LEATHER = (112, 72, 44)


def misregister(layers, size, seed):
    """Composites ink layers (RGBA images) each nudged by up to two pixels, as plates drift."""
    rng = random.Random(seed)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    for layer in layers:
        dx, dy = rng.randint(-2, 2), rng.randint(-2, 2)
        shifted = Image.new("RGBA", size, (0, 0, 0, 0))
        shifted.paste(layer, (dx, dy), layer)
        out = Image.alpha_composite(out, shifted)
    return out


def ink_density(img, seed, amount=0.08):
    """A little unevenness in how much ink each patch took."""
    noise = Image.effect_noise(img.size, 40).convert("L").filter(ImageFilter.GaussianBlur(3))
    r, g, b, a = img.split()
    rng = random.Random(seed)
    lift = noise.point(lambda v: int(255 - amount * 255 * (v / 255.0)))
    r = Image.composite(r, r.point(lambda v: int(v * 0.92)), lift)
    g = Image.composite(g, g.point(lambda v: int(v * 0.92)), lift)
    b = Image.composite(b, b.point(lambda v: int(v * 0.92)), lift)
    del rng
    return Image.merge("RGBA", (r, g, b, a))


def layer(size):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def seal(d, cx, cy, r, foil=GOLD, ink=INK):
    """The House's seal, small: scalloped foil, an ink ring, the foil chip with its crossroads."""
    pts = []
    for a in range(0, 360, 3):
        t = math.radians(a)
        rr = r * (1 + 0.05 * math.cos(24 * t))
        pts.append((cx + rr * math.cos(t), cy + rr * math.sin(t)))
    d.polygon(pts, fill=foil + (255,))
    d.ellipse((cx - r * 0.66, cy - r * 0.66, cx + r * 0.66, cy + r * 0.66), fill=ink + (255,))
    d.ellipse((cx - r * 0.5, cy - r * 0.5, cx + r * 0.5, cy + r * 0.5), fill=foil + (255,))
    w = r * 0.14
    d.rectangle((cx - w, cy - r * 0.5, cx + w, cy + r * 0.5), fill=ink + (255,))
    d.rectangle((cx - r * 0.5, cy - w, cx + r * 0.5, cy + w), fill=ink + (255,))
    d.ellipse((cx - w * 1.4, cy - w * 1.4, cx + w * 1.4, cy + w * 1.4), fill=RED + (255,))


def hub():
    s = 256
    c = s / 2
    plates = []
    base, d = layer((s, s))
    for r, col in ((126, (30, 29, 33)), (104, CREAM), (86, STEEL), (72, RED), (40, STEEL), (22, GOLD)):
        d.ellipse((c - r, c - r, c + r, c + r), fill=col + (255,))
    plates.append(base)
    spokes, d = layer((s, s))
    for k in range(6):
        a = k * math.pi / 3
        d.line([(c + 44 * math.cos(a), c + 44 * math.sin(a)), (c + 68 * math.cos(a), c + 68 * math.sin(a))],
               fill=(120, 34, 28, 255), width=7)
    plates.append(spokes)
    img = misregister(plates, (s, s), 3)
    ink_density(img, 4).convert("RGB").save(OUT / "hub.png")


def driver():
    """Wrapped round a sphere: u runs round it from the back, v from the crown down."""
    w, h = 512, 256
    plates = []
    skin, d = layer((w, h))
    d.rectangle((0, 0, w, h), fill=SKIN + (255,))
    plates.append(skin)
    cap, d = layer((w, h))
    d.rectangle((0, 0, w, 92), fill=LEATHER + (255,))
    d.rectangle((0, 84, w, 98), fill=(78, 48, 30, 255))
    # ear flaps either side
    for cx in (w * 0.25, w * 0.75):
        d.rounded_rectangle((cx - 26, 70, cx + 26, 160), 18, fill=LEATHER + (255,))
    plates.append(cap)
    face, d = layer((w, h))
    # goggles up on the cap, at the front (u = 0.5 faces forward)
    for cx in (w * 0.45, w * 0.55):
        d.ellipse((cx - 24, 44, cx + 24, 90), fill=GOLD + (255,))
        d.ellipse((cx - 16, 51, cx + 16, 83), fill=(120, 182, 205, 255))
        d.ellipse((cx - 10, 54, cx + 2, 64), fill=(232, 246, 252, 255))
    d.rectangle((0, 60, w * 0.45 - 24, 70), fill=(60, 40, 26, 255))
    d.rectangle((w * 0.55 + 24, 60, w, 70), fill=(60, 40, 26, 255))
    for cx in (w * 0.465, w * 0.535):
        d.ellipse((cx - 8, 122, cx + 8, 142), fill=INK + (255,))
        d.ellipse((cx - 3, 125, cx + 2, 131), fill=(255, 255, 255, 255))
    for cx in (w * 0.43, w * 0.57):
        d.ellipse((cx - 13, 146, cx + 13, 160), fill=(230, 146, 132, 255))
    d.arc((w * 0.465, 140, w * 0.535, 176), 20, 160, fill=INK + (255,), width=5)
    plates.append(face)
    img = misregister(plates, (w, h), 7)
    ink_density(img, 8).convert("RGB").save(OUT / "driver.png")


def litho():
    """Over the body from above: x from -0.5 to 0.5 m across, y from the nose (top of the picture,
    -0.9 m) to the tail (+0.9 m), at 512 x 1024. Clear wherever the player's paint shows."""
    w, h = 512, 1024
    sx = w / 1.0
    sy = h / 1.8

    def at(x, y):
        return ((x + 0.5) * sx, (y + 0.9) * sy)

    plates = []
    stripes, d = layer((w, h))
    # gold pinstripes either side of the spine, nose to tail, with a cream line inside each
    for side in (-1, 1):
        x = side * 0.085
        a, b = at(x, -0.85), at(x, 0.65)
        d.line([a, b], fill=GOLD + (255,), width=8)
        a, b = at(x - side * 0.022, -0.85), at(x - side * 0.022, 0.65)
        d.line([a, b], fill=CREAM + (235,), width=4)
    plates.append(stripes)
    roundel, d = layer((w, h))
    # the seal on the bonnet, ahead of the driver, on a cream disc ringed in gold
    cx, cy = at(0.0, -0.46)
    d.ellipse((cx - 64, cy - 64, cx + 64, cy + 64), fill=GOLD + (255,))
    d.ellipse((cx - 56, cy - 56, cx + 56, cy + 56), fill=CREAM + (255,))
    seal(d, cx, cy, 40)
    # a grille of vents printed on the tail, either side of the key
    for k in range(4):
        y = 0.40 + k * 0.045
        for side in (-1, 1):
            a = at(side * 0.13, y)
            b = at(side * 0.25, y)
            d.rounded_rectangle((min(a[0], b[0]), a[1] - 5, max(a[0], b[0]), a[1] + 5), 5, fill=INK + (150,))
    plates.append(roundel)
    seams, d = layer((w, h))
    # printed rivets down either flank and the seam the pressings meet at, faint
    for k in range(10):
        y = -0.7 + k * 0.14
        for side in (-1, 1):
            x, yy = at(side * 0.30, y)
            d.ellipse((x - 5, yy - 5, x + 5, yy + 5), fill=GOLD + (210,))
            d.ellipse((x - 3, yy - 4, x + 2, yy + 1), fill=GOLD_LIGHT + (230,))
    for side in (-1, 1):
        d.line([at(side * 0.36, -0.75), at(side * 0.36, 0.6)], fill=INK + (70,), width=3)
    plates.append(seams)
    img = misregister(plates, (w, h), 11)
    ink_density(img, 12).save(OUT / "litho.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    hub()
    driver()
    litho()
    print("prints in", OUT)
