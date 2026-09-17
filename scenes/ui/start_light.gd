class_name StartLight
extends Control
## The start gantry from GAME.md 8.3. A countdown of seconds told as a number reads as a menu;
## a row of lamps filling up red and then going green is what a driver sitting on the grid
## actually looks at. Five lamps light left to right over the countdown and all five turn green
## on the drop. Driven by [MatchHud]; holds no match state of its own.

const LAMPS := Match.COUNTDOWN_LAMPS
const LAMP_RADIUS := 21.0
const LAMP_GAP := 58.0
const GLOW_RADIUS := 36.0
const HOUSING := Color("#16161A")
const HOUSING_EDGE := Color("#0A0A0C")
const DARK := Color("#2A2126")
const RED := Color("#FF3B30")
const GREEN := Color("#3DDC5C")

## How many lamps are lit, which counts up as the countdown runs down.
var lit := 0
## True on the drop, when the whole row goes green.
var go := false


func _init() -> void:
	custom_minimum_size = Vector2(LAMP_GAP * LAMPS + 44.0, 2.0 * GLOW_RADIUS + 20.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Hangs the gantry over the middle of the screen, [param above] pixels clear of it, so whatever
## the middle is for afterwards has it to itself.
func hang(above: float) -> void:
	var span := custom_minimum_size
	set_anchors_preset(Control.PRESET_CENTER, false)
	offset_left = -span.x * 0.5
	offset_right = span.x * 0.5
	offset_top = -span.y - above
	offset_bottom = -above


## Lights this many lamps, counted by the match so the rack and the start tones agree.
func set_countdown(count: int) -> void:
	_set_lamps(clampi(count, 0, LAMPS), false)


func set_go() -> void:
	_set_lamps(LAMPS, true)


## Only a lamp actually changing is worth a redraw.
func _set_lamps(count: int, green: bool) -> void:
	if count == lit and green == go:
		return
	lit = count
	go = green
	queue_redraw()


func _draw() -> void:
	var housing := Rect2(Vector2.ZERO, size)
	draw_rect(housing.grow(3.0), HOUSING_EDGE, true)
	draw_rect(housing, HOUSING, true)
	var middle := size.y * 0.5
	var first := (size.x - LAMP_GAP * (LAMPS - 1)) * 0.5
	for i: int in LAMPS:
		var at := Vector2(first + LAMP_GAP * i, middle)
		var on := go or i < lit
		var color := (GREEN if go else RED) if on else DARK
		if on:
			draw_circle(at, GLOW_RADIUS, Color(color, 0.22))
		draw_circle(at, LAMP_RADIUS, color)
		draw_circle(at, LAMP_RADIUS, Color(0.0, 0.0, 0.0, 0.55), false, 2.0)
