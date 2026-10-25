extends GdUnitTestSuite
## The bounty, GAME.md 3.10: a price on the leader's head, who wears it, who collects it and what
## happens when nobody does.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 300.0
	# The base bounty, not the sooner, richer one catch up calls, GAME.md 3.16.
	rules.catch_up = false
	rules.bounty_first_delay = 0.0
	rules.bounty_interval_min = 30.0
	rules.bounty_interval_max = 30.0
	rules.bounty_duration = 1.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 41)
	return match_node


func test_a_clear_leader_gets_a_crown_that_lapses_if_nobody_takes_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	# Nobody is clear of anybody yet, so no bounty is worth calling.
	assert_int(match_node.bounty_slot).is_equal(-1)
	match_node.slots[1].banked = 50
	match_node._bounty_wait = 0.0
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.bounty_slot).is_equal(-1)
	var events := monitor_signals(Events, false)
	match_node.slots[1].banked = 900
	match_node._bounty_wait = 0.0
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.bounty_slot).is_equal(1)
	assert_bool(match_node.kart_of(1).has_bounty()).is_true()
	assert_bool(match_node.kart_of(0).has_bounty()).is_false()
	await assert_signal(events).is_emitted("bounty_called", [1])
	# It runs out on its own and the crown comes off.
	await _runner.simulate_frames(80, 17)
	assert_int(match_node.bounty_slot).is_equal(-1)
	assert_bool(match_node.kart_of(1).has_bounty()).is_false()
	await assert_signal(events).is_emitted("bounty_lapsed", [1])


func test_killing_the_carrier_collects_the_reward() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	match_node.slots[1].banked = 900
	match_node._bounty_wait = 0.0
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.bounty_slot).is_equal(1)
	var events := monitor_signals(Events, false)
	var before := match_node.slots[0].banked
	match_node.kart_of(1).die(&"bullet", 0)
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.slots[0].banked).is_equal(before + match_node.rules.bounty_reward)
	assert_float(match_node.slots[0].stats.value(&"bounties")).is_equal(1.0)
	assert_int(match_node.bounty_slot).is_equal(-1)
	await assert_signal(events).is_emitted("bounty_claimed", [0, 1, match_node.rules.bounty_reward])


func test_a_carrier_who_dies_to_nobody_pays_nothing_out() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	match_node.slots[1].banked = 900
	match_node._bounty_wait = 0.0
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.bounty_slot).is_equal(1)
	var before := match_node.slots[0].banked
	match_node.kart_of(1).die(&"pit", -1)
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.slots[0].banked).is_equal(before)
	assert_int(match_node.bounty_slot).is_equal(-1)


func test_the_crown_reaches_puppets_through_snapshots() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	match_node.slots[1].banked = 900
	match_node._bounty_wait = 0.0
	await _runner.simulate_frames(4, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = match_node.rules
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(match_node.build_snapshot())
	assert_int(client.bounty_slot).is_equal(1)
	assert_bool(client.slots[1].kart.has_bounty()).is_true()
	assert_bool(client.slots[0].kart.has_bounty()).is_false()
