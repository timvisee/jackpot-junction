extends RefCounted
## How a lobbed shot moves, GAME.md 5.3: the grenade and the mine, which arc under gravity, bounce
## off the floor and walls and roll to a stop rather than flying flat. A mine then lies in wait and
## bursts when an enemy nears, when an enemy shot clears it, or on its fuse; a grenade blinks down
## its fuse. Kept out of [Bullet] and loaded at runtime the way [Blast] is, see [constant
## Bullet.LOB_MOTION_SCRIPT], so the bullet stays short; every call takes the bullet it moves.

## The nearest a bullet of another shooter's may be, plus the two radii, and still count as shooting
## a mine, see [method shot_by_enemy]. Flat, so a shot over a mine on the floor still clears it.
const SHOOT_MARGIN := 0.25


## A lobbed shot's whole tick: it arcs and settles, then -- a mine -- bursts when an enemy nears or
## an enemy shot clears it, or pulses and waits, while a settled grenade blinks its fuse; either
## catches a kart that drives onto it and grazes the rest.
static func run(bullet: Bullet, delta: float) -> void:
	_tick(bullet, delta)
	if bullet._dead:
		return
	if bullet.kind == &"mine":
		bullet._armed_left = maxf(bullet._armed_left - delta, 0.0)
		var tripped := bullet._armed_left <= 0.0 and enemy_near(bullet, bullet.arm_radius)
		if bullet._at_rest and (tripped or shot_by_enemy(bullet)):
			bullet._burst()
			bullet.destroy()
			return
		_pulse(bullet)
	elif bullet._at_rest:
		bullet._telegraph(&"Band", clampf(bullet.lifetime_left, 0.1, 0.4))
	bullet._hit_overlapping_targets(bullet.get_world_3d().direct_space_state)
	if bullet._dead:
		return
	bullet._update_grazes()
	bullet._orient()


## The arc itself: gravity pulls it down, a wall or target in its flat path stops or turns it, and
## the floor settles it, see [method _settle].
static func _tick(bullet: Bullet, delta: float) -> void:
	if bullet._at_rest:
		return
	var v := bullet.velocity
	v.y -= Bullet.GRENADE_GRAVITY * delta
	bullet.velocity = v
	var from := bullet.global_position
	var to := from + bullet.velocity * delta
	bullet.previous_position = from
	var space := bullet.get_world_3d().direct_space_state
	# A wall or target in the flat path, cast at the shot's height so the floor is not read as one.
	bullet._ray.from = from
	bullet._ray.to = Vector3(to.x, from.y, to.z)
	var hit := space.intersect_ray(bullet._ray)
	if not hit.is_empty():
		var collider: Object = hit["collider"]
		if collider is Crate or collider.has_method("take_hit"):
			if bullet._resolve_hit(collider):
				return
		else:
			_off_wall(bullet, hit["position"], hit["normal"], from.y)
			return
	if to.y <= Bullet.GRENADE_REST_Y:
		to.y = Bullet.GRENADE_REST_Y
		_settle(bullet)
	bullet.global_position = to


## Touching the floor: it bounces back up keeping [constant Bullet.GRENADE_FLOOR_BOUNCE] of its
## fall, losing pace across the ground; once the hop is small it rolls, and once the roll is slow it
## lies still, arming a mine as it comes to rest.
static func _settle(bullet: Bullet) -> void:
	var v := bullet.velocity
	var up := absf(v.y) * Bullet.GRENADE_FLOOR_BOUNCE
	if up < Bullet.GRENADE_REST_UP:
		v.y = 0.0
		v.x *= Bullet.GRENADE_ROLL_KEEP
		v.z *= Bullet.GRENADE_ROLL_KEEP
		if Vector2(v.x, v.z).length() < Bullet.GRENADE_REST_SPEED:
			if not bullet._at_rest:
				bullet._armed_left = Bullet.MINE_ARM_DELAY
			bullet._at_rest = true
			v = Vector3.ZERO
	else:
		v.y = up
		v.x *= Bullet.GRENADE_FLOOR_KEEP
		v.z *= Bullet.GRENADE_FLOOR_KEEP
	bullet.velocity = v


## Off a wall at [param point] (kept at height [param y]): its flat travel reflects and loses some
## pace, its fall is untouched, and a mark is left where it struck, GAME.md 8.3.
static func _off_wall(bullet: Bullet, point: Vector3, normal: Vector3, y: float) -> void:
	var v := bullet.velocity
	var flat_normal := Vector3(normal.x, 0.0, normal.z).normalized()
	if flat_normal.is_zero_approx():
		flat_normal = -Vector3(v.x, 0.0, v.z).normalized()
	var bounced := Vector3(v.x, 0.0, v.z).bounce(flat_normal) * Bullet.GRENADE_WALL_KEEP
	v.x = bounced.x
	v.z = bounced.z
	bullet.velocity = v
	Events.bullet_struck.emit(Vector3(point.x, y, point.z), flat_normal, bullet.color)
	bullet.global_position = (
		Vector3(point.x, y, point.z) + flat_normal * (bullet.radius + Bullet.SKIN)
	)


## A mine's light pulsing, GAME.md 5.3: steady when the floor is clear, blinking faster the nearer
## an enemy comes, so the trap warns before it goes off.
static func _pulse(bullet: Bullet) -> void:
	var reach := maxf(bullet.arm_radius * 2.5, 0.001)
	var near := clampf(1.0 - nearest_enemy_gap(bullet) / reach, 0.0, 1.0)
	bullet._telegraph(&"Light", lerpf(0.5, 0.08, near))


## Whether an enemy kart (not the owner's or a teammate's) is within [param reach] of the shot on
## the flat: what trips a mine, GAME.md 5.3.
static func enemy_near(bullet: Bullet, reach: float) -> bool:
	return nearest_enemy_gap(bullet) <= reach


## The flat distance to the nearest enemy kart, or [constant INF] with none: what trips and pulses a
## mine, GAME.md 5.3.
static func nearest_enemy_gap(bullet: Bullet) -> float:
	var best := INF
	for node: Node in FrameGroups.of(bullet.get_tree(), &"karts"):
		var kart := node as Kart if is_instance_valid(node) else null
		if (
			kart == null
			or kart.slot == bullet.owner_slot
			or Teams.same(bullet.owner_team, kart.team)
		):
			continue
		if kart.is_targetable():
			best = minf(best, Bullet._flat_gap(bullet.global_position, kart.global_position))
	return best


## Whether an enemy shot has run into the mine, clearing it, GAME.md 5.3: another shooter's bullet,
## not a mine itself, within reach on the flat. That bullet is spent doing it. A mine may be shot to
## clear it from range before it can trip.
static func shot_by_enemy(bullet: Bullet) -> bool:
	for node: Node in FrameGroups.of(bullet.get_tree(), &"bullets"):
		var other := node as Bullet if is_instance_valid(node) else null
		if other == null or other == bullet or other.puppet or other.kind == &"mine":
			continue
		if other.owner_slot == bullet.owner_slot or Teams.same(bullet.owner_team, other.owner_team):
			continue
		var reach := bullet.radius + other.radius + SHOOT_MARGIN
		if Bullet._flat_gap(bullet.global_position, other.global_position) < reach:
			other.destroy()
			return true
	return false
