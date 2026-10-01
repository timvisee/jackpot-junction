class_name TutorialRun
extends Node
## Runs the lessons of GAME.md 9.4a in order over the tutorial's match: one at a time, each in its
## room, its tasks on the checklist and the one being done over the kart as a hint, with the arrow
## on the floor pointing where it needs the kart to go. A lesson done opens the gate ahead; the kart
## through it shuts the gate behind and starts the next lesson, and a lesson with no gate of its
## own hands straight on to the next in the same room. The HUD arrives a piece at a time with the
## lessons, see [HudReveal]. Everybody else in the match is parked until their lesson: the dummies
## in the jokers room, and the bots in the pens of the fight, held still until let out; a kart that
## dies comes back where it belongs, the player in the room they are learning in.

signal lesson_started(index: int)
signal finished

## How far past a gate the kart is through it, in meters, and how near the line of a gate a kart
## may be for the gate to shut: never on anybody.
const THROUGH := 3.0
const CLEAR := 1.8
## How far outside a piece of the floor its ring runs, in meters.
const RING_OUT := 0.4
## What a task done sounds like, and a gate opening.
const TICK := &"ready"
const GATE := &"turbo_pass"
## What the notice says for a joker pick with the hand already full, GAME.md 3.7.
const HAND_FULL := "Your hand is full.\nReplace a card or skip it."

var match_node: Match
var layer: CanvasLayer
var lessons: Array[TutorialLesson] = []
## Which lesson is running, or -1 before the first.
var index := -1
var list: TutorialList
var hint: TutorialHint
var arrow: GuideArrow
var reveal: HudReveal
## The word at the top of the screen, and the fight's bar while that is up, which the word and
## the Royal Flush tally keep clear of.
var notice: TutorialNotice
var boss_bar: TutorialBossBar
## The gate opened by the lesson just done, waiting for the kart to go through, or null.
var waiting_at: Gate
## The parked karts of the jokers lesson and the bots of the fight, and which bots are still in
## their pens, held still every tick.
var dummies: Array[PlayerSlot] = []
var bots: Array[PlayerSlot] = []
var penned: Array[PlayerSlot] = []
## The bots gone for good at the end of the fight, never to come back.
var gone: Array[PlayerSlot] = []

var _slot: PlayerSlot
var _task: TutorialTask
## How many of the lesson's tasks were done at the last look, for hearing one more.
var _done := 0
var _over := false
var _bot_spawns := 0
## Gates told to shut while somebody was still in them, shut as soon as nobody is.
var _closing: Array[Gate] = []


static func add_to(parent: Node, in_match: Match, on_layer: CanvasLayer) -> TutorialRun:
	var run := TutorialRun.new()
	run.name = "TutorialRun"
	run.match_node = in_match
	run.layer = on_layer
	run._slot = in_match.slots[0]
	for slot: PlayerSlot in in_match.slots:
		if slot.is_dummy():
			run.dummies.append(slot)
		elif slot.input is BotInput:
			run.bots.append(slot)
	run.penned = run.bots.duplicate()
	run.list = TutorialList.add_to(on_layer)
	run.notice = TutorialNotice.add_to(on_layer)
	run.notice.changed.connect(run.place_tally)
	run.hint = TutorialHint.new()
	run.hint.name = "Hint"
	run.hint.slot = run._slot
	run.add_child(run.hint)
	run.arrow = GuideArrow.add_to(in_match)
	run.arrow.kart = run._slot.kart
	if in_match.hud != null:
		run.reveal = HudReveal.add_to(in_match.hud, run._slot)
	run.lessons = [
		TutorialDrive.new(),
		TutorialSteer.new(),
		TutorialReverse.new(),
		TutorialNitro.new(),
		TutorialDrift.new(),
		TutorialShoot.new(),
		TutorialItems.new(),
		TutorialJokers.new(),
		TutorialPads.new(),
		TutorialBank.new(),
		TutorialFight.new(),
	]
	parent.add_child(run)
	return run


func _ready() -> void:
	Events.kart_respawned.connect(_on_respawned)
	# Everybody where they belong: the match seated them on the map's spawns in reading order.
	kart().respawn(cell(lessons[0].spawn_cell), lessons[0].facing, 0.0)
	# No banking by joker until the Junction is in the room, GAME.md 9.4a.
	kart().banks_passively = false
	for i: int in dummies.size():
		_park_dummy(i)
	for i: int in bots.size():
		_park_bot(i)
	# What each room has in it from the start, and keeps.
	for lesson: TutorialLesson in lessons:
		lesson.prepare(self)


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


## The pause menu's Skip lesson: the lesson being done is done, and its gate opens. The fight is
## not skipped: it is the test, and the menu's entry is gone by then.
func skip() -> void:
	var lesson := current_lesson()
	if lesson == null or waiting_at != null or not lesson.skippable:
		return
	lesson.skip()


## The word at the top under the fight's bar while that is up and under a pointer's card while
## one is, and the Royal Flush tally under all of them, back where the HUD hangs it once they are
## gone.
func place_tally() -> void:
	var top := TutorialNotice.TOP
	var bar_ok := boss_bar != null and is_instance_valid(boss_bar)
	var under := boss_bar.below() if bar_ok else top
	if reveal != null and notice.visible:
		under = maxf(under, reveal.card_bottom() + 10.0)
	if not is_equal_approx(notice.offset_top, under):
		notice.set_top(under)
	var hud := match_node.hud
	var tally := hud.find_child("FlushTally", true, false) as FlushTally if hud != null else null
	if tally == null:
		return
	var drop := MatchHud.TALLY_DROP
	if bar_ok:
		drop = maxf(drop, boss_bar.below())
	if notice.visible:
		drop = maxf(drop, notice.below())
	tally.offset_top = drop


## The gate on [param at] opened, and the bots' map told, see [Gate].
func open_gate(at: Vector2i) -> void:
	var gate := match_node.arena.gate_at(at)
	if gate != null:
		gate.open()
		_block(gate, false)


## The gate on [param at] shut, once nobody is in it.
func close_gate(at: Vector2i) -> void:
	var gate := match_node.arena.gate_at(at)
	if gate != null and gate not in _closing:
		_closing.append(gate)


## Bot [param which] let out of its pen, GAME.md 9.4a.
func release_bot(which: int) -> void:
	if which < 0 or which >= bots.size():
		return
	penned.erase(bots[which])
	bots[which].kart.frozen = false


func _start(i: int) -> void:
	if i >= lessons.size():
		_over = true
		hint.clear()
		arrow.point_at(Vector3.INF)
		finished.emit()
		return
	index = i
	waiting_at = null
	# Whatever the lesson before had to say is said; the one starting has its own.
	notice.clear()
	var lesson := lessons[i]
	lesson.begin(self)
	list.start_lesson(lesson)
	if reveal != null:
		for piece: Array in lesson.reveals:
			var actions: Array[StringName] = []
			if piece.size() > 2:
				actions.assign(piece[2])
			var also: StringName = piece[3] if piece.size() > 3 else &""
			var also_line: String = piece[4] if piece.size() > 4 else ""
			var also_actions: Array[StringName] = []
			if piece.size() > 5:
				also_actions.assign(piece[5])
			reveal.show_piece(piece[0], piece[1], actions, also, also_line, also_actions)
	_task = null
	_done = 0
	_refresh()
	lesson_started.emit(i)


func _physics_process(delta: float) -> void:
	# Held in their pens every tick: the match lets its karts go as it gets going.
	for slot_penned: PlayerSlot in penned:
		slot_penned.kart.frozen = true
	# A parked kart shot stays down, and so does a bot gone at the end: the match would bring
	# them back after its delay.
	for slot_down: PlayerSlot in dummies + gone:
		if not slot_down.kart.alive:
			slot_down.respawn_left = INF
	_shut_what_is_clear()
	_watch_hand()
	notice.keyboard = DeviceInput.uses_keyboard(_slot.device())
	if notice.visible:
		place_tally()
	_place_feed()
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


## The checklist, the hint and the arrow brought up to the task being done: a task done is a
## chime, and the pointer at the HUD has said its piece.
func _refresh() -> void:
	var lesson := lessons[index]
	var now := lesson.current()
	var done := 0
	for task: TutorialTask in lesson.tasks:
		done += 1 if task.done else 0
	if done > _done:
		_done = done
		Audio.play_sfx(TICK, -6.0, 0.0)
		var until := lesson.pointer_until
		if reveal != null and (until == null or until.done):
			reveal.pointer_done()
	if now != _task:
		_task = now
		hint.show_task(now, lesson)
	_aim(now)
	list.refresh(lesson)


## The arrow and its ring on where [param task] needs the kart: round a whole piece of the floor
## where the task names one, round the cell otherwise, and nowhere for a task that needs the kart
## nowhere in particular. Every tick, since a task may move its spot as it goes.
func _aim(task: TutorialTask) -> void:
	if task == null:
		arrow.point_at(Vector3.INF)
	elif task.arrow_rect.has_area():
		var across := maxi(task.arrow_rect.size.x, task.arrow_rect.size.y) * grid().cell_size
		arrow.point_at(grid().rect_center(task.arrow_rect), across * 0.5 + RING_OUT, task.ringed)
	elif task.arrow.x >= 0:
		arrow.point_at(cell(task.arrow), GuideArrow.RING_RADIUS, task.ringed)
	else:
		arrow.point_at(Vector3.INF)


func _complete(lesson: TutorialLesson) -> void:
	Audio.play_sfx(TICK, -6.0, 0.0)
	if reveal != null:
		reveal.pointer_done()
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
	# The arrow alone: a ring on a doorway marks nothing.
	arrow.point_at(
		Vector3(gate.global_position.x, 0.0, gate.global_position.z), GuideArrow.RING_RADIUS, false
	)
	waiting_at = gate


## The kart through the open gate: the gate shuts behind it and the next lesson starts.
func _step_through() -> void:
	var lesson := lessons[index]
	var gate := waiting_at
	var at := kart().global_position
	# In the next room, and far enough past the gate not to be in its doorway: a room may well lie
	# on the far side of its own gate, so the room alone is not enough and nor is the distance.
	if grid().region_of(grid().cell_of(at)) != grid().region_of(lesson.next_cell):
		return
	var here := Vector3(gate.global_position.x, 0.0, gate.global_position.z)
	var onward := cell(lesson.next_cell) - here
	onward.y = 0.0
	if (at - here).dot(onward.normalized()) < THROUGH:
		return
	_closing.append(gate)
	_shut_what_is_clear()
	waiting_at = null
	_start(index + 1)


## The kill feed hangs where the checklist is: under it, for as long as the list is up.
func _place_feed() -> void:
	if match_node.hud == null:
		return
	match_node.hud.feed_drop = list.offset_top + list.size.y + 10.0 if list.visible else 0.0


## A joker pick open with the hand already full is the one moment the pick wants explaining,
## GAME.md 3.7: the word at the top says what the choice is, for as long as the pick is open.
func _watch_hand() -> void:
	var offer := _slot.offer
	var full_pick := offer != null and not offer.is_done() and kart().jokers.is_full()
	if full_pick and not notice.is_saying(&"hand_full"):
		notice.say(&"hand_full", HAND_FULL)
	elif not full_pick and notice.is_saying(&"hand_full"):
		notice.clear(&"hand_full")


## Shuts the gates waiting to shut, each once nobody is in it.
func _shut_what_is_clear() -> void:
	for i: int in range(_closing.size() - 1, -1, -1):
		var gate := _closing[i]
		if _somebody_in(gate):
			continue
		gate.close()
		_block(gate, true)
		_closing.remove_at(i)


## Whether any kart still alive is close enough to the line of [param gate] to be caught by it
## shutting.
func _somebody_in(gate: Gate) -> bool:
	var from := cell(gate.cells[0])
	var to := cell(gate.cells[gate.cells.size() - 1])
	for slot_each: PlayerSlot in match_node.slots:
		var each := slot_each.kart
		if each == null or not each.alive:
			continue
		var at := Vector3(each.global_position.x, 0.0, each.global_position.z)
		if at.distance_to(Geometry3D.get_closest_point_to_segment(at, from, to)) < CLEAR:
			return true
	return false


## A kart that died comes back where it belongs: the player in the room they are learning in,
## facing the way the lesson goes, and a bot in the arena, or in its pen while it is still waiting
## there. A parked kart never comes back.
func _on_respawned(slot_index: int, _at: Vector3) -> void:
	if slot_index == _slot.index:
		var lesson := current_lesson()
		if lesson != null and lesson.spawn_cell.x >= 0:
			kart().respawn(
				cell(lesson.spawn_cell), lesson.facing, match_node.rules.spawn_protection
			)
		return
	for i: int in bots.size():
		if bots[i].index == slot_index:
			_park_bot(i)
			return


## A parked kart on its spot, facing the way in, and one hit from going down.
func _park_dummy(i: int) -> void:
	var at := TutorialJokers.DUMMY_SPOTS[i % TutorialJokers.DUMMY_SPOTS.size()]
	dummies[i].kart.respawn(cell(at), Vector3(0.0, 0.0, -1.0), 0.0)
	dummies[i].kart.lives = 1


func _park_bot(i: int) -> void:
	var slot_bot := bots[i]
	if slot_bot in penned:
		var pen := TutorialFight.PEN_SPOTS[i % TutorialFight.PEN_SPOTS.size()]
		slot_bot.kart.respawn(cell(pen), Vector3(-1.0, 0.0, 0.0), 0.0)
		return
	var spots := TutorialFight.ARENA_SPAWNS
	var at := cell(spots[_bot_spawns % spots.size()])
	_bot_spawns += 1
	var toward := match_node.arena.junction_near(at) - at
	slot_bot.kart.respawn(at, toward, match_node.rules.spawn_protection)


## The bots gone, GAME.md 9.4a, each popping the way a kart that dies does, with everything of
## theirs: their bullets, their turrets and their decoys. The fight is won; nothing of it shoots
## on, and a bot that was banking banks no more.
func vanish_bots() -> void:
	var theirs: Array[int] = []
	for slot_bot: PlayerSlot in bots:
		theirs.append(slot_bot.index)
	for bullet: Bullet in match_node.bullets.bullets.duplicate():
		if bullet.owner_slot in theirs:
			bullet.destroy()
	for turret: Node in get_tree().get_nodes_in_group(&"turrets"):
		if turret is Turret and (turret as Turret).owner_slot in theirs:
			(turret as Turret).destroy()
	for node: Node in get_tree().get_nodes_in_group(&"karts"):
		var each := node as Kart
		if each == null or not each.is_decoy() or each.slot not in theirs:
			continue
		Burst.spawn(each.get_parent(), each.global_position, Palette.player_color(each.color_index))
		each.queue_free()
	for slot_bot: PlayerSlot in bots:
		var each := slot_bot.kart
		if each.alive:
			# A bang, not the puff a kart dying is: this is the end of the fight.
			Burst.spawn(
				each.get_parent(),
				each.global_position,
				Palette.player_color(each.color_index),
				2.4,
				48
			)
			each.die(&"vanished", -1)
		TutorialReveal.hold(each)
		slot_bot.respawn_left = INF
	if not bots.is_empty():
		Audio.play_sfx(&"explosion", -2.0, 0.0)
	gone = bots.duplicate()
	penned.clear()


## Where the bots may drive, with [param gate] shut or open.
func _block(gate: Gate, blocked: bool) -> void:
	for at: Vector2i in gate.cells:
		match_node.nav.set_cell_blocked(at, blocked)
