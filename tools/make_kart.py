"""Builds the House's karts, GAME.md 8.1b, in Blender and writes them out for the game.

    tools/make_kart_prints.py
    blender -b --factory-startup --python tools/make_kart.py [-- body ...]

Without a body named, builds them all. Every kart is one chassis under a body of its own, so the
bodies are one family from the camera over the table and the game finds the same parts on each:
- the four wheels, where and how big they are, though a body may give them a look of its own;
- the driver, its head where hats fit, and the steering wheel it holds;
- the cockpit it sits in, the bonnet ahead of it that every body's print puts the seat's roundel
  on, the tail the plate hangs on and the deck the flag's pole stands in;
- the player's color over the top of the body, which is what the camera sees.

A body is only its shell and its trim:
  tin          the lithographed tin wind-up racer, the first kart: a coke-bottle body with pods
               between the wheels, a rolled brass seam, brass lip, bumpers, lamps and pipes and
               the key on its tail, into assets/models/tin-kart/tin_kart.glb
  racer        the same racer as a clean painted toy: no seam, no key, chrome trim, and a small
               wing over its tail on chrome struts, painted with the body
  woodie       a turned wooden pull-along racer: a round body, dowel axles and bumpers, a turned
               ring round the cockpit, a wooden fin, wooden hubs on peg axles
  streamliner  an art-deco teardrop: skirts over the back wheels, a small fin, a chrome grille,
               spear and speed lines, whitewalls under chrome discs
  microcar     a chunky molded micro-car: a tall rounded shell, wider than the wheels' inner faces
               and arched over them, on a dark molded base that makes its bumpers, a wing, a
               sticker livery, fat tires on gold-capped hubs
each but the tin into assets/models/karts/<body>.glb.

Every one keeps to what the game asks of a kart model (KartVisuals, KartStickers, KartDress):
- it drives toward glTF +Z, Blender's -Y, and stands on z = 0, a kart's length and width once
  KartVisuals.MODEL_SCALE is applied;
- the body is the root mesh and the first one, so stickers find it, and it is painted by the game,
  with a second UV that lays the body's print over the paint from above;
- wheels are named wheel-front-* and wheel-back-*, their origins on the axle at their inner face,
  spun about their own x;
- the driver is "character", left as it is printed; its helmet is "cap", painted with the body;
- every trim part is named trim-*, left in its own brass, chrome, wood or plastic; trim-key turns
  about its own up;
- the driver's helmet is where KartDress fits a hat to it: 0.27 round its middle at
  (0, -0.045, 0.93) and its crown at 1.21, a hat being cut to the helmet 0.386 round that sat
  over the first driver's head and worn KartDress.HAT_SCALE of that.
"""

import bmesh
import bpy
import math
import os
import sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TIN = os.path.join(ROOT, "assets", "models", "tin-kart")
KARTS = os.path.join(ROOT, "assets", "models", "karts")

# The chassis. Wheels: y of the axle, radius, width; the inner face stands this far out from the
# middle.
WHEELS = [("front", -0.42, 0.19, 0.16), ("back", 0.36, 0.22, 0.20)]
WHEEL_INNER = 0.29
# The driver's head: its middle, how big it is, and how much taller than it is round; the
# helmet over it this much bigger, down to its brow at the front, its jaw past the face's sides
# and the nape at the back, as angles from the head's middle, the face that wide either side; and
# the neck under it, the middle, radius and length.
HEAD = Vector((0.0, -0.045, 0.93))
HEAD_RADIUS = 0.25
HEAD_TALL = 1.04
HELMET = 1.08
HELMET_BROW = math.radians(12)
HELMET_JAW = math.radians(-28)
HELMET_NAPE = math.radians(-40)
HELMET_FACE = math.radians(64)
# The suit the driver sits in, turned: radius and height, from its seat up its shoulders to the
# neck, the last three the neck's, in skin, up into the head.
SUIT = [(0.19, 0.30), (0.185, 0.46), (0.165, 0.565), (0.125, 0.625), (0.075, 0.655),
        (0.066, 0.67), (0.066, 0.74)]
# The cockpit: the middle of its opening and how far it reaches across and along.
COCKPIT = Vector((0.0, 0.05))
COCKPIT_RADII = (0.24, 0.29)
# Where the game hangs a kart's plate and stands its flag, here in the model's own measures:
# KartVisuals.PLATE_AT and KartDress.FLAG brought back through MODEL_LIFT and MODEL_SCALE. A body
# ends its tail just ahead of the plate, and has a deck where the pole goes in.
PLATE = Vector((0.0, 0.616, 0.228))
FLAG = Vector((0.0, 0.446))
# The racer's wing over its tail: the middle of it and how far out it reaches either side.
SPOILER = Vector((0.0, 0.562, 0.655))
SPOILER_SPAN = 0.3
# How far out from the middle a body arching over its wheels stands its flank in beside them.
ARCH_INNER = 0.272
SEGMENTS = 48
# How many sides a painted body's shell has round, and its cockpit's well and lip.
SHELL_SEGMENTS = 36
COCKPIT_SEGMENTS = 32

# The tin kart's sections from the nose (-y) to the tail: y, half width, z of its foot and its
# top, and how square the top and the foot are. Narrow over the wheels and wide in the pods
# between.
STATIONS = [
    (-0.83, 0.10, 0.20, 0.27, 2.0, 2.4),
    (-0.78, 0.18, 0.15, 0.31, 2.2, 3.0),
    (-0.66, 0.235, 0.12, 0.34, 2.4, 3.5),
    (-0.50, 0.25, 0.11, 0.37, 2.6, 4.0),
    (-0.32, 0.265, 0.11, 0.40, 2.6, 4.0),
    (-0.22, 0.37, 0.11, 0.39, 3.0, 4.0),
    (-0.10, 0.425, 0.11, 0.40, 3.2, 4.0),
    (0.04, 0.43, 0.11, 0.41, 3.2, 4.0),
    (0.12, 0.37, 0.11, 0.45, 3.0, 4.0),
    (0.19, 0.28, 0.11, 0.50, 2.8, 4.0),
    (0.40, 0.28, 0.12, 0.55, 2.8, 4.0),
    (0.55, 0.265, 0.14, 0.55, 2.6, 3.5),
    (0.62, 0.20, 0.18, 0.50, 2.4, 3.0),
]
KEY_AT = Vector((0.0, 0.56, 0.50))


def srgb(c):
    return tuple(((v / 255.0 + 0.055) / 1.055) ** 2.4 if v / 255.0 > 0.04045 else v / 255.0 / 12.92
                 for v in c) + (1.0,)


def material(name, color, rough=0.5, metal=0.0, image=None, folder=KARTS):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = srgb(color)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if image:
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(os.path.join(folder, image))
        m.node_tree.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    return m


def obj(name, bm, mats, parent=None, loc=(0, 0, 0), smooth=True, recalc=True):
    if recalc:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    if parent is not None:
        o.parent = parent
    return o


def section(bm, y, hw, zb, zt, nt, nb, segs=SEGMENTS, xc=0.0, even=False):
    """A ring of [segs] round a superellipse [hw] across and from [zb] to [zt], its top as square
    as [nt] and its foot as [nb]. [even] spaces the ring evenly along each quarter of it, rather
    than by the angle, which leaves a square section's flanks a few long facets."""
    zc, hz = (zb + zt) / 2, (zt - zb) / 2

    def at(t):
        c, s = math.cos(t), math.sin(t)
        n = nt if s >= 0 else nb
        return (hw * math.copysign(abs(c) ** (2 / n), c),
                zc + hz * math.copysign(abs(s) ** (2 / n), s))

    if even and segs % 4 == 0:
        points = []
        for q in range(4):
            fine = [at(math.pi / 2 * (q + i / 64)) for i in range(65)]
            run = [0.0]
            for a, b in zip(fine, fine[1:]):
                run.append(run[-1] + math.dist(a, b))
            for k in range(segs // 4):
                want = run[-1] * k / (segs // 4)
                i = next(j for j in range(1, 65) if run[j] >= want)
                f = (want - run[i - 1]) / max(run[i] - run[i - 1], 1e-9)
                points.append(tuple(a + (b - a) * f for a, b in zip(fine[i - 1], fine[i])))
    else:
        points = [at(2 * math.pi * k / segs) for k in range(segs)]
    return [bm.verts.new((xc + x if xc else x, y, z)) for x, z in points]


def top_uvs(bm, layer, flip=True):
    for f in bm.faces:
        for loop in f.loops:
            co = loop.vert.co
            u = co.x + 0.5
            v = (co.y + 0.9) / 1.8
            loop[layer].uv = (u, 1.0 - v if flip else v)


def tube(bm, points, radius, closed=False, sides=8, flat=1.0):
    """A rolled bead along points, as quads; [flat] squashes it top to bottom."""
    rings = []
    n = len(points)
    for i, p in enumerate(points):
        a = Vector(points[(i - 1) % n] if closed or i > 0 else points[i])
        b = Vector(points[(i + 1) % n] if closed or i < n - 1 else points[i])
        t = (b - a).normalized()
        side = t.cross(Vector((0, 0, 1)))
        if side.length < 1e-4:
            side = t.cross(Vector((1, 0, 0)))
        side.normalize()
        up = side.cross(t).normalized()
        ring = []
        for k in range(sides):
            ang = 2 * math.pi * k / sides
            if flat == 1.0:
                off = (side * math.cos(ang) + up * math.sin(ang)) * radius
            else:
                off = side * math.cos(ang) * radius + up * math.sin(ang) * radius * flat
            ring.append(bm.verts.new(Vector(p) + off))
        rings.append(ring)
    pairs = list(zip(rings, rings[1:]))
    if closed:
        pairs.append((rings[-1], rings[0]))
    for a, b in pairs:
        for k in range(sides):
            bm.faces.new((a[k], a[(k + 1) % sides], b[(k + 1) % sides], b[k]))
    if not closed:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])


def ellipsoid(bm, center, radii, segs=24, rings=12):
    geom = bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0)
    for v in geom["verts"]:
        v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2])) + Vector(center)
    return geom


def cylinder(bm, center, radius, depth, axis="z", segs=16, radius2=None):
    geom = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=radius,
                                 radius2=radius if radius2 is None else radius2, depth=depth)
    for v in geom["verts"]:
        x, y, z = v.co
        if axis == "x":
            x, y, z = z, y, x
        elif axis == "y":
            x, y, z = x, z, y
        v.co = Vector((x, y, z)) + Vector(center)
    return geom


# Shells: lofts through sections, smoothed between them, closed at either end in a dome.


def smoothed(stations, steps):
    """The stations with [steps] more between each two, on a Catmull-Rom curve through them, so a
    shell runs smoothly from one to the next rather than in facets."""
    if steps <= 0:
        return list(stations)
    out = []
    n = len(stations)
    for i in range(n - 1):
        p0 = stations[max(i - 1, 0)]
        p1, p2 = stations[i], stations[i + 1]
        p3 = stations[min(i + 2, n - 1)]
        for k in range(steps + 1):
            t = k / (steps + 1)
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * (2 * b + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t2
                                    + (3 * b - a - 3 * c + d) * t3)
                             for a, b, c, d in zip(p0, p1, p2, p3)))
    out.append(stations[-1])
    return out


def loft(bm, stations, segs=SHELL_SEGMENTS, steps=2, nose=None, tail=None, xc=0.0):
    """A shell through [stations], closed at the nose and the tail by a fan to a point: [nose] and
    [tail] are how far past the end sections those points stand, or the ends are left flat."""
    rows = smoothed(stations, steps)
    rings = [section(bm, *s[:6], segs=segs, xc=xc, even=True) for s in rows]
    for a, b in zip(rings, rings[1:]):
        for k in range(segs):
            bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
    for ring, row, out, sign in ((rings[0], rows[0], nose, -1), (rings[-1], rows[-1], tail, 1)):
        if out is None:
            bm.faces.new(ring if sign > 0 else list(reversed(ring)))
            continue
        tip = bm.verts.new((xc, row[0] + sign * out, (row[2] + row[3]) / 2))
        for k in range(segs):
            pair = (ring[k], ring[(k + 1) % segs])
            bm.faces.new((pair[0], pair[1], tip) if sign > 0 else (pair[1], pair[0], tip))
    return rings


def fin(bm, rows):
    """A fin on the spine of the tail, from just behind the flag's pole: each row how far behind
    the pole, how thick, and the z of its foot, sunk in the body, and of its edge."""
    loft(bm, [(FLAG.y + d, hw, zb, zt, 2.0, 2.0) for d, hw, zb, zt in rows], segs=12, steps=2,
         nose=0.005, tail=0.005)


def wing(bm, span, at, chord, thick, kick=0.0, segs=12):
    """A wing across the kart, [span] out either side of [at], its middle: an airfoil [chord] long
    and [thick] at its round leading edge, thinning to the trailing edge, which is kicked up by
    [kick] radians, and its tips rounded in."""
    section = []
    for k in range(segs):
        t = 2 * math.pi * k / segs
        u = -math.cos(t) * chord / 2
        w = math.sin(t) * thick / 2 * (1.0 if u < 0 else 1.0 - 0.6 * (2 * u / chord))
        section.append((u * math.cos(kick) - w * math.sin(kick),
                        w * math.cos(kick) + u * math.sin(kick)))
    rings = []
    for x, f in ((-span, 0.7), (-span + thick * 0.6, 1.0), (span - thick * 0.6, 1.0),
                 (span, 0.7)):
        rings.append([bm.verts.new((at.x + x, at.y + u * f, at.z + w * f)) for u, w in section])
    for a, b in zip(rings, rings[1:]):
        for k in range(segs):
            bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])


def arched(bm, gap, swing=0.0, sides=24):
    """[bm], a closed shell wider than the wheels' inner faces, with a wheel arch cut out of it
    over each wheel and its flank stood in beside the tire: a drum round the axle, [gap] out from
    the tire, from ARCH_INNER out, and on a front wheel [swing] longer fore and aft for its
    steering. Returns the carved shell, its arches' edges kept sharp."""
    faces = len(bm.faces)
    shell = obj("arched", bm, [])
    cut = bmesh.new()
    drums = []
    for name, wy, r, _ in WHEELS:
        ry = r + gap + (swing if name == "front" else 0.0)
        rz = r + gap
        drums.append((wy, r, ry, rz))
        for sx in (-1, 1):
            geom = bmesh.ops.create_cone(cut, cap_ends=True, cap_tris=False, segments=sides,
                                         radius1=1.0, radius2=1.0, depth=1.0)
            for v in geom["verts"]:
                cx, cy, cz = v.co
                v.co = Vector((sx * (ARCH_INNER + 0.5 + cz), wy + cx * ry, r + cy * rz))
    cutter = obj("cutter", cut, [])
    carve = shell.modifiers.new("arches", "BOOLEAN")
    carve.operation = "DIFFERENCE"
    carve.solver = "EXACT"
    carve.object = cutter
    dg = bpy.context.evaluated_depsgraph_get()
    done = bmesh.new()
    evaluated = shell.evaluated_get(dg)
    done.from_mesh(evaluated.to_mesh())
    evaluated.to_mesh_clear()
    # the exact boolean gives up now and then on a shell it should cut, and hands back scraps
    if len(done.faces) < faces * 0.8:
        raise RuntimeError("the arches cut %d faces down to %d" % (faces, len(done.faces)))
    for o in (shell, cutter):
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.meshes.remove(me)
    # the arches' edges sharp, where the cut meets the shell, and nowhere else
    done.normal_update()
    for e in done.edges:
        if not e.is_manifold:
            continue
        mid = (e.verts[0].co + e.verts[1].co) / 2
        near = any(abs(mid.x) > ARCH_INNER - 0.01 and
                   math.hypot((mid.y - wy) / ry, (mid.z - r) / rz) < 1.08
                   for wy, r, ry, rz in drums)
        if near and e.calc_face_angle(0.0) > math.radians(40):
            e.smooth = False
    return done


def finish_body(bm, paint, uv_name="print"):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    uv0 = bm.loops.layers.uv.new("UVMap")
    uv1 = bm.loops.layers.uv.new(uv_name)
    top_uvs(bm, uv0)
    top_uvs(bm, uv1)
    return obj("body", bm, [paint])


def grain(o, scale=2.0):
    """UVs laid on each face of [o] from whichever side it faces most, so that the grain of a
    wood running along its picture runs along a dowel rather than round it."""
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.normal_update()
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        axis = max(range(3), key=lambda i: abs(n[i]))
        for loop in f.loops:
            co = loop.vert.co
            u, v = ((co.y, co.z), (co.x, co.z), (co.x, co.y))[axis]
            loop[uv].uv = (u * scale, v * scale)
    bm.to_mesh(o.data)
    bm.free()


class Surface:
    """The top of a body, to lay trim on: how high it is at a point seen from above."""

    def __init__(self, o):
        self.o = o
        dg = bpy.context.evaluated_depsgraph_get()
        self.tree = BVHTree.FromObject(o, dg)

    def z(self, x, y, below=3.0):
        hit = self.tree.ray_cast(Vector((x, y, below)), Vector((0, 0, -1)))
        return hit[0].z if hit[0] is not None else None

    def back(self, x, z):
        """How far back the body reaches at x and z, seen from behind."""
        hit = self.tree.ray_cast(Vector((x, 3.0, z)), Vector((0, -1, 0)))
        return hit[0].y if hit[0] is not None else None

    def side(self, y, z, sign=1):
        """How far out the body's flank is at y and z, on the left (1) or the right (-1)."""
        hit = self.tree.ray_cast(Vector((sign * 2.0, y, z)), Vector((-sign, 0, 0)))
        return abs(hit[0].x) if hit[0] is not None else None


# The chassis's parts.


def cockpit(root, surface, dark, lip_mat, lip=0.028, sides=8, lift=0.0, dish=0.05):
    """The dark well the driver sits in, laid on the body's top as it runs, and the lip round it."""
    rx, ry = COCKPIT_RADII
    n = COCKPIT_SEGMENTS
    rim = []
    for k in range(n):
        a = 2 * math.pi * k / n
        x, y = rx * math.cos(a), COCKPIT.y + ry * math.sin(a)
        rim.append((x, y, surface.z(x, y) + lift))
    bm = bmesh.new()
    rings = []
    for f in (1.0, 0.8, 0.55, 0.3):
        ring = []
        for k in range(n):
            a = 2 * math.pi * k / n
            x, y = rx * f * math.cos(a), COCKPIT.y + ry * f * math.sin(a)
            ring.append(bm.verts.new((x, y, surface.z(x, y) + lift + 0.004 - dish * (1 - f * f))))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for k in range(n):
            bm.faces.new((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]))
    bm.faces.new(rings[-1])
    obj("trim-well", bm, [dark], root)
    bm = bmesh.new()
    tube(bm, [(x, y, z + lip * 0.35) for x, y, z in rim], lip, closed=True, sides=sides)
    obj("trim-lip", bm, [lip_mat], root)


def steer(root, mat):
    """The steering wheel the driver holds."""
    bm = bmesh.new()
    ring = [(0.12 * math.cos(2 * math.pi * k / 20), -0.15 + 0.03 * math.sin(2 * math.pi * k / 20),
             0.58 + 0.1 * math.sin(2 * math.pi * k / 20)) for k in range(20)]
    tube(bm, ring, 0.018, closed=True, sides=6)
    obj("trim-steer", bm, [mat], root)


def tin_wheels(root, rubber, hub):
    for name, y, r, w in WHEELS:
        for side, sx in (("left", 1), ("right", -1)):
            bm = bmesh.new()
            # the tire from the inner face out, the axle along x
            cylinder(bm, (sx * w / 2, 0.0, 0.0), r, w, axis="x", segs=24)
            for f in bm.faces:
                f.material_index = 0
            # the printed hub on the outer face, a hair proud of the rubber
            cap = bmesh.ops.create_circle(bm, cap_ends=True, segments=24, radius=r * 0.74)
            uv = bm.loops.layers.uv.verify()
            for v in cap["verts"]:
                v.co = Vector((sx * (w + 0.004), v.co.x, v.co.y))
            for f in bm.faces:
                if all(v in cap["verts"] for v in f.verts):
                    f.material_index = 1
                    if sx < 0:
                        f.normal_flip()
                    for loop in f.loops:
                        loop[uv].uv = (0.5 + loop.vert.co.y / (2 * r * 0.74),
                                       0.5 + loop.vert.co.z / (2 * r * 0.74))
            obj("wheel-%s-%s" % (name, side), bm, [rubber, hub], root, (sx * WHEEL_INNER, y, r))


def wheels(root, rubber, hub, cap=None, fillet=0.045, hub_share=0.72, recess=0.012,
           cap_shape=None, segs=24):
    """Turned wheels: a tire rounded over its shoulders, its printed hub set into the outer face,
    and whatever cap the body puts on the middle of that. [hub_share] of the radius is the hub."""
    for name, y, r, w in WHEELS:
        hr = r * hub_share
        f = min(fillet, w * 0.45)
        # the profile from the middle of the inner face round to the middle of the hub
        prof = [(0.0, 0.0), (0.0, r - f)]
        for k in (1, 2):
            t = math.pi / 2 * k / 3
            prof.append((f - f * math.cos(t), r - f + f * math.sin(t)))
        prof += [(f, r), (w - f, r)]
        for k in (1, 2):
            t = math.pi / 2 * k / 3
            prof.append((w - f + f * math.sin(t), r - f + f * math.cos(t)))
        prof += [(w, r - f), (w, hr), (w - recess, hr), (w - recess, 0.0)]
        hub_from = len(prof) - 2
        for side, sx in (("left", 1), ("right", -1)):
            bm = bmesh.new()
            uv = bm.loops.layers.uv.verify()
            rings = []
            for i, (a, rad) in enumerate(prof):
                if rad == 0.0:
                    rings.append([bm.verts.new((sx * a, 0.0, 0.0))])
                    continue
                rings.append([bm.verts.new((sx * a, rad * math.cos(2 * math.pi * k / segs),
                                            rad * math.sin(2 * math.pi * k / segs)))
                              for k in range(segs)])
            for i, (a, b) in enumerate(zip(rings, rings[1:])):
                for k in range(segs):
                    k2 = (k + 1) % segs
                    if len(a) == 1:
                        face = bm.faces.new((a[0], b[k2], b[k]))
                    elif len(b) == 1:
                        face = bm.faces.new((a[k], a[k2], b[0]))
                    else:
                        face = bm.faces.new((a[k], a[k2], b[k2], b[k]))
                    face.material_index = 1 if i >= hub_from else 0
                    if face.material_index == 1:
                        for loop in face.loops:
                            co = loop.vert.co
                            loop[uv].uv = (0.5 + sx * co.y / (2 * hr), 0.5 + co.z / (2 * hr))
            if cap_shape is not None:
                tire = set(bm.faces)
                cap_shape(bm, sx, w - recess, r)
                for face in bm.faces:
                    if face not in tire:
                        face.material_index = 2
            mats = [rubber, hub] + ([cap] if cap is not None else [])
            obj("wheel-%s-%s" % (name, side), bm, mats, root, (sx * WHEEL_INNER, y, r))


def driver(root, suit, face, paint):
    """The driver: a suit sat in the cockpit with its arms out to the wheel, a neck, and a head
    with its face printed on it under an open-faced helmet painted with the body, which is what
    the camera over the table sees of them."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.verify()
    # the body: a suit turned round, its shoulders rounded in to the neck, and the arms out to the
    # wheel; the neck is skin, from the print's chin
    rings = []
    for i, (r, z) in enumerate(SUIT):
        y = 0.03 if i < len(SUIT) - 3 else HEAD.y + 0.035
        rings.append([bm.verts.new((r * math.cos(2 * math.pi * k / 12),
                                    y + r * math.sin(2 * math.pi * k / 12), z))
                      for k in range(12)])
    for i, (a, b) in enumerate(zip(rings, rings[1:])):
        for k in range(12):
            band = bm.faces.new((a[k], a[(k + 1) % 12], b[(k + 1) % 12], b[k]))
            band.material_index = 1 if i >= len(SUIT) - 3 else 0
            for loop in band.loops:
                loop[uv].uv = (0.5, 0.06)
    bm.faces.new(list(reversed(rings[0]))).material_index = 0
    for sx in (-1, 1):
        tube(bm, [(sx * 0.15, 0.0, 0.58), (sx * 0.18, -0.1, 0.55), (sx * 0.11, -0.15, 0.585)],
             0.045, sides=8)
    # the head, printed: u round it from the back, v from the crown down
    head = bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=12, radius=HEAD_RADIUS,
                                     calc_uvs=False)
    hv = set(head["verts"])
    for v in head["verts"]:
        v.co = Vector((v.co.x, v.co.y, v.co.z * HEAD_TALL)) + HEAD
    for f in bm.faces:
        if all(v in hv for v in f.verts):
            f.material_index = 1
            us = []
            for loop in f.loops:
                d = (loop.vert.co - HEAD).normalized()
                # facing -y (forward) is the middle of the print
                u = 0.5 + math.atan2(d.x, -d.y) / (2 * math.pi)
                v = 0.5 + math.asin(max(-1.0, min(1.0, d.z))) / math.pi
                us.append(u)
                loop[uv].uv = (u, v)
            # mend the seam at the back, where u wraps
            if max(us) - min(us) > 0.5:
                for loop in f.loops:
                    if loop[uv].uv.x < 0.5:
                        loop[uv].uv.x += 1.0
    o = obj("character", bm, [suit, face], root)
    helmet(root, paint)
    return o


def helmet_edge(turn):
    """How far up or down the head the helmet comes, as an angle from the head's middle, [turn]
    round from the front: over the brow, down past the cheeks and round the back of the neck."""
    a = abs(math.atan2(math.sin(turn), math.cos(turn)))
    if a <= HELMET_FACE:
        return HELMET_BROW + (HELMET_JAW - HELMET_BROW) * (a / HELMET_FACE) ** 4
    t = (a - HELMET_FACE) / (math.pi - HELMET_FACE)
    return HELMET_JAW + (HELMET_NAPE - HELMET_JAW) * t * t


def helmet(root, paint):
    """The open-faced helmet over the head, painted with the body: a dome a little out from the
    head, down to its edge (helmet_edge), and a lip rolled in under the edge to the head, so the
    shell has a thickness rather than a blade's edge. Named "cap", the name the game paints."""
    bm = bmesh.new()
    rh = HEAD_RADIUS * HELMET
    n, rows = 24, 8
    top = bm.verts.new(HEAD + Vector((0.0, 0.0, rh * HEAD_TALL)))
    columns = []
    for k in range(n):
        turn = 2 * math.pi * k / n
        low = helmet_edge(turn)
        col = []
        for j in range(1, rows + 1):
            e = math.pi / 2 - (math.pi / 2 - low) * j / rows
            d = Vector((math.sin(turn) * math.cos(e), -math.cos(turn) * math.cos(e),
                        math.sin(e) * HEAD_TALL))
            col.append(bm.verts.new(HEAD + d * rh))
        columns.append(col)
    for k in range(n):
        a, b = columns[k], columns[(k + 1) % n]
        bm.faces.new((top, a[0], b[0]))
        for j in range(rows - 1):
            bm.faces.new((a[j], a[j + 1], b[j + 1], b[j]))
    # the lip: from the shell's edge in to the head, on vertices of its own so it shades apart
    outer = [bm.verts.new(c[-1].co) for c in columns]
    inner = [bm.verts.new(HEAD + (c[-1].co - HEAD) * (0.985 / HELMET)) for c in columns]
    for k in range(n):
        k2 = (k + 1) % n
        bm.faces.new((outer[k2], outer[k], inner[k], inner[k2]))
    uv0 = bm.loops.layers.uv.new("UVMap")
    uv1 = bm.loops.layers.uv.new("litho")
    for f in bm.faces:
        for loop in f.loops:
            loop[uv0].uv = (0.02, 0.02)
            loop[uv1].uv = (0.02, 0.02)
    obj("cap", bm, [paint], root, recalc=False)


def common(paint):
    """The materials every body but the tin shares: the chassis's and the paint."""
    return {
        "paint": paint,
        "rubber": material("rubber", (30, 29, 33), 0.75),
        "dark": material("dark", (28, 26, 31), 0.5),
        "chrome": material("chrome", (208, 210, 216), 0.3, 0.75),
        "lamp": material("lamp", (250, 242, 220), 0.25),
        "suit": material("suit", (239, 227, 200), 0.55),
        "face": material("face", (255, 255, 255), 0.5, 0.0, "driver.png"),
    }


# The bodies.


def tin():
    paint = material("paint", (220, 60, 50), 0.55)
    rubber = material("rubber", (30, 29, 33), 0.8)
    hub = material("hub", (255, 255, 255), 0.45, 0.2, "hub.png", folder=TIN)
    brass = material("brass", (201, 150, 58), 0.42, 0.75)
    steel = material("steel", (176, 178, 184), 0.4, 0.7)
    dark = material("dark", (24, 22, 27), 0.6)
    suit = material("suit", (239, 227, 200), 0.55)
    face = material("face", (255, 255, 255), 0.5, 0.0, "driver.png")
    bm = bmesh.new()
    rings = [section(bm, *s) for s in STATIONS]
    for a, b in zip(rings, rings[1:]):
        for k in range(SEGMENTS):
            bm.faces.new((a[k], a[(k + 1) % SEGMENTS], b[(k + 1) % SEGMENTS], b[k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    root = finish_body(bm, paint, "litho")
    # the rolled seam along the widest of the body, where the two pressings meet
    bm = bmesh.new()
    pts = [(hw + 0.006, y, (zb + zt) / 2 - 0.015) for (y, hw, zb, zt, a, b) in STATIONS[1:-1]]
    loop = pts + [(-x, y, z) for (x, y, z) in reversed(pts)]
    tube(bm, loop, 0.022, closed=True)
    obj("trim-seam", bm, [brass], root)
    # the cockpit: a dark well and a brass lip rolled round it
    bm = bmesh.new()
    ellipsoid(bm, (0.0, 0.05, 0.43), (0.22, 0.27, 0.06))
    obj("trim-well", bm, [dark], root)
    bm = bmesh.new()
    lip = [(0.24 * math.cos(2 * math.pi * k / 40), 0.05 + 0.29 * math.sin(2 * math.pi * k / 40),
            0.445) for k in range(40)]
    tube(bm, lip, 0.028, closed=True)
    obj("trim-lip", bm, [brass], root)
    # bumpers, front and back, and the lamps and pipes
    bm = bmesh.new()
    arc = [math.radians(d) for d in range(20, 161, 10)]
    tube(bm, [(0.27 * math.cos(a), -0.66 - 0.2 * math.sin(a), 0.2) for a in arc], 0.03)
    tube(bm, [(0.3 * math.cos(a), 0.56 + 0.14 * math.sin(a), 0.24) for a in arc], 0.03)
    for sx in (-1, 1):
        cylinder(bm, (sx * 0.2, 0.66, 0.27), 0.035, 0.18, axis="y", segs=10)
    obj("trim-bumpers", bm, [steel], root)
    bm = bmesh.new()
    for sx in (-1, 1):
        ellipsoid(bm, (sx * 0.13, -0.72, 0.31), (0.05, 0.03, 0.04), 12, 6)
    obj("trim-lamps", bm, [material("lamp", (250, 240, 214), 0.3)], root)
    steer(root, dark)
    # the wind-up key on the tail: its origin at the foot of the shaft, so it turns about its up
    bm = bmesh.new()
    cylinder(bm, (0.0, 0.0, 0.09), 0.028, 0.18, segs=10)
    cylinder(bm, (0.0, 0.0, 0.20), 0.04, 0.08, segs=10)
    for sx in (-1, 1):
        ellipsoid(bm, (sx * 0.11, 0.0, 0.27), (0.1, 0.028, 0.08), 16, 8)
    obj("trim-key", bm, [brass], root, KEY_AT)
    tin_wheels(root, rubber, hub)
    driver(root, suit, face, paint)
    return os.path.join(TIN, "tin_kart.glb")


def racer():
    """The tin racer's coke-bottle line as a painted toy: smooth where the tin was faceted, with a
    rounded nose, no seam and no key, the tail squared off for the plate, and a small wing over
    the tail, kicked up behind, with a plate at either tip."""
    m = common(material("paint", (220, 60, 50), 0.5))
    stations = STATIONS[:-2] + [
        (0.50, 0.275, 0.13, 0.55, 2.7, 3.6),
        (0.585, 0.262, 0.145, 0.52, 2.8, 3.4),
        (0.608, 0.225, 0.17, 0.47, 2.6, 3.0),
    ]
    bm = bmesh.new()
    loft(bm, stations, nose=0.025, tail=0.006)
    # a small wing over the tail, behind the flag's pole and over the plate, painted with the
    # body so its stripes run on across it
    wing(bm, SPOILER_SPAN, SPOILER, 0.16, 0.045, math.radians(10))
    # and a plate at either tip of it, a little taller behind than ahead
    for sx in (-1, 1):
        y, z = SPOILER.y, SPOILER.z
        loft(bm, [(y - 0.085, 0.008, z - 0.02, z + 0.02, 3.0, 3.0),
                  (y - 0.04, 0.01, z - 0.045, z + 0.04, 3.0, 3.0),
                  (y + 0.04, 0.01, z - 0.05, z + 0.06, 3.0, 3.0),
                  (y + 0.09, 0.008, z - 0.04, z + 0.065, 3.0, 3.0)],
             segs=8, steps=0, nose=0.004, tail=0.003, xc=sx * (SPOILER_SPAN + 0.004))
    root = finish_body(bm, m["paint"])
    surface = Surface(root)
    cockpit(root, surface, m["dark"], m["chrome"], lip=0.026)
    bm = bmesh.new()
    arc = [math.radians(d) for d in range(16, 165, 16)]
    tube(bm, [(0.275 * math.cos(a), -0.66 - 0.205 * math.sin(a), 0.2) for a in arc], 0.028)
    # the wing's two struts, down from under it into the deck
    for sx in (-1, 1):
        x = sx * 0.13
        foot = surface.z(x, SPOILER.y, below=SPOILER.z - 0.03) - 0.02
        cylinder(bm, (x, SPOILER.y, (foot + SPOILER.z) / 2), 0.016, SPOILER.z - foot, segs=8)
    # side pipes along the foot of each pod, out behind the front wheel and in again at the back
    for sx in (-1, 1):
        pipe = [(sx * 0.345, -0.21, 0.2), (sx * 0.405, -0.15, 0.165), (sx * 0.44, -0.02, 0.15),
                (sx * 0.42, 0.10, 0.15)]
        tube(bm, pipe, 0.03, sides=10)
    obj("trim-chrome", bm, [m["chrome"]], root)
    bm = bmesh.new()
    for sx in (-1, 1):
        ellipsoid(bm, (sx * 0.13, -0.73, 0.305), (0.052, 0.032, 0.042), 12, 6)
    obj("trim-lamps", bm, [m["lamp"]], root)
    steer(root, m["dark"])
    hub = material("hub", (255, 255, 255), 0.4, 0.0, "hub_racer.png")
    wheels(root, m["rubber"], hub, fillet=0.045, hub_share=0.7)
    driver(root, m["suit"], m["face"], m["paint"])
    return os.path.join(KARTS, "racer.glb")


def woodie():
    """A wooden pull-along racer: a body turned round like a cigar, flattened a little on top for
    its paint, dowels for axles and bumpers, a turned ring round the cockpit, a wooden fin on its
    tail, a bead on its nose, and wooden hubs on the pegs of its axles."""
    m = common(material("paint", (205, 60, 48), 0.55))
    wood = material("wood", (222, 184, 132), 0.62, 0.0, "wood.png")
    stations = [
        (-0.855, 0.06, 0.22, 0.30, 2.0, 2.0),
        (-0.83, 0.13, 0.17, 0.35, 2.1, 2.0),
        (-0.78, 0.185, 0.135, 0.385, 2.2, 2.1),
        (-0.69, 0.225, 0.115, 0.41, 2.3, 2.2),
        (-0.56, 0.245, 0.105, 0.425, 2.3, 2.3),
        (-0.42, 0.255, 0.10, 0.435, 2.3, 2.3),
        (-0.24, 0.30, 0.10, 0.445, 2.4, 2.3),
        (-0.05, 0.335, 0.10, 0.455, 2.4, 2.3),
        (0.10, 0.32, 0.10, 0.465, 2.4, 2.3),
        (0.22, 0.28, 0.105, 0.48, 2.4, 2.3),
        (0.40, 0.268, 0.11, 0.485, 2.4, 2.3),
        (0.54, 0.262, 0.12, 0.47, 2.4, 2.3),
        (0.59, 0.25, 0.13, 0.45, 2.4, 2.3),
        (0.605, 0.225, 0.15, 0.42, 2.4, 2.3),
    ]
    bm = bmesh.new()
    loft(bm, stations, nose=0.012, tail=None)
    root = finish_body(bm, m["paint"])
    surface = Surface(root)
    cockpit(root, surface, m["dark"], wood, lip=0.04, sides=10, lift=-0.005)
    bm = bmesh.new()
    # the axles, dowels right across under the body to the wheels
    for _, y, r, w in WHEELS:
        cylinder(bm, (0.0, y, r), 0.034, 2 * WHEEL_INNER + 0.02, axis="x", segs=12)
    # a dowel bumper across the tail on turned knobs, just ahead of the plate
    back = PLATE.y - 0.051
    cylinder(bm, (0.0, back, 0.2), 0.042, 0.52, axis="x", segs=12)
    for sx in (-1, 1):
        ellipsoid(bm, (sx * 0.27, back, 0.2), (0.05, 0.048, 0.056), 14, 8)
    # the bead on the nose the string is tied to
    ellipsoid(bm, (0.0, -0.862, 0.255), (0.042, 0.04, 0.042), 14, 8)
    # the fin, a board on the spine behind the flag's pole, swept back, its edges rounded
    fin(bm, [(0.04, 0.006, 0.42, 0.47), (0.075, 0.018, 0.42, 0.515), (0.125, 0.02, 0.40, 0.565),
             (0.167, 0.018, 0.37, 0.585), (0.19, 0.01, 0.36, 0.56)])
    obj("trim-wood", bm, [wood], root)
    steer(root, wood)

    def peg(bm, sx, face, r):
        cylinder(bm, (sx * (face + 0.01), 0.0, 0.0), 0.04, 0.024, axis="x", segs=14)
        ellipsoid(bm, (sx * (face + 0.022), 0.0, 0.0), (0.012, 0.04, 0.04), 14, 6)

    hub = material("hub", (255, 255, 255), 0.6, 0.0, "hub_woodie.png")
    wheels(root, m["rubber"], hub, wood, fillet=0.05, hub_share=0.8, recess=0.006, cap_shape=peg)
    driver(root, m["suit"], m["face"], m["paint"])
    for o in root.children:
        if o.name in ("trim-lip", "trim-wood", "trim-steer"):
            grain(o)
    return os.path.join(KARTS, "woodie.glb")


def streamliner():
    """An art-deco teardrop: a round nose low between the front wheels, and behind them the body
    swelling out over the back wheels in skirts that hide all of them but the foot of the tire,
    up to a high rounded tail under a small fin; a chrome grille in the nose, a spear down it, and
    speed lines along the skirts."""
    m = common(material("paint", (200, 52, 46), 0.5))
    stations = [
        (-0.86, 0.06, 0.19, 0.25, 2.0, 2.0),
        (-0.835, 0.15, 0.145, 0.30, 2.1, 2.4),
        (-0.77, 0.215, 0.12, 0.34, 2.2, 2.8),
        (-0.66, 0.245, 0.11, 0.37, 2.3, 3.0),
        (-0.50, 0.255, 0.11, 0.39, 2.4, 3.2),
        (-0.34, 0.262, 0.11, 0.41, 2.5, 3.4),
        (-0.19, 0.30, 0.12, 0.43, 2.6, 3.6),
        (-0.08, 0.40, 0.15, 0.45, 2.8, 4.2),
        (0.03, 0.46, 0.19, 0.47, 3.0, 5.0),
        (0.14, 0.495, 0.215, 0.495, 3.0, 5.5),
        (0.34, 0.505, 0.225, 0.515, 3.0, 5.5),
        (0.49, 0.49, 0.22, 0.505, 2.9, 5.0),
        (0.56, 0.44, 0.205, 0.48, 2.7, 4.0),
        (0.59, 0.36, 0.195, 0.45, 2.5, 3.0),
        (0.602, 0.25, 0.20, 0.41, 2.3, 2.5),
    ]
    bm = bmesh.new()
    loft(bm, stations, nose=0.012, tail=0.004)
    # the fin on the spine, behind the flag's pole
    fin(bm, [(0.044, 0.006, 0.44, 0.52), (0.084, 0.018, 0.43, 0.61), (0.134, 0.02, 0.40, 0.70),
             (0.169, 0.016, 0.37, 0.73), (0.189, 0.008, 0.36, 0.68)])
    root = finish_body(bm, m["paint"])
    surface = Surface(root)
    cockpit(root, surface, m["dark"], m["chrome"], lip=0.026)
    bm = bmesh.new()
    # the grille: a chrome oval in the nose with bars across it
    gz, gy = 0.215, -0.858
    turns = [2 * math.pi * k / 24 for k in range(24)]
    ring = [(0.085 * math.cos(t), gy + 0.012 * abs(math.cos(t)), gz + 0.05 * math.sin(t))
            for t in turns]
    tube(bm, ring, 0.014, closed=True, sides=6)
    for k in range(-2, 3):
        z = gz + k * 0.018
        half = 0.085 * math.sqrt(max(0.0, 1 - (k * 0.018 / 0.05) ** 2))
        tube(bm, [(-half, gy + 0.004, z), (half, gy + 0.004, z)], 0.006, sides=4)
    # the spear down the nose, up to the roundel
    spear = []
    for k in range(9):
        y = -0.845 + k * (0.245 / 8)
        spear.append((0.0, y, surface.z(0.0, y) + 0.004))
    tube(bm, spear, 0.012, sides=6, flat=0.6)
    # three speed lines along each skirt
    by = WHEELS[1][1]
    for sx in (-1, 1):
        for k, z in enumerate((0.41, 0.37, 0.33)):
            line = []
            for i in range(7):
                y = by - 0.2 + k * 0.05 + i * (0.32 - k * 0.07) / 6
                x = surface.side(y, z, sx)
                line.append((sx * (x + 0.002), y, z))
            tube(bm, line, 0.008, sides=5)
    # the lamp rings, round the lamps on the nose
    lamps = []
    for sx in (-1, 1):
        x, y = sx * 0.16, -0.735
        z = surface.z(x, y) - 0.02
        lamps.append((x, y, z))
        ring = [(x + 0.05 * math.cos(2 * math.pi * k / 12), y - 0.03,
                 z + 0.05 * math.sin(2 * math.pi * k / 12)) for k in range(12)]
        tube(bm, ring, 0.011, closed=True, sides=6)
    obj("trim-chrome", bm, [m["chrome"]], root)
    bm = bmesh.new()
    for x, y, z in lamps:
        ellipsoid(bm, (x, y - 0.025, z), (0.046, 0.03, 0.046), 14, 8)
    obj("trim-lamps", bm, [m["lamp"]], root)
    steer(root, material("ivory", (240, 230, 205), 0.35))

    def moon(bm, sx, face, r):
        ellipsoid(bm, (sx * face, 0.0, 0.0), (0.022, r * 0.5, r * 0.5), 16, 6)

    hub = material("hub", (255, 255, 255), 0.35, 0.0, "hub_streamliner.png")
    wheels(root, m["rubber"], hub, m["chrome"], fillet=0.04, hub_share=0.86, recess=0.006,
           cap_shape=moon)
    driver(root, m["suit"], m["face"], m["paint"])
    return os.path.join(KARTS, "streamliner.glb")


def microcar():
    """A chunky molded micro-car: a tall shell in the racer's plan, blunt at both ends and wider
    than the wheels' inner faces, its wheel arches cut over them, pressed down onto a dark molded
    base that makes its bumpers, on fat tires, with a wing on two posts and its livery in
    stickers."""
    m = common(material("paint", (215, 58, 50), 0.45))
    plastic = material("plastic", (40, 37, 44), 0.42)
    stations = [
        (-0.775, 0.20, 0.20, 0.33, 3.0, 3.0),
        (-0.76, 0.26, 0.185, 0.39, 3.4, 3.4),
        (-0.72, 0.29, 0.18, 0.43, 3.8, 3.8),
        (-0.60, 0.305, 0.18, 0.455, 4.0, 4.0),
        (-0.42, 0.315, 0.18, 0.47, 4.0, 4.0),
        (-0.25, 0.40, 0.18, 0.475, 4.0, 4.0),
        (-0.12, 0.455, 0.18, 0.48, 4.2, 4.2),
        (0.03, 0.46, 0.18, 0.49, 4.2, 4.2),
        (0.12, 0.41, 0.18, 0.50, 4.0, 4.0),
        (0.19, 0.33, 0.18, 0.52, 4.0, 4.0),
        (0.40, 0.325, 0.18, 0.54, 4.0, 4.0),
        (0.52, 0.32, 0.185, 0.54, 4.0, 4.0),
        (0.575, 0.30, 0.19, 0.51, 3.6, 3.6),
        (0.598, 0.26, 0.20, 0.46, 3.0, 3.0),
    ]
    bm = bmesh.new()
    loft(bm, stations, nose=0.006, tail=0.004)
    root = finish_body(arched(bm, 0.025, 0.05), m["paint"])
    surface = Surface(root)
    cockpit(root, surface, m["dark"], plastic, lip=0.04, sides=10, lift=-0.004)
    bm = bmesh.new()
    # the molded base the shell is pressed onto, flared out into a bumper at either end
    base = [
        (-0.84, 0.19, 0.10, 0.20, 3.0, 3.0),
        (-0.825, 0.29, 0.09, 0.215, 4.0, 4.0),
        (-0.78, 0.33, 0.085, 0.22, 4.0, 4.0),
        (-0.70, 0.33, 0.085, 0.22, 4.0, 4.0),
        (-0.645, 0.30, 0.09, 0.215, 4.0, 4.0),
        (-0.42, 0.27, 0.09, 0.215, 4.0, 4.0),
        (-0.25, 0.42, 0.09, 0.215, 4.0, 4.0),
        (-0.12, 0.485, 0.09, 0.215, 4.0, 4.0),
        (0.03, 0.49, 0.09, 0.215, 4.0, 4.0),
        (0.12, 0.43, 0.09, 0.215, 4.0, 4.0),
        (0.19, 0.27, 0.09, 0.215, 4.0, 4.0),
        (0.55, 0.27, 0.09, 0.215, 4.0, 4.0),
        (0.585, 0.33, 0.09, 0.215, 4.0, 4.0),
        (0.60, 0.32, 0.10, 0.205, 3.0, 3.0),
    ]
    loft(bm, base, segs=24, steps=0, nose=0.004, tail=0.004)
    bm = arched(bm, 0.025, 0.05)
    # the wing on its two posts, behind the flag's pole
    for sx in (-1, 1):
        cylinder(bm, (sx * 0.15, 0.57, surface.z(sx * 0.15, 0.57) + 0.06), 0.022, 0.16, segs=10)
    wing = [(x, 0.57, 0.66) for x in (-0.3, -0.15, 0.0, 0.15, 0.3)]
    tube(bm, wing, 0.058, sides=12, flat=0.3)
    obj("trim-plastic", bm, [plastic], root)
    bm = bmesh.new()
    for sx in (-1, 1):
        ellipsoid(bm, (sx * 0.17, -0.75, 0.355), (0.06, 0.03, 0.05), 12, 6)
    obj("trim-lamps", bm, [m["lamp"]], root)
    steer(root, plastic)

    def boss(bm, sx, face, r):
        ellipsoid(bm, (sx * face, 0.0, 0.0), (0.03, r * 0.2, r * 0.2), 10, 4)

    hub = material("hub", (255, 255, 255), 0.4, 0.0, "hub_microcar.png")
    gold = material("gold", (214, 168, 70), 0.3, 0.85)
    wheels(root, m["rubber"], hub, gold, fillet=0.07, hub_share=0.66, recess=0.014,
           cap_shape=boss)
    driver(root, m["suit"], m["face"], m["paint"])
    return os.path.join(KARTS, "microcar.glb")


BODIES = {"tin": tin, "racer": racer, "woodie": woodie, "streamliner": streamliner,
          "microcar": microcar}


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for store in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for block in list(store):
            store.remove(block)


def main():
    names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(BODIES)
    os.makedirs(KARTS, exist_ok=True)
    for name in names:
        clear()
        out = BODIES[name]()
        tail = Surface(bpy.data.objects["body"])
        reach = max(tail.back(x, PLATE.z) or -1.0 for x in (-0.3, -0.15, 0.0, 0.15, 0.3))
        if name != "tin" and reach > PLATE.y:
            print("warning: %s reaches %.3f back, past the plate at %.3f" % (name, reach, PLATE.y))
        bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True,
                                  export_yup=True, export_texcoords=True, export_normals=True,
                                  export_materials="EXPORT")
        tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH"
                   for p in o.data.polygons)
        print("wrote", out, tris, "triangles")


main()
