class_name TutorialRun
extends Node
## Runs the lessons of GAME.md 9.4a in order over the tutorial's match, on the one open lot of
## [TestGround]: one at a time, its tasks on the clipboard and the control for the one being done
## over the kart, with the arrow on the floor pointing where it needs the kart to go. Each lesson
## brings its pieces up out of the floor, see [RisingPiece], and they stay, so the lot is a table
## by the exam. A lesson done hands straight on to the next. The HUD arrives a piece at a time with
## the lessons, see [HudReveal]. Everybody else in the match is held under the floor until their
## lesson: the parked kart of the jokers lesson, and the bots of the exam, which come up on lifts at
## the lot's edges; a kart that dies comes back where the lesson under way puts it.

signal lesson_started(index: int)
signal finished

## How far outside a piece of the floor its ring runs, in meters.
const RING_OUT := 0.4
## What a task done sounds like.
const TICK := &"ready"
## What the clipboard says for a joker pick with the hand already full, GAME.md 3.7.
const HAND_FULL := "Your hand is full. Replace a card or skip it."
## How much floor a bot coming up on a lift stands on, for its outline.
const LIFT_ACROSS := Vector2(1.8, 2.2)

## Whether the run goes straight to the exam, every lesson before it settled at once, see
## [method DrivingSchool.express].
static var express := false

var match_node: Match
var layer: CanvasLayer
var lessons: Array[TutorialLesson] = []
## Which lesson is running, or -1 before the first.
var index := -1
var list: TutorialList
var hint: TutorialHint
var arrow: GuideArrow
var reveal: HudReveal
## The jokers lesson's trench, see [Trench].
var trench: Trench
## The parked kart of the jokers lesson and the bots of the exam, and which bots are still held,
## still every tick.
var dummies: Array[PlayerSlot] = []
var bots: Array[PlayerSlot] = []
var penned: Array[PlayerSlot] = []
## The bots gone for good at the end of the exam, never to come back.
var gone: Array[PlayerSlot] = []

var _slot: PlayerSlot
var _task: TutorialTask
## How many of the lesson's tasks were done at the last look, for hearing one more.
var _done := 0
var _over := false


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
	var touch: Control = null
	if in_match.hud != null:
		touch = in_match.hud.get_node_or_null("TouchControls") as Control
	run.list = TutorialList.add_to(on_layer, touch)
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
		TutorialNitro.new(),
		TutorialShoot.new(),
		TutorialJokers.new(),
		TutorialChips.new(),
		TutorialFight.new(),
	]
	parent.add_child(run)
	return run


func _ready() -> void:
	Events.kart_respawned.connect(_on_respawned)
	# Everybody where they belong: the match seated them on the map's spawns in reading order.
	kart().respawn(cell(TestGround.START), TestGround.NORTH, 0.0)
	# No banking by joker until the Junction is in the lot, GAME.md 9.4a.
	kart().banks_passively = false
	for i: int in dummies.size():
		_park_dummy(i)
	for i: int in bots.size():
		_park_bot(i)
	if match_node.nav != null:
		trench = Trench.lay(match_node.arena, match_node.nav, TestGround.TRENCH)
	# What each lesson brings up, held back under the floor from the start.
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


## The middle of [param at], a cell of the map, on the floor.
func cell(at: Vector2i) -> Vector3:
	return grid().cell_center(at)


func current_lesson() -> TutorialLesson:
	return lessons[index] if index >= 0 and index < lessons.size() else null


## Whether the test is over: the exam passed.
func is_over() -> bool:
	return _over


## Starts the test: the first lesson, or straight to the exam with everything before it settled,
## its pieces up and the HUD whole.
func begin() -> void:
	if not express:
		_start(0)
		return
	var exam := lessons.size() - 1
	for i: int in exam:
		var lesson := lessons[i]
		lesson.run = self
		for task: TutorialTask in lesson.tasks:
			task.complete()
		lesson.bring_all_at_once()
		lesson.end()
		if reveal != null:
			for piece: Array in lesson.reveals:
				reveal.ensure_shown(piece[0])
			for piece: StringName in lesson.ensures:
				reveal.ensure_shown(piece)
	if reveal != null:
		for piece: StringName in [&"nitro", &"item", &"lives", &"hand", &"pot", &"bank"]:
			reveal.ensure_shown(piece)
	_start(exam)


## The pause menu's Skip lesson: the lesson being done is done, its pieces up at once. The exam is
## not skipped: it is the test, and the menu's entry is gone by then.
func skip() -> void:
	var lesson := current_lesson()
	if lesson == null or not lesson.skippable:
		return
	lesson.skip()


## Bot [param which] up on a lift at the lot's edge, the one farthest from the player, and let go
## once it is up, GAME.md 9.4a.
func release_bot(which: int) -> void:
	if which < 0 or which >= bots.size():
		return
	var slot_bot := bots[which]
	slot_bot.kart.respawn(_far_lift(), _into_the_lot(_far_lift()), 0.0)
	RisingPiece.hold(slot_bot.kart)
	var skin := match_node.arena.surfaces.floor_top() if match_node.arena.surfaces != null else null
	RisingPiece.bring(
		slot_bot.kart,
		LIFT_ACROSS,
		RisingPiece.Way.RISE,
		0.0,
		skin,
		func() -> void:
			penned.erase(slot_bot)
			slot_bot.kart.frozen = false
	)


func _start(i: int) -> void:
	if i >= lessons.size():
		_over = true
		hint.clear()
		arrow.point_at(Vector3.INF)
		finished.emit()
		return
	index = i
	# Whatever the lesson before had to say is said; the one starting has its own.
	list.unsay()
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
	# Held still every tick until they are up: the match lets its karts go as it gets going.
	for slot_penned: PlayerSlot in penned:
		slot_penned.kart.frozen = true
	# A parked kart shot stays down, and so does a bot gone at the end: the match would bring
	# them back after its delay.
	for slot_down: PlayerSlot in dummies + gone:
		if not slot_down.kart.alive:
			slot_down.respawn_left = INF
	_watch_hand()
	_place_feed()
	if _over or index < 0:
		return
	var lesson := lessons[index]
	lesson.step(delta)
	_refresh()
	if lesson.is_done():
		_complete(lesson)


## The clipboard, the control over the kart and the arrow brought up to the task being done: a task
## done is a chime, and the pointer at the HUD has done its piece.
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


## A lesson done: the chime, its pointer put away, the PASSED stamp on the clipboard, and straight
## on to the next.
func _complete(lesson: TutorialLesson) -> void:
	Audio.play_sfx(TICK, -6.0, 0.0)
	if reveal != null:
		reveal.pointer_done()
		for piece: StringName in lesson.ensures:
			reveal.ensure_shown(piece)
	lesson.end()
	list.finish_lesson(lesson)
	hint.clear()
	_start(index + 1)


## A debug build's Skip to end: the lesson being done is dropped and the test is over as if the
## exam were won, with nothing earned on the license.
func skip_to_end() -> void:
	if _over:
		return
	var lesson := current_lesson()
	if lesson != null:
		lesson.end()
	index = lessons.size() - 1
	_start(lessons.size())


## The kill feed hangs where the clipboard is: under it, for as long as the clipboard is up.
func _place_feed() -> void:
	if match_node.hud == null:
		return
	match_node.hud.feed_drop = list.offset_top + list.size.y + 10.0 if list.visible else 0.0


## A joker pick open with the hand already full is the one moment the pick wants explaining,
## GAME.md 3.7: the clipboard says what the choice is, for as long as the pick is open.
func _watch_hand() -> void:
	var offer := _slot.offer
	var full_pick := offer != null and not offer.is_done() and kart().jokers.is_full()
	if full_pick and not list.is_saying(&"hand_full"):
		list.say(&"hand_full", HAND_FULL)
	elif not full_pick and list.is_saying(&"hand_full"):
		list.unsay(&"hand_full")


## A kart back from the dead: the player where the lesson under way puts it, a bot on a lift.
func _on_respawned(slot_index: int, _at: Vector3) -> void:
	if slot_index == _slot.index:
		var lesson := current_lesson()
		var spot := lesson.spawn_cell if lesson != null else TestGround.START
		var way := lesson.facing if lesson != null else TestGround.NORTH
		kart().respawn(cell(spot), way, match_node.rules.spawn_protection)
		return
	for i: int in bots.size():
		if bots[i].index == slot_index:
			_park_bot(i)
			return


## The parked kart on its spot, facing the kart coming from the targets, and one hit from going
## down. Held under the floor until its lesson brings it up.
func _park_dummy(i: int) -> void:
	dummies[i].kart.respawn(cell(TestGround.PARKED), TestGround.NORTH, 0.0)
	dummies[i].kart.lives = 1


## A bot on a lift: held under the floor until the exam brings it up, or, once it is out, back on
## the lift farthest from the player.
func _park_bot(i: int) -> void:
	var slot_bot := bots[i]
	var at := _far_lift()
	slot_bot.kart.respawn(at, _into_the_lot(at), match_node.rules.spawn_protection)
	if slot_bot in penned:
		RisingPiece.hold(slot_bot.kart)


## The lift farthest from the player's kart.
func _far_lift() -> Vector3:
	var here := kart().global_position
	var best := cell(TestGround.LIFTS[0])
	for lift: Vector2i in TestGround.LIFTS:
		var at := cell(lift)
		if at.distance_to(here) > best.distance_to(here):
			best = at
	return best


## Which way a kart at [param at] faces to look into the lot: at the Junction.
func _into_the_lot(at: Vector3) -> Vector3:
	return cell(TestGround.JUNCTION) - at


## The bots gone, GAME.md 9.4a, each popping the way a kart that dies does, with everything of
## theirs: their bullets, their turrets and their decoys. The exam is passed; nothing of it shoots
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
		if each.alive and each.process_mode != Node.PROCESS_MODE_DISABLED:
			# A bang, not the puff a kart dying is: this is the end of the exam.
			Burst.spawn(
				each.get_parent(),
				each.global_position,
				Palette.player_color(each.color_index),
				2.4,
				48
			)
		if each.alive:
			each.die(&"vanished", -1)
		RisingPiece.hold(each)
		slot_bot.respawn_left = INF
	if not bots.is_empty():
		Audio.play_sfx(&"explosion", -2.0, 0.0)
	gone = bots.duplicate()
	penned.clear()
