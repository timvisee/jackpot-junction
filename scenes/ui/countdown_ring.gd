class_name CountdownRing
extends Control
## A small ring that empties as a wait runs out, GAME.md 10.3: a faint track all the way round
## with the time still to go drawn over it in gold, from the top and clockwise, so something about
## to happen by itself is no surprise. Small enough to sit on a line of text.

const SIZE := Vector2(26.0, 26.0)
const THICKNESS := 4.0
const TRACK := Color(1.0, 1.0, 1.0, 0.14)
const POINTS := 48

## How much of the wait is still to go, from 1 when it starts to 0 when it is over.
var value := 1.0:
	set(left):
		value = clampf(left, 0.0, 1.0)
		queue_redraw()
var color := Palette.CHIP_GOLD


static func create() -> CountdownRing:
	var ring := CountdownRing.new()
	ring.custom_minimum_size = SIZE
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ring


func _draw() -> void:
	var middle := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - THICKNESS * 0.5
	draw_arc(middle, radius, 0.0, TAU, POINTS, TRACK, THICKNESS, true)
	if value > 0.0:
		var top := -PI * 0.5
		draw_arc(middle, radius, top, top + TAU * value, POINTS, color, THICKNESS, true)
