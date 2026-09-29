extends GdUnitTestSuite
## Play Online, GAME.md 9.3a: the screen that connects to a dedicated server, and goes on to its
## games once it has. Against a real hall in this one process, with the games' processes stood in
## for the way test_server_hall.gd does.

const SCREEN := preload("res://scenes/ui/play_online.tscn")
## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side, and the games' after it.
var port := 7971
var _hall_root: Node
var _hall: ServerHall
var _opened := [0]
var _settings_were: Settings


func before_test() -> void:
	_opened[0] = 0
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_play_online.cfg"
	Game.play_online_note = ""
	Game.play_online_reconnect = false
	_hall_root = auto_free(Node.new())
	_hall_root.name = "HallRoot"
	add_child(_hall_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _hall_root.get_path())


func after_test() -> void:
	Net.close()
	if is_instance_valid(_hall):
		_hall.queue_free()
	await await_idle_frame()
	get_tree().set_multiplayer(null, _hall_root.get_path())
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings = _settings_were
	Game.play_online_note = ""
	Game.play_online_reconnect = false


func _open_hall(version := "") -> void:
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	_hall_root.add_child(net)
	_hall = ServerHall.new()
	_hall.name = "Hall"
	_hall.args = ServerArgs.read(["--server", "--port=%d" % port, "--games=2"])
	_hall.home = net
	_hall.launch = func(_started: PackedStringArray) -> int: return 3000
	_hall.running = func(_pid: int) -> bool: return true
	_hall.stop = func(_pid: int) -> Error: return OK
	_hall_root.add_child(_hall)
	assert_int(_hall.open()).is_equal(OK)
	if not version.is_empty():
		_hall.link.version = version


## The screen, with the hall as the last server in its boxes, going nowhere once connected but the
## test's count.
func _screen() -> Control:
	Game.settings.last_server = "127.0.0.1"
	Game.settings.last_server_port = port
	Game.settings.player_names[0] = "Ann"
	var screen: Control = auto_free(SCREEN.instantiate())
	screen.open_games = func() -> void: _opened[0] += 1
	add_child(screen)
	return screen


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## Connect knocks at the server in the boxes, remembers it and the name, and once it is let in goes
## on to its games, keeping the connection for them.
func test_connect_goes_on_to_the_games() -> void:
	_open_hall()
	var screen := _screen()
	assert_int(_opened[0]).is_equal(0)
	screen.name_field.text = "Bo"
	screen.connect_button.pressed.emit()
	var opened := await _wait_until(func() -> bool: return _opened[0] == 1, 4000)
	assert_bool(opened).override_failure_message("never went on: %s" % screen.status.text).is_true()
	assert_object(Net.link).is_not_null()
	assert_str(Net.link.address).is_equal("127.0.0.1")
	assert_int(Net.link.port).is_equal(port)
	assert_str(Game.settings.last_server).is_equal("127.0.0.1")
	assert_str(Game.settings.player_names[0]).is_equal("Bo")


## Back from one of the server's games, it connects again by itself and goes on to them, leaving
## why it is back for them to say.
func test_back_from_a_game_it_connects_again_by_itself() -> void:
	_open_hall()
	Game.play_online_reconnect = true
	Game.play_online_note = "Everybody left, so the game is over"
	var screen := _screen()
	var opened := await _wait_until(func() -> bool: return _opened[0] == 1, 4000)
	assert_bool(opened).override_failure_message("never went on: %s" % screen.status.text).is_true()
	assert_bool(Game.play_online_reconnect).is_false()
	assert_str(Game.play_online_note).is_equal("Everybody left, so the game is over")


## Up by itself from the title, it waits for Connect.
func test_it_waits_for_connect() -> void:
	_open_hall()
	var screen := _screen()
	await await_millis(300)
	assert_int(_opened[0]).is_equal(0)
	assert_object(Net.link).is_null()
	assert_str(screen.status.text).is_empty()


## A server this version cannot play with says so, and does not go on.
func test_a_server_on_another_version_says_so() -> void:
	_open_hall("0.1.0")
	var screen := _screen()
	screen.connect_button.pressed.emit()
	var told := await _wait_until(
		func() -> bool: return screen.status.text.begins_with("Wrong"), 4000
	)
	assert_bool(told).override_failure_message("never told: %s" % screen.status.text).is_true()
	assert_str(screen.status.text).is_equal(
		"Wrong version: the server has 0.1.0, you have %s" % Game.version()
	)
	assert_int(_opened[0]).is_equal(0)


## Nobody at the address is said so, after a few seconds rather than half a minute.
func test_nobody_at_the_address_is_said_so() -> void:
	var screen := _screen()
	screen.connect_button.pressed.emit()
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
