class_name ShotTrail
extends MeshInstance3D
## A fading ribbon that follows a shot along its path, GAME.md 5.3: a boomerang's arc drawn behind
## it so the curve reads at a glance, see [BulletArt]. It records the shot's recent positions each
## frame and lays a flat band through them, brightest at the head and fading to nothing at the tail;
## once the shot is gone it drains the tail and frees itself. It only follows -- nothing of the
## shot's own, so it runs on every machine the same, host and client puppet alike.

## How many positions back the trail remembers, how wide the band is at the head, and how bright.
const POINTS := 12
const WIDTH := 0.16
const ALPHA := 0.5

var _target: Node3D
var _points: PackedVector3Array = []
var _mesh := ImmediateMesh.new()
var _material: StandardMaterial3D


## Lays a trail of [param color] under [param parent] that follows [param target] until it is gone.
static func follow(parent: Node, target: Node3D, color: Color) -> ShotTrail:
	var trail := ShotTrail.new()
	trail.name = "ShotTrail"
	trail._target = target
	trail._material = SpawnRing.glow(color, ALPHA)
	trail._material.vertex_color_use_as_albedo = true
	trail.mesh = trail._mesh
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(trail)
	trail.global_transform = Transform3D.IDENTITY
	return trail


func _process(_delta: float) -> void:
	if is_instance_valid(_target) and _target.is_inside_tree():
		_points.append(_target.global_position)
		if _points.size() > POINTS:
			_points.remove_at(0)
	elif not _points.is_empty():
		# The shot is gone: drain the tail so the trail fades out rather than vanishing at once.
		_points.remove_at(0)
	else:
		queue_free()
		return
	_rebuild()


## Lays a flat band through the remembered points, tapering and fading from the head to the tail.
func _rebuild() -> void:
	_mesh.clear_surfaces()
	if _points.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	for i: int in _points.size():
		var share := float(i) / float(_points.size() - 1)
		var ahead := _points[mini(i + 1, _points.size() - 1)]
		var behind := _points[maxi(i - 1, 0)]
		var dir := Vector3(ahead.x - behind.x, 0.0, ahead.z - behind.z)
		dir = dir.normalized() if not dir.is_zero_approx() else Vector3.FORWARD
		var side := dir.cross(Vector3.UP) * WIDTH * share
		_mesh.surface_set_color(Color(_material.albedo_color, ALPHA * share))
		_mesh.surface_add_vertex(_points[i] - side)
		_mesh.surface_add_vertex(_points[i] + side)
	_mesh.surface_end()
