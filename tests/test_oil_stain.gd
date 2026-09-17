extends GdUnitTestSuite
## The Oil Stain item, GAME.md 7.1 and 4.1: the slick catches any kart that crosses it, the nose
## whips around while the kart keeps its line, and controls do nothing until it straightens out.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const ITEM: OilStainPowerUp = preload("res://data/powerups/oil_stain.tres")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 19)
	return match_node


func test_a_spinning_motor_keeps_its_line_while_the_nose_whips_around() -> void:
	var stats: KartStats = load("res://data/kart/default.tres").duplicate()
	var motor := KartMotor.new(stats)
	var input := KartInput.new()
	input.throttle = 1.0
	for i: int in 150:
		motor.step(input, 1.0 / 60.0)
	var direction := motor.velocity.normalized()
	var speed := motor.speed()
	assert_float(speed).is_greater(stats.top_speed * 0.9)
	motor.apply_spin_out(1.0)
	assert_bool(motor.spinning()).is_true()
	# Steering and throttle are ignored: the nose spins the way the oil sent it.
	input.steer = -1.0
	var turned := 0.0
	var previous := motor.heading
	for i: int in 30:
		motor.step(input, 1.0 / 60.0)
		turned += absf(wrapf(motor.heading - previous, -PI, PI))
		previous = motor.heading
	assert_float(rad_to_deg(turned)).is_greater(180.0)
	assert_float(motor.velocity.normalized().angle_to(direction)).is_less(deg_to_rad(25.0))
	assert_float(motor.speed()).is_greater(speed * 0.6)
	# It wears off and normal steering comes back.
	for i: int in 80:
		motor.step(input, 1.0 / 60.0)
	assert_bool(motor.spinning()).is_false()
	previous = motor.heading
	input.steer = 1.0
	motor.step(input, 1.0 / 60.0)
	assert_float(wrapf(motor.heading - previous, -PI, PI)).is_less(0.0)


func test_a_dropped_stain_catches_any_kart_including_the_one_that_left_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var dropper := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	dropper.global_position = Vector3(-6.0, 0.0, -9.375)
	dropper.face(Vector3(1.0, 0.0, 0.0))
	ITEM.activate(dropper)
	var stains := match_node.get_tree().get_nodes_in_group(&"oil_stains")
	assert_int(stains.size()).is_equal(1)
	var stain: OilStain = stains[0]
	assert_float(stain.global_position.x).is_less(dropper.global_position.x - 1.0)
	dropper.global_position = match_node.arena.spawn_points[0]
	victim.global_position = stain.global_position + Vector3(0.0, 0.0, 3.0)
	victim.face(Vector3(0.0, 0.0, -1.0))
	victim.motor.velocity = Vector3(0.0, 0.0, -6.0)
	var events := monitor_signals(Events, false)
	await _runner.simulate_frames(20, 17)
	assert_bool(victim.motor.spinning()).is_true()
	assert_bool(victim.alive).is_true()
	await assert_signal(events).is_emitted("oil_hit", [1])
	# It stays put and catches the kart that dropped it too.
	assert_bool(is_instance_valid(stain)).is_true()
	dropper.global_position = stain.global_position
	dropper.motor.velocity = Vector3(5.0, 0.0, 0.0)
	await _runner.simulate_frames(6, 17)
	assert_bool(dropper.motor.spinning()).is_true()


func test_stains_reach_puppets_and_vanish_with_the_host_copy() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.global_position = Vector3(4.0, 0.0, 6.0)
	ITEM.activate(kart)
	var stain: OilStain = match_node.get_tree().get_nodes_in_group(&"oil_stains")[0]
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = match_node.rules
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(match_node.build_snapshot())
	assert_int(client.puppet_stains.size()).is_equal(1)
	var copy: OilStain = client.puppet_stains.values()[0]
	assert_bool(copy.puppet).is_true()
	assert_vector(copy.global_position).is_equal_approx(stain.global_position, Vector3.ONE * 0.01)
	stain.queue_free()
	await _runner.simulate_frames(2, 17)
	client.apply_snapshot(match_node.build_snapshot())
	assert_int(client.puppet_stains.size()).is_equal(0)


## GAME.md 7.1: the floor of this arena is not flat. A slick lying at floor level disappears
## inside whichever pad it was dropped on, and the Junction is exactly where somebody wants to
## drop one, so it rides above every one of them.
func test_a_stain_dropped_on_the_junction_is_still_visible() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var dropper := match_node.kart_of(0)
	dropper.global_position = match_node.arena.junction_position
	ITEM.activate(dropper)
	var stain: OilStain = match_node.get_tree().get_nodes_in_group(&"oil_stains")[0]
	stain.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(4, 17)
	# Clear of the Junction's own disc, of the Jackpot tiles with their trim, and of every pad.
	var lowest := INF
	for blob: Node in stain._visual.get_children():
		lowest = minf(lowest, (blob as Node3D).global_position.y)
	assert_float(lowest).is_greater(Arena.PAD_HEIGHT * 1.6)
	assert_float(OilStain.LIFT).is_greater(Arena.PAD_HEIGHT * 1.6)
	# And still on the floor rather than in the air: a kart drives over it, not under it.
	assert_float(OilStain.LIFT).is_less(0.2)
