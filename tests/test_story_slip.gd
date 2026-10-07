extends GdUnitTestSuite
## What the story prints on the payout slip, STORY.md 6.2: the small print and the heading by
## stage, the House's bulletin with the player's own numbers, never one naming a trait nobody was
## dealt, and the line under a player's own line saying how the House classified them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func after_test() -> void:
	Story.override = -1


func _slot_with(trait_path: String) -> PlayerSlot:
	var slot := PlayerSlot.new(1, KartInput.new())
	slot.bot_trait = load(trait_path)
	return slot


## The small print and the heading move with the stage.
func test_the_small_print_and_the_heading_by_stage() -> void:
	var profile := Profile.new()
	profile.license_number = "JJ-246810"
	assert_str(StorySlip.small_print(Story.Stage.CUSTOMER, profile)).is_equal(
		ResultsScreen.SMALL_PRINT
	)
	assert_str(StorySlip.small_print(Story.Stage.PLAYER, profile)).contains("NOT WAGES")
	assert_str(StorySlip.small_print(Story.Stage.NUMBER, profile)).contains("JJ-246810")
	assert_str(StorySlip.small_print(Story.Stage.OPERATOR, profile)).starts_with("SHIFT COMPLETE")
	assert_str(StorySlip.heading(Story.Stage.CANDIDATE)).is_equal("Payout slip")
	assert_str(StorySlip.heading(Story.Stage.OPERATOR)).is_equal("Payslip")


## No bulletin before the second stage; a bulletin naming a trait only when a bot of that trait
## was at the table, and then that trait; never the same bulletin twice running.
func test_the_bulletin_names_only_a_trait_that_was_dealt() -> void:
	var profile := Profile.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var nobody: Array[PlayerSlot] = [PlayerSlot.new(0, KartInput.new())]
	assert_str(StorySlip.bulletin(Story.Stage.PLAYER, profile, nobody, rng)).is_empty()
	var last := ""
	for i: int in 60:
		var said := StorySlip.bulletin(Story.Stage.NUMBER, profile, nobody, rng)
		assert_bool(said.contains("WAS DEALT TO YOUR TABLE")).is_false()
		assert_bool(said.contains("{")).is_false()
		assert_str(said).is_not_equal(last)
		last = said
	var hunted: Array[PlayerSlot] = [
		PlayerSlot.new(0, KartInput.new()), _slot_with("res://data/ai/traits/hunter.tres")
	]
	var dealt := false
	for i: int in 60:
		var said := StorySlip.bulletin(Story.Stage.NUMBER, profile, hunted, rng)
		if said.contains("WAS DEALT TO YOUR TABLE"):
			dealt = true
			assert_str(said).starts_with("A HUNTER WAS DEALT")
	assert_bool(dealt).is_true()


## The classification leans where the match's numbers lean, and nothing much is Balanced.
func test_a_match_is_classified_by_its_numbers() -> void:
	var minute := 60.0
	var hunter := PlayerStats.new()
	assert_str(StorySlip.classify(hunter, 3, minute)).is_equal("HUNTER")
	var bumper := PlayerStats.new()
	bumper.add(&"rams", 4.0)
	assert_str(StorySlip.classify(bumper, 0, minute)).is_equal("BUMPER")
	var grazer := PlayerStats.new()
	grazer.add(&"grazes", 12.0)
	assert_str(StorySlip.classify(grazer, 0, minute)).is_equal("GRAZER")
	var greedy := PlayerStats.new()
	greedy.peak(&"biggest_bank", 900.0)
	assert_str(StorySlip.classify(greedy, 0, minute)).is_equal("GREEDY")
	var cautious := PlayerStats.new()
	cautious.add(&"banks", 3.0)
	cautious.peak(&"biggest_bank", 90.0)
	assert_str(StorySlip.classify(cautious, 0, minute)).is_equal("CAUTIOUS")
	assert_str(StorySlip.classify(PlayerStats.new(), 0, minute)).is_equal("BALANCED")
	(
		assert_str(StorySlip.classified(Story.Stage.PARTICIPANT, PlayerSlot.new(0, null), 60.0))
		. is_empty()
	)


## On the slip itself: the stage's small print at the foot, the bulletin under it, and the House's
## classification under the line of the player at this screen and nobody else's.
func test_the_slip_carries_the_story() -> void:
	Story.override = Story.Stage.NUMBER
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.overtime = false
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([PlayerInput.new(), KartInput.new()] as Array[KartInput], 31, [], ["Ada"])
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	match_node.hud._podium_wait = 0.0
	await _runner.simulate_frames(2, 17)
	var screen: ResultsScreen = match_node.hud._results
	screen.fill_in()
	var small: Label = screen.find_child("SmallPrint", true, false)
	assert_str(small.text).contains("PROFILE")
	var bulletin: Label = screen.find_child("Bulletin", true, false)
	assert_bool(bulletin.visible).is_true()
	var marked := screen.find_children("Classified", "Label", true, false)
	assert_int(marked.size()).is_equal(1)
	assert_str((marked[0] as Label).text).starts_with("CLASSIFIED: ")
	assert_str(screen._title.text).is_equal("Payout slip")
	Story.override = Story.Stage.OPERATOR
	screen.fill_in()
	assert_str(screen._title.text).is_equal("Payslip")
