class_name TutorialFight
extends TutorialLesson
## Lesson 11, GAME.md 9.4a: the fight, in the last room, which gains its item pads, its coin pads
## and its crates as the lesson starts, with chips and a mult die or two over the floor to open
## with, and
## three bots in three pens along its east side, a gate each: the first
## is let out at once, the second at 300 banked and the third, a normal one where the others are
## easy, at 600. Bank 1000 points in here, on the bar across the top of the screen, and the
## tutorial is done, the bots and everything of theirs gone in a poof. A death is a respawn and a
## joker pick; nobody else's banking counts, and nobody can win the match itself.

const BOTS := 3
## Where the bots wait in their pens, each pen's gate, and where the bots come back in the arena.
const PEN_SPOTS: Array[Vector2i] = [Vector2i(54, 42), Vector2i(54, 47), Vector2i(54, 52)]
const PEN_GATES: Array[Vector2i] = [Vector2i(52, 41), Vector2i(52, 46), Vector2i(52, 51)]
const ARENA_SPAWNS: Array[Vector2i] = [
	Vector2i(23, 47), Vector2i(50, 47), Vector2i(36, 41), Vector2i(36, 53)
]
const PORTAL_GATE := Vector2i(35, 39)
## The points banked that let each bot out, and the points that finish the tutorial.
const RELEASE_AT: Array[int] = [0, 300, 600]
const NEED := 1000
const NORMAL: BotDifficulty = preload("res://data/ai/normal.tres")
## Where chips lie as the fight opens, by cell, and how many at each.
const CHIPS_AT: Array[Vector2i] = [
	Vector2i(29, 47), Vector2i(44, 47), Vector2i(36, 44), Vector2i(36, 51)
]
const CHIPS_EACH := 10
## Where a mult die or two lie as the fight opens, by cell, for a quicker road to the goal.
const DICE_AT: Array[Vector2i] = [Vector2i(27, 47), Vector2i(46, 47)]

var _bank: TutorialTask
## The hints under the goal, each a thing worth doing in a match, done on its own or with the goal.
var _kill: TutorialTask
var _mult: TutorialTask
var _jackpot: TutorialTask
var _flush: TutorialTask
var _cash: TutorialTask
var _use: TutorialTask
var _hand: TutorialTask
var _collected_lately := 0.0
var _banked := 0
var _released := 0
## The pens standing open, by bot, until their bot is out.
var _pens_open: Array[int] = []
var _bar: TutorialBossBar


func _init() -> void:
	title = "The fight"
	skippable = false
	show_all = true
	spawn_cell = TutorialPads.SPAWN
	reveals = [[&"stats", "", []], [&"feed", "", []]]
	_bank = add_task("Bank %d points" % NEED, "", [], true)
	_kill = add_task("Take out another kart", "")
	_mult = add_task("Reach a mult of 4", "")
	_jackpot = add_task("Drain a Jackpot", "")
	_flush = add_task("Claim a Royal Flush", "")
	_cash = add_task("Bank your whole pot at the Junction", "")
	_use = add_task("Use an item", "")
	_hand = add_task("Hold five jokers", "")
	stations = [[_bank], [_kill, _mult, _jackpot, _flush, _cash, _use, _hand]]


func _begin() -> void:
	var room := run.grid().region_of(TutorialPads.SPAWN)
	var grid := run.grid()
	for pad: PowerUpPad in arena().power_pads:
		if grid.region_of(grid.cell_of(pad.position)) == room:
			TutorialReveal.show(pad)
	for crate: Crate in arena().crates:
		if grid.region_of(grid.cell_of(crate.position)) == room:
			TutorialReveal.show(crate)
	for pad: CoinPad in arena().coin_pads:
		if grid.region_of(grid.cell_of(pad.position)) == room:
			TutorialReveal.show(pad)
	for at: Vector2i in CHIPS_AT:
		arena().spawn_chips(run.cell(at), CHIPS_EACH, 0.0, 0.15)
	for at: Vector2i in DICE_AT:
		var die := MultDie.new()
		die.lifetime = 0.0
		arena().place_drop(die, run.cell(at))
	Events.bank_tick.connect(_on_tick)
	Events.kart_killed.connect(_on_killed)
	Events.jackpot_collected.connect(_on_collected)
	Events.jackpot_emptied.connect(_on_emptied)
	Events.flush_completed.connect(_on_flush)
	Events.bank_completed.connect(_on_cashed)
	Events.item_used.connect(_on_used)
	# Match point from the goal, GAME.md 3.4: the call, the gold tracks and the burning pot, while
	# the match itself has no target to end on. The goal is counted from where the bank stands as
	# the fight starts, so the match point is too.
	run.match_node.win_at = run.slot().banked + NEED
	_bar = TutorialBossBar.add_to(run.layer, NEED)
	# The Royal Flush tally and the word at the top hang where the bar now is: under it.
	run.boss_bar = _bar
	run.place_tally()
	_release()


func end() -> void:
	if Events.bank_tick.is_connected(_on_tick):
		Events.bank_tick.disconnect(_on_tick)
	for pair: Array in [
		[Events.kart_killed, _on_killed],
		[Events.jackpot_collected, _on_collected],
		[Events.jackpot_emptied, _on_emptied],
		[Events.flush_completed, _on_flush],
		[Events.bank_completed, _on_cashed],
		[Events.item_used, _on_used],
	]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	run.match_node.win_at = 0
	if _bar != null and is_instance_valid(_bar):
		_bar.queue_free()
	run.boss_bar = null
	# Won: the bots go in a poof. Left before that, they are torn down with the room.
	if is_done() and run.is_inside_tree():
		run.vanish_bots()
	super()
	run.place_tally()


func step(delta: float) -> void:
	_collected_lately = maxf(_collected_lately - delta, 0.0)
	if kart().pot.mult >= 4.0 and not _mult.done:
		_mult.complete()
	if kart().jokers.count() >= 5 and not _hand.done:
		_hand.complete()
	# A pen shuts behind its bot once the bot is out in the room.
	for i: int in range(_pens_open.size() - 1, -1, -1):
		var which := _pens_open[i]
		if run.bots[which].kart.global_position.x < run.cell(PEN_GATES[which]).x:
			run.close_gate(PEN_GATES[which])
			_pens_open.remove_at(i)
	while _released < BOTS and _released < RELEASE_AT.size() and _banked >= RELEASE_AT[_released]:
		_release()


## How many bots are out of their pens.
func released() -> int:
	return _released


## The next bot out: its pen opens, the bot is let go, and the last one is the normal one.
func _release() -> void:
	var which := _released
	_released += 1
	if which >= run.bots.size():
		return
	if which == BOTS - 1:
		var brain := run.bots[which].kart.get_node_or_null("Brain") as BotBrain
		if brain != null:
			brain.setup(
				run.bots[which].kart, run.match_node, brain.bot_trait, NORMAL, run.match_node.rng
			)
	run.open_gate(PEN_GATES[which])
	_pens_open.append(which)
	run.release_bot(which)


func _on_tick(slot_index: int, points: int) -> void:
	if slot_index != kart().slot:
		return
	_banked += points
	_bank.progress = clampf(float(_banked) / NEED, 0.0, 1.0)
	if _bar != null and is_instance_valid(_bar):
		_bar.show_banked(_banked)
	if _banked >= NEED:
		# The goal is the lesson: the hints under it go with it, done or not.
		for task: TutorialTask in tasks:
			task.complete()


func _on_killed(_victim: int, killer: int, _cause: StringName) -> void:
	if killer == kart().slot and not _kill.done:
		_kill.complete()


func _on_collected(slot_index: int, _chips: int) -> void:
	if slot_index == kart().slot:
		_collected_lately = 1.0


## A Jackpot emptied while the player was the one collecting from it.
func _on_emptied(_zone_index: int) -> void:
	if _collected_lately > 0.0 and not _jackpot.done:
		_jackpot.complete()


func _on_flush(slot_index: int) -> void:
	if slot_index == kart().slot and not _flush.done:
		_flush.complete()


func _on_cashed(slot_index: int, _coins: int, _mult: float, total: int) -> void:
	# A kart standing on the Junction with nothing in the pot banks nothing, every tick.
	if slot_index == kart().slot and total > 0 and not _cash.done:
		_cash.complete()


func _on_used(slot_index: int, _id: StringName) -> void:
	if slot_index == kart().slot and not _use.done:
		_use.complete()
