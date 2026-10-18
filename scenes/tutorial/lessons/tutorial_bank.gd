class_name TutorialBank
extends TutorialLesson
## Lesson 10, GAME.md 9.4a: the Junction, in the last room, which grows out of the floor as the
## lesson starts. Fill the pot from the Jackpot, then bank the whole of it on the Junction, so the
## fight after starts with nothing in hand. The banked score comes into the corner with it, the
## pointer framing the pot and the bank both, since banking is the one moving to the other, and
## the word at the top says what is lost on death and what is safe.

const JUNCTION := Vector2i(36, 47)
const JUNCTION_RECT := Rect2i(35, 46, 4, 4)
const JACKPOT := Vector2i(47, 52)
const JACKPOT_RECT := Rect2i(47, 52, 2, 2)
const POT := 20
## What the banking task says over the kart: nothing, the pointers and the word at the top
## saying it, unless the pot is empty; and the word at the top for the lesson.
const BANK := ""
const EMPTY := "Your {pot} is empty: fill it at the {Jackpot} first"
const WORDS := "You lose part of your {pot} when you die.\nOnly {banked} points are safe."

var _fill: TutorialTask
var _bank: TutorialTask
## The most the pot has held while banking, for the bar.
var _peak := 0.0


func _init() -> void:
	title = "The Junction"
	spawn_cell = TutorialPads.SPAWN
	reveals = [
		[&"bank", "%s {Bank}: safe", [&"icon:safe"], &"pot", "%s {Pot}: at risk", [&"icon:risk"]]
	]
	_fill = add_task("Fill your {pot} from the {Jackpot}", "")
	_fill.arrow = JACKPOT
	_fill.arrow_rect = JACKPOT_RECT
	_bank = add_task("{Bank} the {chips} in your {pot} at the {Junction}", BANK, [], true)
	_bank.arrow = JUNCTION
	_bank.arrow_rect = JUNCTION_RECT
	pointer_until = _bank


func _begin() -> void:
	for pad: JunctionPad in arena().junctions:
		TutorialReveal.show(pad)
	var zone := jackpot_near(JACKPOT)
	if zone != null:
		arena().activate_jackpot(zone.index)
		zone.chips = float(zone.cap())
	Events.bank_completed.connect(_on_banked)
	run.list.say(&"bank", WORDS)
	# The Junction is in the room: a joker that banks of its own accord may, from here on.
	kart().banks_passively = true


func end() -> void:
	if Events.bank_completed.is_connected(_on_banked):
		Events.bank_completed.disconnect(_on_banked)
	super()


func step(_delta: float) -> void:
	var pot := kart().pot
	if current() == _fill and pot.coins >= POT:
		_fill.complete()
	elif current() == _bank:
		# The bar is how much of the most the pot has held is in the bank; a pot lost to a death
		# or never filled sends the player back to the Jackpot.
		_peak = maxf(_peak, pot.exact_value())
		_bank.progress = clampf(1.0 - pot.exact_value() / maxf(_peak, 1.0), 0.0, 1.0)
		_bank.hint = EMPTY if pot.is_empty() else BANK
		_bank.arrow = JACKPOT if pot.is_empty() else JUNCTION
		_bank.arrow_rect = JACKPOT_RECT if pot.is_empty() else JUNCTION_RECT


func _on_banked(slot_index: int, _coins: int, _mult: float, total: int) -> void:
	# A kart standing on the Junction with nothing in the pot banks nothing, every tick.
	if slot_index == kart().slot and total > 0 and current() == _bank:
		_bank.complete()
