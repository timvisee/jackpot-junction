class_name KartMotor
extends RefCounted
## The arcade handling model from GAME.md 4.1, free of scene nodes so it can be unit tested.
##
## The kart has a heading and a direction of travel that are separate. Every tick the speed
## follows throttle and brake, the heading follows steering, and the direction of travel turns
## toward the heading at a grip rate. The steady slip angle is about the yaw rate divided by the
## grip: a few degrees while driving, and in a drift, with low grip and quicker yaw, the nose
## leads the travel direction by tens of degrees and the kart visibly goes sideways.

var stats: KartStats
## Yaw in radians about +Y. Forward is -Z rotated by the heading, like a Node3D.
var heading := 0.0
## World-space velocity on the XZ plane.
var velocity := Vector3.ZERO
## Signed speed: positive when travelling roughly nose first, negative in reverse.
var forward_speed := 0.0
## The steering actually applied this tick: the input shaped by the stick curve and smoothed.
var steer := 0.0
var drifting := false
var drift_time := 0.0
var boost_time_left := 0.0
var turbo_time_left := 0.0
## Multipliers set by power-ups: Boost raises the speed bonus and lowers the steering.
var speed_bonus := 1.0
var steer_multiplier := 1.0

## Radians of drift entry kick still to apply, signed like the steering that started it.
var _kick_remaining := 0.0


func _init(kart_stats: KartStats) -> void:
	stats = kart_stats


func forward_vector() -> Vector3:
	return Vector3(-sin(heading), 0.0, -cos(heading))


func speed() -> float:
	return velocity.length()


## Fraction of top speed currently driven, unsigned, may exceed 1 while boosted.
func speed_fraction() -> float:
	return speed() / stats.top_speed


func boosting() -> bool:
	return boost_time_left > 0.0


func turboing() -> bool:
	return turbo_time_left > 0.0


## Yaw rate in radians per second for a fraction of top speed.
func yaw_rate(fraction: float) -> float:
	var degrees := lerpf(
		stats.yaw_rate_low_deg, stats.yaw_rate_high_deg, clampf(fraction, 0.0, 1.0)
	)
	return deg_to_rad(degrees)


## Speed limit right now, including drift exit boost and turbo.
func max_speed() -> float:
	if turboing():
		return stats.top_speed * stats.turbo_speed_multiplier
	if boosting():
		return stats.top_speed * speed_bonus * (1.0 + stats.drift_exit_boost)
	return stats.top_speed * speed_bonus


## Angle in radians between the nose and the direction of travel, positive when the nose points
## left of the travel direction. Zero when standing still.
func slip_angle() -> float:
	if velocity.length() < 0.05:
		return 0.0
	var travel := velocity.normalized() * signf(forward_speed if forward_speed != 0.0 else 1.0)
	return travel.signed_angle_to(forward_vector(), Vector3.UP)


func step(input: KartInput, delta: float) -> void:
	boost_time_left = maxf(boost_time_left - delta, 0.0)
	turbo_time_left = maxf(turbo_time_left - delta, 0.0)
	var forward := forward_vector()
	var along := velocity.dot(forward)
	var was_moving := velocity.length() > 0.05
	var was_reversing := was_moving and along < 0.0
	forward_speed = velocity.length() * (-1.0 if along < 0.0 else 1.0)
	_step_steer_input(input, delta)
	_step_longitudinal(input, delta)
	_step_drift(input)
	_step_steering(delta)
	var reversing := forward_speed < 0.0
	var target := forward_vector() * (-1.0 if reversing else 1.0)
	var travel := velocity.normalized() if was_moving else target
	# Setting off, or braking through a stop into reverse: travel starts along the nose.
	if not was_moving or reversing != was_reversing:
		travel = target
	var grip := stats.grip_drift if drifting else stats.grip_normal
	var angle := travel.signed_angle_to(target, Vector3.UP)
	travel = travel.rotated(Vector3.UP, angle * (1.0 - exp(-grip * delta)))
	if drifting:
		forward_speed *= 1.0 - stats.drift_speed_decay * delta
	velocity = travel * absf(forward_speed)
	velocity.y = 0.0
	var limit := max_speed()
	if velocity.length() > limit:
		velocity = velocity.normalized() * limit


## Shapes the raw steering by the stick curve and eases it toward the target, so a keyboard tap is
## a small correction and a held key builds to full lock.
func _step_steer_input(input: KartInput, delta: float) -> void:
	var raw := clampf(input.steer, -1.0, 1.0)
	var target := signf(raw) * pow(absf(raw), maxf(stats.stick_curve, 0.1))
	var increasing := (
		absf(target) > absf(steer) or (target != 0.0 and signf(target) != signf(steer))
	)
	var ramp := stats.steer_ramp_up if increasing else stats.steer_ramp_down
	if ramp <= 0.0:
		steer = target
	else:
		steer = move_toward(steer, target, delta / ramp)


func _step_longitudinal(input: KartInput, delta: float) -> void:
	if turboing():
		forward_speed = max_speed()
		return
	var accel := stats.acceleration()
	if input.throttle > 0.01 and (forward_speed >= 0.0 or input.brake <= 0.01):
		forward_speed = move_toward(forward_speed, max_speed() * input.throttle, accel * delta)
	elif input.brake > 0.01:
		if forward_speed > 0.05:
			forward_speed = move_toward(forward_speed, 0.0, stats.brake_decel * input.brake * delta)
		else:
			var target := -stats.reverse_top_speed * input.brake
			forward_speed = move_toward(forward_speed, target, accel * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, stats.coast_decel * delta)
	if input.handbrake and stats.handbrake_decel > 0.0:
		# A drift scrubs speed gently; below drifting speed the handbrake is a real brake.
		var decel := stats.handbrake_decel * (0.35 if drifting else 1.0)
		forward_speed = move_toward(forward_speed, 0.0, decel * delta)


func _step_drift(input: KartInput) -> void:
	var fraction := absf(forward_speed) / stats.top_speed
	if drifting:
		var too_slow := fraction < stats.handbrake_speed_fraction * 0.75
		if stats.handbrake_drift_only:
			if too_slow or not input.handbrake:
				_end_drift()
			return
		var steering := absf(steer) >= stats.drift_exit_steer
		if too_slow or (not steering and not input.handbrake):
			_end_drift()
		return
	if turboing() or forward_speed <= 0.0:
		return
	var handbrake := input.handbrake and fraction >= stats.handbrake_speed_fraction
	var hard_turn := absf(steer) >= stats.drift_steer_threshold
	var fast := fraction >= stats.drift_speed_fraction
	if handbrake or (not stats.handbrake_drift_only and hard_turn and fast):
		drifting = true
		drift_time = 0.0
		# The rear swings out: the nose kicks into the turn over the next fraction of a second.
		var kick := deg_to_rad(stats.drift_entry_kick_deg)
		_kick_remaining = signf(steer) * kick if absf(steer) > 0.1 else 0.0


func _end_drift() -> void:
	drifting = false
	_kick_remaining = 0.0
	if drift_time >= stats.drift_min_duration:
		boost_time_left = stats.drift_exit_boost_duration
		forward_speed *= 1.0 + stats.drift_exit_boost
	drift_time = 0.0


func _step_steering(delta: float) -> void:
	if drifting:
		drift_time += delta
		_step_entry_kick(delta)
	if absf(forward_speed) <= stats.min_steer_speed:
		# Standing still: turn in place to line up a shot, when enabled.
		if stats.turn_in_place_rate_deg > 0.0 and steer != 0.0:
			var in_place := deg_to_rad(stats.turn_in_place_rate_deg) * steer_multiplier
			heading = wrapf(heading - steer * in_place * delta, -PI, PI)
		return
	var rate := yaw_rate(absf(forward_speed) / stats.top_speed)
	if drifting:
		rate *= stats.drift_yaw_multiplier
	if turboing():
		rate *= stats.turbo_steer_multiplier
	rate *= steer_multiplier
	# Steering right is clockwise seen from above, which is a negative rotation about +Y.
	heading = wrapf(heading - steer * rate * signf(forward_speed) * delta, -PI, PI)


## Plays out the drift entry kick as an extra yaw over [member KartStats.drift_entry_kick_time].
func _step_entry_kick(delta: float) -> void:
	if _kick_remaining == 0.0:
		return
	var total := deg_to_rad(stats.drift_entry_kick_deg)
	var rate := total / maxf(stats.drift_entry_kick_time, 0.001)
	var step := minf(rate * delta, absf(_kick_remaining)) * signf(_kick_remaining)
	heading = wrapf(heading - step, -PI, PI)
	_kick_remaining -= step
	if absf(_kick_remaining) < 0.0001:
		_kick_remaining = 0.0


## Launches the kart along a turbo pad's direction: the nose snaps to it and the kart runs at
## turbo speed for the turbo duration with reduced steering.
func apply_turbo(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	if flat.is_zero_approx():
		return
	heading = atan2(-flat.x, -flat.z)
	turbo_time_left = stats.turbo_duration
	drifting = false
	drift_time = 0.0
	velocity = flat * stats.top_speed * stats.turbo_speed_multiplier
	forward_speed = velocity.length()


## Wall contact: the velocity into the wall is gone already (the body slid); a hard hit also
## costs part of the remaining speed.
func apply_wall_hit(into_speed: float) -> void:
	if into_speed > stats.wall_hit_threshold * stats.top_speed:
		velocity *= 1.0 - stats.wall_hit_speed_loss
	turbo_time_left = 0.0


## Contact with another kart. [param normal] points from the other kart toward this one.
func apply_bump(normal: Vector3) -> void:
	var flat := Vector3(normal.x, 0.0, normal.z).normalized()
	velocity = velocity * (1.0 - stats.bump_speed_loss) + flat * stats.bump_push_speed
	velocity.y = 0.0
