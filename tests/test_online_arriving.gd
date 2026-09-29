extends GdUnitTestSuite
## Arriving online, GAME.md 10.3: the handshake a new connection starts with, a newcomer shown into
## whichever room the host is in, and the lamps of a map held until everybody has the room up. A
## host and a client in one process through two multiplayer instances on separate subtrees, the
## same as the rest of the online suites.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## A port of this suite's own, so it can run beside the other network suites.
## How much slack every wait in this suite gets, see [method _wait_until].
const PATIENCE := 3

## Its own, since the suites run side by side; a suite that runs these again over a slower line,
## see [NetLag], takes another.
var port := 7841
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
	rules.lives = 1
	rules.duration = 60.0
	return rules


## Waits for [param condition], up to [param max_millis] of real time. These are budgets rather
## than measurements: the tests here run two whole matches over a real socket, and what is being
## asked is whether a client ever hears about something, not how many milliseconds it took. Every
## budget is multiplied by [constant PATIENCE], because a suite that has been running for seven
## minutes on a loaded machine is slower than the same suite run on its own, and a budget tight
## enough to catch that is a test that fails for reasons that have nothing to do with the game.
func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	var budget := max_millis * PATIENCE
	while not condition.call() and waited < budget:
		await await_millis(25)
		waited += 25
	return condition.call()


## GAME.md 10.3: two games play together on the same major and minor version, whatever the patch.
func test_only_the_patch_may_differ_between_games_that_play_together() -> void:
	assert_bool(NetDoor.compatible("0.5.0", "0.5.3")).is_true()
	assert_bool(NetDoor.compatible("0.5.2", "0.5.0")).is_true()
	assert_bool(NetDoor.compatible("0.5.0", "0.6.0")).is_false()
	assert_bool(NetDoor.compatible("1.5.0", "0.5.0")).is_false()
	assert_bool(NetDoor.compatible("0.5.0", "?")).is_false()


## A host and a client over a real socket, on the versions given, and what the client was told.
func _meet(host_version: String, client_version: String) -> Dictionary:
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
	host_session.version = host_version
	host_session.match_node = host_match
	_host_root.add_child(host_session)
	assert_int(host_session.host(port)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.version = client_version
	client_session.match_node = client_match
	client_session.local_input = KartInput.new()
	_client_root.add_child(client_session)
	var told: Array[String] = []
	client_session.refused.connect(func(reason: String) -> void: told.append(reason))
	var failed: Array[bool] = []
	client_session.connection_failed.connect(func() -> void: failed.append(true))
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	return {"host": host_match, "client": client_session, "told": told, "failed": failed}


## A client on another minor version is told which one the host has, and never gets a seat.
func test_a_client_on_another_version_is_turned_away() -> void:
	var met := await _meet("0.6.1", "0.5.4")
	var told: Array[String] = met["told"]
	var client: NetSession = met["client"]
	var host_match: Match = met["host"]
	var heard := await _wait_until(func() -> bool: return not told.is_empty(), 4000)
	assert_bool(heard).override_failure_message("the client was never told").is_true()
	assert_str(told[0]).contains("0.6.1").contains("0.5.4")
	await await_millis(300)
	assert_int(client.local_slot).is_equal(-1)
	assert_bool(host_match.slots[1].is_human()).is_false()
	assert_object(client.multiplayer.multiplayer_peer).is_not_null()
	assert_bool(client._connected()).is_false()
	# The reason is the whole story: a connection that failed as well would say it twice.
	assert_array(met["failed"]).is_empty()


## And one that differs only in the patch is let in and seated as usual.
func test_a_client_on_another_patch_is_let_in() -> void:
	var met := await _meet("0.6.1", "0.6.3")
	var client: NetSession = met["client"]
	var host_match: Match = met["host"]
	var seated := await _wait_until(func() -> bool: return client.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("client never got a slot").is_true()
	assert_bool(host_match.slots[1].is_human()).is_true()
	assert_array(met["told"]).is_empty()


## A host in an arena, and a client connecting to it from where joining opens: the waiting room.
func _arrive_mid_match(humans: int, with_hud := false) -> Dictionary:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD)]
	for i: int in humans - 1:
		inputs.append(NetInput.new())
	inputs.append(BotInput.new())
	host_match.start(inputs.slice(0, host_match.rules.max_players), 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
	host_session.in_arena = true
	host_session.match_node = host_match
	_host_root.add_child(host_session)
	assert_int(host_session.host(port)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = with_hud
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client_match
	client_session.local_input = KartInput.new()
	_client_root.add_child(client_session)
	var followed: Array[bool] = []
	client_session.match_beginning.connect(func() -> void: followed.append(true))
	var told: Array[String] = []
	client_session.refused.connect(func(reason: String) -> void: told.append(reason))
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	return {
		"host": host_match,
		"client": client_session,
		"room": client_match,
		"followed": followed,
		"told": told,
	}


## GAME.md 10.3: a client that connects to a host in the middle of a match is told to follow it
## into the arena, the same word everybody else had on the way in, and is seated once it asks from
## there. It was seated on the spot, into the arena's match from inside the waiting room.
func test_a_newcomer_to_a_match_follows_the_host_in_and_is_seated_there() -> void:
	var met := await _arrive_mid_match(1)
	var host_match: Match = met["host"]
	var client: NetSession = met["client"]
	var room: Match = met["room"]
	var followed: Array[bool] = met["followed"]
	var told := await _wait_until(func() -> bool: return not followed.is_empty(), 4000)
	assert_bool(told).override_failure_message("the newcomer was never told to follow").is_true()
	await await_millis(300)
	# Not seated from the waiting room, and not sent the arena to draw in it either.
	assert_int(client.local_slot).is_equal(-1)
	assert_bool(host_match.slots[1].is_human()).is_false()
	assert_array(room.slots).is_empty()
	# Arrived: asked for, and given.
	client.ready_for_seat()
	var seated := await _wait_until(func() -> bool: return client.local_slot >= 0, 4000)
	assert_bool(seated).override_failure_message("never seated in the arena").is_true()
	assert_bool(host_match.slots[client.local_slot].is_human()).is_true()
	var drawn := await _wait_until(func() -> bool: return room.slots.size() == 2, 4000)
	assert_bool(drawn).override_failure_message("never sent the match").is_true()


## Arriving on a Grand Prix podium, the newcomer sees the podium, with the run as it stands.
func test_a_newcomer_on_the_podium_sees_it_and_the_run() -> void:
	var runs: Array[Dictionary] = []
	var count_runs := func(run: Dictionary) -> void: runs.append(run)
	Events.grand_prix_scored.connect(count_runs)
	Game.grand_prix = GrandPrix.start(2, RandomNumberGenerator.new())
	var met := await _arrive_mid_match(1, true)
	var host_match: Match = met["host"]
	var client: NetSession = met["client"]
	var room: Match = met["room"]
	await _wait_until(func() -> bool: return not (met["followed"] as Array).is_empty(), 4000)
	await await_millis(200)
	host_match._finish()
	assert_int(host_match.state).is_equal(Match.State.RESULTS)
	client.ready_for_seat()
	var on_it := await _wait_until(func() -> bool: return room.hud._podium_up, 4000)
	Game.grand_prix = null
	Events.grand_prix_scored.disconnect(count_runs)
	assert_bool(on_it).override_failure_message("the newcomer never saw the podium").is_true()
	assert_int(room.state).is_equal(Match.State.RESULTS)
	assert_int(runs.size()).is_equal(1)
	assert_array(runs[0]["playlist"]).is_not_empty()


## A match with nobody left to take over and no room for another kart says so to a newcomer,
## rather than letting it build the room first.
func test_a_full_match_turns_a_newcomer_away_and_says_why() -> void:
	var met := await _arrive_mid_match(4)
	var host_match: Match = met["host"]
	var told: Array[String] = met["told"]
	assert_int(host_match.slots.size()).is_equal(host_match.rules.max_players)
	var heard := await _wait_until(func() -> bool: return not told.is_empty(), 4000)
	assert_bool(heard).override_failure_message("the newcomer was never told").is_true()
	assert_str(told[0]).is_equal("The match is full")
	assert_array(met["followed"]).is_empty()


## GAME.md 10.3: arriving at a map, the host holds the lamps until every client has the room up,
## and every screen says how many players it is waiting on.
func test_the_lamps_wait_for_every_client_to_have_the_room_up() -> void:
	var ticks: Array[int] = []
	var count_ticks := func(lamps: int) -> void: ticks.append(lamps)
	Events.countdown_tick.connect(count_ticks)
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	host_match.with_hud = true
	host_match.offer_size = 0
	host_match.hold_start = true
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	assert_int(host_match.state).is_equal(Match.State.LOBBY)
	assert_bool(host_match.kart_of(0).frozen).is_true()
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
	host_session.match_node = host_match
	_host_root.add_child(host_session)
	assert_int(host_session.host(port)).is_equal(OK)
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
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).override_failure_message("client never got a slot").is_true()
	host_session.hold_the_start()
	assert_that(host_match.loading).is_equal(Vector2i(1, 2))
	await await_millis(300)
	# Held: the lamps are not lit and nothing is counting down while the client builds the room.
	assert_int(host_match.state).is_equal(Match.State.LOBBY)
	assert_array(ticks).is_empty()
	assert_bool(host_match.hud._start_wait.visible).is_true()
	assert_bool(host_match.hud._lobby.visible).is_false()
	assert_str(host_match.hud._start_wait._label.text).is_equal("Waiting on 1 out of 2 players")
	var told := await _wait_until(
		func() -> bool: return client_match.loading == Vector2i(1, 2), 4000
	)
	assert_bool(told).override_failure_message("the client never heard the count").is_true()
	await await_millis(80)
	assert_bool(client_match.hud._start_wait.visible).is_true()
	assert_bool(client_match.hud._lobby.visible).is_false()
	client_session.room_built()
	var started := await _wait_until(
		func() -> bool: return host_match.state != Match.State.LOBBY, 4000
	)
	assert_bool(started).override_failure_message("the lamps never went").is_true()
	assert_that(host_match.loading).is_equal(Vector2i.ZERO)
	assert_array(ticks).is_not_empty()
	var cleared := await _wait_until(
		func() -> bool: return client_match.loading == Vector2i.ZERO, 4000
	)
	assert_bool(cleared).is_true()
	await await_millis(80)
	assert_bool(client_match.hud._start_wait.visible).is_false()
	Events.countdown_tick.disconnect(count_ticks)
