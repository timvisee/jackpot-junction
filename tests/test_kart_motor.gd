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


## The kart drifts the oversteer way, GAME.md 4.1, and these tests are about the tighten drift it
## keeps alongside: holding the wheel over holds the slide and the kart turns tighter. Switching
## the style on the shared stats is enough, since the motor reads them every tick.
func _use_the_tighten_drift() -> void:
	_stats.drift_style = KartStats.DriftStyle.TIGHTEN


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


## GAME.md 4.1: the bottle is its own throttle, so nitro moves a kart that is not on the pedal.
func test_nitro_pushes_the_kart_forward_without_the_throttle() -> void:
	_motor.nitro_bonus = 1.9
	_run(1.0)
	assert_float(_motor.forward_speed).is_greater(_stats.top_speed)
	# From a standstill going backwards, it turns the kart around rather than letting it drift on.
	_motor.nitro_bonus = 1.0
	_input.brake = 1.0
	_run(2.0)
	assert_float(_motor.forward_speed).is_less(0.0)
	_input.brake = 0.0
	_motor.nitro_bonus = 1.9
	_run(1.0)
	assert_float(_motor.forward_speed).is_greater(0.0)
	# Braking still overrules it, so there is a way out of a burn.
	_input.brake = 1.0
	_run(0.5)
	assert_float(_motor.forward_speed).is_less(_stats.top_speed)


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


## GAME.md 4.1: turning on the spot and turning on the wheels are one control, mixed rather than
## switched between, because a kart shuffling about in a corner crosses that range over and over.
func test_the_turn_on_the_spot_blends_into_the_turn_on_the_wheels() -> void:
	var rates: Array[float] = []
	for speed: float in [0.0, 0.4, 0.8, 1.2, 1.6, 2.2]:
		rates.append(_rate_at(_stats, speed))
	# Rising the whole way, with no step in it: every gap is smaller than the whole range.
	for i: int in range(1, rates.size()):
		assert_float(rates[i]).is_greater(rates[i - 1])
		assert_float(rates[i] - rates[i - 1]).is_less(rates[-1] - rates[0])
	assert_float(rates[0]).is_equal_approx(_stats.turn_in_place_rate_deg, 1.0)
	# Switched instead of blended, the old way steps: a fifth of a metre a second either side of
	# the threshold changes the turn rate by more than the whole blended range does.
	var widest := 0.0
	for i: int in range(1, rates.size()):
		widest = maxf(widest, rates[i] - rates[i - 1])
	_stats.pivot_blend_speed = 0.0
	var parked := _rate_at(_stats, _stats.min_steer_speed - 0.1)
	var rolling := _rate_at(_stats, _stats.min_steer_speed + 0.1)
	assert_float(rolling - parked).is_greater(widest * 3.0)


## Degrees a second the nose comes round at a given speed, with the wheel fully over.
func _rate_at(stats: KartStats, speed: float) -> float:
	var motor := KartMotor.new(stats)
	var input := KartInput.new()
	input.steer = 1.0
	input.throttle = speed / stats.top_speed
	motor.velocity = motor.forward_vector() * speed
	motor.forward_speed = speed
	var before := motor.heading
	motor.step(input, DT)
	return rad_to_deg(absf(wrapf(motor.heading - before, -PI, PI)) / DT)


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
	_use_the_tighten_drift()
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


## GAME.md 4.1: the rear comes round over the entry time rather than arriving sideways in one
## tick, and hooks back up when the drift ends.
func test_the_slide_arrives_over_the_entry_time_rather_than_at_once() -> void:
	_use_the_tighten_drift()
	_input.throttle = 1.0
	_run(2.0)
	_input.steer = 1.0
	_input.handbrake = true
	_motor.step(_input, DT)
	assert_bool(_motor.drifting).is_true()
	# Asked for, but barely arrived: one tick of an 0.18 s entry.
	assert_float(_motor.drift_amount).is_less(0.2)
	assert_float(absf(rad_to_deg(_motor.slip_angle()))).is_less(6.0)
	_run(_stats.drift_entry_time)
	assert_float(_motor.drift_amount).is_equal_approx(1.0, 0.05)
	var sideways := absf(rad_to_deg(_motor.slip_angle()))
	assert_float(sideways).is_greater(15.0)
	# Letting go hooks it back up over the exit time.
	_input.handbrake = false
	_input.steer = 0.0
	_motor.step(_input, DT)
	assert_float(_motor.drift_amount).is_less(1.0)
	_run(_stats.drift_exit_time + 0.1)
	assert_float(_motor.drift_amount).is_equal(0.0)


## GAME.md 4.1: turning the other way mid-drift throws most of the slide away, so the rear comes
## back through the middle and bites before it steps out the other side.
func test_changing_sides_mid_drift_goes_through_the_middle() -> void:
	_input.throttle = 1.0
	_run(2.0)
	_input.steer = 1.0
	_input.handbrake = true
	_run(0.6)
	var settled := rad_to_deg(_motor.slip_angle())
	assert_float(absf(settled)).is_greater(20.0)
	_input.steer = -1.0
	_motor.step(_input, DT)
	# Most of the slide is gone the moment the wheel crosses over, and it starts again from
	# there rather than from where it was.
	assert_float(_motor.drift_amount).is_less(0.5)
	# It passes through straight rather than mirroring: there is a moment of grip in the middle.
	var crossed := false
	for i: int in 30:
		_motor.step(_input, DT)
		crossed = crossed or absf(rad_to_deg(_motor.slip_angle())) < 8.0
	assert_bool(crossed).override_failure_message("the kart mirrored instead of crossing").is_true()
	_run(0.5)
	# And ends up sideways the other way.
	assert_float(rad_to_deg(_motor.slip_angle()) * signf(settled)).is_less(0.0)
	assert_float(absf(rad_to_deg(_motor.slip_angle()))).is_greater(20.0)


## The ramp can be switched off, which puts the old instant drift back: the slide lands whole in
## the tick the handbrake goes in.
func test_the_drift_ramp_can_be_turned_off() -> void:
	_use_the_tighten_drift()
	_stats.drift_ramp = false
	_input.throttle = 1.0
	_run(2.0)
	_input.steer = 1.0
	_input.handbrake = true
	_motor.step(_input, DT)
	assert_bool(_motor.drifting).is_true()
	assert_float(_motor.drift_amount).is_equal(1.0)
	_input.handbrake = false
	_input.steer = 0.0
	_motor.step(_input, DT)
	assert_float(_motor.drift_amount).is_equal(0.0)


func test_a_short_drift_gives_no_boost() -> void:
	_use_the_tighten_drift()
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
	_use_the_tighten_drift()
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
	assert_float(_motor.speed()).is_less(_stats.top_speed * 0.45)
	_run(0.3)
	assert_float(_motor.speed()).is_equal_approx(0.0, 0.001)


func test_drift_grip_keeps_more_sideways_velocity() -> void:
	_use_the_tighten_drift()
	var gripping := _sideways_speed_after_turn(false)
	var sliding := _sideways_speed_after_turn(true)
	assert_float(sliding).is_greater(gripping * 1.5)


func test_a_handbrake_drift_goes_visibly_sideways_then_hooks_up_on_release() -> void:
	_use_the_tighten_drift()
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
	assert_float(turned - _turn_without_the_kick()).is_greater(_stats.drift_entry_kick_deg * 0.9)


## The same drift entry with the kick turned off, so the kick can be read as the difference
## rather than guessed at from the yaw rate it is added to.
func _turn_without_the_kick() -> float:
	var stats: KartStats = _stats.duplicate()
	stats.drift_entry_kick_deg = 0.0
	var motor := KartMotor.new(stats)
	var input := KartInput.new()
	input.throttle = 1.0
	for i: int in int(2.5 / DT):
		motor.step(input, DT)
	input.steer = 1.0
	motor.step(input, DT)
	var before := motor.heading
	input.handbrake = true
	for i: int in int(stats.drift_entry_kick_time / DT) + 1:
		motor.step(input, DT)
	return rad_to_deg(wrapf(before - motor.heading, -PI, PI))


func _sideways_speed_after_turn(drifting: bool) -> float:
	var motor := KartMotor.new(_stats)
	motor.velocity = motor.forward_vector() * _stats.top_speed
	motor.heading = 0.6
	motor.drifting = drifting
	motor.drift_amount = 1.0 if drifting else 0.0
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


## GAME.md 6.2: the shove is a gift, not a sentence. Braking, the handbrake or a real turn of the
## wheel hands the kart straight back, with the speed it was given still on it.
func test_a_turbo_shove_can_be_steered_or_braked_out_of_at_once() -> void:
	_motor.apply_turbo(Vector3(0.0, 0.0, -1.0))
	assert_bool(_motor.turboing()).is_true()
	# A nudge of the wheel is for lining up during the shove, and does not end it.
	_input.steer = 0.2
	_motor.step(_input, DT)
	assert_bool(_motor.turboing()).is_true()
	# Putting it over does, and the kart keeps what the pad gave it.
	_input.steer = 1.0
	_motor.step(_input, DT)
	assert_bool(_motor.turboing()).is_false()
	assert_float(_motor.speed()).is_greater_equal(_stats.top_speed)
	# So does the brake, from a fresh shove.
	_input.steer = 0.0
	_motor.apply_turbo(Vector3(0.0, 0.0, -1.0))
	_input.brake = 1.0
	_motor.step(_input, DT)
	assert_bool(_motor.turboing()).is_false()
	# And so does the handbrake.
	_input.brake = 0.0
	_motor.apply_turbo(Vector3(0.0, 0.0, -1.0))
	_input.handbrake = true
	_motor.step(_input, DT)
	assert_bool(_motor.turboing()).is_false()


func test_turbo_pad_crossed_sideways_shoves_briefly_then_slides_off_it() -> void:
	_motor.apply_turbo(Vector3(1.0, 0.0, 0.0))
	assert_float(_motor.heading).is_equal_approx(0.0, 0.0001)
	assert_float(_motor.turbo_time_left).is_equal_approx(_stats.turbo_side_push_time, 0.0001)
	_run(0.1)
	assert_float(_motor.velocity.x).is_greater(10.0)
	_run(1.6)
	assert_bool(_motor.turboing()).is_false()
	# Most of the shove is scrubbed off, but the kart drives out of it rather than being left
	# standing: sideways slip costs half what it used to.
	assert_float(_motor.speed()).is_less(_stats.top_speed * 0.45)
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


func test_nitro_is_faster_but_steers_and_grips_less() -> void:
	_input.throttle = 1.0
	_run(2.5)
	_input.steer = 1.0
	var before := _motor.heading
	_run(0.5)
	var plain_turn := absf(wrapf(_motor.heading - before, -PI, PI))
	_input.steer = 0.0
	_motor.nitro_bonus = _stats.nitro_speed_multiplier
	_run(2.5)
	assert_float(_motor.speed()).is_greater(_stats.top_speed * 1.5)
	_input.steer = 1.0
	before = _motor.heading
	_run(0.5)
	var nitro_turn := absf(wrapf(_motor.heading - before, -PI, PI))
	assert_float(nitro_turn).is_less(plain_turn * 0.75)


func test_a_shallow_wall_hit_glances_off_and_turns_the_kart_along_the_wall() -> void:
	_input.throttle = 1.0
	_run(2.5)
	# Heading 20 degrees left of -Z, into a wall on the left whose normal points +X.
	_motor.heading = deg_to_rad(20.0)
	_motor.velocity = _motor.forward_vector() * _motor.speed()
	var glanced := _motor.apply_wall_glance(Vector3(1.0, 0.0, 0.0), _motor.velocity)
	assert_bool(glanced).is_true()
	assert_float(rad_to_deg(_motor.heading)).is_between(5.0, 12.0)
	assert_float(_motor.velocity.x).is_greater(0.5)
	assert_float(_motor.velocity.z).is_less(-5.0)
	assert_float(_motor.speed()).is_greater(_stats.top_speed * 0.8)
	# A steep hit is no glance and is left to the wall hit rules.
	_motor.heading = deg_to_rad(60.0)
	_motor.velocity = _motor.forward_vector() * 8.0
	assert_bool(_motor.apply_wall_glance(Vector3(1.0, 0.0, 0.0), _motor.velocity)).is_false()
