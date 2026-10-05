extends GdUnitTestSuite
## A game hosted with nobody playing at the host, GAME.md 9.3a: a game of a dedicated server, whose
## players are all at other machines. Over a real socket between sessions in this one process, and
## through the real waiting room.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")
const WAITING_RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const WAITING_MAP: ArenaLayout = preload("res://data/maps/waiting_room.tres")
## Real time is slower in a long suite than on its own; every budget here is a budget, not a
## measurement, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side.
var port := 7931
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
	Game.settings.path = "user://test_dedicated_host.cfg"


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


## A waiting room with nobody in it, hosted by a session with nobody at it.
func _open_host() -> void:
	_host_match = _waiting_match(_host_root)
	var nobody: Array[KartInput] = []
	_host_match.start(nobody, 23)
	_host = auto_free(NetSession.new())
	_host.name = "Session"
	_host.dedicated = true
	_host.match_node = _host_match
	_host_root.add_child(_host)
	assert_int(_host.host(port)).is_equal(OK)


## A client of its own on a multiplayer root of its own, knocking at the host.
func _client(watching := false, named := "Guest") -> NetSession:
	var root: Node = auto_free(Node.new())
	root.name = "Client%d" % _client_roots.size()
	add_child(root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), root.get_path())
	_client_roots.append(root)
	var client_match := _waiting_match(root)
	client_match.start_puppet()
	var session: NetSession = auto_free(NetSession.new())
	session.name = "Session"
	session.match_node = client_match
	session.local_input = KartInput.new()
	session.watching = watching
	session.player_name = named
	root.add_child(session)
	assert_int(session.join("127.0.0.1", port)).is_equal(OK)
	return session


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


func _seated(clients: Array[NetSession]) -> bool:
	for client: NetSession in clients:
		if client.local_slot < 0:
			return false
	return true


## Every seat is somebody's at another machine: nobody plays at the host, and it is found through
## the server that lists it rather than by asking the network.
func test_a_host_with_nobody_at_it_seats_only_its_clients() -> void:
	_open_host()
	assert_that(_host.get_node_or_null("LanBeacon")).is_null()
	var clients: Array[NetSession] = [_client(false, "Ann"), _client(false, "Bo")]
	var seated := await _wait_until(_seated.bind(clients), 4000)
	assert_bool(seated).override_failure_message("the clients never sat down").is_true()
	assert_int(_host_match.slots.size()).is_equal(2)
	for slot: PlayerSlot in _host_match.slots:
		assert_bool(slot.input is NetInput).is_true()
		assert_bool(slot.is_local_human()).is_false()
	assert_int(_host.host_controls.guests().size()).is_equal(2)


## With nobody at the host, the room's seats are all for clients: in a lobby for eight, eight of
## them play where a host with a player of its own seats seven, and a ninth is told the match is
## full.
func test_a_room_of_clients_plays_and_one_more_is_turned_away() -> void:
	_open_host()
	_host.door.max_players = NetDoor.MOST_PLAYERS
	var clients: Array[NetSession] = []
	for i: int in NetDoor.MOST_PLAYERS:
		clients.append(_client(false, "Player %d" % i))
		var in_turn := await _wait_until(_seated.bind(clients), 4000)
		assert_bool(in_turn).override_failure_message("client %d never sat down" % i).is_true()
	var late := _client(false, "Late")
	var told := [""]
	late.refused.connect(func(reason: String) -> void: told[0] = reason)
	var refused := await _wait_until(func() -> bool: return not told[0].is_empty(), 4000)
	assert_bool(refused).override_failure_message("the ninth was never turned away").is_true()
	assert_str(told[0]).is_equal("The match is full")
	assert_int(SeatLimit.players(_host_match)).is_equal(NetDoor.MOST_PLAYERS)


## Nobody at the host has a menu to ask with, so the room stops once every player asks, and
## starts again the moment one of them is back at the wheel. Somebody watching is not asked.
func test_the_room_stops_once_every_player_asks() -> void:
	_open_host()
	var clients: Array[NetSession] = [_client(false, "Ann"), _client(false, "Bo")]
	var watcher := _client(true, "Kim")
	var seated := await _wait_until(_seated.bind(clients), 4000)
	assert_bool(seated).override_failure_message("the clients never sat down").is_true()
	var watching := await _wait_until(func() -> bool: return _host._watchers.size() == 1, 4000)
	assert_bool(watching).override_failure_message("the watcher never came in").is_true()
	assert_bool(_host.paused).is_false()
	clients[0].want_pause(true)
	await await_millis(200)
	assert_bool(_host.paused).is_false()
	assert_bool(clients[1].paused).is_false()
	clients[1].want_pause(true)
	var stopped := await _wait_until(func() -> bool: return clients[0].paused, 4000)
	assert_bool(stopped).override_failure_message("the room never stopped").is_true()
	assert_bool(_host.paused).is_true()
	assert_bool(watcher.paused).is_true()
	clients[0].want_pause(false)
	var running := await _wait_until(func() -> bool: return not clients[1].paused, 4000)
	assert_bool(running).override_failure_message("the room never started again").is_true()
	assert_bool(_host.paused).is_false()


## The real waiting room, hosted with nobody at it: no seat here, no match settings to choose and
## no HUD, and it says what it will go to under the count all the same.
func test_the_room_hosted_with_nobody_at_it_has_nobody_in_it() -> void:
	Game.pending_config = MatchConfig.new()
	Game.pending_config.online = "host"
	Game.pending_config.dedicated = true
	Game.pending_config.human_devices = [] as Array[int]
	Game.pending_config.port = port
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	var runner := scene_runner(room)
	await runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	var match_node: Match = room.match_node
	assert_int(match_node.slots.size()).is_equal(0)
	assert_that(match_node.hud).is_null()
	assert_that(room.host_settings).is_null()
	assert_bool(room.session.dedicated).is_true()
	assert_bool(room.session.is_host).is_true()
	assert_str(room.ready_room._plan.text).starts_with("Next: ")
	assert_bool(room.ready_room.all_ready()).is_false()
