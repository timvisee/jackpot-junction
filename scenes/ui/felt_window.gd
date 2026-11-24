class_name FeltWindow
extends SubViewportContainer
## A window onto a strip of felt, GAME.md 8.5, for a page of settings to show what one of them looks
## like on the table, as the Accessibility page does the aim guide, see [AimGuidePreview], and the
## rings and the marker, see [KartMarksPreview]: the Workbench's felt by the table's rail, a few
## chips left about, seen from the match camera's angle through a window with rounded corners,
## darker toward its edge, in a frame of foil. What a page shows goes in [member felt].

## How big it stands on the page, and how much of the felt it shows top to bottom, in meters: a kart
## about as big as the match's camera shows one, in a window narrow enough for a column of its own
## beside another, see [SettingsColumns].
const SIZE := Vector2(560.0, 159.0)
const SHOWS := 4.2
## The match camera's pitch, see [CameraRig], and the middle of what is shown.
const PITCH_DEG := 55.0
const MIDDLE := Vector3(6.1, 0.3, -0.45)
const ROOM := preload("res://data/rooms/workbench.tres")
## Where the table's rail runs along the far side.
const RAIL_Z := -2.75
## The window: how round its corners, and its frame's edge.
const WINDOW := preload("res://scenes/ui/rounded_window.gdshader")
const RADIUS := 14.0
const FRAME := 2.0
const FRAME_INK := Color(HouseTheme.FOIL, 0.75)
## The chips' inks, white, gold and black, never a player's color, which what is shown may be in.
const CHIP_INKS: Array[Color] = [Palette.CHIP_WHITE, Palette.CHIP_GOLD, Color(0.15, 0.15, 0.17)]

## The world seen through it, to put what is shown in, and the camera that sees it.
var felt: SubViewport
var camera: Camera3D


func _ready() -> void:
	custom_minimum_size = SIZE
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	felt = SubViewport.new()
	felt.name = "Felt"
	felt.own_world_3d = true
	felt.msaa_3d = Viewport.MSAA_4X
	felt.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Palette.FELT
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.7, 0.66)
	environment.ambient_light_energy = 0.75
	world.environment = environment
	felt.world_3d = world
	add_child(felt)
	_dress(Surfaces.new(ROOM))
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = SHOWS
	var pitch := deg_to_rad(PITCH_DEG)
	camera.look_at_from_position(
		MIDDLE + Vector3(0.0, sin(pitch), cos(pitch)) * 20.0, MIDDLE, Vector3.UP
	)
	felt.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.1
	light.shadow_enabled = true
	light.rotation_degrees = Vector3(-62.0, -30.0, 0.0)
	felt.add_child(light)
	_frame()


## The chips left on the felt, each where it stands and how many high, clear of what is shown.
func _chips() -> Array[Vector4]:
	return []


## The felt, the rail along the far side of it and the chips on it.
func _dress(surfaces: Surfaces) -> void:
	var cloth := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 12.0)
	cloth.mesh = plane
	cloth.material_override = surfaces.floor_top()
	cloth.position = Vector3(MIDDLE.x, 0.0, 0.0)
	felt.add_child(cloth)
	var rail := MeshInstance3D.new()
	var wood := BoxMesh.new()
	wood.size = Vector3(40.0, 0.32, 0.5)
	rail.mesh = wood
	rail.material_override = surfaces.surround()
	rail.position = Vector3(MIDDLE.x, 0.16, RAIL_Z - 0.25)
	felt.add_child(rail)
	var chips := _chips()
	for i: int in chips.size():
		for high: int in int(chips[i].w):
			var chip := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 0.16
			disc.bottom_radius = 0.16
			disc.height = 0.05
			disc.radial_segments = 16
			disc.rings = 1
			chip.mesh = disc
			chip.material_override = surfaces.painted(CHIP_INKS[(i + high) % CHIP_INKS.size()])
			var stands := Vector3(chips[i].x, chips[i].y, chips[i].z)
			chip.position = stands + Vector3(0.01 * high, 0.025 + 0.05 * high, 0.0)
			felt.add_child(chip)


## The window its picture is seen through, and the frame of foil round it, drawn over the picture
## rather than through the window, which would cut it.
func _frame() -> void:
	var window := ShaderMaterial.new()
	window.shader = WINDOW
	window.set_shader_parameter("radius", RADIUS)
	material = window
	var edge := StyleBoxFlat.new()
	edge.draw_center = false
	edge.set_corner_radius_all(roundi(RADIUS))
	edge.set_border_width_all(roundi(FRAME))
	edge.border_color = FRAME_INK
	edge.anti_aliasing = true
	var frame := Panel.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", edge)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	resized.connect(func() -> void: window.set_shader_parameter("box", size))
	window.set_shader_parameter("box", size)
