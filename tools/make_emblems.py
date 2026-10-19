#!/usr/bin/env python3
"""Draws the rooms' emblems, GAME.md 8.1c: one thing from each room, flat, as a die-cut sticker
for the pause menu's corner, into assets/ui/emblems/<room id>.svg, and a map's own over its
room's where a map has one.

    tools/make_emblems.py [out dir]

Every sticker is flat inks under an ink keyline on a cream die-cut margin with a hard shadow, in
the House Print's inks, GAME.md 8.1a: the cream is the paper crowd's margin, 8.1b. The House's
chip is the emblem of a room with none of its own.
"""
import math
import os
import sys

INK = "#211F24"
PAPER = "#F2EAD6"
GOLD = "#F2C14E"
FOIL_HI = "#FFE39A"
FOIL_LO = "#C38D2B"
RED = "#E5483B"
STOCK = "#27252F"
KEY = 3.2  # keyline width
CUT = 13.0  # die-cut margin, as a stroke width (half of it shows)


def f(v):
    return ("%.2f" % v).rstrip("0").rstrip(".")


def pts(points):
    return " ".join("%s,%s" % (f(x), f(y)) for x, y in points)


def poly(points, fill, stroke=INK, width=KEY, extra=""):
    return '<polygon points="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round" %s/>' % (
        pts(points), fill, stroke, f(width), extra)


def circle(cx, cy, r, fill, stroke=INK, width=KEY, extra=""):
    return '<circle cx="%s" cy="%s" r="%s" fill="%s" stroke="%s" stroke-width="%s" %s/>' % (
        f(cx), f(cy), f(r), fill, stroke, f(width), extra)


def path(d, fill, stroke=INK, width=KEY, extra=""):
    return '<path d="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round" %s/>' % (
        d, fill, stroke, f(width), extra)


def sticker(name, cut_shapes, art, out_dir):
    """Writes [art] as a sticker: [cut_shapes], SVG elements with no fill or stroke of their own,
    are the outline the die follows, drawn as a cream margin round the art over its shadow."""
    def cut(color, dx=0.0, dy=0.0):
        return '<g transform="translate(%s %s)" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round">%s</g>' % (
            f(dx), f(dy), color, color, f(CUT), "".join(cut_shapes))
    svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
<g opacity="0.45">%s</g>
%s
%s
</svg>
""" % (cut(INK, 2.5, 3.5), cut(PAPER), art)
    with open(os.path.join(out_dir, name + ".svg"), "w") as fh:
        fh.write(svg)


def rotate(points, deg, cx=64.0, cy=64.0):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in points]


def chip(cx, cy, r, body, notch, ring, center):
    """A casino chip: body, eight notches round its rim, a ring and whatever is in the middle."""
    clip_id = "rim%d" % int(r * 10)
    notches = []
    for k in range(8):
        a = k * math.pi / 4
        w = 0.24 * r  # half the notch's width along the rim, in radians times r
        p = []
        for t in (-1, 1):
            p.append((cx + math.sin(a + t * w / r) * (r + 2), cy - math.cos(a + t * w / r) * (r + 2)))
        for t in (1, -1):
            p.append((cx + math.sin(a + t * w / r) * (r * 0.72), cy - math.cos(a + t * w / r) * (r * 0.72)))
        notches.append('<polygon points="%s" fill="%s"/>' % (pts(p), notch))
    return """<defs><clipPath id="%s"><circle cx="%s" cy="%s" r="%s"/></clipPath></defs>
%s
<g clip-path="url(#%s)">%s</g>
%s
%s
%s""" % (clip_id, f(cx), f(cy), f(r), circle(cx, cy, r, body, width=0), clip_id, "".join(notches),
         circle(cx, cy, r * 0.68, body, stroke=ring, width=3), center,
         circle(cx, cy, r, "none"))


def house(out):
    cx, cy, r = 64, 63, 46
    diamond = [(cx, cy - 16), (cx + 12, cy), (cx, cy + 16), (cx - 12, cy)]
    center = poly(diamond, GOLD, stroke=INK, width=2.4)
    art = chip(cx, cy, r, STOCK, PAPER, GOLD, center)
    sticker("house", ['<circle cx="64" cy="63" r="46"/>'], art, out)


def after_hours(out):
    cx, cy, r = 64, 63, 46
    cherry = "#A8232E"
    rays = []
    for k in range(16):
        a = k * math.pi / 8
        a0, a1 = a - 0.09, a + 0.09
        p = [(cx + math.sin(a0) * 8, cy - math.cos(a0) * 8),
             (cx + math.sin(a) * 27, cy - math.cos(a) * 27),
             (cx + math.sin(a1) * 8, cy - math.cos(a1) * 8)]
        rays.append('<polygon points="%s" fill="%s"/>' % (pts(p), GOLD if k % 2 == 0 else FOIL_LO))
    center = "".join(rays) + circle(cx, cy, 8, PAPER, width=2.4)
    art = chip(cx, cy, r, cherry, PAPER, GOLD, center)
    sticker("after_hours", ['<circle cx="64" cy="63" r="46"/>'], art, out)


def workbench(out):
    maple, dark, teal = "#E3B877", "#B9834A", "#2F8F83"
    body = "M 24 58 C 24 42, 104 42, 104 58 C 104 76, 78 94, 66 110 L 62 110 C 50 94, 24 76, 24 58 Z"
    stem = "M 56 18 L 72 18 Q 74 18 74 21 L 74 47 L 54 47 L 54 21 Q 54 18 56 18 Z"
    art = """<defs><clipPath id="top"><path d="%s"/></clipPath></defs>
%s
<g clip-path="url(#top)">
<path d="M 20 58 C 40 70, 88 70, 108 58 L 108 70 C 88 82, 40 82, 20 70 Z" fill="%s"/>
<path d="M 20 76 C 40 87, 88 87, 108 76 L 108 81 C 88 92, 40 92, 20 81 Z" fill="%s"/>
<path d="M 40 50 C 56 46, 72 46, 88 50" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round"/>
<path d="M 46 94 C 56 98, 72 98, 82 94" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round"/>
</g>
%s
%s
<ellipse cx="64" cy="47" rx="16" ry="4" fill="%s" stroke="%s" stroke-width="2.4"/>
<path d="M 59 22 L 59 44" stroke="%s" stroke-width="2.4" stroke-linecap="round" opacity="0.7"/>
""" % (body, path(body, maple, width=0), RED, teal, dark, dark, path(body, "none"), path(stem, dark),
       dark, INK, FOIL_HI)
    sticker("workbench", ['<path d="%s"/>' % body, '<path d="%s"/>' % stem], art, out)


def the_yard(out):
    yellow, shade = "#F5C518", "#D9A40E"
    dome = "M 26 84 C 26 40, 102 40, 102 84 Z"
    brim = "M 14 84 Q 14 78 20 78 L 108 78 Q 114 78 114 84 L 114 88 Q 114 96 106 96 L 22 96 Q 14 96 14 88 Z"
    art = """%s
<path d="M 56 46 Q 64 42 72 46 L 72 80 L 56 80 Z" fill="%s" stroke="%s" stroke-width="2.4" stroke-linejoin="round"/>
<path d="M 38 56 Q 42 50 48 48 L 48 80 L 38 80 Z" fill="%s" opacity="0.8"/>
%s
%s
<rect x="76" y="58" width="14" height="10" rx="2" fill="%s" stroke="%s" stroke-width="2"/>
<path d="M 34 60 Q 38 52 46 49" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round" opacity="0.8"/>
""" % (path(dome, yellow), shade, INK, shade, path(brim, yellow), path("M 20 86 L 108 86", "none", stroke=shade, width=2.4),
       PAPER, INK, "#FFF1A8")
    sticker("the_yard", ['<path d="%s"/>' % dome, '<path d="%s"/>' % brim], art, out)


def garage(out):
    chrome, chrome_dark = "#D9DDE3", "#9BA3AF"
    turn = -38
    shaft = rotate([(36, 57), (92, 57), (92, 71), (36, 71)], turn)
    grip = rotate([(46, 54.5), (78, 54.5), (78, 73.5), (46, 73.5)], turn)
    jaw = rotate([(88, 51), (103, 46), (113, 47), (121, 55), (122, 58), (108, 58), (108, 70), (122, 70),
                  (121, 73), (113, 81), (103, 82), (88, 77)], turn)
    ring_c = rotate([(25, 64)], turn)[0]
    shine = rotate([(40, 60), (88, 60)], turn)
    art = """%s
%s
%s
%s
<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round"/>
%s
%s
""" % (poly(shaft, chrome), poly(jaw, chrome), circle(ring_c[0], ring_c[1], 17, chrome),
       circle(ring_c[0], ring_c[1], 7.5, STOCK, width=2.4),
       f(shine[0][0]), f(shine[0][1]), f(shine[1][0]), f(shine[1][1]), poly(grip, RED),
       poly(rotate([(50, 58), (74, 58), (74, 61), (50, 61)], turn), "#F28A80", width=0))
    cut = ['<polygon points="%s"/>' % pts(shaft), '<polygon points="%s"/>' % pts(jaw),
           '<circle cx="%s" cy="%s" r="17"/>' % (f(ring_c[0]), f(ring_c[1])),
           '<polygon points="%s"/>' % pts(grip)]
    sticker("garage", cut, art, out)


def school(out):
    orange, white = "#F27A1A", "#F7F3EA"
    cone = [(55, 18), (73, 18), (96, 98), (32, 98)]
    base = "M 20 98 L 108 98 Q 112 98 112 102 L 112 106 Q 112 110 108 110 L 20 110 Q 16 110 16 106 L 16 102 Q 16 98 20 98 Z"
    art = """<defs><clipPath id="cone"><polygon points="%s"/></clipPath></defs>
%s
%s
<g clip-path="url(#cone)">
<rect x="20" y="40" width="88" height="13" fill="%s"/>
<rect x="20" y="66" width="88" height="13" fill="%s"/>
<polygon points="55,18 61,18 44,98 32,98" fill="#FFA45C" opacity="0.7"/>
</g>
%s
<rect x="52" y="14" width="24" height="6" rx="2" fill="%s" stroke="%s" stroke-width="2.4"/>
""" % (pts(cone), path(base, "#3A3A40"), poly(cone, orange, width=0), white, white, poly(cone, "none"),
       orange, INK)
    sticker("school", ['<polygon points="%s"/>' % pts(cone), '<path d="%s"/>' % base,
                       '<rect x="52" y="14" width="24" height="6"/>'], art, out)


def stitch(out):
    plum, plum_dark, thread = "#7A2E5C", "#5A1F43", "#F2D9A0"
    cx, cy = 62, 62
    holes = [(cx - 10, cy - 10), (cx + 10, cy - 10), (cx - 10, cy + 10), (cx + 10, cy + 10)]
    art = """%s
%s
%s
%s
<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="4.5" stroke-linecap="round"/>
<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="4.5" stroke-linecap="round"/>
<path d="M %s %s C 86 82, 96 96, 112 100" fill="none" stroke="%s" stroke-width="7.5" stroke-linecap="round"/>
<path d="M %s %s C 86 82, 96 96, 112 100" fill="none" stroke="%s" stroke-width="3.5" stroke-linecap="round"/>
""" % (circle(cx, cy, 42, plum), circle(cx, cy, 33, plum_dark, stroke="none", width=0),
       circle(cx, cy, 36, "none", stroke=thread, width=2.2, extra='stroke-dasharray="5 4"'),
       "".join(circle(x, y, 5, "#2A0F20", width=2) for x, y in holes),
       f(holes[0][0]), f(holes[0][1]), f(holes[3][0]), f(holes[3][1]), thread,
       f(holes[1][0]), f(holes[1][1]), f(holes[2][0]), f(holes[2][1]), thread,
       f(holes[3][0]), f(holes[3][1]), INK, f(holes[3][0]), f(holes[3][1]), thread)
    sticker("stitch", ['<circle cx="62" cy="62" r="42"/>',
                       '<path d="M 72 72 C 86 82, 96 96, 112 100" fill="none" stroke-width="18"/>'], art, out)


def pinball(out):
    rubber, rubber_dark = "#D8352A", "#9E2219"
    back = "M 18 92 A 46 16 0 0 1 110 92"
    front = "M 110 92 A 46 16 0 0 1 18 92"
    art = """<defs><radialGradient id="steel" cx="0.36" cy="0.32" r="0.75">
<stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9CED8"/>
<stop offset="0.8" stop-color="#6F7684"/><stop offset="1" stop-color="#4A505C"/></radialGradient></defs>
<path d="%s" fill="none" stroke="%s" stroke-width="16" stroke-linecap="round"/>
<path d="%s" fill="none" stroke="%s" stroke-width="10" stroke-linecap="round"/>
%s
<ellipse cx="52" cy="44" rx="9" ry="6" fill="#FFFFFF" opacity="0.9" transform="rotate(-30 52 44)"/>
<path d="%s" fill="none" stroke="%s" stroke-width="16" stroke-linecap="round"/>
<path d="%s" fill="none" stroke="%s" stroke-width="10" stroke-linecap="round"/>
<path d="M 30 100 A 40 12 0 0 0 98 100" fill="none" stroke="#F07A6E" stroke-width="2.4" stroke-linecap="round"/>
""" % (back, INK, back, rubber_dark, circle(64, 62, 34, "url(#steel)"), front, INK, front, rubber)
    sticker("pinball", ['<ellipse cx="64" cy="92" rx="46" ry="16" fill="none" stroke-width="30"/>',
                        '<circle cx="64" cy="62" r="34"/>'], art, out)


def playset(out):
    teal, teal_top, teal_dark, pip = "#1F6F78", "#3B98A0", "#14505A", PAPER
    L = 40.0
    w, h = math.cos(math.radians(30)) * L, 0.5 * L
    front = (64.0, 64.0)  # the top face's nearest corner, over the cube's nearest edge
    right = (front[0] + w, front[1] - h)
    back = (front[0], front[1] - L)
    left = (front[0] - w, front[1] - h)

    def down(p):
        return (p[0], p[1] + L)

    def pips(o, u, v, spots):
        out = []
        for s, t in spots:
            ring = []
            for k in range(16):
                a = k * math.tau / 16
                px, py = s + math.cos(a) * 0.1, t + math.sin(a) * 0.1
                ring.append((o[0] + u[0] * px + v[0] * py, o[1] + u[1] * px + v[1] * py))
            out.append('<polygon points="%s" fill="%s"/>' % (pts(ring), pip))
        return "".join(out)

    top_face = [left, back, right, front]
    left_face = [left, front, down(front), down(left)]
    right_face = [front, right, down(right), down(front)]
    to_front = (front[0] - left[0], front[1] - left[1])
    to_back = (back[0] - left[0], back[1] - left[1])
    to_right = (right[0] - front[0], right[1] - front[1])
    art = "\n".join([
        poly(left_face, teal), poly(right_face, teal_dark), poly(top_face, teal_top),
        pips(left, to_front, to_back, [(0.5, 0.5)]),
        pips(left, to_front, (0.0, L), [(0.25, 0.25), (0.75, 0.75), (0.25, 0.75), (0.75, 0.25),
                                         (0.5, 0.5)]),
        pips(front, to_right, (0.0, L), [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)]),
    ])
    hull = [left, back, right, down(right), down(front), down(left)]
    sticker("playset", ['<polygon points="%s"/>' % pts(hull)], art, out)


def waiting_room(out):
    """The waiting room's own: the House's service bell on the desk, ring for attention."""
    walnut, walnut_dark = "#7A4A2E", "#5A331E"
    base = "M 22 90 Q 22 86 26 86 L 102 86 Q 106 86 106 90 L 106 100 Q 106 106 100 106 L 28 106 Q 22 106 22 100 Z"
    dome = "M 26 87 A 38 40 0 0 1 102 87 Z"
    art = """<defs><radialGradient id="chrome" cx="0.35" cy="0.3" r="0.8">
<stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#D3D8E0"/>
<stop offset="0.85" stop-color="#7C8492"/><stop offset="1" stop-color="#5A616E"/></radialGradient></defs>
%s
%s
%s
<rect x="59" y="38" width="10" height="12" rx="2" fill="#9BA3AF" stroke="%s" stroke-width="2.4"/>
%s
<path d="M 30 84 L 98 84" stroke="#F4F6FA" stroke-width="3" stroke-linecap="round"/>
<ellipse cx="50" cy="62" rx="9" ry="6" fill="#FFFFFF" opacity="0.85" transform="rotate(-35 50 62)"/>
""" % (path(base, walnut), path("M 26 98 L 102 98", "none", stroke=walnut_dark, width=2.4),
       path(dome, "url(#chrome)"), INK, circle(64, 34, 8, "url(#chrome)"))
    sticker("waiting_room", ['<path d="%s"/>' % base, '<path d="%s"/>' % dome,
                             '<circle cx="64" cy="34" r="8"/>', '<rect x="59" y="38" width="10" height="12"/>'],
            art, out)


def high_limit(out):
    """High Limit's, the showdown's room: the House's pair, an ace of spades and an ace of hearts
    fanned out, which is what a tie is."""
    stock, navy = "#FBF7EE", "#2E3D63"

    def heart(cx, cy, s, fill):
        d = ("M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z" % (
            f(cx), f(cy + s * 0.9), f(cx - s * 1.25), f(cy + s * 0.05), f(cx - s * 0.7), f(cy - s * 0.95),
            f(cx), f(cy - s * 0.4), f(cx + s * 0.7), f(cy - s * 0.95), f(cx + s * 1.25), f(cy + s * 0.05),
            f(cx), f(cy + s * 0.9)))
        return path(d, fill, width=0)

    def spade(cx, cy, s, fill):
        d = ("M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z" % (
            f(cx), f(cy - s * 0.95), f(cx - s * 1.25), f(cy - s * 0.1), f(cx - s * 0.7), f(cy + s * 0.8),
            f(cx), f(cy + s * 0.3), f(cx + s * 0.7), f(cy + s * 0.8), f(cx + s * 1.25), f(cy - s * 0.1),
            f(cx), f(cy - s * 0.95)))
        stem = [(cx - s * 0.12, cy + s * 0.3), (cx + s * 0.12, cy + s * 0.3), (cx + s * 0.38, cy + s * 0.95),
                (cx - s * 0.38, cy + s * 0.95)]
        return path(d, fill, width=0) + poly(stem, fill, width=0)

    def card(cx, cy, turn, pips):
        rect = '<rect x="%s" y="%s" width="48" height="68" rx="6"/>' % (f(cx - 24), f(cy - 34))
        group = '<g transform="rotate(%s %s %s)">%s</g>' % (f(turn), f(cx), f(cy), "%s")
        face = '<rect x="%s" y="%s" width="48" height="68" rx="6" fill="%s" stroke="%s" stroke-width="%s"/>' % (
            f(cx - 24), f(cy - 34), stock, INK, f(KEY))
        frame = '<rect x="%s" y="%s" width="36" height="56" rx="3" fill="none" stroke="%s" stroke-width="2"/>' % (
            f(cx - 18), f(cy - 28), navy)
        return group % rect, group % (face + frame + pips(cx, cy))

    back_cut, back = card(43, 60, -13, lambda x, y: spade(x, y - 3, 15, INK))
    front_cut, front = card(83, 66, 9, lambda x, y: heart(x, y + 1, 16, RED))
    sticker("high_limit", [back_cut, front_cut], back + "\n" + front, out)


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "assets", "ui", "emblems")
    os.makedirs(out, exist_ok=True)
    for make in (house, after_hours, workbench, the_yard, garage, waiting_room, school, stitch, pinball,
                 playset, high_limit):
        make(out)
    print("wrote", len(os.listdir(out)), "emblems to", out)
