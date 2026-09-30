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


## GAME.md 8.5: a phone starts with half a house, and the setting stands the house up again at
## the new size a moment later rather than waiting for the next map.
func test_half_a_house_is_half_the_people() -> void:
	var was := Game.settings.crowd_size
	Game.settings.crowd_size = 1.0
	var arena := _arena()
	var crowd := arena.crowd
	var full := crowd.count()
	Game.settings.crowd_size = 0.5
	for i: int in Crowd.REBUILD_WAIT + 1:
		crowd._process(1.0 / 60.0)
	assert_int(crowd.count()).is_between(int(full * 0.35), int(full * 0.65))
	assert_int(crowd.drawn()).is_equal(crowd.count())
	Game.settings.crowd_size = was


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
	# A MultiMesh a side of the table for the lot of them, GAME.md 10.7, not two thousand nodes:
	# one side's people are culled together when the camera has zoomed away from them.
	assert_int(crowd.get_child_count()).is_less(4)
	assert_int(crowd._houses.size()).is_equal(4)
	assert_int(crowd.drawn()).is_equal(crowd.count())
	assert_int(crowd._houses[0].multimesh.mesh.get_surface_count()).is_equal(2)
	for house: MultiMeshInstance3D in crowd._houses:
		assert_object(house.multimesh.mesh).is_same(crowd._houses[0].multimesh.mesh)
	# Each side's box holds each of its own people, jump and all. Checked against the spots kept
	# here rather than read back off the MultiMesh, which a headless run does not keep.
	var outside := 0
	for i: int in crowd._spots.size():
		var house: MultiMeshInstance3D = crowd._onlookers.get_node("Side%d" % crowd._sides[i])
		var feet: Vector3 = crowd._spots[i].origin
		if not house.custom_aabb.has_point(feet):
			outside += 1
		if not house.custom_aabb.has_point(feet + Vector3(0.0, 1.0, 0.0)):
			outside += 1
	(
		assert_int(outside)
		. override_failure_message("%d people stand outside their box" % outside)
		. is_equal(0)
	)
	# No two of them are the same person standing in a line.
	assert_vector(crowd._spots[0].origin).is_not_equal(crowd._spots[1].origin)
	assert_object(crowd._shirts).is_not_equal(crowd._traits)
	assert_int(crowd._speakers.size()).is_equal(2)
	assert_object(crowd._dj).is_not_null()


## The booth stands in the crowd rather than behind it, GAME.md 8.1: people in front of it and
## people behind it, and nobody standing inside it.
func test_the_booth_stands_in_the_crowd() -> void:
	var arena := _arena()
	var crowd := arena.crowd
	# The house stands up again a couple of frames after the last bay is asked for, GAME.md 8.1,
	# and the hoardings ask for theirs as the room goes up. Before that the stands are the ones
	# raised for an empty table.
	await await_millis(80)
	var booth: Node3D = crowd.get_node("DjBooth")
	var edge := arena.world_size().y * 0.5
	var out := absf(booth.position.z) - edge
	assert_float(out).is_greater(Crowd.STANDOFF)
	assert_float(out).is_less(Crowd.STANDOFF + (Crowd.ROWS - 1) * Crowd.ROW_DEPTH)
	var nearer := 0
	var further := 0
	for spot: Transform3D in crowd._spots:
		if absf(spot.origin.x) > Crowd.BOOTH_CLEARANCE.x * 0.5 or spot.origin.z > 0.0:
			continue
		var reach := absf(spot.origin.z) - edge
		if reach < out:
			nearer += 1
		else:
			further += 1
		var inside := crowd._blocked(Vector2(spot.origin.x, spot.origin.z), 0.0)
		(
			assert_bool(inside)
			. override_failure_message("somebody is standing inside the booth")
			. is_false()
		)
	assert_int(nearer).is_greater(3)
	assert_int(further).is_greater(3)
	# And no stand is built through it either.
	for footprint: Rect2 in crowd._footprints:
		assert_bool(crowd._overlaps(footprint, 0.0)).is_false()


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
	# The steps themselves are there, and they are not nine hundred nodes either: every tread is
	# baked into one mesh and every back wall into the other, GAME.md 10.7, so however many stands
	# there are, the steps are two things to draw.
	var stands: Node3D = crowd.get_node("Stands")
	assert_int(stands.get_child_count()).is_equal(2)
	for step: MeshInstance3D in stands.get_children():
		assert_int(step.mesh.get_surface_count()).is_equal(1)


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


## And a client's match keeps its own crowd up to date from its own meter, GAME.md 10.3. It used
## to set the lights alone, so a client's crowd stood still while the host's was on its feet.
func test_a_client_tells_its_crowd_how_the_room_is_going() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES.duplicate()
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	match_node.start_puppet()
	await _runner.simulate_frames(4, 17)
	match_node.intensity.level = 6
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.arena.crowd.level).is_equal(6)
	assert_int(match_node.arena.disco.level).is_equal(6)
	assert_float(match_node.camera_rig.tremble).is_greater_equal(0.0)
	match_node.intensity.level = 2
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.arena.crowd.level).is_equal(2)
	assert_float(match_node.camera_rig.tremble).is_equal(0.0)


## Anybody who would rather have the table to themselves empties the stands, GAME.md 8.5, and
## keeps the booth: it is the thousand moving things that the setting is about.
func test_the_stands_can_be_emptied() -> void:
	var was := Game.settings.crowd_size
	Game.settings.crowd_size = 0.0
	var arena := _arena()
	var crowd := arena.crowd
	var runner: GdUnitSceneRunner = scene_runner(arena)
	await runner.simulate_frames(4, 17)
	assert_bool(crowd._onlookers.visible).is_false()
	assert_bool(crowd.get_node("Stands").visible).is_false()
	assert_bool(crowd.get_node("DjBooth").visible).is_true()
	Game.settings.crowd_size = was
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


## The house is packed at the rail and thins out behind it, GAME.md 8.1: a front row shoulder to
## shoulder and a back row of knots of people with space around them.
func test_the_house_thins_out_the_further_back_it_goes() -> void:
	var arena := _arena()
	var crowd := arena.crowd
	var half := arena.world_size() * 0.5
	var near := 0
	var far := 0
	var middle := Crowd._row_out(Crowd.ROWS / 2)
	for spot: Transform3D in crowd._spots:
		var out := maxf(absf(spot.origin.x) - half.x, absf(spot.origin.z) - half.y)
		if out < middle:
			near += 1
		else:
			far += 1
	# The band behind the halfway line is the deeper half of the two and still holds fewer people.
	assert_int(far).is_greater(20)
	assert_int(near).is_greater(far)
	# And the rows themselves spread as they go back.
	assert_float(Crowd._row_out(1) - Crowd._row_out(0)).is_less(
		Crowd._row_out(Crowd.ROWS - 1) - Crowd._row_out(Crowd.ROWS - 2)
	)
	assert_float(Crowd._row_density(0)).is_greater(Crowd._row_density(Crowd.ROWS - 1) * 2.0)
