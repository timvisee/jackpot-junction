class_name EmoteArt
extends RefCounted
## The emotes a player can put up over their kart, GAME.md 3.8, drawn from the same shapes as the
## other pictures of 8.3a. Being round, each is a chip, 8.1a: a poker chip in the player's color
## with its notches, so it says who as well as what, and in the middle of it a cream inlay with
## the emote printed on it in ink, the way a casino's own chips carry its mark. GG in the condensed
## capitals, a smile, a scowl and a heart.

## The four, in the order the right stick flicks them, up, right, down and left, and the keys 7 to
## 0 press them.
const EMOTES: Array[StringName] = [&"gg", &"happy", &"angry", &"heart"]
const BUBBLE := HouseTheme.PAPER
const FACE_INK := HouseTheme.INK
## How much of the chip the inlay takes, and its rim.
const INLAY := 0.66
const INLAY_RIM := 0.035


## A control that draws one emote, square and centered in whatever room it is given.
class Picture:
	extends Control

	var emote := 0:
		set(value):
			emote = value
			queue_redraw()
	var ink := Color.WHITE:
		set(value):
			ink = value
			queue_redraw()

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var box := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		EmoteArt.draw_into(self, box, emote, ink)


## Emote [param index] as a node [param side] across, its bubble rimmed in [param ink].
static func picture(index: int, ink: Color, side: float) -> Picture:
	var drawn := Picture.new()
	drawn.emote = index
	drawn.ink = ink
	drawn.custom_minimum_size = Vector2(side, side)
	drawn.size = drawn.custom_minimum_size
	drawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return drawn


static func draw_into(on: CanvasItem, chip: Rect2, index: int, ink: Color) -> void:
	var middle := IconShapes.at(chip, 0.5, 0.5)
	var radius := IconShapes.span(chip, 0.5)
	ChipArt.chip(on, middle, radius, Color(ink, 1.0))
	var inlay := radius * INLAY
	on.draw_circle(middle, inlay, BUBBLE, true, -1.0, true)
	var rim := maxf(radius * INLAY_RIM, 1.0)
	on.draw_arc(middle, inlay, 0.0, TAU, 40, ink.darkened(0.35), rim, true)
	# The emote on the inlay, drawn into a box as big as the inlay, a little in from its rim.
	var side := inlay * 2.0 * 0.92
	var box := Rect2(middle - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	match EMOTES[posmod(index, EMOTES.size())]:
		&"gg":
			_letters(on, box, "GG")
		&"happy":
			_eyes(on, box)
			IconShapes.arc(on, box, 0.5, 0.5, 0.22, 25.0, 155.0, FACE_INK)
		&"angry":
			_eyes(on, box)
			IconShapes.line(on, box, 0.27, 0.3, 0.44, 0.38, FACE_INK)
			IconShapes.line(on, box, 0.73, 0.3, 0.56, 0.38, FACE_INK)
			IconShapes.arc(on, box, 0.5, 0.82, 0.2, 215.0, 325.0, FACE_INK)
		_:
			_heart(on, box)


static func _eyes(on: CanvasItem, box: Rect2) -> void:
	IconShapes.disc(on, box, 0.37, 0.43, 0.065, FACE_INK)
	IconShapes.disc(on, box, 0.63, 0.43, 0.065, FACE_INK)


static func _letters(on: CanvasItem, box: Rect2, text: String) -> void:
	var font := Type.mark_font()
	var size := roundi(box.size.y * 0.6)
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var at := box.get_center() + Vector2(-wide.x * 0.5, size * 0.36)
	on.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, FACE_INK)


## The heart the lives are drawn with, in the table's red, filling most of the bubble.
static func _heart(on: CanvasItem, box: Rect2) -> void:
	var points := PackedVector2Array()
	var side := box.size.x * 0.56
	var corner := box.get_center() - Vector2(side, side) * 0.5
	for point: Vector2 in Heart.unit_shape():
		points.append(corner + point * side)
	on.draw_colored_polygon(points, Palette.CHIP_RED)
