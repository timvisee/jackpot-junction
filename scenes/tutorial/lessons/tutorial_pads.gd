class_name TutorialPads
extends TutorialLesson
## Lesson 9, GAME.md 9.4a: the pads, in the last room, which the pads lesson, the Junction's and
## the fight share, see [TutorialReveal]. The room starts bare but for its pit, and this lesson
## brings its pieces in one at a time, each with a word at the top about it: the four Royal Flush
## pads, which pay whoever holds them and lock in for a flush, the pot pointed at as where the
## coins go; then the two Jackpots, one of them full, to drain; then four mult dice to pick up,
## the mult pill of the pot pointed at as what they feed. The Junction is the next lesson's.

## Where the player comes back in the last room, which Jackpot starts full, and the room's floor.
const SPAWN := Vector2i(27, 53)
const JACKPOT := Vector2i(25, 41)
const JACKPOT_RECT := Rect2i(25, 41, 2, 2)
const ROOM := Rect2i(22, 40, 30, 15)
## Where the mult dice lie, by cell, and how many of them are the task.
const DICE_AT: Array[Vector2i] = [
	Vector2i(32, 44), Vector2i(41, 44), Vector2i(32, 50), Vector2i(41, 50)
]
const DICE := 3
## What the word at the top says at each part.
const FLUSH_WORDS := (
	"Royal Flush pads pay out coins when you hold them.\n" + "Hold all four to lock them in."
)
const JACKPOT_WORDS := "Stand on a Jackpot to collect its pot."
const MULT_WORDS := "Mult multiplies your pot.\nBalance coins and mult for the best score."

var _flush: TutorialTask
var _drain: TutorialTask
var _mult: TutorialTask
var _zone: JackpotZone


func _init() -> void:
	title = "Pads"
	spawn_cell = SPAWN
	reveals = [[&"pot", "Collected coins go to your pot", []]]
	_flush = add_task("Hold all four Royal Flush pads at once", "")
	_flush.arrow = Vector2i(24, 44)
	_drain = add_task("Drain the Jackpot", "", [], true)
	_drain.arrow = JACKPOT
	_drain.arrow_rect = JACKPOT_RECT
	_mult = add_task("Pick up three mult dice", "")
	_mult.of = DICE


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


## The pads first, and a word about them.
func _begin() -> void:
	var room := run.grid().region_of(SPAWN)
	for pad: FlushPad in arena().flush_pads:
		if pad.group == room:
			TutorialReveal.show(pad)
	run.notice.say(&"flush", FLUSH_WORDS)
	Events.flush_completed.connect(_on_flush)
	Events.jackpot_emptied.connect(_on_emptied)
	Events.mult_gained.connect(_on_mult)


func end() -> void:
	if Events.flush_completed.is_connected(_on_flush):
		Events.flush_completed.disconnect(_on_flush)
	if Events.jackpot_emptied.is_connected(_on_emptied):
		Events.jackpot_emptied.disconnect(_on_emptied)
	if Events.mult_gained.is_connected(_on_mult):
		Events.mult_gained.disconnect(_on_mult)
	super()


func step(_delta: float) -> void:
	if current() == _flush:
		_aim_at_pad()
	if current() == _drain and _zone != null and _zone.active:
		_drain.progress = clampf(1.0 - _zone.chips / maxf(float(_zone.cap()), 1.0), 0.0, 1.0)
	if current() == _mult:
		_aim_at_die()


## The arrow on the nearest Royal Flush pad of the room that is not the player's yet.
func _aim_at_pad() -> void:
	var here := kart().global_position
	var room := run.grid().region_of(SPAWN)
	var best := INF
	for pad: FlushPad in arena().flush_pads:
		if pad.group != room or pad.owner_slot == kart().slot:
			continue
		var distance := here.distance_to(pad.global_position)
		if distance < best:
			best = distance
			_flush.arrow = run.grid().cell_of(pad.global_position)


## The arrow on the nearest die still on the floor.
func _aim_at_die() -> void:
	var here := kart().global_position
	var best := INF
	for pickup: Node in arena().pickups.get_children():
		if pickup is MultDie and is_instance_valid(pickup):
			var distance := here.distance_to((pickup as Node3D).global_position)
			if distance < best:
				best = distance
				_mult.arrow = run.grid().cell_of((pickup as Node3D).global_position)


## The flush is in: the Jackpots come up, one of them full, and the word is about them.
func _on_flush(slot_index: int) -> void:
	if slot_index != kart().slot or _flush.done:
		return
	_flush.complete()
	var grid := run.grid()
	var room := grid.region_of(SPAWN)
	for zone: JackpotZone in arena().jackpot_zones:
		if grid.region_of(grid.cell_of(zone.position)) == room:
			TutorialReveal.show(zone)
	_zone = jackpot_near(JACKPOT)
	if _zone != null:
		arena().activate_jackpot(_zone.index)
		_zone.chips = float(_zone.cap())
	run.notice.say(&"jackpot", JACKPOT_WORDS)


## The Jackpot is drained: the dice come out, and the word and the pointer are about mult.
func _on_emptied(zone_index: int) -> void:
	if _zone == null or zone_index != _zone.index or current() != _drain:
		return
	_drain.complete()
	for at: Vector2i in DICE_AT:
		var die := MultDie.new()
		die.lifetime = 0.0
		arena().place_drop(die, run.cell(at))
	run.notice.say(&"mult", MULT_WORDS)
	if run.reveal != null:
		pointer_until = _mult
		run.reveal.show_piece(&"mult", "Mult will multiply your pot", [])


func _on_mult(slot_index: int, _amount: float, reason: StringName) -> void:
	if slot_index == kart().slot and reason == &"die" and current() == _mult:
		_mult.tally()
