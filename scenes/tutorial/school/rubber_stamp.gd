class_name RubberStamp
extends Button
## The rubber stamp over the license, GAME.md 9.4a: a wooden handle on a red rubber base, hovering
## over the corner of the card and breathing a little, which is what asks to be pressed. A click,
## a tap, or Enter or A with the cursor on it, and it comes down: it lifts, slams onto the card,
## which is when the card takes its mark, see [LicenseCard], and fades away leaving the mark.
## A button, so every device presses it the way it presses any other.

## The stamp has come down on the card.
signal stamped

const SIZE := Vector2(150.0, 170.0)
const WOOD := Color(0.42, 0.27, 0.16)
const WOOD_LIGHT := Color(0.56, 0.38, 0.24)
const RUBBER := Color(0.72, 0.17, 0.14)
const RUBBER_DARK := Color(0.5, 0.11, 0.1)
const BASE := Color(0.16, 0.14, 0.14)
## How it breathes while it waits: how much it swells and leans, and how fast.
const BREATHE := 0.035
const LEAN := 0.05
const BREATHE_RATE := 1.7
## The slam: up and over, down hard, and settle, in seconds, and how long the stamp stays before
## it fades.
const LIFT := 0.22
const DROP := 0.07
const SETTLE := 0.12
const LINGER := 0.35
const FADE := 0.3

## Where it comes down, in its parent's space, or nowhere in particular for a stamp that lands
## where it hangs.
var lands_at := Vector2.INF

var _time := 0.0
var _slammed := false


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


func _process(delta: float) -> void:
	if _slammed:
		return
	_time += delta
	var lift := 1.0 if is_hovered() or has_focus() else 0.6
	scale = Vector2.ONE * (1.0 + sin(_time * BREATHE_RATE) * BREATHE * lift)
	rotation = sin(_time * BREATHE_RATE * 0.6) * LEAN
	queue_redraw()


## Comes down on the card: once.
func slam() -> void:
	if _slammed:
		return
	_slammed = true
	disabled = true
	focus_mode = Control.FOCUS_NONE
	rotation = 0.0
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


func _draw() -> void:
	var middle := SIZE.x * 0.5
	var lit := is_hovered() or has_focus()
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
	# A gold ring round it while the cursor is on it, the way the menu's buttons light.
	if lit and not _slammed:
		var ring := StyleBoxFlat.new()
		ring.draw_center = false
		ring.set_border_width_all(2)
		ring.border_color = Palette.CHIP_GOLD
		ring.set_corner_radius_all(14)
		draw_style_box(ring, Rect2(Vector2(middle - 70.0, 2.0), Vector2(140.0, 158.0)))
