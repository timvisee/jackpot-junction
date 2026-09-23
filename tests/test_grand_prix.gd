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


## A slot standing in for a player, for scoring by hand.
func _seat(index: int, banked: int) -> PlayerSlot:
	var slot := PlayerSlot.new(index, KartInput.new(), index)
	slot.banked = banked
	return slot


## Each map pays by place, best banked first, and only once however often the result is said.
func test_a_map_pays_points_by_place_once() -> void:
	var run := GrandPrix.start(3, _rng(1))
	var standings: Array[PlayerSlot] = [_seat(2, 900), _seat(0, 600), _seat(1, 100), _seat(3, 0)]
	run.score(standings)
	run.score(standings)
	assert_int(run.total(2)).is_equal(GrandPrix.POINTS[0])
	assert_int(run.total(0)).is_equal(GrandPrix.POINTS[1])
	assert_int(run.total(1)).is_equal(GrandPrix.POINTS[2])
	assert_int(run.total(3)).is_equal(GrandPrix.POINTS[3])
	assert_int(run.wins(2)).is_equal(1)
	assert_array(run.places[2]).contains_exactly([1])


## The run is won on points, whatever was banked on any one map: second on every map beats a
## win and two lasts, and beats two players who won a map each.
func test_the_run_is_won_on_points() -> void:
	var run := GrandPrix.start(3, _rng(2))
	var a := _seat(0, 0)
	var b := _seat(1, 0)
	var c := _seat(2, 0)
	var d := _seat(3, 0)
	for order: Array in [[a, b, c, d], [c, b, d, a], [d, b, c, a]]:
		var standings: Array[PlayerSlot] = []
		standings.assign(order)
		run.score(standings)
		run.advance()
	assert_int(run.wins(b.index)).is_equal(0)
	var ranked := run.standings([a, b, c, d] as Array[PlayerSlot])
	assert_int(ranked[0].index).is_equal(b.index)


## Level on points, more map wins is ahead, then more banked over the whole run.
func test_level_on_points_goes_to_wins_then_banked() -> void:
	var run := GrandPrix.new()
	run.playlist = [&"vault", &"crossfire"]
	run.points = {0: [10, 5], 1: [7, 8], 2: [7, 8]}
	run.places = {0: [1, 3], 1: [2, 2], 2: [2, 2]}
	run.banked = {0: [100, 100], 1: [500, 500], 2: [400, 900]}
	var seats: Array[PlayerSlot] = [_seat(1, 0), _seat(2, 0), _seat(0, 0)]
	var ranked := run.standings(seats)
	# All on 15: the one with a win first, then the one who banked more.
	assert_int(ranked[0].index).is_equal(0)
	assert_int(ranked[1].index).is_equal(2)
	assert_int(ranked[2].index).is_equal(1)


## A client is told the run as it stands and draws the same podium from it.
func test_the_run_survives_the_wire() -> void:
	var run := GrandPrix.start(2, _rng(4))
	var standings: Array[PlayerSlot] = [_seat(1, 300), _seat(0, 200)]
	run.score(standings)
	var theirs := GrandPrix.from_wire(run.to_wire())
	assert_array(theirs.playlist).is_equal(run.playlist)
	assert_int(theirs.scored_round).is_equal(0)
	assert_int(theirs.total(1)).is_equal(run.total(1))
	assert_int(theirs.total(0)).is_equal(run.total(0))
	assert_array(theirs.banked[1]).contains_exactly([300])


## A map of a run, played by the match scene to its whistle: the host scores it and says so.
func test_the_match_scene_scores_a_map_at_the_whistle() -> void:
	var config := MatchConfig.new()
	config.bot_count = 1
	config.rounds = 2
	Game.grand_prix = GrandPrix.start(2, _rng(5))
	config.map = Game.grand_prix.current_map()
	Game.pending_config = config
	var said := {"run": {}}
	Events.grand_prix_scored.connect(func(run: Dictionary) -> void: said["run"] = run)
	var scene: Node3D = auto_free(load("res://scenes/match/match_scene.tscn").instantiate())
	add_child(scene)
	await assert_signal(scene).is_emitted("loaded")
	var match_node: Match = scene.get_node("Match")
	assert_int(match_node.rules.round).is_equal(1)
	assert_int(match_node.rules.rounds).is_equal(2)
	match_node._finish()
	await get_tree().process_frame
	assert_int(Game.grand_prix.scored_round).is_equal(0)
	var paid := 0
	for slot: PlayerSlot in match_node.slots:
		paid += Game.grand_prix.total(slot.index)
	assert_int(paid).is_equal(GrandPrix.POINTS[0] + GrandPrix.POINTS[1])
	assert_int((said["run"] as Dictionary).get("scored", -1)).is_equal(0)


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
## Scored as the match scene would score it, when there is a run to score it in.
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
	if Game.grand_prix != null:
		Game.grand_prix.score(match_node.standings())
	match_node.hud._podium_wait = 0.0
	await runner.simulate_frames(2, 17)
	return match_node.hud._results


## A run of [param rounds] maps on its [param round]th, with the maps before it already scored.
func _run_at(round: int, rounds: int) -> void:
	Game.grand_prix = GrandPrix.start(rounds, _rng(9))
	for i: int in round - 1:
		var standings: Array[PlayerSlot] = [_seat(1, 50), _seat(0, 40)]
		Game.grand_prix.score(standings)
		Game.grand_prix.advance()


## In the middle of a run each row says what its place paid and where that leaves them.
func test_the_podium_in_the_middle_of_a_run_says_what_each_place_paid() -> void:
	_run_at(1, 3)
	var screen := await _podium_after(1, 3)
	var texts := _texts(screen)
	assert_bool(texts.has("+%d points" % GrandPrix.POINTS[0])).is_true()
	assert_bool(texts.has("+%d points" % GrandPrix.POINTS[1])).is_true()
	assert_str(screen._title.text).is_equal(ResultsScreen.TITLE)


## After the last map's own podium comes the run's: headed Grand Prix, everybody ranked on points
## over the whole run, and a chip for each map saying where they finished it.
func test_the_podium_after_the_last_map_is_the_grand_prix() -> void:
	_run_at(2, 2)
	var screen := await _podium_after(2, 2)
	# The last map's results come first, with what each place paid, as on every map.
	assert_str(screen._title.text).is_equal(ResultsScreen.TITLE)
	assert_bool(_texts(screen).has("+%d points" % GrandPrix.POINTS[0])).is_true()
	screen._standings.pressed.emit()
	assert_str(screen._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)
	var run := Game.grand_prix
	var ranked := run.standings(screen.match_node.slots)
	var texts := _texts(screen)
	assert_bool(texts.has("%d pts" % run.total(ranked[0].index))).is_true()
	for map: StringName in run.playlist:
		assert_bool(texts.has(ArenaMaps.NAMES[ArenaMaps.index_of(map)])).is_true()
	assert_bool(run.total(ranked[0].index) >= run.total(ranked[1].index)).is_true()


## Every label under [param node], for asking what a screen says without walking its boxes.
func _texts(node: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	if node is Label:
		found.append((node as Label).text)
	for child: Node in node.get_children():
		found.append_array(_texts(child))
	return found


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
	_run_at(3, 3)
	var screen := await _podium_after(3, 3)
	# The last map's own podium first, with one way on: the run's.
	assert_str(screen._title.text).is_equal(ResultsScreen.TITLE)
	assert_bool(screen._standings.visible).is_true()
	assert_bool(screen._next.visible).is_false()
	assert_bool(screen._rematch.visible).is_false()
	assert_bool(screen._lobby.visible).is_false()
	assert_bool(screen._quit.visible).is_false()
	assert_object(screen.get_viewport().gui_get_focus_owner()).is_equal(screen._standings)
	# And the run's podium ends it: back to the lobby or the title.
	screen._standings.pressed.emit()
	assert_str(screen._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)
	assert_bool(screen._standings.visible).is_false()
	assert_bool(screen._lobby.visible).is_true()
	assert_bool(screen._quit.visible).is_true()
	assert_bool(Game.grand_prix.revealed).is_true()


## A single map is as it was: rematch or the title, and no talk of maps.
func test_a_single_map_podium_is_as_it_was() -> void:
	var screen := await _podium_after(0, 0)
	assert_bool(screen._next.visible).is_false()
	assert_bool(screen._rematch.visible).is_true()
	assert_bool(screen._quit.visible).is_true()
	assert_bool(screen._caption.visible).is_false()
