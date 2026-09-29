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
##
## [param quiet] is a client predicting its own kart, GAME.md 10.3. It wants the push a wall or
## another kart gives, because that is movement and movement is what it is predicting, and none
## of the consequences: no crate broken, no kart rammed, no crash heard. Those are the host's to
## decide and arrive on their own, and a replay would raise each of them again every time it ran
## back over the same tick.
static func resolve(kart: Kart, pre: Vector3, quiet: bool = false) -> void:
	var touching_wall := false
	for i: int in kart.get_slide_collision_count():
		var collision := kart.get_slide_collision(i)
		var normal := collision.get_normal()
		if absf(normal.y) > FLOOR_NORMAL:
			continue
		var collider := collision.get_collider()
		var other := collider as Kart
		var turret := collider as Turret
		var crate := collider as Crate
		if other != null:
			_bump(kart, other, normal, pre, quiet)
		elif turret != null and kart.ramming:
			if not quiet:
				turret.destroy()
		elif crate != null and _smashes(kart, crate, normal, pre, quiet):
			continue
		else:
			touching_wall = _wall(kart, normal, pre, touching_wall, quiet) or touching_wall
	kart.touching_wall = touching_wall


## A crate taken at ramming speed, GAME.md 6.2. A kart that could ram another kart to death
## goes through a box rather than bouncing off it, so nitro, the Ram item and Road Rage all
## clear cover. The kart keeps the speed it arrived with: being stopped dead by a wooden box
## is the opposite of what breaking it is for. Returns whether the crate went.
static func _smashes(
	kart: Kart, crate: Crate, normal: Vector3, pre: Vector3, quiet: bool = false
) -> bool:
	if not crate.alive or not kart.ram_kills() or -pre.dot(normal) <= CRASH_SPEED:
		return false
	if quiet:
		# Predicted: the box comes off the floor so the kart is not seen driving through one that
		# is still there, and nothing it was worth is decided here.
		crate.predict_break()
	else:
		crate.hit(kart.slot)
	kart.motor.velocity = pre
	kart.velocity = pre
	return true


static func _bump(
	kart: Kart, other: Kart, normal: Vector3, pre: Vector3, quiet: bool = false
) -> void:
	if not quiet:
		kart.last_bump_slot = other.slot
		kart.last_bump_time = Time.get_ticks_msec() * 0.001
		# Two karts touching is the one thing neither machine can settle on its own: each sees
		# the other where it last heard, and each predicting its own side would have both shoved
		# and neither right. The host takes the wheel off both of them for a moment, GAME.md 10.3.
		kart.input.deny_claim(NetInput.CLAIM_DENIED)
		other.input.deny_claim(NetInput.CLAIM_DENIED)
		if kart.ram_kills():
			ram(other, kart.slot)
	kart.motor.apply_bump(normal)
	kart.velocity = kart.motor.velocity
	if pre.length() > BUMP_SPEED:
		kart.motor.spoil_drift()
		if not quiet:
			Events.kart_bumped.emit(kart.slot)


## A ramming kart reached [param victim], GAME.md 4.1: its shield pops, or it loses a life or dies.
## One too freshly hurt, or too freshly back, to be hurt again is still knocked, and loses coins
## rather than a life, which the match hears of through [signal Kart.rammed], as it does of a ram
## the victim lives through. Two karts in touch meet on every tick of it, so a ram reaches nobody
## again for [member MatchRules.ram_cooldown] after the last one, or one that never let go would
## knock the pot out a handful a tick until nothing was left.
static func ram(victim: Kart, by_slot: int) -> void:
	if not victim.alive or victim.falling or victim.coasting or victim.ram_wait > 0.0:
		return
	victim.ram_wait = victim.rules.ram_cooldown
	var shield := victim.shielded and victim.is_targetable()
	victim.take_ram(by_slot)
	if victim.alive and not shield:
		victim.rammed.emit(by_slot)


## Distance from a point on the floor plane to [param kart]'s body rectangle, 0 when inside.
static func distance_to_body(kart: Kart, point: Vector3) -> float:
	var local := kart.to_local(Vector3(point.x, kart.global_position.y, point.z))
	var half := Vector3(kart.stats.width * 0.5, 0.0, kart.stats.length * 0.5)
	var clamped := Vector3(clampf(local.x, -half.x, half.x), 0.0, clampf(local.z, -half.z, half.z))
	return Vector3(local.x, 0.0, local.z).distance_to(clamped)


## One wall contact. Returns whether it was a square hit rather than a glance along the wall.
static func _wall(
	kart: Kart, normal: Vector3, pre: Vector3, already: bool, quiet: bool = false
) -> bool:
	kart.motor.velocity = Vector3(kart.velocity.x, 0.0, kart.velocity.z)
	var into := -pre.dot(normal)
	var square := not kart.motor.apply_wall_glance(normal, pre)
	if square:
		kart.motor.apply_wall_hit(into)
		if into > CRASH_SPEED:
			# A glance along a wall is part of driving here and costs nothing; a square hit
			# is a crash, and a crash has nothing to collect at the end of it.
			kart.motor.spoil_drift()
		if (
			not quiet
			and not already
			and not kart.touching_wall
			and kart.crash_wait <= 0.0
			and into > CRASH_SPEED
		):
			kart.crash_wait = CRASH_INTERVAL
			Events.kart_crashed.emit(kart.slot, force(kart.stats, into))
	kart.velocity = kart.motor.velocity
	return square


## How hard a wall was hit: 0 at the lightest contact worth hearing, 1 straight into it flat out.
static func force(stats: KartStats, into: float) -> float:
	return clampf((into - CRASH_SPEED) / maxf(stats.top_speed - CRASH_SPEED, 0.001), 0.0, 1.0)
