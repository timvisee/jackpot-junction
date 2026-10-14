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

## The ray every shot looks along to see whether a target is in the open, set up once and pointed
## again each time, as each bullet's own [member _ray] is.
static var _sight := PhysicsRayQueryParameters3D.new()
## What a bullet is drawn with, by its radius and its color, shared by every bullet, GAME.md
## 10.7: a shot builds nothing, and a ball of eight segments is all a bullet ever shows.
static var _cores: Dictionary[float, SphereMesh] = {}
static var _cones: Dictionary[float, CylinderMesh] = {}
static var _glows: Dictionary[Color, StandardMaterial3D] = {}
static var _trails: Dictionary[Color, StandardMaterial3D] = {}

var owner_slot := -1
## The team of whoever fired it, GAME.md 3.14, -1 without teams, and whether it goes through their
## teammates as though they were not there, as it does with friendly fire off.
var owner_team := -1
var spares_team := false
## Fired by the owner's turret rather than by the owner's kart, for the kill feed to say so,
## GAME.md 8.3. The kill is the owner's either way.
var from_turret := false
## Fired by the owner's decoy, for the kill feed to say so as it does a turret's, GAME.md 8.3.
var from_decoy := false
## How many walls it has come off, for the kill feed to show a ricochet, GAME.md 8.3.
var bounced_times := 0
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
## The ray a bullet moves along each tick, set up once and pointed again each time: a query made
## new for every bullet on every tick is thousands of them a second in a busy match.
var _ray := PhysicsRayQueryParameters3D.new()
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
	_ray.collision_mask = Layers.WORLD | Layers.KART | Layers.TURRET | Layers.BOMB | Layers.BALL
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
		get_world_3d().direct_space_state,
		owner_team
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
##
## Whatever is [param ignore_team]'s is passed over as well, GAME.md 3.14: a teammate is not an
## enemy, nor their turret, decoy or bomb.
static func nearest_target(
	tree: SceneTree,
	from: Vector3,
	ignore_slot: int,
	max_range: float = INF,
	facing: Vector3 = Vector3.ZERO,
	cone: float = 0.0,
	space: PhysicsDirectSpaceState3D = null,
	ignore_team: int = -1
) -> Node3D:
	var scored: Array = []
	var flat := Vector3(facing.x, 0.0, facing.z)
	# Read off the group once a frame and shared by every bullet, see [FrameGroups].
	for node: Node in FrameGroups.of(tree, TARGET_GROUP):
		var target := node as Node3D if is_instance_valid(node) else null
		if target == null or not target.has_method("is_targetable"):
			continue
		if not target.call("is_targetable") or target.get("slot") == ignore_slot:
			continue
		if Teams.same(ignore_team, Teams.of(target)):
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
	_sight.from = Vector3(from.x, HEIGHT, from.z)
	_sight.to = Vector3(to.x, HEIGHT, to.z)
	_sight.collision_mask = Layers.WORLD
	var body := target as CollisionObject3D
	# The target itself is on the wall layer when it is a box, a bomb or a shooting target.
	_sight.exclude = [body.get_rid()] if body != null else []
	return space.intersect_ray(_sight).is_empty()


func _move(delta: float) -> void:
	var from := global_position
	var to := from + velocity * delta
	previous_position = from
	var space := get_world_3d().direct_space_state
	_ray.from = from
	_ray.to = to
	var hit := space.intersect_ray(_ray)
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
		if _strike(collider):
			destroy()
		else:
			global_position = to
		return
	_bounce(hit["position"], hit["normal"])


## [param collider] taking this bullet, a kart told first how it came, for the kill feed should
## the bullet kill it, see [member Kart.kill_how]. Whether the bullet is spent on it.
func _strike(collider: Object) -> bool:
	if _spares(collider):
		return false
	var kart := collider as Kart
	if kart != null:
		kart.kill_how = {"decoy": from_decoy, "bounces": bounced_times}
	return collider.call("take_hit", self)


## Whether [param thing] lets this shot through untouched, GAME.md 3.14: a teammate's kart, decoy
## or turret, with friendly fire off. Its owner's own are the lobby's rule for a kart's own bullets.
func _spares(thing: Object) -> bool:
	if not spares_team or not Teams.same(owner_team, Teams.of(thing)):
		return false
	var slot: Variant = thing.get("slot")
	return slot is int and slot != owner_slot


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
		if not _strike(collider):
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
	bounced_times += 1
	Events.bullet_bounced.emit()
	if not puppet:
		_tell_shooter()
	velocity = velocity.bounce(flat_normal)
	velocity.y = 0.0
	global_position = Vector3(point.x, HEIGHT, point.z) + flat_normal * (radius + SKIN)


## A bounce is the shooter's jokers' to hear, Cushion Shot's, GAME.md 7.3, a turret's or a decoy's
## shot its owner's.
func _tell_shooter() -> void:
	var shooter := Kart.of_slot(get_tree(), owner_slot)
	if shooter != null:
		for joker: Joker in shooter.jokers.in_play:
			joker.on_shot_bounced(shooter)


## Catches targets the ray passed next to, within the bullet's radius.
func _hit_overlapping_targets(space: PhysicsDirectSpaceState3D) -> void:
	_shape_query.transform = Transform3D(Basis.IDENTITY, global_position)
	for result: Dictionary in space.intersect_shape(_shape_query, 4):
		var collider: Object = result["collider"]
		if collider.has_method("take_hit") and _strike(collider):
			destroy()
			return


## A kart is grazed when the bullet leaves its graze distance without having hit it.
func _update_grazes() -> void:
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var kart := node as Kart if is_instance_valid(node) else null
		# A teammate's shot is no danger worth a graze, GAME.md 3.14, whatever friendly fire says.
		if kart == null or kart.slot == owner_slot or Teams.same(owner_team, kart.team):
			continue
		var id := kart.get_instance_id()
		var inside := (
			kart.is_targetable()
			and KartCollisions.distance_to_body(kart, global_position) < kart.rules.graze_distance
		)
		if _graze_inside.get(id, false) and not inside:
			kart.graze(owner_slot)
		_graze_inside[id] = inside


func _orient() -> void:
	if not velocity.is_zero_approx():
		look_at(global_position + velocity, Vector3.UP)


func _build_visuals() -> void:
	var core := MeshInstance3D.new()
	core.name = "Core"
	core.mesh = _core_mesh(radius)
	core.material_override = _glow(color)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	var trail := MeshInstance3D.new()
	trail.name = "Trail"
	trail.mesh = _cone_mesh(radius)
	trail.material_override = _trail(color)
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The cylinder's axis is Y; lay it along +Z, which is behind the bullet after look_at.
	trail.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	trail.position = Vector3(0.0, 0.0, 0.5)
	add_child(trail)


static func _core_mesh(size: float) -> SphereMesh:
	if not _cores.has(size):
		var sphere := SphereMesh.new()
		sphere.radius = size
		sphere.height = size * 2.0
		sphere.radial_segments = 8
		sphere.rings = 4
		_cores[size] = sphere
	return _cores[size]


static func _cone_mesh(size: float) -> CylinderMesh:
	if not _cones.has(size):
		var cone := CylinderMesh.new()
		cone.top_radius = size * 0.8
		cone.bottom_radius = 0.01
		cone.height = 1.0
		cone.radial_segments = 8
		cone.rings = 1
		_cones[size] = cone
	return _cones[size]


static func _glow(tint: Color) -> StandardMaterial3D:
	if not _glows.has(tint):
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = 2.0
		_glows[tint] = material
	return _glows[tint]


static func _trail(tint: Color) -> StandardMaterial3D:
	if not _trails.has(tint):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(tint.r, tint.g, tint.b, 0.45)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_trails[tint] = material
	return _trails[tint]
