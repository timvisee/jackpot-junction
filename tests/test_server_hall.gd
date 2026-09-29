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
	_ended.append(1001)
	var gone := await _wait_until(func() -> bool: return lists[-1].is_empty(), 4000)
	assert_bool(gone).override_failure_message("the game stayed in the list").is_true()
	assert_int(_hall.count()).is_equal(0)


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


## What a server is started with, after `--`.
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
