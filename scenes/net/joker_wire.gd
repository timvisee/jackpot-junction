class_name JokerWire
extends Node
## A client's joker choices on the wire, GAME.md 10.3: which card it took off a pick, or skipped,
## and which held card it gave up for it, and which card in its hand it dropped or destroyed, all
## by name. The host checks the pick dealt that card and the hand holds that one before it does
## anything, see [method JokerOffer.answer_with]. A client's controls never steer the host's own
## copy of its pick or its hand: a cursor walked by a stick is a cursor a late packet can leave a
## card short, and the card the player meant is the one under the cursor on their own screen.
##
## Under the session at both ends, as a call from one to the other has to be.

## At the host, for a word from a client that no copy of the game sends, see [NetConduct].
signal malformed(peer: int)

## How long a joker taken here is held against the host's word for it, see [method took_here].
const TAKEN_HEARD_MSEC := 2000

var session: NetSession
## On a client: jokers taken from a pick here, "slot|id" to when each time, see [method took_here].
var _taken_here: Dictionary[String, Array] = {}


func _init(of: NetSession) -> void:
	session = of
	name = "Jokers"


## At a client: everything [param seat]'s player chose since the last tick, sent in order.
func tell(seat: ClientSeat) -> void:
	for said: Array in seat.said:
		if multiplayer.is_server() or not _connected():
			break
		if said[0] == &"answer":
			_answered.rpc_id(1, seat.seat, said[1], said[2])
		else:
			_handled.rpc_id(1, seat.seat, said[0] == &"destroy", said[1])
	seat.said.clear()


@rpc("any_peer", "call_remote", "reliable")
func _answered(number: Variant, taken: Variant, replaced: Variant) -> void:
	if not _names(number, [taken, replaced]):
		return
	var slot := session.sender_slot(number)
	# A pick the host has closed since, at the whistle or by the deadline, is nothing to answer.
	if slot != null and slot.offer != null:
		slot.offer.answer_with(StringName(taken), StringName(replaced))


@rpc("any_peer", "call_remote", "reliable")
func _handled(number: Variant, destroy: Variant, id: Variant) -> void:
	if not _names(number, [id]):
		return
	if not destroy is bool:
		if multiplayer.is_server():
			malformed.emit(multiplayer.get_remote_sender_id())
		return
	var slot := session.sender_slot(number)
	# A dead kart's hand may be read, not changed, GAME.md 3.7.
	if slot == null or slot.kart == null or not slot.kart.alive:
		return
	var index := slot.kart.jokers.ids().find(StringName(id))
	if index < 0:
		return
	if destroy:
		slot.kart.destroy_joker(index)
	else:
		slot.kart.drop_joker(index)


## A joker taken from a pick by a player here, GAME.md 10.3: answered and heard on this machine at
## once, and noted, so the host's word for it a round trip later is not heard a second time.
func took_here(slot: int, joker: StringName) -> void:
	var match_node := session.match_node
	if NetSession._replaying or session.is_host or match_node == null:
		return
	if not match_node.is_local_seat(slot):
		return
	var key := "%d|%s" % [slot, String(joker)]
	if not _taken_here.has(key):
		_taken_here[key] = []
	_taken_here[key].append(Time.get_ticks_msec())


## Whether the host's word that [param slot] took [param joker] is one heard here already, as its
## player took it, see [method took_here]. Once for every time it was: the same card taken again
## later is heard again.
func heard_already(slot: int, joker: StringName) -> bool:
	var key := "%d|%s" % [slot, String(joker)]
	var times: Array = _taken_here.get(key, [])
	while not times.is_empty() and Time.get_ticks_msec() - int(times[0]) >= TAKEN_HEARD_MSEC:
		times.pop_front()
	if times.is_empty():
		_taken_here.erase(key)
		return false
	times.pop_front()
	return true


func _connected() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Whether a word from a client is a seat's number and names: what every copy of the game sends.
## Anything else is said to be malformed.
func _names(number: Variant, names: Array) -> bool:
	var fine := number is int
	for each: Variant in names:
		fine = fine and (each is StringName or each is String)
	if not fine and multiplayer.is_server():
		malformed.emit(multiplayer.get_remote_sender_id())
	return fine
