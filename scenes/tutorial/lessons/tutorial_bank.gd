class_name TutorialBank
extends TutorialLesson
## Lesson 10, GAME.md 9.4a: the Junction, in the last room, which grows out of the floor as the
## lesson starts. Fill the pot from the Jackpots, then bank 50 points on the Junction, in as many
## cash-outs as it takes. The banked score comes into the corner with it, and a sign says the
## difference between the pot and the bank.

const JUNCTION := Vector2i(36, 47)
const JACKPOT := Vector2i(47, 52)
const WORDS := Vector2i(36, 50)
const NEED := 50
const POT := 20

var _fill: TutorialTask
var _bank: TutorialTask
var _banked := 0


func _init() -> void:
	title = "The Junction"
	spawn_cell = TutorialPads.SPAWN
	reveals = [[&"bank", "Your bank: safe for good", []]]
	_fill = add_task("Fill your pot from the Jackpot", "Drive into the Jackpot and wait")
	_fill.arrow = JACKPOT
	_bank = add_task("Bank 50 points at the Junction", "Drive onto the Junction and wait", [], true)
	_bank.arrow = JUNCTION


func _begin() -> void:
	for pad: JunctionPad in arena().junctions:
		TutorialReveal.show(pad)
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
