extends GdUnitTestSuite
## What a bot makes of shots that do not fly off its nose and of somewhere to hide, GAME.md 9.1, see
## [BotTactics]: Backfire's shot out of the back, a shot off a wall at a kart round it, and cover
## from a kart with a line on it in a showdown.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const HUNTER: BotTrait = preload("res://data/ai/traits/hunter.tres")
## Far out past the arena, where nothing of the map is in the way of the walls a test builds.
const AWAY := Vector3(300.0, 0.0, 300.0)

var _runner: GdUnitSceneRunner


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


## A box of wall, on the layer walls are on, standing [param size] at [param at].
func _wall(match_node: Match, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	match_node.add_child(body)
	body.global_position = at
	return body


## The brain of the first kart, its aim held still and willing to shoot, as a hunter's.
func _brain(match_node: Match) -> BotBrain:
	var brain: BotBrain = match_node.kart_of(0).get_node("Brain")
	brain.bot_trait = HUNTER
	brain._willing_to_fire = true
	brain._aim_error = 0.0
	brain._aim_error_left = 99.0
	return brain


## Whether the bot fires within half a second at [param enemy] standing at [param at], the bot at
## the middle facing along x.
func _fires_at(brain: BotBrain, enemy: Kart, at: Vector3) -> bool:
	brain.kart.global_position = Vector3.ZERO
	brain.kart.face(Vector3(1.0, 0.0, 0.0))
	enemy.global_position = at
	enemy.protection_left = 0.0
	enemy.hurt_left = 0.0
	enemy.motor.velocity = Vector3.ZERO
	brain._aim_timer = 0.0
	# Who is about is looked at at the pace the bot thinks, which this has not given it.
	brain._look_around()
	for i: int in 30:
		brain._shoot(1.0 / 60.0)
	return brain.input.fire


## Holding Backfire, GAME.md 7.3, a bot brakes to shoot a kart behind it out of the back, and does
## not fire at one in front while the brake is held for something else, which would send the shot
## the other way. Without it, a kart behind is not shot at.
func test_backfire_shoots_out_of_the_back() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	for crate: Crate in match_node.arena.crates:
		crate.global_position = Vector3(0.0, 0.0, -400.0)
	var brain := _brain(match_node)
	var enemy := match_node.kart_of(1)
	brain.input.brake = 0.0
	assert_bool(_fires_at(brain, enemy, Vector3(-4.0, 0.0, 0.0))).is_false()
	brain.kart.jokers.add(load("res://data/jokers/backfire.tres"))
	brain.input.brake = 0.0
	assert_bool(_fires_at(brain, enemy, Vector3(-4.0, 0.0, 0.0))).is_true()
	assert_float(brain.input.brake).is_greater_equal(0.5)
	assert_float(brain.tactics.aim().dot(Vector3(-1.0, 0.0, 0.0))).is_greater(0.99)
	# In front, with the brake held for a stop: the cannon points back, and nothing is fired.
	brain.input.brake = 1.0
	assert_bool(_fires_at(brain, enemy, Vector3(4.0, 0.0, 0.0))).is_false()


## With bullets that bounce, a kart round a wall is shot off another wall, GAME.md 9.1: a way
## within the fan off the aim whose shot comes off the side wall onto the mark. None while the
## mark is in sight, which is shot straight, and none with bullets that do not bounce.
func test_a_kart_round_a_wall_is_shot_off_the_wall() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var brain := _brain(match_node)
	var kart := brain.kart
	kart.global_position = AWAY
	kart.face(AWAY + Vector3(1.0, 0.0, 0.0))
	# A post between the bot and the mark, and a long wall to one side of both.
	_wall(match_node, AWAY + Vector3(4.0, 0.5, 0.0), Vector3(1.0, 2.0, 2.0))
	_wall(match_node, AWAY + Vector3(4.0, 0.5, 2.5), Vector3(14.0, 2.0, 1.0))
	await _runner.simulate_frames(2, 17)
	var mark := AWAY + Vector3(8.0, 0.0, 0.0)
	brain.tactics.think_bank(mark, false)
	assert_vector(brain.tactics.bank_way).is_equal(Vector3.ZERO)
	kart.jokers.add(load("res://data/jokers/rubber_bumpers.tres"))
	assert_int(kart.cannon.current_stats().bounces).is_greater(0)
	brain.tactics.think_bank(mark, false)
	var way := brain.tactics.bank_way
	assert_vector(way).is_not_equal(Vector3.ZERO)
	# Toward the side wall, off the aim by no more than the fan.
	assert_float(way.z).is_greater(0.0)
	assert_float(absf(Vector3(1.0, 0.0, 0.0).angle_to(way))).is_less_equal(
		BotTactics.BANK_FAN + 0.01
	)
	brain.tactics.think_bank(mark, true)
	assert_vector(brain.tactics.bank_way).is_equal(Vector3.ZERO)


## Somewhere to hide is a place near the bot the threat cannot see any of a kart's width of, and
## no nearer the threat than the bot is, GAME.md 9.7a: behind a box between them.
func test_cover_is_a_place_the_threat_cannot_see() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	for crate: Crate in match_node.arena.crates:
		crate.global_position = Vector3(0.0, 0.0, -400.0)
	var brain := _brain(match_node)
	var nav := match_node.nav
	# Two open cells side by side somewhere in the room, the bot on one and a box on the next.
	var spot := Vector3.INF
	for x: int in range(2, nav.grid.width - 6):
		var cell := Vector2i(x, nav.grid.height / 2)
		var free := true
		for dx: int in 6:
			free = free and not nav.is_blocked(cell + Vector2i(dx, 0))
		if free:
			spot = nav.grid.cell_center(cell)
			break
	assert_vector(spot).is_not_equal(Vector3.INF)
	brain.kart.global_position = spot
	var threat_at := spot + Vector3(-7.0, 0.0, 0.0)
	_wall(match_node, spot + Vector3(1.6, 0.5, 0.0), Vector3(0.6, 2.0, 3.0))
	await _runner.simulate_frames(2, 17)
	var hide := brain.tactics._hiding_place(threat_at)
	assert_vector(hide).is_not_equal(Vector3.INF)
	assert_float(hide.distance_to(spot)).is_less_equal(BotTactics.COVER_RANGE)
	assert_float(hide.distance_to(threat_at)).is_greater_equal(spot.distance_to(threat_at) - 1.0)
	var eye := Vector3(threat_at.x, BotBrain.BULLET_HEIGHT, threat_at.z)
	(
		assert_bool(brain.tactics._hidden(eye, Vector3(hide.x, BotBrain.BULLET_HEIGHT, hide.z)))
		. is_true()
	)


## A bot only hides in a showdown, and only when it is the worse off: in an ordinary match, or
## whole and level with the other kart, it does not look for cover at all; and the goal it is
## then on is cover, ahead of everything but fleeing a kart about to ram it.
func test_a_bot_hides_only_in_a_showdown_when_worse_off() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var brain := _brain(match_node)
	var threat := match_node.kart_of(1)
	brain.kart.global_position = Vector3.ZERO
	threat.global_position = Vector3(6.0, 0.0, 0.0)
	assert_vector(brain.tactics.think_cover(threat)).is_equal(Vector3.INF)
	match_node.rules.map = ArenaMaps.SHOWDOWN
	assert_bool(brain.kart.is_wounded()).is_false()
	assert_vector(brain.tactics.think_cover(threat)).is_equal(Vector3.INF)
	assert_str(String(BotGoals.choose({"cover": Vector3.ONE}, HUNTER))).is_equal("cover")
	(
		assert_str(
			String(BotGoals.choose({"cover": Vector3.ONE, "boost_enemy_distance": 0.0}, HUNTER))
		)
		. is_equal("flee")
	)
