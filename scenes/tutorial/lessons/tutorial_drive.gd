class_name TutorialDrive
extends TutorialLesson
## Lesson 1, GAME.md 9.4a: drive forward, up the corridor out of the start, 15 cells of it.

const CELLS := 15.0

var _drive: TutorialTask


func _init() -> void:
	title = "Driving"
	gate_cell = Vector2i(17, 36)
	spawn_cell = Vector2i(18, 55)
	next_cell = Vector2i(18, 33)
	_drive = add_task("Drive forward", "Hold %s to drive", [InputActions.THROTTLE], true)
	_drive.simple_hint = "Push %s to drive"
	_drive.simple_way = true
	_drive.arrow = Vector2i(18, 36)
	_drive.ringed = false


func step(delta: float) -> void:
	var speed := kart().motor.forward_speed
	if speed > 0.0:
		_drive.advance(speed * delta, CELLS * cell_size())
