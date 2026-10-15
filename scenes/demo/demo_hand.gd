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
	# Taken before the press is heard: one that deals the next run from the title changes the room,
	# which takes this out of the tree there and then, and out of its viewport with it.
	var viewport := get_viewport()
	if host != null and host.heard(event, get_parent()):
		viewport.set_input_as_handled()
