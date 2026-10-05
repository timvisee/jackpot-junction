class_name LanBeacon
extends Node
## A host saying it is there to anybody looking for a game on the network, GAME.md 9.3. The Play
## LAN screen asks, about once a second, on [constant PORT] of every machine the network reaches
## and of its own; a host answers from there, to whoever asked, with what somebody choosing a game
## wants to know: what it is called and whose it is, whether it is still in the lobby or which map
## it is on, how many play in it and may, and whether it wants a password. Asking rather than
## calling out unasked is what lets several copies of the game on one machine all look: only the
## host has to have the port to itself.
##
## A second host on the same machine cannot have it, and is only reached by its address.

## Where hosts listen for somebody looking, apart from the port a game is played on.
const PORT := 7779
## What a question and an answer start with, so nothing else on the network is taken for either.
const QUESTION := "jackpot-junction?"
const ANSWER := "jackpot-junction!"

var session: NetSession
## The port the game itself is played on, which the answer gives.
var game_port := NetSession.DEFAULT_PORT
## Which beacon this is, so one answer heard twice, by the network and by this machine's own
## address, is one game in the list.
var id := 0

var _udp := PacketPeerUDP.new()


## A beacon for [param for_session], hosting on [param port], listening on [param listen].
static func open(for_session: NetSession, port: int, listen := PORT) -> LanBeacon:
	var beacon := LanBeacon.new()
	beacon.name = "LanBeacon"
	beacon.session = for_session
	beacon.game_port = port
	beacon.id = randi()
	if beacon._udp.bind(listen) != OK:
		push_warning("LAN games cannot be found on this machine: port %d is taken" % listen)
	for_session.add_child(beacon)
	return beacon


func _exit_tree() -> void:
	_udp.close()


func _process(_delta: float) -> void:
	while _udp.is_bound() and _udp.get_available_packet_count() > 0:
		var packet := _udp.get_packet()
		if packet.get_string_from_utf8() != QUESTION:
			continue
		_udp.set_dest_address(_udp.get_packet_ip(), _udp.get_packet_port())
		_udp.put_packet(var_to_bytes(answer()))


## What this game says about itself.
func answer() -> Dictionary:
	var match_node := session.match_node
	var host_name := ""
	if match_node != null:
		for slot: PlayerSlot in match_node.slots:
			if slot.is_local_human() and host_name.is_empty():
				host_name = slot.display_name()
	var playing := NetDoor.locals(match_node)
	for guest: Dictionary in session.host_controls.guests():
		playing += 1 if guest.has("color") else 0
	return {
		"game": ANSWER,
		"id": id,
		"name": host_name if not host_name.is_empty() else "Host",
		"title": session.door.listed_title(),
		"map": map_of(session),
		"version": session.version,
		"port": game_port,
		"players": playing,
		"most": session.door.max_players,
		"password": not session.door.password.is_empty(),
		"watching": session.door.watchers_allowed,
		"watch_password": session.door.watchers_locked(),
		"lobby": not session.in_arena,
	}


## The map [param session]'s room is on, with how far into a Grand Prix it is, "Crossfire, map 2 of
## 3", or nothing in the lobby: for the lists of games, and a dedicated server's log.
static func map_of(session: NetSession) -> String:
	var match_node := session.match_node if session != null else null
	if match_node == null or not session.in_arena:
		return ""
	var rules := match_node.rules
	var where := ArenaMaps.NAMES[ArenaMaps.index_of(rules.map)]
	if rules.rounds > 0:
		where += ", map %d of %d" % [rules.round, rules.rounds]
	return where
