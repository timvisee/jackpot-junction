extends GdUnitTestSuite
## The loyalty program's map of GAME.md 8.9, as it is drawn: the grid read into landmarks and roads,
## and the first map holding together, see [LoyaltyMap].

const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const LATER_SET: PowerUpTable = preload("res://data/powerups/later_set.tres")


func _first() -> LoyaltyMap:
	return load(Loyalty.MAP_PATH) as LoyaltyMap


func _landmark(id: StringName, mark: String, entry := false) -> LoyaltyLandmark:
	var landmark := LoyaltyLandmark.new()
	landmark.id = id
	landmark.mark = mark
	landmark.entry = entry
	return landmark


## A map of [param rows] with a landmark for each of [param marks], the first open from the start.
func _drawn(rows: Array[String], marks: String) -> LoyaltyMap:
	var drawn := LoyaltyMap.new()
	drawn.grid = "\n".join(rows)
	for i: int in marks.length():
		drawn.landmarks.append(_landmark(StringName(marks[i]), marks[i], i == 0))
	return drawn


func _sorted(ids: Array[StringName]) -> Array[StringName]:
	var sorted := ids.duplicate()
	sorted.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return sorted


## The first map holds together: every character a landmark or a road, every landmark drawn once
## and reached from the slip road or from the first landmark off the books, every road joining two,
## and the house's keystones on the roundabout's roads.
func test_the_first_map_holds_together() -> void:
	var drawn := _first()
	assert_array(Array(drawn.problems())).is_empty()
	assert_int(drawn.landmarks.size()).is_equal(41)
	assert_vector(drawn.size()).is_equal(Vector2i(49, 16))


## The roads are the drawing's: through bends, from ink to pencil, and to the roundabout.
func test_the_roads_are_the_drawings() -> void:
	var drawn := _first()
	var cases := {
		&"slip_road": [&"dealers_visor", &"racing_stripes"],
		&"card_shark": [&"gilt_back", &"services", &"wages"],
		&"showroom": [&"dashed_marks", &"lost_hard_hat"],
		&"cursed_cards": [&"ace_of_spades", &"spread_and_swivel", &"torn_up"],
		&"clean_record": [&"afterburn", &"marksman", &"walk_away"],
		&"back_roads": [&"paper_hat", &"patchwork"],
		&"fedora": [&"chip_trail", &"ace_of_spades", &"decoy_and_wipe"],
	}
	for id: StringName in cases:
		var expected: Array[StringName] = []
		expected.assign(cases[id])
		assert_array(_sorted(drawn.roads_of(id))).is_equal(_sorted(expected))
	var to_roundabout: Array[StringName] = []
	for each: LoyaltyLandmark in drawn.landmarks:
		if drawn.reaches_roundabout(each.id):
			to_roundabout.append(each.id)
	assert_array(_sorted(to_roundabout)).is_equal(_sorted([&"card_shark", &"showroom"]))
	assert_vector(drawn.at(&"slip_road")).is_equal(Vector2i(24, 14))
	assert_str(drawn.cell(Vector2i(23, 10))).is_equal(LoyaltyMap.ROUNDABOUT)


## Two roads crossing at a bend join all four ways; a road drawn across does not join what is above
## or below it.
func test_a_bend_joins_and_a_road_runs_one_way() -> void:
	var rows: Array[String] = [
		"  b  ",
		"  |  ",
		"a-+-c",
		"  |  ",
		"  d e",
	]
	var drawn := _drawn(rows, "abcde")
	assert_array(_sorted(drawn.roads_of(&"a"))).is_equal(_sorted([&"b", &"c", &"d"]))
	assert_array(drawn.roads_of(&"e")).is_empty()
	assert_array(Array(drawn.problems())).contains_exactly(["No road reaches e."])


## A grid that does not hold together says what is wrong with it.
func test_a_grid_that_does_not_hold_together_says_so() -> void:
	var rows: Array[String] = ["a--b  x", "      -", "c--"]
	var drawn := _drawn(rows, "abcz")
	drawn.landmarks.append(_landmark(&"b2", "b"))
	var keystone := _landmark(&"k", "k")
	keystone.keystone = true
	drawn.landmarks.append(keystone)
	var problems := Array(drawn.problems())
	var expected := [
		"Nothing is drawn as x, at 6, 0.",
		"A road at 6, 1 goes nowhere.",
		"z is not drawn on the grid.",
		"Two landmarks are drawn as b.",
		"The keystone k has no road to the roundabout.",
		"No road reaches c.",
	]
	assert_array(problems).contains(expected)


## Every card and item the map pays is one the game has: fifteen jokers, each paid once, which with
## the twenty of every deck is the whole deck, and the four items of the later set.
func test_what_the_first_map_pays_is_in_the_game() -> void:
	var known: Array[StringName] = []
	for joker: Joker in JOKERS.jokers:
		known.append(joker.id)
	var later: Array[StringName] = []
	for item: PowerUp in LATER_SET.entries:
		later.append(item.id)
	var paid: Array[StringName] = []
	var items: Array[StringName] = []
	for each: LoyaltyLandmark in _first().landmarks:
		for id: StringName in each.jokers:
			assert_bool(id in known).override_failure_message("%s is no joker" % id).is_true()
			assert_bool(id in paid).override_failure_message("%s paid twice" % id).is_false()
			paid.append(id)
		for id: StringName in each.items:
			assert_bool(id in later).override_failure_message("%s is not later" % id).is_true()
			items.append(id)
	assert_int(paid.size()).is_equal(15)
	assert_int(known.size() - paid.size()).is_equal(20)
	assert_array(_sorted(items)).is_equal(_sorted(later))


## A fresh profile welcomed opens the first landmarks of the Strip and the Department, and off the
## books only once a note is found with the story on.
func test_a_welcome_opens_the_first_landmarks() -> void:
	var drawn := _first()
	var profile := Profile.new()
	profile.loyalty.welcomed = true
	var won := Loyalty.settle(profile, drawn)
	assert_int(won.size()).is_equal(1)
	assert_str(String(won[0].id)).is_equal("slip_road")
	var open: Array[StringName] = []
	for each: LoyaltyLandmark in drawn.landmarks:
		if not profile.loyalty.has_won(each.id) and Loyalty.is_open(profile, each, drawn):
			open.append(each.id)
	assert_array(_sorted(open)).is_equal(_sorted([&"dealers_visor", &"racing_stripes"]))
	profile.story.notes = PackedInt32Array([1])
	assert_bool(Loyalty.is_open(profile, drawn.landmark(&"pencil_trail"), drawn)).is_true()


## Everything done, the whole map is won in one settling, the keystones last of their districts.
func test_the_whole_map_can_be_won() -> void:
	var drawn := _first()
	var profile := Profile.new()
	profile.loyalty.welcomed = true
	for each: LoyaltyLandmark in drawn.landmarks:
		match each.kind:
			LoyaltyLandmark.Kind.STAT:
				profile.stats[each.stat] = maxf(profile.stats.get(each.stat, 0.0), each.count)
			LoyaltyLandmark.Kind.FEAT:
				profile.loyalty.do_feat(each.id)
			LoyaltyLandmark.Kind.FIND:
				profile.loyalty.find(each.id)
	var twelve := PackedInt32Array()
	for i: int in 12:
		twelve.append(i + 1)
	profile.story.notes = twelve
	assert_int(Loyalty.settle(profile, drawn).size()).is_equal(41)


## The legend prints the House's lines alone; Kit's pencil is drawn in over it by hand, and only
## once Kit's roads are on the map.
func test_kits_pencil_in_the_legend() -> void:
	assert_array(Array(LoyaltyMapPrint.LEGEND_LINES)).not_contains(["Kit's pencil"])
	var profile := Profile.new()
	profile.story.on = true
	assert_bool(LoyaltyMapPrint.kit_legend_shown(profile)).is_false()
	profile.story.notes.append(1)
	assert_bool(LoyaltyMapPrint.kit_legend_shown(profile)).is_true()
	profile.story.on = false
	assert_bool(LoyaltyMapPrint.kit_legend_shown(profile)).is_false()


## Laid out on both sheets, every sign keeps its room clear of every other's, the ticket of its bet
## under it counted in and the roundabout too, however far the sway and the jitter move them; and
## each ticket is narrower than its sign, so it hangs from under it.
func test_the_signs_keep_their_room() -> void:
	var profile := Profile.new()
	profile.story.on = true
	profile.story.notes = PackedInt32Array([1])
	for sheet: int in [LoyaltyMapLayout.Sheet.HOUSE, LoyaltyMapLayout.Sheet.KIT]:
		var layout := LoyaltyMapLayout.of(_first(), profile, sheet)
		var ids: Array[StringName] = []
		ids.assign(layout.points.keys())
		if sheet == LoyaltyMapLayout.Sheet.HOUSE:
			ids.append(Loyalty.ROUNDABOUT)
		for i: int in ids.size():
			for j: int in range(i + 1, ids.size()):
				var a := layout.room_of(ids[i]).grow(-1.0)
				var b := layout.room_of(ids[j]).grow(-1.0)
				(
					assert_bool(a.intersects(b))
					. override_failure_message("%s and %s are too near" % [ids[i], ids[j]])
					. is_false()
				)
	for wide: float in [LoyaltyMapLayout.SIGN_LEAST, LoyaltyMapLayout.SIGN_MOST]:
		assert_float(LoyaltyMapPrint.ticket_wide(wide)).is_less(wide)


## The country keeps off the landmarks: the river never runs through a sign or its ticket, nor the
## lake, and no little drawing stands in the river; a bridge carries a road wherever it crosses one.
func test_the_country_keeps_off_the_landmarks() -> void:
	var layout := LoyaltyMapLayout.of(_first(), Profile.new())
	assert_int(layout.river.size()).is_greater(2)
	for id: StringName in layout.points:
		var room := layout.room_of(id)
		for point: Vector2 in layout.river:
			(
				assert_bool(room.has_point(point))
				. override_failure_message("the river runs through %s" % id)
				. is_false()
			)
		for point: Vector2 in layout.lake:
			assert_bool(room.has_point(point)).is_false()
	for doodle: Dictionary in layout.doodles:
		var at: Vector2 = doodle["at"]
		for point: Vector2 in layout.river:
			assert_float(point.distance_to(at)).is_greater(LoyaltyMapLand.RIVER_ROOM)
	assert_int(layout.bridges.size()).is_greater(0)
	for bridge: PackedVector2Array in layout.bridges:
		assert_int(bridge.size()).is_greater_equal(2)
