class_name JokerArt
extends RefCounted
## A picture for every joker, GAME.md 8.3, drawn rather than drawn from a set of pictures.
##
## One flat pictogram per card, in the kind's own colour on the dark of the card, built from a
## small vocabulary of shapes: discs, rings, bars, triangles, arcs, bolts and pips. Keeping them
## all to that vocabulary is what makes thirty of them look like one set rather than thirty
## drawings, and the whole thing weighs nothing and scales to any size, which a folder of PNGs
## cut for one card size would not.
##
## Coordinates are fractions of the box the picture is given, so the same recipe serves the card
## in the hand, the bigger one in the pick and anything else that wants one.

## How thick a drawn line is, as a fraction of the box, and the faintness of the detail lines
## that sit behind the subject of a picture.
const STROKE := 0.055
const FAINT := 0.4
## How big a pip is, for the pictures made of them.
const PIP := 0.055


## A control that draws one joker's picture, to drop into a card. It keeps the picture square
## and centred in whatever room it is given, so a tall slot does not stretch the drawing.
class Picture:
	extends Control

	var id: StringName
	var ink := Color.WHITE

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var box := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		JokerArt.draw_into(self, box, id, ink)


## One joker's picture as a node, sized by whatever it is put in.
static func picture(id: StringName, ink: Color) -> Control:
	var art := Picture.new()
	art.id = id
	art.ink = ink
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


## Draws [param id]'s picture into [param box] on [param on], in [param ink]. An id with no
## picture of its own gets the wild card's star, which is the house's own mark.
static func draw_into(on: CanvasItem, box: Rect2, id: StringName, ink: Color) -> void:
	var dim := Color(ink.r, ink.g, ink.b, ink.a * FAINT)
	match id:
		&"aimbot":
			_ring(on, box, 0.5, 0.5, 0.3, ink)
			_line(on, box, 0.5, 0.06, 0.5, 0.3, ink)
			_line(on, box, 0.5, 0.7, 0.5, 0.94, ink)
			_line(on, box, 0.06, 0.5, 0.3, 0.5, ink)
			_line(on, box, 0.7, 0.5, 0.94, 0.5, ink)
			_disc(on, box, 0.5, 0.5, 0.07, ink)
		&"backfire":
			_bar(on, box, 0.54, 0.38, 0.36, 0.24, dim)
			_flame(on, box, 0.56, 0.5, 0.44, -90.0, ink)
		&"big_tank":
			_bar(on, box, 0.26, 0.38, 0.48, 0.46, dim)
			for at: float in [0.36, 0.5, 0.64]:
				_bar(on, box, at - 0.05, 0.24, 0.1, 0.2, ink)
				_tri(on, box, at, 0.18, 0.14, 0.0, ink)
		&"comeback":
			_arc(on, box, 0.5, 0.56, 0.3, 160.0, 380.0, ink)
			_tri(on, box, 0.5, 0.1, 0.22, 0.0, ink)
		&"curve_ball":
			_arc(on, box, 0.86, 0.5, 0.56, 130.0, 230.0, dim)
			_disc(on, box, 0.32, 0.26, 0.11, ink)
			_disc(on, box, 0.3, 0.74, 0.11, ink)
		&"deep_pockets":
			_bar(on, box, 0.18, 0.4, 0.64, 0.46, dim)
			_disc(on, box, 0.36, 0.6, 0.12, ink)
			_disc(on, box, 0.64, 0.6, 0.12, ink)
		&"direct_debit":
			_bar(on, box, 0.16, 0.66, 0.68, 0.2, dim)
			_line(on, box, 0.5, 0.12, 0.5, 0.48, ink)
			_tri(on, box, 0.5, 0.62, 0.24, 180.0, ink)
		&"getaway_driver":
			_bar(on, box, 0.1, 0.24, 0.5, 0.08, dim)
			_bar(on, box, 0.1, 0.46, 0.66, 0.08, dim)
			_bar(on, box, 0.1, 0.68, 0.4, 0.08, dim)
			_tri(on, box, 0.82, 0.46, 0.34, 90.0, ink)
		&"glass_jackpot":
			_disc(on, box, 0.5, 0.5, 0.36, dim)
			_ring(on, box, 0.5, 0.5, 0.36, ink)
			_line(on, box, 0.46, 0.16, 0.58, 0.42, ink)
			_line(on, box, 0.58, 0.42, 0.4, 0.56, ink)
			_line(on, box, 0.4, 0.56, 0.54, 0.84, ink)
		&"green_light":
			_bar(on, box, 0.32, 0.08, 0.36, 0.84, dim)
			_disc(on, box, 0.5, 0.26, 0.09, dim)
			_disc(on, box, 0.5, 0.5, 0.09, dim)
			_disc(on, box, 0.5, 0.74, 0.11, ink)
		&"hair_trigger":
			_bolt(on, box, 0.5, 0.5, 0.42, ink)
		&"high_roller":
			_bar(on, box, 0.16, 0.16, 0.68, 0.68, dim)
			for spot: Vector2 in [Vector2(0.32, 0.32), Vector2(0.5, 0.5), Vector2(0.68, 0.68)]:
				_disc(on, box, spot.x, spot.y, PIP * 1.6, ink)
		&"hot_streak":
			_flame(on, box, 0.28, 0.86, 0.3, 0.0, dim)
			_flame(on, box, 0.72, 0.86, 0.3, 0.0, dim)
			_flame(on, box, 0.5, 0.9, 0.46, 0.0, ink)
		&"insurance_policy":
			_shield(on, box, 0.5, 0.5, 0.36, ink)
		&"jerry_can":
			_bar(on, box, 0.22, 0.28, 0.5, 0.58, ink)
			_bar(on, box, 0.3, 0.16, 0.3, 0.09, ink)
			_bar(on, box, 0.66, 0.36, 0.16, 0.1, ink)
			_line(on, box, 0.34, 0.4, 0.34, 0.76, dim)
		&"loaded_dice":
			_bar(on, box, 0.2, 0.2, 0.6, 0.6, dim)
			for spot: Vector2 in [
				Vector2(0.34, 0.34),
				Vector2(0.66, 0.34),
				Vector2(0.5, 0.5),
				Vector2(0.34, 0.66),
				Vector2(0.66, 0.66)
			]:
				_disc(on, box, spot.x, spot.y, PIP * 1.5, ink)
		&"lucky_seven":
			_line(on, box, 0.24, 0.18, 0.76, 0.18, ink)
			_line(on, box, 0.76, 0.18, 0.44, 0.86, ink)
			_line(on, box, 0.34, 0.52, 0.62, 0.52, dim)
		&"magnet_hubcaps":
			_arc(on, box, 0.5, 0.56, 0.3, 180.0, 360.0, ink)
			_line(on, box, 0.2, 0.56, 0.2, 0.84, ink)
			_line(on, box, 0.8, 0.56, 0.8, 0.84, ink)
			_bar(on, box, 0.14, 0.78, 0.12, 0.1, dim)
			_bar(on, box, 0.74, 0.78, 0.12, 0.1, dim)
		&"nitro_habit":
			_bar(on, box, 0.34, 0.24, 0.32, 0.6, dim)
			_bar(on, box, 0.42, 0.12, 0.16, 0.14, dim)
			_flame(on, box, 0.5, 0.8, 0.3, 0.0, ink)
		&"odometer":
			_arc(on, box, 0.5, 0.64, 0.34, 180.0, 360.0, dim)
			_line(on, box, 0.5, 0.64, 0.72, 0.4, ink)
			_disc(on, box, 0.5, 0.64, 0.07, ink)
		&"payday":
			_disc(on, box, 0.5, 0.3, 0.2, ink)
			_bar(on, box, 0.24, 0.56, 0.52, 0.12, dim)
			_bar(on, box, 0.28, 0.74, 0.44, 0.12, dim)
		&"pickpocket":
			_bar(on, box, 0.14, 0.54, 0.44, 0.34, dim)
			_arc(on, box, 0.62, 0.62, 0.3, 200.0, 290.0, ink)
			_disc(on, box, 0.74, 0.26, 0.15, ink)
		&"road_rage":
			_burst(on, box, 0.5, 0.5, 0.4, ink)
		&"rubber_bumpers":
			_arc(on, box, 0.5, 0.5, 0.36, 210.0, 330.0, ink)
			_arc(on, box, 0.5, 0.5, 0.36, 30.0, 150.0, ink)
			_disc(on, box, 0.5, 0.5, 0.12, dim)
		&"slipstream":
			_bar(on, box, 0.1, 0.26, 0.58, 0.08, dim)
			_bar(on, box, 0.22, 0.46, 0.58, 0.08, ink)
			_bar(on, box, 0.1, 0.66, 0.44, 0.08, dim)
		&"snake_eyes":
			_bar(on, box, 0.2, 0.2, 0.6, 0.6, dim)
			_disc(on, box, 0.36, 0.36, PIP * 1.8, ink)
			_disc(on, box, 0.64, 0.64, PIP * 1.8, ink)
		&"tailslide":
			_arc(on, box, 0.72, 0.28, 0.5, 90.0, 190.0, dim)
			_arc(on, box, 0.72, 0.28, 0.34, 90.0, 190.0, ink)
		&"toll_booth":
			_bar(on, box, 0.14, 0.2, 0.12, 0.66, dim)
			_bar(on, box, 0.3, 0.42, 0.58, 0.12, ink)
			_disc(on, box, 0.2, 0.34, 0.08, ink)
		&"vulture":
			_arc(on, box, 0.2, 0.16, 0.36, 10.0, 80.0, ink)
			_arc(on, box, 0.8, 0.16, 0.36, 100.0, 170.0, ink)
			_disc(on, box, 0.5, 0.5, 0.1, ink)
			_tri(on, box, 0.5, 0.68, 0.16, 180.0, ink)
		_:
			_star(on, box, 0.5, 0.5, 0.4, ink)


## Every id this knows a picture for, so a test can hold the set to the catalogue.
static func known() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"aimbot",
		&"backfire",
		&"big_tank",
		&"comeback",
		&"curve_ball",
		&"deep_pockets",
		&"direct_debit",
		&"getaway_driver",
		&"glass_jackpot",
		&"green_light",
		&"hair_trigger",
		&"high_roller",
		&"hot_streak",
		&"insurance_policy",
		&"jerry_can",
		&"loaded_dice",
		&"lucky_seven",
		&"magnet_hubcaps",
		&"nitro_habit",
		&"odometer",
		&"payday",
		&"pickpocket",
		&"road_rage",
		&"rubber_bumpers",
		&"slipstream",
		&"snake_eyes",
		&"tailslide",
		&"toll_booth",
		&"vulture",
		&"wild_card"
	]
	return ids


static func _at(box: Rect2, x: float, y: float) -> Vector2:
	return box.position + Vector2(x * box.size.x, y * box.size.y)


static func _span(box: Rect2, fraction: float) -> float:
	return fraction * minf(box.size.x, box.size.y)


static func _width(box: Rect2) -> float:
	return maxf(_span(box, STROKE), 1.5)


static func _disc(on: CanvasItem, box: Rect2, x: float, y: float, r: float, ink: Color) -> void:
	on.draw_circle(_at(box, x, y), _span(box, r), ink)


static func _ring(on: CanvasItem, box: Rect2, x: float, y: float, r: float, ink: Color) -> void:
	on.draw_arc(_at(box, x, y), _span(box, r), 0.0, TAU, 40, ink, _width(box))


static func _arc(
	on: CanvasItem, box: Rect2, x: float, y: float, r: float, from: float, to: float, ink: Color
) -> void:
	on.draw_arc(
		_at(box, x, y), _span(box, r), deg_to_rad(from), deg_to_rad(to), 32, ink, _width(box)
	)


static func _line(
	on: CanvasItem, box: Rect2, x1: float, y1: float, x2: float, y2: float, ink: Color
) -> void:
	on.draw_line(_at(box, x1, y1), _at(box, x2, y2), ink, _width(box))


## A rounded bar, which is how every block, body and panel in the set is drawn.
static func _bar(
	on: CanvasItem, box: Rect2, x: float, y: float, w: float, h: float, ink: Color
) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ink
	style.set_corner_radius_all(roundi(_span(box, 0.1)))
	on.draw_style_box(style, Rect2(_at(box, x, y), Vector2(w, h) * box.size))


## A solid triangle of [param span] across, pointing [param facing] degrees clockwise from up.
static func _tri(
	on: CanvasItem, box: Rect2, x: float, y: float, span: float, facing: float, ink: Color
) -> void:
	var centre := _at(box, x, y)
	var reach := _span(box, span) * 0.5
	var points := PackedVector2Array()
	for i: int in 3:
		var angle := deg_to_rad(facing + i * 120.0) - PI * 0.5
		points.append(centre + Vector2(cos(angle), sin(angle)) * reach)
	on.draw_colored_polygon(points, ink)


## A flame: a teardrop standing on [param x], [param y] with its tip [param span] away, blowing
## [param turn] degrees off straight up, so the ones out of an exhaust can lie on their side.
static func _flame(
	on: CanvasItem, box: Rect2, x: float, y: float, span: float, turn: float, ink: Color
) -> void:
	var foot := _at(box, x, y)
	var reach := _span(box, span)
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
static func _shield(
	on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color
) -> void:
	var centre := _at(box, x, y)
	var reach := _span(box, span)
	on.draw_colored_polygon(
		PackedVector2Array(
			[
				centre + Vector2(-reach * 0.8, -reach),
				centre + Vector2(reach * 0.8, -reach),
				centre + Vector2(reach * 0.8, reach * 0.25),
				centre + Vector2(0.0, reach),
				centre + Vector2(-reach * 0.8, reach * 0.25)
			]
		),
		ink
	)


## A jagged burst, for the pictures that are about something going off.
static func _burst(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	_spiked(on, box, x, y, span, 10, 0.52, ink)


## A lightning bolt, for the one picture in the set that is about speed rather than about a
## thing. Nothing else here is a bolt, so it reads on its own.
static func _bolt(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	var centre := _at(box, x, y)
	var reach := _span(box, span)
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
		points.append(centre + step * reach)
	on.draw_colored_polygon(points, ink)


## A five-pointed star, the house's own mark.
static func _star(on: CanvasItem, box: Rect2, x: float, y: float, span: float, ink: Color) -> void:
	_spiked(on, box, x, y, span, 5, 0.46, ink)


## A ring of [param points] spikes reaching [param span] with the valleys between them at
## [param inner] of that, which is a star at five and a burst at ten.
static func _spiked(
	on: CanvasItem,
	box: Rect2,
	x: float,
	y: float,
	span: float,
	points: int,
	inner: float,
	ink: Color
) -> void:
	var centre := _at(box, x, y)
	var reach := _span(box, span)
	var shape := PackedVector2Array()
	for i: int in points * 2:
		var angle := TAU * i / float(points * 2) - PI * 0.5
		var out := reach if i % 2 == 0 else reach * inner
		shape.append(centre + Vector2(cos(angle), sin(angle)) * out)
	on.draw_colored_polygon(shape, ink)
