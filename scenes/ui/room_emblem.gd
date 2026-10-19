class_name RoomEmblem
extends Control
## The room's emblem on the pause menu's corner, GAME.md 8.1c: one small thing from the room the
## menu was opened over, its chip or its pinball or its hard hat, turning slowly in a view of its
## own, so the House's menu says which of its tables it is standing on. The emblem is the room's
## kit's to give, [method RoomKit.emblem]; a menu with no room under it shows none.

## How big it is drawn, in pixels of the menu, and how fast it turns, in turns a second.
const SIDE := 132.0
const TURNS := 0.12
## The viewport it is drawn in, a few times its size so its edges are smooth.
const PIXELS := 256

var _view: SubViewport
var _turning: Node3D


func _init() -> void:
	name = "RoomEmblem"
	custom_minimum_size = Vector2.ONE * SIDE
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


## Shows the emblem of the room [param arena] is built in, or nothing for no arena.
func show_for(arena: Arena) -> void:
	if _view != null:
		_view.queue_free()
		_view = null
	visible = arena != null and arena.kit != null
	if not visible:
		return
	_view = SubViewport.new()
	_view.own_world_3d = true
	_view.transparent_bg = true
	_view.size = Vector2i.ONE * PIXELS
	# Smoothed on the screen's side rather than with MSAA, which leaves a see-through viewport black.
	_view.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_view)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	environment.environment.ambient_light_energy = 0.8
	_view.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	key.light_energy = 1.4
	_view.add_child(key)
	var camera := Camera3D.new()
	# The emblem is drawn as it is, on nothing: a look's pass over it would fill the nothing in.
	camera.set_meta(RenderLook.NO_LOOK, true)
	camera.fov = 30.0
	camera.position = Vector3(0.0, 1.35, 2.3)
	_view.add_child(camera)
	camera.look_at(Vector3(0.0, 0.05, 0.0))
	_turning = Node3D.new()
	_view.add_child(_turning)
	var emblem := arena.kit.emblem()
	if emblem != null:
		_turning.add_child(emblem)
	var picture := TextureRect.new()
	picture.texture = _view.get_texture()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)


func _process(delta: float) -> void:
	if _turning != null and is_visible_in_tree():
		_turning.rotate_y(TURNS * TAU * delta)
