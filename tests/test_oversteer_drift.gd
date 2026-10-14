extends GdUnitTestSuite
## The oversteer drift from GAME.md 4.1, which is what the kart drifts with, at a 60 Hz tick. A
## flick of the handbrake breaks the rear loose; after that the wheel asks the kart to sit at an
## angle rather than asking for more slide, which is how a rally car is driven.

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


## The whole point of the style, and the second attempt at it: the wheel asks the kart to sit at
## an angle rather than asking for more slide. Full lock into the slide holds a big one, half lock
## holds half of it, and every one of them is steady. A slide that runs away from a held wheel can
## only be fought.
func test_the_wheel_asks_for_an_angle_and_the_kart_holds_it() -> void:
	var angles: Array[float] = []
	for lock: float in [1.0, 0.6, 0.3]:
		angles.append(_hang_held_at(lock))
	assert_float(angles[0]).is_between(30.0, 50.0)
	# Proportional to the wheel, near enough, and in the right order.
	assert_float(angles[1]).is_between(angles[0] * 0.45, angles[0] * 0.75)
	assert_float(angles[2]).is_between(angles[0] * 0.2, angles[0] * 0.45)


## Held, not merely reached: three seconds at one wheel position ends where it settled a second in.
func test_a_held_angle_is_steady() -> void:
	_break_the_rear_loose()
	_input.steer = 1.0
	_run(1.0)
	var settled := _hang()
	var lowest := settled
	var highest := settled
	for i: int in 120:
		_motor.step(_input, DT)
		lowest = minf(lowest, _hang())
		highest = maxf(highest, _hang())
	assert_float(highest - lowest).override_failure_message("the slide wandered").is_less(6.0)
	assert_bool(_motor.drifting).is_true()
	assert_float(_motor.speed()).is_greater(_stats.top_speed * 0.9)


## Where the kart settles with the wheel held at one position for two seconds after the flick.
func _hang_held_at(lock: float) -> float:
	var motor := KartMotor.new(_stats)
	var input := KartInput.new()
	input.throttle = 1.0
	for i: int in int(3.0 / DT):
		motor.step(input, DT)
	input.steer = 1.0
	input.handbrake = true
	for i: int in 24:
		motor.step(input, DT)
	input.handbrake = false
	input.steer = lock
	for i: int in int(2.0 / DT):
		motor.step(input, DT)
	return -rad_to_deg(motor.slip_angle())


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
## the wheel alone. Nothing the wheel does may end the drift, or the first correction would end it
## and there would be no slide left to drive.
func test_a_slide_is_driven_on_the_wheel_after_the_flick() -> void:
	_break_the_rear_loose()
	var carried := _motor.speed()
	var held := 0
	for i: int in 240:
		# Eased off when it hangs out too far, fed back in when it tucks up: driving, not fighting.
		_input.steer = 0.2 if _hang() > 38.0 else 1.0
		_motor.step(_input, DT)
		if _motor.drifting:
			held += 1
	assert_int(held).override_failure_message("the drift did not last").is_greater(230)
	assert_float(_hang()).is_between(20.0, 50.0)
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
