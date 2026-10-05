class_name SpeedDial
extends Range
## The speedometer of a corner block, GAME.md 8.3 and 8.1a: a small dial, three quarters of a ring
## open at the foot, filling clockwise from the bottom left with the kart's speed, ticks round it,
## and the unit written in the gap at the foot. The number itself is a label laid over the middle
## of it by whoever builds the block, so it is set in the same type as the rest of the corner.
## Drawn in white, so the block can light the whole gauge the nitro's color by its modulate.

## Where the ring starts and ends, in radians clockwise from east with y down: the bottom left
## round over the top to the bottom right.
const FROM := PI * 0.75
const TO := PI * 2.25
## How thick the ring is, as a share of the dial's radius, and how many ticks go round it.
const RING := 0.16
const TICKS := 12
const TRACK := Color(0.0, 0.0, 0.0, 0.5)
const TICK_INK := Color(0.66, 0.65, 0.71, 0.8)
const UNIT := "KM/H"


func _init() -> void:
	min_value = 0.0
	max_value = 100.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_changed.connect(func(_to: float) -> void: queue_redraw())


func _draw() -> void:
	var side := minf(size.x, size.y)
	var middle := size * 0.5
	var thick := side * 0.5 * RING
	var radius := side * 0.5 - thick * 0.5 - 1.0
	draw_arc(middle, radius, FROM, TO, 48, TRACK, thick, true)
	var share := clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)
	if share > 0.0:
		draw_arc(middle, radius, FROM, lerpf(FROM, TO, share), 48, Color.WHITE, thick, true)
	for i: int in TICKS + 1:
		var angle := lerpf(FROM, TO, float(i) / float(TICKS))
		var toward := Vector2.from_angle(angle)
		var long := i % 3 == 0
		var inner := radius - thick * (2.6 if long else 1.9)
		draw_line(
			middle + toward * (radius - thick * 1.1),
			middle + toward * inner,
			TICK_INK,
			1.6 if long else 1.0,
			true
		)
	var font := Type.STRONG
	var unit_size := maxi(int(side * 0.11), 8)
	var wide := font.get_string_size(UNIT, HORIZONTAL_ALIGNMENT_LEFT, -1, unit_size).x
	draw_string(
		font,
		Vector2(middle.x - wide * 0.5, middle.y + radius * 0.92),
		UNIT,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		unit_size,
		TICK_INK
	)
