extends GdUnitTestSuite
## The table's cards, GAME.md 3.17: the features a match can leave off, what each takes off the
## floor and out of the rules, and Roulette's deal.

const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _table(cards: Array[int]) -> int:
	var table := 0
	for card: int in cards:
		table = TableCards.with(table, card, true)
	return table


func _rng(seed_in: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_in
	return rng


## The House opens a card a map, 8.9a: power-ups from the start, the whole floor after seven.
func test_the_house_opens_a_card_a_map() -> void:
	assert_int(TableCards.opened_by(0)).is_equal(TableCards.FIRST)
	assert_int(TableCards.opened_by(1)).is_equal(
		_table([TableCards.Card.ITEMS, TableCards.Card.JACKPOT])
	)
	assert_int(TableCards.opened_by(3)).is_equal(
		_table(
			[
				TableCards.Card.ITEMS,
				TableCards.Card.JACKPOT,
				TableCards.Card.JOKERS,
				TableCards.Card.FLUSH
			]
		)
	)
	assert_int(TableCards.opened_by(4)).is_equal(
		TableCards.opened_by(3) | TableCards.bit(TableCards.Card.TRICKS)
	)
	assert_int(TableCards.opened_by(7)).is_equal(TableCards.ALL)
	assert_int(TableCards.opened_by(40)).is_equal(TableCards.ALL)
	assert_int(TableCards.opened_at(0)).is_equal(-1)
	assert_int(TableCards.opened_at(2)).is_equal(TableCards.Card.JOKERS)
	assert_int(TableCards.opened_at(7)).is_equal(TableCards.Card.SUITS)
	assert_int(TableCards.opened_at(8)).is_equal(-1)
	assert_int(TableCards.NAMES.size()).is_equal(TableCards.Card.size())
	assert_int(TableCards.LINES.size()).is_equal(TableCards.Card.size())
	assert_int(TableCards.GLYPHS.size()).is_equal(TableCards.Card.size())


## Suits & hands are nothing without the Jokers they are of.
func test_suits_need_jokers() -> void:
	var suits_alone := _table([TableCards.Card.ITEMS, TableCards.Card.SUITS])
	assert_bool(TableCards.has(TableCards.playable(suits_alone), TableCards.Card.SUITS)).is_false()
	var both := _table([TableCards.Card.JOKERS, TableCards.Card.SUITS])
	assert_int(TableCards.playable(both)).is_equal(both)


## Each card off takes its glyphs off the floor; the tripwires go with either of theirs.
func test_cards_off_clear_their_glyphs() -> void:
	assert_str(TableCards.glyphs_off(TableCards.ALL)).is_empty()
	var first := TableCards.glyphs_off(TableCards.FIRST)
	for glyph: String in "KF$@E=MNWL":
		assert_str(first).contains(glyph)
	assert_str(first).not_contains("P")
	var no_bounty := TableCards.glyphs_off(
		TableCards.with(TableCards.ALL, TableCards.Card.BOUNTY, false)
	)
	assert_str(no_bounty).is_equal("L")
	var no_tricks := TableCards.glyphs_off(
		TableCards.with(TableCards.ALL, TableCards.Card.TRICKS, false)
	)
	assert_str(no_tricks).is_equal("@E=MNWL")
	var rows := PackedStringArray(["#K.F#", "#$P@#"])
	assert_array(Array(TableCards.clear_grid(rows, first))).is_equal(["#...#", "#.P.#"])


## A map at a first table, power-ups alone: no Jackpot, no Flush pads, no slot machines on the
## floor and none of the room's tricks, the casino still on the rail.
func test_a_first_table_clears_the_floor() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.map = &"lucky_crossing"
	assert_object(ArenaMaps.layout_for(rules)).is_same(ArenaMaps.layout(&"lucky_crossing"))
	rules.table = TableCards.FIRST
	var layout := ArenaMaps.layout_for(rules)
	assert_object(layout).is_not_same(ArenaMaps.layout(&"lucky_crossing"))
	var grid := layout.parse()
	assert_array(grid.jackpots).is_empty()
	assert_array(grid.flush_pads).is_empty()
	assert_array(grid.slot_pads).is_empty()
	assert_array(grid.magnets).is_empty()
	assert_bool(grid.slot_rail).is_true()
	assert_int(grid.power_pads.size()).is_equal(4)
	assert_int(grid.junctions.size()).is_equal(1)
	# The map itself is left as it was for the next match.
	assert_int(ArenaMaps.layout(&"lucky_crossing").parse().flush_pads.size()).is_equal(4)
	for id: StringName in [&"crossfire", &"house_rules", &"loose_threads", &"toy_box"]:
		rules.map = id
		var cleared := ArenaMaps.layout_for(rules).parse()
		assert_array(cleared.cabinets).override_failure_message(id).is_empty()
		assert_array(cleared.belts).override_failure_message(id).is_empty()
		assert_array(cleared.seams).override_failure_message(id).is_empty()
		assert_array(cleared.toys).override_failure_message(id).is_empty()
	rules.map = &"vault"
	rules.table = TableCards.with(TableCards.ALL, TableCards.Card.BOUNTY, false)
	assert_array(ArenaMaps.layout_for(rules).parse().lasers).is_empty()


## A card off switches off what it is in the rules; the Final Hand plays the whole floor.
func test_the_rules_follow_the_table() -> void:
	var config := MatchConfig.new()
	config.table = TableCards.FIRST
	var rules := config.rules(DEFAULT_RULES)
	assert_int(rules.table).is_equal(TableCards.FIRST)
	assert_bool(rules.offer_jokers).is_false()
	assert_bool(rules.bounties).is_false()
	assert_int(rules.wild_joker_level).is_greater(100)
	config.table = TableCards.ALL
	rules = config.rules(DEFAULT_RULES)
	assert_bool(rules.offer_jokers).is_true()
	assert_bool(rules.bounties).is_true()
	assert_int(rules.wild_joker_level).is_equal(DEFAULT_RULES.wild_joker_level)
	config.table = TableCards.FIRST
	config.final_hand = true
	assert_int(config.rules(DEFAULT_RULES).table).is_equal(TableCards.ALL)


## The table goes over the wire with the rest of the rules, so a client builds the same floor.
func test_the_table_goes_over_the_wire() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.table = TableCards.FIRST | TableCards.bit(TableCards.Card.SLOTS)
	var client: MatchRules = DEFAULT_RULES.duplicate()
	client.from_wire(rules.to_wire())
	assert_int(client.table).is_equal(rules.table)


## Roulette deals power-ups and three of the deck's other cards a map, Suits & hands with Jokers.
func test_roulette_deals_three_cards_a_map() -> void:
	var seen := 0
	for i: int in 60:
		var dealt := TableCards.deal(TableCards.ALL, _rng(i))
		assert_bool(TableCards.has(dealt, TableCards.Card.ITEMS)).is_true()
		var others := 0
		for card: int in TableCards.DEALT:
			if TableCards.has(dealt, card):
				others += 1
		assert_int(others).is_equal(TableCards.DEAL)
		assert_bool(TableCards.has(dealt, TableCards.Card.SUITS)).is_equal(
			TableCards.has(dealt, TableCards.Card.JOKERS)
		)
		seen |= dealt
	assert_int(seen).is_equal(TableCards.ALL)
	# A deck of two deals the two; a card not in the deck is never dealt.
	var deck := _table([TableCards.Card.ITEMS, TableCards.Card.JACKPOT, TableCards.Card.SLOTS])
	assert_int(TableCards.deal(deck, _rng(3))).is_equal(deck)
	var config := MatchConfig.new()
	config.roulette = true
	config.table = _table(
		[
			TableCards.Card.ITEMS,
			TableCards.Card.FLUSH,
			TableCards.Card.BOUNTY,
			TableCards.Card.SLOTS,
			TableCards.Card.JACKPOT
		]
	)
	for i: int in 20:
		var rules := config.rules(DEFAULT_RULES, _rng(i))
		assert_int(rules.table & ~config.table).is_equal(0)
		assert_int(TableCards.cards_of(rules.table).size()).is_equal(1 + TableCards.DEAL)


## Without Suits & hands a hand of three Spades is no Suited hand, its pick leans to no suit, and
## the joker that only bends the suits is not in the deck.
func test_a_table_without_suits_makes_no_hands() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.table = TableCards.with(TableCards.ALL, TableCards.Card.SUITS, false)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	Loyalty.deal_table(match_node, load("res://data/powerups/first_set.tres"), false)
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new(), KartInput.new()], 21)
	await _runner.simulate_frames(6, 17)
	var kart := match_node.kart_of(0)
	for id: StringName in [&"hair_trigger", &"big_tank", &"aimbot"]:
		kart.jokers.add(JOKERS.by_id(id))
	assert_array(kart.jokers.suited).is_empty()
	assert_array(kart.jokers.made.hands).is_empty()
	assert_int(JokerSuits.lean(kart)).is_equal(-1)
	assert_bool(match_node.joker_catalog.deals(JOKERS.by_id(&"flush_draw"))).is_false()
	assert_bool(match_node.joker_catalog.deals(JOKERS.by_id(&"hair_trigger"))).is_true()


## A match on a first table has none of the cards' pieces on its floor, and the rail still stands.
func test_a_first_table_match_has_none_of_their_pieces() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.map = &"lucky_crossing"
	rules.table = TableCards.FIRST
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	match_node.arena_layout = ArenaMaps.layout_for(rules)
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new()], 3)
	await _runner.simulate_frames(6, 17)
	assert_array(match_node.arena.jackpot_zones).is_empty()
	assert_array(match_node.arena.flush_pads).is_empty()
	assert_int(match_node.arena.power_pads.size()).is_equal(4)
	assert_array(match_node.arena.find_children("SlotPad*", "SlotPad", false, false)).is_empty()
	assert_object(match_node.arena.get_node_or_null("RailMachines")).is_not_null()
	await _runner.simulate_frames(60, 17)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)


## Bots play a first table, its pieces gone from under them, without a hitch: on the maps whose
## rooms have tricks of their own taken off the floor.
func test_bots_play_a_first_table() -> void:
	for id: StringName in [&"crossfire", &"toy_box", &"vault"]:
		var rules: MatchRules = DEFAULT_RULES.duplicate()
		rules.countdown = 0.1
		rules.respawn_delay = 0.2
		rules.map = id
		rules.table = TableCards.FIRST
		rules.offer_jokers = false
		rules.bounties = false
		var match_node: Match = auto_free(MATCH_SCENE.instantiate())
		match_node.rules = rules
		match_node.with_hud = false
		match_node.arena_layout = ArenaMaps.layout_for(rules)
		_runner = scene_runner(match_node)
		var inputs: Array[KartInput] = []
		for i: int in 4:
			inputs.append(BotInput.new())
		match_node.start(inputs, 11)
		await _runner.simulate_frames(120, 33)
		assert_int(match_node.state).override_failure_message(id).is_equal(Match.State.PLAYING)
		for slot: PlayerSlot in match_node.slots:
			assert_int(slot.kart.jokers.count()).override_failure_message(id).is_equal(0)


## The table's new card is pointed at once as the lamps go out, GAME.md 8.9a: the nearest of its
## pieces, and none for a card with nothing on the floor.
func test_the_new_card_is_pointed_at() -> void:
	var settings_were := Game.settings
	Game.settings = Settings.new()
	Game.settings.profile.table.fresh = TableCards.bit(TableCards.Card.FLUSH)
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.map = &"lucky_crossing"
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	FreshPointer.add_to(match_node)
	match_node.start([KartInput.new()], 3)
	await _runner.simulate_frames(20, 17)
	var arrow := match_node.get_node_or_null("GuideArrow") as GuideArrow
	assert_object(arrow).is_not_null()
	var nearest := FreshPointer.target(
		match_node, TableCards.Card.FLUSH, arrow.kart.global_position
	)
	assert_vector(arrow.target).is_equal(nearest)
	assert_bool(nearest.is_finite()).is_true()
	for card: int in [TableCards.Card.ITEMS, TableCards.Card.JACKPOT, TableCards.Card.TRICKS]:
		var spot := FreshPointer.target(match_node, card, Vector3.ZERO)
		assert_bool(spot.is_finite()).override_failure_message(TableCards.NAMES[card]).is_true()
	Game.settings.profile.table.fresh = TableCards.bit(TableCards.Card.JOKERS)
	var before := match_node.get_child_count()
	FreshPointer.add_to(match_node)
	assert_int(match_node.get_child_count()).is_equal(before)
	Game.settings = settings_were
