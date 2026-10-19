#!/usr/bin/env python3
"""Draws the prints of the House's karts, GAME.md 8.1b: what goes on a kart besides its paint.

    tools/make_kart_prints.py [body ...]

Without a body named, draws them all. The chassis every body stands on, tools/make_kart.py, wears
one driver, so the driver's print is shared, and every body's own print lays the seat's roundel
on its bonnet in the same place:

  karts/driver.png       the driver's face, wrapped round its head: eyes, a blush, a grin
  tin-kart/hub.png       the tin kart's pressed wheel: whitewall, red hub, steel cap
  tin-kart/litho.png     the tin kart's print over the paint: pinstripes, the roundel, rivets and
                         seams, each ink a pixel or two out of register as a lithograph's are
  karts/hub_<body>.png   the outer face of a body's wheel, laid across its hub
  karts/wood.png         the woodie's bare maple, its grain running along the picture
  karts/print_<body>.png a body's print over the player's paint, laid from above on the model's
                         second UV (RGBA: clear where the paint shows)

A print over the paint is the detail layer KartDress.paint lays on: x from -0.5 to 0.5 m across,
y from the nose (the top of the picture, -0.9 m) to the tail (+0.9 m), at 512 x 1024. Every
unevenness in an ink is seeded, so drawing them again draws the same prints.
"""

import math
import pathlib
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
TIN = ROOT / "assets" / "models" / "tin-kart"
KARTS = ROOT / "assets" / "models" / "karts"

CREAM = (239, 227, 200)
INK = (33, 31, 36)
GOLD = (217, 164, 65)
GOLD_LIGHT = (245, 206, 120)
RED = (192, 57, 43)
STEEL = (176, 178, 184)
SKIN = (238, 202, 164)
RUBBER = (30, 29, 33)
MAPLE = (222, 186, 136)
GRAIN = (120, 78, 40)

# The print laid from above: its size, and where the seat's roundel sits on every bonnet.
PRINT = (512, 1024)
ROUNDEL = (0.0, -0.46)


def noise(size, seed, blur=3):
    """A soft gray noise, the same for the same seed."""
    rng = random.Random(seed)
    img = Image.new("L", size)
    img.putdata([int(128 + rng.gauss(0, 40)) for _ in range(size[0] * size[1])])
    return img.filter(ImageFilter.GaussianBlur(blur))


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
    lift = noise(img.size, seed).point(lambda v: int(255 - amount * 255 * (v / 255.0)))
    r, g, b, a = img.split()
    r = Image.composite(r, r.point(lambda v: int(v * 0.92)), lift)
    g = Image.composite(g, g.point(lambda v: int(v * 0.92)), lift)
    b = Image.composite(b, b.point(lambda v: int(v * 0.92)), lift)
    return Image.merge("RGBA", (r, g, b, a))


def layer(size):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def at(x, y):
    """Where (x, y) in meters on the kart, seen from above, falls on a print over the paint."""
    return ((x + 0.5) * PRINT[0], (y + 0.9) * PRINT[1] / 1.8)


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


def roundel(d, ring=GOLD, edge=None):
    """The seat's roundel on the bonnet, ahead of the driver: the seal on a cream disc in a ring,
    the same on every body, with a fine [edge] round it where a body wants one to lift it."""
    cx, cy = at(*ROUNDEL)
    if edge is not None:
        d.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), fill=edge + (255,))
    d.ellipse((cx - 64, cy - 64, cx + 64, cy + 64), fill=ring + (255,))
    d.ellipse((cx - 56, cy - 56, cx + 56, cy + 56), fill=CREAM + (255,))
    seal(d, cx, cy, 40)


def disc(d, c, r, fill):
    d.ellipse((c - r, c - r, c + r, c + r), fill=fill + (255,))


def save(img, path, seed, amount=0.08, mode="RGBA"):
    """Saves a print with its inks a little uneven; a wheel's or a head's whole, in RGB."""
    ink_density(img, seed, amount).convert(mode).save(path)


# The chassis's prints.


def driver():
    """Wrapped round a sphere: u runs round it from the back, v from the crown down, so the front
    of the face is the middle of the picture and its equator the middle row, a degree of it about
    1.4 pixels either way. The helmet covers it from 12 degrees above its middle up and round the
    back, so only the face shows: two eyes with a glint, a blush either side and a grin."""
    w, h = 512, 256
    plates = []
    skin, d = layer((w, h))
    d.rectangle((0, 0, w, h), fill=SKIN + (255,))
    plates.append(skin)
    face, d = layer((w, h))
    c = w / 2
    for side in (-1, 1):
        cx = c + side * 22
        d.ellipse((cx - 7, 122, cx + 7, 142), fill=INK + (255,))
        d.ellipse((cx - 4, 125, cx + 1, 131), fill=(255, 255, 255, 255))
        bx = c + side * 43
        d.ellipse((bx - 12, 146, bx + 12, 158), fill=(234, 150, 136, 255))
    d.arc((c - 14, 138, c + 14, 164), 25, 155, fill=INK + (255,), width=4)
    plates.append(face)
    img = misregister(plates, (w, h), 7)
    save(img, KARTS / "driver.png", 8, mode="RGB")


# The tin kart, the House's first: a lithographed tin wind-up racer.


def tin_hub():
    s = 256
    c = s / 2
    plates = []
    base, d = layer((s, s))
    for r, col in ((126, RUBBER), (104, CREAM), (86, STEEL), (72, RED), (40, STEEL), (22, GOLD)):
        disc(d, c, r, col)
    plates.append(base)
    spokes, d = layer((s, s))
    for k in range(6):
        a = k * math.pi / 3
        d.line([(c + 44 * math.cos(a), c + 44 * math.sin(a)),
                (c + 68 * math.cos(a), c + 68 * math.sin(a))], fill=(120, 34, 28, 255), width=7)
    plates.append(spokes)
    img = misregister(plates, (s, s), 3)
    ink_density(img, 4).convert("RGB").save(TIN / "hub.png")


def tin():
    tin_hub()
    plates = []
    stripes, d = layer(PRINT)
    # gold pinstripes either side of the spine, nose to tail, with a cream line inside each
    for side in (-1, 1):
        x = side * 0.085
        d.line([at(x, -0.85), at(x, 0.65)], fill=GOLD + (255,), width=8)
        inside = x - side * 0.022
        d.line([at(inside, -0.85), at(inside, 0.65)], fill=CREAM + (235,), width=4)
    plates.append(stripes)
    seat, d = layer(PRINT)
    roundel(d)
    # a grille of vents printed on the tail, either side of the key
    for k in range(4):
        y = 0.40 + k * 0.045
        for side in (-1, 1):
            a = at(side * 0.13, y)
            b = at(side * 0.25, y)
            d.rounded_rectangle((min(a[0], b[0]), a[1] - 5, max(a[0], b[0]), a[1] + 5), 5,
                                fill=INK + (150,))
    plates.append(seat)
    seams, d = layer(PRINT)
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
    img = misregister(plates, PRINT, 11)
    save(img, TIN / "litho.png", 12)


# The painted bodies: clean inks on a satin paint, no plates out of register.


def racer():
    """Today's racer as a painted toy: twin cream stripes either side of the spine, nose to tail
    with the cockpit between, a fine ink line inside each, and the roundel."""
    s = 256
    c = s / 2
    hub, d = layer((s, s))
    for r, col in ((128, RUBBER), (112, CREAM), (96, (214, 200, 170)), (90, CREAM),
                   (46, (150, 152, 160)), (40, STEEL), (16, (210, 212, 218))):
        disc(d, c, r, col)
    for k in range(5):
        a = k * 2 * math.pi / 5 - math.pi / 2
        x, y = c + 64 * math.cos(a), c + 64 * math.sin(a)
        d.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(150, 140, 120, 255))
    save(hub, KARTS / "hub_racer.png", 21, 0.05, "RGB")
    img, d = layer(PRINT)
    for side in (-1, 1):
        for y0, y1 in ((-0.86, -0.27), (0.33, 0.66)):
            a, b = at(side * 0.07, y0), at(side * 0.12, y1)
            d.rectangle((min(a[0], b[0]), a[1], max(a[0], b[0]), b[1]), fill=CREAM + (255,))
            a, b = at(side * 0.135, y0), at(side * 0.145, y1)
            d.rectangle((min(a[0], b[0]), a[1], max(a[0], b[0]), b[1]), fill=CREAM + (255,))
    roundel(d, edge=INK)
    save(img, KARTS / "print_racer.png", 22, 0.04)


def woodie():
    """The wooden pull-along: the grain of the wood running nose to tail through the paint, a cream
    band down the spine as the toy has, the grooves the lathe cut round it, and the roundel; its
    end grain on the wheels' hubs, and the bare maple of its dowels."""
    s = 256
    c = s / 2
    grain, d = layer((s, s))
    d.rectangle((0, 0, s, s), fill=MAPLE + (255,))
    rng = random.Random(31)
    # end grain: rings round the heart of the wood, a little off the middle
    hx, hy = c + 14, c - 9
    for r in range(8, 190, 7):
        rr = r + rng.uniform(-1.5, 1.5)
        tone = (190, 146, 96, 255) if (r // 7) % 2 else (204, 164, 114, 255)
        d.ellipse((hx - rr, hy - rr * 0.97, hx + rr, hy + rr * 0.97), outline=tone, width=2)
    face = Image.new("L", (s, s), 0)
    ImageDraw.Draw(face).ellipse((c - 112, c - 112, c + 112, c + 112), fill=255)
    hub, d = layer((s, s))
    disc(d, c, 128, RUBBER)
    disc(d, c, 118, (176, 132, 84))
    hub.paste(grain, (0, 0), face)
    d = ImageDraw.Draw(hub)
    d.ellipse((c - 112, c - 112, c + 112, c + 112), outline=(170, 124, 76, 255), width=3)
    save(hub, KARTS / "hub_woodie.png", 32, 0.06, "RGB")
    img, d = layer(PRINT)
    rng = random.Random(33)
    # the grain: long fine lines nose to tail, wandering a little, dark and faint
    for k in range(110):
        x = rng.uniform(-0.48, 0.48)
        y0 = rng.uniform(-0.9, -0.2)
        y1 = rng.uniform(0.2, 0.9)
        pts = []
        wob = rng.uniform(0.004, 0.012)
        phase = rng.uniform(0, 6.3)
        for i in range(24):
            y = y0 + (y1 - y0) * i / 23
            pts.append(at(x + wob * math.sin(phase + y * 9), y))
        d.line(pts, fill=GRAIN + (rng.randint(40, 90),), width=rng.choice((1, 2, 2, 3)))
    # a knot or two
    for x, y in ((0.18, 0.42), (-0.21, -0.2)):
        cx, cy = at(x, y)
        for r in (5, 9, 13):
            d.ellipse((cx - r * 0.6, cy - r, cx + r * 0.6, cy + r), outline=GRAIN + (70,), width=2)
    for y0, y1 in ((-0.88, -0.27), (0.32, 0.66)):
        a, b = at(-0.05, y0), at(0.05, y1)
        d.rectangle((a[0], a[1], b[0], b[1]), fill=CREAM + (245,))
    # the grooves the lathe cut round the nose and the tail, laid from above as rings round it
    for y in (-0.74, -0.715, 0.50, 0.525):
        d.line([at(-0.5, y), at(0.5, y)], fill=GRAIN + (150,), width=3)
    roundel(d, ring=(160, 108, 58), edge=CREAM)
    save(img, KARTS / "print_woodie.png", 34, 0.05)
    # the bare wood of its dowels, ring and fin: maple with its grain along the picture
    s = 256
    bare, d = layer((s, s))
    d.rectangle((0, 0, s, s), fill=MAPLE + (255,))
    rng = random.Random(35)
    for k in range(60):
        y = rng.uniform(0, s)
        wob = rng.uniform(1.0, 4.0)
        phase = rng.uniform(0, 6.3)
        pts = [(x, y + wob * math.sin(phase + x / s * 2 * math.pi)) for x in range(-4, s + 8, 8)]
        tone = rng.choice(((196, 152, 100), (204, 162, 112), (186, 140, 90)))
        d.line(pts, fill=tone + (255,), width=rng.choice((1, 2, 2, 3)))
    save(bare, KARTS / "wood.png", 36, 0.05, "RGB")


def streamliner():
    """The art-deco teardrop: a whitewall round a chrome disc on its wheels, and on the body the
    roundel with three ink whiskers swept back either side of the nose's chrome spear."""
    s = 256
    c = s / 2
    hub, d = layer((s, s))
    for r, col in ((128, RUBBER), (112, (244, 240, 230)), (84, RUBBER), (80, (200, 202, 208))):
        disc(d, c, r, col)
    save(hub, KARTS / "hub_streamliner.png", 41, 0.04, "RGB")
    img, d = layer(PRINT)
    for side in (-1, 1):
        for k in range(3):
            x0, x1 = 0.035 + k * 0.03, 0.10 + k * 0.045
            d.line([at(side * x0, -0.84 + k * 0.012), at(side * x1, -0.64 + k * 0.03)],
                   fill=INK + (215,), width=5)
    roundel(d, edge=INK)
    save(img, KARTS / "print_streamliner.png", 42, 0.04)


def microcar():
    """The molded micro-car's sticker livery: a cream stripe either side of the spine in a fine
    ink edge, a checkered band across the tail, a star on each pod, and the roundel, every one cut
    with the white margin round it a sticker has."""
    s = 256
    c = s / 2
    hub, d = layer((s, s))
    for r, col in ((128, RUBBER), (106, CREAM), (40, GOLD), (30, GOLD_LIGHT), (24, GOLD)):
        disc(d, c, r, col)
    for k in range(5):
        a = k * 2 * math.pi / 5 - math.pi / 2
        x, y = c + 72 * math.cos(a), c + 72 * math.sin(a)
        d.ellipse((x - 11, y - 11, x + 11, y + 11), fill=(196, 182, 152, 255))
    save(hub, KARTS / "hub_microcar.png", 51, 0.04, "RGB")
    img, d = layer(PRINT)
    white = (250, 248, 242)
    for side in (-1, 1):
        for y0, y1 in ((-0.79, -0.30), (0.32, 0.47)):
            a, b = at(side * 0.055, y0), at(side * 0.16, y1)
            box = (min(a[0], b[0]), a[1], max(a[0], b[0]), b[1])
            d.rounded_rectangle((box[0] - 10, box[1] - 10, box[2] + 10, box[3] + 10), 16,
                                fill=white + (255,))
            d.rounded_rectangle((box[0] - 5, box[1] - 5, box[2] + 5, box[3] + 5), 12,
                                fill=INK + (255,))
            d.rounded_rectangle(box, 8, fill=CREAM + (255,))
    # the checkered band across the tail
    y0, y1 = 0.50, 0.58
    a, b = at(-0.22, y0), at(0.22, y1)
    d.rounded_rectangle((a[0] - 7, a[1] - 7, b[0] + 7, b[1] + 7), 10, fill=white + (255,))
    n = 10
    cell = (b[0] - a[0]) / n
    for i in range(n):
        for j in range(2):
            col = INK if (i + j) % 2 else CREAM
            x = a[0] + i * cell
            y = a[1] + j * (b[1] - a[1]) / 2
            d.rectangle((x, y, x + cell, y + (b[1] - a[1]) / 2), fill=col + (255,))
    # a star on each pod
    for side in (-1, 1):
        cx, cy = at(side * 0.31, -0.06)
        for r, col in ((36, white), (31, INK), (26, CREAM)):
            d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=col + (255,))
        pts = []
        for k in range(10):
            ang = -math.pi / 2 + k * math.pi / 5
            rr = 20 if k % 2 == 0 else 8
            pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
        d.polygon(pts, fill=RED + (255,))
    roundel(d, edge=white)
    save(img, KARTS / "print_microcar.png", 52, 0.03)


BODIES = {"tin": tin, "racer": racer, "woodie": woodie, "streamliner": streamliner,
          "microcar": microcar}


if __name__ == "__main__":
    names = sys.argv[1:] or list(BODIES)
    KARTS.mkdir(parents=True, exist_ok=True)
    driver()
    for name in names:
        BODIES[name]()
    print("prints for", ", ".join(names))
