extends GdUnitTestSuite
## Kit's cards, STORY.md 6.3 and GAME.md 3.7: five cards the House did not print, in every catalog
## but never dealt by a deck, never on the floor and of no suit; dealt by the host now and then for
## a seat that may have them, never to a bot nor at the Final Hand; what each does and costs; and
## taken, a pencil tick, the hoardings' green second, the folder's pocket and Under the Floorboards.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")

var _runner: GdUnitSceneRunner
var _was_story := StoryState.new()
var _was_achievements: AchievementState


func before_test() -> void:
	var profile := Game.settings.profile
	_was_story = profile.story
	_was_achievements = profile.achievements
	profile.story = StoryState.new()
	profile.story.notes = PackedInt32Array([1])
	profile.achievements = AchievementState.new()


func after_test() -> void:
	Game.settings.profile.story = _was_story
	Game.settings.profile.achievements = _was_achievements
	Story.final_hand_on = false


func _start_match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 3
	_runner = scene_runner(match_node)
	match_node.start(inputs, 17)
	await _runner.simulate_frames(12, 17)
	return match_node


func _person_and_bots() -> Array[KartInput]:
	return [PlayerInput.new(DeviceInput.ANY, 0), BotInput.new(), BotInput.new()]


static func _card(id: StringName) -> Joker:
	return CATALOG.by_id(id)


## In every catalog, of no suit and drawn in pencil; never offered by a deck nor counted as the
## House's: not in the press proof, Full Deck, the loyalty program's deck or a hand's suits.
func test_they_are_none_of_the_houses() -> void:
	for id: StringName in KitCards.IDS:
		var card := _card(id)
		assert_object(card).override_failure_message(String(id)).is_not_null()
		assert_bool(card.contraband).is_true()
		assert_str(card.kit_line).is_not_empty()
		assert_str(card.kit_back).is_not_empty()
		assert_bool(CATALOG.deals(card)).is_false()
		assert_bool(id in Achievements.joker_ids()).is_false()
		assert_bool(id in CatalogDialog.ids_of(CATALOG.printed())).is_false()
		assert_bool(id in JokerArt.known()).is_true()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i: int in 200:
		for joker: Joker in CATALOG.offer(rng, 3, []):
			assert_bool(joker.contraband).is_false()
	var deck := Loyalty.deck_from({}, CATALOG)
	for id: StringName in KitCards.IDS:
		assert_bool(id in deck).is_false()
	var hand: Array[Joker] = []
	for id: StringName in [&"brake_check", &"not_today", &"blind_spot"]:
		hand.append(_card(id))
	assert_array(JokerSuits.suited(hand)).is_empty()


## The one flag a seat: nothing before the first note or with the story off, then how many of the
## five are taken, and whether the story has ended.
func test_the_flag_a_seat() -> void:
	var profile := Profile.new()
	assert_array(Array(KitCards.flag_of(profile))).is_empty()
	profile.story.notes = PackedInt32Array([1])
	assert_array(Array(KitCards.flag_of(profile))).is_equal(["0"])
	profile.story.kit_cards = PackedStringArray(["brake_check", "not_today"])
	profile.story.final_hand = "2026-10-16"
	assert_array(Array(KitCards.flag_of(profile))).is_equal(["2", KitCards.ENDED])
	profile.story.on = false
	assert_array(Array(KitCards.flag_of(profile))).is_empty()
	assert_array(Array(Loyalty.clean_unlocks({"kit": ["3"]})["kit"])).is_equal(["3"])


## Dealt by the host to a person who may have them: the five in order the first time, at most once a
## map; never to a bot, and never at the Final Hand.
func test_the_host_deals_them_now_and_then() -> void:
	var match_node: Match = await _start_match(_person_and_bots())
	var person := match_node.slots[0]
	var dealt: Joker = null
	for i: int in 200:
		dealt = KitCards.deal_for(match_node, person)
		if dealt != null:
			break
	assert_object(dealt).is_not_null()
	assert_str(String(dealt.id)).is_equal("brake_check")
	for i: int in 200:
		assert_object(KitCards.deal_for(match_node, person)).is_null()
	for i: int in 50:
		assert_object(KitCards.deal_for(match_node, match_node.slots[1])).is_null()
	match_node.remove_meta(&"kit_dealt")
	Game.settings.profile.story.kit_cards = PackedStringArray(["brake_check"])
	match_node.rules.final_hand = true
	for i: int in 50:
		assert_object(KitCards.deal_for(match_node, person)).is_null()
	match_node.rules.final_hand = false
	var next: Joker = null
	for i: int in 200:
		next = KitCards.deal_for(match_node, person)
		if next != null:
			break
	assert_str(String(next.id)).is_equal("not_today")
	var choices: Array[Joker] = [_card(&"payday"), _card(&"vulture"), _card(&"aimbot")]
	KitCards.swap_in(choices, next, match_node.rng)
	assert_bool(next in choices).is_true()
	assert_int(choices.size()).is_equal(3)


## Brake Check: 10% off top speed, and a dead stop out of a run with chips in the pot pays 1 mult,
## once every 8 seconds and 3 a life.
func test_brake_check() -> void:
	var match_node: Match = await _start_match(_person_and_bots())
	var kart := match_node.kart_of(0)
	var before := kart.motor.stats.top_speed
	var card := kart.jokers.add(_card(&"brake_check"))
	assert_float(kart.motor.stats.top_speed).is_equal_approx(before * 0.9, 0.01)
	kart.pot.add_coins(5)
	var mult := kart.pot.mult
	kart.motor.forward_speed = 8.0
	card.on_step(kart, 0.1)
	kart.motor.forward_speed = 0.0
	card.on_step(kart, 0.1)
	assert_float(kart.pot.mult).is_equal_approx(mult + 1.0, 0.01)
	kart.motor.forward_speed = 8.0
	card.on_step(kart, 0.1)
	kart.motor.forward_speed = 0.0
	card.on_step(kart, 0.1)
	assert_float(kart.pot.mult).is_equal_approx(mult + 1.0, 0.01)


## Not Today: a pick skipped pays 2 mult to the life it comes back to; one of the House's taken
## takes 1 off, never under the pot's own 1.
func test_not_today() -> void:
	var match_node: Match = await _start_match(_person_and_bots())
	var kart := match_node.kart_of(0)
	var card := kart.jokers.add(_card(&"not_today"))
	Events.joker_answered.emit(kart.slot, &"")
	card.on_respawn(kart)
	assert_float(kart.pot.mult).is_equal_approx(3.0, 0.01)
	kart.pot.reset()
	Events.joker_answered.emit(kart.slot, &"payday")
	card.on_respawn(kart)
	assert_float(kart.pot.mult).is_equal_approx(1.0, 0.01)
	kart.jokers.remove(card)


## Blind Spot: the bots aim at where the kart is, not ahead of it; and the board is gone at this
## screen while every player here holds it.
func test_blind_spot() -> void:
	var match_node: Match = await _start_match(_person_and_bots())
	var target := match_node.kart_of(0)
	var bot := match_node.kart_of(1)
	var brain := bot.get_node("Brain") as BotBrain
	target.motor.velocity = Vector3(10.0, 0.0, 0.0)
	var led := brain._lead_point(target)
	assert_float(led.distance_to(target.global_position)).is_greater(0.1)
	target.jokers.add(_card(&"blind_spot"))
	assert_vector(brain._lead_point(target)).is_equal(target.global_position)
	var board: Scoreboard = auto_free(Scoreboard.new())
	board.match_node = match_node
	assert_bool(board.blinded()).is_true()


## Loose Change: half again as many chips dropped at a death, and they stay on the floor.
func test_loose_change() -> void:
	var match_node: Match = await _start_match(_person_and_bots())
	var kart := match_node.kart_of(0)
	var death := DeathOutcome.from_rules(match_node.rules)
	var fraction := death.drop_fraction
	var most := death.drop_max
	kart.jokers.add(_card(&"loose_change")).modify_death(kart, death)
	assert_float(death.drop_fraction).is_equal_approx(minf(fraction * 1.5, 1.0), 0.001)
	assert_int(death.drop_max).is_equal(ceili(most * 1.5))
	assert_bool(death.chips_stay).is_true()


## Under the Table: its score off the standings until the whistle, no bounty and no match point on
## it, and Last Call paying it single.
func test_under_the_table() -> void:
	var match_node: Match = await _start_match(_person_and_bots())
	var slot := match_node.slots[0]
	var card := slot.kart.jokers.add(_card(&"under_the_table"))
	assert_bool(KitCards.off_the_board(match_node, slot)).is_true()
	slot.banked = 5000
	match_node.slots[1].banked = 10
	assert_object(Bounty._leader(match_node)).is_not_same(slot)
	match_node.state = Match.State.LAST_CALL
	var doubled := match_node.rules.last_call_payout
	assert_float(card.modify_bank_payout(slot.kart, 1.0)).is_equal_approx(1.0 / doubled, 0.001)
	match_node.state = Match.State.RESULTS
	assert_bool(KitCards.off_the_board(match_node, slot)).is_false()


## Taken: the hoardings show the House's own green screen for a second, the card is kept with the
## profile the first time and goes into the folder's pocket, and all five earn Under the
## Floorboards; none of it counts as a term of the House's.
func test_taken() -> void:
	var match_node: Match = await _start_match(_person_and_bots())
	var person := match_node.slots[0]
	var story := Game.settings.profile.story
	KitCards.taken(match_node, person, &"blind_spot")
	assert_array(Array(story.kit_cards)).is_equal(["blind_spot"])
	var green := 0
	for board: Node in match_node.arena.billboards.get_children():
		if board is Billboard:
			for part: Node in (board as Billboard).face.get_children():
				if part is Label3D and (part as Label3D).text == StoryLines.MONITOR:
					green += 1
	assert_int(green).is_greater(0)
	KitCards.taken(match_node, person, &"blind_spot")
	assert_int(story.kit_cards.size()).is_equal(1)
	var pages := NotesFolder.in_order(story)
	assert_bool(KitCards.page_of(&"blind_spot") in pages).is_true()
	assert_str(StoryNotes.title_of(KitCards.page_of(&"blind_spot"))).is_equal("Blind Spot")
	for id: StringName in KitCards.IDS:
		KitCards.taken(match_node, person, id)
	assert_bool(Game.settings.profile.achievements.has(&"under_the_floorboards")).is_true()
	# Not counted as one of the House's jokers taken.
	var before := person.stats.value(&"jokers")
	Events.joker_taken.emit(0, &"not_today")
	assert_float(person.stats.value(&"jokers")).is_equal(before)


## Its face in pencil: no suit, K. in the corner, Kit's line along its foot; the pane says it is
## Kit's; and in the folder it lies on its page and turns over to Kit's longer line.
func test_drawn_in_pencil() -> void:
	var card: JokerCard = auto_free(JokerCard.create(_card(&"loose_change")))
	add_child(card)
	var line := card.find_child("KitLine", true, false) as Label
	assert_object(line).is_not_null()
	assert_str(line.text).is_equal(_card(&"loose_change").kit_line)
	var pane: JokerDetail = auto_free(JokerDetail.new())
	add_child(pane)
	pane.show_joker(_card(&"loose_change"))
	assert_str(pane._kind.text).is_equal(JokerDetail.KIT)
	Game.settings.profile.story.kit_cards = PackedStringArray(["loose_change"])
	for layer: StringName in [&"lying", &"back"]:
		var page: NotePage = auto_free(NotePage.make(KitCards.page_of(&"loose_change"), null))
		page.profile = Game.settings.profile
		page.layer = layer
		add_child(page)
		await await_idle_frame()
		assert_object(page.find_child("Kept", true, false)).is_not_null()
