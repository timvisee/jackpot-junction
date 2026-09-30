extends GdUnitTestSuite
## Jokers that stack, GAME.md 7.3: offered and picked up again up to their most, the whole stack
## applied once rather than one copy's numbers multiplied by another's, and the card saying what
## the stack does, the numbers it has changed in gold, GAME.md 8.3.

const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## A mark that shows where a stacked number went, for asking of the words without the colors.
const MARK := "<%s>"

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 21)
	return match_node


func _joker(id: String) -> Joker:
	return load("res://data/jokers/%s.tres" % id)


func _attach(kart: Kart, id: String, copies := 1) -> Joker:
	var first: Joker = null
	for i: int in copies:
		var added := kart.jokers.add(_joker(id))
		first = added if first == null else first
	return first


## Every card fills in its numbers. One that stacks says how far, and a stack of it says more
## than one copy does, every number it changed marked; one copy's marks nothing.
func test_every_card_fills_in_its_numbers_and_a_stack_marks_what_it_changed() -> void:
	for joker: Joker in CATALOG.jokers:
		var one := joker.describe(1, MARK)
		assert_bool("{" in one or "}" in one).override_failure_message(joker.id).is_false()
		assert_bool("<" in one).override_failure_message("%s marks one copy" % joker.id).is_false()
		if not joker.stackable:
			assert_str(joker.describe(3, MARK)).is_equal(one)
			continue
		assert_int(joker.most).override_failure_message("%s stacks forever" % joker.id).is_greater(
			1
		)
		assert_str(one).override_failure_message(joker.id).ends_with(
			"Stacks up to ×%d." % joker.most
		)
		var most := joker.describe(joker.most, MARK)
		assert_bool("<" in most).override_failure_message("%s says one copy" % joker.id).is_true()
		# Past its most, the card says its most: that is all a stack does.
		assert_str(joker.describe(joker.most + 1, MARK)).is_equal(most)


func test_the_numbers_a_stack_says() -> void:
	assert_str(_joker("vulture").describe(2, MARK)).starts_with(
		"Chips dropped by other karts are worth <4 coins> to you."
	)
	assert_str(_joker("payday").describe(1, MARK)).starts_with("+1 coin every second")
	assert_str(_joker("payday").describe(3, MARK)).starts_with("+<3 coins> every second")
	assert_str(_joker("hair_trigger").describe(2, MARK)).starts_with("Fire cooldown <-46%>.")
	assert_str(_joker("curve_ball").describe(3, MARK)).contains("up to <300°> a second")
	assert_str(_joker("toll_booth").describe(3, MARK)).contains("you bank <35%> of it")
	assert_str(_joker("magnet_hubcaps").describe(2, MARK)).starts_with("Pickup radius times <2.8>.")
	assert_str(_joker("spare_tire").describe(2, MARK)).starts_with("<Two more lives>. Lost")
	assert_str(_joker("wild_card").describe(2, MARK)).starts_with("Respawn offers <7> jokers")


## A stack is offered again until it is at its most, and a joker that does not stack never is.
func test_a_stack_is_offered_again_up_to_its_most() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var held: Array[StringName] = [&"vulture", &"vulture", &"pickpocket", &"wild_card"]
	var offered := CATALOG.offer(rng, CATALOG.jokers.size(), held)
	var ids: Array[StringName] = []
	for joker: Joker in offered:
		ids.append(joker.id)
	assert_bool(&"vulture" in ids).is_true()
	assert_bool(&"wild_card" in ids).is_true()
	assert_bool(&"pickpocket" in ids).is_false()
	held.append_array([&"vulture", &"wild_card"])
	offered = CATALOG.offer(rng, CATALOG.jokers.size(), held)
	ids.clear()
	for joker: Joker in offered:
		ids.append(joker.id)
	assert_bool(&"vulture" in ids).override_failure_message("three Vultures and more").is_false()
	assert_bool(&"wild_card" in ids).override_failure_message("two Wild Cards and more").is_false()


## A card on the floor that the hand already holds is left there for somebody else, unless it
## stacks and the stack has room for it.
func test_a_floor_joker_already_held_is_left_unless_it_stacks() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(10, 17)
	var kart := match_node.kart_of(0)
	var lying := match_node.arena.spawn_floor_joker(Vector3.ZERO, _joker("pickpocket"), 15.0)
	assert_bool(lying.can_collect(kart)).is_true()
	_attach(kart, "pickpocket")
	assert_bool(lying.can_collect(kart)).is_false()
	assert_bool(lying.can_collect(match_node.kart_of(1))).is_true()
	var tires := match_node.arena.spawn_floor_joker(Vector3.ZERO, _joker("spare_tire"), 15.0)
	_attach(kart, "spare_tire")
	assert_bool(tires.can_collect(kart)).is_true()
	_attach(kart, "spare_tire")
	assert_bool(tires.can_collect(kart)).is_false()


## The first copy applies the whole stack and the others nothing, so a stack's numbers are the
## card's: three Curve Balls turn a bullet 300°/s, and a fourth, however it got there, no more.
func test_the_first_copy_applies_the_whole_stack() -> void:
	var match_node := _start_match()
	var kart := match_node.kart_of(0)
	var chip := Chip.new()
	chip.dropped = true
	chip.value = 1
	var worth := func() -> int:
		var value := 1
		for joker: Joker in kart.jokers.jokers:
			value = joker.modify_coin_value(kart, chip, value)
		return value
	var first := _attach(kart, "vulture", 2)
	assert_int(worth.call()).is_equal(4)
	# The first gone, the next is first and the stack is one.
	kart.jokers.remove(first)
	assert_bool(kart.jokers.jokers[0].leads).is_true()
	assert_int(worth.call()).is_equal(3)
	chip.free()
	var cooldown := kart.cannon_stats.fire_cooldown
	_attach(kart, "hair_trigger", 2)
	assert_float(kart.cannon_stats.fire_cooldown).is_equal_approx(cooldown * 7.0 / 13.0, 0.0001)
	var reach := kart.pickup_reach()
	_attach(kart, "magnet_hubcaps", 3)
	assert_float(kart.pickup_reach()).is_equal_approx(reach * 4.0, 0.001)
	_attach(kart, "curve_ball", 4)
	assert_float(kart.cannon_stats.aim_assist_turn_rate_deg).is_equal(300.0)
	var coins := kart.pot.coins
	_attach(kart, "payday", 2)
	for joker: Joker in kart.jokers.jokers:
		joker.on_step(kart, 1.0)
	assert_int(kart.pot.coins - coins).is_equal(2)


## Copies that simply add up still do: two Big Tanks are four bullets more, two Spare Tires two
## lives more, and one death takes both tires.
func test_copies_that_add_up_still_do() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(10, 17)
	var kart := match_node.kart_of(0)
	var bullets := kart.cannon_stats.max_live_bullets
	_attach(kart, "big_tank", 2)
	assert_int(kart.cannon_stats.max_live_bullets).is_equal(bullets + 4)
	var lives := kart.lives
	_attach(kart, "spare_tire", 2)
	assert_int(kart.lives).is_equal(lives + 2)
	assert_int(KartLives.most(kart)).is_equal(match_node.rules.lives + 2)
	match_node.rules.death_joker_drop_chance = 0.0
	kart.die(&"pit", -1)
	assert_bool(kart.jokers.has(&"spare_tire")).is_false()


## A client hears its hand from the host by name, GAME.md 10.3, and holds copies of its own, so
## two karts with the same stack each count their own; the same hand again makes nothing anew.
func test_a_client_holds_copies_of_its_own() -> void:
	var match_node := _start_match()
	var one := match_node.kart_of(0)
	var two := match_node.kart_of(1)
	var vulture := _joker("vulture")
	var dealt: Array[Joker] = [vulture, vulture]
	one.jokers.deal(dealt)
	two.jokers.deal([vulture] as Array[Joker])
	assert_bool(one.jokers.jokers[0] == vulture).is_false()
	assert_bool(one.jokers.jokers[0] == one.jokers.jokers[1]).is_false()
	assert_int(one.jokers.jokers[0].held).is_equal(2)
	assert_bool(one.jokers.jokers[1].leads).is_false()
	assert_int(two.jokers.jokers[0].held).is_equal(1)
	var kept := one.jokers.jokers[0]
	one.jokers.deal(dealt)
	assert_bool(one.jokers.jokers[0] == kept).is_true()


## GAME.md 8.3: the pane says what the whole stack does, every number the stack changed in the
## gold of the ×2 beside the name; one copy's words are the card's own, in the pane's ink.
func test_the_pane_says_a_stacks_numbers_in_gold() -> void:
	var detail: JokerDetail = auto_free(JokerDetail.new())
	add_child(detail)
	var gold := "[color=#%s]" % JokerDetail.STACK.to_html(false)
	detail.show_joker(_joker("vulture"), 1)
	assert_str(detail._body.text).not_contains("[color")
	assert_str(detail._body.text).contains("3 coins")
	detail.show_joker(_joker("vulture"), 2)
	assert_str(detail._body.text).contains(gold + "4 coins[/color]")
	# On offer, what taking it would make it.
	detail.show_joker(_joker("vulture"), 2, true)
	assert_str(detail._body.text).contains(gold + "5 coins[/color]")


## Two Wild Cards offer seven, and seven fit across the screen, alone and sharing it.
func test_two_wild_cards_offer_seven_and_they_fit() -> void:
	var match_node := _start_match()
	var kart := match_node.kart_of(0)
	_attach(kart, "wild_card", 2)
	assert_int(kart.offer_count(3)).is_equal(7)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var offer := JokerOffer.new(kart, CATALOG.offer(rng, 7, []))
	for columns: int in [1, 2]:
		var picker: JokerPicker = auto_free(JokerPicker.new())
		picker.columns = columns
		add_child(picker)
		await await_idle_frame()
		picker.size = Vector2(1280.0, 720.0)
		for i: int in 30:
			picker.show_offer(offer, kart)
		var share := picker.size.x / columns
		for card: JokerCard in picker._cards:
			var middle := card.position.x + card.pivot_offset.x
			var half := JokerCard.SIZE.x * card.scale.x * 0.5
			(
				assert_float(middle - half)
				. override_failure_message("off the left of %d" % columns)
				. is_greater_equal(0.0)
			)
			(
				assert_float(middle + half)
				. override_failure_message("off the right of %d" % columns)
				. is_less_equal(share)
			)
