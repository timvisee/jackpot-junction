class_name NetHandshake
extends RefCounted
## The first thing said on a new connection, GAME.md 10.3, before anything else is let through: a
## client knocks with its version, whether it has come to watch, its name and its password, and the
## host's [NetDoor] answers whether it may come in and why not. Kept apart from [NetSession] so that
## file stays about the room.

var session: NetSession


static func of(owner: NetSession) -> NetHandshake:
	var made := NetHandshake.new()
	made.session = owner
	return made


## A new connection. The client opens by saying who it is; the host waits to hear it.
func knock(peer: int) -> void:
	if session.is_host:
		return
	var words := NetDoor.knock(
		session.version, session.watching, PlayerNames.clean(session.player_name), session.password
	)
	(session.multiplayer as SceneMultiplayer).send_auth(peer, var_to_bytes(words))


## The other end of it. The host answers every client with its own version and whether it can come
## in, which it can on a version this one plays with and with a seat for it; a client turned away is
## left to run out of [constant NetSession.HANDSHAKE_TIMEOUT], which drops it, so a client too old
## to understand the answer still goes. A client that is let in lets the host in; one that is not
## says why.
func answer(peer: int, data: PackedByteArray) -> void:
	var scene := session.multiplayer as SceneMultiplayer
	var words: Dictionary = {}
	if session.is_host:
		# Garbage, or a second hello, is dropped there and then, see [NetGuard].
		words = session.guard.heard(peer, data)
		if words.is_empty():
			return
	else:
		var said: Variant = bytes_to_var(data) if not data.is_empty() else null
		words = said if said is Dictionary else {}
	if session.is_host:
		if bool(words.get(ServerLink.LISTING, false)):
			# Play Online, looking for a server's list at a game's port.
			var named := PlayerNames.clean(str(words.get("name", "")))
			session.door.turned_away.emit(named, "Came from Play Online, looking for a server")
			scene.send_auth(peer, var_to_bytes({"version": session.version, "game": true}))
			return
		var match_node := session.match_node
		var players := session._player_peers().size()
		# Full is only known while there is a room to be full: between rooms nobody is refused.
		var room := {
			"no_seat":
			session._room_up and match_node != null and not SeatLimit.has_seat(match_node),
			"players": players,
			"clients": NetDoor.clients(session.dedicated),
			"humans": SeatLimit.players(match_node) if match_node != null else players,
			"watchers": session._watchers.size(),
			"match": match_node,
		}
		var answered := session.door.answer(session.version, peer, words, room)
		scene.send_auth(peer, var_to_bytes(answered))
		if answered["welcome"]:
			if answered["watch"]:
				session._watchers[peer] = true
			scene.complete_auth(peer)
		return
	if bool(words.get("welcome", false)):
		scene.complete_auth(peer)
		return
	session._turned_away = true
	# After the handshake has returned rather than inside it: hanging up in the middle of the
	# peer's own poll pulls the connection out from under it.
	if NetDoor.wants_password(session.version, words):
		session._hang_up.call_deferred("", str(words["locked"]) == NetDoor.WRONG)
	else:
		session._hang_up.call_deferred(NetDoor.refusal(session.version, words))
