class_name TutorialFight
extends TutorialLesson
## Lesson 11, GAME.md 9.4a: the fight. A small arena with everything a map has and three bots in a
## pen behind a gate: the first is let out at once, the second at 150 banked and the third, a
## normal one where the others are easy, at 300. Bank 400 points in here, on the bar across the
## top of the screen, and the tutorial is done. A death is a respawn and a joker pick; nobody
## else's banking counts, and nobody can win the match itself.

const BOTS := 3
## Where the bots wait in the pen and come back in the arena, and where the player does.
const PEN_SPOTS: Array[Vector2i] = [Vector2i(86, 34), Vector2i(88, 36), Vector2i(86, 39)]
const ARENA_SPAWNS: Array[Vector2i] = [
	Vector2i(63, 32), Vector2i(63, 60), Vector2i(81, 47), Vector2i(72, 33)
]
const PEN_GATE := Vector2i(84, 35)
const PORTAL_GATE := Vector2i(84, 54)
## The points banked that let each bot out, and the points that finish the tutorial.
const RELEASE_AT: Array[int] = [0, 150, 300]
const NEED := 400
const NORMAL: BotDifficulty = preload("res://data/ai/normal.tres")
## How long the pen stands open for a bot to come out, in seconds.
const PEN_OPEN := 6.0

var _bank: TutorialTask
var _banked := 0
var _released := 0
var _pen_left := 0.0
var _bar: TutorialBossBar


func _init() -> void:
	title = "The fight"
	spawn_cell = Vector2i(61, 45)
	facing = Vector3(1.0, 0.0, 0.0)
	reveals = [[&"stats", "", []], [&"feed", "", []]]
	_bank = add_task("Bank 400 points", "Collect, bank, and watch your back", [], true)


func _begin() -> void:
	var zone := jackpot_near(Vector2i(65, 36))
	if zone != null:
		arena().activate_jackpot(zone.index)
	Events.bank_tick.connect(_on_tick)
	_bar = TutorialBossBar.add_to(run.layer, NEED)
	_release()


func end() -> void:
	if Events.bank_tick.is_connected(_on_tick):
		Events.bank_tick.disconnect(_on_tick)
	if _bar != null and is_instance_valid(_bar):
		_bar.queue_free()
	super()


func step(delta: float) -> void:
	if _pen_left > 0.0:
		_pen_left -= delta
		if _pen_left <= 0.0:
			run.close_gate(PEN_GATE)
	while _released < BOTS and _released < RELEASE_AT.size() and _banked >= RELEASE_AT[_released]:
		_release()


## How many bots are out of the pen.
func released() -> int:
	return _released


## The next bot out: the pen opens, the bot is let go, and the last one is the normal one.
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
	run.open_gate(PEN_GATE)
	_pen_left = PEN_OPEN
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
