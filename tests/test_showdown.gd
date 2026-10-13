extends GdUnitTestSuite
## A showdown, GAME.md 9.7a: sudden death from the flag on the Showdown map, nobody coming back, no
## money in the room, the same hand for every kart in it, everybody else sitting it out, and the
## order they go out in.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")
const ALL_ITEMS: PowerUpTable = preload("res://data/powerups/all.tres")

var _runner: GdUnitSceneRunner


## A showdown of [param seats] karts, those in [param fighters] in the fight, or all of them.
func _showdown(seats: int, fighters: Array[int] = []) -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.map = ArenaMaps.SHOWDOWN
	rules.countdown = 0.1
	rules.max_players = 8
	rules.fighters = PackedInt32Array(fighters)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.power_ups = ALL_ITEMS
	match_node.arena_layout = ArenaMaps.layout_for(rules)
	match_node.with_hud = false
	match_node.offer_size = 0
	Showdown.dress(match_node)
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in seats:
		inputs.append(KartInput.new())
	match_node.start(inputs, 23)
	return match_node


## Past the lamps and into the fight.
func _to_the_flag(match_node: Match) -> void:
	await _runner.simulate_frames(20, 17)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)


func _order(match_node: Match) -> Array[int]:
	var order: Array[int] = []
	for slot: PlayerSlot in match_node.standings():
		order.append(slot.index)
	return order


## The rules as a showdown plays them, on a copy: the clock, nobody banking, no bounty, nothing on
## the floor, crates for good, no picks.
func test_a_showdown_dresses_its_rules() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.map = ArenaMaps.SHOWDOWN
	assert_bool(rules.showdown()).is_true()
	var dressed := Showdown.dressed(rules)
	assert_float(dressed.duration).is_equal(Showdown.SECONDS)
	assert_bool(dressed.timed).is_true()
	assert_bool(dressed.overtime).is_false()
	assert_bool(dressed.offer_jokers).is_false()
	assert_bool(dressed.bounties).is_false()
	assert_int(dressed.crate_drop_max).is_equal(0)
	assert_float(dressed.crate_respawn).is_greater(3600.0)
	assert_int(dressed.wild_joker_level).is_greater(100)
	assert_float(dressed.last_call_duration).is_less(0.0)
	# The rules it was given are left as they were.
	assert_float(rules.duration).is_equal(DEFAULT_RULES.duration)
	assert_bool(rules.offer_jokers).is_true()
	var items := Showdown.items(ALL_ITEMS)
	for entry: PowerUp in items.entries:
		assert_str(String(entry.id)).is_not_equal("chip_magnet")
	assert_int(items.entries.size()).is_greater(5)
	# Any other map is no showdown, and is left alone.
	rules.map = &"vault"
	assert_bool(rules.showdown()).is_false()


## Only the karts named fight: the rest keep their seats and their karts, but sit it out, out of
## sight, out of the way and out of the camera's frame.
func test_everybody_not_in_it_sits_it_out() -> void:
	var fighters: Array[int] = [1, 3]
	var match_node := _showdown(4, fighters)
	await _to_the_flag(match_node)
	for seat: int in [0, 2]:
		var slot := match_node.slots[seat]
		assert_bool(slot.benched).is_true()
		assert_bool(slot.kart.alive).is_false()
		assert_bool(slot.kart.visible).is_false()
		assert_int(slot.kart.collision_layer).is_equal(0)
		assert_bool(slot.kart in match_node.camera_rig.targets).is_false()
		assert_int(slot.kart.jokers.count()).is_equal(0)
	for seat: int in fighters:
		var slot := match_node.slots[seat]
		assert_bool(slot.benched).is_false()
		assert_bool(slot.kart.alive).is_true()
	# Across the room from each other, on the corners of a diagonal.
	var points := match_node.arena.spawn_points
	var first := match_node.kart_of(1).global_position
	var second := match_node.kart_of(3).global_position
	assert_float(Vector2(first.x, first.z).distance_to(Vector2(points[0].x, points[0].z))).is_less(
		1.0
	)
	(
		assert_float(Vector2(second.x, second.z).distance_to(Vector2(points[3].x, points[3].z)))
		. is_less(1.0)
	)
	# Sitting it out, they rank under everybody in it.
	assert_array(_order(match_node).slice(2)).contains_exactly_in_any_order([0, 2])


## The same three jokers in every hand, each one that does something in a fight.
func test_every_kart_in_it_holds_the_same_hand() -> void:
	var match_node := _showdown(4)
	var first := match_node.kart_of(0).jokers.ids()
	assert_int(first.size()).is_equal(Showdown.HAND)
	for id: StringName in first:
		assert_bool(match_node.joker_catalog.by_id(id).fights).is_true()
	for slot: PlayerSlot in match_node.slots:
		assert_array(slot.kart.jokers.ids()).is_equal(first)
	# Dealt from the table's deck: a deck of two fighting jokers deals those two.
	var deck: Array[StringName] = [&"hair_trigger", &"big_tank", &"payday"]
	match_node.joker_catalog = match_node.joker_catalog.dealing(deck)
	var hand := Showdown.deal_hand(match_node)
	var ids: Array[StringName] = []
	for joker: Joker in hand:
		ids.append(joker.id)
	assert_array(ids).contains_exactly_in_any_order([&"hair_trigger", &"big_tank"])


## The fighting jokers are the ones the design names, GAME.md 9.7a: none about chips, pots or the
## Junction.
func test_the_fighting_jokers() -> void:
	var catalog: JokerCatalog = load("res://data/jokers/catalog.tres")
	var fighting: Array[StringName] = []
	for joker: Joker in catalog.jokers:
		if joker.fights:
			fighting.append(joker.id)
	(
		assert_array(fighting)
		. contains_exactly_in_any_order(
			[
				&"aimbot",
				&"backfire",
				&"big_tank",
				&"curve_ball",
				&"guardian_angel",
				&"hair_trigger",
				&"jerry_can",
				&"nitro_habit",
				&"road_rage",
				&"rubber_bumpers",
				&"scar_tissue",
				&"spare_tire",
			]
		)
	)


## Nobody comes back: a kart out stays out, the last one standing wins and the whistle goes, and
## the standings are the order they went out in, the last one out first.
func test_the_last_kart_standing_wins_and_nobody_comes_back() -> void:
	var match_node := _showdown(3)
	await _to_the_flag(match_node)
	match_node.kart_of(2).die(&"test", 1)
	await _runner.simulate_frames(int(match_node.rules.respawn_delay * 60.0) + 30, 17)
	assert_bool(match_node.kart_of(2).alive).is_false()
	assert_int(match_node.slots[2].out_at).is_greater_equal(0)
	assert_object(match_node.slots[2].offer).is_null()
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	assert_int(Showdown.left(match_node)).is_equal(2)
	match_node.kart_of(0).die(&"test", 1)
	await _runner.simulate_frames(3, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_array(_order(match_node)).is_equal([1, 0, 2])
	var lasted := Showdown.lasted(match_node)
	assert_int(lasted[1]).is_greater(lasted[0])
	assert_int(lasted[0]).is_greater(lasted[2])
	assert_int(lasted[1]).is_greater_equal(GrandPrix.STOOD)


## Karts that go out in the same moment are level on it.
func test_out_together_is_level() -> void:
	var match_node := _showdown(3)
	await _to_the_flag(match_node)
	match_node.kart_of(0).die(&"test", -1)
	match_node.kart_of(1).die(&"test", -1)
	await _runner.simulate_frames(3, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	var lasted := Showdown.lasted(match_node)
	assert_int(lasted[0]).is_equal(lasted[1])
	assert_int(_order(match_node)[0]).is_equal(2)


## Out of time with more than one standing, the whistle goes and lives left rank them.
func test_out_of_time_ranks_on_lives_left() -> void:
	var match_node := _showdown(2)
	await _to_the_flag(match_node)
	match_node.kart_of(0).lives = 1
	match_node.time_left = 0.02
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_array(_order(match_node)).is_equal([1, 0])
	var lasted := Showdown.lasted(match_node)
	# Spare Tire or Scar Tissue in the hand adds lives of its own.
	assert_int(lasted[1]).is_equal(GrandPrix.STOOD + match_node.kart_of(1).lives)
	assert_int(lasted[0]).is_equal(GrandPrix.STOOD + 1)


## The room is at the top from the flag: no Last Call, and the lights and the music as the finale.
func test_the_room_is_the_finale_from_the_flag() -> void:
	var match_node := _showdown(2)
	assert_bool(match_node.in_the_finale()).is_false()
	await _to_the_flag(match_node)
	assert_bool(match_node.in_the_finale()).is_true()
	match_node.time_left = 10.0
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)


## A crate breaks as ever, but drops nothing and stays broken.
func test_a_crate_drops_nothing_and_stays_broken() -> void:
	var match_node := _showdown(2)
	await _to_the_flag(match_node)
	var before := MatchSnapshot.pickups_now(match_node).size()
	var crate: Crate = match_node.arena.crates[0]
	crate.hit(0)
	await _runner.simulate_frames(5, 17)
	assert_int(MatchSnapshot.pickups_now(match_node).size()).is_equal(before)
	crate._respawn_left = 60.0
	await _runner.simulate_frames(30, 17)
	assert_bool(crate.alive).is_false()
	assert_float(crate.respawn_delay).is_greater(3600.0)


## Played on a map at the usual size, nothing about a showdown happens.
func test_any_other_map_is_no_showdown() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	Showdown.dress(match_node)
	assert_object(match_node.rules).is_same(rules)
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new(), KartInput.new()] as Array[KartInput], 23)
	await _runner.simulate_frames(20, 17)
	for slot: PlayerSlot in match_node.slots:
		assert_bool(slot.benched).is_false()
		assert_int(slot.kart.jokers.count()).is_equal(0)
	match_node.kart_of(1).die(&"test", 0)
	await _runner.simulate_frames(3, 17)
	assert_int(match_node.slots[1].out_at).is_equal(-1)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)


## A client ranks the showdown as the host does: who sits it out and when each kart went out ride
## the snapshot.
func test_a_client_ranks_it_as_the_host_does() -> void:
	var fighters: Array[int] = [0, 1, 3]
	var host := _showdown(4, fighters)
	await _to_the_flag(host)
	host.kart_of(1).die(&"test", 0)
	await _runner.simulate_frames(3, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = DEFAULT_RULES.duplicate()
	client.with_hud = false
	client.rules.from_wire(host.rules.to_wire())
	assert_bool(client.rules.showdown()).is_true()
	assert_array(Array(client.rules.fighters)).is_equal([0, 1, 3])
	client.arena_layout = ArenaMaps.layout_for(client.rules)
	Showdown.dress(client)
	add_child(client)
	client.start_puppet()
	client.set_local_slot(0)
	client.apply_snapshot(host.build_snapshot())
	assert_bool(client.slots[2].benched).is_true()
	assert_int(client.slots[1].out_at).is_equal(host.slots[1].out_at)
	assert_array(_order(client)).is_equal(_order(host))
	assert_bool(client.in_the_finale()).is_true()


## A showdown dressed as another room keeps its own floor in it, GAME.md 6.3.
func test_a_showdown_is_dressed_as_the_room_it_is_told() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.map = ArenaMaps.SHOWDOWN
	assert_str(ArenaMaps.layout_for(rules).room.id).is_equal("after_hours")
	rules.room = &"the_yard"
	var dressed := ArenaMaps.layout_for(rules)
	assert_str(dressed.room.id).is_equal("the_yard")
	assert_str(dressed.grid).is_equal(ArenaMaps.layout(ArenaMaps.SHOWDOWN).grid)
	# The map's own layout is left as it was.
	assert_str(ArenaMaps.layout(ArenaMaps.SHOWDOWN).room.id).is_equal("after_hours")
	rules.room = &"a_room_from_the_future"
	assert_str(ArenaMaps.layout_for(rules).room.id).is_equal("after_hours")


## Bots hunt in a showdown, GAME.md 9.7a: every one knows where the nearest kart is, seen or not,
## and a room of them gets on with it.
func test_bots_go_after_each_other() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.map = ArenaMaps.SHOWDOWN
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.power_ups = ALL_ITEMS
	match_node.arena_layout = ArenaMaps.layout_for(rules)
	match_node.bot_difficulty = load("res://data/ai/hard.tres")
	match_node.with_hud = false
	match_node.offer_size = 0
	Showdown.dress(match_node)
	_runner = scene_runner(match_node)
	match_node.start([BotInput.new(), BotInput.new()] as Array[KartInput], 41)
	await _to_the_flag(match_node)
	var brain: BotBrain = match_node.kart_of(0).get_node("Brain")
	var other := match_node.kart_of(1)
	# Across the room from each other, out of sight of each other, and known about all the same.
	assert_bool(brain.has_line_of_sight(other.global_position)).is_false()
	assert_bool(brain._context()["enemy_visible"]).is_true()
	for second: int in 90:
		await _runner.simulate_frames(60, 16)
		if match_node.state == Match.State.RESULTS:
			break
	assert_int(match_node.state).override_failure_message("nobody went out in 90 s").is_equal(
		Match.State.RESULTS
	)
