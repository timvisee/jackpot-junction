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


## Up to speed, then a flick of the handbrake with the wheel to the right: the rear lets go
## and the handbrake comes straight back off, which is how the technique goes. Holding it down
## keeps breaking the rear loose, which is its own test.
func _break_the_rear_loose() -> void:
	_input.throttle = 1.0
	_run(3.0)
	_input.steer = 1.0
	_input.handbrake = true
	_run(0.4)
	_input.handbrake = false


## Degrees of slip, positive when the kart is hanging out to the right of where it is going.
func _hang() -> float:
	return -rad_to_deg(_motor.slip_angle())


func test_the_handbrake_breaks_the_rear_loose() -> void:
	_break_the_rear_loose()
	assert_bool(_motor.drifting).is_true()
	assert_float(_motor.slide_rate).is_greater(0.0)
	assert_float(_hang()).is_greater(20.0)


## The whole point of the style: holding the wheel into the slide loses you the corner. The
## rear keeps coming round until the kart is travelling sideways and the nose has swung most
## of the way round with it, so the kart leaves pointing somewhere it never meant to go. That
## is the punishment: not the speed, which power-on it largely keeps, but the direction.
func test_holding_the_wheel_in_loses_you_the_corner() -> void:
	_break_the_rear_loose()
	var swung := _motor.heading
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
	# And the nose has gone round with it, well past any corner that was being taken.
	assert_float(rad_to_deg(absf(wrapf(_motor.heading - swung, -PI, PI)))).is_greater(100.0)


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


## The technique the style exists for: flick the handbrake, let go of it, and drive the slide on
## the wheel alone, catching it back whenever it hangs out too far. Nothing the wheel does may end
## the drift, or the first catch would end it and there would be no slide to drive.
func test_a_slide_can_be_held_on_the_wheel_alone() -> void:
	_input.throttle = 1.0
	_run(3.0)
	_input.steer = 1.0
	_input.handbrake = true
	_run(0.2)
	# The handbrake was a flick. From here the wheel is the only thing driving the slide.
	_input.handbrake = false
	var carried := _motor.speed()
	var held := 0
	var hangs: Array[float] = []
	for i: int in 240:
		_input.steer = -1.0 if _hang() > 40.0 else 1.0
		_motor.step(_input, DT)
		if _motor.drifting:
			held += 1
		if i > 60:
			hangs.append(_hang())
	assert_int(held).override_failure_message("the drift did not last").is_greater(230)
	# Held out around the angle it was being driven to, rather than creeping in or running away.
	assert_float(hangs.min()).is_greater(20.0)
	assert_float(hangs.max()).is_less(55.0)
	assert_float(_motor.speed()).is_greater(carried * 0.9)


## Keeping the handbrake down through a catch breaks the rear loose again, the other way. That
## is the player asking for it rather than the kart doing it to them: the flick is meant to be
## a flick, and holding it is how a kart is thrown from one side to the other on purpose.
func test_holding_the_handbrake_through_a_catch_throws_it_the_other_way() -> void:
	_break_the_rear_loose()
	_input.handbrake = true
	_input.steer = -1.0
	_run(1.0)
	assert_bool(_motor.drifting).is_true()
	assert_float(_motor.slide_rate).is_less(0.0)
	assert_float(_hang()).is_less(-20.0)


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
