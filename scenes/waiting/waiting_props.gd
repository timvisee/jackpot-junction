class_name WaitingProps
extends RefCounted
## The handful of things standing about on the floor of the waiting room, GAME.md 9.6: a stack of
## wheels, a drum and a cone.
##
## Everything else in the game keeps its scenery out of the arena, because a match is played in
## there and a prop in the way of a shot is a prop deciding something. Nothing is decided in the
## waiting room: there is no clock, no score and nobody to shoot, so a few things to drift round
## are the only reason to drive at all while the last player finds their pad.
##
## They are solid, unlike the clutter outside: driving through a drum is worse than having no
## drum. They are the room's own colors, so the waiting room reads as the corner of the garage
## that it is.

## Where each one stands, as a share of the arena's half size, and how far it reaches. The three
## sit off the middle so the pad in the center is left clear and the line to it from any spawn is
## not blocked by one. The wheels stand [constant WHEELS_DOWN] cells further from the back wall
## than their share alone puts them, clear of the room along the stalls there.
const PLACES: Array[Vector2] = [Vector2(-0.52, -0.42), Vector2(0.55, 0.3), Vector2(-0.3, 0.52)]
const WHEELS_DOWN := 1
## How far a kart is held off each of them, which is what a drift round one is measured against.
const WHEEL_RADIUS := 1.1
const DRUM_RADIUS := 0.62
const CONE_RADIUS := 0.5


## Stands the three of them on [param arena]'s floor and returns the holder they went into.
static func add_to(arena: Arena) -> Node3D:
	var holder := Node3D.new()
	holder.name = "WaitingProps"
	arena.add_child(holder)
	var surfaces := arena.surfaces
	var half := arena.world_size() * 0.5
	var spots: Array[Vector3] = []
	for place: Vector2 in PLACES:
		spots.append(Vector3(place.x * half.x, 0.0, place.y * half.y))
	spots[0].z += arena.grid.cell_size * WHEELS_DOWN
	_wheels(holder, surfaces, spots[0])
	_drum(holder, surfaces, spots[1])
	_cone(holder, surfaces, spots[2])
	return holder


## A stack of wheels, lying flat the way a stack of them is left.
static func _wheels(into: Node3D, surfaces: Surfaces, at: Vector3) -> void:
	var rubber := surfaces.painted(Color(0.1, 0.1, 0.11))
	var hub := surfaces.metal(Color(0.62, 0.64, 0.68))
	var body := _standing(into, "Wheels", at, WHEEL_RADIUS, 1.25)
	for i: int in 3:
		_cylinder(body, WHEEL_RADIUS, 0.42, rubber, Vector3(0.0, 0.22 + float(i) * 0.4, 0.0))
	_cylinder(body, WHEEL_RADIUS * 0.44, 0.44, hub, Vector3(0.0, 1.02, 0.0))


## A drum, banded the way an oil drum is.
static func _drum(into: Node3D, surfaces: Surfaces, at: Vector3) -> void:
	var paint := surfaces.painted(Color(0.22, 0.35, 0.44))
	var steel := surfaces.metal(Color(0.66, 0.68, 0.72))
	var body := _standing(into, "Drum", at, DRUM_RADIUS, 1.6)
	_cylinder(body, DRUM_RADIUS, 1.55, paint, Vector3(0.0, 0.78, 0.0))
	for height: float in [0.5, 1.1]:
		_cylinder(body, DRUM_RADIUS * 1.06, 0.12, steel, Vector3(0.0, height, 0.0))


## A cone, with the band round it that a cone has.
static func _cone(into: Node3D, surfaces: Surfaces, at: Vector3) -> void:
	var orange := surfaces.painted(Color(0.94, 0.42, 0.1))
	var white := surfaces.painted(Color(0.9, 0.9, 0.92))
	var base := surfaces.painted(Color(0.2, 0.2, 0.22))
	var body := _standing(into, "Cone", at, CONE_RADIUS, 1.1)
	_box(body, Vector3(0.96, 0.12, 0.96), base, Vector3(0.0, 0.06, 0.0))
	_taper(body, CONE_RADIUS, 0.08, 1.0, orange, Vector3(0.0, 0.6, 0.0))
	_taper(body, CONE_RADIUS * 0.66, CONE_RADIUS * 0.5, 0.2, white, Vector3(0.0, 0.5, 0.0))


## One prop's body: a static thing a kart is stopped by, with a cylinder round it so that a kart
## slides off whichever way it came in rather than catching on a corner.
static func _standing(
	into: Node3D, called: String, at: Vector3, radius: float, tall: float
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = called
	body.position = at
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = tall
	shape.shape = cylinder
	shape.position = Vector3(0.0, tall * 0.5, 0.0)
	body.add_child(shape)
	into.add_child(body)
	return body


static func _cylinder(
	into: Node3D, radius: float, height: float, skin: Material, at: Vector3
) -> void:
	_taper(into, radius, radius, height, skin, at)


static func _taper(
	into: Node3D, bottom: float, top: float, height: float, skin: Material, at: Vector3
) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	_put(into, mesh, skin, at)


static func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_put(into, mesh, skin, at)


static func _put(into: Node3D, mesh: Mesh, skin: Material, at: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
