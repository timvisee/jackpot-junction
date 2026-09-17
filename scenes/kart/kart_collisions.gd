class_name KartCollisions
extends RefCounted
## What happens when a [Kart] runs into something, GAME.md 4.1 and 6.2: another kart, a turret it
## is ramming, or a wall. Kept apart from the kart itself so that file stays about rules rather
## than about contact response, the same way [KartVisuals] keeps the geometry out of it.
##
## Reporting a wall hit is harder than it looks. `move_and_slide` has already taken the speed
## into the wall off the body by the time this runs, so how hard the wall was hit has to come
## from what the motor still wants rather than from what the body did; that also means a kart
## with the throttle held against a wall asks for a fresh collision every single tick. So a hit
## is reported on the first frame of contact only, and not again for a while afterwards, because
## bouncing down a wall breaks contact between every touch.

## Speed straight into a wall below which a scrape is not worth a sound.
const CRASH_SPEED := 2.5
## Seconds before a kart may be heard hitting a wall again.
const CRASH_INTERVAL := 0.45
## A bump below this speed is a nudge rather than a knock, and is not announced.
const BUMP_SPEED := 3.0
## A collision surface more level than this is the floor, not something to bounce off.
const FLOOR_NORMAL := 0.7


## Applies every contact [method CharacterBody3D.move_and_slide] found. [param pre] is the
## velocity the motor wanted before the body slid along anything.
static func resolve(kart: Kart, pre: Vector3) -> void:
	var touching_wall := false
	for i: int in kart.get_slide_collision_count():
		var collision := kart.get_slide_collision(i)
		var normal := collision.get_normal()
		if absf(normal.y) > FLOOR_NORMAL:
			continue
		var collider := collision.get_collider()
		var other := collider as Kart
		var turret := collider as Turret
		if other != null:
			_bump(kart, other, normal, pre)
		elif turret != null and kart.ramming:
			turret.destroy()
		else:
			touching_wall = _wall(kart, normal, pre, touching_wall) or touching_wall
	kart.touching_wall = touching_wall


static func _bump(kart: Kart, other: Kart, normal: Vector3, pre: Vector3) -> void:
	kart.last_bump_slot = other.slot
	kart.last_bump_time = Time.get_ticks_msec() * 0.001
	if kart.ram_kills():
		other.take_ram(kart.slot)
	kart.motor.apply_bump(normal)
	kart.velocity = kart.motor.velocity
	if pre.length() > BUMP_SPEED:
		Events.kart_bumped.emit(kart.slot)


## One wall contact. Returns whether it was a square hit rather than a glance along the wall.
static func _wall(kart: Kart, normal: Vector3, pre: Vector3, already: bool) -> bool:
	kart.motor.velocity = Vector3(kart.velocity.x, 0.0, kart.velocity.z)
	var into := -pre.dot(normal)
	var square := not kart.motor.apply_wall_glance(normal, pre)
	if square:
		kart.motor.apply_wall_hit(into)
		if not already and not kart.touching_wall and kart.crash_wait <= 0.0 and into > CRASH_SPEED:
			kart.crash_wait = CRASH_INTERVAL
			Events.kart_crashed.emit(kart.slot, force(kart.stats, into))
	kart.velocity = kart.motor.velocity
	return square


## How hard a wall was hit: 0 at the lightest contact worth hearing, 1 straight into it flat out.
static func force(stats: KartStats, into: float) -> float:
	return clampf((into - CRASH_SPEED) / maxf(stats.top_speed - CRASH_SPEED, 0.001), 0.0, 1.0)
