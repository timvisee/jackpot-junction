extends GdUnitTestSuite
## Royal Flush pads, GAME.md 3.9: claiming, stealing, the flush bonus and the disabled spell.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match(inputs: Array[KartInput] = [], hud := false) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = hud
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	if inputs.is_empty():
		inputs = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 9)
	return match_node


func _park(kart: Kart, pad: FlushPad) -> void:
	kart.global_position = pad.global_position
	await _runner.simulate_frames(3, 17)


## GAME.md 3.9: a pad pays its holder while they hold it, and pays nothing to a holder who is
## not in play or once it has been taken back off them.
func test_a_held_pad_trickles_coins_into_its_holders_pot() -> void:
	var match_node := _start_match()
	match_node.rules.flush_pad_income = 4.0
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pads := match_node.arena.flush_pads
	kart.pot.reset()
	await _park(kart, pads[0])
	assert_int(pads[0].owner_slot).is_equal(0)
	# One pad held: coins arrive, in whole coins, without anyone driving anywhere.
	kart.global_position = match_node.arena.spawn_points[0]
	await _runner.simulate_frames(60, 17)
	var one_pad := kart.pot.coins
	assert_int(one_pad).is_greater(0)
	# Unheld pads pay nobody, and a dead holder earns nothing while they are down.
	var idle := match_node.kart_of(1).pot.coins
	assert_int(idle).is_equal(0)
	kart.die(&"test", -1)
	await _runner.simulate_frames(30, 17)
	assert_int(kart.pot.coins).is_equal(0)
	assert_int(pads[0].owner_slot).is_equal(0)


## GAME.md 3.9: the board pays on one beat rather than four. Every pad that owes somebody a coin
## hands it over on the same tick, so the rings go up together and a player holding two pads is
## paid two coins at once instead of a stutter of singles.
func test_the_pads_all_pay_on_the_same_beat() -> void:
	var match_node := _start_match()
	match_node.rules.flush_pad_income = 3.0
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pads := match_node.arena.flush_pads
	kart.pot.reset()
	for pad: FlushPad in pads:
		await _park(kart, pad)
	# Taking the fourth scores the flush, which clears the board, so the lock is what is paying
	# now: all four pads at once, in the winner's color.
	kart.global_position = match_node.arena.spawn_points[0]
	assert_float(match_node.flush_lock_left).is_greater(0.0)
	var paid: Array[int] = []
	var rings := 0
	for i: int in 90:
		var before := kart.pot.coins
		await _runner.simulate_frames(1, 17)
		var gained := kart.pot.coins - before
		if gained > 0:
			paid.append(gained)
			# Every pad throws its ring on that same tick rather than in its own time.
			var lit := 0
			for pad: FlushPad in pads:
				if pad._halo_left > 0.9:
					lit += 1
			rings = maxi(rings, lit)
	assert_int(paid.size()).is_greater(0)
	# Four pads, four coins, all in the one tick.
	assert_int(paid[0]).is_equal(pads.size())
	assert_int(rings).is_equal(pads.size())


## GAME.md 3.9: a paid coin throws a ring off the pad, in the holder's color, so the trickle can
## be seen from across the table.
## GAME.md 3.9: the trickle runs with the room, so a pad pays faster at level 6 than at level 1.
func test_a_hot_room_pays_the_pads_faster() -> void:
	var match_node := _start_match()
	match_node.rules.flush_pad_income = 4.0
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pads := match_node.arena.flush_pads
	await _park(kart, pads[0])
	kart.global_position = match_node.arena.spawn_points[0]
	match_node.intensity.level = 1
	kart.pot.reset()
	await _runner.simulate_frames(60, 17)
	var cold := kart.pot.coins
	assert_int(cold).is_greater(0)
	match_node.intensity.level = MatchIntensity.LEVELS
	kart.pot.reset()
	await _runner.simulate_frames(60, 17)
	assert_int(kart.pot.coins).is_greater(cold * 2)


## GAME.md 3.9: winning a flush clears the board it was won on, so without a lock-in the reward
## for winning one is that the thing paying you stops. The four pads keep paying their winner for
## a while as though they were still held.
func test_a_flush_keeps_paying_its_winner_while_the_pads_rest() -> void:
	var match_node := _start_match()
	match_node.rules.flush_pad_income = 4.0
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var rival := match_node.kart_of(1)
	for pad: FlushPad in match_node.arena.flush_pads:
		await _park(kart, pad)
	assert_int(match_node.flush_lock_slot).is_equal(0)
	assert_float(match_node.flush_lock_left).is_greater(0.0)
	for pad: FlushPad in match_node.arena.flush_pads:
		assert_bool(pad.is_disabled()).is_true()
		assert_int(pad.owner_slot).is_equal(-1)
	# Off the pads entirely, and still being paid by them.
	kart.global_position = match_node.arena.spawn_points[0]
	kart.pot.reset()
	rival.pot.reset()
	await _runner.simulate_frames(60, 17)
	assert_int(kart.pot.coins).is_greater(0)
	# Nobody else is, and the rings say whose flush it is.
	assert_int(rival.pot.coins).is_equal(0)
	assert_object(match_node.arena.flush_pads[0]._halo_color).is_equal(match_node.slots[0].color())
	# And it runs out, leaving the board to be fought over again.
	match_node.flush_lock_left = 0.05
	await _runner.simulate_frames(20, 17)
	kart.pot.reset()
	await _runner.simulate_frames(60, 17)
	assert_float(match_node.flush_lock_left).is_equal(0.0)
	assert_int(kart.pot.coins).is_equal(0)


func test_every_paid_coin_throws_a_ring_off_the_pad() -> void:
	var match_node := _start_match()
	match_node.rules.flush_pad_income = 4.0
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pads := match_node.arena.flush_pads
	assert_bool(pads[0]._halo.visible).is_false()
	await _park(kart, pads[0])
	kart.global_position = match_node.arena.spawn_points[0]
	await _runner.simulate_frames(30, 17)
	assert_bool(pads[0]._halo.visible).is_true()
	assert_float(pads[0]._halo_material.albedo_color.a).is_greater(0.0)
	# Lying flat on the table, not standing up on edge, and square with the pad rather than
	# stood on a corner.
	assert_float(pads[0]._halo.rotation_degrees.y).is_equal_approx(45.0, 0.01)
	var box := pads[0]._halo.get_aabb()
	assert_float(box.size.x).is_greater(box.size.y * 4.0)
	assert_float(box.size.x).is_equal_approx(box.size.z, 0.01)
	assert_object(pads[0]._halo_material.albedo_color.srgb_to_linear()).is_not_equal(Color.BLACK)
	# The ring grows outward as it goes and takes itself off the table when it is spent.
	var first := pads[0]._halo.scale.x
	pads[0].pop_halo()
	pads[0]._physics_process(FlushPad.HALO_TIME * 0.5)
	assert_float(pads[0]._halo.scale.x).is_greater(first)
	pads[0]._physics_process(FlushPad.HALO_TIME)
	pads[0]._physics_process(0.016)
	assert_bool(pads[0]._halo.visible).is_false()


## GAME.md 3.9: a claim lapses on its own, and driving over your own pad renews it.
func test_a_claim_lapses_on_its_own_and_driving_over_it_again_renews_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pad := match_node.arena.flush_pads[0]
	assert_float(pad.decay).is_equal_approx(match_node.rules.flush_pad_decay, 0.01)
	pad.decay = 1.0
	await _park(kart, pad)
	assert_int(pad.owner_slot).is_equal(0)
	assert_float(pad.held_left).is_greater(0.0)
	# Sitting on it renews the claim every time round, so it never lapses under its holder.
	await _runner.simulate_frames(120, 17)
	assert_int(pad.owner_slot).is_equal(0)
	# Driven away from, it lapses back to nobody and stops paying.
	kart.global_position = match_node.arena.spawn_points[0]
	await _runner.simulate_frames(120, 17)
	assert_int(pad.owner_slot).is_equal(-1)
	assert_object(pad.owner_color).is_equal(FlushPad.NEUTRAL)
	assert_bool(pad.is_disabled()).is_false()
	# And it can be taken again straight away.
	await _park(kart, pad)
	assert_int(pad.owner_slot).is_equal(0)


func test_driving_over_pads_claims_and_steals_them_and_all_four_score_a_flush() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var rival := match_node.kart_of(1)
	var pads := match_node.arena.flush_pads
	assert_int(pads.size()).is_equal(4)
	for pad: FlushPad in pads:
		assert_int(pad.owner_slot).is_equal(-1)
	await _park(kart, pads[0])
	assert_int(pads[0].owner_slot).is_equal(0)
	assert_object(pads[0].owner_color).is_equal(Palette.player_color(kart.color_index))
	kart.global_position = match_node.arena.spawn_points[0]
	await _runner.simulate_frames(2, 17)
	await _park(rival, pads[0])
	assert_int(pads[0].owner_slot).is_equal(1)
	rival.global_position = match_node.arena.spawn_points[1]
	await _runner.simulate_frames(2, 17)
	kart.nitro_charge = 0.1
	var events := monitor_signals(Events, false)
	for pad: FlushPad in pads:
		await _park(kart, pad)
		kart.global_position += Vector3(0.0, 0.0, 3.0)
		await _runner.simulate_frames(2, 17)
	await assert_signal(events).is_emitted("flush_completed", [0])
	assert_float(kart.pot.mult).is_equal_approx(1.0 + match_node.rules.flush_mult, 0.001)
	assert_float(kart.nitro_charge).is_equal(1.0)
	for pad: FlushPad in pads:
		assert_int(pad.owner_slot).is_equal(-1)
		assert_bool(pad.is_disabled()).is_true()
	# Disabled pads ignore karts until their time is up.
	await _park(rival, pads[1])
	assert_int(pads[1].owner_slot).is_equal(-1)
	pads[1].disabled_left = 0.03
	await _runner.simulate_frames(4, 17)
	assert_bool(pads[1].is_disabled()).is_false()
	assert_int(pads[1].owner_slot).is_equal(1)


func test_pads_replicate_to_puppets_through_snapshots() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pads := match_node.arena.flush_pads
	await _park(kart, pads[2])
	var snapshot := match_node.build_snapshot()
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = match_node.rules
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(snapshot)
	assert_int(client.arena.flush_pads[2].owner_slot).is_equal(0)
	assert_int(client.arena.flush_pads[0].owner_slot).is_equal(-1)
	assert_bool(client.arena.flush_pads[2].puppet).is_true()


## GAME.md 8.3: while a player at this screen holds a Royal Flush pad, each pad's suit hangs under
## the clock: the held ones in their holders' colors, this screen's player first whatever their
## suits, and the free ones faint at the end. Nobody here holding one, it is not there at all.
func test_the_pads_held_are_counted_under_the_clock() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new(), BotInput.new()
	]
	var match_node := _start_match(inputs, true)
	await _runner.simulate_frames(20, 17)
	var tally: FlushTally = match_node.hud.get_node("FlushTally")
	var pads := match_node.arena.flush_pads
	var mine := match_node.slots[0].color()
	var theirs := match_node.slots[1].color()
	# Somebody else's pad is not this screen's business.
	pads[0].claim(1, theirs)
	await _runner.simulate_frames(2, 17)
	assert_bool(tally.visible).is_false()
	pads[1].claim(0, mine)
	pads[2].claim(1, theirs)
	await _runner.simulate_frames(2, 17)
	assert_bool(tally.visible).is_true()
	assert_int(tally.pads).is_equal(4)
	assert_array(tally.held).is_equal([mine, theirs, theirs])
	assert_array(tally.suits).is_equal(
		[SuitArt.Suit.HEART, SuitArt.Suit.SPADE, SuitArt.Suit.DIAMOND, SuitArt.Suit.CLUB]
	)
	# Let go of, it goes again.
	pads[1].claim(-1, FlushPad.NEUTRAL)
	await _runner.simulate_frames(2, 17)
	assert_bool(tally.visible).is_false()
	# A flush this screen's player scored is theirs for as long as it pays: all four blocks, and a
	# bar under them for how much of it is left. Somebody else's is not this screen's business.
	for pad: FlushPad in pads:
		pad.clear_and_disable(match_node.rules.flush_disable_time)
	match_node.flush_lock_slot = 0
	match_node.flush_lock_left = match_node.rules.flush_lock_seconds * 0.5
	tally._process(0.0)
	assert_bool(tally.visible).is_true()
	assert_array(tally.held).is_equal([mine, mine, mine, mine])
	assert_array(tally.suits).is_equal([0, 1, 2, 3])
	assert_float(tally.locked).is_equal_approx(0.5, 0.05)
	match_node.flush_lock_slot = 1
	tally._process(0.0)
	assert_bool(tally.visible).is_false()


## GAME.md 9.3: a watcher has nobody of their own to count for, and sees the tally whenever
## anybody holds a pad, most held first, and whoever's flush is still paying out.
func test_a_watcher_sees_the_tally_whenever_a_pad_is_held() -> void:
	var inputs: Array[KartInput] = [BotInput.new(), BotInput.new(), BotInput.new()]
	var match_node := _start_match(inputs, true)
	var was: NetSession = Net.session
	var watching: NetSession = auto_free(NetSession.new())
	watching.watching = true
	Net.session = watching
	await _runner.simulate_frames(20, 17)
	var tally: FlushTally = match_node.hud.get_node("FlushTally")
	var pads := match_node.arena.flush_pads
	await _runner.simulate_frames(2, 17)
	assert_bool(tally.visible).override_failure_message("up with no pad held").is_false()
	pads[0].claim(1, match_node.slots[1].color())
	await _runner.simulate_frames(2, 17)
	assert_bool(tally.visible).is_true()
	pads[1].claim(2, match_node.slots[2].color())
	pads[2].claim(2, match_node.slots[2].color())
	tally._process(0.0)
	assert_array(tally.holders).is_equal([2, 2, 1])
	for pad: FlushPad in pads:
		pad.clear_and_disable(match_node.rules.flush_disable_time)
	match_node.flush_lock_slot = 1
	match_node.flush_lock_left = match_node.rules.flush_lock_seconds * 0.5
	tally._process(0.0)
	assert_bool(tally.visible).is_true()
	assert_float(tally.locked).is_equal_approx(0.5, 0.05)
	Net.session = was


## GAME.md 8.3: somebody else one pad off the flush puts the tally up on every screen, whoever
## there holds anything, as a warning: that player's suits pulse and an exclamation mark stands
## at the end of the row. Two pads short of it is not a warning.
func test_a_rival_one_pad_off_the_flush_is_warned_of() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new(), BotInput.new()
	]
	var match_node := _start_match(inputs, true)
	await _runner.simulate_frames(20, 17)
	var tally: FlushTally = match_node.hud.get_node("FlushTally")
	var pads := match_node.arena.flush_pads
	var theirs := match_node.slots[1].color()
	pads[0].claim(1, theirs)
	pads[1].claim(1, theirs)
	tally._process(0.0)
	assert_bool(tally.visible).is_false()
	assert_int(tally.threat).is_equal(-1)
	pads[2].claim(1, theirs)
	tally._process(0.1)
	assert_bool(tally.visible).is_true()
	assert_int(tally.threat).is_equal(1)
	assert_array(tally.held).is_equal([theirs, theirs, theirs])
	assert_array(tally.suits).is_equal([0, 1, 2, 3])
	# This screen's own player one pad off is no warning to themselves.
	for pad: FlushPad in pads.slice(0, 3):
		pad.claim(0, match_node.slots[0].color())
	tally._process(0.1)
	assert_int(tally.threat).is_equal(-1)
	assert_bool(tally.visible).is_true()
