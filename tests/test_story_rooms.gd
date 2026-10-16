extends GdUnitTestSuite
## The rooms and the crowd as the story goes, STORY.md 6.8 and 6.9: the Yard's sign, the
## Workbench's calendar, After Hours' picture, the crowd falling into step, and the Final Hand's
## house watching the candidate and applauding at the whistle.

var _notes_were := PackedInt32Array()


func before_test() -> void:
	_notes_were = Game.settings.profile.story.notes.duplicate()


func after_test() -> void:
	Story.override = -1
	Story.clock_override = -1.0
	Game.settings.profile.story.notes = _notes_were


func _dressing(map: String) -> StoryDressing:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = false
	add_child(arena)
	return arena.get_node_or_null("Story") as StoryDressing


## The lit board over the Yard's doors says what the yard has become, stage by stage; the Garage's
## board stays blank.
func test_the_yard_sign_reads_as_the_story_has_come() -> void:
	var lines := {
		Story.Stage.CUSTOMER: "LOADING BAY 4",
		Story.Stage.PARTICIPANT: "AUTOMATED LOADING",
		Story.Stage.CANDIDATE: "CREW REQUIRED: 0",
		Story.Stage.OPERATOR: "UNDER NEW MANAGEMENT",
	}
	for stage: int in lines:
		Story.override = stage
		assert_str(_dressing("crossfire").sign.text).is_equal(lines[stage])
	assert_object(_dressing("lucky_crossing").sign).is_null()


## The calendar has a month's days on it; from the third stage the day Kit left is ringed, and once
## the last note is found it is the next month, with nothing ringed.
func test_the_calendar_is_ringed_and_in_the_end_turned_over() -> void:
	Game.settings.profile.story.notes = PackedInt32Array()
	Story.override = Story.Stage.PLAYER
	var early := _dressing("lucky_crossing").calendar
	var days: MultiMeshInstance3D = early.get_node("Days")
	assert_int(days.multimesh.instance_count).is_equal(StoryDressing.MONTHS[0].x)
	assert_object(early.get_node_or_null("Ring")).is_null()
	Story.override = Story.Stage.PARTICIPANT
	assert_object(_dressing("lucky_crossing").calendar.get_node_or_null("Ring")).is_not_null()
	Game.settings.profile.story.notes = PackedInt32Array([Story.NOTE_COUNT])
	var turned := _dressing("lucky_crossing").calendar
	assert_object(turned.get_node_or_null("Ring")).is_null()
	days = turned.get_node("Days")
	assert_int(days.multimesh.instance_count).is_equal(StoryDressing.MONTHS[1].x)


## After Hours' frames are dark until the ending, and after it the left one holds the player's
## kart over a plate.
func test_after_the_ending_the_card_room_has_an_employee_of_the_month() -> void:
	Story.override = Story.Stage.CANDIDATE
	assert_object(_dressing("vault").picture).is_null()
	Story.override = Story.Stage.OPERATOR
	var picture := _dressing("vault").picture
	assert_object(picture).is_not_null()
	assert_str((picture.get_node("Plate") as Label3D).text).is_equal("EMPLOYEE OF THE MONTH")
	var viewport: SubViewport = picture.find_children("*", "SubViewport", false, false)[0]
	assert_int(viewport.render_target_update_mode).is_equal(SubViewport.UPDATE_ONCE)
	assert_object(viewport.find_child("Kart", true, false)).is_not_null()


## Each to their own beat until the Candidate, then less with the clock until the house moves as
## one by the Final Hand, and after it; a match room's crowd is set so as it goes up.
func test_the_crowd_falls_into_step() -> void:
	assert_float(Story.crowd_spread(Story.Stage.NUMBER, 9000.0)).is_equal(1.0)
	var start := Story.STAGE_STARTS[Story.Stage.CANDIDATE]
	assert_float(Story.crowd_spread(Story.Stage.CANDIDATE, start)).is_equal(1.0)
	var middle := (start + Story.FINAL_HAND_AT) * 0.5
	assert_float(Story.crowd_spread(Story.Stage.CANDIDATE, middle)).is_equal_approx(0.5, 0.001)
	assert_float(Story.crowd_spread(Story.Stage.CANDIDATE, Story.FINAL_HAND_AT)).is_equal(0.0)
	assert_float(Story.crowd_spread(Story.Stage.OPERATOR, 0.0)).is_equal(0.0)
	Story.override = Story.Stage.CANDIDATE
	Story.clock_override = middle
	var crowd := _dressing("vault").arena.crowd
	assert_float(crowd.spread).is_equal_approx(0.5, 0.001)
	for skin: ShaderMaterial in crowd._skins:
		assert_float(skin.get_shader_parameter(&"spread")).is_equal_approx(0.5, 0.001)


## At the Final Hand the house stands still in step and leans in toward the candidate wherever the
## kart goes, then applauds together at the whistle.
func test_the_final_hand_house_watches_the_candidate() -> void:
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var crowd := Crowd.add_to(holder, Vector2(24.0, 18.0))
	var kart: Node3D = auto_free(Node3D.new())
	holder.add_child(kart)
	kart.position = Vector3(4.0, 0.0, -2.0)
	crowd.watch(kart)
	assert_bool(crowd.still).is_true()
	assert_float(crowd.spread).is_equal(0.0)
	for i: int in 30:
		crowd._process(1.0 / 60.0)
	for skin: ShaderMaterial in crowd._skins:
		assert_float(skin.get_shader_parameter(&"watch")).is_equal(Crowd.WATCH_LEAN)
		assert_vector(skin.get_shader_parameter(&"watch_point")).is_equal(kart.global_position)
	assert_float(crowd._lift).is_less(0.01)
	crowd.applaud()
	for i: int in 120:
		crowd._process(1.0 / 60.0)
	assert_bool(crowd.still).is_false()
	assert_float(crowd._rate).is_equal_approx(Crowd.APPLAUSE_RATE, 0.5)
	assert_float(crowd._lean).is_less(0.01)


## Before the Final Hand a few in the house stop to watch the player's kart, STORY.md 6.9: the most
## in view first, the far side's front row, its middle before its ends; one never falls into step.
func test_a_few_watch_the_players_kart() -> void:
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var crowd := Crowd.add_to(holder, Vector2(24.0, 18.0))
	var kart: Node3D = auto_free(Node3D.new())
	holder.add_child(kart)
	kart.position = Vector3(-3.0, 0.0, 2.0)
	assert_int(crowd.watchers()).is_equal(0)
	crowd.watched_by(6, kart)
	assert_int(crowd.watchers()).is_equal(6)
	crowd._process(1.0 / 60.0)
	for skin: ShaderMaterial in crowd._skins:
		assert_vector(skin.get_shader_parameter(&"watcher_point")).is_equal(kart.global_position)
	# Ranked in the fraction of each one's phase: exactly one 0, the odd one, and the six lowest
	# of the rest on the far side.
	var ranks: Array[Vector2] = []
	var odd := 0
	for i: int in crowd._traits.size():
		var rank := fposmod(crowd._traits[i].a, 1.0)
		if rank < 0.001:
			odd += 1
		else:
			ranks.append(Vector2(rank, float(i)))
	assert_int(odd).is_equal(1)
	ranks.sort()
	for k: int in 6:
		assert_int(crowd._sides[int(ranks[k].y)]).is_equal(0)
	crowd.watched_by(0, null)
	assert_int(crowd.watchers()).is_equal(0)


## From the third stage a bot wears a piece of the player's dress, STORY.md 6.9, drawn so on this
## machine while the dress it was dealt, which goes over the wire, stays its own.
func test_a_bot_wears_the_players_hat() -> void:
	var bot: Kart = auto_free(preload("res://scenes/kart/kart.tscn").instantiate())
	add_child(bot)
	await await_idle_frame()
	var player := KartStyle.new()
	player.hat = KartStyle.HATS.find("Fedora")
	var own_hat := bot.style.hat
	StoryTable.dress_bot(bot, player)
	assert_int(bot.style.hat).is_equal(own_hat)
	assert_object(bot.get_node_or_null("Body/Hat")).is_not_null()
	# A crown is the bounty's, never a bot's; a player with no hat lends a flag.
	player.hat = KartStyle.HATS.find("Crown")
	player.flag = 0
	StoryTable.dress_bot(bot, player)
	assert_int(StoryTable.WATCHERS[Story.Stage.PARTICIPANT]).is_equal(1)
