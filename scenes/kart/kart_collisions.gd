class_name KartCollisions
extends RefCounted
## What happens when a [Kart] runs into something, GAME.md 4.1 and 6.2: another kart, a turret it
## is ramming, or a wall. Kept apart from the kart itself so that file stays about rules rather
## than about contact response, the same way [KartVisuals] keeps the geometry out of it.
##
## Reporting a wall hit is harder than it looks. `move_and_slide` has already stopped the body at
## the wall by the time this runs, so how hard the wall was hit has to come from what the motor
## still wants rather than from what the body did; that also means a kart
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
## A body going slower than this share of what its motor wants is pinned at the wall rather than
## sliding along it.
const PINNED := 0.5
## Meters between the sideways steps that look for a way round the end of a wall.
const EDGE_STEP := 0.05
## Meters ahead the way round the end of a wall has to be clear: a good deal more than the kart
## covers in a tick, so that a long wall met at an angle is not taken for the end of one.
const EDGE_AHEAD := 1.0
## How square to the end of a wall a kart has to meet it to be eased round it, as the cosine of
## the angle between its travel and the way the end faces: about 30 degrees.
const EDGE_SQUARE := 0.85


## Applies every contact [method CharacterBody3D.move_and_slide] found. [param pre] is the
## velocity the motor wanted before the body slid along anything.
##
## [param quiet] is a client predicting its own kart, GAME.md 10.3. It wants the push a wall or
## another kart gives, because that is movement and movement is what it is predicting, and none
## of the consequences: no crate broken, no kart rammed, no crash heard. Those are the host's to
## decide and arrive on their own, and a replay would raise each of them again every time it ran
## back over the same tick.
##
## A pop bumper met in the tick throws the kart once it has seen everything else the tick ran
## into, so a wall touched on the same tick does not take the throw back off it, see [Bumper].
static func resolve(kart: Kart, pre: Vector3, quiet: bool = false) -> void:
	var touching_wall := false
	var eased := false
	var bumper: Bumper = null
	for i: int in kart.get_slide_collision_count():
		var collision := kart.get_slide_collision(i)
		var normal := collision.get_normal()
		if absf(normal.y) > FLOOR_NORMAL:
			continue
		var collider := collision.get_collider()
		var other := collider as Kart
		var turret := collider as Turret
		var crate := collider as Crate
		if collider is Bumper:
			bumper = collider as Bumper
		elif other != null:
			_bump(kart, other, normal, pre, quiet)
		elif turret != null and kart.ramming:
			if not quiet:
				turret.destroy()
		elif crate != null and _smashes(kart, crate, normal, pre, quiet):
			continue
		elif eased:
			continue
		elif _eases_round(kart, normal, pre):
			# Round the end of a wall rather than into it, and so into nothing else this tick.
			eased = true
		else:
			touching_wall = _wall(kart, normal, pre, touching_wall, quiet) or touching_wall
	kart.touching_wall = touching_wall
	kart.thrown_by = bumper
	if bumper != null:
		bumper.throw(kart, pre, quiet)


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
		# A teammate's ram is a bump with friendly fire off, GAME.md 3.14: nothing knocked loose.
		var spared := Teams.spares(kart.slot, kart.team, other)
		if kart.ram_kills() and not spared and ram(other, kart.slot, kart.is_decoy()):
			_raged(kart)
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
## knock the pot out a handful a tick until nothing was left. Returns whether it reached them.
## [param by_decoy] says the rammer was [param by_slot]'s decoy, for the kill feed.
static func ram(victim: Kart, by_slot: int, by_decoy := false) -> bool:
	if not victim.alive or victim.falling or victim.coasting or victim.ram_wait > 0.0:
		return false
	victim.kill_how = {"decoy": by_decoy}
	victim.ram_wait = victim.rules.ram_cooldown
	# Counted for the rammer, GAME.md 3.8, once a ram and whatever it did: a shield, a life, a death
	# or only coins knocked out.
	victim.ram_landed.emit(by_slot)
	var shield := victim.shielded and victim.is_targetable()
	victim.take_ram(by_slot)
	if victim.alive and not shield:
		victim.rammed.emit(by_slot)
	return true


## A ram that landed because of a joker such as Road Rage rather than Boost or nitro, which the
## joker's card says, GAME.md 8.3.
static func _raged(kart: Kart) -> void:
	if kart.ramming or kart.nitro_active:
		return
	for joker: Joker in kart.jokers.in_play:
		if joker.ram_kills(kart):
			joker.went_off(kart, "WRECKED")
			return


## A bullet reaching [param kart] while it cannot be hurt, just back or just hit, GAME.md 3.6: it
## stops on the kart, spent and harmless, with a flash of its color, rather than going on through
## as if nobody were there, which read as a kart that was not. Its owner's own shot passes, and so
## does anybody's through a kart down a hole or gone. Whether the bullet is spent on it.
static func shrugs_off(kart: Kart, bullet: Bullet) -> bool:
	if not kart.alive or kart.falling or kart.coasting or bullet.owner_slot == kart.slot:
		return false
	Events.bullet_deflected.emit(bullet.global_position, bullet.color)
	return true


## Distance from a point on the floor plane to [param kart]'s body rectangle, 0 when inside.
static func distance_to_body(kart: Kart, point: Vector3) -> float:
	var local := kart.to_local(Vector3(point.x, kart.global_position.y, point.z))
	var half := Vector3(kart.stats.width * 0.5, 0.0, kart.stats.length * 0.5)
	var clamped := Vector3(clampf(local.x, -half.x, half.x), 0.0, clampf(local.z, -half.z, half.z))
	return Vector3(local.x, 0.0, local.z).distance_to(clamped)


## A kart that clips the very end of a wall, GAME.md 4.1, is eased sideways round it and keeps its
## speed, rather than being stopped dead by a corner it all but missed: when it meets the end
## about square, no more than [member KartStats.wall_edge_nudge] of it is in the way and the way
## past is clear. A kart driven into a wall with no end near, or into a corner, is stopped as ever.
## The kart moves sideways at [member KartStats.wall_edge_nudge_speed] for the ticks it takes, so
## it is seen to slip past rather than jump. Returns whether it was eased round.
static func _eases_round(kart: Kart, normal: Vector3, pre: Vector3) -> bool:
	var travel := Vector3(pre.x, 0.0, pre.z)
	var facing := Vector3(normal.x, 0.0, normal.z).normalized()
	var most := kart.stats.wall_edge_nudge
	if travel.length() < 0.1 or most <= 0.0 or -travel.normalized().dot(facing) < EDGE_SQUARE:
		return false
	var ahead := travel.normalized() * EDGE_AHEAD
	var side := travel.normalized().cross(Vector3.UP)
	var at := kart.global_transform
	var shift := Vector3.ZERO
	var reach := EDGE_STEP
	while shift == Vector3.ZERO and reach <= most + 0.001:
		for way: float in [1.0, -1.0]:
			var offset := side * way * reach
			if not kart.test_move(at, offset) and not kart.test_move(at.translated(offset), ahead):
				shift = offset
				break
		reach += EDGE_STEP
	if shift == Vector3.ZERO:
		return false
	var step := kart.stats.wall_edge_nudge_speed * kart.get_physics_process_delta_time()
	kart.move_and_collide(shift.limit_length(step))
	kart.motor.velocity = travel
	kart.velocity = travel
	return true


## One wall contact. Returns whether it was a square hit rather than a glance along the wall.
static func _wall(
	kart: Kart, normal: Vector3, pre: Vector3, already: bool, quiet: bool = false
) -> bool:
	kart.motor.velocity = Vector3(kart.velocity.x, 0.0, kart.velocity.z)
	var into := -pre.dot(normal)
	var delta := kart.get_physics_process_delta_time()
	var square := not kart.motor.apply_wall_glance(normal, pre, delta)
	if square:
		# Stopped at the wall, the motor stops with it: left wanting its speed into the wall, a
		# kart pinned there was still doing it, so backing off first braked a speed it did not have
		# and turning away ground along the wall before lurching off it. Sliding along it, the
		# motor is left be, as the body goes on at its speed.
		var real := kart.get_real_velocity()
		if Vector2(real.x, real.z).length() < kart.motor.speed() * PINNED:
			kart.motor.went(real)
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
