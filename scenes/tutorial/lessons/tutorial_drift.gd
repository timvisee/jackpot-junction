class_name TutorialDrift
extends TutorialLesson
## Lesson 5, GAME.md 9.4a: tap the handbrake while turning, once, then hold a drift long enough
## for a turbo, three times, each drift's bar filling toward the turbo point of 4.1. The hint over
## the kart is the three steps of a drift with a tick box each, ticked as the drift under way gets
## there: the handbrake tapped while turning, the drift held until the turbo is earned, and the
## kart straightened up to launch it; a turbo launched holds all three ticked for a moment, and
## then it starts over for the next. The room has three stacks of tires and barrels out of the
## Garage to drift round, each with a body in it a kart bumps and a shot hits.

const TURBOS := 3
## Where the props stand, by the cells each covers, what each is, how far round a body of tires
## reaches, in meters, and how big the body round the barrels is, along their row and across it,
## see [method RoomProps.garage_prop].
const PROPS: Array[Rect2i] = [Rect2i(67, 6, 2, 2), Rect2i(75, 15, 2, 2), Rect2i(83, 8, 2, 2)]
const PROP_KINDS: Array[StringName] = [&"tires", &"barrels", &"tires"]
const TIRES_RADIUS := 1.5
const BARRELS_BODY := Vector3(4.2, 3.0, 2.2)
## The steps, and what each is done with.
const STEPS: Array[String] = [
	"Tap %s while turning", "Hold the drift to build turbo", "Straighten up to launch"
]
const STEP_ACTIONS: Array[Array] = [[InputActions.HANDBRAKE], [], []]
## How long all three stay ticked after a turbo, in seconds.
const LAUNCHED_FOR := 0.9
## The word at the top for the lesson.
const WORDS := "Drift in tight corners.\nHold a drift to build turbo."

var _tap: TutorialTask
var _turbo: TutorialTask
var _launched := 0.0


func _init() -> void:
	title = "Drifting"
	gate_cell = Vector2i(61, 10)
	spawn_cell = Vector2i(81, 20)
	next_cell = Vector2i(59, 11)
	_tap = add_task(
		"Tap the handbrake while turning", "Tap %s while turning", [InputActions.HANDBRAKE]
	)
	_turbo = add_task("Hold a drift until it turbos", "Hold the drift for a turbo", [], true)
	_turbo.of = TURBOS
	for task: TutorialTask in [_tap, _turbo]:
		task.steps = STEPS
		task.step_actions = STEP_ACTIONS


## The props, there from the start: the Garage's own tires and barrels, each with a body in it.
func _prepare() -> void:
	var props := arena().get_node_or_null("Props") as RoomProps
	var grid := run.grid()
	for i: int in PROPS.size():
		var rect := PROPS[i]
		var at := grid.rect_center(rect)
		var turn := PI * 0.25 * i
		if props != null:
			props.garage_prop(PROP_KINDS[i], at, turn)
		var body := StaticBody3D.new()
		body.name = "DriftProp%d" % i
		body.collision_layer = Layers.WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		if PROP_KINDS[i] == &"tires":
			var drum := CylinderShape3D.new()
			drum.radius = TIRES_RADIUS
			drum.height = 3.0
			shape.shape = drum
		else:
			var box := BoxShape3D.new()
			box.size = BARRELS_BODY
			shape.shape = box
		shape.position = Vector3(0.0, 1.5, 0.0)
		body.add_child(shape)
		run.match_node.add_child(body)
		body.global_position = at
		body.rotation.y = turn
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				run.match_node.nav.set_cell_blocked(Vector2i(x, y), true)


func _begin() -> void:
	Events.drift_boosted.connect(_on_boost)
	run.list.say(&"drift", WORDS)


func end() -> void:
	if Events.drift_boosted.is_connected(_on_boost):
		Events.drift_boosted.disconnect(_on_boost)
	super()


func _on_boost(slot_index: int) -> void:
	if slot_index != kart().slot:
		return
	_launched = LAUNCHED_FOR
	if current() == _turbo:
		_turbo.tally()


func step(delta: float) -> void:
	var motor := kart().motor
	var task := current()
	if task == _tap and motor.drifting:
		_tap.complete()
	elif task == _turbo:
		var charge := motor.drift_time / maxf(kart().stats.drift_min_duration, 0.001)
		_turbo.progress = clampf(charge, 0.0, 1.0) if motor.drifting else 0.0
	# Where the drift under way has got to: a turbo just launched is all three for a moment.
	_launched = maxf(_launched - delta, 0.0)
	var stage := 0
	if _launched > 0.0:
		stage = 3
	elif motor.drifting:
		stage = 2 if motor.boost_earned() else 1
	_tap.steps_done = stage
	_turbo.steps_done = stage
