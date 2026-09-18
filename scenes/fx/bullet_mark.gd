class_name BulletMark
extends MeshInstance3D
## A scorch left where a bullet struck a wall, GAME.md 8.3: a small disc in the shooter's colour
## lying flat against the surface, fading out over a few seconds. Bullets are the loudest thing
## in the room and they used to vanish without trace; a wall that has been shot at looks like a
## wall that has been shot at, which is most of the reason for shooting one.
##
## The arena owns them rather than the bullets do, so a room wears only so many at once and the
## oldest goes when a new one arrives.

## Side of the disc, in metres.
const SIZE := 0.3
const LIFETIME := 7.0
## The share of a mark's life spent fading out.
const FADE := 0.45
const ALPHA := 0.72
## How many marks a room wears at once.
const MAX_MARKS := 60
## How far off the surface the quad sits, so it does not fight the wall for the same pixels.
const LIFT := 0.02

var _age := 0.0
var _material: StandardMaterial3D


## Puts a mark at [param at] facing along [param normal], which has to point away from the
## surface. Returns it so the arena can keep hold of it.
static func spawn(parent: Node, at: Vector3, normal: Vector3, color: Color) -> BulletMark:
	var mark := BulletMark.new()
	mark.name = "BulletMark"
	parent.add_child(mark)
	mark._build(color)
	mark.global_position = at + normal * LIFT
	# The quad faces +Z and look_at points -Z at what it is given, so it is aimed into the wall.
	mark.look_at(mark.global_position - normal, Vector3.UP)
	# A little roll, so a wall taking fire does not end up wearing a row of identical stamps.
	mark.rotate_object_local(Vector3(0.0, 0.0, 1.0), randf() * TAU)
	return mark


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var left := 1.0 - _age / LIFETIME
	_material.albedo_color.a = ALPHA * minf(left / FADE, 1.0)


func _build(color: Color) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(SIZE, SIZE)
	mesh = quad
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(color.darkened(0.45), ALPHA)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.emission_enabled = true
	_material.emission = color.darkened(0.7)
	_material.emission_energy_multiplier = 0.5
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
