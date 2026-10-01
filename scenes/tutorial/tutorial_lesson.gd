class_name TutorialLesson
extends RefCounted
## One lesson of the tutorial, GAME.md 9.4a: a room, a name, the tasks done in it in order and the
## gate out of it. Each lesson is a script of its own under lessons/, which adds its tasks as it is
## made and watches the kart every tick to tick them off; [TutorialRun] runs them in turn.

const SIGN_HEIGHT := 2.7

var title := ""
var tasks: Array[TutorialTask] = []
## The gate out of this room, by one of its cells, or none for the last room.
var gate_cell := Vector2i(-1, -1)
## Where a kart that died comes back in this room, which way it faces there, and the first cell of
## the next room, for knowing when the kart is through the gate.
var spawn_cell := Vector2i(-1, -1)
var facing := Vector3(0.0, 0.0, -1.0)
var next_cell := Vector2i(-1, -1)
## The pieces of the HUD this lesson brings in, each [piece, line, actions], see [HudReveal].
var reveals: Array[Array] = []
var run: TutorialRun

## The signs this lesson put up, taken down with it.
var _signs: Array[Node] = []


## Begins, in [param of]: the lesson's own [method _begin] once it has its run.
func begin(of: TutorialRun) -> void:
	run = of
	_begin()


func _begin() -> void:
	pass


## One physics tick of the lesson, for watching the kart.
func step(_delta: float) -> void:
	pass


## The lesson is done with: whatever it listened to or put down, let go of. A lesson with more to
## let go of calls this as well.
func end() -> void:
	for board: Node in _signs:
		if is_instance_valid(board):
			board.queue_free()
	_signs.clear()


## The task being done: the first not yet done, or null once they all are.
func current() -> TutorialTask:
	for task: TutorialTask in tasks:
		if not task.done:
			return task
	return null


func is_done() -> bool:
	return current() == null


## Every task done, for the pause menu's Skip step.
func skip() -> void:
	for task: TutorialTask in tasks:
		task.complete()


func add_task(
	text: String, hint: String, actions: Array[StringName] = [], bar := false
) -> TutorialTask:
	var task := TutorialTask.new()
	task.text = text
	task.hint = hint
	task.actions = actions
	task.bar = bar
	tasks.append(task)
	return task


## A sign over [param cell], in [param color], taken down with the lesson.
func put_sign(text: String, cell: Vector2i, color: Color = Palette.CHIP_WHITE) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.outline_size = 12
	label.modulate = color
	label.outline_modulate = Color(0.04, 0.04, 0.05, 0.9)
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	var at := run.cell(cell)
	label.position = Vector3(at.x, SIGN_HEIGHT, at.z)
	run.match_node.add_child(label)
	_signs.append(label)
	return label


func kart() -> Kart:
	return run.kart()


## Whether the player drives the simple way, GAME.md 4.2, which some tasks say differently.
func simple() -> bool:
	var player := kart().input as PlayerInput
	return player != null and player.simple()


## A cell of the map's grid, in meters.
func cell_size() -> float:
	return run.grid().cell_size


func arena() -> Arena:
	return run.match_node.arena


## The Jackpot zone nearest [param cell], for the lessons with one of their own.
func jackpot_near(cell: Vector2i) -> JackpotZone:
	var at := run.cell(cell)
	var best: JackpotZone = null
	var best_distance := INF
	for zone: JackpotZone in arena().jackpot_zones:
		var distance := zone.position.distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = zone
	return best


## The target standing on [param cell], or null.
func target_at(cell: Vector2i) -> Target:
	var at := run.cell(cell)
	for target: Target in arena().targets:
		if target.position.distance_to(at) < 0.5:
			return target
	return null
