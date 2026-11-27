class_name DressArt
extends RefCounted
## A picture for each of the things a kart is dressed in at the stalls, GAME.md 4.4, drawn as the
## other pictures of 8.3a are: a paint roller, a top hat, a flag on its pole, the puffs of a trail,
## a plate, two tracks of tire tread, a kart seen from its side for its body, and a card. Small
## and on buttons, chips and paper, so printed flat in one ink, whatever is under them showing
## through.
## On a touch screen they are what the fire button shows while the kart stands on a stall, since
## the button there changes that thing rather than firing, and the hint over the kart shows the
## same, see [method button].

## How much of the button a picture takes up, and how big the round chip the hint draws it on is
## beside the words, as a share of the line's font size.
const ON_BUTTON := 1.1
const CHIP_SIZE := 1.6
## Each part's drawing, in [constant KartStyle.CHOICES] order, the card back last.
const PICTURES: Array[StringName] = [
	&"dress_paint",
	&"dress_hat",
	&"dress_flag",
	&"dress_trail",
	&"dress_plate",
	&"dress_marks",
	&"dress_body",
	&"dress_card_back",
]


## A control that draws the picture of one of the four, square and centered in whatever room it
## is given, on a round chip with a rim, the way the button on the screen looks.
class Badge:
	extends Control

	var part := 0
	var ink := Color.WHITE

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var middle := size * 0.5
		draw_circle(middle, side * 0.5, InputGlyph.CHIP)
		draw_arc(middle, side * 0.5 - 1.0, 0.0, TAU, 32, ink, InputGlyph.EDGE_WIDTH, true)
		var inner := side * 0.62
		DressArt.draw_into(
			self, Rect2(middle - Vector2.ONE * inner * 0.5, Vector2.ONE * inner), part, ink
		)


## Part [param part] of a [KartStyle] drawn as the touch screen's button for it, for a hint in a
## line of [param font_size] text.
static func button(part: int, ink: Color, font_size: int) -> Badge:
	var chip := Badge.new()
	chip.part = part
	chip.ink = ink
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side := roundf(font_size * CHIP_SIZE)
	chip.custom_minimum_size = Vector2(side, side)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return chip


## Part [param part] of a [KartStyle], in [constant KartStyle.CHOICES] order, and the card back
## after them, drawn into [param box].
static func draw_into(on: CanvasItem, box: Rect2, part: int, ink: Color) -> void:
	var drawing: StringName = (
		PICTURES[part] if part >= 0 and part < PICTURES.size() else &"dress_trail"
	)
	IconPress.draw(on, box, drawing, ink, IconPress.Ground.PAPER)
