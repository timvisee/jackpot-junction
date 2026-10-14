extends GdUnitTestSuite
## The arenas a match can be played in, GAME.md 6.3: three of them and an XL of each, picked in the
## lobby, and the host's pick is the one everybody plays in.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


## Every cell reachable from the first spawn.
func _reachable(grid: ArenaGrid) -> int:
	var seen: Dictionary[Vector2i, bool] = {grid.spawns[0]: true}
	var queue: Array[Vector2i] = [grid.spawns[0]]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if seen.has(next) or next.x < 0 or next.y < 0:
				continue
			if next.x >= grid.width or next.y >= grid.height or grid.is_wall(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen.size()


func test_every_arena_is_the_same_room_in_a_different_shape() -> void:
	assert_int(ArenaMaps.IDS.size()).is_equal(8)
	assert_int(ArenaMaps.NAMES.size()).is_equal(ArenaMaps.IDS.size())
	for id: StringName in ArenaMaps.IDS:
		# The showdown's map has none of the furniture, GAME.md 6.3: see test_tie_breaker.
		if id == ArenaMaps.SHOWDOWN:
			continue
		var layout := ArenaMaps.layout(id)
		(
			assert_array(layout.validate())
			. override_failure_message("%s is not a valid map" % id)
			. is_empty()
		)
		var grid := layout.parse()
		var size := Vector2(42.0, 24.0) if ArenaMaps.is_xl(id) else Vector2(32.0, 18.0)
		assert_vector(Vector2(grid.width, grid.height)).is_equal(size)
		assert_int(grid.spawns.size()).is_equal(8)
		assert_int(grid.corner_spawns).is_equal(4)
		assert_object(grid.junction.size).is_equal(Vector2i(4, 4))
		assert_int(grid.jackpots.size()).is_equal(2)
		assert_int(grid.pits.size()).is_equal(2)
		assert_int(grid.flush_pads.size()).is_equal(4)
		# Four turbo sections; an XL map's are two pads wide, see below.
		assert_int(grid.turbo_pads.size()).is_equal(8 if ArenaMaps.is_xl(id) else 4)
		assert_int(grid.power_pads.size()).is_greater_equal(4)
		assert_int(grid.coin_pads.size()).is_greater_equal(8)
		assert_int(grid.crates.size()).is_greater_equal(6)
		# Nowhere on any of them is walled off from the start.
		var open := 0
		for y: int in grid.height:
			for x: int in grid.width:
				if not grid.is_wall(Vector2i(x, y)):
					open += 1
		(
			assert_int(_reachable(grid))
			. override_failure_message("%s has a corner nobody can drive to" % id)
			. is_equal(open)
		)


## GAME.md 6.3: a room of up to eight, 9.3, starts its fifth kart on in one of four more spawn
## points, after the corners, each beside its twin across the middle of the room. Every one of
## them has a clear run at the Junction it faces, with no pit and no turbo pad on the way, and none
## is in a lane a turbo pad fires down.
func test_every_arena_and_the_lobby_have_a_start_for_eight() -> void:
	var ids: Array[StringName] = ArenaMaps.IDS.duplicate()
	ids.append(&"waiting_room")
	for id: StringName in ids:
		var layout: ArenaLayout = load("res://data/maps/%s.tres" % id)
		var grid := layout.parse()
		assert_int(grid.spawns.size()).override_failure_message("%s spawns" % id).is_equal(8)
		for i: int in grid.spawns.size():
			var glyph := ArenaGrid.SPAWN if i < grid.corner_spawns else ArenaGrid.EXTRA_SPAWN
			assert_str(grid.glyph(grid.spawns[i])).is_equal(glyph)
		if id != &"waiting_room":
			for i: int in [4, 6]:
				var cell := grid.spawns[i]
				var twin := Vector2i(grid.width - 1 - cell.x, grid.height - 1 - cell.y)
				assert_object(grid.spawns[i + 1]).override_failure_message(id).is_equal(twin)
		# The showdown's has no Junction to run at, GAME.md 6.3.
		if id == ArenaMaps.SHOWDOWN:
			continue
		var lanes := _turbo_lanes(grid)
		var middle := Vector2(grid.junction.get_center())
		for i: int in range(grid.corner_spawns, grid.spawns.size()):
			var cell := grid.spawns[i]
			assert_bool(lanes.has(cell)).override_failure_message("%s %s" % [id, cell]).is_false()
			var from := Vector2(cell) + Vector2.ONE * 0.5
			for step: int in 100:
				var on := Vector2i(from.lerp(middle, step / 100.0).floor())
				var glyph := grid.glyph(on)
				if glyph == ArenaGrid.JUNCTION:
					break
				(
					assert_bool(glyph in [ArenaGrid.PIT, ArenaGrid.WALL] or lanes.has(on))
					. override_failure_message("%s: %s from %s at %s" % [id, glyph, cell, on])
					. is_false()
				)


## GAME.md 6.3: the spawn points past the corners are only painted on the floor while the room has
## more than four karts. A match of four does not show them, and the fifth kart sitting down puts
## them down.
func test_the_extra_spawns_show_only_past_four_karts() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.max_players = 8
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	# Four people, so the fifth is a kart of their own rather than a seat taken over.
	var inputs: Array[KartInput] = []
	for i: int in 4:
		inputs.append(NetInput.new())
	match_node.start(inputs, 3)
	await _runner.simulate_frames(3, 17)
	var extra := match_node.arena.get_node("ExtraSpawns") as SpawnPads
	assert_int(extra.find_children("Spawn*", "Marker3D", false, false).size()).is_equal(4)
	assert_bool(extra.visible).is_false()
	assert_bool((match_node.arena.get_node("Spawns") as Node3D).visible).is_true()
	match_node.join_network(NetInput.new())
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.slots.size()).is_equal(5)
	assert_bool(extra.visible).is_true()


## Every cell a turbo pad of [param grid] fires a kart down, the pads included, as far as the next
## pad, which sends a kart on its own way.
func _turbo_lanes(grid: ArenaGrid) -> Dictionary[Vector2i, bool]:
	var lanes: Dictionary[Vector2i, bool] = {}
	for pad: Vector2i in grid.turbo_pads:
		var way := grid.turbo_direction(pad)
		var step := Vector2i(roundi(way.x), roundi(way.z))
		var cell := pad
		while grid.glyph(cell) in ArenaGrid.TURBO_GLYPHS:
			lanes[cell] = true
			cell += step
		var ends := [ArenaGrid.WALL, ArenaGrid.CRATE, ArenaGrid.PIT] + ArenaGrid.TURBO_GLYPHS
		while not (grid.glyph(cell) in ends):
			lanes[cell] = true
			cell += step
	return lanes


func test_an_unknown_map_falls_back_rather_than_leaving_no_arena() -> void:
	assert_int(ArenaMaps.index_of(&"a_map_from_the_future")).is_equal(0)
	assert_object(ArenaMaps.layout(&"a_map_from_the_future")).is_same(
		ArenaMaps.layout(ArenaMaps.IDS[0])
	)
	assert_str(String(ArenaMaps.id_at(99))).is_equal(String(ArenaMaps.IDS[-1]))


## GAME.md 6.3: an XL map is its map made roomier, in the same room. Every pit has two cells of
## open floor all round it and four between it and the Junction, and every turbo pad launches down
## at least eight cells of open lane with no hole in it, so a turbo never drives a kart into a
## wall or down a pit.
func test_an_xl_map_has_room_to_drive() -> void:
	for id: StringName in ArenaMaps.IDS:
		if not ArenaMaps.is_xl(id):
			continue
		var layout := ArenaMaps.layout(id)
		assert_object(layout.room).is_same(ArenaMaps.layout(ArenaMaps.family(id)).room)
		var grid := layout.parse()
		(
			assert_bool(grid.is_point_symmetric())
			. override_failure_message("%s lopsided" % id)
			. is_true()
		)
		for pit: Rect2i in grid.pits:
			var apart := maxi(
				maxi(pit.position.x - grid.junction.end.x, grid.junction.position.x - pit.end.x),
				maxi(pit.position.y - grid.junction.end.y, grid.junction.position.y - pit.end.y)
			)
			assert_int(apart).override_failure_message("%s pit %s" % [id, pit]).is_greater_equal(4)
			var ring := pit.grow(2)
			for y: int in range(ring.position.y, ring.end.y):
				for x: int in range(ring.position.x, ring.end.x):
					var glyph := grid.glyph(Vector2i(x, y))
					(
						assert_bool(glyph in [".", "C", "X"])
						. override_failure_message(
							"%s: %s beside a pit at %d,%d" % [id, glyph, x, y]
						)
						. is_true()
					)
		for pad: Vector2i in grid.turbo_pads:
			var way := grid.turbo_direction(pad)
			var step := Vector2i(roundi(way.x), roundi(way.z))
			var cell := pad + step
			while grid.glyph(cell) in ArenaGrid.TURBO_GLYPHS:
				cell += step
			var lane := 0
			while not (grid.glyph(cell) in [ArenaGrid.WALL, ArenaGrid.CRATE, ArenaGrid.PIT]):
				lane += 1
				cell += step
			(
				assert_str(grid.glyph(cell))
				. override_failure_message("%s turbo %s into a pit" % [id, pad])
				. is_not_equal(ArenaGrid.PIT)
			)
			assert_int(lane).override_failure_message("%s turbo %s" % [id, pad]).is_greater_equal(8)


## GAME.md 6.3: a map at the usual size with more than four karts on it is played as its XL,
## unless the match settings ask for it as picked. Four karts play it as picked, and an XL map is
## played as itself whatever is on it.
func test_a_map_too_small_for_its_karts_is_played_as_its_xl() -> void:
	assert_str(String(ArenaMaps.xl_of(&"vault"))).is_equal("vault_xl")
	assert_str(String(ArenaMaps.xl_of(&"vault_xl"))).is_equal("vault_xl")
	var config := MatchConfig.new()
	config.map = &"crossfire"
	config.bot_count = 3
	assert_str(String(config.rules(DEFAULT_RULES).map)).is_equal("crossfire")
	config.network_seats = 1
	assert_int(config.karts()).is_equal(5)
	assert_str(String(config.rules(DEFAULT_RULES).map)).is_equal("crossfire_xl")
	config.small_maps = true
	assert_str(String(config.rules(DEFAULT_RULES).map)).is_equal("crossfire")
	config.small_maps = false
	config.map = &"lucky_crossing_xl"
	assert_str(String(config.rules(DEFAULT_RULES).map)).is_equal("lucky_crossing_xl")
	# The choice rides the plan a player hosting at a dedicated server sends it, GAME.md 9.3a.
	var said := MatchConfig.new()
	config.small_maps = true
	MatchOptions.from_wire(said, MatchOptions.to_wire(config))
	assert_bool(said.small_maps).is_true()


## GAME.md 9.7: a Grand Prix deals from the sizes asked for, and never from none.
func test_a_grand_prix_deals_from_the_sizes_asked_for() -> void:
	for id: StringName in ArenaMaps.pool(true, false):
		assert_bool(ArenaMaps.is_xl(id)).is_false()
	for id: StringName in ArenaMaps.pool(false, true):
		assert_bool(ArenaMaps.is_xl(id)).is_true()
	# Every map but the story's, STORY.md 10, and the showdown's, GAME.md 6.3.
	var dealable := (
		ArenaMaps.IDS.size() - ArenaMaps.STORY_ONLY.size() - ArenaMaps.NEVER_DEALT.size()
	)
	assert_int(ArenaMaps.pool(true, true).size()).is_equal(dealable)
	assert_int(ArenaMaps.pool(false, false).size()).is_equal(dealable)
	assert_str(String(ArenaMaps.family(&"vault_xl"))).is_equal("vault")
	# A map and its XL are the same room, which a run never plays twice running.
	var rng := RandomNumberGenerator.new()
	for seed: int in 40:
		rng.seed = seed
		var dealt := GrandPrix.deal(6, rng)
		for i: int in range(1, dealt.size()):
			assert_str(String(ArenaMaps.family(dealt[i]))).is_not_equal(
				String(ArenaMaps.family(dealt[i - 1]))
			)


## GAME.md 10.3: the map is one of the host's settings, so it travels with the rest of them and
## a client never builds the room its own lobby happened to be showing.
func test_the_map_rides_the_wire_with_the_rest_of_the_settings() -> void:
	assert_bool(MatchRules.WIRE_FIELDS.has(&"map")).is_true()
	var config := MatchConfig.new()
	config.map = &"crossfire"
	var rules := config.rules(DEFAULT_RULES)
	assert_str(String(rules.map)).is_equal("crossfire")
	var theirs: MatchRules = DEFAULT_RULES.duplicate()
	theirs.map = &"vault"
	theirs.from_wire(rules.to_wire())
	assert_str(String(theirs.map)).is_equal("crossfire")


func test_the_lobby_picks_one_and_a_match_is_played_in_it() -> void:
	var pane: HostSettings = auto_free(HostSettings.add_to(self, true))
	assert_int(pane.options.map_option.item_count).is_equal(
		ArenaMaps.offered(Game.settings.profile).size()
	)
	pane.options.map_option.selected = 1
	var config := MatchConfig.new()
	pane.options.apply_to(config)
	assert_str(String(config.map)).is_equal(String(ArenaMaps.IDS[1]))
	var rules := config.rules(DEFAULT_RULES)
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = ArenaMaps.layout(rules.map)
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new()] as Array[KartInput], 5)
	await _runner.simulate_frames(30, 17)
	assert_object(match_node.arena.layout).is_same(ArenaMaps.layout(ArenaMaps.IDS[1]))
	assert_bool(match_node.kart_of(0).alive).is_true()
	assert_object(match_node.arena.junction).is_not_null()
