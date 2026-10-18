class_name TutorialLesson
extends RefCounted
## One lesson of the tutorial, GAME.md 9.4a: a name, the tasks done for it and the pieces it brings
## up into the lot, see [TestGround]. Each lesson is a script of its own under lessons/, which adds
## its tasks as it is made and watches the kart every tick to tick them off; [TutorialRun] runs them
## in turn. A lesson's tasks are done in order unless it says otherwise, when they are done in any
## order and the one being done is whichever is nearest the kart. An extra is never waited for.

const SIGN_HEIGHT := 2.7
## How much nearer another station has to be, in meters, before the hint moves to it from the one
## it is on, so a kart between two does not see it flicker.
const STICK := 2.5

var title := ""
var tasks: Array[TutorialTask] = []
## Whether the tasks come one after another, each shown as the one before is done, or all at once
## in any order.
var ordered := true
## For a lesson done in any order, its tasks in groups that belong together, each a station of the
## room done in its own order, nearest station first. Empty for one task at a time.
var stations: Array[Array] = []
## Where a kart that died comes back while this lesson is on, and which way it faces there.
var spawn_cell := TestGround.START
var facing := TestGround.NORTH
## The pieces of the HUD this lesson brings in, each [piece, line, actions] and for a pointer
## that frames a second piece too [piece, line, actions, also], see [HudReveal], and the task the
## pointer at them stays up until, or null for the first task done.
var reveals: Array[Array] = []
var pointer_until: TutorialTask
## The pieces of the HUD that are in the corner once this lesson is over, however it went: the
## item slot a lesson skipped never pointed at, say.
var ensures: Array[StringName] = []
## Whether the pause menu may pass this lesson: every lesson but the fight.
var skippable := true
## Whether every task is on the list from the start though they are done in order: the fight's
## goal with its hints under it.
var show_all := false
var run: TutorialRun
## What the lesson brings up into the lot, each [piece, the floor it stands on in meters, the way it
## comes, see [RisingPiece]], held back from the start of the test until the lesson brings it up.
var pieces: Array[Array] = []

## The signs this lesson put up, taken down with it.
var _signs: Array[Node] = []
## The station the hint is on, for a lesson done in any order.
var _held: Array = []


## What the lesson puts in the lot before anything starts, with [param of] the run: its pieces,
## held back, see [method keep_back].
func prepare(of: TutorialRun) -> void:
	run = of
	_prepare()


func _prepare() -> void:
	pass


## Begins, in [param of]: the lesson's own [method _begin] once it has its run.
func begin(of: TutorialRun) -> void:
	run = of
	_begin()


func _begin() -> void:
	pass


## One physics tick of the lesson, for watching the kart.
func step(_delta: float) -> void:
	pass


## The lesson is done with: whatever it listened to or put down for itself, let go of, and its
## words on the clipboard taken back. A lesson with more to let go of calls this as well.
func end() -> void:
	for board: Node in _signs:
		if is_instance_valid(board):
			board.queue_free()
	_signs.clear()
	if run != null and run.list != null:
		run.list.unsay()


## The task being done: the first not yet done, or for a lesson done in any order the first not
## yet done of the station nearest the kart, or null once they all are.
func current() -> TutorialTask:
	if ordered or run == null or run.kart() == null:
		return _first_undone(tasks)
	var groups := stations
	if groups.is_empty():
		groups = []
		for task: TutorialTask in tasks:
			groups.append([task])
	var nearest := _nearest(groups)
	if _held.is_empty() or _first_undone(_held) == null:
		_held = nearest
	elif not nearest.is_empty() and nearest != _held:
		if _distance(nearest) + STICK < _distance(_held):
			_held = nearest
	return _first_undone(_held) if not _held.is_empty() else null


## The tasks the checklist shows: up to the one being done, the extras after them, or all of them
## in any order or when the lesson wants them all up.
func shown() -> Array[TutorialTask]:
	if not ordered or show_all:
		return tasks
	var up_to: Array[TutorialTask] = []
	for task: TutorialTask in tasks:
		if task.extra:
			continue
		up_to.append(task)
		if not task.done:
			break
	for task: TutorialTask in tasks:
		if task.extra:
			up_to.append(task)
	return up_to


## Whether every task the lesson waits for is done: its extras need not be.
func is_done() -> bool:
	for task: TutorialTask in tasks:
		if not task.done and not task.extra:
			return false
	return true


## Every task done and every piece up at once, for the pause menu's Skip lesson.
func skip() -> void:
	for task: TutorialTask in tasks:
		task.complete()
	bring_all_at_once()


## [param node] one of this lesson's pieces, standing on [param across] of floor, coming the
## [param how] way: held back until the lesson brings it up.
func keep_back(node: Node3D, across: Vector2, how := RisingPiece.Way.RISE) -> Node3D:
	RisingPiece.hold(node)
	pieces.append([node, across, how])
	return node


## Those of this lesson's pieces that are among [param nodes] brought up, one after another
## [param apart] seconds, from [param after] on; [param done] called once the last is up.
func bring_up(nodes: Array, apart := 0.12, after := 0.0, done := Callable()) -> void:
	var skin := arena().surfaces.floor_top() if arena().surfaces != null else null
	# By instance: a typed array of one kind of piece cannot be asked about another kind.
	var wanted: Dictionary[int, bool] = {}
	for node: Node3D in nodes:
		wanted[node.get_instance_id()] = true
	var count := 0
	for entry: Array in pieces:
		if wanted.has((entry[0] as Node3D).get_instance_id()):
			count += 1
	var i := 0
	for entry: Array in pieces:
		if not wanted.has((entry[0] as Node3D).get_instance_id()):
			continue
		i += 1
		var then := done if i == count else Callable()
		RisingPiece.bring(entry[0], entry[1], entry[2], after + apart * (i - 1), skin, then)


## Every piece of the lesson's up at once, for a lesson skipped and the exam gone to straight.
func bring_all_at_once() -> void:
	for entry: Array in pieces:
		RisingPiece.at_once(entry[0])
	_settle()


## What a lesson leaves behind it, done whichever way: its pieces in play as they would be.
func _settle() -> void:
	pass


## The pieces of this lesson's, for asking.
func piece_nodes() -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	for entry: Array in pieces:
		nodes.append(entry[0])
	return nodes


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


## Whether the player drives the simple way, GAME.md 4.2, which some tasks say differently: the
## stick's way of working the pedals too. With Auto throttle off they are the player's own, the gas
## to hold and the brake to press as in the wheel and pedals' words, which say it as it is.
func simple() -> bool:
	var player := kart().input as PlayerInput
	return player != null and player.simple() and not player.works_the_pedals()


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


static func _first_undone(group: Array) -> TutorialTask:
	for task: TutorialTask in group:
		if not task.done and not task.extra:
			return task
	return null


## Of [param groups] with something left to do, the one whose spot is nearest the kart; a station
## with no spot comes last.
func _nearest(groups: Array) -> Array:
	var best: Array = []
	var best_distance := INF
	for group: Array in groups:
		if _first_undone(group) == null:
			continue
		var distance := _distance(group)
		if distance < best_distance:
			best_distance = distance
			best = group
	return best


## How far the kart is from the station [param group] is, by the nearest spot any of its tasks
## names, done or not, so a station is not lost between its tasks when one of them, arming an
## item say, is done anywhere; very far for a station that names no spot at all.
func _distance(group: Array) -> float:
	var best := 1.0e9
	for task: TutorialTask in group:
		if task.arrow.x >= 0:
			best = minf(best, kart().global_position.distance_to(run.cell(task.arrow)))
	return best
