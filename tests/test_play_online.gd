extends GdUnitTestSuite
## Play Online, GAME.md 9.3a: connected to a dedicated server, the screen lists its games, makes one
## and goes into its lobby with the host's say, or into one somebody made. Against a real hall in
## this one process, with the games' processes stood in for the way test_server_hall.gd does.

const SCREEN := preload("res://scenes/ui/play_online.tscn")
## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side, and the games' after it.
var port := 7971
var _hall_root: Node
var _hall: ServerHall
var _launched: Array[PackedStringArray] = []
var _games := PacketPeerUDP.new()
var _entered: Array[MatchConfig] = []
var _settings_were: Settings


func before_test() -> void:
	_launched.clear()
	_entered.clear()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_play_online.cfg"
	_hall_root = auto_free(Node.new())
	_hall_root.name = "HallRoot"
	add_child(_hall_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _hall_root.get_path())
	_games.bind(0, "127.0.0.1")


func after_test() -> void:
	Net.close()
	_games.close()
	if is_instance_valid(_hall):
		_hall.queue_free()
	await await_idle_frame()
	get_tree().set_multiplayer(null, _hall_root.get_path())
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings = _settings_were


func _open_hall(version := "") -> void:
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	_hall_root.add_child(net)
	_hall = ServerHall.new()
	_hall.name = "Hall"
	_hall.args = ServerArgs.read(["--server", "--port=%d" % port, "--games=2"])
	_hall.home = net
	_hall.launch = func(started: PackedStringArray) -> int:
		_launched.append(started)
		return 2000 + _launched.size()
	_hall.running = func(_pid: int) -> bool: return true
	_hall.stop = func(_pid: int) -> Error: return OK
	_hall_root.add_child(_hall)
	assert_int(_hall.open()).is_equal(OK)
	if not version.is_empty():
		_hall.link.version = version


## The screen, remembering the hall as the last server so it connects as it comes up, and going
## into nothing but the test's list when it goes into a game.
func _screen() -> Control:
	Game.settings.last_server = "127.0.0.1"
	Game.settings.last_server_port = port
	Game.settings.player_names[0] = "Ann"
	var screen: Control = auto_free(SCREEN.instantiate())
	screen.enter = func(config: MatchConfig) -> void: _entered.append(config)
	add_child(screen)
	return screen


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## Says [param players] play in game [param index] of those the hall started, as its process would.
func _up(index: int, players: int, named: String) -> void:
	var given := {}
	for arg: String in _launched[index]:
		if arg.contains("="):
			given[arg.get_slice("=", 0).trim_prefix("--")] = arg.get_slice("=", 1)
	var state := {"name": named, "players": players, "most": 4, "lobby": true}
	var words := {"game": int(given["game"]), "key": given["key"], "state": state}
	_games.set_dest_address("127.0.0.1", int(given["report"]))
	_games.put_packet(var_to_bytes(words))


## Make a game starts one on the server, and the screen goes into its lobby the moment it is up,
## as the one who made it: to play, with the host's say to come, and the server remembered.
func test_make_a_game_goes_into_its_lobby_with_the_say() -> void:
	_open_hall()
	var screen := _screen()
	var connected := await _wait_until(func() -> bool: return not screen.make_button.disabled, 4000)
	(
		assert_bool(connected)
		. override_failure_message("never connected: %s" % screen.status.text)
		. is_true()
	)
	assert_str(screen.status.text).is_equal("Connected to 127.0.0.1:%d" % port)
	screen.make_button.pressed.emit()
	assert_bool(await _wait_until(func() -> bool: return not _launched.is_empty(), 4000)).is_true()
	_up(0, 0, "")
	var gone_in := await _wait_until(func() -> bool: return not _entered.is_empty(), 4000)
	assert_bool(gone_in).override_failure_message("never went into the game").is_true()
	var config := _entered[0]
	assert_str(config.online).is_equal("join")
	assert_bool(config.creating).is_true()
	assert_bool(config.watching).is_false()
	assert_str(config.address).is_equal("127.0.0.1")
	assert_int(config.port).is_equal(port + 1)
	assert_str(config.server).is_equal("127.0.0.1:%d" % port)
	assert_array(config.human_names).is_equal(["Ann"] as Array[String])
	assert_str(Game.settings.last_server).is_equal("127.0.0.1")


## Somebody else's game is listed with Join and Watch, and each goes into its lobby its own way.
func test_a_listed_game_is_joined_or_watched() -> void:
	_open_hall()
	var screen := _screen()
	var up := func() -> bool: return not screen.make_button.disabled
	assert_bool(await _wait_until(up, 4000)).is_true()
	# Somebody made a game a moment ago, and plays in it.
	_hall.make_game(_hall.multiplayer.get_peers()[0])
	assert_bool(await _wait_until(func() -> bool: return not _launched.is_empty(), 4000)).is_true()
	_entered.clear()
	_up(0, 1, "Bo")
	var games: GameList = screen._games
	var listed := await _wait_until(func() -> bool: return games.get_child_count() == 1, 4000)
	assert_bool(listed).override_failure_message("the game never showed").is_true()
	assert_str(screen._games_line.text).is_equal("Games on this server")
	var join: Button = games.find_child("Join1", true, false)
	assert_str(join.text).starts_with("Bo's game")
	_entered.clear()
	(games.find_child("Watch1", true, false) as Button).pressed.emit()
	join.pressed.emit()
	assert_int(_entered.size()).is_equal(2)
	assert_bool(_entered[0].watching).is_true()
	assert_bool(_entered[1].watching).is_false()
	assert_bool(_entered[1].creating).is_false()
	assert_int(_entered[1].port).is_equal(port + 1)


## A server this version cannot play with says so, and there is nothing to make or join there.
func test_a_server_on_another_version_says_so() -> void:
	_open_hall("0.1.0")
	var screen := _screen()
	var told := await _wait_until(
		func() -> bool: return screen.status.text.begins_with("Wrong"), 4000
	)
	assert_bool(told).override_failure_message("never told: %s" % screen.status.text).is_true()
	assert_str(screen.status.text).is_equal(
		"Wrong version: the server has 0.1.0, you have %s" % Game.version()
	)
	assert_bool(screen.make_button.disabled).is_true()


## Nobody at the address is said so, after a few seconds rather than half a minute.
func test_nobody_at_the_address_is_said_so() -> void:
	var screen := _screen()
	var told := await _wait_until(
		func() -> bool: return screen.status.text.begins_with("Could"), 4000
	)
	assert_bool(told).override_failure_message("never told: %s" % screen.status.text).is_true()
	assert_str(screen.status.text).is_equal("Could not connect to 127.0.0.1:%d" % port)


## The server is kept for next time with the rest of the settings.
func test_the_last_server_is_kept() -> void:
	var settings := Settings.new()
	settings.path = "user://test_play_online_kept.cfg"
	settings.last_server = "games.example.org"
	settings.last_server_port = 9100
	settings.save_to_disk()
	var again := Settings.new()
	again.path = settings.path
	again.load_from_disk()
	assert_str(again.last_server).is_equal("games.example.org")
	assert_int(again.last_server_port).is_equal(9100)
	DirAccess.remove_absolute(settings.path)


## Back from one of the server's games with something to say, the screen says it, and goes on
## saying it once it has connected again, which says something of its own.
func test_why_the_screen_is_up_again_stays_said() -> void:
	_open_hall()
	Game.play_online_note = "Everybody left, so the game is over"
	var screen := _screen()
	assert_str(Game.play_online_note).is_empty()
	var up := func() -> bool: return not screen.make_button.disabled
	assert_bool(await _wait_until(up, 4000)).is_true()
	assert_str(screen.status.text).is_equal("Connected to 127.0.0.1:%d" % port)
	assert_bool(screen.note.visible).is_true()
	assert_str(screen.note.text).is_equal("Everybody left, so the game is over")
