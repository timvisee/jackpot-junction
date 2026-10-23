class_name SwapMarks
extends Object
## The marks drawn over the respawn pick's cards, GAME.md 3.7: the swap arrow shown between a new
## card and the one it replaces, or on a card a full hand is about to swap for; and the trash can on
## the card given up. Kept here so [JokerPicker] stays the layout and these stay the drawing. Each
## draws onto the [Control] passed in, sized to its width, through that control's [signal
## CanvasItem.draw].

## The red the trash can is drawn in, shared with the doomed card's own frame.
const DOOMED := JokerCard.DOOMED


## The double-headed swap arrow filling [param on], an open chevron head at either end of a round
## shaft, up and down since a new card floats over the old: a dark outline first and the house's
## foil over it, antialiased, so it reads cleanly where it laps onto either card.
static func draw_arrow(on: Control) -> void:
	_arrow(on, Color(0.0, 0.0, 0.0, 0.8), 2.4)
	_arrow(on, HouseTheme.FOIL, 0.0)


## One pass of [method draw_arrow] in [param color], its strokes [param grow] wider for the outline.
static func _arrow(on: Control, color: Color, grow: float) -> void:
	var side := on.size.x
	var mid := side * 0.5
	var head := side * 0.24
	var span := side * 0.36
	var thick := maxf(side * 0.12, 3.0) + grow * 2.0
	var top := Vector2(mid, mid - span)
	var bottom := Vector2(mid, mid + span)
	on.draw_line(top, bottom, color, thick, true)
	for tip: Vector2 in [top, bottom]:
		var into := 1.0 if tip == top else -1.0
		var wings := PackedVector2Array(
			[tip + Vector2(-head, head * into), tip, tip + Vector2(head, head * into)]
		)
		on.draw_polyline(wings, color, thick, true)


## The trash can filling [param on], in the doomed red over a dark shadow of itself so it reads on
## the card's own face, its ridges carved back out in the dark.
static func draw_trash(on: Control) -> void:
	_bin(on, Vector2(2.0, 2.0), Color(0.0, 0.0, 0.0, 0.7))
	_bin(on, Vector2.ZERO, DOOMED)
	var s := on.size.x
	for k: int in 3:
		var x := s * (0.38 + k * 0.12)
		on.draw_line(Vector2(x, s * 0.44), Vector2(x, s * 0.76), Color(0.0, 0.0, 0.0, 0.4), 2.0)


## The can itself at [param shift] in [param color]: a handle and a lid over a tapered body.
static func _bin(on: Control, shift: Vector2, color: Color) -> void:
	var s := on.size.x
	on.draw_rect(Rect2(Vector2(s * 0.40, s * 0.12) + shift, Vector2(s * 0.20, s * 0.07)), color)
	on.draw_rect(Rect2(Vector2(s * 0.16, s * 0.20) + shift, Vector2(s * 0.68, s * 0.10)), color)
	var body := PackedVector2Array(
		[
			Vector2(s * 0.24, s * 0.32) + shift,
			Vector2(s * 0.76, s * 0.32) + shift,
			Vector2(s * 0.69, s * 0.84) + shift,
			Vector2(s * 0.31, s * 0.84) + shift,
		]
	)
	on.draw_colored_polygon(body, color)
