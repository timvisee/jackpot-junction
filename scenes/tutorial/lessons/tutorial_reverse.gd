class_name TutorialReverse
extends TutorialLesson
## Lesson 3, GAME.md 9.4a: brake to a stop from speed, then reverse 4 cells. Simple driving has no
## reverse, since letting go is the brake, so its second task is to turn round and drive back.

## Fast enough to be braking from, slow enough to have stopped, in meters a second, and how far
## back to go, in cells.
const FROM := 4.0
const STOPPED := 0.4
const CELLS := 4.0
## Which way back is, in this room: it runs east.
const BACK := Vector3(-1.0, 0.0, 0.0)

var _stop: TutorialTask
var _back: TutorialTask
var _was_moving := false


func _init() -> void:
	title = "Brake and reverse"
	gate_cell = Vector2i(47, 25)
	spawn_cell = Vector2i(33, 26)
	facing = Vector3(1.0, 0.0, 0.0)
	next_cell = Vector2i(50, 26)
	_stop = add_task("Brake to a stop", "Hold %s to brake", [InputActions.BRAKE])
	_stop.simple_hint = "Let go of %s to stop"
	_stop.simple_way = true
	_back = add_task("Reverse 4 cells", "Hold %s to reverse", [InputActions.BRAKE], true)
	_back.simple_text = "Drive back 4 cells"
	_back.simple_hint = "Push %s back the way you came"
	_back.simple_way = true


func step(delta: float) -> void:
	var motor := kart().motor
	var speed := motor.forward_speed
	var task := current()
	if task == _stop:
		if speed > FROM:
			_was_moving = true
		elif _was_moving and absf(speed) < STOPPED:
			_stop.complete()
	elif task == _back:
		var total := CELLS * cell_size()
		if simple():
			if motor.forward_vector().dot(BACK) > 0.5 and speed > 1.0:
				_back.advance(speed * delta, total)
		elif speed < -0.3:
			_back.advance(-speed * delta, total)
