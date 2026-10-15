class_name NetGuard
extends RefCounted
## The door of a server's connections before anybody is let in, GAME.md 10.3: a dedicated server's
## hall, one of its games, or a game hosted on a LAN. What speaks neither ENet nor the game's own
## compression never gets this far: ENet drops it before any of the game sees it, and resets a
## connection that does not open the way the engine does. What does get here is a connection that
## has to say hello, one knock of the game's own, before anything else is heard from it. Anything
## else is garbage, and the connection is dropped on the spot and said so, with where it came from:
##
## - a hello that is not one: too long, not a dictionary, no version in it, no [constant MAGIC] in
##   it, or values that are neither words, numbers nor flags;
## - a second hello, which no copy of the game sends;
## - more connections from one address at once, or in a minute, than any number of players behind
##   one router open, which is a scan or a flood;
## and a connection that says nothing at all is dropped once the handshake runs out of time, and
## said so too. A flood of datagrams that are not the game's, which ENet drops unread, is said once
## a minute, since it cannot be traced to anybody: a firewall is the place to stop one.
##
## Names nothing of the game but the connection, so the hall, which runs without the game's
## autoloads, uses it too.

## Something dropped, with the address it came from and why, for the log.
signal dropped(address: String, why: String)

## What a client shown out for misbehaving is told, at the hall or in a game, see [NetConduct].
const KICKED := "Kicked: abnormal behavior detected"
## What every hello says it is, under [constant MAGIC_KEY], so a connection of the engine's own kind
## that is not the game is known for what it is, see [method marked].
const MAGIC_KEY := "magic"
const MAGIC := "jackpot-junction"
## The most a hello may be, in bytes: a version, a name, a password and a flag or two.
const KNOCK_BYTES := 2048
## How many connections one address may have waiting to say hello at once, and open in a minute:
## a room of players behind one router, eight of them since a room took eight, GAME.md 9.3, each
## with a list and a game open, and some to spare.
const WAITING_AT_ONCE := 16
const PER_MINUTE := 60
## How often the traffic is looked at, in seconds, and how many datagrams a second more than its
## connections could send is a flood: a client sends sixty or seventy a second, its players' ticks
## and the acknowledgements, so each connection is allowed four times that. Measured as they are
## read, which is as fast as the system's buffer lets them in: a small datagram takes a kilobyte of
## a buffer of a couple of hundred, so a hall reading ten times a second sees a flood of any size as
## about two thousand a second, and the rest is dropped before anybody sees it.
const TRAFFIC_EVERY := 10.0
const FLOOD_FLOOR := 1000
const FLOOD_PER_PEER := 300
## How long between two words about a flood, in seconds.
const FLOOD_QUIET := 60.0

var api: MultiplayerAPI
## [constant TRAFFIC_EVERY], unless a test says otherwise.
var every := TRAFFIC_EVERY
## Waiting to say hello: peer to [address, how many hellos so far].
var _waiting: Dictionary[int, Array] = {}
## When each address last opened connections, in the last minute, in engine milliseconds.
var _opened: Dictionary[String, Array] = {}
## Seconds since the traffic was last looked at.
var _since := 0.0
var _flood_said := -FLOOD_QUIET


func _init(of: MultiplayerAPI) -> void:
	api = of


## What [param data], the first thing a connection said, says, or empty when it is not a hello of
## the game's at all. Looked at before it is read, since the engine complains aloud of every
## garbled one it is asked to read, and garbage is what this is for.
static func knock_of(data: PackedByteArray) -> Dictionary:
	if data.size() < 8 or data.size() > KNOCK_BYTES or data.decode_u8(0) != TYPE_DICTIONARY:
		return {}
	var said: Variant = bytes_to_var(data)
	if not said is Dictionary or not (said as Dictionary).get("version") is String:
		return {}
	for key: Variant in said:
		var value: Variant = said[key]
		if not key is String or not (value is String or value is bool or value is int):
			return {}
	if (said as Dictionary).get(MAGIC_KEY) != MAGIC:
		return {}
	return said


## [param words], a hello, with what every hello says it is, see [constant MAGIC].
static func marked(words: Dictionary) -> Dictionary:
	words[MAGIC_KEY] = MAGIC
	return words


## A new connection, waiting to say hello: dropped at once if its address has too many going.
func came(peer: int) -> void:
	var address := address_of(peer)
	var now := Time.get_ticks_msec()
	var times: Array = _opened.get(address, [])
	while not times.is_empty() and now - int(times[0]) > 60_000:
		times.pop_front()
	times.append(now)
	_opened[address] = times
	var waiting := 0
	for other: int in _waiting:
		if _waiting[other][0] == address:
			waiting += 1
	_waiting[peer] = [address, 0]
	if waiting >= WAITING_AT_ONCE:
		drop(peer, "%d connections waiting at once, a scan or a flood" % (waiting + 1))
	elif times.size() > PER_MINUTE:
		drop(peer, "%d connections in a minute, a scan or a flood" % times.size())


## [param peer] said hello, [param data]: what it said, or empty, and dropped, for garbage or for a
## second hello.
func heard(peer: int, data: PackedByteArray) -> Dictionary:
	var entry: Array = _waiting.get(peer, [address_of(peer), 0])
	entry[1] = int(entry[1]) + 1
	_waiting[peer] = entry
	if int(entry[1]) > 1:
		drop(peer, "said hello twice")
		return {}
	var knock := knock_of(data)
	if knock.is_empty():
		drop(peer, "said %d bytes that are not a Jackpot Junction hello" % data.size())
	return knock


## [param peer] is in, or gone: no longer waiting.
func settled(peer: int) -> void:
	_waiting.erase(peer)


## The handshake ran out of time for [param peer], which the engine drops for it.
func timed_out(peer: int) -> void:
	if _waiting.has(peer):
		dropped.emit(str(_waiting[peer][0]), "connected and never said hello")
	_waiting.erase(peer)


## Drops [param peer] with [param why] said, a frame later rather than in the middle of the
## engine's own reading of it.
func drop(peer: int, why: String) -> void:
	var address: String = _waiting[peer][0] if _waiting.has(peer) else address_of(peer)
	_waiting.erase(peer)
	dropped.emit(address, why)
	_disconnect.call_deferred(peer)


## Looks at the traffic now and then: a flood of datagrams nothing here sent for is said once a
## minute. [param delta] is the frame's.
func watch(delta: float) -> void:
	_since += delta
	if _since < every:
		return
	var enet := NetLag.enet(api.multiplayer_peer)
	if enet == null or enet.host == null:
		return
	var received := enet.host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_PACKETS)
	var rate := roundi(received / _since)
	_since = 0.0
	var expected := FLOOD_FLOOR + FLOOD_PER_PEER * enet.host.get_peers().size()
	var now := Time.get_ticks_msec() * 0.001
	if rate > expected and now - _flood_said >= FLOOD_QUIET:
		_flood_said = now
		dropped.emit(
			"somewhere",
			(
				(
					"%d datagrams a second, far more than its connections send: a flood or a scan, "
					+ "answered with nothing, and a firewall is the place to stop it"
				)
				% rate
			)
		)


## Where [param peer] is connecting from: an address, or for a Steam game its account, GAME.md
## 10.8, so the limits on one place hold for one person there too.
func address_of(peer: int) -> String:
	var steam := SteamPeer.of(api.multiplayer_peer)
	if steam != null:
		return steam.address_of(peer)
	var enet := NetLag.enet(api.multiplayer_peer)
	var connection := enet.get_peer(peer) if enet != null else null
	return connection.get_remote_address() if connection != null else "somewhere"


## At once rather than politely: there is nobody at the other end to say goodbye to. Through the
## multiplayer rather than the connection, which would leave the multiplayer waiting on a hello from
## a peer that has gone, and complaining of it once the handshake ran out.
func _disconnect(peer: int) -> void:
	var enet := NetLag.enet(api.multiplayer_peer)
	var steam := SteamPeer.of(api.multiplayer_peer)
	if steam == null and (enet == null or enet.get_peer(peer) == null):
		return
	var scene := api as SceneMultiplayer
	if scene != null:
		scene.disconnect_peer(peer)
	else:
		api.multiplayer_peer.disconnect_peer(peer, true)
