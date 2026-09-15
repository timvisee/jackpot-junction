extends Node3D
## Development harness: Lucky Crossing, a player kart, a scripted dummy kart, the camera rig, the
## debug overlay (F3) and the tuning panel (F4).
##
## User arguments after "++": --screenshot=<path> saves a PNG of the viewport after --frames=<n>
## frames (default 60) and quits. Needs a display.

const ARENA_SCENE := preload("res://scenes/arena/arena.tscn")
const KART_SCENE := preload("res://scenes/kart/kart.tscn")
const CAMERA_SCENE := preload("res://scenes/camera/camera_rig.tscn")

var arena: Arena
var camera_rig: CameraRig
var karts: Array[Kart] = []

var _screenshot_path := ""
var _screenshot_frames := 60
var _frames := 0


func _ready() -> void:
	_add_environment()
	arena = ARENA_SCENE.instantiate()
	add_child(arena)
	camera_rig = CAMERA_SCENE.instantiate()
	add_child(camera_rig)
	camera_rig.frame_arena(arena.bounds())
	var player := _spawn_kart(0, 0, PlayerInput.new())
	var dummy := _spawn_kart(1, 3, ScriptedInput.new())
	camera_rig.targets.assign([player, dummy])
	var overlay := DebugOverlay.new()
	overlay.kart = player
	overlay.arena_width = arena.world_size().x
	add_child(overlay)
	var tuning := TuningPanel.new()
	tuning.stats = player.stats
	add_child(tuning)
	_parse_user_args()


func _process(_delta: float) -> void:
	if _screenshot_path.is_empty():
		return
	_frames += 1
	if _frames == _screenshot_frames:
		_save_screenshot()


func _spawn_kart(slot: int, spawn_index: int, input: KartInput) -> Kart:
	var kart: Kart = KART_SCENE.instantiate()
	kart.name = "Kart%d" % slot
	kart.slot = slot
	kart.input = input
	kart.position = arena.spawn_points[spawn_index]
	add_child(kart)
	kart.face(arena.junction_position - kart.position)
	karts.append(kart)
	return kart


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


func _save_screenshot() -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(_screenshot_path)
	print("screenshot %s: %s" % [_screenshot_path, error_string(error)])
	get_tree().quit()
