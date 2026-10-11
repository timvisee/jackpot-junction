class_name AimGuidePreview
extends SubViewportContainer
## The aim guide as it is set, GAME.md 8.5, on the Accessibility page under its switch: the first
## seat's kart on the Workbench's felt by the table's rail, a few chips left about, seen from the
## match camera's angle, its nose swinging slowly to and fro and the dots ahead of it as long, as
## big, as solid and in the color the settings say, built again the moment one changes; none while
## the guide is switched off. The dots are the guide's own, see [method AimGuide.make_dots], placed
## as it places them.

## How big it stands on the page, and how much of the felt it shows top to bottom, in meters: the
## longest guide with the kart behind it, about as big as the match's camera shows them.
const SIZE := Vector2(600.0, 170.0)
const SHOWS := 4.2
## The match camera's pitch, see [CameraRig], and the middle of what is shown.
const PITCH_DEG := 55.0
const MIDDLE := Vector3(6.1, 0.3, -0.45)
const ROOM := preload("res://data/rooms/workbench.tres")
## Where the table's rail runs along the far side, and the chips left on the felt: a stack and a
## few lying loose, each where it is and how many high.
const RAIL_Z := -2.75
const CHIPS: Array[Vector3] = [
	Vector3(10.4, 0.0, 1.15), Vector3(10.75, 0.0, 1.3), Vector3(2.6, 0.0, -1.5)
]
const STACKED: Array[int] = [4, 1, 2]
## How far ahead of the kart the first dot is measured from, as a kart's cannon has it, see
## [CannonStats].
const MUZZLE := 1.0
## How far the nose swings either way, in radians, and how long a swing there and back takes.
const SWING := 0.12
const SWING_SECONDS := 7.0
## The kart faces down the strip, +X: a model's nose is its -Z.
const FACING := -PI * 0.5

var _viewport: SubViewport
var _kart: Node3D
var _dots: Array[MeshInstance3D] = []
## What the dots and the kart were last built for, see [method AimGuide.wanted].
var _built := []
var _kart_for := []
var _age := 0.0


func _ready() -> void:
	custom_minimum_size = SIZE
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.name = "Felt"
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Palette.FELT
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.7, 0.66)
	environment.ambient_light_energy = 0.75
	world.environment = environment
	_viewport.world_3d = world
	add_child(_viewport)
	_dress(Surfaces.new(ROOM))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = SHOWS
	var pitch := deg_to_rad(PITCH_DEG)
	camera.look_at_from_position(
		MIDDLE + Vector3(0.0, sin(pitch), cos(pitch)) * 20.0, MIDDLE, Vector3.UP
	)
	_viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.1
	light.shadow_enabled = true
	light.rotation_degrees = Vector3(-62.0, -30.0, 0.0)
	_viewport.add_child(light)
	visibility_changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_age += delta
	if AimGuide.wanted() != _built:
		_build_dots()
	var turn := FACING + sin(_age * TAU / SWING_SECONDS) * SWING
	_kart.rotation.y = turn
	# The way the nose points, from the turn: a model's nose is its -Z.
	var ahead := Vector3(-sin(turn), 0.0, -cos(turn))
	AimGuide.place(_dots, _kart.position + ahead * MUZZLE, ahead)
	var on := Game.settings == null or Game.settings.aim_guide
	for dot: MeshInstance3D in _dots:
		dot.visible = on


## The felt, the rail along the far side of it and the chips on it.
func _dress(surfaces: Surfaces) -> void:
	var felt := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 12.0)
	felt.mesh = plane
	felt.material_override = surfaces.floor_top()
	felt.position = Vector3(MIDDLE.x, 0.0, 0.0)
	_viewport.add_child(felt)
	var rail := MeshInstance3D.new()
	var wood := BoxMesh.new()
	wood.size = Vector3(40.0, 0.32, 0.5)
	rail.mesh = wood
	rail.material_override = surfaces.surround()
	rail.position = Vector3(MIDDLE.x, 0.16, RAIL_Z - 0.25)
	_viewport.add_child(rail)
	# White, gold and black, never a player's color, which the dots may be in.
	var inks: Array[Color] = [Palette.CHIP_WHITE, Palette.CHIP_GOLD, Color(0.15, 0.15, 0.17)]
	for i: int in CHIPS.size():
		for high: int in STACKED[i]:
			var chip := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 0.16
			disc.bottom_radius = 0.16
			disc.height = 0.05
			disc.radial_segments = 16
			disc.rings = 1
			chip.mesh = disc
			chip.material_override = surfaces.painted(inks[(i + high) % inks.size()])
			chip.position = CHIPS[i] + Vector3(0.01 * high, 0.025 + 0.05 * high, 0.0)
			_viewport.add_child(chip)


## A thin edge of foil round it, as a frame.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(HouseTheme.FOIL, 0.55), false, 2.0)


## The first seat's kart, in its color and dress, built again should either have changed on another
## page since it was last shown, and the dots with it.
func _refresh() -> void:
	if not is_visible_in_tree() and _kart != null:
		return
	var settings := Game.settings
	var wanted := [_color_index(), settings.seat_style(0) if settings != null else []]
	if wanted == _kart_for:
		return
	_kart_for = wanted
	if _kart != null:
		_kart.queue_free()
	var style: KartStyle = KartStyle.from_array(wanted[1]) if settings != null else null
	_kart = KartVisuals.display_model(_color_index(), style)
	_kart.rotation.y = FACING
	_viewport.add_child(_kart)
	_build_dots()


func _build_dots() -> void:
	for dot: MeshInstance3D in _dots:
		dot.queue_free()
	_built = AimGuide.wanted()
	_dots = AimGuide.make_dots(Palette.player_color(_color_index()))
	for dot: MeshInstance3D in _dots:
		_viewport.add_child(dot)


## The first seat's color, its favorite or the one its place gives it, as its kart has it.
static func _color_index() -> int:
	var chosen := Game.settings.seat_color(0) if Game.settings != null else -1
	return maxi(chosen, 0)
