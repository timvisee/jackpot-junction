class_name PadLights
extends Node
## Each pad's light in the color of the kart it drives, GAME.md 10.8 "Steam Input": a DualSense's
## or a DualShock's light bar, so four players at one screen tell their pads apart at a glance as
## they tell their karts. A pad the engine reads is lit where it has a light; one Steam Input reads,
## through Steam, which puts the player's own color back once the match is over. A player reading
## every device lights every pad no seat has.

## How often the seats are looked at, in seconds: a seat taken, left or painted another color.
const EVERY := 0.5

var match_node: Match

## Each pad lit, by its id, and its color.
var _lit: Dictionary[int, Color] = {}
var _wait := 0.0


static func add_to(in_match: Match) -> PadLights:
	var lights := PadLights.new()
	lights.name = "PadLights"
	lights.match_node = in_match
	in_match.add_child(lights)
	return lights


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


## Every pad lit as its seat is now, and every pad no longer at one given its own color back.
func light() -> void:
	var now := wanted()
	for pad: int in _lit.keys():
		if not now.has(pad):
			DeviceInput.unlight(pad)
			_lit.erase(pad)
	for pad: int in now:
		if not _lit.has(pad) or _lit[pad] != now[pad]:
			DeviceInput.light(pad, now[pad])
			_lit[pad] = now[pad]


## The color each pad is to be lit in, by its id: its seat's kart's, a team's in team play.
func wanted() -> Dictionary[int, Color]:
	var colors: Dictionary[int, Color] = {}
	var everybody: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_local_human():
			continue
		var device := (slot.input as PlayerInput).device
		if device >= 0:
			colors[device] = slot.color()
		elif device == DeviceInput.ANY:
			everybody.append(slot)
	for slot: PlayerSlot in everybody:
		for pad: int in DeviceInput.pads():
			if not colors.has(pad):
				colors[pad] = slot.color()
	return colors
