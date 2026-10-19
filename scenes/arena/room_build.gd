class_name RoomBuild
extends Node3D
## The parts a room is put together from, GAME.md 8.1.
##
## [RoomShell] builds the room itself -- the floor under the table, the walls round it, the board
## at the back and what hangs on it -- and [RoomProps] builds what is lying about in it. Both are
## boxes and cylinders in the room's own materials, and both need to know how far out the crowd
## and the clutter go, so both are built from here.

## How a prop is turned where it stands: square with the table a degree or two off, which is what
## says somebody put it there rather than dropped it; thrown, for the things that were thrown;
## along the front edge of the bench, for what lies on the near apron; loose, for a tower run up
## in a hurry; facing, for the things with a front on them, which is turned to the arena wherever
## it is standing; and not turned at all, for what a room places by hand.
enum Turned { SQUARE, THROWN, ALONG, LOOSE, FACING, FLAT }

## The table's own surface, a little under the arena floor. Everything outside the wall stands on
## this rather than on the floor the karts drive on.
const TOP := -Arena.FLOOR_THICKNESS
## How deep the table's own edge goes under its top, which is the slab [Arena] lays the table as.
## Whatever the room hangs under the table starts this far down, so nothing of the room's lies in
## the table's top or its edge, where two faces in one place flicker between their colors.
const TABLE_EDGE := 0.5
## How far past the arena wall the clutter starts and how far out it may go: right behind the
## crowd, and not much further. A room reads as somewhere from what is close enough to make out,
## and the camera of 8.2 sees very little past the stands while a match is being played.
const NEAR := 8.0
const FAR := 14.0
## How far the clutter behind the arena goes, which is shorter, and how far past the last of it
## the wall of the room stands. The camera looks down at the table, so what is further back is
## higher up rather than further off: a wall much past this is a wall above the top of the
## picture, which is a wall nobody sees.
const BACK_FAR := 11.0
const BACK_WALL := 2.0
## How far past the edge of the table the wall round the room stands, and how thick it is.
const ROOM_CLEAR := 2.0
const WALL_THICKNESS := 2.0
## The patch of table each kind of prop covers and how it is turned on it. The patch is measured
## off the parts the prop is built from, in the prop's own frame: across it is the rectangle's
## width and along it -- the way a hammer's handle points -- is its height.
##
## Every place is found with these, so a hammer fifteen meters long asks for fifteen meters of
## bench and a glass asks for three. One patch of the same size for every prop is what left rod
## stock lying through a stack of chips and barrels standing in each other however many places
## were tried, and a round patch big enough to hold a prop whichever way it was turned costs nine
## times the table a hammer lying on it does.
const PATCH := {
	&"lamp": [Rect2(-3.4, -3.4, 6.8, 15.8), Turned.FLAT],
	&"vice": [Rect2(-2.2, -2.3, 4.4, 7.4), Turned.FLAT],
	&"rods": [Rect2(-1.3, -3.2, 2.6, 6.4), Turned.SQUARE],
	&"tape": [Rect2(-2.2, -1.3, 4.4, 6.5), Turned.SQUARE],
	&"tin": [Rect2(-3.4, -3.4, 6.8, 6.8), Turned.FLAT],
	&"hammer": [Rect2(-1.4, -5.8, 2.8, 14.7), Turned.SQUARE],
	&"planks": [Rect2(-3.1, -5.5, 6.2, 11.0), Turned.SQUARE],
	&"drill": [Rect2(-1.8, -4.5, 3.6, 14.0), Turned.SQUARE],
	&"mug": [Rect2(-2.6, -2.6, 5.2, 5.9), Turned.SQUARE],
	&"pencil": [Rect2(-0.5, -3.8, 1.0, 8.7), Turned.ALONG],
	&"rule": [Rect2(-5.0, -0.5, 10.0, 1.0), Turned.ALONG],
	&"pendant": [Rect2(-4.2, -4.2, 8.4, 8.4), Turned.FLAT],
	&"dice": [Rect2(-1.5, -0.7, 3.0, 1.4), Turned.THROWN],
	&"cards": [Rect2(-3.4, -3.4, 6.8, 6.8), Turned.THROWN],
	&"chips": [Rect2(-3.4, -1.1, 6.8, 2.2), Turned.SQUARE],
	&"deck": [Rect2(-1.4, -1.9, 2.8, 3.8), Turned.SQUARE],
	&"glass": [Rect2(-1.3, -1.3, 2.6, 2.6), Turned.FLAT],
	&"floodlight": [Rect2(-3.5, -2.5, 7.0, 5.0), Turned.FLAT],
	&"truck": [Rect2(-2.8, -6.4, 5.6, 12.8), Turned.FLAT],
	&"forklift": [Rect2(-2.0, -3.8, 4.0, 6.6), Turned.FLAT],
	&"tape_along": [Rect2(-3.2, -0.4, 6.4, 0.8), Turned.FLAT],
	&"tape_across": [Rect2(-0.4, -2.7, 0.8, 5.4), Turned.FLAT],
	&"cones": [Rect2(-4.0, -0.8, 8.0, 1.6), Turned.SQUARE],
	&"pallets": [Rect2(-2.1, -1.7, 4.2, 3.4), Turned.SQUARE],
	&"barrels": [Rect2(-3.2, -1.1, 6.4, 2.2), Turned.SQUARE],
	&"barrel_row": [Rect2(-1.1, -3.2, 2.2, 6.4), Turned.FLAT],
	&"scaffold": [Rect2(-3.1, -1.6, 6.2, 3.2), Turned.LOOSE],
	&"container": [Rect2(-4.2, -1.8, 8.4, 3.6), Turned.SQUARE],
	&"bricks": [Rect2(-1.4, -3.0, 2.8, 6.0), Turned.SQUARE],
	&"barrier": [Rect2(-3.2, -0.9, 6.4, 1.8), Turned.SQUARE],
	&"tires": [Rect2(-1.7, -1.7, 3.4, 3.4), Turned.SQUARE],
	&"chest": [Rect2(-1.9, -1.0, 3.8, 2.0), Turned.FACING],
	&"jerry": [Rect2(-1.6, -0.9, 3.2, 1.8), Turned.SQUARE],
	&"work_bench": [Rect2(-5.5, -1.4, 11.0, 2.8), Turned.FLAT],
}

var arena: Arena
var room: RoomLook
var surfaces: Surfaces
## How far out this room's clutter starts. [constant NEAR] for a room with a crowd in it, which
## is where the stands end; a room with nobody watching has nothing to stand behind, and eight
## meters of bare floor round the arena reads as a room somebody has been cleared out of.
var clutter_from := NEAR

## Its own generator, seeded off the room, so a room is dressed the same way every time it is
## built and two rooms are not dressed the same way.
var _rng := RandomNumberGenerator.new()


## Takes what this is being built out of from [param for_arena] and puts it in the room.
func _stand_in(for_arena: Arena, called: String) -> void:
	name = called
	arena = for_arena
	room = for_arena.room
	surfaces = for_arena.surfaces
	_rng.seed = hash(room.id)
	for_arena.add_child(self)


## Deals [param count] choices out of [param kinds], shuffled, so a room gets one of everything
## before it gets two of anything. Rolling for each place separately is what leaves a yard with
## five stacks of barrels in one corner and no bricks anywhere.
##
## Shuffled with the room's own generator rather than with [method Array.shuffle], which uses the
## global one and would dress the same room differently every time it was built.
func _deal(kinds: int, count: int) -> Array[int]:
	var out: Array[int] = []
	while out.size() < count:
		var deck: Array[int] = []
		for kind: int in kinds:
			deck.append(kind)
		for i: int in range(deck.size() - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var keep: int = deck[i]
			deck[i] = deck[j]
			deck[j] = keep
		out.append_array(deck)
	out.resize(count)
	return out


## Half the table: the arena and its overhang together.
func _table() -> Vector2:
	return (arena.world_size() + Vector2.ONE * Arena.TABLE_OVERHANG) * 0.5


## Half the room: the table and the clearance round it that the walls stand in.
func _room_half() -> Vector2:
	return _table() + Vector2.ONE * ROOM_CLEAR


func _box(size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _put(mesh, skin, at)


func _cylinder(radius: float, height: float, skin: Material, at: Vector3) -> MeshInstance3D:
	return _taper(radius, radius, height, skin, at)


func _taper(
	bottom: float, top: float, height: float, skin: Material, at: Vector3
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	return _put(mesh, skin, at)


func _put(mesh: Mesh, skin: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	add_child(node)
	return node


## Turns a prop about its own upright, which is what makes one hammer different from the next.
func _turned(node: MeshInstance3D, turn: float) -> MeshInstance3D:
	node.rotation.y = turn
	return node


## Casts no shadow. A wall thirty meters tall standing in a directional light throws the whole
## room into the dark, and the shadow map has the table to be spending itself on.
func _dim(node: MeshInstance3D) -> MeshInstance3D:
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
