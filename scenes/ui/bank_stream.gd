class_name BankStream
extends Node
## Chips going into the Junction the whole time a pot is being banked on it, GAME.md 3.4 and 8.3,
## not only in the burst at the end of the cash-out: a steady beat of them while the pot drains,
## more at a time the faster it is draining, so the bank reads as money going in for as long as it
## is. Off the relayed ticks of the bank, so every screen sees the same.

## Seconds between two throws of chips, how long after the last tick a pot stops counting as
## being banked, and how many points one more chip in a throw is worth.
const EVERY := 0.09
const QUIET := 0.3
const POINTS_PER_CHIP := 25
const MOST := 3

var match_node: Match

## Slot to how the bank is going for it: points banked since the last throw, seconds until the
## next, and seconds since the last tick.
var _banking: Dictionary[int, Dictionary] = {}


static func add_to(hud: MatchHud) -> BankStream:
	var stream := BankStream.new()
	stream.name = "BankStream"
	stream.match_node = hud.match_node
	hud.add_child(stream)
	return stream


func _ready() -> void:
	Events.bank_tick.connect(_on_bank_tick)


func _exit_tree() -> void:
	Events.bank_tick.disconnect(_on_bank_tick)


func _on_bank_tick(slot: int, points: int) -> void:
	if not _banking.has(slot):
		_banking[slot] = {"points": 0, "next": 0.0, "quiet": 0.0}
	var bank := _banking[slot]
	bank["points"] = int(bank["points"]) + points
	bank["quiet"] = 0.0


func _process(delta: float) -> void:
	for slot: int in _banking.keys():
		var bank := _banking[slot]
		bank["quiet"] = float(bank["quiet"]) + delta
		bank["next"] = float(bank["next"]) - delta
		if float(bank["next"]) <= 0.0 and int(bank["points"]) > 0:
			bank["next"] = EVERY
			_throw(slot, int(bank["points"]))
			bank["points"] = 0
		if float(bank["quiet"]) > QUIET:
			_banking.erase(slot)


## A few chips from [param slot]'s kart into the Junction, for [param points] banked.
func _throw(slot: int, points: int) -> void:
	if match_node == null or match_node.arena == null or slot >= match_node.slots.size():
		return
	var kart := match_node.slots[slot].kart
	if kart == null:
		return
	var chips := clampi(1 + points / POINTS_PER_CHIP, 1, MOST)
	ChipBurst.spawn(
		match_node,
		kart.global_position,
		match_node.arena.junction_position,
		chips,
		Palette.CHIP_GOLD
	)
