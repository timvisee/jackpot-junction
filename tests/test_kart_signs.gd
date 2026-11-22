extends GdUnitTestSuite
## Where the karts are when they cannot be seen, GAME.md 8.2 and 8.5: an arrow at the edge of the
## screen for a kart out of the picture, see [KartPointers].

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


## A match with a player at this screen and a bot, its HUD up.
func _playing() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, -1), KartInput.new()]
	match_node.start(inputs, 5)
	await _runner.simulate_frames(12, 17)
	return match_node


func test_a_kart_out_of_the_picture_is_pointed_at_from_the_edge() -> void:
	var match_node := await _playing()
	var pointers := match_node.hud.get_node("KartPointers") as KartPointers
	var rival := match_node.kart_of(1)
	rival.global_position = match_node.camera_rig.camera.global_position + Vector3(400.0, 0.0, 0.0)
	rival.global_position.y = 0.0
	pointers._process(0.0)
	var arrows := pointers._signs.filter(
		func(each: Dictionary) -> bool: return each.color == match_node.slots[1].color()
	)
	assert_int(arrows.size()).is_equal(1)
	var at: Vector2 = arrows[0].at
	assert_float(at.x).is_equal_approx(pointers.size.x - KartPointers.INSET, 1.0)
	assert_float((arrows[0].way as Vector2).x).is_greater(0.5)
