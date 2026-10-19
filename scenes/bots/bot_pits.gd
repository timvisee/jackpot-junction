class_name BotPits
extends RefCounted
## The last word on a bot's driving, GAME.md 9.1: whatever it was doing, it does not drive into a
## pit. Paths keep clear of the holes where there is room, see [ArenaNav], but a bot cutting a
## corner, sliding out of a drift, backing out of a wall, dodging a bullet or shoved off its line
## would go in regardless, so the controls it has settled on for this tick are played forward a
## second, the kart turning at the rate its wheel gives at the speed its pedals give, and its
## body checked against each hole at every step of the way.
##
## A straight line along the way the kart is moving, which it used to check, says nothing about
## a kart that is turning, which is most of the time, and everything about one parked beside a
## hole: it fled holes it was never going to enter and drove into the ones its turn carried it
## to. When the wheel the bot wants leads in, the nearest wheel either side that does not is
## taken instead, the same side as last time while a hole is near so it does not flip between
## the two; the brakes go on only when no wheel at all keeps it out.
##
## Stepped by its [BotBrain] once the rest of the tick has had its say, and cheap when no hole is
## within reach, which is nearly always: two distances to a rectangle.

## How far ahead the controls are played, in seconds, and in how many steps.
const HORIZON := 1.0
const STEPS := 8
## The kart's body as two circles along its nose, GAME.md 4.1: a box a meter across and 1.6 m
## long, whose corners these just cover. A hole takes a kart the moment any of it is over the
## hole's trigger, which is 70% of the hole's cells, see [Pit].
const BODY_REACH := 0.4
const BODY_RADIUS := 0.65
## Room left between the body and a hole's trigger, and as much again for every meter a second.
const MARGIN := 0.15
const MARGIN_PER_SPEED := 0.02
## How far off the wheel the bot wants the others tried are, nearest first: the last is the
## other lock, whatever the wheel was.
const FAN: Array[float] = [0.25, 0.5, 1.0, 2.0]

var brain: BotBrain
## Which way it last turned out of a hole's way, held while one is near: +1, -1 or 0 for none.
var _side := 0.0
## The holes within reach this tick, as their triggers grown by the body and the margin.
var _near: Array[Rect2] = []


func _init(owner: BotBrain) -> void:
	brain = owner


## Overrides this tick's controls, already written into the brain's input, where they would take
## the kart into a hole: another wheel if one keeps it out, else the brakes as well.
func guard() -> void:
	var kart := brain.kart
	var input := brain.input
	if kart.falling or kart.motor.spinning() or not _holes_near():
		_side = 0.0
		return
	if _clear(input.steer, input.throttle, input.brake, input.nitro):
		return
	input.handbrake = false
	input.nitro = false
	var wanted := input.steer
	# The pedals it chose first, then the ones that stop it whichever way it is rolling.
	var stopping := _stopping()
	for pedals: Vector2 in [Vector2(input.throttle, input.brake), stopping]:
		for offset: float in FAN:
			for way: float in _ways():
				var steer := clampf(wanted + offset * way, -1.0, 1.0)
				if _clear(steer, pedals.x, pedals.y, false):
					_side = way
					input.steer = steer
					input.throttle = pedals.x
					input.brake = pedals.y
					return
	# Nothing keeps it out: stopping as hard as it can, turned away from the middle of the hole.
	input.throttle = stopping.x
	input.brake = stopping.y
	input.steer = _away()


## The throttle and the brake, as x and y, that bring the kart to a stop the quickest from the
## way it is rolling: the brakes going forward, the throttle going backward, since the brakes
## are reverse once the kart has stopped, and neither standing still.
func _stopping() -> Vector2:
	var speed := brain.kart.motor.forward_speed
	if speed > 0.05:
		return Vector2(0.0, 1.0)
	if speed < -0.05:
		return Vector2(1.0, 0.0)
	return Vector2.ZERO


## Whether any hole is close enough to be reached in [constant HORIZON], filling [member _near].
func _holes_near() -> bool:
	_near.clear()
	var kart := brain.kart
	var motor := kart.motor
	var reach := (
		absf(motor.forward_speed) * HORIZON
		+ motor.max_speed() * HORIZON * 0.5
		+ BODY_REACH
		+ BODY_RADIUS
	)
	var grid := brain.match_node.nav.grid
	var here := Vector2(kart.global_position.x, kart.global_position.z)
	var grow := BODY_RADIUS + MARGIN + MARGIN_PER_SPEED * motor.speed()
	for rect: Rect2i in grid.pits:
		var center := grid.rect_center(rect)
		var half := grid.rect_size(rect) * Pit.TRIGGER_SHARE * 0.5 + Vector2.ONE * grow
		var hole := Rect2(Vector2(center.x, center.z) - half, half * 2.0)
		if _distance(hole, here) <= reach:
			_near.append(hole)
	return not _near.is_empty()


## Whether a second of [param steer], [param throttle] and [param brake] keeps the body out of
## every hole near, with nitro lit or not by [param nitro].
func _clear(steer: float, throttle: float, brake: float, nitro: bool) -> bool:
	var kart := brain.kart
	var motor := kart.motor
	var stats := motor.stats
	var dt := HORIZON / STEPS
	var at := Vector2(kart.global_position.x, kart.global_position.z)
	var heading := motor.heading
	var speed := motor.forward_speed
	var lights := nitro and motor.nitro_bonus <= 1.0 and kart.nitro_charge >= stats.nitro_min_start
	var boosted := lights or motor.nitro_bonus > 1.0
	var limit := motor.max_speed() * (stats.nitro_speed_multiplier if lights else 1.0)
	if (boosted or motor.turboing()) and brake <= 0.01:
		throttle = 1.0
	var accel := stats.acceleration() * (1.5 if boosted else 1.0)
	var travel := Vector2(motor.velocity.x, motor.velocity.z)
	travel = travel.normalized() if travel.length() > 0.05 else _forward(heading)
	var grip := 1.0 - exp(-(stats.grip_drift if motor.drifting else stats.grip_normal) * dt)
	for step: int in STEPS:
		if throttle > 0.01 and (speed >= 0.0 or brake <= 0.01):
			speed = move_toward(speed, limit * throttle, accel * dt)
		elif brake > 0.01:
			if speed > 0.05:
				speed = move_toward(speed, 0.0, stats.brake_decel * brake * dt)
			else:
				speed = move_toward(speed, -stats.reverse_top_speed * brake, accel * dt)
		else:
			speed = move_toward(speed, 0.0, stats.coast_decel * dt)
		heading -= steer * _turn_rate(speed) * dt
		var nose := _forward(heading) * (1.0 if speed >= 0.0 else -1.0)
		travel = travel.lerp(nose, grip).normalized()
		at += travel * absf(speed) * dt
		if _touches(at, _forward(heading)):
			return false
	return true


## How fast the nose comes round at [param speed] with the wheel at full lock, as the motor turns
## it, see [method KartMotor._step_steering]: on the spot at a standstill, on the wheels once
## rolling, slower on nitro.
func _turn_rate(speed: float) -> float:
	var motor := brain.kart.motor
	var stats := motor.stats
	var pivot := deg_to_rad(stats.turn_in_place_rate_deg)
	var rolling := motor.yaw_rate(absf(speed) / stats.top_speed) * signf(speed)
	if motor.nitro_bonus > 1.0:
		rolling *= stats.nitro_steer_multiplier
	var blend := clampf(absf(speed) / maxf(stats.pivot_blend_speed, 0.001), 0.0, 1.0)
	return lerpf(pivot, rolling, blend) * motor.steer_multiplier


## Whether the body at [param at], nose along [param nose], is over a hole near.
func _touches(at: Vector2, nose: Vector2) -> bool:
	var front := at + nose * BODY_REACH
	var back := at - nose * BODY_REACH
	for hole: Rect2 in _near:
		if hole.has_point(front) or hole.has_point(back):
			return true
	return false


## The ways to try a wheel off the one wanted: the side it took last time first.
func _ways() -> Array[float]:
	return [-1.0, 1.0] if _side < 0.0 else [1.0, -1.0]


## A wheel that turns the nose away from the middle of the nearest hole.
func _away() -> float:
	var kart := brain.kart
	var here := Vector2(kart.global_position.x, kart.global_position.z)
	var nearest := _near[0]
	for hole: Rect2 in _near:
		if _distance(hole, here) < _distance(nearest, here):
			nearest = hole
	var away := here - nearest.get_center()
	var nose := _forward(kart.motor.heading)
	# A wheel to the right brings the nose round to whatever is on its right, which is the side
	# the cross product of the two is positive on, see [method KartMotor._step_steering].
	var turn := signf(nose.cross(away))
	return turn if turn != 0.0 else 1.0


## The nose of a kart at [param heading], flat, see [method KartMotor.forward_vector].
static func _forward(heading: float) -> Vector2:
	return Vector2(-sin(heading), -cos(heading))


## How far [param point] is from [param rect], nought inside it.
static func _distance(rect: Rect2, point: Vector2) -> float:
	var nearest := point.clamp(rect.position, rect.end)
	return nearest.distance_to(point)
