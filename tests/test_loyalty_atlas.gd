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
## at the foot of the column in its pocket, under the pane, with room between them, and its bind is
## on its bottom right corner, held by the cover so it is drawn over the photo corner there.
func test_the_pane_is_the_atlas_cover() -> void:
	var dialog := await _open()
	var look := dialog._pane.get_theme_stylebox(&"panel")
	assert_object(look).is_instanceof(StyleBoxEmpty)
	assert_float(look.get_margin(SIDE_LEFT)).is_equal(AtlasCover.INSIDE[SIDE_LEFT])
	var last := dialog._pane.get_child(dialog._pane.get_child_count() - 1)
	assert_object(last).is_same(dialog.cover)
	assert_int(dialog.cover.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	var pocket := dialog.card_corner.get_parent()
	assert_object(pocket).is_instanceof(AtlasCover.Pocket)
	var column := pocket.get_parent()
	# Last but Back, under it.
	assert_int(pocket.get_index()).is_equal(column.get_child_count() - 2)
	assert_int(dialog.back.get_index()).is_equal(column.get_child_count() - 1)
	assert_bool(dialog.pane.get_index() < pocket.get_index()).is_true()
	dialog._keyboard = true
	dialog._pointer = false
	dialog._show_binds()
	var bind := dialog.cover.get_node("CardBind") as Control
	await get_tree().process_frame
	var card_end := dialog.card_corner.get_global_rect().end
	assert_vector(bind.get_global_rect().get_center()).is_equal_approx(
		card_end - Vector2.ONE * AtlasCover.BIND_IN, Vector2.ONE
	)
	dialog.card_corner.visible = false
	assert_bool(pocket.visible).is_false()
	dialog.card_corner.visible = true
	await get_tree().process_frame
	assert_float(dialog.card_corner.get_global_rect().position.y).is_greater(
		dialog.pane.get_global_rect().end.y
	)


## With room, the pencil lies tilted in the head past the line beside the title, short of the
## switches, where the map has no tabs; with Kit's tab on it, right of the tabs, short of the map's
## right edge. The dividers lie left of Back, which is at the foot of the column beside the map,
## under the card; the name is under the cover's middle.
func test_the_pencil_and_the_dividers_lie_in_the_room() -> void:
	var screen := get_tree().root
	var size_was := screen.size
	screen.size = Vector2i(1920, 1080)
	var dialog := await _open()
	await get_tree().process_frame
	var placed := dialog.cover.places()
	var map := dialog._well.get_global_rect()
	var back := dialog.back.get_global_rect()
	var card := dialog.card_corner.get_global_rect()
	var line := dialog._line.get_global_rect()
	var switches := dialog._switches.get_global_rect()
	var pane_at := dialog._pane.global_position
	var short := dialog.cover.short
	dialog.sheet_tabs.visible = true
	await get_tree().process_frame
	var tabbed := dialog.cover.places()
	var row := dialog._sheet_row.get_global_rect()
	screen.size = size_was
	assert_bool(short).is_false()
	assert_float(placed.pencil_to.x - placed.pencil_from.x).is_equal(AtlasCover.PENCIL_LONG)
	assert_float(placed.pencil_from.y - placed.pencil_to.y).is_equal(AtlasCover.PENCIL_RISE)
	assert_float(placed.pencil_from.x + pane_at.x).is_greater(line.position.x)
	assert_float(placed.pencil_to.x + pane_at.x).is_less(switches.position.x)
	var middle := (placed.pencil_from.y + placed.pencil_to.y) * 0.5 + pane_at.y
	assert_float(middle).is_equal_approx(line.get_center().y - AtlasCover.PENCIL_UP, 0.5)
	assert_float(tabbed.pencil_to.x + pane_at.x).is_equal_approx(
		map.end.x - AtlasCover.PENCIL_SHORT, 0.5
	)
	middle = (tabbed.pencil_from.y + tabbed.pencil_to.y) * 0.5 + pane_at.y
	assert_float(middle).is_equal_approx(row.get_center().y - AtlasCover.PENCIL_UP, 0.5)
	assert_object(dialog.back.get_parent()).is_same(dialog._column)
	assert_float(back.position.y).is_greater(card.end.y)
	assert_float(absf(back.end.y - map.end.y)).is_less(12.0)
	assert_float(placed.reach).is_equal(AtlasCover.DIVIDERS_REACH)
	assert_float(placed.hinge.x + pane_at.x).is_greater(map.end.x)
	var tips := placed.hinge + Vector2.from_angle(placed.toward) * placed.reach + pane_at
	assert_float(tips.x).is_equal_approx(back.position.x - AtlasCover.DIVIDERS_SHORT, 0.5)
	assert_float(placed.name_at).is_equal(0.0)


## On a short screen, a phone's, the pane fills it and the cover has little room inside it;
## nothing lies on it, as it has no foot, and the atlas's name is under the map's middle. A pencil
## lies under the details instead, where there is room for it.
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
	var lying := dialog._spare.lying
	# Put back, the screen fits the dialog again at once, so all of it is read before.
	screen.content_scale_factor = scale_was
	screen.size = size_was
	assert_bool(short).is_true()
	assert_float(top).is_equal(AtlasCover.INSIDE_SHORT[SIDE_TOP])
	assert_float(placed.pencil_to.distance_to(placed.pencil_from)).is_equal(0.0)
	assert_float(placed.reach).is_equal(0.0)
	assert_float(placed.name_at + pane_at.x).is_equal_approx(well.get_center().x, 0.5)
	assert_bool(card_shown).is_false()
	assert_bool(lying).is_true()


## The details are a slip of the House's paper in ink, bound by a coil at its top, its dotted line
## across the room left for it under the header; Pin, Back, the tabs and the switch are paper.
func test_the_details_are_a_slip() -> void:
	var dialog := await _open()
	var look := dialog.pane.get_theme_stylebox(&"panel") as AtlasSlipStyle
	assert_object(look).is_not_null()
	var tear := dialog.pane.find_child("Tear", true, false) as Control
	var tear_middle := tear.get_global_rect().get_center().y - dialog.pane.global_position.y
	assert_float(look.tear_at).is_equal_approx(tear_middle, 0.5)
	assert_object(dialog.pane.find_child("Coil", false, false)).is_instanceof(LoyaltyPane.Coil)
	assert_object(dialog.pane.pin.get_theme_stylebox(&"normal")).is_instanceof(AtlasTicketStyle)
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


## A pad's triggers zoom the map at two doublings a second at their full pull, and its right stick
## moves it 1,800 pixels a second at its full push.
func test_a_pad_zooms_and_moves_the_map_briskly() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	var zoom := view.zoom
	dialog.pad_on_map(1.0, Vector2.ZERO, 0.25)
	assert_float(view.zoom / zoom).is_equal_approx(pow(2.0, LoyaltyDialog.ZOOM_RATE * 0.25), 0.01)
	assert_float(LoyaltyDialog.ZOOM_RATE).is_equal(2.0)
	assert_float(LoyaltyDialog.PAN_RATE).is_equal(1800.0)


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


## A landmark not open yet is on the plans: its slip blueprint paper, its words in white, stamped
## CONCEPT, and a keystone's sealed besides; the roundabout too while it is shut. An open one is
## the House's cream paper again, nothing stamped on it.
func test_what_is_not_open_is_on_the_plans() -> void:
	var dialog := await _open()
	var profile := Game.settings.profile
	var pane := dialog.pane
	var style := pane.get_theme_stylebox(&"panel") as AtlasSlipStyle
	var map := Loyalty.map()
	pane.show_landmark(profile, map.landmark(&"spread_and_swivel"))
	assert_bool(style.planned).is_true()
	assert_bool(pane._stamp.stamped).is_true()
	assert_bool(pane._stamp.sealed).is_false()
	var named := pane.find_child("Name", true, false) as Label
	assert_object(named.get_theme_color(&"font_color")).is_equal(LoyaltyPane.PLAN_INK)
	assert_float(style.content_margin_bottom).is_equal(
		AtlasSlipStyle.ROOM_FOOT + AtlasSlipStyle.BARRIER_ROOM
	)
	pane.show_landmark(profile, map.landmark(&"card_shark"))
	assert_bool(pane._stamp.sealed).is_true()
	pane.show_roundabout(profile)
	assert_bool(style.planned).is_true()
	assert_bool(pane._stamp.sealed).is_false()
	pane.show_landmark(profile, map.landmark(&"slip_road"))
	assert_bool(style.planned).is_false()
	assert_bool(pane._stamp.stamped).is_false()
	assert_object(named.get_theme_color(&"font_color")).is_equal(LoyaltyPane.INK)
	assert_float(style.content_margin_bottom).is_equal(AtlasSlipStyle.ROOM_FOOT)


## On Kit's sheet the details are his, open or not: his scrap of graph paper over the slip, its
## lines in his hand in pencil, never the House's plans, even for his keystone shut, which he
## crosses out and marks "later" instead; back on the House's sheet the slip is printed again, in
## its own type.
func test_kits_sheet_is_written_on_his_scrap() -> void:
	var dialog := await _open()
	var profile := Game.settings.profile
	var pane := dialog.pane
	var style := pane.get_theme_stylebox(&"panel") as AtlasSlipStyle
	var named := pane.find_child("Name", true, false) as Label
	var printed := named.get_theme_font(&"font")
	pane.show_landmark(profile, Loyalty.map().landmark(&"back_roads"))
	assert_bool(pane._scrap.showing).is_true()
	assert_bool(style.planned).is_false()
	assert_bool(pane._stamp.stamped).is_false()
	assert_object(named.get_theme_font(&"font")).is_same(LoyaltyPane.KIT_HAND)
	assert_object(named.get_theme_color(&"font_color")).is_equal(LoyaltyPane.KIT_INK)
	assert_bool(pane._later.showing).is_true()
	Game.settings.profile.loyalty.win(&"pencil_trail")
	pane.show_landmark(profile, Loyalty.map().landmark(&"pencil_trail"))
	assert_bool(pane._scrap.showing).is_true()
	assert_bool(pane._later.showing).is_false()
	pane.show_landmark(profile, Loyalty.map().landmark(&"slip_road"))
	assert_bool(pane._scrap.showing).is_false()
	assert_bool(pane._later.showing).is_false()
	assert_object(named.get_theme_font(&"font")).is_same(printed)
	assert_object(named.get_theme_color(&"font_color")).is_equal(LoyaltyPane.INK)
