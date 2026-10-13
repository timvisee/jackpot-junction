extends GdUnitTestSuite
## GAME.md 5.1: a shot fired with the muzzle inside a crate or wall, because the shooter is
## pressed against it, stops there. The crate breaks; the wall just eats the bullet.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match(input: KartInput) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.spawn_protection = 0.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [input, KartInput.new()]
	match_node.start(inputs, 13)
	return match_node


func test_a_kart_pressed_against_a_crate_breaks_it_instead_of_shooting_through() -> void:
	var input := KartInput.new()
	var match_node := _start_match(input)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var crate: Crate = match_node.arena.crates[0]
	# The crate is 1 m wide; the muzzle, 1 m ahead of the center, ends up inside it.
	kart.global_position = crate.global_position + Vector3(-1.32, 0.0, 0.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	assert_bool(crate.alive).is_true()
	input.fire = true
	await _runner.simulate_frames(4, 17)
	input.fire = false
	assert_bool(crate.alive).is_false()
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.bullets.live_count()).is_equal(0)


func test_a_kart_pressed_against_a_wall_loses_the_bullet_without_a_bounce() -> void:
	var input := KartInput.new()
	var match_node := _start_match(input)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	# The west wall's inner face is at x = -18.75; the muzzle ends up inside the wall.
	kart.global_position = Vector3(-17.93, 0.0, 0.0)
	kart.face(Vector3(-1.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	var bounces := monitor_signals(Events, false)
	input.fire = true
	await _runner.simulate_frames(4, 17)
	input.fire = false
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.bullets.live_count()).is_equal(0)
	await assert_signal(bounces).wait_until(50).is_not_emitted("bullet_bounced")


func test_a_clear_muzzle_fires_normally() -> void:
	var input := KartInput.new()
	var match_node := _start_match(input)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.global_position = Vector3(0.0, 0.0, -9.375)
	kart.face(Vector3(1.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	input.fire = true
	await _runner.simulate_frames(3, 17)
	input.fire = false
	assert_int(match_node.bullets.live_count()).is_equal(1)


## GAME.md 5.1: the limit on bullets in the air refuses a shot past it, the bullets up left as they
## are; a player at this machine pulling the trigger against it hears a dry click, once a cooldown
## for as long as it is held, and a bot says nothing.
func test_a_shot_past_the_limit_is_refused_and_says_so() -> void:
	var input := KartInput.new()
	var match_node := _start_match(input)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.input = PlayerInput.new(DeviceInput.ANY, 0)
	var cap := kart.cannon.current_stats().max_live_bullets
	var fired: Array[Bullet] = []
	for i: int in cap:
		kart.cannon.cooldown_left = 0.0
		assert_bool(kart.cannon.can_fire()).is_true()
		var shot := kart.cannon.fire(
			match_node.bullets,
			kart.slot,
			kart.global_position + Vector3(0.0, 0.5, 0.0),
			Vector3.FORWARD,
			Color.WHITE
		)
		fired.append_array(shot)
	kart.cannon.cooldown_left = 0.0
	assert_bool(kart.cannon.can_fire()).is_false()
	assert_bool(kart.cannon.is_full()).is_true()
	var heard: Array[int] = []
	var note := func(slot: int) -> void: heard.append(slot)
	Events.cannon_jammed.connect(note)
	assert_bool(CannonJam.has_shot(kart)).is_false()
	assert_bool(CannonJam.has_shot(kart)).is_false()
	assert_array(heard).is_equal([kart.slot] as Array[int])
	assert_int(kart.cannon.live_count()).is_equal(cap)
	for bullet: Bullet in fired:
		assert_bool(bullet.is_dead()).is_false()
	# A bot holding its trigger against it says nothing.
	kart.input = KartInput.new()
	kart.cannon.step(1.0)
	kart.cannon.cooldown_left = 0.0
	CannonJam.has_shot(kart)
	Events.cannon_jammed.disconnect(note)
	assert_int(heard.size()).is_equal(1)
