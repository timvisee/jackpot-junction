class_name PinballFlippers
extends Node3D
## The Arcade's flippers at work, GAME.md 8.1c: the two bats below the near rail of the machine,
## see [PinballMachine], flicked up now and then as a player at the machine would, so the machine
## round the table looks played rather than switched off. One at a time mostly, now and then both
## at once or one twice over, snapping up, held a moment and dropping back. Nothing touches them:
## they are below the table, past the rail, and none of the machine collides.

## How far a bat swings up from where it rests, in radians, and how long the swing up, the hold
## at the top and the drop back take, in seconds.
const SWING := 0.88
const UP := 0.06
const HOLD := Vector2(0.08, 0.35)
const DOWN := 0.13
## How long the machine waits between two flicks, in seconds, the least and the most.
const WAIT := Vector2(1.6, 6.0)
## How often a flick is both bats at once, and how often one goes again straight after.
const BOTH := 0.25
const AGAIN := 0.3
const AGAIN_WAIT := 0.18

## The two bats, each turned about its pivot, and which way each swings up.
var bats: Array[Node3D] = []
var ways: Array[float] = []
var rng := RandomNumberGenerator.new()

var _wait := 0.0
## How far through its flick each bat is, in seconds, or below 0 for one at rest, and how long it
## holds at the top this time.
var _flicking: Array[float] = []
var _holds: Array[float] = []


## A bat pivoting at [param pivot] that swings up [param way], -1 or 1, for the machine to flick.
func add_bat(pivot: Vector3, way: float) -> Node3D:
	var bat := Node3D.new()
	bat.name = "Bat%d" % bats.size()
	bat.position = pivot
	add_child(bat)
	bats.append(bat)
	ways.append(way)
	_flicking.append(-1.0)
	_holds.append(0.0)
	return bat


func _ready() -> void:
	rng.seed = hash(get_path())
	_wait = rng.randf_range(WAIT.x, WAIT.y)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_wait = rng.randf_range(WAIT.x, WAIT.y)
		var which := rng.randi_range(0, bats.size() - 1)
		for i: int in bats.size():
			if i == which or rng.randf() < BOTH:
				flick(i)
		if rng.randf() < AGAIN:
			_wait = UP + HOLD.x + DOWN + AGAIN_WAIT
	for i: int in bats.size():
		if _flicking[i] < 0.0:
			continue
		_flicking[i] += delta
		bats[i].rotation.y = ways[i] * SWING * raised(_flicking[i], _holds[i])
		if _flicking[i] >= UP + _holds[i] + DOWN:
			_flicking[i] = -1.0
			bats[i].rotation.y = 0.0


## Flicks bat [param index] up, held for a while at the top and dropped back.
func flick(index: int) -> void:
	if index < 0 or index >= bats.size() or _flicking[index] >= 0.0:
		return
	_flicking[index] = 0.0
	_holds[index] = rng.randf_range(HOLD.x, HOLD.y)


## How far up a bat is [param seconds] into a flick held [param hold] seconds at the top: 0 at rest
## and 1 at the top, quick up and a little slower down.
static func raised(seconds: float, hold: float) -> float:
	if seconds < UP:
		return seconds / UP
	if seconds < UP + hold:
		return 1.0
	return clampf(1.0 - (seconds - UP - hold) / DOWN, 0.0, 1.0)
