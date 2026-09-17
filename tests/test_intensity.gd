extends GdUnitTestSuite
## The excitement meter, GAME.md 8.4: heat from what just happened plus pressure from how the
## match stands, read out as six levels that hold, with the music layer following them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 23)
	return match_node


## Parks both karts well apart and empties their pots, so the meter starts from nothing.
func _settle(match_node: Match) -> void:
	match_node.kart_of(0).global_position = Vector3(-15.0, 0.0, -9.0)
	match_node.kart_of(1).global_position = Vector3(15.0, 0.0, 9.0)
	for slot: PlayerSlot in match_node.slots:
		slot.kart.pot.reset()
	match_node.intensity.reset()
	await _runner.simulate_frames(6, 17)


## A match opens at level 1, and one kill on its own is not an evening: it takes sustained
## action, held up for a few seconds, to be given the next level.
func test_the_match_opens_at_level_one_and_sustained_action_wins_a_level() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	assert_int(meter.level).is_equal(1)
	assert_float(meter.share()).is_equal(0.0)
	assert_str(Audio.current_layer).is_equal("calm")
	# One kill reads on the meter but fades long before the level would follow it.
	meter.add(MatchIntensity.KILL)
	await _runner.simulate_frames(20, 17)
	assert_float(meter.value).is_greater(0.1)
	assert_int(meter.level).is_equal(1)
	# Kept up for a few seconds, it is another matter.
	for i: int in 10:
		meter.add(MatchIntensity.KILL)
		await _runner.simulate_frames(18, 17)
	assert_int(meter.level).is_greater(1)
	assert_int(meter.level).is_less_equal(MatchIntensity.LEVELS)


## The levels are the point: they climb one at a time and then stand, so a flurry cannot flick
## the room up and straight back down again.
func test_a_level_climbs_one_step_at_a_time_and_then_stands() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	assert_int(meter.level).is_equal(1)
	# Everything at once. Even so the room takes it one level at a time.
	meter.value = 1.0
	meter._hold = 0.0
	meter._dwell = 0.0
	for i: int in int(MatchIntensity.DWELL * 60.0) + 30:
		meter.value = 1.0
		await _runner.simulate_frames(1, 17)
	assert_int(meter.level).is_equal(2)
	# And having just moved, it stands there for a while whatever the meter says.
	meter.value = 0.0
	await _runner.simulate_frames(30, 17)
	assert_int(meter.level).is_equal(2)


## GAME.md 8.4: only level 6 puts the beat in the camera, and even there it is a nudge that has
## fallen away again before the next beat.
func test_only_the_top_level_puts_the_beat_in_the_camera() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	for level: int in range(1, MatchIntensity.LEVELS):
		match_node.intensity.level = level
		assert_float(match_node._beat_tremble()).is_equal(0.0)
	var peak := 0.0
	var trough := 1.0
	for i: int in 40:
		match_node.intensity.level = MatchIntensity.LEVELS
		var nudge := match_node._beat_tremble()
		peak = maxf(peak, nudge)
		trough = minf(trough, nudge)
		await _runner.simulate_frames(1, 17)
	assert_float(peak).is_greater(0.5)
	assert_float(trough).is_less(0.1)
	# And a beat is worth being felt: it shakes the camera harder than a kart being wrecked in a
	# cold room, which is the point of the top of the meter. Kills still hit hardest.
	assert_float(peak * CameraRig.TREMBLE_SHAKE).is_greater(0.2)
	assert_float(peak * CameraRig.TREMBLE_SHAKE).is_less(0.7)


## GAME.md 8.4: everyone being dead normally takes the room back to level 1, but the finale is
## the finale whoever is lying in a pit for the last few seconds of it.
func test_dying_in_last_call_does_not_wind_the_room_back_down() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	match_node._enter_last_call()
	await _runner.simulate_frames(int(MatchIntensity.LAST_CALL_CLIMB * 60.0) + 30, 17)
	assert_int(meter.level).is_equal(MatchIntensity.LEVELS)
	assert_str(Audio.current_layer).is_equal("peak")
	# The only human on this screen goes down, and the room carries on regardless.
	match_node.kart_of(0).die(&"test", -1)
	await _runner.simulate_frames(30, 17)
	assert_bool(match_node.kart_of(0).alive).is_false()
	assert_int(meter.level).is_equal(MatchIntensity.LEVELS)
	assert_float(meter.value).is_equal_approx(1.0, 0.001)
	assert_str(Audio.current_layer).is_equal("peak")


## GAME.md 8.4: a bounty is an announcement, so the room goes up a level for it there and then
## rather than waiting for the meter to argue its way there.
func test_a_bounty_puts_the_room_up_a_level() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	assert_int(meter.level).is_equal(1)
	Events.bounty_called.emit(0)
	await _runner.simulate_frames(2, 17)
	assert_int(meter.level).is_equal(2)
	# Another one on top of it goes up again: a bounty does not wait on the hold.
	Events.bounty_called.emit(0)
	await _runner.simulate_frames(2, 17)
	assert_int(meter.level).is_equal(3)
	# It stands for a while rather than being argued straight back down by a quiet meter.
	await _runner.simulate_frames(120, 17)
	assert_int(meter.level).is_equal(3)
	# And a room nobody is fighting in does come back down eventually.
	await _runner.simulate_frames(int((MatchIntensity.HOLD + MatchIntensity.DWELL) * 120.0), 17)
	assert_int(meter.level).is_less(3)


func test_pressure_comes_from_a_fat_pot_a_duel_and_a_cash_out() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	assert_float(meter.pressure).is_equal_approx(0.0, 0.001)
	match_node.kart_of(0).pot.add_coins(int(match_node.rules.junction_hint_full))
	await _runner.simulate_frames(4, 17)
	var with_pot := meter.pressure
	assert_float(with_pot).is_between(0.2, 0.3)
	match_node.kart_of(1).global_position = (
		match_node.kart_of(0).global_position + Vector3(2.0, 0.0, 0.0)
	)
	await _runner.simulate_frames(4, 17)
	assert_float(meter.pressure).is_greater(with_pot + 0.15)


## GAME.md 8.4: Last Call walks the room up to the top rather than switching to it, a level
## every couple of seconds, and the music comes with it.
func test_last_call_climbs_to_the_top_level_and_everyone_down_drops_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var meter := match_node.intensity
	assert_int(meter.level).is_equal(1)
	match_node._enter_last_call()
	# Not there yet: one step at a time, whatever the meter says.
	await _runner.simulate_frames(6, 17)
	assert_int(meter.level).is_equal(1)
	await _runner.simulate_frames(int(MatchIntensity.LAST_CALL_STEP * 60.0) + 10, 17)
	assert_int(meter.level).is_equal(2)
	assert_str(Audio.current_layer).is_equal("calm")
	# And all the way up within the ten seconds the climb is given.
	await _runner.simulate_frames(int(MatchIntensity.LAST_CALL_CLIMB * 60.0), 17)
	assert_int(meter.level).is_equal(MatchIntensity.LEVELS)
	assert_float(meter.share()).is_equal(1.0)
	assert_float(meter.value).is_equal_approx(1.0, 0.001)
	assert_str(Audio.current_layer).is_equal("peak")
	match_node._set_state(Match.State.RESULTS)
	meter.add(MatchIntensity.KILL)
	meter.reset()
	assert_float(meter.value).is_equal(0.0)
	assert_int(meter.level).is_equal(1)
	assert_str(Audio.current_layer).is_equal("calm")


## GAME.md 8.4: a hot table is not only louder. The Jackpot fills faster and holds more and
## nitro comes back quicker, so the finale has something to spend as well as something to hear.
func test_a_hot_table_fills_and_refills_faster_than_a_cold_one() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	var zone: JackpotZone = match_node.arena.jackpot_zones[0]
	var kart := match_node.kart_of(0)
	match_node.intensity.level = 1
	await _runner.simulate_frames(4, 17)
	var cold_fill := zone.accrual_multiplier
	var cold_cap := zone.cap()
	var cold_nitro := kart.nitro_recharge_scale
	match_node.intensity.level = MatchIntensity.LEVELS
	await _runner.simulate_frames(4, 17)
	assert_float(zone.accrual_multiplier).is_greater(cold_fill)
	assert_int(zone.cap()).is_greater(cold_cap)
	assert_float(kart.nitro_recharge_scale).is_greater(cold_nitro)
	assert_float(zone.accrual_multiplier).is_equal_approx(
		match_node.rules.jackpot_accrual_hot, 0.001
	)
	assert_int(zone.cap()).is_equal(
		roundi(match_node.rules.jackpot_cap * match_node.rules.jackpot_cap_hot)
	)


## GAME.md 3.11: once the room is going the table starts throwing good cards onto the floor,
## and never a common one.
func test_a_hot_table_throws_jokers_onto_the_floor() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	await _settle(match_node)
	# Cold, nothing is thrown however long it is left.
	match_node.intensity.level = 1
	match_node.wild_joker_left = 0.05
	await _runner.simulate_frames(30, 17)
	assert_int(_floor_jokers(match_node).size()).is_equal(0)
	# Hot, one lands, and it is worth picking up.
	match_node.intensity.level = MatchIntensity.LEVELS
	match_node.wild_joker_left = 0.05
	var dropped: Array[StringName] = []
	Events.wild_joker_dropped.connect(func(id: StringName) -> void: dropped.append(id))
	await _runner.simulate_frames(30, 17)
	var cards := _floor_jokers(match_node)
	assert_int(cards.size()).is_equal(1)
	assert_array(dropped).has_size(1)
	assert_int((cards[0] as FloorJoker).joker.rarity).is_greater_equal(Joker.Rarity.UNCOMMON)
	# And it does not keep raining cards: the next one is a while off.
	assert_float(match_node.wild_joker_left).is_greater(1.0)


func _floor_jokers(match_node: Match) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in match_node.arena.pickups.get_children():
		if child is FloorJoker:
			found.append(child)
	return found
