class_name PrismRibbon
extends MeshInstance3D
## The supporter pack's Prism trail, GAME.md 10.8: a thin ribbon of light split into the colors of
## the spectrum across its width, laid along the kart's line where its exhaust has been and gone in
## under a second, narrower and fainter toward its tail, so a slide leaves an arc of rainbow on the
## felt; brighter in a drift. Light added over the table rather than particles: the last second of
## where the exhaust was, kept as points and built again each frame, a few hundred triangles.
## Worked out on every screen from where the kart is, the look alone.

## How long a stretch of it lasts, in seconds; how far apart its points are laid, and how far a
## step may jump before it is taken for a kart put back on the floor and the ribbon starts again.
const LIFE := 0.85
const STEP := 0.15
const MOST_JUMP := 2.5
## How wide it is at the exhaust and how much of that it keeps at its tail, how strong it is
## driven and drifting, and how quickly it eases between the two.
const WIDE := 0.55
const TAIL := 0.45
const DRIVEN := 0.55
const DRIFTING := 0.8
const EASE := 4.0
## The spectrum across it, outside edge to inside, and how much fainter its two outer bands are.
const BANDS: Array[Color] = [
	Color(1.0, 0.2, 0.2),
	Color(1.0, 0.55, 0.15),
	Color(1.0, 0.9, 0.2),
	Color(0.3, 0.9, 0.35),
	Color(0.25, 0.55, 1.0),
	Color(0.6, 0.3, 1.0),
]
const EDGE := 0.6

## Whether the kart is drifting, which the exhaust says, see [method ExhaustSmoke.update_state].
var drifting := false
## Where the exhaust has been, newest last, each with when, in seconds.
var _points: PackedVector3Array = PackedVector3Array()
var _times := PackedFloat64Array()
var _strength := DRIVEN
var _drawn: ImmediateMesh
## Its own clock, in seconds of the game rather than of the wall, so it stops with the game.
var _clock := 0.0


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drawn = ImmediateMesh.new()
	mesh = _drawn
	material_override = SupporterDress.added(Color.WHITE)


func _process(delta: float) -> void:
	var holder := get_parent() as Node3D
	if holder == null or not holder.is_inside_tree():
		return
	step(delta, holder.global_position)


## One frame of [param delta] seconds with the exhaust at [param at]: a point laid where it has gone
## far enough from the last, the stretch older than [constant LIFE] let go, and the ribbon built
## again.
func step(delta: float, at: Vector3) -> void:
	_clock += delta
	var now := _clock
	_strength = lerpf(_strength, DRIFTING if drifting else DRIVEN, 1.0 - exp(-EASE * delta))
	if not _points.is_empty() and _points[_points.size() - 1].distance_to(at) > MOST_JUMP:
		_points.clear()
		_times.clear()
	if _points.is_empty() or _points[_points.size() - 1].distance_to(at) >= STEP:
		_points.append(at)
		_times.append(now)
	while not _times.is_empty() and now - _times[0] > LIFE:
		_points.remove_at(0)
		_times.remove_at(0)
	_build(at, now)


## How many points it holds now.
func length() -> int:
	return _points.size()


## The ribbon from the exhaust at [param at] back along its points, each band a strip whose light
## fades with how old the point is.
func _build(at: Vector3, now: float) -> void:
	_drawn.clear_surfaces()
	var line := _points.duplicate()
	var ages := PackedFloat32Array()
	for i: int in _times.size():
		ages.append(clampf((now - _times[i]) / LIFE, 0.0, 1.0))
	if line.is_empty() or line[line.size() - 1].distance_to(at) > 0.01:
		line.append(at)
		ages.append(0.0)
	if line.size() < 2:
		return
	var corners := PackedVector3Array()
	var lights := PackedColorArray()
	for i: int in range(line.size() - 1, 0, -1):
		var near := line[i]
		var far := line[i - 1]
		var along := near - far
		along.y = 0.0
		if along.length_squared() < 0.0001:
			continue
		var side := along.normalized().cross(Vector3.UP)
		var near_age := ages[i]
		var far_age := ages[i - 1]
		var near_wide := WIDE * lerpf(1.0, TAIL, near_age)
		var far_wide := WIDE * lerpf(1.0, TAIL, far_age)
		var near_light := _strength * pow(1.0 - near_age, 1.4)
		var far_light := _strength * pow(1.0 - far_age, 1.4)
		for band: int in BANDS.size():
			var left := float(band) / BANDS.size() - 0.5
			var right := float(band + 1) / BANDS.size() - 0.5
			var edge := 1.0 if band > 0 and band < BANDS.size() - 1 else EDGE
			var color := BANDS[band]
			for corner: Array in [
				[near, left, near_wide, near_light],
				[far, left, far_wide, far_light],
				[far, right, far_wide, far_light],
				[near, left, near_wide, near_light],
				[far, right, far_wide, far_light],
				[near, right, near_wide, near_light],
			]:
				var point: Vector3 = corner[0]
				lights.append(Color(color, float(corner[3]) * edge))
				corners.append(point + side * float(corner[1]) * float(corner[2]))
	if corners.is_empty():
		return
	_drawn.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in corners.size():
		_drawn.surface_set_color(lights[i])
		_drawn.surface_add_vertex(corners[i])
	_drawn.surface_end()
