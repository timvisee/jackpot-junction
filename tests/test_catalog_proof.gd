extends GdUnitTestSuite
## The catalog dressed as the House's press proof, GAME.md 8.8: the pane a cutting mat, each page's
## cards a sheet on it with its tab, the cards not taken their die lines, the first taken ringed,
## the steel rule, the swatch fan and the tin in the foot where there is room, the spec sheet on
## paper, the job ticket, and the motto by the story's stage, see [ProofCover], [ProofArt] and
## [ProofStyle].

const PATH := "user://test_catalog_proof.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.story.on = false
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	Story.override = -1
	CatalogDialog.detailed = false
	CatalogDialog.stack = CatalogDialog.WHOLE_STACK
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> CatalogDialog:
	var dialog := CatalogDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


## The pane is the mat, with its room inside it and the cover over everything in it; the wells draw
## nothing, the sheet is drawn under them, and each page's sheet starts right under the row of tabs,
## its first tab standing on its left edge.
func test_the_pane_is_the_mat_and_the_tabs_stand_on_the_sheet() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	await get_tree().process_frame
	var look := dialog._pane.get_theme_stylebox(&"panel")
	assert_object(look).is_instanceof(StyleBoxEmpty)
	var last := dialog._pane.get_child(dialog._pane.get_child_count() - 1)
	assert_object(last).is_same(dialog.cover)
	assert_int(dialog.cover.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	var well := dialog.tabs.get_current_tab_control().get_node("Well") as ListBox.Well
	assert_bool(well.bare).is_true()
	var sheet := well.get_global_rect()
	var row := dialog.tab_bar.get_global_rect()
	assert_float(sheet.position.y).is_equal_approx(row.end.y, 0.5)
	var first := dialog.tab_bar.get_tab_rect(0)
	assert_float(row.position.x + first.position.x).is_equal_approx(sheet.position.x, 0.5)


## A card never taken is its die line and a card taken is printed; the first taken on each page is
## ringed in the pressman's grease pencil, and no other.
func test_the_first_card_taken_is_ringed() -> void:
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	catalog.take_joker(&"aimbot")
	catalog.use_item(&"bomb")
	var dialog := await _open()
	assert_object(dialog.cell_of(&"wild_card").card).is_instanceof(DieLine)
	assert_object(dialog.cell_of(&"payday").card).is_instanceof(JokerCard)
	var ringed: Array[StringName] = []
	for grid: CardGrid in [dialog.joker_grid, dialog.item_grid]:
		for cell: Control in grid.cells():
			if (cell as CatalogCell).is_ringed():
				ringed.append((cell as CatalogCell).id)
	assert_array(ringed).contains_exactly([&"payday", &"bomb"])


## The card taken or used the most, twice at least, is ringed Fave! too, and the joker that went
## off by itself the most MVP!, GAME.md 8.8; a card that is more than one of them says each, a line
## each.
func test_the_most_taken_and_the_busiest_are_ringed_too() -> void:
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	for i: int in 3:
		catalog.take_joker(&"toll_booth")
	catalog.go_off(&"toll_booth")
	catalog.take_joker(&"pickpocket")
	for i: int in 4:
		catalog.go_off(&"pickpocket")
	catalog.use_item(&"bomb")
	catalog.use_item(&"bomb")
	var dialog := await _open()
	assert_array(dialog.cell_of(&"payday").marks).is_equal(PackedStringArray([ProofArt.RING_FIRST]))
	assert_array(dialog.cell_of(&"toll_booth").marks).is_equal(
		PackedStringArray([ProofArt.RING_MOST])
	)
	assert_array(dialog.cell_of(&"pickpocket").marks).is_equal(
		PackedStringArray([ProofArt.RING_BEST])
	)
	assert_array(dialog.cell_of(&"bomb").marks).is_equal(
		PackedStringArray([ProofArt.RING_FIRST, ProofArt.RING_MOST])
	)
	assert_bool(dialog.cell_of(&"toll_booth").is_ringed()).is_true()
	# Each reason in a pencil of its own.
	var pencils := [ProofArt.RING_FIRST, ProofArt.RING_MOST, ProofArt.RING_BEST].map(
		func(word: String) -> Color: return ProofArt.grease_of(word)
	)
	assert_int(pencils.size()).is_equal(3)
	assert_bool(pencils[0] != pencils[1] and pencils[1] != pencils[2]).is_true()
	assert_bool(pencils[0] != pencils[2]).is_true()


## The first of a page found is the first ever found of it, kept so by the profile's file.
func test_the_first_found_is_kept_in_order() -> void:
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"wild_card")
	catalog.take_joker(&"payday")
	catalog.take_joker(&"wild_card")
	var ids := CatalogDialog.ids_of(CatalogDialog.CATALOG.jokers)
	assert_str(String(catalog.first_of(ids))).is_equal("wild_card")
	var file := ConfigFile.new()
	catalog.write(file)
	var read := CatalogState.new()
	read.read(file)
	assert_str(String(read.first_of(ids))).is_equal("wild_card")
	assert_str(String(read.first_of([&"payday", &"aimbot"]))).is_equal("payday")
	assert_str(String(read.first_of([&"aimbot"]))).is_empty()


## Nothing found on a page, nothing on it is ringed and its sheet is blank but for how to begin it.
func test_an_empty_page_has_no_ring() -> void:
	var dialog := await _open()
	for cell: Control in dialog.joker_grid.cells():
		assert_bool((cell as CatalogCell).is_ringed()).is_false()
	assert_bool(dialog.is_empty(0)).is_true()


## With room, the steel rule, the swatch fan and the tin lie in the foot left of Back, one after the
## other; the job ticket lies under the switches, clear of Back.
func test_the_foot_and_the_ticket_with_room() -> void:
	var screen := get_tree().root
	var size_was := screen.size
	screen.size = Vector2i(1920, 1080)
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	await get_tree().process_frame
	var placed := dialog.cover.places()
	var pane_at := dialog._pane.global_position
	var back := dialog.back.get_global_rect()
	var spot := dialog.cover.ticket_spot()
	var spot_at := dialog.cover.global_position
	var switches := dialog.joker_grid.get_parent().get_parent().get_parent()
	switches = switches.get_node("Side/Column/Switches")
	var under := (switches as Control).get_global_rect().end.y
	var short := dialog.cover.short
	screen.size = size_was
	assert_bool(short).is_false()
	assert_float(placed.rule.size.x).is_greater_equal(ProofArt.RULE_LEAST)
	assert_float(placed.fan.x).is_greater(placed.rule.end.x)
	assert_float(placed.tin.x).is_greater(placed.fan.x)
	assert_float(placed.tin.x + ProofArt.LID_BESIDE + ProofArt.TIN + pane_at.x).is_less(
		back.position.x
	)
	assert_bool(spot.has_area()).is_true()
	assert_float(spot.position.y + spot_at.y).is_greater(under)
	assert_float(spot.end.y + spot_at.y).is_less(back.position.y)


## Where the column has no room for the ticket it lies in the foot left of Back, the rule, the fan
## and the tin left of it in turn.
func test_the_ticket_lies_in_the_foot_short_of_room_in_the_column() -> void:
	var screen := get_tree().root
	var size_was := screen.size
	screen.size = Vector2i(1920, 1080)
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	dialog.switches.custom_minimum_size.y = 600.0
	await get_tree().process_frame
	await get_tree().process_frame
	var cover := dialog.cover
	var side := cover._side_ticket()
	var spot := cover.ticket_spot()
	var back := dialog.back.get_global_rect()
	var placed := cover.places()
	var pane_at := dialog._pane.global_position
	var cover_at := cover.global_position
	screen.size = size_was
	assert_bool(side.has_area()).is_false()
	assert_bool(spot.has_area()).is_true()
	assert_float(spot.end.x + cover_at.x).is_less(back.position.x)
	assert_float(placed.tin.x + ProofArt.LID_BESIDE + ProofArt.TIN + pane_at.x).is_less(
		spot.position.x + cover_at.x
	)


## On a short screen, a phone's, the mat has little room inside it and the cards little round them
## on the sheet; nothing lies in the foot, as there is none.
func test_a_short_screen_has_nothing_in_its_foot() -> void:
	var screen := get_tree().root
	var scale_was := screen.content_scale_factor
	var size_was := screen.size
	screen.size = Vector2i(2400, 1080)
	screen.content_scale_factor = 2.0
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	await get_tree().process_frame
	var placed := dialog.cover.places()
	var top := dialog._pane.get_theme_stylebox(&"panel").get_margin(SIDE_TOP)
	var well := dialog.tabs.get_current_tab_control().get_node("Well") as ListBox.Well
	var inset := well.inset
	var short := dialog.cover.short
	# Put back, the screen fits the dialog again at once, so all of it is read before.
	screen.content_scale_factor = scale_was
	screen.size = size_was
	assert_bool(short).is_true()
	assert_float(top).is_equal(ProofCover.INSIDE_SHORT[SIDE_TOP])
	assert_int(inset).is_equal(ProofCover.SHEET_IN_SHORT)
	assert_bool(placed.rule.has_area()).is_false()
	assert_object(placed.fan).is_equal(Vector2.ZERO)
	assert_object(placed.tin).is_equal(Vector2.ZERO)


## The spec sheets are printed on the House's paper in ink; Back is a slip of the stock, the tabs
## the sheets' tabs, the switch and the stack's field paper too.
func test_the_spec_sheet_and_the_controls_are_paper() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	for pane: Control in [dialog.joker_pane, dialog.item_pane]:
		var look := pane.get_theme_stylebox(&"panel") as TicketStyle
		assert_object(look.fill).is_equal(HouseTheme.PAPER)
	var named := dialog.joker_pane.get("_name") as Label
	assert_object(named.get_theme_color(&"font_color")).is_equal(HouseTheme.INK)
	assert_object(dialog.back.get_theme_stylebox(&"normal")).is_instanceof(ProofStyle)
	assert_object(dialog.tab_bar.get_theme_stylebox(&"tab_selected")).is_instanceof(ProofStyle)
	assert_object(dialog.detailed_switch.get_theme_icon(&"checked")).is_instanceof(
		AtlasTicketStyle.Switch
	)
	assert_bool(dialog.stepper.on_paper).is_true()


## The mat is drawn again only for a move of a pixel or more: the hair a layout wobbles by as the
## column beside the cards changes would draw the whole of it again into a picture for nothing.
func test_the_mat_is_not_drawn_again_for_a_hair() -> void:
	var a := Rect2(Vector2(44.0, 165.0), Vector2(1254.0, 717.0))
	assert_bool(ProofCover._near(a, Rect2(Vector2(44.0, 166.0), Vector2(1254.0, 717.0)))).is_true()
	assert_bool(ProofCover._near(a, Rect2(Vector2(44.0, 165.0), Vector2(1254.0, 720.0)))).is_false()


## Both pages' sheets are the same, so one picture of the mat serves both: what a sheet says in its
## foot is its own, drawn over it.
func test_one_mat_for_both_pages() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	Game.settings.profile.catalog.use_item(&"bomb")
	var dialog := await _open()
	await get_tree().process_frame
	dialog.cover._settled()
	var jokers := dialog.cover._settled_sheet
	assert_bool(jokers.has_area()).is_true()
	dialog.switch_tab(1)
	await get_tree().process_frame
	await get_tree().process_frame
	dialog.cover._settled()
	assert_object(dialog.cover._settled_sheet).is_equal(jokers)
	assert_str(dialog.cover.slug()).contains("POWER-UP SET")


## What the proof says of each page: how many of how many were printed, in the sheet's foot and on
## the job ticket, whose job it is, and the license's number on it.
func test_the_job_lines() -> void:
	Game.settings.license_holder = "Snake Eyes Sam"
	Game.settings.license_number = "jj-123456"
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	catalog.take_joker(&"aimbot")
	var dialog := await _open()
	var jokers := CatalogDialog.CATALOG.jokers.size()
	var items := CatalogDialog.items_in_order().size()
	assert_str(dialog.cover.slugs[0]).contains("2 OF %d PRINTED" % jokers)
	assert_str(dialog.cover.slugs[1]).contains("0 OF %d PRINTED" % items)
	assert_str(dialog.cover.ticket_head).contains("JJ-123456")
	var said := ""
	for line: PackedStringArray in dialog.cover.tickets[0]:
		said += " ".join(line) + "\n"
	assert_str(said).contains("Snake Eyes Sam")
	assert_str(said).contains("2 of %d" % jokers)


## The motto in the sheet's foot by the story's stage: the House's press proof, then its proof of
## the terms it keeps.
func test_the_motto_by_stage() -> void:
	Story.override = Story.Stage.CUSTOMER
	var dialog := await _open()
	assert_str(dialog.cover.motto).is_equal("PRESS PROOF  ·  PRINTED BY THE HOUSE")
	dialog.free()
	Story.override = Story.Stage.PARTICIPANT
	dialog = await _open()
	assert_str(dialog.cover.motto).is_equal("PROOF OF TERMS  ·  KEPT ON FILE")
	dialog.free()
	Story.override = Story.Stage.OPERATOR
	dialog = await _open()
	assert_str(dialog.cover.motto).is_equal("PROOF OF TERMS  ·  APPROVED BY YOU")
