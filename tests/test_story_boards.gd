extends GdUnitTestSuite
## The House's advertising, STORY.md 6.1: the hoardings draw one board from the newest stage and one
## from every stage reached, the poster on the back wall changes once a stage, and the road says its
## word in a box on the near side of every map, clear of everything on it.


func after_test() -> void:
	Story.override = -1


func _arena(map: String) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = false
	add_child(arena)
	return arena


func _dressing(arena: Arena) -> StoryDressing:
	return arena.get_node_or_null("Story") as StoryDressing


## The first stage is the sixteen boards there have always been; later ones put one of their own up
## every time, never the same board twice and never two that name the player.
func test_one_board_from_the_newest_stage_and_one_from_them_all() -> void:
	var rng := RandomNumberGenerator.new()
	for seed: int in 200:
		rng.seed = seed
		var first := StoryBoards.pick(Story.Stage.CUSTOMER, false, rng)
		assert_bool(first[0] in Billboard.ADS and first[1] in Billboard.ADS).is_true()
		assert_bool(first[0] == first[1]).is_false()
		for stage: int in range(Story.Stage.PLAYER, Story.Stage.OPERATOR + 1):
			var two := StoryBoards.pick(stage, false, rng)
			assert_bool(two[0] in StoryLines.ADS[stage]).is_true()
			assert_bool(two[1] in StoryBoards.pool(stage)).is_true()
			assert_bool(two[0] == two[1]).is_false()
			var named := 0
			for ad: Array in two:
				if StoryBoards.names_the_player(ad):
					named += 1
			assert_int(named).is_less_equal(1)
	var final := StoryBoards.pick(Story.Stage.CANDIDATE, true, rng)
	assert_str(str(final[0][0])).is_equal("FINAL HAND")
	assert_str(str(final[1][0])).is_equal("NOW HIRING")
	# The old jokes keep coming around: the first stage's boards are in every stage's pool.
	assert_bool(Billboard.ADS[0] in StoryBoards.pool(Story.Stage.OPERATOR)).is_true()


## The road's box lies on a row of bare floor with no hazard, spawn, Junction or Jackpot beside it,
## on every map a match is played on.
func test_the_road_finds_a_clear_lane_on_every_map() -> void:
	for id: StringName in ArenaMaps.IDS:
		var layout: ArenaLayout = ArenaMaps.layout(id)
		var grid := layout.parse()
		var spot := StoryDressing.road_spot(grid, StoryDressing.ROAD_CELLS)
		assert_int(spot.size.x).override_failure_message(String(id)).is_equal(
			StoryDressing.ROAD_CELLS
		)
		assert_int(spot.size.y).is_equal(StoryDressing.ROAD_ROWS)
		assert_int(spot.position.y).override_failure_message(String(id)).is_greater(grid.height / 2)
		for y: int in range(spot.position.y - 1, spot.end.y + 1):
			for x: int in range(spot.position.x - 1, spot.end.x + 1):
				var glyph := grid.glyph(Vector2i(x, y))
				assert_bool(glyph in StoryDressing.AVOID).is_false()
				if spot.has_point(Vector2i(x, y)):
					assert_str(glyph).is_equal(ArenaGrid.FLOOR)


## A match's room is dressed for the stage the machine shows; the Garage is not dressed at all.
func test_the_rooms_wear_the_stage_they_are_built_at() -> void:
	Story.override = Story.Stage.PARTICIPANT
	for map: String in ["lucky_crossing", "vault", "crossfire"]:
		var dressing := _dressing(_arena(map))
		assert_object(dressing).override_failure_message(map).is_not_null()
		var word: RoadPaint = dressing.road.get_node("Word")
		assert_str(word.text).is_equal("KEEP PLAYING")
		var big: Label3D = dressing.poster.get_node("Big")
		assert_str(big.text).is_equal("BE YOURSELF")
	Story.override = Story.Stage.CUSTOMER
	var first := _dressing(_arena("lucky_crossing"))
	assert_str((first.road.get_node("Word") as RoadPaint).text).is_equal("KEEP CLEAR")
	assert_str((first.poster.get_node("Big") as Label3D).text).is_equal("PLAY RESPONSIBLY")
	assert_object(_dressing(_arena("garage"))).is_null()
	assert_object(_dressing(_arena("waiting_room"))).is_null()


## The hoardings carry the newest stage's words, filled in.
func test_the_hoardings_carry_the_stage() -> void:
	Story.override = Story.Stage.OPERATOR
	var arena := _arena("vault")
	var said: Array[String] = []
	for label: Label3D in arena.billboards.find_children("*", "Label3D", true, false):
		said.append(label.text)
	var newest: Array[String] = []
	for ad: Array in StoryLines.ADS[Story.Stage.OPERATOR]:
		newest.append(StoryFill.fill(str(ad[0]), Game.settings.profile))
	var found := false
	for line: String in said:
		if line in newest:
			found = true
	assert_bool(found).override_failure_message(str(said)).is_true()
	for line: String in said:
		assert_bool(line.contains("{")).is_false()
