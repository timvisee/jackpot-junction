extends GdUnitTestSuite
## A pot one cash-out from winning the match on fire, GAME.md 3.4 and 8.3: its owner's numbers in
## their corner of the HUD, and their kart laying gold tracks, on every machine.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	return rules


## Lit by a pot that banked would win, and out again once it would not; a rival's kart that
## would not win lays its tracks as ever.
func test_a_pot_that_would_win_sets_its_numbers_and_its_kart_alight() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules()
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(20, 17)
	var pills: ScorePills = match_node.hud._blocks[0]["pot"]
	var kart := match_node.kart_of(0)
	match_node.slots[0].banked = match_node.rules.target_score - 50
	kart.pot.add_coins(40)
	await runner.simulate_frames(3, 17)
	assert_bool(pills.is_burning()).override_failure_message("short of it").is_false()
	assert_bool(kart.tire_marks.gold).is_false()
	kart.pot.add_coins(20)
	await runner.simulate_frames(3, 17)
	assert_bool(pills.is_burning()).is_true()
	# A sheet of fire off each pill, climbing up over the banked score above the pills.
	assert_int(pills._flames.size()).is_equal(2)
	var banked: Label = match_node.hud._blocks[0]["banked"]
	for flame: PotFlame in pills._flames:
		assert_float(flame.get_global_rect().position.y).is_less(banked.get_global_rect().end.y)
	assert_bool(kart.tire_marks.gold).is_true()
	assert_bool(match_node.kart_of(1).tire_marks.gold).is_false()
	# What it lays is gold, over the ordinary mark it would have laid, left once the gold has gone.
	_lay(kart.tire_marks, 0.06)
	var laid: Dictionary = kart.tire_marks._open[0].back()
	assert_bool(laid["gold"]).is_true()
	var ordinary := lerpf(TireMarks.MIN_ALPHA, TireMarks.MAX_ALPHA, 0.06)
	assert_float(laid["alpha"]).is_equal_approx(
		ordinary if Game.settings.tire_marks else 0.0, 0.0001
	)
	kart.pot.reset()
	await runner.simulate_frames(3, 17)
	assert_bool(pills.is_burning()).is_false()
	assert_bool(kart.tire_marks.gold).is_false()
	_lay(kart.tire_marks, 0.06)
	assert_bool(kart.tire_marks._open[0].back()["gold"]).is_false()


## GAME.md 3.4: what would win is what a cash-out would bank, not the pot's bare worth. With a
## target of 3000, a pot of 2000 wins with Glass Jackpot's half again on it, and wins without it
## once Last Call doubles what the Junction pays.
func test_would_win_counts_what_a_cash_out_would_pay() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules()
	match_node.rules.target_score = 3000
	match_node.with_hud = false
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(20, 17)
	var slot := match_node.slots[0]
	slot.kart.pot.add_coins(2000)
	assert_int(slot.cash_out_value()).is_equal(2000)
	assert_bool(match_node.would_win(slot)).is_false()
	slot.kart.jokers.add(load("res://data/jokers/glass_jackpot.tres"))
	assert_int(slot.cash_out_value()).is_equal(3000)
	assert_bool(match_node.would_win(slot)).is_true()
	slot.kart.jokers.remove_at(0)
	match_node.arena.junction.payout_multiplier = 2.0
	assert_bool(match_node.would_win(slot)).is_true()
	# Nothing in the pot is nothing to cash in, whatever it would pay.
	slot.kart.pot.reset()
	assert_bool(match_node.would_win(slot)).is_false()


## Gold tracks are laid with the tire marks turned off in the settings, GAME.md 8.5: they say who
## is about to win rather than dressing the floor. Ordinary ones are not.
func test_gold_tracks_are_laid_with_the_tire_marks_off() -> void:
	# Settings of its own, so nothing here can reach the player's.
	var was := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_winning_blaze.cfg"
	var marks: TireMarks = auto_free(TireMarks.new())
	add_child(marks)
	Game.settings.tire_marks = false
	marks._process(0.0)
	_lay(marks, 0.5)
	assert_bool(marks._open[0].is_empty()).is_true()
	marks.gold = true
	_lay(marks, 0.5)
	assert_bool(marks._open[0].is_empty()).is_false()
	# And nothing is left once the gold has gone: the marks are off.
	assert_float(marks._open[0].back()["alpha"]).is_zero()
	marks._process(0.0)
	assert_bool(marks._open[0].is_empty()).is_false()
	Game.settings = was


## A few samples laid in a line at [param intensity], a hand's width further on than the last.
static func _lay(marks: TireMarks, intensity: float) -> void:
	var from := 50.0 + randf() * 50.0
	for i: int in 4:
		var at := Vector3(from + i * TireMarks.MIN_SAMPLE_DISTANCE * 1.5, 0.0, 0.0)
		marks.add_sample(0, at, Vector3.FORWARD, intensity, 1.0)


## A client works out who lays gold from the banked scores and pots the snapshot hands it, so its
## karts lay it the same as the host's with nothing more said.
func test_a_client_sees_the_same_kart_lay_gold() -> void:
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.with_hud = false
	host.offer_size = 0
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 23)
	await runner.simulate_frames(20, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	host.slots[1].banked = host.rules.target_score - 10
	host.kart_of(1).pot.add_coins(30)
	await runner.simulate_frames(2, 17)
	client.apply_snapshot(host.build_snapshot())
	TireMarks.gild(client)
	assert_bool(client.slots[1].kart.tire_marks.gold).is_true()
	assert_bool(client.slots[0].kart.tire_marks.gold).is_false()


## GAME.md 3.4: a cash-out that crosses the target runs to its last coin before the match ends, so
## its player collects all of it; driven off the Junction part way, the match ends there and then.
func test_the_cash_out_that_wins_is_let_finish() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules()
	match_node.rules.target_score = 300
	match_node.with_hud = false
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(20, 17)
	var slot := match_node.slots[0]
	var kart := slot.kart
	slot.banked = 250
	kart.pot.add_coins(400)
	kart.global_position = match_node.arena.junction_position
	var crossed := func() -> bool: return slot.banked >= 300
	for i: int in 600:
		await runner.simulate_frames(1, 17)
		if crossed.call():
			break
	assert_bool(crossed.call()).override_failure_message("never crossed").is_true()
	assert_int(match_node.state).is_not_equal(Match.State.RESULTS)
	for i: int in 1200:
		await runner.simulate_frames(1, 17)
		if match_node.state == Match.State.RESULTS:
			break
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_int(slot.banked).is_equal(650)
	# A second match: crossing, then driven off the pad with some of the pot still in it.
	match_node.rematch()
	await runner.simulate_frames(20, 17)
	slot = match_node.slots[0]
	kart = slot.kart
	slot.banked = 250
	kart.pot.add_coins(400)
	kart.global_position = match_node.arena.junction_position
	for i: int in 600:
		await runner.simulate_frames(1, 17)
		if slot.banked >= 300:
			break
	assert_int(match_node.state).is_not_equal(Match.State.RESULTS)
	kart.global_position = match_node.arena.junction_position + Vector3(0.0, 0.0, 9.0)
	await runner.simulate_frames(4, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_int(slot.banked).is_less(650)


## GAME.md 8.4: a player one cash-out from winning takes the room up to the top the way Last Call
## does, a level at a time, and once nobody is, the room goes back to asking the meter.
func test_a_pot_that_would_win_climbs_the_room_like_last_call() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules()
	match_node.with_hud = false
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(20, 17)
	assert_int(match_node.intensity.level).is_equal(1)
	match_node.slots[0].banked = match_node.rules.target_score - 10
	match_node.kart_of(0).pot.add_coins(40)
	assert_bool(match_node.someone_would_win()).is_true()
	await runner.simulate_frames(int(MatchIntensity.LAST_CALL_CLIMB * 60.0) + 30, 17)
	assert_int(match_node.intensity.level).is_equal(MatchIntensity.LEVELS)
	match_node.kart_of(0).pot.reset()
	assert_bool(match_node.someone_would_win()).is_false()
	await runner.simulate_frames(2, 17)
	assert_bool(match_node.intensity._finale).is_false()


## GAME.md 3.4: the moment a player's next cash-out would win is called out on every screen, in
## their color, and not again for a while however their pot hovers on the line.
func test_the_moment_a_pot_would_win_is_called_out() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules()
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(20, 17)
	var hud := match_node.hud
	# A rival's pot, not this screen's player's: everybody is told.
	match_node.slots[1].banked = match_node.rules.target_score - 10
	match_node.kart_of(1).pot.add_coins(40)
	await runner.simulate_frames(2, 17)
	assert_bool(hud._call.visible).is_true()
	var named := match_node.slots[1].display_name()
	assert_str(hud._call.text).is_equal("%s  %s" % [named, MatchHud.WIN_CALL])
	# Off the line and back on it at once is not called again.
	hud._call_left = 0.0
	hud._call.visible = false
	match_node.kart_of(1).pot.reset()
	await runner.simulate_frames(2, 17)
	match_node.kart_of(1).pot.add_coins(40)
	await runner.simulate_frames(2, 17)
	assert_bool(hud._call.visible).is_false()


## A room with no target, such as the development driving room, has nothing to win.
func test_a_room_with_no_target_has_nothing_to_win() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules()
	match_node.rules.target_score = 0
	match_node.with_hud = false
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(20, 17)
	match_node.kart_of(0).pot.add_coins(40)
	assert_bool(match_node.would_win(match_node.slots[0])).is_false()
	assert_bool(match_node.someone_would_win()).is_false()
