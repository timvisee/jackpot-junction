extends GdUnitTestSuite
## The loyalty program's dialog dressed as the House's road atlas, GAME.md 8.9: the pane its cover,
## the card at the column's foot, the pencil and the dividers in the foot where there is room, the
## details a slip of the House's paper, and the words in the foot of the cover and of the
## achievements' table by the story's stage, see [AtlasCover], [AtlasArt] and [AtlasTicketStyle].

const PATH := "user://test_loyalty_atlas.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.story.on = false
	var state := Game.settings.profile.loyalty
	state.welcomed = true
	state.win(&"slip_road")
	state.look_at(&"slip_road")
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	Story.override = -1
	LoyaltyDialog.listed = false
	LoyaltyDialog.stood_at = &""
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> LoyaltyDialog:
	var dialog := LoyaltyDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


## The pane is the cover, with its room inside it and the cover over everything in it; the card is
## at the foot of the column, under the pane, with room between them.
func test_the_pane_is_the_atlas_cover() -> void:
	var dialog := await _open()
	var look := dialog._pane.get_theme_stylebox(&"panel")
	assert_object(look).is_instanceof(StyleBoxEmpty)
	assert_float(look.get_margin(SIDE_LEFT)).is_equal(AtlasCover.INSIDE[SIDE_LEFT])
	var last := dialog._pane.get_child(dialog._pane.get_child_count() - 1)
	assert_object(last).is_same(dialog.cover)
	assert_int(dialog.cover.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	var column := dialog.card_corner.get_parent()
	assert_int(dialog.card_corner.get_index()).is_equal(column.get_child_count() - 1)
	assert_bool(dialog.pane.get_index() < dialog.card_corner.get_index()).is_true()
	await get_tree().process_frame
	assert_float(dialog.card_corner.get_global_rect().position.y).is_greater(
		dialog.pane.get_global_rect().end.y
	)


## With room, the pencil lies in the foot left of Back, from near the map's left edge, and the
## dividers past it; the atlas's name is under the cover's middle.
func test_the_pencil_and_the_dividers_lie_in_the_foot() -> void:
	var screen := get_tree().root
	var size_was := screen.size
	screen.size = Vector2i(1920, 1080)
	var dialog := await _open()
	await get_tree().process_frame
	var placed := dialog.cover.places()
	var foot := dialog._foot_row.get_global_rect()
	var back := dialog.back.get_global_rect()
	var pane_at := dialog._pane.global_position
	var short := dialog.cover.short
	screen.size = size_was
	assert_bool(short).is_false()
	assert_float(placed.pencil_to.x - placed.pencil_from.x).is_greater_equal(AtlasCover.PENCIL_ROOM)
	assert_float(placed.pencil_to.x + pane_at.x).is_less(back.position.x)
	assert_float(absf(placed.pencil_from.y + pane_at.y - foot.get_center().y)).is_less(10.0)
	assert_float(placed.reach).is_equal(AtlasCover.DIVIDERS_REACH)
	assert_float(placed.hinge.x).is_greater(placed.pencil_to.x)
	assert_float(placed.hinge.x + AtlasCover.DIVIDERS_ROOM + pane_at.x).is_less_equal(
		back.position.x - AtlasCover.BACK_ROOM + 0.5
	)
	assert_float(placed.name_at).is_equal(0.0)


## On a short screen, a phone's, the pane fills it and the cover has little room inside it;
## nothing lies on it, as it has no foot, and the atlas's name is under the map's middle.
func test_a_short_screen_has_nothing_on_its_cover() -> void:
	var screen := get_tree().root
	var scale_was := screen.content_scale_factor
	var size_was := screen.size
	screen.size = Vector2i(2400, 1080)
	screen.content_scale_factor = 2.0
	var dialog := await _open()
	await get_tree().process_frame
	var placed := dialog.cover.places()
	var top := dialog._pane.get_theme_stylebox(&"panel").get_margin(SIDE_TOP)
	var well := dialog._well.get_global_rect()
	var pane_at := dialog._pane.global_position
	var card_shown := dialog.card_corner.visible
	var short := dialog.cover.short
	# Put back, the screen fits the dialog again at once, so all of it is read before.
	screen.content_scale_factor = scale_was
	screen.size = size_was
	assert_bool(short).is_true()
	assert_float(top).is_equal(AtlasCover.INSIDE_SHORT[SIDE_TOP])
	assert_float(placed.pencil_to.distance_to(placed.pencil_from)).is_equal(0.0)
	assert_float(placed.reach).is_equal(0.0)
	assert_float(placed.name_at + pane_at.x).is_equal_approx(well.get_center().x, 0.5)
	assert_bool(card_shown).is_false()


## The details are a slip of the House's paper in ink, its buttons printed on it; Back, the tabs
## and the switch are paper laid on the cloth.
func test_the_details_are_a_slip() -> void:
	var dialog := await _open()
	var look := dialog.pane.get_theme_stylebox(&"panel") as TicketStyle
	assert_bool(look.torn).is_true()
	assert_object(look.fill).is_equal(HouseTheme.PAPER)
	assert_str(String(dialog.pane.pin.theme_type_variation)).is_equal(HouseTheme.PAPER_BUTTON)
	var named := dialog.pane.find_child("Name", true, false) as Label
	assert_object(named.get_theme_color(&"font_color")).is_equal(HouseTheme.INK)
	assert_object(dialog.back.get_theme_stylebox(&"normal")).is_instanceof(AtlasTicketStyle)
	assert_object(dialog.sheet_tabs.get_theme_stylebox(&"tab_selected")).is_instanceof(
		AtlasTicketStyle
	)
	assert_object(dialog.list_switch.get_theme_icon(&"checked")).is_instanceof(
		AtlasTicketStyle.Switch
	)


## The atlas's name in the foot of its cover by the story's stage, the license's number in it once
## the House calls the player by it.
func test_the_atlas_name_by_stage() -> void:
	var profile := Game.settings.profile
	Story.override = Story.Stage.CUSTOMER
	assert_str(LoyaltyDialog.atlas_name(profile)).is_equal("ROAD ATLAS  ·  MEMBERS' EDITION")
	Story.override = Story.Stage.NUMBER
	var number := Game.settings.license_number.to_upper()
	assert_str(LoyaltyDialog.atlas_name(profile)).is_equal("ROAD ATLAS  ·  ISSUED TO " + number)
	Story.override = Story.Stage.OPERATOR
	var dialog := await _open()
	assert_str(dialog.cover.motto).contains("STAFF COPY")


## The motto on the achievements' table by the story's stage, its payout trimmed as it goes.
func test_the_table_motto_by_stage() -> void:
	Story.override = Story.Stage.CUSTOMER
	assert_str(AchievementsDialog.motto()).is_equal("BRAGGING RIGHTS PAY 3 TO 2")
	Story.override = Story.Stage.PLAYER
	assert_str(AchievementsDialog.motto()).is_equal("BRAGGING RIGHTS PAY 3 TO 2")
	Story.override = Story.Stage.NUMBER
	assert_str(AchievementsDialog.motto()).is_equal("BRAGGING RIGHTS PAY 6 TO 5")
	Story.override = Story.Stage.OPERATOR
	assert_str(AchievementsDialog.motto()).is_equal("BRAGGING RIGHTS DO NOT EXPIRE")
