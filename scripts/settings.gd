class_name Settings
extends RefCounted
## User settings from GAME.md 8.5, saved between sessions with ConfigFile. Nothing else is
## persisted yet.

const DEFAULT_PATH := "user://settings.cfg"
const AIM_ASSIST_MAX := 1.0

var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 1.0
## The engine and tires of the karts themselves, on their own bus under the effects, GAME.md 8.4.
var kart_volume := 1.0
## Music switched off entirely, toggled with the mute key.
var music_muted := false
var fullscreen := false
var vsync := true
var render_scale := 1.0
var screen_shake := true
var flash_reduction := false
## 0 to 1 of the default aim assist, never more.
var aim_assist := 1.0
var rumble := true
## Dots ahead of the cannon showing where shots go.
var aim_guide := true
## The moving-head lights over the arena, GAME.md 8.1.
var disco_lights := true
## The on-screen reminders of which button does what, GAME.md 8.3.
var control_hints := true
var stick_deadzone := 0.15
## Action name to the descriptors that replace its defaults.
var bindings: Dictionary = {}
var match_minutes := 5
var target_score := 3000
var bot_count := 3
var difficulty := "normal"
var item_set := "first"
## Whether a kart's own shots hurt it, GAME.md 5.1.
var own_bullets_hurt := false
var last_address := "127.0.0.1"
var last_port := 7777

var path := DEFAULT_PATH


func load_from_disk() -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	master_volume = file.get_value("audio", "master", master_volume)
	music_volume = file.get_value("audio", "music", music_volume)
	sfx_volume = file.get_value("audio", "sfx", sfx_volume)
	kart_volume = file.get_value("audio", "kart", kart_volume)
	music_muted = file.get_value("audio", "music_muted", music_muted)
	fullscreen = file.get_value("video", "fullscreen", fullscreen)
	vsync = file.get_value("video", "vsync", vsync)
	render_scale = file.get_value("video", "render_scale", render_scale)
	screen_shake = file.get_value("accessibility", "screen_shake", screen_shake)
	flash_reduction = file.get_value("accessibility", "flash_reduction", flash_reduction)
	aim_assist = clampf(
		file.get_value("accessibility", "aim_assist", aim_assist), 0.0, AIM_ASSIST_MAX
	)
	rumble = file.get_value("accessibility", "rumble", rumble)
	aim_guide = file.get_value("accessibility", "aim_guide", aim_guide)
	disco_lights = file.get_value("accessibility", "disco_lights", disco_lights)
	control_hints = file.get_value("accessibility", "control_hints", control_hints)
	stick_deadzone = file.get_value("controls", "stick_deadzone", stick_deadzone)
	bindings = file.get_value("controls", "bindings", {})
	match_minutes = file.get_value("lobby", "match_minutes", match_minutes)
	target_score = file.get_value("lobby", "target_score", target_score)
	bot_count = file.get_value("lobby", "bot_count", bot_count)
	difficulty = file.get_value("lobby", "difficulty", difficulty)
	item_set = file.get_value("lobby", "item_set", item_set)
	own_bullets_hurt = file.get_value("lobby", "own_bullets_hurt", own_bullets_hurt)
	last_address = file.get_value("online", "address", last_address)
	last_port = file.get_value("online", "port", last_port)


func save_to_disk() -> Error:
	var file := ConfigFile.new()
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "sfx", sfx_volume)
	file.set_value("audio", "kart", kart_volume)
	file.set_value("audio", "music_muted", music_muted)
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "vsync", vsync)
	file.set_value("video", "render_scale", render_scale)
	file.set_value("accessibility", "screen_shake", screen_shake)
	file.set_value("accessibility", "flash_reduction", flash_reduction)
	file.set_value("accessibility", "aim_assist", aim_assist)
	file.set_value("accessibility", "rumble", rumble)
	file.set_value("accessibility", "aim_guide", aim_guide)
	file.set_value("accessibility", "disco_lights", disco_lights)
	file.set_value("accessibility", "control_hints", control_hints)
	file.set_value("controls", "stick_deadzone", stick_deadzone)
	file.set_value("controls", "bindings", bindings)
	file.set_value("lobby", "match_minutes", match_minutes)
	file.set_value("lobby", "target_score", target_score)
	file.set_value("lobby", "bot_count", bot_count)
	file.set_value("lobby", "difficulty", difficulty)
	file.set_value("lobby", "item_set", item_set)
	file.set_value("lobby", "own_bullets_hurt", own_bullets_hurt)
	file.set_value("online", "address", last_address)
	file.set_value("online", "port", last_port)
	return file.save(path)


## Pushes every setting into the engine: buses, window, input map.
func apply(tree: SceneTree) -> void:
	apply_audio()
	apply_input()
	if not DisplayServer.get_name() == "headless":
		apply_video(tree)


func apply_audio() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	_set_bus("Kart", kart_volume)
	var music := AudioServer.get_bus_index("Music")
	if music >= 0 and music_muted:
		AudioServer.set_bus_mute(music, true)


func apply_video(tree: SceneTree) -> void:
	var mode := (
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	var wanted := DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != wanted:
		DisplayServer.window_set_vsync_mode(wanted)
	if tree != null and tree.root != null:
		tree.root.scaling_3d_scale = clampf(render_scale, 0.5, 1.0)


## Registers the default input map, then the player's rebindings and dead zone on top.
func apply_input() -> void:
	InputActions.register_defaults()
	for action: String in bindings:
		var descriptors: Array = bindings[action]
		var name := StringName(action)
		if not InputMap.has_action(name):
			continue
		InputMap.action_erase_events(name)
		for descriptor: Dictionary in descriptors:
			InputMap.action_add_event(name, InputActions.make_event(descriptor))
	for action: StringName in InputActions.STICK_ACTIONS:
		InputMap.action_set_deadzone(action, stick_deadzone)


## Records the current input map for an action as an override.
func remember_binding(action: StringName) -> void:
	bindings[String(action)] = InputActions.descriptors(action)


func reset_bindings() -> void:
	bindings = {}
	apply_input()


func _set_bus(bus: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.0001)
