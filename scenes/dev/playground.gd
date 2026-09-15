extends Node3D
## Development harness: a match on Lucky Crossing with a player kart and a scripted dummy, plus
## the debug overlay (F3) and the tuning panel (F4).
##
## User arguments after "++":
##   --players=2          keyboard drives slot 0 and the first gamepad slot 1, no dummy
##   --screenshot=<path>  save a PNG of the viewport after --frames=<n> frames (default 60) and
##                        quit; needs a display

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var match_node: Match

var _players := 1
var _screenshot_path := ""
var _screenshot_frames := 60
var _frames := 0


func _ready() -> void:
	_parse_user_args()
	_add_environment()
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	add_child(match_node)
	var inputs: Array[KartInput] = []
	if _players >= 2:
		inputs.append(PlayerInput.new(DeviceInput.KEYBOARD))
		for joypad: int in range(0, _players - 1):
			inputs.append(PlayerInput.new(joypad))
	else:
		inputs.append(PlayerInput.new())
		inputs.append(ScriptedInput.new())
	match_node.start(inputs)
	var player := match_node.kart_of(0)
	var overlay := DebugOverlay.new()
	overlay.kart = player
	overlay.arena_width = match_node.arena.world_size().x
	add_child(overlay)
	var tuning := TuningPanel.new()
	tuning.stats = player.base_stats
	tuning.on_change = player.rebuild_stats
	add_child(tuning)


func _process(_delta: float) -> void:
	if _screenshot_path.is_empty():
		return
	_frames += 1
	if _frames == _screenshot_frames:
		_save_screenshot()


func _add_environment() -> void:
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	light.shadow_enabled = true
	light.light_energy = 1.2
	add_child(light)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#2A1E16")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.9, 0.86, 0.8)
	environment.ambient_light_energy = 0.55
	environment.ssao_enabled = true
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = environment
	add_child(world)


func _parse_user_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_screenshot_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--players="):
			_players = int(arg.get_slice("=", 1))


func _save_screenshot() -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(_screenshot_path)
	print("screenshot %s: %s" % [_screenshot_path, error_string(error)])
	get_tree().quit()
