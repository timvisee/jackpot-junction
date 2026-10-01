class_name HazardLine
extends RefCounted
## Hazard stripes painted on the floor, GAME.md 9.4a: yellow and black, a line across the run the
## tutorial's guard turret covers where its reach begins, and a box round the spot to drop a turret
## on. Flat slabs a hair off the floor, so they read as paint rather than as something to hit.

const YELLOW := Color(0.96, 0.78, 0.16)
const BLACK := Color(0.09, 0.09, 0.1)
const WIDTH := 0.28
const STRIPE := 0.5
const LIFT := 0.02


## A striped line from [param from] to [param to], on the floor.
static func lay(parent: Node, from: Vector3, to: Vector3) -> Node3D:
	var line := Node3D.new()
	line.name = "HazardLine"
	parent.add_child(line)
	var flat_from := Vector3(from.x, LIFT, from.z)
	var flat_to := Vector3(to.x, LIFT, to.z)
	var along := flat_to - flat_from
	var length := along.length()
	if length < 0.01:
		return line
	var way := along / length
	var count := maxi(1, ceili(length / STRIPE))
	var each := length / count
	for i: int in count:
		var slab := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(each, LIFT, WIDTH)
		slab.mesh = mesh
		slab.material_override = _paint(YELLOW if i % 2 == 0 else BLACK)
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		line.add_child(slab)
		slab.global_position = flat_from + way * (each * (float(i) + 0.5))
		slab.rotation.y = atan2(-way.z, way.x)
	return line


## A striped box round [param center], [param size] across on the floor.
static func box(parent: Node, center: Vector3, size: Vector2) -> Node3D:
	var frame := Node3D.new()
	frame.name = "HazardBox"
	parent.add_child(frame)
	var half := Vector3(size.x * 0.5, 0.0, size.y * 0.5)
	var corners: Array[Vector3] = [
		center + Vector3(-half.x, 0.0, -half.z),
		center + Vector3(half.x, 0.0, -half.z),
		center + Vector3(half.x, 0.0, half.z),
		center + Vector3(-half.x, 0.0, half.z),
	]
	for i: int in corners.size():
		lay(frame, corners[i], corners[(i + 1) % corners.size()])
	return frame


static func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
