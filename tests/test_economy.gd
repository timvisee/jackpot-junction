extends GdUnitTestSuite
## The economy in a running match: banking at the Junction, the death sequence, the Jackpot, coin
## pads and the match flow from countdown to results. Uses shortened rules to keep it quick.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _quick_rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 4.0
	rules.last_call_duration = 1.5
	return rules


func _start_match(inputs: Array[KartInput], rules: MatchRules) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	match_node.start(inputs, 11)
	return match_node


func test_countdown_then_play_then_last_call_then_results() -> void:
	var rules := _quick_rules()
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	assert_int(match_node.state).is_equal(Match.State.COUNTDOWN)
	assert_bool(match_node.kart_of(0).frozen).is_true()
	var runner := _runner
	await runner.simulate_frames(20, 17)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	assert_bool(match_node.kart_of(0).frozen).is_false()
	await runner.simulate_frames(170, 17)
	assert_int(match_node.state).is_equal(Match.State.LAST_CALL)
	assert_float(match_node.arena.junction.payout_multiplier).is_equal(rules.last_call_payout)
	await runner.simulate_frames(110, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_bool(match_node.kart_of(0).frozen).is_true()


func test_standing_on_the_junction_banks_the_pot_and_resets_it() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	await runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.pot.add_coins(20)
	kart.pot.add_mult(1.0)
	kart.global_position = match_node.arena.junction_position
	var events := monitor_signals(Events, false)
	await runner.simulate_frames(110, 17)
	assert_int(match_node.slots[0].banked).is_equal(40)
	assert_bool(kart.pot.is_empty()).is_true()
	assert_float(kart.pot.mult).is_equal(1.0)
	await assert_signal(events).is_emitted("bank_completed", [0, 20, 2.0, 40])


func test_the_death_sequence_banks_half_drops_chips_and_credits_the_killer() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	await runner.simulate_frames(12, 17)
	var victim := match_node.kart_of(0)
	var killer := match_node.kart_of(1)
	victim.pot.add_coins(10)
	victim.pot.add_mult(1.0)
	victim.global_position = Vector3(5.0, 0.0, 5.0)
	var pickups_before := match_node.arena.pickups.get_child_count()
	victim.die(&"bullet", 1)
	assert_int(match_node.slots[0].banked).is_equal(10)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(pickups_before + 3)
	assert_float(killer.pot.mult).is_equal(2.0)
	assert_int(match_node.slots[1].kills).is_equal(1)
	assert_int(match_node.slots[0].deaths).is_equal(1)
	assert_bool(victim.pot.is_empty()).is_true()
	assert_float(victim.pot.mult).is_equal(1.0)


func test_a_lone_kart_in_the_active_jackpot_collects_it_and_the_other_zone_takes_over() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	await runner.simulate_frames(12, 17)
	var active: JackpotZone = null
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		if zone.active:
			active = zone
	assert_object(active).is_not_null()
	rules.jackpot_accrual = 0.0
	active.chips = 30.0
	var kart := match_node.kart_of(0)
	kart.global_position = active.global_position
	await runner.simulate_frames(200, 17)
	assert_int(kart.pot.coins).is_equal(30)
	assert_bool(active.active).is_false()
	var other := match_node.arena.jackpot_zones[(active.index + 1) % 2]
	assert_bool(other.active).is_true()


func test_coin_pads_spawn_pickups_that_karts_collect() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(
		match_node.arena.coin_pads.size()
	)
	var pad := match_node.arena.coin_pads[0]
	var expected_coins := 0
	var chip := pad.current as Chip
	if chip != null:
		expected_coins = chip.value
	var kart := match_node.kart_of(0)
	kart.global_position = pad.global_position
	await runner.simulate_frames(20, 17)
	assert_object(pad.current).is_null()
	if expected_coins > 0:
		assert_int(kart.pot.coins).is_equal(expected_coins)
	else:
		assert_float(kart.pot.mult).is_equal(2.0)


func test_a_near_miss_grazes_for_half_a_mult() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	await runner.simulate_frames(12, 17)
	var target := match_node.kart_of(1)
	target.global_position = Vector3(0.0, 0.0, 6.0)
	target.face(Vector3(0.0, 0.0, -1.0))
	var stats: CannonStats = load("res://data/cannons/default.tres").duplicate()
	stats.aim_assist = false
	match_node.bullets.spawn(
		0, Vector3(0.9, 0.0, 9.5), Vector3(0.0, 0.0, -1.0), stats, Color.WHITE
	)
	await runner.simulate_frames(40, 17)
	assert_bool(target.alive).is_true()
	assert_float(target.pot.mult).is_equal(1.5)
