class_name LanFinder
extends Node
## The Play LAN screen looking for games on the network, GAME.md 9.3: asking about once a second,
## on [constant LanBeacon.PORT] of every machine the network reaches and of this one, and keeping
## whatever answers, for as long as it goes on answering. See [LanBeacon] for the other end.

## Something has been found, or has gone.
signal changed

## How often it asks, and how long a game that has stopped answering stays in the list.
const ASK_EVERY := 1.0
const FORGET_AFTER := 3.5
## Where it asks: every machine on the network, and this one, which a broadcast does not always
## reach on its own.
const EVERYWHERE := "255.255.255.255"
const HERE := "127.0.0.1"

## The port hosts listen on, [constant LanBeacon.PORT] unless a test says otherwise.
var listen := LanBeacon.PORT

var _udp := PacketPeerUDP.new()
var _ask_left := 0.0
## Each game heard, by its beacon's id: its answer, the address it came from and when.
var _heard: Dictionary[int, Dictionary] = {}


func _ready() -> void:
	_udp.set_broadcast_enabled(true)
	_udp.bind(0)


func _exit_tree() -> void:
	_udp.close()


## The games answering, the ones in the lobby first, then by whose they are.
func games() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	found.assign(_heard.values())
	found.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if a["lobby"] != b["lobby"]:
				return a["lobby"]
			return str(a["name"]) < str(b["name"])
	)
	return found


func _process(delta: float) -> void:
	_ask_left -= delta
	if _ask_left <= 0.0:
		_ask_left = ASK_EVERY
		for where: String in [EVERYWHERE, HERE]:
			_udp.set_dest_address(where, listen)
			_udp.put_packet(LanBeacon.QUESTION.to_utf8_buffer())
	var now := Time.get_ticks_msec()
	var moved := false
	while _udp.get_available_packet_count() > 0:
		var packet := _udp.get_packet()
		var address := _udp.get_packet_ip()
		var said: Variant = bytes_to_var(packet)
		if not said is Dictionary or (said as Dictionary).get("game", "") != LanBeacon.ANSWER:
			continue
		var game: Dictionary = said
		var id := int(game.get("id", 0))
		var known: Dictionary = _heard.get(id, {})
		# One game heard by the network and by this machine's own address is one game, found at
		# the address the network gave it, which the others can reach too.
		if known.has("address") and address == HERE and known["address"] != HERE:
			address = known["address"]
		game["address"] = address
		game["seen"] = now
		moved = moved or known.is_empty() or _changed(known, game)
		_heard[id] = game
	for id: int in _heard.keys():
		if now - int(_heard[id]["seen"]) > FORGET_AFTER * 1000.0:
			_heard.erase(id)
			moved = true
	if moved:
		changed.emit()


## Whether a game says anything different from last time, whatever it is: everything but when it
## was heard, so a field a host starts sending is never one the list misses.
static func _changed(was: Dictionary, now: Dictionary) -> bool:
	var before := was.duplicate()
	var after := now.duplicate()
	before.erase("seen")
	after.erase("seen")
	return before != after
