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
## says they are ready. When everybody has, the match begins and the room gives way to the arena.
##
## Online it is the room the connection is opened in, and the connection outlives it, see 10.3.
## The host seats everybody here and seats them again in the arena; a client drives in here, is
## told when the host leaves, and follows.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")

var match_node: Match
var ready_room: ReadyRoom
var config: MatchConfig
var session: NetSession


func _ready() -> void:
	config = Game.pending_config if Game.pending_config != null else MatchConfig.new()
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.power_ups = load("res://data/powerups/all.tres")
	add_child(match_node)
	match config.online:
		"host":
			_take_seats()
			_host()
		"join":
			_join()
		_:
			_take_seats()
	_dress_the_room()
	ready_room = ReadyRoom.add_to(match_node)
	if config.online != "join":
		ready_room.everybody_ready.connect(_begin, CONNECT_ONE_SHOT)
	DebugOverlay.add_to(self, match_node, session)
	PauseMenu.add_to(self, session)


## The people at this machine, and nobody else. Bots do not wait for anybody and cannot drive
## onto a pad to say they are ready, so they are left for the arena, where the host's confirmed
## number of them is added.
func _take_seats() -> void:
	var inputs: Array[KartInput] = []
	for device: int in config.human_devices:
		inputs.append(PlayerInput.new(device))
	if inputs.is_empty():
		inputs.append(PlayerInput.new())
	match_node.start(inputs, 0, config.colors(), config.names(), config.styles())


func _host() -> void:
	session = Net.open(match_node)
	var error := session.host(config.port)
	if error != OK:
		ready_room_hint("Could not host on port %d: %s" % [config.port, error_string(error)])
		return
	ready_room_hint("Friends join on port %d at %s" % [config.port, ", ".join(_local_addresses())])


func _join() -> void:
	session = Net.open(match_node)
	session.local_input = PlayerInput.new()
	session.player_name = config.human_names[0] if not config.human_names.is_empty() else ""
	session.match_beginning.connect(_follow_the_host, CONNECT_ONE_SHOT)
	session.disconnected.connect(func() -> void: Game.go_to_title())
	var error := session.join(config.address, config.port)
	if error != OK:
		Game.go_to_title()
		return
	match_node.start_puppet()


## Everybody is ready: through to the arena, with everybody who is here. The word goes out before
## this machine changes room, so the rooms change together rather than leaving a client driving
## round a lobby the host has already left.
func _begin() -> void:
	if session != null:
		session.begin_the_match()
	Game.start_match(config)


## The host has gone through. A client follows into the same arena; which one it is arrives on
## the wire with the rest of the rules, see 10.3.
func _follow_the_host() -> void:
	Game.start_match(config)


## What the room is dressed as: nothing is being played in it, so it is not dressed as a match.
## No crowd to watch a waiting room, no lights over it, no hoardings selling anything to nobody,
## and the camera holds the whole room rather than following anybody -- everybody in here is
## waiting on everybody else, so what has to be on screen is the pad and who is standing on it.
func _dress_the_room() -> void:
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	match_node.camera_rig.show_the_room(0.8)
	WaitingProps.add_to(match_node.arena)


## The line under the ready count that says how somebody at another machine gets in. Held until
## the room is built, since the room is what says it.
func ready_room_hint(words: String) -> void:
	if ready_room != null:
		ready_room.say_how_to_join(words)
		return
	await get_tree().process_frame
	if ready_room != null:
		ready_room.say_how_to_join(words)


## IPv4 addresses of this machine other than loopback, for the joining line.
func _local_addresses() -> PackedStringArray:
	var result: PackedStringArray = []
	for address: String in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127."):
			result.append(address)
	if result.is_empty():
		result.append("127.0.0.1")
	return result


## Pressing the join button on a device nobody is playing with adds that player, the same as it
## does in a match. This is the room that is for, so the HUD says so out loud.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.JOIN) or get_tree().paused:
		return
	if config.online == "join":
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if match_node.join_human(device) != null:
		get_viewport().set_input_as_handled()
