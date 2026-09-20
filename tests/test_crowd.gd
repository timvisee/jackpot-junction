extends GdUnitTestSuite
## The crowd, GAME.md 8.1: a band of onlookers on the table with a DJ booth at the top of it.
## They bob while the room is quiet, they are on their feet at the top two excitement levels, and
## a kill gets them up whatever the meter says. All of them are instances of one mesh animated in
## a shader, so what is checked here is the house and the beat the house is dancing to.

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
	# A full house rather than a fence: several rows deep all the way round.
	assert_int(crowd.count()).is_greater(400)
	# Nobody is standing on the felt, and nobody is standing inside the table either.
	var half := arena.world_size() * 0.5
	var lowest := 0.0
	for spot: Transform3D in crowd._spots:
		var at := spot.origin
		var outside := absf(at.x) > half.x + 0.5 or absf(at.z) > half.y + 0.5
		assert_bool(outside).override_failure_message("somebody is standing on the floor").is_true()
		lowest = minf(lowest, at.y - Crowd.TABLE_TOP)
	assert_float(lowest).is_greater_equal(-0.001)
	# Two draw calls for the lot of them, not two thousand nodes.
	assert_int(crowd.get_child_count()).is_less(4)
	assert_int(crowd._onlookers.multimesh.instance_count).is_equal(crowd.count())
	assert_int(crowd._onlookers.multimesh.mesh.get_surface_count()).is_equal(2)
	# No two of them are the same person standing in a line.
	assert_vector(crowd._spots[0].origin).is_not_equal(crowd._spots[1].origin)
	assert_object(crowd._shirts).is_not_equal(crowd._traits)
	assert_int(crowd._speakers.size()).is_equal(2)
	assert_object(crowd._dj).is_not_null()


## Tribunes, GAME.md 8.1: a stretch of each side is built up into steps, and the people standing
## on that stretch go up with them rather than staying flat while the steps rise under them.
func test_some_of_them_are_standing_on_a_tribune() -> void:
	var arena := _arena()
	var crowd := arena.crowd
	assert_int(crowd._footprints.size()).is_greater(2)
	var highest := Crowd.TABLE_TOP
	var on_a_stand := 0
	for spot: Transform3D in crowd._spots:
		highest = maxf(highest, spot.origin.y)
		if spot.origin.y > Crowd.TABLE_TOP + 0.01:
			on_a_stand += 1
	assert_float(highest).is_greater(Crowd.TABLE_TOP + Crowd.TIER)
	assert_int(on_a_stand).is_greater(20)
	# And most of the house is still on the table: a stand is somewhere, not everywhere.
	assert_int(on_a_stand).is_less(crowd.count() / 2)
	# The steps themselves are there, and they are not nine hundred nodes either.
	var stands: Node3D = crowd.get_node("Stands")
	assert_int(stands.get_child_count()).is_equal(crowd._footprints.size() * Crowd.ROWS)


func test_a_kill_gets_them_up_and_so_does_a_hot_room() -> void:
	var arena := _arena()
	var crowd := arena.crowd
	var runner: GdUnitSceneRunner = scene_runner(arena)
	await runner.simulate_frames(6, 17)
	assert_float(crowd._lift).is_less(Crowd.JUMP * 0.5)
	Events.kart_killed.emit(1, 0, &"bullet")
	assert_float(crowd._cheer).is_greater(0.0)
	await runner.simulate_frames(40, 17)
	assert_float(crowd._lift).is_greater(Crowd.JUMP * 0.5)
	# Whatever the room is doing is what the figures are told, since they do the moving.
	var skin: ShaderMaterial = crowd._skins[0]
	assert_float(skin.get_shader_parameter(&"lift")).is_equal_approx(crowd._lift, 0.001)
	assert_float(skin.get_shader_parameter(&"beat")).is_greater(0.0)
	# The cheer runs out; a hot room keeps them up without one.
	crowd._cheer = 0.0
	crowd.level = 0
	await runner.simulate_frames(80, 17)
	assert_float(crowd._lift).is_less(Crowd.JUMP * 0.5)
	crowd.level = Crowd.DANCING_LEVEL
	await runner.simulate_frames(40, 17)
	assert_float(crowd._lift).is_greater(Crowd.JUMP * 0.5)


## The beat is wrapped at its own period, so an hour of dancing neither drifts out of float
## precision nor jumps when it comes round again.
func test_the_beat_comes_round_rather_than_running_away() -> void:
	var arena := _arena()
	var crowd := arena.crowd
	crowd._beat = Crowd.PERIOD - 0.01
	var runner: GdUnitSceneRunner = scene_runner(arena)
	await runner.simulate_frames(4, 17)
	assert_float(crowd._beat).is_less(Crowd.PERIOD)
	assert_float(crowd._beat).is_greater_equal(0.0)


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


## Anybody who would rather have the table to themselves empties the stands, GAME.md 8.5, and
## keeps the booth: it is the thousand moving things that the setting is about.
func test_the_stands_can_be_emptied() -> void:
	var was := Game.settings.crowd
	Game.settings.crowd = false
	var arena := _arena()
	var crowd := arena.crowd
	var runner: GdUnitSceneRunner = scene_runner(arena)
	await runner.simulate_frames(4, 17)
	assert_bool(crowd._onlookers.visible).is_false()
	assert_bool(crowd.get_node("Stands").visible).is_false()
	assert_bool(crowd.get_node("DjBooth").visible).is_true()
	Game.settings.crowd = was
	await runner.simulate_frames(4, 17)
	assert_bool(crowd._onlookers.visible).is_true()


## The Garage is not a party, the same as it is not a nightclub.
func test_nobody_is_watching_in_the_garage() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(60, 17)
	var match_node: Match = garage.get_node("Match")
	assert_bool(match_node.arena.crowd.enabled).is_false()
	assert_bool(match_node.arena.crowd.visible).is_false()
