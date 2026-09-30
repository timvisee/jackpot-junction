extends GdUnitTestSuite
## Online play, GAME.md 9.3: a host and a client in one process through two multiplayer
## instances on separate subtrees. The client gets a slot, sees snapshots, drives its kart on
## the host, and the kart goes back to a bot when the client leaves.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## How much slack every wait in this suite gets, see [method _wait_until].
const PATIENCE := 3

## Its own, since the suites run side by side; a suite that runs these again over a slower line,
## see [NetLag], takes another.
var port := 7791
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
	# A pot halfway through a cash-out is worth less than its coins times its mult, and that is
	# the number both screens show, GAME.md 10.3.
	host_match.kart_of(0).pot.add_mult(2.0)
	host_match.kart_of(0).pot.drain(5.5)
	assert_int(host_match.kart_of(0).pot.value()).is_equal(15)
	data = host_match.build_snapshot()
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
	assert_int(client_match.kart_of(0).pot.value()).is_equal(host_match.kart_of(0).pot.value())
	assert_bool(client_match.kart_of(0).puppet).is_true()
	assert_int(client_match.arena.pickups.get_child_count()).is_equal(data["pickups"].size())
	assert_int(client_match.hud._blocks.size()).is_equal(1)
	# A client lights its own Junction ring off the pot the snapshot just handed it, GAME.md 3.4.
	assert_bool(client_match.arena.junction.winning).is_false()
	client_match.rules.target_score = 5
	client_match.apply_snapshot(decoded)
	assert_bool(client_match.arena.junction.winning).is_true()
	assert_str(client_match.slots[1].display_name()).contains("P2")


func test_client_joins_takes_over_a_bot_drives_it_and_hands_it_back_on_leaving() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	# The host has a HUD of its own, so what it puts on its own screen for a player at the other
	# end of a wire is part of what this is checking.
	host_match.with_hud = true
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
	host_session.match_node = host_match
	_host_root.add_child(host_session)
	assert_int(host_session.host(port)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	# A lobby of its own, set to nothing like the host's.
	client_match.rules.target_score = 777
	client_match.rules.duration = 42.0
	client_match.rules.lives = 5
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
	assert_int(client_session.local_slot).is_equal(1)
	# The client came up on its own lobby settings and is now playing the host's match, so the
	# host's numbers replace them, GAME.md 10.3.
	assert_int(client_match.rules.target_score).is_equal(host_match.rules.target_score)
	assert_float(client_match.rules.duration).is_equal(host_match.rules.duration)
	assert_int(client_match.rules.lives).is_equal(host_match.rules.lives)
	assert_bool(host_match.slots[1].input is NetInput).is_true()
	assert_bool(host_match.slots[1].is_human()).is_true()
	# The host drives one kart, so it has one corner block, one hand and one joker pick. The
	# player on the other end of the wire has their own screen for all three.
	assert_bool(host_match.slots[1].is_local_human()).is_false()
	assert_array(host_match.hud._blocks.keys()).is_equal([0])
	assert_array(host_match.hud._hands.keys()).is_equal([0])
	assert_array(host_match.hud._pickers.keys()).is_equal([0])
	var seen := await _wait_until(
		func() -> bool: return client_match.puppet_karts.size() >= 2, 4000
	)
	assert_bool(seen).override_failure_message("client never saw the karts").is_true()
	assert_int(client_match.slots.size()).is_equal(2)
	assert_int(client_match.hud._blocks.size()).is_equal(1)
	# The client is player two at the table but the only player in the room, so its block takes
	# the corner a lone player always gets rather than the second player's corner.
	assert_array(client_match.hud._blocks.keys()).is_equal([1])
	assert_int(client_match.hud._blocks[1]["corner"]).is_equal(0)
	var kart := host_match.kart_of(1)
	var start := kart.global_position
	client_session.local_input.throttle = 1.0
	await await_millis(1200)
	assert_float(kart.global_position.distance_to(start)).is_greater(2.0)
	# The kart this player drives is driven here, GAME.md 10.3, not waited for.
	assert_bool(client_session.seats[0].prediction != null).is_true()
	assert_bool(client_match.slots[1].kart.predicted).is_true()
	var puppet: Kart = client_match.slots[1].kart
	assert_float(puppet.global_position.distance_to(kart.global_position)).is_less(3.0)
	client_session.multiplayer.multiplayer_peer.close()
	var handed_back := await _wait_until(
		func() -> bool: return not host_match.slots[1].is_human(), 4000
	)
	assert_bool(handed_back).is_true()
	assert_object(host_match.slots[1].bot_trait).is_not_null()


## An event a host relays is raised once on the client and not relayed again. Run side by side in
## one process, as here, the two sessions hear the one [Events], and the client raising what the
## host told it was the host hearing it afresh: the pair passed it back and forth for as long as
## they were connected, which buried everything else going down the wire.
func test_a_relayed_event_is_not_relayed_back() -> void:
	var heard: Array[int] = []
	var count_joins := func(slot: int) -> void: heard.append(slot)
	Events.player_joined.connect(count_joins)
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
	assert_int(host_session.host(port)).is_equal(OK)
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
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).is_true()
	await await_millis(500)
	Events.player_joined.disconnect(count_joins)
	# Once where the host seated them, once where the client was told.
	assert_array(heard).is_equal([1, 1])


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
	assert_str(host_match.hud._lobby_rows.text).contains(host_match.slots[0].display_name())
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


## GAME.md 10.3: a client is told what is there rather than keeping its own clocks. A crate that
## ran one would come back the frame after a snapshot broke it, and the next snapshot would find
## it whole and break it again, throwing a fresh burst of debris thirty times a second for as
## long as it was really gone.
func test_a_broken_crate_bursts_once_on_a_client() -> void:
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var runner := scene_runner(client_match)
	await runner.simulate_frames(4, 17)
	var crate := client_match.arena.crates[0]
	assert_bool(crate.puppet).is_true()
	# A snapshot in which that one crate has gone, repeated the way the host repeats them.
	var broken: Array = []
	for other: Crate in client_match.arena.crates:
		broken.append(other != crate)
	for i: int in 30:
		MatchSnapshot.apply(client_match, _crate_snapshot(client_match, broken))
		await runner.simulate_frames(2, 17)
	assert_bool(crate.alive).is_false()
	assert_int(_bursts(client_match)).is_less_equal(1)
	# And it comes back when, and only when, the host says so.
	var whole: Array = []
	for other: Crate in client_match.arena.crates:
		whole.append(true)
	MatchSnapshot.apply(client_match, _crate_snapshot(client_match, whole))
	await runner.simulate_frames(2, 17)
	assert_bool(crate.alive).is_true()


## A host snapshot of a match standing still, with the crates in the state given.
func _crate_snapshot(match_node: Match, crates: Array) -> Dictionary:
	var data := MatchSnapshot.build(match_node)
	data["crates"] = crates
	return data


func _bursts(match_node: Match) -> int:
	var count := 0
	for node: Node in match_node.get_tree().get_nodes_in_group(&"bursts"):
		if match_node.is_ancestor_of(node):
			count += 1
	return count


## GAME.md 8.4: the kart you drive sounds like your own and everybody else's sounds like a kart
## somebody else is driving. The host says which slot is yours in a message of its own, which
## lands after the first snapshot has already built the karts, so the voice has to be asked for
## again rather than settled once on the way in.
func test_your_own_kart_finds_its_voice_once_the_host_says_which_is_yours() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _quick_rules()
	host.with_hud = false
	host.offer_size = 0
	_host_root.add_child(host)
	var inputs: Array[KartInput] = [PlayerInput.new(), BotInput.new()]
	host.start(inputs, 9)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _quick_rules()
	client.with_hud = false
	client.offer_size = 0
	_client_root.add_child(client)
	client.start_puppet()
	var runner := scene_runner(client)
	await runner.simulate_frames(4, 17)
	# Snapshots first, the slot assignment after, which is the order they really arrive in.
	MatchSnapshot.apply(client, MatchSnapshot.build(host))
	await runner.simulate_frames(2, 17)
	assert_int(client.local_slot).is_equal(-1)
	client.set_local_slot(1)
	MatchSnapshot.apply(client, MatchSnapshot.build(host))
	await runner.simulate_frames(2, 17)
	var mine := client.kart_of(1)
	var theirs := client.kart_of(0)
	assert_bool(mine.sound.lean).override_failure_message("own kart kept a bot voice").is_false()
	assert_bool(mine.driven_here).is_true()
	assert_bool(theirs.sound.lean).is_true()
	assert_bool(theirs.driven_here).is_false()


## GAME.md 3.8: online it takes the whole room. One player in the menu is one player not
## driving, not a match everyone else has to sit out.
func test_a_match_stops_only_once_every_machine_has_asked_it_to() -> void:
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
	assert_int(host_session.host(port)).is_equal(OK)
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
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).override_failure_message("client never got a slot").is_true()
	# The host asking on its own leaves the client still playing, so the match runs on.
	host_session.want_pause(true)
	await await_millis(200)
	assert_bool(host_session.paused).is_false()
	assert_bool(client_session.paused).is_false()
	# The last one to ask stops it, for both of them.
	client_session.want_pause(true)
	var stopped := await _wait_until(func() -> bool: return client_session.paused, 4000)
	assert_bool(stopped).override_failure_message("the room never stopped").is_true()
	assert_bool(host_session.paused).is_true()
	# One of them going back to the wheel starts it again for everyone.
	client_session.want_pause(false)
	var running := await _wait_until(func() -> bool: return not client_session.paused, 4000)
	assert_bool(running).override_failure_message("the room never started again").is_true()
	assert_bool(host_session.paused).is_false()
	# The host can stop it for everybody without waiting for them, and letting go starts it again.
	host_session.host_controls.force_pause(true)
	var forced := await _wait_until(func() -> bool: return client_session.paused, 4000)
	assert_bool(forced).override_failure_message("the host could not stop the room").is_true()
	host_session.host_controls.force_pause(false)
	var let_go := await _wait_until(func() -> bool: return not client_session.paused, 4000)
	assert_bool(let_go).override_failure_message("the room stayed stopped").is_true()
	# The host is still holding its own answer, so the client asking again is enough on its own.
	client_session.want_pause(true)
	var again := await _wait_until(func() -> bool: return client_session.paused, 4000)
	assert_bool(again).is_true()
	# And a client leaving leaves the host as the whole room, still asking.
	client_session.multiplayer.multiplayer_peer.close()
	var handed_back := await _wait_until(
		func() -> bool: return not host_match.slots[1].is_human(), 4000
	)
	assert_bool(handed_back).is_true()
	assert_bool(host_session.paused).is_true()
	host_session.want_pause(false)
	assert_bool(host_session.paused).is_false()


## A player who is dead is not driving, and for a while that meant not being heard either. The
## controls went out unnumbered while the kart was dead and the host dropped every packet, so a
## client could not pick a joker, walk the cursor along the cards, or press anything at all in
## the one part of the match that is nothing but pressing things.
func test_a_dead_client_is_still_heard() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
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
	client_session.match_node = client_match
	client_session.local_input = PlayerInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).override_failure_message("client never got a slot").is_true()
	var host_input := host_match.slots[1].input as NetInput
	await await_millis(300)
	assert_int(host_input.last_seq).is_greater(0)
	# Killed, which is the state a joker pick happens in.
	host_match.kart_of(1).die(&"test", -1)
	# Waited out rather than slept through: packets already on their way when the kart died are
	# still accepted, and counting those would say the host was listening when it had stopped.
	var knows := await _wait_until(
		func() -> bool: return not client_match.slots[1].kart.alive, 4000
	)
	assert_bool(knows).override_failure_message("the client never saw its kart die").is_true()
	await await_millis(200)
	var heard_dead := host_input.last_seq
	await await_millis(500)
	assert_bool(host_match.kart_of(1).alive).is_false()
	(
		assert_int(host_input.last_seq - heard_dead)
		. override_failure_message(
			(
				"the host heard %d packets in half a second from a client that had died"
				% (host_input.last_seq - heard_dead)
			)
		)
		. is_greater(10)
	)


## GAME.md 8.3: the host going away ends the room, and the notice saying so has the screen to
## itself. A joker pick left open under it would be asking a player to choose a card for a match
## that is not there any more.
func test_the_host_going_away_clears_the_screen() -> void:
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = true
	_client_root.add_child(client_match)
	client_match.start_puppet()
	client_match.set_local_slot(0)
	await await_millis(60)
	var hud := client_match.hud
	assert_bool(hud.visible).is_true()
	assert_bool(hud.dismissed).is_false()
	hud.stand_down()
	assert_bool(hud.dismissed).is_true()
	(
		assert_bool(hud.visible)
		. override_failure_message("the HUD was still on the screen under the notice")
		. is_false()
	)
	# And it stays down: nothing the frame loop or a relayed event does brings it back.
	hud.call("_on_state_changed", Match.State.RESULTS)
	await await_millis(80)
	assert_bool(hud.visible).is_false()


## GAME.md 10.3: the joker pick in front of this player is answered here. Waiting a round trip to
## see the cursor move, and another to see a card taken, is the whole of what made picking a
## joker on a client feel broken.
func test_a_client_works_its_own_joker_pick_at_once() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
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
	client_session.match_node = client_match
	client_session.local_input = PlayerInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).is_true()
	host_match.kart_of(1).die(&"test", -1)
	var offered := await _wait_until(
		func() -> bool:
			return client_match.slots.size() > 1 and client_match.slots[1].offer != null,
		4000
	)
	assert_bool(offered).override_failure_message("the client never saw the pick").is_true()
	var offer: JokerOffer = client_match.slots[1].offer
	assert_int(offer.selected).is_equal(0)
	# Walking the cursor along is answered here rather than a round trip away. Pressed straight
	# into the session's own step, because a real player's controls are read off the keyboard
	# every tick and a flag set from a test is gone again before the tick comes round.
	client_session.local_input.joker_next_pressed = true
	client_session.seats[0]._step_offer(client_match)
	assert_int(offer.selected).override_failure_message("the cursor waited for the host").is_equal(
		1
	)
	# And the snapshot does not walk it back again on its way past.
	await await_millis(300)
	assert_object(client_match.slots[1].offer).is_equal(offer)
	(
		assert_int(offer.selected)
		. override_failure_message("a snapshot put the cursor back where the host had it")
		. is_equal(1)
	)
	# Taken here, the pick stays shut. The snapshots made before the host heard still carry it,
	# and they are not to put the cards back up, nor take the card out of the hand again, nor is
	# the host's word for it heard as a second pick.
	# Host and client share one Events here, so the host's own word is heard too; what must not
	# be is the host's word relayed to the client, which the client heard for itself already.
	var heard := [0]
	var count := func(slot: int, _joker: StringName) -> void:
		if slot == 1 and NetSession._replaying:
			heard[0] += 1
	Events.joker_taken.connect(count)
	var wanted: Joker = offer.choices[1]
	# Picks stand for a moment before they can be answered, so nobody takes one by accident.
	await _wait_until(func() -> bool: return offer.is_settled(), 2000)
	# Taken the way a finger or the mouse takes one: a tap on the card, read with the controls on
	# the next tick, answered here and sent to the host with the rest of them.
	var touch_was := TouchInput.enabled
	TouchInput.enabled = true
	TouchInput.tap(1)
	var answered := await _wait_until(func() -> bool: return offer.is_done(), 2000)
	TouchInput.enabled = touch_was
	assert_bool(answered).override_failure_message("the tap was never answered here").is_true()
	var reopened := [false]
	var dropped := [false]
	for i: int in 40:
		await get_tree().process_frame
		var now: JokerOffer = client_match.slots[1].offer
		if now != null and not now.is_done():
			reopened[0] = true
		if not client_match.slots[1].kart.jokers.ids().has(wanted.id):
			dropped[0] = true
	Events.joker_taken.disconnect(count)
	(
		assert_bool(reopened[0])
		. override_failure_message("a stale snapshot put the pick back")
		. is_false()
	)
	assert_bool(dropped[0]).override_failure_message("the card left the hand again").is_false()
	var confirmed := await _wait_until(
		func() -> bool: return host_match.slots[1].kart.jokers.ids().has(wanted.id), 4000
	)
	assert_bool(confirmed).override_failure_message("the host never took the card").is_true()
	await await_millis(200)
	assert_int(heard[0]).override_failure_message("the pick was heard twice").is_equal(0)


## A kart that has been down a hole and come back is still solid, GAME.md 10.3. Falling takes a
## kart's collisions away, and a client's kart is dead, suspended and brought back between losing
## them and being driven again: whatever it was left holding is not to be trusted. Getting that
## wrong meant driving through walls for the rest of the match.
func test_a_client_kart_is_solid_again_after_coming_back() -> void:
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
	assert_int(host_session.host(port)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client_match
	client_session.local_input = PlayerInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).is_true()
	await await_millis(300)
	var slot := client_session.local_slot
	var kart: Kart = client_match.slots[slot].kart
	var driving := kart.collision_mask
	assert_int(driving).is_not_equal(0)
	# Down a hole here, killed there, which is the order those happen in.
	kart.start_fall()
	assert_int(kart.collision_mask).is_equal(0)
	host_match.kart_of(slot).die(&"pit", -1)
	var died := await _wait_until(func() -> bool: return not kart.alive, 4000)
	assert_bool(died).override_failure_message("the client never saw its kart die").is_true()
	var back := await _wait_until(func() -> bool: return kart.alive, 8000)
	assert_bool(back).override_failure_message("the kart never came back").is_true()
	await await_millis(150)
	(
		assert_int(kart.collision_mask)
		. override_failure_message("came back able to drive through walls")
		. is_equal(driving)
	)
	assert_int(kart.collision_layer).is_equal(Layers.PUPPET)
	assert_bool(kart.falling).is_false()


## Two things a client gets wrong about a kart that has died, both of which a player meets within
## a minute of playing: its own kart has to come back out of the hole it fell down, and somebody
## else's has to stop being in the way the moment it bursts.
func test_a_dead_kart_is_out_of_the_way_and_comes_back_properly() -> void:
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
	assert_int(host_session.host(port)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client_match
	client_session.local_input = PlayerInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).is_true()
	await await_millis(300)
	var mine := client_session.local_slot
	var theirs := 1 - mine
	# Somebody else's kart bursts. The spot it died on has to be drivable at once.
	host_match.kart_of(theirs).die(&"shot", mine)
	var seen := await _wait_until(
		func() -> bool: return not client_match.slots[theirs].kart.alive, 4000
	)
	assert_bool(seen).override_failure_message("the client never saw them die").is_true()
	(
		assert_int(client_match.slots[theirs].kart.collision_layer)
		. override_failure_message("a kart nobody can see was still standing in the way")
		. is_equal(0)
	)
	# And this player's own kart goes down a hole and has to come back out of it.
	var own: Kart = client_match.slots[mine].kart
	var hole: Pit = client_match.arena.pits[0]
	own.global_position = hole.global_position
	own.start_fall()
	host_match.kart_of(mine).global_position = hole.global_position
	host_match.kart_of(mine).die(&"pit", -1)
	var died := await _wait_until(func() -> bool: return not own.alive, 4000)
	assert_bool(died).override_failure_message("the client never saw its own kart die").is_true()
	var back := await _wait_until(func() -> bool: return own.alive, 8000)
	assert_bool(back).override_failure_message("the kart never came back").is_true()
	await await_millis(250)
	assert_bool(own.falling).override_failure_message("it came back still falling").is_false()
	(
		assert_float(own.global_position.distance_to(hole.global_position))
		. override_failure_message("it came back standing in the hole it fell down")
		. is_greater(2.0)
	)
	assert_float(own.global_position.y).is_equal_approx(0.0, 0.2)


## A rematch keeps whoever is at the table, GAME.md 10.3. Starting again from the lobby's list
## handed every remote player's kart to a bot while they went on driving it: each client stayed
## at the wheel of a kart the host had given away.
func test_a_rematch_keeps_the_players_who_are_here() -> void:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.rules = _quick_rules()
	host_match.with_hud = false
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	# One player at this keyboard and one bot, which is the lobby's idea of the match.
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
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
	client_session.match_node = client_match
	client_session.local_input = PlayerInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).is_true()
	var slot := client_session.local_slot
	assert_bool(host_match.slots[slot].input is NetInput).is_true()
	var was := host_match.slots[slot].input
	# The host plays it again.
	host_match.rematch()
	await await_millis(400)
	(
		assert_bool(host_match.slots[slot].input is NetInput)
		. override_failure_message("the rematch handed a connected player's kart to a bot")
		. is_true()
	)
	assert_object(host_match.slots[slot].input).is_equal(was)
	assert_bool(host_match.slots[slot].is_human()).is_true()
	assert_object(host_match.slots[slot].bot_trait).is_null()
	# And the client is still driving it: its controls still reach the host.
	var heard := (host_match.slots[slot].input as NetInput).last_seq
	await await_millis(400)
	(
		assert_int((host_match.slots[slot].input as NetInput).last_seq)
		. override_failure_message("the host stopped hearing the client after a rematch")
		. is_greater(heard)
	)


## The Swivel Cannon on a client, GAME.md 7.1 and 10.3. Free aim points the cannon with the stick
## or the mouse, and a mouse reads nothing that means anything on another machine: the pointer is
## on this screen. A host handed an empty aim asked where its own pointer was and fired the shot
## at that, so a client's swivel shots went anywhere but where it was aiming.
func test_a_client_aims_its_swivel_cannon_itself() -> void:
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
	assert_int(host_session.host(port)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.rules = _quick_rules()
	client_match.with_hud = false
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client_match
	client_session.local_input = PlayerInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var assigned := await _wait_until(func() -> bool: return client_session.local_slot >= 0, 4000)
	assert_bool(assigned).is_true()
	await await_millis(300)
	var slot := client_session.local_slot
	var mine: Kart = client_match.slots[slot].kart
	# The Swivel Cannon is on, which a client knows from the arrow the host sends it.
	mine.aim_arrow_visible = true
	mine.motor.heading = PI * 0.5
	mine.rotation = Vector3(0.0, mine.motor.heading, 0.0)
	assert_float(KartAim.pointed_flat(mine).length()).is_greater(0.5)
	# What goes out is that direction, not the empty stick reading behind it. Read together with
	# the kart's own answer, because the kart is still rolling and the two have to agree now
	# rather than agree with where it was pointing a moment ago.
	await await_millis(300)
	var host_input := host_match.slots[slot].input as NetInput
	host_input.poll(1.0 / 60.0)
	var pointing := KartAim.pointed_flat(mine)
	(
		assert_float(host_input.aim.length())
		. override_failure_message("the host was handed an empty aim and had to guess")
		. is_greater(0.5)
	)
	(
		assert_vector(Vector2(host_input.aim.x, host_input.aim.y))
		. override_failure_message("the host is aiming somewhere the client is not")
		. is_equal_approx(pointing, Vector2.ONE * 0.15)
	)


## GAME.md 10.3: somebody can join to watch. They are let in with no seat, the match goes on as it
## was, they see it in the snapshots, and a room stops without waiting for them.
func test_a_client_can_watch_without_a_kart() -> void:
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
	assert_int(host_session.host(port)).is_equal(OK)
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
	client_session.watching = true
	var let_in := [false]
	client_session.watching_started.connect(func() -> void: let_in[0] = true)
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var watching := await _wait_until(func() -> bool: return let_in[0], 4000)
	assert_bool(watching).override_failure_message("the watcher was never let in").is_true()
	assert_int(client_session.local_slot).is_equal(-1)
	# Nobody lost a kart to them: the bot is still the bot.
	assert_int(host_match.slots.size()).is_equal(2)
	assert_bool(host_match.slots[1].is_human()).is_false()
	var seen := await _wait_until(
		func() -> bool: return client_match.puppet_karts.size() == 2, 4000
	)
	assert_bool(seen).override_failure_message("the watcher never saw the karts").is_true()
	# The host asking is the whole room: somebody watching has nothing to stop.
	host_session.want_pause(true)
	assert_bool(host_session.paused).is_true()
	host_session.want_pause(false)
