class_name StartGate
extends RefCounted
## The lamps of a map held for whoever is still putting the room up, GAME.md 10.3.
##
## Everybody sets off for the next map together, but a machine that builds the room slower than
## the host does used to arrive to a countdown already running, or to a match already going. So
## the host waits for every client to say it has the room up. Not for ever: somebody on a slow
## machine, or one that has quietly stopped answering, holds up everybody else for at most
## [constant DEADLINE], and the lamps go anyway.

## The longest anybody is waited for, in seconds.
const DEADLINE := 15.0

## The clients still building the room, by peer id.
var waiting: Array[int] = []
## Everybody playing: the players at the host's own machine and one at each client's.
var players := 0
## How much longer they are waited for.
var left := DEADLINE


func _init(peers: PackedInt32Array, here: int) -> void:
	for peer: int in peers:
		waiting.append(peer)
	players = here + peers.size()


## [param peer] has the room up.
func arrived(peer: int) -> void:
	waiting.erase(peer)


## Runs the clock down, and stops waiting for anybody who is no longer connected: a player who
## left is not coming. True once there is nobody left to wait for, or no time.
func step(delta: float, connected: PackedInt32Array) -> bool:
	left -= delta
	for peer: int in waiting.duplicate():
		if peer not in connected:
			waiting.erase(peer)
			players -= 1
	return waiting.is_empty() or left <= 0.0


## How many have the room up, out of how many are playing.
func count() -> Vector2i:
	return Vector2i(players - waiting.size(), players)
