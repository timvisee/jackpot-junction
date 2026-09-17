extends GdUnitTestSuite
## The oversteer drift style from GAME.md 4.1, at a 60 Hz tick. Pulling the handbrake breaks the
## rear loose once; after that the wheel does not hold the slide, it feeds it, bleeds it or catches
## it, which is how a rally car is driven.

const DT := 1.0 / 60.0

var _stats: KartStats
var _motor: KartMotor
var _input: KartInput


func before_test() -> void:
	_stats = load("res://data/kart/feel_oversteer.tres").duplicate()
	_motor = KartMotor.new(_stats)
	_input = KartInput.new()


func _run(seconds: float) -> void:
	for i: int in int(round(seconds / DT)):
		_motor.step(_input, DT)


## Up to speed, then the handbrake and the wheel to the right: the rear lets go.
func _break_the_rear_loose() -> void:
	_input.throttle = 1.0
	_run(3.0)
	_input.steer = 1.0
	_input.handbrake = true
	_run(0.4)


## Degrees of slip, positive when the kart is hanging out to the right of where it is going.
func _hang() -> float:
	return -rad_to_deg(_motor.slip_angle())


func test_the_handbrake_breaks_the_rear_loose() -> void:
	_break_the_rear_loose()
	assert_bool(_motor.drifting).is_true()
	assert_float(_motor.slide_rate).is_greater(0.0)
	assert_float(_hang()).is_greater(20.0)


## The whole point of the style: holding the wheel into the slide loses you the corner. The
## rear keeps coming round until the kart is all but sideways and the speed scrubs away with
## it, so there is a reason to catch it beyond tidiness.
func test_holding_the_wheel_in_loses_you_the_corner() -> void:
	_break_the_rear_loose()
	var carried := _motor.speed()
	var early := _hang()
	_run(0.5)
	assert_float(_hang()).is_greater(early)
	var worst := 0.0
	for i: int in 90:
		_motor.step(_input, DT)
		worst = maxf(worst, _hang())
	# Round far enough to be a mistake, and never so far that the nose passes what it is
	# chasing, which would flip the kart into reverse.
	assert_float(worst).is_greater(70.0)
	assert_float(worst).is_less(90.0)
	assert_float(_motor.speed()).is_less(carried * 0.45)


## Winding the wheel the other way is what holds a rally car straight, and it works here: the
## slide is pulled back in within about a quarter of a second, with the speed still on.
func test_counter_steering_catches_the_slide() -> void:
	_break_the_rear_loose()
	var carried := _motor.speed()
	_input.steer = -1.0
	_run(0.35)
	assert_float(_motor.slide_rate).is_equal(0.0)
	assert_float(absf(_hang())).is_less(20.0)
	# And it is worth doing: the kart comes out of the corner with the speed it went in with.
	assert_float(_motor.speed()).is_greater(carried * 0.9)


## Catching it is the end of it. Opposite lock held afterwards steers the kart; it does not throw
## the rear out the other way, which would make every catch a tank-slapper.
func test_catching_the_slide_does_not_throw_it_the_other_way() -> void:
	_break_the_rear_loose()
	_input.steer = -1.0
	_run(1.5)
	assert_float(_motor.slide_rate).is_equal(0.0)
	assert_float(absf(_hang())).is_less(25.0)


## Straightening the wheel lets the slide bleed off by itself, slower than catching it.
func test_a_straight_wheel_lets_the_slide_bleed_off() -> void:
	_break_the_rear_loose()
	var loose := _motor.slide_rate
	_input.steer = 0.0
	_motor.step(_input, DT)
	assert_float(_motor.slide_rate).is_less(loose)
	assert_float(_motor.slide_rate).is_greater(0.0)


## The style is a switch: the kart the game ships with still holds its drift on the wheel.
func test_the_other_style_is_untouched() -> void:
	var tighten: KartStats = load("res://data/kart/default.tres").duplicate()
	assert_int(tighten.drift_style).is_equal(KartStats.DriftStyle.TIGHTEN)
	var motor := KartMotor.new(tighten)
	var input := KartInput.new()
	input.throttle = 1.0
	for i: int in 180:
		motor.step(input, DT)
	input.steer = 1.0
	input.handbrake = true
	for i: int in 60:
		motor.step(input, DT)
	assert_float(motor.slide_rate).is_equal(0.0)
	assert_bool(motor.drifting).is_true()
	assert_float(absf(rad_to_deg(motor.slip_angle()))).is_greater(20.0)
