class_name TutorialPads
extends TutorialLesson
## Lesson 9, GAME.md 9.4a: the pads. Hold every Royal Flush pad of the room at once for a flush,
## then drain the Jackpot, which starts full. The pot comes into the corner with it.

const JACKPOT := Vector2i(31, 47)
const FLUSH_SIGN := Vector2i(31, 41)

var _flush: TutorialTask
var _drain: TutorialTask
var _zone: JackpotZone


func _init() -> void:
	title = "Pads"
	gate_cell = Vector2i(41, 46)
	spawn_cell = Vector2i(24, 54)
	next_cell = Vector2i(43, 47)
	reveals = [[&"pot", "Your pot: chips times mult", []]]
	_flush = add_task("Hold all four Royal Flush pads at once", "Drive over each of the pads")
	_flush.arrow = Vector2i(25, 41)
	_drain = add_task("Drain the Jackpot", "Drive in and wait", [], true)
	_drain.arrow = JACKPOT


func _begin() -> void:
	_zone = jackpot_near(JACKPOT)
	if _zone != null:
		arena().activate_jackpot(_zone.index)
		_zone.chips = float(_zone.cap())
	Events.flush_completed.connect(_on_flush)
	Events.jackpot_emptied.connect(_on_emptied)
	put_sign("ROYAL FLUSH\nhold all four pads at once", FLUSH_SIGN, Palette.NEON_CYAN)
	put_sign("JACKPOT\ndrive in and wait", JACKPOT, Palette.CHIP_GOLD)


func end() -> void:
	if Events.flush_completed.is_connected(_on_flush):
		Events.flush_completed.disconnect(_on_flush)
	if Events.jackpot_emptied.is_connected(_on_emptied):
		Events.jackpot_emptied.disconnect(_on_emptied)
	super()


func step(_delta: float) -> void:
	if current() == _drain and _zone != null and _zone.active:
		_drain.progress = clampf(1.0 - _zone.chips / maxf(float(_zone.cap()), 1.0), 0.0, 1.0)


func _on_flush(slot_index: int) -> void:
	if slot_index == kart().slot:
		_flush.complete()


func _on_emptied(zone_index: int) -> void:
	if _zone != null and zone_index == _zone.index and current() == _drain:
		_drain.complete()
