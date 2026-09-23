extends GdUnitTestSuite
## Where the tire marks are laid, GAME.md 4.3: under the wheels making them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new()]
	match_node.start(inputs, 7)
	return match_node


## The rear axle is taken from the middle of the tires on the model rather than from a fraction
## of the kart's length or from the point the model hangs a wheel from, either of which puts the
## marks somewhere the rubber is not.
func test_the_marks_are_laid_at_the_middle_of_the_rear_tires() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var wanted := Vector2.ZERO
	var count := 0
	for wheel: MeshInstance3D in kart._wheels:
		if not wheel.name.to_lower().contains("back"):
			continue
		var to_kart := kart.global_transform.affine_inverse() * wheel.global_transform
		var at := (to_kart * wheel.get_aabb()).get_center()
		wanted += Vector2(absf(at.x), at.z)
		count += 1
	assert_int(count).is_equal(2)
	wanted /= float(count)
	assert_float(kart.rear_half_track).is_equal_approx(wanted.x, 0.001)
	assert_float(kart.rear_axle).is_equal_approx(wanted.y, 0.001)
	# And that is wider than the wheels' own origins, which sit at their inner faces.
	var origin := absf(kart.to_local(kart._wheels[0].global_position).x)
	assert_float(kart.rear_half_track).is_greater(origin)
