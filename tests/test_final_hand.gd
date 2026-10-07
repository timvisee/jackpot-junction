extends GdUnitTestSuite
## The story's Final Hand, STORY.md 8: when the House offers it and the table it sets, the locked
## settings, CANDIDATE where the House prints names and nowhere else, the models, the house
## watching, and the whistle lit for the candidate.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")

var _runner: GdUnitSceneRunner
var _was_story := StoryState.new()
var _was_number := ""
var _was_map := ""


func before_test() -> void:
	var profile := Game.settings.profile
	_was_story = profile.story
	_was_number = profile.license_number
	_was_map = Game.settings.map
	profile.story = StoryState.new()
	profile.license_number = "JJ-212212"


func after_test() -> void:
	var profile := Game.settings.profile
	profile.story = _was_story
	profile.license_number = _was_number
	Game.settings.map = _was_map
	Story.override = -1
	Story.final_hand_on = false
	Story.final_hand_now = false
	FinalHand.declined = false


## Offered once the clock reaches it, licensed and with the story on, until it is played or put off
## for the session.
func test_it_is_offered_only_when_due() -> void:
	Story.override = Story.Stage.CANDIDATE
	var profile := Game.settings.profile
	profile.story.seconds = Story.FINAL_HAND_AT - 1.0
	assert_bool(FinalHand.offered(profile)).is_false()
	profile.story.seconds = Story.FINAL_HAND_AT
	assert_bool(FinalHand.offered(profile)).is_true()
	profile.story.on = false
	assert_bool(FinalHand.offered(profile)).is_false()
	profile.story.on = true
	FinalHand.declined = true
	assert_bool(FinalHand.offered(profile)).is_false()
	FinalHand.declined = false
	profile.story.final_hand = "2026-10-07"
	assert_bool(FinalHand.offered(profile)).is_false()
	profile.story.final_hand = ""
	# While it is due, the House's flyer points at Play, STORY.md 8.1.
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var ad: HouseAd = title.find_child("HouseAd", true, false)
	assert_object(ad).is_not_null()
	assert_str(ad.headline.text).is_equal("YOUR TABLE IS READY")
	profile.license_number = ""
	assert_bool(FinalHand.offered(profile)).is_false()


## Take your seat sets the House's table, shown in the settings and not to be changed, under its
## stamp; the lobby's own choices are left as they were.
func test_the_house_sets_the_table_and_locks_it() -> void:
	var config := MatchConfig.new()
	FinalHand.set_table(config, "hard")
	assert_bool(config.final_hand).is_true()
	assert_str(String(config.map)).is_equal("house_rules")
	assert_int(config.rounds).is_equal(0)
	assert_float(config.duration).is_equal(300.0)
	assert_int(config.target_score).is_equal(MatchConfig.new().target_score)
	assert_str(config.difficulty).is_equal("hard")
	assert_str(config.item_set).is_equal("all")
	assert_int(config.bot_count).is_equal(3)
	assert_dict(MatchOptions.to_wire(config)).not_contains_keys(["final_hand"])
	Game.settings.map = "vault"
	var pane: HostSettings = auto_free(HostSettings.add_to(self, true))
	await await_idle_frame()
	pane.set_by_the_house(config)
	pane.open()
	assert_bool(pane.options.map_option.disabled).is_true()
	assert_bool(pane.options.bots_option.disabled).is_true()
	assert_bool(pane.options.mode_picker.locked).is_true()
	assert_object(pane.find_child("SetByTheHouse", true, false)).is_not_null()
	var shown := MatchConfig.new()
	pane.options.apply_to(shown)
	assert_str(String(shown.map)).is_equal("house_rules")
	assert_int(shown.bot_count).is_equal(3)
	assert_float(shown.duration).is_equal(300.0)
	pane.close()
	assert_str(Game.settings.map).is_equal("vault")


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 300.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0)]
	for i: int in 3:
		inputs.append(BotInput.new())
	match_node.start(inputs, 41)
	return match_node


## CANDIDATE where the House prints a name, for the candidate's seat alone, and only at the Final
## Hand; the models after the player, in the player's dress, driving on the player's habits; the
## house watching the candidate; and at the whistle the board naming the candidate.
func test_the_table_is_the_houses() -> void:
	Story.final_hand_on = true
	var profile := Game.settings.profile
	profile.stats[&"items"] = 120.0
	profile.stats[&"seconds"] = 3600.0
	var match_node := _start_match()
	var table := FinalHandTable.add_to(match_node)
	await _runner.simulate_frames(10, 17)
	var candidate := match_node.slots[0]
	assert_str(FinalHand.name_of(candidate)).is_equal("CANDIDATE")
	assert_object(FinalHand.candidate(match_node)).is_same(candidate)
	var named := StoryFill.written_name(profile)
	for i: int in range(1, 4):
		var model := match_node.slots[i]
		assert_str(FinalHand.name_of(model)).is_equal("%s %d" % [named, i + 1])
		assert_array(Array(model.style.to_array())).is_equal(Array(Game.settings.seat_style(0)))
	assert_bool(match_node.bot_mirror.held).is_true()
	assert_float(match_node.bot_mirror.items).is_equal_approx(120.0 / 60.0 / 3.0, 0.001)
	assert_object(match_node.arena.crowd._watched).is_same(candidate.kart)
	var board: LedClock = match_node.find_children("*", "LedClock", true, false)[0]
	assert_str(board._winner()).is_equal("CANDIDATE")
	MatchEnd.spotlight(match_node)
	assert_object(match_node.arena.disco._focus).is_same(candidate.kart)
	table.queue_free()
	await await_idle_frame()
	# Over, it is a name again.
	assert_bool(Story.final_hand_on).is_false()
	assert_str(FinalHand.name_of(candidate)).is_equal(candidate.display_name())
