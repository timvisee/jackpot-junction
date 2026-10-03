extends GdUnitTestSuite
## Play Online, GAME.md 9.3a: the servers a player keeps, Add a server, Direct connect and LAN
## games, and the connecting to a server, which goes on to its games once it has. Against a real
## hall in this one process, with the games' processes stood in for the way test_server_hall.gd
## does.

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
	Settings.remove_files(Game.settings.path)
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
	screen.open_lan = func(_note: String) -> void: _opened[0] += 100
	add_child(screen)
	return screen


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## Direct connect puts up the boxes, with the last server in them; Connect knocks at the server in
## them, remembers it and the name without keeping it on the list, and once it is let in goes on to
## its games, keeping the connection for them.
func test_connect_goes_on_to_the_games() -> void:
	_open_hall()
	var screen := _screen()
	assert_int(_opened[0]).is_equal(0)
	screen.name_field.text = "Bo"
	screen.direct_button.pressed.emit()
	assert_bool(screen.is_form_up()).is_true()
	assert_bool(screen.connect_button.visible).is_true()
	assert_bool(screen.add_button.visible).is_false()
	assert_str(screen.address_field.text).is_equal("127.0.0.1")
	screen.connect_button.pressed.emit()
	var opened := await _wait_until(func() -> bool: return _opened[0] == 1, 4000)
	assert_bool(opened).override_failure_message("never went on: %s" % screen.status.text).is_true()
	assert_object(Net.link).is_not_null()
	assert_str(Net.link.address).is_equal("127.0.0.1")
	assert_int(Net.link.port).is_equal(port)
	assert_str(Game.settings.last_server).is_equal("127.0.0.1")
	assert_str(Game.settings.player_names[0]).is_equal("Bo")
	assert_bool(Game.settings.servers.is_empty()).is_true()


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
	Settings.remove_files(settings.path)


## The list is empty to start with and says so; Add a server keeps one, under a name or none, and
## the list shows it with the cursor on it. Added again it is called what it is called now rather
## than kept twice, and the list is kept with the rest of the settings.
func test_add_keeps_a_server_on_the_list() -> void:
	var screen := _screen()
	await await_idle_frame()
	assert_bool(screen.is_form_up()).is_false()
	var none: Label = screen._none
	assert_bool(none.visible).is_true()
	assert_str(none.text).is_equal("No servers yet. Add one or connect directly.")
	screen.adding_button.pressed.emit()
	assert_bool(screen.is_form_up()).is_true()
	assert_bool(screen.add_button.visible).is_true()
	assert_bool(screen.connect_button.visible).is_false()
	assert_str(screen.address_field.text).is_empty()
	# Nothing to keep without an address.
	screen.add_button.pressed.emit()
	assert_str(screen.status.text).is_equal("Enter the server's address")
	assert_bool(Game.settings.servers.is_empty()).is_true()
	screen.server_name_field.text = "  Friday night  "
	screen.address_field.text = "games.example.org"
	screen.port_field.text = "9100"
	screen.add_button.pressed.emit()
	assert_bool(screen.is_form_up()).is_false()
	assert_bool(none.visible).is_false()
	assert_int(Game.settings.servers.size()).is_equal(1)
	assert_str(Game.settings.servers[0]["name"]).is_equal("Friday night")
	var row: Button = screen._servers.connect_button(0)
	assert_str(row.text).is_equal("Friday night\ngames.example.org:9100")
	await await_idle_frame()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(row)
	# The same server again, by another name: the one row, renamed.
	screen.adding_button.pressed.emit()
	screen.address_field.text = "Games.Example.org"
	screen.port_field.text = "9100"
	screen.add_button.pressed.emit()
	assert_int(Game.settings.servers.size()).is_equal(1)
	assert_str(screen._servers.connect_button(0).text).is_equal("Games.Example.org:9100")
	var again := Settings.new()
	again.path = Game.settings.path
	again.load_from_disk()
	assert_int(again.servers.size()).is_equal(1)
	assert_str(again.servers[0]["address"]).is_equal("Games.Example.org")
	assert_int(again.servers[0]["port"]).is_equal(9100)


## A kept server's row connects to it, and goes on to its games.
func test_a_kept_server_connects_in_one_press() -> void:
	_open_hall()
	Game.settings.servers.append(ServerList.entry("Home", "127.0.0.1", port))
	var screen := _screen()
	await await_idle_frame()
	screen._servers.connect_button(0).pressed.emit()
	var opened := await _wait_until(func() -> bool: return _opened[0] == 1, 4000)
	assert_bool(opened).override_failure_message("never went on: %s" % screen.status.text).is_true()
	assert_int(Game.settings.last_server_port).is_equal(port)


## Remove asks first, and Keep keeps it; Remove takes it off, and an empty list says so again.
func test_remove_asks_first() -> void:
	Game.settings.servers.append(ServerList.entry("", "a.example.org", 7777))
	Game.settings.servers.append(ServerList.entry("", "b.example.org", 7777))
	var screen := _screen()
	await await_idle_frame()
	var ask: ConfirmPane = screen._ask
	screen._servers.remove_button(0).pressed.emit()
	assert_bool(ask.visible).is_true()
	assert_str(ask.said()).contains("a.example.org:7777")
	ask.no_button().pressed.emit()
	assert_bool(ask.visible).is_false()
	assert_int(Game.settings.servers.size()).is_equal(2)
	screen._servers.remove_button(0).pressed.emit()
	ask.yes_button().pressed.emit()
	assert_int(Game.settings.servers.size()).is_equal(1)
	assert_str(Game.settings.servers[0]["address"]).is_equal("b.example.org")
	screen._servers.remove_button(0).pressed.emit()
	ask.yes_button().pressed.emit()
	assert_bool(Game.settings.servers.is_empty()).is_true()
	assert_bool(screen._none.visible).is_true()


## Back from the boxes is the list again, and LAN games goes on to the games on the network.
func test_back_from_the_boxes_and_on_to_lan_games() -> void:
	var screen := _screen()
	await await_idle_frame()
	screen.direct_button.pressed.emit()
	screen._back()
	assert_bool(screen.is_form_up()).is_false()
	screen.lan_button.pressed.emit()
	assert_int(_opened[0]).is_equal(100)


## What a settings file says the kept servers are is cleaned: anything that is not one is left out,
## and there are never more than the list keeps.
func test_kept_servers_are_cleaned() -> void:
	var raw: Array = [
		{"name": "Ok", "address": " x.example.org ", "port": 7777},
		{"name": "No port", "address": "y.example.org"},
		{"address": "", "port": 7777},
		{"address": "z.example.org", "port": 70000},
		"a string",
	]
	var kept := ServerList.clean(raw)
	assert_int(kept.size()).is_equal(1)
	assert_str(kept[0]["address"]).is_equal("x.example.org")
	assert_bool(ServerList.clean("garbage").is_empty()).is_true()
	var many: Array = []
	for i: int in ServerList.MOST + 5:
		many.append({"name": "", "address": "s%d.example.org" % i, "port": 7777})
	assert_int(ServerList.clean(many).size()).is_equal(ServerList.MOST)
