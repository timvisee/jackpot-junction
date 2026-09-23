extends GdUnitTestSuite
## The arenas a match can be played in, GAME.md 6.3: three of them, picked in the lobby, and the
## host's pick is the one everybody plays in.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LOBBY_SCENE := preload("res://scenes/ui/lobby.tscn")
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
	assert_int(ArenaMaps.IDS.size()).is_equal(3)
	assert_int(ArenaMaps.NAMES.size()).is_equal(ArenaMaps.IDS.size())
	for id: StringName in ArenaMaps.IDS:
		var layout := ArenaMaps.layout(id)
		(
			assert_array(layout.validate())
			. override_failure_message("%s is not a valid map" % id)
			. is_empty()
		)
		var grid := layout.parse()
		assert_vector(Vector2(grid.width, grid.height)).is_equal(Vector2(32.0, 18.0))
		assert_int(grid.spawns.size()).is_equal(4)
		assert_object(grid.junction.size).is_equal(Vector2i(4, 4))
		assert_int(grid.jackpots.size()).is_equal(2)
		assert_int(grid.pits.size()).is_equal(2)
		assert_int(grid.flush_pads.size()).is_equal(4)
		assert_int(grid.turbo_pads.size()).is_equal(4)
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


func test_an_unknown_map_falls_back_rather_than_leaving_no_arena() -> void:
	assert_int(ArenaMaps.index_of(&"a_map_from_the_future")).is_equal(0)
	assert_object(ArenaMaps.layout(&"a_map_from_the_future")).is_same(
		ArenaMaps.layout(ArenaMaps.IDS[0])
	)
	assert_str(String(ArenaMaps.id_at(99))).is_equal(String(ArenaMaps.IDS[2]))


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
	var lobby: Control = auto_free(LOBBY_SCENE.instantiate())
	add_child(lobby)
	assert_int(lobby.options.map_option.item_count).is_equal(ArenaMaps.IDS.size())
	lobby.options.map_option.selected = 1
	var config: MatchConfig = lobby.config()
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
