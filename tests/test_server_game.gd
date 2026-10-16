extends GdUnitTestSuite
## One game of a dedicated server, GAME.md 9.3a, as the process the server started it in runs it:
## the real waiting room hosted with nobody at it, reporting to a server the test stands in for,
## and ending by itself once everybody has gone, or nobody has come, or the server has.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")
const WAITING_RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const WAITING_MAP: ArenaLayout = preload("res://data/maps/waiting_room.tres")
## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

## A block of free ports of its own for every test, see tests/free_ports.gd.
var port := 0
var _hall := PacketPeerUDP.new()
var _game: ServerGame
var _finished := false
## Everything the game has said to the server, its lines and its reports in turn.
var _lines: Array[String] = []
var _states: Array[Dictionary] = []
## How far along it said it was while it was being made, in turn.
var _making: Array[float] = []
var _over := false
## Whether the stand-in server answers, the way a server tells its games it is still there.
var _answering := true
var _client_root: Node
var _settings_were: Settings


func before_test() -> void:
	port = FreePorts.take()
	_lines.clear()
	_states.clear()
	_making.clear()
	_over = false
	_finished = false
	_answering = true
	_hall.bind(0, "127.0.0.1")
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = ""


func after_test() -> void:
	if is_instance_valid(_game):
		_game.free()
	_hall.close()
	if _client_root != null:
		get_tree().set_multiplayer(null, _client_root.get_path())
		_client_root = null
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	Game.settings = _settings_were


## The game, started the way the server starts one, with its room put up by the test rather than by
## a change of scene, which would pull the tree out from under the runner.
func _start_game() -> void:
	_game = ServerGame.new()
	_game.name = "ServerGame"
	_game.args = ServerArgs.read(
		["--server", "--game=3", "--port=%d" % port, "--report=%d" % _hall.get_local_port()]
	)
	_game.args.key = "k"
	_game.open_room = func(config: MatchConfig) -> void:
		Game.pending_config = config
		var room: Node3D = auto_free(WAITING_SCENE.instantiate())
		add_child(room)
	_game.finish = func() -> void: _finished = true
	add_child(_game)


## Reads what the game has said since last time, and answers the way the server does.
func _listen() -> void:
	while _hall.get_available_packet_count() > 0:
		var said: Variant = bytes_to_var(_hall.get_packet())
		var from := _hall.get_packet_port()
		if not said is Dictionary or str(said.get("key", "")) != "k":
			continue
		if said.has("log"):
			_lines.append(str(said["log"]))
		if said.get("state") is Dictionary:
			_states.append(said["state"])
		if said.has("making"):
			_making.append(float(said["making"]))
		_over = _over or bool(said.get("over", false))
		if _answering:
			_hall.set_dest_address("127.0.0.1", from)
			_hall.put_packet(var_to_bytes({"alive": true}))


## Waits on frames rather than a timer, since the room stops the tree once nobody plays in it.
func _wait_until(condition: Callable, max_millis: int) -> bool:
	var until := Time.get_ticks_msec() + max_millis * PATIENCE
	while Time.get_ticks_msec() < until:
		_listen()
		if condition.call():
			return true
		await get_tree().process_frame
	_listen()
	return condition.call()


func _said(line: String) -> bool:
	return line in _lines


## A client of its own, knocking at the game the way a player's screen does, under Net as a room's
## own session is.
func _client(named: String) -> NetSession:
	_client_root = auto_free(Node.new())
	_client_root.name = "ClientRoot"
	add_child(_client_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _client_root.get_path())
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = WAITING_RULES.duplicate()
	client_match.arena_layout = WAITING_MAP
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	_client_root.add_child(net)
	var session: NetSession = auto_free(NetSession.new())
	session.name = "Session"
	session.match_node = client_match
	session.local_input = KartInput.new()
	session.player_name = named
	net.add_child(session)
	assert_int(session.join("127.0.0.1", port)).is_equal(OK)
	return session


## Up, it says so; a player coming in is written down and has the host's say, and the game says it
## is theirs; once they have gone, it is over, and the process goes.
func test_a_game_says_who_comes_and_goes_and_ends_when_everybody_has() -> void:
	_start_game()
	var up := await _wait_until(_said.bind("Up on port %d" % port), 8000)
	# On its way up it said how far along it was, for whoever asked for it: running, and then its
	# room a phase at a time, never going back, and never saying it was all the way.
	assert_float(_making[0]).is_equal(ServerLink.MAKING_BOOTED)
	assert_int(_making.size()).is_greater(5)
	for i: int in range(1, _making.size()):
		assert_float(_making[i]).is_greater_equal(_making[i - 1])
	assert_float(_making[-1]).is_equal_approx(ServerLink.MAKING_BUILT, 0.001)
	(
		assert_bool(up)
		. override_failure_message("the game never said it was up: %s" % [_lines])
		. is_true()
	)
	assert_bool(await _wait_until(func() -> bool: return not _states.is_empty(), 4000)).is_true()
	assert_int(int(_states[-1]["players"])).is_equal(0)
	assert_bool(bool(_states[-1]["lobby"])).is_true()
	var ann := _client("Ann")
	var arrived := await _wait_until(_said.bind("Ann came in to play, from 127.0.0.1"), 4000)
	(
		assert_bool(arrived)
		. override_failure_message("Ann's arrival was never said: %s" % [_lines])
		. is_true()
	)
	var says := await _wait_until(_said.bind("Ann has the host's say"), 4000)
	assert_bool(says).override_failure_message("the say was never said: %s" % [_lines]).is_true()
	var theirs := func() -> bool: return not _states.is_empty() and int(_states[-1]["players"]) == 1
	assert_bool(await _wait_until(theirs, 4000)).is_true()
	assert_str(str(_states[-1]["name"])).is_not_empty()
	ann.multiplayer.multiplayer_peer.close()
	var over := await _wait_until(_said.bind("Everybody left, so the game is over"), 4000)
	assert_bool(over).override_failure_message("the end was never said: %s" % [_lines]).is_true()
	assert_bool(_said("Ann left")).is_true()
	assert_bool(await _wait_until(func() -> bool: return _finished, 4000)).is_true()
	assert_bool(_over).is_true()


## A game nobody comes to does not wait for ever.
func test_a_game_nobody_comes_to_ends_by_itself() -> void:
	_start_game()
	_game.first_wait = 0.5
	var over := await _wait_until(_said.bind("Nobody came, so the game is over"), 8000)
	assert_bool(over).override_failure_message("it waited: %s" % [_lines]).is_true()
	assert_bool(await _wait_until(func() -> bool: return _finished, 4000)).is_true()


## A game whose server has gone quiet goes too, rather than running on with nobody to list it.
func test_a_game_the_server_has_left_ends_by_itself() -> void:
	_start_game()
	_answering = false
	_game.orphan_wait = 0.5
	var over := await _wait_until(_said.bind("Lost the server, so the game is over"), 8000)
	assert_bool(over).override_failure_message("it ran on: %s" % [_lines]).is_true()
	assert_bool(await _wait_until(func() -> bool: return _finished, 4000)).is_true()
