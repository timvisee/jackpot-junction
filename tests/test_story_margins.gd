extends GdUnitTestSuite
## The story in the game's margins, STORY.md 6.4 to 6.6 and 3.11: the HUD's microprint, the
## loading line, the Statistics page's line and its Shifts row, and About's last sentence.

const PATH := "user://test_story_margins.cfg"


func after_test() -> void:
	Story.override = -1
	Settings.remove_files(PATH)


## The microprint along a corner block says what the House calls the player by now, with the
## block's seat in it.
func test_the_hud_microprint_moves_with_the_story() -> void:
	var slot := PlayerSlot.new(1, KartInput.new())
	Story.override = Story.Stage.CUSTOMER
	assert_str(HudBlock.strip(slot, false, false).micro).is_equal(HudBlock.MICRO % 2)
	Story.override = Story.Stage.CANDIDATE
	assert_str(HudBlock.strip(slot, false, false).micro).is_equal(
		"SEAT 2 · CANDIDATE · HUMAN OVERSIGHT 0 · "
	)
	Story.override = Story.Stage.OPERATOR
	assert_str(HudBlock.strip(slot, true, true).micro).contains("OPERATOR · APPROVED")


## The microprint is set larger on a touch screen, where a phone's few inches made the desktop's
## size a line nobody could read up close; at either size every stage's words fit along a corner
## block whole at least once.
func test_the_hud_microprint_reads_up_close_on_a_phone() -> void:
	var slot := PlayerSlot.new(0, KartInput.new())
	var was := TouchInput.enabled
	for touch: bool in [false, true]:
		TouchInput.enabled = touch
		var size := StripStyle.MICRO_TOUCH if touch else StripStyle.MICRO_SIZE
		for stage: int in [Story.Stage.CUSTOMER, Story.Stage.CANDIDATE, Story.Stage.OPERATOR]:
			Story.override = stage
			var style := HudBlock.strip(slot, false, false)
			assert_int(style.micro_size).is_equal(size)
			var wide := (
				MatchHud.BLOCK_WIDTH + style.content_margin_left + style.content_margin_right
			)
			var made := style._made(Vector2(wide, 180.0))
			assert_str(made["micro"]).starts_with(style.micro.strip_edges())
	TouchInput.enabled = was
	assert_int(StripStyle.MICRO_TOUCH).is_greater(StripStyle.MICRO_SIZE)


## The loading line says who the room is for from the third stage, and the Final Hand's its own.
func test_the_loading_line_moves_with_the_story() -> void:
	Story.override = Story.Stage.PARTICIPANT
	assert_str(LoadingScreen.building()).is_equal("Building the room")
	Story.override = Story.Stage.NUMBER
	assert_str(LoadingScreen.building()).is_equal("Building your room")
	Story.override = Story.Stage.OPERATOR
	assert_str(LoadingScreen.building()).is_equal("Building the room, as approved")
	assert_str(LoadingScreen.building(true)).is_equal("Setting the final table")


## The Statistics page says whose record it is from the second stage, and after the ending counts
## the shifts.
func test_the_statistics_page_says_whose_record_it_is() -> void:
	var settings := Settings.new()
	settings.path = PATH
	settings.load_from_disk()
	settings.profile.story.shifts = 7
	Story.override = Story.Stage.PLAYER
	var early: StatsTab = auto_free(StatsTab.make(settings))
	add_child(early)
	await await_idle_frame()
	assert_object(early.find_child("Kept", true, false)).is_null()
	assert_bool(early.values.has(StatsTab.SHIFTS)).is_false()
	Story.override = Story.Stage.CANDIDATE
	var later: StatsTab = auto_free(StatsTab.make(settings))
	add_child(later)
	await await_idle_frame()
	var kept: Label = later.find_child("Kept", true, false)
	assert_str(kept.text).is_equal("Kept by the House, for your evaluation.")
	Story.override = Story.Stage.OPERATOR
	var after: StatsTab = auto_free(StatsTab.make(settings))
	add_child(after)
	await await_idle_frame()
	assert_str(after.values[StatsTab.SHIFTS].text).is_equal("7")


## About says the game was overseen by a human, for everybody and at every stage.
func test_about_says_a_human_oversaw_it() -> void:
	var about: AboutTab = auto_free(AboutTab.new())
	add_child(about)
	await await_idle_frame()
	var said := ""
	for label: Node in about.find_children("*", "RichTextLabel", true, false):
		said += (label as RichTextLabel).text
	for label: Node in about.find_children("*", "Label", true, false):
		said += (label as Label).text
	assert_str(said).contains("A human oversaw it")
	assert_str(said).contains("put their name on it")


## GAME.md 8.6: the card that turns over wears the room's sticker on the House's face, the one the
## pause menu wears; a screen for no room wears none.
func test_the_turned_card_wears_the_rooms_sticker() -> void:
	var sticker: Texture2D = RoomEmblem.HOUSE
	var screen: LoadingScreen = auto_free(LoadingScreen.add_to(self, "The Yard", sticker))
	var face := screen._face
	var stuck := face.get_node_or_null("Sticker") as TextureRect
	assert_object(stuck).is_not_null()
	assert_object(stuck.texture).is_same(sticker)
	var plain: LoadingScreen = auto_free(LoadingScreen.add_to(self, "The Yard"))
	assert_object(plain._face.get_node_or_null("Sticker")).is_null()
