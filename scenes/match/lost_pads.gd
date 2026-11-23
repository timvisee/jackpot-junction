class_name LostPads
extends Node
## A pad that goes while it is played on, GAME.md 4.2, out of battery or pulled out: the room's
## menu comes up for a player here holding it, as if they had pressed Pause, which stops the room
## played alone and asks for a stop online, and they keep their seat while it is up, the next pad
## that comes being theirs. Played on without it, the menu put away with the pad still gone, a bot
## takes their kart over, as it would from somebody who got up; and should that pad ever come again,
## it takes the same kart back. A player reading every device plays on with whatever else they
## have, and a pad nobody holds goes unremarked.

## The room's pause menus, [constant PauseMenu.GROUP] by name: the menu reaches far enough into the
## game to bring the match round again.
const PAUSE_MENUS := &"pause_menu"

var match_node: Match

## The players whose pad went while the menu is up for it, each with that pad.
var _waiting: Dictionary[PlayerSlot, int] = {}
## The karts a bot took over, their player's pad gone, each with that pad and the player's seat
## here, for the pad to take it back when it comes again.
var _gone: Dictionary[PlayerSlot, Vector2i] = {}


static func add_to(in_match: Match) -> LostPads:
	var lost := LostPads.new()
	lost.name = "LostPads"
	lost.match_node = in_match
	in_match.add_child(lost)
	return lost


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_pad_plugged)


func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_on_pad_plugged):
		Input.joy_connection_changed.disconnect(_on_pad_plugged)


func _on_pad_plugged(device: int, connected: bool) -> void:
	if connected:
		hand(device)
		return
	var held := holding(device)
	if held.is_empty():
		return
	for slot: PlayerSlot in held:
		if (slot.input as PlayerInput).device == device:
			_waiting[slot] = device
	var menus := get_tree().get_nodes_in_group(PAUSE_MENUS)
	# A room with no menu to wait in: a bot at once.
	if menus.is_empty():
		play_on()
	for menu: Node in menus:
		if not menu.is_connected(&"resumed", play_on):
			menu.connect(&"resumed", play_on)
		if not bool(menu.call(&"is_open")):
			menu.call(&"set_paused", true)


## The players here holding the pad [param device]: one who plays on it, or one reading every
## device who last drove with it.
func holding(device: int) -> Array[PlayerSlot]:
	var held: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		var player := slot.input as PlayerInput
		if player != null and player.held_device() == device:
			held.append(slot)
	return held


## The pad [param device], just come: while the menu is up for a pad that went, the player's whose
## pad it was, or failing that the first waiting; afterwards, the kart a bot took over from the
## player whose pad it was, taken back, as long as a bot still has it.
func hand(device: int) -> void:
	var waiting: PlayerSlot = null
	for slot: PlayerSlot in _waiting.keys():
		# One who got up from their switch meanwhile waits no more.
		if not slot.input is PlayerInput:
			_waiting.erase(slot)
		elif waiting == null or _waiting[slot] == device:
			waiting = slot
	if waiting != null:
		_waiting.erase(waiting)
		(waiting.input as PlayerInput).device = device
		return
	for slot: PlayerSlot in _gone.keys():
		if _gone[slot].x != device:
			continue
		var seat := _gone[slot].y
		_gone.erase(slot)
		if not slot.is_human():
			match_node.take_back(slot, PlayerInput.new(device, seat))
		return


## The room played on, its menu put away: a bot at the wheel for each player whose pad is still
## gone, keeping the kart for that pad.
func play_on() -> void:
	var there := DeviceInput.pads()
	for slot: PlayerSlot in _waiting:
		var player := slot.input as PlayerInput
		if player == null or player.device != _waiting[slot] or player.device in there:
			continue
		_gone[slot] = Vector2i(player.device, player.seat)
		match_node.leave_human(slot)
	_waiting.clear()
