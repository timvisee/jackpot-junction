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
	Game.settings.player_names[0] = "Bo"
	screen.direct_button.pressed.emit()
	assert_bool(screen.is_form_up()).is_true()
	assert_bool(screen.connect_button.visible).is_true()
	assert_bool(screen.add_button.visible).is_false()
	assert_str(screen.address_field.text).is_equal("127.0.0.1")
	screen.connect_button.pressed.emit()
	var opened := await _wait_until(func() -> bool: return _opened[0] == 1, 4000)
	assert_bool(opened).override_failure_message("never went on: %s" % screen.busy_said()).is_true()
	assert_object(Net.link).is_not_null()
	assert_str(Net.link.address).is_equal("127.0.0.1")
	assert_int(Net.link.port).is_equal(port)
	assert_str(Game.settings.last_server).is_equal("127.0.0.1")
	assert_str(Net.link.player_name).is_equal("Bo")
	assert_bool(Game.settings.servers.is_empty()).is_true()


## Back from one of the server's games, it connects again by itself and goes on to them, leaving
## why it is back for them to say.
func test_back_from_a_game_it_connects_again_by_itself() -> void:
	_open_hall()
	Game.play_online_reconnect = true
	Game.play_online_note = "Everybody left, so the game is over"
	var screen := _screen()
	var opened := await _wait_until(func() -> bool: return _opened[0] == 1, 4000)
	assert_bool(opened).override_failure_message("never went on: %s" % screen.busy_said()).is_true()
	assert_bool(Game.play_online_reconnect).is_false()
	assert_str(Game.play_online_note).is_equal("Everybody left, so the game is over")


## Up by itself from the title, it waits for Connect.
func test_it_waits_for_connect() -> void:
	_open_hall()
	var screen := _screen()
	await await_millis(300)
	assert_int(_opened[0]).is_equal(0)
	assert_object(Net.link).is_null()
	assert_bool(screen.busy.is_open()).is_false()


## Connecting says so in a dialog with a bar that moves, and Cancel hangs up.
func test_connecting_is_a_dialog_that_cancel_hangs_up() -> void:
	var screen := _screen()
	await await_idle_frame()
	screen.direct_button.pressed.emit()
	screen.connect_button.pressed.emit()
	assert_bool(screen.busy.is_open()).is_true()
	assert_str(screen.busy._line.text).is_equal("Connecting to 127.0.0.1:%d..." % port)
	assert_bool(screen.busy_bar.visible).is_true()
	await await_millis(400)
	assert_float(screen.busy_bar.value).is_greater(0.0)
	screen.busy_button.pressed.emit()
	assert_bool(screen.busy.is_open()).is_false()
	assert_object(Net.link).is_null()


## A server this version cannot play with says so, and does not go on.
func test_a_server_on_another_version_says_so() -> void:
	_open_hall("0.1.0")
	var screen := _screen()
	screen.connect_button.pressed.emit()
	var told := await _wait_until(
		func() -> bool: return screen.busy_said().begins_with("Wrong"), 4000
	)
	assert_bool(told).override_failure_message("never told: %s" % screen.busy_said()).is_true()
	assert_str(screen.busy_button.text).is_equal("OK")
	assert_bool(screen.busy_bar.visible).is_false()
	assert_str(screen.busy_said()).is_equal(
		"Wrong version: the server has 0.1.0, you have %s" % Game.version()
	)
	assert_int(_opened[0]).is_equal(0)


## Nobody at the address is said so, after a few seconds rather than half a minute.
func test_nobody_at_the_address_is_said_so() -> void:
	var screen := _screen()
	screen.connect_button.pressed.emit()
	var told := await _wait_until(
		func() -> bool: return screen.busy_said().begins_with("Could"), 4000
	)
	assert_bool(told).override_failure_message("never told: %s" % screen.busy_said()).is_true()
	assert_str(screen.busy_said()).is_equal("Could not connect to 127.0.0.1:%d" % port)
	screen.busy_button.pressed.emit()
	assert_bool(screen.busy.is_open()).is_false()


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
	# The box is there empty, as big as full, with the link to add one alone at its top.
	var box: ListBox = screen.servers_box
	assert_bool(box.is_visible_in_tree()).is_true()
	assert_bool(box.is_empty()).is_true()
	await await_idle_frame()
	assert_float((box.link.get_parent() as Control).position.y).is_less_equal(8.0)
	assert_float(box.get_combined_minimum_size().y).is_greater(ListBox.ROOM)
	screen.adding_button.pressed.emit()
	assert_bool(screen.is_form_up()).is_true()
	assert_bool(screen.add_button.visible).is_true()
	assert_bool(screen.connect_button.visible).is_false()
	assert_str(screen.address_field.text).is_empty()
	# Nothing to keep without an address.
	screen.add_button.pressed.emit()
	assert_str(screen.dialog.said()).is_equal("Enter the server's address")
	assert_bool(screen.is_form_up()).is_true()
	assert_bool(Game.settings.servers.is_empty()).is_true()
	screen.server_name_field.text = "  Friday night  "
	# A phone's keyboard for addresses, and its keyboard for digits; a space typed is dropped, as
	# a phone's keyboard for words puts one after every dot.
	assert_int(screen.address_field.virtual_keyboard_type).is_equal(LineEdit.KEYBOARD_TYPE_URL)
	assert_int(screen.port_field.virtual_keyboard_type).is_equal(LineEdit.KEYBOARD_TYPE_NUMBER)
	screen.address_field.text = "games. example.org"
	screen.address_field.caret_column = 9
	screen.address_field.text_changed.emit(screen.address_field.text)
	assert_str(screen.address_field.text).is_equal("games.example.org")
	assert_int(screen.address_field.caret_column).is_equal(8)
	screen.address_field.text = "games.example.org"
	screen.port_field.text = "9100"
	screen.add_button.pressed.emit()
	assert_bool(screen.is_form_up()).is_false()
	assert_bool(box.is_empty()).is_false()
	assert_int(Game.settings.servers.size()).is_equal(1)
	assert_str(Game.settings.servers[0]["name"]).is_equal("Friday night")
	var row: Button = screen._servers.connect_button(0)
	assert_str(screen._servers.row_text(0)).is_equal("Friday night\ngames.example.org:9100")
	# The address under the name is the smaller and the grayer of the two.
	var named: Label = row.get_node("Words/Name")
	var where: Label = row.get_node("Words/Where")
	assert_int(where.get_theme_font_size("font_size")).is_less(
		named.get_theme_font_size("font_size")
	)
	assert_that(where.get_theme_color("font_color")).is_equal(ServerList.WHERE_INK)
	await await_idle_frame()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(row)
	# The same server again, by another name: the one row, renamed.
	screen.adding_button.pressed.emit()
	screen.address_field.text = "Games.Example.org"
	screen.port_field.text = "9100"
	screen.add_button.pressed.emit()
	assert_int(Game.settings.servers.size()).is_equal(1)
	assert_str(screen._servers.row_text(0)).is_equal("Games.Example.org:9100")
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
	assert_bool(opened).override_failure_message("never went on: %s" % screen.busy_said()).is_true()
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
	assert_bool(screen.servers_box.is_empty()).is_true()


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


## The boxes are asked for in a dialog over the list, laid out as the match settings are, GAME.md
## 9.3a: the cursor goes round its boxes and buttons and never walks off it, and Cancel puts it away
## with the cursor back on the button that put it up. The three ways on stand in a row.
func test_the_boxes_are_a_dialog_over_the_list() -> void:
	var screen := _screen()
	await await_idle_frame()
	var row: Node = screen.adding_button.get_parent()
	assert_object(row).is_instanceof(HBoxContainer)
	assert_object(screen.direct_button.get_parent()).is_same(row)
	assert_object(screen.lan_button.get_parent()).is_same(row)
	screen.direct_button.pressed.emit()
	var dialog: FormDialog = screen.dialog
	assert_bool(dialog.is_open()).is_true()
	assert_bool(screen.servers_box.is_visible_in_tree()).is_true()
	var cancel: Button = screen.cancel_button
	assert_object(cancel.get_node(cancel.focus_neighbor_bottom)).is_same(screen.address_field)
	assert_object(screen.address_field.get_node(screen.address_field.focus_neighbor_top)).is_same(
		cancel
	)
	cancel.pressed.emit()
	assert_bool(dialog.is_open()).is_false()
	await await_idle_frame()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(screen.direct_button)


## A kept server is taken off with a trash can rather than a word, and the word is its tooltip.
func test_remove_is_a_trash_can() -> void:
	Game.settings.servers.append(ServerList.entry("", "a.example.org", 7777))
	var screen := _screen()
	await await_idle_frame()
	var remove: Button = screen._servers.remove_button(0)
	assert_str(remove.text).is_empty()
	assert_str(remove.tooltip_text).is_equal("Remove")
	var picture: IconButton.Picture = remove.get_node("Picture")
	assert_int(picture.kind).is_equal(IconButton.Kind.TRASH)
	# Beside a row with a name over its address, which is the taller, it is as tall as the row.
	Game.settings.servers.append(ServerList.entry("Home", "b.example.org", 7777))
	screen.show_list()
	await await_idle_frame()
	await await_idle_frame()
	var plain: Button = screen._servers.connect_button(0)
	var named: Button = screen._servers.connect_button(1)
	var beside: Button = screen._servers.remove_button(1)
	assert_float(named.size.y).is_greater(plain.size.y)
	assert_float(beside.size.y).is_equal_approx(named.size.y, 0.5)


## GAME.md 9.3a: a kept server moves up and down the list with its arrows, the first's up and the
## last's down off, the order kept, and the cursor staying on the arrow so it can be moved on.
func test_kept_servers_move_up_and_down() -> void:
	for name: String in ["One", "Two", "Three"]:
		Game.settings.servers.append(ServerList.entry(name, "%s.example.org" % name, 7777))
	var screen := _screen()
	await await_idle_frame()
	var list: ServerList = screen._servers
	assert_bool(list.row_button("Up", 0).disabled).is_true()
	assert_bool(list.row_button("Down", 2).disabled).is_true()
	assert_bool(list.row_button("Down", 0).disabled).is_false()
	var picture: IconButton.Picture = list.row_button("Up", 1).get_node("Picture")
	assert_int(picture.kind).is_equal(IconButton.Kind.UP)
	list.row_button("Down", 0).pressed.emit()
	await await_idle_frame()
	var names := Game.settings.servers.map(func(each: Dictionary) -> String: return each["name"])
	assert_array(names).is_equal(["Two", "One", "Three"])
	assert_object(get_viewport().gui_get_focus_owner()).is_same(list.row_button("Down", 1))
	list.row_button("Up", 2).pressed.emit()
	await await_idle_frame()
	names = Game.settings.servers.map(func(each: Dictionary) -> String: return each["name"])
	assert_array(names).is_equal(["Two", "Three", "One"])
	var read := Settings.new()
	read.path = Game.settings.path
	read.load_from_disk()
	assert_str(str(read.servers[1]["name"])).is_equal("Three")


## GAME.md 9.3a: the pencil opens the dialog with the server in its boxes, and Save changes it in
## its place on the list; made into another server already on the list, it is not saved twice.
func test_a_kept_server_is_edited_in_its_place() -> void:
	Game.settings.servers.append(ServerList.entry("Home", "a.example.org", 7777))
	Game.settings.servers.append(ServerList.entry("Club", "b.example.org", 7777))
	var screen := _screen()
	await await_idle_frame()
	var list: ServerList = screen._servers
	var picture: IconButton.Picture = list.row_button("Edit", 0).get_node("Picture")
	assert_int(picture.kind).is_equal(IconButton.Kind.PENCIL)
	list.row_button("Edit", 0).pressed.emit()
	assert_bool(screen.is_form_up()).is_true()
	assert_str(screen.add_button.text).is_equal("Save")
	assert_str(screen.server_name_field.text).is_equal("Home")
	assert_str(screen.address_field.text).is_equal("a.example.org")
	screen.server_name_field.text = "Home server"
	screen.address_field.text = "c.example.org"
	screen.port_field.text = "9100"
	screen.add_button.pressed.emit()
	assert_bool(screen.is_form_up()).is_false()
	assert_int(Game.settings.servers.size()).is_equal(2)
	assert_str(str(Game.settings.servers[0]["name"])).is_equal("Home server")
	assert_str(str(Game.settings.servers[0]["address"])).is_equal("c.example.org")
	assert_int(Game.settings.servers[0]["port"]).is_equal(9100)
	# Made into the Club, which is on the list already: said, and nothing changed.
	list.row_button("Edit", 0).pressed.emit()
	screen.address_field.text = "b.example.org"
	screen.port_field.text = "7777"
	screen.add_button.pressed.emit()
	assert_bool(screen.is_form_up()).is_true()
	assert_str(screen.dialog.said()).is_equal("That server is on your list already")
	screen.cancel_button.pressed.emit()
	assert_str(str(Game.settings.servers[0]["address"])).is_equal("c.example.org")
	# And Add afterwards adds rather than edits.
	screen.adding_button.pressed.emit()
	assert_str(screen.add_button.text).is_equal("Add")


## Only an address is taken, GAME.md 9.3a: an IPv4 or IPv6 address, or a host name, with what is
## wrong said otherwise, an address with its port on it among it.
func test_only_an_address_is_taken() -> void:
	for good: String in [
		"127.0.0.1",
		"10.0.0.7",
		"::1",
		"[::1]",
		"2001:db8::42",
		"localhost",
		"games.example.org",
		"my-server.local",
		"games.example.org.",
		"a1.b2"
	]:
		assert_str(ServerList.address_problem(good)).override_failure_message(good).is_empty()
	for bad: String in [
		"999.1.1.1",
		"1.2.3",
		"-games.example.org",
		"games-.example.org",
		"games..org",
		"games_example.org",
		"games example.org",
		"http://games.example.org",
		"a".repeat(64) + ".org"
	]:
		assert_str(ServerList.address_problem(bad)).override_failure_message(bad).is_not_empty()
	assert_str(ServerList.address_problem("games.example.org:7777")).is_equal(
		"Put the port in the Port box"
	)
	var screen := _screen()
	await await_idle_frame()
	screen.adding_button.pressed.emit()
	screen.address_field.text = "games example.org"
	screen.add_button.pressed.emit()
	assert_str(screen.dialog.said()).is_equal(
		"That is not an address: use an IP address or a host name"
	)
	assert_bool(Game.settings.servers.is_empty()).is_true()
	# Nor is one kept in a settings file taken on trust.
	(
		assert_bool(ServerList.clean([{"address": "not an address", "port": 7777}]).is_empty())
		. is_true()
	)


## Under the rows of the box is a link saying how to put a server on the list, alone at the top of
## an empty one, and it opens the dialog for it, as Add a server under the box does.
func test_the_box_ends_in_a_link_to_add_a_server() -> void:
	var screen := _screen()
	await await_idle_frame()
	var box: ListBox = screen.servers_box
	assert_str(box.link.text).is_equal("Add a server")
	assert_bool(box.link.is_visible_in_tree()).is_true()
	assert_int(box.link.focus_mode).is_equal(Control.FOCUS_ALL)
	var room_round := box.link.get_parent()
	assert_object(room_round.get_parent()).is_same(box.list.get_parent())
	assert_int(room_round.get_index()).is_greater(box.list.get_index())
	# With room round it, above and below as well as either side.
	assert_float((room_round as Control).get_combined_minimum_size().y).is_greater_equal(
		box.link.get_combined_minimum_size().y + ListBox.LINK_ROOM.y * 2.0
	)
	box.link.pressed.emit()
	assert_bool(screen.is_form_up()).is_true()
	assert_bool(screen.add_button.visible).is_true()
	screen._back()
	Game.settings.servers.append(ServerList.entry("", "a.example.org", 7777))
	screen.show_list()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(box.link.is_visible_in_tree()).is_true()
	# With a server on the list, under its row.
	assert_float(box.link.global_position.y).is_greater(
		screen._servers.connect_button(0).get_global_rect().end.y
	)
