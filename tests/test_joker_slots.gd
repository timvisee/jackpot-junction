extends GdUnitTestSuite
## How many jokers a hand holds, GAME.md 3.7 and 7.3: the lobby's number, which a joker in the hand
## can widen.

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


func _attach(kart: Kart, id: String) -> Joker:
	return kart.jokers.add(load("res://data/jokers/%s.tres" % id))


## GAME.md 3.7: the lobby says how many jokers a hand holds, and Deep Pockets still adds its two
## to however many that is. The lobby's row carries it to the rules and keeps it for next time.
func test_the_lobby_sets_how_many_jokers_a_hand_holds() -> void:
	var match_node := _start_match()
	var kart := match_node.kart_of(0)
	match_node.rules.joker_slots = 3
	assert_int(kart.jokers.capacity()).is_equal(3)
	_attach(kart, "deep_pockets")
	assert_int(kart.jokers.capacity()).is_equal(5)
	var config := MatchConfig.new()
	config.joker_slots = 7
	var rules := config.rules(match_node.rules)
	assert_int(rules.joker_slots).is_equal(7)
	var client: MatchRules = match_node.rules.duplicate()
	client.from_wire(rules.to_wire())
	assert_int(client.joker_slots).is_equal(7)


## GAME.md 3.7: five slots unless the hand itself says otherwise, and Deep Pockets stands in one
## of the two it adds. Two copies leave room for seven other jokers.
func test_deep_pockets_widens_the_hand_and_stacks() -> void:
	var match_node := _start_match()
	var kart := match_node.kart_of(0)
	assert_int(kart.jokers.capacity()).is_equal(JokerHolder.MAX_JOKERS)
	_attach(kart, "deep_pockets")
	assert_int(kart.jokers.capacity()).is_equal(7)
	assert_bool(kart.jokers.is_full()).is_false()
	var second := _attach(kart, "deep_pockets")
	assert_int(kart.jokers.capacity()).is_equal(9)
	for i: int in 7:
		_attach(kart, "big_tank")
	assert_int(kart.jokers.count()).is_equal(9)
	assert_bool(kart.jokers.is_full()).is_true()
	# Losing one takes its room with it, and a hand over the new limit is simply full.
	kart.jokers.remove(second)
	assert_int(kart.jokers.capacity()).is_equal(7)
	assert_bool(kart.jokers.is_full()).is_true()
