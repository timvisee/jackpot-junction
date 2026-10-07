extends GdUnitTestSuite
## The story's Final Hand, STORY.md 8: when the House offers it and the table it sets, the locked
## settings, CANDIDATE where the House prints names and nowhere else, the models, the house
## watching, and the whistle lit for the candidate.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")

var _runner: GdUnitSceneRunner
var _was_story := StoryState.new()
var _was_number := ""
var _was_map := ""
## The player's own settings, put aside while a lobby, which saves its match settings, runs on a
## scratch copy.
var _settings_were: Settings


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
	Game.pending_config = null
	Net.close()
	if _settings_were != null:
		Settings.remove_files(Game.settings.path)
		Game.settings = _settings_were
		_settings_were = null


## Offered once the clock reaches it, licensed and with the story on, until it is played.
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
	# Every value blacked out, the map's among them, and no stamp over them.
	assert_object(pane.options.map_option.find_child("Redacted", false, false)).is_not_null()
	assert_object(pane.options.minutes_option.find_child("Redacted", false, false)).is_not_null()
	assert_object(pane.find_child("SetByTheHouse", true, false)).is_null()
	var shown := MatchConfig.new()
	pane.options.apply_to(shown)
	assert_str(String(shown.map)).is_equal("house_rules")
	assert_int(shown.bot_count).is_equal(3)
	assert_float(shown.duration).is_equal(300.0)
	pane.close()
	assert_str(Game.settings.map).is_equal("vault")


## Not now puts the Final Hand off for that lobby alone: the next one Play opens asks again,
## STORY.md 8.1.
func test_not_now_asks_again_at_the_next_lobby() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_final_hand_lobby.cfg"
	Game.settings.profile.license_number = "JJ-212212"
	Game.settings.profile.license_holder = "Ada"
	Game.settings.profile.story.seconds = Story.FINAL_HAND_AT
	Story.override = Story.Stage.CANDIDATE
	for visit: int in 2:
		Game.pending_config = MatchConfig.new()
		var room: Node3D = auto_free(WAITING_SCENE.instantiate())
		_runner = scene_runner(room)
		await _runner.simulate_frames(45, 17)
		var pane := room.find_child("FinalHandPane", true, false) as FinalHandPane
		assert_object(pane).override_failure_message("lobby %d" % visit).is_not_null()
		# Dealt face down, turned over, and only then answered.
		assert_str(pane.card.holder).is_equal("Ada")
		for wait: int in 40:
			if pane.dealt():
				break
			await await_millis(50)
		assert_bool(pane.card.face_up).is_true()
		pane.not_now.pressed.emit()
		await await_idle_frame()
		var choosing: HostSettings = room.get("host_settings")
		assert_bool(choosing.is_open()).is_true()
		assert_bool(Game.pending_config.final_hand).is_false()
		choosing.close()
		Net.close()


## Take your seat brings the golden ticket up from behind the card, numbered with the license, and
## the seat is taken once it has dropped away; at the door the ticket comes back and its ADMIT ONE
## is torn off before the match begins, STORY.md 8.1.
func test_the_ticket_comes_with_the_seat_and_is_torn_at_the_door() -> void:
	Game.settings.profile.license_holder = "Ada"
	var pane: FinalHandPane = FinalHandPane.add_to(self)
	var said: Array[bool] = []
	pane.answered.connect(func(take: bool) -> void: said.append(take))
	for wait: int in 40:
		if pane.dealt():
			break
		await await_millis(50)
	assert_bool(pane.ticket.visible).is_false()
	pane.take.pressed.emit()
	assert_bool(pane.taking()).is_true()
	assert_bool(pane.ticket.visible).is_true()
	assert_str(pane.ticket.serial).is_equal("212212")
	assert_str(pane.ticket.holder).is_equal("Ada")
	# Pressed again, or put off, while it shows: nothing.
	pane.not_now.pressed.emit()
	assert_array(said).is_empty()
	for wait: int in 80:
		if not said.is_empty():
			break
		await await_millis(50)
	assert_array(said).is_equal([true])
	var door: FinalHandPane = FinalHandPane.admit(self)
	var in_now := [false]
	door.admitted.connect(func() -> void: in_now[0] = true)
	assert_object(door.card).is_null()
	for wait: int in 80:
		if in_now[0]:
			break
		await await_millis(50)
	assert_bool(in_now[0]).is_true()
	# Torn, its outlines still close: both sides of the ragged edge fill.
	var torn := GoldenTicket.make("Ada", "JJ-212212")
	add_child(torn)
	torn.show_torn()
	assert_bool(torn.stub.visible).is_false()
	assert_bool(Geometry2D.triangulate_polygon(torn._body()).is_empty()).is_false()
	assert_bool(Geometry2D.triangulate_polygon(torn._stub_shape()).is_empty()).is_false()
	assert_str(GoldenTicket.number_of("JJ-42")).is_equal("000042")
	torn.free()


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


## At the whistle the House's evaluation is under the slip's lines, every line filled in and STATUS
## blank, its stamp in place of the ways on; the stamp coming down writes the Final Hand into the
## profile with what the evaluation said, and leaves one way on, Continue, which puts up the last
## lines. Walking away before it leaves the Final Hand due.
func test_the_stamp_is_the_ending() -> void:
	Story.final_hand_on = true
	var profile := Game.settings.profile
	profile.story.seconds = Story.FINAL_HAND_AT
	var match_node := _start_match()
	var table := FinalHandTable.add_to(match_node)
	await _runner.simulate_frames(10, 17)
	match_node._finish()
	await _runner.simulate_frames(5, 17)
	var section := table.evaluation
	assert_object(section).is_not_null()
	assert_int(section.lines.size()).is_equal(StoryLines.EVALUATION.size())
	for line: Array in section.lines:
		assert_str(str(line[1])).not_contains("{")
	var by_label := {}
	for line: Array in section.lines:
		by_label[line[0]] = line[1]
	assert_str(str(by_label["MODELS AT THIS TABLE"])).is_equal("3")
	assert_str(str(by_label["STATUS"])).is_empty()
	assert_str(str(by_label["PLACE AT THIS TABLE"])).ends_with("NOT A FACTOR")
	assert_int(int(str(by_label["DEVIATION FROM MODEL"]).get_slice("%", 0))).is_greater_equal(1)
	assert_bool(section.go_on.visible).is_false()
	# Walked away from here, it is still due.
	assert_bool(profile.story.ended()).is_false()
	section.stamp.pressed.emit()
	await await_millis(int((RubberStamp.LIFT + RubberStamp.DROP) * 1000.0) + 200)
	assert_bool(profile.story.ended()).is_true()
	assert_float(profile.story.final_seconds).is_equal(Story.FINAL_HAND_AT)
	assert_array(profile.story.evaluation["lines"] as Array).has_size(StoryLines.EVALUATION.size())
	assert_bool(section.go_on.visible).is_true()
	assert_object(section.find_child("Approved", true, false)).is_not_null()
	assert_int(Story.stage_of(profile)).is_equal(Story.Stage.OPERATOR)
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	match_node.reparent(holder)
	section.go_on.pressed.emit()
	await await_idle_frame()
	var last: LastLines = holder.find_child("LastLines", true, false)
	assert_object(last).is_not_null()
	last.queue_free()


func _press() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	var up := InputEventKey.new()
	up.keycode = KEY_SPACE
	up.pressed = false
	Input.parse_input_event(up)


## The last lines in their order, each held until a press made once it has stood a second; a press
## sooner counts for nothing. Then the license.
func test_the_last_lines_wait_for_a_press() -> void:
	var holder: Control = auto_free(Control.new())
	holder.size = Vector2(1920.0, 1080.0)
	add_child(holder)
	Engine.time_scale = 8.0
	var last := LastLines.begin(holder)
	assert_int(last.digit).is_equal(0)
	for i: int in 200:
		await await_millis(20)
		if last.showing == 0:
			break
	Engine.time_scale = 1.0
	assert_int(last.digit).is_equal(1)
	assert_int(last.showing).is_equal(0)
	assert_str(last.line.text).is_equal(StoryLines.LAST_LINES[0])
	_press()
	await await_idle_frame()
	assert_int(last.showing).is_equal(0)
	await await_millis(int(LastLines.STEADY * 1000.0) + 100)
	_press()
	await await_idle_frame()
	assert_int(last.showing).is_equal(-1)
	await await_millis(int((LastLines.FADE + LastLines.BREATH) * 1000.0) + 300)
	assert_int(last.showing).is_equal(1)
	assert_str(last.line.text).is_equal(StoryLines.LAST_LINES[1])
	await await_millis(int(LastLines.STEADY * 1000.0) + 100)
	_press()
	await await_millis(int(LastLines.FADE * 1000.0) + 300)
	assert_bool(last.done).is_true()
	assert_object(last.find_child("LicenseView", true, false)).is_not_null()
	Audio.hush_music(false)
	last.queue_free()
