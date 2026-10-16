extends GdUnitTestSuite
## Leaving the waiting room of GAME.md 9.6 together. The room and the arena are two matches on
## one connection: the host has to say it is going, and has to seat everybody again in the match
## it has gone to, because the rules and the seats were sent once on the way in and belong to a
## match that has been taken down.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const WAITING_RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const WAITING_MAP: ArenaLayout = preload("res://data/maps/waiting_room.tres")
## The first of a block of ports of this suite's own, so it can run beside the other network
## suites.
const PATIENCE := 3

## A block of free ports of its own for every test, see tests/free_ports.gd, the suites running
## side by side, and a suite that runs these again over a slower line, see [NetLag], beside them.
var port := 0
var _host_root: Node
var _client_root: Node
var _host: NetSession
var _client: NetSession
var _host_waiting: Match
var _client_waiting: Match
var _host_arena: Match
var _client_arena: Match


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
	while waited < max_millis * PATIENCE:
		if condition.call():
			return true
		await get_tree().process_frame
		waited += 16
	return condition.call()


## A match in the waiting room, which is what both ends start in.
func _waiting_match(into: Node, called: String) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.name = called
	match_node.rules = WAITING_RULES.duplicate()
	match_node.arena_layout = WAITING_MAP
	into.add_child(match_node)
	return match_node


## And the arena it gives way to, which is a second match on the same wire.
func _arena_match(into: Node, called: String) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.name = called
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 42.0
	rules.lives = 4
	match_node.rules = rules
	into.add_child(match_node)
	return match_node


## Both ends in the waiting room over a real connection on [param port], with the client seated.
## The client's seat is given a color the arena would not hand out by itself, so a test that
## finds it again on the other side knows it was kept rather than dealt.
func _both_in_the_room(port: int) -> void:
	_host_waiting = _waiting_match(_host_root, "Waiting")
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD)]
	_host_waiting.start(inputs, 23)
	_host = auto_free(NetSession.new())
	_host.name = "Session"
	_host.match_node = _host_waiting
	_host_root.add_child(_host)
	assert_int(_host.host(port)).is_equal(OK)
	_client_waiting = _waiting_match(_client_root, "Waiting")
	_client_waiting.start_puppet()
	_client = auto_free(NetSession.new())
	_client.name = "Session"
	_client.match_node = _client_waiting
	_client.local_input = KartInput.new()
	_client_root.add_child(_client)
	assert_int(_client.join("127.0.0.1", port)).is_equal(OK)
	var seated := await _wait_until(func() -> bool: return _client.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("the client never got into the room").is_true()
	_host_waiting.slots[_client.local_slot].color_index = 3


## The host says it is going to the arena and both ends build one. The arena keeps a seat for the
## client, in the color it had in the room, and has the one bot the host asked for after it.
## Nobody is seated in it yet: the client has to ask.
func _both_go_to_the_arena() -> void:
	var seen := {"told": false}
	_client.match_beginning.connect(func() -> void: seen["told"] = true)
	var kept: Array[int] = []
	for index: int in _host.peer_seats():
		kept.append(_host_waiting.slots[index].color_index)
	_host.begin_the_match()
	var heard := await _wait_until(func() -> bool: return seen["told"], 4000)
	assert_bool(heard).override_failure_message("the client was not told to follow").is_true()
	_host_arena = _arena_match(_host_root, "Arena")
	var plan := MatchConfig.new()
	var devices: Array[int] = [DeviceInput.KEYBOARD]
	plan.human_devices = devices
	plan.network_seats = kept.size()
	plan.network_colors = kept
	plan.bot_count = 1
	_host_arena.start(plan.inputs(), 23, plan.colors())
	_host.match_node = _host_arena
	_client_arena = _arena_match(_client_root, "Arena")
	_client_arena.start_puppet()
	_client.match_node = _client_arena
	_client.local_slot = -1


## The whole handover: a client waits in the room with the host, the host says it is going, and
## the client, once its own arena is up and it asks, is seated in the host's with that arena's
## rules, in the seat kept for it and the color it had.
func test_the_host_takes_everybody_through_to_the_arena() -> void:
	await _both_in_the_room(port)
	var was := _client.local_slot
	await _both_go_to_the_arena()
	# The flag is kept in a dictionary rather than in a local: a lambda captures a local by
	# value, so setting one from inside a signal handler sets the handler's own copy only.
	var seen := {"ruled": false}
	_client.rules_applied.connect(func() -> void: seen["ruled"] = true)
	_host.re_seat()
	_client.ready_for_seat()
	var ruled := await _wait_until(func() -> bool: return seen["ruled"], 4000)
	assert_bool(ruled).override_failure_message("the arena's rules never arrived").is_true()
	assert_float(_client_arena.rules.duration).is_equal(42.0)
	assert_int(_client_arena.rules.lives).is_equal(4)
	var again := await _wait_until(func() -> bool: return _client.local_slot >= 0, 4000)
	assert_bool(again).override_failure_message("the client was not seated again").is_true()
	assert_int(_client.local_slot).is_equal(was)
	assert_bool(_host_arena.slots[_client.local_slot].input is NetInput).is_true()
	assert_int(_host_arena.slots.size()).is_equal(3)
	assert_int(_host_arena.slots[_client.local_slot].color_index).is_equal(3)
	assert_bool(_host_arena.slots[2].input is BotInput).is_true()


## A client that got there first, and asked before the host's arena was up, is not told a seat in
## a match that is being taken down. It is seated once the host arrives.
func test_a_client_that_asks_early_is_seated_when_the_host_arrives() -> void:
	await _both_in_the_room(port + 2)
	await _both_go_to_the_arena()
	_client.ready_for_seat()
	for i: int in 20:
		await get_tree().process_frame
	assert_int(_client.local_slot).override_failure_message("seated with no room up").is_equal(-1)
	_host.re_seat()
	var seated := await _wait_until(func() -> bool: return _client.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("the early client was never seated").is_true()
	assert_int(_host_arena.slots[_client.local_slot].color_index).is_equal(3)


## After the match the host takes everybody back to the waiting room: the client is told, both
## ends build a room, and the client is seated in the host's with the room's rules and the color
## it drove the arena in.
func test_the_host_takes_everybody_back_to_the_room() -> void:
	await _both_in_the_room(port + 3)
	await _both_go_to_the_arena()
	_host.re_seat()
	_client.ready_for_seat()
	var arrived := await _wait_until(func() -> bool: return _client.local_slot >= 0, 4000)
	assert_bool(arrived).override_failure_message("never got into the arena").is_true()
	var seen := {"back": false, "ruled": false}
	_client.back_to_room.connect(func() -> void: seen["back"] = true)
	_host.back_to_the_room()
	var heard := await _wait_until(func() -> bool: return seen["back"], 4000)
	assert_bool(heard).override_failure_message("the client was not told to come back").is_true()
	var host_room := _waiting_match(_host_root, "Again")
	host_room.rules.lives = 5
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD)]
	host_room.start(inputs, 29)
	_host.match_node = host_room
	var client_room := _waiting_match(_client_root, "Again")
	client_room.start_puppet()
	_client.match_node = client_room
	_client.local_slot = -1
	_client.rules_applied.connect(func() -> void: seen["ruled"] = true)
	_client.ready_for_seat()
	_host.re_seat()
	var ruled := await _wait_until(func() -> bool: return seen["ruled"], 4000)
	assert_bool(ruled).override_failure_message("the room's rules never arrived").is_true()
	assert_int(client_room.rules.lives).is_equal(5)
	assert_bool(client_room.rules.timed).is_false()
	var seated := await _wait_until(func() -> bool: return _client.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("not seated back in the room").is_true()
	var seat := host_room.slots[_client.local_slot]
	assert_bool(seat.input is NetInput).is_true()
	assert_int(seat.color_index).is_equal(3)


## Nobody is told to follow by a client, and a host with nobody connected says nothing to
## anybody: the word is the host's and only goes out when there is somebody to hear it.
func test_only_a_host_with_company_says_it_is_going() -> void:
	var alone := _waiting_match(_host_root, "Waiting")
	alone.start([PlayerInput.new()] as Array[KartInput], 5)
	var host: NetSession = auto_free(NetSession.new())
	host.name = "Session"
	host.match_node = alone
	_host_root.add_child(host)
	assert_int(host.host(port + 1)).is_equal(OK)
	# No peers: nothing to say and nothing that throws for saying it.
	host.begin_the_match()
	host.re_seat()
	assert_bool(host.is_host).is_true()
