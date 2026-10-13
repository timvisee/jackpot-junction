class_name ResultsPodium
extends SubViewportContainer
## The top three on a victory podium at the head of the results screen, GAME.md 3.8: the winner
## on the tallest step in the middle, second a little lower on one side and third the lowest on
## the other, each with their own kart standing on top of it turning slowly on the spot.
##
## A little 3D scene of its own in a viewport rather than a picture, because the karts are
## already models and a kart turning under a light says more about who won than a name in a list
## does. Its own world too, so none of the arena the match was played in leaks into it.

## The top three have been stood on it, see [method show_top].
signal stood

const SIZE := Vector2(940.0, 272.0)
## Where each place stands and how tall its step is, in meters: the winner in the middle, second
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
## The band of the player's own color round the top of their step, and how far it stands proud
## of it. Level with the step, the two faces fight over the same pixels and the gray shows
## through the color in patches.
const BAND_HEIGHT := 0.09
const BAND_LIFT := 0.03
const NUMBER_SIZE := 72

## How high over a kart on the podium its player's emote pops up, clear of the tallest hat, and how
## big it is drawn there, the picture being small, see [method Emotes.pop_over].
const EMOTE_HEIGHT := 1.72
const EMOTE_BIG := 0.62

var _viewport: SubViewport
var _stage: Node3D
var _karts: Array[Node3D] = []
## Who stands on each step, by the step, for their emotes, see [method _on_emoted].
var _standing: Array[PlayerSlot] = []


static func create() -> ResultsPodium:
	var podium := ResultsPodium.new()
	podium.name = "Podium"
	podium._build()
	return podium


## Stands the top three on it, tallest first, each kart with the plate it wore in the match on
## its back, GAME.md 4.4, the learner's L or its license plate, a bot's too. Called every time
## the screen is filled in, so it clears whatever was standing there before.
func show_top(standings: Array[PlayerSlot]) -> void:
	for child: Node in _stage.get_children():
		_stage.remove_child(child)
		child.free()
	_karts.clear()
	_standing.clear()
	var shown := mini(standings.size(), PLACES.size())
	for place: int in shown:
		_add_step(standings[place], place)
	# A full podium is already centered on the winner. A short one is not, so the whole thing is
	# slid over until what is standing on it sits in the middle of the picture.
	var middle := 0.0
	for place: int in shown:
		middle += PLACES[place].x
	_stage.position.x = -middle / maxf(shown, 1.0)
	visible = not _karts.is_empty()
	stood.emit()
	# Nothing is drawn until there is something to draw. A viewport set to update always does so
	# whether or not anybody can see it, and this one is hidden for the whole match.
	draw_while(visible)


## Where the winner stands in the picture, as a share of it across and down: the top of the
## middle of the tallest step, slid over with the rest on a short podium, for the lamps over the
## photo finish to be aimed at, see [PhotoBackdrop]. Worked out from the camera rather than asked
## of it, so it is known before anything is drawn.
func winner_at() -> Vector2:
	var camera := _viewport.get_node("Camera") as Camera3D
	var top := Vector3(_stage.position.x + PLACES[0].x, PLACES[0].y, 0.0)
	var seen := camera.transform.affine_inverse() * top
	if seen.z >= 0.0:
		return Vector2(0.5, 0.5)
	# Over the distance in front of the camera, against how far the picture's half height reaches.
	var reach := tan(deg_to_rad(camera.fov) * 0.5) * -seen.z
	var aspect := size.x / maxf(size.y, 1.0) if size.y > 0.0 else SIZE.x / SIZE.y
	return Vector2(0.5 + seen.x / (reach * aspect) * 0.5, 0.5 - seen.y / reach * 0.5)


## Drawn while [param seen], and not while it is not: hidden, or scrolled off the screen on a long
## slip, see [PayoutBill].
func draw_while(seen: bool) -> void:
	var mode := (
		SubViewport.UPDATE_ALWAYS if seen and not _karts.is_empty() else SubViewport.UPDATE_DISABLED
	)
	if _viewport.render_target_update_mode != mode:
		_viewport.render_target_update_mode = mode


func _process(delta: float) -> void:
	if not visible:
		return
	for kart: Node3D in _karts:
		kart.rotate_y(TAU * delta / SPIN_SECONDS)


## One step with its kart on top and its place painted on the front, and the plate the kart
## wore.
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
	band.position = Vector3(at.x, at.y - BAND_HEIGHT * 0.5 + BAND_LIFT, 0.0)
	_stage.add_child(band)
	_stage.add_child(_numeral(place + 1, at))
	var kart := Node3D.new()
	kart.name = "Kart%d" % place
	# Its wheels on the step: a model stands lifted in what is hung round it, see
	# [constant KartVisuals.MODEL_LIFT].
	kart.position = Vector3(at.x, at.y + BAND_LIFT - KartVisuals.MODEL_LIFT * KART_SCALE, 0.0)
	kart.scale = Vector3.ONE * KART_SCALE
	kart.rotation.y = KartVisuals.facing_soon(SPIN_SECONDS)
	var model := KartVisuals.display_model(slot.color_index, slot.style)
	kart.add_child(model)
	KartVisuals.plate_like(model, KartVisuals.plate_worn(slot.kart))
	_stage.add_child(kart)
	_karts.append(kart)
	_standing.append(slot)


func _ready() -> void:
	Events.emoted.connect(_on_emoted)


func _exit_tree() -> void:
	if Events.emoted.is_connected(_on_emoted):
		Events.emoted.disconnect(_on_emoted)


## Somebody on the podium has emoted, GAME.md 3.8: up it pops over their kart in the photo finish
## as well as over the kart itself, so it is seen where everybody is looking.
func _on_emoted(index: int, emote: int) -> void:
	if not visible:
		return
	for place: int in _standing.size():
		var slot := _standing[place]
		if slot.index == index:
			Emotes.pop_over(_karts[place], emote, slot.color(), EMOTE_HEIGHT, EMOTE_BIG)


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
