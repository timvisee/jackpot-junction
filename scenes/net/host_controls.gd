class_name HostControls
extends Node
## The host's say over its game, GAME.md 10.3: who else is in it, showing any of them out, and
## stopping the match for everybody at once rather than waiting for them all to ask. Lives under
## the [NetSession] at the same place on every machine, as a call from one to the other has to.
## Kept apart from [NetSession] so that file stays about the connection rather than the host.

## How long a kicked client has to hear why before the host lets go of it, in seconds.
const KICK_GRACE := 0.5

var session: NetSession
## On the host: whether it has stopped the match for everybody without waiting to be asked.
var forcing := false


static func of(owner: NetSession) -> HostControls:
	var made := HostControls.new()
	made.name = "Host"
	made.session = owner
	return made


## Everybody else in the host's game, for its Manage players, GAME.md 10.3: each client that plays,
## by the name and color of its seat, and each that watches, by the name it gave.
func guests() -> Array[Dictionary]:
	return session.door.guests(
		session.match_node, session._peer_slots.held, session._watchers, multiplayer
	)


## Shows [param peer] out of the game: told why, and let go of a moment later whatever it does
## with that, so it cannot stay by not listening. It may knock again. With [param number], one of
## several players at it, only that one goes, and the rest of them play on.
func kick(peer: int, number := -1) -> void:
	if not session.is_host or not multiplayer.get_peers().has(peer):
		return
	var held: Dictionary = session._peer_slots.held.get(peer, {})
	if number >= 0 and held.size() > 1 and held.has(number):
		session._empty_seat(peer, number)
		session._seat_dropped.rpc_id(peer, number)
		return
	_kicked.rpc_id(peer)
	get_tree().create_timer(KICK_GRACE).timeout.connect(_let_go_of.bind(peer))


func _let_go_of(peer: int) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.get_peers().has(peer):
		multiplayer.multiplayer_peer.disconnect_peer(peer)


@rpc("authority", "call_remote", "reliable")
func _kicked() -> void:
	session._turned_away = true
	session._hang_up.call_deferred("The host removed you from the game")


## The host stopping the match for everybody at once, GAME.md 3.8, rather than waiting for each
## of them to ask. It holds until the host lets go of it, which closing its menu does.
func force_pause(on: bool) -> void:
	if not session.is_host:
		return
	forcing = on
	session._settle_pause()
