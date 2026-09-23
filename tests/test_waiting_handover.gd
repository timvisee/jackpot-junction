extends GdUnitTestSuite
## Leaving the waiting room of GAME.md 9.6 together. The room and the arena are two matches on
## one connection: the host has to say it is going, and has to seat everybody again in the match
## it has gone to, because the rules and the seats were sent once on the way in and belong to a
## match that has been taken down.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const WAITING_RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const WAITING_MAP: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const PORT := 7793
const PATIENCE := 3

var _host_root: Node
var _client_root: Node


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


## The whole handover: a client waits in the room with the host, the host says it is going, and
## the client is seated in the arena it went to with that arena's rules.
func test_the_host_takes_everybody_through_to_the_arena() -> void:
	var host_waiting := _waiting_match(_host_root, "Waiting")
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD)]
	host_waiting.start(inputs, 23)
	var host: NetSession = auto_free(NetSession.new())
	host.name = "Session"
	host.match_node = host_waiting
	_host_root.add_child(host)
	assert_int(host.host(PORT)).is_equal(OK)

	var client_waiting := _waiting_match(_client_root, "Waiting")
	client_waiting.start_puppet()
	var client: NetSession = auto_free(NetSession.new())
	client.name = "Session"
	client.match_node = client_waiting
	client.local_input = KartInput.new()
	_client_root.add_child(client)
	assert_int(client.join("127.0.0.1", PORT)).is_equal(OK)
	var seated := await _wait_until(func() -> bool: return client.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("the client never got into the room").is_true()
	var was := client.local_slot

	# The host is told everybody is ready and goes. The word goes out first. The flags are kept
	# in a dictionary rather than in a local: a lambda captures a local by value, so setting one
	# from inside a signal handler sets the handler's own copy and nothing else.
	var seen := {"told": false, "ruled": false}
	client.match_beginning.connect(func() -> void: seen["told"] = true)
	host.begin_the_match()
	var heard := await _wait_until(func() -> bool: return seen["told"], 4000)
	assert_bool(heard).override_failure_message("the client was not told to follow").is_true()

	# Both change room. The connection is the same one; the match under it is not.
	var host_arena := _arena_match(_host_root, "Arena")
	host_arena.start(inputs, 23)
	host.match_node = host_arena
	var client_arena := _arena_match(_client_root, "Arena")
	client_arena.start_puppet()
	client.match_node = client_arena
	client.rules_applied.connect(func() -> void: seen["ruled"] = true)
	host.re_seat()

	# The arena's rules reach the client, not the waiting room's, and it has its seat back.
	var ruled := await _wait_until(func() -> bool: return seen["ruled"], 4000)
	assert_bool(ruled).override_failure_message("the arena's rules never arrived").is_true()
	assert_float(client_arena.rules.duration).is_equal(42.0)
	assert_int(client_arena.rules.lives).is_equal(4)
	var again := await _wait_until(func() -> bool: return client.local_slot >= 0, 4000)
	assert_bool(again).override_failure_message("the client was not seated again").is_true()
	assert_int(client.local_slot).is_equal(was)
	assert_bool(host_arena.slots[client.local_slot].input is NetInput).is_true()


## Nobody is told to follow by a client, and a host with nobody connected says nothing to
## anybody: the word is the host's and only goes out when there is somebody to hear it.
func test_only_a_host_with_company_says_it_is_going() -> void:
	var alone := _waiting_match(_host_root, "Waiting")
	alone.start([PlayerInput.new()] as Array[KartInput], 5)
	var host: NetSession = auto_free(NetSession.new())
	host.name = "Session"
	host.match_node = alone
	_host_root.add_child(host)
	assert_int(host.host(PORT + 1)).is_equal(OK)
	# No peers: nothing to say and nothing that throws for saying it.
	host.begin_the_match()
	host.re_seat()
	assert_bool(host.is_host).is_true()
