class_name KartMotor
extends RefCounted
## The arcade handling model from GAME.md 4.1, free of scene nodes so it can be unit tested.
##
## The kart has a heading and a velocity that are separate. Every tick the longitudinal speed
## follows throttle and brake, the heading follows steering, and the part of the velocity that
## is not along the heading decays at a grip rate. Drifting lowers the grip, so the kart slides
## while its nose turns faster.

var stats: KartStats
## Yaw in radians about +Y. Forward is -Z rotated by the heading, like a Node3D.
var heading := 0.0
## World-space velocity on the XZ plane.
var velocity := Vector3.ZERO
## Signed speed along the heading, updated every step.
var forward_speed := 0.0
var drifting := false
var drift_time := 0.0
var boost_time_left := 0.0
var turbo_time_left := 0.0
## Multipliers set by power-ups: Boost raises the speed bonus and lowers the steering.
var speed_bonus := 1.0
var steer_multiplier := 1.0


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


func step(input: KartInput, delta: float) -> void:
	boost_time_left = maxf(boost_time_left - delta, 0.0)
	turbo_time_left = maxf(turbo_time_left - delta, 0.0)
	var forward := forward_vector()
	forward_speed = velocity.dot(forward)
	var lateral := velocity - forward * forward_speed
	_step_longitudinal(input, delta)
	_step_drift(input)
	_step_steering(input, delta)
	var grip := stats.grip_drift if drifting else stats.grip_normal
	lateral *= exp(-grip * delta)
	if drifting:
		forward_speed *= 1.0 - stats.drift_speed_decay * delta
	velocity = forward_vector() * forward_speed + lateral
	velocity.y = 0.0
	var limit := max_speed()
	if velocity.length() > limit:
		velocity = velocity.normalized() * limit


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


func _step_drift(input: KartInput) -> void:
	var fraction := absf(forward_speed) / stats.top_speed
	if drifting:
		var steering := absf(input.steer) >= stats.drift_exit_steer
		var too_slow := fraction < stats.handbrake_speed_fraction * 0.75
		if too_slow or (not steering and not input.handbrake):
			_end_drift()
		return
	if turboing() or forward_speed <= 0.0:
		return
	var hard_turn := absf(input.steer) >= stats.drift_steer_threshold
	var fast := fraction >= stats.drift_speed_fraction
	var handbrake := input.handbrake and fraction >= stats.handbrake_speed_fraction
	if (hard_turn and fast) or handbrake:
		drifting = true
		drift_time = 0.0


func _end_drift() -> void:
	drifting = false
	if drift_time >= stats.drift_min_duration:
		boost_time_left = stats.drift_exit_boost_duration
		forward_speed *= 1.0 + stats.drift_exit_boost
	drift_time = 0.0


func _step_steering(input: KartInput, delta: float) -> void:
	if drifting:
		drift_time += delta
	if absf(forward_speed) <= stats.min_steer_speed:
		return
	var rate := yaw_rate(absf(forward_speed) / stats.top_speed)
	if drifting:
		rate *= stats.drift_yaw_multiplier
	if turboing():
		rate *= stats.turbo_steer_multiplier
	rate *= steer_multiplier
	# Steering right is clockwise seen from above, which is a negative rotation about +Y.
	heading = wrapf(heading - input.steer * rate * signf(forward_speed) * delta, -PI, PI)


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
