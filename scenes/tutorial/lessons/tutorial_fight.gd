class_name TutorialFight
extends TutorialLesson
## Lesson 11, GAME.md 9.4a: the fight, in the last room, which gains its item pads and its crates
## as the lesson starts, with three bots in three pens along its east side, a gate each: the first
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

var _bank: TutorialTask
var _banked := 0
var _released := 0
## The pens standing open, by bot, until their bot is out.
var _pens_open: Array[int] = []
var _bar: TutorialBossBar


func _init() -> void:
	title = "The fight"
	spawn_cell = TutorialPads.SPAWN
	reveals = [[&"stats", "", []], [&"feed", "", []]]
	_bank = add_task("Bank %d points" % NEED, "Collect, bank, and watch your back", [], true)


func _begin() -> void:
	var room := run.grid().region_of(TutorialPads.SPAWN)
	var grid := run.grid()
	for pad: PowerUpPad in arena().power_pads:
		if grid.region_of(grid.cell_of(pad.position)) == room:
			TutorialReveal.show(pad)
	for crate: Crate in arena().crates:
		if grid.region_of(grid.cell_of(crate.position)) == room:
			TutorialReveal.show(crate)
	Events.bank_tick.connect(_on_tick)
	_bar = TutorialBossBar.add_to(run.layer, NEED)
	# The Royal Flush tally hangs where the bar now is: under it for the rest of the fight.
	var tally := _tally()
	if tally != null:
		tally.offset_top = _bar.below()
	_release()


func end() -> void:
	if Events.bank_tick.is_connected(_on_tick):
		Events.bank_tick.disconnect(_on_tick)
	if _bar != null and is_instance_valid(_bar):
		_bar.queue_free()
	# Won: the bots go in a poof. Left before that, they are torn down with the room.
	if is_done() and run.is_inside_tree():
		run.vanish_bots()
	var tally := _tally()
	if tally != null:
		tally.offset_top = MatchHud.TALLY_DROP
	super()


func _tally() -> FlushTally:
	var hud := run.match_node.hud
	return hud.find_child("FlushTally", true, false) as FlushTally if hud != null else null


func step(_delta: float) -> void:
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
		_bank.complete()
