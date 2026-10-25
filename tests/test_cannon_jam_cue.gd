extends GdUnitTestSuite
## The JAMMED cue, [CannonJamCue]: it shows only while the human playing on this machine has a
## cannon locked by a scrambler, GAME.md 5.3, and hides once the lock runs out.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 9)
	return match_node


func test_the_cue_shows_only_while_the_local_cannon_is_locked() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var cue := CannonJamCue.add_to(match_node, match_node)
	var kart := match_node.kart_of(0)
	# Clear: nothing shown.
	kart.cannon_locked_left = 0.0
	cue._process(0.016)
	assert_bool(cue._label.visible).is_false()
	# Locked by a scrambler: the word shows.
	kart.cannon_locked_left = 3.0
	cue._process(0.016)
	assert_bool(cue._label.visible).is_true()
	# Lock run out: hidden again.
	kart.cannon_locked_left = 0.0
	cue._process(0.016)
	assert_bool(cue._label.visible).is_false()
