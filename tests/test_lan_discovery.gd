extends GdUnitTestSuite
## Finding games on the network, GAME.md 9.3: the LAN games screen asks, and a host answers with
## whose game it is and how it stands. Both ends in this one process, on ports of their own.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const ONLINE_SCENE := preload("res://scenes/ui/online.tscn")
const PORT := 7871
const LISTEN := 7879

var _host_root: Node


func before_test() -> void:
	_host_root = auto_free(Node.new())
	_host_root.name = "HostRoot"
	add_child(_host_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _host_root.get_path())


func after_test() -> void:
	get_tree().set_multiplayer(null, _host_root.get_path())


func test_the_lan_screen_finds_a_hosted_game_and_what_it_is() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	host_match.slots[0].player_name = "Ann"
	var session: NetSession = auto_free(NetSession.new())
	session.name = "Session"
	session.match_node = host_match
	_host_root.add_child(session)
	assert_int(session.host(PORT)).is_equal(OK)
	session.door.password = "sesame"
	session.door.max_players = 3
	LanBeacon.open(session, PORT, LISTEN)
	var finder: LanFinder = auto_free(LanFinder.new())
	finder.listen = LISTEN
	add_child(finder)
	var waited := 0
	while finder.games().is_empty() and waited < 6000:
		await await_millis(50)
		waited += 50
	assert_int(finder.games().size()).override_failure_message("no game was found").is_equal(1)
	var game: Dictionary = finder.games()[0]
	assert_str(game["name"]).is_equal("Ann")
	assert_int(game["port"]).is_equal(PORT)
	assert_int(game["players"]).is_equal(1)
	assert_int(game["most"]).is_equal(3)
	assert_bool(game["password"]).is_true()
	assert_bool(game["lobby"]).is_true()
	assert_str(game["address"]).is_not_empty()
	var line := GameList.describe(game)
	assert_str(line).is_equal("Ann's game · in the lobby · 1/3 players · password")
	assert_bool(game["watching"]).is_true()
	assert_bool(game["watch_password"]).is_true()
	# On the LAN games screen it is a row: the button that joins it, and Watch beside it.
	var screen: Control = auto_free(ONLINE_SCENE.instantiate())
	add_child(screen)
	screen.finder.queue_free()
	screen.finder = finder
	finder.changed.connect(screen._show_found)
	screen._show_found()
	var id := int(game["id"])
	var watch: Button = screen._found.find_child("Watch%d" % id, true, false)
	assert_object(watch).is_not_null()
	assert_bool(watch.disabled).is_false()
	var join: Button = screen._found.find_child("Join%d" % id, true, false)
	assert_object(join).is_not_null()
	# Where the game is hosted, said when a pointer rests on it.
	assert_str(join.tooltip_text).is_equal("Host: %s:%d" % [game["address"], PORT])
	# Shut to watchers, Watch cannot be pressed.
	session.door.watchers_allowed = false
	waited = 0
	while finder.games()[0]["watching"] and waited < 6000:
		await await_millis(50)
		waited += 50
	watch = screen._found.find_child("Watch%d" % id, true, false)
	assert_bool(watch.disabled).is_true()
	screen.queue_free()
	# Gone quiet, it is forgotten.
	session.queue_free()
	await await_millis(int(LanFinder.FORGET_AFTER * 1000.0) + 600)
	assert_bool(finder.games().is_empty()).is_true()
