extends GdUnitTestSuite
## Finding games on the network, GAME.md 9.3: the LAN games screen asks, and a host answers with
## whose game it is and how it stands. Both ends in this one process, on ports of their own.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const ONLINE_SCENE := preload("res://scenes/ui/online.tscn")
## A block of free ports of its own for every test, see tests/free_ports.gd.
var port := 0

var _host_root: Node


func before_test() -> void:
	port = FreePorts.take()
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
	assert_int(session.host(port)).is_equal(OK)
	session.door.password = "sesame"
	session.door.max_players = 3
	LanBeacon.open(session, port, port + 8)
	var finder: LanFinder = auto_free(LanFinder.new())
	finder.listen = (port + 8)
	add_child(finder)
	var waited := 0
	while finder.games().is_empty() and waited < 6000:
		await await_millis(50)
		waited += 50
	assert_int(finder.games().size()).override_failure_message("no game was found").is_equal(1)
	var game: Dictionary = finder.games()[0]
	assert_str(game["name"]).is_equal("Ann")
	assert_int(game["port"]).is_equal(port)
	assert_int(game["players"]).is_equal(1)
	assert_int(game["most"]).is_equal(3)
	assert_bool(game["password"]).is_true()
	assert_bool(game["lobby"]).is_true()
	assert_str(game["address"]).is_not_empty()
	# Hosted by a test, it says it is one, see [method NetDoor.listed_title].
	assert_str(GameList.title_of(game)).is_equal(NetDoor.TEST_TITLE)
	assert_str(GameList.describe(game)).is_equal("In the lobby · 1/3 players · password")
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
	assert_str(join.tooltip_text).is_equal("Host: %s:%d" % [game["address"], port])
	assert_str(screen._found.row_text(id)).is_equal(
		"Test game\nIn the lobby · 1/3 players · password"
	)
	# Named by its host, it is listed by that name.
	session.door.title = "Friday night"
	waited = 0
	while GameList.title_of(finder.games()[0]) == NetDoor.TEST_TITLE and waited < 6000:
		await await_millis(50)
		waited += 50
	assert_str(GameList.title_of(finder.games()[0])).is_equal("Friday night (test)")
	assert_str(screen._found.row_text(id)).starts_with("Friday night (test)\n")
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


## GAME.md 9.3: a game is listed by its name, or its host's game with none, over how it stands: in
## the lobby, or on which map; the map is left out for a host that did not say it.
func test_a_game_is_said_by_its_name_and_where_it_is() -> void:
	var game := {
		"name": "Ann",
		"title": "",
		"map": "Crossfire, map 2 of 3",
		"players": 3,
		"most": 4,
		"password": false,
		"lobby": false,
		"version": Game.version(),
	}
	assert_str(GameList.title_of(game)).is_equal("Ann's game")
	assert_str(GameList.describe(game)).is_equal("Playing Crossfire, map 2 of 3 · 3/4 players")
	game["title"] = "  [Friday] night  "
	assert_str(GameList.title_of(game)).is_equal("Friday night")
	game.erase("map")
	game.erase("title")
	assert_str(GameList.describe(game)).is_equal("Playing · 3/4 players")
	assert_str(GameList.title_of({"name": ""})).is_equal("Host's game")


## A game a test hosts says it is one, since it answers anybody on the network looking, its
## developer's own game among them; the game itself lists its name as given.
func test_a_tests_game_says_it_is_one() -> void:
	assert_bool(NetDoor.a_test_runs()).is_true()
	var door := NetDoor.new()
	assert_str(door.listed_title()).is_equal("Test game")
	assert_str(door.listed_title(false)).is_empty()
	door.title = "x".repeat(PlayerNames.TITLE_LENGTH)
	assert_str(door.listed_title()).ends_with(" (test)")
	assert_int(door.listed_title().length()).is_equal(PlayerNames.TITLE_LENGTH)
	assert_str(door.listed_title(false)).is_equal(door.title)
