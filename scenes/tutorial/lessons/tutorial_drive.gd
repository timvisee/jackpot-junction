class_name TutorialDrive
extends TutorialLesson
## Lesson 1, GAME.md 9.4a: driving. A lane of cones rises ahead of the start and a ring of them at
## its head: drive up the lane, ten meters of it, then go round the ring, the kart's heading a full
## circle either way, counted from where the task starts, moving or standing, so sawing the wheel
## back and forth adds up to nothing. The pad that opens the way of driving to change, 4.2, lies
## beside the start, the clipboard saying what it is while the kart is near it; driving onto it puts
## up the question to choose from, see [method _switch_mode], rather than switching on the spot. It
## goes back into the floor once the lesson is done: the pause menu changes it after. No welcome:
## the driving school has greeted the player already. There is no lesson in reversing: letting go is
## the brake.

## How far forward, in meters, and how near a pad the kart has to be for the clipboard to say what
## the pads are.
const FORWARD := 10.0
const NEAR_PADS := 6.0
const MODES_WORDS := "Drive onto the pad to choose how you drive.\nChange it any time in the menu."
## How far toward the outside of the lane its cones stand, in meters, so the middle is clear.
const LANE_OUT := 0.3

var _drive: TutorialTask
var _round: TutorialTask
## How far the heading has turned since the ring's task started, either way, and where it was.
var _turned := 0.0
var _heading := 0.0
var _pads: Array[ModePad] = []


func _init() -> void:
	title = "Driving"
	spawn_cell = TestGround.START
	facing = TestGround.NORTH
	_drive = add_task("Drive forward", "", [InputActions.THROTTLE], true)
	_drive.simple_way = true
	_drive.arrow = TestGround.LANE[TestGround.LANE.size() - 1] + Vector2i(1, 0)
	_drive.ringed = false
	_round = add_task(
		"Go round the cones", "", [InputActions.STEER_LEFT, InputActions.STEER_RIGHT], true
	)
	_round.simple_way = true
	_round.arrow = TestGround.ROUNDABOUT
	_round.arrow_rect = Rect2i(TestGround.ROUNDABOUT - Vector2i(1, 1), Vector2i(3, 3))


## The pad, there from the start, and the lane's cones and the ring's, held back.
func _prepare() -> void:
	var pad := ModePad.add_to(run.match_node, run.cell(TestGround.MODE_PAD))
	pad.stepped.connect(_switch_mode)
	_pads.append(pad)
	var lane_x := TestGround.LANE[0].x
	for i: int in TestGround.LANE.size():
		var cell := TestGround.LANE[i]
		var out := -LANE_OUT if cell.x == lane_x else LANE_OUT
		var cone := SchoolCone.stand(arena(), run.cell(cell) + Vector3(out, 0.0, 0.0), "Lane%d" % i)
		keep_back(cone, SchoolCone.ACROSS)
	_ring(TestGround.ROUNDABOUT, "Roundabout")


## A ring of cones round [param middle], held back, named after [param called].
func _ring(middle: Vector2i, called: String) -> void:
	var at := run.cell(middle)
	var points := TestGround.ring(TestGround.RING_CONES, TestGround.RING_RADIUS)
	for i: int in points.size():
		var spot := at + Vector3(points[i].x, 0.0, points[i].y)
		keep_back(SchoolCone.stand(arena(), spot, "%s%d" % [called, i]), SchoolCone.ACROSS)


func _begin() -> void:
	bring_up(piece_nodes(), 0.08)
	_heading = kart().motor.heading


func end() -> void:
	# The pads go back into the floor: the exam is played over where they lay.
	for pad: ModePad in _pads:
		RisingPiece.lower(pad, Vector2.ONE * ModePad.RADIUS * 2.0)
	super()


func step(delta: float) -> void:
	var here := kart().global_position
	var near_pads := false
	for pad: ModePad in _pads:
		near_pads = near_pads or (pad.visible and here.distance_to(pad.global_position) < NEAR_PADS)
	if near_pads and not run.list.is_saying(&"modes"):
		run.list.say(&"modes", MODES_WORDS)
	elif not near_pads:
		run.list.unsay(&"modes")
	var now := kart().motor.heading
	var turned := wrapf(now - _heading, -PI, PI)
	_heading = now
	var task := current()
	if task == _drive:
		var speed := kart().motor.forward_speed
		if speed > 0.0:
			_drive.advance(speed * delta, FORWARD)
	elif task == _round:
		# Either way counts, and back the other way takes it off again.
		_turned += turned
		_round.progress = clampf(absf(_turned) / TAU, 0.0, 1.0)
		if absf(_turned) >= TAU:
			_round.complete()


## Driven onto the pad, the question the title asks is put up to choose the way of driving, see
## [DriveChoice], the kart held while it is up so the room does not go on under it; the chosen way
## is called out over the kart as the pad's own text did, 4.2. Backing out leaves it as it was.
func _switch_mode() -> void:
	var driver := kart()
	driver.frozen = true
	var holder := Control.new()
	holder.name = "ModeQuestion"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run.layer.add_child(holder)
	var done := func() -> void:
		driver.frozen = false
		holder.queue_free()
	var chose := func() -> void:
		done.call()
		FloatingText.spawn(
			run.match_node,
			driver.global_position,
			"%s DRIVING" % DrivePicker.WORDS[Game.settings.drive_mode(0)].to_upper(),
			ModePad.LIT,
			44,
			1.4
		)
	var choice := DriveChoice.ask(holder, chose, 0)
	choice.backed_out = done


## The pad beside the start, for asking.
func pads() -> Array[ModePad]:
	return _pads
