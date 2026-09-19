class_name BulletMark
extends MeshInstance3D
## A scorch left where a bullet struck a wall, GAME.md 8.3: a small round mark in the shooter's
## colour lying flat against the surface, fading out over a few seconds. Bullets are the loudest
## thing in the room and they used to vanish without trace; a wall that has been shot at looks
## like a wall that has been shot at, which is most of the reason for shooting one.
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

## The mark's own shape, built once and shared by every mark there has ever been: a disc that
## falls away to nothing at its edge, so the quad it is painted on is never seen as a square.
static var _disc: GradientTexture2D

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


## A round, soft-edged mark, made once. A bullet hole is not square and a hard circle painted on
## a flat wall reads as a sticker, so the edge is given to the wall rather than drawn on it.
static func disc() -> GradientTexture2D:
	if _disc != null:
		return _disc
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	gradient.colors = PackedColorArray(
		[Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.92), Color(1.0, 1.0, 1.0, 0.0)]
	)
	_disc = GradientTexture2D.new()
	_disc.gradient = gradient
	_disc.fill = GradientTexture2D.FILL_RADIAL
	_disc.fill_from = Vector2(0.5, 0.5)
	_disc.fill_to = Vector2(1.0, 0.5)
	_disc.width = 64
	_disc.height = 64
	return _disc


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
	_material.albedo_texture = disc()
	_material.albedo_color = Color(color.darkened(0.45), ALPHA)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.emission_enabled = true
	_material.emission = color.darkened(0.7)
	_material.emission_energy_multiplier = 0.5
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
