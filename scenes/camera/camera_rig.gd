class_name CameraRig
extends Node3D
## The tilted camera from GAME.md 8.2. It frames the karts rather than the arena: it comes in as
## close as it can while keeping every kart it tracks on screen, follows them about the floor,
## and can shake.
##
## Framing the whole room meant the room was always the subject. Most of a match happens in a
## corner of it, and the table, the crowd and two empty thirds of the felt were taking up the
## screen while the karts were eight pixels of it. What has to be visible is every kart; the rest
## of the arena is scenery and can go off the edge.

## What a unit of tremble is worth as a shake. A beat at the top level should land between a
## kart being wrecked and a bomb going off: felt through the floor, not read off the screen.
const TREMBLE_SHAKE := 0.2

@export var pitch_degrees := 55.0
@export var base_fov := 35.0
@export var margin := 1.0
@export var pan_weight := 1.0
@export var pan_limit := 2.0
## The fit is worked out against a slightly narrower view than the camera really has, which is
## the margin that keeps a kart off the very edge of the screen.
@export var zoom_min := 0.93
@export var smoothing := 0.6
## Metres of floor left around the karts when the camera comes in on them, and the closest it is
## ever allowed to get however tightly they are packed.
@export var follow_margin := 6.0
@export var follow_min_distance := 30.0
## How fast the distance follows the karts spreading out and closing up. Slower than the pan on
## purpose: a camera that pumps in and out with every bump is worse than one that is too far off.
@export var distance_smoothing := 1.2
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
## The furthest back it ever goes: the distance that holds the whole arena, which is where it
## sits when there is nobody to follow.
var _arena_distance := 40.0
var _pan := Vector3.ZERO
var _zoom := 1.0
var _shake := 0.0
var _framed := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# The camera and the ears are placed every drawn frame, smoothed here rather than by the
	# engine: they follow karts that move on the physics tick, but the following itself is what
	# the smoothing in [method _process] is for. Left interpolated, the engine would smooth an
	# already smoothed transform and warn on every frame that it was moved outside a physics
	# tick, which is the only place this rig ever moves it.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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


## Takes an arena to work in: its middle to pan around, and its size for the furthest the camera
## ever pulls back to. From there the framing is the karts' business, see [method _target_distance].
func frame_arena(bounds: AABB) -> void:
	_center = Vector3(bounds.get_center().x, 0.0, bounds.get_center().z)
	_arena_size = Vector2(bounds.size.x, bounds.size.z)
	_wall_height = bounds.size.y
	_framed = true
	_arena_distance = _fit_distance()
	_distance = _arena_distance
	# Far enough to follow the karts anywhere on the floor, and no further: the look-at point
	# stays over the table, so the camera never ends up studying the crowd.
	pan_limit = maxf(_arena_size.x, _arena_size.y) * 0.5
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
		_arena_distance = _fit_distance()


## Kicks the camera; the offset decays on its own.
func shake(strength: float) -> void:
	if not Game.settings.screen_shake:
		return
	_shake = maxf(_shake, strength)


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-delta / maxf(smoothing, 0.001))
	_pan = _pan.lerp(_target_pan(), blend)
	_zoom = lerpf(_zoom, _target_zoom(), blend)
	var creep := 1.0 - exp(-delta / maxf(distance_smoothing, 0.001))
	_distance = lerpf(_distance, _target_distance(), creep)
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


## The middle of everybody rather than the average of them: with the camera framing the karts,
## what has to sit in the middle of the screen is the middle of the box they are all in, or the
## one furthest out is the one that falls off the edge.
func _target_pan() -> Vector3:
	var alive := _alive_targets()
	if alive.is_empty():
		return Vector3.ZERO
	var offset := (_target_box(alive).get_center() - _center) * pan_weight
	offset.y = 0.0
	return offset.limit_length(pan_limit)


## How far back the camera has to be for every kart, with its margin of floor, to be on screen:
## the whole point of the rig, GAME.md 8.2. Never closer than [member follow_min_distance] and
## never further than the distance that holds the whole arena, which is where it waits when
## there is nobody to follow.
func _target_distance() -> float:
	if not _framed:
		return _distance
	var alive := _alive_targets()
	if alive.is_empty():
		return _arena_distance
	var box := _target_box(alive).grow(follow_margin)
	box.position.y = 0.0
	box.size.y = maxf(_wall_height, 1.5)
	var corners: Array[Vector3] = []
	for i: int in 8:
		corners.append(box.get_endpoint(i))
	return clampf(_needed_distance(corners, _center + _pan), follow_min_distance, _arena_distance)


## The box every tracked kart is inside.
static func _target_box(alive: Array[Node3D]) -> AABB:
	var box := AABB(alive[0].global_position, Vector3.ZERO)
	for target: Node3D in alive:
		box = box.expand(target.global_position)
	return box


## The zoom is the distance's job now. The field of view stays where it is, so a kart the same
## size on screen is the same distance away wherever it is standing.
func _target_zoom() -> float:
	return 1.0


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
func _fit_distance() -> float:
	var half := _arena_size * 0.5 + Vector2.ONE * margin
	var corners: Array[Vector3] = []
	for x: int in [-1, 1]:
		for z: int in [-1, 1]:
			corners.append(_center + Vector3(x * half.x, 0.0, z * half.y))
			corners.append(_center + Vector3(x * half.x, _wall_height, z * half.y))
	return _needed_distance(corners, _center)


## Aspect ratio of the viewport the camera renders to.
func _aspect() -> float:
	var size := get_viewport().get_visible_rect().size
	if size.y <= 0.0:
		return 16.0 / 9.0
	return size.x / size.y


## The smallest distance at which every one of [param points] projects inside the view of a
## camera looking at [param at]. Worked out from the camera's own geometry rather than asked of
## Godot, whose frustum queries only answer after a frame has rendered, and this has to answer at
## load and again every frame.
##
## The camera only ever slides along one line, so in its own coordinates moving it back by d
## moves every point d further away and nothing else. A point is on screen while its sideways
## offset fits inside the cone at its depth, which rearranges into a smallest d per point; the
## answer is the largest of those.
func _needed_distance(points: Array[Vector3], at: Vector3) -> float:
	var pitch := deg_to_rad(pitch_degrees)
	var back := Vector3(0.0, sin(pitch), cos(pitch))
	var view := Basis.looking_at(-back, Vector3.UP).transposed()
	var tan_half_v := tan(deg_to_rad(base_fov * zoom_min) * 0.5)
	var tan_half_h := tan_half_v * _aspect()
	var needed := (camera.near if camera != null else 0.5) + 1.0
	for point: Vector3 in points:
		var local := view * (point - at)
		needed = maxf(
			needed, local.z + maxf(absf(local.x) / tan_half_h, absf(local.y) / tan_half_v)
		)
	return needed
