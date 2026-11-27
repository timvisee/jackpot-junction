extends GdUnitTestSuite
## A game hosted at a player's machine off Steam handed to a new host as its host goes, GAME.md
## 10.8 and 9.3: whether a game is hosted at an address yet; who the host says hosts after it, at
## which address and from what; the first in line taking it on as the host goes, over a real
## connection; everybody else asking at its address and following it in once a game answers; the
## next in line taking it on when nobody does; and the game it is taken on as, its password kept.
## A host gone quiet rather than hanging up asked after at its own address first: still answering,
## it was this machine's connection that went. Over ENet on this machine.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var port := 0
var _host_root: Node
var _client_root: Node
var _handover: HostHandover
var _went: Array[MatchConfig] = []
var _gave_up: Array[String] = []


## Stands in for [HostHandover] at Make host: what it was handed down.
class HandedDown:
	extends Node
	var got: Array = []

	func hand_down(line: Array, port: int, plan: String) -> void:
		got = [line, port, plan]


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
	_went.clear()
	_gave_up.clear()
	_handover = HostHandover.new()
	_handover.go_on = func(config: MatchConfig) -> void: _went.append(config)
	_handover.play_on = func(config: MatchConfig) -> void: _went.append(config)
	_handover.give_up_to = func(why: String) -> void: _gave_up.append(why)
	add_child(_handover)


func after_test() -> void:
	_handover.free()
	get_tree().set_multiplayer(null, _host_root.get_path())
	get_tree().set_multiplayer(null, _client_root.get_path())
	Game.pending_config = null


func _until(done: Callable, most: int) -> void:
	var waited := 0
	while not done.call() and waited < most:
		await await_millis(25)
		waited += 25


func _quick_rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	return rules


## A game hosted here on [member port], a match in it with a bot.
func _a_host() -> NetSession:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host: NetSession = auto_free(NetSession.new())
	host.name = "Session"
	host.match_node = host_match
	_host_root.add_child(host)
	assert_int(host.host(port)).is_equal(OK)
	return host


## A client of it, seated, knocking with [param password].
func _a_client(password := "") -> NetSession:
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client: NetSession = auto_free(NetSession.new())
	client.name = "Session"
	client.match_node = client_match
	client.local_input = KartInput.new()
	client.password = password
	_client_root.add_child(client)
	assert_int(client.join("127.0.0.1", port)).is_equal(OK)
	await _until(func() -> bool: return client.local_slot >= 0, 12000)
	return client


## A game is found at its address once it is hosted there, and not at a port nobody hosts on.
func test_asking_whether_a_game_is_up() -> void:
	var host := _a_host()
	var probe := HostProbe.new("127.0.0.1", port)
	await _until(
		func() -> bool:
			probe.poll()
			return probe.reached or probe.failed,
		6000
	)
	assert_bool(probe.reached).is_true()
	var nobody := HostProbe.new("127.0.0.1", FreePorts.take())
	await _until(
		func() -> bool:
			nobody.poll()
			return nobody.reached or nobody.failed,
		8000
	)
	assert_bool(nobody.reached).is_false()
	assert_bool(HostProbe.new("", port).failed).is_true()
	host.free()


## The host tells every player who hosts after it, at the address it reaches them at, on which port,
## from what and who it is; and as the host goes, the first in line, this one, takes the game on.
func test_the_first_in_line_takes_it_on() -> void:
	var host := _a_host()
	Game.pending_config = MatchConfig.new()
	Game.pending_config.port = port
	host.door.password = "secret"
	var client: NetSession = await _a_client("secret")
	await _until(func() -> bool: return not client.host_controls.succession.is_empty(), 4000)
	var line := client.host_controls.succession
	assert_int(line.size()).is_equal(1)
	assert_int(int(line[0]["peer"])).is_equal(client.multiplayer.get_unique_id())
	assert_str(str(line[0]["address"])).is_equal("127.0.0.1")
	assert_int(client.host_controls.succession_port).is_equal(port)
	var plan: Dictionary = JSON.parse_string(client.host_controls.succession_plan)
	assert_str(str(plan["door"]["password"])).is_equal("secret")
	assert_str(client.host_controls.succession_host).is_not_empty()
	# The host goes, hanging up, heard from just before: the connection drops, and this player
	# hosts the game next, the room as the old host had it and its password kept.
	await _until(func() -> bool: return client.ping.heard_lately(), 2000)
	assert_bool(client.ping.heard_lately()).is_true()
	Game.pending_config = MatchConfig.new()
	Game.pending_config.online = "join"
	Game.pending_config.address = "127.0.0.1"
	Game.pending_config.port = port
	host.multiplayer.multiplayer_peer.close()
	await _until(func() -> bool: return not _went.is_empty(), 6000)
	assert_int(_went.size()).is_equal(1)
	assert_str(_went[0].online).is_equal("host")
	assert_bool(_went[0].rehost).is_true()
	assert_bool(_went[0].steam).is_false()
	assert_int(_went[0].port).is_equal(port)
	assert_str(_went[0].password).is_equal("secret")
	assert_bool(client.host_controls.succession.is_empty()).is_false()


## Somebody watching, let in without the password, is told who hosts next but not the password.
func test_watchers_are_not_told_the_password() -> void:
	var host := _a_host()
	Game.pending_config = MatchConfig.new()
	Game.pending_config.port = port
	host.door.password = "secret"
	host.door.watchers_need_password = false
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var watcher: NetSession = auto_free(NetSession.new())
	watcher.name = "Session"
	watcher.match_node = client_match
	watcher.watching = true
	_client_root.add_child(watcher)
	assert_int(watcher.join("127.0.0.1", port)).is_equal(OK)
	var told := func() -> bool: return not watcher.host_controls.succession_plan.is_empty()
	await _until(told, 8000)
	var plan: Dictionary = JSON.parse_string(watcher.host_controls.succession_plan)
	assert_bool((plan["door"] as Dictionary).has("password")).is_false()
	assert_int(watcher.host_controls.succession_port).is_equal(port)
	host.free()


## Make host off Steam: the player made host put first in line, everybody told so before the game
## is handed down to them, from the room as it is, its password with it.
func test_make_host_hands_it_down() -> void:
	var host := _a_host()
	Game.pending_config = MatchConfig.new()
	Game.pending_config.port = port
	host.door.password = "secret"
	var client: NetSession = await _a_client("secret")
	await _until(func() -> bool: return not client.host_controls.succession.is_empty(), 4000)
	_handover.remove_from_group(HostHandover.GROUP)
	var stub: HandedDown = auto_free(HandedDown.new())
	stub.add_to_group(HostHandover.GROUP)
	add_child(stub)
	var peer := client.multiplayer.get_unique_id()
	host.in_arena = false
	host.host_controls.hand_on(peer)
	assert_int(stub.got.size()).is_equal(3)
	assert_int(int((stub.got[0] as Array)[0]["peer"])).is_equal(peer)
	assert_int(int(stub.got[1])).is_equal(port)
	var plan: Dictionary = JSON.parse_string(str(stub.got[2]))
	assert_str(str(plan["door"]["password"])).is_equal("secret")
	# Told before it was handed down: the order as of now has gone to the client already.
	assert_str(str(host.host_controls._succession_told.get(peer, ""))).contains(str(peer))
	host.free()


## The one in line is somebody else: asked at their address until a game answers there, and
## followed in as the player this one was; nobody answering, the next in line, this one, takes it
## on.
func test_following_down_the_line() -> void:
	var host := _a_host()
	_handover._kind = HostHandover.Kind.LAN
	_handover._me = 9
	_handover._password = "secret"
	_handover._port = port
	_handover._line = [{"peer": 5, "address": "127.0.0.1", "name": "Bo"}]
	await _until(func() -> bool: return not _went.is_empty(), 6000)
	assert_str(_handover.dialog._line.text).is_equal("Migrating host to Bo...")
	assert_int(_went.size()).is_equal(1)
	assert_str(_went[0].online).is_equal("join")
	assert_str(_went[0].address).is_equal("127.0.0.1")
	assert_int(_went[0].port).is_equal(port)
	assert_str(_went[0].password).is_equal("secret")
	assert_int(_went[0].was_peer).is_equal(9)
	host.free()
	# Nobody answering at the first in line: past their wait, the next, this one, hosts.
	_went.clear()
	_handover._kind = HostHandover.Kind.LAN
	_handover._me = 9
	_handover._line = [
		{"peer": 5, "address": "127.0.0.1", "name": "Bo"},
		{"peer": 9, "address": "127.0.0.1", "name": "Ann"},
	]
	_handover._port = FreePorts.take()
	_handover._stage = 0
	_handover._stage_left = 0.3
	await _until(func() -> bool: return not _went.is_empty(), 6000)
	assert_int(_went.size()).is_equal(1)
	assert_str(_went[0].online).is_equal("host")
	# Nobody left in line at all: the game is over.
	_handover._kind = HostHandover.Kind.LAN
	_handover._line = []
	await await_millis(100)
	assert_array(_gave_up).has_size(1)


## The host gone quiet, not heard from as the connection went: asked after at its own address
## first. A game still answering there means it was this machine's connection that went, and it is
## out of the game; nobody answering, the game goes down the line, this machine first in it.
func test_asking_after_a_quiet_host() -> void:
	var host := _a_host()
	_handover._kind = HostHandover.Kind.LAN
	_handover._me = 9
	_handover._port = FreePorts.take()
	_handover._line = [{"peer": 9, "address": "127.0.0.1", "name": "Ann"}]
	_handover._old_address = "127.0.0.1"
	_handover._old_port = port
	_handover._asking_old = true
	await _until(func() -> bool: return not _gave_up.is_empty(), 6000)
	assert_array(_gave_up).contains_exactly([HostHandover.LOST])
	assert_array(_went).is_empty()
	host.free()
	# Its game gone from there too: this machine, first in line, takes it on.
	_handover._kind = HostHandover.Kind.LAN
	_handover._line = [{"peer": 9, "address": "127.0.0.1", "name": "Ann"}]
	_handover._old_port = FreePorts.take()
	_handover._asking_old = true
	await _until(func() -> bool: return not _went.is_empty(), 9000)
	assert_int(_went.size()).is_equal(1)
	assert_str(_went[0].online).is_equal("host")
	assert_bool(_handover._asking_old).is_false()


## The game a new host off Steam takes on: the old host's match and door, its password with it.
func test_the_game_taken_on() -> void:
	var config := MatchConfig.new()
	config.duration = 180.0
	var door := NetDoor.new()
	door.password = "secret"
	door.max_players = 6
	var plan := MatchResume.plan_of(config, door, -1, true)
	var taken := HostHandover.line_config(plan, 7790)
	assert_str(taken.online).is_equal("host")
	assert_int(taken.port).is_equal(7790)
	assert_float(taken.duration).is_equal(180.0)
	assert_str(taken.password).is_equal("secret")
	assert_int(int(taken.door_plan["max_players"])).is_equal(6)
	assert_bool(taken.rehost).is_true()
	# A Steam game's plan says no password.
	var steam := JSON.parse_string(MatchResume.plan_of(config, door, 1)) as Dictionary
	assert_bool((steam["door"] as Dictionary).has("password")).is_false()
	var follow := HostHandover.follow_config("10.0.0.7", 7790, "secret", 4, true)
	assert_bool(follow.watching).is_true()
	assert_int(follow.was_peer).is_equal(4)
