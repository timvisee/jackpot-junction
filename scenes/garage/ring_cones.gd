class_name RingCones
extends Node3D
## Traffic cones round the outside of the Garage's rings, GAME.md 9.4: something to drive round
## them without touching. A kart that clips one knocks it over and away from it, and it lies there
## a few seconds before it is stood back up where it was. Nothing stops a kart: a cone is knocked,
## never hit.

## Where the cones stand: their angles round the rings, from +X toward the front of the room, and
## how far outside the outer ring, in meters. Three over the top of the rings and three under them,
## clear of the Royal Flush pads on the ring and of the way to the dyno on the right.
const ANGLES: Array[float] = [-110.0, -90.0, -70.0, 70.0, 90.0, 110.0]
const OUTSIDE := 0.7
## A cone: its foot, how tall, how wide at the bottom, and its band.
const BASE := Vector3(0.56, 0.05, 0.56)
const TALL := 0.78
const WIDE := 0.24
const BAND := Vector2(0.32, 0.1)
const ORANGE := Color(0.96, 0.4, 0.08)
const WHITE := Color(0.93, 0.92, 0.88)
## How near a kart's middle has to come to knock one, in meters, how far it is thrown, how long
## it takes to go over and how long it lies before it is stood back up.
const REACH := 0.75
const THROWN := 0.6
const FALL := 0.18
const LIES := 4.0
const STANDS := 0.3

## The cones, each a [Node3D] at its spot, and when each went over, or -1 while it stands.
var cones: Array[Node3D] = []
var _down: Array[float] = []
var _spots: Array[Vector3] = []
var _now := 0.0
var _match: Match


## The cones round the rings of [param in_match]'s room, [param radius] meters out from its
## Junction.
static func add_to(in_match: Match, radius: float) -> RingCones:
	var made := RingCones.new()
	made.name = "RingCones"
	made._match = in_match
	in_match.arena.add_child(made)
	made._build(radius + OUTSIDE)
	return made


func _build(radius: float) -> void:
	var surfaces := _match.arena.surfaces
	var orange := surfaces.painted(ORANGE)
	var white := surfaces.painted(WHITE)
	var middle := _match.arena.junction_position
	for angle: float in ANGLES:
		var turn := deg_to_rad(angle)
		var spot := middle + Vector3(cos(turn), 0.0, sin(turn)) * radius
		var cone := Node3D.new()
		cone.position = spot
		add_child(cone)
		var base := MeshInstance3D.new()
		var plate := BoxMesh.new()
		plate.size = BASE
		base.mesh = plate
		base.material_override = orange
		base.position.y = BASE.y * 0.5
		cone.add_child(base)
		cone.add_child(_cut(WIDE, WIDE * 0.18, TALL, BASE.y, orange))
		cone.add_child(_cut(BAND.x * 0.5 + 0.005, BAND.x * 0.4, BAND.y, TALL * 0.5, white))
		cones.append(cone)
		_spots.append(spot)
		_down.append(-1.0)


## A slice of a cone: [param bottom] and [param top] radii, [param high] tall, its foot
## [param lift] off the floor.
static func _cut(
	bottom: float, top: float, high: float, lift: float, skin: Material
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = high
	mesh.radial_segments = 12
	mesh.rings = 1
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = skin
	made.position.y = lift + high * 0.5
	return made


func _physics_process(delta: float) -> void:
	_now += delta
	for i: int in cones.size():
		if _down[i] >= 0.0:
			_lie(i)
			continue
		for slot: PlayerSlot in _match.slots:
			var kart := slot.kart
			if kart == null or not kart.alive:
				continue
			var off := cones[i].position - kart.global_position
			off.y = 0.0
			if off.length() < REACH:
				_knock(i, off, kart.motor.velocity)
				break


## Knocks cone [param i] over, away from the kart [param off] behind it going at [param going].
func _knock(i: int, off: Vector3, going: Vector3) -> void:
	_down[i] = _now
	var away := (off.normalized() + going * 0.08).normalized()
	if away.is_zero_approx():
		away = Vector3.FORWARD
	var cone := cones[i]
	var spot := _spots[i]
	# Over on its side, its top toward where it was knocked, thrown a little way along and lying on
	# its flank rather than through the floor.
	var axis := Vector3.UP.cross(away).normalized()
	var lying := spot + away * THROWN + Vector3.UP * WIDE * 0.7
	var fall := create_tween()
	fall.tween_property(cone, "position", lying, FALL)
	fall.parallel().tween_property(cone, "rotation", Basis(axis, PI * 0.5).get_euler(), FALL)


## Stands cone [param i] back up once it has lain long enough.
func _lie(i: int) -> void:
	if _now - _down[i] < LIES:
		return
	_down[i] = -1.0
	var cone := cones[i]
	var stand := create_tween()
	stand.tween_property(cone, "position", _spots[i], STANDS)
	stand.parallel().tween_property(cone, "rotation", Vector3.ZERO, STANDS)


## Whether cone [param i] is standing.
func standing(i: int) -> bool:
	return _down[i] < 0.0
