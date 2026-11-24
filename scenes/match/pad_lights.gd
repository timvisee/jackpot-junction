class_name PadLights
extends Node
## Each pad's light in the color of the kart it drives, GAME.md 10.8 "Steam Input": a DualSense's
## or a DualShock's light bar, so four players at one screen tell their pads apart at a glance as
## they tell their karts. A pad the engine reads is lit where it has a light; one Steam Input reads,
## through Steam, which puts the player's own color back once the match is over. A player reading
## every device lights every pad no seat has. It looks while the game is paused too, so a color
## picked in the pause menu lights the pad at once rather than once the game goes on. A pad is lit
## again whenever it takes another seat, and as it comes back, whatever it was lit in last, so a
## light Steam put back meanwhile is never left showing.

## How often the seats are looked at, in seconds: a seat taken, left or painted another color.
const EVERY := 0.1

var match_node: Match

## Each pad lit, by its id, its color, and the seat it was lit for.
var _lit: Dictionary[int, Color] = {}
var _seat: Dictionary[int, int] = {}
var _wait := 0.0


static func add_to(in_match: Match) -> PadLights:
	var lights := PadLights.new()
	lights.name = "PadLights"
	lights.process_mode = Node.PROCESS_MODE_ALWAYS
	lights.match_node = in_match
	in_match.add_child(lights)
	return lights


func _ready() -> void:
	# A method rather than a lambda, which the engine's Input would still hold as the game quits.
	Input.joy_connection_changed.connect(_on_pad_plugged)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = EVERY
	light()


## The match over, or this gone with it, every pad given its own light back.
func _notification(what: int) -> void:
	if what in [NOTIFICATION_EXIT_TREE, NOTIFICATION_PREDELETE]:
		for pad: int in _lit:
			DeviceInput.unlight(pad)
		_lit.clear()


## Every pad lit as its seat is now, and every pad no longer at one given its own color back. A
## pad at another seat than it was lit for, one just sat down say, is lit again even in the same
## color, see the class.
func light() -> void:
	var seats := seated()
	var now := wanted(seats)
	for pad: int in _lit.keys():
		if not now.has(pad):
			DeviceInput.unlight(pad)
			_lit.erase(pad)
			_seat.erase(pad)
	for pad: int in now:
		if not _lit.has(pad) or _lit[pad] != now[pad] or _seat.get(pad, -1) != seats[pad]:
			DeviceInput.light(pad, now[pad])
			_lit[pad] = now[pad]
			_seat[pad] = seats[pad]


## The seat each pad is at, by its id, as its index: its own, or the seat reading every device for a
## pad no other seat has.
func seated() -> Dictionary[int, int]:
	var seats: Dictionary[int, int] = {}
	var everybody: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_local_human():
			continue
		var device := (slot.input as PlayerInput).device
		if device >= 0:
			seats[device] = slot.index
		elif device == DeviceInput.ANY:
			everybody.append(slot)
	for slot: PlayerSlot in everybody:
		for pad: int in DeviceInput.pads():
			if not seats.has(pad):
				seats[pad] = slot.index
	return seats


## The color each pad is to be lit in, by its id: its seat's kart's, a team's in team play; at the
## seats [param seats] says, see [method seated].
func wanted(seats: Dictionary[int, int]) -> Dictionary[int, Color]:
	var colors: Dictionary[int, Color] = {}
	for pad: int in seats:
		for slot: PlayerSlot in match_node.slots:
			if slot.index == seats[pad]:
				colors[pad] = slot.color()
	return colors


## A pad plugged in again, or gone: lit afresh at its seat whatever it was lit in before.
func _on_pad_plugged(device: int, _connected: bool) -> void:
	_lit.erase(device)
	_seat.erase(device)
