extends GdUnitTestSuite
## The cones round the Garage's rings, GAME.md 9.4: a kart that clips one knocks it over, and it
## lies a few seconds before it is stood back up where it was. See [RingCones].

const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")

var _runner: GdUnitSceneRunner


## Every cone stands just outside the outer ring, and none on the way to anything.
func test_the_cones_stand_outside_the_outer_ring() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	_runner = scene_runner(garage)
	await _runner.simulate_frames(60, 17)
	var match_node: Match = garage.get_node("Match")
	var cones: RingCones = garage.get("cones")
	var paint: GarageFloor = garage.get("floor_paint")
	assert_int(cones.cones.size()).is_equal(RingCones.ANGLES.size())
	for cone: Node3D in cones.cones:
		var reach := cone.position - match_node.arena.junction_position
		var out := Vector2(reach.x, reach.z).length()
		assert_float(out).is_equal_approx(paint.outer + RingCones.OUTSIDE, 0.01)


## A kart that clips a cone knocks it over; it lies a few seconds and is stood back up where it was.
func test_a_cone_knocked_over_stands_back_up() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	_runner = scene_runner(garage)
	await _runner.simulate_frames(60, 17)
	var match_node: Match = garage.get_node("Match")
	var cones: RingCones = garage.get("cones")
	var spot := cones.cones[0].position
	var kart := match_node.kart_of(0)
	kart.global_position = spot + Vector3(0.3, 0.0, 0.0)
	await _runner.simulate_frames(3, 17)
	assert_bool(cones.standing(0)).is_false()
	# Out of the way, so it is not knocked again the moment it is up.
	kart.global_position = spot + Vector3(0.0, 0.0, 4.0)
	await _runner.simulate_frames(roundi((RingCones.LIES + RingCones.STANDS) * 60.0) + 20, 17)
	assert_bool(cones.standing(0)).is_true()
	assert_vector(cones.cones[0].position).is_equal_approx(spot, Vector3.ONE * 0.01)
