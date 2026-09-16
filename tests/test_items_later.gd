extends GdUnitTestSuite
## The later power-up set from GAME.md 7.1: Decoy Kart, Spread Cannon, Swivel Cannon, Bullet Wipe.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const CANNON: CannonStats = preload("res://data/cannons/default.tres")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 13)
	return match_node


func _item(id: String) -> PowerUp:
	return load("res://data/powerups/%s.tres" % id)


func _decoys(match_node: Match) -> Array[Kart]:
	var result: Array[Kart] = []
	for child: Node in match_node.get_children():
		var kart := child as Kart
		if kart != null and kart.is_decoy():
			result.append(kart)
	return result


func test_tables_cover_the_first_and_later_sets() -> void:
	var later: PowerUpTable = load("res://data/powerups/later_set.tres")
	var all: PowerUpTable = load("res://data/powerups/all.tres")
	assert_int(later.entries.size()).is_equal(4)
	assert_int(all.entries.size()).is_equal(11)


func test_decoy_fights_for_its_owner_and_dies_to_one_hit() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var owner := match_node.kart_of(0)
	owner.global_position = Vector3(-4.5, 0.0, 1.0)
	owner.face(Vector3(0.0, 0.0, -1.0))
	var decoy_item: DecoyKartPowerUp = _item("decoy_kart").duplicate()
	decoy_item.lifetime = 30.0
	decoy_item.activate(owner)
	var decoys := _decoys(match_node)
	assert_int(decoys.size()).is_equal(1)
	var decoy := decoys[0]
	assert_int(decoy.slot).is_equal(0)
	assert_object(decoy.get_node_or_null("Brain")).is_not_null()
	var chip := Chip.new()
	chip.value = 3
	chip.position = decoy.global_position
	match_node.arena.pickups.add_child(chip)
	await _runner.simulate_frames(10, 17)
	assert_int(owner.pot.coins).is_equal(3)
	assert_int(decoy.pot.coins).is_equal(0)
	var stats := CANNON
	var from := decoy.global_position + Vector3(3.0, 0.0, 0.0)
	match_node.bullets.spawn(
		1, from, (decoy.global_position - from).normalized(), stats, Color.WHITE
	)
	await _runner.simulate_frames(20, 17)
	assert_int(_decoys(match_node).size()).is_equal(0)
	assert_bool(owner.alive).is_true()


func test_decoy_expires_on_its_own() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var owner := match_node.kart_of(0)
	owner.global_position = Vector3(-4.5, 0.0, 1.0)
	var decoy_item: DecoyKartPowerUp = _item("decoy_kart").duplicate()
	decoy_item.lifetime = 0.3
	decoy_item.activate(owner)
	assert_int(_decoys(match_node).size()).is_equal(1)
	await _runner.simulate_frames(40, 17)
	assert_int(_decoys(match_node).size()).is_equal(0)


func test_spread_cannon_fires_a_fan() -> void:
	var match_node := _start_match()
	var kart := match_node.kart_of(0)
	_item("spread_cannon").activate(kart)
	kart.cannon.cooldown_left = 0.0
	var shots := kart.cannon.fire(
		match_node.bullets, 0, Vector3(0.0, 0.0, 6.0), Vector3(0.0, 0.0, -1.0), Color.WHITE
	)
	assert_int(shots.size()).is_equal(3)
	assert_float(shots[0].velocity.angle_to(shots[2].velocity)).is_equal_approx(
		deg_to_rad(20.0), 0.01
	)
	for bullet: Bullet in shots:
		bullet.destroy()


func test_bullet_wipe_clears_nearby_bullets_only() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.global_position = Vector3(-4.5, 0.0, 1.0)
	var stats := CANNON
	var near := match_node.bullets.spawn(
		1, kart.global_position + Vector3(3.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), stats, Color.WHITE
	)
	var far := match_node.bullets.spawn(
		1,
		kart.global_position + Vector3(14.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 1.0),
		stats,
		Color.WHITE
	)
	_item("bullet_wipe").activate(kart)
	assert_bool(near.is_dead()).is_true()
	assert_bool(far.is_dead()).is_false()
	far.destroy()


func test_swivel_cannon_aims_with_the_stick_then_wears_off() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.face(Vector3(0.0, 0.0, -1.0))
	assert_vector(kart.aim_direction()).is_equal_approx(
		Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.001
	)
	var swivel: SwivelCannonPowerUp = _item("swivel_cannon").duplicate()
	swivel.duration = 0.4
	swivel.activate(kart)
	assert_bool(kart.cannon.current_stats().free_aim).is_true()
	kart.input.aim = Vector2(1.0, 0.0)
	assert_vector(kart.aim_direction()).is_equal_approx(Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.001)
	await _runner.simulate_frames(40, 17)
	assert_bool(kart.cannon.current_stats().free_aim).is_false()
	kart.input.aim = Vector2.ZERO
