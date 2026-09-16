extends GdUnitTestSuite
## The economy in a running match: banking at the Junction, the death sequence, the Jackpot, coin
## pads and the match flow from countdown to results. Uses shortened rules to keep it quick.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _quick_rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
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
	# Not stopped dead: let go of, and out of play while it rolls out.
	assert_bool(match_node.kart_of(0).frozen).is_false()
	assert_bool(match_node.kart_of(0).coasting).is_true()
	assert_bool(match_node.kart_of(0).is_active()).is_false()


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


## The bob used to overwrite the hover height, so chips and dice sat half inside the floor.
func test_pickups_hover_clear_of_the_floor_while_they_bob() -> void:
	var root: Node3D = auto_free(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(root)
	var chip := Chip.new()
	var die := MultDie.new()
	var box := ItemBox.new()
	for pickup: Pickup in [chip, die, box]:
		root.add_child(pickup)
	await runner.simulate_frames(4, 17)
	for pickup: Pickup in [chip, die, box]:
		var height: float = (pickup.get_node("Visual") as Node3D).position.y
		(
			assert_float(height)
			. override_failure_message("%s sits at %.2f" % [pickup.get_class(), height])
			. is_greater(Pickup.BOB_HEIGHT)
		)
	assert_float((chip.get_node("Visual") as Node3D).position.y).is_between(0.3, 0.5)


## GAME.md 3.4: the Junction ring blinks at a local player carrying a lot of unbanked value.
func test_the_junction_blinks_when_a_local_player_carries_a_fortune() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var rules := _quick_rules()
	rules.duration = 60.0
	var match_node := _start_match(inputs, rules)
	await _runner.simulate_frames(20, 17)
	var junction := match_node.arena.junction
	assert_float(match_node.junction_hint()).is_equal(0.0)
	assert_float(junction.ring_material.emission_energy_multiplier).is_equal(0.0)
	# A bot hoarding coins is nobody's business: only players on this screen make it blink.
	match_node.kart_of(1).pot.add_coins(2000)
	await _runner.simulate_frames(4, 17)
	assert_float(junction.hint).is_equal(0.0)
	var kart := match_node.kart_of(0)
	kart.pot.add_coins(int(rules.junction_hint_start) + 10)
	await _runner.simulate_frames(4, 17)
	assert_float(junction.hint).is_between(0.001, 0.2)
	kart.pot.add_coins(3000)
	await _runner.simulate_frames(4, 17)
	assert_float(junction.hint).is_equal(1.0)
	var lit := junction.ring_material.emission_energy_multiplier
	var changed := false
	for i: int in 12:
		await _runner.simulate_frames(2, 17)
		changed = changed or absf(junction.ring_material.emission_energy_multiplier - lit) > 0.05
	assert_bool(changed).override_failure_message("the ring never pulsed").is_true()


## GAME.md 3.6: a wreck scatters its chips well clear of the spot, and anything that lands over
## a hole drops into it instead of sitting there.
func test_drops_scatter_wide_and_anything_over_a_pit_falls_in() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, _quick_rules())
	await _runner.simulate_frames(20, 17)
	var arena := match_node.arena
	var centre := Vector3(0.0, 0.0, 6.0)
	var chips := arena.spawn_chips(centre, 12, 0.0, 0.0, true)
	var furthest := 0.0
	for chip: Chip in chips:
		furthest = maxf(furthest, chip.global_position.distance_to(centre))
	assert_float(furthest).is_greater(2.0)
	# The hole in the floor swallows whatever lands on it.
	var pit := arena.pits[0].global_position
	assert_bool(arena.is_over_pit(pit)).is_true()
	assert_bool(arena.is_over_pit(centre)).is_false()
	var doomed := ItemBox.new()
	doomed.fixed_item = load("res://data/powerups/boost.tres")
	arena.place_drop(doomed, pit)
	assert_bool(doomed.falling).is_true()
	assert_bool(doomed.can_collect(match_node.kart_of(0))).is_false()
	var height := doomed.position.y
	await _runner.simulate_frames(6, 17)
	assert_float(doomed.position.y).is_less(height)
	await _runner.simulate_frames(60, 17)
	assert_bool(is_instance_valid(doomed)).is_false()


func test_coin_pads_spawn_pickups_that_karts_collect() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	var pads := match_node.arena.coin_pads.size() + match_node.arena.power_pads.size()
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(pads)
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
	match_node.bullets.spawn(0, Vector3(0.9, 0.0, 9.5), Vector3(0.0, 0.0, -1.0), stats, Color.WHITE)
	await runner.simulate_frames(40, 17)
	assert_bool(target.alive).is_true()
	assert_float(target.pot.mult).is_equal(1.5)
