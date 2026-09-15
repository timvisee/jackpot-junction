extends GdUnitTestSuite
## Spawning, shooting, dying and respawning in a running match, GAME.md 3.6.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func test_pick_spawn_prefers_the_point_farthest_from_every_enemy() -> void:
	var points: Array[Vector3] = [
		Vector3(-10.0, 0.0, -5.0),
		Vector3(10.0, 0.0, -5.0),
		Vector3(-10.0, 0.0, 5.0),
		Vector3(10.0, 0.0, 5.0)
	]
	var enemies: Array[Vector3] = [Vector3(-9.0, 0.0, -5.0), Vector3(9.0, 0.0, -5.0)]
	assert_vector(Match.pick_spawn(points, enemies)).is_equal(Vector3(-10.0, 0.0, 5.0))
	assert_vector(Match.pick_spawn(points, [])).is_equal(points[0])


func test_start_spawns_a_kart_per_input_facing_the_junction() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	add_child(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new(), KartInput.new()]
	match_node.start(inputs, 7)
	assert_int(match_node.slots.size()).is_equal(3)
	assert_int(match_node.state).is_equal(Match.State.COUNTDOWN)
	for slot: PlayerSlot in match_node.slots:
		assert_bool(slot.kart.alive).is_true()
		var to_centre := (
			(match_node.arena.junction_position - slot.kart.global_position).normalized()
		)
		var forward := -slot.kart.global_basis.z
		assert_float(forward.dot(to_centre)).is_greater(0.99)


func test_a_bullet_kills_the_kart_ahead_and_the_victim_respawns_protected() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	match_node.rules = rules
	match_node.with_hud = false
	var runner := scene_runner(match_node)
	var shooter_input := KartInput.new()
	var inputs: Array[KartInput] = [shooter_input, KartInput.new()]
	match_node.start(inputs, 7)
	await runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	shooter.global_position = Vector3(6.0, 0.0, 6.0)
	shooter.face(Vector3(-1.0, 0.0, 0.0))
	victim.global_position = Vector3(1.0, 0.0, 6.0)
	victim.face(Vector3(-1.0, 0.0, 0.0))
	var killed := monitor_signals(Events, false)
	shooter_input.fire = true
	await runner.simulate_frames(45, 17)
	assert_bool(victim.alive).is_false()
	assert_int(match_node.slots[1].deaths).is_equal(1)
	assert_int(match_node.slots[0].kills).is_equal(1)
	await assert_signal(killed).is_emitted("kart_killed", [1, 0, &"bullet"])
	shooter_input.fire = false
	await runner.simulate_frames(200, 17)
	assert_bool(victim.alive).is_true()
	assert_float(victim.protection_left).is_greater(0.0)
	assert_bool(victim.is_targetable()).is_false()
