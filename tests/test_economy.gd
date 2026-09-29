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
	# The clock running out with a field still driving is sudden death, GAME.md 3.13, and the
	# whistle goes when one of them is left.
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	match_node.kart_of(1).die(&"test", -1)
	await runner.simulate_frames(4, 17)
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


## GAME.md 3.6: a death says how its pot split, what banked and what went, for every screen to show
## going where it went; a pot that banks nothing still says what it lost.
func test_a_death_says_what_its_pot_banked_and_lost() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	await _runner.simulate_frames(12, 17)
	var said: Array = []
	var hear := func(slot: int, banked: int, lost: int) -> void: said.append([slot, banked, lost])
	Events.death_banked.connect(hear)
	var victim := match_node.kart_of(0)
	victim.pot.add_coins(20)
	victim.pot.add_mult(1.0)
	victim.die(&"pit", -1)
	var gambler := match_node.kart_of(1)
	gambler.jokers.add(load("res://data/jokers/high_roller.tres"))
	gambler.pot.add_coins(10)
	gambler.die(&"pit", -1)
	Events.death_banked.disconnect(hear)
	assert_array(said).is_equal([[0, 20, 20], [1, 0, 10]])


## GAME.md 8.1: the chip count is a marking on the floor of the zone, so a kart parked on it is
## in front of it. It is painted the way a Royal Flush pad wears its letter, and neither is drawn
## through whatever is standing on it.
func test_the_jackpot_count_is_painted_on_the_floor_rather_than_over_everything() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	await _runner.simulate_frames(12, 17)
	var zone: JackpotZone = match_node.arena.jackpot_zones[0]
	var pad: FlushPad = match_node.arena.flush_pads[0]
	assert_bool(zone._label.no_depth_test).is_equal(pad._label.no_depth_test)
	assert_bool(zone._label.no_depth_test).is_false()
	# And it clears the trim of the tile it is painted on, or nobody would see it at all.
	assert_float(zone._label.position.y).is_greater(Arena.PAD_HEIGHT * 1.6)


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


## GAME.md 3.5: the counter is painted on the tile the collector is parked on, so the kart
## wears the ring instead, full when it arrives and gone when the pile is. A pile that has gone
## throws a handful of gold up off the tile, on every screen.
func test_collecting_the_jackpot_puts_a_ring_on_the_kart_and_pops_when_it_is_clear() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	rules.jackpot_accrual = 0.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	await runner.simulate_frames(12, 17)
	var active: JackpotZone = null
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		if zone.active:
			active = zone
	active.chips = 40.0
	var kart := match_node.kart_of(0)
	assert_float(kart.channel_progress).is_equal(-1.0)
	kart.global_position = active.global_position
	await runner.simulate_frames(6, 17)
	# Part way through: the ring is on and coming down with the pile.
	assert_float(kart.channel_progress).is_between(0.05, 0.999)
	var ring := kart.channel_progress
	await runner.simulate_frames(6, 17)
	assert_float(kart.channel_progress).is_less(ring)
	await runner.simulate_frames(120, 17)
	# The pile has gone: no ring left to wear, and gold thrown up off the tile.
	assert_float(active.chips).is_equal(0.0)
	assert_float(kart.channel_progress).is_equal(-1.0)
	assert_int(match_node.arena.get_tree().get_nodes_in_group(&"bursts").size()).is_greater(0)


## A second kart driving in pauses the channel, and a ring that is not moving is a lie.
func test_a_contested_jackpot_takes_the_ring_off() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	rules.jackpot_accrual = 0.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	await runner.simulate_frames(12, 17)
	var active: JackpotZone = null
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		if zone.active:
			active = zone
	active.chips = 40.0
	var kart := match_node.kart_of(0)
	kart.global_position = active.global_position
	await runner.simulate_frames(6, 17)
	assert_float(kart.channel_progress).is_greater(0.0)
	match_node.kart_of(1).global_position = active.global_position + Vector3(0.6, 0.0, 0.6)
	await runner.simulate_frames(6, 17)
	assert_float(kart.channel_progress).is_equal(-1.0)


## GAME.md 7.2: a decoy cannot collect the Jackpot and does not count as somebody standing in
## it. Parked on the pile it used to hand the whole thing to its owner from across the arena,
## and block anybody who actually drove there while it did.
func test_a_decoy_neither_collects_the_jackpot_nor_blocks_it() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	rules.jackpot_accrual = 0.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	var runner := _runner
	await runner.simulate_frames(12, 17)
	var active: JackpotZone = null
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		if zone.active:
			active = zone
	active.chips = 30.0
	var owner := match_node.kart_of(0)
	var decoy := match_node.kart_of(1)
	decoy.decoy_owner = owner
	decoy.global_position = active.global_position
	await runner.simulate_frames(60, 17)
	assert_float(active.chips).is_equal(30.0)
	assert_int(owner.pot.coins).is_equal(0)
	# And it is not in anybody's way either: as far as the zone is concerned the tile is empty,
	# so whoever does drive there collects rather than finding the channel paused by a prop.
	assert_int(active.occupant_count()).is_equal(0)


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


## A box taken hands its look to the flight into the kart, GAME.md 8.3, and is freed at the end of
## the frame; its pulse reached for the look that had gone, an error in every match. And a box
## going down a hole kept its full size, the pulse writing over the shrink.
func test_an_item_box_pulses_only_a_look_it_still_has() -> void:
	var root: Node3D = auto_free(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(root)
	var box := ItemBox.new()
	root.add_child(box)
	await runner.simulate_frames(2, 17)
	box.fall_into_pit()
	await runner.simulate_frames(12, 17)
	var visual: Node3D = box.get_node("Visual")
	assert_float(visual.scale.x).is_less(0.9)
	# Taken: the look is gone, and the frame the box has left passes quietly.
	var taken := ItemBox.new()
	root.add_child(taken)
	await runner.simulate_frames(2, 17)
	taken.detach_visual().free()
	await runner.simulate_frames(2, 17)
	assert_object(taken.get_node_or_null("Visual")).is_null()


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
	var center := Vector3(0.0, 0.0, 8.0)
	var chips := arena.spawn_chips(center, 12, 0.0, 0.0, true)
	var furthest := 0.0
	for chip: Chip in chips:
		furthest = maxf(furthest, chip.global_position.distance_to(center))
	assert_float(furthest).is_greater(2.0)
	# The hole in the floor swallows whatever lands on it.
	var pit := arena.pits[0].global_position
	assert_bool(arena.is_over_pit(pit)).is_true()
	assert_bool(arena.is_over_pit(center)).is_false()
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
	target.global_position = Vector3(0.0, 0.0, -3.0)
	target.face(Vector3(0.0, 0.0, 1.0))
	var stats: CannonStats = load("res://data/cannons/default.tres").duplicate()
	stats.aim_assist = false
	match_node.bullets.spawn(0, Vector3(0.9, 0.0, -6.5), Vector3(0.0, 0.0, 1.0), stats, Color.WHITE)
	await runner.simulate_frames(40, 17)
	assert_bool(target.alive).is_true()
	assert_float(target.pot.mult).is_equal(1.5)


## GAME.md 8.3: what a kart drops on the way out is thrown clear of it rather than appearing on
## the floor, the mirror of the way a pickup is drawn into a kart that takes one.
func test_dropped_chips_are_thrown_clear_of_the_kart() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.global_position = match_node.arena.junction_position + Vector3(8.0, 0.0, 0.0)
	var chips := match_node.arena.spawn_chips(kart.global_position, 5, 15.0, 0.0, true)
	assert_int(chips.size()).is_equal(5)
	await _runner.simulate_frames(1, 17)
	# Straight away each one is still up by the kart rather than down where it will lie.
	for chip: Chip in chips:
		var lying := chip.global_position + Vector3(0.0, chip.hover, 0.0)
		assert_float(chip.visual_center().distance_to(kart.global_position)).is_less(
			lying.distance_to(kart.global_position)
		)
	# And once it has landed it sits on its own spot and bobs there like any other.
	await _runner.simulate_frames(int(Pickup.THROW_TIME * 60.0) + 20, 17)
	for chip: Chip in chips:
		assert_float(chip.visual_center().distance_to(chip.global_position)).is_less(1.0)


## A pickup put down rather than dropped is simply there: the coin pads do not throw anything.
func test_a_pad_pickup_is_placed_rather_than_thrown() -> void:
	var rules := _quick_rules()
	rules.duration = 60.0
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, rules)
	await _runner.simulate_frames(12, 17)
	var pad := match_node.arena.coin_pads[0]
	assert_object(pad.current).is_not_null()
	assert_float(pad.current._thrown_left).is_equal(0.0)
