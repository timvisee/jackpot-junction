extends GdUnitTestSuite
## A bot's driver license, GAME.md 9.4a: made up at each screen from the bot's name, trait, color
## and dress, the same for the same bot; none for a learner, nor for anybody but a bot; a card of
## its own, Class B on gray stock, signed AUTOMATED; the House's MODEL stamp on its back once the
## mirror's note is read, STORY.md 3.6; at the Final Hand a model's card the player's own; and the
## payout slip's robot holding it up, 3.8.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const TRAITS: BotTraitTable = preload("res://data/ai/traits.tres")

var _kept: Profile
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_kept = Game.settings.profile
	Game.settings.profile = Profile.new()


func after_test() -> void:
	Game.settings.profile = _kept
	Story.override = -1
	Story.final_hand_on = false


func _bot(named: String, trait_id := &"hunter") -> PlayerSlot:
	var slot := PlayerSlot.new(2, BotInput.new(), 3)
	slot.bot_trait = TRAITS.by_id(trait_id)
	slot.player_name = named
	return slot


func test_a_bot_holds_one_of_its_own() -> void:
	var holder := BotLicense.of(_bot("Rusty Bolts"))
	assert_bool(holder["bot"]).is_true()
	assert_str(str(holder["name"])).is_equal("Rusty Bolts")
	assert_array(Array(holder["earned"])).contains_exactly(["HUNTER"])
	assert_int(int(holder["color"])).is_equal(3)
	var serial := RegEx.create_from_string("^B-\\d{4}-\\d{4}$")
	assert_object(serial.search(str(holder["number"]))).is_not_null()
	assert_int(str(holder["issued"]).left(4).to_int()).is_between(
		BotLicense.FIRST_YEAR, BotLicense.LAST_YEAR
	)
	# The same bot the same card, wherever it is looked at; another bot another.
	assert_dict(BotLicense.of(_bot("Rusty Bolts"))).is_equal(holder)
	assert_str(str(BotLicense.of(_bot("Clanker"))["number"])).is_not_equal(str(holder["number"]))
	# Nothing of the story before the mirror is read.
	assert_array(Array(holder["stamps"])).is_empty()


func test_nobody_but_a_bot_holds_one_this_way() -> void:
	assert_dict(BotLicense.of(PlayerSlot.new(0, PlayerInput.new()))).is_empty()
	assert_dict(BotLicense.of(PlayerSlot.new(1, DummyInput.new()))).is_empty()
	assert_dict(BotLicense.of(null)).is_empty()


func test_the_card_of_a_bot() -> void:
	var card: LicenseCard = auto_free(LicenseCard.for_bot(BotLicense.of(_bot("Rusty Bolts"))))
	assert_bool(card.bot).is_true()
	assert_str(card.holder_name).is_equal("Rusty Bolts")
	assert_dict(card.endorsements).is_equal({"HUNTER": true})
	# It never sat the test: no PASSED, no examiner, and none of the story's marks.
	assert_bool(card.stamped).is_false()
	assert_str(card.examiner).is_equal(LicenseCard.BOT_EXAMINER)
	assert_bool(card.scratched).is_false()
	assert_str(card.approved).is_empty()
	assert_int(card.cones).is_equal(0)
	assert_str(card.words()).contains("Class B, Bot")


## The mirror's note found but not read yet, nothing; read, the House's MODEL stamp on the back.
func test_the_mirror_read_stamps_it_a_model() -> void:
	Game.settings.license_number = "JJ-123456"
	Story.override = Story.Stage.PARTICIPANT
	var story := Game.settings.profile.story
	story.notes.append(BotLicense.MIRROR_NOTE)
	assert_array(Array(BotLicense.of(_bot("Rusty Bolts"))["stamps"])).is_empty()
	story.notes_read.append(BotLicense.MIRROR_NOTE)
	var stamps: PackedStringArray = BotLicense.of(_bot("Rusty Bolts"))["stamps"]
	assert_int(stamps.size()).is_equal(1)
	assert_str(stamps[0]).starts_with("MODEL").ends_with("PARTICIPANTS")
	var card: LicenseCard = auto_free(LicenseCard.for_bot(BotLicense.of(_bot("Rusty Bolts"))))
	assert_array(Array(card.program_stamps)).is_equal(Array(stamps))


## At the Final Hand a model seated as the player carries the player's own license under its name,
## its seat after the number; a bot named otherwise keeps a bot's.
func test_a_model_at_the_final_hand_carries_the_players_own() -> void:
	Game.settings.license_number = "JJ-123456"
	Game.settings.license_holder = "Ann"
	Game.settings.license_endorsements = PackedStringArray(["KO"])
	Story.final_hand_on = true
	var model := _bot("Ann 2")
	var holder := BotLicense.of(model)
	assert_bool(holder.has("bot")).is_false()
	assert_str(str(holder["name"])).is_equal("Ann 2")
	assert_str(str(holder["number"])).is_equal("JJ-123456-2")
	assert_int(int(holder["color"])).is_equal(model.paint_index())
	var card: LicenseCard = auto_free(LicenseCard.from_wire(holder))
	assert_bool(card.bot).is_false()
	assert_bool(card.endorsements["KO"]).is_true()
	assert_bool(BotLicense.of(_bot("Annie"))["bot"]).is_true()
	Story.final_hand_on = false
	assert_bool(BotLicense.of(_bot("Ann 2"))["bot"]).is_true()


func _finished_match() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.overtime = false
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), BotInput.new(), BotInput.new()]
	match_node.start(inputs, 31, [], ["Ada"])
	return match_node


## A learner bot, with the L, has none; the rest hold up theirs from the robot after their name on
## the payout slip, over it.
func test_the_slips_robot_holds_it_up() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	var learner := match_node.slots[2]
	KartVisuals.learner_plate(learner.kart)
	assert_dict(BotLicense.of(learner)).is_empty()
	assert_dict(BotLicense.of(match_node.slots[1])).is_not_empty()
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	match_node.hud._podium_wait = 0.0
	await _runner.simulate_frames(2, 17)
	var screen: ResultsScreen = match_node.hud._results
	var robots: Array[Node] = screen.find_children("Bot", "", true, false)
	assert_int(robots.size()).is_equal(2)
	var held: Array[Node] = robots.filter(func(robot: Node) -> bool: return robot is Button)
	assert_int(held.size()).is_equal(1)
	(held[0] as Button).pressed.emit()
	var view := get_tree().root.find_child("LicenseView", true, false) as LicenseView
	assert_object(view).is_not_null()
	assert_bool(view.card.bot).is_true()
	assert_str(view.card.holder_name).is_equal(match_node.slots[1].display_name())
	view.get_parent().free()
