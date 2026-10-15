extends GdUnitTestSuite
## The jokers' suits, GAME.md 7.3, Suits: every joker's, what a hand is Suited in, and how a card
## and the pane that describes it show them.

const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match(inputs: Array[KartInput] = [], with_hud := false) -> Match:
	if inputs.is_empty():
		inputs = [KartInput.new(), KartInput.new()]
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	rules.respawn_delay = 0.2
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = with_hud
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 21)
	return match_node


func _take(kart: Kart, ids: Array[StringName]) -> void:
	for id: StringName in ids:
		kart.jokers.add(JOKERS.by_id(id))


func _chip() -> Chip:
	var chip := Chip.new()
	chip.value = 1
	return auto_free(chip)


func _hand(ids: Array[StringName]) -> Array[Joker]:
	var hand: Array[Joker] = []
	for id: StringName in ids:
		hand.append(JOKERS.by_id(id))
	return hand


## Every joker has its suit, as many of each as GAME.md 7.3's table has.
func test_every_joker_has_its_suit() -> void:
	var counted := {}
	for joker: Joker in JOKERS.jokers:
		counted[joker.suit] = counted.get(joker.suit, 0) + 1
	assert_int(counted.get(Joker.Suit.SPADES, 0)).is_equal(9)
	assert_int(counted.get(Joker.Suit.HEARTS, 0)).is_equal(8)
	assert_int(counted.get(Joker.Suit.DIAMONDS, 0)).is_equal(11)
	assert_int(counted.get(Joker.Suit.CLUBS, 0)).is_equal(12)
	assert_int(counted.get(Joker.Suit.WILD, 0)).is_equal(7)
	assert_int(JOKERS.by_id(&"hair_trigger").suit).is_equal(Joker.Suit.SPADES)
	assert_int(JOKERS.by_id(&"payday").suit).is_equal(Joker.Suit.DIAMONDS)


## Three of a suit is Suited in it; two are not; a wild card joins the suit held most of, the first
## in order where two are level, and counts once rather than in every suit.
func test_three_of_a_suit_is_suited_and_a_wild_card_joins_the_lead() -> void:
	assert_array(JokerSuits.suited(_hand([&"hair_trigger", &"big_tank"]))).is_empty()
	var three := _hand([&"hair_trigger", &"big_tank", &"aimbot", &"payday"])
	assert_array(JokerSuits.suited(three)).contains_exactly([Joker.Suit.SPADES])
	var level := _hand([&"payday", &"odometer", &"spare_tire", &"comeback", &"deep_pockets"])
	assert_array(JokerSuits.suited(level)).contains_exactly([Joker.Suit.HEARTS])
	assert_int(JokerSuits.leading(level)).is_equal(Joker.Suit.HEARTS)
	assert_int(JokerSuits.leading(_hand([&"deep_pockets"]))).is_equal(-1)
	# Two cards of a stack are two cards.
	var stacked := _hand([&"payday", &"payday", &"vulture"])
	assert_array(JokerSuits.suited(stacked)).contains_exactly([Joker.Suit.DIAMONDS])


## A card wears its suit before its kind, and the pane says what three of it pay.
func test_a_card_and_its_pane_show_the_suit() -> void:
	var joker := JOKERS.by_id(&"vulture")
	var card: JokerCard = auto_free(JokerCard.create(joker))
	var mark := card.find_child("Suit", true, false) as JokerSuits.Mark
	assert_int(mark.suit).is_equal(Joker.Suit.DIAMONDS)
	assert_str(JokerSuits.words(joker.suit)).is_equal(": every chip you pick up is worth one more.")
	assert_str(JokerSuits.words(Joker.Suit.WILD)).contains("Wild")
	var pane: JokerDetail = auto_free(JokerDetail.new())
	pane.show_joker(joker)
	assert_str(pane._suit_count.text.replace(JokerDetail.SPACE, "")).is_equal("3×")
	assert_int(pane._suit_mark.suit).is_equal(Joker.Suit.DIAMONDS)
	assert_str(pane._suit_words.text).starts_with(":")
	pane.show_joker(JOKERS.by_id(&"wild_card"))
	assert_bool(pane._suit_count.visible).is_false()
	assert_str(pane._suit_words.text.replace(JokerDetail.SPACE, "")).starts_with("Wild")
	pane.show_unknown("A card", "Not taken yet")
	assert_bool(pane._suit_row.visible).is_false()


## A Suited hand is paid as one more joker in play, never a card in the hand: Spades' bullets fly
## faster, and the bonus goes with the third card.
func test_a_suited_hand_is_paid_its_suits_bonus() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var speed := kart.cannon_stats.bullet_speed
	_take(kart, [&"hair_trigger", &"big_tank"])
	assert_array(kart.jokers.suited).is_empty()
	_take(kart, [&"aimbot"])
	assert_array(kart.jokers.suited).contains_exactly([Joker.Suit.SPADES])
	assert_int(kart.jokers.count()).is_equal(3)
	assert_int(kart.jokers.in_play.size()).is_equal(4)
	assert_float(kart.cannon_stats.bullet_speed).is_equal_approx(
		speed * SuitBonus.BULLET_SPEED, 0.001
	)
	kart.jokers.remove_at(0)
	assert_float(kart.cannon_stats.bullet_speed).is_equal_approx(speed, 0.001)


## Diamonds make every chip one more, Hearts come back holding a Shield, Clubs pay mult for a drift
## carried to its boost.
func test_each_suit_pays_its_own() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"payday", &"vulture", &"odometer"])
	kart.collect_coins(1, _chip())
	assert_int(kart.pot.coins).is_equal(2)
	var other := match_node.kart_of(1)
	_take(other, [&"spare_tire", &"comeback", &"tight_grip"])
	other.respawn(other.global_position, Vector3.FORWARD, 0.0)
	assert_object(other.held_item).is_not_null()
	assert_str(String(other.held_item.id)).is_equal("shield")
	kart.jokers.remove_at(0)
	_take(kart, [&"tailslide", &"nitro_habit", &"jerry_can"])
	kart.pot.reset()
	# A drift carried to its boost, ending on the next tick with the kart at speed.
	kart.motor.velocity = kart.motor.forward_vector() * kart.stats.top_speed
	kart.motor.drifting = true
	kart.motor.drift_time = 1.0
	kart.motor.slide_rate = 0.0
	await _runner.simulate_frames(2, 17)
	assert_float(kart.pot.mult).is_equal_approx(1.0 + SuitBonus.DRIFT_MULT, 0.001)


## A Suited hand says so over its count, a card of its suit and SUITED, and stops once it is not.
func test_the_hand_says_it_is_suited() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, true)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var hand: JokerHand = match_node.hud._hands[0]
	_take(kart, [&"payday", &"vulture"])
	await _runner.simulate_frames(4, 17)
	assert_bool(hand._suited.visible).is_false()
	_take(kart, [&"odometer"])
	await _runner.simulate_frames(4, 17)
	assert_bool(hand._suited.visible).is_true()
	assert_array(hand._suited.suits()).contains_exactly([Joker.Suit.DIAMONDS])
	assert_str(hand._suited._word).is_equal("SUITED")
	_take(kart, [&"tailslide", &"hot_streak"])
	await _runner.simulate_frames(4, 17)
	assert_str(hand._suited._word).is_equal("FULL HOUSE")
	assert_array(hand._suited.suits()).contains_exactly([Joker.Suit.DIAMONDS, Joker.Suit.CLUBS])
	kart.jokers.remove_at(4)
	kart.jokers.remove_at(3)
	kart.jokers.remove_at(0)
	await _runner.simulate_frames(4, 17)
	assert_bool(hand._suited.visible).is_false()


## Half the time a respawn offer deals one card of the suit the hand holds most of, in among the
## others; with no suit to lean to it deals as it always did.
func test_the_offer_leans_toward_the_hands_suit() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var with_lean := 0
	var without := 0
	for i: int in 400:
		for card: Joker in JOKERS.offer(rng, 3, [], Joker.Suit.HEARTS):
			if card.suit == Joker.Suit.HEARTS:
				with_lean += 1
		for card: Joker in JOKERS.offer(rng, 3, [], -1):
			if card.suit == Joker.Suit.HEARTS:
				without += 1
	# Hearts are a sixth of the deck: a lean half the time adds about half a card an offer.
	assert_int(with_lean - without).is_greater(120)
	# A suit with nothing left to deal leans to nothing, and the offer is still whole.
	var held: Array[StringName] = []
	for card: Joker in JOKERS.jokers:
		if card.suit == Joker.Suit.HEARTS:
			for copy: int in maxi(card.most, 1):
				held.append(card.id)
	for i: int in 20:
		var offered := JOKERS.offer(rng, 3, held, Joker.Suit.HEARTS)
		assert_int(offered.size()).is_equal(3)
		for card: Joker in offered:
			assert_int(card.suit).is_not_equal(Joker.Suit.HEARTS)


## A bot takes the rarest card of the suit it holds most of, and with a full hand destroys a card of
## another suit, keeping its wild cards.
func test_a_bot_builds_by_suit() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(1)
	_take(kart, [&"hair_trigger", &"big_tank"])
	var rng := RandomNumberGenerator.new()
	var offer := JokerOffer.new(kart, _hand([&"payday", &"rubber_bumpers", &"aimbot"]))
	offer.answer_at = 0.0
	KartDeath._bot_pick(offer, kart, rng)
	assert_bool(kart.jokers.has(&"aimbot")).is_true()
	_take(kart, [&"deep_pockets", &"payday", &"vulture", &"odometer"])
	assert_bool(kart.jokers.is_full()).is_true()
	var full := JokerOffer.new(kart, _hand([&"curve_ball"]))
	full.answer_at = 0.0
	KartDeath._bot_pick(full, kart, rng)
	assert_bool(kart.jokers.has(&"curve_ball")).is_true()
	assert_bool(kart.jokers.has(&"deep_pockets")).is_true()
	assert_int(kart.jokers.ids().count(&"hair_trigger")).is_equal(1)
	var diamonds := 0
	for card: Joker in kart.jokers.jokers:
		if card.suit == Joker.Suit.DIAMONDS:
			diamonds += 1
	assert_int(diamonds).is_equal(2)


## A death applies the cursed jokers' terms first, so an antidote has the last say whichever card
## was taken last: Insurance Policy banks all that is left under High Roller's 0%.
func test_an_antidote_beats_its_curse_in_any_order() -> void:
	for order: Array[StringName] in [
		[&"high_roller", &"insurance_policy"] as Array[StringName],
		[&"insurance_policy", &"high_roller"] as Array[StringName],
	]:
		var match_node := _start_match()
		await _runner.simulate_frames(12, 17)
		var slot := match_node.slots[0]
		_take(slot.kart, order)
		slot.kart.pot.add_coins(10)
		slot.kart.die(&"bullet", 1)
		var rules := match_node.rules
		var dropped := mini(floori(rules.death_drop_fraction * 10), rules.death_drop_max)
		assert_int(slot.banked).is_equal(10 - dropped)
		var first := slot.kart.jokers.cursed_first()
		assert_str(String(first[0].id)).is_equal("high_roller")


## The reworks that reach from one suit into the next: Lucky Seven counts chips by what they are
## worth, Backfire points back while drifting, and Odometer counts a meter on nitro twice.
func test_the_reworks_bridge_the_suits() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"lucky_seven", &"backfire", &"odometer"])
	var gold := _chip()
	gold.gold = true
	gold.value = 5
	kart.collect_coins(5, gold)
	kart.collect_coins(1, _chip())
	assert_float(kart.pot.mult).is_equal(1.0)
	kart.collect_coins(1, _chip())
	assert_float(kart.pot.mult).is_equal(2.0)
	var backfire := kart.jokers.jokers[1]
	assert_that(backfire.modify_aim(kart, Vector3.FORWARD)).is_equal(Vector3.FORWARD)
	kart.motor.drifting = true
	assert_that(backfire.modify_aim(kart, Vector3.FORWARD)).is_equal(Vector3.BACK)
	kart.motor.drifting = false
	var odometer := kart.jokers.jokers[2]
	var coins := kart.pot.coins
	kart.motor.velocity = kart.motor.forward_vector() * 10.0
	odometer.on_step(kart, 1.0)
	assert_int(kart.pot.coins).is_equal(coins)
	kart.nitro_active = true
	odometer.on_step(kart, 0.5)
	assert_int(kart.pot.coins).is_equal(coins + 1)


## Double Tap: a wounded kart's grace stops a shot only for as long as the shooter's bullets wait,
## half of it with one copy; spawn protection still stops everything.
func test_double_tap_cuts_the_grace() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var target := match_node.kart_of(1)
	var grace := match_node.rules.hurt_protection
	var shot: Bullet = auto_free(Bullet.new())
	shot.owner_slot = 0
	target.hurt_left = grace * 0.6
	assert_bool(KartLives.tapped(target, shot)).is_false()
	_take(shooter, [&"double_tap"])
	assert_bool(KartLives.tapped(target, shot)).is_false()
	target.hurt_left = grace * 0.4
	assert_bool(KartLives.tapped(target, shot)).is_true()
	target.protection_left = 1.0
	assert_bool(KartLives.tapped(target, shot)).is_false()
	target.protection_left = 0.0
	_take(shooter, [&"double_tap", &"double_tap"])
	var tap := shooter.jokers.jokers[0]
	assert_float(tap.modify_wound_grace(1.0)).is_equal_approx(0.125, 0.0001)


## Cushion Shot pays a chip for a bounce off a wall; Snowball fires faster for every kill this life,
## up to half again, and starts over at a death.
func test_cushion_shot_and_snowball() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"cushion_shot", &"cushion_shot", &"snowball"])
	for joker: Joker in kart.jokers.in_play:
		joker.on_shot_bounced(kart)
	assert_int(kart.pot.coins).is_equal(2)
	var cooldown := kart.cannon_stats.fire_cooldown
	var snowball := kart.jokers.jokers[2]
	for i: int in 7:
		snowball.on_victim_death(kart, match_node.kart_of(1), null)
	assert_float(kart.cannon_stats.fire_cooldown).is_equal_approx(cooldown / 1.5, 0.0001)
	snowball.on_death(kart)
	assert_float(kart.cannon_stats.fire_cooldown).is_equal_approx(cooldown, 0.0001)


## Second Wind comes back with a full tank and a Boost; Daredevil's graze patches a wounded kart up,
## but not under Scar Tissue.
func test_second_wind_and_daredevil() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"second_wind", &"daredevil"])
	kart.nitro_charge = 0.0
	kart.respawn(kart.global_position, Vector3.FORWARD, 0.0)
	assert_float(kart.nitro_charge).is_equal(1.0)
	assert_bool(kart.effects.any(func(e: KartEffect) -> bool: return e.id == &"boost")).is_true()
	kart.rules.lives = 2
	kart.lives = 1
	assert_bool(kart.is_wounded()).is_true()
	kart.graze(1)
	assert_bool(kart.is_wounded()).is_false()
	_take(kart, [&"scar_tissue"])
	kart.lives = 1
	kart._graze_cooldown_left = 0.0
	kart.graze(1)
	assert_bool(kart.is_wounded()).is_true()


## Burnout's drift boost is a turbo pad to the other jokers: Green Light pays its mult for it.
func test_burnout_counts_a_drift_boost_as_a_pad() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"burnout", &"green_light"])
	for joker: Joker in kart.jokers.in_play:
		joker.on_drift_boost(kart)
	assert_float(kart.pot.mult).is_equal(2.0)


## Copy Cat is one more copy of the card just before it, past its most, a life and all; after a
## card that does not stack it does nothing.
func test_copy_cat_stands_in_for_the_card_before_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"payday", &"payday", &"payday", &"copy_cat"])
	var payday := kart.jokers.jokers[0]
	assert_int(payday.stacked()).is_equal(4)
	# Its words name the card it copies, in a hand; on offer it says what it does and no more.
	var cat := kart.jokers.jokers[3]
	assert_str(cat.describe()).ends_with("Copying Payday.")
	assert_str(JOKERS.by_id(&"copy_cat").describe()).not_contains("Copying")
	var lives := kart.lives
	_take(kart, [&"spare_tire"])
	assert_int(kart.lives).is_equal(lives + 1)
	kart.jokers.remove_at(3)
	kart.jokers.add(JOKERS.by_id(&"copy_cat"))
	assert_int(KartLives.most(kart)).is_equal(match_node.rules.lives + 2)
	assert_int(kart.lives).is_equal(lives + 2)
	assert_int(payday.stacked()).is_equal(3)
	var other := match_node.kart_of(1)
	_take(other, [&"pickpocket", &"copy_cat"])
	assert_int(other.jokers.in_play.size()).is_equal(2)


## Flush Draw makes two of a suit Suited; Royal Court comes back with a mult for every curse, on top
## of Snake Eyes' 3 whichever card came first.
func test_flush_draw_and_royal_court() -> void:
	var two := _hand([&"payday", &"vulture"])
	assert_array(JokerSuits.suited(two)).is_empty()
	two.append(JOKERS.by_id(&"flush_draw"))
	assert_array(JokerSuits.suited(two)).contains_exactly([Joker.Suit.DIAMONDS])
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"royal_court", &"snake_eyes", &"road_rage"])
	kart.respawn(kart.global_position, Vector3.FORWARD, 0.0)
	assert_float(kart.pot.mult).is_equal(5.0)


## Echo pays again what a joker in the hand pays, chips or mult, when it echoes: its card says so,
## and the next within a second and a half is only counted; and not when it does not.
func test_echo_pays_again() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"cushion_shot", &"green_light", &"echo"])
	var echo := kart.jokers.jokers[2]
	echo.set(&"chance", 1.0)
	var said: Array[String] = []
	var listen := func(_slot: int, joker: StringName, word: String) -> void:
		if joker == &"echo":
			said.append(word)
	Events.joker_went_off.connect(listen)
	kart.jokers.jokers[0].on_shot_bounced(kart)
	assert_int(kart.pot.coins).is_equal(2)
	kart.jokers.jokers[1].on_turbo_pad(kart)
	assert_float(kart.pot.mult).is_equal(3.0)
	Events.joker_went_off.disconnect(listen)
	assert_array(said).contains_exactly(["ECHO", ""])
	echo.set(&"chance", 0.0)
	kart.jokers.jokers[0].on_shot_bounced(kart)
	assert_int(kart.pot.coins).is_equal(3)


## Lucky Charm pays a slot machine pull a step better: a pair as three of a kind, three of a kind
## as three sevens, and nothing as nothing.
func test_lucky_charm_steps_a_pull_up() -> void:
	var charm: Joker = JOKERS.by_id(&"lucky_charm").duplicate()
	assert_int(charm.modify_slot_pays(null, SlotPad.PAIR_PAY)).is_equal(SlotPad.THREE_PAY)
	assert_int(charm.modify_slot_pays(null, SlotPad.THREE_PAY)).is_equal(SlotPad.SEVENS_PAY)
	assert_int(charm.modify_slot_pays(null, SlotPad.SEVENS_PAY)).is_equal(SlotPad.SEVENS_PAY)
	assert_int(charm.modify_slot_pays(null, 0)).is_equal(0)


## Pit Crew puts half a tank back on a turbo pad, all of it with two, then rests three seconds; a
## full tank takes nothing.
func test_pit_crew_refills_on_a_pad() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"pit_crew"])
	var crew := kart.jokers.jokers[0]
	kart.nitro_charge = 0.0
	crew.on_turbo_pad(kart)
	assert_float(kart.nitro_charge).is_equal_approx(0.5, 0.0001)
	crew.on_turbo_pad(kart)
	assert_float(kart.nitro_charge).is_equal_approx(0.5, 0.0001)
	crew.on_step(kart, 3.0)
	_take(kart, [&"pit_crew"])
	kart.nitro_charge = 0.0
	crew.on_turbo_pad(kart)
	assert_float(kart.nitro_charge).is_equal(1.0)
	assert_str(crew.describe(2)).contains("all")


## A joker counted without a word, Cushion Shot's every bounce, goes into the catalog's count but
## leaves its card still in the hand; one with a word sets it going off.
func test_a_count_without_a_word_leaves_the_card_still() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, true)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var hand: JokerHand = match_node.hud._hands[0]
	_take(kart, [&"cushion_shot"])
	await _runner.simulate_frames(2, 17)
	Events.joker_went_off.emit(0, &"cushion_shot", "")
	assert_bool(hand._flashing.is_empty()).is_true()
	Events.joker_went_off.emit(0, &"cushion_shot", "BOUNCE")
	assert_bool(hand._flashing.is_empty()).is_false()
	for id: StringName in [
		&"cushion_shot",
		&"daredevil",
		&"second_wind",
		&"royal_court",
		&"burnout",
		&"echo",
		&"lucky_charm",
		&"pit_crew"
	]:
		assert_str(JOKERS.by_id(id).went_off_words(2)).is_not_empty()


## The hands of GAME.md 7.3, Hands: a Full House is Suited in both its suits, Four of a Kind and a
## Flush take four and five of one, a Rainbow a card of each suit of its own, and a Two Pair two
## each of two suits with neither Suited; Flush Draw makes two of a suit Suited, so its pairs are.
func test_the_hands_a_hand_makes() -> void:
	var full := JokerHands.of(
		_hand([&"payday", &"vulture", &"odometer", &"tailslide", &"hot_streak"])
	)
	assert_int(full.best()).is_equal(JokerHands.Hand.FULL_HOUSE)
	assert_array(full.suited).contains_exactly([Joker.Suit.DIAMONDS, Joker.Suit.CLUBS])
	var four := JokerHands.of(_hand([&"payday", &"vulture", &"odometer", &"pickpocket"]))
	assert_int(four.best()).is_equal(JokerHands.Hand.FOUR_OF_A_KIND)
	assert_bool(four.has(JokerHands.Hand.SUITED)).is_true()
	var flush := JokerHands.of(
		_hand([&"payday", &"vulture", &"odometer", &"pickpocket", &"toll_booth"])
	)
	assert_array(flush.hands).contains_exactly(
		[JokerHands.Hand.FLUSH, JokerHands.Hand.FOUR_OF_A_KIND, JokerHands.Hand.SUITED]
	)
	assert_int(flush.twice).is_equal(Joker.Suit.DIAMONDS)
	var rainbow := JokerHands.of(_hand([&"big_tank", &"spare_tire", &"payday", &"tailslide"]))
	assert_int(rainbow.best()).is_equal(JokerHands.Hand.RAINBOW)
	assert_array(rainbow.shown).contains_exactly([0, 1, 2, 3])
	var wild := JokerHands.of(_hand([&"big_tank", &"spare_tire", &"payday", &"wild_card"]))
	assert_bool(wild.has(JokerHands.Hand.RAINBOW)).is_false()
	var two := JokerHands.of(_hand([&"big_tank", &"hair_trigger", &"spare_tire", &"tight_grip"]))
	assert_int(two.best()).is_equal(JokerHands.Hand.TWO_PAIR)
	assert_array(two.shown).contains_exactly([Joker.Suit.SPADES, Joker.Suit.HEARTS])
	var drawn := JokerHands.of(
		_hand([&"big_tank", &"hair_trigger", &"spare_tire", &"tight_grip", &"flush_draw"])
	)
	assert_array(drawn.suited).contains_exactly([Joker.Suit.SPADES, Joker.Suit.HEARTS])
	assert_bool(drawn.has(JokerHands.Hand.TWO_PAIR)).is_false()


## What the hands pay: a Flush its suit's bonus twice, so a chip is worth two more; a Rainbow's and
## a Two Pair's cash-outs bank more; Four of a Kind a chip every few seconds.
func test_what_the_hands_pay() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	_take(kart, [&"payday", &"vulture", &"odometer", &"pickpocket", &"toll_booth"])
	var worth := 1
	for joker: Joker in kart.jokers.in_play:
		worth = joker.modify_coin_value(kart, _chip(), worth)
	assert_int(worth).is_equal(3)
	var chips := 0
	for joker: Joker in kart.jokers.in_play:
		if joker is HandBonus:
			joker.on_step(kart, HandBonus.CHIP_EVERY)
	chips = kart.pot.coins
	assert_int(chips).is_equal(1)
	var other := match_node.kart_of(1)
	_take(other, [&"big_tank", &"spare_tire", &"payday", &"tailslide"])
	var payout := 1.0
	for joker: Joker in other.jokers.in_play:
		payout = joker.modify_bank_payout(other, payout)
	assert_float(payout).is_equal_approx(HandBonus.RAINBOW_BANK, 0.0001)


## The pay table of the hands stands beside the hand while its key is held, with one seat at the
## screen; it says what the next hand up the suit still wants.
func test_the_pay_table_shows_while_the_key_is_held() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, true)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var hand: JokerHand = match_node.hud._hands[0]
	_take(kart, [&"payday", &"vulture", &"odometer"])
	await _runner.simulate_frames(4, 17)
	assert_bool(hand._table.visible).is_false()
	Input.action_press(InputActions.JOKER_MENU)
	await _runner.simulate_frames(20, 17)
	assert_bool(hand._table.visible).is_true()
	# Out from behind the bottom edge, standing on it.
	assert_float(hand._table.position.y + HandsTable.SIZE.y).is_equal_approx(
		hand.size.y - JokerHand.MARGIN, 1.0
	)
	assert_array(hand._table._made).contains([JokerHands.Hand.SUITED])
	# The card's pane says what the hand makes, its suit's line lit.
	assert_bool(hand._detail._active.visible).is_true()
	assert_str(hand._detail._active.text).is_equal("Your hand: Suited.")
	assert_array(hand._table._wanted).is_equal(
		[JokerHands.Hand.FOUR_OF_A_KIND, 1, Joker.Suit.DIAMONDS]
	)
	hand.columns = 2
	await _runner.simulate_frames(20, 17)
	assert_bool(hand._table.visible).is_false()
	Input.action_release(InputActions.JOKER_MENU)
