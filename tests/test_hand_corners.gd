extends GdUnitTestSuite
## The hands of three or four players at one screen, GAME.md 8.3: each keeps to its owner's corner,
## beside their block on the same edge, the two top players' hanging from the top edge with the
## pane of the card being read under it, and each tucked into its edge until a card of it is read.
## A respawn pick keeps to its owner's corner as well.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


## A match of [param players] at this screen, each holding three jokers.
func _start_match(players: int) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new()]
	for joypad: int in players - 1:
		inputs.append(PlayerInput.new(joypad, joypad + 1))
	match_node.start(inputs, 7)
	for slot: PlayerSlot in match_node.slots:
		for id: String in ["hair_trigger", "rubber_bumpers", "curve_ball"]:
			slot.kart.jokers.add(load("res://data/jokers/%s.tres" % id))
	await _runner.simulate_frames(30, 17)
	return match_node


static func _center(card: Control) -> Vector2:
	return card.get_global_transform() * (card.size * 0.5)


static func _block_rects(hud: MatchHud) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for index: int in hud._blocks:
		rects.append((hud._blocks[index]["box"] as Control).get_global_rect())
	return rects


func test_four_hands_keep_to_their_owners_corners() -> void:
	var match_node := await _start_match(4)
	var hud := match_node.hud
	var blocks := _block_rects(hud)
	for index: int in hud._blocks:
		var corner: int = hud._blocks[index]["corner"]
		var hand: JokerHand = hud._hands[index]
		var screen := hand.size
		assert_int(hand.corner).is_equal(corner)
		assert_bool(hand.hangs()).is_equal(corner < 2)
		assert_int(hand.card_count()).is_equal(3)
		for card: JokerCard in hand._cards:
			var at := _center(card)
			# On the owner's edge and the owner's side, and over nobody's block.
			if corner < 2:
				assert_float(at.y).is_less(screen.y * 0.25)
			else:
				assert_float(at.y).is_greater(screen.y * 0.75)
			if corner % 2 == 0:
				assert_float(at.x).is_less(screen.x * 0.5)
			else:
				assert_float(at.x).is_greater(screen.x * 0.5)
			for rect: Rect2 in blocks:
				assert_bool(rect.intersects(card.get_global_rect())).is_false()


## Hanging from the top, the card being read drops out of the fan and its pane opens under it,
## clear of the block beside it.
func test_a_top_hand_opens_its_pane_under_the_card() -> void:
	var match_node := await _start_match(4)
	var hud := match_node.hud
	var hand: JokerHand = hud._hands[0]
	assert_bool(hand.hangs()).is_true()
	var resting := _center(hand._cards[0]).y
	Input.action_press(InputActions.JOKER_MENU)
	await _runner.simulate_frames(20, 17)
	assert_bool(match_node.kart_of(0).menu_open).is_true()
	var picked := hand._cards[hand.selected()]
	assert_float(_center(picked).y).is_greater(resting)
	var pane := hand._detail.get_global_rect()
	assert_bool(hand._detail.visible).is_true()
	assert_float(pane.position.y).is_greater(_center(picked).y)
	for rect: Rect2 in _block_rects(hud):
		assert_bool(rect.intersects(pane)).is_false()
	Input.action_release(InputActions.JOKER_MENU)
	await _runner.simulate_frames(2, 17)


## At rest a cornered hand is tucked into its edge, smaller and half past it, as a touch screen's
## is, and comes out to its full size as a card of it is read.
func test_a_cornered_hand_is_tucked_until_it_is_read() -> void:
	var match_node := await _start_match(4)
	var hud := match_node.hud
	for index: int in hud._hands:
		var hand: JokerHand = hud._hands[index]
		for card: JokerCard in hand._cards:
			var face := card.get_global_rect()
			assert_float(card.scale.y).is_less(0.6)
			if hand.hangs():
				assert_float(face.position.y).is_less(0.0)
			else:
				assert_float(face.end.y).is_greater(hand.size.y)
	var top: JokerHand = hud._hands[0]
	Input.action_press(InputActions.JOKER_MENU)
	await _runner.simulate_frames(30, 17)
	for card: JokerCard in top._cards:
		assert_float(card.scale.y).is_equal_approx(0.8, 0.01)
		assert_float(card.get_global_rect().position.y).is_greater_equal(0.0)
	Input.action_release(InputActions.JOKER_MENU)
	await _runner.simulate_frames(2, 17)


## Two players share the bottom edge as they always have.
func test_two_hands_stand_on_the_bottom_edge() -> void:
	var match_node := await _start_match(2)
	for index: int in match_node.hud._hands:
		var hand: JokerHand = match_node.hud._hands[index]
		assert_int(hand.corner).is_equal(-1)
		assert_bool(hand.hangs()).is_false()
		for card: JokerCard in hand._cards:
			assert_float(_center(card).y).is_greater(hand.size.y * 0.75)


## A top player's pick comes up in their corner, under their hand, with the pane under the cards.
func test_a_top_players_pick_stacks_down_from_their_hand() -> void:
	var match_node := await _start_match(4)
	var slot := match_node.slots[0]
	slot.kart.die(&"pit", -1)
	await _runner.simulate_frames(2, 17)
	var choices: Array[Joker] = []
	for id: String in ["big_tank", "toll_booth", "road_rage"]:
		choices.append(load("res://data/jokers/%s.tres" % id))
	slot.offer = JokerOffer.new(slot.kart, choices)
	slot.offer.selected = 1
	slot.respawn_left = 30.0
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var hand: JokerHand = hud._hands[0]
	var picker: JokerPicker = hud._pickers[0]
	assert_bool(picker.visible).is_true()
	var screen := picker.size
	var lowest := 0.0
	for card: JokerCard in picker._cards:
		var face := card.get_global_rect()
		assert_float(face.position.y).is_greater(hand.reach())
		assert_float(_center(card).x).is_less(screen.x * 0.5)
		assert_float(_center(card).y).is_less(screen.y * 0.5)
		lowest = maxf(lowest, face.end.y)
	assert_float(picker._detail.get_global_rect().position.y).is_greater(lowest)
