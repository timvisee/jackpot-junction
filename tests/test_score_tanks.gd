extends GdUnitTestSuite
## The score tanks, GAME.md 8.1: one on the table per player, filling with their color as they
## bank and full at the score that wins.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")

var _runner: GdUnitSceneRunner


func _start_match(players: int) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	rules.target_score = 1000
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in players:
		inputs.append(KartInput.new())
	match_node.start(inputs, 9)
	return match_node


func test_there_is_a_tank_per_player_standing_clear_of_the_floor() -> void:
	var match_node := _start_match(3)
	await _runner.simulate_frames(10, 17)
	var tanks := match_node.score_tanks
	assert_object(tanks).is_not_null()
	assert_bool(tanks.visible).is_true()
	assert_int(tanks._columns.size()).is_equal(3)
	# Out on the table beyond the wall, where nothing of the match reaches them.
	var half := match_node.arena.world_size() * 0.5
	for column: MeshInstance3D in tanks._columns:
		var at: Vector3 = column.get_parent().position
		assert_float(absf(at.z)).is_greater(half.y)


## GAME.md 8.1: full at the target score, and proportional on the way there.
func test_the_level_follows_what_is_banked_against_the_target() -> void:
	var match_node := _start_match(2)
	await _runner.simulate_frames(10, 17)
	var tanks := match_node.score_tanks
	assert_float(tanks._levels[0]).is_equal_approx(0.0, 0.01)
	match_node.slots[0].banked = 500
	match_node.slots[1].banked = 2000
	await _runner.simulate_frames(120, 17)
	# Half way for half the target, and full rather than overflowing for twice it.
	assert_float(tanks._levels[0]).is_equal_approx(0.5, 0.02)
	assert_float(tanks._levels[1]).is_equal_approx(1.0, 0.02)
	# And the fluid itself is that deep, so what is on screen is what is banked.
	var deep: float = tanks._columns[0].scale.y
	var brim: float = tanks._columns[1].scale.y
	assert_float(deep).is_greater(0.0)
	assert_float(deep / brim).is_equal_approx(0.5, 0.05)


## A room with no clock and nothing to reach has no tanks: one that can never fill is furniture.
func test_the_garage_has_no_tanks() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(30, 17)
	var match_node: Match = garage.get_node("Match")
	assert_bool(match_node.score_tanks.wanted()).is_false()
	assert_bool(match_node.score_tanks.visible).is_false()


## Nobody stands in front of them: the crowd leaves the stretch of table they are on alone.
func test_the_crowd_leaves_the_tanks_a_bay() -> void:
	var match_node := _start_match(4)
	await _runner.simulate_frames(10, 17)
	var tanks := match_node.score_tanks
	var crowd := match_node.arena.crowd
	assert_int(crowd._clear.size()).is_greater(1)
	for column: MeshInstance3D in tanks._columns:
		var at: Vector3 = column.get_parent().position
		var near := 999.0
		for spot: Transform3D in crowd._spots:
			near = minf(near, Vector2(spot.origin.x - at.x, spot.origin.z - at.z).length())
		assert_float(near).override_failure_message("somebody is standing on a tank").is_greater(
			ScoreTanks.RADIUS
		)
