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
	assert_int(counted.get(Joker.Suit.SPADES, 0)).is_equal(6)
	assert_int(counted.get(Joker.Suit.HEARTS, 0)).is_equal(6)
	assert_int(counted.get(Joker.Suit.DIAMONDS, 0)).is_equal(10)
	assert_int(counted.get(Joker.Suit.CLUBS, 0)).is_equal(10)
	assert_int(counted.get(Joker.Suit.WILD, 0)).is_equal(3)
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


## A card wears its suit after its kind, and the pane says what three of it pay.
func test_a_card_and_its_pane_show_the_suit() -> void:
	var joker := JOKERS.by_id(&"vulture")
	var card: JokerCard = auto_free(JokerCard.create(joker))
	var mark := card.find_child("Suit", true, false) as JokerSuits.Mark
	assert_int(mark.suit).is_equal(Joker.Suit.DIAMONDS)
	assert_str(JokerSuits.words(joker.suit)).is_equal(
		"Three Diamonds: every chip you pick up is worth one more."
	)
	assert_str(JokerSuits.words(Joker.Suit.WILD)).contains("Wild")
	var pane: JokerDetail = auto_free(JokerDetail.new())
	pane.show_joker(joker)
	assert_str(pane._suit_words.text).contains("Three Diamonds")
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


## A Suited hand says so against its count, SUITED and its suit, and stops saying it once it is not.
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
	assert_int(hand._suited.get_child_count()).is_equal(2)
	var mark := hand._suited.get_child(1) as JokerSuits.Mark
	assert_int(mark.suit).is_equal(Joker.Suit.DIAMONDS)
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
