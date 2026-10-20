class_name ClaimCheck
extends RefCounted
## What the host lets a client's word for its own kart say, GAME.md 10.3. The host follows the
## client about where its kart is, since how it drove is the client's to answer, but the host has
## just driven the same tick itself from the same controls, and its own answer is the most the
## client's may be: no more in the nitro tank, no more boost, turbo or drift banked, no less of a
## spin, no longer a bumper's throw, no power-up the host has not given it, no more speed than the
## kart can go, and no further than it could have driven, nor through a wall. A client that says
## otherwise, broken or cheating, is held to the host's answer, and one that claims to be somewhere
## it could not have got to is not followed.

## Slack on the host's own answer for a client a tick out of step with it: a tick's worth of each
## timer, and of the nitro a tick burns, twice over.
const TIME_SLACK := 2.0 / 60.0
const NITRO_SLACK := 0.02
## How much faster than the kart's limit a claim may say it is going, for rounding, in m/s.
const SPEED_SLACK := 0.5
## How many ticks of driving at its limit a kart's reach may bank: a packet late and the next on
## time is two ticks at once, and the host holds a few in hand, see [constant NetInput.QUEUE_MAX].
const REACH_TICKS := 4.0
## How high over the floor a claim's way is looked along for a wall: where the bullets fly, under
## the top of every wall and crate and over the floor.
const WALL_HEIGHT := 0.5

## The one ray every claim's way is looked along, see [method through_wall].
static var _way: PhysicsRayQueryParameters3D


## Whether [param claim] is a kart's state at all, the way [method KartPrediction.capture] puts it:
## as long as that, every field a number, a flag or the velocity, and every number a real one.
static func well_formed(claim: Array) -> bool:
	if claim.size() != 4 + KartMotor.STATE_FIELDS.size():
		return false
	for field: Variant in claim:
		if field is Vector3:
			if not (field as Vector3).is_finite():
				return false
		elif not plain(field):
			return false
	return true


## Whether [param field] is a flag, a whole number or a real number, and not infinity or NaN.
static func plain(field: Variant) -> bool:
	match typeof(field):
		TYPE_BOOL, TYPE_INT:
			return true
		TYPE_FLOAT:
			return is_finite(field)
	return false


## One tick of [param on]'s reach: how far it may have gone since it was last believed, grown by a
## tick of driving at the kart's limit as the host has it, and kept to [constant REACH_TICKS].
static func step_reach(on: Kart, input: NetInput, delta: float) -> void:
	var tick := (on.motor.max_speed() + SPEED_SLACK) * delta
	input.reach_left = minf(input.reach_left + tick, tick * REACH_TICKS)


## Whether [param on] could have got from [param from], where it started the tick, to [param to]
## within its reach; if so the distance is spent from it.
static func reaches(input: NetInput, from: Vector3, to: Vector3) -> bool:
	var gone := Vector2(to.x - from.x, to.z - from.z).length()
	if gone > input.reach_left:
		return false
	input.reach_left -= gone
	return true


## Whether the way from [param from] to [param to] runs through a wall or a crate of [param on]'s
## room, which no kart drives through: one ray a claim, at the host, so cheap enough for every
## client every tick. A kart up against a wall starts inside nothing, and slides along it, so an
## honest claim's way never crosses one.
static func through_wall(on: Kart, from: Vector3, to: Vector3) -> bool:
	var flat := Vector2(to.x - from.x, to.z - from.z)
	if flat.length_squared() < 0.0001 or not on.is_inside_tree():
		return false
	if _way == null:
		_way = PhysicsRayQueryParameters3D.new()
		_way.collision_mask = Layers.WORLD
	_way.from = Vector3(from.x, from.y + WALL_HEIGHT, from.z)
	_way.to = Vector3(to.x, from.y + WALL_HEIGHT, to.z)
	return not on.get_world_3d().direct_space_state.intersect_ray(_way).is_empty()


## What the host made of the tick itself, before the client's word is laid over it.
static func own(on: Kart) -> Dictionary:
	var motor := on.motor
	return {
		"boost": motor.boost_time_left,
		"turbo": motor.turbo_time_left,
		"thrown": motor.thrown_left,
		"kicks": motor.kicks,
		"kick_gap": motor.kick_gap_left,
		"kick_rest": motor.kick_rest_left,
		"spin": motor.spin_time_left,
		"drift": motor.drift_time,
		"speed_bonus": motor.speed_bonus,
		"steer_multiplier": motor.steer_multiplier,
		"nitro": on.nitro_charge,
		"burning": on.nitro_active,
	}


## Holds [param on], with the client's word laid over it, to the host's [param answer] of the same
## tick, see [method own].
static func hold(on: Kart, answer: Dictionary) -> void:
	var motor := on.motor
	# The power-ups the kart holds are the host's to give, and the client has no say in them.
	motor.speed_bonus = answer["speed_bonus"]
	motor.steer_multiplier = answer["steer_multiplier"]
	motor.boost_time_left = minf(motor.boost_time_left, float(answer["boost"]) + TIME_SLACK)
	motor.turbo_time_left = minf(motor.turbo_time_left, float(answer["turbo"]) + TIME_SLACK)
	# A pop bumper's throw lifts the kart's limit while it lasts, GAME.md 6.2, and is the host's
	# to have seen on the same tick, as a turbo pad's shove is.
	motor.thrown_left = minf(motor.thrown_left, float(answer["thrown"]) + TIME_SLACK)
	# A run of bumpers' kicks and the rest after a long one are counted on the host too, 6.2: no
	# longer a rest, nor more of a run, which would bring one on sooner, than it counted.
	motor.kick_rest_left = minf(motor.kick_rest_left, float(answer["kick_rest"]) + TIME_SLACK)
	motor.kick_gap_left = minf(motor.kick_gap_left, float(answer["kick_gap"]) + TIME_SLACK)
	motor.kicks = mini(motor.kicks, int(answer["kicks"]) + 1)
	motor.drift_time = minf(motor.drift_time, float(answer["drift"]) + TIME_SLACK)
	motor.spin_time_left = maxf(motor.spin_time_left, float(answer["spin"]) - TIME_SLACK)
	on.nitro_charge = clampf(on.nitro_charge, 0.0, float(answer["nitro"]) + NITRO_SLACK)
	# Lit only where the host's own tank could have lit it, and a nitro bonus only with the flame.
	var could := bool(answer["burning"]) or float(answer["nitro"]) >= on.stats.nitro_min_start
	on._set_nitro_active(on.nitro_active and could and on.nitro_charge > 0.0)
	var limit := motor.max_speed() + SPEED_SLACK
	motor.velocity = Vector3(motor.velocity.x, 0.0, motor.velocity.z).limit_length(limit)
	motor.forward_speed = clampf(motor.forward_speed, -limit, limit)
	on.velocity = motor.velocity
