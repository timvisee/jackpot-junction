class_name NetConduct
extends RefCounted
## What the host makes of a client that sends what no copy of the game sends, GAME.md 10.3: a word
## where a number goes, a number that is not one, a name that is not a name, a packet the wrong
## length. A connection, however bad, loses, delays, repeats and reorders what is sent, and never
## changes it: a datagram damaged on the way is dropped before anything reads it, a call that does
## not decode is refused by the engine before the game sees it, and every client let in plays the
## same version, see [NetHandshake]. So a client that sends one has been changed, and after
## [constant KICK_AT] of them it is shown out, told why, and everybody else is told too.
##
## What a slow line does is never counted: a claim the host does not follow, a packet too late to
## play, a pick that arrives after its pick has closed. Those are what an honest player on a bad
## connection sends, and they are simply not acted on.

## At the host, for a dedicated server's log: [param peer] sent what no copy of the game sends, the
## [param count]th time, and [param peer], called [param named], shown out for it.
signal heard_from(peer: int, count: int)
signal shown_out(peer: int, named: String)

## How many a client may send before it is shown out: more than one, in case a bug of the game's
## own ever sends one.
const KICK_AT := 3
## What the client shown out is told, and what everybody else is told after its name.
const KICKED := "Kicked: abnormal behavior detected"
const TOLD := "%s was kicked: abnormal behavior detected"

var session: NetSession
## How many there have been from anybody in this session, gone or not, for the checks that play the
## game to say there were none.
var total := 0
var _counts: Dictionary[int, int] = {}


func _init(of: NetSession) -> void:
	session = of


## At the host: [param peer] sent something no copy of the game sends.
func heard(peer: int) -> void:
	if not session.is_host or peer <= 1:
		return
	var count: int = _counts.get(peer, 0) + 1
	_counts[peer] = count
	total += 1
	heard_from.emit(peer, count)
	if count != KICK_AT:
		return
	var named := name_of(peer)
	shown_out.emit(peer, named)
	session.host_controls.kick(peer, -1, KICKED)
	Events.player_kicked.emit(named)


## A client gone: its count goes with it.
func forget(peer: int) -> void:
	_counts.erase(peer)


## What [param peer] is called: its first player's name, or for somebody watching, the name the host
## gave them.
func name_of(peer: int) -> String:
	var held: Dictionary = session._peer_slots.held.get(peer, {})
	var match_node := session.match_node
	for number: int in held:
		var index: int = held[number]
		if match_node != null and index >= 0 and index < match_node.slots.size():
			return match_node.slots[index].display_name()
	return session.door.names.get(peer, "Somebody")
