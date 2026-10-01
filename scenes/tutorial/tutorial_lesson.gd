class_name TutorialLesson
extends RefCounted
## One lesson of the tutorial, GAME.md 9.4a: a room, a name, the tasks done in it in order and the
## gate out of it. Each lesson is a script of its own under lessons/, which adds its tasks as it is
## made and watches the kart every tick to tick them off; [TutorialRun] runs them in turn.

var title := ""
var tasks: Array[TutorialTask] = []
## The gate out of this room, by one of its cells, or none for the last room.
var gate_cell := Vector2i(-1, -1)
## Where a kart that died comes back in this room, which way it faces there, and the first cell of
## the next room, for knowing when the kart is through the gate.
var spawn_cell := Vector2i(-1, -1)
var facing := Vector3(0.0, 0.0, -1.0)
var next_cell := Vector2i(-1, -1)
## The pieces of the HUD this lesson brings in, each [piece, line], see [HudReveal].
var reveals: Array[Array] = []
var run: TutorialRun


## Begins, in [param of]: the lesson's own [method _begin] once it has its run.
func begin(of: TutorialRun) -> void:
	run = of
	_begin()


func _begin() -> void:
	pass


## One physics tick of the lesson, for watching the kart.
func step(_delta: float) -> void:
	pass


## The lesson is done with: whatever it listened to or put down, let go of.
func end() -> void:
	pass


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
