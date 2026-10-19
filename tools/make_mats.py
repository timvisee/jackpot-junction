#!/usr/bin/env python3
"""Draws the mats two rooms lay over their floors, GAME.md 8.1, into assets/textures/:

    tools/make_mats.py

  rubber_albedo.png  the Garage's rubber matting, GAME.md 9.4: interlocking tiles a meter square
  rubber_normal.png  with fine ribs pressed into them, the ribs of each tile turned a quarter from
                     its neighbours', so a bay of them reads as tiles from across the room and as
                     rubber close up. Two meters square; grayscale around white, multiplied by the
                     room's own color as every surface is.

Periodic by construction, so a slab the size of a table is tiled out of it without a seam.
"""

import pathlib

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "textures"
RNG = np.random.default_rng(20261019)

# The rubber: how many pixels across, how many tiles a side, and how many ribs to a tile.
RUBBER = 512
TILES = 2
RIBS = 10


def noise(size, scale):
    """Periodic noise with features about `scale` pixels across, between -1 and 1."""
    white = RNG.normal(size=(size, size))
    fx = np.fft.fftfreq(size)[:, None]
    fy = np.fft.fftfreq(size)[None, :]
    radius = np.sqrt(fx ** 2 + fy ** 2)
    target = 1.0 / max(scale, 2.0)
    band = np.exp(-((radius - target) ** 2) / (2.0 * (target * 0.6) ** 2))
    band[0, 0] = 0.0
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * band))
    out -= out.mean()
    return out / np.abs(out).max()


def normal_map(height, strength):
    """A tangent-space normal map from a periodic height field."""
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * strength
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * strength
    normals = np.stack([-dx, -dy, np.ones_like(height)], axis=-1)
    normals /= np.linalg.norm(normals, axis=-1, keepdims=True)
    return Image.fromarray(((normals * 0.5 + 0.5) * 255.0).astype(np.uint8), mode="RGB")


def rubber():
    size = RUBBER
    tile = size // TILES
    line = np.arange(size)
    down, across = np.meshgrid(line, line, indexing="ij")
    # Which way each tile's ribs run: along x on one diagonal of the checker, along y on the other.
    along_x = ((down // tile) + (across // tile)) % 2 == 0
    phase = np.where(along_x, down % tile, across % tile) / tile * RIBS
    # A rib is a rounded ridge a little over half its pitch wide, with a flat groove between.
    ridge = np.clip(np.cos((phase % 1.0 - 0.5) * np.pi * 1.7), 0.0, 1.0) ** 0.6
    # Each rib stops short of the tile's edge, where the tiles lock together in a plain border.
    inside = np.minimum(np.minimum(down % tile, tile - 1 - down % tile),
                        np.minimum(across % tile, tile - 1 - across % tile))
    border = np.clip((inside - 5.0) / 3.0, 0.0, 1.0)
    height = ridge * border
    # The joint between two tiles, a thin dark line, and each tile a shade off the next.
    joint = np.clip(1.0 - (inside - 1.0) / 2.0, 0.0, 1.0)
    tones = RNG.uniform(-1.0, 1.0, (TILES, TILES))
    tone = tones[down // tile, across // tile]
    wear = noise(size, 90.0)
    albedo = 1.0 + height * 0.09 - (1.0 - border) * 0.03 - joint * 0.28 + tone * 0.025
    albedo += wear * 0.03
    gray = (np.clip(albedo * 0.93, 0.0, 1.0) * 255.0).astype(np.uint8)
    Image.fromarray(gray, mode="L").save(OUT / "rubber_albedo.png", optimize=True)
    relief = height * 0.8 - joint * 0.3
    normals = normal_map(relief, 2.2).resize((size // 2, size // 2), Image.LANCZOS)
    normals.save(OUT / "rubber_normal.png", optimize=True)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    rubber()
    print("mats in", OUT)
