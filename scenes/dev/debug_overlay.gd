class_name DebugOverlay
extends CanvasLayer
## F3 toggles a readout of one kart: speed, drift, boost, heading, fps, how long the last
## crossing of the arena took, measured between two lines 3 m from each side wall, and the
## music layers and the excitement meter. Given a match instead of a kart it follows the first
## local human.

const CROSSING_INSET := 3.0

var kart: Kart
var match_node: Match
## The room's session, when it has one. Online it holds what this client's own kart is doing
## ahead of the host, GAME.md 10.3, which is worth being able to look at while playing.
var session: NetSession
var arena_width := 40.0

var _label: Label
var _crossing_side := 0
var _crossing_start := 0.0
var _last_crossing := 0.0


## Hangs one over a room, watching that room's match and hidden until F3 asks for it. Every
## room that runs a match wants exactly this, so it is worth one call rather than five lines.
static func add_to(parent: Node, watching: Match, net: NetSession = null) -> DebugOverlay:
	var overlay := DebugOverlay.new()
	overlay.name = "DebugOverlay"
	overlay.match_node = watching
	overlay.session = net
	overlay.visible = false
	parent.add_child(overlay)
	return overlay


func _ready() -> void:
	layer = 10
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.position = Vector2(12.0, 0.0)
	_label.offset_bottom = -12.0
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color.WHITE)
	HudText.shadowed(_label, 1)
	add_child(_label)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F3:
		visible = not visible


func _process(_delta: float) -> void:
	if (kart == null or not is_instance_valid(kart)) and match_node != null:
		_find_kart()
	if kart == null or not is_instance_valid(kart):
		if visible:
			_label.text = (
				"fps %d\n%s\n%s\n%s\n\nF3 overlay"
				% [
					Engine.get_frames_per_second(),
					_intensity_text(),
					Audio.music_debug(),
					Story.debug_text(),
				]
			)
		return
	_track_crossing()
	if not visible:
		return
	var motor := kart.motor
	var state := "drift %.2fs" % motor.drift_time if motor.drifting else "grip"
	state += "  slip %.0f deg" % rad_to_deg(motor.slip_angle())
	if motor.turboing():
		state += " turbo"
	if motor.boosting():
		state += " boost %.2f" % motor.boost_time_left
	var template := "fps %d\nspeed %.1f m/s (%.0f%%)\nforward %.1f\n%s\nheading %.0f deg\n"
	template += "last crossing %.2f s\n%s\n%s\n%s%s\n%s\n\nF3 overlay  F4 tuning"
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
			_intensity_text(),
			Audio.music_debug(),
			kart.sound.debug_text() if kart.sound != null else "engine -",
			_prediction_text(),
			Story.debug_text(),
		]
	)


func _prediction_text() -> String:
	if session == null:
		return ""
	var line := session.prediction_debug()
	return "" if line.is_empty() else "\n" + line


func _intensity_text() -> String:
	if match_node == null or match_node.intensity == null:
		return "intensity -"
	return match_node.intensity.debug_text()


func _find_kart() -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human() and slot.kart != null:
			kart = slot.kart
			arena_width = match_node.arena.world_size().x
			return


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
