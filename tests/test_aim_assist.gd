extends GdUnitTestSuite
## What a shot may be bent toward, GAME.md 5.1. Karts, turrets, boxes, bombs and shooting
## targets are all worth hitting, and a kart is worth more than any of them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const CANNON := preload("res://data/cannons/default.tres")
const CONE := PI * 0.5
const REACH := 30.0
## Where a kart is put when it is meant to be out of the shot: behind it, not beside it.
const BEHIND := Vector3(-14.0, 0.0, 9.0)

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
##
## Karts are parked with [constant BEHIND] for the same reason. Straight out to the side is not
## out of the way: that is exactly [constant CONE] from the shot, and whether a thing on the edge
## of the cone is in it or out of it comes down to the last bit of a float, which is a test that
## passes on one machine and fails on another.
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
	me.global_position = BEHIND
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
	match_node.kart_of(0).global_position = BEHIND
	match_node.kart_of(1).global_position = BEHIND * Vector3(1.0, 1.0, -1.0)
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


## The lobby's football, GAME.md 9.6: something to shoot at in a room with nobody to shoot, and a
## shot at it leans onto it the way one at a kart does.
func test_the_football_is_worth_bending_toward() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	_clear_floor(match_node)
	match_node.kart_of(0).global_position = BEHIND
	match_node.kart_of(1).global_position = BEHIND * Vector3(1.0, 1.0, -1.0)
	var ball := RoomBall.add_to(match_node, Vector3(5.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	assert_object(_best(match_node)).is_same(ball)
	# And a shot fired a little off it, inside the cone the default cannon's assist looks in, is
	# bent onto it the way it would be onto a kart.
	var shot: Bullet = auto_free(Bullet.new())
	var off := Vector3(1.0, 0.0, 0.0).rotated(Vector3.UP, CANNON.aim_assist_cone_deg * 0.01)
	shot.setup(0, Vector3.ZERO, off, CANNON, Color.WHITE)
	var before := shot.velocity.angle_to(ball.global_position)
	match_node.add_child(shot)
	shot._steer(0.1)
	assert_float(shot.velocity.angle_to(ball.global_position)).is_less(before)


func test_nothing_behind_the_shot_takes_the_aim() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	_clear_floor(match_node)
	match_node.kart_of(0).global_position = BEHIND
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
	match_node.kart_of(0).global_position = BEHIND
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


## GAME.md 5.2: the assist is for a shot taken on the move. A kart that has been parked a while
## keeps its nose pointed down a corridor and lets the bend do the aiming, so the bend fades
## away while it stands about.
func test_the_assist_fades_on_a_kart_that_stands_still() -> void:
	var stats := CANNON
	assert_float(KartAim.assist_share(stats, 0.0)).is_equal_approx(1.0, 0.001)
	# Nothing happens at all for the first moment: a kart lining a shot up is not camping.
	assert_float(KartAim.assist_share(stats, stats.assist_still_grace)).is_equal_approx(1.0, 0.001)
	var half := stats.assist_still_grace + stats.assist_still_fade * 0.5
	var midway := KartAim.assist_share(stats, half)
	assert_float(midway).is_less(1.0)
	assert_float(midway).is_greater(stats.assist_still_floor)
	# And it settles at the floor rather than falling away to nothing.
	var parked := stats.assist_still_grace + stats.assist_still_fade + 10.0
	assert_float(KartAim.assist_share(stats, parked)).is_equal_approx(
		stats.assist_still_floor, 0.001
	)


## A kart standing still runs the clock down; driving off hands the assist straight back, which
## is what keeps this from punishing a shot taken while fighting for position.
func test_standing_still_runs_the_clock_and_moving_hands_the_assist_back() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.still_for = 0.0
	for i: int in 180:
		kart._step_assist(1.0 / 60.0)
	assert_float(kart.still_for).is_greater(kart.cannon_stats.assist_still_grace)
	assert_float(kart.assist_share).is_less(1.0)
	kart.motor.velocity = -kart.global_basis.z * kart.stats.top_speed
	kart._step_assist(1.0 / 60.0)
	assert_float(kart.still_for).is_equal(0.0)
	assert_float(kart.assist_share).is_equal_approx(1.0, 0.001)


## The share rides on the bullet, so a shot already in the air is not re-judged and a cannon
## with no assist at all does not get one back.
func test_the_share_scales_the_bend_the_shot_leaves_with() -> void:
	var stats := CANNON
	var bullet: Bullet = auto_free(Bullet.new())
	bullet.setup(0, Vector3.ZERO, Vector3(1.0, 0.0, 0.0), stats, Color.WHITE)
	var cone := bullet.assist_cone
	var turn := bullet.assist_turn_rate
	bullet.apply_assist_share(0.25)
	assert_float(bullet.assist_cone).is_equal_approx(cone * 0.25, 0.0001)
	assert_float(bullet.assist_turn_rate).is_equal_approx(turn * 0.25, 0.0001)
	assert_bool(bullet.assist_enabled).is_true()
	var blind: Bullet = auto_free(Bullet.new())
	var no_assist: CannonStats = stats.duplicate()
	no_assist.aim_assist = false
	blind.setup(0, Vector3.ZERO, Vector3(1.0, 0.0, 0.0), no_assist, Color.WHITE)
	blind.apply_assist_share(1.0)
	assert_bool(blind.assist_enabled).is_false()
