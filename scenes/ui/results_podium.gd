class_name ResultsPodium
extends SubViewportContainer
## The top three on a victory podium at the head of the results screen, GAME.md 3.8: the winner
## on the tallest step in the middle, second a little lower on one side and third the lowest on
## the other, each with their own kart standing on top of it turning slowly on the spot.
##
## A little 3D scene of its own in a viewport rather than a picture, because the karts are
## already models and a kart turning under a light says more about who won than a name in a list
## does. Its own world too, so none of the arena the match was played in leaks into it.

const SIZE := Vector2(940.0, 272.0)
## Where each place stands and how tall its step is, in metres: the winner in the middle, second
## to the left a little lower, third to the right and lowest of all.
const PLACES: Array[Vector2] = [Vector2(0.0, 1.15), Vector2(-2.3, 0.88), Vector2(2.3, 0.66)]
const STEP_WIDTH := 1.9
const STEP_DEPTH := 1.9
## Seconds for a kart to turn all the way round.
const SPIN_SECONDS := 7.0
## Room over the karts for the tallest hat anybody can wear, GAME.md 4.4, without the picture
## being mostly sky for everybody who is not wearing one.
const KART_SCALE := 1.05
const STEP_COLOR := Color(0.14, 0.14, 0.18)
## The band of the player's own colour round the top of their step.
const BAND_HEIGHT := 0.09
const NUMBER_SIZE := 72

var _viewport: SubViewport
var _stage: Node3D
var _karts: Array[Node3D] = []


static func create() -> ResultsPodium:
	var podium := ResultsPodium.new()
	podium.name = "Podium"
	podium._build()
	return podium


## Stands the top three on it, tallest first. Called every time the screen is filled in, so it
## clears whatever was standing there before.
func show_top(standings: Array[PlayerSlot]) -> void:
	for child: Node in _stage.get_children():
		_stage.remove_child(child)
		child.free()
	_karts.clear()
	var shown := mini(standings.size(), PLACES.size())
	for place: int in shown:
		_add_step(standings[place], place)
	# A full podium is already centred on the winner. A short one is not, so the whole thing is
	# slid over until what is standing on it sits in the middle of the picture.
	var middle := 0.0
	for place: int in shown:
		middle += PLACES[place].x
	_stage.position.x = -middle / maxf(shown, 1.0)
	visible = not _karts.is_empty()
	# Nothing is drawn until there is something to draw. A viewport set to update always does so
	# whether or not anybody can see it, and this one is hidden for the whole match.
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	)


func _process(delta: float) -> void:
	if not visible:
		return
	for kart: Node3D in _karts:
		kart.rotate_y(TAU * delta / SPIN_SECONDS)


## One step with its kart on top and its place painted on the front.
func _add_step(slot: PlayerSlot, place: int) -> void:
	var at := PLACES[place]
	var step := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(STEP_WIDTH, at.y, STEP_DEPTH)
	step.mesh = box
	step.material_override = _material(STEP_COLOR)
	step.position = Vector3(at.x, at.y * 0.5, 0.0)
	_stage.add_child(step)
	var band := MeshInstance3D.new()
	var band_box := BoxMesh.new()
	band_box.size = Vector3(STEP_WIDTH + 0.06, BAND_HEIGHT, STEP_DEPTH + 0.06)
	band.mesh = band_box
	band.material_override = _material(slot.color(), true)
	band.position = Vector3(at.x, at.y - BAND_HEIGHT * 0.5, 0.0)
	_stage.add_child(band)
	_stage.add_child(_numeral(place + 1, at))
	var kart := Node3D.new()
	kart.name = "Kart%d" % place
	kart.position = Vector3(at.x, at.y, 0.0)
	kart.scale = Vector3.ONE * KART_SCALE
	kart.add_child(KartVisuals.display_model(slot.color_index, slot.style))
	_stage.add_child(kart)
	_karts.append(kart)


## The place, painted large on the front face of the step.
func _numeral(place: int, at: Vector2) -> Label3D:
	var label := Label3D.new()
	label.text = str(place)
	label.font_size = NUMBER_SIZE
	label.pixel_size = 0.006
	label.modulate = Color(0.85, 0.85, 0.9)
	label.outline_size = 0
	label.no_depth_test = false
	label.position = Vector3(at.x, at.y * 0.55, STEP_DEPTH * 0.5 + 0.01)
	return label


func _material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if glowing:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.9
	return material


func _build() -> void:
	custom_minimum_size = SIZE
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.name = "Stage"
	_viewport.size = Vector2i(SIZE)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.world_3d = _world()
	add_child(_viewport)
	_stage = Node3D.new()
	_stage.name = "Podium"
	_viewport.add_child(_stage)
	_viewport.add_child(_camera())
	_viewport.add_child(_key_light())


## A world of its own with nothing in it but an even light, so the podium is lit the same
## whatever the arena behind it was doing.
func _world() -> World3D:
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.62, 0.7)
	environment.ambient_light_energy = 1.0
	world.environment = environment
	return world


## Aimed a little above the steps rather than at them, so the karts have air over their heads
## instead of being cut off by the top edge and the picture is not all sky underneath them.
func _camera() -> Camera3D:
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.fov = 40.0
	camera.position = Vector3(0.0, 2.15, 6.6)
	camera.look_at_from_position(camera.position, Vector3(0.0, 1.25, 0.0), Vector3.UP)
	return camera


func _key_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "Key"
	light.light_energy = 1.1
	light.rotation_degrees = Vector3(-38.0, -32.0, 0.0)
	light.shadow_enabled = false
	return light
