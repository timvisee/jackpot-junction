extends Node3D
## The driving room: one kart, one track, nothing else. No bots, no bullets, no pickups and no
## clock, because the driving has to be worth doing on its own before any of that is worth
## adding. The track is laid out for the three things that tell you how a kart feels: a straight
## with braking gates, a slalom of posts, a ring to hold a constant turn around, and a block of
## tight corridors for close quarters.
##
## Tab cycles the handling presets under the kart without stopping it, so two of them can be
## compared on the same corner half a second apart, which is the only honest way to tell them
## apart. The kart keeps its speed and heading across the change.
##
## The readout shows what the model is actually doing rather than what it looks like it is doing:
## speed, how far the wheel is turned, how far the kart is sideways, how fast the nose is coming
## round and how hard the tires are working. Numbers make "it feels off" into something that can
## be chased.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/driving.tres")
const RULES: MatchRules = preload("res://data/match/driving.tres")
## Gravity, for reading lateral acceleration in g.
const G := 9.81
## How far back the camera sits. Close enough that the kart is worth watching, wide enough to
## see the next post coming.
const CAMERA_DISTANCE := 26.0
## The handling to try, in the order Tab walks through them. The first is what the game ships
## with today, so every other one is judged against it rather than against a memory of it, and
## each of the rest changes one thing, so a verdict on one of them says which thing.
const PRESETS: Array[String] = [
	"feel_shipped",
	"default",
	"feel_tighten",
	"feel_snapdrift",
]
const PRESET_NAMES: Array[String] = [
	"as it ships",
	"the kart now: oversteer drift",
	"the tighten drift it had before",
	"the kart now, with the instant drift ramp",
]

var match_node: Match

var _readout: Label
var _start := Vector3.ZERO
var _peak_lateral := 0.0
var _preset := 0
var _last_velocity := Vector3.ZERO


func _ready() -> void:
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	add_child(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0)]
	match_node.start(inputs)
	# A room for feeling the kart, not a nightclub.
	match_node.arena.disco.enabled = false
	match_node.camera_rig.follow_close(CAMERA_DISTANCE)
	_start = _kart().global_position
	_apply_preset()
	_build_readout()
	PauseMenu.add_to(self)


func _kart() -> Kart:
	return match_node.kart_of(0)


## Tab swaps the handling under the kart, R puts it back on the line: stopped, pointing down
## the straight, so a run can be repeated without driving back.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_TAB:
		_preset = (_preset + 1) % PRESETS.size()
		_apply_preset()
		get_viewport().set_input_as_handled()
		return
	if key.physical_keycode != KEY_R:
		return
	var kart := _kart()
	kart.global_position = _start
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.motor.velocity = Vector3.ZERO
	kart.motor.forward_speed = 0.0
	kart.motor.steer = 0.0
	_peak_lateral = 0.0
	get_viewport().set_input_as_handled()


## Puts the chosen handling under the kart mid-drive. Speed and heading are left alone: the
## point is to feel one model take over from another on the same corner.
func _apply_preset() -> void:
	var kart := _kart()
	kart.base_stats = load("res://data/kart/%s.tres" % PRESETS[_preset])
	kart.rebuild_stats()
	_peak_lateral = 0.0


func _process(_delta: float) -> void:
	var kart := _kart()
	if kart == null:
		return
	var motor := kart.motor
	var lateral := _lateral_g(motor, get_physics_process_delta_time())
	_peak_lateral = maxf(_peak_lateral, lateral)
	var slip := rad_to_deg(motor.slip_angle())
	_readout.text = (
		(
			"speed   %5.1f m/s   %3.0f km/h\n"
			+ "wheel   %5.0f %%\n"
			+ "slip    %5.1f deg\n"
			+ "yaw     %5.0f deg/s\n"
			+ "lateral %5.2f g   peak %.2f g\n"
			+ "%s\n\n"
			+ "[%d/%d] %s\n"
			+ "Tab handling    R reset    Esc pause"
		)
		% [
			motor.speed(),
			motor.speed() * 20.0,
			motor.steer * 100.0,
			slip,
			rad_to_deg(_yaw_rate(motor)),
			lateral,
			_peak_lateral,
			"DRIFT" if motor.drifting else "",
			_preset + 1,
			PRESETS.size(),
			PRESET_NAMES[_preset],
		]
	)


## How hard the tires are working, as the sideways part of the change in velocity. Read in g so
## it can be compared with a real vehicle: a road car holds about 0.9 g, a go-kart rather more.
func _lateral_g(motor: KartMotor, delta: float) -> float:
	if delta <= 0.0:
		return 0.0
	var change := (motor.velocity - _last_velocity) / delta
	_last_velocity = motor.velocity
	var right := motor.forward_vector().cross(Vector3.DOWN)
	return absf(change.dot(right)) / G


## The nose's turn rate, measured rather than asked for, so it reads the same whatever model is
## driving it.
func _yaw_rate(motor: KartMotor) -> float:
	var speed := motor.speed()
	if speed < 0.2:
		return 0.0
	var radius_turn := motor.velocity.normalized().cross(_last_velocity.normalized()).y
	return asin(clampf(radius_turn, -1.0, 1.0)) / maxf(get_physics_process_delta_time(), 0.0001)


func _build_readout() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Readout"
	add_child(layer)
	_readout = Label.new()
	_readout.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_readout.position = Vector2(16.0, 12.0)
	_readout.add_theme_font_size_override("font_size", 20)
	_readout.add_theme_color_override("font_color", Color.WHITE)
	HudText.shadowed(_readout, 2)
	layer.add_child(_readout)
