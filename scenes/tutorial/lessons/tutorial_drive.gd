class_name TutorialDrive
extends TutorialLesson
## Lesson 1, GAME.md 9.4a: drive forward, up the corridor out of the start, 15 cells of it, with
## the welcome and the game's mark at the top until the kart has driven a few meters.

const CELLS := 15.0
## The welcome, and how far the kart drives before it goes, in meters.
const WELCOME := "Welcome to"
const WELCOME_FOR := 4.0

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


func _begin() -> void:
	run.notice.say(&"welcome", WELCOME, true)


func step(delta: float) -> void:
	var speed := kart().motor.forward_speed
	if speed > 0.0:
		_drive.advance(speed * delta, CELLS * cell_size())
	if _drive.progress * CELLS * cell_size() >= WELCOME_FOR:
		run.notice.clear(&"welcome")
