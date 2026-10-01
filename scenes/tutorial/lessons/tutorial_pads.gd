class_name TutorialPads
extends TutorialLesson
## Lesson 9, GAME.md 9.4a: the pads, in the last room, which the pads lesson, the Junction's and
## the fight share, see [TutorialReveal]. The room starts bare but for its pit; the four Royal
## Flush pads and the two Jackpots grow out of the floor as the lesson starts. Hold every pad of
## the room at once for a flush, then drain the Jackpot, which starts full. The pot comes into the
## corner with it.

## Where the player comes back in the last room, which way they face, and where the Jackpot that
## starts full is.
const SPAWN := Vector2i(27, 53)
const JACKPOT := Vector2i(25, 41)
const JACKPOT_RECT := Rect2i(25, 41, 2, 2)
## The room's floor, by cell.
const ROOM := Rect2i(22, 40, 30, 15)

var _flush: TutorialTask
var _drain: TutorialTask
var _zone: JackpotZone


func _init() -> void:
	title = "Pads"
	spawn_cell = SPAWN
	reveals = [[&"pot", "Your pot: what you carry, part lost when you die", []]]
	_flush = add_task("Hold all four Royal Flush pads at once", "Drive over each of the pads")
	_flush.arrow = Vector2i(24, 44)
	_drain = add_task("Drain the Jackpot", "Drive in and wait", [], true)
	_drain.arrow = JACKPOT
	_drain.arrow_rect = JACKPOT_RECT


## The last room starts bare: everything but its pit is held back for the lesson it is for.
func _prepare() -> void:
	var room := run.grid().region_of(SPAWN)
	var grid := run.grid()
	for pad: FlushPad in arena().flush_pads:
		if pad.group == room:
			TutorialReveal.hold(pad)
	for zone: JackpotZone in arena().jackpot_zones:
		if grid.region_of(grid.cell_of(zone.position)) == room:
			TutorialReveal.hold(zone)
	for pad: JunctionPad in arena().junctions:
		if grid.region_of(grid.cell_of(pad.position)) == room:
			TutorialReveal.hold(pad)
	for pad: PowerUpPad in arena().power_pads:
		if grid.region_of(grid.cell_of(pad.position)) == room:
			TutorialReveal.hold(pad)
	for crate: Crate in arena().crates:
		if grid.region_of(grid.cell_of(crate.position)) == room:
			TutorialReveal.hold(crate)
	for pad: CoinPad in arena().coin_pads:
		if grid.region_of(grid.cell_of(pad.position)) == room:
			TutorialReveal.hold(pad)


func _begin() -> void:
	var room := run.grid().region_of(SPAWN)
	var grid := run.grid()
	for pad: FlushPad in arena().flush_pads:
		if pad.group == room:
			TutorialReveal.show(pad)
	for zone: JackpotZone in arena().jackpot_zones:
		if grid.region_of(grid.cell_of(zone.position)) == room:
			TutorialReveal.show(zone)
	_zone = jackpot_near(JACKPOT)
	if _zone != null:
		arena().activate_jackpot(_zone.index)
		_zone.chips = float(_zone.cap())
	Events.flush_completed.connect(_on_flush)
	Events.jackpot_emptied.connect(_on_emptied)


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
