extends GdUnitTestSuite
## Team play online, GAME.md 3.14 and 10.3: a host and a client in one process over a real socket,
## as [code]test_online.gd[/code] runs them. A client sits down on a team and sees everybody's, in
## the teams' colors; in the waiting room it asks the host for another team and is moved, and hears
## when the host changes how many teams there are.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const ROOM_RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const ROOM_LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
## How much slack every wait gets, as in [code]test_online.gd[/code].
const PATIENCE := 3

## A block of free ports of its own for every test, see tests/free_ports.gd.
var port := 0
var _host_root: Node
var _client_root: Node
var _host_session: NetSession
var _client_session: NetSession


func before_test() -> void:
	port = FreePorts.take()
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


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	while not condition.call() and waited < max_millis * PATIENCE:
		await await_millis(25)
		waited += 25
	return condition.call()


## A host's match of [param inputs] in two teams, on [param rules], [param layout] its map or the
## default one, hosted on this suite's port.
func _host(inputs: Array[KartInput], rules: MatchRules, layout: ArenaLayout = null) -> Match:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = rules
	host_match.rules.teams = 2
	host_match.arena_layout = layout
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	host_match.start(inputs, 23)
	_host_session = auto_free(NetSession.new())
	_host_session.name = "Session"
	_host_session.match_node = host_match
	_host_root.add_child(_host_session)
	assert_int(_host_session.host(port)).is_equal(OK)
	return host_match


## A client of the host, seated, with the karts in its room.
func _client(rules: MatchRules, layout: ArenaLayout = null) -> Match:
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = rules
	client_match.arena_layout = layout
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	_client_session = auto_free(NetSession.new())
	_client_session.name = "Session"
	_client_session.match_node = client_match
	_client_session.local_input = KartInput.new()
	_client_root.add_child(_client_session)
	assert_int(_client_session.join("127.0.0.1", port)).is_equal(OK)
	var seated := await _wait_until(
		func() -> bool:
			return _client_session.local_slot >= 0 and client_match.puppet_karts.size() >= 2,
		4000
	)
	assert_bool(seated).override_failure_message("the client never sat down").is_true()
	return client_match


func _quick_rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	return rules


## A client taking over a bot's kart sits on that kart's team, and sees every seat's team, the
## teams' colors and pennants and the team's target as the host has them.
func test_a_client_plays_on_a_team() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new(), BotInput.new(), BotInput.new()
	]
	var host_match := _host(inputs, _quick_rules())
	var client_match: Match = await _client(_quick_rules())
	var mine := _client_session.local_slot
	assert_int(host_match.slots[mine].team).is_equal(1)
	assert_int(client_match.rules.teams).is_equal(2)
	assert_int(client_match.rules.team_target()).is_equal(host_match.rules.team_target())
	var told := await _wait_until(
		func() -> bool: return client_match.slots.size() == host_match.slots.size(), 2000
	)
	assert_bool(told).is_true()
	for i: int in host_match.slots.size():
		assert_int(client_match.slots[i].team).is_equal(host_match.slots[i].team)
		var kart := client_match.slots[i].kart
		assert_int(kart.team).is_equal(host_match.slots[i].team)
		assert_int(kart.color_index).is_equal(Teams.color_index(host_match.slots[i].team))
		assert_object(kart.get_node_or_null("Body/TeamPennant")).is_not_null()


## In the waiting room a client asks the host for the other team and is moved there, and hears the
## host turn the room to three teams.
func test_a_client_changes_team_in_the_waiting_room() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD)]
	var host_match := _host(inputs, ROOM_RULES.duplicate(), ROOM_LAYOUT)
	# Where teams are picked, as the waiting room's corners say, see [TeamCorners].
	host_match.add_to_group(SeatIdentity.PICKING_TEAMS)
	var client_match: Match = await _client(ROOM_RULES.duplicate(), ROOM_LAYOUT)
	var mine := _client_session.local_slot
	assert_int(host_match.slots[mine].team).is_equal(1)
	_client_session.claim_color(SeatIdentity.TEAM_CLAIM + 0, mine)
	var moved := await _wait_until(func() -> bool: return client_match.slots[mine].team == 0, 3000)
	assert_bool(moved).override_failure_message("the client was never moved").is_true()
	assert_int(host_match.slots[mine].team).is_equal(0)
	assert_int(client_match.slots[mine].kart.color_index).is_equal(Teams.color_index(0))
	host_match.rules.teams = 3
	var heard := await _wait_until(func() -> bool: return client_match.rules.teams == 3, 3000)
	assert_bool(heard).override_failure_message("the client never heard of three").is_true()
