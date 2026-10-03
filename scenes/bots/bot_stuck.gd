class_name BotStuck
extends RefCounted
## Getting a bot off a wall, GAME.md 9.1. Driving at something solid pins the kart there, and
## steering toward a target on the far side of it only holds it harder, so a bot that is going
## nowhere backs up with the wheel over, swings its nose clear and drives out on the heading it
## ends up with before the navigator gets the kart back. The turn is picked once and held for
## the whole maneuver, and it alternates, so a bot that backs into the same corner twice tries
## the other way out rather than rocking on the spot. Stepped by its [BotBrain] every tick, after
## the brain has said where it wants to go, which this overrides while it lasts.

## How long a bot puts up with going nowhere before backing out of it, and how long it backs
## out for. A nose flat against a wall needs no second of proof, so that case is quicker.
const STUCK_TIME := 1.2
const WALL_STUCK_TIME := 0.35
const REVERSE_TIME := 0.7
## After backing up, how long the wheel stays where it was with the power back on. Handing the
## kart straight back to the navigator points it at the target again, which is through the wall
## it just came off; this drives it out along the new heading first.
const SWING_TIME := 0.5
## Under this it counts as going nowhere.
const STUCK_SPEED := 0.6
## Standing still is not the only way to get nowhere: a kart scrubbing along a wall or grinding
## on a corner keeps a speed on the clock and still arrives nowhere. Covering less than this
## much ground in this long, while asking to drive, counts as stuck whatever the speedometer
## says.
const PROGRESS_TIME := 2.0
const PROGRESS_STEP := 2.0
## How far in front of itself a bot feels for a wall it is nosed up against.
const WALL_PROBE := 1.3

var brain: BotBrain

var _stuck_time := 0.0
var _reverse_left := 0.0
var _swing_left := 0.0
## Which way the wheel goes while backing out, held for the whole maneuver.
var _reverse_steer := 1.0
## Where the kart was when the ground it has covered was last looked at, and how long ago.
var _progress_mark := Vector3.INF
var _progress_left := PROGRESS_TIME


func _init(owner: BotBrain) -> void:
	brain = owner


func step(delta: float) -> void:
	if _reverse_left > 0.0:
		_reverse_left -= delta
		_back_out()
		if _reverse_left <= 0.0:
			_swing_left = SWING_TIME
		return
	if _swing_left > 0.0:
		_swing_left -= delta
		_swing_out()
		return
	if brain.input.throttle <= 0.0:
		_stuck_time = 0.0
		_forget_progress()
		return
	if brain.kart.motor.speed() < STUCK_SPEED:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
	var patience := WALL_STUCK_TIME if _nose_on_a_wall() else STUCK_TIME
	if _stuck_time >= patience or _getting_nowhere(delta):
		begin_backing_out()


## Starts the maneuver on the tick it is decided, not the one after: the frame it would wait
## is a frame it spends pushing at the wall.
func begin_backing_out() -> void:
	_stuck_time = 0.0
	_forget_progress()
	_reverse_left = REVERSE_TIME
	_reverse_steer = -_reverse_steer
	_back_out()


## Whether it is backing out or driving out again just now.
func maneuvering() -> bool:
	return _reverse_left > 0.0 or _swing_left > 0.0


## Nothing left over: no maneuver under way, and the clocks back at the start.
func reset() -> void:
	_stuck_time = 0.0
	_reverse_left = 0.0
	_swing_left = 0.0
	_progress_mark = Vector3.INF


## Whether the kart has covered any ground lately. A kart wedged on a corner can keep a speed
## on the clock while going nowhere at all, so what is measured is the ground covered rather
## than the speedometer.
func _getting_nowhere(delta: float) -> bool:
	if _progress_mark == Vector3.INF:
		_forget_progress()
		return false
	_progress_left -= delta
	if _progress_left > 0.0:
		return false
	var covered := brain.kart.global_position.distance_to(_progress_mark)
	_forget_progress()
	return covered < PROGRESS_STEP


## Starts the ground-covered window again from where the kart is now.
func _forget_progress() -> void:
	_progress_mark = brain.kart.global_position
	_progress_left = PROGRESS_TIME


## Backing out: off the gas, on the brakes, wheel held over.
func _back_out() -> void:
	var input := brain.input
	input.throttle = 0.0
	input.brake = 1.0
	input.steer = _reverse_steer
	input.handbrake = false
	input.nitro = false


## Driving out of it: back on the power with the wheel still over, so the kart leaves along the
## heading it backed into rather than turning straight into what it was stuck on.
func _swing_out() -> void:
	var input := brain.input
	input.throttle = brain.difficulty.top_speed_fraction
	input.brake = 0.0
	input.steer = _reverse_steer
	input.handbrake = false
	input.nitro = false


## Whether there is something solid right in front of the nose.
func _nose_on_a_wall() -> bool:
	var kart := brain.kart
	return not brain.has_line_of_sight(
		kart.global_position + kart.motor.forward_vector() * WALL_PROBE
	)
