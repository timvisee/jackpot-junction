"""The Steam Controller's two views for the gamepad's blueprint, GAME.md 8.3b, out of Valve's
reference drawing of it, see tools/steam_controller_art: its front off the drawing's first sheet,
and its top off the second, turned over so its front faces the front view as the Steam Deck's is.

Each sheet comes in as pdftocairo writes it, one path an outline. An engineering drawing's notes,
its measurements, leaders, keep-out boxes and words, are told from the controller by their pen:
the controller is drawn in a 1.44 point black line with its finer lines in 0.36 point gray, while
the notes are 0.36 point black lines, dash-dotted boxes, filled arrowheads and glyphs. What is kept
is inked in white, as Xelu's pads and the Deck's are, so the blueprint prints it in its own ink; its
lines a little heavier, to be read at the size it is drawn, its fine lines fainter. A line wholly
outside a view is left out of it.

python3 tools/steam_controller_svg.py <first sheet.svg> <second sheet.svg> <into folder>
"""

import re
import sys
import xml.etree.ElementTree as ET

SVG = "http://www.w3.org/2000/svg"
# Each view: the sheet it is on, the part of the sheet it takes in points, both views as wide and
# centered on the controller, and whether it is turned over. The top view stops short of the
# sticks standing up from the face, which the front view shows.
VIEWS = {
    "front": (0, (454.5, 502.0, 920.0, 647.0), False),
    "top": (1, (629.5, 322.0, 920.0, 335.0), True),
}
# The pens: the controller's line and its fine lines, as drawn, and as inked.
LINE, FINE = "1.44", "0.36"
INK_LINE, INK_FINE, FINE_OPACITY = "2", "0.8", "0.5"


def within(path: ET.Element, part: tuple[float, float, float, float]) -> bool:
    """Whether any point [path] runs through, a curve's handles among them, is within [part] of the
    sheet; pdftocairo writes every path's points as pairs after M, L or C, with a matrix to the
    sheet, and a path written otherwise is kept."""
    matrix = re.fullmatch(r"matrix\(([^)]*)\)", path.get("transform", "matrix(1, 0, 0, 1, 0, 0)"))
    data = path.get("d", "")
    if matrix is None or re.search(r"[^MLCZ0-9eE.,\s+-]", data):
        return True
    a, b, c, d, e, f = (float(n) for n in matrix.group(1).split(","))
    numbers = [float(n) for n in re.findall(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?", data)]
    x, y, wide, tall = part
    for u, v in zip(numbers[0::2], numbers[1::2]):
        px, py = a * u + c * v + e, b * u + d * v + f
        if x - 2.0 <= px <= x + wide + 2.0 and y - 2.0 <= py <= y + tall + 2.0:
            return True
    return False


def inked(sheet: ET.Element, part: tuple[float, float, float, float]) -> list[ET.Element]:
    """The controller's lines off [sheet] within [part] of it, inked, its notes left behind."""
    kept = []
    for path in sheet.findall(f"{{{SVG}}}path"):
        if path.get("fill") != "none" or path.get("stroke-dasharray"):
            continue
        if not within(path, part):
            continue
        width = path.get("stroke-width")
        black = path.get("stroke") == "rgb(0%, 0%, 0%)"
        if width == LINE:
            path.set("stroke-width", INK_LINE)
        elif width == FINE and not black:
            path.set("stroke-width", INK_FINE)
            path.set("stroke-opacity", FINE_OPACITY)
        else:
            continue
        path.set("stroke", "#ffffff")
        path.set("stroke-linecap", "round")
        path.set("stroke-linejoin", "round")
        kept.append(path)
    return kept


def main() -> None:
    sheets = [ET.parse(path).getroot() for path in sys.argv[1:3]]
    into = sys.argv[3]
    ET.register_namespace("", SVG)
    for name, (sheet, part, turned) in VIEWS.items():
        x, y, wide, tall = part
        view = ET.Element(
            f"{{{SVG}}}svg",
            {
                "width": f"{wide:g}",
                "height": f"{tall:g}",
                "viewBox": f"{x:g} {y:g} {wide:g} {tall:g}",
            },
        )
        group = ET.SubElement(view, f"{{{SVG}}}g", {"fill": "none"})
        if turned:
            group.set("transform", f"rotate(180 {x + wide / 2:g} {y + tall / 2:g})")
        lines = inked(sheets[sheet], part)
        if not lines:
            sys.exit(f"Nothing of the controller found on sheet {sheet + 1} of Valve's drawing")
        group.extend(lines)
        ET.ElementTree(view).write(f"{into}/{name}.svg", encoding="unicode")


if __name__ == "__main__":
    main()
