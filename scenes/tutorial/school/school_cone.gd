class_name SchoolCone
extends Node3D
## A traffic cone of the driving test, GAME.md 9.4a: kart-sized, a square foot and a tapering body
## in cone orange with a pale band, out of the room's own materials as the rest of the dressing is.
## Each its own piece, so it rises out of the floor with its lesson, see [RisingPiece].

const ORANGE := Color(0.94, 0.42, 0.1)
const FOOT := Color(0.16, 0.16, 0.18)
const BAND := Color(0.93, 0.92, 0.88)
const HEIGHT := 0.72
## How much floor a cone stands on, for its outline as it comes up.
const ACROSS := Vector2(0.6, 0.6)
const GROUP := &"school_cones"


## A cone at [param at] on the floor of [param arena], held back until its lesson brings it up.
static func stand(arena: Arena, at: Vector3, name_as: String) -> SchoolCone:
	var cone := SchoolCone.new()
	cone.name = name_as
	cone.add_to_group(GROUP)
	var surfaces := arena.surfaces
	cone._part(BoxMesh.new(), Vector3(0.5, 0.06, 0.5), surfaces.painted(FOOT), 0.03)
	var body := CylinderMesh.new()
	body.top_radius = 0.05
	body.bottom_radius = 0.2
	body.height = HEIGHT
	body.radial_segments = 12
	cone._part(body, Vector3.ONE, surfaces.painted(ORANGE), HEIGHT * 0.5 + 0.06)
	var band := CylinderMesh.new()
	band.top_radius = 0.115
	band.bottom_radius = 0.145
	band.height = 0.12
	band.radial_segments = 12
	cone._part(band, Vector3.ONE, surfaces.painted(BAND), HEIGHT * 0.5 + 0.1)
	arena.add_child(cone)
	cone.position = Vector3(at.x, 0.0, at.z)
	RisingPiece.hold(cone)
	return cone


func _part(mesh: PrimitiveMesh, box_size: Vector3, skin: Material, height: float) -> void:
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = box_size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = skin
	part.position.y = height
	add_child(part)
