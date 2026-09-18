extends GdUnitTestSuite
## The Garage, GAME.md 9.4: a practice room with everything on the floor, nobody to fight but a
## pair of dummies to shoot at, and no clock running.

const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/garage.tres")
const RULES: MatchRules = preload("res://data/match/garage.tres")

var _runner: GdUnitSceneRunner


func test_the_map_has_one_of_everything_to_practise_on() -> void:
	assert_array(LAYOUT.validate()).is_empty()
	var grid := LAYOUT.parse()
	# Four spawn points: two for players and two for the dummies to stand on.
	assert_int(grid.spawns.size()).is_equal(4)
	assert_int(grid.targets.size()).is_equal(3)
	assert_int(grid.joker_pads.size()).is_equal(1)
	assert_int(grid.turbo_pads.size()).is_equal(2)
	assert_int(grid.flush_pads.size()).is_equal(4)
	assert_int(grid.coin_pads.size()).is_greater_equal(4)
	assert_int(grid.power_pads.size()).is_greater_equal(2)
	assert_int(grid.crates.size()).is_greater_equal(8)
	assert_int(grid.pits.size()).is_equal(1)
	assert_int(grid.jackpots.size()).is_equal(1)
	# The Junction sits in the middle of the room.
	assert_vector(grid.rect_center(grid.junction)).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.01)


func test_the_room_runs_one_player_two_dummies_and_no_clock() -> void:
	# Nothing is heard on the way in either: the tones and the flag both come from the countdown,
	# and there is none. Watched from before the room is built, so nothing can be missed.
	var start_cues: Array[int] = []
	var tone := func(count: int) -> void: start_cues.append(count)
	var flag := func() -> void: start_cues.append(0)
	Events.countdown_tick.connect(tone)
	Events.countdown_done.connect(flag)
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	# Long enough for the countdown to run out, so the room is actually under way.
	await runner.simulate_frames(120, 17)
	var match_node: Match = garage.get_node("Match")
	assert_int(match_node.slots.size()).is_equal(3)
	assert_bool(match_node.slots[0].is_local_human()).is_true()
	assert_object(match_node.slots[0].bot_trait).is_null()
	# The other two are dummies rather than bots: nobody is playing against anybody in here.
	for slot: PlayerSlot in [match_node.slots[1], match_node.slots[2]]:
		assert_bool(slot.is_dummy()).is_true()
		assert_object(slot.bot_trait).is_null()
	assert_int(match_node.arena.targets.size()).is_equal(3)
	assert_int(match_node.arena.joker_pads.size()).is_equal(1)
	# No nightclub in here, whatever the excitement meter says.
	assert_bool(match_node.arena.disco.enabled).is_false()
	match_node.arena.disco.level = DiscoLights.COUNT
	await runner.simulate_frames(10, 17)
	assert_int(match_node.arena.disco.lit_count()).is_equal(0)
	# The clock stands still, so the room never reaches Last Call or the results.
	assert_bool(match_node.rules.timed).is_false()
	var left := match_node.time_left
	await runner.simulate_frames(40, 17)
	assert_float(match_node.time_left).is_equal(left)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	assert_bool(match_node.hud._timer.visible).is_false()
	# Nobody is held on a grid in here, GAME.md 9.4: no countdown, so no gantry and no tones.
	Events.countdown_tick.disconnect(tone)
	Events.countdown_done.disconnect(flag)
	assert_float(match_node.rules.countdown).is_equal(0.0)
	assert_bool(match_node.hud._light.visible).is_false()
	assert_array(start_cues).is_empty()


func test_shooting_a_target_pays_the_shooter() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new()] as Array[KartInput], 43)
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var target: Target = match_node.arena.targets[0]
	assert_int(kart.pot.coins).is_equal(0)
	# Lined up 4 m below the target, shooting straight up the table.
	kart.global_position = target.global_position + Vector3(0.0, 0.0, 4.0)
	kart.face(Vector3(0.0, 0.0, -1.0))
	kart.cannon.stats.aim_assist = false
	kart.cannon.cooldown_left = 0.0
	await _runner.simulate_frames(2, 17)
	kart.cannon.fire(
		match_node.bullets,
		0,
		kart.global_position + Vector3(0.0, 0.0, -1.0),
		Vector3(0.0, 0.0, -1.0),
		Color.WHITE
	)
	await _runner.simulate_frames(20, 17)
	assert_bool(target.alive).is_false()
	assert_int(kart.pot.coins).is_equal(rules.target_coins)
	assert_float(match_node.slots[0].stats.value(&"targets")).is_equal(1.0)


## GAME.md 9.4: the dummies are targets rather than opponents. Nobody drives them, they carry
## something worth shooting them for, and they come back carrying something new.
func test_the_dummies_carry_loot_stand_still_and_come_back_restocked() -> void:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	var runner: GdUnitSceneRunner = scene_runner(garage)
	await runner.simulate_frames(120, 17)
	var match_node: Match = garage.get_node("Match")
	var dummies: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.is_dummy():
			dummies.append(slot)
	assert_int(dummies.size()).is_equal(2)
	for slot: PlayerSlot in dummies:
		assert_str(slot.display_name()).contains("Dummy")
		assert_int(slot.kart.pot.coins).is_greater(0)
		assert_object(slot.kart.held_item).is_not_null()
	var kart := dummies[0].kart
	var parked := kart.global_position
	await runner.simulate_frames(90, 17)
	# Standing where it was put, with nothing fired, however long the room runs.
	assert_vector(kart.global_position).is_equal_approx(parked, Vector3.ONE * 0.05)
	assert_float(dummies[0].stats.value(&"bullets")).is_equal(0.0)
	kart.die(&"bullet", 0)
	assert_bool(kart.alive).is_false()
	await runner.simulate_frames(200, 17)
	assert_bool(kart.alive).is_true()
	assert_int(kart.pot.coins).is_greater(0)
	assert_object(kart.held_item).is_not_null()
