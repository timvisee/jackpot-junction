extends GdUnitTestSuite
## The crowd, GAME.md 8.1: a ring of onlookers on the table with a DJ booth at the top of it.
## They bob while the room is quiet, they are on their feet at the top two excitement levels, and
## a kill gets them up whatever the meter says.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")

var _runner: GdUnitSceneRunner


func _arena() -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/lucky_crossing.tres")
	add_child(arena)
	return arena


func test_the_table_is_ringed_with_onlookers_and_a_booth() -> void:
	var arena := _arena()
	var crowd := arena.crowd
	assert_object(crowd).is_not_null()
	# Enough of them to read as a crowd, all standing on the table rather than on the felt.
	assert_int(crowd._figures.size()).is_greater(20)
	for figure: Node3D in crowd._figures:
		assert_float(figure.position.y).is_equal_approx(Crowd.TABLE_TOP, 0.001)
	# And all of them outside the walls, where nothing can be driven into them.
	var half := arena.world_size() * 0.5
	for figure: Node3D in crowd._figures:
		var outside := (
			absf(figure.position.x) > half.x + 0.5 or absf(figure.position.z) > half.y + 0.5
		)
		assert_bool(outside).override_failure_message("somebody is standing on the floor").is_true()
	assert_int(crowd._speakers.size()).is_equal(2)
	assert_object(crowd._dj).is_not_null()


func test_a_kill_gets_them_up_and_so_does_a_hot_room() -> void:
	var arena := _arena()
	var crowd := arena.crowd
	var runner: GdUnitSceneRunner = scene_runner(arena)
	await runner.simulate_frames(6, 17)
	var resting := crowd._figures[0].position.y
	Events.kart_killed.emit(1, 0, &"bullet")
	assert_float(crowd._cheer).is_greater(0.0)
	var highest := resting
	for i: int in 30:
		await runner.simulate_frames(1, 17)
		highest = maxf(highest, crowd._figures[0].position.y)
	assert_float(highest - Crowd.TABLE_TOP).is_greater(Crowd.JUMP * 0.5)
	# The cheer runs out; a hot room keeps them up without one.
	crowd._cheer = 0.0
	crowd.level = Crowd.DANCING_LEVEL
	highest = Crowd.TABLE_TOP
	for i: int in 30:
		await runner.simulate_frames(1, 17)
		highest = maxf(highest, crowd._figures[0].position.y)
	assert_float(highest - Crowd.TABLE_TOP).is_greater(Crowd.JUMP * 0.5)


## The match keeps the crowd's level up to date along with the lights.
func test_the_match_tells_the_crowd_how_the_room_is_going() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new()] as Array[KartInput], 5)
	await _runner.simulate_frames(20, 17)
	match_node.intensity.level = 6
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.arena.crowd.level).is_equal(6)


## The Garage is not a party, the same as it is not a nightclub.
func test_nobody_is_watching_in_the_garage() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(60, 17)
	var match_node: Match = garage.get_node("Match")
	assert_bool(match_node.arena.crowd.enabled).is_false()
	assert_bool(match_node.arena.crowd.visible).is_false()
