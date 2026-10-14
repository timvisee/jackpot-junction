class_name NetPing
extends Node
## How long the line to each client takes there and back, GAME.md 10.3, so a player on a slow one
## is warned of it: in their own corner of the HUD, and beside their name in the running order on
## every screen, the host's included. The host knocks on each client twice a second and times the
## answer, and puts the time on the seats that client holds, see [member PlayerSlot.round_trip];
## it goes out with the rest of each player in the snapshot, so every list says the same.
##
## Lives under the [NetSession] at the same place on every machine, as a call from one to the
## other has to.

## Seconds between two knocks, how far a new time moves the one kept towards it, and the round trip,
## in milliseconds, past which a line is too slow to play on without being told so. A tenth of a
## second there and back is already a lot for a game this quick, well before the point where
## pickups taken at speed start to blink out rather than fly, see GAME.md 10.3.
const EVERY := 0.5
const SETTLE := 0.3
const SLOW := 100.0
## Past this an answer is not believed, being more likely made up than that slow.
const MOST := 60000.0

## Each client's round trip in milliseconds, settled over the last few answers.
var _round_trips: Dictionary[int, float] = {}
## When the oldest knock to each client still unanswered went, in microseconds.
var _waiting: Dictionary[int, int] = {}
var _next := 0.0


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_forget)


func _process(delta: float) -> void:
	var session := get_parent() as NetSession
	if session == null or not session.is_host or multiplayer.multiplayer_peer == null:
		return
	_next -= delta
	if _next > 0.0:
		return
	_next = EVERY
	var now := Time.get_ticks_usec()
	for peer: int in multiplayer.get_peers():
		if not _waiting.has(peer):
			_waiting[peer] = now
		_knock.rpc_id(peer, now)
	_mark_seats(session)


## Milliseconds there and back to [param peer]: what the last answers took, or as long as the
## oldest knock has gone unanswered if that is longer, since a line gone quiet is at least as slow
## as the wait for it.
func round_trip(peer: int) -> float:
	var trip: float = _round_trips.get(peer, 0.0)
	if _waiting.has(peer):
		trip = maxf(trip, (Time.get_ticks_usec() - _waiting[peer]) / 1000.0)
	return trip


## Puts each client's round trip on the seats it holds, and none on the rest: the host's own
## players, and the bots, are at the host.
func _mark_seats(session: NetSession) -> void:
	var match_node := session.match_node
	if match_node == null:
		return
	for slot: PlayerSlot in match_node.slots:
		slot.round_trip = 0.0
	for peer: int in session._peer_slots.held:
		var trip := round_trip(peer)
		for number: int in session._peer_slots.held[peer]:
			var index: int = session._peer_slots.held[peer][number]
			if index < match_node.slots.size():
				match_node.slots[index].round_trip = trip


func _forget(peer: int) -> void:
	_round_trips.erase(peer)
	_waiting.erase(peer)


@rpc("authority", "call_remote", "unreliable")
func _knock(sent: int) -> void:
	_answer.rpc_id(1, sent)


@rpc("any_peer", "call_remote", "unreliable")
func _answer(sent: int) -> void:
	var peer := multiplayer.get_remote_sender_id()
	var session := get_parent() as NetSession
	if session != null:
		session.conduct.spoke(peer)
	var trip := (Time.get_ticks_usec() - sent) / 1000.0
	if trip < 0.0 or trip > MOST:
		return
	_round_trips[peer] = lerpf(_round_trips.get(peer, trip), trip, SETTLE)
	_waiting.erase(peer)
