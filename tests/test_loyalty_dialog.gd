extends GdUnitTestSuite
## The loyalty program's dialog, GAME.md 8.9: the cursor driving the map's roads, the pane's words,
## the list of open bets nearest done first, the NEW tags, the program's name by stage and the
## ways in, see [LoyaltyDialog], [LoyaltyMapView], [LoyaltyPane] and [LoyaltyList].

const PATH := "user://test_loyalty_dialog.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.story.on = false
	_welcome()
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)


func after_test() -> void:
	Story.override = -1
	LoyaltyDialog.listed = false
	LoyaltyDialog.stood_at = &""
	# Gone before the scratch files are: a dialog going keeps the NEW tags it cleared.
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _welcome() -> void:
	var state := Game.settings.profile.loyalty
	state.welcomed = true
	state.win(&"slip_road")
	state.look_at(&"slip_road")


func _open() -> LoyaltyDialog:
	var dialog := LoyaltyDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


## Drives the cursor of [param dialog] [param way] and has it there at once.
func _push(dialog: LoyaltyDialog, way: Vector2i) -> bool:
	var went := dialog.map_view.drive_toward(way)
	dialog.cursor.finish()
	return went


## The cursor starts at the slip road and drives the roads that way from a landmark: left and up to
## the Strip's first, right to the Department's; nowhere where no road goes.
func test_the_cursor_drives_the_roads() -> void:
	var dialog := await _open()
	assert_str(String(dialog.cursor.at)).is_equal("slip_road")
	assert_bool(_push(dialog, Vector2i.UP)).is_false()
	assert_bool(_push(dialog, Vector2i.LEFT)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("dealers_visor")
	assert_bool(_push(dialog, Vector2i.LEFT)).is_false()
	assert_bool(_push(dialog, Vector2i.UP)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")
	assert_bool(_push(dialog, Vector2i.RIGHT)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("decoy_and_wipe")
	assert_bool(_push(dialog, Vector2i.DOWN)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("more_rare_cards")
	dialog.map_view.drive_to(&"slip_road")
	dialog.cursor.finish()
	assert_bool(_push(dialog, Vector2i.RIGHT)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("racing_stripes")


## A click on a landmark drives the cursor there along the fewest roads, closed landmarks and all,
## and the pane says where it came.
func test_a_click_drives_the_cursor_there() -> void:
	var dialog := await _open()
	dialog.map_view.picked.emit(&"card_suits")
	assert_bool(dialog.cursor.is_driving()).is_true()
	dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_equal("card_suits")
	assert_str(String(dialog.pane.shown)).is_equal("card_suits")
	var route := dialog.map_view._route(&"slip_road", &"card_suits")
	assert_array(route).is_equal(
		[&"slip_road", &"dealers_visor", &"rare_cards", &"chip_trail", &"card_suits"]
	)


## The cells of a road from the slip road to the Strip's first landmark: along the foot of the map,
## round the bend and up.
func test_a_road_runs_through_its_cells() -> void:
	var map := Loyalty.map()
	var cells := map.path(&"slip_road", &"dealers_visor")
	assert_object(cells[0]).is_equal(map.at(&"slip_road"))
	assert_object(cells[-1]).is_equal(map.at(&"dealers_visor"))
	assert_object(cells[1] - cells[0]).is_equal(Vector2i.LEFT)
	assert_object(cells[-1] - cells[-2]).is_equal(Vector2i.UP)
	assert_array(map.path(&"slip_road", &"card_suits")).is_empty()
	for run: Dictionary in map.runs():
		assert_array(run["cells"]).is_not_empty()


## With the story off, Kit's roads are not on the map at all and no road leads up to them; with it
## on and a note found they are, in pencil, and the cursor drives up into them.
func test_off_the_books_with_the_story() -> void:
	var dialog := await _open()
	assert_bool(_ids(dialog.map_view.drawn()).has(&"pencil_trail")).is_false()
	dialog.map_view.drive_to(&"cursed_cards")
	dialog.cursor.finish()
	assert_bool(_push(dialog, Vector2i.UP)).is_false()
	dialog.close()
	remove_child(_holder)
	_holder.free()
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)
	Game.settings.profile.story.on = true
	Game.settings.profile.story.notes = PackedInt32Array([1])
	dialog = await _open()
	# Kit's landmarks are on Kit's sheet, not the House's.
	assert_bool(_ids(dialog.map_view.drawn()).has(&"pencil_trail")).is_false()
	var pencil := 0
	for run: Dictionary in Loyalty.map().runs():
		pencil += 1 if run["pencil"] else 0
	assert_int(pencil).is_greater(0)
	dialog.map_view.drive_to(&"cursed_cards")
	dialog.cursor.finish()
	assert_bool(_push(dialog, Vector2i.UP)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("torn_up")
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.KIT)
	assert_bool(_ids(dialog.map_view.drawn()).has(&"pencil_trail")).is_true()
	assert_bool(_ids(dialog.map_view.drawn()).has(&"cursed_cards")).is_false()
	# And down again off the foot of Kit's sheet, onto the House's.
	assert_bool(_push(dialog, Vector2i.DOWN)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("cursed_cards")
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.HOUSE)


## The pane: an open landmark's name, district, bet and how far it has come, and what it pays; a
## closed one's what it pays, not what it asks, and which roads would open it; a keystone's every
## road.
func test_the_pane_says_the_landmark() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"dealers_visor")
	profile.stats[&"jokers"] = 12.0
	var dialog := await _open()
	var map := Loyalty.map()
	dialog.pane.show_landmark(profile, map.landmark(&"rare_cards"))
	assert_str(_label(dialog.pane, "Name").text).is_equal("The Card Room")
	assert_str(_label(dialog.pane, "District").text).is_equal("THE STRIP")
	assert_str(_label(dialog.pane, "Standing").text).is_equal(LoyaltyPane.OPEN.to_upper())
	assert_str(_label(dialog.pane, "Bet").text).is_equal("Take 30 jokers")
	assert_str(_label(dialog.pane, "Come").text).is_equal("12 / 30")
	var pays := LoyaltyPane.pays_of(map.landmark(&"rare_cards"))
	assert_str(str(pays[0][0])).is_equal("Joker card: Lucky Seven")
	assert_str(str(pays[-1][0])).is_equal("Paint: Checks")
	dialog.pane.show_landmark(profile, map.landmark(&"fedora"))
	assert_str(_label(dialog.pane, "Bet").text).is_equal(LoyaltyPane.ASKS_LATER)
	var opens := _label(dialog.pane, "Opens").text
	assert_str(opens).starts_with("Opens with a road from ")
	for named: String in ["Chip Alley", "Flush Row", "The Bounty Board"]:
		assert_str(opens).contains(named)
	assert_str(opens).contains(LoyaltyPane.OR)
	dialog.pane.show_landmark(profile, map.landmark(&"card_shark"))
	assert_str(_label(dialog.pane, "Standing").text).contains(LoyaltyPane.KEYSTONE.to_upper())
	assert_str(_label(dialog.pane, "Opens").text).starts_with("Opens once every road in is won")


## How far a bet has come, in its own units, and how near done it is.
func test_how_far_a_bet_has_come() -> void:
	var profile := Game.settings.profile
	var map := Loyalty.map()
	profile.stats[&"driven"] = 3170.0
	profile.stats[&"nitro"] = 95.0
	assert_str(Loyalty.progress_text(profile, map.landmark(&"racing_stripes"))).is_equal(
		"3.1 / 10 km"
	)
	assert_str(Loyalty.progress_text(profile, map.landmark(&"afterburn"))).is_equal(
		"1.5 / 3 minutes"
	)
	assert_float(Loyalty.nearness(profile, map.landmark(&"racing_stripes"))).is_equal_approx(
		0.317, 0.001
	)
	# A feat of one map has no bar: it is done in one go.
	assert_str(Loyalty.progress_text(profile, map.landmark(&"cursed_cards"))).is_empty()
	profile.loyalty.rooms = PackedStringArray(["the_yard"])
	assert_str(Loyalty.progress_text(profile, map.landmark(&"showroom"))).is_equal("1 / 3")


## The list holds the open bets only, nearest done first, and a row pressed is the map at it.
func test_the_list_is_nearest_done_first() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"dealers_visor")
	profile.loyalty.win(&"racing_stripes")
	profile.stats[&"jokers"] = 3.0
	profile.stats[&"coins"] = 0.0
	profile.stats[&"drifted"] = 1800.0
	var open := LoyaltyList.open_bets(profile)
	var ids := _ids(open)
	assert_str(String(ids[0])).is_equal("chalk_marks")
	assert_bool(ids.has(&"dealers_visor")).is_false()
	assert_bool(ids.has(&"card_suits")).is_false()
	for i: int in range(1, open.size()):
		var before := Loyalty.nearness(profile, open[i - 1])
		assert_bool(before >= Loyalty.nearness(profile, open[i])).is_true()
	var dialog := await _open()
	dialog.set_listed(true)
	assert_bool(dialog.list.is_visible_in_tree()).is_true()
	assert_bool(dialog.map_view.is_visible_in_tree()).is_false()
	assert_int(dialog.list.rows().size()).is_equal(open.size())
	dialog.list.chosen.emit(&"rare_cards")
	assert_bool(dialog.map_view.is_visible_in_tree()).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")
	assert_bool(LoyaltyDialog.listed).is_false()


## A landmark won since the program last showed it is new until the cursor has been on it, which
## is kept; while one is, the title's Extras and the program's button wear the NEW tag, but not
## for one off the books with the story off, which is not drawn.
func test_new_until_the_cursor_has_been_on_it() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"dealers_visor")
	assert_bool(Loyalty.has_fresh(profile)).is_true()
	var button := Button.new()
	add_child(button)
	CatalogCell.tag(button, Loyalty.has_fresh(profile))
	assert_object(button.get_node_or_null("New")).is_not_null()
	var dialog := await _open()
	assert_bool(profile.loyalty.is_fresh(&"dealers_visor")).is_true()
	dialog.map_view.drive_to(&"dealers_visor")
	dialog.cursor.finish()
	assert_bool(profile.loyalty.is_fresh(&"dealers_visor")).is_false()
	assert_bool(Loyalty.has_fresh(profile)).is_false()
	CatalogCell.tag(button, Loyalty.has_fresh(profile))
	assert_object(button.get_node_or_null("New")).is_null()
	dialog.close()
	await get_tree().process_frame
	var kept := Settings.new()
	kept.path = PATH
	kept.load_from_disk()
	assert_bool(kept.profile.loyalty.is_fresh(&"dealers_visor")).is_false()
	profile.loyalty.win(&"pencil_trail")
	assert_bool(Loyalty.has_fresh(profile)).is_false()
	button.free()


## The program's name and its line by the story's stage, STORY.md 6.6b, on the dialog's title.
func test_the_name_by_stage() -> void:
	var profile := Game.settings.profile
	Story.override = Story.Stage.CUSTOMER
	assert_str(LoyaltyDialog.program_name(profile)).is_equal("Loyalty Program")
	assert_str(LoyaltyDialog.program_line(profile)).is_equal("EARN REWARDS AS YOU PLAY")
	Story.override = Story.Stage.NUMBER
	assert_str(LoyaltyDialog.program_name(profile)).is_equal("Retention Program")
	Story.override = Story.Stage.OPERATOR
	var dialog := await _open()
	assert_str((dialog.find_child("Title", true, false) as Label).text).is_equal("Staff Benefits")


## The dialog goes on Back, the cursor where it stood kept for the next time it opens.
func test_back_keeps_where_the_cursor_stood() -> void:
	var dialog := await _open()
	dialog.map_view.drive_to(&"rare_cards")
	dialog.close()
	assert_str(String(LoyaltyDialog.stood_at)).is_equal("rare_cards")
	for i: int in 30:
		await get_tree().process_frame
	assert_bool(is_instance_valid(dialog)).is_false()
	dialog = await _open()
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")


## A room's pause menu has the program's button once the profile playing is welcomed, and opens
## the program over itself; not before.
func test_the_pause_menu_opens_it() -> void:
	var menu := PauseMenu.add_to(_holder)
	await get_tree().process_frame
	var button := menu.find_child("Loyalty", true, false) as Button
	assert_object(button).is_not_null()
	assert_str(button.text).is_equal("Loyalty Program")
	menu.open_loyalty()
	await get_tree().process_frame
	assert_object(menu.find_child("Loyalty", false, false)).is_instanceof(LoyaltyDialog)
	menu.free()
	Game.settings.profile.loyalty.welcomed = false
	menu = PauseMenu.add_to(_holder)
	await get_tree().process_frame
	assert_object(menu.find_child("Loyalty", true, false)).is_null()


func _ids(landmarks: Array[LoyaltyLandmark]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for each: LoyaltyLandmark in landmarks:
		ids.append(each.id)
	return ids


func _label(pane: LoyaltyPane, named: String) -> Label:
	return pane.find_child(named, true, false) as Label


## The map's layout: each road from one landmark's point to the other's, its corners rounded;
## a wash for each district drawn and none for Kit's with the story off; no little drawing on a
## sign; the same every time it is laid out.
func test_the_layout_of_the_map() -> void:
	var profile := Game.settings.profile
	var layout := LoyaltyMapLayout.of(Loyalty.map(), profile)
	assert_bool(layout.washes.has(LoyaltyLandmark.District.STRIP)).is_true()
	assert_bool(layout.washes.has(LoyaltyLandmark.District.DEPARTMENT)).is_true()
	assert_bool(layout.washes.has(LoyaltyLandmark.District.OFF_THE_BOOKS)).is_false()
	var road := layout.road(&"slip_road", &"dealers_visor")
	assert_int(road.size()).is_greater(4)
	assert_object(road[0]).is_equal(layout.points[&"slip_road"])
	assert_object(road[-1]).is_equal(layout.points[&"dealers_visor"])
	var back := layout.road(&"dealers_visor", &"slip_road")
	assert_object(back[0]).is_equal(road[-1])
	for each: Dictionary in layout.roads:
		assert_int((each["points"] as PackedVector2Array).size()).is_greater_equal(2)
	assert_array(layout.doodles).is_not_empty()
	for doodle: Dictionary in layout.doodles:
		for id: StringName in layout.points:
			assert_bool(layout.sign_rect(id).has_point(doodle["at"])).is_false()
	var again := LoyaltyMapLayout.of(Loyalty.map(), profile)
	assert_int(again.doodles.size()).is_equal(layout.doodles.size())
	assert_object(again.points[&"card_suits"]).is_equal(layout.points[&"card_suits"])
	profile.story.on = true
	profile.story.notes = PackedInt32Array([1])
	# Off the books is a sheet of its own: the House's is as it was, and Kit's has his district
	# alone, its two roads into the House's running off its foot, and nothing of the House's.
	var house := LoyaltyMapLayout.of(Loyalty.map(), profile)
	assert_bool(house.washes.has(LoyaltyLandmark.District.OFF_THE_BOOKS)).is_false()
	assert_float(house.paper.y).is_equal(layout.paper.y)
	# The House's has Kit's two roads in, in pencil, up off its top once his sheet is drawn, and none
	# before.
	var up: Array[StringName] = []
	for each: Dictionary in house.roads:
		if each.get("off_to", &"") != &"":
			up.append(each["off_to"])
			assert_bool(each["pencil"]).is_true()
			assert_float((each["points"] as PackedVector2Array)[-1].y).is_equal(0.0)
	assert_array(up).contains_exactly_in_any_order([&"torn_up", &"walk_away"])
	for each: Dictionary in layout.roads:
		assert_str(String(each.get("off_to", &""))).is_empty()
	var kit := LoyaltyMapLayout.of(Loyalty.map(), profile, LoyaltyMapLayout.Sheet.KIT)
	assert_bool(kit.washes.has(LoyaltyLandmark.District.OFF_THE_BOOKS)).is_true()
	assert_bool(kit.washes.has(LoyaltyLandmark.District.STRIP)).is_false()
	assert_bool(kit.points.has(&"pencil_trail")).is_true()
	assert_bool(kit.points.has(&"cursed_cards")).is_false()
	assert_float(kit.ring).is_equal(0.0)
	assert_array(kit.streets).is_empty()
	var off: Array[StringName] = []
	for each: Dictionary in kit.roads:
		if each.get("off_to", &"") != &"":
			off.append(each["off_to"])
			var line: PackedVector2Array = each["points"]
			assert_float(line[-1].y).is_equal(kit.paper.y)
	assert_array(off).contains_exactly_in_any_order([&"cursed_cards", &"clean_record"])
	assert_float(kit.paper.y).is_less(house.paper.y)


## A landmark chosen behind the kart while it drives turns it back from where it is, rather than
## driving on to where it was going first.
func test_a_landmark_behind_turns_the_kart_back() -> void:
	var dialog := await _open()
	dialog.map_view.picked.emit(&"card_suits")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(dialog.cursor.is_driving()).is_true()
	var point_was := dialog.cursor.point
	dialog.map_view.picked.emit(&"racing_stripes")
	assert_object(dialog.cursor.point).is_equal(point_was)
	assert_str(String(dialog.map_view._driven[0])).is_equal("slip_road")
	assert_str(String(dialog.map_view._driven[-1])).is_equal("racing_stripes")
	dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_equal("racing_stripes")


## A landmark clicked is said in the pane at once, the kart still on its way; another click takes
## the kart on from where it is, never making it jump.
func test_a_click_is_said_at_once() -> void:
	var dialog := await _open()
	dialog.map_view.picked.emit(&"dealers_visor")
	assert_str(String(dialog.pane.shown)).is_equal("dealers_visor")
	assert_bool(dialog.cursor.is_driving()).is_true()
	await get_tree().process_frame
	var point_was := dialog.cursor.point
	dialog.map_view.picked.emit(&"rare_cards")
	assert_str(String(dialog.pane.shown)).is_equal("rare_cards")
	assert_object(dialog.cursor.point).is_equal(point_was)
	assert_bool(dialog.cursor.is_driving()).is_true()
	dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")
	assert_bool(dialog.cursor.is_driving()).is_false()


## The card in the corner is picked as a button: an arrow off the map's right where no road goes
## puts the cursor on it, accept shows it in full, accept again turns it over, and Back puts it
## away with the dialog still up and the cursor back on the corner's card.
func test_the_card_shows_in_full() -> void:
	var dialog := await _open()
	var right := InputEventAction.new()
	right.action = &"ui_right"
	right.pressed = true
	for i: int in 8:
		dialog._input(right)
		dialog.cursor.finish()
	assert_bool(dialog.card_corner.has_focus()).is_true()
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	dialog._input(accept)
	var view := dialog.card_view
	assert_object(view).is_not_null()
	# The license's two buttons under it, turn over and put away.
	assert_object(view.turn).is_not_null()
	assert_object(view.away).is_not_null()
	await get_tree().create_timer(LoyaltyCardView.FLY + 0.05).timeout
	view._input(accept)
	await get_tree().create_timer(LoyaltyCardView.TURN + 0.1).timeout
	assert_bool(view.card.back).is_true()
	assert_bool(view.shine.back).is_true()
	view.turn.pressed.emit()
	await get_tree().create_timer(LoyaltyCardView.TURN + 0.1).timeout
	assert_bool(view.card.back).is_false()
	view.turn.pressed.emit()
	await get_tree().create_timer(LoyaltyCardView.TURN + 0.1).timeout
	assert_bool(view.card.back).is_true()
	# Put away with its back up, it turns face up again on the way down, as the license does.
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	view._unhandled_input(cancel)
	assert_bool(view.is_turning()).is_true()
	await get_tree().create_timer(LoyaltyCardView.FLY_BACK * 0.8).timeout
	assert_bool(view.card.back).is_false()
	assert_object(dialog.card_view).is_null()
	assert_bool(dialog.card_corner.has_focus()).is_true()
	assert_bool(is_instance_valid(dialog)).is_true()
	await get_tree().create_timer(LoyaltyCardView.FLY_BACK + 0.1).timeout
	assert_bool(is_instance_valid(view)).is_false()


## With keys or a pad in hand the binds over the map say how to drive to another landmark, the
## arrows or the stick, as well as the zoom and the list; on the list, only the list's.
func test_the_binds_say_how_to_select_a_landmark() -> void:
	var dialog := await _open()
	dialog._keyboard = true
	dialog._pointer = false
	dialog._show_binds()
	var said := _words_in(dialog._hint_row)
	assert_str(said).contains(LoyaltyDialog.SELECT)
	assert_str(said).contains(LoyaltyDialog.ZOOM)
	dialog.set_listed(true)
	dialog._show_binds()
	assert_str(_words_in(dialog._hint_row)).not_contains(LoyaltyDialog.SELECT)


## Every word written under [param node], not counting what is on its way out.
func _words_in(node: Node) -> String:
	var said := PackedStringArray()
	for label: Node in node.find_children("*", "Label", true, false):
		if not label.is_queued_for_deletion() and not label.get_parent().is_queued_for_deletion():
			said.append((label as Label).text)
	return " ".join(said)


## Once Kit's district is on the map its sheet has a tab over the map, and the bind turns to it:
## the cursor at Kit's way in, and back on the House's sheet where it stood.
func test_the_sheets_turn() -> void:
	var dialog := await _open()
	assert_bool(dialog.sheet_tabs.visible).is_false()
	dialog.close()
	remove_child(_holder)
	_holder.free()
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)
	Game.settings.profile.story.on = true
	Game.settings.profile.story.notes = PackedInt32Array([1])
	dialog = await _open()
	assert_bool(dialog.sheet_tabs.visible).is_true()
	dialog.map_view.drive_to(&"dealers_visor")
	dialog.cursor.finish()
	var turn := InputEventAction.new()
	turn.action = LoyaltyDialog.SHEET_ACTION
	turn.pressed = true
	dialog._input(turn)
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.KIT)
	assert_str(String(dialog.cursor.at)).is_equal("pencil_trail")
	assert_str(String(dialog.pane.shown)).is_equal("pencil_trail")
	assert_int(dialog.sheet_tabs.current_tab).is_equal(LoyaltyMapLayout.Sheet.KIT)
	dialog.sheet_tabs.current_tab = LoyaltyMapLayout.Sheet.HOUSE
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.HOUSE)
	assert_str(String(dialog.cursor.at)).is_equal("dealers_visor")
