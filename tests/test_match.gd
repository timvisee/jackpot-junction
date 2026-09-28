extends GdUnitTestSuite
## Spawning, shooting, dying and respawning in a running match, GAME.md 3.6.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const CANNON: CannonStats = preload("res://data/cannons/default.tres")
const RULES: MatchRules = preload("res://data/match/default.tres")


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
		var to_center := (
			(match_node.arena.junction_position - slot.kart.global_position).normalized()
		)
		var forward := -slot.kart.global_basis.z
		assert_float(forward.dot(to_center)).is_greater(0.99)


func test_a_bullet_kills_the_kart_ahead_and_the_victim_respawns_protected() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	match_node.rules = rules
	match_node.with_hud = false
	var runner := scene_runner(match_node)
	var shooter_input := KartInput.new()
	var inputs: Array[KartInput] = [shooter_input, KartInput.new()]
	match_node.start(inputs, 7)
	await runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	shooter.global_position = Vector3(6.0, 0.0, 8.0)
	shooter.face(Vector3(-1.0, 0.0, 0.0))
	victim.global_position = Vector3(1.0, 0.0, 8.0)
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


func test_two_bullets_meeting_head_on_destroy_each_other() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	match_node.rules = rules
	match_node.with_hud = false
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 7)
	await runner.simulate_frames(12, 17)
	var stats := CANNON
	var left := match_node.bullets.spawn(
		0, Vector3(-6.0, 0.0, 1.0), Vector3(1.0, 0.0, 0.0), stats, Color.WHITE
	)
	var right := match_node.bullets.spawn(
		1, Vector3(-1.0, 0.0, 1.0), Vector3(-1.0, 0.0, 0.0), stats, Color.WHITE
	)
	await runner.simulate_frames(20, 17)
	assert_bool(is_instance_valid(left) and not left.is_dead()).is_false()
	assert_bool(is_instance_valid(right) and not right.is_dead()).is_false()
	assert_int(match_node.bullets.live_count()).is_equal(0)


## GAME.md 3.8: the results screen offers a rematch, which tears the room down and builds it
## again for the same players. The match node itself survives that, so anything it hung on a
## signal outside itself is still hanging there the second time round.
func test_a_rematch_rebuilds_the_room_without_connecting_anything_twice() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(10, 17)
	match_node.slots[0].banked = 700
	assert_int(_connections(match_node)).is_equal(2)
	match_node.rematch()
	await runner.simulate_frames(10, 17)
	# The same players, a fresh arena, and nobody carrying last match's score.
	assert_int(match_node.slots.size()).is_equal(2)
	assert_int(match_node.slots[0].banked).is_equal(0)
	assert_object(match_node.arena).is_not_null()
	assert_object(match_node.camera_rig).is_not_null()
	assert_int(match_node.kart_of(0).lives).is_equal(rules.lives)
	# One connection each, not two. The engine refuses a duplicate rather than making one, so
	# this held before the guard was added as well; what the guard takes away is the pair of
	# errors it printed on the way, on a button every player who finishes a match can press.
	assert_int(_connections(match_node)).is_equal(2)


## How many of the match's own handlers are hanging off the global event bus: its own, and those
## of what it counts the results screen's figures with, see [MatchStats.Listener].
func _connections(match_node: Match) -> int:
	var mine := 0
	for signal_name: StringName in [&"joker_taken", &"life_restored"]:
		for entry: Dictionary in (Events.get(signal_name) as Signal).get_connections():
			var owner := (entry["callable"] as Callable).get_object()
			if owner == match_node or owner == match_node._counting:
				mine += 1
	return mine
