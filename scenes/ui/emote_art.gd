class_name EmoteArt
extends RefCounted
## The emotes a player can put up over their kart, GAME.md 3.8, drawn as the other pictures of 8.3a
## are. Being round, each is a chip, 8.1a: a poker chip in the player's color with its notches, so
## it says who as well as what, and in the middle of it a cream inlay with the emote printed on it
## in ink, the way a casino's own chips carry its mark. GG in round strokes, a smile and a scowl
## printed open on the inlay, and a heart in the table's red whoever sends it.

## The four, in the order the right stick flicks them, up, right, down and left, and the keys 7 to
## 0 press them.
const EMOTES: Array[StringName] = [&"gg", &"happy", &"angry", &"heart"]
## Each one's drawing, in that order.
const PICTURES: Array[StringName] = [&"emote_gg", &"emote_happy", &"emote_angry", &"emote_heart"]
const BUBBLE := HouseTheme.PAPER
const FACE_INK := HouseTheme.INK
## How much of the chip the inlay takes, and its rim, and how much of the inlay's width the
## drawing's square takes.
const INLAY := 0.66
const INLAY_RIM := 0.035
const ON_INLAY := 0.72


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
	# The emote on the inlay in the House's ink, the heart in the table's red in two inks.
	var side := inlay * 2.0 * ON_INLAY
	var box := Rect2(middle - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	var which := posmod(index, EMOTES.size())
	if EMOTES[which] == &"heart":
		IconPress.draw(
			on, box, PICTURES[which], Palette.CHIP_RED, IconPress.Ground.TWO_INKS, BUBBLE
		)
	else:
		IconPress.draw(on, box, PICTURES[which], FACE_INK, IconPress.Ground.PAPER, BUBBLE)
