class_name LoyaltyCursor
extends Node
## The loyalty program's cursor, GAME.md 8.9: a toy kart in the player's color and dress, the
## profile playing's first kart, standing at the landmark chosen and driving the roads to the next
## one chosen, unhurried, turning to face the way it goes: the map and its pane never wait for it.
## Rendered on a sheet of its own from above, and shown as a paper cut-out lying on the map, its
## colors printed flat in a few tones, a border of paper round it with an ink edge and its shadow
## under it, see paper_cutout.gdshader, for [LoyaltyMapView] to draw where it is.

## It has moved or turned, and needs drawing again.
signal moved
## It has come to the landmark [param id] at the end of a drive.
signal arrived(id: StringName)

## The sheet the kart is rendered on, and how much of the scene it shows, in meters across; and the
## look that makes a paper cut-out of it.
const PIXELS := Vector2i(160, 160)
const SHOWS := 2.5
const CUTOUT := preload("res://scenes/loyalty/paper_cutout.gdshader")
## How fast it drives, in the map's own pixels a second, and the longest any one drive takes,
## however far it goes: a toy driven along, but never a crawl across the whole map.
const SPEED := 420.0
const LONGEST := 6.0
## How quickly it comes round to face the way it goes, a share of the way each second.
const TURN := 16.0

## The landmark it stands at, or is on its way to.
var at: StringName
## Where it is on the map, in the map's own pixels, and which way it faces there.
var point := Vector2.ZERO
var heading := Vector2.RIGHT

var _path := PackedVector2Array()
var _lengths := PackedFloat32Array()
var _along := 0.0
## The end of the stretch of [member _path] it is on.
var _stretch := 1
var _speed := SPEED
var _viewport: SubViewport
## The sheet the kart's is shown on as a paper cut-out, which is what is drawn.
var _paper: SubViewport
var _kart: Node3D
var _turned := 0.0


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Sheet"
	_viewport.size = PIXELS
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.7, 0.68, 0.66)
	environment.ambient_light_energy = 0.9
	world.environment = environment
	_viewport.world_3d = world
	add_child(_viewport)
	var settings := Game.settings
	_kart = KartVisuals.display_model(
		maxi(settings.seat_color(0), 0), KartStyle.from_array(settings.seat_style(0))
	)
	_viewport.add_child(_kart)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = SHOWS
	# Steeply from above, so it lies flat on the map as a cut-out would.
	camera.look_at_from_position(Vector3(0.0, 6.0, 2.6), Vector3(0.0, 0.5, 0.0), Vector3.UP)
	_viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.15
	light.rotation_degrees = Vector3(-58.0, -35.0, 0.0)
	_viewport.add_child(light)
	_paper = SubViewport.new()
	_paper.name = "Paper"
	_paper.size = PIXELS
	_paper.transparent_bg = true
	_paper.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_paper)
	var shown := TextureRect.new()
	shown.name = "Cutout"
	shown.texture = _viewport.get_texture()
	shown.size = Vector2(PIXELS)
	var look := ShaderMaterial.new()
	look.shader = CUTOUT
	shown.material = look
	_paper.add_child(shown)
	_turned = _yaw(heading)
	_kart.rotation.y = _turned


## The kart as it is drawn now, a paper cut-out.
func texture() -> Texture2D:
	return _paper.get_texture() if _paper != null else null


## Stands it at the landmark [param id], at [param where] on the map, facing [param facing].
func place(id: StringName, where: Vector2, facing := Vector2.RIGHT) -> void:
	at = id
	point = where
	heading = facing
	_path = PackedVector2Array()
	_turned = _yaw(heading)
	if _kart != null:
		_kart.rotation.y = _turned
	moved.emit()


## Drives it along [param points] on the map to the landmark [param to], from where it is; on its
## way somewhere already, it goes there first and on from there, so it never jumps.
func drive(points: PackedVector2Array, to: StringName) -> void:
	at = to
	var path := PackedVector2Array([point])
	if is_driving():
		path.append_array(_path.slice(_stretch))
	path.append_array(points)
	_path = path
	_stretch = 1
	_lengths = PackedFloat32Array([0.0])
	for i: int in range(1, _path.size()):
		_lengths.append(_lengths[i - 1] + _path[i - 1].distance_to(_path[i]))
	_along = 0.0
	var whole := _lengths[-1]
	_speed = maxf(SPEED, whole / LONGEST)
	if whole <= 0.0:
		_path = PackedVector2Array()
		arrived.emit(to)


## Whether it is on its way somewhere.
func is_driving() -> bool:
	return not _path.is_empty()


## There at once, wherever it was going.
func finish() -> void:
	if not is_driving():
		return
	_along = _lengths[-1]
	_advance(0.0)


func _process(delta: float) -> void:
	if is_driving():
		_along += _speed * delta
		_advance(delta)
	if _kart == null:
		return
	var wanted := _yaw(heading)
	if absf(angle_difference(_turned, wanted)) > 0.001:
		_turned = lerp_angle(_turned, wanted, 1.0 - exp(-TURN * delta))
		_kart.rotation.y = _turned
		moved.emit()


## Moves it to [member _along] of its way, facing along the stretch it is on, and says it has come
## at the end.
func _advance(_delta: float) -> void:
	var whole := _lengths[-1]
	var gone := minf(_along, whole)
	var i := 1
	while i < _lengths.size() - 1 and _lengths[i] < gone:
		i += 1
	_stretch = i
	var stretch := _path[i] - _path[i - 1]
	var into := (
		0.0
		if _lengths[i] <= _lengths[i - 1]
		else ((gone - _lengths[i - 1]) / (_lengths[i] - _lengths[i - 1]))
	)
	point = _path[i - 1].lerp(_path[i], clampf(into, 0.0, 1.0))
	if stretch.length() > 0.5:
		heading = stretch.normalized()
	moved.emit()
	if gone >= whole:
		_path = PackedVector2Array()
		arrived.emit(at)


## The kart's turn that faces it [param way] on the map seen from above, its nose up the map at
## none: the model's nose is its -Z, which the camera sees as up.
static func _yaw(way: Vector2) -> float:
	return atan2(-way.x, -way.y)
