class_name TutorialSteer
extends TutorialLesson
## Lesson 2, GAME.md 9.4a: steer, round the pillar, a circle and a half to the left and then to
## the right, counted from the kart's heading while it is moving forward, so sawing the wheel back
## and forth adds up to nothing. The room has the two pads that switch the way of driving, 4.2.

## How far round each way, in turns, and how fast the kart has to be going for a turn to count.
const TURNS := 1.5
const MOVING := 1.5
## The pads either side of the way in, and the sign between them, by cell.
const SIMPLE_PAD := Vector2i(13, 33)
const ADVANCED_PAD := Vector2i(24, 33)
const PADS_SIGN := Vector2i(18, 33)

var _left: TutorialTask
var _right: TutorialTask
var _heading := 0.0
var _pads: Array[Node] = []


func _init() -> void:
	title = "Steering"
	gate_cell = Vector2i(30, 25)
	spawn_cell = Vector2i(18, 33)
	next_cell = Vector2i(33, 26)
	var steer: Array[StringName] = [InputActions.STEER_LEFT, InputActions.STEER_RIGHT]
	_left = add_task("Turn left, a circle and a half", "%s to steer left", steer, true)
	_left.simple_hint = "Push %s the way to go, round to the left"
	_left.simple_way = true
	_right = add_task("Turn right, a circle and a half", "%s to steer right", steer, true)
	_right.simple_hint = "Push %s the way to go, round to the right"
	_right.simple_way = true


func _begin() -> void:
	_heading = kart().motor.heading
	var holder := run.match_node
	var simple := ModePad.add_to(holder, run.cell(SIMPLE_PAD), Settings.DRIVE_SIMPLE)
	var advanced := ModePad.add_to(holder, run.cell(ADVANCED_PAD), Settings.DRIVE_ADVANCED)
	var board := Label3D.new()
	board.text = "HOW TO DRIVE\ndrive onto a pad to switch\nthe pause menu changes it later too"
	board.font_size = 48
	board.outline_size = 12
	board.modulate = Palette.CHIP_WHITE
	board.outline_modulate = Color(0.04, 0.04, 0.05, 0.9)
	board.pixel_size = 0.009
	board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	board.no_depth_test = true
	var at := run.cell(PADS_SIGN)
	board.position = Vector3(at.x, 2.7, at.z)
	holder.add_child(board)
	_pads = [simple, advanced, board]


func step(_delta: float) -> void:
	var motor := kart().motor
	var now := motor.heading
	var turned := wrapf(now - _heading, -PI, PI)
	_heading = now
	if motor.forward_speed < MOVING:
		return
	var task := current()
	if task == _left and turned > 0.0:
		_left.advance(turned, TURNS * TAU)
	elif task == _right and turned < 0.0:
		_right.advance(-turned, TURNS * TAU)


func end() -> void:
	for pad: Node in _pads:
		if is_instance_valid(pad):
			pad.queue_free()
	_pads.clear()
	super()
