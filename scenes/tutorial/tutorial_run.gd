class_name TutorialRun
extends Node
## Runs the lessons of GAME.md 9.4a in order over the tutorial's match: one at a time, each in its
## room, its tasks on the checklist and the one being done over the kart as a hint, with the arrow
## on the floor pointing where it needs the kart to go. A lesson done opens the gate ahead; the kart
## through it shuts the gate behind and starts the next lesson. The HUD arrives a piece at a time
## with the lessons, see [HudReveal], and a kart that dies comes back in its own room.

signal lesson_started(index: int)
signal finished

## How far past a gate the kart is through it, in meters.
const THROUGH := 2.0
## What a task done sounds like, and a gate opening.
const TICK := &"ready"
const GATE := &"turbo_pass"

var match_node: Match
var lessons: Array[TutorialLesson] = []
## Which lesson is running, or -1 before the first.
var index := -1
var list: TutorialList
var hint: TutorialHint
var arrow: GuideArrow
var reveal: HudReveal
## The gate opened by the lesson just done, waiting for the kart to go through, or null.
var waiting_at: Gate

var _slot: PlayerSlot
var _task: TutorialTask
var _over := false


static func add_to(parent: Node, in_match: Match, layer: CanvasLayer) -> TutorialRun:
	var run := TutorialRun.new()
	run.name = "TutorialRun"
	run.match_node = in_match
	run._slot = in_match.slots[0]
	run.list = TutorialList.add_to(layer)
	run.hint = TutorialHint.new()
	run.hint.name = "Hint"
	run.hint.slot = run._slot
	run.add_child(run.hint)
	run.arrow = GuideArrow.add_to(in_match)
	run.arrow.kart = run._slot.kart
	if in_match.hud != null:
		run.reveal = HudReveal.add_to(in_match.hud, run._slot.index)
	run.lessons = [
		TutorialDrive.new(),
		TutorialSteer.new(),
		TutorialReverse.new(),
		TutorialNitro.new(),
		TutorialDrift.new(),
		TutorialShoot.new(),
	]
	parent.add_child(run)
	return run


func _ready() -> void:
	Events.kart_respawned.connect(_on_respawned)


func _exit_tree() -> void:
	if Events.kart_respawned.is_connected(_on_respawned):
		Events.kart_respawned.disconnect(_on_respawned)
	if index >= 0 and index < lessons.size():
		lessons[index].end()


func kart() -> Kart:
	return _slot.kart


func slot() -> PlayerSlot:
	return _slot


func grid() -> ArenaGrid:
	return match_node.arena.grid


## The middle of [param at], a cell of the map, in the world.
func cell(at: Vector2i) -> Vector3:
	return grid().cell_center(at)


func current_lesson() -> TutorialLesson:
	return lessons[index] if index >= 0 and index < lessons.size() else null


func is_over() -> bool:
	return _over


## The first lesson.
func begin() -> void:
	_start(0)


## The pause menu's Skip step: the lesson being done is done, and its gate opens.
func skip() -> void:
	var lesson := current_lesson()
	if lesson != null and waiting_at == null:
		lesson.skip()


func _start(i: int) -> void:
	if i >= lessons.size():
		_over = true
		hint.clear()
		arrow.point_at(Vector3.INF)
		finished.emit()
		return
	index = i
	var lesson := lessons[i]
	lesson.begin(self)
	list.start_lesson(lesson)
	if reveal != null:
		for piece: Array in lesson.reveals:
			reveal.show_piece(piece[0], piece[1])
	_task = null
	_refresh()
	lesson_started.emit(i)


func _physics_process(delta: float) -> void:
	if _over or index < 0:
		return
	if waiting_at != null:
		_step_through()
		return
	var lesson := lessons[index]
	lesson.step(delta)
	_refresh()
	if lesson.is_done():
		_complete(lesson)


## The checklist, the hint and the arrow brought up to the task being done.
func _refresh() -> void:
	var lesson := lessons[index]
	var now := lesson.current()
	if now != _task:
		if _task != null:
			Audio.play_sfx(TICK, -6.0, 0.0)
			if reveal != null:
				reveal.pointer_done()
		_task = now
		hint.show_task(now, lesson)
		arrow.point_at(cell(now.arrow) if now != null and now.arrow.x >= 0 else Vector3.INF)
	list.refresh(lesson)


func _complete(lesson: TutorialLesson) -> void:
	Audio.play_sfx(TICK, -6.0, 0.0)
	lesson.end()
	list.finish_lesson(lesson)
	hint.clear()
	var gate := match_node.arena.gate_at(lesson.gate_cell)
	if gate == null:
		_start(index + 1)
		return
	gate.open()
	_block(gate, false)
	Audio.play_sfx(GATE, -8.0)
	arrow.point_at(Vector3(gate.global_position.x, 0.0, gate.global_position.z))
	waiting_at = gate


## The kart through the open gate: the gate shuts behind it and the next lesson starts.
func _step_through() -> void:
	var lesson := lessons[index]
	var gate := waiting_at
	var at := kart().global_position
	var here := Vector3(gate.global_position.x, 0.0, gate.global_position.z)
	var onward := cell(lesson.next_cell) - here
	onward.y = 0.0
	if (at - here).dot(onward.normalized()) < THROUGH:
		return
	gate.close()
	_block(gate, true)
	waiting_at = null
	_start(index + 1)


## A kart that died comes back in the room it is learning in, facing the way the lesson goes.
func _on_respawned(slot_index: int, _at: Vector3) -> void:
	var lesson := current_lesson()
	if slot_index != _slot.index or lesson == null or lesson.spawn_cell.x < 0:
		return
	kart().respawn(cell(lesson.spawn_cell), lesson.facing, match_node.rules.spawn_protection)


## Where the bots may drive, with [param gate] shut or open.
func _block(gate: Gate, blocked: bool) -> void:
	for at: Vector2i in gate.cells:
		match_node.nav.set_cell_blocked(at, blocked)
