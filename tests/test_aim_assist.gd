extends GdUnitTestSuite
## What a shot may be bent toward, GAME.md 5.1. Karts, turrets, boxes, bombs and shooting
## targets are all worth hitting, and a kart is worth more than any of them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const CONE := PI * 0.5
const REACH := 30.0

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


## Everything on the floor is a target now, so the ones a test is not about are parked well out
## of reach. Shooting them would not do: a box that has been broken puts itself back up.
func _clear_floor(match_node: Match) -> void:
	var away := Vector3(0.0, 0.0, -400.0)
	for crate: Crate in match_node.arena.crates:
		crate.global_position = away
		away += Vector3(4.0, 0.0, 0.0)
	for target: Target in match_node.arena.targets:
		target.global_position = away
		away += Vector3(4.0, 0.0, 0.0)


## From the origin, looking along +X.
func _best(match_node: Match) -> Node3D:
	return Bullet.nearest_target(
		match_node.get_tree(), Vector3.ZERO, 0, REACH, Vector3(1.0, 0.0, 0.0), CONE
	)


## The same question asked of a shot that has to actually get there.
func _best_seen(match_node: Match) -> Node3D:
	return Bullet.nearest_target(
		match_node.get_tree(),
		Vector3.ZERO,
		0,
		REACH,
		Vector3(1.0, 0.0, 0.0),
		CONE,
		match_node.arena.get_world_3d().direct_space_state
	)


func test_a_kart_is_worth_more_than_a_box_in_front_of_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	_clear_floor(match_node)
	var me := match_node.kart_of(0)
	var enemy := match_node.kart_of(1)
	me.global_position = Vector3(0.0, 0.0, 12.0)
	enemy.global_position = Vector3(8.0, 0.0, 0.0)
	var crate: Crate = match_node.arena.crates[0]
	crate.global_position = Vector3(4.0, 0.0, 0.0)
	# Twice as far away and still the better thing to shoot at.
	assert_object(_best(match_node)).is_same(enemy)
	# A box right under the nose wins: this is a nudge, not a guarantee.
	crate.global_position = Vector3(2.0, 0.0, 0.0)
	assert_object(_best(match_node)).is_same(crate)


func test_bombs_and_shooting_targets_are_worth_bending_toward() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	_clear_floor(match_node)
	match_node.kart_of(0).global_position = Vector3(0.0, 0.0, 12.0)
	match_node.kart_of(1).global_position = Vector3(0.0, 0.0, -12.0)
	var target: Target = auto_free(Target.new())
	match_node.add_child(target)
	target.global_position = Vector3(6.0, 0.0, 0.0)
	await _runner.simulate_frames(2, 17)
	assert_object(_best(match_node)).is_same(target)
	var bomb: Bomb = auto_free(Bomb.new())
	bomb.fuse = 600.0
	match_node.add_child(bomb)
	bomb.global_position = Vector3(3.0, 0.0, 0.0)
	await _runner.simulate_frames(2, 17)
	assert_object(_best(match_node)).is_same(bomb)
	# Nothing that has already gone off or been knocked down is worth aiming at.
	bomb.alive = false
	target.alive = false
	assert_object(_best(match_node)).is_null()


func test_nothing_behind_the_shot_takes_the_aim() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	_clear_floor(match_node)
	match_node.kart_of(0).global_position = Vector3(0.0, 0.0, 12.0)
	match_node.kart_of(1).global_position = Vector3(-6.0, 0.0, 0.0)
	var crate: Crate = match_node.arena.crates[0]
	crate.global_position = Vector3(-3.0, 0.0, 0.0)
	assert_object(_best(match_node)).is_null()


## GAME.md 5.2: the bend cannot go round a wall, so a target standing behind one is passed over.
## Curve Ball made this obvious: a shot fired at a wall swung hard toward somebody safely behind
## it and buried itself in the brickwork.
func test_a_target_behind_a_wall_is_passed_over() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	_clear_floor(match_node)
	var enemy := match_node.kart_of(1)
	match_node.kart_of(0).global_position = Vector3(0.0, 0.0, 12.0)
	enemy.global_position = Vector3(5.0, 0.0, 0.0)
	var crate: Crate = match_node.arena.crates[0]
	crate.global_position = Vector3(2.5, 0.0, 0.0)
	await _runner.simulate_frames(4, 17)
	# On distance alone the kart wins, being worth far more than a box.
	assert_object(_best(match_node)).is_same(enemy)
	# A shot that has to get there picks the box, which is what it would hit anyway.
	assert_object(_best_seen(match_node)).is_same(crate)
	# Out from behind the box and it is the better thing to aim at again.
	enemy.global_position = Vector3(4.0, 0.0, 3.0)
	await _runner.simulate_frames(4, 17)
	assert_object(_best_seen(match_node)).is_same(enemy)
