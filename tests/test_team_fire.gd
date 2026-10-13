extends GdUnitTestSuite
## Friendly fire and who is an enemy in team play, GAME.md 3.14: with it off a teammate's shots,
## blasts and rams do a kart no harm, and with it on a team kill is credited to nobody. Either way
## nothing that looks for an enemy finds a teammate.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const LANE := Vector3(0.0, 0.0, -9.375)
## Out of the lane's way, for the karts a test does not need there.
const AWAY: Array[Vector3] = [
	Vector3(-10.0, 0.0, 8.0),
	Vector3(10.0, 0.0, 8.0),
	Vector3(-4.0, 0.0, 8.0),
	Vector3(4.0, 0.0, 8.0)
]

var _runner: GdUnitSceneRunner
var _met := 0


## Four karts, Hearts in seats 0 and 2 and Spades in 1 and 3, each parked out of the lane.
func _start(friendly_fire := false) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.teams = 2
	rules.friendly_fire = friendly_fire
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in 4:
		inputs.append(KartInput.new())
	match_node.start(inputs, 11)
	await _runner.simulate_frames(12, 17)
	for i: int in 4:
		_park(match_node.kart_of(i), AWAY[i])
	return match_node


func _park(kart: Kart, at: Vector3) -> void:
	kart.global_position = at
	kart.motor.velocity = Vector3.ZERO


## A shot of [param slot]'s from [param from] along [param direction], as its kart fires one: on its
## team, and going through its teammates unless friendly fire is on. No aim assist.
func _shot(
	match_node: Match, slot: int, from: Vector3, direction := Vector3(1.0, 0.0, 0.0)
) -> Bullet:
	var kart := match_node.kart_of(slot)
	var stats: CannonStats = kart.cannon.stats.duplicate()
	stats.aim_assist = false
	var bullet := match_node.bullets.spawn(slot, from, direction, stats, Color.WHITE)
	bullet.owner_team = kart.team
	bullet.spares_team = not match_node.rules.friendly_fire
	return bullet


func _count_met(_a: int, _b: int) -> void:
	_met += 1


func test_the_seats_alternate_teams() -> void:
	var match_node: Match = await _start()
	var teams: Array[int] = []
	for slot: PlayerSlot in match_node.slots:
		teams.append(slot.team)
	assert_array(teams).is_equal([0, 1, 0, 1])


## Off, a teammate's shot goes through a kart, its shield and its turret as though nothing were
## there, and on to whoever is behind them.
func test_a_teammates_shot_goes_through_to_the_enemy_behind() -> void:
	var match_node: Match = await _start()
	var mate := match_node.kart_of(2)
	var enemy := match_node.kart_of(1)
	_park(mate, LANE)
	_park(enemy, LANE + Vector3(4.0, 0.0, 0.0))
	_shot(match_node, 0, LANE + Vector3(-2.0, 0.0, 0.0))
	await _runner.simulate_frames(30, 17)
	assert_int(mate.lives).is_equal(match_node.rules.lives)
	assert_int(enemy.lives).is_equal(match_node.rules.lives - 1)
	mate.set_shielded(true)
	_shot(match_node, 0, LANE + Vector3(-2.0, 0.0, 0.0))
	await _runner.simulate_frames(12, 17)
	assert_bool(mate.shielded).is_true()
	var turret := Turret.new()
	turret.owner_slot = 2
	turret.team = mate.team
	turret.spares_team = true
	match_node.add_child(turret)
	turret.global_position = LANE + Vector3(1.0, 0.0, 0.0)
	_shot(match_node, 0, LANE + Vector3(-2.0, 0.0, 0.0))
	await _runner.simulate_frames(12, 17)
	assert_bool(turret.alive).is_true()


## A kart's own controls fire shots on its team.
func test_a_kart_fires_on_its_team() -> void:
	var match_node: Match = await _start()
	var kart := match_node.kart_of(1)
	kart.input.fire = true
	await _runner.simulate_frames(4, 17)
	kart.input.fire = false
	assert_int(match_node.bullets.live_count()).is_greater(0)
	for bullet: Bullet in match_node.bullets.bullets:
		assert_int(bullet.owner_team).is_equal(1)
		assert_bool(bullet.spares_team).is_true()


## Teammates' shots pass each other in the air; the other team's are shot down.
func test_teammates_shots_pass_each_other() -> void:
	var match_node: Match = await _start()
	_met = 0
	Events.bullets_met.connect(_count_met)
	_shot(match_node, 0, LANE + Vector3(-3.0, 0.0, 0.0))
	_shot(match_node, 2, LANE + Vector3(3.0, 0.0, 0.0), Vector3(-1.0, 0.0, 0.0))
	await _runner.simulate_frames(20, 17)
	assert_int(_met).is_equal(0)
	_shot(match_node, 0, LANE + Vector3(-3.0, 0.0, 0.0))
	_shot(match_node, 1, LANE + Vector3(3.0, 0.0, 0.0), Vector3(-1.0, 0.0, 0.0))
	await _runner.simulate_frames(20, 17)
	Events.bullets_met.disconnect(_count_met)
	assert_int(_met).is_equal(1)


## On, a teammate's shot hurts as anybody's does, and a teammate taken out is credited to nobody:
## no kill, no mult, and an own goal on the results.
func test_with_friendly_fire_a_team_kill_is_nobodys() -> void:
	var match_node: Match = await _start(true)
	var mate := match_node.kart_of(2)
	_park(mate, LANE)
	mate.lives = 1
	_shot(match_node, 0, LANE + Vector3(-2.0, 0.0, 0.0))
	await _runner.simulate_frames(20, 17)
	assert_bool(mate.alive).is_false()
	var shooter := match_node.slots[0]
	assert_int(shooter.kills).is_equal(0)
	assert_float(shooter.kart.pot.mult).is_equal(1.0)
	assert_float(shooter.stats.value(&"self_kills")).is_equal(1.0)
	assert_int(match_node.slots[2].deaths).is_equal(1)


## A teammate's bump into a pit credits nobody, and is no own goal either.
func test_a_teammates_bump_into_a_pit_credits_nobody() -> void:
	var match_node: Match = await _start(true)
	var mate := match_node.kart_of(2)
	mate.last_bump_slot = 0
	mate.last_bump_time = Time.get_ticks_msec() * 0.001
	mate.die(&"pit", 0)
	assert_int(match_node.slots[0].kills).is_equal(0)
	assert_float(match_node.slots[0].stats.value(&"self_kills")).is_equal(0.0)


## A teammate's shot going by is no graze, whatever friendly fire says.
func test_a_teammates_shot_gives_no_graze() -> void:
	var match_node: Match = await _start(true)
	var mate := match_node.kart_of(2)
	_park(mate, LANE + Vector3(0.0, 0.0, 1.0))
	_shot(match_node, 0, LANE + Vector3(-3.0, 0.0, 0.0))
	await _runner.simulate_frames(30, 17)
	assert_float(mate.pot.mult).is_equal(1.0)
	var enemy := match_node.kart_of(1)
	_park(mate, AWAY[2])
	_park(enemy, LANE + Vector3(0.0, 0.0, 1.0))
	_shot(match_node, 0, LANE + Vector3(-3.0, 0.0, 0.0))
	await _runner.simulate_frames(30, 17)
	assert_float(enemy.pot.mult).is_greater(1.0)


## The aim, Aimbot's included, passes over a teammate for the enemy behind them; a turret turns
## on the other team only.
func test_nothing_aims_at_a_teammate() -> void:
	var match_node: Match = await _start()
	var mate := match_node.kart_of(2)
	var enemy := match_node.kart_of(1)
	_park(mate, LANE + Vector3(2.0, 0.0, 0.0))
	_park(enemy, LANE + Vector3(6.0, 0.0, 0.0))
	var from := LANE + Vector3(-1.0, 0.0, 0.0)
	var aimed := Bullet.nearest_target(
		match_node.get_tree(), from, 0, 20.0, Vector3(1.0, 0.0, 0.0), 0.5, null, 0
	)
	assert_object(aimed).is_same(enemy)
	var turret := Turret.new()
	turret.owner_slot = 0
	turret.team = 0
	match_node.add_child(turret)
	turret.global_position = from
	assert_object(turret._nearest_enemy()).is_same(enemy)
	# With only the teammate in reach, nobody.
	turret.reach = 4.0
	assert_object(turret._nearest_enemy()).is_null()


## Off, a teammate neither sets a bomb off nor is hurt by its blast, while the other team is.
func test_a_teammates_bomb_spares_the_team() -> void:
	var match_node: Match = await _start()
	var mate := match_node.kart_of(2)
	var enemy := match_node.kart_of(1)
	var bomb := Bomb.new()
	bomb.owner_slot = 0
	bomb.team = 0
	match_node.add_child(bomb)
	bomb.global_position = LANE
	_park(mate, LANE)
	await _runner.simulate_frames(50, 17)
	assert_bool(bomb.alive).is_true()
	# Still inside the blast, but off the bomb, which the other team drives onto.
	_park(mate, LANE + Vector3(-1.5, 0.0, 0.0))
	_park(enemy, LANE)
	await _runner.simulate_frames(10, 17)
	assert_bool(is_instance_valid(bomb)).is_false()
	assert_int(mate.lives).is_equal(match_node.rules.lives)
	assert_int(enemy.lives).is_equal(match_node.rules.lives - 1)


## Off, a teammate's ram is a bump: no life taken and nothing knocked loose.
func test_a_teammates_ram_is_a_bump() -> void:
	var match_node: Match = await _start()
	var rammer := match_node.kart_of(0)
	var mate := match_node.kart_of(2)
	mate.pot.add_coins(20)
	rammer.ramming = true
	KartCollisions._bump(rammer, mate, Vector3(1.0, 0.0, 0.0), Vector3(-8.0, 0.0, 0.0))
	assert_int(mate.lives).is_equal(match_node.rules.lives)
	assert_int(mate.pot.coins).is_equal(20)
	var enemy := match_node.kart_of(1)
	KartCollisions._bump(rammer, enemy, Vector3(1.0, 0.0, 0.0), Vector3(-8.0, 0.0, 0.0))
	assert_int(enemy.lives).is_equal(match_node.rules.lives - 1)


## Bullet Wipe takes only what could hurt its user, so not a teammate's shots with it off.
func test_bullet_wipe_leaves_a_teammates_shots() -> void:
	var match_node: Match = await _start()
	var kart := match_node.kart_of(0)
	_park(kart, LANE)
	var mate := _shot(match_node, 2, LANE + Vector3(-3.0, 0.0, 0.0))
	var enemy := _shot(match_node, 1, LANE + Vector3(3.0, 0.0, 0.0), Vector3(-1.0, 0.0, 0.0))
	BulletWipePowerUp.new().activate(kart)
	assert_bool(mate.is_dead()).is_false()
	assert_bool(enemy.is_dead()).is_true()


## A kart comes back far from the other team, whoever of its own team is near.
func test_a_respawn_keeps_away_from_the_other_team_only() -> void:
	var match_node: Match = await _start()
	var points := match_node.arena.spawns_for(match_node.slots.size())
	var enemy := match_node.kart_of(1)
	var mate := match_node.kart_of(2)
	_park(match_node.kart_of(3), points[0])
	_park(enemy, points[0])
	var far := Match.pick_spawn(points, [points[0]])
	_park(mate, far)
	var slot := match_node.slots[0]
	slot.kart.die(&"test", -1)
	match_node._respawn(slot)
	assert_vector(slot.kart.global_position).is_equal_approx(
		Vector3(far.x, 0.0, far.z), Vector3(0.01, 0.01, 0.01)
	)
