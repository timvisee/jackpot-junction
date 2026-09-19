extends GdUnitTestSuite
## The results screen, GAME.md 3.8: everybody ranked by what they banked, each on a row of their
## own with their awards beside them, built like the joker detail pane so the two read as the
## same game.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _finished_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.overtime = false
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new(), KartInput.new()]
	match_node.start(inputs, 31, [], ["Ada", "Grace", "Linus"])
	return match_node


## Every label the screen carries, flattened, so a test can ask what it says without walking the
## boxes it is laid out in.
func _texts(node: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	var label := node as Label
	if label != null:
		found.append(label.text)
	for child: Node in node.get_children():
		found.append_array(_texts(child))
	return found


func test_the_screen_ranks_everybody_with_their_score_and_awards() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	match_node.slots[1].banked = 900
	match_node.slots[0].banked = 400
	match_node.slots[0].kills = 2
	match_node.slots[0].stats.add(&"crates", 9.0)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	var screen: ResultsScreen = match_node.hud._results
	assert_bool(screen.visible).is_true()
	var texts := _texts(screen)
	assert_array(texts).contains(["Results", "Grace", "Ada", "900", "400", "2 kills"])
	# Ranked by what is banked, so the winner's row comes first.
	assert_int(Array(texts).find("Grace")).is_less(Array(texts).find("Ada"))
	# The award for what somebody did most of is on their row, as a chip of its own.
	assert_array(texts).contains(["Demolition Crew", "9 crates broken"])
	# The bar along the top wears the winner's colour, the way the joker pane wears the kind's.
	assert_object(screen._style.border_color).is_equal(match_node.slots[1].color())


## The same screen filled in twice says the same thing, which is what a client does every time
## the host repeats that the match is over.
func test_filling_the_screen_in_again_does_not_double_it_up() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	var screen: ResultsScreen = match_node.hud._results
	var before := _texts(screen).size()
	screen.fill_in()
	assert_int(_texts(screen).size()).is_equal(before)
