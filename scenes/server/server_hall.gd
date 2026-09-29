class_name ServerHall
extends Node
## A dedicated server, GAME.md 9.3a: the hall players come into to see the games being played on
## it and to make one. Each game runs in a process of its own, the game itself started headless as
## a host with nobody at it on a port of its own, see [ServerGame]. The hall starts it, lists it
## while anybody is playing in it, writes down what it says, and forgets it once its process has
## ended, which it does by itself when everybody has left.
##
## A process for each game rather than a scene each in this one: a game is the whole game, its
## autoloads among it, and two sharing a process would hear each other's every kill.

## How many people may be looking at the list at once.
const MOST_VISITORS := 32
## How long a new game has to say it is up, in seconds, and how long one that is up may go without
## saying anything before the hall takes it for hung.
const START_WAIT := 20.0
const QUIET_WAIT := 10.0
## Seconds between one look at every game and the next.
const TICK := 1.0

var args: ServerArgs
var link: ServerLink
## Where the link hangs, [Net] unless a test says otherwise: the same place as a player's screen
## hangs theirs, as a call from one to the other has to.
var home: Node
## [constant START_WAIT] and [constant QUIET_WAIT], unless a test says otherwise.
var start_wait := START_WAIT
var quiet_wait := QUIET_WAIT
## Starts a game's process with the arguments given and returns its id, or -1; says whether one is
## still running; and stops one. The operating system's, unless a test says otherwise.
var launch: Callable = _launch
var running: Callable = OS.is_process_running
var stop: Callable = OS.kill

## Every game by its number: its process, port and key, who made it and when, when it was last
## heard, and how it last said it stands.
var _games: Dictionary[int, Dictionary] = {}
var _next_game := 1
var _reports := PacketPeerUDP.new()
## What each visitor gave as their name.
var _visitors: Dictionary[int, String] = {}
var _tick_left := 0.0
## The list as it was last sent, to send it again only when it changes.
var _listed := ""


## Opens the hall on [member args]' port, and the ear its games report to on this machine.
func open() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(args.port, MOST_VISITORS)
	if error != OK:
		return error
	NetLine.compress(peer)
	# Visitors have nothing to say to each other, so none of them is told about the others coming
	# and going, which is all the engine's relay would be doing here.
	var scene := multiplayer as SceneMultiplayer
	if scene != null:
		scene.server_relay = false
	multiplayer.multiplayer_peer = peer
	error = _reports.bind(0, "127.0.0.1")
	if error != OK:
		return error
	link = ServerLink.new()
	link.name = ServerLink.NAME
	link.hall = self
	(home if home != null else Net).add_child(link)
	var ports := args.game_ports()
	var games := "1 game on port %d" % ports[0]
	if ports.size() > 1:
		games = "%d games on ports %d to %d" % [ports.size(), ports[0], ports[-1]]
	_say("Jackpot Junction %s server on port %d, up to %s" % [Game.version(), args.port, games])
	return OK


func _exit_tree() -> void:
	for id: int in _games.keys():
		_forget(id, "stopped with the server", true)
	if link != null and is_instance_valid(link):
		link.queue_free()
	_reports.close()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


## Whose each game is, and how it stands, as the Play Online screen lists it: the way a LAN game
## found on the network says it, see [LanBeacon], with the port it is played on. Only games up and
## with somebody playing, the ones in the lobby first.
func listing() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for id: int in _games:
		var game := _games[id]
		var state: Dictionary = game["state"]
		if not game["up"] or int(state.get("players", 0)) <= 0:
			continue
		(
			found
			. append(
				{
					"game": LanBeacon.ANSWER,
					"id": id,
					"name": str(state.get("name", "")) if state.get("name", "") != "" else "Host",
					"version": Game.version(),
					"port": game["port"],
					"players": int(state.get("players", 0)),
					"most": int(state.get("most", NetDoor.MOST_PLAYERS)),
					"password": bool(state.get("password", false)),
					"watching": bool(state.get("watching", true)),
					"watch_password": bool(state.get("watch_password", false)),
					"lobby": bool(state.get("lobby", true)),
				}
			)
		)
	found.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if a["lobby"] != b["lobby"]:
				return a["lobby"]
			return int(a["id"]) < int(b["id"])
	)
	return found


## How many games are running, up or on their way.
func count() -> int:
	return _games.size()


## Somebody has knocked, [param named], on [param version], and was let in if [param welcome].
func knocked(peer: int, named: String, version: String, welcome: bool) -> void:
	_visitors[peer] = named if not named.is_empty() else "Somebody"
	if not welcome:
		_say("Turned away %s: version %s" % [_visitor(peer), version])


func visitor_came(peer: int) -> void:
	_say("%s is looking at the games, from %s" % [_visitor(peer), _address_of(peer)])
	link._games_are.rpc_id(peer, listing())


func visitor_left(peer: int) -> void:
	if _visitors.has(peer):
		_say("%s left the list" % _visitor(peer))
	_visitors.erase(peer)


## [param peer] asks for a game of their own: started on the first free port, if there is room for
## another, and they are told its port once it says it is up. Only one at a time that nobody plays
## in yet: whoever asks goes into theirs the moment it is up, so a second is not for playing in.
func make_game(peer: int) -> void:
	for id: int in _games:
		var game := _games[id]
		if game["maker"] == peer and int((game["state"] as Dictionary).get("players", 0)) == 0:
			return
	var port := _free_port()
	if port == 0:
		var most := "%d game%s" % [args.games, "" if args.games == 1 else "s"]
		_say("%s asked for a game, but the server holds %s at once" % [_visitor(peer), most])
		link._not_made.rpc_id(peer, "The server is full: it holds %s at once" % most)
		return
	var id := _next_game
	_next_game += 1
	var key := "%08x%08x" % [randi(), randi()]
	var pid: int = launch.call(_game_args(id, port, key))
	if pid <= 0:
		_say("Could not start game %d for %s" % [id, _visitor(peer)])
		link._not_made.rpc_id(peer, "The server could not start a game")
		return
	var now := Time.get_ticks_msec()
	_games[id] = {
		"port": port,
		"pid": pid,
		"key": key,
		"maker": peer,
		"made": now,
		"heard": now,
		"from": 0,
		"up": false,
		"state": {},
	}
	_say("%s made game %d, on port %d" % [_visitor(peer), id, port])


func _free_port() -> int:
	if _games.size() >= args.games:
		return 0
	var taken: Array[int] = []
	for id: int in _games:
		taken.append(_games[id]["port"])
	for port: int in args.game_ports():
		if port not in taken:
			return port
	return 0


## What a game is started with: the game itself, headless and saying nothing on its own output,
## since what it has to say comes here and goes in the log, see [ServerGame].
func _game_args(id: int, port: int, key: String) -> PackedStringArray:
	var started := PackedStringArray(["--headless", "--quiet"])
	# Run from the project rather than from an export, the game is the project's.
	if OS.has_feature("editor"):
		started.append_array(["--path", ProjectSettings.globalize_path("res://")])
	var mine := OS.get_cmdline_args()
	var pack := mine.find("--main-pack")
	if pack >= 0 and pack + 1 < mine.size():
		started.append_array(["--main-pack", mine[pack + 1]])
	(
		started
		. append_array(
			[
				"--",
				"--server",
				"--game=%d" % id,
				"--port=%d" % port,
				"--report=%d" % _reports.get_local_port(),
				"--key=%s" % key,
			]
		)
	)
	return started


func _launch(started: PackedStringArray) -> int:
	return OS.create_process(OS.get_executable_path(), started)


func _process(delta: float) -> void:
	_hear_the_games()
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK
	_look_at_the_games()
	_send_the_list()


## What the games have said: a line for the log, how one stands, or that it is over.
func _hear_the_games() -> void:
	while _reports.get_available_packet_count() > 0:
		var said: Variant = bytes_to_var(_reports.get_packet())
		var from := _reports.get_packet_port()
		if not said is Dictionary:
			continue
		var words: Dictionary = said
		var id := int(words.get("game", 0))
		if not _games.has(id) or str(words.get("key", "")) != _games[id]["key"]:
			continue
		var game := _games[id]
		game["heard"] = Time.get_ticks_msec()
		game["from"] = from
		if words.has("log"):
			ServerLog.say("game %d" % id, str(words["log"]))
		if words.get("state") is Dictionary:
			game["state"] = words["state"]
			if not game["up"]:
				game["up"] = true
				_tell_the_maker(id)


## The game [param id] is up: whoever asked for it is told where it is, and goes to it.
func _tell_the_maker(id: int) -> void:
	var maker: int = _games[id]["maker"]
	if multiplayer.get_peers().has(maker):
		link._made.rpc_id(maker, _games[id]["port"])


## Every game in turn: told the hall is still here, and forgotten once its process has ended, or it
## never came up, or it has gone quiet.
func _look_at_the_games() -> void:
	var now := Time.get_ticks_msec()
	for id: int in _games.keys():
		var game := _games[id]
		if not running.call(game["pid"]):
			if not game["up"]:
				_let_the_maker_down(id)
			_forget(id, "over" if game["up"] else "ended before it was up")
		elif not game["up"] and now - int(game["made"]) > start_wait * 1000.0:
			_let_the_maker_down(id)
			_forget(id, "never started", true)
		elif game["up"] and now - int(game["heard"]) > quiet_wait * 1000.0:
			_forget(id, "stopped answering", true)
		elif int(game["from"]) > 0:
			_reports.set_dest_address("127.0.0.1", game["from"])
			_reports.put_packet(var_to_bytes({"alive": true}))


## Whoever asked for game [param id] is told it could not be made, if they are still here to hear
## it.
func _let_the_maker_down(id: int) -> void:
	var maker: int = _games[id]["maker"]
	if multiplayer.get_peers().has(maker):
		link._not_made.rpc_id(maker, "The server could not start a game")


func _forget(id: int, why: String, stopping := false) -> void:
	if stopping:
		stop.call(_games[id]["pid"])
	_games.erase(id)
	_say("Game %d is %s" % [id, why] if why == "over" else "Game %d %s" % [id, why])


func _send_the_list() -> void:
	var now := listing()
	var said := str(now)
	if said == _listed:
		return
	_listed = said
	# To each visitor still connected: one that has just gone is still counted until the wire says
	# so, and a word to it is an error for nothing.
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	for peer: int in multiplayer.get_peers():
		var connection := enet.get_peer(peer) if enet != null else null
		if connection != null and connection.get_state() == ENetPacketPeer.STATE_CONNECTED:
			link._games_are.rpc_id(peer, now)


func _visitor(peer: int) -> String:
	return _visitors.get(peer, "Somebody")


func _address_of(peer: int) -> String:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	var connection := enet.get_peer(peer) if enet != null else null
	return connection.get_remote_address() if connection != null else "somewhere"


func _say(text: String) -> void:
	ServerLog.say("server", text)
