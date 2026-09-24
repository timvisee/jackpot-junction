extends GdUnitTestSuite
## The whistle, GAME.md 2 and 8.1: the karts are let go of rather than stopped dead, and the
## disco rig swings onto the winner.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	return match_node


func test_the_karts_roll_to_a_halt_rather_than_stopping_dead() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	kart.global_position = Vector3(-8.0, 0.0, -6.0)
	kart.motor.velocity = -kart.global_transform.basis.z * 12.0
	kart.motor.forward_speed = 12.0
	var from := kart.global_position
	match_node._finish()
	assert_bool(kart.coasting).is_true()
	assert_bool(kart.frozen).is_false()
	# Still rolling the moment after the whistle, and further on than it was.
	await _runner.simulate_frames(10, 17)
	assert_float(kart.motor.speed()).is_greater(1.0)
	assert_float(kart.global_position.distance_to(from)).is_greater(0.5)
	# And stopped on its own a few seconds later, with nobody having touched the controls.
	await _runner.simulate_frames(300, 17)
	assert_float(kart.motor.speed()).is_less(0.5)


## Nothing may reach a kart that is only rolling out the end of the match: a late cash-out or a
## pit would change a score the results screen has already shown.
func test_a_coasting_kart_is_out_of_play() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	kart.pot.add_coins(50)
	match_node._finish()
	assert_bool(kart.is_active()).is_false()
	assert_bool(kart.is_targetable()).is_false()
	kart.start_fall()
	assert_bool(kart.falling).is_false()
	var banked := match_node.slots[0].banked
	kart.global_position = match_node.arena.junction.global_position
	await _runner.simulate_frames(120, 17)
	assert_int(match_node.slots[0].banked).is_equal(banked)
	assert_bool(kart.alive).is_true()


func test_the_rig_swings_every_head_onto_the_winner() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	match_node.slots[1].banked = 500
	match_node.kart_of(1).global_position = Vector3(9.0, 0.0, 4.0)
	match_node._finish()
	assert_int(match_node.standings()[0].index).is_equal(1)
	var lights := match_node.arena.disco
	await _runner.simulate_frames(240, 17)
	assert_float(lights._swing).is_equal(1.0)
	assert_int(lights.lit_count()).is_equal(DiscoLights.COUNT)
	var winner := match_node.kart_of(1).global_position
	for i: int in lights._heads.size():
		var light: SpotLight3D = lights._heads[i]["light"]
		var forward := -light.global_transform.basis.z
		var toward := (winner - light.global_position).normalized()
		(
			assert_float(forward.normalized().dot(toward))
			. override_failure_message("head %d is not looking at the winner" % i)
			. is_greater(0.99)
		)


## GAME.md 8.1: whoever tops the standings gets the rig, on their wheels or not. A leader lying
## in a pit at the whistle used to be passed over, and the room saw out the end of the match
## with the lights still sweeping as though nobody had won it.
func test_the_rig_takes_the_winner_even_when_they_are_down() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	match_node.slots[1].banked = 500
	var winner := match_node.kart_of(1)
	winner.die(&"pit", -1)
	match_node._finish()
	assert_int(match_node.standings()[0].index).is_equal(1)
	assert_bool(winner.alive).is_false()
	assert_object(match_node.arena.disco._focus).is_same(winner)
	await _runner.simulate_frames(120, 17)
	assert_int(match_node.arena.disco.lit_count()).is_equal(DiscoLights.COUNT)


## GAME.md 8.3: the start gantry is up for the countdown and the moment after it, whatever the
## match goes on to. A map whose Last Call starts as the flag drops went straight past playing,
## which was the only state that ever put the lamps away.
func test_the_start_lamps_go_whatever_the_match_goes_on_to() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.3
	rules.duration = 20.0
	rules.last_call_duration = 30.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([PlayerInput.new(), KartInput.new()] as Array[KartInput], 5)
	await _runner.simulate_frames(5, 17)
	assert_bool(match_node.hud._light.visible).is_true()
	await _runner.simulate_frames(90, 17)
	assert_int(match_node.state).is_equal(Match.State.LAST_CALL)
	assert_bool(match_node.hud._light.visible).is_false()
