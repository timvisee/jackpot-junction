extends GdUnitTestSuite
## Jokers that stack, GAME.md 3.7 and 7.3.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 21)
	return match_node


func _joker(id: String) -> Joker:
	return load("res://data/jokers/%s.tres" % id)


## A card on the floor that the hand already holds is left there for somebody else, unless it
## stacks.
func test_a_floor_joker_already_held_is_left_unless_it_stacks() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(10, 17)
	var kart := match_node.kart_of(0)
	var lying := match_node.arena.spawn_floor_joker(Vector3.ZERO, _joker("pickpocket"), 15.0)
	assert_bool(lying.can_collect(kart)).is_true()
	kart.jokers.add(_joker("pickpocket"))
	assert_bool(lying.can_collect(kart)).is_false()
	assert_bool(lying.can_collect(match_node.kart_of(1))).is_true()
	var bumpers := match_node.arena.spawn_floor_joker(Vector3.ZERO, _joker("rubber_bumpers"), 15.0)
	kart.jokers.add(_joker("rubber_bumpers"))
	assert_bool(bumpers.can_collect(kart)).is_true()
