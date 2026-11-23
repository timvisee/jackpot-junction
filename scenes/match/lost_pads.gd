class_name LostPads
extends Node
## A pad that goes while it is played on, GAME.md 4.2, out of battery or pulled out: the room's
## menu comes up for a player here holding it, as if they had pressed Pause, which stops the room
## played alone and asks for a stop online; and they keep their seat, the next pad that comes being
## theirs. They get up from their switch in the menu, should they mean to go. A pad nobody holds
## goes unremarked.

## The room's pause menus, [constant PauseMenu.GROUP] by name: the menu reaches far enough into the
## game to bring the match round again.
const PAUSE_MENUS := &"pause_menu"

var match_node: Match


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
	elif not holding(device).is_empty():
		for menu: Node in get_tree().get_nodes_in_group(PAUSE_MENUS):
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


## The pad [param device], just come, for the first player here whose own pad went; one that came
## back as itself is theirs already.
func hand(device: int) -> void:
	var there := DeviceInput.pads()
	for slot: PlayerSlot in match_node.slots:
		var player := slot.input as PlayerInput
		if player != null and player.device >= 0 and player.device not in there:
			player.device = device
			return
