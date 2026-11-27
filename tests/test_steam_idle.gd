extends GdUnitTestSuite
## A kart left alone in a public Steam game, GAME.md 10.8: what counts as somebody at the controls,
## and over a whole session, the kart handed to a bot, its player watching, and a press seating
## them again. Over ENet on this machine with [FakeSteam] for Steam, as test_steam_peer.gd plays.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var port := 0
var _host_root: Node
var _client_root: Node


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
	Store.steam = null
	SteamStore.loopback_port = 0
	Net.session = null
	Game.pending_config = null


## A stick off its middle, a pedal or a button is somebody at the controls; a stick resting a hair
## off it, and nothing at all, is not.
func test_what_counts_as_touched() -> void:
	var input := KartInput.new()
	assert_bool(HostControls.touched(input)).is_false()
	assert_bool(HostControls.touched(null)).is_false()
	input.steer = 0.05
	assert_bool(HostControls.touched(input)).is_false()
	input.steer = -0.8
	assert_bool(HostControls.touched(input)).is_true()
	input.steer = 0.0
	input.fire_pressed = true
	assert_bool(HostControls.touched(input)).is_true()
	input.fire_pressed = false
	input.emote = 2
	assert_bool(HostControls.touched(input)).is_true()


## In a public game the kart of a player who left it alone is a bot's; they watch, told so, until a
## press seats them again in a bot's kart.
func test_a_kart_left_alone_is_a_bots_till_a_press() -> void:
	SteamStore.loopback_port = port + 1
	Store.steam = SteamStore.new(FakeSteam.new())
	Store.steam.start(3141590)
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
	assert_int(host_session.host_steam()).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client_match
	client_session.local_input = KartInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join_steam(76561197960287931)).is_equal(OK)
	await _until(func() -> bool: return client_session.local_slot >= 0, 12000)
	assert_int(client_session.local_slot).is_equal(1)
	# A public game hosted here.
	Net.session = host_session
	Game.pending_config = SteamJoins.host_config(SteamLobby.Who.ANYONE)
	Store.steam.lobbies.host(8, SteamLobby.Who.ANYONE)
	assert_bool(Store.public_game()).is_true()
	var heard: Array[bool] = []
	client_session.host_controls.benched_changed.connect(func(on: bool) -> void: heard.append(on))
	host_session.host_controls.bench(1)
	assert_bool(host_match.slots[1].is_human()).is_false()
	await _until(func() -> bool: return client_session.host_controls.benched, 4000)
	assert_bool(client_session.watching).is_true()
	assert_int(client_session.local_slot).is_equal(-1)
	assert_array(heard).is_equal([true])
	# A press, and back in a bot's kart.
	client_session.local_input.throttle = 1.0
	await _until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(client_session.watching).is_false()
	assert_bool(client_session.host_controls.benched).is_false()
	assert_array(heard).is_equal([true, false])
	assert_bool(host_match.slots[client_session.local_slot].input is NetInput).is_true()


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
