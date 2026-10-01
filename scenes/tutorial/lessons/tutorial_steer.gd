class_name TutorialSteer
extends TutorialLesson
## Lesson 2, GAME.md 9.4a: steer, round the pillar, a circle and a half to the left and then to
## the right, counted from the kart's heading, moving or standing, so sawing the wheel back and
## forth adds up to nothing and turning on the spot counts. The room has the two pads that switch
## the way of driving, 4.2, which are there from the start and stay.

## How far round each way, in turns.
const TURNS := 1.5
## How near a pad the kart has to be for the word at the top about the two ways to drive, in
## meters, and the word.
const NEAR_PADS := 7.0
const MODES_WORDS := (
	"Two ways to drive: SIMPLE steers where you push, ADVANCED like a car.\n"
	+ "Drive onto a pad to switch. The pause menu changes it any time."
)
## The pads either side of the way in, by cell.
const SIMPLE_PAD := Vector2i(13, 33)
const ADVANCED_PAD := Vector2i(24, 33)

var _left: TutorialTask
var _right: TutorialTask
var _heading := 0.0


func _init() -> void:
	title = "Steering"
	gate_cell = Vector2i(30, 25)
	spawn_cell = Vector2i(18, 33)
	next_cell = Vector2i(33, 26)
	_left = add_task(
		"Turn left, a circle and a half", "%s to steer left", [InputActions.STEER_LEFT], true
	)
	_left.simple_hint = "Push %s the way to go, round to the left"
	_left.simple_way = true
	_right = add_task(
		"Turn right, a circle and a half", "%s to steer right", [InputActions.STEER_RIGHT], true
	)
	_right.simple_hint = "Push %s the way to go, round to the right"
	_right.simple_way = true


func _prepare() -> void:
	var holder := run.match_node
	ModePad.add_to(holder, run.cell(SIMPLE_PAD), Settings.DRIVE_SIMPLE)
	ModePad.add_to(holder, run.cell(ADVANCED_PAD), Settings.DRIVE_ADVANCED)


func _begin() -> void:
	_heading = kart().motor.heading


func step(_delta: float) -> void:
	var here := kart().global_position
	var near_pads := (
		here.distance_to(run.cell(SIMPLE_PAD)) < NEAR_PADS
		or here.distance_to(run.cell(ADVANCED_PAD)) < NEAR_PADS
	)
	if near_pads and not run.notice.is_saying(&"modes"):
		run.notice.say(&"modes", MODES_WORDS)
	elif not near_pads:
		run.notice.clear(&"modes")
	var motor := kart().motor
	var now := motor.heading
	var turned := wrapf(now - _heading, -PI, PI)
	_heading = now
	var task := current()
	if task == _left and turned > 0.0:
		_left.advance(turned, TURNS * TAU)
	elif task == _right and turned < 0.0:
		_right.advance(-turned, TURNS * TAU)
