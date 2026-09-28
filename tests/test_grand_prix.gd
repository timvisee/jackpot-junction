extends GdUnitTestSuite
## Play, GAME.md 9.7: a Grand Prix of several maps, played one after another by the same people.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

## The player's own settings, put aside so a lobby opened here starts from the defaults rather
## than from whatever the player last chose, and nothing chosen here is ever theirs.
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_grand_prix.cfg"


func after_test() -> void:
	Audio.hush_music(false)
	Game.grand_prix = null
	Game.pending_config = null
	Game.settings = _settings_were


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


## Who went up and who went down on the last map: the places now held against the places before
## it, the same tie-breaks both times.
func test_the_run_knows_who_moved_on_the_last_map() -> void:
	var run := GrandPrix.start(2, _rng(31))
	var a := _seat(0, 0)
	var b := _seat(1, 0)
	var c := _seat(2, 0)
	var seats: Array[PlayerSlot] = [a, b, c]
	var first: Array[PlayerSlot] = [a, b, c]
	run.score(first)
	# One map in: nobody has moved from anywhere yet.
	assert_int(run.moved(c.index, seats)).is_equal(0)
	run.advance()
	var second: Array[PlayerSlot] = [c, b, a]
	run.score(second)
	# a 15, c 15 and ahead of b on 14 by a map won each and the seat order after that.
	assert_int(run.moved(a.index, seats)).is_equal(0)
	assert_int(run.moved(c.index, seats)).is_equal(1)
	assert_int(run.moved(b.index, seats)).is_equal(-1)
	assert_array(run.standings(seats, 1)).is_equal([a, b, c])


## The run's podium marks who moved: an arrow up for a climb, down for a fall, nothing for neither.
## Here the first seat wins the last map by enough to go from second to first, and the second
## seat falls the other way.
func test_the_grand_prix_podium_shows_who_moved() -> void:
	_run_at(2, 2)
	var screen := await _podium_after(2, 2, GrandPrix.Keep.RANDOM, [100, 0])
	await _to_the_run(screen)
	var run := Game.grand_prix
	assert_int(run.moved(0, screen.match_node.slots)).is_equal(1)
	assert_int(run.moved(1, screen.match_node.slots)).is_equal(-1)
	var ups := 0
	var downs := 0
	for arrow: Node in screen.find_children("*", "RankArrow", true, false):
		if (arrow as RankArrow).up:
			ups += 1
		else:
			downs += 1
	assert_int(ups).is_equal(1)
	assert_int(downs).is_equal(1)


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


## A seat on a started match holding [param count] jokers off the catalog, from [param first].
func _holding(match_node: Match, seat: int, first: int, count: int) -> Array[StringName]:
	var given: Array[StringName] = []
	var catalog := match_node.joker_catalog.jokers
	for i: int in count:
		var joker: Joker = catalog[(first + i) % catalog.size()]
		match_node.slots[seat].kart.jokers.add(joker)
		given.append(joker.id)
	return given


## Each way of keeping jokers between maps keeps what it says: none, one at random, all, or, for
## a player choosing, the jokers to choose from on the next map. A bot choosing keeps one at
## random, having nobody to choose for it.
func test_each_way_of_keeping_jokers_keeps_what_it_says() -> void:
	var run := GrandPrix.start(3, _rng(21))
	var match_node := _map_of(run, 5)
	var mine := _holding(match_node, 0, 0, 3)
	var bots := _holding(match_node, 1, 4, 2)
	for keep: GrandPrix.Keep in [
		GrandPrix.Keep.NONE, GrandPrix.Keep.CHOOSE, GrandPrix.Keep.RANDOM, GrandPrix.Keep.ALL
	]:
		run.keep = keep
		run.hold_over(match_node.slots, _rng(22))
		var kept_mine: Array = run.carried[0]
		var kept_bot: Array = run.carried[1]
		assert_bool(run.has_choices()).is_equal(keep == GrandPrix.Keep.CHOOSE)
		match keep:
			GrandPrix.Keep.NONE:
				assert_array(kept_mine).is_empty()
				assert_array(kept_bot).is_empty()
			GrandPrix.Keep.CHOOSE:
				assert_array(kept_mine).is_empty()
				assert_array(run.choosing[0]).contains_exactly(mine)
				assert_bool(run.choosing.has(1)).is_false()
				assert_int(kept_bot.size()).is_equal(1)
				assert_bool(bots.has(kept_bot[0])).is_true()
			GrandPrix.Keep.RANDOM:
				assert_int(kept_mine.size()).is_equal(1)
				assert_bool(mine.has(kept_mine[0])).is_true()
			GrandPrix.Keep.ALL:
				assert_array(kept_mine).contains_exactly(mine)
				assert_array(kept_bot).contains_exactly(bots)
	# Nothing held, nothing carried, whatever the rule.
	assert_array(run.carried[2]).is_empty()


## What was carried is in everybody's hands when the next map starts.
func test_the_carried_jokers_are_dealt_into_the_next_map() -> void:
	var run := GrandPrix.start(2, _rng(23))
	var first := _map_of(run, 6)
	var mine := _holding(first, 0, 0, 2)
	run.keep = GrandPrix.Keep.ALL
	run.hold_over(first.slots, _rng(24))
	var second := _map_of(run, 7)
	run.deal_jokers(second)
	assert_array(second.slots[0].kart.jokers.ids()).contains_exactly(mine)
	assert_int(second.slots[1].kart.jokers.count()).is_equal(0)


## A Grand Prix has the row for it, and a quick match does not, having no next map.
func test_the_joker_rule_is_a_grand_prix_row() -> void:
	var lobby := _lobby(true)
	assert_bool(lobby.options._jokers_row.visible).is_true()
	# Picking one to keep is the choice to start with.
	assert_int(lobby.options.jokers_option.selected).is_equal(GrandPrix.Keep.CHOOSE)
	assert_int(Settings.new().grand_prix_jokers).is_equal(GrandPrix.Keep.CHOOSE)
	lobby.options.jokers_option.selected = GrandPrix.Keep.ALL
	assert_int(_config(lobby).keep_jokers).is_equal(GrandPrix.Keep.ALL)
	_choose(lobby, false)
	assert_bool(lobby.options._jokers_row.visible).is_false()


## The next map of a run, started the way the match scene starts it: held on the grid while
## anybody is choosing which joker to keep, then begun.
func _next_map_of(run: GrandPrix, seed: int) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES.duplicate()
	match_node.rules.countdown = 0.1
	match_node.with_hud = false
	match_node.offer_size = 0
	match_node.bot_traits = run.bot_table(match_node.bot_traits)
	add_child(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), BotInput.new()]
	match_node.hold_start = run.has_choices()
	match_node.start(inputs, seed)
	run.deal_jokers(match_node)
	match_node.begin_from_lobby()
	return match_node


## GAME.md 9.7: choosing which joker to keep is done as the next map starts, on the joker pick,
## with the jokers the player held at the whistle. The lamps wait for it, and it cannot be skipped.
func test_choosing_which_joker_to_keep_opens_the_next_map() -> void:
	var run := GrandPrix.start(2, _rng(25))
	run.keep = GrandPrix.Keep.CHOOSE
	var first := _map_of(run, 8)
	var mine := _holding(first, 0, 0, 2)
	_holding(first, 1, 3, 2)
	run.hold_over(first.slots, _rng(26))
	var second := _next_map_of(run, 9)
	var offer := second.slots[0].offer
	assert_object(offer).is_not_null()
	assert_bool(offer.keeping).is_true()
	assert_array(_ids(offer.choices)).contains_exactly(mine)
	assert_int(second.slots[0].kart.jokers.count()).is_equal(0)
	# The bot kept one of its two there and then.
	assert_int(second.slots[1].kart.jokers.count()).is_equal(1)
	await await_millis(300)
	assert_int(second.state).is_equal(Match.State.LOBBY)
	assert_bool(second.kart_of(0).frozen).is_true()
	offer.skip()
	assert_bool(offer.is_done()).is_false()
	offer.take(1)
	await await_millis(100)
	assert_int(second.state).is_not_equal(Match.State.LOBBY)
	assert_array(second.slots[0].kart.jokers.ids()).contains_exactly([mine[1]])
	assert_object(second.slots[0].offer).is_null()


## Nobody holds up the lamps for ever: a pick still open at the deadline keeps one at random.
func test_a_pick_left_open_keeps_a_joker_at_random() -> void:
	var run := GrandPrix.start(2, _rng(27))
	run.keep = GrandPrix.Keep.CHOOSE
	var first := _map_of(run, 10)
	var mine := _holding(first, 0, 0, 3)
	run.hold_over(first.slots, _rng(28))
	var second := _next_map_of(run, 11)
	second.slots[0].offer.keep_left = 0.05
	await await_millis(300)
	assert_int(second.state).is_not_equal(Match.State.LOBBY)
	var kept := second.slots[0].kart.jokers.ids()
	assert_int(kept.size()).is_equal(1)
	assert_bool(mine.has(kept[0])).is_true()


## A choice of one is not a choice: a player holding one joker keeps it without being asked.
func test_one_joker_is_kept_without_asking() -> void:
	var run := GrandPrix.start(2, _rng(29))
	run.keep = GrandPrix.Keep.CHOOSE
	var first := _map_of(run, 12)
	var mine := _holding(first, 0, 0, 1)
	run.hold_over(first.slots, _rng(30))
	assert_bool(run.has_choices()).is_false()
	var second := _next_map_of(run, 13)
	assert_object(second.slots[0].offer).is_null()
	assert_array(second.slots[0].kart.jokers.ids()).contains_exactly(mine)
	assert_int(second.state).is_equal(Match.State.COUNTDOWN)


## The podium says when the choosing happens, and offers nothing to choose on it.
func test_the_podium_says_the_choosing_is_on_the_next_map() -> void:
	_run_at(1, 3)
	Game.grand_prix.keep = GrandPrix.Keep.CHOOSE
	var screen := await _podium_after(1, 3, GrandPrix.Keep.CHOOSE)
	_holding(screen.match_node, 0, 1, 2)
	screen.fill_in()
	for node: Node in screen.find_children("*", "Button", true, false):
		assert_bool((node as Button).toggle_mode).is_false()
	assert_str(screen._keep_note.text).contains("next map starts")


func _ids(jokers: Array[Joker]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for joker: Joker in jokers:
		ids.append(joker.id)
	return ids


## The match settings over the lobby room, GAME.md 9.6, opened on [param grand_prix] as their first
## row's answer.
func _lobby(grand_prix: bool) -> HostSettings:
	var pane: HostSettings = auto_free(HostSettings.add_to(self, true))
	_choose(pane, grand_prix)
	return pane


## A Grand Prix or a quick match chosen, the way a player choosing it does: its button pressed.
func _choose(pane: HostSettings, grand_prix: bool) -> void:
	pane.options.mode_picker.button(grand_prix).pressed.emit()


## What the rows describe, as the room builds its match from them.
func _config(pane: HostSettings) -> MatchConfig:
	var config := MatchConfig.from_settings(Game.settings)
	pane.options.apply_to(config)
	return config


## Play's lobby asks first whether it is a Grand Prix or a quick match, with a button each. A
## Grand Prix asks how many maps rather than which arena, and says its length is per map; a quick
## match asks which arena and no number of maps.
func test_the_lobby_asks_grand_prix_or_quick_match_first() -> void:
	var lobby := _lobby(true)
	var options: MatchOptions = lobby.options
	assert_bool(options.is_grand_prix()).is_true()
	assert_bool(options._maps_row.visible).is_true()
	assert_bool(options._arena_row.visible).is_false()
	assert_str(options._length_label.text).is_equal("Time per map")
	options.maps_option.selected = MatchOptions.MAPS.find(5)
	assert_int(_config(lobby).rounds).is_equal(5)
	_choose(lobby, false)
	assert_bool(options.is_grand_prix()).is_false()
	assert_bool(options.mode_picker.button(false).button_pressed).is_true()
	assert_bool(options.mode_picker.button(true).button_pressed).is_false()
	assert_bool(options._maps_row.visible).is_false()
	assert_bool(options._arena_row.visible).is_true()
	assert_str(options._length_label.text).is_equal("Match length")
	assert_int(_config(lobby).rounds).is_equal(0)


## A finished map in the middle of a run: the podium leads to the next map and nowhere else.
## Scored as the match scene would score it, when there is a run to score it in.
func _podium_after(
	round: int, rounds: int, keep := GrandPrix.Keep.RANDOM, fortunes: Array = []
) -> ResultsScreen:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.overtime = false
	rules.round = round
	rules.rounds = rounds
	rules.keep_jokers = keep
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(12, 17)
	for seat: int in fortunes.size():
		match_node.slots[seat].banked = fortunes[seat]
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
	await _to_the_run(screen)
	assert_str(screen._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)
	var run := Game.grand_prix
	var ranked := run.standings(screen.match_node.slots)
	var texts := _texts(screen)
	assert_bool(texts.has("%d pts" % run.total(ranked[0].index))).is_true()
	for map: StringName in run.playlist:
		assert_bool(texts.has(ArenaMaps.NAMES[ArenaMaps.index_of(map)])).is_true()
	assert_bool(run.total(ranked[0].index) >= run.total(ranked[1].index)).is_true()


## Grand Prix results pressed on the last map's podium, the way a player presses it: the finale in
## the room comes first, and is skipped here the way a player skips it, straight to the standings.
func _to_the_run(screen: ResultsScreen) -> void:
	screen._standings.pressed.emit()
	var finale := screen.match_node.finale
	if finale != null:
		finale.skip()
		# The frame's signal comes before the finale's own turn in it.
		await await_idle_frame()
		await await_idle_frame()


## GAME.md 9.7: after the last map, Grand Prix results first puts up a party in a room of its own.
## The top of the run floats over a podium on a dance floor, the arena is hidden, the room opens
## hushed and drops to the top of its meter, and a camera of its own flies in onto the podium; the
## standings go up once it has arrived and held there.
func test_the_end_of_a_run_is_a_party_on_a_podium() -> void:
	_run_at(2, 2)
	var screen := await _podium_after(2, 2)
	var match_node := screen.match_node
	var champion := Game.grand_prix.standings(match_node.slots)[0]
	screen._standings.pressed.emit()
	var finale := match_node.finale
	assert_object(finale).is_not_null()
	assert_bool(screen.visible).is_false()
	assert_int(finale._karts.size()).is_equal(match_node.slots.size())
	assert_str(finale._champion.text).is_equal(champion.display_name())
	assert_object(finale._champion.get_parent().get_parent()).is_instanceof(Billboard)
	# A room of its own: the arena the map was played in and everything in it goes for it.
	assert_bool(match_node.arena.visible).is_false()
	assert_bool(match_node.kart_of(0).visible).is_false()
	assert_bool(match_node.hud._scoreboard.visible).is_false()
	assert_float(finale.global_position.distance_to(match_node.arena.global_position)).is_greater(
		100.0
	)
	assert_bool(finale._camera.is_current()).is_true()
	# It opens hushed, on a meter already at the top: the music muffled, the house still, one light.
	assert_int(match_node.intensity.level).is_equal(MatchIntensity.LEVELS)
	assert_int(finale.crowd.level).is_equal(MatchIntensity.LEVELS)
	assert_bool(finale.has_dropped()).is_false()
	assert_bool(Audio.is_music_hushed()).is_true()
	assert_bool(finale.crowd.still).is_true()
	assert_int(finale.disco.level).is_equal(1)
	# The three face where the camera ends up, rather than turn.
	var facing: Array[float] = []
	for kart: Node3D in finale._karts:
		var nose := -kart.global_basis.z
		var shot_at := finale.global_position + GrandPrixFinale.SHOT_FROM - kart.global_position
		var flat := Vector2(shot_at.x, shot_at.z).normalized()
		assert_float(Vector2(nose.x, nose.z).normalized().dot(flat)).is_greater(0.999)
		facing.append(kart.rotation.y)
	# The booth stands on its riser, half again its size, to be seen over the podium.
	var booth: Node3D = finale.crowd.get_node("DjBooth")
	var riser_top := Crowd.TABLE_TOP + GrandPrixFinale.RISER_HEIGHT
	assert_float(booth.position.y).is_equal_approx(riser_top, 0.001)
	assert_float(booth.scale.x).is_equal_approx(GrandPrixFinale.BOOTH_SCALE, 0.001)
	# Still on its way down a second in, with nothing over it yet, and still holding its breath.
	await await_millis(1000)
	assert_bool(screen.visible).is_false()
	assert_bool(finale.has_dropped()).is_false()
	# The rising sound comes in before the drop, with the two smoke machines spitting under it
	# together, and only under it.
	assert_int(finale._smoke.size()).is_equal(2)
	assert_int(_spitting(finale)).is_equal(2 if finale._rising else 0)
	for i: int in 60:
		if finale._rising:
			break
		await await_millis(50)
	assert_bool(finale._rising).is_true()
	assert_bool(finale.has_dropped()).is_false()
	assert_int(_spitting(finale)).is_equal(2)
	var up := false
	for i: int in 150:
		await await_millis(100)
		if screen.visible:
			up = true
			break
	assert_bool(up).override_failure_message("the standings never came up").is_true()
	assert_str(screen._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)
	assert_bool(finale.is_shown()).is_true()
	var shot := finale.global_position + GrandPrixFinale.SHOT_FROM
	assert_float(finale._camera.global_position.distance_to(shot)).is_less(0.05)
	# Dropped long before: the music back, the house dancing, every light on the winner.
	assert_bool(finale.has_dropped()).is_true()
	assert_bool(Audio.is_music_hushed()).is_false()
	assert_bool(finale.crowd.still).is_false()
	assert_int(finale.disco.level).is_equal(MatchIntensity.LEVELS)
	assert_int(_spitting(finale)).is_equal(0)
	# Floating over their steps, still facing the same way.
	for i: int in finale._karts.size():
		var kart := finale._karts[i]
		assert_float(kart.rotation.y).is_equal_approx(facing[i], 0.0001)
		var top := GrandPrixFinale.PLACES[i].y + GrandPrixFinale.BAND_LIFT
		assert_float(kart.position.y).is_greater(top)
	# And the room stays at the top of its meter under the standings.
	await await_millis(600)
	assert_int(match_node.intensity.level).is_equal(MatchIntensity.LEVELS)


## How many of the finale's smoke machines are spitting.
func _spitting(finale: GrandPrixFinale) -> int:
	var count := 0
	for machine: SmokeMachine in finale._smoke:
		if machine.is_spitting():
			count += 1
	return count


## A player who has seen it can skip straight to the standings, and a map in the middle of a run
## has no party at all: the run is not over.
func test_the_party_can_be_skipped_and_only_ends_a_run() -> void:
	_run_at(2, 2)
	var screen := await _podium_after(2, 2)
	screen._standings.pressed.emit()
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	screen.match_node.finale._unhandled_input(accept)
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(screen.visible).is_true()
	assert_str(screen._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)
	# Skipped straight through the drop, so the music is back.
	assert_bool(screen.match_node.finale.has_dropped()).is_true()
	assert_bool(Audio.is_music_hushed()).is_false()
	_run_at(1, 3)
	var early := await _podium_after(1, 3)
	early._standings.pressed.emit()
	assert_object(early.match_node.finale).is_null()
	assert_str(early._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)


## Every label under [param node], for asking what a screen says without walking its boxes.
func _texts(node: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	if node is Label:
		found.append((node as Label).text)
	for child: Node in node.get_children():
		found.append_array(_texts(child))
	return found


func test_the_podium_in_the_middle_of_a_run_only_goes_on() -> void:
	_run_at(1, 3)
	var screen := await _podium_after(1, 3)
	# The map's own podium first, the first of two pages, with one way on: how the run stands.
	assert_str(screen._title.text).is_equal(ResultsScreen.TITLE)
	assert_str(screen._caption.text).contains("map 1 of 3")
	assert_bool(screen._pager.visible).is_true()
	assert_int(screen._pager.page).is_equal(0)
	assert_bool(screen._standings.disabled).is_false()
	assert_bool(screen._map_podium.disabled).is_true()
	# The next map is there from the podium too, for whoever has seen enough.
	assert_bool(screen._next.visible).is_true()
	assert_bool(screen._rematch.visible).is_false()
	assert_bool(screen._quit.visible).is_false()
	assert_bool(screen._lobby.visible).is_false()
	assert_object(screen.get_viewport().gui_get_focus_owner()).is_equal(screen._standings)
	# Then the standings so far, and from them the next map and nowhere else.
	screen._standings.pressed.emit()
	assert_str(screen._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)
	assert_str(screen._caption.text).is_equal("Standings after map 1 of 3")
	assert_int(screen._pager.page).is_equal(1)
	assert_bool(screen._standings.disabled).is_true()
	assert_bool(screen._next.visible).is_true()
	assert_bool(screen._lobby.visible).is_false()
	assert_bool(screen._quit.visible).is_false()
	assert_object(screen.get_viewport().gui_get_focus_owner()).is_equal(screen._next)
	# Nobody is champion of a run that is still going.
	assert_bool(Game.grand_prix.revealed).is_false()
	# And back to the map's podium, and on to the standings again, as often as anybody likes.
	assert_bool(screen._map_podium.disabled).is_false()
	screen._map_podium.pressed.emit()
	assert_str(screen._title.text).is_equal(ResultsScreen.TITLE)
	assert_str(screen._caption.text).contains("map 1 of 3")
	assert_int(screen._pager.page).is_equal(0)
	assert_bool(screen._map_podium.disabled).is_true()
	assert_bool(screen._standings.disabled).is_false()
	assert_bool(screen._next.visible).is_true()
	assert_object(screen.get_viewport().gui_get_focus_owner()).is_equal(screen._standings)
	screen._standings.pressed.emit()
	assert_str(screen._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)
	assert_bool(screen._next.visible).is_true()


## Somebody watching has nothing to press, GAME.md 10.3: a map's podium goes on to how the run
## stands by itself, and a ring beside the host's word counts down to that, so it is no surprise.
func test_a_watchers_podium_counts_down_to_the_standings() -> void:
	_run_at(1, 3)
	var screen := await _podium_after(1, 3)
	screen._process(0.0)
	assert_bool(screen._watcher_ring.visible).is_false()
	var watching := NetSession.new()
	watching.watching = true
	Net.session = watching
	screen._process(ResultsScreen.WATCHER_WAIT * 0.5)
	var ring_up := screen._watcher_ring.visible
	var left := screen._watcher_ring.value
	screen._process(ResultsScreen.WATCHER_WAIT)
	var shown := screen._showing_run
	screen._process(0.0)
	var ring_after := screen._watcher_ring.visible
	# Gone back to the map's podium, the watcher is looking at it, and it stays.
	screen._map_podium.pressed.emit()
	screen._process(ResultsScreen.WATCHER_WAIT * 2.0)
	var stayed := not screen._showing_run and not screen._watcher_ring.visible
	Net.session = null
	watching.free()
	assert_bool(ring_up).is_true()
	assert_float(left).is_equal_approx(0.5, 0.01)
	assert_bool(shown).is_true()
	assert_bool(ring_after).is_false()
	assert_bool(stayed).is_true()


## The standings after a map in the middle of a run replace that map's podium on a screen that is
## already up, and the pane holds all of them rather than keeping the size it measured while the
## map's rows were cleared out, with the run's hanging out of the bottom of it.
func test_the_standings_in_the_middle_of_a_run_fit_their_pane() -> void:
	_run_at(1, 3)
	var screen := await _podium_after(1, 3)
	await await_idle_frame()
	var podium_height := screen.size.y
	assert_float(podium_height).is_equal_approx(screen.get_combined_minimum_size().y, 0.5)
	screen._standings.pressed.emit()
	await await_idle_frame()
	await await_idle_frame()
	assert_float(screen.size.y).is_equal_approx(screen.get_combined_minimum_size().y, 0.5)
	var column: Control = screen.get_child(0)
	assert_float(screen.size.y).is_greater_equal(column.get_combined_minimum_size().y)
	# Still in the middle of the screen, however tall it has become, and never taller than it.
	var middle := screen.position.y + screen.size.y * 0.5
	var screen_middle := screen.get_parent_area_size().y * 0.5
	assert_float(middle).is_equal_approx(screen_middle, 1.0)
	var shown := screen.size.y * screen.scale.y
	assert_float(shown).is_less_equal(screen.get_parent_area_size().y)


## And the last map ends the run: no next map and no rematch, back to the lobby or the title.
func test_the_podium_after_the_last_map_ends_the_run() -> void:
	_run_at(3, 3)
	var screen := await _podium_after(3, 3)
	# The last map's own podium first, with one way on: the run's.
	assert_str(screen._title.text).is_equal(ResultsScreen.TITLE)
	assert_bool(screen._pager.visible).is_true()
	assert_bool(screen._standings.disabled).is_false()
	assert_bool(screen._next.visible).is_false()
	assert_bool(screen._rematch.visible).is_false()
	assert_bool(screen._lobby.visible).is_false()
	assert_bool(screen._quit.visible).is_false()
	assert_object(screen.get_viewport().gui_get_focus_owner()).is_equal(screen._standings)
	# And the run's podium ends it: back to the lobby or the title.
	await _to_the_run(screen)
	assert_str(screen._title.text).is_equal(ResultsScreen.GRAND_PRIX_TITLE)
	# The second page, and the last: the podium it came from has handed over to the party.
	assert_int(screen._pager.page).is_equal(1)
	assert_bool(screen._standings.disabled).is_true()
	assert_bool(screen._map_podium.disabled).is_true()
	assert_bool(screen._lobby.visible).is_true()
	assert_bool(screen._quit.visible).is_true()
	assert_bool(Game.grand_prix.revealed).is_true()


## A single map is as it was: rematch or the title, and no talk of maps.
func test_a_single_map_podium_is_as_it_was() -> void:
	var screen := await _podium_after(0, 0)
	assert_bool(screen._next.visible).is_false()
	assert_bool(screen._pager.visible).is_false()
	assert_bool(screen._rematch.visible).is_true()
	assert_bool(screen._quit.visible).is_true()
	assert_bool(screen._caption.visible).is_false()
