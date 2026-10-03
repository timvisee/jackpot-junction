extends GdUnitTestSuite
## Two lives, GAME.md 3.6 and 5.4: the first hit wounds, the Junction heals, the second hit
## kills, pits kill outright, and a wounded kart is slower and darker.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const LANE := Vector3(0.0, 0.0, -9.375)

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 11)
	return match_node


## Fires one unassisted bullet from 5 m left of [param at] along +X and lets it arrive.
func _shoot(match_node: Match, shooter: Kart, at: Vector3) -> void:
	shooter.global_position = at + Vector3(-5.0, 0.0, 0.0)
	shooter.face(Vector3(1.0, 0.0, 0.0))
	shooter.cannon.stats.aim_assist = false
	shooter.cannon.cooldown_left = 0.0
	shooter.cannon.fire(
		match_node.bullets,
		shooter.slot,
		shooter.global_position + Vector3(1.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		Color.WHITE
	)
	await _runner.simulate_frames(30, 17)


## One bullet from [param slot], 2 m to the left of the lane and heading along it.
func _shot(match_node: Match, slot: int) -> Bullet:
	return match_node.bullets.spawn(
		slot,
		LANE + Vector3(-2.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		match_node.kart_of(0).cannon.stats,
		Color.WHITE
	)


## Waits out the moment of immunity a wound grants, so the next shot actually lands.
func _wait_out_immunity(kart: Kart) -> void:
	for i: int in 20:
		if kart.hurt_left <= 0.0:
			return
		await _runner.simulate_frames(10, 17)


func test_the_first_hit_wounds_the_junction_heals_and_the_second_hit_kills() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	var color := Palette.player_color(victim.color_index)
	victim.global_position = LANE
	victim.face(Vector3(1.0, 0.0, 0.0))
	var base_speed := victim.stats.top_speed
	assert_int(victim.lives).is_equal(2)
	var events := monitor_signals(Events, false)
	await _shoot(match_node, shooter, LANE)
	assert_bool(victim.alive).is_true()
	assert_int(victim.lives).is_equal(1)
	assert_bool(victim.is_wounded()).is_true()
	assert_float(victim.stats.top_speed).is_equal_approx(base_speed * 0.85, 0.001)
	assert_float(victim._tint.albedo_color.v).is_less(color.v - 0.1)
	await assert_signal(events).is_emitted("kart_wounded", [1, 0, &"bullet"])
	# GAME.md 3.4: a pot goes in before the life comes back, so arriving loaded is not enough.
	victim.pot.add_coins(20)
	victim.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(3, 17)
	assert_int(victim.lives).is_equal(1)
	# The life comes with the last coin of the cash-out.
	await _runner.simulate_frames(60, 17)
	assert_bool(victim.pot.is_empty()).is_true()
	assert_int(victim.lives).is_equal(2)
	assert_float(victim.stats.top_speed).is_equal_approx(base_speed, 0.001)
	assert_object(victim._tint.albedo_color).is_equal(color)
	await assert_signal(events).is_emitted("life_restored", [1])
	await _wait_out_immunity(victim)
	victim.global_position = LANE
	victim.face(Vector3(1.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	await _shoot(match_node, shooter, LANE)
	assert_int(victim.lives).is_equal(1)
	await _wait_out_immunity(victim)
	victim.global_position = LANE
	await _shoot(match_node, shooter, LANE)
	assert_bool(victim.alive).is_false()
	assert_int(match_node.slots[0].kills).is_equal(1)
	assert_int(match_node.slots[1].deaths).is_equal(1)
	await _runner.simulate_frames(200, 17)
	assert_bool(victim.alive).is_true()
	assert_int(victim.lives).is_equal(2)
	assert_float(victim.stats.top_speed).is_equal_approx(base_speed, 0.001)


## GAME.md 5.1: a kart's own shot is spent on it but does no harm, unless the lobby says
## otherwise. Its turret and its decoy fire its bullets, so they are covered by the same answer.
func test_your_own_bullets_drop_on_you_without_hurting_you() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	assert_bool(match_node.rules.own_bullets_hurt).is_false()
	var kart := match_node.kart_of(0)
	kart.global_position = LANE
	kart.cannon.stats.aim_assist = false
	# Spent on the kart it came from, rather than carrying on through it.
	var own := _shot(match_node, kart.slot)
	assert_bool(kart.take_hit(own)).is_true()
	assert_int(kart.lives).is_equal(match_node.rules.lives)
	own.destroy()
	# One arriving under its own steam drops on the kart and is gone.
	_shot(match_node, kart.slot)
	await _runner.simulate_frames(12, 17)
	assert_int(match_node.bullets.live_count()).is_equal(0)
	assert_int(kart.lives).is_equal(match_node.rules.lives)
	assert_bool(kart.alive).is_true()
	# It does not cost a shield either.
	kart.set_shielded(true)
	var shielded := _shot(match_node, kart.slot)
	assert_bool(kart.take_hit(shielded)).is_true()
	assert_bool(kart.shielded).is_true()
	kart.set_shielded(false)
	shielded.destroy()
	# Somebody else's bullet still lands, and so does your own once the rules allow it.
	var theirs := _shot(match_node, 1)
	assert_bool(kart.take_hit(theirs)).is_true()
	assert_int(kart.lives).is_equal(match_node.rules.lives - 1)
	theirs.destroy()
	await _wait_out_immunity(kart)
	match_node.rules.own_bullets_hurt = true
	var mine := _shot(match_node, kart.slot)
	assert_bool(kart.take_hit(mine)).is_true()
	assert_bool(kart.alive).is_false()
	mine.destroy()


## GAME.md 3.6: a kill patches the killer up, so a wounded kart can fight its way back instead
## of having to break off for the Junction.
## GAME.md 3.4: with nothing to bank there is nothing to wait for, so the pad patches a wounded
## kart up the moment it rolls on.
func test_an_empty_pot_is_patched_up_on_arrival() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	victim.global_position = LANE
	victim.face(Vector3(1.0, 0.0, 0.0))
	await _shoot(match_node, shooter, LANE)
	assert_bool(victim.is_wounded()).is_true()
	victim.pot.reset()
	victim.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(6, 17)
	assert_int(victim.lives).is_equal(2)
	assert_bool(victim.is_wounded()).is_false()


## GAME.md 3.4: the pad has one life to give every few seconds. Without the wait a kart parked
## on the Junction is patched up the instant it is wounded, and the one place everybody has to
## come to is the one place nobody can be finished off.
func test_the_junction_waits_before_it_patches_the_same_kart_up_again() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var victim := match_node.kart_of(1)
	victim.global_position = match_node.arena.junction_position
	victim.pot.reset()
	await _runner.simulate_frames(4, 17)
	victim.take_blast(0)
	assert_int(victim.lives).is_equal(1)
	await _runner.simulate_frames(6, 17)
	assert_int(victim.lives).is_equal(2)
	# The second wound stands: the pad has nothing left to give yet.
	victim.hurt_left = 0.0
	victim.take_blast(0)
	assert_int(victim.lives).is_equal(1)
	await _runner.simulate_frames(60, 17)
	assert_int(victim.lives).is_equal(1)
	# A little over three seconds after the first patch-up, there is another one to have.
	await _runner.simulate_frames(150, 17)
	assert_int(victim.lives).is_equal(2)


func test_a_kill_gives_the_killer_a_life_back() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	# Wound the shooter first, so it has something to win back.
	shooter.global_position = LANE
	await _shoot(match_node, victim, LANE)
	assert_int(shooter.lives).is_equal(1)
	assert_bool(shooter.is_wounded()).is_true()
	await _wait_out_immunity(shooter)
	var events := monitor_signals(Events, false)
	# Now take the other kart out twice over, which is what its two lives cost.
	for i: int in 2:
		victim.global_position = LANE
		shooter.global_position = LANE + Vector3(-5.0, 0.0, 0.0)
		await _shoot(match_node, shooter, LANE)
		await _wait_out_immunity(victim)
	assert_bool(victim.alive).is_false()
	assert_int(match_node.slots[0].kills).is_equal(1)
	assert_int(shooter.lives).is_equal(match_node.rules.lives)
	assert_bool(shooter.is_wounded()).is_false()
	await assert_signal(events).is_emitted("life_restored", [0])


## Nobody gets a life back for driving into a hole by themselves.
func test_a_death_with_nobody_to_credit_patches_nobody_up() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	shooter.global_position = LANE
	await _shoot(match_node, victim, LANE)
	assert_int(shooter.lives).is_equal(1)
	await _wait_out_immunity(shooter)
	victim.global_position = match_node.arena.pits[0].global_position
	await _runner.simulate_frames(45, 17)
	assert_bool(victim.alive).is_false()
	assert_int(shooter.lives).is_equal(1)


func test_a_fresh_wound_cannot_be_hit_again_for_a_moment() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	victim.global_position = LANE
	await _shoot(match_node, shooter, LANE)
	assert_int(victim.lives).is_equal(1)
	# Straight after the wound the kart is untouchable for a moment and blinks.
	assert_float(victim.hurt_left).is_greater(0.5)
	assert_bool(victim.is_targetable()).is_false()
	var bullet := match_node.bullets.spawn(
		0, LANE + Vector3(-2.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), shooter.cannon.stats, Color.WHITE
	)
	# The shot stops on it, spent and harmless, with a flash on every screen, GAME.md 3.6, rather
	# than going on through as if nobody were there.
	var flashed := [0]
	var flash := func(_at: Vector3, _color: Color) -> void: flashed[0] += 1
	Events.bullet_deflected.connect(flash)
	assert_bool(victim.take_hit(bullet)).is_true()
	assert_int(flashed[0]).is_equal(1)
	assert_int(victim.lives).is_equal(1)
	assert_bool(victim.alive).is_true()
	# Its own shot, untouchable, passes, as a shot through a kart gone down a hole does.
	bullet.owner_slot = 1
	assert_bool(victim.take_hit(bullet)).is_false()
	Events.bullet_deflected.disconnect(flash)
	assert_int(flashed[0]).is_equal(1)
	assert_bool(&"bullet_deflected" in NetEvents.RELAYED).is_true()
	bullet.destroy()
	# It wears off and the kart can be finished after that.
	victim.hurt_left = 0.0
	assert_bool(victim.is_targetable()).is_true()


## GAME.md 8.3: a destroyed kart or crate leaves a burst of chunks; one lost down a pit does not.
func test_destroyed_things_leave_a_burst_of_chunks_but_pit_falls_do_not() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var tree := match_node.get_tree()
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	victim.global_position = LANE
	assert_int(tree.get_nodes_in_group(&"bursts").size()).is_equal(0)
	# A wound is not a destruction: the chunks wait for the last life.
	await _shoot(match_node, shooter, LANE)
	assert_bool(victim.alive).is_true()
	assert_int(tree.get_nodes_in_group(&"bursts").size()).is_equal(0)
	await _wait_out_immunity(victim)
	victim.global_position = LANE
	await _shoot(match_node, shooter, LANE)
	assert_bool(victim.alive).is_false()
	assert_int(tree.get_nodes_in_group(&"bursts").size()).is_equal(1)
	var crate: Crate = match_node.arena.crates[0]
	crate.hit(0)
	await _runner.simulate_frames(2, 17)
	assert_int(tree.get_nodes_in_group(&"bursts").size()).is_equal(2)
	for burst: Burst in tree.get_nodes_in_group(&"bursts"):
		burst.queue_free()
	await _runner.simulate_frames(2, 17)
	shooter.global_position = match_node.arena.pits[0].global_position
	await _runner.simulate_frames(45, 17)
	assert_bool(shooter.alive).is_false()
	assert_int(tree.get_nodes_in_group(&"bursts").size()).is_equal(0)


func test_a_pit_kills_a_kart_whatever_its_lives() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var victim := match_node.kart_of(1)
	var events := monitor_signals(Events, false)
	victim.global_position = match_node.arena.pits[0].global_position
	await _runner.simulate_frames(45, 17)
	assert_bool(victim.alive).is_false()
	assert_int(match_node.slots[1].deaths).is_equal(1)
	# The floor going is its own moment, and its own sound: the kill is the landing.
	await assert_signal(events).is_emitted("kart_fell", [1])


func test_lives_reach_puppets_through_snapshots() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var shooter := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	victim.global_position = LANE
	await _shoot(match_node, shooter, LANE)
	assert_int(victim.lives).is_equal(1)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = match_node.rules
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(match_node.build_snapshot())
	var puppet: Kart = client.slots[1].kart
	assert_int(puppet.lives).is_equal(1)
	assert_bool(puppet.is_wounded()).is_true()
	assert_float(puppet._tint.albedo_color.v).is_less(Palette.player_color(1).v - 0.1)
	assert_int(client.slots[0].kart.lives).is_equal(2)


## GAME.md 3.6: coming back is announced to the room rather than only to whoever happened to be
## watching that kart blink.
func test_a_kart_coming_back_opens_a_ring_in_its_own_color() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	rules.respawn_delay = 0.2
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 11)
	await _runner.simulate_frames(12, 17)
	var victim := match_node.kart_of(1)
	assert_array(_rings(match_node)).is_empty()
	victim.die(&"pit", -1)
	await _runner.simulate_frames(20, 17)
	var rings := _rings(match_node)
	assert_int(rings.size()).is_equal(1)
	var flare: SpawnRing = rings[0]
	assert_object(flare.color).is_equal(match_node.slots[1].color())
	# And it is gone again on its own a moment later.
	await _runner.simulate_frames(80, 17)
	assert_array(_rings(match_node)).is_empty()


## A client hears that a kart is back before the snapshot that puts it there, so the ring opens
## where the host put the kart, not over the spot it died on.
func test_a_client_opens_the_ring_where_the_kart_came_back() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	rules.respawn_delay = 0.2
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = rules
	host.with_hud = false
	host.offer_size = 0
	_runner = scene_runner(host)
	host.start([KartInput.new(), KartInput.new()] as Array[KartInput], 11)
	await _runner.simulate_frames(12, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = rules
	add_child(client)
	client.start_puppet()
	var victim := host.kart_of(1)
	victim.global_position = LANE
	victim.die(&"shot", 0)
	client.apply_snapshot(host.build_snapshot())
	var died_at := client.kart_of(1).global_position
	await _runner.simulate_frames(20, 17)
	assert_bool(victim.alive).is_true()
	var back := victim.global_position
	assert_float(Vector2(back.x - died_at.x, back.z - died_at.z).length()).is_greater(2.0)
	var rings := _rings(client)
	assert_int(rings.size()).is_equal(1)
	var at: Vector3 = (rings[0] as SpawnRing).global_position
	assert_vector(Vector2(at.x, at.z)).is_equal_approx(Vector2(back.x, back.z), Vector2.ONE * 0.01)


func _rings(match_node: Match) -> Array:
	var found: Array = []
	for child: Node in match_node.get_children():
		if child is SpawnRing:
			found.append(child)
	return found


## GAME.md 4.1: a ram somebody lives through knocks coins out of their pot onto the floor. A ram
## that kills scatters them through the death sequence already, so this is for the other one.
func test_a_ram_that_does_not_kill_knocks_coins_loose() -> void:
	var match_node := await _ram_match()
	var victim := match_node.kart_of(1)
	victim.pot.add_coins(20)
	var loose := _chips(match_node)
	KartCollisions.ram(victim, 0)
	assert_bool(victim.alive).is_true()
	assert_bool(victim.is_wounded()).is_true()
	# A quarter of them, out of the pot and onto the floor.
	assert_int(victim.pot.coins).is_equal(15)
	assert_int(_chips(match_node) - loose).is_equal(5)
	# A kart with nothing to lose loses nothing, and drops no empty handful.
	await _wait_out_immunity(victim)
	victim.pot.reset()
	victim.lives = 2
	loose = _chips(match_node)
	KartCollisions.ram(victim, 0)
	assert_int(_chips(match_node)).is_equal(loose)
	# Held tight, a pot keeps every coin, GAME.md 7.3.
	await _wait_out_immunity(victim)
	victim.lives = 2
	victim.jokers.add(load("res://data/jokers/tight_grip.tres"))
	victim.pot.add_coins(20)
	KartCollisions.ram(victim, 0)
	assert_bool(victim.is_wounded()).is_true()
	assert_int(victim.pot.coins).is_equal(20)
	assert_int(_chips(match_node)).is_equal(loose)


## GAME.md 4.1: a kart too freshly hurt to lose another life is still knocked by a ram, and loses
## coins rather than a life. A ram reaches nobody twice inside the cooldown, so two karts stuck
## together do not knock a pot out a handful a tick.
func test_a_ram_knocks_coins_out_of_a_kart_it_cannot_hurt() -> void:
	var match_node := await _ram_match()
	var victim := match_node.kart_of(1)
	KartCollisions.ram(victim, 0)
	assert_int(victim.lives).is_equal(1)
	victim.pot.add_coins(20)
	var loose := _chips(match_node)
	# Still blinking from that one, and past the cooldown.
	await _runner.simulate_frames(15, 17)
	assert_bool(victim.is_targetable()).is_false()
	KartCollisions.ram(victim, 0)
	assert_bool(victim.alive).is_true()
	assert_int(victim.lives).is_equal(1)
	assert_int(victim.pot.coins).is_equal(15)
	assert_int(_chips(match_node) - loose).is_equal(5)
	# Rammed again on the very next tick, it loses nothing more.
	await _runner.simulate_frames(1, 17)
	KartCollisions.ram(victim, 0)
	assert_int(victim.pot.coins).is_equal(15)
	await _runner.simulate_frames(15, 17)
	KartCollisions.ram(victim, 0)
	assert_int(victim.pot.coins).is_equal(11)
	assert_int(victim.lives).is_equal(1)
	# Just back on the floor, under the spawn's protection, it is knocked the same way.
	victim.respawn(victim.global_position, Vector3.FORWARD, match_node.rules.spawn_protection)
	victim.pot.reset()
	victim.pot.add_coins(20)
	await _runner.simulate_frames(15, 17)
	KartCollisions.ram(victim, 0)
	assert_int(victim.lives).is_equal(match_node.rules.lives)
	assert_int(victim.pot.coins).is_equal(15)


## A match of two for ramming in, under way.
func _ram_match() -> Match:
	var rules := RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 11)
	await _runner.simulate_frames(12, 17)
	return match_node


func _chips(match_node: Match) -> int:
	var count := 0
	for node: Node in match_node.arena.pickups.get_children():
		if node is Chip:
			count += 1
	return count
