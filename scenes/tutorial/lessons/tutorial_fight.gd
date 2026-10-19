class_name TutorialFight
extends TutorialLesson
## Lesson 6, GAME.md 9.4a: the final exam, on the whole lot, which gains the rest of a table as the
## lesson starts: item pads, coin pads, crates and a second Jackpot coming up out of the floor, with
## chips and a mult die or two over it to open with, and two easy bots coming up on lifts at its
## edges: the first at once and the second at 250 held, banked or in the pot, so a player who never
## banks still meets it. Bank 500 points, on the goal's bar on the clipboard, and the tutorial is
## done, the bots and everything of theirs gone in a poof. A death is a respawn and a joker pick;
## nobody else's banking counts, and nobody can win the match itself.

const BOTS := 2
## The points held, banked since the exam began and in the pot, that bring each bot up, and the
## points banked that finish the tutorial.
const RELEASE_AT: Array[int] = [0, 250]
const NEED := 500
## How many jokers held is a full hand for the exam's hint: the jokers lesson deals two.
const HAND := 3
## Where chips lie as the exam opens, by cell, and how many at each.
const CHIPS_AT: Array[Vector2i] = [
	Vector2i(10, 10), Vector2i(17, 7), Vector2i(13, 4), Vector2i(22, 11)
]
const CHIPS_EACH := 10
## Where a mult die or two lie as the exam opens, by cell, for a quicker road to the goal.
const DICE_AT: Array[Vector2i] = [Vector2i(6, 11), Vector2i(26, 7)]
## What each hint under the goal is called on the license, see [LicenseCard], in the order of
## the hints.
const ENDORSEMENTS: Array[String] = [
	"KO", "MULT 4", "JACKPOT", "ROYAL FLUSH", "CASH-OUT", "ITEMS", "FULL HAND"
]

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
## What the bank held as the fight began, which the goal and the match point count from.
var _bank_at_start := 0
var _released := 0
## The hints done on their own, by endorsement, before the goal took the rest with it.
var _earned: Dictionary[String, bool] = {}


func _init() -> void:
	title = "Final exam"
	skippable = false
	show_all = true
	spawn_cell = TestGround.START
	reveals = [[&"stats", "", []], [&"feed", "", []], [&"mult", "Your {mult}", []]]
	_bank = add_task("{Bank} points", "", [], true)
	_bank.of = NEED
	_kill = add_task("Take out another kart", "")
	_mult = add_task("Reach a {mult} of 4", "")
	_jackpot = add_task("Drain a {Jackpot}", "")
	_flush = add_task("Claim a {Royal Flush}", "")
	_cash = add_task("{Bank} your whole {pot} at the {Junction}", "")
	_use = add_task("Use an item", "")
	_hand = add_task("Hold three jokers", "")
	stations = [[_bank], [_kill, _mult, _jackpot, _flush, _cash, _use, _hand]]


## The rest of a table, held back: the item pads, the coin pads, the crates and the second Jackpot.
func _prepare() -> void:
	var size := cell_size()
	for pad: PowerUpPad in arena().power_pads:
		keep_back(pad, Vector2.ONE * size, RisingPiece.Way.DROP)
	for pad: CoinPad in arena().coin_pads:
		keep_back(pad, Vector2.ONE * size, RisingPiece.Way.DROP)
	for crate: Crate in arena().crates:
		keep_back(crate, Vector2.ONE * size)
	var first := jackpot_near(TestGround.JACKPOT)
	for zone: JackpotZone in arena().jackpot_zones:
		if zone != first:
			keep_back(zone, Vector2.ONE * size * TutorialChips.JACKPOT_CELLS, RisingPiece.Way.DROP)


func _begin() -> void:
	bring_up(piece_nodes(), 0.06)
	for at: Vector2i in CHIPS_AT:
		arena().spawn_chips(run.cell(at), CHIPS_EACH, 0.0, 0.15)
	for at: Vector2i in DICE_AT:
		var die := MultDie.new()
		die.lifetime = 0.0
		arena().place_drop(die, run.cell(at))
	Events.bank_tick.connect(_on_tick)
	Events.death_banked.connect(_on_death_banked)
	Events.kart_killed.connect(_on_killed)
	Events.jackpot_collected.connect(_on_collected)
	Events.jackpot_emptied.connect(_on_emptied)
	Events.flush_completed.connect(_on_flush)
	Events.bank_completed.connect(_on_cashed)
	Events.item_used.connect(_on_used)
	# Match point from the goal, GAME.md 3.4: the call, the gold tracks and the burning pot, while
	# the match itself has no target to end on. The goal is the thousand on top of what the bank
	# holds as the fight starts, so the match point is where banking the pot would reach that,
	# and never with an empty pot, which is the match's own rule.
	_bank_at_start = run.slot().banked
	run.match_node.win_at = _bank_at_start + NEED
	_release()


func end() -> void:
	if Events.bank_tick.is_connected(_on_tick):
		Events.bank_tick.disconnect(_on_tick)
	if Events.death_banked.is_connected(_on_death_banked):
		Events.death_banked.disconnect(_on_death_banked)
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
	# Won: the bots go in a poof. Left before that, they are torn down with the room.
	if is_done() and run.is_inside_tree():
		run.vanish_bots()
	super()


func step(delta: float) -> void:
	_collected_lately = maxf(_collected_lately - delta, 0.0)
	if kart().pot.mult >= 4.0:
		_earn(_mult, ENDORSEMENTS[1])
	if kart().jokers.count() >= HAND:
		_earn(_hand, ENDORSEMENTS[6])
	var held := _banked + kart().pot.value()
	while _released < BOTS and _released < RELEASE_AT.size() and held >= RELEASE_AT[_released]:
		_release()


## How many bots are out of their pens.
func released() -> int:
	return _released


## What the bank held as the fight began.
func bank_at_start() -> int:
	return _bank_at_start


## The endorsements for the license, each to whether it was earned: a hint done on its own, not
## one the goal ticked on the way out.
func endorsements() -> Dictionary[String, bool]:
	var earned: Dictionary[String, bool] = {}
	for word: String in ENDORSEMENTS:
		earned[word] = _earned.get(word, false)
	return earned


## [param task] done on its own, which is the endorsement [param word] earned.
func _earn(task: TutorialTask, word: String) -> void:
	if task.done:
		return
	_earned[word] = true
	task.complete()


## The next bot up, on a lift at the lot's edge.
func _release() -> void:
	var which := _released
	_released += 1
	if which >= run.bots.size():
		return
	run.release_bot(which)


## A death banks a share of the pot, GAME.md 3.6, into the bank like anything else: on the bar,
## so the bar and the match point, which counts the bank, agree.
func _on_death_banked(slot_index: int, amount: int, _lost: int) -> void:
	_on_tick(slot_index, amount)


func _on_tick(slot_index: int, points: int) -> void:
	if slot_index != kart().slot or points <= 0:
		return
	_banked += points
	_bank.progress = clampf(float(_banked) / NEED, 0.0, 1.0)
	_bank.count = mini(_banked, NEED)
	if _banked >= NEED:
		# The goal is the lesson: the hints under it go with it, done or not.
		for task: TutorialTask in tasks:
			task.complete()


func _on_killed(_victim: int, killer: int, _cause: StringName) -> void:
	if killer == kart().slot:
		_earn(_kill, ENDORSEMENTS[0])


func _on_collected(slot_index: int, _chips: int) -> void:
	if slot_index == kart().slot:
		_collected_lately = 1.0


## A Jackpot emptied while the player was the one collecting from it.
func _on_emptied(_zone_index: int) -> void:
	if _collected_lately > 0.0:
		_earn(_jackpot, ENDORSEMENTS[2])


func _on_flush(slot_index: int) -> void:
	if slot_index == kart().slot:
		_earn(_flush, ENDORSEMENTS[3])


func _on_cashed(slot_index: int, _coins: int, _mult: float, total: int) -> void:
	# A kart standing on the Junction with nothing in the pot banks nothing, every tick.
	if slot_index == kart().slot and total > 0:
		_earn(_cash, ENDORSEMENTS[4])


func _on_used(slot_index: int, _id: StringName) -> void:
	if slot_index == kart().slot:
		_earn(_use, ENDORSEMENTS[5])
