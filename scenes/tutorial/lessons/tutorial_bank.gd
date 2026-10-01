class_name TutorialBank
extends TutorialLesson
## Lesson 10, GAME.md 9.4a: the Junction. Fill the pot from the chips and the Jackpot, then bank
## 50 points on the Junction, in as many cash-outs as it takes. The banked score comes into the
## corner with it, and a sign says the difference between the pot and the bank.

const JUNCTION := Vector2i(49, 46)
const JACKPOT := Vector2i(55, 41)
const WORDS := Vector2i(50, 41)
const NEED := 50
const POT := 20

var _fill: TutorialTask
var _bank: TutorialTask
var _banked := 0


func _init() -> void:
	title = "The Junction"
	gate_cell = Vector2i(59, 46)
	spawn_cell = Vector2i(43, 47)
	facing = Vector3(1.0, 0.0, 0.0)
	next_cell = Vector2i(62, 45)
	reveals = [[&"bank", "Your bank: safe for good", []]]
	_fill = add_task("Fill your pot with chips", "Drive over the chips and into the Jackpot")
	_fill.arrow = JACKPOT
	_bank = add_task("Bank 50 points at the Junction", "Drive onto the Junction and wait", [], true)
	_bank.arrow = JUNCTION


func _begin() -> void:
	var zone := jackpot_near(JACKPOT)
	if zone != null:
		arena().activate_jackpot(zone.index)
		zone.chips = float(zone.cap())
	Events.bank_tick.connect(_on_tick)
	put_sign("JUNCTION\nbank your pot here", JUNCTION, Palette.NEON_MAGENTA)
	put_sign(
		"POT: what you carry, part of it lost when you die\nBANK: safe for good, and 3000 wins a match",
		WORDS,
		Palette.CHIP_WHITE
	)


func end() -> void:
	if Events.bank_tick.is_connected(_on_tick):
		Events.bank_tick.disconnect(_on_tick)
	super()


func step(_delta: float) -> void:
	if current() == _fill and kart().pot.coins >= POT:
		_fill.complete()


func _on_tick(slot_index: int, points: int) -> void:
	if slot_index != kart().slot or current() != _bank:
		return
	_banked += points
	_bank.progress = clampf(float(_banked) / NEED, 0.0, 1.0)
	if _banked >= NEED:
		_bank.complete()
