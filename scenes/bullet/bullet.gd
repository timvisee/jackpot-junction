class_name Bullet
extends Node3D
## One bullet, GAME.md 5.1 and 5.2. Moves by ray each physics tick so it cannot tunnel, bounces
## off walls while it has bounces left and off a pop bumper always, 6.2, bends slightly toward
## targets until its first bounce,
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
## A flame's colour, the same behind every rocket whoever fired it, so a rocket reads as one and not
## just a fat bullet in a player's colour; and an electric blue for chain lightning's spark.
const FLAME := Color(1.0, 0.55, 0.12)
const SPARK := Color(0.6, 0.85, 1.0)

## The ray every shot looks along to see whether a target is in the open, set up once and pointed
## again each time, as each bullet's own [member _ray] is.
static var _sight := PhysicsRayQueryParameters3D.new()
## What a bullet is drawn with, by its radius and its color, shared by every bullet, GAME.md
## 10.7: a shot builds nothing, and a ball of eight segments is all a bullet ever shows.
static var _cores: Dictionary[float, SphereMesh] = {}
static var _cones: Dictionary[float, CylinderMesh] = {}
static var _glows: Dictionary[Color, StandardMaterial3D] = {}
static var _trails: Dictionary[Color, StandardMaterial3D] = {}
## A grenade's dark casing, the same behind every one, see [method _build_grenade].
static var _grenade_casing: StandardMaterial3D

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
## How many times the shot has turned off anything, a wall or a pop bumper, GAME.md 6.2: what a
## bot dodging it decides about it again by, and what makes a kart's own shot dangerous to it.
var turns := 0
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

## What kind of shot it is, for how it strikes and is drawn, see [CannonStats]; and the life a hit
## takes, two for a rocket.
var kind := &"ball"
var hits := 1
## If above zero, it bursts where it lands, see [Blast], and whether its fuse running out bursts it
## rather than simply ending it: a grenade.
var blast_radius := 0.0
var explode_on_expire := false
## How many karts or crates it still passes through (a railgun) and how many targets it still leaps
## to (chain lightning).
var pierce_left := 0
var chain_left := 0
## Whether it flies back to the kart that fired it.
var returns := false

## On a client: dead-reckons between snapshots, never collides.
var puppet := false
var _puppet_target := Vector3.ZERO
var _puppet_has_target := false

var _dead := false
## Whether a boomerang is on its way back to the shooter now.
var _returning := false
var _spawn_checked := false
var _shape := SphereShape3D.new()
var _shape_query := PhysicsShapeQueryParameters3D.new()
## The ray a bullet moves along each tick, set up once and pointed again each time: a query made
## new for every bullet on every tick is thousands of them a second in a busy match.
var _ray := PhysicsRayQueryParameters3D.new()
## Kart instance id to whether the bullet was inside that kart's graze distance last tick.
var _graze_inside: Dictionary[int, bool] = {}
## What a piercing or chaining shot has already hit, by instance id, so it is not struck twice.
var _hit_ids: Dictionary[int, bool] = {}


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
	kind = stats.kind
	hits = stats.hits
	blast_radius = stats.blast_radius
	explode_on_expire = stats.explode_on_expire
	pierce_left = stats.pierce
	chain_left = stats.chain
	returns = stats.returns


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
		# A grenade's fuse: it bursts where it lies rather than simply going out.
		if explode_on_expire:
			_detonate()
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


## The best thing to bend a shot toward right now, GAME.md 5.1: a kart, a turret, a box, a bomb,
## a shooting target or a pop bumper, whichever of them is worth most from here. Skips
## [param ignore_slot]'s own kart and anything further than [param max_range].
##
## Karts come first. Everything else on the floor is worth shooting and a shot that finds a box
## or sets off a bomb is a shot that did something, but none of it wins a match, so a kart is
## treated as [constant PLAYER_PULL] of its real distance away and a box has to be well inside
## one to take the aim off it. A pop bumper comes last of all, after anything else in reach
## however far off, 6.2: it kicks the shot back and pays nothing, so a shot is bent onto one only
## when it would find nothing else, and a kart anywhere in the cone always takes the aim off it.
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
		var last := 1 if target is Bumper else 0
		scored.append([last, distance * (PLAYER_PULL if target is Kart else 1.0), target])
	scored.sort_custom(
		func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])
	)
	for entry: Array in scored:
		if in_the_open(space, from, entry[2]):
			return entry[2]
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
	if collider is Crate or collider.has_method("take_hit"):
		if not _resolve_hit(collider):
			global_position = to
		return
	_bounce(hit["position"], hit["normal"], collider is Bumper)


## Acts on [param collider] -- a crate, kart, turret or bomb -- the shot reached, GAME.md 5.3.
## Returns whether the shot is spent on it. An explosive shot bursts, see [Blast]; a railgun pierces
## on; chain lightning leaps to the next; a plain shot is spent on the first thing it touches, each
## hit thing remembered so a piercing or chaining shot does not strike it twice.
func _resolve_hit(collider: Object) -> bool:
	var crate := collider as Crate
	if blast_radius > 0.0:
		if crate == null and _spares(collider):
			return false
		_land(collider, crate)
		_detonate()
		destroy()
		return true
	var id := collider.get_instance_id()
	if (pierce_left > 0 or chain_left > 0) and _hit_ids.has(id):
		return false
	if not _land(collider, crate):
		return false
	return _carry_on_or_stop(id)


## The shot landing on [param collider]: a crate broken, or a kart, turret or bomb struck, taking
## [member hits] of a kart's lives. Returns whether it landed, false when it passed through: a dead
## crate, or a teammate's or the owner's own harmless shot.
func _land(collider: Object, crate: Crate) -> bool:
	if crate != null:
		if not crate.alive:
			return false
		crate.hit(owner_slot)
		return true
	return _strike(collider)


## After a hit the shot landed, whether it is now spent: a railgun carries on until its pierces run
## out, chain lightning until it finds nothing more to leap to, anything else at once. [param id] is
## the thing just hit, kept so it is not struck again.
func _carry_on_or_stop(id: int) -> bool:
	if pierce_left > 0:
		_hit_ids[id] = true
		pierce_left -= 1
		if pierce_left > 0:
			return false
	elif chain_left > 0:
		_hit_ids[id] = true
		chain_left -= 1
		if _leap_to_next():
			return false
	destroy()
	return true


## A chaining shot's next mark, GAME.md 5.3: the nearest kart, turret, crate or bomb within its leap
## it has not hit yet and can see, aimed at by turning the shot's velocity onto it. Whether one was
## found; without one the shot is done.
func _leap_to_next() -> bool:
	var target := _nearest_unhit()
	if target == null:
		return false
	var to := Vector3(
		target.global_position.x - global_position.x,
		0.0,
		target.global_position.z - global_position.z
	)
	if to.is_zero_approx():
		return false
	velocity = to.normalized() * velocity.length()
	return true


## The nearest thing a chaining shot may leap to: in its leap range, not the owner's or a teammate's
## or one already hit or a pop bumper, and in the open, see [method in_the_open].
func _nearest_unhit() -> Node3D:
	var best: Node3D = null
	var best_distance := assist_range
	var space := get_world_3d().direct_space_state
	for node: Node in FrameGroups.of(get_tree(), TARGET_GROUP):
		var target := node as Node3D if is_instance_valid(node) else null
		if target == null or target is Bumper or not target.has_method("is_targetable"):
			continue
		if not target.call("is_targetable") or target.get("slot") == owner_slot:
			continue
		if _hit_ids.has(target.get_instance_id()) or Teams.same(owner_team, Teams.of(target)):
			continue
		var flat := Vector3(
			target.global_position.x - global_position.x,
			0.0,
			target.global_position.z - global_position.z
		)
		var distance := flat.length()
		if distance < best_distance and in_the_open(space, global_position, target):
			best_distance = distance
			best = target
	return best


## [param collider] taking this bullet, a kart told first how it came, for the kill feed should
## the bullet kill it, see [member Kart.kill_how]. Whether the bullet is spent on it.
func _strike(collider: Object) -> bool:
	if _spares(collider):
		return false
	var kart := collider as Kart
	if kart != null:
		kart.kill_how = {"decoy": from_decoy, "bounces": bounced_times}
	return collider.call("take_hit", self)


## The shot bursts where it is, GAME.md 5.3: the host deals the area damage and every screen shows
## the flash, see [Blast]. Nothing on a client, whose shots are puppets that never touch anything.
func _detonate() -> void:
	if puppet or blast_radius <= 0.0:
		return
	Blast.go(_match(), global_position, blast_radius, owner_slot, owner_team, color)


## The match this shot is in, found by walking up rather than asking the tree, which in a split
## screen or a test holds more than one.
func _match() -> Match:
	var at: Node = self
	while at != null:
		var found := at as Match
		if found != null:
			return found
		at = at.get_parent()
	return null


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


## Off a wall at [param point], or off a pop bumper when [param kicked], GAME.md 6.2. A bumper kicks
## every shot back as it kicks a ball, whether or not the shot has a bounce in it, and the kick is
## the bumper's rather than the shot's: no bounce is spent on it, so Rubber Bumpers' and a Ricochet
## Cannon's are still there for the walls after it, and none is counted against the shot, since a
## bumper is not a wall, so it never reads "off a wall" in the kill feed. On Pin Alley alone it pays
## Cushion Shot, [method _kick_counts], the room's bank shots its own kind of cushion; off that map
## a bumper pays nothing, the farm a shot rattling between a three would be. What a kick shares with
## a wall's bounce is the shot no longer bending toward a mark, and the word that it landed there.
func _bounce(point: Vector3, normal: Vector3, kicked := false) -> void:
	var flat_normal := Vector3(normal.x, 0.0, normal.z).normalized()
	if flat_normal.is_zero_approx():
		flat_normal = -velocity.normalized()
	# A mark on the wall wherever a shot lands, GAME.md 8.3, whether it stops there or comes off.
	Events.bullet_struck.emit(Vector3(point.x, HEIGHT, point.z), flat_normal, color)
	turns += 1
	if kicked:
		bounced = true
		if not puppet and _kick_counts():
			_tell_shooter()
	elif bounces_left <= 0:
		# Out of bounces: an explosive shot bursts against the wall where it would have died.
		if blast_radius > 0.0:
			global_position = Vector3(point.x, HEIGHT, point.z)
			_detonate()
		destroy()
		return
	else:
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


## Whether a bumper's kick counts as a cushion, GAME.md 6.2: only on Pin Alley, read off the
## shooter's map, where the room makes a bank shot off a bumper worth what one off a wall is.
func _kick_counts() -> bool:
	var shooter := Kart.of_slot(get_tree(), owner_slot)
	return shooter != null and shooter.rules != null and shooter.rules.map == &"pin_alley"


## Catches targets the ray passed next to, within the bullet's radius.
func _hit_overlapping_targets(space: PhysicsDirectSpaceState3D) -> void:
	_shape_query.transform = Transform3D(Basis.IDENTITY, global_position)
	for result: Dictionary in space.intersect_shape(_shape_query, 4):
		var collider: Object = result["collider"]
		if collider.has_method("take_hit") and _resolve_hit(collider):
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
	if kind == &"rocket":
		_build_rocket()
		return
	if kind == &"grenade":
		_build_grenade()
		return
	if kind == &"railgun":
		_build_railgun()
		return
	if kind == &"lightning":
		_build_lightning()
		return
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


## A rocket: an elongated warhead in the shooter's colour nose-first, with a long flame behind it.
func _build_rocket() -> void:
	var body := MeshInstance3D.new()
	body.name = "Core"
	var warhead := CapsuleMesh.new()
	warhead.radius = radius
	warhead.height = radius * 4.0
	warhead.radial_segments = 8
	warhead.rings = 2
	body.mesh = warhead
	body.material_override = _glow(color)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The capsule's axis is Y; turn it to point along -Z, the way the bullet faces after look_at.
	body.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(body)
	var flame := MeshInstance3D.new()
	flame.name = "Trail"
	flame.mesh = _cone_mesh(radius * 1.5)
	flame.material_override = _trail(FLAME)
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	flame.scale = Vector3(1.0, 1.8, 1.0)
	flame.position = Vector3(0.0, 0.0, radius * 2.0 + 0.4)
	add_child(flame)


## A grenade: a dark casing the size of a fist with a band of the shooter's colour round it, no
## flame and no bright core, so it reads as a thing lobbed rather than a shot fired.
func _build_grenade() -> void:
	var body := MeshInstance3D.new()
	body.name = "Core"
	body.mesh = _core_mesh(radius)
	body.material_override = _grenade_body()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)
	var band := MeshInstance3D.new()
	band.name = "Band"
	var ring := TorusMesh.new()
	ring.inner_radius = radius * 0.7
	ring.outer_radius = radius * 1.08
	ring.rings = 12
	ring.ring_segments = 6
	band.mesh = ring
	band.material_override = _glow(color)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	band.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(band)


## A railgun bolt: a long, thin streak nose-first in the shooter's colour, so it reads as a bolt
## that runs clean through a line of karts rather than a single ball.
func _build_railgun() -> void:
	var bolt := MeshInstance3D.new()
	bolt.name = "Core"
	var streak := CylinderMesh.new()
	streak.top_radius = radius * 0.6
	streak.bottom_radius = radius * 0.6
	streak.height = 1.3
	streak.radial_segments = 6
	streak.rings = 1
	bolt.mesh = streak
	bolt.material_override = _glow(color)
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bolt.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(bolt)


## Chain lightning: a bright core in the shooter's colour in an electric-blue spark, the same behind
## every one, so it reads as lightning that leaps from mark to mark.
func _build_lightning() -> void:
	var core := MeshInstance3D.new()
	core.name = "Core"
	core.mesh = _core_mesh(radius)
	core.material_override = _glow(color)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	var spark := MeshInstance3D.new()
	spark.name = "Trail"
	spark.mesh = _cone_mesh(radius * 1.4)
	spark.material_override = _trail(SPARK)
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spark.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	spark.scale = Vector3(1.0, 1.5, 1.0)
	spark.position = Vector3(0.0, 0.0, 0.5)
	add_child(spark)


static func _grenade_body() -> StandardMaterial3D:
	if _grenade_casing == null:
		_grenade_casing = StandardMaterial3D.new()
		_grenade_casing.albedo_color = Color(0.17, 0.21, 0.14)
		_grenade_casing.metallic = 0.2
		_grenade_casing.roughness = 0.5
	return _grenade_casing


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
