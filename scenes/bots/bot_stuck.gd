class_name BotStuck
extends RefCounted
## Getting a bot off a wall, GAME.md 9.1. Driving at something solid pins the kart there, and
## steering toward a target on the far side of it only holds it harder, so a bot that is going
## nowhere backs up with the wheel over, swings its nose clear and drives out on the heading it
## ends up with before the navigator gets the kart back. The turn is picked once and held for
## the whole maneuver, and it alternates, so a bot that backs into the same corner twice tries
## the other way out rather than rocking on the spot. Stepped by its [BotBrain] every tick, after
## the brain has said where it wants to go, which this overrides while it lasts.
##
## Backing out does not get a bot out of everything, so a longer watch runs under it in a match:
## a bot that has not got out of a small circle in [constant LONG_TIME] seconds, while not waiting
## somewhere on purpose, gives up on what it was doing and goes somewhere else, see
## [method BotBrain.go_elsewhere]; still there [constant PUT_DOWN_AFTER] seconds later, it is put
## down on a free spawn point, as a respawn puts it but without dying, see [method put_down].

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
## The longer watch: how long a bot may stay inside a circle this wide across before it gives up
## on what it was doing, and how long after that it is put down somewhere else.
const LONG_TIME := 10.0
const LONG_STEP := 2.0
const PUT_DOWN_AFTER := 5.0

var brain: BotBrain

var _stuck_time := 0.0
var _reverse_left := 0.0
var _swing_left := 0.0
## Which way the wheel goes while backing out, held for the whole maneuver.
var _reverse_steer := 1.0
## Where the kart was when the ground it has covered was last looked at, and how long ago.
var _progress_mark := Vector3.INF
var _progress_left := PROGRESS_TIME
## Where the longer watch has the kart staying, and how long it has left to get out of there.
var _long_mark := Vector3.INF
var _long_left := LONG_TIME
## How long until a bot that gave up and has still got nowhere is put down; below zero when it
## has not given up.
var _put_down_left := -1.0


func _init(owner: BotBrain) -> void:
	brain = owner


func step(delta: float) -> void:
	_watch(delta)
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
	_long_mark = Vector3.INF
	_put_down_left = -1.0


## Whether it has given up on what it was doing and is waiting to see if that got it anywhere.
func gave_up() -> bool:
	return _put_down_left >= 0.0


## Puts the kart down on the spawn point farthest from everybody else, GAME.md 9.1, facing the
## Junction, as a respawn puts it but without dying: it keeps its lives, its pot and its jokers.
func put_down() -> void:
	var kart := brain.kart
	var match_node := brain.match_node
	if not kart.alive or kart.falling or match_node.arena.spawn_points.is_empty():
		return
	var others: Array[Vector3] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and slot.kart != kart and slot.kart.alive:
			others.append(slot.kart.global_position)
	var point := Match.pick_spawn(match_node.arena.spawn_points, others)
	kart.global_position = Vector3(point.x, 0.0, point.z)
	kart.face(match_node.arena.junction_position - point)
	kart.motor.velocity = Vector3.ZERO
	kart.motor.forward_speed = 0.0
	kart.motor.drifting = false
	kart.velocity = Vector3.ZERO
	kart.reset_physics_interpolation()
	reset()


## The longer watch, see the class. Only in a match: a room has nothing to be late for, and the
## driving school holds bots still in their pens on purpose. A bot waiting on the Junction or the
## Jackpot is where it wants to be.
func _watch(delta: float) -> void:
	var kart := brain.kart
	if (
		not brain.match_node.rules.timed
		or brain.holding_position()
		or _long_mark == Vector3.INF
		or kart.global_position.distance_to(_long_mark) >= LONG_STEP
	):
		_forget_long()
		return
	if gave_up():
		_put_down_left -= delta
		if _put_down_left < 0.0:
			put_down()
			_forget_long()
		return
	_long_left -= delta
	if _long_left <= 0.0:
		_put_down_left = PUT_DOWN_AFTER
		brain.go_elsewhere()


func _forget_long() -> void:
	_long_mark = brain.kart.global_position
	_long_left = LONG_TIME
	_put_down_left = -1.0


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
