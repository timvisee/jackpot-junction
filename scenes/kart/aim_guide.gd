class_name AimGuide
extends Node3D
## Faint dots ahead of the cannon showing where a shot will go, for local players. Lives in world
## space and follows the kart's aim every drawn frame, from where the kart is drawn rather than
## from where its last physics tick left it: the kart is smoothed between ticks, and dots placed
## off the tick jumped back and forth against it wherever the screen draws faster than the
## physics runs, which on a phone at 90 Hz was every frame. So the engine does not smooth the
## dots again, see [method attach].

const DOTS := 4
const SPACING := 1.5
const RADIUS := 0.08
const ALPHA := 0.45

var _dots: Array[MeshInstance3D] = []


static func attach(kart: Kart, color: Color) -> AimGuide:
	var guide := AimGuide.new()
	guide.name = "AimGuide"
	guide.top_level = true
	# Placed every drawn frame from the drawn kart: smoothing it again would put it a tick behind.
	guide.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	kart.add_child(guide)
	guide._build(color)
	return guide


func _build(color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, ALPHA)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := SphereMesh.new()
	mesh.radius = RADIUS
	mesh.height = RADIUS * 2.0
	# A dot a few pixels across: eight segments round it, GAME.md 10.7.
	mesh.radial_segments = 8
	mesh.rings = 4
	for i: int in DOTS:
		var dot := MeshInstance3D.new()
		dot.mesh = mesh
		dot.material_override = material
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(dot)
		_dots.append(dot)


## The dots in [param color] instead, for a player who has picked another one.
func paint(color: Color) -> void:
	if not _dots.is_empty():
		var material := _dots[0].material_override as StandardMaterial3D
		material.albedo_color = Color(color.r, color.g, color.b, ALPHA)


## Places the dots along the aim from the muzzle.
func update_line(muzzle: Vector3, direction: Vector3) -> void:
	for i: int in _dots.size():
		_dots[i].global_position = muzzle + direction * (SPACING * (i + 1))
		_dots[i].global_position.y = Bullet.HEIGHT
