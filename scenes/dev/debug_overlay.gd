class_name DebugOverlay
extends CanvasLayer
## F3 toggles a readout of one kart: speed, drift, boost, heading, fps, and how long the last
## crossing of the arena took, measured between two lines 3 m from each side wall.

const CROSSING_INSET := 3.0

var kart: Kart
var arena_width := 40.0

var _label: Label
var _crossing_side := 0
var _crossing_start := 0.0
var _last_crossing := 0.0


func _ready() -> void:
	layer = 10
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.position = Vector2(12.0, 0.0)
	_label.offset_bottom = -12.0
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F3:
		visible = not visible


func _process(_delta: float) -> void:
	if kart == null or not is_instance_valid(kart):
		return
	_track_crossing()
	if not visible:
		return
	var motor := kart.motor
	var state := "drift %.2fs" % motor.drift_time if motor.drifting else "grip"
	if motor.turboing():
		state += " turbo"
	if motor.boosting():
		state += " boost %.2f" % motor.boost_time_left
	var template := "fps %d\nspeed %.1f m/s (%.0f%%)\nforward %.1f\n%s\nheading %.0f deg\n"
	template += "last crossing %.2f s\n\nF3 overlay  F4 tuning"
	_label.text = (
		template
		% [
			Engine.get_frames_per_second(),
			motor.speed(),
			motor.speed_fraction() * 100.0,
			motor.forward_speed,
			state,
			rad_to_deg(motor.heading),
			_last_crossing,
		]
	)


func _track_crossing() -> void:
	var line := arena_width * 0.5 - CROSSING_INSET
	var x := kart.global_position.x
	var now := Time.get_ticks_msec() * 0.001
	var side := 0
	if x < -line:
		side = -1
	elif x > line:
		side = 1
	if side == 0 or side == _crossing_side:
		return
	if _crossing_side != 0:
		_last_crossing = now - _crossing_start
	_crossing_side = side
	_crossing_start = now
