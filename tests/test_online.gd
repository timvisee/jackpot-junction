extends GdUnitTestSuite
## Online play, GAME.md 9.3: a host and a client in one process through two multiplayer
## instances on separate subtrees. The client gets a slot, sees snapshots, drives its kart on
## the host, and the kart goes back to a bot when the client leaves.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const PORT := 7791

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


func _quick_rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	return rules


func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	while not condition.call() and waited < max_millis:
		await await_millis(25)
		waited += 25
	return condition.call()


func test_snapshot_round_trip_describes_the_match() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [KartInput.new(), BotInput.new()]
	host_match.start(inputs, 23)
	host_match.kart_of(0).pot.add_coins(7)
	var data := host_match.build_snapshot()
	assert_int(data["slots"].size()).is_equal(2)
	assert_int(data["karts"].size()).is_equal(2)
	assert_int(data["pickups"].size()).is_greater(10)
	var bytes := var_to_bytes(data)
	var decoded: Dictionary = bytes_to_var(bytes)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.rules = _quick_rules()
	client_match.with_hud = true
	_client_root.add_child(client_match)
	client_match.start_puppet()
	client_match.set_local_slot(0)
	client_match.apply_snapshot(decoded)
	assert_int(client_match.slots.size()).is_equal(2)
	assert_int(client_match.kart_of(0).pot.coins).is_equal(7)
	assert_bool(client_match.kart_of(0).puppet).is_true()
	assert_int(client_match.arena.pickups.get_child_count()).is_equal(data["pickups"].size())
	assert_int(client_match.hud._blocks.size()).is_equal(1)
	assert_str(client_match.slots[1].display_name()).contains("P2")


func test_client_joins_takes_over_a_bot_drives_it_and_hands_it_back_on_leaving() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
	host_session.match_node = host_match
	_host_root.add_child(host_session)
	assert_int(host_session.host(PORT)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = true
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client_match
	client_session.local_input = KartInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", PORT)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).override_failure_message("client never got a slot").is_true()
	assert_int(client_session.local_slot).is_equal(1)
	assert_bool(host_match.slots[1].input is NetInput).is_true()
	assert_bool(host_match.slots[1].is_human()).is_true()
	var seen := await _wait_until(
		func() -> bool: return client_match._puppet_karts.size() >= 2, 4000
	)
	assert_bool(seen).override_failure_message("client never saw the karts").is_true()
	assert_int(client_match.slots.size()).is_equal(2)
	assert_int(client_match.hud._blocks.size()).is_equal(1)
	var kart := host_match.kart_of(1)
	var start := kart.global_position
	client_session.local_input.throttle = 1.0
	await await_millis(1200)
	assert_float(kart.global_position.distance_to(start)).is_greater(2.0)
	var puppet: Kart = client_match.slots[1].kart
	assert_float(puppet.global_position.distance_to(kart.global_position)).is_less(3.0)
	client_session.multiplayer.multiplayer_peer.close()
	var handed_back := await _wait_until(
		func() -> bool: return not host_match.slots[1].is_human(), 4000
	)
	assert_bool(handed_back).is_true()
	assert_object(host_match.slots[1].bot_trait).is_not_null()


func test_the_host_holds_the_match_in_a_lobby_until_it_begins() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.rules = _quick_rules()
	host_match.with_hud = true
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	host_match.lobby_hint = "port 7791"
	host_match.hold_in_lobby()
	assert_int(host_match.state).is_equal(Match.State.LOBBY)
	assert_bool(host_match.kart_of(0).frozen).is_true()
	await await_millis(80)
	assert_bool(host_match.hud._lobby.visible).is_true()
	assert_str(host_match.hud._lobby_rows.text).contains("P1")
	var joined := host_match.join_network(NetInput.new())
	assert_object(joined).is_not_null()
	assert_bool(joined.kart.frozen).is_true()
	var snapshot := host_match.build_snapshot()
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.rules = _quick_rules()
	client_match.with_hud = true
	_client_root.add_child(client_match)
	client_match.start_puppet()
	client_match.set_local_slot(1)
	client_match.apply_snapshot(snapshot)
	assert_int(client_match.state).is_equal(Match.State.LOBBY)
	assert_bool(client_match.slots[1].is_human()).is_true()
	await await_millis(80)
	assert_bool(client_match.hud._lobby.visible).is_true()
	assert_bool(client_match.hud._lobby_start.visible).is_false()
	client_match.begin_from_lobby()
	assert_int(client_match.state).is_equal(Match.State.LOBBY)
	host_match.begin_from_lobby()
	assert_int(host_match.state).is_equal(Match.State.COUNTDOWN)
	await await_millis(300)
	assert_int(host_match.state).is_equal(Match.State.PLAYING)
	assert_bool(host_match.kart_of(0).frozen).is_false()


func test_puppets_glide_toward_new_snapshot_positions_instead_of_jumping() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host_match.start(inputs, 23)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	client_match.set_local_slot(0)
	var kart := host_match.kart_of(0)
	kart.global_position = Vector3(-4.5, 0.0, 1.0)
	client_match.apply_snapshot(host_match.build_snapshot())
	var puppet: Kart = client_match.slots[0].kart
	assert_vector(puppet.global_position).is_equal_approx(
		Vector3(-4.5, 0.0, 1.0), Vector3.ONE * 0.001
	)
	kart.global_position = Vector3(-2.5, 0.0, 1.0)
	client_match.apply_snapshot(host_match.build_snapshot())
	assert_vector(puppet.global_position).is_equal_approx(
		Vector3(-4.5, 0.0, 1.0), Vector3.ONE * 0.001
	)
	await await_millis(40)
	assert_float(puppet.global_position.x).is_between(-4.4, -2.6)
	await await_millis(400)
	assert_float(puppet.global_position.x).is_equal_approx(-2.5, 0.05)
	kart.global_position = Vector3(10.0, 0.0, 1.0)
	client_match.apply_snapshot(host_match.build_snapshot())
	assert_vector(puppet.global_position).is_equal_approx(
		Vector3(10.0, 0.0, 1.0), Vector3.ONE * 0.001
	)
