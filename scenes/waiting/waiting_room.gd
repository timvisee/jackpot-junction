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
## The rules the arena is built on, for how many seats it has.
const ARENA_RULES: MatchRules = preload("res://data/match/default.tres")

var match_node: Match
var ready_room: ReadyRoom
var config: MatchConfig
var session: NetSession
## The host's choice of match, null on any other machine.
var host_settings: HostSettings


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
	var menu := PauseMenu.add_to(self, session)
	if config.online == "host":
		_offer_the_settings(menu)
	elif config.online == "":
		# Chosen in the lobby on the way in, so the room only has to say what it was.
		Events.match_planned.emit(MatchOptions.describe(config), false)


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
	if Net.online():
		# Back from a match with everybody still connected, GAME.md 9.6. The same connection, a
		# different room: everybody who follows is seated in here as they ask.
		session = Net.session
		Net.attach(match_node)
		session.re_seat()
	else:
		session = Net.open(match_node)
		var error := session.host(config.port)
		if error != OK:
			ready_room_hint("Could not host on port %d: %s" % [config.port, error_string(error)])
			return
	ready_room_hint("Friends join on port %d at %s" % [config.port, ", ".join(_local_addresses())])


func _join() -> void:
	var back := Net.online()
	if back:
		# Followed the host back from a match: the connection is the one already open.
		session = Net.session
		Net.attach(match_node)
	else:
		session = Net.open(match_node)
		session.local_input = PlayerInput.new()
		session.player_name = config.human_names[0] if not config.human_names.is_empty() else ""
	session.match_beginning.connect(_follow_the_host, CONNECT_ONE_SHOT)
	session.disconnected.connect(func() -> void: Game.go_to_title())
	if not back:
		var error := session.join(config.address, config.port)
		if error != OK:
			Game.go_to_title()
			return
	match_node.start_puppet()
	if back:
		# Asked for rather than waited for: the host seats whoever asks once its room is up, and
		# this room is now up at this end to hear the answer.
		session.ready_for_seat()


## Everybody is ready: through to the arena, with everybody who is here. The word goes out before
## this machine changes room, so the rooms change together rather than leaving a client driving
## round a lobby the host has already left.
func _begin() -> void:
	var first := first_map_config()
	if session != null:
		session.begin_the_match()
	Game.start_match(first)


## What the first map is built from: [method arena_config], and for Play the Grand Prix dealt
## now that everybody playing it is here, GAME.md 9.7, with the first of its maps.
func first_map_config() -> MatchConfig:
	var first := arena_config()
	Game.grand_prix = null
	if first.rounds > 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		Game.grand_prix = GrandPrix.start(first.rounds, rng)
		first.map = Game.grand_prix.current_map()
		# And its bots, once: the same ones drive every map of it.
		Game.grand_prix.deal_bots(
			load("res://data/ai/traits.tres"), first.network_seats + first.bot_count, rng
		)
	return first


## The host chooses the match in here, GAME.md 9.6: first thing on opening the room, and again
## from the pause menu. The room is open the whole time, so friends join while it is chosen.
func _offer_the_settings(menu: PauseMenu) -> void:
	host_settings = HostSettings.add_to(self)
	host_settings.closed.connect(_chosen)
	menu.add_entry("Match settings", choose)
	Events.player_joined.connect(_on_player_joined)
	choose()


## Opens the choosing. The host's own karts wait where they are while it is open: the controls
## are working the menu, and a kart that drove off on them would be a kart nobody was driving.
func choose() -> void:
	host_settings.open()
	_hold(true)
	_say_the_plan()


## Held for as long as the choosing is open rather than once when it opens: the room opens it on
## the first frame, before the match has finished starting, and a match that starts lets every
## kart go.
func _process(_delta: float) -> void:
	if host_settings != null and host_settings.is_open():
		_hold(true)


func _chosen() -> void:
	host_settings.options.apply_to(config)
	_hold(false)
	_say_the_plan()


func _hold(held: bool) -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human() and slot.kart != null:
			slot.kart.frozen = held


## Tells the room what the next match is, or that it is still being chosen. The host's own room
## hears it the same way the clients' rooms do.
func _say_the_plan() -> void:
	Events.match_planned.emit(MatchOptions.describe(config), host_settings.is_open())


## Somebody arrived. They were not here to hear the plan the first time, so it is said again.
func _on_player_joined(_slot: int) -> void:
	_say_the_plan()


## What the arena is built from: the configuration the room was opened with, and everybody at
## this machine as the room has them now. A seat taken in here is as much a part of the match as
## the one that came in through the door, and the arena keeps the colour, the name and the dress
## each of them had in the room rather than handing out new ones on the way across.
func arena_config() -> MatchConfig:
	var devices: Array[int] = []
	var colors: Array[int] = []
	var names: Array[String] = []
	var styles: Array = []
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_local_human():
			continue
		devices.append(slot.device())
		colors.append(slot.color_index)
		names.append(slot.player_name)
		styles.append(slot.style.to_array())
	if not devices.is_empty():
		config.human_devices = devices
		config.human_colors = colors
		config.human_names = names
		config.human_styles = styles
	# Everybody connected from elsewhere is kept a seat, in the colour they had in here and in the
	# order the host will seat them again, and the bots the host asked for are on top of everybody
	# here, as many of them as the arena has seats left for.
	var kept: Array[int] = []
	if session != null:
		for index: int in session.peer_seats():
			if index < match_node.slots.size():
				kept.append(match_node.slots[index].color_index)
	var remote := kept.size()
	config.network_seats = remote
	config.network_colors = kept
	var free := ARENA_RULES.max_players - config.human_devices.size() - remote
	config.bot_count = clampi(config.bot_count, 0, maxi(free, 0))
	return config


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
## does in a match, and heard first for the same reason: a pad's join button is its pause button,
## and a pad nobody is driving pressing it is somebody sitting down. This is the room that is for,
## so the HUD says so out loud.
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.JOIN) or get_tree().paused:
		return
	if config.online == "join":
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if match_node.join_human(device) != null:
		get_viewport().set_input_as_handled()
