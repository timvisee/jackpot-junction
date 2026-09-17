class_name CameraRig
extends Node3D
## The fixed tilted camera from GAME.md 8.2. It frames the whole arena, pans a little toward the
## karts it tracks, zooms a little with their spread, and can shake.

## What a unit of tremble is worth as a shake. A beat at the top level should land between a
## kart being wrecked and a bomb going off: felt through the floor, not read off the screen.
const TREMBLE_SHAKE := 0.2

@export var pitch_degrees := 55.0
@export var base_fov := 35.0
@export var margin := 1.0
@export var pan_weight := 0.3
@export var pan_limit := 2.0
@export var zoom_min := 0.93
@export var zoom_max := 1.07
@export var smoothing := 0.6
@export var shake_decay := 4.0
## How far above the floor the ears sit, so a kart right under them is not at zero distance.
## [member KartSoundStats.unit_size] has to match it: that is the distance a kart plays at its
## written level, so the two moving apart quietly changes every level in the kart mix.
@export var listener_height := 2.5
## The thump of the room at its most frantic, fed every frame and shaped by whoever sets it.
var tremble := 0.0

var targets: Array[Node3D] = []
## The karts somebody is driving on this machine. The ears sit over them rather than up at the
## camera, which frames the whole room from far enough away that every kart would sound the
## same distance off, GAME.md 8.4. Facing is the camera's, so left on screen is left in the mix.
var listener_targets: Array[Node3D] = []
var camera: Camera3D
var listener: AudioListener3D

var _center := Vector3.ZERO
var _arena_size := Vector2(40.0, 22.5)
var _wall_height := 1.0
var _distance := 40.0
var _pan := Vector3.ZERO
var _zoom := 1.0
var _shake := 0.0
var _framed := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.near = 0.5
	camera.far = 300.0
	camera.fov = base_fov
	add_child(camera)
	camera.make_current()
	listener = AudioListener3D.new()
	listener.name = "Listener"
	listener.top_level = true
	add_child(listener)
	listener.make_current()
	get_viewport().size_changed.connect(_refit)
	_place(_distance, Vector3.ZERO, 1.0)
	_place_listener()


## Frames an arena so that its whole bounding box, plus the margin, stays on screen.
func frame_arena(bounds: AABB) -> void:
	_center = Vector3(bounds.get_center().x, 0.0, bounds.get_center().z)
	_arena_size = Vector2(bounds.size.x, bounds.size.z)
	_wall_height = bounds.size.y
	_framed = true
	_distance = _fit_distance()
	_pan = Vector3.ZERO
	_zoom = 1.0
	_place(_distance, _pan, _zoom)


## Follows its targets from close in rather than framing the whole arena, for the driving room
## of GAME.md 9.5: a kart twenty pixels tall tells you nothing about how it drives.
func follow_close(distance: float) -> void:
	_framed = false
	_distance = distance
	pan_weight = 1.0
	pan_limit = 1000.0
	smoothing = 0.25


func _refit() -> void:
	if _framed:
		_distance = _fit_distance()


## Kicks the camera; the offset decays on its own.
func shake(strength: float) -> void:
	if not Game.settings.screen_shake:
		return
	_shake = maxf(_shake, strength)


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-delta / maxf(smoothing, 0.001))
	_pan = _pan.lerp(_target_pan(), blend)
	_zoom = lerpf(_zoom, _target_zoom(), blend)
	_shake = maxf(_shake - shake_decay * delta * maxf(_shake, 0.1), 0.0)
	if tremble > 0.0:
		shake(tremble * TREMBLE_SHAKE)
	_place(_distance, _pan, _zoom)
	_place_listener()


## Puts the ears over the karts being driven here, facing the way the camera does. With nobody
## to follow they sit where the camera is looking, so the room still sounds like it is in front.
func _place_listener() -> void:
	if listener == null:
		return
	var centre := _center + _pan
	var alive := _valid(listener_targets)
	if not alive.is_empty():
		centre = Vector3.ZERO
		for target: Node3D in alive:
			centre += target.global_position
		centre /= alive.size()
	listener.global_position = Vector3(centre.x, listener_height, centre.z)
	listener.global_basis = camera.global_basis


func _alive_targets() -> Array[Node3D]:
	return _valid(targets)


static func _valid(list: Array[Node3D]) -> Array[Node3D]:
	var alive: Array[Node3D] = []
	for target: Node3D in list:
		if is_instance_valid(target) and target.is_inside_tree():
			alive.append(target)
	return alive


func _target_pan() -> Vector3:
	var alive := _alive_targets()
	if alive.is_empty():
		return Vector3.ZERO
	var centroid := Vector3.ZERO
	for target: Node3D in alive:
		centroid += target.global_position
	centroid /= alive.size()
	var offset := (centroid - _center) * pan_weight
	offset.y = 0.0
	return offset.limit_length(pan_limit)


func _target_zoom() -> float:
	var alive := _alive_targets()
	if alive.size() < 2:
		return 1.0
	var centroid := Vector3.ZERO
	for target: Node3D in alive:
		centroid += target.global_position
	centroid /= alive.size()
	var spread := 0.0
	for target: Node3D in alive:
		spread = maxf(spread, centroid.distance_to(target.global_position))
	var max_spread := _arena_size.length() * 0.5
	return remap(clampf(spread, 0.0, max_spread), 0.0, max_spread, zoom_min, zoom_max)


func _place(distance: float, pan: Vector3, zoom: float) -> void:
	var pitch := deg_to_rad(pitch_degrees)
	var look_at_point := _center + pan
	var offset := Vector3(0.0, sin(pitch), cos(pitch)) * distance
	if _shake > 0.0:
		offset += (
			Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), 0.0) * _shake * 0.3
		)
	camera.position = look_at_point + offset
	camera.look_at_from_position(camera.position, look_at_point, Vector3.UP)
	camera.fov = base_fov * zoom


## Smallest distance at which every corner of the arena, with margin, projects inside the view.
## Computed from the camera's own geometry: Godot's frustum queries only work after a frame has
## rendered, and this has to work at load.
func _fit_distance() -> float:
	var half := _arena_size * 0.5 + Vector2.ONE * margin
	var corners: Array[Vector3] = []
	for x: int in [-1, 1]:
		for z: int in [-1, 1]:
			corners.append(_center + Vector3(x * half.x, 0.0, z * half.y))
			corners.append(_center + Vector3(x * half.x, _wall_height, z * half.y))
	var low := 1.0
	var high := 1000.0
	for i: int in 60:
		var mid := (low + high) * 0.5
		if _all_inside(corners, mid):
			high = mid
		else:
			low = mid
	return high


## Aspect ratio of the viewport the camera renders to.
func _aspect() -> float:
	var size := get_viewport().get_visible_rect().size
	if size.y <= 0.0:
		return 16.0 / 9.0
	return size.x / size.y


## True when every point projects inside the view for a camera at [param distance] with the
## tightest zoom.
func _all_inside(points: Array[Vector3], distance: float) -> bool:
	var pitch := deg_to_rad(pitch_degrees)
	var position := _center + Vector3(0.0, sin(pitch), cos(pitch)) * distance
	var view := (
		Transform3D(Basis.looking_at(_center - position, Vector3.UP), position).affine_inverse()
	)
	var tan_half_v := tan(deg_to_rad(base_fov * zoom_min) * 0.5)
	var tan_half_h := tan_half_v * _aspect()
	for point: Vector3 in points:
		var local := view * point
		var depth := -local.z
		if depth <= camera.near:
			return false
		if absf(local.x) > depth * tan_half_h or absf(local.y) > depth * tan_half_v:
			return false
	return true
