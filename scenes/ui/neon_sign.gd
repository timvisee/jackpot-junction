class_name NeonSign
extends Control
## A bar's neon sign, GAME.md 3.3 and 8.1a: what Last Call is called with over the middle of the
## screen, the words bent in red tube inside a tube frame, on a dark board, glowing into the room
## round it. It flickers on as a tube does when it is switched on, then hums, a little brighter and
## dimmer, for as long as it is up. For anybody who asked for fewer flashes, 8.5, it comes on
## steady and stays so.

## How big the words are set, how much room the frame leaves round them, the frame's corner, and
## how far the glow spreads.
const SIZE := 84
const ROOM := Vector2(34.0, 20.0)
const CORNER := 18.0
const GLOW := 24
## The tube, its glow, and the white-hot middle of the tube.
const TUBE := Color("#ff3b4e")
const HOT := Color("#ffd9dc")
const BOARD := Color(0.04, 0.035, 0.05, 0.82)
## When the tube catches, in seconds after it is switched on, each a step lit or not, and how much
## the hum moves it and how fast.
const CATCH := [[0.0, 0.0], [0.05, 0.9], [0.11, 0.1], [0.2, 1.0], [0.27, 0.25], [0.42, 1.0]]
const HUM := 0.08
const HUM_RATE := 9.0

## The words on the sign.
var text := "":
	set = _set_text

var _age := 0.0
var _on := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_text(value: String) -> void:
	text = value
	# Said to a screen reader as it comes up, see [ScreenReader].
	ScreenReader.say(self, ScreenReader.spoken(text))
	var font := Type.display_font()
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	custom_minimum_size = Vector2(wide, float(SIZE) * Type.CAP_HEIGHT) + ROOM * 2.0
	size = custom_minimum_size
	pivot_offset = size * 0.5
	queue_redraw()


## Switches the sign on from dark, to flicker on again.
func switch_on() -> void:
	_age = 0.0
	_on = 0.0
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		switch_on()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_age += delta
	var steady := Game.settings != null and Game.settings.flash_reduction
	if steady:
		_on = 1.0
	else:
		_on = 0.0
		for step: Array in CATCH:
			if _age >= float(step[0]):
				_on = float(step[1])
		if _age > float(CATCH[-1][0]):
			_on = 1.0 - HUM * (0.5 + 0.5 * sin(_age * HUM_RATE))
	queue_redraw()


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	var board := StyleBoxFlat.new()
	board.bg_color = BOARD
	board.set_corner_radius_all(int(CORNER + 6.0))
	board.shadow_color = Color(TUBE, 0.25 * _on)
	board.shadow_size = GLOW
	draw_style_box(board, box.grow(6.0))
	var frame := box.grow(-8.0)
	_tube_box(frame, 9.0, Color(TUBE, 0.12 * _on))
	_tube_box(frame, 4.5, Color(TUBE, 0.55 * _on + 0.12))
	_tube_box(frame, 1.6, Color(HOT, 0.9 * _on + 0.1))
	var font := Type.display_font()
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	var at := Vector2((size.x - wide) * 0.5, size.y * 0.5 + float(SIZE) * Type.CAP_HEIGHT * 0.5)
	for glow: Array in [[22, 0.08], [12, 0.16], [6, 0.4]]:
		draw_string_outline(
			font,
			at,
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			SIZE,
			int(glow[0]),
			Color(TUBE, float(glow[1]) * _on)
		)
	draw_string_outline(
		font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 3, Color(TUBE, 0.35 + 0.65 * _on)
	)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(HOT, 0.25 + 0.75 * _on))


## A rounded frame of tube round [param box], [param width] thick, in [param ink].
func _tube_box(box: Rect2, width: float, ink: Color) -> void:
	var line := StyleBoxFlat.new()
	line.draw_center = false
	line.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	line.set_border_width_all(int(ceilf(width)))
	line.border_color = ink
	line.set_corner_radius_all(int(CORNER))
	line.anti_aliasing = true
	draw_style_box(line, box.grow(width * 0.5))
