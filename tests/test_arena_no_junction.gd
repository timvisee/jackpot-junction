extends GdUnitTestSuite
## GAME.md 6.3: a map may leave the Junction out. The test track in 9.4 is a road with corners on
## it and nothing to bank, and a pad of no size in the corner of the map is worse than no pad.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/garage.tres")
const GRID := (
	"################\n"
	+ "#S.............#\n"
	+ "#....BB........#\n"
	+ "#..........C...#\n"
	+ "#.............S#\n"
	+ "################"
)

var _runner: GdUnitSceneRunner


func _layout() -> ArenaLayout:
	var layout := ArenaLayout.new()
	layout.grid = GRID
	return layout


func test_a_map_without_a_junction_parses_and_builds() -> void:
	var layout := _layout()
	assert_array(layout.validate()).is_empty()
	assert_object(layout.parse().junction).is_equal(Rect2i())
	var arena: Arena = auto_free(Arena.new())
	arena.layout = layout
	add_child(arena)
	assert_object(arena.junction).is_null()
	assert_int(arena.crates.size()).is_equal(2)


## And a whole match runs on it: no pad to connect to, nothing to blink, nothing to pay double.
func test_a_match_runs_on_a_map_with_no_junction() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = _layout()
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new()] as Array[KartInput], 5)
	await _runner.simulate_frames(40, 17)
	assert_object(match_node.arena.junction).is_null()
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	assert_bool(match_node.kart_of(0).alive).is_true()
	# The snapshot a client would be sent describes it without falling over either.
	var data := match_node.build_snapshot()
	assert_bool(data.has("payout")).is_true()
	match_node.apply_snapshot(data)
