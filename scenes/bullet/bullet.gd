class_name Bullet
extends Node3D
## One bullet, GAME.md 5.1 and 5.2. Moves by ray each physics tick so it cannot tunnel, bounces
## off walls while it has bounces left, bends slightly toward targets until its first bounce,
## and kills what it touches. Its first step checks the way from the shooter's center to the
## muzzle, so a shot fired with the muzzle inside a wall or crate stops there instead of passing
## through.
## Bullet against bullet is resolved by the [BulletSystem].

signal expired(bullet: Bullet)

const HEIGHT := 0.5
const SKIN := 0.02
const TARGET_GROUP := &"targets"
## How much nearer a kart counts than it really is when the aim has a choice, GAME.md 5.1. A
## player is always the better thing to hit, so a box has to be well inside one to win the shot.
const PLAYER_PULL := 0.4

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
## The shooter's center; anything solid between it and the muzzle stops the bullet at once.
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


## Scales what this shot's assist is worth, GAME.md 5.2: a kart that has been parked up gets
## less of it than one on the move. Applied after setup rather than folded into the stats, since
## it changes shot by shot and the stats do not.
func apply_assist_share(share: float) -> void:
	assist_cone *= share
	assist_turn_rate *= share
	assist_enabled = assist_enabled and share > 0.0


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
## radians, and only when the target is within [param cone] radians and [param range] meters.
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
	return nearest_target(
		get_tree(),
		global_position,
		owner_slot,
		assist_range,
		velocity,
		assist_cone,
		get_world_3d().direct_space_state
	)


## The best thing to bend a shot toward right now, GAME.md 5.1: a kart, a turret, a box, a bomb
## or a shooting target, whichever of them is worth most from here. Skips [param ignore_slot]'s
## own kart and anything further than [param max_range].
##
## Karts come first. Everything else on the floor is worth shooting and a shot that finds a box
## or sets off a bomb is a shot that did something, but none of it wins a match, so a kart is
## treated as [constant PLAYER_PULL] of its real distance away and a box has to be well inside
## one to take the aim off it.
##
## With a [param facing] and a [param cone], only what is in front is considered. Without them
## the nearest thing wins wherever it is, which is what a bullet with no direction yet wants.
##
## Given a [param space], anything a shot could not reach is passed over: the bend cannot go
## round a wall, GAME.md 5.2, so bending toward somebody standing behind one only throws the
## shot away. The candidates are ranked first and looked through in order, so the usual case
## costs one cast rather than one per box on the floor.
static func nearest_target(
	tree: SceneTree,
	from: Vector3,
	ignore_slot: int,
	max_range: float = INF,
	facing: Vector3 = Vector3.ZERO,
	cone: float = 0.0,
	space: PhysicsDirectSpaceState3D = null
) -> Node3D:
	var scored: Array = []
	var flat := Vector3(facing.x, 0.0, facing.z)
	for node: Node in tree.get_nodes_in_group(TARGET_GROUP):
		var target := node as Node3D
		if target == null or not target.has_method("is_targetable"):
			continue
		if not target.call("is_targetable") or target.get("slot") == ignore_slot:
			continue
		var to_target := Vector3(
			target.global_position.x - from.x, 0.0, target.global_position.z - from.z
		)
		var distance := to_target.length()
		if distance > max_range:
			continue
		if cone > 0.0 and not flat.is_zero_approx() and distance > 0.001:
			if absf(flat.signed_angle_to(to_target, Vector3.UP)) > cone:
				continue
		scored.append([distance * (PLAYER_PULL if target is Kart else 1.0), target])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in scored:
		if in_the_open(space, from, entry[1]):
			return entry[1]
	return null


## Whether a shot from [param from] could reach [param target] at all, or whether a wall or a
## box stands between the two. Walls and boxes are the only things that stop a bullet dead;
## karts are not in the way of a shot at another kart, they are another shot at a kart.
static func in_the_open(space: PhysicsDirectSpaceState3D, from: Vector3, target: Node3D) -> bool:
	if space == null:
		return true
	var to := target.global_position
	var ray := PhysicsRayQueryParameters3D.create(
		Vector3(from.x, HEIGHT, from.z), Vector3(to.x, HEIGHT, to.z), Layers.WORLD
	)
	var body := target as CollisionObject3D
	if body != null:
		# The target itself is on the wall layer when it is a box, a bomb or a shooting target.
		ray.exclude = [body.get_rid()]
	return space.intersect_ray(ray).is_empty()


func _move(delta: float) -> void:
	var from := global_position
	var to := from + velocity * delta
	previous_position = from
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(
		from, to, Layers.WORLD | Layers.KART | Layers.TURRET | Layers.BOMB | Layers.BALL
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
## shooter's center to the muzzle: a crate in the way breaks, a kart takes the hit, a wall
## simply eats the bullet. Nothing bounces back into the shooter.
func _check_spawn_path() -> void:
	if spawn_from.is_equal_approx(global_position):
		return
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(
		spawn_from,
		global_position,
		Layers.WORLD | Layers.KART | Layers.TURRET | Layers.BOMB | Layers.BALL
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
	var flat_normal := Vector3(normal.x, 0.0, normal.z).normalized()
	if flat_normal.is_zero_approx():
		flat_normal = -velocity.normalized()
	# A mark on the wall wherever a shot lands, GAME.md 8.3, whether it stops there or comes off.
	Events.bullet_struck.emit(Vector3(point.x, HEIGHT, point.z), flat_normal, color)
	if bounces_left <= 0:
		destroy()
		return
	bounces_left -= 1
	bounced = true
	Events.bullet_bounced.emit()
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
