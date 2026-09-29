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

## Where it hangs under [Net], at both ends.
const NAME := "Server"
## How long the two ends of a new connection have to agree on a version, in seconds.
const HANDSHAKE_TIMEOUT := 5.0

## At the server: the hall it is the wire of. Null at a player's machine.
var hall: ServerHall
## The version this end gives, the game's own unless a test says otherwise, and at a player's
## machine the name it gives, for the server's log.
var version := ""
var player_name := ""
## At a player's machine: the address of the server it knocked at, and the games it last listed.
var address := ""
var games: Array[Dictionary] = []

var _turned_away := false


func _ready() -> void:
	if version.is_empty():
		version = Game.version()
	var scene := multiplayer as SceneMultiplayer
	if scene != null:
		scene.auth_callback = _answer
		scene.auth_timeout = HANDSHAKE_TIMEOUT
		scene.peer_authenticating.connect(_knock)
	if hall != null:
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
	if hall == null and multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


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
	var words := {"version": version, "name": PlayerNames.clean(player_name)}
	(multiplayer as SceneMultiplayer).send_auth(peer, var_to_bytes(words))


## The server lets in anybody on a version it plays with and says which version it has; a player's
## end let in lets the server in, and one turned away says why.
func _answer(peer: int, data: PackedByteArray) -> void:
	var scene := multiplayer as SceneMultiplayer
	var said: Variant = bytes_to_var(data) if not data.is_empty() else null
	var words: Dictionary = said if said is Dictionary else {}
	var theirs := str(words.get("version", "?"))
	if hall != null:
		var playable := NetDoor.compatible(version, theirs)
		scene.send_auth(peer, var_to_bytes({"version": version, "welcome": playable}))
		hall.knocked(peer, PlayerNames.clean(str(words.get("name", ""))), theirs, playable)
		if playable:
			scene.complete_auth(peer)
		return
	if bool(words.get("welcome", false)):
		scene.complete_auth(peer)
		return
	_turned_away = true
	_give_up.call_deferred("Wrong version: the server has %s, you have %s" % [theirs, version])


func _give_up(reason: String) -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	refused.emit(reason)


@rpc("any_peer", "call_remote", "reliable")
func _make() -> void:
	if hall != null:
		hall.make_game(multiplayer.get_remote_sender_id())


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
