extends GdUnitTestSuite
## Power-ups from GAME.md 7.1 and 7.2 in a running match: pads, item boxes, Boost, Shield,
## Turret, Ricochet Cannon and Chip Magnet.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const TABLE: PowerUpTable = preload("res://data/powerups/first_set.tres")

var _runner: GdUnitSceneRunner


func _start_match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	match_node.start(inputs, 5)
	return match_node


func _item(id: String) -> PowerUp:
	return load("res://data/powerups/%s.tres" % id)


func test_table_picks_by_weight() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var counts: Dictionary[StringName, int] = {}
	for i: int in 400:
		var picked := TABLE.pick(rng)
		counts[picked.id] = counts.get(picked.id, 0) + 1
	assert_int(counts.size()).is_equal(7)
	assert_int(counts[&"boost"]).is_greater(counts[&"turret"])


func test_power_pads_spawn_item_boxes_that_a_kart_takes_and_reveals() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	assert_int(match_node.arena.power_pads.size()).is_equal(4)
	var pad := match_node.arena.power_pads[0]
	assert_object(pad.current).is_not_null()
	var kart := match_node.kart_of(0)
	await _runner.simulate_frames(12, 17)
	kart.global_position = pad.global_position
	await _runner.simulate_frames(10, 17)
	assert_object(kart.held_item).is_not_null()
	assert_object(pad.current).is_null()
	assert_float(kart.item_reveal_left).is_greater(0.0)
	var flights := match_node.get_tree().get_nodes_in_group(&"pickup_flights")
	assert_int(flights.size()).is_equal(1)
	assert_float((flights[0] as Node3D).global_position.distance_to(kart.global_position)).is_less(
		3.0
	)
	await _runner.simulate_frames(40, 17)
	assert_float(kart.item_reveal_left).is_equal(0.0)
	var other := match_node.arena.power_pads[1]
	kart.global_position = other.global_position
	await _runner.simulate_frames(10, 17)
	assert_object(other.current).is_not_null()


func test_boost_speeds_up_and_rams_then_wears_off() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	await _runner.simulate_frames(12, 17)
	var boost: BoostPowerUp = _item("boost").duplicate()
	boost.duration = 0.5
	boost.activate(kart)
	assert_bool(kart.ramming).is_true()
	assert_float(kart.motor.speed_bonus).is_equal(1.5)
	assert_float(kart.motor.max_speed()).is_equal_approx(kart.stats.top_speed * 1.5, 0.001)
	await _runner.simulate_frames(45, 17)
	assert_bool(kart.ramming).is_false()
	assert_float(kart.motor.speed_bonus).is_equal(1.0)


## GAME.md 4.1: a kart that can ram another kart to death goes through a crate too, and keeps
## the speed it arrived with rather than being stopped dead by a wooden box.
## GAME.md 8.3: everything a kart takes flows into it rather than blinking out, so it is plain
## who got it. The pickup hands over its own visual, so a chip flies as a chip.
func test_a_taken_pickup_flies_into_the_kart_that_took_it() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	await _runner.simulate_frames(12, 17)
	var chip := Chip.new()
	chip.value = 3
	match_node.arena.pickups.add_child(chip)
	chip.global_position = kart.global_position + Vector3(6.0, 0.0, 0.0)
	await _runner.simulate_frames(4, 17)
	var was := chip.visual_center()
	chip.collect(kart)
	var flights := match_node.get_tree().get_nodes_in_group(&"pickup_flights")
	assert_int(flights.size()).is_equal(1)
	var flight: PickupFlight = flights[0]
	# It leaves from where the chip was being drawn, not from the floor under it.
	assert_float(flight.global_position.distance_to(was)).is_less(0.2)
	assert_int(flight.get_child_count()).is_greater(0)
	# And arrives at the kart, shrunk to nothing, then goes.
	var closest := INF
	for i: int in 40:
		await _runner.simulate_frames(1, 17)
		if not is_instance_valid(flight):
			break
		closest = minf(closest, flight.global_position.distance_to(kart.global_position))
	assert_float(closest).is_less(1.0)
	assert_bool(is_instance_valid(flight)).is_false()


## GAME.md 7.1: a box dropped on a death wears the item it holds, branded on its faces, and a box
## from a pad a question mark; neither has anything hung over it. Taken, the brand goes into the
## kart with the rest of the box.
func test_a_box_wears_what_it_holds() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	await _runner.simulate_frames(12, 17)
	var dropped := ItemBox.new()
	dropped.fixed_item = _item("bomb")
	match_node.arena.pickups.add_child(dropped)
	dropped.global_position = kart.global_position + Vector3(6.0, 0.0, 0.0)
	var from_pad := ItemBox.new()
	from_pad.table = TABLE
	from_pad.rng = match_node.rng
	match_node.arena.pickups.add_child(from_pad)
	for box: ItemBox in [dropped, from_pad]:
		var visual := box._visual
		assert_array(visual.find_children("*", "Label3D", false, false)).is_empty()
		assert_array(visual.find_children("*", "Sprite3D", false, false)).is_empty()
		var render: SubViewport = visual.get_node("Drawn")
		var badge: ItemBox.Badge = render.get_child(0)
		assert_object(badge.item).is_same(box.fixed_item)
		# Five faces, one mesh, GAME.md 10.7.
		var brands := visual.find_children("Brand*", "MeshInstance3D", false, false)
		assert_int(brands.size()).is_equal(1)
		var ink: StandardMaterial3D = (brands[0] as MeshInstance3D).material_override
		assert_object(ink.albedo_texture).is_same(render.get_texture())
		var faces: Array = (brands[0] as MeshInstance3D).mesh.surface_get_arrays(0)
		assert_int((faces[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()).is_equal(20)
	await _runner.simulate_frames(4, 17)
	var visual := dropped._visual
	dropped.collect(kart)
	assert_str(kart.held_item.id).is_equal("bomb")
	assert_object(visual.get_node("Drawn").get_parent()).is_same(visual)
	assert_bool(visual.get_parent() is PickupFlight).is_true()


func test_a_kart_at_ramming_speed_goes_through_a_crate() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	await _runner.simulate_frames(12, 17)
	var crate: Crate = match_node.arena.crates[0]
	# Lined up a couple of meters short of the crate, pointed at it, flat out.
	var at := crate.global_position
	var approach := match_node.arena.junction_position - at
	approach.y = 0.0
	approach = approach.normalized()
	kart.global_position = at + approach * 2.2
	kart.face(-approach)
	kart.motor.forward_speed = kart.stats.top_speed
	kart.motor.velocity = kart.motor.forward_vector() * kart.stats.top_speed
	kart.input.throttle = 1.0
	# Without ramming speed the box stands and the kart is stopped by it.
	await _runner.simulate_frames(20, 17)
	assert_bool(crate.alive).is_true()
	# Boosting, the same run takes it out and the kart is still traveling.
	var boost: BoostPowerUp = _item("boost").duplicate()
	boost.duration = 3.0
	boost.activate(kart)
	assert_bool(kart.ram_kills()).is_true()
	kart.global_position = at + approach * 2.2
	kart.face(-approach)
	kart.motor.forward_speed = kart.motor.max_speed()
	kart.motor.velocity = kart.motor.forward_vector() * kart.motor.forward_speed
	for i: int in 30:
		await _runner.simulate_frames(1, 17)
		if not crate.alive:
			break
	assert_bool(crate.alive).is_false()
	assert_float(kart.motor.speed()).is_greater(kart.stats.top_speed * 0.5)


func test_shield_absorbs_one_bullet_then_the_next_kills() -> void:
	var shooter_input := KartInput.new()
	var inputs: Array[KartInput] = [shooter_input, KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	shooter.global_position = Vector3(6.0, 0.0, 8.0)
	shooter.face(Vector3(-1.0, 0.0, 0.0))
	victim.global_position = Vector3(1.0, 0.0, 8.0)
	victim.face(Vector3(-1.0, 0.0, 0.0))
	_item("shield").activate(victim)
	assert_bool(victim.shielded).is_true()
	shooter_input.fire = true
	await _runner.simulate_frames(20, 17)
	shooter_input.fire = false
	assert_bool(victim.alive).is_true()
	assert_bool(victim.shielded).is_false()
	assert_bool(victim.has_effect(&"shield")).is_false()
	shooter_input.fire = true
	await _runner.simulate_frames(40, 17)
	assert_bool(victim.alive).is_false()


func test_ricochet_cannon_overrides_the_next_shots_only() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	var ricochet: RicochetCannonPowerUp = _item("ricochet_cannon")
	ricochet.activate(kart)
	assert_int(kart.cannon.override_shots_left()).is_equal(8)
	assert_int(kart.cannon.current_stats().bounces).is_equal(1)
	var faster := kart.base_cannon_stats.bullet_speed * 1.25
	assert_float(kart.cannon.current_stats().bullet_speed).is_equal_approx(faster, 0.001)
	for i: int in 8:
		kart.cannon.cooldown_left = 0.0
		var shots := kart.cannon.fire(
			match_node.bullets, 0, Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Color.WHITE
		)
		assert_int(shots[0].bounces_left).is_equal(1)
		for bullet: Bullet in shots:
			bullet.destroy()
	assert_int(kart.cannon.override_shots_left()).is_equal(0)
	assert_int(kart.cannon.current_stats().bounces).is_equal(0)


## The Rocket loads the cannon with a bursting, two-hit shot, GAME.md 5.3, for its few shots only.
func test_rocket_arms_the_cannon_with_a_bursting_two_hit_shot() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	var rocket: RocketPowerUp = _item("rocket")
	rocket.activate(kart)
	assert_int(kart.cannon.override_shots_left()).is_equal(rocket.shots)
	var stats := kart.cannon.current_stats()
	assert_str(String(stats.kind)).is_equal("rocket")
	assert_int(stats.hits).is_equal(2)
	assert_float(stats.blast_radius).is_greater(0.0)
	kart.cannon.cooldown_left = 0.0
	var shots := kart.cannon.fire(
		match_node.bullets, 0, Vector3.ZERO, Vector3(1.0, 0.0, 0.0), Color.WHITE
	)
	assert_str(String(shots[0].kind)).is_equal("rocket")
	assert_int(shots[0].hits).is_equal(2)
	for bullet: Bullet in shots:
		bullet.destroy()


## A rocket's direct hit takes two lives at once, killing a kart at full life where a plain bullet,
## one life, would only wound it, GAME.md 5.3.
func test_two_lives_at_once_kill_where_a_plain_bullet_only_wounds() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var victim := match_node.kart_of(1)
	victim.hurt_left = 0.0
	victim.lives = 2
	var plain: Bullet = auto_free(Bullet.new())
	plain.owner_slot = 0
	victim.take_hit(plain)
	assert_bool(victim.alive).is_true()
	assert_int(victim.lives).is_equal(1)
	victim.lives = 2
	victim.hurt_left = 0.0
	var rocket: Bullet = auto_free(Bullet.new())
	rocket.owner_slot = 0
	rocket.hits = 2
	victim.take_hit(rocket)
	assert_bool(victim.alive).is_false()


## A rocket's blast catches a kart standing near where it lands, see [Blast].
func test_a_blast_catches_a_kart_nearby() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var victim := match_node.kart_of(1)
	victim.hurt_left = 0.0
	victim.lives = 1
	Blast.go(match_node, victim.global_position, 3.0, 0, -1, Color.WHITE)
	assert_bool(victim.alive).is_false()


## The Grenade loads a bouncing, fused, bursting shot that does not home, GAME.md 5.3.
func test_grenade_arms_a_bouncing_fused_bursting_shot() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	var grenade: GrenadePowerUp = _item("grenade")
	grenade.activate(kart)
	var stats := kart.cannon.current_stats()
	assert_str(String(stats.kind)).is_equal("grenade")
	assert_float(stats.blast_radius).is_greater(0.0)
	assert_bool(stats.explode_on_expire).is_true()
	assert_int(stats.bounces).is_greater(0)
	assert_bool(stats.aim_assist).is_false()


## The Railgun loads a fast, piercing bolt that does not home, GAME.md 5.3.
func test_railgun_arms_a_piercing_bolt() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	var railgun: RailgunPowerUp = _item("railgun")
	railgun.activate(kart)
	var stats := kart.cannon.current_stats()
	assert_str(String(stats.kind)).is_equal("railgun")
	assert_int(stats.pierce).is_greater(0)
	assert_bool(stats.aim_assist).is_false()
	kart.cannon.cooldown_left = 0.0
	var shots := kart.cannon.fire(
		match_node.bullets, 0, Vector3.ZERO, Vector3(1.0, 0.0, 0.0), Color.WHITE
	)
	assert_int(shots[0].pierce_left).is_equal(stats.pierce)
	for bullet: Bullet in shots:
		bullet.destroy()


## A piercing bolt runs through more than one kart, killing each, GAME.md 5.3.
func test_a_railgun_bolt_pierces_through_more_than_one() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var bolt: Bullet = auto_free(Bullet.new())
	bolt.owner_slot = 0
	bolt.pierce_left = 3
	for i: int in [1, 2]:
		var victim := match_node.kart_of(i)
		victim.hurt_left = 0.0
		victim.lives = 1
		var destroyed := bolt._resolve_hit(victim)
		assert_bool(destroyed).is_false()
		assert_bool(victim.alive).is_false()


## Chain Lightning loads a leaping shot, GAME.md 5.3.
func test_chain_lightning_arms_a_leaping_shot() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	var chain: ChainLightningPowerUp = _item("chain_lightning")
	chain.activate(kart)
	var stats := kart.cannon.current_stats()
	assert_str(String(stats.kind)).is_equal("lightning")
	assert_int(stats.chain).is_greater(0)
	kart.cannon.cooldown_left = 0.0
	var shots := kart.cannon.fire(
		match_node.bullets, 0, Vector3.ZERO, Vector3(1.0, 0.0, 0.0), Color.WHITE
	)
	assert_int(shots[0].chain_left).is_equal(stats.chain)
	for bullet: Bullet in shots:
		bullet.destroy()


## On a hit, chain lightning turns onto the next mark nearby, killing the first, GAME.md 5.3.
func test_chain_lightning_leaps_to_the_next_mark() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var first := match_node.kart_of(1)
	var second := match_node.kart_of(2)
	first.global_position = Vector3.ZERO
	second.global_position = Vector3(4.0, 0.0, 0.0)
	first.hurt_left = 0.0
	first.lives = 1
	var bolt: Bullet = auto_free(Bullet.new())
	match_node.bullets.add_child(bolt)
	bolt.owner_slot = 0
	bolt.chain_left = 2
	bolt.assist_range = 11.0
	bolt.velocity = Vector3(0.0, 0.0, 5.0)
	bolt.global_position = first.global_position
	var destroyed := bolt._resolve_hit(first)
	assert_bool(destroyed).is_false()
	assert_bool(first.alive).is_false()
	assert_float(bolt.velocity.normalized().x).is_greater(0.5)


func test_a_turret_kills_the_enemy_ahead_and_credits_its_owner() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var owner := match_node.kart_of(0)
	var enemy := match_node.kart_of(1)
	owner.global_position = Vector3(-4.5, 0.0, 1.0)
	owner.face(Vector3(0.0, 0.0, -1.0))
	enemy.global_position = Vector3(3.0, 0.0, 2.0)
	_item("turret").activate(owner)
	var turrets := get_tree().get_nodes_in_group(&"turrets")
	assert_int(turrets.size()).is_equal(1)
	var turret: Turret = turrets[0]
	assert_int(turret.owner_slot).is_equal(0)
	var kills: Array[Array] = []
	var heard := func(victim: int, killer: int, cause: StringName) -> void:
		kills.append([victim, killer, cause])
	Events.kart_killed.connect(heard)
	await _runner.simulate_frames(90, 17)
	Events.kart_killed.disconnect(heard)
	assert_int(match_node.slots[1].deaths).is_equal(1)
	assert_int(match_node.slots[0].kills).is_equal(1)
	# The owner's kill, and the turret's doing, which the kill feed says, GAME.md 8.3.
	assert_array(kills).is_equal([[1, 0, &"turret"]])
	assert_float(owner.pot.mult).is_equal(2.0)
	var stats: CannonStats = load("res://data/cannons/default.tres")
	var from := turret.global_position + Vector3(3.0, 0.0, 0.0)
	match_node.bullets.spawn(
		1, from, (turret.global_position - from).normalized(), stats, Color.WHITE
	)
	await _runner.simulate_frames(20, 17)
	assert_bool(is_instance_valid(turret) and turret.alive).is_false()


func test_coin_magnet_widens_the_pickup_radius_and_pulls_chips() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.global_position = Vector3(0.0, 0.0, 8.0)
	var chips := match_node.arena.spawn_chips(Vector3(0.0, 0.0, 8.0), 0, 0.0)
	var chip := Chip.new()
	chip.value = 1
	chip.position = Vector3(2.2, 0.0, 8.0)
	match_node.arena.pickups.add_child(chip)
	chips.append(chip)
	await _runner.simulate_frames(10, 17)
	assert_int(kart.pot.coins).is_equal(0)
	_item("coin_magnet").activate(kart)
	assert_float(kart._pickup_shape.radius).is_equal_approx(2.7, 0.001)
	await _runner.simulate_frames(40, 17)
	assert_int(kart.pot.coins).is_equal(1)


func test_a_bomb_arms_then_blows_up_under_a_kart_breaking_crates_and_credits_its_owner() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var owner := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	owner.global_position = Vector3(-4.0, 0.0, 3.0)
	owner.face(Vector3(1.0, 0.0, 0.0))
	var item: BombPowerUp = _item("bomb")
	item.activate(owner)
	var bombs := match_node.get_tree().get_nodes_in_group(&"bombs")
	assert_int(bombs.size()).is_equal(1)
	var bomb: Bomb = bombs[0]
	assert_float(bomb.global_position.x).is_less(owner.global_position.x - 1.0)
	var crate: Crate = match_node.arena.crates[0]
	bomb.global_position = crate.global_position + Vector3(1.5, 0.0, 0.0)
	owner.global_position = match_node.arena.spawn_points[0]
	victim.global_position = bomb.global_position + Vector3(0.2, 0.0, 0.0)
	await _runner.simulate_frames(3, 17)
	assert_bool(victim.alive).override_failure_message("blew up before arming").is_true()
	await _runner.simulate_frames(45, 17)
	assert_bool(victim.alive).is_false()
	assert_int(match_node.slots[0].kills).is_equal(1)
	assert_bool(owner.alive).is_true()
	assert_bool(crate.alive).is_false()
	assert_bool(is_instance_valid(bomb) and bomb.alive).is_false()
	assert_int(match_node.get_tree().get_nodes_in_group(&"explosions").size()).is_equal(1)


func test_a_bullet_sets_off_a_bomb() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var owner := match_node.kart_of(1)
	owner.global_position = Vector3(1.8, 0.0, -9.375)
	owner.face(Vector3(1.0, 0.0, 0.0))
	var item: BombPowerUp = _item("bomb")
	item.activate(owner)
	var bomb: Bomb = match_node.get_tree().get_nodes_in_group(&"bombs")[0]
	assert_vector(bomb.global_position).is_equal_approx(
		Vector3(0.0, 0.0, -9.375), Vector3.ONE * 0.05
	)
	owner.global_position = Vector3(-16.0, 0.0, 6.0)
	shooter.global_position = Vector3(-6.0, 0.0, -9.375)
	shooter.face(Vector3(1.0, 0.0, 0.0))
	shooter.cannon.stats.aim_assist = false
	shooter.cannon.cooldown_left = 0.0
	shooter.cannon.fire(
		match_node.bullets,
		0,
		shooter.global_position + Vector3(1.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		Color.WHITE
	)
	await _runner.simulate_frames(30, 17)
	assert_bool(is_instance_valid(bomb) and bomb.alive).is_false()
	assert_int(match_node.get_tree().get_nodes_in_group(&"explosions").size()).is_equal(1)
	assert_int(match_node.bullets.live_count()).is_equal(0)
