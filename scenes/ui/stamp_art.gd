class_name StampArt
extends RefCounted
## The house's rubber stamp, GAME.md 9.4a and 8.1a: two rings with a word between them, the agency
## over the word and a date under it, a star either side, laid a little askew and short of solid,
## the way ink is. The driving test stamps PASSED on the license with it and the payout slip WINNER.


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
	canvas.draw_set_transform(at, turn, Vector2.ONE)
	canvas.draw_arc(Vector2.ZERO, radius, 0.15, 2.95, 40, ink, 4.0, true)
	canvas.draw_arc(Vector2.ZERO, radius, 3.25, 6.15, 40, ink, 4.0, true)
	canvas.draw_arc(Vector2.ZERO, radius - 8.0, 0.0, TAU, 48, Color(ink, 0.6), 1.5, true)
	var wide := radius * 2.0
	_centered(canvas, Vector2(-radius, -14.0), word, Type.display_font(), 24, ink, wide)
	_centered(canvas, Vector2(-radius, -32.0), over, Type.STRONG, 8, ink, wide)
	_centered(canvas, Vector2(-radius, 16.0), under, Type.numbers_text_font(), 10, ink, wide)
	for side: float in [-1.0, 1.0]:
		IconShapes.star(
			canvas, Rect2(Vector2(side * 34.0 - 6.0, 24.0), Vector2(12.0, 12.0)), 0.5, 0.5, 0.9, ink
		)
	canvas.draw_set_transform(Vector2.ZERO)


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
