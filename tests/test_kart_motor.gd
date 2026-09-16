extends GdUnitTestSuite
## The arcade handling model behaves as GAME.md 4.1 describes, at a 60 Hz tick.

const DT := 1.0 / 60.0

var _stats: KartStats
var _motor: KartMotor
var _input: KartInput


func before_test() -> void:
	_stats = load("res://data/kart/default.tres").duplicate()
	_motor = KartMotor.new(_stats)
	_input = KartInput.new()


func _run(seconds: float) -> void:
	for i: int in int(round(seconds / DT)):
		_motor.step(_input, DT)


func test_full_throttle_reaches_top_speed_in_about_accel_time() -> void:
	_input.throttle = 1.0
	_run(_stats.accel_time * 0.5)
	assert_float(_motor.speed()).is_between(_stats.top_speed * 0.4, _stats.top_speed * 0.6)
	_run(_stats.accel_time)
	assert_float(_motor.speed()).is_equal_approx(_stats.top_speed, 0.01)


func test_braking_stops_then_reverses_up_to_reverse_top_speed() -> void:
	_input.throttle = 1.0
	_run(2.0)
	_input.throttle = 0.0
	_input.brake = 1.0
	_run(1.0)
	assert_float(_motor.forward_speed).is_less(0.0)
	_run(2.0)
	assert_float(_motor.forward_speed).is_equal_approx(-_stats.reverse_top_speed, 0.01)


func test_coasting_slows_down_and_stops() -> void:
	_input.throttle = 1.0
	_run(2.0)
	_input.throttle = 0.0
	_run(1.0)
	assert_float(_motor.speed()).is_between(_stats.top_speed - 5.0, _stats.top_speed - 3.0)
	_run(4.0)
	assert_float(_motor.speed()).is_equal_approx(0.0, 0.001)


func test_yaw_rate_interpolates_from_low_to_high_speed() -> void:
	assert_float(rad_to_deg(_motor.yaw_rate(0.0))).is_equal_approx(_stats.yaw_rate_low_deg, 0.01)
	assert_float(rad_to_deg(_motor.yaw_rate(1.0))).is_equal_approx(_stats.yaw_rate_high_deg, 0.01)
	var middle := (_stats.yaw_rate_low_deg + _stats.yaw_rate_high_deg) * 0.5
	assert_float(rad_to_deg(_motor.yaw_rate(0.5))).is_equal_approx(middle, 0.01)


func test_standing_still_turns_in_place_only_when_enabled() -> void:
	_input.steer = 1.0
	_run(0.5)
	assert_float(_motor.heading).is_less(0.0)
	assert_float(_motor.speed()).is_equal(0.0)
	_stats.turn_in_place_rate_deg = 0.0
	_motor.heading = 0.0
	_run(1.0)
	assert_float(_motor.heading).is_equal(0.0)


func test_steering_ramps_up_and_shapes_the_stick() -> void:
	_stats.steer_ramp_up = 0.12
	_stats.steer_ramp_down = 0.08
	_stats.stick_curve = 1.5
	_input.throttle = 1.0
	_run(1.0)
	_input.steer = 1.0
	_motor.step(_input, DT)
	assert_float(_motor.steer).is_between(0.05, 0.3)
	_run(0.2)
	assert_float(_motor.steer).is_equal_approx(1.0, 0.001)
	_input.steer = 0.5
	_run(0.3)
	assert_float(_motor.steer).is_equal_approx(pow(0.5, _stats.stick_curve), 0.01)
	_stats.steer_ramp_up = 0.0
	_stats.steer_ramp_down = 0.0
	_stats.stick_curve = 1.0
	_input.steer = -1.0
	_motor.step(_input, DT)
	assert_float(_motor.steer).is_equal(-1.0)


func test_steering_right_is_clockwise_and_reversing_flips_it() -> void:
	_input.throttle = 1.0
	_run(1.0)
	_input.steer = 0.5
	_run(0.5)
	assert_float(_motor.heading).is_less(0.0)
	_motor.heading = 0.0
	_motor.velocity = Vector3.ZERO
	_input.throttle = 0.0
	_input.brake = 1.0
	_input.steer = 0.0
	_run(1.5)
	_input.steer = 0.5
	_run(0.5)
	assert_float(_motor.heading).is_greater(0.0)


func test_hard_turn_at_speed_drifts_and_a_long_drift_exit_boosts() -> void:
	_stats.handbrake_drift_only = false
	_input.throttle = 1.0
	_run(2.0)
	_input.steer = 1.0
	_run(1.0)
	assert_bool(_motor.drifting).is_true()
	assert_float(_motor.drift_time).is_greater(_stats.drift_min_duration)
	_input.steer = 0.0
	_run(0.2)
	assert_bool(_motor.drifting).is_false()
	assert_bool(_motor.boosting()).is_true()
	assert_float(_motor.speed()).is_greater(_stats.top_speed)


func test_a_short_drift_gives_no_boost() -> void:
	_stats.handbrake_drift_only = false
	_input.throttle = 1.0
	_run(2.0)
	_input.steer = 1.0
	_run(0.3)
	assert_bool(_motor.drifting).is_true()
	_input.steer = 0.0
	_run(0.2)
	assert_bool(_motor.drifting).is_false()
	assert_bool(_motor.boosting()).is_false()


func test_with_handbrake_only_drifting_steering_never_drifts_and_the_handbrake_brakes() -> void:
	_input.throttle = 1.0
	_run(2.5)
	_input.steer = 1.0
	_run(1.0)
	assert_bool(_motor.drifting).is_false()
	var before := _motor.speed()
	_input.handbrake = true
	_run(0.5)
	assert_bool(_motor.drifting).is_true()
	assert_float(_motor.speed()).is_less(before)
	_input.handbrake = false
	_run(DT)
	assert_bool(_motor.drifting).is_false()
	_input.steer = 0.0
	_input.throttle = 0.0
	_motor.velocity = _motor.forward_vector() * 3.0
	_input.handbrake = true
	_run(0.5)
	assert_float(_motor.speed()).is_equal_approx(0.0, 0.001)


func test_handbrake_drifts_at_lower_speed_than_a_hard_turn() -> void:
	_stats.handbrake_drift_only = false
	_input.throttle = 1.0
	_run(0.75)
	assert_float(_motor.speed_fraction()).is_between(0.42, 0.68)
	_input.steer = 1.0
	_run(DT)
	assert_bool(_motor.drifting).is_false()
	_input.handbrake = true
	_run(DT)
	assert_bool(_motor.drifting).is_true()


func test_the_handbrake_without_steering_stops_the_kart_quickly_without_drifting() -> void:
	_input.throttle = 1.0
	_run(2.5)
	assert_float(_motor.speed()).is_greater(_stats.top_speed * 0.95)
	_input.throttle = 0.0
	_input.handbrake = true
	_run(0.3)
	assert_bool(_motor.drifting).is_false()
	assert_float(_motor.speed()).is_less(_stats.top_speed * 0.7)
	_run(0.9)
	assert_float(_motor.speed()).is_equal_approx(0.0, 0.001)


func test_drift_grip_keeps_more_sideways_velocity() -> void:
	var gripping := _sideways_speed_after_turn(false)
	var sliding := _sideways_speed_after_turn(true)
	assert_float(sliding).is_greater(gripping * 1.5)


func test_a_handbrake_drift_goes_visibly_sideways_then_hooks_up_on_release() -> void:
	_input.throttle = 1.0
	_run(2.5)
	_input.steer = 1.0
	_run(0.5)
	assert_float(rad_to_deg(absf(_motor.slip_angle()))).is_less(15.0)
	_input.handbrake = true
	_run(0.5)
	assert_bool(_motor.drifting).is_true()
	var slip := rad_to_deg(absf(_motor.slip_angle()))
	assert_float(slip).is_between(25.0, 75.0)
	assert_float(_motor.speed()).is_greater(3.0)
	_input.handbrake = false
	_input.steer = 0.0
	_run(0.4)
	assert_bool(_motor.drifting).is_false()
	assert_float(rad_to_deg(absf(_motor.slip_angle()))).is_less(8.0)


func test_drift_entry_kicks_the_nose_into_the_turn() -> void:
	_input.throttle = 1.0
	_run(2.5)
	_input.steer = 1.0
	_run(DT)
	var before := _motor.heading
	_input.handbrake = true
	_motor.step(_input, DT)
	var first_tick := rad_to_deg(wrapf(before - _motor.heading, -PI, PI))
	var plain_turn := (
		rad_to_deg(_motor.yaw_rate(_motor.speed_fraction())) * _stats.drift_yaw_multiplier * DT
	)
	assert_float(first_tick).is_less(_stats.drift_entry_kick_deg * 0.5)
	assert_float(first_tick).is_greater(plain_turn)
	_run(_stats.drift_entry_kick_time)
	var turned := rad_to_deg(wrapf(before - _motor.heading, -PI, PI))
	var expected_plain := plain_turn * (_stats.drift_entry_kick_time / DT + 1.0)
	assert_float(turned).is_greater(expected_plain + _stats.drift_entry_kick_deg * 0.9)


func _sideways_speed_after_turn(drifting: bool) -> float:
	var motor := KartMotor.new(_stats)
	motor.velocity = motor.forward_vector() * _stats.top_speed
	motor.heading = 0.6
	motor.drifting = drifting
	var input := KartInput.new()
	input.throttle = 1.0
	input.steer = 1.0
	input.handbrake = drifting
	for i: int in 6:
		motor.step(input, DT)
	var forward := motor.forward_vector()
	return (motor.velocity - forward * motor.velocity.dot(forward)).length()


func test_turbo_pad_along_the_nose_pushes_for_the_duration_without_turning() -> void:
	_motor.heading = 0.2
	_motor.apply_turbo(Vector3(0.0, 0.0, -1.0))
	assert_float(_motor.heading).is_equal_approx(0.2, 0.0001)
	_run(_stats.turbo_duration * 0.5)
	var turbo_speed := _stats.top_speed * _stats.turbo_speed_multiplier
	assert_float(_motor.speed()).is_equal_approx(turbo_speed, 0.01)
	assert_float(_motor.forward_speed).is_greater(0.0)
	assert_bool(_motor.turboing()).is_true()
	_run(_stats.turbo_duration)
	assert_bool(_motor.turboing()).is_false()
	assert_float(_motor.speed()).is_less(turbo_speed)
	assert_float(_motor.heading).is_equal_approx(0.2, 0.0001)


func test_turbo_pad_against_the_nose_pushes_the_kart_backwards() -> void:
	_motor.apply_turbo(Vector3(0.0, 0.0, 1.0))
	assert_float(_motor.heading).is_equal_approx(0.0, 0.0001)
	_run(_stats.turbo_duration * 0.5)
	assert_float(_motor.forward_speed).is_less(0.0)
	assert_float(_motor.speed()).is_equal_approx(
		_stats.top_speed * _stats.turbo_speed_multiplier, 0.01
	)
	assert_float(_motor.velocity.z).is_greater(0.0)


func test_turbo_pad_crossed_sideways_shoves_briefly_then_slides_to_a_near_stop() -> void:
	_motor.apply_turbo(Vector3(1.0, 0.0, 0.0))
	assert_float(_motor.heading).is_equal_approx(0.0, 0.0001)
	assert_float(_motor.turbo_time_left).is_equal_approx(_stats.turbo_side_push_time, 0.0001)
	_run(0.1)
	assert_float(_motor.velocity.x).is_greater(10.0)
	_run(1.6)
	assert_bool(_motor.turboing()).is_false()
	assert_float(_motor.speed()).is_less(2.0)
	assert_float(_motor.heading).is_equal_approx(0.0, 0.0001)


func test_wall_hits_cost_speed_only_when_hard() -> void:
	_motor.velocity = _motor.forward_vector() * 10.0
	_motor.apply_wall_hit(2.0)
	assert_float(_motor.speed()).is_equal_approx(10.0, 0.001)
	_motor.apply_wall_hit(_stats.top_speed)
	assert_float(_motor.speed()).is_equal_approx(10.0 * (1.0 - _stats.wall_hit_speed_loss), 0.001)


func test_bump_pushes_along_the_normal_and_costs_speed() -> void:
	_motor.velocity = Vector3(0.0, 0.0, -10.0)
	_motor.apply_bump(Vector3(1.0, 0.0, 0.0))
	assert_float(_motor.velocity.x).is_equal_approx(_stats.bump_push_speed, 0.001)
	assert_float(_motor.velocity.z).is_equal_approx(-10.0 * (1.0 - _stats.bump_speed_loss), 0.001)
