class_name Bullet
extends Node3D
## One bullet, GAME.md 5.1 and 5.2. Moves by ray each physics tick so it cannot tunnel, bounces
## off walls while it has bounces left, bends slightly toward targets until its first bounce,
## and kills what it touches. Its first step checks the way from the shooter's centre to the
## muzzle, so a shot fired with the muzzle inside a wall or crate stops there instead of passing
## through.
## Bullet against bullet is resolved by the [BulletSystem].

signal expired(bullet: Bullet)

const HEIGHT := 0.5
const SKIN := 0.02
const TARGET_GROUP := &"targets"

var owner_slot := -1
var velocity := Vector3.ZERO
var radius := 0.15
var bounces_left := 0
var lifetime_left := 3.0
var bounced := false
var color := Color.WHITE
var assist_enabled := true
var assist_cone := 0.2
var assist_range := 15.0
var assist_turn_rate := 0.5
## Whether the bend survives a bounce.
var assist_after_bounce := false
## Where this tick's movement started, for sweeps against other bullets.
var previous_position := Vector3.ZERO
## The shooter's centre; anything solid between it and the muzzle stops the bullet at once.
var spawn_from := Vector3.ZERO

## On a client: dead-reckons between snapshots, never collides.
var puppet := false
var _puppet_target := Vector3.ZERO
var _puppet_has_target := false

var _dead := false
var _spawn_checked := false
var _shape := SphereShape3D.new()
var _shape_query := PhysicsShapeQueryParameters3D.new()
## Kart instance id to whether the bullet was inside that kart's graze distance last tick.
var _graze_inside: Dictionary[int, bool] = {}


## A later snapshot of a puppet: glide toward it rather than jump.
func correct_puppet(target: Vector3, bullet_velocity: Vector3) -> void:
	_puppet_target = Vector3(target.x, HEIGHT, target.z)
	velocity = bullet_velocity


## A client-side copy: looks like a bullet, moves by its last known velocity.
func setup_puppet(
	origin: Vector3, bullet_velocity: Vector3, bullet_radius: float, tint: Color
) -> void:
	puppet = true
	position = Vector3(origin.x, HEIGHT, origin.z)
	previous_position = position
	_puppet_target = position
	_puppet_has_target = true
	velocity = bullet_velocity
	radius = bullet_radius
	color = tint
	assist_enabled = false


func setup(
	slot: int,
	origin: Vector3,
	direction: Vector3,
	stats: CannonStats,
	tint: Color,
	from: Vector3 = Vector3.INF
) -> void:
	owner_slot = slot
	position = Vector3(origin.x, HEIGHT, origin.z)
	previous_position = position
	spawn_from = position if from == Vector3.INF else Vector3(from.x, HEIGHT, from.z)
	velocity = Vector3(direction.x, 0.0, direction.z).normalized() * stats.bullet_speed
	radius = stats.bullet_radius
	bounces_left = stats.bounces
	lifetime_left = stats.lifetime
	color = tint
	assist_enabled = stats.aim_assist
	assist_cone = deg_to_rad(stats.aim_assist_cone_deg)
	assist_range = stats.aim_assist_range
	assist_turn_rate = deg_to_rad(stats.aim_assist_turn_rate_deg)
	assist_after_bounce = stats.assist_after_bounce


func _ready() -> void:
	add_to_group(&"bullets")
	_shape.radius = radius
	_shape_query.shape = _shape
	_shape_query.collision_mask = Layers.KART | Layers.TURRET
	_build_visuals()
	_orient()


func is_dead() -> bool:
	return _dead


func destroy() -> void:
	if _dead:
		return
	_dead = true
	expired.emit(self)
	queue_free()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if puppet:
		global_position += velocity * delta
		if _puppet_has_target:
			_puppet_target += velocity * delta
			global_position = global_position.lerp(_puppet_target, 0.35)
		_orient()
		return
	if not _spawn_checked:
		_spawn_checked = true
		_check_spawn_path()
		if _dead:
			return
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		destroy()
		return
	if assist_enabled and (assist_after_bounce or not bounced):
		_steer(delta)
	_move(delta)
	if _dead:
		return
	_update_grazes()
	_orient()


## Bends the velocity toward the nearest target inside the cone and range.
func _steer(delta: float) -> void:
	var target := _nearest_target()
	if target == null:
		return
	velocity = steer_toward(
		velocity,
		global_position,
		target.global_position,
		assist_cone,
		assist_range,
		assist_turn_rate * delta
	)


## Rotates [param velocity] about the up axis toward [param target], by at most [param max_step]
## radians, and only when the target is within [param cone] radians and [param range] metres.
static func steer_toward(
	velocity: Vector3, from: Vector3, target: Vector3, cone: float, range: float, max_step: float
) -> Vector3:
	var to_target := Vector3(target.x - from.x, 0.0, target.z - from.z)
	var distance := to_target.length()
	if distance > range or distance < 0.001:
		return velocity
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.is_zero_approx():
		return velocity
	var angle := flat.signed_angle_to(to_target, Vector3.UP)
	if absf(angle) > cone:
		return velocity
	return velocity.rotated(Vector3.UP, clampf(angle, -max_step, max_step))


func _nearest_target() -> Node3D:
	return nearest_target(get_tree(), global_position, owner_slot)


## The nearest kart or turret that may be shot right now, skipping [param ignore_slot]'s own
## and anything further away than [param max_range].
static func nearest_target(
	tree: SceneTree, from: Vector3, ignore_slot: int, max_range: float = INF
) -> Node3D:
	var best: Node3D = null
	var best_distance := max_range
	for node: Node in tree.get_nodes_in_group(TARGET_GROUP):
		var target := node as Node3D
		if target == null or not target.has_method("is_targetable"):
			continue
		if not target.call("is_targetable") or target.get("slot") == ignore_slot:
			continue
		var distance := from.distance_to(target.global_position)
		if distance < best_distance:
			best_distance = distance
			best = target
	return best


func _move(delta: float) -> void:
	var from := global_position
	var to := from + velocity * delta
	previous_position = from
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(
		from, to, Layers.WORLD | Layers.KART | Layers.TURRET | Layers.BOMB
	)
	var hit := space.intersect_ray(ray)
	if hit.is_empty():
		global_position = to
		_hit_overlapping_targets(space)
		return
	var collider: Object = hit["collider"]
	if collider is Crate:
		(collider as Crate).hit(owner_slot)
		destroy()
		return
	if collider.has_method("take_hit"):
		if collider.call("take_hit", self):
			destroy()
		else:
			global_position = to
		return
	_bounce(hit["position"], hit["normal"])


## A kart or turret pressed against a wall or crate has its muzzle inside it. Cast from the
## shooter's centre to the muzzle: a crate in the way breaks, a kart takes the hit, a wall
## simply eats the bullet. Nothing bounces back into the shooter.
func _check_spawn_path() -> void:
	if spawn_from.is_equal_approx(global_position):
		return
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(
		spawn_from, global_position, Layers.WORLD | Layers.KART | Layers.TURRET | Layers.BOMB
	)
	var hit := space.intersect_ray(ray)
	if hit.is_empty():
		return
	var collider: Object = hit["collider"]
	if collider is Crate:
		(collider as Crate).hit(owner_slot)
	elif collider.has_method("take_hit") and collider.get("slot") != owner_slot:
		if not collider.call("take_hit", self):
			return
	elif collider.has_method("take_hit"):
		return
	destroy()


func _bounce(point: Vector3, normal: Vector3) -> void:
	if bounces_left <= 0:
		destroy()
		return
	bounces_left -= 1
	bounced = true
	Events.bullet_bounced.emit()
	var flat_normal := Vector3(normal.x, 0.0, normal.z).normalized()
	if flat_normal.is_zero_approx():
		flat_normal = -velocity.normalized()
	velocity = velocity.bounce(flat_normal)
	velocity.y = 0.0
	global_position = Vector3(point.x, HEIGHT, point.z) + flat_normal * (radius + SKIN)


## Catches targets the ray passed next to, within the bullet's radius.
func _hit_overlapping_targets(space: PhysicsDirectSpaceState3D) -> void:
	_shape_query.transform = Transform3D(Basis.IDENTITY, global_position)
	for result: Dictionary in space.intersect_shape(_shape_query, 4):
		var collider: Object = result["collider"]
		if collider.has_method("take_hit") and collider.call("take_hit", self):
			destroy()
			return


## A kart is grazed when the bullet leaves its graze distance without having hit it.
func _update_grazes() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"karts"):
		var kart := node as Kart
		if kart == null or kart.slot == owner_slot:
			continue
		var id := kart.get_instance_id()
		var inside := (
			kart.is_targetable()
			and kart.distance_to_body(global_position) < kart.rules.graze_distance
		)
		if _graze_inside.get(id, false) and not inside:
			kart.graze(owner_slot)
		_graze_inside[id] = inside


func _orient() -> void:
	if not velocity.is_zero_approx():
		look_at(global_position + velocity, Vector3.UP)


func _build_visuals() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	var core := MeshInstance3D.new()
	core.name = "Core"
	core.mesh = sphere
	core.material_override = material
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	var trail_material := StandardMaterial3D.new()
	trail_material.albedo_color = Color(color.r, color.g, color.b, 0.45)
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var cone := CylinderMesh.new()
	cone.top_radius = radius * 0.8
	cone.bottom_radius = 0.01
	cone.height = 1.0
	var trail := MeshInstance3D.new()
	trail.name = "Trail"
	trail.mesh = cone
	trail.material_override = trail_material
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The cylinder's axis is Y; lay it along +Z, which is behind the bullet after look_at.
	trail.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	trail.position = Vector3(0.0, 0.0, 0.5)
	add_child(trail)
