class_name SteamPeer
extends MultiplayerPeerExtension
## A Steam game's connection, GAME.md 10.8: GodotSteam's peer underneath, which sends over Steam's
## own network, with the two things done here that ENet did by itself. What is sent is compressed,
## since a busy snapshot is about 14 KB and ENet's range coder sent a tenth of that. And what is
## sent unreliably in order, a snapshot, goes unreliably with a number of its own, a late one
## dropped, where GodotSteam would send it reliably and hold everything up behind a lost one.
##
## It wraps any [MultiplayerPeer], ENet's as well, which is how it is tested on one machine.

## The first byte of every packet: whether the rest is compressed, with how long it unpacks to in
## four bytes first, and whether a number of two bytes comes first, for a packet sent unreliably in
## order.
const COMPRESSED := 1
const NUMBERED := 2
## Anything shorter goes as it is: a few bytes are not worth compressing.
const SQUEEZE_FROM := 64
const COMPRESSION := FileAccess.COMPRESSION_ZSTD
## The most a packet may unpack to.
const LARGEST := 1 << 24
## Half the numbers there are: one this far ahead of the last heard, or further, is an old one
## come round again.
const HALF := 1 << 15

## Whether every game's connection goes through one, not only a Steam game's: with JJ_STEAM_PEER=1
## in the environment, so the online tests and checks play through what a Steam game plays through,
## on one machine and over ENet.
static var everywhere := OS.get_environment("JJ_STEAM_PEER") == "1"

## The connection underneath, which does the sending.
var inner: MultiplayerPeer

var _mode := TRANSFER_MODE_RELIABLE
var _channel := 0
## The next number to send on each channel, and the last heard from each peer on each channel.
var _sent: Dictionary[int, int] = {}
var _heard: Dictionary[Vector2i, int] = {}
## What has been heard and unpacked and not read yet, oldest first: the bytes, who from, on what
## channel and how.
var _through: Array[Array] = []


## The Steam connection under [param peer], whether or not it is made slower, see [NetLag]; or null
## for a connection of another kind.
static func of(peer: MultiplayerPeer) -> SteamPeer:
	var lagged := peer as NetLag
	return (lagged.inner if lagged != null else peer) as SteamPeer


func _init(wrapped: MultiplayerPeer) -> void:
	inner = wrapped
	# Methods rather than lambdas, so this and the connection under it never hold each other.
	inner.peer_connected.connect(_on_peer_connected)
	inner.peer_disconnected.connect(_on_peer_disconnected)


func _on_peer_connected(id: int) -> void:
	peer_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	for key: Vector2i in _heard.keys():
		if key.x == id:
			_heard.erase(key)
	peer_disconnected.emit(id)


## Where [param peer] is, for [NetGuard]: its Steam account, or an address on another connection.
func address_of(peer: int) -> String:
	if inner.has_method(&"get_steam_id_for_peer_id"):
		return "steam:%d" % int(inner.call(&"get_steam_id_for_peer_id", peer))
	var enet := inner as ENetMultiplayerPeer
	var connection := enet.get_peer(peer) if enet != null else null
	return connection.get_remote_address() if connection != null else "somewhere"


## [param bytes] as they go down the line: the first byte saying how, a number for a packet sent
## unreliably in order, then the bytes, compressed where that makes them shorter.
func pack(bytes: PackedByteArray, mode: TransferMode, channel: int) -> PackedByteArray:
	var flags := 0
	var head := PackedByteArray([0])
	if mode == TRANSFER_MODE_UNRELIABLE_ORDERED:
		flags |= NUMBERED
		var number: int = _sent.get(channel, 0)
		_sent[channel] = (number + 1) & 0xFFFF
		head.resize(3)
		head.encode_u16(1, number)
	var body := bytes
	if bytes.size() >= SQUEEZE_FROM:
		var squeezed := bytes.compress(COMPRESSION)
		if squeezed.size() + 4 < bytes.size():
			flags |= COMPRESSED
			var size := PackedByteArray([0, 0, 0, 0])
			size.encode_u32(0, bytes.size())
			body = size + squeezed
	head[0] = flags
	return head + body


## What [param packed] says, from [param from] on [param channel], or null for one to drop: one
## that will not unpack, or one sent in order that a later one has overtaken.
func unpack(packed: PackedByteArray, from: int, channel: int) -> Variant:
	if packed.is_empty():
		return null
	var flags := packed[0]
	var start := 1
	if flags & NUMBERED:
		if packed.size() < 3 or not _in_order(packed.decode_u16(1), from, channel):
			return null
		start = 3
	var body := packed.slice(start)
	return _unsqueezed(body) if flags & COMPRESSED else body


## Whether [param number], from [param from] on [param channel], is later than any heard before
## from there, and kept as the latest if it is.
func _in_order(number: int, from: int, channel: int) -> bool:
	var key := Vector2i(from, channel)
	if _heard.has(key):
		var ahead := (number - _heard[key]) & 0xFFFF
		if ahead == 0 or ahead >= HALF:
			return false
	_heard[key] = number
	return true


## [param body] unpacked, the length it unpacks to first, or null for one that will not.
static func _unsqueezed(body: PackedByteArray) -> Variant:
	if body.size() < 5:
		return null
	var size := body.decode_u32(0)
	if size == 0 or size > LARGEST:
		return null
	var bytes := body.slice(4).decompress(size, COMPRESSION)
	return bytes if bytes.size() == size else null


func _poll() -> void:
	inner.poll()
	while inner.get_available_packet_count() > 0:
		var from := inner.get_packet_peer()
		var channel := inner.get_packet_channel()
		var mode := inner.get_packet_mode()
		var packed := inner.get_packet()
		var bytes: Variant = unpack(packed, from, channel)
		if bytes != null:
			var numbered := not packed.is_empty() and packed[0] & NUMBERED
			var heard_as := TRANSFER_MODE_UNRELIABLE_ORDERED if numbered else mode
			_through.append([bytes, from, channel, heard_as])


func _get_available_packet_count() -> int:
	return _through.size()


func _get_packet_script() -> PackedByteArray:
	if _through.is_empty():
		return PackedByteArray()
	return _through.pop_front()[0]


func _get_packet_peer() -> int:
	return _through[0][1] if not _through.is_empty() else 0


func _get_packet_channel() -> int:
	return _through[0][2] if not _through.is_empty() else 0


func _get_packet_mode() -> TransferMode:
	return _through[0][3] if not _through.is_empty() else TRANSFER_MODE_RELIABLE


## Sent the way it was asked for, but for a packet in order without being reliable, which goes
## unreliably with its number, see [method pack].
func _put_packet_script(buffer: PackedByteArray) -> Error:
	var mode := _mode
	inner.transfer_mode = (
		TRANSFER_MODE_UNRELIABLE if mode == TRANSFER_MODE_UNRELIABLE_ORDERED else mode
	)
	inner.transfer_channel = _channel
	return inner.put_packet(pack(buffer, mode, _channel))


## Room for the header, under what the connection underneath takes.
func _get_max_packet_size() -> int:
	return inner.get_max_packet_size() - 7


func _set_transfer_channel(channel: int) -> void:
	_channel = channel


func _get_transfer_channel() -> int:
	return _channel


func _set_transfer_mode(mode: TransferMode) -> void:
	_mode = mode


func _get_transfer_mode() -> TransferMode:
	return _mode


func _set_target_peer(peer: int) -> void:
	inner.set_target_peer(peer)


func _is_server() -> bool:
	return inner.get_unique_id() == 1


func _is_server_relay_supported() -> bool:
	return inner.is_server_relay_supported()


func _get_unique_id() -> int:
	return inner.get_unique_id()


func _get_connection_status() -> ConnectionStatus:
	return inner.get_connection_status()


func _set_refuse_new_connections(refuse: bool) -> void:
	inner.refuse_new_connections = refuse


func _is_refusing_new_connections() -> bool:
	return inner.refuse_new_connections


func _disconnect_peer(peer: int, force: bool) -> void:
	inner.disconnect_peer(peer, force)


func _close() -> void:
	_through.clear()
	_heard.clear()
	inner.close()
