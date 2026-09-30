class_name IconShapes
extends RefCounted
## The shapes every icon in the game is drawn out of, GAME.md 8.3a: the joker pictures and the
## power-up pictures both, so the two sets look like one hand drew them.
##
## Everything takes the canvas and a box, and everything else is a fraction of that box: (0, 0)
## is its top left corner, (1, 1) its bottom right, y downwards, and radii, spans and widths are
## fractions of its shorter side. Nothing is in pixels, which is what lets one recipe serve a
## card in the hand, a bigger one in the respawn pick and a slot in the HUD.

## How thick a drawn line is, as a fraction of the box, and the faintness of the detail that sits
## behind the subject of a picture.
const STROKE := 0.055
const FAINT := 0.4
## How big a pip is, for the pictures made of them.
const PIP := 0.055


## The dimmer of the two colors a picture is drawn in: whatever the subject sits on, in or
## behind.
static func behind(ink: Color) -> Color:
	return Color(ink.r, ink.g, ink.b, ink.a * FAINT)


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


static func arc(
	on: CanvasItem, box: Rect2, x: float, y: float, r: float, from: float, to: float, ink: Color
) -> void:
	on.draw_arc(at(box, x, y), span(box, r), deg_to_rad(from), deg_to_rad(to), 32, ink, width(box))


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


## A flame: a teardrop standing on [param x], [param y] with its tip [param span] away, blowing
## [param turn] degrees off straight up, so the ones out of an exhaust can lie on their side.
static func flame(
	on: CanvasItem, box: Rect2, x: float, y: float, span: float, turn: float, ink: Color
) -> void:
	var foot := at(box, x, y)
	var reach := span(box, span)
	var angle := deg_to_rad(turn)
	var out := Vector2(sin(angle), -cos(angle))
	var side := Vector2(-out.y, out.x)
	var outline: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(0.46, 0.2),
		Vector2(0.42, 0.56),
		Vector2(0.18, 0.72),
		Vector2(0.12, 1.0),
		Vector2(-0.16, 0.76),
		Vector2(-0.4, 0.58),
		Vector2(-0.46, 0.22)
	]
	var points := PackedVector2Array()
	for step: Vector2 in outline:
		points.append(foot + side * reach * step.x + out * reach * step.y)
	on.draw_colored_polygon(points, ink)


## A shield: shoulders square, sides tapering to a point.
static func shield(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	var center := at(box, x, y)
	var reach := span(box, span)
	on.draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(-reach * 0.8, -reach),
				center + Vector2(reach * 0.8, -reach),
				center + Vector2(reach * 0.8, reach * 0.25),
				center + Vector2(0.0, reach),
				center + Vector2(-reach * 0.8, reach * 0.25)
			]
		),
		ink
	)


## A heart, [param span] of the box from its middle to its edge: a life, see [Heart].
static func heart(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	var side := span(box, span) * 2.0
	var corner := at(box, x, y) - Vector2(side, side) * 0.5
	var points := PackedVector2Array()
	for point: Vector2 in Heart.unit_shape():
		points.append(corner + point * side)
	on.draw_colored_polygon(points, ink)


## A jagged burst, for the pictures that are about something going off.
static func burst(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	spiked(on, box, x, y, span, 10, 0.52, ink)


## A lightning bolt, for the one picture in the set that is about speed rather than about a
## thing. Nothing else here is a bolt, so it reads on its own.
static func bolt(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	var center := at(box, x, y)
	var reach := span(box, span)
	var outline: Array[Vector2] = [
		Vector2(0.24, -1.0),
		Vector2(-0.52, 0.1),
		Vector2(-0.04, 0.1),
		Vector2(-0.24, 1.0),
		Vector2(0.52, -0.14),
		Vector2(0.04, -0.14)
	]
	var points := PackedVector2Array()
	for step: Vector2 in outline:
		points.append(center + step * reach)
	on.draw_colored_polygon(points, ink)


## A five-pointed star, the house's own mark.
static func star(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	spiked(on, box, x, y, span, 5, 0.46, ink)


## A ring of [param points] spikes reaching [param span] with the valleys between them at
## [param inner] of that, which is a star at five and a burst at ten.
static func spiked(
	on: CanvasItem,
	box: Rect2,
	x: float,
	y: float,
	span: float,
	points: int,
	inner: float,
	ink: Color
) -> void:
	var center := at(box, x, y)
	var reach := span(box, span)
	var shape := PackedVector2Array()
	for i: int in points * 2:
		var angle := TAU * i / float(points * 2) - PI * 0.5
		var out := reach if i % 2 == 0 else reach * inner
		shape.append(center + Vector2(cos(angle), sin(angle)) * out)
	on.draw_colored_polygon(shape, ink)
