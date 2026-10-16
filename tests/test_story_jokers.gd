extends GdUnitTestSuite
## The story on the jokers, STORY.md 6.3: a line of the House's small print under the pick from the
## second stage, TERMS ACCEPTED as a card is taken from the third, and the term every card is under
## its effect. What a card does is never touched.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func after_test() -> void:
	Story.override = -1
	Story.final_hand_on = false


func _start_match() -> Match:
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
	match_node.start([PlayerInput.new(), KartInput.new()] as Array[KartInput], 21)
	return match_node


func _offer(match_node: Match) -> JokerOffer:
	var slot := match_node.slots[0]
	var choices: Array[Joker] = []
	for id: String in ["big_tank", "payday", "road_rage"]:
		choices.append(load("res://data/jokers/%s.tres" % id))
	slot.offer = JokerOffer.new(match_node.kart_of(0), choices)
	slot.respawn_left = 30.0
	return slot.offer


## Nothing under the pick at the first stage; the stage's line after it, filled in; the
## candidate's at the Final Hand.
func test_the_pick_says_the_stage_terms() -> void:
	Story.override = Story.Stage.CUSTOMER
	assert_str(JokerPicker.terms_line()).is_empty()
	Story.override = Story.Stage.PLAYER
	assert_str(JokerPicker.terms_line()).is_equal("NEW TERMS AVAILABLE")
	Story.override = Story.Stage.NUMBER
	assert_str(JokerPicker.terms_line()).starts_with("TERMS DEALT TO ")
	assert_bool(JokerPicker.terms_line().contains("{")).is_false()
	Story.override = Story.Stage.OPERATOR
	assert_str(JokerPicker.terms_line()).is_equal("STAFF TERMS")
	Story.final_hand_on = true
	assert_str(JokerPicker.terms_line()).is_equal("CANDIDATE TERMS")


## A card's pane carries its term from the second stage and not before, under its effect.
func test_a_card_says_its_term_from_the_second_stage() -> void:
	var payday: Joker = load("res://data/jokers/payday.tres")
	var pane: JokerDetail = auto_free(JokerDetail.new())
	add_child(pane)
	Story.override = Story.Stage.PLAYER
	pane.show_joker(payday)
	var term: Label = pane.find_child("Term", true, false)
	assert_bool(term.visible).is_false()
	Story.override = Story.Stage.PARTICIPANT
	pane.show_joker(payday)
	assert_bool(term.visible).is_true()
	assert_str(term.text).is_equal("Formerly a day of the month.")
	assert_str(pane._body.text).is_not_empty()


## Taking a card from the first stage on leaves TERMS ACCEPTED where the line was as the pick
## goes; skipping one says nothing, and neither does a take before the first stage.
func test_taking_a_card_accepts_the_terms() -> void:
	Story.override = Story.Stage.PLAYER
	var match_node := _start_match()
	await _runner.simulate_frames(6, 17)
	var offer := _offer(match_node)
	await _runner.simulate_frames(4, 17)
	var picker: JokerPicker = match_node.hud._pickers[0]
	assert_bool(picker.visible).is_true()
	var line: Label = picker.find_child("Terms", true, false)
	assert_bool(line.visible).is_true()
	offer.answer_at = 0.0
	offer.take(1)
	await _runner.simulate_frames(2, 17)
	assert_bool(picker.visible).is_false()
	var said: Label = picker.get_parent().find_child("TermsAccepted", false, false)
	assert_object(said).is_not_null()
	assert_str(said.text).is_equal("TERMS ACCEPTED")
	await _runner.simulate_frames(70, 17)
	assert_object(picker.get_parent().find_child("TermsAccepted", false, false)).is_null()
	# Skipped, nothing is accepted.
	var skipped := _offer(match_node)
	await _runner.simulate_frames(4, 17)
	skipped.skip()
	await _runner.simulate_frames(2, 17)
	assert_object(picker.get_parent().find_child("TermsAccepted", false, false)).is_null()
	# And before the first stage a take says nothing.
	Story.override = Story.Stage.CUSTOMER
	var early := _offer(match_node)
	await _runner.simulate_frames(4, 17)
	early.answer_at = 0.0
	early.take(0)
	await _runner.simulate_frames(2, 17)
	assert_object(picker.get_parent().find_child("TermsAccepted", false, false)).is_null()
