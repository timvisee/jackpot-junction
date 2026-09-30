extends GdUnitTestSuite
## A client that sends what no copy of the game sends is shown out, GAME.md 10.3, see [NetConduct]:
## told why, and everybody else told quietly. What a slow line sends is never held against anybody.
## A host and a client in one process over a real socket, as test_online.gd has them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## How much slack every wait in this suite gets, see test_online.gd.
const PATIENCE := 3

## Its own, since the suites run side by side.
var port := 7995
var _host_root: Node
var _client_root: Node
var _host: NetSession
var _client: NetSession
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


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## A host with a match going and a client seated in it.
func _connect() -> void:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	_host_match = auto_free(MATCH_SCENE.instantiate())
	_host_match.name = "Match"
	_host_match.rules = rules
	_host_match.with_hud = false
	_host_root.add_child(_host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	_host_match.start(inputs, 23)
	_host = auto_free(NetSession.new())
	_host.name = "Session"
	_host.match_node = _host_match
	_host_root.add_child(_host)
	assert_int(_host.host(port)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = rules.duplicate()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	_client = auto_free(NetSession.new())
	_client.name = "Session"
	_client.match_node = client_match
	_client.local_input = PlayerInput.new()
	_client.player_name = "Mallory"
	_client_root.add_child(_client)
	assert_int(_client.join("127.0.0.1", port)).is_equal(OK)
	var seated := await _wait_until(func() -> bool: return _client.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("the client was never seated").is_true()


func _connected() -> bool:
	return not _host.multiplayer.get_peers().is_empty()


## Controls that are not controls, a claim that is not a kart, a hand change that names no card:
## a few is a changed client, which is told why it is shown out, the others are told who went and
## why in a line of the feed, and a dedicated server writes it down. Fewer is nothing yet.
func test_a_client_that_sends_what_no_game_sends_is_shown_out() -> void:
	await _connect()
	var told := [""]
	_client.refused.connect(func(reason: String) -> void: told[0] = reason)
	var kicked: Array[String] = []
	# Host and client share one Events here: the host's own word, not its relay to the client.
	var note := func(named: String) -> void:
		if not NetSession._replaying:
			kicked.append(named)
	Events.player_kicked.connect(note)
	var worded := NetInput.encode(KartInput.new())
	worded[0] = "full left"
	_client._send_input.rpc_id(1, worded, 10_000, [], 0)
	_client.jokers._handled.rpc_id(1, 0, "yes", &"big_tank")
	await await_millis(400)
	assert_bool(_connected()).override_failure_message("shown out too soon").is_true()
	assert_array(kicked).is_empty()
	var claim := KartPrediction.capture(_host_match.kart_of(1))
	claim[0] = NAN
	_client._send_input.rpc_id(1, NetInput.encode(KartInput.new()), 10_001, claim, 0)
	var heard := await _wait_until(func() -> bool: return told[0] == NetConduct.KICKED, 4000)
	Events.player_kicked.disconnect(note)
	assert_bool(heard).override_failure_message("the client was never told").is_true()
	assert_array(kicked).is_equal(["Mallory"] as Array[String])
	var gone := await _wait_until(func() -> bool: return not _connected(), 4000)
	assert_bool(gone).override_failure_message("the host kept the client").is_true()


## What a slow line sends is not held against anybody however much of it there is: packets too
## late to play, claims from too far away to follow, a pick answered after it closed, a card it no
## longer holds.
func test_a_slow_line_is_never_shown_out() -> void:
	await _connect()
	var input := _host_match.slots[1].input as NetInput
	for i: int in 20:
		# Late, every one of them: numbered before the last the host has.
		_client._send_input.rpc_id(1, NetInput.encode(KartInput.new()), 0, [], 0)
		var far := KartPrediction.capture(_host_match.kart_of(1))
		far[0] = float(far[0]) + 50.0
		_client._send_input.rpc_id(1, NetInput.encode(KartInput.new()), input.last_seq + 1, far, 0)
		_client.jokers._answered.rpc_id(1, 0, &"big_tank", &"")
		_client.jokers._handled.rpc_id(1, 0, true, &"no_such_card")
	await await_millis(600)
	assert_bool(_connected()).override_failure_message("a slow line was shown out").is_true()
	assert_bool(_host.conduct._counts.is_empty()).is_true()
