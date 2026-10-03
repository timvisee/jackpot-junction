extends GdUnitTestSuite
## The jokers by mouse, GAME.md 3.7: over a card of the pick its cursor goes there and a click takes
## it; over a card of the hand it opens, a click keeps it open with a drop and a destroy button on
## its pane, and a click on it again, or anywhere else, closes it.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _was_touch := false
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_was_touch = TouchInput.enabled
	TouchInput.enabled = false


func after_test() -> void:
	TouchInput.enabled = _was_touch
	TouchInput.release()
	get_tree().paused = false


## A match with a player on the keyboard and the mouse, holding [param jokers].
func _playing(jokers: Array[String] = []) -> MouseJokers:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, -1), KartInput.new()]
	match_node.start(inputs, 5)
	for id: String in jokers:
		match_node.kart_of(0).jokers.add(load("res://data/jokers/%s.tres" % id))
	await _runner.simulate_frames(20, 17)
	var mouse: MouseJokers = match_node.hud.get_node("MouseJokers")
	# Pointed here by the test rather than by wherever a headless run's mouse happens to sit.
	mouse.set_process(false)
	mouse._moved = true
	return mouse


## The pointer over [param at] for a few ticks, as it would be over the frames it rested there.
func _rest(mouse: MouseJokers, at: Vector2, frames := 4) -> void:
	for i: int in frames:
		mouse.point(mouse.match_node.slots[0], at)
		await _runner.simulate_frames(1, 17)


func _click(mouse: MouseJokers, at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	mouse._input(click)


static func _center(card: Control) -> Vector2:
	return card.get_global_rect().get_center()


func test_the_mouse_reads_a_card_of_the_hand_keeps_it_open_and_drops_it() -> void:
	var mouse := await _playing(["hair_trigger", "rubber_bumpers", "curve_ball"])
	var kart := mouse.match_node.kart_of(0)
	var hand: JokerHand = mouse.match_node.hud._hands[0]
	var far := hand.get_global_rect().size * Vector2(0.5, 0.3)
	# Over a card it opens, pane and all, and off it closes again.
	await _rest(mouse, _center(hand._cards[1]))
	assert_bool(kart.menu_open).is_true()
	assert_int(kart.menu_index).is_equal(1)
	assert_bool(hand._detail.visible).is_true()
	await _rest(mouse, far)
	assert_bool(kart.menu_open).is_false()
	# Clicked, it stays open with the pointer gone, a button each for dropping and destroying it.
	await _rest(mouse, _center(hand._cards[1]))
	_click(mouse, _center(hand._cards[1]))
	await _rest(mouse, far)
	assert_bool(kart.menu_open).is_true()
	assert_int(kart.menu_index).is_equal(1)
	assert_int(hand.touch_buttons().size()).is_equal(2)
	var drop: Button = hand.touch_buttons()[&"drop"]
	_click(mouse, _center(drop))
	await _rest(mouse, far)
	assert_int(kart.jokers.count()).is_equal(2)
	assert_bool(kart.jokers.ids().has(&"rubber_bumpers")).is_false()
	assert_bool(kart.menu_open).is_false()
	# Kept open again, a click on it closes it, and so does one anywhere else.
	await _rest(mouse, _center(hand._cards[0]))
	_click(mouse, _center(hand._cards[0]))
	_click(mouse, _center(hand._cards[0]))
	await _rest(mouse, far)
	assert_bool(kart.menu_open).is_false()
	await _rest(mouse, _center(hand._cards[0]))
	_click(mouse, _center(hand._cards[0]))
	_click(mouse, far)
	await _rest(mouse, far)
	assert_bool(kart.menu_open).is_false()


## The pause key puts a card kept open away before it would pause the match, and the pane says
## so; with no card kept open it pauses as it always has.
func test_the_pause_key_closes_a_card_kept_open_before_it_pauses() -> void:
	var mouse := await _playing(["hair_trigger", "rubber_bumpers"])
	var menu := PauseMenu.add_to(mouse.match_node)
	var kart := mouse.match_node.kart_of(0)
	var hand: JokerHand = mouse.match_node.hud._hands[0]
	var far := hand.get_global_rect().size * Vector2(0.5, 0.3)
	await _rest(mouse, _center(hand._cards[1]))
	_click(mouse, _center(hand._cards[1]))
	await _rest(mouse, far)
	assert_bool(kart.menu_open).is_true()
	var said := hand._detail.find_children("*", "Label", true, false).map(
		func(label: Label) -> String: return label.text
	)
	assert_array(said).contains(["to close it"])
	_press_pause(mouse)
	await _rest(mouse, far)
	assert_bool(kart.menu_open).is_false()
	assert_bool(menu.is_open()).is_false()
	_press_pause(mouse)
	assert_bool(menu.is_open()).is_true()


func _press_pause(mouse: MouseJokers) -> void:
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.physical_keycode = KEY_ESCAPE
		key.pressed = down
		mouse.get_viewport().push_input(key)


## A mouse nobody has moved is not pointing at anything, wherever it was left lying.
func test_a_mouse_that_has_not_moved_opens_nothing() -> void:
	var mouse := await _playing(["hair_trigger", "rubber_bumpers"])
	mouse._moved = false
	var kart := mouse.match_node.kart_of(0)
	var hand: JokerHand = mouse.match_node.hud._hands[0]
	await _rest(mouse, _center(hand._cards[1]))
	assert_bool(kart.menu_open).is_false()
	mouse._input(InputEventMouseMotion.new())
	await _rest(mouse, _center(hand._cards[1]))
	assert_bool(kart.menu_open).is_true()


func test_the_mouse_moves_the_pick_to_a_card_and_a_click_takes_it() -> void:
	var mouse := await _playing()
	var slot := mouse.match_node.slots[0]
	slot.kart.die(&"pit", -1)
	await _runner.simulate_frames(2, 17)
	var choices: Array[Joker] = []
	for id: String in ["hair_trigger", "rubber_bumpers", "curve_ball"]:
		choices.append(load("res://data/jokers/%s.tres" % id))
	slot.offer = JokerOffer.new(slot.kart, choices)
	slot.offer.answer_at = 0.0
	slot.respawn_left = 30.0
	await _runner.simulate_frames(4, 17)
	var offer := slot.offer
	var picker: JokerPicker = mouse.match_node.hud._pickers[0]
	assert_bool(picker.visible).is_true()
	await _rest(mouse, _center(picker._cards[2]))
	assert_int(offer.selected).is_equal(2)
	assert_bool(offer.is_done()).is_false()
	_click(mouse, _center(picker._cards[1]))
	await _runner.simulate_frames(3, 17)
	assert_bool(offer.is_done()).is_true()
	assert_str(String(offer.taken.id)).is_equal("rubber_bumpers")


## Off a touch screen the pick has its skip button too, GAME.md 8.3, with the key that skips in it
## and the word beside it, rather than skipping as small print in the pane; a click on it skips.
func test_the_pick_has_a_skip_button_with_its_key_on_it() -> void:
	var mouse := await _playing()
	var slot := mouse.match_node.slots[0]
	slot.kart.die(&"pit", -1)
	await _runner.simulate_frames(2, 17)
	var choices: Array[Joker] = []
	for id: String in ["hair_trigger", "rubber_bumpers"]:
		choices.append(load("res://data/jokers/%s.tres" % id))
	slot.offer = JokerOffer.new(slot.kart, choices)
	slot.offer.answer_at = 0.0
	slot.respawn_left = 30.0
	await _runner.simulate_frames(4, 17)
	var offer := slot.offer
	var picker: JokerPicker = mouse.match_node.hud._pickers[0]
	var skip := picker.skip_button()
	assert_object(skip).is_not_null()
	assert_str(skip.text).is_empty()
	var keys: Control = skip.get_node_or_null("Keys")
	assert_object(keys).is_not_null()
	var glyphs := keys.find_children("*", "InputGlyph", true, false)
	assert_int(glyphs.size()).is_equal(1)
	assert_str((glyphs[0] as InputGlyph).caption).is_equal("Q")
	var words := ""
	for label: Node in keys.find_children("*", "Label", true, false):
		words += (label as Label).text
	assert_str(words).contains("Skip")
	# The pane says how to choose and take, and leaves skipping to the button.
	var pane_words := ""
	for label: Node in picker._detail.find_children("*", "Label", true, false):
		pane_words += (label as Label).text
	assert_str(pane_words).not_contains("skip")
	assert_float(skip.size.x).is_greater_equal(keys.size.x)
	_click(mouse, skip.get_global_rect().get_center())
	await _runner.simulate_frames(3, 17)
	assert_bool(offer.is_done()).is_true()
	assert_object(offer.taken).is_null()
