class_name IconShapes
extends RefCounted
## The shapes the few small pictures still drawn in code are made of: the road signs of the driving
## school, the arena's slot pads, the touch controls' and the like. The icons of GAME.md 8.3a are
## SVG drawings printed by [IconPress].
##
## Everything takes the canvas and a box, and everything else is a fraction of that box: (0, 0)
## is its top left corner, (1, 1) its bottom right, y downwards, and radii, spans and widths are
## fractions of its shorter side. Nothing is in pixels, which is what lets one recipe serve a
## card in the hand, a bigger one in the respawn pick and a slot in the HUD.

## How thick a drawn line is, as a fraction of the box.
const STROKE := 0.055


static func at(box: Rect2, x: float, y: float) -> Vector2:
	return box.position + Vector2(x * box.size.x, y * box.size.y)


static func span(box: Rect2, fraction: float) -> float:
	return fraction * minf(box.size.x, box.size.y)


static func width(box: Rect2) -> float:
	return maxf(span(box, STROKE), 1.5)


static func disc(on: CanvasItem, box: Rect2, x: float, y: float, r: float, ink: Color) -> void:
	on.draw_circle(at(box, x, y), span(box, r), ink)


static func ring(on: CanvasItem, box: Rect2, x: float, y: float, r: float, ink: Color) -> void:
	on.draw_arc(at(box, x, y), span(box, r), 0.0, TAU, 40, ink, width(box))


static func line(
	on: CanvasItem, box: Rect2, x1: float, y1: float, x2: float, y2: float, ink: Color
) -> void:
	on.draw_line(at(box, x1, y1), at(box, x2, y2), ink, width(box))


## A rounded bar, which is how every block, body and panel in the set is drawn.
static func bar(
	on: CanvasItem, box: Rect2, x: float, y: float, w: float, h: float, ink: Color
) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ink
	style.set_corner_radius_all(roundi(span(box, 0.1)))
	on.draw_style_box(style, Rect2(at(box, x, y), Vector2(w, h) * box.size))


## A crown in [param box], the one the kart with the bounty wears, GAME.md 3.6: three points with a
## ball on each over a band.
static func crown(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var points := PackedVector2Array()
	for corner: Vector2 in [
		Vector2(0.1, 0.3),
		Vector2(0.32, 0.54),
		Vector2(0.5, 0.18),
		Vector2(0.68, 0.54),
		Vector2(0.9, 0.3),
		Vector2(0.86, 0.72),
		Vector2(0.14, 0.72),
	]:
		points.append(at(box, corner.x, corner.y))
	on.draw_colored_polygon(points, ink)
	bar(on, box, 0.14, 0.76, 0.72, 0.12, ink)
	for tip: Vector2 in [Vector2(0.1, 0.27), Vector2(0.5, 0.15), Vector2(0.9, 0.27)]:
		disc(on, box, tip.x, tip.y, 0.08, ink)


## A driver license in [param box], GAME.md 9.4a, what the payout slip shows somebody's by, 10.8: a
## card of [param ink], wider than tall, its photo and two lines of writing cut out of it in
## [param cut], the color of whatever it is drawn on.
static func license(on: CanvasItem, box: Rect2, ink: Color, cut: Color) -> void:
	bar(on, box, 0.0, 0.16, 1.0, 0.68, ink)
	bar(on, box, 0.1, 0.3, 0.3, 0.4, cut)
	bar(on, box, 0.5, 0.34, 0.38, 0.08, cut)
	bar(on, box, 0.5, 0.52, 0.26, 0.08, cut)


## A solid triangle of [param span] across, pointing [param facing] degrees clockwise from up.
static func tri(
	on: CanvasItem, box: Rect2, x: float, y: float, span: float, facing: float, ink: Color
) -> void:
	var center := at(box, x, y)
	var reach := span(box, span) * 0.5
	var points := PackedVector2Array()
	for i: int in 3:
		var angle := deg_to_rad(facing + i * 120.0) - PI * 0.5
		points.append(center + Vector2(cos(angle), sin(angle)) * reach)
	on.draw_colored_polygon(points, ink)


## A heart, [param span] of the box from its middle to its edge: a life, see [Heart].
static func heart(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	var side := span(box, span) * 2.0
	var corner := at(box, x, y) - Vector2(side, side) * 0.5
	var points := PackedVector2Array()
	for point: Vector2 in Heart.unit_shape():
		points.append(corner + point * side)
	on.draw_colored_polygon(points, ink)
