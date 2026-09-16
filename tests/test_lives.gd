extends GdUnitTestSuite
## Two lives, GAME.md 3.6 and 5.4: the first hit wounds, the Junction heals, the second hit
## kills, pits kill outright, and a wounded kart is slower and darker.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LANE := Vector3(0.0, 0.0, -9.375)

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
	match_node.start(inputs, 11)
	return match_node


## Fires one unassisted bullet from 5 m left of [param at] along +X and lets it arrive.
func _shoot(match_node: Match, shooter: Kart, at: Vector3) -> void:
	shooter.global_position = at + Vector3(-5.0, 0.0, 0.0)
	shooter.face(Vector3(1.0, 0.0, 0.0))
	shooter.cannon.stats.aim_assist = false
	shooter.cannon.cooldown_left = 0.0
	shooter.cannon.fire(
		match_node.bullets,
		shooter.slot,
		shooter.global_position + Vector3(1.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		Color.WHITE
	)
	await _runner.simulate_frames(30, 17)


func test_the_first_hit_wounds_the_junction_heals_and_the_second_hit_kills() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	var color := Palette.player_color(victim.color_index)
	victim.global_position = LANE
	victim.face(Vector3(1.0, 0.0, 0.0))
	var base_speed := victim.stats.top_speed
	assert_int(victim.lives).is_equal(2)
	var events := monitor_signals(Events, false)
	await _shoot(match_node, shooter, LANE)
	assert_bool(victim.alive).is_true()
	assert_int(victim.lives).is_equal(1)
	assert_bool(victim.is_wounded()).is_true()
	assert_float(victim.stats.top_speed).is_equal_approx(base_speed * 0.85, 0.001)
	assert_float(victim._tint.albedo_color.v).is_less(color.v - 0.1)
	await assert_signal(events).is_emitted("kart_wounded", [1, 0, &"bullet"])
	victim.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(3, 17)
	assert_int(victim.lives).is_equal(2)
	assert_float(victim.stats.top_speed).is_equal_approx(base_speed, 0.001)
	assert_object(victim._tint.albedo_color).is_equal(color)
	await assert_signal(events).is_emitted("life_restored", [1])
	victim.global_position = LANE
	victim.face(Vector3(1.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	await _shoot(match_node, shooter, LANE)
	assert_int(victim.lives).is_equal(1)
	await _runner.simulate_frames(20, 17)
	await _shoot(match_node, shooter, LANE)
	assert_bool(victim.alive).is_false()
	assert_int(match_node.slots[0].kills).is_equal(1)
	assert_int(match_node.slots[1].deaths).is_equal(1)
	await _runner.simulate_frames(200, 17)
	assert_bool(victim.alive).is_true()
	assert_int(victim.lives).is_equal(2)
	assert_float(victim.stats.top_speed).is_equal_approx(base_speed, 0.001)


func test_a_fresh_wound_cannot_be_hit_again_for_a_moment() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	victim.global_position = LANE
	await _shoot(match_node, shooter, LANE)
	assert_int(victim.lives).is_equal(1)
	victim.hurt_left = 0.4
	assert_bool(victim.is_targetable()).is_false()
	var bullet := match_node.bullets.spawn(
		0, LANE + Vector3(-2.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), shooter.cannon.stats, Color.WHITE
	)
	assert_bool(victim.take_hit(bullet)).is_false()
	assert_int(victim.lives).is_equal(1)
	assert_bool(victim.alive).is_true()
	bullet.destroy()


func test_a_pit_kills_a_kart_whatever_its_lives() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var victim := match_node.kart_of(1)
	victim.global_position = match_node.arena.pits[0].global_position
	await _runner.simulate_frames(45, 17)
	assert_bool(victim.alive).is_false()
	assert_int(match_node.slots[1].deaths).is_equal(1)


func test_lives_reach_puppets_through_snapshots() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	victim.global_position = LANE
	await _shoot(match_node, shooter, LANE)
	assert_int(victim.lives).is_equal(1)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = match_node.rules
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(match_node.build_snapshot())
	var puppet: Kart = client.slots[1].kart
	assert_int(puppet.lives).is_equal(1)
	assert_bool(puppet.is_wounded()).is_true()
	assert_float(puppet._tint.albedo_color.v).is_less(Palette.player_color(1).v - 0.1)
	assert_int(client.slots[0].kart.lives).is_equal(2)
