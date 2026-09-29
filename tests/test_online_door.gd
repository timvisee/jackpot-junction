extends GdUnitTestSuite
## Who a host lets into its game and shows out of it, GAME.md 10.3: kicked from Manage players,
## over a real socket between two sessions in this one process.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side; a suite that runs these again over a slower line,
## see [NetLag], takes another.
var port := 7861
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
	assert_int(_host.host(port)).is_equal(OK)


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
	assert_int(session.join("127.0.0.1", port)).is_equal(OK)
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
	# Sat down, and by the name it gave: that follows the seat a moment later, and until it arrives
	# the guest is listed under the one the host handed it.
	var named := func() -> bool:
		var guests := _host.guests()
		return guests.size() == 1 and guests[0]["name"] == "Guest"
	var seated := await _wait_until(named, 4000)
	assert_bool(seated).override_failure_message("the client never sat down as Guest").is_true()
	var guest: Dictionary = _host.guests()[0]
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
	var seated := await _wait_until(func() -> bool: return right.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("the right password was not let in").is_true()
	assert_int(_host.guests().size()).is_equal(1)


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


## A host that lets nobody watch says so to somebody who comes to, and nothing else about them.
func test_a_lobby_closed_to_watchers_turns_them_away() -> void:
	_open_host()
	_host.door.watchers_allowed = false
	var watcher := _client(true, "Couch Kim")
	var told := [""]
	watcher.refused.connect(func(reason: String) -> void: told[0] = reason)
	var heard := await _wait_until(func() -> bool: return not told[0].is_empty(), 4000)
	assert_bool(heard).override_failure_message("the watcher was never turned away").is_true()
	assert_str(told[0]).is_equal("This game is not open to watchers")


## With watching free of the password, somebody who comes to watch is let in without it, and
## somebody who comes to play is still asked for it.
func test_a_watcher_may_come_in_without_the_password() -> void:
	_open_host()
	_host.door.password = "sesame"
	_host.door.watchers_need_password = false
	assert_bool(_host.door.watchers_locked()).is_false()
	var watcher := _client(true, "Couch Kim")
	var seen := await _wait_until(func() -> bool: return _host.guests().size() == 1, 4000)
	assert_bool(seen).override_failure_message("the watcher was not let in").is_true()
	# One client at a time: the two of them share this process's end of the wire.
	watcher.queue_free()
	await await_idle_frame()
	var player := _client(false, "Guest")
	var asked: Array = []
	player.locked.connect(func(wrong: bool) -> void: asked.append(wrong))
	var heard := await _wait_until(func() -> bool: return not asked.is_empty(), 4000)
	assert_bool(heard).override_failure_message("the player was not asked").is_true()


## Somebody watching is called what they gave if nobody else has it, and otherwise, or with nothing
## given, a funny name nobody else has, which nobody who sits down later is handed either.
func test_every_watcher_has_a_name_of_their_own() -> void:
	PlayerNames.held_elsewhere.clear()
	var door := NetDoor.new()
	var room := {"no_seat": false, "players": 0, "humans": 1, "watchers": 0, "match": null}
	var version := Game.version()
	var knock := func(peer: int, named: String) -> String:
		door.answer(version, peer, NetDoor.knock(version, true, named, ""), room)
		return door.names[peer]
	var first: String = knock.call(2, "")
	var second: String = knock.call(3, "")
	assert_array(PlayerNames.WATCHER_NAMES).contains([first, second])
	assert_str(first).is_not_equal(second)
	assert_str(knock.call(4, "Couch Kim")).is_equal("Couch Kim")
	var clash: String = knock.call(5, "Couch Kim")
	assert_str(clash).is_not_equal("Couch Kim")
	assert_array(PlayerNames.WATCHER_NAMES).contains([clash])
	# Nobody who comes after is handed a name somebody watching has.
	var others: Array[String] = []
	for name: String in PlayerNames.WATCHER_NAMES:
		if name != first:
			others.append(name)
	var rng := RandomNumberGenerator.new()
	assert_str(PlayerNames.pick_watcher(rng, others)).is_not_equal(first)
	# Gone, their name is free again.
	door.forget(2)
	assert_array(PlayerNames.held_elsewhere).not_contains([first])
	assert_str(PlayerNames.pick_watcher(rng, others)).is_equal(first)
	door.forget(3)
	door.forget(4)
	door.forget(5)
	assert_array(PlayerNames.held_elsewhere).is_empty()
	# And a door that goes, as a session's does, takes its watchers' names with it.
	_name_a_watcher_and_go()
	assert_array(PlayerNames.held_elsewhere).is_empty()


func _name_a_watcher_and_go() -> void:
	var door := NetDoor.new()
	var room := {"no_seat": false, "players": 0, "humans": 1, "watchers": 0, "match": null}
	door.answer(Game.version(), 9, NetDoor.knock(Game.version(), true, "", ""), room)
	assert_int(PlayerNames.held_elsewhere.size()).is_equal(1)


## Neither end of a connection lets ENet throttle what it sends unreliably, GAME.md 10.3: the
## snapshots are several packets each, and a throttle letting some of them go lost all of them
## for seconds at a time, a client's own kart falling down a hole it was never told it had died in.
func test_neither_end_throttles_the_snapshots() -> void:
	_open_host()
	var client := _client()
	var seated := await _wait_until(func() -> bool: return _host.guests().size() == 1, 4000)
	assert_bool(seated).is_true()
	var host_end := NetLag.enet(_host.multiplayer.multiplayer_peer)
	var client_end := NetLag.enet(client.multiplayer.multiplayer_peer)
	var peer: int = _host.guests()[0]["peer"]
	for connection: ENetPacketPeer in [host_end.get_peer(peer), client_end.get_peer(1)]:
		var down := connection.get_statistic(ENetPacketPeer.PEER_PACKET_THROTTLE_DECELERATION)
		assert_float(down).is_equal(0.0)
