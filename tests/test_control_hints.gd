extends GdUnitTestSuite
## On-screen control hints, GAME.md 8.3: which button is named, when it is worth naming, and
## whether it is named as a key or as a gamepad button.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner
var _hints_were := true


func before_test() -> void:
	_hints_were = Game.settings.control_hints
	Game.settings.control_hints = true


func after_test() -> void:
	Game.settings.control_hints = _hints_were


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 47)
	return match_node


func test_a_pinned_device_names_its_own_scheme_and_any_follows_the_last_touched() -> void:
	assert_bool(DeviceInput.uses_keyboard(DeviceInput.KEYBOARD)).is_true()
	assert_bool(DeviceInput.uses_keyboard(0)).is_false()
	var was := Game.last_input_keyboard
	Game.last_input_keyboard = true
	assert_bool(DeviceInput.uses_keyboard(DeviceInput.ANY)).is_true()
	Game.last_input_keyboard = false
	assert_bool(DeviceInput.uses_keyboard(DeviceInput.ANY)).is_false()
	# A real push on a stick counts as picking the pad up; a twitch does not.
	Game.last_input_keyboard = true
	var twitch := InputEventJoypadMotion.new()
	twitch.axis = JOY_AXIS_LEFT_X
	twitch.axis_value = 0.2
	Game._input(twitch)
	assert_bool(Game.last_input_keyboard).is_true()
	twitch.axis_value = 0.9
	Game._input(twitch)
	assert_bool(Game.last_input_keyboard).is_false()
	var key := InputEventKey.new()
	key.keycode = KEY_W
	Game._input(key)
	assert_bool(Game.last_input_keyboard).is_true()
	Game.last_input_keyboard = was


func test_each_hint_shows_only_while_it_is_worth_pressing() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var block: Dictionary = hud._blocks[0]
	var label: Label = block["hints"]
	var kart := match_node.kart_of(0)
	# Parked, full tank, empty hands: only the nitro reminder is worth showing.
	kart.motor.velocity = Vector3.ZERO
	kart.nitro_charge = 1.0
	kart.held_item = null
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_bool(label.visible).is_true()
	assert_str(label.text).contains("nitro")
	assert_str(label.text).not_contains("drift")
	assert_str(label.text).not_contains("item")
	# An empty tank takes its reminder away again.
	kart.nitro_charge = 0.0
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_bool(label.visible).is_false()
	# Up to speed with an item in hand: both of those show instead.
	kart.motor.velocity = Vector3(kart.stats.top_speed, 0.0, 0.0)
	kart.held_item = load("res://data/powerups/boost.tres")
	kart.item_reveal_left = 0.0
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_str(label.text).contains("drift")
	assert_str(label.text).contains("item")
	# An item still rolling in the roulette cannot be played yet.
	kart.item_reveal_left = 0.4
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_str(label.text).not_contains("item")
	# The setting puts the whole row away.
	Game.settings.control_hints = false
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_bool(label.visible).is_false()


func test_hints_are_named_for_the_scheme_in_use() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var block: Dictionary = hud._blocks[0]
	var label: Label = block["hints"]
	var kart := match_node.kart_of(0)
	kart.nitro_charge = 1.0
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	var keys := label.text
	hud._update_hints(block, kart, 0)
	assert_str(label.text).is_not_equal(keys)
	assert_str(keys).contains(InputActions.short_binding_text(InputActions.NITRO, true))
	assert_str(label.text).contains(InputActions.short_binding_text(InputActions.NITRO, false))


func test_the_joker_menu_cap_shows_beside_a_hand_with_cards_in_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hand: JokerHand = match_node.hud._hands[0]
	var kart := match_node.kart_of(0)
	assert_bool(hand._cap.visible).is_false()
	kart.jokers.add(load("res://data/jokers/big_tank.tres"))
	await _runner.simulate_frames(4, 17)
	assert_bool(hand._cap.visible).is_true()
	assert_str(hand._cap_label.text).is_equal(
		InputActions.short_binding_text(InputActions.JOKER_MENU, hand.keyboard)
	)
	# It sits to the left of the leftmost card.
	assert_float(hand._cap.position.x).is_less(hand._cards[0].position.x)
	Game.settings.control_hints = false
	await _runner.simulate_frames(4, 17)
	assert_bool(hand._cap.visible).is_false()
