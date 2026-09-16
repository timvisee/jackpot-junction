extends GdUnitTestSuite
## The joker system from GAME.md 3.7 and the twenty jokers from 7.3, in a running match.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


## Offers are off by default so deaths do not hand out random jokers; offer tests turn them on.
func _start_match(inputs: Array[KartInput], offer_size: int = 0, seed: int = 21) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.respawn_delay = 0.2
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = offer_size
	_runner = scene_runner(match_node)
	match_node.start(inputs, seed)
	return match_node


func _bots() -> Array[KartInput]:
	return [KartInput.new(), KartInput.new()]


func _attach(kart: Kart, id: String) -> Joker:
	return kart.jokers.add(load("res://data/jokers/%s.tres" % id))


func _chip(dropped := false, gold := false) -> Chip:
	var chip := Chip.new()
	chip.dropped = dropped
	chip.gold = gold
	chip.value = 5 if gold else 1
	return auto_free(chip)


func test_catalog_has_twenty_unique_jokers_and_offers_exclude_held_ones() -> void:
	var catalog: JokerCatalog = load("res://data/jokers/catalog.tres")
	assert_int(catalog.jokers.size()).is_equal(20)
	var ids: Array[StringName] = []
	for joker: Joker in catalog.jokers:
		(
			assert_bool(joker.id in ids)
			. override_failure_message("duplicate id %s" % joker.id)
			. is_false()
		)
		ids.append(joker.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var exclude: Array[StringName] = [&"hair_trigger", &"big_tank"]
	var offered := catalog.offer(rng, 3, exclude)
	assert_int(offered.size()).is_equal(3)
	for joker: Joker in offered:
		assert_bool(joker.id in exclude).is_false()
	assert_bool(offered[0] == offered[1] or offered[1] == offered[2]).is_false()


func test_stat_jokers_rebuild_the_karts_own_stats_and_removal_restores_them() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var trigger := _attach(kart, "hair_trigger")
	_attach(kart, "big_tank")
	_attach(kart, "rubber_bumpers")
	_attach(kart, "nitro_habit")
	_attach(kart, "magnet_hubcaps")
	assert_float(kart.cannon.stats.fire_cooldown).is_equal_approx(0.28, 0.001)
	assert_int(kart.cannon.stats.max_live_bullets).is_equal(4)
	assert_int(kart.cannon.stats.bounces).is_equal(2)
	assert_float(kart.stats.drift_exit_boost_duration).is_equal_approx(1.6, 0.001)
	assert_float(kart.stats.turbo_duration).is_equal_approx(2.0, 0.001)
	assert_float(kart._pickup_shape.radius).is_equal_approx(1.8, 0.001)
	assert_float(kart.base_stats.turbo_duration).is_equal_approx(1.0, 0.001)
	kart.jokers.remove(trigger)
	assert_float(kart.cannon.stats.fire_cooldown).is_equal_approx(0.4, 0.001)
	assert_int(kart.jokers.count()).is_equal(4)


func test_road_rage_slows_the_kart_and_rams_at_speed() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "road_rage")
	var expected := kart.base_stats.top_speed * 0.9
	assert_float(kart.stats.top_speed).is_equal_approx(expected, 0.001)
	assert_bool(kart.ram_kills()).is_false()
	kart.motor.velocity = kart.motor.forward_vector() * expected * 0.95
	assert_bool(kart.ram_kills()).is_true()


func test_graze_jokers() -> void:
	var match_node := _start_match(_bots())
	var slip := match_node.kart_of(0)
	var snake := match_node.kart_of(1)
	_attach(slip, "slipstream")
	_attach(snake, "snake_eyes")
	slip.graze(1)
	snake.graze(0)
	assert_float(slip.pot.mult).is_equal(2.0)
	assert_float(snake.pot.mult).is_equal(1.0)


func test_high_roller_doubles_mult_gains_and_banks_nothing_on_death() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "high_roller")
	kart.gain_mult(1.0, &"kill")
	assert_float(kart.pot.mult).is_equal(3.0)
	kart.pot.add_coins(10)
	kart.die(&"pit", -1)
	assert_int(match_node.slots[0].banked).is_equal(0)


func test_insurance_policy_banks_everything_on_death() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "insurance_policy")
	kart.pot.add_coins(10)
	kart.pot.add_mult(1.0)
	kart.die(&"pit", -1)
	assert_int(match_node.slots[0].banked).is_equal(20)


func test_coin_value_jokers() -> void:
	var match_node := _start_match(_bots())
	var vulture := match_node.kart_of(0)
	var dice := match_node.kart_of(1)
	_attach(vulture, "vulture")
	_attach(dice, "loaded_dice")
	vulture.collect_coins(1, _chip(true))
	vulture.collect_coins(1, _chip(false))
	assert_int(vulture.pot.coins).is_equal(3)
	for i: int in 300:
		dice.collect_coins(1, _chip())
	assert_int(dice.pot.coins).is_between(330, 520)


func test_lucky_seven_gives_a_mult_every_seventh_chip() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "lucky_seven")
	for i: int in 14:
		kart.collect_coins(1, _chip())
	assert_float(kart.pot.mult).is_equal(3.0)


func test_green_light_rewards_turbo_pads() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "green_light")
	await _runner.simulate_frames(12, 17)
	kart.apply_turbo(Vector3(0.0, 0.0, 1.0))
	assert_float(kart.pot.mult).is_equal(1.5)


func test_pickpocket_steals_half_the_victims_coins_and_the_victim_drops_none() -> void:
	var match_node := _start_match(_bots())
	var killer := match_node.kart_of(1)
	var victim := match_node.kart_of(0)
	_attach(killer, "pickpocket")
	victim.pot.add_coins(10)
	var pickups_before := match_node.arena.pickups.get_child_count()
	victim.die(&"bullet", 1)
	assert_int(killer.pot.coins).is_equal(5)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(pickups_before)


func test_glass_jackpot_pays_more_and_dies_hard() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "glass_jackpot")
	_attach(kart, "hair_trigger")
	_attach(kart, "big_tank")
	await _runner.simulate_frames(12, 17)
	kart.pot.add_coins(20)
	kart.pot.add_mult(1.0)
	kart.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(110, 17)
	assert_int(match_node.slots[0].banked).is_equal(60)
	kart.pot.add_coins(10)
	var pickups_before := match_node.arena.pickups.get_child_count()
	kart.die(&"pit", -1)
	assert_int(kart.jokers.count()).is_equal(1)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(pickups_before + 12)


func test_getaway_driver_banks_faster_and_toll_booth_skims_others() -> void:
	var match_node := _start_match(_bots())
	var driver := match_node.kart_of(0)
	var booth := match_node.kart_of(1)
	_attach(driver, "getaway_driver")
	_attach(booth, "toll_booth")
	assert_float(driver.bank_doubling()).is_equal_approx(0.25, 0.001)
	await _runner.simulate_frames(12, 17)
	driver.pot.add_coins(20)
	driver.pot.add_mult(1.0)
	driver.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(60, 17)
	assert_int(match_node.slots[0].banked).is_equal(40)
	assert_int(match_node.slots[1].banked).is_equal(2)


func test_comeback_and_snake_eyes_set_the_mult_on_respawn() -> void:
	var match_node := _start_match(_bots())
	var comeback := match_node.kart_of(0)
	var snake := match_node.kart_of(1)
	_attach(comeback, "comeback")
	_attach(snake, "snake_eyes")
	await _runner.simulate_frames(12, 17)
	comeback.pot.add_mult(3.0)
	comeback.die(&"pit", -1)
	snake.die(&"pit", -1)
	await _runner.simulate_frames(30, 17)
	assert_bool(comeback.alive).is_true()
	assert_float(comeback.pot.mult).is_equal(2.0)
	assert_float(snake.pot.mult).is_equal(3.0)


func test_a_human_gets_an_offer_on_death_and_respawn_waits_for_the_choice() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), KartInput.new()]
	var match_node := _start_match(inputs, 3)
	var kart := match_node.kart_of(0)
	_attach(kart, "hair_trigger")
	await _runner.simulate_frames(12, 17)
	kart.die(&"pit", -1)
	var slot := match_node.slots[0]
	assert_object(slot.offer).is_not_null()
	assert_int(slot.offer.choices.size()).is_equal(3)
	for joker: Joker in slot.offer.choices:
		assert_bool(joker.id == &"hair_trigger").is_false()
	await _runner.simulate_frames(30, 17)
	assert_bool(kart.alive).is_false()
	slot.offer.take(1)
	var picked := slot.offer.chosen.id
	assert_bool(slot.offer.is_done()).is_true()
	assert_bool(kart.jokers.has(picked)).is_true()
	await _runner.simulate_frames(6, 17)
	assert_bool(kart.alive).is_true()


func test_a_full_hand_must_destroy_a_joker_to_take_a_new_one_and_may_skip() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), KartInput.new()]
	var match_node := _start_match(inputs, 3)
	var kart := match_node.kart_of(0)
	for id: String in ["hair_trigger", "big_tank", "rubber_bumpers", "nitro_habit", "vulture"]:
		_attach(kart, id)
	await _runner.simulate_frames(12, 17)
	kart.die(&"pit", -1)
	var offer := match_node.slots[0].offer
	offer.take(0)
	assert_int(offer.stage).is_equal(JokerOffer.Stage.REPLACING)
	offer.cancel_replace()
	assert_int(offer.stage).is_equal(JokerOffer.Stage.CHOOSING)
	offer.take(0)
	offer.replace(1)
	assert_bool(offer.is_done()).is_true()
	assert_int(kart.jokers.count()).is_equal(5)
	assert_bool(kart.jokers.has(&"big_tank")).is_false()
	assert_bool(kart.jokers.has(offer.chosen.id)).is_true()
	await _runner.simulate_frames(30, 17)
	kart.die(&"pit", -1)
	var second := match_node.slots[0].offer
	second.skip()
	assert_bool(second.is_done()).is_true()
	assert_int(kart.jokers.count()).is_equal(5)


func test_wild_card_offers_five_and_bots_always_take_one() -> void:
	var match_node := _start_match(_bots(), 3)
	var kart := match_node.kart_of(0)
	_attach(kart, "wild_card")
	assert_int(kart.offer_count(3)).is_equal(5)
	await _runner.simulate_frames(12, 17)
	kart.die(&"pit", -1)
	var offer := match_node.slots[0].offer
	assert_int(offer.choices.size()).is_equal(5)
	assert_bool(offer.is_done()).is_true()
	assert_int(kart.jokers.count()).is_equal(2)


func test_dropped_jokers_land_on_the_floor_and_can_be_picked_up() -> void:
	var match_node := _start_match(_bots())
	var rules := match_node.rules
	rules.death_joker_drop_chance = 1.0
	var kart := match_node.kart_of(0)
	var other := match_node.kart_of(1)
	_attach(kart, "hair_trigger")
	await _runner.simulate_frames(12, 17)
	kart.global_position = Vector3(-4.5, 0.0, 1.0)
	kart.die(&"pit", -1)
	var cards: Array[FloorJoker] = []
	for child: Node in match_node.arena.pickups.get_children():
		if child is FloorJoker:
			cards.append(child)
	assert_int(cards.size()).is_equal(1)
	assert_bool(kart.jokers.has(&"hair_trigger")).is_false()
	other.global_position = cards[0].global_position
	await _runner.simulate_frames(10, 17)
	assert_bool(other.jokers.has(&"hair_trigger")).is_true()
	other.drop_joker(0)
	assert_int(other.jokers.count()).is_equal(0)
	var dropped := 0
	for child: Node in match_node.arena.pickups.get_children():
		if child is FloorJoker:
			dropped += 1
	assert_int(dropped).is_equal(1)
