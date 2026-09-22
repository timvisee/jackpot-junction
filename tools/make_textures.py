"""Generates the seamless surface textures the rooms are made of, GAME.md 8.1.

Run with `make textures`, which writes assets/textures. Needs numpy and pillow.

Everything here is periodic: the noise is built by filtering white noise in the
frequency domain, which wraps by construction, so a slab the size of a table can
be tiled out of it without a seam. Albedo maps are greyscale around 1.0 and are
multiplied by the room's own colour, so one felt serves a green table and a slate
one; normal maps carry what little relief there is.

Two things decide how these look. The first is the distance they are seen from:
from forty metres up a two-centimetre weave is nothing, so each map carries
something coarse enough to survive that -- the boards in the table, the wear in
the felt, the joints between slabs -- with finer grain under it. The second is
that a surface should read as the thing it is rather than as noise: baize is an
even nap with soft unevenness across it, a finished board is long straight grain,
poured concrete is fine aggregate with the odd darker patch. Contrast is kept low
on purpose. Anything stronger reads as damage.
"""

import pathlib

import numpy as np
from PIL import Image

OUT = pathlib.Path(__file__).resolve().parent.parent / "assets/textures"
SIZE = 512
RNG = np.random.default_rng(20260921)


def noise(scale, stretch=1.0, size=SIZE):
    """Periodic noise with features about `scale` across, `stretch` times longer along x."""
    white = RNG.normal(size=(size, size))
    fx = np.fft.fftfreq(size)[:, None] * stretch
    fy = np.fft.fftfreq(size)[None, :] / stretch
    radius = np.sqrt(fx ** 2 + fy ** 2)
    target = 1.0 / max(scale, 2.0)
    band = np.exp(-((radius - target) ** 2) / (2.0 * (target * 0.6) ** 2))
    band[0, 0] = 0.0
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * band))
    out -= out.mean()
    peak = np.abs(out).max()
    return out / peak if peak > 0 else out


def octaves(scales, weights, stretch=1.0):
    out = np.zeros((SIZE, SIZE))
    for scale, weight in zip(scales, weights):
        out += noise(scale, stretch) * weight
    peak = np.abs(out).max()
    return out / peak if peak > 0 else out


def grey(field, middle=1.0, spread=0.06):
    """A greyscale albedo map: `middle` with `spread` of variation either way."""
    values = np.clip(middle + field * spread, 0.0, 1.0)
    return Image.fromarray((values * 255.0).astype(np.uint8), mode="L")


def normal_map(height, strength=1.0):
    """A tangent-space normal map from a periodic height field."""
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * strength
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * strength
    normals = np.stack([-dx, -dy, np.ones_like(height)], axis=-1)
    normals /= np.linalg.norm(normals, axis=-1, keepdims=True)
    rgb = ((normals * 0.5 + 0.5) * 255.0).astype(np.uint8)
    return Image.fromarray(rgb, mode="RGB")


def save(image, name):
    OUT.mkdir(parents=True, exist_ok=True)
    # Normal maps are tiled small and never looked at up close, so half the resolution of an
    # albedo is plenty and a quarter of the bytes.
    if name.endswith("_normal.png"):
        image = image.resize((SIZE // 2, SIZE // 2), Image.LANCZOS)
    image.save(OUT / name, optimize=True)
    print(name, image.size, image.mode)


def seams(count, softness=0.012, along_x=False):
    """`count` seams across the texture as a 0..1 mask that wraps."""
    line = np.linspace(0.0, 1.0, SIZE, endpoint=False)
    phase = (line * count) % 1.0
    edge = np.minimum(phase, 1.0 - phase)
    band = np.clip(1.0 - edge / softness, 0.0, 1.0)
    return np.tile(band, (SIZE, 1)) if along_x else np.tile(band[:, None], (1, SIZE))


def band_index(count):
    line = np.floor(np.linspace(0.0, 1.0, SIZE, endpoint=False) * count).astype(int)
    return np.tile(line[:, None], (1, SIZE))


# --- felt: baize. An even nap with the table's own unevenness under it -------
nap = octaves([2.0, 4.0], [1.0, 0.5])
wear = octaves([260.0, 110.0], [1.0, 0.5])
save(grey(wear * 0.85 + nap * 0.3, 1.0, 0.055), "felt_albedo.png")
save(normal_map(nap, 3.0), "felt_normal.png")

# --- wood: finished boards. Long straight grain, seams you can just see ------
PLANKS = 4
seam = seams(PLANKS)
tone = np.take(RNG.uniform(-1.0, 1.0, PLANKS), band_index(PLANKS))
grain = octaves([3.0, 9.0, 30.0], [0.6, 1.0, 0.7], stretch=26.0)
figure = octaves([90.0], [1.0], stretch=8.0)
wood = grain * 0.55 + figure * 0.5 + tone * 0.35
save(grey(wood - seam * 0.9, 1.0, 0.075), "wood_albedo.png")
save(normal_map(grain * 0.25 - seam * 0.8, 3.0), "wood_normal.png")

# --- paint: a coat rolled onto a block. Nearly flat, a little uneven ---------
coat = octaves([9.0], [1.0])
uneven = octaves([200.0], [1.0])
save(grey(uneven * 0.9 + coat * 0.25, 1.0, 0.04), "paint_albedo.png")
save(normal_map(coat, 1.6), "paint_normal.png")

# --- stone: poured concrete. Fine aggregate, soft joints, the odd patch ------
joint = np.maximum(seams(3, 0.008), seams(3, 0.008, along_x=True))
aggregate = octaves([2.5, 7.0], [1.0, 0.6])
patches = octaves([220.0, 70.0], [1.0, 0.55])
save(grey(patches * 0.8 + aggregate * 0.35 - joint * 0.9, 1.0, 0.06), "stone_albedo.png")
save(normal_map(aggregate * 0.3 - joint * 1.0, 4.0), "stone_normal.png")


# --- playing cards -----------------------------------------------------------
#
# Not a material but a picture: the card room leaves cards lying about, and a card the size of a
# kart that is a white rectangle reads as a white rectangle. These are drawn rather than filtered
# -- a field, a border, a pip in the middle and one in the corner -- at a size that survives being
# looked at from forty metres up, which is all the detail a card at that distance can carry.

CARD = (356, 256)


def card_grid():
    """Coordinates across a card, each running 0 to 1."""
    down = np.linspace(0.0, 1.0, CARD[0])[:, None]
    across = np.linspace(0.0, 1.0, CARD[1])[None, :]
    return down + np.zeros_like(across), across + np.zeros_like(down)


def diamond(down, across, at, size):
    """A pip: the diamond, which is the one suit that reads at any size."""
    tall = np.abs(down - at[0]) / size[0]
    wide = np.abs(across - at[1]) / size[1]
    return tall + wide <= 1.0


def paint(field, mask, color):
    for channel in range(3):
        field[..., channel] = np.where(mask, color[channel] / 255.0, field[..., channel])


def border(down, across, margin):
    edge = np.minimum(np.minimum(down, 1.0 - down), np.minimum(across, 1.0 - across))
    return edge < margin


down, across = card_grid()
face = np.ones(CARD + (3,))
paint(face, np.ones(CARD, dtype=bool), (247, 243, 234))
paint(face, border(down, across, 0.045), (222, 214, 198))
paint(face, border(down, across, 0.03), (247, 243, 234))
paint(face, diamond(down, across, (0.5, 0.5), (0.26, 0.2)), (196, 69, 60))
paint(face, diamond(down, across, (0.12, 0.13), (0.07, 0.055)), (196, 69, 60))
paint(face, diamond(down, across, (0.88, 0.87), (0.07, 0.055)), (196, 69, 60))
save(Image.fromarray((face * 255.0).astype(np.uint8), mode="RGB"), "card_face.png")

# The back: the house's own lattice, which is what a deck left face down looks like.
back = np.zeros(CARD + (3,))
paint(back, np.ones(CARD, dtype=bool), (158, 32, 38))
lattice = np.zeros(CARD, dtype=bool)
for shift in np.linspace(-1.0, 2.0, 26):
    lattice |= np.abs(down + across - shift) < 0.012
    lattice |= np.abs(down - across - shift + 0.5) < 0.012
paint(back, lattice, (196, 74, 78))
paint(back, border(down, across, 0.055), (247, 243, 234))
paint(back, border(down, across, 0.04), (140, 26, 32))
save(Image.fromarray((back * 255.0).astype(np.uint8), mode="RGB"), "card_back.png")
