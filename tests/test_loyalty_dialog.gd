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


## The cursor starts at the slip road and drives the roads that way from a landmark: left to the
## Strip's first, right to the Department's. Where no road goes that way, it goes to the nearest
## landmark that way all the same, the High Limit Room's down Chip Alley; only past the edge of the
## map is there nowhere to go.
func test_the_cursor_drives_the_roads() -> void:
	var dialog := await _open()
	assert_str(String(dialog.cursor.at)).is_equal("slip_road")
	assert_bool(_push(dialog, Vector2i.UP)).is_true()
	assert_str(String(dialog.cursor.at)).is_not_equal("slip_road")
	dialog.map_view.drive_to(&"slip_road")
	dialog.cursor.finish()
	assert_bool(_push(dialog, Vector2i.LEFT)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("dealers_visor")
	assert_bool(_push(dialog, Vector2i.UP)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")
	assert_bool(_push(dialog, Vector2i.LEFT)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("decoy_and_wipe")
	assert_bool(_push(dialog, Vector2i.DOWN)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("more_rare_cards")
	dialog.map_view.drive_to(&"slip_road")
	dialog.cursor.finish()
	assert_bool(_push(dialog, Vector2i.RIGHT)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("racing_stripes")
	dialog.map_view.drive_to(&"card_suits")
	dialog.cursor.finish()
	assert_bool(_push(dialog, Vector2i.DOWN)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("chip_trail")
	# The landmark furthest left has nowhere further left to go.
	var layout := dialog.map_view.layout
	var leftmost := &""
	for each: LoyaltyLandmark in layout.drawn():
		if leftmost == &"" or layout.points[each.id].x < layout.points[leftmost].x:
			leftmost = each.id
	dialog.map_view.drive_to(leftmost)
	dialog.cursor.finish()
	assert_bool(_push(dialog, Vector2i.LEFT)).is_false()
	assert_str(String(dialog.cursor.at)).is_equal(String(leftmost))


## The stick drives a landmark a push: every move of it held over reads as a push, and only the
## first drives, until it has been let go; a pad held over goes on as [PadRepeat] sends the way
## again, GAME.md 4.2.
func test_the_stick_drives_a_landmark_a_push() -> void:
	var dialog := await _open()
	dialog.map_view.drive_to(&"slip_road")
	dialog.cursor.finish()
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	for value: float in [0.6, 0.8, 1.0, 0.9]:
		stick.axis_value = value
		dialog._input(stick)
		dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_equal("racing_stripes")
	var again := InputEventAction.new()
	again.action = &"ui_up"
	again.pressed = true
	dialog._input(again)
	dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_not_equal("racing_stripes")
	var went := dialog.cursor.at
	# Let go back to the middle, then pushed again, the other way, it drives once more.
	for value: float in [-0.3, 0.0, -0.7, -1.0]:
		stick.axis_value = value
		dialog._input(stick)
		dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_not_equal(String(went))


## Pushed back the way it came while still on the first stretch of a road, the kart turns round
## onto it and stops before the sign it left, rather than the drive being cut on nothing: what is
## left of the road behind it is a single point, and the stop is measured from the kart.
func test_turning_back_on_the_first_stretch_of_a_road() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	var going := &"dealers_visor"
	var line := view.layout.road(&"slip_road", going)
	# Driving to it, halfway along the first stretch of the road's line.
	dialog.cursor.point = line[0].lerp(line[1], 0.5)
	view._driven.assign([&"slip_road", going])
	dialog.cursor.drive(PackedVector2Array([line[-1]]), going)
	assert_bool(dialog.cursor.is_driving()).is_true()
	assert_bool(view.drive_toward(view._way_to(going, &"slip_road"))).is_true()
	dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_equal("slip_road")


## Pushed back and forth along a road faster than the kart drives it, every push is heard at once:
## the kart turns round each time from where it is, rather than the choice freezing until it gets
## to where it was turned back to.
func test_back_and_forth_while_it_drives() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	var here := &"racing_stripes"
	var there := &"slip_road"
	view.drive_to(here)
	dialog.cursor.finish()
	var on := view._way_to(here, there)
	var back := view._way_to(there, here)
	for time: int in 3:
		assert_bool(view.drive_toward(on)).is_true()
		assert_str(String(dialog.cursor.at)).is_equal(String(there))
		# A little way along, pushed back, and pushed on again before it is back.
		dialog.cursor._process(0.12)
		assert_bool(dialog.cursor.is_driving()).is_true()
		assert_bool(view.drive_toward(back)).is_true()
		assert_str(String(dialog.cursor.at)).is_equal(String(here))
		assert_bool(dialog.cursor.is_driving()).is_true()
	dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_equal(String(here))


## The mouse over a landmark is a pointing hand, so it is plain a click chooses it, and the arrow
## over the paper between them.
func test_a_hand_over_a_landmark() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	var over := InputEventMouseMotion.new()
	over.position = view.sign_rect(&"slip_road").get_center()
	view._gui_input(over)
	assert_int(view.mouse_default_cursor_shape).is_equal(Control.CURSOR_POINTING_HAND)
	over.position = view.sign_rect(&"slip_road").position - Vector2(60.0, 60.0)
	view._gui_input(over)
	assert_int(view.mouse_default_cursor_shape).is_equal(Control.CURSOR_ARROW)


## The bulbs of the Strip's sign the cursor is at chase round it, the sign drawn again as they
## step; a closed one's and a sign of the Department's have none, and the map is not drawn again
## for them.
func test_the_bulbs_chase_round_a_marquee() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	view.drive_to(&"dealers_visor")
	dialog.cursor.finish()
	var was := view.chase
	view._process(LoyaltyMapView.CHASE_EVERY * 3.5)
	assert_int(view.chase).is_greater(was)
	view.drive_to(&"rare_cards")
	dialog.cursor.finish()
	assert_int(Loyalty.standing(view.profile, Loyalty.map().landmark(&"rare_cards"))).is_equal(
		Loyalty.Standing.CLOSED
	)
	was = view.chase
	view._process(LoyaltyMapView.CHASE_EVERY * 3.5)
	assert_int(view.chase).is_equal(was)
	view.drive_to(&"slip_road")
	dialog.cursor.finish()
	view.drive_to(&"racing_stripes")
	dialog.cursor.finish()
	was = view.chase
	view._process(LoyaltyMapView.CHASE_EVERY * 3.5)
	assert_int(view.chase).is_equal(was)


## A click on the roundabout out of view drives the cursor there and brings the roundabout into
## the middle of the view, not the place the cursor set off from.
func test_a_click_on_the_roundabout_brings_it_into_view() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	view.zoom_to(LoyaltyMapView.ZOOM_MOST, view.size * 0.5)
	view.stand_at(&"slip_road")
	(
		assert_bool(view.sign_rect(Loyalty.ROUNDABOUT).intersects(Rect2(Vector2.ZERO, view.size)))
		. is_false()
	)
	view.picked.emit(Loyalty.ROUNDABOUT)
	var middle := view._clamped(view.size * 0.5 - view.layout.ring_middle * view.zoom)
	assert_vector(view._goal).is_equal_approx(middle, Vector2.ONE * 0.5)
	dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_equal(String(Loyalty.ROUNDABOUT))


## The map coming round to what was chosen goes on to it through a change in its room, rather than
## stopping where the cursor set off from; the side keeps its scroll bar's room, so a pane that
## scrolls, the roundabout's on a short screen, does not change the map's room at all.
func test_the_map_comes_round_through_a_change_in_its_room() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	assert_int(dialog._side.vertical_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_RESERVE)
	view.zoom_to(LoyaltyMapView.ZOOM_MOST, view.size * 0.5)
	view.stand_at(&"slip_road")
	view.picked.emit(Loyalty.ROUNDABOUT)
	view.size -= Vector2(8.0, 0.0)
	# The well puts the room back as it lays out again, a change of its own.
	await get_tree().process_frame
	await get_tree().process_frame
	for i: int in 60:
		view._process(0.1)
	var middle := view._clamped(view.size * 0.5 - view.layout.ring_middle * view.zoom)
	assert_vector(view.offset).is_equal_approx(middle, Vector2.ONE)


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
		[&"slip_road", &"dealers_visor", &"rare_cards", &"decoy_and_wipe", &"card_suits"]
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
	_push(dialog, Vector2i.UP)
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.HOUSE)
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		if each.district == LoyaltyLandmark.District.OFF_THE_BOOKS:
			assert_str(String(dialog.cursor.at)).is_not_equal(String(each.id))
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
	assert_bool(dialog.map_view.drive_toward(Vector2i.UP)).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("torn_up")
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.KIT)
	# Driven in over the foot of Kit's sheet, where the road comes onto it, rather than set down.
	assert_bool(dialog.cursor.is_driving()).is_true()
	assert_float(dialog.cursor.point.y).is_equal_approx(dialog.map_view.layout.paper.y, 1.0)
	dialog.cursor.finish()
	assert_bool(dialog.cursor.is_driving()).is_false()
	assert_float(dialog.cursor.point.y).is_less(dialog.map_view.layout.paper.y - 10.0)
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
	for named: String in ["The Counting Room", "The High Limit Room", "The Winners' Circle"]:
		assert_str(opens).contains(named)
	assert_str(opens).contains(LoyaltyPane.OR)
	dialog.pane.show_landmark(profile, map.landmark(&"card_shark"))
	assert_str(_label(dialog.pane, "Standing").text).contains(LoyaltyPane.KEYSTONE.to_upper())
	assert_str(_label(dialog.pane, "Opens").text).starts_with("Opens once every road in is won")
	# A keystone opens only once every road into it is won, so it never opens the way in to it.
	for pair: Array in [
		[&"cursed_cards", &"card_shark"],
		[&"services", &"card_shark"],
		[&"clean_record", &"showroom"],
		[&"dashed_marks", &"showroom"],
	]:
		var keystone := map.landmark(pair[1])
		assert_str(LoyaltyPane.opens_by(profile, map.landmark(pair[0]))).is_not_empty()
		assert_str(LoyaltyPane.opens_by(profile, map.landmark(pair[0]))).not_contains(
			keystone.title
		)


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
	profile.loyalty.run = PackedStringArray(["the_yard"])
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
## is kept; while one is, the title's Clubhouse and the program's button wear the NEW tag, but not
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
	# The little drawings are many, and off every sign and road.
	assert_int(layout.doodles.size()).is_greater_equal(100)
	for doodle: Dictionary in layout.doodles:
		var at: Vector2 = doodle["at"]
		for id: StringName in layout.points:
			assert_bool(layout.sign_rect(id).has_point(at)).is_false()
		for each: Dictionary in layout.roads:
			var line: PackedVector2Array = each["points"]
			for i: int in range(1, line.size()):
				var near := Geometry2D.get_closest_point_to_segment(at, line[i - 1], line[i])
				assert_float(near.distance_to(at)).is_greater_equal(20.0)
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
	# The road it is on first, then back through the slip road.
	assert_array(dialog.map_view._driven).contains([&"slip_road"])
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


## The card in the corner never takes the cursor, which stays on the map however far right it is
## driven; its own bind, drawn on its bottom right corner with keys or a pad in hand, shows it in
## full, accept turns it over, and Back puts it away with the dialog still up and the cursor back
## on the map.
func test_the_card_shows_in_full() -> void:
	var dialog := await _open()
	assert_int(dialog.card_corner.focus_mode).is_equal(Control.FOCUS_NONE)
	var right := InputEventAction.new()
	right.action = &"ui_right"
	right.pressed = true
	for i: int in 8:
		dialog._input(right)
		dialog.cursor.finish()
	assert_bool(dialog.card_corner.has_focus()).is_false()
	dialog._keyboard = true
	dialog._pointer = false
	dialog._show_binds()
	var bind := dialog.cover.get_node_or_null("CardBind") as Control
	assert_object(bind).is_not_null()
	var card_at := dialog.card_corner.get_global_rect()
	assert_bool(bind.get_global_rect().get_center().x > card_at.get_center().x).is_true()
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	var card := InputEventAction.new()
	card.action = LoyaltyDialog.CARD_ACTION
	card.pressed = true
	dialog._input(card)
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
	assert_bool(dialog.map_view.has_focus()).is_true()
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


## Once welcomed, the License tab of the settings has the loyalty card beside the license, which
## shows it in full as the program does; not before.
func test_the_license_tab_holds_the_loyalty_card() -> void:
	Game.settings.license_number = "JJ-212212"
	Game.settings.profile.loyalty.welcomed = false
	var stranger := LicenseTab.make(Game.settings)
	_holder.add_child(stranger)
	await get_tree().process_frame
	assert_object(stranger.loyalty_card).is_null()
	stranger.free()
	Game.settings.profile.loyalty.welcomed = true
	var tab := LicenseTab.make(Game.settings)
	_holder.add_child(tab)
	await get_tree().process_frame
	await get_tree().process_frame
	var card := tab.loyalty_card
	assert_object(card).is_not_null()
	var license := (tab.find_child("LicenseCard", true, false) as Control).get_global_rect()
	var held := card.get_global_rect()
	if tab.get_viewport_rect().size.x >= 1280.0:
		assert_float(held.position.x).is_greater(license.end.x)
		assert_float(held.size.y).is_equal_approx(license.size.y, 1.0)
	var press := InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = true
	card.gui_input.emit(press)
	assert_object(tab.loyalty_view).is_not_null()
	tab.loyalty_view.put_away.emit()
	assert_object(tab.loyalty_view).is_null()
	tab.free()


## The sheet is drawn once into a picture at the zoom the map rests at, which is what is shown; a
## zoom on its way is not drawn again at, and once the zoom has rested a moment it is, never more
## than so many pixels across.
func test_the_sheet_is_drawn_once_and_again_once_the_zoom_rests() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	var bake := view.get_node("Bake") as LoyaltyMapBake
	for i: int in LoyaltyMapBake.FRAMES + 2:
		await get_tree().process_frame
	assert_bool(bake.is_up()).is_true()
	assert_float(bake.scale_up()).is_equal_approx(bake.scale_wanted(), 0.0001)
	var was := bake.scale_up()
	view.zoom_to(view.zoom * LoyaltyMapView.ZOOM_STEP, view.size * 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(bake.scale_up()).is_equal(was)
	await get_tree().create_timer(LoyaltyMapBake.SETTLE + 0.1).timeout
	for i: int in LoyaltyMapBake.FRAMES + 2:
		await get_tree().process_frame
	assert_float(bake.scale_up()).is_equal_approx(bake.scale_wanted(), 0.0001)
	assert_float(bake.scale_up()).is_greater(was)
	view.zoom_to(LoyaltyMapView.ZOOM_MOST, view.size * 0.5)
	var whole := view.layout.paper + Vector2.ONE * LoyaltyMapBake.ROOM * 2.0
	assert_float(maxf(whole.x, whole.y) * bake.scale_wanted()).is_less_equal(LoyaltyMapBake.MOST)


## The kart's sheets are drawn again only as it turns, not every frame it stands or drives on.
func test_the_kart_is_drawn_again_only_as_it_turns() -> void:
	var dialog := await _open()
	var cursor := dialog.cursor
	for i: int in LoyaltyCursor.FIRST_FOR + 2:
		await get_tree().process_frame
	assert_int(cursor._redraw).is_equal(0)
	cursor.heading = cursor.heading.rotated(PI * 0.5)
	await get_tree().process_frame
	assert_int(cursor._redraw).is_greater(0)


## On a phone at a big UI scale, the screen 1200 by 540, the dialog stays on the screen with the
## roundabout's long pane up, the pane scrolling under the card rather than pushing it off, the
## line under the title beside it and the side column narrower; and a touch screen draws no binds
## of keys or pads.
func test_a_phone_holds_the_whole_dialog() -> void:
	var profile := Game.settings.profile
	for id: StringName in [&"card_shark", &"showroom"]:
		profile.loyalty.win(id)
	Loyalty.settle(profile)
	var screen := get_tree().root
	var scale_was := screen.content_scale_factor
	var size_was := screen.size
	screen.size = Vector2i(2400, 1080)
	screen.content_scale_factor = 2.0
	var touch_was := TouchInput.enabled
	TouchInput.enabled = true
	LoyaltyDialog.stood_at = Loyalty.ROUNDABOUT
	var dialog := await _open()
	await get_tree().process_frame
	TouchInput.enabled = touch_was
	var room := screen.get_visible_rect().grow(1.0)
	var held := dialog._pane.get_global_rect()
	var back := dialog.back.get_global_rect()
	var line_beside := dialog._line.get_parent() == dialog._head and dialog._line.visible
	var side := dialog._side.custom_minimum_size.x
	screen.content_scale_factor = scale_was
	screen.size = size_was
	assert_float(room.size.y).is_less(600.0)
	assert_object(dialog.pane.get_parent().get_parent().get_parent()).is_instanceof(ScrollContainer)
	assert_bool(room.encloses(held)).is_true()
	assert_bool(room.encloses(back)).is_true()
	# The whole screen the dialog's, the shade nowhere round it.
	assert_float(held.size.x).is_greater(room.size.x - 4.0)
	# The line under the title beside it, the head one row; the side column narrower, the map
	# the wider for it.
	assert_bool(line_beside).is_true()
	assert_float(side).is_equal(LoyaltyDialog.side_wide(1200.0, false))
	assert_float(LoyaltyDialog.side_wide(1200.0, false)).is_less(LoyaltyDialog.SIDE_MOST)
	assert_float(LoyaltyDialog.side_wide(1920.0, true)).is_equal(LoyaltyDialog.SIDE_MOST)
	assert_float(LoyaltyDialog.side_wide(600.0, false)).is_equal(LoyaltyDialog.SIDE_LEAST)
	var up := dialog._hint_row.get_children().filter(
		func(child: Node) -> bool: return not child.is_queued_for_deletion()
	)
	assert_array(up).is_empty()


## At 200% on a screen 1920 by 1080, the keys' binds shown, the head stays on its one row in the
## room there is: the switch's bind kept, the map's keys' left out, and the dialog no wider than
## the screen for them. At 100% there is room for all of it and the line beside the title.
func test_the_head_keeps_to_the_room() -> void:
	var screen := get_tree().root
	var scale_was := screen.content_scale_factor
	var size_was := screen.size
	screen.size = Vector2i(1920, 1080)
	var held: Array[bool] = []
	for scale: float in [2.0, 1.0]:
		screen.content_scale_factor = scale
		var dialog := await _open()
		dialog._keyboard = true
		dialog._pointer = false
		dialog._show_binds()
		await get_tree().process_frame
		await get_tree().process_frame
		var room := screen.get_visible_rect().grow(1.0)
		held.append(room.encloses(dialog._pane.get_global_rect()))
		held.append(dialog._how != null and dialog._how.visible == (scale == 1.0))
		held.append(dialog._line.visible == (scale == 1.0))
		held.append(dialog._line.get_parent() == dialog._head)
		dialog.queue_free()
		await get_tree().process_frame
	screen.content_scale_factor = scale_was
	screen.size = size_was
	assert_array(held).not_contains([false])


## The map runs right to the edge of its well, nothing of it lost to a border, cut to the well's
## shape and its shade and rim drawn over it; the list in the same well keeps its room round its
## rows.
func test_the_map_runs_to_the_wells_edge() -> void:
	var dialog := await _open()
	var cut := dialog.map_view.get_parent() as ListBox.Cut
	var well := cut.get_parent() as ListBox.Well
	assert_bool(well.flush).is_true()
	assert_int(cut.clip_children).is_equal(CanvasItem.CLIP_CHILDREN_ONLY)
	assert_vector(dialog.map_view.size).is_equal(well.size)
	var room := dialog.list.get_parent() as MarginContainer
	assert_int(room.get_theme_constant(&"margin_left")).is_equal(ListBox.INSET)
	var over := well.get_child(well.get_child_count(true) - 1, true)
	assert_str(String(over.name)).is_equal("Over")


## Zoomed out as far as it goes, the whole map lies in its well with a little room round it.
func test_the_map_zooms_out_to_a_little_room_round_it() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	view.zoom_to(0.01, view.size * 0.5)
	var room := view.size - view.layout.paper * view.zoom
	assert_float(minf(room.x, room.y)).is_equal_approx(LoyaltyMapView.FIT_ROOM * 2.0, 0.5)


## Zoomed in, the map is dragged a little past its edge either way, the well showing beyond it,
## and no further.
func test_the_map_is_dragged_a_little_past_its_edge() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	view.zoom_to(LoyaltyMapView.ZOOM_MOST, view.size * 0.5)
	var room := Vector2.ONE * LoyaltyMapView.FIT_ROOM
	view.pan_by(Vector2.ONE * 100000.0)
	assert_vector(view.offset).is_equal_approx(room, Vector2.ONE * 0.01)
	view.pan_by(Vector2.ONE * -200000.0)
	var far := view.size - view.layout.paper * view.zoom - room
	assert_vector(view.offset).is_equal_approx(far, Vector2.ONE * 0.01)


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
	# The dialogs' page key after, E, turns to Kit's, see [DialogBinds].
	var turn := InputEventAction.new()
	turn.action = LoyaltyDialog.SHEET_ON
	turn.pressed = true
	dialog._input(turn)
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.KIT)
	assert_str(String(dialog.cursor.at)).is_equal("pencil_trail")
	assert_str(String(dialog.pane.shown)).is_equal("pencil_trail")
	assert_int(dialog.sheet_tabs.current_tab).is_equal(LoyaltyMapLayout.Sheet.KIT)
	dialog.sheet_tabs.current_tab = LoyaltyMapLayout.Sheet.HOUSE
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.HOUSE)
	assert_str(String(dialog.cursor.at)).is_equal("dealers_visor")
	# On a pad the shoulders are the page keys: the right to Kit's, the left back to the House's.
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	shoulder.pressed = true
	dialog._input(shoulder)
	assert_int(dialog.sheet_tabs.current_tab).is_equal(LoyaltyMapLayout.Sheet.KIT)
	assert_str(String(dialog.cursor.at)).is_equal("pencil_trail")
	shoulder.button_index = JOY_BUTTON_LEFT_SHOULDER
	dialog._input(shoulder)
	assert_int(dialog.map_view.sheet).is_equal(LoyaltyMapLayout.Sheet.HOUSE)
	# Their binds at the tabs' end: the key, or the two shoulders.
	dialog._keyboard = true
	dialog._pointer = false
	dialog._show_binds()
	var up := dialog._sheet_hint.get_children().filter(
		func(child: Node) -> bool: return not child.is_queued_for_deletion()
	)
	assert_int(up.size()).is_equal(1)
	# The dialogs' page keys, see [DialogBinds]: the two shoulders on a pad, Q and E on keys.
	var shoulders := DialogBinds.pages(false, Color.WHITE, 18)
	var glyphs: Array[Node] = shoulders.find_children("*", "InputGlyph", true, false)
	assert_int(glyphs.size()).is_equal(2)
	for glyph: Node in glyphs:
		assert_int((glyph as InputGlyph).kind).is_equal(InputGlyph.Kind.SHOULDER)
	shoulders.free()
	var keys := DialogBinds.pages(true, Color.WHITE, 18)
	var said := ""
	for glyph: Node in keys.find_children("*", "InputGlyph", true, false):
		said += (glyph as InputGlyph).caption + " "
	assert_str(said).contains("Q").contains("E")
	keys.free()


## On a pad the triggers zoom the map for as long as they are held, faster the further they are
## pulled, the right in and the left out, about the landmark the cursor is at; the right stick
## moves it. A trigger's pull is heard here and does nothing else.
func test_the_triggers_zoom_and_the_right_stick_moves() -> void:
	var dialog := await _open()
	var view := dialog.map_view
	view.zoom_to(1.0, view.size * 0.5)
	var at := view.offset + dialog.cursor.point * view.zoom
	dialog.pad_on_map(1.0, Vector2.ZERO, 0.25)
	assert_float(view.zoom).is_equal_approx(pow(2.0, 0.25 * LoyaltyDialog.ZOOM_RATE), 0.001)
	# The landmark the cursor is at stays where it was.
	assert_vector(view.offset + dialog.cursor.point * view.zoom).is_equal_approx(
		at, Vector2.ONE * 0.5
	)
	var zoomed := view.zoom
	dialog.pad_on_map(-0.5, Vector2.ZERO, 0.2)
	assert_float(view.zoom).is_less(zoomed)
	# Pushed left, more of the map to the left comes into view.
	var was := view.offset
	dialog.pad_on_map(0.0, Vector2(-1.0, 0.0), 0.1)
	assert_float(view.offset.x).is_greater(was.x)
	var pull := InputEventJoypadMotion.new()
	pull.axis = LoyaltyDialog.ZOOM_IN
	pull.axis_value = 1.0
	var before := view.zoom
	assert_bool(dialog._zoom_by(pull)).is_true()
	assert_float(view.zoom).is_equal(before)
