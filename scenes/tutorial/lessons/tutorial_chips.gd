class_name TutorialChips
extends TutorialLesson
## Lesson 5, GAME.md 9.4a: chips. Its pieces come up one after another, each dropping out of the
## sky onto its outline, each with the clipboard's line about it: first the four Royal Flush pads in
## the corners of the lot, which pay whoever holds them and lock in for a flush, the pot coming into
## the corner as where the chips go: hold every pad at once. Then a Jackpot, full, which pays
## whoever waits in it: drain it. Then the Junction in the middle: bank the pot, all of it, so the
## exam starts with nothing in hand. A pot emptied any other way, a death say, sends the player
## back to the Jackpot. The bank comes into the corner with the Junction, a shut padlock on it and
## an open one on the pot, and a joker that banks of its own accord, Direct Debit, may from then.

## What the clipboard says at each part.
const FLUSH_WORDS := "{Royal Flush} pads pay out {chips} while you hold them. Hold all four."
const JACKPOT_WORDS := "Stand on a {Jackpot} to collect its {chips}."
const BANK_WORDS := "You lose part of your {pot} when you die. Only {banked} points are safe."
## How much floor a Jackpot and the Junction stand on, in cells.
const JACKPOT_CELLS := 2
const JUNCTION_CELLS := 4

var _flush: TutorialTask
var _drain: TutorialTask
var _bank: TutorialTask
var _pads: Array[FlushPad] = []
var _zone: JackpotZone
var _junction: JunctionPad
## The most the pot has held while banking, for the bar.
var _peak := 0.0


func _init() -> void:
	title = "Chips"
	spawn_cell = TestGround.ACROSS
	facing = TestGround.WEST
	reveals = [[&"pot", "Your {pot}", []]]
	_flush = add_task("Hold all four {Royal Flush} pads at once", "")
	_flush.arrow = TestGround.FLUSH_PADS[0]
	_drain = add_task("Drain the {Jackpot}", "", [], true)
	_drain.arrow = TestGround.JACKPOT
	_drain.arrow_rect = TestGround.JACKPOT_RECT
	_bank = add_task("{Bank} your {pot} at the {Junction}", "", [], true)
	_bank.arrow = TestGround.JUNCTION
	_bank.arrow_rect = TestGround.JUNCTION_RECT


## The pads, the Jackpot and the Junction, held back.
func _prepare() -> void:
	var size := cell_size()
	for pad: FlushPad in arena().flush_pads:
		_pads.append(pad)
		keep_back(pad, Vector2.ONE * size, RisingPiece.Way.DROP)
	_zone = jackpot_near(TestGround.JACKPOT)
	if _zone != null:
		keep_back(_zone, Vector2.ONE * size * JACKPOT_CELLS, RisingPiece.Way.DROP)
	for pad: JunctionPad in arena().junctions:
		_junction = pad
		keep_back(pad, Vector2.ONE * size * JUNCTION_CELLS, RisingPiece.Way.DROP)


## The pads first, and a line about them.
func _begin() -> void:
	bring_up(_pads, 0.25)
	run.list.say(&"flush", FLUSH_WORDS)
	Events.flush_completed.connect(_on_flush)
	Events.jackpot_emptied.connect(_on_emptied)
	Events.bank_completed.connect(_on_banked)


func end() -> void:
	if Events.flush_completed.is_connected(_on_flush):
		Events.flush_completed.disconnect(_on_flush)
	if Events.jackpot_emptied.is_connected(_on_emptied):
		Events.jackpot_emptied.disconnect(_on_emptied)
	if Events.bank_completed.is_connected(_on_banked):
		Events.bank_completed.disconnect(_on_banked)
	super()


## Done whichever way: the Junction in the lot, so a joker may bank of its own accord, and the
## Jackpot a live one for the exam that follows, GAME.md 9.4a. Played in order its [method _fill]
## does that; the exam gone to straight, or the lesson skipped, comes through here instead, where
## [method _begin] never ran, so settle it active too, left to fill as any does.
func _settle() -> void:
	kart().banks_passively = true
	if _zone != null:
		arena().activate_jackpot(_zone.index)


func step(_delta: float) -> void:
	var task := current()
	if task == _flush:
		_aim_at_pad()
	elif task == _drain and _zone != null and _zone.active:
		_drain.progress = clampf(1.0 - _zone.chips / maxf(float(_zone.cap()), 1.0), 0.0, 1.0)
	elif task == _bank:
		# The bar is how much of the most the pot has held is in the bank; a pot lost to a death
		# sends the player back to the Jackpot.
		var pot := kart().pot
		_peak = maxf(_peak, pot.exact_value())
		_bank.progress = clampf(1.0 - pot.exact_value() / maxf(_peak, 1.0), 0.0, 1.0)
		var empty := pot.is_empty()
		_bank.arrow = TestGround.JACKPOT if empty else TestGround.JUNCTION
		_bank.arrow_rect = TestGround.JACKPOT_RECT if empty else TestGround.JUNCTION_RECT


## The arrow on the nearest Royal Flush pad that is not the player's yet.
func _aim_at_pad() -> void:
	var here := kart().global_position
	var best := INF
	for pad: FlushPad in _pads:
		if pad.owner_slot == kart().slot:
			continue
		var distance := here.distance_to(pad.global_position)
		if distance < best:
			best = distance
			_flush.arrow = run.grid().cell_of(pad.global_position)


## The flush is in: the Jackpot comes up, full, and the line is about it.
func _on_flush(slot_index: int) -> void:
	if slot_index != kart().slot or _flush.done:
		return
	_flush.complete()
	if _zone != null:
		bring_up([_zone], 0.0, 0.0, _fill)
	run.list.say(&"jackpot", JACKPOT_WORDS)


## The Jackpot up, and full.
func _fill() -> void:
	if _zone == null:
		return
	arena().activate_jackpot(_zone.index)
	_zone.chips = float(_zone.cap())


## The Jackpot drained: the Junction comes up in the middle, the bank into the corner with it,
## and the line is about what is safe.
func _on_emptied(zone_index: int) -> void:
	if _zone == null or zone_index != _zone.index or current() != _drain:
		return
	_drain.complete()
	if _junction != null:
		bring_up([_junction])
	kart().banks_passively = true
	run.list.say(&"bank", BANK_WORDS)
	if run.reveal != null:
		pointer_until = _bank
		run.reveal.show_piece(&"bank", "{Bank}", [&"icon:safe"], &"pot", "{Pot}", [&"icon:risk"])


func _on_banked(slot_index: int, _coins: int, _mult: float, total: int) -> void:
	# A kart standing on the Junction with nothing in the pot banks nothing, every tick.
	if slot_index == kart().slot and total > 0 and current() == _bank:
		_bank.complete()
