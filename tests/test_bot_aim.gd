extends GdUnitTestSuite
## Where a bot aims, GAME.md 9.1: the shot led by the kart's travel while it flies, and the drive
## led only a little way ahead of a kart it hunts.

const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


## A running match of two bots, the second one's brain taken away so it stays where it is put.
func _match() -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [BotInput.new(), BotInput.new()]
	match_node.start(inputs, 9)
	return match_node


## GAME.md 9.1: a kart on the move is led by as far as it travels while the shot flies to it, and
## no further: the shot's own aim assist bends it toward where the kart is, see GAME.md 5.2, so a
## shot led all the way to where the two would meet is bent back off it.
func test_a_bot_leads_a_moving_kart_by_the_shots_flight() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var enemy := match_node.kart_of(1)
	enemy.get_node("Brain").queue_free()
	await _runner.simulate_frames(1, 17)
	kart.global_position = Vector3(0.0, 0.0, 8.0)
	enemy.global_position = Vector3(4.0, 0.0, -4.0)
	enemy.motor.velocity = Vector3(7.0, 0.0, -7.0)
	var speed := kart.cannon.current_stats().bullet_speed
	var flight := kart.global_position.distance_to(enemy.global_position) / speed
	var lead := brain._lead_point(enemy)
	assert_vector(lead).is_equal_approx(
		enemy.global_position + enemy.motor.velocity * flight, Vector3.ONE * 0.01
	)
	# Standing still, a kart is aimed at where it is.
	enemy.motor.velocity = Vector3.ZERO
	assert_vector(brain._lead_point(enemy)).is_equal_approx(
		enemy.global_position, Vector3.ONE * 0.01
	)


## A bot drives at where a kart it is hunting is about to be, not at where its shot would meet a
## kart running away, which is across the room: half a second of the kart's travel at most.
func test_a_bot_steers_only_a_little_ahead_of_a_kart_it_hunts() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var enemy := match_node.kart_of(1)
	enemy.get_node("Brain").queue_free()
	await _runner.simulate_frames(1, 17)
	kart.global_position = Vector3(-8.0, 0.0, 0.0)
	enemy.global_position = Vector3(0.0, 0.0, 0.0)
	enemy.motor.velocity = Vector3(10.0, 0.0, 0.0)
	brain.goal = &"hunt"
	brain.target_node = enemy
	brain._steer(1.0 / 60.0)
	var ahead := brain.target.distance_to(enemy.global_position)
	assert_float(ahead).is_less_equal(10.0 * BotBrain.STEER_LEAD + 0.01)
	assert_float(ahead).is_greater(0.0)


## GAME.md 7.1: with the Swivel Cannon a bot aims the cannon at its mark, as a player does with
## the stick, rather than firing it down its nose: a kart off to the side is shot where it is.
func test_a_bot_aims_the_swivel_cannon_at_its_mark() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	for crate: Crate in match_node.arena.crates:
		crate.global_position = Vector3(0.0, 0.0, -400.0)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var enemy := match_node.kart_of(1)
	enemy.get_node("Brain").queue_free()
	await _runner.simulate_frames(1, 17)
	brain.bot_trait = load("res://data/ai/traits/hunter.tres")
	brain._willing_to_fire = true
	brain._aim_error = 0.0
	brain._aim_error_left = 99.0
	kart.global_position = Vector3(-6.0, 0.0, 0.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	# Sixty degrees off the nose and seven meters away: no shot down the nose goes near it.
	enemy.global_position = kart.global_position + Vector3(3.5, 0.0, 6.06)
	enemy.protection_left = 0.0
	enemy.hurt_left = 0.0
	enemy.motor.velocity = Vector3.ZERO
	brain._look_around()
	assert_bool(_fires(brain)).is_false()
	var swivel: CannonStats = kart.cannon_stats.duplicate()
	swivel.free_aim = true
	swivel.aim_assist = false
	kart.cannon.set_override(swivel, 1 << 20)
	assert_bool(_fires(brain)).is_true()
	var toward := (enemy.global_position - kart.global_position).normalized()
	assert_float(KartAim.direction(kart).dot(toward)).is_greater(0.99)
	kart.cannon.clear_override()


## Whether the brain pulls the trigger within half a second of shooting thoughts, standing still.
func _fires(brain: BotBrain) -> bool:
	brain._aim_timer = 0.0
	for i: int in 30:
		brain._shoot(1.0 / 60.0)
	return brain.input.fire
