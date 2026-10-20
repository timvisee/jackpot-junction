class_name BotPits
extends RefCounted
## The last word on a bot's driving, GAME.md 9.1: whatever it was doing, it does not drive into
## a pit, nor touch a live cabinet, 6.2, which kills as surely and is kept clear of the same way:
## its footprint is a hole here. Paths keep clear of the holes where there is room, see
## [ArenaNav], but a bot cutting a corner, sliding out of a drift, backing out of a wall, dodging a
## bullet or shoved off its line would go in regardless, so the controls it has settled on for
## this tick are played forward a second, the kart turning at the rate its wheel gives at the speed
## its pedals give, and its body checked against each hole at every step of the way.
##
## A straight line along the way the kart is moving, which it used to check, says nothing about
## a kart that is turning, which is most of the time, and everything about one parked beside a
## hole: it fled holes it was never going to enter and drove into the ones its turn carried it
## to. When the wheel the bot wants leads in, the nearest wheel either side that does not is
## taken instead, the same side as last time while a hole is near so it does not flip between
## the two; the brakes go on only when no wheel at all keeps it out.
##
## Stepped by its [BotBrain] once the rest of the tick has had its say. With no hole within reach
## of a second's driving it costs a distance to each hole; with one, the controls are played
## forward every other tick at most while they hold steady, see [constant LIKE_STEER].

## How far ahead the controls are played, in seconds, and in how many steps: at top speed a step
## is under two meters, which no hole's trigger and the body round it fit between.
const HORIZON := 1.0
const STEPS := 6
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

## How near this tick's wheel and pedals have to be to the ones played forward last tick, and
## found to keep the kart out, for that to stand for this tick too: a tick of difference at top
## speed is a sixth of a meter, well inside [constant MARGIN] and what speed adds to it, and the
## controls are played forward every other tick at most rather than every one.
const LIKE_STEER := 0.15
const LIKE_PEDAL := 0.2

var brain: BotBrain
## Which way it last turned out of a hole's way, held while one is near: +1, -1 or 0 for none.
var _side := 0.0
## The wheel and the pedals, as x and y, last played forward and found clear, and whether last
## tick went by them rather than playing its own forward, see [constant LIKE_STEER].
var _checked_steer := INF
var _checked_pedals := Vector2.INF
var _went_by := false
## The holes within reach this tick, as their triggers grown by the body and the margin.
var _near: Array[Rect2] = []
## Every hole's trigger, worked out from the grid's holes when their number changes, which is
## only when a room digs or shuts one, see [Trench].
var _holes: Array[Rect2] = []
## How the kart turns, taken off its stats once a tick for the playing forward, in radians a
## second: on the spot, on the wheels slow and fast, and the speed between the first two.
var _pivot := 0.0
var _yaw_slow := 0.0
var _yaw_fast := 0.0
var _blend_speed := 1.0


func _init(owner: BotBrain) -> void:
	brain = owner


## Overrides this tick's controls, already written into the brain's input, where they would take
## the kart into a hole: another wheel if one keeps it out, else the brakes as well.
func guard() -> void:
	var kart := brain.kart
	var input := brain.input
	if kart.falling or kart.motor.spinning() or not _holes_near():
		_side = 0.0
		_checked_steer = INF
		return
	if not _went_by and not input.nitro and _like_last(input):
		_went_by = true
		return
	_went_by = false
	_checked_steer = INF
	var stats := kart.motor.stats
	_pivot = deg_to_rad(stats.turn_in_place_rate_deg)
	_yaw_slow = deg_to_rad(stats.yaw_rate_low_deg)
	_yaw_fast = deg_to_rad(stats.yaw_rate_high_deg)
	_blend_speed = maxf(stats.pivot_blend_speed, 0.001)
	if _clear(input.steer, input.throttle, input.brake, input.nitro):
		_checked_steer = input.steer
		_checked_pedals = Vector2(input.throttle, input.brake)
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


## Whether this tick's controls are near enough the ones last played forward and found clear to
## go by, see [constant LIKE_STEER].
func _like_last(input: BotInput) -> bool:
	return (
		absf(input.steer - _checked_steer) < LIKE_STEER
		and absf(input.throttle - _checked_pedals.x) < LIKE_PEDAL
		and absf(input.brake - _checked_pedals.y) < LIKE_PEDAL
	)


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


## Whether any hole is close enough to be reached in [constant HORIZON], filling [member _near]:
## as far as the kart can get in that time from the speed it is doing, whatever it does with the
## pedals, and its body.
func _holes_near() -> bool:
	_near.clear()
	var kart := brain.kart
	var motor := kart.motor
	var grid := brain.match_node.nav.grid
	if _holes.size() != grid.pits.size() + grid.cabinets.size():
		_holes.clear()
		for rect: Rect2i in grid.pits:
			var center := grid.rect_center(rect)
			var half := Pit.trigger_size(grid.rect_size(rect), grid.cell_size) * 0.5
			_holes.append(Rect2(Vector2(center.x, center.z) - half, half * 2.0))
		for run: Rect2i in grid.cabinets:
			_holes.append(LiveCabinet.footprint(grid, run))
	var speed := absf(motor.forward_speed)
	var accel := motor.stats.acceleration() * 1.5
	var travel := minf(speed * HORIZON + 0.5 * accel * HORIZON * HORIZON, motor.max_speed() * 2.0)
	var grow := BODY_RADIUS + MARGIN + MARGIN_PER_SPEED * motor.speed()
	var reach := travel + BODY_REACH
	var here := Vector2(kart.global_position.x, kart.global_position.z)
	for hole: Rect2 in _holes:
		var grown := hole.grow(grow)
		if _distance(grown, here) <= reach:
			_near.append(grown)
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
	# How the motor turns the nose at full lock, see [method KartMotor._step_steering]: on the
	# spot at a standstill, on the wheels once rolling, slower on nitro.
	var on_wheels := stats.nitro_steer_multiplier if boosted else 1.0
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
		var moving := absf(speed)
		var rolling := lerpf(_yaw_slow, _yaw_fast, minf(moving / stats.top_speed, 1.0))
		var blend := minf(moving / _blend_speed, 1.0)
		var rate := lerpf(_pivot, rolling * signf(speed) * on_wheels, blend)
		heading -= steer * rate * motor.steer_multiplier * dt
		var nose := _forward(heading)
		travel = travel.lerp(nose if speed >= 0.0 else -nose, grip).normalized()
		at += travel * moving * dt
		if _touches(at, nose):
			return false
	return true


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
