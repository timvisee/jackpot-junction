class_name FloatingIcon
extends Node3D
## A shape that rises out of the arena and fades, the way [FloatingText] does with words.
##
## For the things that used to be announced in writing and are quicker as a picture: a heart
## breaking when a life goes and a whole one when the Junction hands it back, GAME.md 3.6. Two
## words have to be read, and a player who is reading is not driving.
##
## The shapes arrive as polygons in the unit box and are built into one flat mesh, billboarded
## and unshaded, so it faces the camera and stays its own color under the disco lights.

## How fast it rises, and the share of its life it spends fading rather than holding.
const RISE := 1.2
const FADE := 0.4

var _duration := 1.0
var _age := 0.0
var _material: StandardMaterial3D


## Puts one up at [param at], made of [param shapes] in the unit box and [param span] meters
## across. Returns null when the shapes are empty, which is nothing worth a node.
static func spawn(
	parent: Node,
	at: Vector3,
	shapes: Array[PackedVector2Array],
	color: Color,
	span: float,
	duration: float
) -> FloatingIcon:
	var mesh := _mesh(shapes, span)
	if mesh == null:
		return null
	var icon := FloatingIcon.new()
	icon.name = "FloatingIcon"
	icon._duration = duration
	icon._material = StandardMaterial3D.new()
	icon._material.albedo_color = color
	icon._material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	icon._material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	icon._material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	icon._material.cull_mode = BaseMaterial3D.CULL_DISABLED
	icon._material.no_depth_test = true
	var face := MeshInstance3D.new()
	face.mesh = mesh
	face.material_override = icon._material
	icon.add_child(face)
	icon.position = at + Vector3(0.0, 1.2, 0.0)
	parent.add_child(icon)
	return icon


## One flat mesh out of every polygon handed in, centered on itself and [param span] meters wide.
## The unit box has y downwards and the world has it up, so it is flipped on the way through.
static func _mesh(shapes: Array[PackedVector2Array], span: float) -> ArrayMesh:
	var points := PackedVector3Array()
	for shape: PackedVector2Array in shapes:
		var fan := Geometry2D.triangulate_polygon(shape)
		for index: int in fan:
			var at := (shape[index] - Vector2(0.5, 0.5)) * span
			points.append(Vector3(at.x, -at.y, 0.0))
	if points.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _process(delta: float) -> void:
	_age += delta
	position.y += RISE * delta
	var progress := _age / maxf(_duration, 0.001)
	_material.albedo_color.a = 1.0 - clampf((progress - (1.0 - FADE)) / FADE, 0.0, 1.0)
	if _age >= _duration:
		queue_free()
