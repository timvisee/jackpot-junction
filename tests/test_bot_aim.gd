extends GdUnitTestSuite
## Where a bot aims, GAME.md 9.1: the shot led to where it meets a moving kart, the drive led only
## a little way ahead of a kart it hunts, and the Swivel Cannon pointed at its mark.

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


## The time worked out is the one at which the shot and the kart are in the same place.
func test_the_meeting_time_is_where_the_shot_and_the_kart_meet() -> void:
	var speed := 17.0
	for case: Array in [
		[Vector3(0.0, 0.0, -10.0), Vector3(10.0, 0.0, 0.0)],
		[Vector3(3.0, 0.0, -8.0), Vector3(-6.0, 0.0, 4.0)],
		[Vector3(0.0, 0.0, -6.0), Vector3(0.0, 0.0, -9.0)],
		[Vector3(0.0, 0.0, -12.0), Vector3(0.0, 0.0, 10.0)],
	]:
		var relative: Vector3 = case[0]
		var velocity: Vector3 = case[1]
		var t := BotBrain.intercept_time(relative, velocity, speed)
		assert_float(t).is_greater(0.0)
		assert_float((relative + velocity * t).length()).is_equal_approx(speed * t, 0.001)
	# Crossing at right angles ten meters off, the meeting is later than the distance over the
	# shot's speed, which is the guess the bots used to make.
	var crossing := BotBrain.intercept_time(
		Vector3(0.0, 0.0, -10.0), Vector3(10.0, 0.0, 0.0), speed
	)
	assert_float(crossing).is_greater(10.0 / speed + 0.1)
	# Something running away faster than a shot is never met: the shot is aimed where it is.
	var gone := BotBrain.intercept_time(Vector3(0.0, 0.0, -5.0), Vector3(0.0, 0.0, -20.0), speed)
	assert_float(gone).is_equal_approx(5.0 / speed, 0.001)


## GAME.md 9.1: a moving kart is led to where the shot meets it. Played out as the shot and the
## kart would fly, the shot passes through the kart, where the guess from the distance alone,
## the one the bots used to make, puts it well wide.
func test_a_bot_leads_a_moving_kart() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var enemy := match_node.kart_of(1)
	enemy.get_node("Brain").queue_free()
	await _runner.simulate_frames(1, 17)
	# Pulling away across the bot's bows, twelve meters off.
	kart.global_position = Vector3(0.0, 0.0, 8.0)
	kart.face(Vector3(0.0, 0.0, -1.0))
	enemy.global_position = Vector3(4.0, 0.0, -4.0)
	enemy.motor.velocity = Vector3(7.0, 0.0, -7.0)
	var stats := kart.cannon.current_stats()
	var muzzle := kart.global_position + kart.motor.forward_vector() * stats.muzzle_offset
	var way := (brain._lead_point(enemy) - muzzle).normalized()
	var miss := BotBrain.closest_approach(
		enemy.global_position - muzzle, enemy.motor.velocity - way * stats.bullet_speed, 2.0
	)
	assert_float(miss).is_less(0.2)
	var distance := kart.global_position.distance_to(enemy.global_position)
	var guess := enemy.global_position + enemy.motor.velocity * (distance / stats.bullet_speed)
	var guessed := (guess - muzzle).normalized()
	var wide := BotBrain.closest_approach(
		enemy.global_position - muzzle, enemy.motor.velocity - guessed * stats.bullet_speed, 2.0
	)
	assert_float(wide).is_greater(1.5)
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
