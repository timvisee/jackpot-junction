extends GdUnitTestSuite
## Play, GAME.md 9.7: a Grand Prix of several maps, played one after another by the same people.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LOBBY_SCENE := preload("res://scenes/ui/lobby.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")


func after_test() -> void:
	Game.grand_prix = null
	Game.pending_config = null
	Game.lobby_for = Game.LobbyFor.QUICK_PLAY


func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


## Every map comes round once before any of them comes round again, and none is played twice
## running, whatever the length of the run and however the deal falls.
func test_the_maps_are_dealt_every_one_before_any_again_and_never_twice_running() -> void:
	var count := ArenaMaps.IDS.size()
	for seed: int in 40:
		for rounds: int in MatchOptions.MAPS:
			var dealt := GrandPrix.deal(rounds, _rng(seed))
			assert_int(dealt.size()).is_equal(rounds)
			for start: int in range(0, rounds, count):
				var bag := dealt.slice(start, mini(start + count, rounds))
				var seen := {}
				for map: StringName in bag:
					(
						assert_bool(seen.has(map))
						. override_failure_message("%s dealt twice" % map)
						. is_false()
					)
					seen[map] = true
			for i: int in range(1, rounds):
				(
					assert_bool(dealt[i] == dealt[i - 1])
					. override_failure_message("%s twice running" % dealt[i])
					. is_false()
				)


## A run goes map by map and stops at the last one, and each map is told which one of how many it
## is, which is how a client knows whether its podium leads on.
func test_a_run_goes_map_by_map_and_says_which_one_it_is_on() -> void:
	var run := GrandPrix.start(3, _rng(7))
	var rules := MatchRules.new()
	for round: int in 3:
		assert_str(String(run.current_map())).is_equal(String(run.playlist[round]))
		run.label(rules)
		assert_int(rules.round).is_equal(round + 1)
		assert_int(rules.rounds).is_equal(3)
		assert_bool(run.is_last()).is_equal(round == 2)
		run.advance()
	assert_int(run.round).is_equal(2)
	var theirs := MatchRules.new()
	theirs.from_wire(rules.to_wire())
	assert_int(theirs.round).is_equal(3)
	assert_int(theirs.rounds).is_equal(3)


## The next map is the same configuration on the next arena: the same people, the same bots and
## the same settings. There is no next map after the last one, and none without a run at all.
func test_the_next_map_is_the_same_match_on_the_next_arena() -> void:
	assert_object(Game.next_map_config()).is_null()
	var config := MatchConfig.new()
	config.bot_count = 2
	config.duration = 180.0
	Game.pending_config = config
	Game.grand_prix = GrandPrix.start(2, _rng(3))
	config.map = Game.grand_prix.current_map()
	var next := Game.next_map_config()
	assert_object(next).is_same(config)
	assert_str(String(next.map)).is_equal(String(Game.grand_prix.playlist[1]))
	assert_int(next.bot_count).is_equal(2)
	assert_float(next.duration).is_equal(180.0)
	assert_object(Game.next_map_config()).is_null()


## A map of a run, started the way the match scene starts one: bots drawn from the run's table.
func _map_of(run: GrandPrix, seed: int) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES.duplicate()
	match_node.bot_traits = run.bot_table(match_node.bot_traits)
	add_child(match_node)
	var inputs: Array[KartInput] = [
		PlayerInput.new(), BotInput.new(), BotInput.new(), BotInput.new()
	]
	match_node.start(inputs, seed)
	return match_node


## The bots are dealt once, at the start of the run, and every map of it has the same ones in
## the same seats: the same way of driving and so the same name, however each map's own draw
## would have fallen.
func test_every_map_of_a_run_has_the_same_bots() -> void:
	var run := GrandPrix.start(3, _rng(11))
	run.deal_bots(load("res://data/ai/traits.tres"), 3, _rng(12))
	assert_int(run.bots.size()).is_equal(3)
	var first := _map_of(run, 101)
	var second := _map_of(run, 202)
	for seat: int in range(1, 4):
		var dealt: BotTrait = run.bots[seat - 1]
		assert_str(String(first.slots[seat].bot_trait.id)).is_equal(String(dealt.id))
		assert_str(String(second.slots[seat].bot_trait.id)).is_equal(String(dealt.id))
		assert_str(second.slots[seat].display_name()).is_equal(first.slots[seat].display_name())


## Play's lobby asks how many maps rather than which arena, and says its length is per map. Quick
## play's asks which arena and no number of maps.
func test_play_asks_how_many_maps_and_quick_play_which_arena() -> void:
	Game.lobby_for = Game.LobbyFor.PLAY
	var playing: Control = auto_free(LOBBY_SCENE.instantiate())
	add_child(playing)
	var options: MatchOptions = playing.options
	assert_bool(options.is_grand_prix()).is_true()
	assert_bool(options._maps_row.visible).is_true()
	assert_bool(options._arena_row.visible).is_false()
	assert_str(options._length_label.text).is_equal("Time per map")
	options.maps_option.selected = MatchOptions.MAPS.find(5)
	assert_int(playing.config().rounds).is_equal(5)
	Game.lobby_for = Game.LobbyFor.QUICK_PLAY
	var quick: Control = auto_free(LOBBY_SCENE.instantiate())
	add_child(quick)
	assert_bool(quick.options.is_grand_prix()).is_false()
	assert_bool(quick.options._maps_row.visible).is_false()
	assert_bool(quick.options._arena_row.visible).is_true()
	assert_int(quick.config().rounds).is_equal(0)


## A finished map in the middle of a run: the podium leads to the next map and nowhere else.
func _podium_after(round: int, rounds: int) -> ResultsScreen:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.overtime = false
	rules.round = round
	rules.rounds = rounds
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await runner.simulate_frames(10, 17)
	match_node.hud._podium_wait = 0.0
	await runner.simulate_frames(2, 17)
	return match_node.hud._results


func test_the_podium_in_the_middle_of_a_run_only_goes_on() -> void:
	var screen := await _podium_after(1, 3)
	assert_bool(screen._next.visible).is_true()
	assert_bool(screen._rematch.visible).is_false()
	assert_bool(screen._quit.visible).is_false()
	assert_bool(screen._lobby.visible).is_false()
	assert_object(screen.get_viewport().gui_get_focus_owner()).is_equal(screen._next)
	assert_str(screen._caption.text).contains("map 1 of 3")


## And the last map ends the run: no next map and no rematch, back to the lobby or the title.
func test_the_podium_after_the_last_map_ends_the_run() -> void:
	var screen := await _podium_after(3, 3)
	assert_bool(screen._next.visible).is_false()
	assert_bool(screen._rematch.visible).is_false()
	assert_bool(screen._lobby.visible).is_true()
	assert_bool(screen._quit.visible).is_true()


## A single map is as it was: rematch or the title, and no talk of maps.
func test_a_single_map_podium_is_as_it_was() -> void:
	var screen := await _podium_after(0, 0)
	assert_bool(screen._next.visible).is_false()
	assert_bool(screen._rematch.visible).is_true()
	assert_bool(screen._quit.visible).is_true()
	assert_bool(screen._caption.visible).is_false()
