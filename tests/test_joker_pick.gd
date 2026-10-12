extends GdUnitTestSuite
## The respawn joker pick of GAME.md 3.7 and 8.3 on the screen: the hand of cards read over it, and
## how it is turned down.

const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 21)
	return match_node


## Holding the hand of cards open over a pick reads the hand instead, GAME.md 3.7: the pick takes
## nothing, skips nothing and walks nowhere while it is held, and steps aside on the screen; let go,
## it is back as it was.
func test_holding_the_hand_open_over_a_pick_reads_the_hand() -> void:
	var match_node := _start_match()
	var kart := match_node.kart_of(0)
	kart.jokers.add(CATALOG.jokers[0])
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	offer.answer_at = 0.0
	var input := KartInput.new()
	input.joker_menu = true
	input.cursor = 1.0
	input.fire_pressed = true
	input.joker_destroy_pressed = true
	offer.poll_input(input)
	assert_int(offer.selected).is_equal(0)
	assert_int(offer.stage).is_equal(JokerOffer.Stage.CHOOSING)
	var picker: JokerPicker = auto_free(JokerPicker.new())
	add_child(picker)
	await await_idle_frame()
	picker.size = Vector2(1920.0, 1080.0)
	kart.menu_open = true
	picker.show_offer(offer, kart)
	assert_bool(picker.aside).is_true()
	assert_bool(picker.visible).is_false()
	kart.menu_open = false
	picker.show_offer(offer, kart)
	assert_bool(picker.visible).is_true()
	# Let go, the pick answers again, the stick held over as the hand was let go stepping nothing.
	input.joker_menu = false
	input.fire_pressed = false
	input.joker_destroy_pressed = false
	offer.poll_input(input)
	assert_int(offer.selected).is_equal(0)
	input.cursor = 0.0
	offer.poll_input(input)
	input.cursor = 1.0
	offer.poll_input(input)
	assert_int(offer.selected).is_equal(1)


## Skipping is a chip at the end of the pane's hint row off a touch screen, GAME.md 8.3: its key and
## its word as small as the hints beside it, rather than a button of its own under the pane.
func test_skipping_is_a_chip_in_the_pane() -> void:
	var match_node := _start_match()
	var kart := match_node.kart_of(0)
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	var picker: JokerPicker = auto_free(JokerPicker.new())
	add_child(picker)
	await await_idle_frame()
	picker.size = Vector2(1920.0, 1080.0)
	picker.show_offer(offer, kart)
	await await_idle_frame()
	var chip := picker.skip_button()
	assert_object(chip).is_not_null()
	assert_bool(picker._detail.is_ancestor_of(chip)).is_true()
	assert_float(chip.size.y).is_less(40.0)
	var pane := picker._detail.get_global_rect()
	assert_bool(pane.encloses(chip.get_global_rect())).is_true()
