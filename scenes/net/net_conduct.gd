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
signal shown_out(peer: int, named: String, why: String)

## How many a client may send before it is shown out: more than one, in case a bug of the game's
## own ever sends one.
const KICK_AT := 3
## What everybody else is told after its name; the client itself is told [constant
## NetGuard.KICKED].
const TOLD := "%s was kicked: abnormal behavior detected"
## How many messages a second a client may send before it is flooding, and shown out: its players'
## controls, sixty a second for each of up to four, with the ball and its jokers, and three times
## that again. A hitch at the client runs a few ticks at once and no more, see the engine's most
## physics steps a frame, so an honest client comes nowhere near it.
const FLOOD := 1000
## How many of the messages a person sends by hand a client may send in a second before it is
## flooding, and shown out, see [method said]: a name, a dress, a plate, a color or a team, a seat,
## a pause, an emote, a say at a dedicated server. A client sends four or so for each of its seats
## as it sits down, and a person pressing as fast as they can sends ten a second at most, so an
## honest client comes nowhere near it; one that sent each as fast as the line takes them would
## have every other screen told of it as fast.
const SAYS := 60

var session: NetSession
## [constant FLOOD], unless a test says otherwise.
var flood := FLOOD
## [constant SAYS], unless a test says otherwise.
var says := SAYS
## How many there have been from anybody in this session, gone or not, for the checks that play the
## game to say there were none.
var total := 0
var _counts: Dictionary[int, int] = {}
## For each client: when its current second began, in engine milliseconds, and what it has sent in
## it, see [method spoke], and of what it sends by hand, see [method said].
var _second: Dictionary[int, Vector2i] = {}
var _said: Dictionary[int, Vector2i] = {}


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
	if count == KICK_AT:
		_show_out(peer, "sent abnormal state %d times" % count)


## At the host: [param peer] sent a message; past [constant FLOOD] of them in a second, it is
## flooding.
func spoke(peer: int) -> void:
	if _counted(peer, _second, flood):
		_show_out(peer, "more than %d messages in a second, flooding" % flood)


## At the host: [param peer] sent a message a person sends by hand, which counts as one it sent at
## all, see [method spoke]; past [constant SAYS] of them in a second, it is flooding.
func said(peer: int) -> void:
	spoke(peer)
	if _counted(peer, _said, says):
		_show_out(peer, "more than %d requests in a second, flooding" % says)


## At the host: [param peer] sent by hand, see [method said], what carries [param size] of what no
## copy of the game sends more than [param most] of, a name longer than a name may be, say, which
## is heard as such, see [method heard]. False for one that carried more, to go no further.
func said_within(peer: int, size: int, most: int) -> bool:
	said(peer)
	if size <= most:
		return true
	heard(peer)
	return false


## Counts one more from [param peer] in its current second in [param seconds]: true the moment it
## goes past [param most], once.
func _counted(peer: int, seconds: Dictionary[int, Vector2i], most: int) -> bool:
	if not session.is_host or peer <= 1:
		return false
	var now := Time.get_ticks_msec()
	var second: Vector2i = seconds.get(peer, Vector2i(now, 0))
	if now - second.x >= 1000:
		second = Vector2i(now, 0)
	second.y += 1
	seconds[peer] = second
	if second.y != most + 1:
		return false
	total += 1
	return true


## A client gone: its count goes with it.
func forget(peer: int) -> void:
	_counts.erase(peer)
	_second.erase(peer)
	_said.erase(peer)


## Shows [param peer] out for [param why]: it is told, everybody else sees it in the feed.
func _show_out(peer: int, why: String) -> void:
	var named := name_of(peer)
	shown_out.emit(peer, named, why)
	session.host_controls.kick(peer, -1, NetGuard.KICKED)
	Events.player_kicked.emit(named)


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
