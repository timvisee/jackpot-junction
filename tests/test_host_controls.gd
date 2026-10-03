extends GdUnitTestSuite
## The host's say at a dedicated server, GAME.md 9.3a: nobody is at the host, so a player at
## another machine has it, the first to sit down and after them whoever has been in the longest.
## What they choose goes over the wire and is taken from them alone. Over a real socket between
## sessions in this one process.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")
const WAITING_RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const WAITING_MAP: ArenaLayout = preload("res://data/maps/waiting_room.tres")
## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side.
var port := 7941
var _host_root: Node
var _host: NetSession
var _host_match: Match
var _client_roots: Array[Node] = []
var _settings_were: Settings


func before_test() -> void:
	_host_root = auto_free(Node.new())
	_host_root.name = "HostRoot"
	add_child(_host_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), _host_root.get_path())
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_host_controls.cfg"


func after_test() -> void:
	get_tree().set_multiplayer(null, _host_root.get_path())
	for root: Node in _client_roots:
		get_tree().set_multiplayer(null, root.get_path())
	_client_roots.clear()
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


func _waiting_match(into: Node) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.name = "Match"
	match_node.rules = WAITING_RULES.duplicate()
	match_node.arena_layout = WAITING_MAP
	match_node.with_hud = false
	into.add_child(match_node)
	return match_node


## A waiting room with nobody in it, hosted by a session with nobody at it. Under a node called
## Net, as a game's own session is, so a client in the real waiting room calls the same path.
func _open_host() -> void:
	_host_match = _waiting_match(_host_root)
	var nobody: Array[KartInput] = []
	_host_match.start(nobody, 23)
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	_host_root.add_child(net)
	_host = auto_free(NetSession.new())
	_host.name = "Session"
	_host.dedicated = true
	_host.match_node = _host_match
	net.add_child(_host)
	assert_int(_host.host(port)).is_equal(OK)


## A client of its own on a multiplayer root of its own, knocking at the host.
func _client(named: String, watching := false) -> NetSession:
	var root: Node = auto_free(Node.new())
	root.name = "Client%d" % _client_roots.size()
	add_child(root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), root.get_path())
	_client_roots.append(root)
	var client_match := _waiting_match(root)
	client_match.start_puppet()
	var net: Node = auto_free(Node.new())
	net.name = "Net"
	root.add_child(net)
	var session: NetSession = auto_free(NetSession.new())
	session.name = "Session"
	session.match_node = client_match
	session.local_input = KartInput.new()
	session.watching = watching
	session.player_name = named
	net.add_child(session)
	assert_int(session.join("127.0.0.1", port)).is_equal(OK)
	return session


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## [param clients], seated in the order given, each before the next knocks.
func _seat_in_turn(names: Array[String]) -> Array[NetSession]:
	var clients: Array[NetSession] = []
	for named: String in names:
		var client := _client(named)
		clients.append(client)
		var seated := await _wait_until(func() -> bool: return client.local_slot >= 0, 4000)
		assert_bool(seated).override_failure_message("%s never sat down" % named).is_true()
	return clients


func _says(client: NetSession) -> bool:
	return client.host_controls.mine()


## The first to sit down has the say, and nobody else does. The host itself never has it: there
## is nobody at it to use it.
func test_the_first_player_to_sit_down_has_the_say() -> void:
	_open_host()
	var clients := await _seat_in_turn(["Ann", "Bo"] as Array[String])
	var given := await _wait_until(_says.bind(clients[0]), 4000)
	assert_bool(given).override_failure_message("Ann never had the say").is_true()
	assert_bool(_says(clients[1])).is_false()
	assert_bool(_host.host_controls.mine()).is_false()
	assert_int(_host.host_controls.peer).is_equal(clients[0].multiplayer.get_unique_id())


## When the player with the say goes, it passes to whoever has been in the longest, and so on down.
func test_the_say_passes_to_whoever_has_been_in_the_longest() -> void:
	_open_host()
	var clients := await _seat_in_turn(["Ann", "Bo", "Cy"] as Array[String])
	await _wait_until(_says.bind(clients[0]), 4000)
	clients[0].multiplayer.multiplayer_peer.close()
	var passed := await _wait_until(_says.bind(clients[1]), 4000)
	assert_bool(passed).override_failure_message("the say never reached Bo").is_true()
	assert_bool(_says(clients[2])).is_false()
	clients[1].multiplayer.multiplayer_peer.close()
	var again := await _wait_until(_says.bind(clients[2]), 4000)
	assert_bool(again).override_failure_message("the say never reached Cy").is_true()
	clients[2].multiplayer.multiplayer_peer.close()
	var nobody := await _wait_until(func() -> bool: return _host.host_controls.peer == 0, 4000)
	assert_bool(nobody).override_failure_message("the say stayed with somebody gone").is_true()


## Somebody watching never has the say, even the first in.
func test_somebody_watching_never_has_the_say() -> void:
	_open_host()
	var watcher := _client("Kim", true)
	var watching := await _wait_until(func() -> bool: return _host._watchers.size() == 1, 4000)
	assert_bool(watching).override_failure_message("the watcher never came in").is_true()
	var clients := await _seat_in_turn(["Ann"] as Array[String])
	var given := await _wait_until(_says.bind(clients[0]), 4000)
	assert_bool(given).is_true()
	assert_bool(_says(watcher)).is_false()


## Manage players at the player with the say lists everybody else, and Kick there shows them out.
func test_the_player_with_the_say_sees_everybody_else_and_can_show_them_out() -> void:
	_open_host()
	var clients := await _seat_in_turn(["Ann", "Bo"] as Array[String])
	var ann := clients[0]
	var listed := func() -> bool:
		var guests := ann.host_controls.guests()
		return guests.size() == 1 and guests[0]["name"] == "Bo"
	var seen := await _wait_until(listed, 4000)
	assert_bool(seen).override_failure_message("Ann never saw Bo in the list").is_true()
	var told := [""]
	clients[1].refused.connect(func(reason: String) -> void: told[0] = reason)
	ann.host_controls.kick(int(ann.host_controls.guests()[0]["peer"]))
	var gone := await _wait_until(func() -> bool: return not told[0].is_empty(), 4000)
	assert_bool(gone).override_failure_message("Bo was never shown out").is_true()
	assert_str(told[0]).is_equal("The host removed you from the game")
	var empty := await _wait_until(
		func() -> bool: return ann.host_controls.guests().is_empty(), 4000
	)
	assert_bool(empty).override_failure_message("Bo stayed on Ann's list").is_true()


## Lobby settings at the player with the say set the server's door, and a knock after it is
## answered by them: a password given now is asked for.
func test_lobby_settings_from_the_player_with_the_say_set_the_door() -> void:
	_open_host()
	var clients := await _seat_in_turn(["Ann"] as Array[String])
	var ann := clients[0]
	await _wait_until(_says.bind(ann), 4000)
	ann.door.max_players = 3
	ann.door.password = "sesame"
	ann.door.watchers_allowed = false
	ann.host_controls.door_changed()
	var changed := await _wait_until(func() -> bool: return _host.door.password == "sesame", 4000)
	assert_bool(changed).override_failure_message("the door never changed").is_true()
	assert_int(_host.door.max_players).is_equal(3)
	assert_bool(_host.door.watchers_allowed).is_false()
	var late := _client("Late")
	var asked: Array = []
	late.locked.connect(func(wrong: bool) -> void: asked.append(wrong))
	var heard := await _wait_until(func() -> bool: return not asked.is_empty(), 4000)
	assert_bool(heard).override_failure_message("the password was never asked for").is_true()


## The player with the say can stop the room for everybody, and letting go starts it again.
func test_the_player_with_the_say_can_stop_the_room_for_everybody() -> void:
	_open_host()
	var clients := await _seat_in_turn(["Ann", "Bo"] as Array[String])
	await _wait_until(_says.bind(clients[0]), 4000)
	clients[0].host_controls.force_pause(true)
	var stopped := await _wait_until(func() -> bool: return clients[1].paused, 4000)
	assert_bool(stopped).override_failure_message("the room never stopped").is_true()
	assert_bool(_host.paused).is_true()
	clients[0].host_controls.force_pause(false)
	var running := await _wait_until(func() -> bool: return not clients[1].paused, 4000)
	assert_bool(running).override_failure_message("the room stayed stopped").is_true()
	# Anybody else asking to stop everybody is not heard.
	clients[1].host_controls._force.rpc_id(1, true)
	await await_millis(300)
	assert_bool(_host.paused).is_false()
	# A pause the holder made goes with the say, GAME.md 3.8: handed on, the room runs again, and
	# neither holder's menu shows it as theirs.
	clients[0].host_controls.force_pause(true)
	assert_bool(clients[0].host_controls.forcing).is_true()
	assert_bool(await _wait_until(func() -> bool: return clients[1].paused, 4000)).is_true()
	clients[0].host_controls.make_host(clients[1].multiplayer.get_unique_id())
	var let_go := await _wait_until(func() -> bool: return not clients[1].paused, 4000)
	(
		assert_bool(let_go)
		. override_failure_message("the old holder's pause outlived the say")
		. is_true()
	)
	assert_bool(clients[0].host_controls.forcing).is_false()
	assert_bool(clients[1].host_controls.forcing).is_false()


## The plan and the way on are heard from the player with the say and nobody else, and only a way
## on there is.
func test_the_plan_and_the_way_on_are_heard_only_from_the_player_with_the_say() -> void:
	_open_host()
	var clients := await _seat_in_turn(["Ann", "Bo"] as Array[String])
	await _wait_until(_says.bind(clients[0]), 4000)
	var plans: Array = []
	var ways: Array[StringName] = []
	_host.host_controls.planned.connect(
		func(plan: Dictionary, still: bool) -> void: plans.append([plan, still])
	)
	_host.host_controls.asked_to_go.connect(func(where: StringName) -> void: ways.append(where))
	var chosen := MatchConfig.new()
	chosen.map = ArenaMaps.IDS[2]
	chosen.bot_count = 1
	clients[1].host_controls._plan.rpc_id(1, MatchOptions.to_wire(chosen), false)
	clients[1].host_controls._go.rpc_id(1, &"lobby")
	clients[0].host_controls.plan(chosen, true)
	clients[0].host_controls._go.rpc_id(1, &"nowhere")
	clients[0].host_controls.go(&"rematch")
	var heard := await _wait_until(func() -> bool: return not ways.is_empty(), 4000)
	assert_bool(heard).override_failure_message("the way on was never heard").is_true()
	assert_int(plans.size()).is_equal(1)
	assert_str(str(plans[0][0]["map"])).is_equal(String(ArenaMaps.IDS[2]))
	assert_bool(plans[0][1]).is_true()
	assert_bool(_host.host_controls.choosing).is_true()
	assert_array(ways).is_equal([&"rematch"] as Array[StringName])


## A plan off the wire is taken as far as the match settings could have said it, and no further.
func test_a_plan_is_taken_only_as_far_as_the_menu_could_say_it() -> void:
	var config := MatchConfig.new()
	var was := MatchOptions.to_wire(config)
	var sent := {
		"map": "the_moon",
		"rounds": 40,
		"keep_jokers": 9,
		"duration": 7,
		"target_score": 12345,
		"bot_count": 12,
		"difficulty": "brutal",
		"item_set": "every",
		"joker_slots": 99,
	}
	MatchOptions.from_wire(config, sent)
	assert_dict(MatchOptions.to_wire(config)).is_equal(was)
	var fair := {
		"map": String(ArenaMaps.IDS[1]),
		"rounds": 3,
		"keep_jokers": GrandPrix.Keep.ALL,
		"duration": 480,
		"target_score": 5000,
		"bot_count": 0,
		"difficulty": "hard",
		"item_set": "all",
		"own_bullets_hurt": true,
		"overtime": false,
		"joker_slots": 8,
	}
	MatchOptions.from_wire(config, fair)
	assert_str(String(config.map)).is_equal(String(ArenaMaps.IDS[1]))
	assert_int(config.rounds).is_equal(3)
	assert_int(config.keep_jokers).is_equal(GrandPrix.Keep.ALL)
	assert_float(config.duration).is_equal(480.0)
	assert_int(config.target_score).is_equal(5000)
	assert_int(config.bot_count).is_equal(0)
	assert_str(config.difficulty).is_equal("hard")
	assert_str(config.item_set).is_equal("all")
	assert_bool(config.own_bullets_hurt).is_true()
	assert_bool(config.overtime).is_false()
	assert_int(config.joker_slots).is_equal(8)


## The door off the wire keeps to what Lobby settings can set.
func test_the_door_is_taken_only_as_far_as_lobby_settings_could_say_it() -> void:
	var door := NetDoor.new()
	door.from_wire({"max_players": 40, "password": "  %s  " % "x".repeat(200)})
	assert_int(door.max_players).is_equal(NetDoor.MOST_PLAYERS)
	assert_int(door.password.length()).is_equal(NetDoor.PASSWORD_LENGTH)
	door.from_wire({"max_players": 0})
	assert_int(door.max_players).is_equal(NetDoor.FEWEST_PLAYERS)


## The real waiting room at the player who has just made the game: the say comes with the seat,
## the lobby's settings come up first and then the match's, and what they choose reaches the
## server, which says it to the room.
func test_the_maker_of_a_game_chooses_it_in_the_waiting_room() -> void:
	_open_host()
	var plans: Array = []
	_host.host_controls.planned.connect(
		func(plan: Dictionary, still: bool) -> void: plans.append([plan, still])
	)
	Game.pending_config = MatchConfig.new()
	Game.pending_config.online = "join"
	Game.pending_config.creating = true
	Game.pending_config.address = "127.0.0.1"
	Game.pending_config.port = port
	Game.pending_config.human_names = ["Maker"] as Array[String]
	Game.pending_config.server = "127.0.0.1:7940"
	# Who may come in, as the maker left it last time.
	Game.settings.lobby_players = 3
	Game.settings.lobby_watchers = false
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	var runner := scene_runner(room)
	var up := func() -> bool: return room.host_settings != null and room.host_settings.is_open()
	var waited := 0
	while not up.call() and waited < 300:
		await runner.simulate_frames(1, 17)
		waited += 1
	assert_bool(up.call()).override_failure_message("the match settings never came up").is_true()
	var pane: HostSettings = room.host_settings
	assert_bool(pane.on_lobby()).is_true()
	var door := func() -> bool:
		return _host.door.max_players == 3 and not _host.door.watchers_allowed
	var kept := await _wait_until(door, 4000)
	(
		assert_bool(kept)
		. override_failure_message("the maker's lobby settings never reached the door")
		. is_true()
	)
	# Anybody in the game can say where it is found.
	var hint: Label = room.ready_room._online_hint
	assert_str(hint.text).is_equal("Friends find this game in Play Online, at 127.0.0.1:7940")
	var holding := await _wait_until(
		func() -> bool: return not plans.is_empty() and plans[-1][1], 4000
	)
	(
		assert_bool(holding)
		. override_failure_message("the server never heard it was choosing")
		. is_true()
	)
	pane._lobby._back.pressed.emit()
	pane.options.choose(false)
	pane.options.map_option.selected = 2
	pane.close()
	var chosen := await _wait_until(func() -> bool: return not plans[-1][1], 4000)
	assert_bool(chosen).override_failure_message("the server never heard the choice").is_true()
	assert_str(str(plans[-1][0]["map"])).is_equal(String(ArenaMaps.IDS[2]))
	assert_bool(room.host_settings.is_open()).is_false()


## Make host in the Manage players of the player with the say hands it to that player, who is told
## who handed it over, and takes it from them. Somebody watching has no Make host beside them.
func test_make_host_hands_the_say_to_another_player() -> void:
	_open_host()
	var clients := await _seat_in_turn(["Ann", "Bo"] as Array[String])
	var ann := clients[0]
	var bo := clients[1]
	var watcher := _client("Kim", true)
	await _wait_until(_says.bind(ann), 4000)
	var both_listed := func() -> bool: return ann.host_controls.guests().size() == 2
	(
		assert_bool(await _wait_until(both_listed, 4000))
		. override_failure_message("Ann never saw Bo and Kim")
		. is_true()
	)
	var pane: ManagePlayers = auto_free(ManagePlayers.new())
	pane.session = ann
	add_child(pane)
	pane.open()
	var hands: Array[Button] = []
	for button: Node in pane.find_children("*", "Button", true, false):
		if (button as Button).text == "Make host":
			hands.append(button)
	assert_int(hands.size()).is_equal(1)
	hands[0].pressed.emit()
	var handed := await _wait_until(_says.bind(bo), 4000)
	assert_bool(handed).override_failure_message("Bo was never handed the say").is_true()
	assert_bool(_says(ann)).is_false()
	assert_str(bo.host_controls.given_by).is_equal("Ann")
	assert_int(_host.host_controls.peer).is_equal(bo.multiplayer.get_unique_id())
	assert_bool(_says(watcher)).is_false()


## The say is handed over by the player with it and nobody else, and only to somebody playing.
func test_the_say_is_handed_only_by_its_holder_and_only_to_a_player() -> void:
	_open_host()
	var clients := await _seat_in_turn(["Ann", "Bo", "Cy"] as Array[String])
	var watcher := _client("Kim", true)
	await _wait_until(_says.bind(clients[0]), 4000)
	var watching := await _wait_until(func() -> bool: return _host._watchers.size() == 1, 4000)
	assert_bool(watching).is_true()
	var cy := clients[2].multiplayer.get_unique_id()
	clients[1].host_controls._make_host.rpc_id(1, cy)
	clients[0].host_controls.make_host(watcher.multiplayer.get_unique_id())
	await await_millis(400)
	assert_bool(_says(clients[0])).is_true()
	assert_bool(_says(clients[2])).is_false()
	assert_bool(_says(watcher)).is_false()
