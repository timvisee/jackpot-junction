class_name ServerLink
extends Node
## The wire between the Play Online screen and a dedicated server, GAME.md 9.3a: the games the
## server holds, and a new one made there. Joining one is a connection of its own, straight to that
## game, the way a LAN game is joined: this is only the list and the making.
##
## The server's hall has one listening, a player's screen one knocking, and it lives at the same
## place at both, under [Net], as a call from one to the other has to. Like a game's own
## connection, it starts with each end saying its version, and a server this game cannot play with
## says so rather than listing games nobody here could join.

## At a player's machine: through the server's door, turned away at it with [param reason], or
## never answered; and later, the server gone.
signal connected
signal refused(reason: String)
signal failed
signal lost
## At a player's machine: the games the server lists now, see [method ServerHall.listing].
signal listed(games: Array[Dictionary])
## At a player's machine: the game it asked for is up and waiting for it on [param port], or it
## could not be made, and [param reason] says why.
signal made(port: int)
signal not_made(reason: String)
## At a player's machine: how far along the game it asked for is, from 0 to 1, see [constant
## MAKING_STARTED].
signal making(done: float)

## Where it hangs under [Net], at both ends.
const NAME := "Server"
## What a knock asking for a server's list says it is, so that a game knocked at the same way, a
## LAN game on the port a server would have, says it is a game rather than seating a list.
const LISTING := "list"
## How long the two ends of a new connection have to agree on a version, in seconds.
const HANDSHAKE_TIMEOUT := 5.0
## How far along a game being made is, GAME.md 9.3a: its process started by the server, running
## its first frame, and its waiting room built, with the rest the room opening its door. Weighted
## by how long each part takes: about 1.3, 0.45 and 0.15 seconds of 1.9 on a desktop, the engine
## starting up in the new process being most of it.
const MAKING_STARTED := 0.05
const MAKING_BOOTED := 0.65
const MAKING_BUILT := 0.92
## How many games a visitor may ask for in a second before it is flooding, and shown out: a player
## presses Make a game once, and the hall makes one game each at a time anyway.
const MAKES_A_SECOND := 10

## At the server: the hall it is the wire of. Null at a player's machine.
var hall: ServerHall
## The version this end gives, the game's own unless a test says otherwise, and at a player's
## machine the name it gives, for the server's log.
var version := ""
var player_name := ""
## At a player's machine: the address and port of the server it knocked at, and the games it last
## listed.
var address := ""
var port := 0
var games: Array[Dictionary] = []
## At the server: the door before anybody is let in to look, see [NetGuard].
var guard: NetGuard

var _turned_away := false
## At the server: when each visitor last asked for games, in the last second.
var _asked: Dictionary[int, Array] = {}


func _ready() -> void:
	if version.is_empty():
		version = GameVersion.current()
	var scene := multiplayer as SceneMultiplayer
	if scene != null:
		scene.auth_callback = _answer
		scene.auth_timeout = HANDSHAKE_TIMEOUT
		scene.peer_authenticating.connect(_knock)
	if hall != null:
		guard = NetGuard.new(multiplayer)
		guard.dropped.connect(hall.dropped)
		if scene != null:
			scene.peer_authenticating.connect(guard.came)
			scene.peer_authentication_failed.connect(guard.timed_out)
		multiplayer.peer_connected.connect(guard.settled)
		multiplayer.peer_disconnected.connect(guard.settled)
		multiplayer.peer_disconnected.connect(func(peer: int) -> void: _asked.erase(peer))
		multiplayer.peer_connected.connect(hall.visitor_came)
		multiplayer.peer_disconnected.connect(hall.visitor_left)
		return
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(
		func() -> void:
			if not _turned_away:
				failed.emit()
	)
	multiplayer.server_disconnected.connect(
		func() -> void:
			if not _turned_away:
				lost.emit()
	)


func _exit_tree() -> void:
	var scene := multiplayer as SceneMultiplayer
	if scene != null and scene.auth_callback == _answer:
		scene.auth_callback = Callable()
	if scene != null and scene.peer_authenticating.is_connected(_knock):
		scene.peer_authenticating.disconnect(_knock)
	if hall == null:
		# Closed now and taken off a frame later, see [NetPeer].
		NetPeer.let_go(multiplayer, multiplayer.multiplayer_peer)


## At a player's machine: knocks at the server at [param at], on [param port].
func reach(at: String, port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(at, port)
	if error != OK:
		return error
	NetLine.compress(peer)
	var server := peer.get_peer(1)
	if server != null:
		NetLine.trying(server)
	multiplayer.multiplayer_peer = peer
	address = at
	self.port = port
	_turned_away = false
	return OK


## At a player's machine: asks the server to make a game for it, see [signal made].
func make_game() -> void:
	if _talking():
		_make.rpc_id(1)


func _talking() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _on_connected() -> void:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet != null and enet.get_peer(1) != null:
		NetLine.made(enet.get_peer(1))
	connected.emit()


## A new connection: the player's end says who it is, and the server waits to hear it.
func _knock(peer: int) -> void:
	if hall != null:
		return
	var words := {"version": version, "name": PlayerNames.clean(player_name), LISTING: true}
	(multiplayer as SceneMultiplayer).send_auth(peer, var_to_bytes(words))


## The server lets in anybody on a version it plays with and says which version it has; a player's
## end let in lets the server in, and one turned away says why.
func _answer(peer: int, data: PackedByteArray) -> void:
	var scene := multiplayer as SceneMultiplayer
	var words: Dictionary = {}
	if hall != null:
		# Garbage, or a second hello, is dropped there and then, see [NetGuard].
		words = guard.heard(peer, data)
		if words.is_empty():
			return
	else:
		var said: Variant = bytes_to_var(data) if not data.is_empty() else null
		words = said if said is Dictionary else {}
	var theirs := str(words.get("version", "?"))
	if hall != null:
		# Knocked at from Play LAN, which hosts on the same port: told this is a server, see
		# [method NetDoor.refusal], rather than let in to wait for a seat nobody here hands out.
		var listing := bool(words.get(LISTING, false))
		var playable := listing and GameVersion.compatible(version, theirs)
		var answer := {"version": version, "welcome": playable, "server": not listing}
		scene.send_auth(peer, var_to_bytes(answer))
		hall.knocked(peer, PlayerNames.clean(str(words.get("name", ""))), theirs, playable, listing)
		if playable:
			scene.complete_auth(peer)
		return
	if bool(words.get("welcome", false)):
		scene.complete_auth(peer)
		return
	_turned_away = true
	var why := "Wrong version: the server has %s, you have %s" % [theirs, version]
	if bool(words.get("game", false)):
		why = "That is a game rather than a server: join it from Play LAN"
	_give_up.call_deferred(why)


func _give_up(reason: String) -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	refused.emit(reason)


@rpc("any_peer", "call_remote", "reliable")
func _make() -> void:
	if hall == null:
		return
	var peer := multiplayer.get_remote_sender_id()
	var now := Time.get_ticks_msec()
	var times: Array = _asked.get(peer, [])
	while not times.is_empty() and now - int(times[0]) >= 1000:
		times.pop_front()
	times.append(now)
	_asked[peer] = times
	if times.size() > MAKES_A_SECOND:
		if times.size() == MAKES_A_SECOND + 1:
			hall.show_out(peer, "%d games asked for in a second, flooding" % times.size())
		return
	hall.make_game(peer)


## At a player's machine: the server has shown this machine out, and [param why] is what it said.
@rpc("authority", "call_remote", "reliable")
func _shown_out(why: String) -> void:
	_turned_away = true
	_give_up.call_deferred(why)


## At a player's machine: the games as the server lists them, each as a found LAN game is, see
## [method ServerHall.listing]. Anything that is not one is left out.
@rpc("authority", "call_remote", "reliable")
func _games_are(listing: Array) -> void:
	games.clear()
	for game: Variant in listing:
		if game is Dictionary and (game as Dictionary).has("port"):
			games.append(game)
	listed.emit(games)


@rpc("authority", "call_remote", "reliable")
func _made(port: int) -> void:
	made.emit(port)


@rpc("authority", "call_remote", "reliable")
func _not_made(reason: String) -> void:
	not_made.emit(reason)


@rpc("authority", "call_remote", "reliable")
func _making(done: float) -> void:
	making.emit(clampf(done, 0.0, 1.0))
