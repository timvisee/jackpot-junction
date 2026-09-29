class_name NetLag
extends MultiplayerPeerExtension
## A connection made slower on purpose, GAME.md 10.3: what a machine hears is held for a while
## before it is let through, so a host and a client on one machine, or on one quiet LAN, play
## the way two machines a long way apart do. Off unless [member ping] is set, as the tests and
## the multiplayer check do; nothing in the game sets it.
##
## Each end holds what it hears for half of [member ping], so two ends both set to it have that
## round trip between them. On top of that [member jitter] holds each packet sent unreliably a
## little longer or shorter at random, which puts snapshots out of order the way a busy network
## does. What is sent reliably, or in order, is never put out of order: those arrive late, never
## early and never overtaking each other.
##
## A peer going is heard the same way, in its place behind whatever it said before it went, so a
## last word before a hang-up is heard before the hang-up is. ENet's own traffic, its
## acknowledgements and its pings, goes on at the speed of the wire, so ENet itself never sees
## the round trip and never resends anything because of it.

## The round trip to put between two ends, in seconds, and the most each packet sent unreliably
## is held longer or shorter than that on top.
static var ping := 0.0
static var jitter := 0.0

## The connection underneath, which does the sending.
var inner: MultiplayerPeer

var _rng := RandomNumberGenerator.new()
## What has been heard and not let through yet, oldest first: when it is due, in microseconds,
## the bytes, and who it came from, on what channel and how. A peer going is in here too, with no
## bytes.
var _held: Array[Array] = []
## What has been let through and not read yet, oldest first, the same way.
var _through: Array[Array] = []
## Peers whose going has been let through, to be said once everything they said before it has
## been read.
var _leaving: Array[int] = []
## Peers gone underneath whose going has not been said yet, and who is being sent to: what is
## sent to one of them in that time goes nowhere, as it would down a line nobody is on.
var _gone: Array[int] = []
var _target := 0
## The latest due time handed to anything that has to stay in order, so nothing sent after it
## is let through before it.
var _last_in_order := 0
## Whether this end is hanging up itself, which is not news to be held up.
var _closing := false
## Who this end is, kept for while it hears out a connection already gone underneath, which no
## longer knows.
var _id := 0


## [param peer] as it should be used: made slower when [member ping] or [member jitter] says so,
## and as it is otherwise.
static func over(peer: MultiplayerPeer) -> MultiplayerPeer:
	if ping <= 0.0 and jitter <= 0.0:
		return peer
	return NetLag.new(peer)


## The ENet connection under [param peer], whether or not it is being made slower, or null.
static func enet(peer: MultiplayerPeer) -> ENetMultiplayerPeer:
	var lagged := peer as NetLag
	return (lagged.inner if lagged != null else peer) as ENetMultiplayerPeer


func _init(wrapped: MultiplayerPeer) -> void:
	inner = wrapped
	if inner.get_connection_status() != CONNECTION_DISCONNECTED:
		_id = inner.get_unique_id()
	_rng.randomize()
	# Methods rather than lambdas: a lambda holds on to this, and this to the connection under it,
	# and a pair holding each other is never let go, and nor is the port under them.
	inner.peer_connected.connect(_on_peer_connected)
	inner.peer_disconnected.connect(_on_peer_disconnected)


func _on_peer_connected(id: int) -> void:
	peer_connected.emit(id)


## Gone, which is heard in its place behind whatever it said before it went.
func _on_peer_disconnected(id: int) -> void:
	if _closing:
		peer_disconnected.emit(id)
		return
	_gone.append(id)
	_hold(null, id, 0, TRANSFER_MODE_RELIABLE)


func _poll() -> void:
	_let_go()
	# A connection already gone underneath is not polled, only heard out.
	var gone := inner.get_connection_status() == CONNECTION_DISCONNECTED
	if not gone:
		inner.poll()
	while not gone and inner.get_available_packet_count() > 0:
		var from := inner.get_packet_peer()
		var channel := inner.get_packet_channel()
		var mode := inner.get_packet_mode()
		_hold(inner.get_packet(), from, channel, mode)
	var now := Time.get_ticks_usec()
	var still: Array[Array] = []
	var due_now: Array[Array] = []
	for packet: Array in _held:
		(due_now if packet[0] <= now else still).append(packet)
	due_now.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	_held = still
	for packet: Array in due_now:
		if packet[1] == null:
			_leaving.append(packet[2])
		elif not _leaving.has(packet[2]):
			_through.append(packet)


## Holds [param bytes] from [param from], or its going when there are none, for as long as the
## line says to.
func _hold(bytes: Variant, from: int, channel: int, mode: TransferMode) -> void:
	var due := Time.get_ticks_usec() + roundi(ping * 0.5 * 1000000.0)
	if mode == TRANSFER_MODE_UNRELIABLE:
		due += roundi(_rng.randf_range(-jitter, jitter) * 1000000.0)
	else:
		due = maxi(due, _last_in_order)
		_last_in_order = due
	_held.append([due, bytes, from, channel, mode])


## Says a peer has gone once all it said before has been read, and drops anything of its that
## was still on the way, which nobody is left to hear.
func _let_go() -> void:
	for id: int in _leaving.duplicate():
		if _through.any(func(packet: Array) -> bool: return packet[2] == id):
			continue
		_leaving.erase(id)
		_gone.erase(id)
		_held = _held.filter(func(packet: Array) -> bool: return packet[2] != id)
		peer_disconnected.emit(id)


func _get_available_packet_count() -> int:
	return _through.size()


func _get_packet_script() -> PackedByteArray:
	if _through.is_empty():
		return PackedByteArray()
	return _through.pop_front()[1]


func _get_packet_peer() -> int:
	return _through[0][2] if not _through.is_empty() else 0


func _get_packet_channel() -> int:
	return _through[0][3] if not _through.is_empty() else 0


func _get_packet_mode() -> TransferMode:
	return _through[0][4] if not _through.is_empty() else TRANSFER_MODE_RELIABLE


## Said to nobody once the connection underneath has gone, the way words into a line the far end
## has put down go nowhere.
func _put_packet_script(buffer: PackedByteArray) -> Error:
	if inner.get_connection_status() == CONNECTION_DISCONNECTED or _gone.has(_target):
		return OK
	return inner.put_packet(buffer)


func _get_max_packet_size() -> int:
	return 1 << 24


func _set_transfer_channel(channel: int) -> void:
	inner.transfer_channel = channel


func _get_transfer_channel() -> int:
	return inner.transfer_channel


func _set_transfer_mode(mode: TransferMode) -> void:
	inner.transfer_mode = mode


func _get_transfer_mode() -> TransferMode:
	return inner.transfer_mode


func _set_target_peer(peer: int) -> void:
	_target = peer
	inner.set_target_peer(peer)


func _is_server() -> bool:
	return _id == 1


func _is_server_relay_supported() -> bool:
	return inner.is_server_relay_supported()


func _get_unique_id() -> int:
	return _id


## Connected for as long as there is still something to hear from the far end: a client the host
## has let go of hears the last of what it said before it hears that it is gone.
func _get_connection_status() -> ConnectionStatus:
	var status := inner.get_connection_status()
	var hearing := not (_held.is_empty() and _through.is_empty() and _leaving.is_empty())
	return CONNECTION_CONNECTED if status == CONNECTION_DISCONNECTED and hearing else status


func _set_refuse_new_connections(refuse: bool) -> void:
	inner.refuse_new_connections = refuse


func _is_refusing_new_connections() -> bool:
	return inner.refuse_new_connections


func _disconnect_peer(peer: int, force: bool) -> void:
	inner.disconnect_peer(peer, force)


func _close() -> void:
	_held.clear()
	_through.clear()
	_leaving.clear()
	_gone.clear()
	_closing = true
	inner.close()
	_closing = false
