extends GdUnitTestSuite
## What a player who is out may do with their hand, GAME.md 3.7: read it, walk the cursor, and
## nothing else. The rest of the hand and the cards themselves are in test_jokers.gd.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


## Offers are off: a death here is not an excuse to deal somebody a random joker.
func _start_match(inputs: Array[KartInput], seed: int = 21) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	rules.respawn_delay = 0.2
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, seed)
	return match_node


func _attach(kart: Kart, id: String) -> Joker:
	return kart.jokers.add(load("res://data/jokers/%s.tres" % id))


## The words in the pane's hint line, which is a row of drawn buttons with words between them.
func _hint_words(hand: JokerHand) -> String:
	var said: PackedStringArray = []
	for child: Node in hand._detail._hints.get_children():
		var word := child as Label
		if word != null:
			said.append(word.text)
	return " ".join(said)


## GAME.md 3.7: the pane under a card offers what can be done with it. A player waiting to come
## back can walk the cursor but cannot throw anything away, so the two buttons that would are
## not drawn while the kart is down.
func test_the_pane_offers_a_dead_player_the_cursor_and_nothing_else() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	_attach(kart, "hair_trigger")
	_attach(kart, "rubber_bumpers")
	await _runner.simulate_frames(12, 17)
	var hand: JokerHand = match_node.hud._hands[0]
	Input.action_press(InputActions.JOKER_MENU)
	await _runner.simulate_frames(6, 17)
	assert_bool(kart.menu_open).is_true()
	var alive_line := _hint_words(hand)
	assert_str(alive_line).contains("cycle")
	assert_str(alive_line).contains("drop")
	assert_str(alive_line).contains("destroy")
	# Killed with the hand open: the cards stay readable and the cursor stays usable.
	kart.die(&"pit", -1)
	await _runner.simulate_frames(6, 17)
	assert_bool(kart.menu_open).is_true()
	assert_int(hand.selected()).is_greater_equal(0)
	var dead_line := _hint_words(hand)
	assert_str(dead_line).contains("cycle")
	assert_str(dead_line).not_contains("drop")
	assert_str(dead_line).not_contains("destroy")
	Input.action_release(InputActions.JOKER_MENU)
	await _runner.simulate_frames(2, 17)


## GAME.md 3.13 and 3.7: nobody comes back in sudden death, which makes a player who is out
## exactly the player with time to read their hand. Their controls stopped being polled at all
## when the clock ran out, so the hand would not open for them at the one moment it should.
func test_a_player_out_in_sudden_death_can_still_read_their_hand() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(), KartInput.new(), KartInput.new(), KartInput.new()
	]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	_attach(kart, "hair_trigger")
	_attach(kart, "big_tank")
	await _runner.simulate_frames(12, 17)
	kart.die(&"pit", -1)
	# The clock runs out with a field still standing, which is sudden death rather than a
	# whistle. Nobody is coming back, this player least of all.
	match_node.time_left = 0.0
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	assert_bool(kart.alive).is_false()
	Input.action_press(InputActions.JOKER_MENU)
	await _runner.simulate_frames(6, 17)
	assert_bool(kart.menu_open).is_true()
	Input.action_release(InputActions.JOKER_MENU)
	await _runner.simulate_frames(6, 17)
	assert_bool(kart.menu_open).is_false()
	# And they are still out: reading the hand is not a way back into the match.
	assert_bool(kart.alive).is_false()


## The pane is filled in when what it says changes rather than every frame it is up: the hand and
## the pick are asked every frame, and a row of drawn buttons built again each time is a dozen
## nodes made and thrown away sixty times a second.
func test_the_pane_is_not_built_again_every_frame() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	_attach(kart, "hair_trigger")
	_attach(kart, "rubber_bumpers")
	await _runner.simulate_frames(12, 17)
	var hand: JokerHand = match_node.hud._hands[0]
	Input.action_press(InputActions.JOKER_MENU)
	await _runner.simulate_frames(4, 17)
	var row := hand._detail._hints
	assert_object(row).is_not_null()
	await _runner.simulate_frames(6, 17)
	assert_object(hand._detail._hints).is_same(row)
	# Down, the pane stops offering to throw anything away, which is a new row.
	kart.die(&"pit", -1)
	await _runner.simulate_frames(3, 17)
	assert_object(hand._detail._hints).is_not_same(row)
	Input.action_release(InputActions.JOKER_MENU)
	await _runner.simulate_frames(2, 17)
	# And the pick, which the HUD shows every frame it is up.
	var slot := match_node.slots[0]
	var choices: Array[Joker] = []
	for id: String in ["big_tank", "toll_booth", "road_rage"]:
		choices.append(load("res://data/jokers/%s.tres" % id))
	slot.offer = JokerOffer.new(kart, choices)
	slot.respawn_left = 30.0
	await _runner.simulate_frames(4, 17)
	var picker: JokerPicker = match_node.hud._pickers[0]
	assert_bool(picker.visible).is_true()
	var pick_row := picker._detail._hints
	assert_object(pick_row).is_not_null()
	slot.offer.selected = 2
	await _runner.simulate_frames(6, 17)
	assert_object(picker._detail._hints).is_same(pick_row)
	assert_str(picker._detail._name.text).is_equal(choices[2].display_name)
