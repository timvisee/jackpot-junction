extends GdUnitTestSuite
## Joining a Steam game's match in play, GAME.md 10.8: a newcomer taking over a bot's kart is told
## whose it was and what came with it; one coming in during Last Call watches until the next map and
## is let go to sit down there as the host leaves the room. Over ENet on this machine with
## [FakeSteam] for Steam, as test_steam_peer.gd plays.

const FreePorts := preload("res://tests/free_ports.gd")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var port := 0
var _host_root: Node
var _client_root: Node
var _host_match: Match
var _host_session: NetSession


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


## What the ticket says.
func test_the_tickets_words() -> void:
	assert_str(TakeoverTicket.words("Kit")).is_equal("You took over Kit's kart")
	assert_str(TakeoverTicket.words("")).is_equal("You took over a kart")
	assert_str(TakeoverTicket.came_with(420, 60, 2)).is_equal(
		"420 banked · 60 in the pot · 2 jokers"
	)
	assert_str(TakeoverTicket.came_with(0, 0, 1)).is_equal("0 banked · 0 in the pot · 1 joker")


## A Steam game hosted here, a match playing in it with a bot, and a client on its way in.
func _host_a_steam_match() -> NetSession:
	SteamStore.loopback_port = port + 1
	Store.steam = SteamStore.new(FakeSteam.new())
	Store.steam.start(3141590)
	_host_match = auto_free(MATCH_SCENE.instantiate())
	_host_match.name = "Match"
	_host_match.rules = _quick_rules()
	_host_match.with_hud = false
	_host_match.offer_size = 0
	_host_root.add_child(_host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	_host_match.start(inputs, 23)
	_host_session = auto_free(NetSession.new())
	_host_session.name = "Session"
	_host_session.match_node = _host_match
	_host_root.add_child(_host_session)
	assert_int(_host_session.host_steam()).is_equal(OK)
	_host_session.in_arena = true
	Net.session = _host_session
	Game.pending_config = SteamJoins.host_config(SteamLobby.Who.ANYONE)
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
	_client_root.add_child(client)
	# Told to follow the host into the arena, it asks for its seat there, as the match scene does.
	client.match_beginning.connect(client.ready_for_seat)
	return client


## Into the bot's kart in the middle of the match, and told whose it was and what came with it.
func test_a_bots_kart_taken_over_says_whose() -> void:
	var client := await _host_a_steam_match()
	await _until(func() -> bool: return _host_match.is_running(), 4000)
	var bot_name := _host_match.slots[1].display_name()
	_host_match.slots[1].banked = 420
	var heard: Array = []
	client.host_controls.took_over.connect(
		func(from: String, banked: int, coins: int, jokers: int) -> void:
			heard.append([from, banked, coins, jokers])
	)
	assert_int(client.join_steam(76561197960287931)).is_equal(OK)
	await _until(func() -> bool: return not heard.is_empty(), 12000)
	assert_int(client.local_slot).is_equal(1)
	assert_array(heard).has_size(1)
	assert_str(heard[0][0]).is_equal(PlayerNames.clean(bot_name))
	assert_int(heard[0][1]).is_equal(420)


## Coming in during Last Call: watching, told so, until the host leaves the room, then let go.
func test_too_late_in_a_map_watches_till_the_next() -> void:
	var client := await _host_a_steam_match()
	await _until(func() -> bool: return _host_match.is_running(), 4000)
	_host_match._set_state(Match.State.LAST_CALL)
	assert_bool(_host_match.in_the_finale()).is_true()
	assert_int(client.join_steam(76561197960287931)).is_equal(OK)
	await _until(func() -> bool: return client.host_controls.held, 12000)
	assert_bool(client.host_controls.held).is_true()
	assert_bool(client.watching).is_true()
	assert_int(client.local_slot).is_equal(-1)
	assert_bool(_host_match.slots[1].is_human()).is_false()
	# The host leaving for the next map lets the newcomer go to sit down there.
	_host_session._leaving()
	await _until(func() -> bool: return not client.host_controls.held, 4000)
	assert_bool(client.watching).is_false()
	assert_bool(_host_session._watchers.has(_host_session.multiplayer.get_peers()[0])).is_false()


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
