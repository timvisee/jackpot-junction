class_name GuideArrow
extends Node3D
## The arrow on the floor ahead of the kart, GAME.md 9.4a, pulsing toward wherever the task needs
## the kart to go, and toward the open gate once a lesson is done. Gone within a few meters of the
## spot, and while there is nowhere in particular to go.

## How far ahead of the kart it lies, how near the spot it goes, and how high off the floor.
const AHEAD := 3.2
const NEAR := 4.0
const HEIGHT := 0.07
const COLOR := Palette.NEON_CYAN
## How fast it pulses, in beats a second.
const PULSE := 0.8

var kart: Kart
## Where it points, or not finite for nowhere.
var target := Vector3.INF

var _material: StandardMaterial3D
var _time := 0.0


static func add_to(in_match: Match) -> GuideArrow:
	var arrow := GuideArrow.new()
	arrow.name = "GuideArrow"
	in_match.add_child(arrow)
	return arrow


func _ready() -> void:
	var face := MeshInstance3D.new()
	face.mesh = _mesh()
	_material = StandardMaterial3D.new()
	_material.albedo_color = COLOR
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	face.material_override = _material
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(face)
	visible = false


func point_at(at: Vector3) -> void:
	target = at


func _process(delta: float) -> void:
	_time += delta
	if kart == null or not is_instance_valid(kart) or not target.is_finite():
		visible = false
		return
	var from := kart.global_position
	var flat := Vector3(target.x - from.x, 0.0, target.z - from.z)
	if flat.length() < NEAR:
		visible = false
		return
	visible = true
	var way := flat.normalized()
	global_position = Vector3(from.x, HEIGHT, from.z) + way * AHEAD
	look_at(global_position + way, Vector3.UP)
	var pulse := 0.5 + 0.5 * sin(_time * TAU * PULSE)
	scale = Vector3.ONE * (0.9 + 0.2 * pulse)
	_material.albedo_color = Color(COLOR, 0.5 + 0.45 * pulse)


## A flat arrow lying on the floor, pointing down the node's -Z, which [method look_at] aims.
static func _mesh() -> ArrayMesh:
	var points := PackedVector3Array()
	var shaft := [
		Vector3(-0.16, 0.0, 0.5),
		Vector3(0.16, 0.0, 0.5),
		Vector3(0.16, 0.0, -0.15),
		Vector3(-0.16, 0.0, -0.15),
	]
	points.append_array([shaft[0], shaft[1], shaft[2], shaft[0], shaft[2], shaft[3]])
	points.append_array(
		[Vector3(-0.45, 0.0, -0.1), Vector3(0.45, 0.0, -0.1), Vector3(0.0, 0.0, -0.9)]
	)
	var normals := PackedVector3Array()
	for i: int in points.size():
		normals.append(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
