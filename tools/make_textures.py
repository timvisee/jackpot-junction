"""Generates the seamless surface textures the rooms are made of, GAME.md 8.1.

Run with `make textures`, which writes assets/textures. Needs numpy and pillow.

Everything here is periodic: the noise is built by filtering white noise in the
frequency domain, which wraps by construction, so a slab the size of a table can
be tiled out of it without a seam. Albedo maps are greyscale around 1.0 and are
multiplied by the room's own colour, so one felt serves a green table and a slate
one; normal maps carry the relief.

The scale that matters is the one the camera actually sees. From forty metres up
a two-centimetre weave is nothing, so every map here carries a coarse component
that survives at that distance -- planks, worn patches, slab joints -- with the
fine detail riding on top of it for the times something is looked at closely.
"""

import pathlib

import numpy as np
from PIL import Image

OUT = pathlib.Path(__file__).resolve().parent.parent / "assets/textures"
SIZE = 512
RNG = np.random.default_rng(20260921)


def noise(scale, size=SIZE):
    """Periodic value noise with features about `scale` pixels across."""
    white = RNG.normal(size=(size, size))
    fx = np.fft.fftfreq(size)[:, None]
    fy = np.fft.fftfreq(size)[None, :]
    radius = np.sqrt(fx ** 2 + fy ** 2)
    target = 1.0 / max(scale, 2.0)
    band = np.exp(-((radius - target) ** 2) / (2.0 * (target * 0.6) ** 2))
    band[0, 0] = 0.0
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * band))
    out -= out.mean()
    peak = np.abs(out).max()
    return out / peak if peak > 0 else out


def octaves(scales, weights):
    out = np.zeros((SIZE, SIZE))
    for scale, weight in zip(scales, weights):
        out += noise(scale) * weight
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


def bands(count, softness=0.02):
    """`count` stripes across the texture, as a 0..1 seam mask that wraps."""
    y = np.linspace(0.0, 1.0, SIZE, endpoint=False)[:, None]
    phase = (y * count) % 1.0
    edge = np.minimum(phase, 1.0 - phase)
    return np.clip(1.0 - edge / softness, 0.0, 1.0) * np.ones((1, SIZE))


def band_index(count):
    y = np.linspace(0.0, 1.0, SIZE, endpoint=False)[:, None]
    return np.floor(y * count).astype(int) * np.ones((1, SIZE), dtype=int)


# --- felt: worn patches at table scale with the weave riding on them -----------
felt_worn = octaves([220.0, 90.0], [1.0, 0.55])
felt_weave = octaves([3.0, 6.0], [1.0, 0.6])
save(grey(felt_worn * 0.8 + felt_weave * 0.35, 1.0, 0.11), "felt_albedo.png")
save(normal_map(felt_weave * 0.7 + felt_worn * 0.3, 10.0), "felt_normal.png")

# --- wood: boards with seams between them, each with its own tone and grain ----
PLANKS = 4
seam = bands(PLANKS, 0.012)
plank = band_index(PLANKS)
tone = np.take(RNG.uniform(-1.0, 1.0, PLANKS), plank)
warp = octaves([80.0, 30.0], [1.0, 0.4])
rings = np.sin((np.linspace(0.0, 1.0, SIZE, endpoint=False)[None, :] * 6.0 + warp * 0.5) * 2.0 * np.pi * 2.0)
grain = noise(3.0) * 0.5 + noise(9.0) * 0.5
wood = rings * 0.35 + grain * 0.35 + tone * 0.5
save(grey(wood - seam * 1.4, 0.98, 0.13), "wood_albedo.png")
save(normal_map(wood * 0.5 - seam * 1.2, 6.0), "wood_normal.png")

# --- paint: a roller's orange peel, barely there, for the blocks and the crates -
paint = octaves([6.0, 18.0], [1.0, 0.6])
paint_worn = octaves([160.0], [1.0])
save(grey(paint * 0.5 + paint_worn * 0.7, 1.0, 0.06), "paint_albedo.png")
save(normal_map(paint, 6.0), "paint_normal.png")

# --- stone: poured slabs with joints, mottled, with a pepper of aggregate ------
joint = np.maximum(bands(3, 0.01), bands(3, 0.01).T)
stone = octaves([200.0, 60.0, 12.0], [1.0, 0.6, 0.35])
pepper = (RNG.random((SIZE, SIZE)) > 0.992).astype(float)
pepper -= (RNG.random((SIZE, SIZE)) > 0.994).astype(float)
save(grey(stone + pepper * 0.5 - joint * 1.2, 1.0, 0.12), "stone_albedo.png")
save(normal_map(stone * 0.5 + pepper * 0.3 - joint * 1.4, 8.0), "stone_normal.png")
