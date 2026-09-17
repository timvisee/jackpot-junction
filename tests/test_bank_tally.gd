extends GdUnitTestSuite
## The cash-out tally, GAME.md 8.3. A player parked on the Junction while the Royal Flush pads
## trickle finishes a cash-out of one coin every second, so a run of them has to read as one
## number climbing rather than as a label, a shower of chips and a thump for every coin.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func _tallies(match_node: Match) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in match_node.get_children():
		if child is FloatingText:
			found.append(child)
	return found


func test_a_run_of_cash_outs_climbs_one_number() -> void:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 17)
	await runner.simulate_frames(30, 17)
	var hud := match_node.hud
	var kart := match_node.kart_of(0)
	# One proper cash-out: its own label, with the equation on it.
	Events.bank_completed.emit(0, 12, 3.0, 36)
	await runner.simulate_frames(2, 17)
	assert_int(_tallies(match_node).size()).is_equal(1)
	var tally: FloatingText = hud._tallies[0]
	assert_int(tally.total()).is_equal(36)
	assert_str(tally.text).contains("×")
	# The trickle banking a coin at a time adds to it rather than piling labels up.
	for i: int in 5:
		Events.bank_completed.emit(0, 1, 1.0, 1)
		await runner.simulate_frames(2, 17)
	assert_int(_tallies(match_node).size()).is_equal(1)
	assert_int(tally.total()).is_equal(41)
	# The equation is dropped once it is no longer what made the number.
	assert_str(tally.text).not_contains("×")
	# Another player's cash-out is their own business and their own label.
	Events.bank_completed.emit(1, 4, 2.0, 8)
	await runner.simulate_frames(2, 17)
	assert_int(_tallies(match_node).size()).is_equal(2)
	# And it goes away on its own once the coins stop.
	await runner.simulate_frames(180, 17)
	assert_int(_tallies(match_node).size()).is_equal(0)
	assert_bool(kart.alive).is_true()
