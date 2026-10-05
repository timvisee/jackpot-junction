extends GdUnitTestSuite
## A dedicated server's hall, GAME.md 9.3a: who is let in to look, the games it lists, making one,
## and forgetting one whose process has ended. Over a real socket between the hall and a player's
## screen in this one process, with the games' processes stood in for by the test, which reports
## for them the way [ServerGame] does.

## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side, and the games' after it.
var port := 7951
var _hall_root: Node
var _hall: ServerHall
var _client_roots: Array[Node] = []
## What the hall asked to have started, the processes it thinks are running, and the ones it
## stopped.
var _launched: Array[PackedStringArray] = []
var _ended: Array[int] = []
var _stopped: Array[int] = []
var _games := PacketPeerUDP.new()


func before_test() -> void:
	_launched.clear()
	_ended.clear()
	_stopped.clear()
	_hall_root = auto_free(Node.new())
	_hall_root.name = "HallRoot"
	add_child(_hall_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _hall_root.get_path())
	_games.bind(0, "127.0.0.1")


func after_test() -> void:
	_games.close()
	if is_instance_valid(_hall):
		_hall.queue_free()
	await await_idle_frame()
	get_tree().set_multiplayer(null, _hall_root.get_path())
	for root: Node in _client_roots:
		get_tree().set_multiplayer(null, root.get_path())
	_client_roots.clear()


## A hall for [param games] games, under a node called Net, as the server's own is.
func _open_hall(games := 2) -> void:
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	_hall_root.add_child(net)
	_hall = ServerHall.new()
	_hall.name = "Hall"
	_hall.args = ServerArgs.read(["--server", "--port=%d" % port, "--games=%d" % games])
	_hall.home = net
	_hall.launch = func(started: PackedStringArray) -> int:
		_launched.append(started)
		return 1000 + _launched.size()
	_hall.running = func(pid: int) -> bool: return pid not in _ended
	_hall.stop = func(pid: int) -> Error:
		_stopped.append(pid)
		return OK
	_hall_root.add_child(_hall)
	assert_int(_hall.open()).is_equal(OK)


## A player's screen on a multiplayer root of its own, knocking at the hall on [param version].
func _visitor(named: String, version := "") -> ServerLink:
	var root: Node = auto_free(Node.new())
	root.name = "Visitor%d" % _client_roots.size()
	add_child(root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), root.get_path())
	_client_roots.append(root)
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	root.add_child(net)
	var link: ServerLink = auto_free(ServerLink.new())
	link.name = ServerLink.NAME
	link.player_name = named
	link.version = version
	net.add_child(link)
	assert_int(link.reach("127.0.0.1", port)).is_equal(OK)
	return link


## A connection of the game's own kind at the hall that is not the game, on a root of its own: it
## says [param hello] as its first word, or nothing at all.
func _stranger(hello := PackedByteArray()) -> SceneMultiplayer:
	var root: Node = auto_free(Node.new())
	root.name = "Stranger%d" % _client_roots.size()
	add_child(root)
	var scene := SceneMultiplayer.new()
	get_tree().set_multiplayer(scene, root.get_path())
	_client_roots.append(root)
	scene.auth_callback = func(_id: int, _data: PackedByteArray) -> void: pass
	scene.auth_timeout = 30.0
	if not hello.is_empty():
		scene.peer_authenticating.connect(func(id: int) -> void: scene.send_auth(id, hello))
	var peer := ENetMultiplayerPeer.new()
	assert_int(peer.create_client("127.0.0.1", port)).is_equal(OK)
	NetLine.compress(peer)
	scene.multiplayer_peer = peer
	return scene


## Whether the hall still holds a connection from [param stranger].
func _held(stranger: SceneMultiplayer) -> bool:
	var enet := _hall.multiplayer.multiplayer_peer as ENetMultiplayerPeer
	return enet.get_peer(stranger.get_unique_id()) != null


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## What the hall started game [param index] with, by name: its number, port, report port and key.
func _given(index: int) -> Dictionary:
	var found := {}
	for arg: String in _launched[index]:
		if arg.begins_with("--") and arg.contains("="):
			found[arg.get_slice("=", 0).trim_prefix("--")] = arg.get_slice("=", 1)
	return found


## Says [param words] to the hall as game [param index] of those it started.
func _report(index: int, words: Dictionary) -> void:
	var given := _given(index)
	words["game"] = int(given["game"])
	words["key"] = given.get("key", "")
	_games.set_dest_address("127.0.0.1", int(given["report"]))
	_games.put_packet(var_to_bytes(words))


func _up(index: int, players: int, named := "") -> void:
	var state := {"name": named, "players": players, "most": 4, "lobby": true}
	_report(index, {"state": state})


## A game is made for whoever asks, started as a server's game on the first port after the hall's,
## and they are told its port once it says it is up. It is listed once somebody plays in it.
func test_a_game_is_made_listed_and_forgotten_when_its_process_ends() -> void:
	_open_hall()
	var ann := _visitor("Ann")
	var lists: Array = []
	ann.listed.connect(func(games: Array[Dictionary]) -> void: lists.append(games.duplicate()))
	var looked := await _wait_until(func() -> bool: return not lists.is_empty(), 4000)
	assert_bool(looked).override_failure_message("Ann never saw the list").is_true()
	assert_array(lists[-1]).is_empty()
	var ports: Array[int] = []
	ann.made.connect(func(at: int) -> void: ports.append(at))
	ann.make_game()
	var started := await _wait_until(func() -> bool: return not _launched.is_empty(), 4000)
	assert_bool(started).override_failure_message("no game was started").is_true()
	var given := _given(0)
	assert_bool("--server" in _launched[0]).is_true()
	assert_bool("--headless" in _launched[0]).is_true()
	assert_str(given["port"]).is_equal(str(port + 1))
	# How far along it is goes to whoever asked for it: started, and then as the game says.
	var along: Array[float] = []
	ann.making.connect(func(done: float) -> void: along.append(done))
	_report(0, {"making": 0.5})
	_report(0, {"making": 0.6})
	var heard := await _wait_until(func() -> bool: return 0.6 in along, 4000)
	assert_bool(heard).override_failure_message("Ann never heard how far along it was").is_true()
	_up(0, 0)
	var told := await _wait_until(func() -> bool: return not ports.is_empty(), 4000)
	assert_bool(told).override_failure_message("Ann was never told the port").is_true()
	assert_int(ports[0]).is_equal(port + 1)
	# Nobody plays in it yet, so there is nothing to list.
	assert_array(_hall.listing()).is_empty()
	_up(0, 1, "Ann")
	var listed := await _wait_until(func() -> bool: return not lists[-1].is_empty(), 4000)
	assert_bool(listed).override_failure_message("the game never showed in the list").is_true()
	var game: Dictionary = lists[-1][0]
	assert_str(str(game["name"])).is_equal("Ann")
	assert_int(int(game["port"])).is_equal(port + 1)
	assert_int(int(game["players"])).is_equal(1)
	assert_bool(bool(game["lobby"])).is_true()
	assert_str(str(game["version"])).is_equal(Game.version())
	# What its host called it and the map it is on, as the game says them.
	var state := {"name": "Ann", "title": "Friday night", "map": "Crossfire", "players": 1}
	state.merge({"most": 4, "lobby": false})
	_report(0, {"state": state})
	var named := await _wait_until(func() -> bool: return lists[-1][0].get("title") != "", 4000)
	assert_bool(named).override_failure_message("the game's name never showed").is_true()
	assert_str(str(lists[-1][0]["title"])).is_equal("Friday night")
	assert_str(str(lists[-1][0]["map"])).is_equal("Crossfire")
	_ended.append(1001)
	var gone := await _wait_until(func() -> bool: return lists[-1].is_empty(), 4000)
	assert_bool(gone).override_failure_message("the game stayed in the list").is_true()
	assert_int(_hall.count()).is_equal(0)


## Garbage for a hello, or a second hello, is dropped there and then and said, with the address it
## came from, rather than waited on for the handshake to run out, see [NetGuard]; one that says
## nothing is dropped once it has, and said too.
func test_a_connection_that_is_not_the_game_is_dropped_and_said() -> void:
	_open_hall()
	var said: Array[String] = []
	_hall.link.guard.dropped.connect(
		func(at: String, why: String) -> void: said.append(at + ": " + why)
	)
	var junk := PackedByteArray()
	for i: int in 64:
		junk.append((i * 37 + 11) % 256)
	var garbled := _stranger(junk)
	var gone := await _wait_until(func() -> bool: return not said.is_empty(), 1000)
	assert_bool(gone).override_failure_message("garbage was not dropped at once").is_true()
	assert_str(said[0]).contains("127.0.0.1").contains("not a Jackpot Junction hello")
	assert_bool(await _wait_until(func() -> bool: return not _held(garbled), 1000)).is_true()
	# Hello, and hello again.
	said.clear()
	var hello := var_to_bytes(
		NetGuard.marked({"version": Game.version(), "name": "Twice", ServerLink.LISTING: true})
	)
	var twice := _stranger(hello)
	twice.peer_authenticating.connect(func(id: int) -> void: twice.send_auth(id, hello))
	assert_bool(await _wait_until(func() -> bool: return not said.is_empty(), 1000)).is_true()
	assert_str(said[0]).contains("said hello twice")
	# Nothing at all.
	said.clear()
	(_hall.multiplayer as SceneMultiplayer).auth_timeout = 0.5
	_stranger()
	assert_bool(await _wait_until(func() -> bool: return not said.is_empty(), 2000)).is_true()
	assert_str(said[0]).contains("never said hello")


## More connections from one address at once than any room of players behind one router opens is a
## scan or a flood: the one too many is dropped, and said.
func test_a_flood_of_connections_is_dropped() -> void:
	_open_hall()
	var said: Array[String] = []
	_hall.link.guard.dropped.connect(func(_at: String, why: String) -> void: said.append(why))
	for i: int in NetGuard.WAITING_AT_ONCE + 1:
		_stranger()
	assert_bool(await _wait_until(func() -> bool: return not said.is_empty(), 2000)).is_true()
	assert_str(said[0]).contains("waiting at once")
	assert_int(said.size()).is_equal(1)


## A flood of datagrams that are not the game's, which ENet drops unread, is said, since that is all
## that can be done with it here.
func test_a_flood_of_datagrams_is_said() -> void:
	_open_hall()
	var said: Array[String] = []
	_hall.link.guard.dropped.connect(func(_at: String, why: String) -> void: said.append(why))
	_hall.link.guard.every = 0.25
	var noise := PacketPeerUDP.new()
	noise.set_dest_address("127.0.0.1", port)
	# A frame at a time, as a flood arrives: the system's buffer takes a couple of hundred at once.
	var sending := func() -> bool:
		for i: int in 150:
			noise.put_packet(PackedByteArray([i % 256, 1, 2, 3, 4, 5, 6, 7]))
		return not said.is_empty()
	assert_bool(await _wait_until(sending, 3000)).is_true()
	noise.close()
	assert_str(said[0]).contains("datagrams a second").contains("firewall")


## A visitor that asks for games faster than anybody presses a button is shown out, and told why.
func test_a_visitor_flooding_the_hall_is_shown_out() -> void:
	_open_hall()
	var ann := _visitor("Ann")
	assert_bool(await _wait_until(ann._talking, 4000)).is_true()
	var told := [""]
	ann.refused.connect(func(why: String) -> void: told[0] = why)
	for i: int in ServerLink.MAKES_A_SECOND + 5:
		ann.make_game()
	(
		assert_bool(await _wait_until(func() -> bool: return told[0] == NetGuard.KICKED, 4000))
		. is_true()
	)
	assert_int(_launched.size()).is_less_equal(1)


## Asking again while the game asked for has nobody in it yet makes nothing: its maker is on the
## way into it, and a second would only stand empty holding a port.
func test_a_second_game_waits_for_the_first_to_be_played_in() -> void:
	_open_hall()
	var ann := _visitor("Ann")
	assert_bool(await _wait_until(ann._talking, 4000)).is_true()
	ann.make_game()
	ann.make_game()
	assert_bool(await _wait_until(func() -> bool: return not _launched.is_empty(), 4000)).is_true()
	_up(0, 0)
	ann.make_game()
	await await_millis(300)
	assert_int(_launched.size()).is_equal(1)
	_up(0, 1, "Ann")
	await await_millis(100)
	ann.make_game()
	var another := await _wait_until(func() -> bool: return _launched.size() == 2, 4000)
	(
		assert_bool(another)
		. override_failure_message("no second game once the first was played in")
		. is_true()
	)


## A server holding as many games as it may says so to anybody asking for another.
func test_a_full_server_says_so() -> void:
	_open_hall(1)
	var ann := _visitor("Ann")
	var bo := _visitor("Bo")
	var reasons: Array[String] = []
	bo.not_made.connect(func(reason: String) -> void: reasons.append(reason))
	var both := func() -> bool: return _hall.multiplayer.get_peers().size() == 2
	assert_bool(await _wait_until(both, 4000)).is_true()
	ann.make_game()
	assert_bool(await _wait_until(func() -> bool: return _hall.count() == 1, 4000)).is_true()
	bo.make_game()
	var refused := await _wait_until(func() -> bool: return not reasons.is_empty(), 4000)
	assert_bool(refused).override_failure_message("Bo was never told").is_true()
	assert_str(reasons[0]).is_equal("The server is full: it holds 1 game at once")
	assert_int(_launched.size()).is_equal(1)


## A game that never says it is up is stopped, and whoever asked for it is told.
func test_a_game_that_never_comes_up_is_stopped() -> void:
	_open_hall()
	_hall.start_wait = 0.3
	var ann := _visitor("Ann")
	var reasons: Array[String] = []
	ann.not_made.connect(func(reason: String) -> void: reasons.append(reason))
	assert_bool(await _wait_until(ann._talking, 4000)).is_true()
	ann.make_game()
	var refused := await _wait_until(func() -> bool: return not reasons.is_empty(), 4000)
	assert_bool(refused).override_failure_message("Ann was never told").is_true()
	assert_str(reasons[0]).is_equal("The server could not start a game")
	assert_array(_stopped).is_equal([1001] as Array[int])
	assert_int(_hall.count()).is_equal(0)


## A game whose process ends before it is up tells whoever asked for it, rather than leaving them
## waiting on it for ever.
func test_a_game_that_ends_before_it_is_up_is_said_so() -> void:
	_open_hall()
	var ann := _visitor("Ann")
	var reasons: Array[String] = []
	ann.not_made.connect(func(reason: String) -> void: reasons.append(reason))
	assert_bool(await _wait_until(ann._talking, 4000)).is_true()
	ann.make_game()
	assert_bool(await _wait_until(func() -> bool: return not _launched.is_empty(), 4000)).is_true()
	_ended.append(1001)
	var told := await _wait_until(func() -> bool: return not reasons.is_empty(), 4000)
	assert_bool(told).override_failure_message("Ann was never told").is_true()
	assert_str(reasons[0]).is_equal("The server could not start a game")
	assert_int(_hall.count()).is_equal(0)


## A report is only heard from the game it says it is, with that game's key.
func test_a_report_without_its_key_is_not_heard() -> void:
	_open_hall()
	var ann := _visitor("Ann")
	var ports: Array[int] = []
	ann.made.connect(func(at: int) -> void: ports.append(at))
	assert_bool(await _wait_until(ann._talking, 4000)).is_true()
	ann.make_game()
	assert_bool(await _wait_until(func() -> bool: return not _launched.is_empty(), 4000)).is_true()
	var given := _given(0)
	_games.set_dest_address("127.0.0.1", int(given["report"]))
	var state := {"players": 1}
	_games.put_packet(var_to_bytes({"game": int(given["game"]), "key": "guess", "state": state}))
	await await_millis(400)
	assert_array(ports).is_empty()
	assert_array(_hall.listing()).is_empty()


## A game that is up and then goes quiet is taken for hung, stopped and forgotten.
func test_a_game_gone_quiet_is_stopped() -> void:
	_open_hall()
	_hall.quiet_wait = 0.3
	var ann := _visitor("Ann")
	assert_bool(await _wait_until(ann._talking, 4000)).is_true()
	ann.make_game()
	assert_bool(await _wait_until(func() -> bool: return not _launched.is_empty(), 4000)).is_true()
	_up(0, 1, "Ann")
	var stopped := await _wait_until(func() -> bool: return not _stopped.is_empty(), 4000)
	assert_bool(stopped).override_failure_message("the quiet game was never stopped").is_true()
	assert_int(_hall.count()).is_equal(0)


## A game this one cannot play with is not listed to it: it is told which version the server has.
func test_another_version_is_turned_away() -> void:
	_open_hall()
	var old := _visitor("Old", "0.1.0")
	var reasons: Array[String] = []
	old.refused.connect(func(reason: String) -> void: reasons.append(reason))
	var told := await _wait_until(func() -> bool: return not reasons.is_empty(), 4000)
	assert_bool(told).override_failure_message("the old game was never told").is_true()
	assert_str(reasons[0]).is_equal(
		"Wrong version: the server has %s, you have 0.1.0" % Game.version()
	)


## LAN games at the server's port, the port a LAN game is hosted on, is told what it found there
## rather than let in to wait for a seat nobody hands out.
func test_play_lan_at_a_server_is_told_it_is_one() -> void:
	_open_hall()
	var root: Node = auto_free(Node.new())
	root.name = "LanClient"
	add_child(root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), root.get_path())
	_client_roots.append(root)
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	root.add_child(net)
	var session: NetSession = auto_free(NetSession.new())
	session.name = "Session"
	session.local_input = KartInput.new()
	session.player_name = "Lan"
	net.add_child(session)
	var reasons: Array[String] = []
	session.refused.connect(func(reason: String) -> void: reasons.append(reason))
	assert_int(session.join("127.0.0.1", port)).is_equal(OK)
	var told := await _wait_until(func() -> bool: return not reasons.is_empty(), 4000)
	assert_bool(told).override_failure_message("LAN games were never told").is_true()
	assert_str(reasons[0]).is_equal("That is a dedicated server: find its games in Play Online")


## What a server is started with, after `--`.
## The server says where it listens as it starts: every address of its machine anybody else can
## reach it on, which is not its loopback or a link-local one.
func test_the_server_says_where_it_listens() -> void:
	var addresses := PackedStringArray(
		[
			"127.0.0.1",
			"192.168.1.20",
			"::1",
			"0:0:0:0:0:0:0:1",
			"fe80::1c2b:3aff:fe4d:5e6f",
			"2001:db8::7",
			"10.8.0.2",
		]
	)
	assert_str(ServerHall.listening(7777, addresses)).is_equal(
		(
			"Listening on every address of this machine, UDP port 7777: "
			+ "192.168.1.20, 2001:db8::7 and 10.8.0.2"
		)
	)
	assert_str(ServerHall.listening(7777, PackedStringArray(["127.0.0.1", "::1"]))).contains(
		"no address but its own loopback"
	)


func test_the_arguments() -> void:
	var read := ServerArgs.read(["--server", "--port=9000", "--games=3"])
	assert_bool(read.server).is_true()
	assert_int(read.port).is_equal(9000)
	assert_array(read.game_ports()).is_equal([9001, 9002, 9003] as Array[int])
	assert_str(read.problem()).is_empty()
	var plain := ServerArgs.read([])
	# Where a LAN game is hosted, and the games on the ports after it.
	assert_int(plain.port).is_equal(7777)
	assert_int(plain.games).is_equal(ServerArgs.GAMES)
	assert_array(plain.game_ports()).is_equal([7778, 7779, 7780, 7781, 7782, 7783, 7784, 7785])
	assert_str(ServerArgs.read(["--games=0"]).problem()).is_not_empty()
	assert_str(ServerArgs.read(["--port=65530", "--games=8"]).problem()).is_not_empty()
	assert_str(ServerArgs.read(["--port=many"]).problem()).is_not_empty()
	var game := ServerArgs.read(["--server", "--game=4", "--port=7784", "--report=5555", "--key=k"])
	assert_int(game.game).is_equal(4)
	assert_int(game.report).is_equal(5555)
	assert_str(game.key).is_equal("k")


## The games' ports as a range of their own, for a firewall or a container that lets through a
## different stretch than the one after the server's port. As many games as the range has room
## for, eight at most unless asked for; asked for more than it has room for, it says so.
func test_the_games_ports_as_a_range() -> void:
	var ranged := ServerArgs.read(["--server", "--game-ports=9100-9103"])
	assert_int(ranged.port).is_equal(ServerArgs.PORT)
	assert_int(ranged.games).is_equal(4)
	assert_array(ranged.game_ports()).is_equal([9100, 9101, 9102, 9103] as Array[int])
	assert_str(ranged.problem()).is_empty()
	var wide := ServerArgs.read(["--game-ports=9100-9199"])
	assert_int(wide.games).is_equal(ServerArgs.GAMES)
	assert_int(ServerArgs.read(["--game-ports=9100-9199", "--games=20"]).game_ports()[-1]).is_equal(
		9119
	)
	var one := ServerArgs.read(["--game-ports=9100"])
	assert_array(one.game_ports()).is_equal([9100] as Array[int])
	assert_str(ServerArgs.read(["--game-ports=9100-9101", "--games=3"]).problem()).contains("2")
	assert_str(ServerArgs.read(["--game-ports=9101-9100"]).problem()).is_not_empty()
	assert_str(ServerArgs.read(["--game-ports=lots"]).problem()).is_not_empty()
	assert_str(ServerArgs.read(["--game-ports=1-2-3"]).problem()).is_not_empty()
	assert_str(ServerArgs.read(["--game-ports=9100-70000"]).problem()).is_not_empty()
	assert_str(ServerArgs.read(["--port=9102", "--game-ports=9100-9105"]).problem()).contains(
		"own port"
	)


## The same three settings from the environment, JJ_PORT, JJ_GAMES and JJ_GAME_PORTS, the way a
## container is told them, and the command line over them; an empty one is left out.
func test_the_arguments_from_the_environment() -> void:
	var told := ServerArgs.read(
		["--server"], {"JJ_PORT": "9200", "JJ_GAMES": " 3 ", "JJ_GAME_PORTS": "9300-9309"}
	)
	assert_int(told.port).is_equal(9200)
	assert_int(told.games).is_equal(3)
	assert_array(told.game_ports()).is_equal([9300, 9301, 9302] as Array[int])
	var over := ServerArgs.read(["--port=9400", "--games=2"], {"JJ_PORT": "9200", "JJ_GAMES": "3"})
	assert_int(over.port).is_equal(9400)
	assert_int(over.games).is_equal(2)
	var empty := ServerArgs.read([], {"JJ_PORT": "", "JJ_GAMES": ""})
	assert_int(empty.port).is_equal(ServerArgs.PORT)
	assert_int(empty.games).is_equal(ServerArgs.GAMES)
	var wrong := ServerArgs.read([], {"JJ_PORT": "high"})
	assert_str(wrong.problem()).contains("JJ_PORT")
	# The server's name, JJ_NAME or --name, the whole of it, cleaned the way a game's name is.
	assert_str(ServerArgs.read([], {"JJ_NAME": " Friday night "}).name).is_equal("Friday night")
	var named := ServerArgs.read(["--name=Two = one [club]"], {"JJ_NAME": "Friday night"})
	assert_str(named.name).is_equal("Two = one club")
	assert_str(ServerArgs.read([]).name).is_empty()
	# Nothing else is read from it: a game the hall starts is told its port on the command line,
	# whatever the environment it inherits says, and the environment never makes a server.
	var game := ServerArgs.read(["--server", "--game=2", "--port=9301"], {"JJ_PORT": "9200"})
	assert_int(game.port).is_equal(9301)
	assert_bool(ServerArgs.read([], {"JJ_PORT": "9200"}).server).is_equal(
		OS.has_feature("dedicated_server")
	)
