class_name NitroCells
extends Range
## The nitro tank of a corner block, GAME.md 8.3 and 8.1a: a row of slanted cells in the player's
## color, lit as far as the tank is full, the last one lit only as far as it has got, like the
## segments of a gauge on a dashboard. The block lights the whole row the nitro's color by its
## modulate while the bottle burns.

## How many cells, how far each leans over its height, and the gap between two of them.
const CELLS := 10
const LEAN := 0.35
const GAP := 3.0
const EMPTY := Color(0.0, 0.0, 0.0, 0.5)

## The player's color the cells are lit in, and what an unlit one is.
var ink := Color.WHITE:
	set = _set_ink
var empty := EMPTY:
	set = _set_empty


func _init() -> void:
	min_value = 0.0
	max_value = 100.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_changed.connect(func(_to: float) -> void: queue_redraw())


func _set_ink(value: Color) -> void:
	ink = value
	queue_redraw()


func _set_empty(value: Color) -> void:
	empty = value
	queue_redraw()


func _draw() -> void:
	var h := size.y
	var lean := h * LEAN
	var wide := (size.x - lean - GAP * float(CELLS - 1)) / float(CELLS)
	var share := clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)
	var full := share * float(CELLS)
	for i: int in CELLS:
		var x := float(i) * (wide + GAP)
		var cell := PackedVector2Array(
			[
				Vector2(x + lean, 0.0),
				Vector2(x + lean + wide, 0.0),
				Vector2(x + wide, h),
				Vector2(x, h),
			]
		)
		draw_colored_polygon(cell, empty)
		var lit := clampf(full - float(i), 0.0, 1.0)
		if lit <= 0.0:
			continue
		# The cell being filled is filled from its near edge, so the tank reads as it empties.
		var reach := wide * lit
		var part := PackedVector2Array(
			[
				Vector2(x + lean, 0.0),
				Vector2(x + lean + reach, 0.0),
				Vector2(x + reach, h),
				Vector2(x, h),
			]
		)
		draw_colored_polygon(part, ink)
