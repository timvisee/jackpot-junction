extends GdUnitTestSuite
## The games on a dedicated server, GAME.md 9.3a, on the screen Play Online goes on to once it has
## connected: listed, made, joined and watched, and left. Against a real hall in this one process,
## with the games' processes stood in for the way test_server_hall.gd does.

const SCREEN := preload("res://scenes/ui/server_games.tscn")
## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side, and the games' after it.
var port := 7981
var _hall_root: Node
var _hall: ServerHall
var _launched: Array[PackedStringArray] = []
var _games := PacketPeerUDP.new()
var _entered: Array[MatchConfig] = []
var _left: Array[String] = []
var _settings_were: Settings


func before_test() -> void:
	_launched.clear()
	_entered.clear()
	_left.clear()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = ""
	Game.settings.player_names[0] = "Ann"
	Game.play_online_note = ""
	_hall_root = auto_free(Node.new())
	_hall_root.name = "HallRoot"
	add_child(_hall_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _hall_root.get_path())
	_games.bind(0, "127.0.0.1")
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	_hall_root.add_child(net)
	_hall = ServerHall.new()
	_hall.name = "Hall"
	_hall.args = ServerArgs.read(["--server", "--port=%d" % port, "--games=2"])
	_hall.home = net
	_hall.launch = func(started: PackedStringArray) -> int:
		_launched.append(started)
		return 4000 + _launched.size()
	_hall.running = func(_pid: int) -> bool: return true
	_hall.stop = func(_pid: int) -> Error: return OK
	_hall_root.add_child(_hall)
	assert_int(_hall.open()).is_equal(OK)


func after_test() -> void:
	Net.close()
	_games.close()
	if is_instance_valid(_hall):
		_hall.queue_free()
	await await_idle_frame()
	get_tree().set_multiplayer(null, _hall_root.get_path())
	Game.settings = _settings_were
	Game.play_online_note = ""


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## Connected the way Play Online connects, and then the screen, going into games and back to
## Play Online only as far as the test's lists.
func _screen() -> ServerGames:
	var link := Net.open_link()
	link.player_name = "Ann"
	assert_int(link.reach("127.0.0.1", port)).is_equal(OK)
	var up := await _wait_until(link._talking, 4000)
	assert_bool(up).override_failure_message("never connected").is_true()
	var screen: ServerGames = auto_free(SCREEN.instantiate())
	screen.enter = func(config: MatchConfig) -> void: _entered.append(config)
	screen.leave = func(why: String) -> void: _left.append(why)
	add_child(screen)
	return screen


## Says [param players] play in game [param index] of those the hall started, as its process would.
func _up(index: int, players: int, named: String) -> void:
	var state := {"name": named, "players": players, "most": 4, "lobby": true}
	_report(index, {"state": state})


## Says [param words] to the hall as game [param index] of those it started.
func _report(index: int, words: Dictionary) -> void:
	var given := {}
	for arg: String in _launched[index]:
		if arg.contains("="):
			given[arg.get_slice("=", 0).trim_prefix("--")] = arg.get_slice("=", 1)
	words["game"] = int(given["game"])
	words["key"] = given["key"]
	_games.set_dest_address("127.0.0.1", int(given["report"]))
	_games.put_packet(var_to_bytes(words))


## Make a game starts one on the server, and the screen goes into its lobby the moment it is up,
## as the one who made it: to play, with the host's say to come.
func test_make_a_game_goes_into_its_lobby_with_the_say() -> void:
	var screen := await _screen()
	# The games' box is there with none in it but the link that makes one, as the button under it
	# does.
	assert_bool(screen._box.is_empty()).is_true()
	assert_str(screen._box.link.text).is_equal("Make a game")
	screen.make_button.pressed.emit()
	assert_bool(screen.make_button.disabled).is_true()
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


## While the game is being made a bar under the line saying so follows it, from its process being
## started to its room being built, as the game says, and it goes once the game cannot be made.
func test_a_bar_follows_the_game_being_made() -> void:
	var screen := await _screen()
	assert_bool(screen.making_bar.visible).is_false()
	screen.make_button.pressed.emit()
	assert_bool(screen.making_bar.visible).is_true()
	assert_bool(screen.busy.is_open()).is_true()
	var at := func(done: float) -> Callable:
		return func() -> bool: return is_equal_approx(screen.making_bar.value, done)
	var started := await _wait_until(at.call(ServerLink.MAKING_STARTED), 4000)
	assert_bool(started).override_failure_message("the bar never moved").is_true()
	_report(0, {"making": 0.7})
	var along := await _wait_until(at.call(0.7), 4000)
	assert_bool(along).override_failure_message("the bar never followed the game").is_true()
	# Word of less than the bar shows, out of order, never takes it back.
	_report(0, {"making": 0.6})
	await await_millis(300)
	assert_float(screen.making_bar.value).is_equal_approx(0.7, 0.001)
	screen.link.not_made.emit("The server could not start a game")
	assert_bool(screen.making_bar.visible).is_false()
	assert_bool(screen.make_button.disabled).is_false()
	# Said in the dialog, with OK to put it away.
	assert_str(screen.busy.said()).is_equal("The server could not start a game")
	assert_bool(screen.busy_button.visible).is_true()
	screen.busy_button.pressed.emit()
	assert_bool(screen.busy.is_open()).is_false()


## Somebody else's game is listed with Join and the eye that watches it, and each goes into its
## lobby its own way. Over the box, the line says which server this is.
func test_a_listed_game_is_joined_or_watched() -> void:
	var screen := await _screen()
	var said := screen.find_children("*", "Label", true, false).map(
		func(each: Node) -> String: return (each as Label).text
	)
	(
		assert_bool(
			"Connected to 127.0.0.1:%d. Join a game on this server, or make one now." % port in said
		)
		. is_true()
	)
	_hall.make_game(_hall.multiplayer.get_peers()[0])
	assert_bool(await _wait_until(func() -> bool: return not _launched.is_empty(), 4000)).is_true()
	_entered.clear()
	_up(0, 1, "Bo")
	var games: GameList = screen._games
	var listed := await _wait_until(func() -> bool: return games.get_child_count() == 1, 4000)
	assert_bool(listed).override_failure_message("the game never showed").is_true()
	assert_bool(screen._box.is_empty()).is_false()
	var join: Button = games.find_child("Join1", true, false)
	assert_str(join.text).starts_with("Bo's game")
	_entered.clear()
	var watch: Button = games.find_child("Watch1", true, false)
	assert_str(watch.text).is_empty()
	assert_int((watch.get_node("Picture") as IconButton.Picture).kind).is_equal(IconButton.Kind.EYE)
	watch.pressed.emit()
	join.pressed.emit()
	assert_int(_entered.size()).is_equal(2)
	assert_bool(_entered[0].watching).is_true()
	assert_bool(_entered[1].watching).is_false()
	assert_bool(_entered[1].creating).is_false()
	assert_int(_entered[1].port).is_equal(port + 1)


## Back from one of the server's games, the screen says why, the once.
func test_why_the_screen_is_up_again_is_said() -> void:
	Game.play_online_note = "The host removed you from the game"
	var screen := await _screen()
	assert_bool(screen.note.visible).is_true()
	assert_str(screen.note.text).is_equal("The host removed you from the game")
	assert_str(Game.play_online_note).is_empty()


## Back hangs up and goes back to Play Online, and so does the server going away, saying so.
func test_back_and_the_server_going_both_go_back_to_play_online() -> void:
	var screen := await _screen()
	var back: Button = null
	for button: Node in screen.find_children("*", "Button", true, false):
		if (button as Button).text == "Back":
			back = button
	back.pressed.emit()
	assert_array(_left).is_equal([""] as Array[String])
	_hall.queue_free()
	var gone := await _wait_until(func() -> bool: return _left.size() == 2, 4000)
	assert_bool(gone).override_failure_message("the server going was never noticed").is_true()
	assert_str(_left[1]).is_equal("The server closed the connection")
