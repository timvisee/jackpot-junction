class_name ServerGame
extends Node
## One game of a dedicated server, GAME.md 9.3a, in the process the server started it in: hosted
## with nobody at it, from the waiting room on, for as long as anybody plays in it. It tells the
## server how it stands and everything worth a line in the server's log, and ends its process once
## everybody playing has left, or once nobody has come at all.
##
## Kept at the root rather than in a room, since it outlives every one of them, the way the
## connection does, see [Net].

## Seconds between two reports when nothing has changed, which also tell the server the game is
## still there.
const REPORT_EVERY := 1.0
## Seconds the game waits for its first player, whoever asked for it, before giving up on them.
const FIRST_WAIT := 30.0
## Seconds without a word from the server before the game takes it as gone, and goes too.
const ORPHAN_WAIT := 10.0
## Seconds between telling anybody still in it that it is over and going, for the word to get out.
const LAST_WORDS := 1.0
## Seconds a room has to be up and hosting before the game gives up on it.
const HOSTING_WAIT := 15.0

var args: ServerArgs
## [constant FIRST_WAIT] and [constant ORPHAN_WAIT], unless a test says otherwise.
var first_wait := FIRST_WAIT
var orphan_wait := ORPHAN_WAIT
## Opens the first room, and ends the process: the game's own, unless a test says otherwise.
var open_room: Callable = Game.go_to_waiting
var finish: Callable = _quit

var _socket := PacketPeerUDP.new()
## The session being watched for the log, once the room has opened one.
var _session: NetSession
var _up := false
var _had_players := false
var _closing := -1.0
var _since_start := 0.0
var _unheard := 0.0
var _report_left := 0.0
## What the server was last told of how the game stands, to tell it again only on a change or
## once a second.
var _told := {}
## Who each client said they were as they came in, kept for the line saying they went.
var _names: Dictionary[int, String] = {}
## The match the log last described the room of, and the host's name as it last was.
var _room: Match
var _host_name := ""


func _ready() -> void:
	# On while the room is stopped, which it is by itself once the last player has left it, see
	# [method NetSession._settle_pause]: that is exactly when there is something to do here.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_socket.bind(0, "127.0.0.1")
	_socket.set_dest_address("127.0.0.1", args.report)
	# How far along it is, for whoever asked for it, see [constant ServerLink.MAKING_STARTED].
	_send({"making": ServerLink.MAKING_BOOTED})
	Events.room_building.connect(_on_room_building)
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "host"
	config.dedicated = true
	config.human_devices = [] as Array[int]
	config.human_names = [] as Array[String]
	config.human_styles = []
	config.port = args.port
	config.server_password = args.password
	open_room.call(config)


func _exit_tree() -> void:
	_socket.close()


## A line for the server's log.
func say(text: String) -> void:
	_send({"log": text})


func _on_room_building(done: float) -> void:
	if not _up:
		_send({"making": lerpf(ServerLink.MAKING_BOOTED, ServerLink.MAKING_BUILT, done)})


func _process(delta: float) -> void:
	_since_start += delta
	# The server answers once it has heard from the game, which is once the game is up: a room slow
	# to put up is not a server gone quiet.
	if _up:
		_unheard += delta
	_hear_the_server()
	if _closing >= 0.0:
		_closing -= delta
		if _closing < 0.0:
			finish.call()
		return
	if _unheard > orphan_wait:
		_over("Lost the server, so the game is over")
		return
	_watch(Net.session)
	if not _up:
		if _session != null and _session.is_host:
			_up = true
			say("Up on port %d" % args.port)
		elif _since_start > HOSTING_WAIT:
			_over("Could not host on port %d" % args.port)
			return
	var players := _players()
	_had_players = _had_players or players > 0
	if _up and _had_players and players == 0:
		_over("Everybody left, so the game is over")
		return
	if _up and not _had_players and _since_start > first_wait:
		_over("Nobody came, so the game is over")
		return
	_describe_the_room()
	_report(delta)


func _hear_the_server() -> void:
	while _socket.get_available_packet_count() > 0:
		var said: Variant = bytes_to_var(_socket.get_packet())
		if said is Dictionary and (said as Dictionary).has("alive"):
			_unheard = 0.0


## How the game stands, for the server's list: what it is called and whose it is, which map it is
## on, how many play and may, and the rest a found LAN game says, see [method ServerHall.listing].
## Sent on a change, and once a second.
func _report(delta: float) -> void:
	if not _up:
		return
	var state := _state()
	_report_left -= delta
	if state == _told and _report_left > 0.0:
		return
	_told = state
	_report_left = REPORT_EVERY
	_send({"state": state})


func _state() -> Dictionary:
	var door := _session.door
	return {
		"name": _host(),
		"title": door.listed_title(),
		"map": LanBeacon.map_of(_session),
		"players": _players(),
		"most": door.max_players,
		"password": not door.password.is_empty(),
		"watching": door.watchers_allowed,
		"watch_password": door.watchers_locked(),
		"lobby": not _session.in_arena,
		"watchers": _session._watchers.size(),
	}


## How many play in the game: its seats taken by people, or while the room is changing and nobody
## is seated yet, the clients connected to play.
func _players() -> int:
	if _session == null or not _session.is_host:
		return 0
	var peers := _session._player_peers().size()
	if peers == 0:
		return 0
	var match_node := _session.match_node
	var seated := SeatLimit.players(match_node) if match_node != null else 0
	return maxi(seated, peers)


## The name of whoever has the host's say, as their seat has it, or as they gave it at the door.
func _host() -> String:
	var peer := _session.host_controls.peer
	if peer == 0:
		return _host_name
	var match_node := _session.match_node
	var seats: Dictionary = _session._peer_slots.held.get(peer, {})
	for number: int in seats:
		var index: int = seats[number]
		if match_node != null and index < match_node.slots.size():
			_host_name = match_node.slots[index].display_name()
			return _host_name
	if _host_name.is_empty():
		_host_name = _names.get(peer, "")
	return _host_name


## The game is over: said, anybody still in it told, and the process gone a moment later.
func _over(why: String) -> void:
	say(why)
	if _session != null:
		_session.host_controls.end_the_game(why)
	_send({"over": true})
	_closing = LAST_WORDS


func _quit() -> void:
	Game.quit()


func _send(words: Dictionary) -> void:
	words["game"] = args.game
	words["key"] = args.key
	_socket.put_packet(var_to_bytes(words))


## Starts writing down what happens in [param session], the first time it is seen.
func _watch(session: NetSession) -> void:
	if session == null or session == _session:
		return
	_session = session
	session.multiplayer.peer_connected.connect(_on_came)
	session.multiplayer.peer_disconnected.connect(_on_went)
	session.door.turned_away.connect(
		func(named: String, why: String) -> void: say("Turned away %s: %s" % [_named(named), why])
	)
	session.host_controls.changed_hands.connect(_on_hands_changed)
	session.host_controls.planned.connect(_on_planned)
	session.host_controls.door_set.connect(_on_door_set)
	session.host_controls.kicked.connect(
		func(player: int) -> void: say("The host showed %s out" % _names.get(player, "somebody"))
	)
	session.conduct.heard_from.connect(
		func(peer: int, count: int) -> void:
			say("%s sent abnormal state (%d/%d)" % [_name_of(peer), count, NetConduct.KICK_AT])
	)
	session.conduct.shown_out.connect(
		func(peer: int, named: String, why: String) -> void:
			say("Kicked %s, from %s: %s" % [_named(named), _address_of(peer), why])
	)
	session.guard.dropped.connect(
		func(address: String, why: String) -> void: say("Dropped %s: %s" % [address, why])
	)
	session.host_controls.handed.connect(
		func(player: int) -> void:
			var from := _name_of(session.host_controls.peer)
			say("%s made %s the host" % [from, _name_of(player)])
	)
	Events.match_state_changed.connect(_on_state_changed)


func _on_came(peer: int) -> void:
	var named := _name_of(peer)
	_names[peer] = named
	var to := "watch" if _session._watchers.has(peer) else "play"
	say("%s came in to %s, from %s" % [named, to, _address_of(peer)])


func _on_went(peer: int) -> void:
	say("%s left" % _names.get(peer, "Somebody"))
	_names.erase(peer)


## Said after whatever else the connection coming or going has to say: the say passes as somebody
## arrives or leaves, and they are said to first.
func _on_hands_changed(player: int) -> void:
	if player == 0:
		say.call_deferred("Nobody has the host's say")
		return
	say.call_deferred("%s has the host's say" % _name_of(player))


func _on_planned(plan: Dictionary, still_choosing: bool) -> void:
	if still_choosing:
		return
	var chosen := MatchConfig.new()
	MatchOptions.from_wire(chosen, plan)
	var bots := "%d bot%s" % [chosen.bot_count, "" if chosen.bot_count == 1 else "s"]
	say("The host chose the next match: %s, %s asked for" % [MatchOptions.describe(chosen), bots])


func _on_door_set() -> void:
	var door := _session.door
	var watching := "watchers allowed" if door.watchers_allowed else "no watchers"
	if door.watchers_allowed and not door.watchers_locked() and not door.password.is_empty():
		watching = "watchers allowed without it"
	var words: PackedStringArray = [
		"%d players" % door.max_players,
		"a password" if not door.password.is_empty() else "no password",
		watching,
	]
	if not door.title.is_empty():
		words.insert(0, 'named "%s"' % door.title)
	say("Lobby settings: %s" % ", ".join(words))


## A new room, the lobby or a map, said as it is taken over.
func _describe_the_room() -> void:
	var match_node := _session.match_node if _session != null else null
	if match_node == null or match_node == _room:
		return
	_room = match_node
	if not _session.in_arena:
		say("In the lobby")
		return
	say("Onto %s" % LanBeacon.map_of(_session))


func _on_state_changed(state: int) -> void:
	if _session == null or not _session.in_arena or _session.match_node == null:
		return
	match state:
		Match.State.PLAYING:
			say("Playing: %s" % ServerLog.listed(_everybody()))
		Match.State.LAST_CALL:
			say("Last call")
		Match.State.OVERTIME:
			say("Overtime")
		Match.State.RESULTS:
			say("Results: %s" % _results())


## Everybody in the match, the people first and then the bots, by the name the room shows.
func _everybody() -> Array[String]:
	var people: Array[String] = []
	var bots := 0
	for slot: PlayerSlot in _session.match_node.slots:
		if slot.is_human():
			people.append(slot.display_name())
		else:
			bots += 1
	if bots > 0:
		people.append("%d bot%s" % [bots, "" if bots == 1 else "s"])
	return people


func _results() -> String:
	var places: PackedStringArray = []
	var rank := 1
	for slot: PlayerSlot in _session.match_node.standings():
		places.append("%d. %s %d" % [rank, slot.display_name(), slot.banked])
		rank += 1
	return ", ".join(places)


func _named(given: String) -> String:
	return given if not given.is_empty() else "Somebody"


## What [param peer] is called here: what they said at the door, known before they are all the way
## in.
func _name_of(peer: int) -> String:
	if _names.has(peer):
		return _names[peer]
	return _named(_session.door.names.get(peer, ""))


func _address_of(peer: int) -> String:
	var enet := NetLag.enet(_session.multiplayer.multiplayer_peer)
	var connection := enet.get_peer(peer) if enet != null else null
	return connection.get_remote_address() if connection != null else "somewhere"
