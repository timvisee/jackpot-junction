class_name DemoHand
extends Node
## Hears every press in the room before the room does, GAME.md 9.8: kept the last thing in it,
## which is the first to hear, see [DemoHost]. A press that sits somebody down is theirs and nobody
## else's: not a shot, not the join of a map and not the pause a pad's Start would otherwise be.

var host: DemoHost


static func add_to(room: Node, for_host: DemoHost) -> DemoHand:
	var hand := DemoHand.new()
	hand.name = "DemoHand"
	hand.host = for_host
	room.add_child(hand)
	return hand


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if host != null and host.heard(event, get_parent()):
		get_viewport().set_input_as_handled()
