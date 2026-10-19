extends GdUnitTestSuite
## The choice at the end of the Final Hand, STORY.md 8.4: the House's forecast of the stamp and its
## sums; the page torn off along its perforation, by its tab or the destroy button, noted, counted
## and kept, the slip's ways back and the Final Hand asked for again; the verdict as the stamp
## lands; and what comes after a tear: DUPLICATE, YOUR TABLE IS STILL READY, Kit's note, Not This
## Time and the torn page at the back of the folder.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const PLAYED := preload("res://scenes/match/match_scene.tscn")
const RULES := preload("res://data/match/default.tres")
const DEBUG_SKIP := "Debug: skip to end"

var _runner: GdUnitSceneRunner
var _was_story := StoryState.new()
var _was_number := ""
var _was_achievements: AchievementState


func before_test() -> void:
	var profile := Game.settings.profile
	_was_story = profile.story
	_was_number = profile.license_number
	_was_achievements = profile.achievements
	profile.story = StoryState.new()
	profile.license_number = "JJ-212212"
	profile.achievements = AchievementState.new()


func after_test() -> void:
	var profile := Game.settings.profile
	profile.story = _was_story
	profile.license_number = _was_number
	profile.achievements = _was_achievements
	Story.final_hand_on = false
	FinalHand.seat_index = -1
	Game.pending_config = null


## The Final Hand played to its whistle, due for the profile playing, its slip on the House's page.
func _whistled() -> Array:
	Story.final_hand_on = true
	Game.settings.profile.story.seconds = Story.FINAL_HAND_AT
	var rules: MatchRules = RULES.duplicate()
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
	var table := FinalHandTable.add_to(match_node)
	await _runner.simulate_frames(10, 17)
	match_node._finish()
	await _runner.simulate_frames(5, 17)
	match_node.hud._podium_wait = 0.0
	await _runner.simulate_frames(3, 17)
	var slip: ResultsScreen = match_node.hud._results
	slip.bill.turn_to(slip.bill.page_count() - 1, false)
	await await_millis(int(PayoutBill.TURN * 1000.0) + 250)
	return [match_node, table, slip]


## A debug build's pause menu at the Final Hand blows the whistle at once, with no sudden death to
## play however many are standing, and brings the slip straight up.
func test_a_debug_build_skips_to_the_slip() -> void:
	Game.settings.profile.story.seconds = Story.FINAL_HAND_AT
	var config := MatchConfig.new()
	FinalHand.set_table(config, "easy")
	config.overtime = true
	Game.pending_config = config
	var scene: Node3D = auto_free(PLAYED.instantiate())
	add_child(scene)
	await assert_signal(scene).is_emitted("loaded")
	var match_node: Match = scene.get_node("Match")
	var skip: Button = null
	for found: Node in scene.get_node("PauseMenu").find_children("*", "Button", true, false):
		if (found as Button).text == DEBUG_SKIP:
			skip = found
	assert_object(skip).is_not_null()
	for i: int in 300:
		if match_node.is_running():
			break
		if match_node.state == Match.State.COUNTDOWN:
			match_node.countdown_left = 0.0
		await get_tree().process_frame
	assert_bool(match_node.is_running()).is_true()
	skip.pressed.emit()
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_float(match_node.time_left).is_equal(0.0)
	for i: int in 3:
		await get_tree().process_frame
	assert_bool(match_node.hud._results.visible).is_true()


static func _value(lines: Array, label: String) -> String:
	for line: Array in lines:
		if str(line[0]) == label:
			return str(line[1])
	return ""


## The first time WILL STAMP, as sure as the terms accepted are of those offered; once torn off,
## WILL NOT STAMP, as sure as the tears are of the times the page was answered; each to a decimal.
func test_the_house_forecasts_the_stamp() -> void:
	var profile := Profile.new()
	profile.license_number = "JJ-212212"
	profile.story.invited = true
	profile.story.maps = 30
	profile.story.jokers = 20
	profile.story.declined = 3
	# 52 accepted of 55 offered: (52 + 1) / (55 + 2).
	assert_str(FinalHand.prediction(profile)).is_equal("WILL STAMP  ·  93.0%")
	assert_str(FinalHand.verdict(profile)).ends_with("CORRECT")
	profile.story.tears = 1
	assert_str(FinalHand.prediction(profile)).is_equal("WILL NOT STAMP  ·  66.7%  ·  REVISED")
	profile.story.tears = 2
	assert_str(FinalHand.prediction(profile)).contains("75.0%")
	assert_str(FinalHand.verdict(profile)).is_equal(StoryLines.PREDICTED_WRONG)
	# Never quite sure.
	assert_str(FinalHand.percent(1000, 1000)).is_equal("99.9")


## On the House's page, over STATUS, PREDICTED; and TERMS ACCEPTED out of those offered.
func test_the_page_says_what_it_predicts() -> void:
	var played: Array = await _whistled()
	var table: FinalHandTable = played[1]
	var lines := table.evaluation.lines
	assert_str(_value(lines, "PREDICTED")).starts_with("WILL STAMP")
	assert_str(_value(lines, "TERMS ACCEPTED")).contains(" OF ")
	var labels: Array[String] = []
	for line: Array in lines:
		labels.append(str(line[0]))
	assert_int(labels.find("PREDICTED")).is_equal(labels.find("STATUS") - 1)


## Torn off by its tab: the strip off the slip and falling, noted and counted, kept for the folder,
## Not This Time earned, DECLINED printed under the slip, and the ways on back but for a rematch of
## the House's table; the Final Hand still due.
func test_the_page_torn_off() -> void:
	var played: Array = await _whistled()
	var table: FinalHandTable = played[1]
	var slip: ResultsScreen = played[2]
	var section := table.evaluation
	await _runner.simulate_frames(2, 17)
	assert_bool(section.tab.visible).is_true()
	# Beside the stamp, where the paper tears over STATUS, and Kit's pencil pointing at it.
	var tab_at := section.tab.get_global_rect().get_center()
	var stamp_at := section.stamp.get_global_rect()
	assert_float(absf(tab_at.y - stamp_at.get_center().y)).is_less(stamp_at.size.y)
	assert_float(tab_at.x).is_greater(stamp_at.end.x)
	var tears_at := section.tab.global_position.y + section.tab.tear_at
	assert_float(absf(tears_at - section.strip.global_position.y)).is_less(4.0)
	assert_bool(section.pencil.points_to.is_finite()).is_true()
	var strip := section.strip
	var torn := [false]
	section.torn_off.connect(func() -> void: torn[0] = true)
	var title_was := (section.get_child(0) as Control).get_global_rect().position
	section.tab.pressed.emit()
	var story := Game.settings.profile.story
	assert_bool(torn[0]).is_true()
	assert_int(story.tears).is_equal(1)
	assert_int(story.declined).is_equal(1)
	assert_str(_value(story.torn.get("lines", []), "STATUS")).is_empty()
	assert_bool(story.ended()).is_false()
	assert_bool(Story.final_hand_due(Game.settings.profile)).is_true()
	assert_bool(Game.settings.profile.achievements.has(&"not_this_time")).is_true()
	await _runner.simulate_frames(3, 17)
	# Nothing on the slip moves for it.
	var title_is := (section.get_child(0) as Control).get_global_rect().position
	assert_vector(title_is).is_equal_approx(title_was, Vector2.ONE)
	# The strip off and falling with the tab, STATUS and the stamp with it; the evaluation left on
	# the slip, the paper ending a little under it, torn by hand.
	var torn_page := slip.find_child("TornPage", true, false) as TornPage
	assert_object(torn_page).is_not_null()
	assert_bool(is_instance_valid(strip)).is_false()
	assert_object(torn_page.find_child("TearTab", false, false)).is_not_null()
	assert_bool(section.tab == null).is_true()
	assert_int(slip.bill.page_count()).is_equal(2)
	assert_bool(slip._end.visible).is_false()
	assert_bool(slip.bill.cut_last).is_true()
	var paper := slip.bill.paper.get_theme_stylebox(&"panel") as TicketStyle
	assert_bool(paper.foot_by_hand).is_true()
	assert_bool(slip._lobby.visible).is_true()
	assert_bool(slip._quit.visible).is_true()
	assert_bool(slip._rematch.visible).is_false()
	# The House's note of it stamped over the evaluation only once the strip has gone off the
	# screen, and the slip none the longer for it.
	assert_object(section.find_child("Declined", true, false)).is_null()
	var paper_was := slip.bill.paper.size.y
	await await_millis(int(TornPage.LONGEST * 1000.0) + 500)
	assert_object(slip.find_child("TornPage", true, false)).is_null()
	var noted := section.find_child("Declined", true, false) as NotedStamp
	assert_object(noted).is_not_null()
	assert_str(noted.said()).is_equal(StoryLines.EVALUATION_DECLINED)
	assert_float(slip.bill.paper.size.y).is_equal_approx(paper_was, 0.5)


## The destroy button tears it off as well, while the page is in view; and once torn, the stamp
## does nothing more.
func test_the_destroy_button_tears_it() -> void:
	var played: Array = await _whistled()
	var table: FinalHandTable = played[1]
	var section := table.evaluation
	var destroy := InputEventAction.new()
	destroy.action = InputActions.JOKER_DESTROY
	destroy.pressed = true
	section._unhandled_input(destroy)
	assert_bool(section.torn).is_true()
	assert_int(Game.settings.profile.story.tears).is_equal(1)
	section.tear_off()
	assert_int(Game.settings.profile.story.tears).is_equal(1)


## Stamped after a tear, the House's forecast was wrong, and it says so as the stamp lands; the
## torn page and the stamped slip both kept.
func test_the_verdict_as_the_stamp_lands() -> void:
	Game.settings.profile.story.tears = 1
	Game.settings.profile.story.torn = {"date": "2026-10-15", "lines": []}
	var played: Array = await _whistled()
	var table: FinalHandTable = played[1]
	var section := table.evaluation
	assert_str(_value(section.lines, "PREDICTED")).starts_with("WILL NOT STAMP")
	section.stamp.pressed.emit()
	await await_millis(int((RubberStamp.LIFT + RubberStamp.DROP) * 1000.0) + 200)
	var story := Game.settings.profile.story
	assert_bool(story.ended()).is_true()
	var kept: Array = story.evaluation["lines"]
	assert_str(_value(kept, "PREDICTED")).is_equal(StoryLines.PREDICTED_WRONG)
	assert_bool(section.tab == null).is_true()
	var pages := NotesFolder.in_order(story)
	assert_bool(StoryNotes.TORN_SLIP in pages).is_true()
	assert_int(pages.find(StoryNotes.TORN_SLIP)).is_less(pages.find(StoryNotes.FINAL_SLIP))


## Asked for again: the invitation stamped DUPLICATE, the flyer YOUR TABLE IS STILL READY, and Kit's
## note for a refusal in the next map, outside the story's order.
func test_asked_again() -> void:
	var profile := Game.settings.profile
	profile.story.seconds = Story.FINAL_HAND_AT
	assert_int(StoryNotes.loose_due(profile)).is_equal(0)
	profile.story.tears = 1
	assert_int(StoryNotes.loose_due(profile)).is_equal(StoryNotes.NOT_STAMPED)
	StoryNotes.file(profile, StoryNotes.NOT_STAMPED)
	assert_int(StoryNotes.loose_due(profile)).is_equal(0)
	var ad: HouseAd = auto_free(HouseAd.new())
	add_child(ad)
	assert_str(ad.headline_words).is_equal(StoryLines.FLYER_AGAIN)
	var pane := FinalHandPane.add_to(self)
	await await_idle_frame()
	assert_bool(pane.card.again).is_true()
	pane.queue_free()


## The torn page and the slip stamped later draw at the back of the folder.
func test_the_torn_page_draws() -> void:
	var profile := Game.settings.profile
	profile.story.torn = {"date": "2026-10-15", "lines": [["CANDIDATE", "ANN"], ["STATUS", ""]]}
	var page: NotePage = auto_free(NotePage.new())
	page.number = StoryNotes.TORN_SLIP
	page.profile = profile
	add_child(page)
	await await_idle_frame()
	assert_str(StoryNotes.title_of(StoryNotes.TORN_SLIP)).is_equal("Torn off")
	assert_str(String(FolderBack.HELD[StoryNotes.TORN_SLIP])).is_equal("clip")
