"""Builds the tin kart, GAME.md 8.1b, in Blender and writes it out for the game.

    tools/make_kart_prints.py
    blender -b --factory-startup --python tools/make_kart.py

A lithographed tin wind-up racer: a body pressed in a coke-bottle line with side pods between the
wheels, a rolled seam where its two pressings meet, a brass lip round the cockpit, bumpers, lamps,
pipes, the wind-up key on the tail, pressed tin wheels with printed hubs in rubber tires, and a tin
driver with a printed face under a cap.

It keeps to what the game asks of a kart model (KartVisuals, KartStickers, KartDress):
- it drives toward glTF +Z, Blender's -Y, and stands on z = 0, a kart's length and width once
  KartVisuals.MODEL_SCALE is applied;
- the body is the root mesh and the first one, so stickers find it, and it is painted by the game;
- wheels are named wheel-front-* and wheel-back-*, their origins on the axle at their inner face,
  spun about their own x;
- the driver is "character", left as it is printed; the cap is painted with the body;
- every trim part is named trim-*, left in its own brass or steel; trim-key turns about its own up;
- the driver's head is where the stock model's was, so hats, the learner's block and the roof
  marker sit as before: a helmet 0.375 across the middle at (0, -0.054, 0.95).
"""

import bmesh
import bpy
import math
import os
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "models", "tin-kart")

# The body's sections from the nose (-y) to the tail: y, half width, z of its foot and its top,
# and how square the top and the foot are. Narrow over the wheels and wide in the pods between.
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
SEGMENTS = 48
# Wheels: y of the axle, radius, width; the inner face stands this far out from the middle.
WHEELS = [("front", -0.42, 0.19, 0.16), ("back", 0.36, 0.22, 0.20)]
WHEEL_INNER = 0.29
HEAD = Vector((0.0, -0.054, 0.95))
HEAD_RADIUS = 0.375
KEY_AT = Vector((0.0, 0.56, 0.50))


def srgb(c):
    return tuple(((v / 255.0 + 0.055) / 1.055) ** 2.4 if v / 255.0 > 0.04045 else v / 255.0 / 12.92 for v in c) + (1.0,)


def material(name, color, rough=0.5, metal=0.0, image=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = srgb(color)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if image:
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(os.path.join(OUT, image))
        m.node_tree.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    return m


def obj(name, bm, mats, parent=None, loc=(0, 0, 0), smooth=True):
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


def section(bm, y, hw, zb, zt, nt, nb, segs=SEGMENTS):
    zc, hz = (zb + zt) / 2, (zt - zb) / 2
    ring = []
    for k in range(segs):
        t = 2 * math.pi * k / segs
        c, s = math.cos(t), math.sin(t)
        n = nt if s >= 0 else nb
        x = hw * math.copysign(abs(c) ** (2 / n), c)
        z = zc + hz * math.copysign(abs(s) ** (2 / n), s)
        ring.append(bm.verts.new((x, y, z)))
    return ring


def top_uvs(bm, layer, flip=True):
    for f in bm.faces:
        for loop in f.loops:
            co = loop.vert.co
            u = co.x + 0.5
            v = (co.y + 0.9) / 1.8
            loop[layer].uv = (u, 1.0 - v if flip else v)


def body(paint):
    bm = bmesh.new()
    rings = [section(bm, *s) for s in STATIONS]
    for a, b in zip(rings, rings[1:]):
        for k in range(SEGMENTS):
            bm.faces.new((a[k], a[(k + 1) % SEGMENTS], b[(k + 1) % SEGMENTS], b[k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    uv0 = bm.loops.layers.uv.new("UVMap")
    uv1 = bm.loops.layers.uv.new("litho")
    top_uvs(bm, uv0)
    top_uvs(bm, uv1)
    return obj("body", bm, [paint])


def tube(bm, points, radius, closed=False, sides=8):
    """A rolled bead along points, as quads."""
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
            ring.append(bm.verts.new(Vector(p) + (side * math.cos(ang) + up * math.sin(ang)) * radius))
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


def trim(root, brass, steel, dark):
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
    lip = [(0.24 * math.cos(2 * math.pi * k / 40), 0.05 + 0.29 * math.sin(2 * math.pi * k / 40), 0.445)
           for k in range(40)]
    tube(bm, lip, 0.028, closed=True)
    obj("trim-lip", bm, [brass], root)
    # bumpers, front and back, and the lamps and pipes
    bm = bmesh.new()
    front = [(0.27 * math.cos(a), -0.66 - 0.2 * math.sin(a), 0.2) for a in [math.radians(d) for d in range(20, 161, 10)]]
    tube(bm, front, 0.03)
    back = [(0.3 * math.cos(a), 0.56 + 0.14 * math.sin(a), 0.24) for a in [math.radians(d) for d in range(20, 161, 10)]]
    tube(bm, back, 0.03)
    for sx in (-1, 1):
        cylinder(bm, (sx * 0.2, 0.66, 0.27), 0.035, 0.18, axis="y", segs=10)
    obj("trim-bumpers", bm, [steel], root)
    bm = bmesh.new()
    for sx in (-1, 1):
        ellipsoid(bm, (sx * 0.13, -0.72, 0.31), (0.05, 0.03, 0.04), 12, 6)
    obj("trim-lamps", bm, [material("lamp", (250, 240, 214), 0.3)], root)
    # the steering wheel the driver holds
    bm = bmesh.new()
    ring = [(0.12 * math.cos(2 * math.pi * k / 20), -0.15 + 0.03 * math.sin(2 * math.pi * k / 20),
             0.58 + 0.1 * math.sin(2 * math.pi * k / 20)) for k in range(20)]
    tube(bm, ring, 0.018, closed=True, sides=6)
    obj("trim-steer", bm, [dark], root)
    # the wind-up key on the tail: its origin at the foot of the shaft, so it turns about its up
    bm = bmesh.new()
    cylinder(bm, (0.0, 0.0, 0.09), 0.028, 0.18, segs=10)
    cylinder(bm, (0.0, 0.0, 0.20), 0.04, 0.08, segs=10)
    for sx in (-1, 1):
        ellipsoid(bm, (sx * 0.11, 0.0, 0.27), (0.1, 0.028, 0.08), 16, 8)
    obj("trim-key", bm, [brass], root, KEY_AT)


def wheels(root, rubber, hub):
    for name, y, r, w in WHEELS:
        for side, sx in (("left", 1), ("right", -1)):
            bm = bmesh.new()
            # the tire from the inner face out, the axle along x
            geom = cylinder(bm, (sx * w / 2, 0.0, 0.0), r, w, axis="x", segs=24)
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
                        loop[uv].uv = (0.5 + loop.vert.co.y / (2 * r * 0.74), 0.5 + loop.vert.co.z / (2 * r * 0.74))
            obj("wheel-%s-%s" % (name, side), bm, [rubber, hub], root, (sx * WHEEL_INNER, y, r))


def driver(root, suit, face, paint):
    bm = bmesh.new()
    uv = bm.loops.layers.uv.verify()
    # the body: a tapered tin torso and the arms out to the wheel
    cylinder(bm, (0.0, 0.03, 0.50), 0.2, 0.36, segs=20, radius2=0.15)
    for sx in (-1, 1):
        tube(bm, [(sx * 0.16, 0.0, 0.62), (sx * 0.19, -0.1, 0.58), (sx * 0.11, -0.15, 0.6)], 0.05, sides=8)
    for f in bm.faces:
        f.material_index = 0
    # the head, printed: u round it from the back, v from the crown down
    head = bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=16, radius=HEAD_RADIUS, calc_uvs=False)
    hv = set(head["verts"])
    for v in head["verts"]:
        v.co += HEAD
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
    # the cap over the crown, painted with the body, and its peak
    bm = bmesh.new()
    cap = bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=16, radius=HEAD_RADIUS * 1.03)
    for v in list(cap["verts"]):
        v.co += HEAD
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < HEAD.z + HEAD_RADIUS * 0.28], context="VERTS")
    rim = [(HEAD.x + HEAD_RADIUS * 0.99 * math.cos(2 * math.pi * k / 32),
            HEAD.y + HEAD_RADIUS * 0.99 * math.sin(2 * math.pi * k / 32), HEAD.z + HEAD_RADIUS * 0.27) for k in range(32)]
    tube(bm, rim, 0.025, closed=True, sides=6)
    uv0 = bm.loops.layers.uv.new("UVMap")
    uv1 = bm.loops.layers.uv.new("litho")
    for f in bm.faces:
        for loop in f.loops:
            loop[uv0].uv = (0.02, 0.02)
            loop[uv1].uv = (0.02, 0.02)
    obj("cap", bm, [paint], root)
    return o


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    paint = material("paint", (220, 60, 50), 0.55)
    rubber = material("rubber", (30, 29, 33), 0.8)
    hub = material("hub", (255, 255, 255), 0.45, 0.2, "hub.png")
    brass = material("brass", (201, 150, 58), 0.42, 0.75)
    steel = material("steel", (176, 178, 184), 0.4, 0.7)
    dark = material("dark", (24, 22, 27), 0.6)
    suit = material("suit", (239, 227, 200), 0.55)
    face = material("face", (255, 255, 255), 0.5, 0.0, "driver.png")
    root = body(paint)
    trim(root, brass, steel, dark)
    wheels(root, rubber, hub)
    driver(root, suit, face, paint)
    out = os.path.join(OUT, "tin_kart.glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True, export_yup=True,
                              export_texcoords=True, export_normals=True, export_materials="EXPORT")
    print("wrote", out)


main()
