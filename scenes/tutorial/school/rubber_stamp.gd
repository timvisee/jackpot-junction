class_name RubberStamp
extends Button
## The rubber stamp over the license, GAME.md 9.4a: a wooden handle on a red rubber base, hanging
## off the edge of the card over its own shadow, breathing a little and leaning after the mouse
## as it moves, which is what makes it look alive and asks to be pressed, with the control that
## presses it drawn under its base: the left mouse button, Enter, or the pad's accept, whichever
## was used last, and nothing on a touch screen, where a tap needs no picture. A click, a tap, or
## that control with the cursor on it, and it comes down: it lifts, swings over the card, slams
## onto it, which is when the card takes its mark, see [LicenseCard], and fades away leaving the
## mark. A button, so every device presses it the way it presses any other.

## The stamp has come down on the card.
signal stamped
## The device in hand changed, by what was last touched.
signal device_changed

enum Device { MOUSE, KEYBOARD, PAD, TOUCH }

const SIZE := Vector2(150.0, 170.0)
const WOOD := Color(0.42, 0.27, 0.16)
const WOOD_LIGHT := Color(0.56, 0.38, 0.24)
const RUBBER := Color(0.72, 0.17, 0.14)
const RUBBER_DARK := Color(0.5, 0.11, 0.1)
const BASE := Color(0.16, 0.14, 0.14)
const SHADOW := Color(0.0, 0.0, 0.0, 0.3)
## How it breathes while it waits: how much it swells and leans, and how fast.
const BREATHE := 0.035
const LEAN := 0.05
const BREATHE_RATE := 1.7
## How far it leans after the mouse, in pixels at most, and how quickly it follows.
const FOLLOW := 26.0
const FOLLOW_RATE := 9.0
## The slam: up and over, down hard, and settle, in seconds, and how long the stamp stays before
## it fades.
const LIFT := 0.22
const DROP := 0.07
const SETTLE := 0.12
const LINGER := 0.35
const FADE := 0.3
const GLYPH_SIZE := 18
const GLYPH_INK := Color(0.92, 0.92, 0.95)

## Where it comes down, in its parent's space, or nowhere in particular for a stamp that lands
## where it hangs.
var lands_at := Vector2.INF
## The device in hand, by what was last touched: the mouse unless the screen is one to touch.
var device := Device.MOUSE

var _time := 0.0
var _slammed := false
var _lean := Vector2.ZERO
var _lean_to := Vector2.ZERO
var _glyph: Control


static func create() -> RubberStamp:
	var stamp := RubberStamp.new()
	stamp.name = "Stamp"
	return stamp


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = Vector2(SIZE.x * 0.5, SIZE.y * 0.82)
	focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	pressed.connect(slam)
	pressed.connect(func() -> void: Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0))
	if TouchInput.enabled:
		device = Device.TOUCH
	elif not Game.last_input_keyboard:
		device = Device.PAD
	_show_glyph()


## What the stamp is pressed with, as a word: Tap, Click or Press.
func press_word() -> String:
	match device:
		Device.TOUCH:
			return "Tap"
		Device.MOUSE:
			return "Click"
		_:
			return "Press"


func _input(event: InputEvent) -> void:
	if _slammed:
		return
	var was := device
	if event is InputEventMouseMotion:
		device = Device.MOUSE
		var middle := global_position + (pivot_offset * scale).rotated(rotation)
		_lean_to = ((get_global_mouse_position() - middle) / 24.0).limit_length(FOLLOW)
	elif event is InputEventMouseButton:
		device = Device.MOUSE
	elif event is InputEventKey:
		device = Device.KEYBOARD
	elif event is InputEventJoypadButton:
		device = Device.PAD
	elif (
		event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5
	):
		device = Device.PAD
	elif event is InputEventScreenTouch:
		device = Device.TOUCH
	if device != was:
		_show_glyph()
		device_changed.emit()


func _process(delta: float) -> void:
	if _slammed:
		return
	_time += delta
	var lift := 1.0 if is_hovered() or has_focus() else 0.6
	scale = Vector2.ONE * (1.0 + sin(_time * BREATHE_RATE) * BREATHE * lift)
	rotation = sin(_time * BREATHE_RATE * 0.6) * LEAN
	_lean = _lean.lerp(_lean_to, 1.0 - exp(-FOLLOW_RATE * delta))
	queue_redraw()


## Comes down on the card: once.
func slam() -> void:
	if _slammed:
		return
	_slammed = true
	disabled = true
	focus_mode = Control.FOCUS_NONE
	rotation = 0.0
	_lean = Vector2.ZERO
	if _glyph != null:
		_glyph.visible = false
	var fall := create_tween()
	fall.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(self, "scale", Vector2.ONE * 1.35, LIFT)
	# Lifted, it swings over to where it lands.
	if lands_at.is_finite():
		fall.parallel().tween_property(self, "position", lands_at, LIFT)
	fall.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(self, "scale", Vector2.ONE * 0.9, DROP)
	fall.tween_callback(_land)
	fall.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	fall.tween_property(self, "scale", Vector2.ONE, SETTLE)
	fall.tween_interval(LINGER)
	fall.tween_property(self, "modulate:a", 0.0, FADE)
	fall.tween_callback(hide)


func _land() -> void:
	Audio.play_sfx(&"stamp", -2.0, 0.0)
	stamped.emit()


func has_slammed() -> bool:
	return _slammed


## The control that presses the stamp, under its base, for the device in hand: the left mouse
## button, the key or the pad button that accepts, and none for a touch screen.
func _show_glyph() -> void:
	if _glyph != null:
		remove_child(_glyph)
		_glyph.queue_free()
		_glyph = null
	var event: InputEvent = null
	match device:
		Device.MOUSE:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			event = click
		Device.KEYBOARD:
			event = InputActions.first_event(&"ui_accept", true)
		Device.PAD:
			event = InputActions.first_event(&"ui_accept", false)
	if event == null:
		return
	_glyph = InputGlyph.of_event(event, GLYPH_INK, GLYPH_SIZE)
	_glyph.position = Vector2((SIZE.x - _glyph.custom_minimum_size.x) * 0.5, SIZE.y - 14.0)
	add_child(_glyph)


func _draw() -> void:
	var middle := SIZE.x * 0.5
	var lifted := is_hovered() or has_focus()
	# The shadow it hangs over, further off and softer the higher it is held.
	var drop := Vector2(10.0, 14.0) if lifted else Vector2(6.0, 8.0)
	draw_set_transform(Vector2(middle, 148.0) + drop + _lean * 0.3, 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 66.0, SHADOW if not lifted else Color(SHADOW, 0.22))
	draw_set_transform(_lean, _lean.x * 0.004, Vector2.ONE)
	# The base: the rubber under a dark block, widest of all.
	var base := StyleBoxFlat.new()
	base.bg_color = BASE
	base.set_corner_radius_all(6)
	draw_style_box(base, Rect2(Vector2(middle - 62.0, 118.0), Vector2(124.0, 22.0)))
	var rubber := StyleBoxFlat.new()
	rubber.bg_color = RUBBER
	rubber.corner_radius_bottom_left = 8
	rubber.corner_radius_bottom_right = 8
	draw_style_box(rubber, Rect2(Vector2(middle - 58.0, 138.0), Vector2(116.0, 14.0)))
	draw_rect(Rect2(Vector2(middle - 58.0, 149.0), Vector2(116.0, 3.0)), RUBBER_DARK)
	# The handle: a shaft up from the base and a knob on top of it, with a highlight down one side.
	var shaft := StyleBoxFlat.new()
	shaft.bg_color = WOOD
	shaft.set_corner_radius_all(9)
	draw_style_box(shaft, Rect2(Vector2(middle - 17.0, 44.0), Vector2(34.0, 80.0)))
	draw_rect(Rect2(Vector2(middle - 11.0, 50.0), Vector2(6.0, 68.0)), WOOD_LIGHT)
	var knob := StyleBoxFlat.new()
	knob.bg_color = WOOD
	knob.set_corner_radius_all(24)
	draw_style_box(knob, Rect2(Vector2(middle - 36.0, 10.0), Vector2(72.0, 48.0)))
	draw_circle(Vector2(middle - 12.0, 26.0), 7.0, WOOD_LIGHT)
	draw_set_transform(Vector2.ZERO)
