class_name StampArt
extends RefCounted
## The house's rubber stamp, GAME.md 9.4a and 8.1a: a heavy ring broken at either side for a star
## and a fine ring inside it, a drawing of 8.3a, with a word inside them, the agency over the word
## and a date under it, laid a little askew. The driving test stamps PASSED on the license with it
## and the payout slip WINNER. Drawn to [constant DESIGN] and scaled to the radius asked for, words,
## rings and stars alike, so a small stamp is the same stamp smaller.

## The radius it is drawn to, and how wide the word may be inside the inner ring, at
## [constant DESIGN]; and the heavy ring's radius in its drawing's 48 units.
const DESIGN := 52.0
const WORD_WIDE := 76.0
const RING := 20.6


## Stamps [param word] onto [param canvas] round [param at], [param radius] out and turned
## [param turn], with [param over] above the word and [param under] beneath it, in [param ink].
static func stamp(
	canvas: CanvasItem,
	at: Vector2,
	radius: float,
	word: String,
	over: String,
	under: String,
	turn: float,
	ink: Color
) -> void:
	var k := radius / DESIGN
	canvas.draw_set_transform(at, turn, Vector2.ONE)
	# The rings and the stars, a drawing of GAME.md 8.3a pressed in the ink: its heavy ring is
	# RING units out of its 48.
	var unit := radius / RING
	var box := Rect2(-Vector2.ONE * 24.0 * unit, Vector2.ONE * 48.0 * unit)
	IconPress.draw(canvas, box, &"stamp_house", ink, IconPress.Ground.PAPER)
	var wide := radius * 2.0
	var display := Type.display_font()
	var word_size := _fitting(word, display, 24.0 * k, WORD_WIDE * k)
	_centered(canvas, Vector2(-radius, -14.0 * k), word, display, word_size, ink, wide)
	_centered(canvas, Vector2(-radius, -32.0 * k), over, Type.STRONG, roundi(8.0 * k), ink, wide)
	_centered(
		canvas,
		Vector2(-radius, 16.0 * k),
		under,
		Type.numbers_text_font(),
		roundi(10.0 * k),
		ink,
		wide
	)
	canvas.draw_set_transform(Vector2.ZERO)


## The size [param text] is set at in [param font]: [param wanted], or smaller to be no wider than
## [param widest].
static func _fitting(text: String, font: Font, wanted: float, widest: float) -> int:
	var size := roundi(wanted)
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if wide > widest:
		size = floori(size * widest / wide)
	return maxi(size, 1)


## [param text] centered across [param width] from [param at], its top at [param at].
static func _centered(
	canvas: CanvasItem,
	at: Vector2,
	text: String,
	font: Font,
	font_size: int,
	ink: Color,
	width: float
) -> void:
	var baseline := at + Vector2(0.0, font.get_ascent(font_size))
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, ink)
