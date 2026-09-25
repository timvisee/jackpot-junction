extends GdUnitTestSuite
## Who a host lets into its game and shows out of it, GAME.md 10.3: kicked from Manage players,
## over a real socket between two sessions in this one process.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const PORT := 7861
## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

var _host_root: Node
var _client_root: Node
var _host: NetSession
var _host_match: Match


func before_test() -> void:
	_host_root = auto_free(Node.new())
	_host_root.name = "HostRoot"
	add_child(_host_root)
	_client_root = auto_free(Node.new())
	_client_root.name = "ClientRoot"
	add_child(_client_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _host_root.get_path())
	get_tree().set_multiplayer(SceneMultiplayer.new(), _client_root.get_path())


func after_test() -> void:
	get_tree().set_multiplayer(null, _host_root.get_path())
	get_tree().set_multiplayer(null, _client_root.get_path())


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	return rules


func _open_host() -> void:
	_host_match = auto_free(MATCH_SCENE.instantiate())
	_host_match.name = "Match"
	_host_match.rules = _rules()
	_host_match.with_hud = false
	_host_match.offer_size = 0
	_host_root.add_child(_host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	_host_match.start(inputs, 23)
	_host = auto_free(NetSession.new())
	_host.name = "Session"
	_host.match_node = _host_match
	_host_root.add_child(_host)
	assert_int(_host.host(PORT)).is_equal(OK)


## A client knocking at the host opened by [method _open_host], [param watching] or to play, with
## [param given] for a password.
func _client(watching := false, named := "Guest", given := "") -> NetSession:
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var session: NetSession = auto_free(NetSession.new())
	session.name = "Session"
	session.match_node = client_match
	session.local_input = KartInput.new()
	session.watching = watching
	session.player_name = named
	session.password = given
	_client_root.add_child(session)
	assert_int(session.join("127.0.0.1", PORT)).is_equal(OK)
	return session


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## Kicked: told why, disconnected, and the seat it had is a bot's again, since this is a match.
func test_the_host_kicks_a_client_out_of_its_game() -> void:
	_open_host()
	var client := _client()
	var told := [""]
	client.refused.connect(func(reason: String) -> void: told[0] = reason)
	var seated := await _wait_until(func() -> bool: return _host.guests().size() == 1, 4000)
	assert_bool(seated).override_failure_message("the client never sat down").is_true()
	var guest: Dictionary = _host.guests()[0]
	assert_str(guest["name"]).is_equal("Guest")
	_host.kick(guest["peer"])
	var gone := await _wait_until(func() -> bool: return not told[0].is_empty(), 4000)
	assert_bool(gone).override_failure_message("the client was never told").is_true()
	assert_str(told[0]).is_equal("The host removed you from the game")
	var empty := await _wait_until(func() -> bool: return _host.guests().is_empty(), 4000)
	assert_bool(empty).is_true()
	assert_bool(_host_match.slots[1].is_human()).is_false()


## Somebody watching is on the list by the name they gave, and can be shown out the same way.
func test_a_watcher_is_named_and_can_be_kicked() -> void:
	_open_host()
	var watcher := _client(true, "Couch Kim")
	var told := [""]
	watcher.refused.connect(func(reason: String) -> void: told[0] = reason)
	var seen := await _wait_until(func() -> bool: return _host.guests().size() == 1, 4000)
	assert_bool(seen).override_failure_message("the watcher never came in").is_true()
	var guest: Dictionary = _host.guests()[0]
	assert_str(guest["name"]).is_equal("Couch Kim")
	assert_bool(guest.has("color")).is_false()
	_host.kick(guest["peer"])
	var gone := await _wait_until(func() -> bool: return not told[0].is_empty(), 4000)
	assert_bool(gone).is_true()


## A lobby with a password asks for it: none given is asked for, a wrong one is said to be wrong,
## and the right one is let in. Only the password: nothing else about the knock was wrong.
func test_a_lobby_with_a_password_asks_for_it() -> void:
	_open_host()
	_host.door.password = "sesame"
	for given: String in ["", "open up"]:
		var client := _client(false, "Guest", given)
		var asked: Array = []
		client.locked.connect(func(wrong: bool) -> void: asked.append(wrong))
		var heard := await _wait_until(func() -> bool: return not asked.is_empty(), 4000)
		assert_bool(heard).override_failure_message("never asked for %s" % given).is_true()
		assert_bool(asked[0]).is_equal(not given.is_empty())
		client.queue_free()
		await await_idle_frame()
	var right := _client(false, "Guest", "sesame")
	var seated := await _wait_until(func() -> bool: return _host.guests().size() == 1, 4000)
	assert_bool(seated).override_failure_message("the right password was not let in").is_true()
	assert_int(right.local_slot).is_greater_equal(0)


## However many seats the arena has, a lobby set to fewer players turns the next one away as full.
func test_a_lobby_turns_away_players_past_its_limit() -> void:
	_open_host()
	_host.door.max_players = 1
	var client := _client()
	var told := [""]
	client.refused.connect(func(reason: String) -> void: told[0] = reason)
	var heard := await _wait_until(func() -> bool: return not told[0].is_empty(), 4000)
	assert_bool(heard).override_failure_message("the client was never turned away").is_true()
	assert_str(told[0]).is_equal("The match is full")
	client.queue_free()
	await await_idle_frame()
	# Somebody watching takes no seat, and is let in all the same.
	var watcher := _client(true, "Couch Kim")
	var seen := await _wait_until(func() -> bool: return _host.guests().size() == 1, 4000)
	assert_bool(seen).is_true()
	assert_bool(watcher.watching).is_true()
