class_name HostProbe
extends RefCounted
## Whether a game is hosted at an address and port yet, GAME.md 9.3: a connection made there and
## let go of at once, on the game's own network, packed as the game's are, see [NetLine], without
## a word said over it. For a game handed to a new host off Steam, see [HostHandover]: the others
## wait to hear the new host's game is up before they knock at it, which takes the new host the
## moment its room is built. [method poll] it every frame until it has [member reached] the game, or
## [member failed] to: nobody answering in the few seconds a connection is given.

## Whether the connection was made, and whether it could not be.
var reached := false
var failed := false

var _connection: ENetConnection
var _host: ENetPacketPeer
var _made := false


func _init(address: String, port: int) -> void:
	_connection = ENetConnection.new()
	if address.is_empty() or _connection.create_host(1) != OK:
		_fail()
		return
	_made = true
	_connection.compress(ENetConnection.COMPRESS_RANGE_CODER)
	_host = _connection.connect_to_host(address, port)
	if _host == null:
		_fail()
		return
	NetLine.trying(_host)


## Whatever the network has said since, heard: the connection made, or given up on.
func poll() -> void:
	if reached or failed:
		return
	while true:
		var event: Array = _connection.service(0)
		var kind: int = event[0]
		if kind == ENetConnection.EVENT_NONE:
			return
		if kind == ENetConnection.EVENT_CONNECT:
			reached = true
			_host.peer_disconnect_now()
			_made = false
			_connection.destroy()
			return
		if kind == ENetConnection.EVENT_DISCONNECT or kind == ENetConnection.EVENT_ERROR:
			_fail()
			return


func _fail() -> void:
	failed = true
	if _made:
		_made = false
		_connection.destroy()
