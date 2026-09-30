class_name BallWire
extends Node
## The waiting room's football on the wire, GAME.md 9.6: where the host says it is, to everybody,
## and where a client whose kart has just kicked it says it is, to the host, see [RoomBall]. Under
## the session at both ends, as a call from one to the other has to be.

## At a client: where the host says the ball is, and whose word that is.
signal told(state: Array)
## At the host: where the client [param peer] says the ball its kart kicked is.
signal claimed(peer: int, state: Array)


func _init() -> void:
	name = "Ball"


## From the host to everybody. Sent often and unreliably: a telling that goes missing is overtaken
## by the next.
func share(state: Array) -> void:
	if multiplayer.is_server() and _connected() and not multiplayer.get_peers().is_empty():
		_told.rpc(state)


## From a client that has the ball to the host, just as often and as unreliably.
func claim(state: Array) -> void:
	if not multiplayer.is_server() and _connected():
		_claimed.rpc_id(1, state)


func _connected() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


@rpc("authority", "call_remote", "unreliable_ordered")
func _told(state: Array) -> void:
	told.emit(state)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _claimed(state: Array) -> void:
	if multiplayer.is_server():
		claimed.emit(multiplayer.get_remote_sender_id(), state)
