extends GdUnitTestSuite
## The loyalty program's welcome, GAME.md 8.9 and STORY.md 6.6b: due after the first map played to
## its whistle and not before, once a profile, never with the invitation; the member number the
## invitation's; activated, the profile a member and its program settled, the map open with the
## card in its corner, and the title's Clubhouse gaining the program's button. See [LoyaltyWelcome].

const PATH := "user://test_loyalty_welcome.cfg"
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.story.on = false
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)


func after_test() -> void:
	Engine.time_scale = 1.0
	LoyaltyWelcome.again = false
	OpeningInvitation.again = false
	LoyaltyDialog.stood_at = &""
	LoyaltyDialog.listed = false
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## Owed once a map has been played to its whistle and the profile not welcomed; never shown where
## nothing is drawn unless asked for.
func test_due_after_the_first_map() -> void:
	var profile := Game.settings.profile
	assert_bool(LoyaltyWelcome.owed(profile)).is_false()
	profile.stats[&"maps"] = 1.0
	assert_bool(LoyaltyWelcome.owed(profile)).is_true()
	assert_bool(LoyaltyWelcome.due(profile)).is_false()
	LoyaltyWelcome.again = true
	assert_bool(LoyaltyWelcome.due(profile)).is_true()
	LoyaltyWelcome.again = false
	profile.loyalty.welcomed = true
	assert_bool(LoyaltyWelcome.owed(profile)).is_false()


## The card's number is the invitation's stub's, the House having kept it, or one like it, given
## once and kept.
func test_the_member_number() -> void:
	var profile := Game.settings.profile
	profile.story.invitation = "1234 5678"
	assert_str(LoyaltyWelcome.number_for(profile)).is_equal("1234 5678")
	profile.loyalty.member = ""
	profile.story.invitation = ""
	var given := LoyaltyWelcome.number_for(profile)
	assert_int(given.length()).is_equal(9)
	assert_str(given.substr(4, 1)).is_equal(" ")
	assert_str(LoyaltyWelcome.number_for(profile)).is_equal(given)


## Joining makes the profile a member and settles its program: the slip road won with the card, the
## first bets open, and a count already met won at once.
func test_joining_settles_the_first_map() -> void:
	var profile := Game.settings.profile
	profile.stats[&"maps"] = 1.0
	profile.stats[&"driven"] = 12000.0
	assert_bool(profile.loyalty.has_won(&"slip_road")).is_false()
	LoyaltyWelcome.join(profile)
	assert_bool(profile.loyalty.welcomed).is_true()
	assert_bool(profile.loyalty.has_won(&"slip_road")).is_true()
	assert_bool(profile.loyalty.has_won(&"racing_stripes")).is_true()
	var visor := Loyalty.map().landmark(&"dealers_visor")
	assert_int(Loyalty.standing(profile, visor)).is_equal(Loyalty.Standing.OPEN)
	assert_bool(profile.loyalty.member.is_empty()).is_false()


## The ceremony: the letter to the profile by name and the card with its number; Back does nothing;
## activated, the profile is a member, the map opens unfolding with the card carried to its corner,
## and the welcome is gone.
func test_the_ceremony_ends_in_the_map() -> void:
	var profile := Game.settings.profile
	profile.stats[&"maps"] = 1.0
	profile.player_names[0] = "Ada"
	profile.story.invitation = "7343 4238"
	var welcome := LoyaltyWelcome.over(_holder, profile)
	var opened: Array[LoyaltyDialog] = []
	welcome.welcomed.connect(func(dialog: LoyaltyDialog) -> void: opened.append(dialog))
	welcome.start()
	await get_tree().process_frame
	assert_str(welcome.letter.paragraphs()[0]).is_equal("Dear Ada,")
	assert_str(welcome.letter.paragraphs()[1]).contains("Loyalty Program")
	assert_str(welcome.card.member).is_equal("7343 4238")
	assert_str(welcome.card.holder).is_equal("Ada")
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	welcome._unhandled_input(back)
	assert_bool(is_instance_valid(welcome)).is_true()
	welcome.come_on_now()
	Engine.time_scale = 40.0
	welcome.activate.pressed.emit()
	assert_bool(welcome.is_activated()).is_true()
	assert_bool(profile.loyalty.welcomed).is_true()
	for i: int in 240:
		if not is_instance_valid(welcome):
			break
		await get_tree().process_frame
	Engine.time_scale = 1.0
	assert_bool(is_instance_valid(welcome)).is_false()
	assert_int(opened.size()).is_equal(1)
	var dialog := opened[0]
	assert_bool(dialog.unfolding).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("slip_road")
	assert_float(dialog.card_corner.modulate.a).is_equal(1.0)
	# And once the card is at rest the program says what it is, put away by its one button.
	assert_object(dialog.intro).is_not_null()
	var said := dialog.intro.find_children("*", "ConfirmPane", true, false)[0] as ConfirmPane
	assert_str(said.said()).contains(LoyaltyDialog.INTRO_LINE)
	assert_bool(said.no_button().visible).is_false()
	said.yes_button().pressed.emit()
	assert_object(dialog.intro).is_null()
	assert_bool(dialog.map_view.has_focus()).is_true()


## On a screen too short for the program to keep its card in the corner, the card has nowhere on the
## map to go and drops off the table, and the program still says what it is.
func test_the_card_drops_where_the_map_has_no_place_for_it() -> void:
	var profile := Game.settings.profile
	profile.stats[&"maps"] = 1.0
	var welcome := LoyaltyWelcome.over(_holder, profile)
	var opened: Array[LoyaltyDialog] = []
	# The program as a short screen lays it out, its card left out of the corner.
	welcome.welcomed.connect(
		func(dialog: LoyaltyDialog) -> void:
			dialog.card_corner.visible = false
			opened.append(dialog)
	)
	welcome.start()
	await get_tree().process_frame
	welcome.come_on_now()
	Engine.time_scale = 40.0
	welcome.activate.pressed.emit()
	for i: int in 600:
		if not is_instance_valid(welcome):
			break
		await get_tree().process_frame
	Engine.time_scale = 1.0
	assert_bool(is_instance_valid(welcome)).is_false()
	var dialog := opened[0]
	assert_bool(dialog.card_corner.visible).is_false()
	assert_object(dialog.intro).is_not_null()


## At the title it comes after the invitation, never with it; and once the map it opens is put
## away the program's button is the first of the Clubhouse's.
func test_the_title_gains_the_program() -> void:
	var profile := Game.settings.profile
	profile.stats[&"maps"] = 1.0
	OpeningInvitation.again = true
	LoyaltyWelcome.again = true
	var first: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(first)
	await await_idle_frame()
	assert_object(first.invitation).is_not_null()
	assert_object(first.welcome).is_null()
	remove_child(first)
	OpeningInvitation.again = false
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	assert_object(title.welcome).is_not_null()
	assert_object(title.find_child("Loyalty", true, false)).is_null()
	Engine.time_scale = 40.0
	title.welcome.come_on_now()
	title.welcome.activate.pressed.emit()
	var dialog: LoyaltyDialog = null
	for i: int in 240:
		dialog = title.get_node_or_null("Loyalty") as LoyaltyDialog
		if dialog != null and not is_instance_valid(title.welcome):
			break
		await get_tree().process_frame
	assert_object(dialog).is_not_null()
	dialog.close()
	for i: int in 60:
		if not is_instance_valid(dialog):
			break
		await get_tree().process_frame
	Engine.time_scale = 1.0
	var button := title.find_child("Loyalty", true, false) as Button
	assert_object(button).is_not_null()
	assert_str(button.text).is_equal("Loyalty Program")
	assert_object(title.get("_clubhouse")[0]).is_same(button)
	title.show_clubhouse(true)
	assert_bool(button.visible).is_true()
	assert_bool(button.has_focus()).is_true()


## The two lamps hang evenly either side of where the card comes to rest, so their beams meet on it
## in the middle of the table.
func test_the_lamps_meet_on_the_card() -> void:
	var rests := LoyaltyWelcome.card_rests_at()
	var lamps := LoyaltyWelcome.LAMPS
	assert_float((lamps[0].x + lamps[1].x) * 0.5).is_equal_approx(rests.x, 2.0)
	assert_float(lamps[0].y).is_equal(lamps[1].y)
	assert_float(rests.x).is_equal_approx(LoyaltyWelcome.STAGE.x * 0.5, 10.0)


## The Catalog's button wears the NEW tag while a card in the catalog is unseen, and the Clubhouse
## with it; with nothing unseen anywhere, neither does.
func test_the_catalog_button_is_tagged_for_unseen_cards() -> void:
	var profile := Game.settings.profile
	profile.story.invited = true
	profile.catalog.fresh = PackedStringArray(["payday"])
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var catalog := title.find_child("Catalog", true, false) as Button
	var clubhouse := title.find_child("Clubhouse", true, false) as Button
	assert_object(catalog.get_node_or_null("New")).is_not_null()
	assert_object(clubhouse.get_node_or_null("New")).is_not_null()
	profile.catalog.fresh = PackedStringArray()
	title._tag_fresh()
	assert_object(catalog.get_node_or_null("New")).is_null()
	assert_object(clubhouse.get_node_or_null("New")).is_null()


## The program's button wears the NEW tag while an edition is owed for a lap of the roundabout, and
## the Clubhouse with it, though every landmark won has been shown.
func test_the_program_button_is_tagged_for_an_edition_owed() -> void:
	var profile := Game.settings.profile
	profile.story.invited = true
	profile.loyalty.welcomed = true
	profile.loyalty.member = "1234 5678"
	profile.loyalty.owed = 1
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	assert_bool(Loyalty.has_fresh(profile)).is_false()
	var program := title.find_child("Loyalty", true, false) as Button
	var clubhouse := title.find_child("Clubhouse", true, false) as Button
	assert_object(program.get_node_or_null("New")).is_not_null()
	assert_object(clubhouse.get_node_or_null("New")).is_not_null()
	profile.loyalty.owed = 0
	title._tag_fresh()
	assert_object(program.get_node_or_null("New")).is_null()
	assert_object(clubhouse.get_node_or_null("New")).is_null()


## The button stands under the letter's middle near the foot of the screen, and the letter, turned
## as it lies, never reaches it.
func test_the_button_stands_clear_under_the_letter() -> void:
	var shown := LoyaltyLetter.SIZE * LoyaltyWelcome.LETTER_SCALE
	var corners := PackedVector2Array()
	for corner: Vector2 in [
		Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)
	]:
		corners.append(
			LoyaltyWelcome.LETTER_AT + (shown * corner).rotated(LoyaltyWelcome.LETTER_TURN)
		)
	var lowest := 0.0
	for corner: Vector2 in corners:
		lowest = maxf(lowest, corner.y)
	var button := Rect2(
		LoyaltyWelcome.button_at(), Vector2(LoyaltyWelcome.BUTTON_WIDE, MenuTheme.button_size().y)
	)
	assert_float(button.position.y - lowest).is_greater(12.0)
	assert_float(button.get_center().x).is_equal_approx(LoyaltyWelcome.LETTER_AT.x, 1.0)
	assert_float(LoyaltyWelcome.STAGE.y - button.end.y).is_less(60.0)
