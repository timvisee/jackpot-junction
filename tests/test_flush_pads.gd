extends GdUnitTestSuite
## Royal Flush pads, GAME.md 3.9: claiming, stealing, the flush bonus and the disabled spell.

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
	match_node.start(inputs, 9)
	return match_node


func _park(kart: Kart, pad: FlushPad) -> void:
	kart.global_position = pad.global_position
	await _runner.simulate_frames(3, 17)


func test_driving_over_pads_claims_and_steals_them_and_all_four_score_a_flush() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var rival := match_node.kart_of(1)
	var pads := match_node.arena.flush_pads
	assert_int(pads.size()).is_equal(4)
	for pad: FlushPad in pads:
		assert_int(pad.owner_slot).is_equal(-1)
	await _park(kart, pads[0])
	assert_int(pads[0].owner_slot).is_equal(0)
	assert_object(pads[0].owner_color).is_equal(Palette.player_color(kart.color_index))
	kart.global_position = match_node.arena.spawn_points[0]
	await _runner.simulate_frames(2, 17)
	await _park(rival, pads[0])
	assert_int(pads[0].owner_slot).is_equal(1)
	rival.global_position = match_node.arena.spawn_points[1]
	await _runner.simulate_frames(2, 17)
	kart.nitro_charge = 0.1
	var events := monitor_signals(Events, false)
	for pad: FlushPad in pads:
		await _park(kart, pad)
		kart.global_position += Vector3(0.0, 0.0, 3.0)
		await _runner.simulate_frames(2, 17)
	await assert_signal(events).is_emitted("flush_completed", [0])
	assert_float(kart.pot.mult).is_equal_approx(1.0 + match_node.rules.flush_mult, 0.001)
	assert_float(kart.nitro_charge).is_equal(1.0)
	for pad: FlushPad in pads:
		assert_int(pad.owner_slot).is_equal(-1)
		assert_bool(pad.is_disabled()).is_true()
	# Disabled pads ignore karts until their time is up.
	await _park(rival, pads[1])
	assert_int(pads[1].owner_slot).is_equal(-1)
	pads[1].disabled_left = 0.03
	await _runner.simulate_frames(4, 17)
	assert_bool(pads[1].is_disabled()).is_false()
	assert_int(pads[1].owner_slot).is_equal(1)


func test_pads_replicate_to_puppets_through_snapshots() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pads := match_node.arena.flush_pads
	await _park(kart, pads[2])
	var snapshot := match_node.build_snapshot()
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = match_node.rules
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(snapshot)
	assert_int(client.arena.flush_pads[2].owner_slot).is_equal(0)
	assert_int(client.arena.flush_pads[0].owner_slot).is_equal(-1)
	assert_bool(client.arena.flush_pads[2].puppet).is_true()
