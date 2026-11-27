extends GdUnitTestSuite
## A player back in their own kart in the map they dropped out of, GAME.md 10.8, see [RejoinSeats]:
## off Steam the secret the host gave them alone kept on disk at their machine, the last one only,
## with where it holds and till when; the host keeping the karts of whoever goes during a map, by
## that secret or a Steam account, for nobody shown out and never in the lobby; and the game started
## again knocking with the secret, sat in its own kart with its score. Over ENet on this machine.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const PATH := "user://test_rejoin.cfg"

var port := 0
var _roots: Array[Node] = []
var _settings_were: Settings


func before_test() -> void:
	port = FreePorts.take()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.pending_config = _config("127.0.0.1", port)


func after_test() -> void:
	for root: Node in _roots:
		get_tree().set_multiplayer(null, root.get_path())
	_roots.clear()
	Game.pending_config = null
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _config(address: String, at: int) -> MatchConfig:
	var config := MatchConfig.new()
	config.address = address
	config.port = at
	return config


func _until(done: Callable, most: int) -> void:
	var waited := 0
	while not done.call() and waited < most:
		await await_millis(25)
		waited += 25


## A root of its own for a machine, with its own multiplayer.
func _root(named: String) -> Node:
	var root: Node = auto_free(Node.new())
	root.name = named
	add_child(root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), root.get_path())
	_roots.append(root)
	return root


func _a_match(root: Node) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.name = "Match"
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	root.add_child(match_node)
	return match_node


## A game hosted here on [member port], a map in it with a bot.
func _a_host() -> NetSession:
	var root := _root("HostRoot")
	var host_match := _a_match(root)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host: NetSession = auto_free(NetSession.new())
	host.name = "Session"
	host.match_node = host_match
	root.add_child(host)
	assert_int(host.host(port)).is_equal(OK)
	return host


## A client of it under a root of its own named [param named], seated.
func _a_client(named: String) -> NetSession:
	var root := _root(named)
	var client_match := _a_match(root)
	client_match.start_puppet()
	var client: NetSession = auto_free(NetSession.new())
	client.name = "Session"
	client.match_node = client_match
	client.local_input = KartInput.new()
	root.add_child(client)
	assert_int(client.join("127.0.0.1", port)).is_equal(OK)
	await _until(func() -> bool: return client.local_slot >= 0, 12000)
	return client


## Gone in the middle of a map, as a crash goes, and started again: back in its own kart, its score
## and all, by the secret it kept on disk; and given a new one there, which is the one kept now.
func test_back_in_its_own_kart_after_starting_again() -> void:
	var host := _a_host()
	var host_match := host.match_node
	var gone: NetSession = await _a_client("GoneRoot")
	var told := func() -> bool: return not gone.host_controls.rejoin_token.is_empty()
	await _until(told, 4000)
	var secret := gone.host_controls.rejoin_token
	assert_int(secret.length()).is_equal(32)
	var on_disk := Settings.new()
	on_disk.path = PATH
	on_disk.load_from_disk()
	assert_str(str(on_disk.rejoin.get("token", ""))).is_equal(secret)
	await _until(func() -> bool: return host_match.state in MatchResume.PLAYING, 4000)
	var index := gone.local_slot
	host_match.slots[index].banked = 99
	var color := host_match.slots[index].color_index
	gone.multiplayer.multiplayer_peer.close()
	await _until(func() -> bool: return not host_match.slots[index].is_human(), 4000)
	assert_bool(host_match.slots[index].is_human()).is_false()
	var again: NetSession = await _a_client("AgainRoot")
	assert_int(again.local_slot).is_equal(index)
	assert_int(host_match.slots[index].color_index).is_equal(color)
	assert_int(host_match.slots[index].banked).is_equal(99)
	var new_one := func() -> bool:
		var now := again.host_controls.rejoin_token
		return not now.is_empty() and now != secret
	await _until(new_one, 4000)
	assert_str(RejoinSeats.token_for(Game.pending_config)).is_equal(
		again.host_controls.rejoin_token
	)
	host.free()


## The karts kept are kept while a map is played, by the proof of the secret or the Steam account,
## for one claim; not for somebody shown out, nor in the lobby; and those of a map carried over
## nobody came back for in time kept the same way.
func test_what_the_host_keeps() -> void:
	var host := _a_host()
	await _until(func() -> bool: return host.match_node.state in MatchResume.PLAYING, 4000)
	var kept := RejoinSeats.new()
	var token := kept.token_of(5)
	kept.went(host, 5, {0: 1})
	assert_dict(kept.claim(0, "")).is_empty()
	assert_dict(kept.claim(0, RejoinSeats.new_token())).is_empty()
	assert_int(int(kept.claim(0, token)[0]["slot"])).is_equal(1)
	assert_dict(kept.claim(0, token)).is_empty()
	var shown := kept.token_of(6)
	kept.shown_out(6)
	kept.went(host, 6, {0: 1})
	assert_dict(kept.claim(0, shown)).is_empty()
	kept.knocked(7, 4242)
	kept.went(host, 7, {0: 1})
	assert_dict(kept.claim(4242, "")).is_not_empty()
	var adopted := RejoinSeats.new_token()
	var seats := {
		0: {"slot": 1, "color": 3, "team": -1, "name": "Bo", "proof": adopted.sha256_text()}
	}
	kept.adopt({"p3": seats})
	assert_int(int(kept.claim(0, adopted)[0]["color"])).is_equal(3)
	host.match_node.state = Match.State.LOBBY
	var in_lobby := kept.token_of(8)
	kept.went(host, 8, {0: 1})
	assert_dict(kept.claim(0, in_lobby)).is_empty()
	host.free()


## Only the last secret is kept, and it holds where it was given and down the line of who hosts
## next, and only till it runs out.
func test_the_secret_holds_where_and_while_it_does() -> void:
	var line := [{"peer": 4, "address": "10.0.0.5"}]
	RejoinSeats.remember("first", _config("127.0.0.1", 7000), line, 7000)
	RejoinSeats.remember("last", _config("127.0.0.1", 7000), line, 7000)
	assert_str(RejoinSeats.token_for(_config("127.0.0.1", 7000))).is_equal("last")
	assert_str(RejoinSeats.token_for(_config("10.0.0.5", 7000))).is_equal("last")
	assert_str(RejoinSeats.token_for(_config("10.0.0.6", 7000))).is_empty()
	assert_str(RejoinSeats.token_for(_config("127.0.0.1", 7001))).is_empty()
	assert_str(RejoinSeats.token_for(_config("", 7000))).is_empty()
	Game.settings.rejoin["until"] = Time.get_unix_time_from_system() - 1.0
	assert_str(RejoinSeats.token_for(_config("127.0.0.1", 7000))).is_empty()
