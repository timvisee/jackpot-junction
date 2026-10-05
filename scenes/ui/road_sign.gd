class_name RoadSign
extends Control
## A road sign, GAME.md 8.1a, for what the game warns about: a yellow warning diamond in the
## header of a question that loses something, a round blue sign in one that is only a question,
## and an amber diamond beside a player whose line to the host is slow. Drawn, like every picture
## in the game, so it is sharp at any size.

enum Kind { WARNING, QUESTION, SLOW }

## The sign's own colors: road yellow, road blue, the board's amber, and the ink on all of them.
const YELLOW := Color("#f6c42e")
const BLUE := Color("#2f62c9")
const AMBER := Color("#ffb23d")
const INK := Color("#16151a")

var kind := Kind.WARNING:
	set = _set_kind


## A sign of [param what], [param side] pixels across.
static func of(what: Kind, side: float) -> RoadSign:
	var made := RoadSign.new()
	made.kind = what
	made.custom_minimum_size = Vector2(side, side)
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return made


func _set_kind(value: Kind) -> void:
	kind = value
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var middle := size * 0.5
	if kind == Kind.QUESTION:
		var radius := side * 0.5
		draw_circle(middle, radius, BLUE, true, -1.0, true)
		draw_arc(middle, radius * 0.84, 0.0, TAU, 48, Color.WHITE, radius * 0.08, true)
		_mark("?", Color.WHITE, side)
		return
	var fill := YELLOW if kind == Kind.WARNING else AMBER
	var half := side * 0.5
	var diamond := PackedVector2Array(
		[
			middle + Vector2(0.0, -half),
			middle + Vector2(half, 0.0),
			middle + Vector2(0.0, half),
			middle + Vector2(-half, 0.0),
		]
	)
	draw_colored_polygon(diamond, fill)
	diamond.append(diamond[0])
	draw_polyline(diamond, fill, 1.0, true)
	var inner := PackedVector2Array()
	for point: Vector2 in diamond:
		inner.append(middle + (point - middle) * 0.8)
	draw_polyline(inner, INK, side * 0.045, true)
	_mark("!", INK, side)


## The mark on the sign, set in the display cut and centered on it.
func _mark(text: String, ink: Color, side: float) -> void:
	var font := Type.display_font()
	var font_size := int(side * 0.62)
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# Barlow's capitals stand 0.7 of the size tall, so half of that under the middle is centered.
	var baseline := size.y * 0.5 + float(font_size) * 0.35
	draw_string(
		font,
		Vector2(size.x * 0.5 - wide * 0.5, baseline),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		ink
	)
