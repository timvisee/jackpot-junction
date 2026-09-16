extends GdUnitTestSuite
## The tire handling model from GAME.md 4.1, at a 60 Hz tick. What is pinned here is the things
## the model exists for, not its numbers: the wheel sets the arc, the kart carries sideways
## velocity, the handbrake takes the rear away, and crawling in a corner is calm.

const DT := 1.0 / 60.0

var _stats: KartStats
var _motor: KartMotor
var _input: KartInput


func before_test() -> void:
	_stats = load("res://data/kart/feel_grip.tres").duplicate()
	_motor = KartMotor.new(_stats)
	_input = KartInput.new()


func _run(seconds: float) -> void:
	for i: int in int(round(seconds / DT)):
		_motor.step(_input, DT)


## Radius of the circle the kart has settled into, measured from how fast the nose comes round.
func _radius() -> float:
	var before := _motor.heading
	_motor.step(_input, DT)
	var yaw := absf(wrapf(_motor.heading - before, -PI, PI)) / DT
	return _motor.speed() / yaw if yaw > 0.001 else INF


func test_the_wheel_sets_the_arc_rather_than_the_speed() -> void:
	_input.throttle = 1.0
	_run(3.0)
	_input.steer = 1.0
	_run(2.0)
	var full := _radius()
	_input.steer = 0.5
	_run(2.0)
	var half := _radius()
	# Half the lock, near enough twice the circle: that is what makes a line predictable.
	assert_float(half).is_between(full * 1.6, full * 2.4)


## GAME.md 4.1: the old model turned fastest when the kart was slowest, which is what made close
## quarters feel like spinning a turret. A rolling kart now turns at a rate that comes from how
## fast it is going.
func test_crawling_turns_far_slower_than_the_old_model_did() -> void:
	_input.throttle = 0.25
	_input.steer = 1.0
	_run(2.0)
	var before := _motor.heading
	_run(1.0)
	var turned := rad_to_deg(absf(wrapf(_motor.heading - before, -PI, PI)))
	assert_float(_motor.speed()).is_between(1.5, 4.5)
	assert_float(turned).is_between(30.0, 110.0)


## Stopped, it still turns on the spot to line up a shot, GAME.md 4.1.
func test_a_stopped_kart_still_pivots_to_aim() -> void:
	_input.steer = 1.0
	var before := _motor.heading
	_run(1.0)
	var turned := rad_to_deg(absf(wrapf(_motor.heading - before, -PI, PI)))
	assert_float(turned).is_equal_approx(_stats.turn_in_place_rate_deg, 8.0)
	assert_float(_motor.speed()).is_less(0.1)


## The handbrake is grip taken off the back axle, so the rear steps out and the kart goes sideways.
func test_the_handbrake_takes_the_rear_away() -> void:
	_input.throttle = 1.0
	_run(3.0)
	_input.steer = 1.0
	_run(1.0)
	var gripped := absf(rad_to_deg(_motor.slip_angle()))
	assert_float(gripped).is_less(12.0)
	assert_bool(_motor.drifting).is_false()
	_input.handbrake = true
	var peak := 0.0
	for i: int in 90:
		_motor.step(_input, DT)
		peak = maxf(peak, absf(rad_to_deg(_motor.slip_angle())))
	assert_float(peak).is_greater(25.0)
	assert_bool(_motor.drifting).is_true()
	# Letting go hooks the kart back up rather than leaving it swapped round.
	_input.handbrake = false
	_input.steer = 0.0
	_run(2.0)
	assert_float(absf(rad_to_deg(_motor.slip_angle()))).is_less(12.0)


## Steering right is still clockwise, the same as the rate model, and reversing still flips it.
func test_steering_right_is_clockwise_and_reversing_flips_it() -> void:
	_input.throttle = 1.0
	_run(1.0)
	_input.steer = 0.5
	_run(0.5)
	assert_float(_motor.heading).is_less(0.0)
	_motor.heading = 0.0
	_motor.velocity = Vector3.ZERO
	_motor.yaw = 0.0
	_input.throttle = 0.0
	_input.brake = 1.0
	_input.steer = 0.0
	_run(1.5)
	_input.steer = 0.5
	_run(0.5)
	assert_float(_motor.heading).is_greater(0.0)


## The wheel winds on at a rate instead of snapping to the stick, which is the weight a keyboard
## player feels. Nothing else in the model works if this is instant.
func test_the_wheel_winds_on_rather_than_snapping() -> void:
	_input.throttle = 1.0
	_run(2.0)
	_input.steer = 1.0
	_motor.step(_input, DT)
	var after_one := absf(rad_to_deg(_motor._wheel))
	assert_float(after_one).is_less(_stats.steer_speed_deg * DT + 0.5)
	_run(1.0)
	assert_float(absf(rad_to_deg(_motor._wheel))).is_greater(after_one)


## A corner taken at the limit costs speed, because rubber spent holding the kart cannot also
## drive it. The grippy preset is quick enough about it that a tidy line keeps its speed.
func test_a_slide_costs_speed() -> void:
	var loose: KartStats = load("res://data/kart/feel_rally.tres").duplicate()
	var motor := KartMotor.new(loose)
	var input := KartInput.new()
	input.throttle = 1.0
	for i: int in 180:
		motor.step(input, DT)
	var straight := motor.speed()
	input.steer = 1.0
	for i: int in 180:
		motor.step(input, DT)
	assert_float(motor.speed()).is_less(straight * 0.9)
