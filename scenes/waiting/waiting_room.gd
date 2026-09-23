extends Node3D
## The room everybody waits in before a match, GAME.md 9.6.
##
## A match needs everybody at the table before it can start, and a menu is a poor place to wait:
## there is nothing to do in one and no way to tell whether the person who has not pressed
## anything yet is thinking or has walked off. So the waiting is done in a room. It is the corner
## of the garage of 9.4, the same concrete bay with the same light, a pad in the middle of it and
## three things to drift round while the last player finds their seat.
##
## Nothing is scored in here. There is no clock, nothing to shoot and nothing to collect: the only
## thing the room asks of anybody is that they drive onto the pad and stay on it, which is what
## says they are ready. When everybody has, the match begins.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")

var match_node: Match
var ready_room: ReadyRoom


func _ready() -> void:
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.power_ups = load("res://data/powerups/all.tres")
	add_child(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new()]
	match_node.start(inputs, 0, [], [], [Game.settings.kart_styles[0]])
	# Nothing is being played, so the room is not dressed as a match: no crowd to watch a waiting
	# room, no lights over it and no hoardings selling anything to nobody.
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	# The room is held whole rather than followed. Everybody in here is waiting on everybody
	# else, so what the camera has to show is the pad and who is standing on it, not whichever
	# kart this machine happens to be driving.
	match_node.camera_rig.show_the_room(0.8)
	WaitingProps.add_to(match_node.arena)
	ready_room = ReadyRoom.add_to(match_node)
	DebugOverlay.add_to(self, match_node)
	PauseMenu.add_to(self)


## Pressing the join button on a device nobody is playing with adds that player, the same as it
## does in a match. This is the room that is for, so the HUD says so out loud.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.JOIN) or get_tree().paused:
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if match_node.join_human(device) != null:
		get_viewport().set_input_as_handled()
