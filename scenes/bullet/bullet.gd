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
## The area burst an explosive shot deals, see [method _detonate]. A path rather than a preload, and
## the match found as a plain [Node], so the bullet does not compile-depend on [Blast] or [Match]:
## those pull in half the arena, and a bullet drawn into that web shifts the order the project's
## classes are scanned in and breaks a typed [code]preload[/code] elsewhere, GAME.md 10.7.
const BLAST_SCRIPT := "res://scenes/items/blast.gd"
## Everything a shot is drawn with, loaded once at runtime rather than preloaded for the same reason
## as [constant BLAST_SCRIPT], see [BulletArt] and [method _draw_kit].
const BULLET_ART_SCRIPT := "res://scenes/bullet/bullet_art.gd"
## A boomerang's arc, GAME.md 5.3, in degrees a second: how gently it bows going out and how hard it
## sweeps back, so it traces a smooth curve rather than flying straight and snapping round, see
## [method _return_step].
const BOOMERANG_OUT_TURN := 55.0
const BOOMERANG_BACK_TURN := 165.0
## The electric blue-white a chain-lightning leap is drawn in, see [method _leap_to_next].
const CHAIN_ARC_INK := Color(0.68, 0.88, 1.0)
## A grenade's lob, GAME.md 5.3: thrown up and forward, it falls under this gravity, bounces off the
## floor keeping this much of its speed up and across, rolls to a stop and lies there until its
## fuse, see [method _grenade_tick]. Heights and speeds are in meters and meters a second.
const GRENADE_GRAVITY := 20.0
const GRENADE_TOSS_UP := 4.2
const GRENADE_REST_Y := 0.2
const GRENADE_FLOOR_BOUNCE := 0.42
const GRENADE_FLOOR_KEEP := 0.65
const GRENADE_ROLL_KEEP := 0.9
const GRENADE_WALL_KEEP := 0.6
## Below this upward bounce it stops hopping, and below this ground speed it lies still.
const GRENADE_REST_UP := 1.3
const GRENADE_REST_SPEED := 1.5
## A flak shell's airburst, GAME.md 5.3: how wide its pellets fan, and how fast and briefly each
## flies, see [method _spawn_pellets].
const FLAK_SPREAD_DEG := 60.0
const FLAK_PELLET_SPEED := 22.0
const FLAK_PELLET_LIFE := 0.45
## How long after a sticky bomb latches on it goes off, GAME.md 5.3, see [method _stick_to].
const STICKY_FUSE := 0.9

## The ray every shot looks along to see whether a target is in the open, set up once and pointed
## again each time, as each bullet's own [member _ray] is.
static var _sight := PhysicsRayQueryParameters3D.new()
## The blast and drawing scripts, loaded once at runtime rather than preloaded, see [constant
## BLAST_SCRIPT] and [constant BULLET_ART_SCRIPT].
static var _blast: GDScript
static var _art: GDScript
## The stats every flak pellet flies with, built once, see [method _pellet_stats].
static var _pellet: CannonStats

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
## How many pellets it bursts into (a flak shell), how near an enemy arms it (a mine), whether it
## sticks to the kart it hits (a sticky bomb) and how long it locks a cannon (a scrambler), see 5.3.
var cluster := 0
var arm_radius := 0.0
var sticky := false
var jam := 0.0

## On a client: dead-reckons between snapshots, never collides.
var puppet := false
var _puppet_target := Vector3.ZERO
var _puppet_has_target := false

var _dead := false
## Whether a boomerang is on its way back to the shooter now.
var _returning := false
## Whether a grenade has come to rest on the floor, lying still until its fuse, see [method
## _grenade_tick].
var _at_rest := false
## The kart a sticky bomb is stuck to, by instance id, zero until it sticks, see [method _stick_to].
var _stuck_to := 0
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
## Where a boomerang was fired from, to know when it has flown out far enough to turn back.
var _origin := Vector3.ZERO
## A chain-lightning bolt's arcs, re-struck at random angles each tick, see [BulletArt].
var _sparks: Array[MeshInstance3D] = []


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
	cluster = stats.cluster
	arm_radius = stats.arm_radius
	sticky = stats.sticky
	jam = stats.jam
	_origin = position
	# A grenade and a mine are lobbed, not fired flat: they leave the muzzle with an upward kick and
	# arc down, see [method _grenade_tick].
	if _is_lobbed():
		velocity.y = GRENADE_TOSS_UP


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
		# A fuse: it bursts where it lies -- a grenade's blast, a flak shell's pellets -- rather than
		# simply going out, see [method _burst].
		if explode_on_expire:
			_burst()
		destroy()
		return
	if _stuck_to != 0:
		_follow_stuck()
	elif _is_lobbed():
		_run_grenade(delta)
	else:
		_run_shot(delta)


## A shot's tick that is not a grenade's: it bends, moves, grazes and faces the way it flies. Split
## off [method _physics_process] so that one keeps within its returns.
func _run_shot(delta: float) -> void:
	if returns:
		_return_step(delta)
	elif assist_enabled and (assist_after_bounce or not bounced):
		_steer(delta)
	if _dead:
		return
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
	# A sticky bomb latches onto the first kart it reaches and waits out its fuse rather than
	# bursting at once, GAME.md 5.3, see [method _stick_to]; against anything else it bursts.
	if sticky and _stuck_to == 0 and crate == null:
		var caught := collider as Kart
		if caught != null and not _spares(caught):
			_stick_to(caught)
			return true
	if _bursts():
		if crate == null and _spares(collider):
			return false
		_land(collider, crate)
		_burst()
		destroy()
		return true
	var id := collider.get_instance_id()
	if (pierce_left > 0 or chain_left > 0 or returns) and _hit_ids.has(id):
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
	if returns:
		# A boomerang flies on through what it hits; its lifetime or its home ends it, not a hit.
		_hit_ids[id] = true
		return false
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


## A boomerang's flight, GAME.md 5.3: it bows gently to one side on the way out, then once it has
## flown its range sweeps smoothly back onto the kart that threw it, which may have moved; gone once
## it reaches it, or when its lifetime ends. The bow and the sweep turn the same way, so the path is
## one continuous curve rather than a straight throw that snaps round. Turning back it forgets what
## it hit, so it may catch the same marks on the way home.
func _return_step(delta: float) -> void:
	if not _returning:
		# Still going out: curve the flight so the turn home continues an arc already begun.
		velocity = velocity.rotated(Vector3.UP, deg_to_rad(BOOMERANG_OUT_TURN) * delta)
		if _flat_gap(_origin, global_position) >= assist_range:
			_returning = true
			_hit_ids.clear()
		return
	var back := deg_to_rad(BOOMERANG_BACK_TURN) * delta
	var home := _owner_home()
	if home == Vector3.INF:
		# The thrower is gone: keep curving on the same arc until the fuse ends it.
		velocity = velocity.rotated(Vector3.UP, back)
		return
	var to := Vector3(home.x - global_position.x, 0.0, home.z - global_position.z)
	if to.length() < 1.0:
		destroy()
		return
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var angle := flat.signed_angle_to(to, Vector3.UP)
	velocity = velocity.rotated(Vector3.UP, clampf(angle, -back, back))


## Where the kart that threw the boomerang is now, or [constant Vector3.INF] when it is gone: a
## boomerang whose thrower is dead flies out and expires rather than chasing nothing.
func _owner_home() -> Vector3:
	var kart := Kart.of_slot(get_tree(), owner_slot)
	return kart.global_position if kart != null else Vector3.INF


static func _flat_gap(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## A grenade's whole tick: it lobs and settles, then catches a kart that drives onto it even where
## it lies still and grazes the rest, see [method _grenade_tick]. Split off the tick so it keeps
## within its returns.
func _run_grenade(delta: float) -> void:
	_grenade_tick(delta)
	if _dead:
		return
	# An armed mine lying in wait bursts the moment an enemy comes within reach, GAME.md 5.3.
	if kind == &"mine" and _at_rest and _enemy_near(arm_radius):
		_burst()
		destroy()
		return
	_hit_overlapping_targets(get_world_3d().direct_space_state)
	if _dead:
		return
	_update_grazes()
	_orient()


## A grenade's lob, GAME.md 5.3: it falls under gravity, bounces off a wall in its flat path and off
## the floor when it lands, and rolls to a stop, see [method _settle_on_floor]. It goes off on a
## direct hit the way any bursting shot does, see [method _resolve_hit]; otherwise it lies where it
## came to rest until its fuse. Does nothing once at rest -- the fuse in [method _physics_process]
## ends it then.
func _grenade_tick(delta: float) -> void:
	if _at_rest:
		return
	velocity.y -= GRENADE_GRAVITY * delta
	var from := global_position
	var to := from + velocity * delta
	previous_position = from
	var space := get_world_3d().direct_space_state
	# A wall or a target in the flat path, cast at the grenade's height so the floor is not read as
	# one: a target is struck, a wall is bounced off keeping some pace.
	_ray.from = from
	_ray.to = Vector3(to.x, from.y, to.z)
	var hit := space.intersect_ray(_ray)
	if not hit.is_empty():
		var collider: Object = hit["collider"]
		if collider is Crate or collider.has_method("take_hit"):
			if _resolve_hit(collider):
				return
		else:
			_bounce_off_wall(hit["position"], hit["normal"], from.y)
			return
	if to.y <= GRENADE_REST_Y:
		to.y = GRENADE_REST_Y
		_settle_on_floor()
	global_position = to


## A grenade touching the floor: it bounces back up keeping [constant GRENADE_FLOOR_BOUNCE] of its
## fall, losing pace across the ground; once the hop is small it stops hopping and rolls, and once
## the roll is slow it lies still, see [member _at_rest].
func _settle_on_floor() -> void:
	var up := absf(velocity.y) * GRENADE_FLOOR_BOUNCE
	if up < GRENADE_REST_UP:
		velocity.y = 0.0
		velocity.x *= GRENADE_ROLL_KEEP
		velocity.z *= GRENADE_ROLL_KEEP
		if Vector2(velocity.x, velocity.z).length() < GRENADE_REST_SPEED:
			_at_rest = true
			velocity = Vector3.ZERO
	else:
		velocity.y = up
		velocity.x *= GRENADE_FLOOR_KEEP
		velocity.z *= GRENADE_FLOOR_KEEP


## A grenade off a wall at [param point] (kept at height [param y]): its flat travel reflects and
## loses some pace, its fall is untouched, and a mark is left where it struck, GAME.md 8.3.
func _bounce_off_wall(point: Vector3, normal: Vector3, y: float) -> void:
	var flat_normal := Vector3(normal.x, 0.0, normal.z).normalized()
	if flat_normal.is_zero_approx():
		flat_normal = -Vector3(velocity.x, 0.0, velocity.z).normalized()
	var bounced_flat := Vector3(velocity.x, 0.0, velocity.z).bounce(flat_normal) * GRENADE_WALL_KEEP
	velocity.x = bounced_flat.x
	velocity.z = bounced_flat.z
	Events.bullet_struck.emit(Vector3(point.x, y, point.z), flat_normal, color)
	global_position = Vector3(point.x, y, point.z) + flat_normal * (radius + SKIN)


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
	# A bolt drawn between the mark just struck and the next, so the leaps read as one chain, see
	# [ZapArc]. The host alone chains, so it alone says so; the arc is shown on every screen.
	Events.chain_arc.emit(global_position, target.global_position, CHAIN_ARC_INK)
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
		# A scrambler locks the cannon rather than taking a life, GAME.md 5.3, and is spent doing it;
		# the longest lock in force wins, so a second hit cannot cut the first short.
		if jam > 0.0:
			kart.cannon_locked_left = maxf(kart.cannon_locked_left, jam)
			return true
		kart.kill_how = {"decoy": from_decoy, "bounces": bounced_times}
	return collider.call("take_hit", self)


## Whether the shot goes off where it lands or over its fuse: a blast, a cluster of pellets, or both
## at once.
func _bursts() -> bool:
	return blast_radius > 0.0 or cluster > 0


## The shot going off, GAME.md 5.3: its blast dealt and its pellets thrown, each as far as it has.
func _burst() -> void:
	_detonate()
	if cluster > 0:
		_spawn_pellets()


## The shot bursts where it is, GAME.md 5.3: the host deals the area damage and every screen shows
## the flash, see [Blast]. Nothing on a client, whose shots are puppets that never touch anything.
func _detonate() -> void:
	if puppet or blast_radius <= 0.0:
		return
	if _blast == null:
		_blast = load(BLAST_SCRIPT)
	_blast.go(_match(), global_position, blast_radius, owner_slot, owner_team, color)


## A flak shell's airburst, GAME.md 5.3: a fan of plain, short-lived pellets thrown out along the
## way the shell was flying. The host alone throws them; they reach clients as the shell's own shots
## do, in the snapshot, see [MatchSnapshot]. Spawned through the system the shell hangs under, found
## by a method rather than its type so the bullet does not compile-depend on it.
func _spawn_pellets() -> void:
	if puppet:
		return
	var system := get_parent()
	if system == null or not system.has_method("spawn"):
		return
	var base := Vector3(velocity.x, 0.0, velocity.z)
	base = base.normalized() if not base.is_zero_approx() else Vector3.FORWARD
	var spread := deg_to_rad(FLAK_SPREAD_DEG)
	for i: int in cluster:
		var share := 0.5 if cluster < 2 else float(i) / float(cluster - 1)
		var dir := base.rotated(Vector3.UP, lerpf(-spread, spread, share))
		var pellet: Bullet = system.spawn(owner_slot, global_position, dir, _pellet_stats(), color)
		pellet.owner_team = owner_team
		pellet.spares_team = spares_team
		pellet.from_turret = from_turret
		pellet.from_decoy = from_decoy


## A sticky bomb latching onto [param kart], GAME.md 5.3: it rides along on the kart's back with a
## short fuse running, and goes off on it wherever it has got to, see [method _follow_stuck].
func _stick_to(kart: Kart) -> void:
	_stuck_to = kart.get_instance_id()
	velocity = Vector3.ZERO
	lifetime_left = STICKY_FUSE
	explode_on_expire = true


## A stuck bomb riding its kart: it keeps to the kart's position until the fuse ends it; should the
## kart be gone, the fuse is cut short so it bursts where it last was.
func _follow_stuck() -> void:
	var kart := instance_from_id(_stuck_to) as Node3D
	if kart == null or not is_instance_valid(kart):
		lifetime_left = 0.0
		return
	global_position = Vector3(kart.global_position.x, HEIGHT, kart.global_position.z)


## Whether an enemy kart (not the owner's or a teammate's) is within [param reach] of the shot on
## the flat: what trips a mine, GAME.md 5.3.
func _enemy_near(reach: float) -> bool:
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var kart := node as Kart if is_instance_valid(node) else null
		if kart == null or kart.slot == owner_slot or Teams.same(owner_team, kart.team):
			continue
		if kart.is_targetable() and _flat_gap(global_position, kart.global_position) <= reach:
			return true
	return false


## Whether the shot is lobbed in an arc rather than fired flat: a grenade or a mine.
func _is_lobbed() -> bool:
	return kind == &"grenade" or kind == &"mine"


## The stats a flak pellet flies with, shared by every shell: a plain, fast, short-lived ball.
static func _pellet_stats() -> CannonStats:
	if _pellet == null:
		_pellet = CannonStats.new()
		_pellet.bullet_speed = FLAK_PELLET_SPEED
		_pellet.bullet_radius = 0.1
		_pellet.lifetime = FLAK_PELLET_LIFE
		_pellet.aim_assist = false
		_pellet.max_live_bullets = 99
	return _pellet


## The match this shot is in, found by walking up rather than asking the tree, which in a split
## screen or a test holds more than one. Returned as a plain [Node], not typed [Match], and found by
## a method only a match has rather than by its type, so the bullet does not compile-depend on it,
## see [constant BLAST_SCRIPT].
func _match() -> Node:
	var at: Node = self
	while at != null:
		if at.has_method("kart_of"):
			return at
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
		# Out of bounces: a shot that goes off does so against the wall where it would have died --
		# an explosive bursts, a flak shell throws its pellets, see [method _burst].
		if _bursts():
			global_position = Vector3(point.x, HEIGHT, point.z)
			_burst()
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
	if kind == &"boomerang":
		# A boomerang spins flat rather than facing the way it flies.
		rotate_y(0.4)
		return
	if not velocity.is_zero_approx():
		look_at(global_position + velocity, Vector3.UP)
	if kind == &"lightning":
		_draw_kit().crackle(_sparks, radius)


## Builds the look of this shot and keeps a chain-lightning bolt's arcs to re-strike, see
## [BulletArt].
func _build_visuals() -> void:
	_sparks = _draw_kit().build(self, kind, radius, color)


## The drawing kit, loaded once at runtime rather than preloaded, see [constant BULLET_ART_SCRIPT].
func _draw_kit() -> GDScript:
	if _art == null:
		_art = load(BULLET_ART_SCRIPT)
	return _art
