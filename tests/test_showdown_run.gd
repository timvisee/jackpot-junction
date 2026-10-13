extends GdUnitTestSuite
## The run's way through a showdown, GAME.md 9.7a: the last map's podium says who is level and
## offers Tie-breaker, the showdown's whistle settles the run and goes straight to the party, and
## the final standings say what settled each tie. A tie settled otherwise says how, 9.7a and 3.8.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const PATH := "user://test_showdown_run.cfg"
## A port of this suite's own, so it can run beside the other network suites.
const PORT := 7883

var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH


func after_test() -> void:
	Audio.hush_music(false)
	Settings.remove_files(PATH)
	Game.grand_prix = null
	Game.pending_config = null
	Game.settings = _settings_were


func _seat(index: int, banked := 0) -> PlayerSlot:
	var slot := PlayerSlot.new(index, KartInput.new(), index)
	slot.banked = banked
	return slot


## A run of two maps with the first scored: seat 1 won it. Whoever wins the second is level with
## seat 1 on 17, unless [param level] is false, when seat 1 wins both.
func _run_of_two(level := true) -> GrandPrix:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	Game.grand_prix = GrandPrix.start(2, rng)
	var first: Array[PlayerSlot] = [_seat(1, 50), _seat(0, 40)]
	Game.grand_prix.score(first)
	Game.grand_prix.advance()
	if not level:
		Game.grand_prix.points[1][0] = 12
	return Game.grand_prix


## A map of the run, played to its whistle with [param fortunes] banked, scored as the match scene
## scores it, and its podium up.
func _podium(fortunes: Array, map := &"vault") -> ResultsScreen:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.overtime = false
	rules.map = map
	Game.grand_prix.label(rules)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = ArenaMaps.layout_for(rules)
	match_node.with_hud = true
	match_node.offer_size = 0
	Showdown.dress(match_node)
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(12, 17)
	for seat: int in fortunes.size():
		match_node.slots[seat].banked = fortunes[seat]
	match_node.time_left = 0.02
	await runner.simulate_frames(10, 17)
	Game.grand_prix.score(match_node.standings())
	match_node.hud._podium_wait = 0.0
	await runner.simulate_frames(2, 17)
	return match_node.hud._results


func _texts(node: Node) -> PackedStringArray:
	var texts: PackedStringArray = []
	for label: Node in node.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	return texts


## The chips on a page of the bill named Tie, as "title value".
func _ties(page: SlipPage) -> PackedStringArray:
	var said: PackedStringArray = []
	for chip: Node in page.rows.find_children("Tie", "", true, false):
		said.append(" ".join(_texts(chip)))
	return said


## Level at the end of the run: the last map's podium says who, and Tie-breaker is its way on in
## the place of Continue.
func test_the_last_podium_offers_the_tie_breaker() -> void:
	_run_of_two()
	var screen := await _podium([100, 50])
	assert_bool(Game.grand_prix.needs_showdown()).is_true()
	assert_bool(screen._tie.visible).is_true()
	assert_bool(screen._continue.visible).is_false()
	assert_str(screen._tie.text).is_equal("Tie-breaker")
	var names := screen.match_node.slots.map(
		func(slot: PlayerSlot) -> String: return slot.display_name()
	)
	assert_str(screen.map_page.note.text).is_equal(
		"Level on points: %s and %s (17). A showdown settles it." % names
	)
	assert_object(screen._primary()).is_same(screen._tie)


## Nobody level, or the switch off: Continue, as ever, and nothing said about a tie.
func test_no_tie_or_no_switch_is_the_party_as_ever() -> void:
	_run_of_two(false)
	var screen := await _podium([100, 50])
	assert_bool(screen._tie.visible).is_false()
	assert_bool(screen._continue.visible).is_true()
	assert_bool(screen.map_page.note.visible).is_false()
	_run_of_two()
	Game.grand_prix.tie_breaker = false
	screen = await _podium([100, 50])
	assert_bool(screen._tie.visible).is_false()
	assert_bool(screen._continue.visible).is_true()


## Tie-breaker goes on to the showdown, as Next map goes on to a map: the level seats in it, the
## room the run ended in, no jokers carried into it, and only the once.
func test_the_tie_breaker_starts_the_showdown_in_the_last_room() -> void:
	var run := _run_of_two()
	var last: Array[PlayerSlot] = [_seat(0, 100), _seat(1, 50)]
	run.score(last)
	run.carried = {0: [&"payday"]}
	Game.pending_config = MatchConfig.new()
	var config := Game.next_map_config()
	assert_object(config).is_not_null()
	assert_str(String(config.map)).is_equal(String(ArenaMaps.SHOWDOWN))
	assert_array(run.fighters).is_equal([0, 1])
	assert_bool(run.carried.is_empty()).is_true()
	var rules := config.rules(RULES)
	run.label(rules)
	assert_bool(rules.showdown()).is_true()
	assert_array(Array(rules.fighters)).is_equal([0, 1])
	assert_str(String(rules.room)).is_equal(String(ArenaMaps.layout(run.playlist[1]).room.id))
	assert_int(rules.round).is_equal(2)
	assert_int(rules.rounds).is_equal(2)
	# Once: the run has its showdown now.
	assert_object(Game.next_map_config()).is_null()


## The showdown's whistle settles the run and goes straight on to the party, with no slip of its
## own; the final standings are the bill's first page, each row in the tie saying where the
## showdown put it.
func test_the_showdown_settles_the_run_and_goes_to_the_party() -> void:
	var run := _run_of_two()
	var last: Array[PlayerSlot] = [_seat(0, 100), _seat(1, 50)]
	run.score(last)
	run.begin_showdown()
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.map = ArenaMaps.SHOWDOWN
	run.label(rules)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = ArenaMaps.layout_for(rules)
	match_node.with_hud = true
	match_node.offer_size = 0
	Showdown.dress(match_node)
	var runner := scene_runner(match_node)
	match_node.start([PlayerInput.new(), KartInput.new()] as Array[KartInput], 5)
	await runner.simulate_frames(20, 17)
	match_node.kart_of(1).die(&"test", 0)
	await runner.simulate_frames(4, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	var screen: ResultsScreen = match_node.hud._results
	# A client hears the whistle before the host's word on the run: it waits for it.
	match_node.hud._podium_wait = 0.0
	await runner.simulate_frames(2, 17)
	assert_bool(screen._awaiting_showdown).is_true()
	assert_object(match_node.finale).is_null()
	# As the match scene does at the host's whistle.
	run.settle(Showdown.lasted(match_node))
	Events.grand_prix_scored.emit(run.to_wire())
	await runner.simulate_frames(2, 17)
	assert_object(match_node.finale).is_not_null()
	assert_bool(screen.visible).is_false()
	match_node.finale.skip()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(screen.visible).is_true()
	assert_int(screen.bill.page_count()).is_equal(1)
	assert_int(screen.bill.page).is_equal(0)
	assert_int(run.standings(match_node.slots)[0].index).is_equal(0)
	assert_array(_ties(screen.run_page)).contains_exactly(["Showdown 1st", "Showdown 2nd"])
	assert_bool(screen._lobby.visible).is_true()
	assert_bool(screen._tie.visible).is_false()


## The run is counted once it is settled: not on its last map while a showdown is to come, and
## the showdown itself is no map played.
func test_the_run_is_counted_at_its_showdown() -> void:
	var run := _run_of_two()
	var last: Array[PlayerSlot] = [_seat(0, 100), _seat(1, 50)]
	run.score(last)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES.duplicate()
	match_node.with_hud = false
	var runner := scene_runner(match_node)
	match_node.start(
		[PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()] as Array[KartInput], 3
	)
	await runner.simulate_frames(2, 17)
	var record := MatchRecord.add_to(match_node)
	record.record()
	var profile := Game.settings.profile
	assert_float(LifetimeStats.value_of(profile, &"maps")).is_equal(1.0)
	assert_float(LifetimeStats.value_of(profile, &"grand_prix")).is_equal(0.0)
	# The showdown, which seat 0 wins.
	run.begin_showdown()
	var lasted: Dictionary[int, int] = {0: GrandPrix.STOOD + 2, 1: 400}
	run.settle(lasted)
	var showdown: Match = auto_free(MATCH_SCENE.instantiate())
	showdown.rules = RULES.duplicate()
	showdown.rules.map = ArenaMaps.SHOWDOWN
	run.label(showdown.rules)
	showdown.arena_layout = ArenaMaps.layout_for(showdown.rules)
	showdown.with_hud = false
	Showdown.dress(showdown)
	runner = scene_runner(showdown)
	showdown.start(
		[PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()] as Array[KartInput], 3
	)
	await runner.simulate_frames(2, 17)
	showdown.slots[0].kills = 1
	record = MatchRecord.add_to(showdown)
	record.record()
	assert_float(LifetimeStats.value_of(profile, &"maps")).is_equal(1.0)
	assert_float(LifetimeStats.value_of(profile, &"kills")).is_equal(0.0)
	assert_float(LifetimeStats.value_of(profile, &"grand_prix")).is_equal(1.0)
	assert_float(LifetimeStats.value_of(profile, &"grand_prix_won")).is_equal(1.0)


## A map's lines level on banked say what put them in order: the kills, then the deaths.
func test_a_map_tie_says_what_settled_it() -> void:
	var a := _seat(0, 300)
	var b := _seat(1, 300)
	var c := _seat(2, 100)
	a.kills = 5
	b.kills = 3
	var standings: Array[PlayerSlot] = [a, b, c]
	assert_array(TieWords.of_map(a, standings)).is_equal(["Tie", "5 kills"])
	assert_array(TieWords.of_map(b, standings)).is_equal(["Tie", "3 kills"])
	assert_bool(TieWords.of_map(c, standings).is_empty()).is_true()
	b.kills = 5
	a.deaths = 1
	b.deaths = 2
	assert_array(TieWords.of_map(a, standings)).is_equal(["Tie", "1 death"])
	assert_array(TieWords.of_map(b, standings)).is_equal(["Tie", "2 deaths"])
	b.deaths = 1
	assert_array(TieWords.of_map(a, standings)).is_equal(["Tie", "seat order"])


## A run's rows level on points say what put them in order when no showdown did: maps won, then
## banked over the run; and where a showdown left two level, that as well.
func test_a_run_tie_says_what_settled_it() -> void:
	var run := GrandPrix.new()
	run.playlist = [&"vault", &"crossfire"]
	run.points = {0: [10, 7], 1: [7, 10], 2: [5, 5], 3: [5, 5], 4: [3, 3]}
	run.places = {0: [1, 2], 1: [2, 1], 2: [3, 3], 3: [4, 3], 4: [5, 5]}
	run.banked = {0: [900, 340], 1: [500, 700], 2: [100, 0], 3: [50, 0], 4: [0, 0]}
	var slots: Array[PlayerSlot] = []
	for i: int in 5:
		slots.append(_seat(i))
	# 0 and 1 both won a map: their banked over the run tells them apart.
	assert_array(TieWords.of_run(0, run, slots)).is_equal(["Tie", "1,240 banked"])
	assert_array(TieWords.of_run(1, run, slots)).is_equal(["Tie", "1,200 banked"])
	assert_array(TieWords.of_run(4, run, slots)).is_empty()
	assert_array(TieWords.of_run(2, run, slots)).is_equal(["Tie", "100 banked"])
	run.places[3] = [4, 1]
	assert_array(TieWords.of_run(3, run, slots)).is_equal(["Tie", "1 map won"])
	assert_array(TieWords.of_run(2, run, slots)).is_equal(["Tie", "0 maps won"])
	# A showdown settles 0 and 1 outright, and leaves 2 and 3 out together.
	var lasted: Dictionary[int, int] = {0: GrandPrix.STOOD + 2, 1: 500, 2: 300, 3: 300}
	run.settle(lasted)
	assert_array(TieWords.of_run(0, run, slots)).is_equal(["Showdown", "1st"])
	assert_array(TieWords.of_run(1, run, slots)).is_equal(["Showdown", "2nd"])
	assert_array(TieWords.of_run(3, run, slots)).is_equal(["Showdown", "1st · 1 map won"])
	assert_array(TieWords.of_run(2, run, slots)).is_equal(["Showdown", "2nd · 0 maps won"])


## Online, GAME.md 9.7a and 10.3: the karts in it and the room ride the rules over a real socket,
## and a client sitting it out, and the order the karts go out in, ride the snapshots.
func test_a_client_is_told_the_showdown() -> void:
	var host_root: Node = auto_free(Node.new())
	host_root.name = "HostRoot"
	add_child(host_root)
	var client_root: Node = auto_free(Node.new())
	client_root.name = "ClientRoot"
	add_child(client_root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), host_root.get_path())
	get_tree().set_multiplayer(SceneMultiplayer.new(), client_root.get_path())
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.map = ArenaMaps.SHOWDOWN
	rules.fighters = PackedInt32Array([0, 2])
	rules.room = &"the_yard"
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.name = "Match"
	host.rules = rules
	host.arena_layout = ArenaMaps.layout_for(rules)
	host.with_hud = false
	host.offer_size = 0
	Showdown.dress(host)
	host_root.add_child(host)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	inputs.append(KartInput.new())
	host.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
	host_session.match_node = host
	host_root.add_child(host_session)
	assert_int(host_session.host(PORT)).is_equal(OK)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.name = "Match"
	client.rules = RULES.duplicate()
	client.with_hud = false
	client_root.add_child(client)
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client
	client_session.local_input = KartInput.new()
	client_root.add_child(client_session)
	# As the match scene does: nothing is built until the host has said which room this is.
	client_session.rules_applied.connect(
		func() -> void:
			client.arena_layout = ArenaMaps.layout_for(client.rules)
			Showdown.dress(client)
			client.start_puppet(),
		CONNECT_ONE_SHOT
	)
	assert_int(client_session.join("127.0.0.1", PORT)).is_equal(OK)
	var seated := await _wait_until(func() -> bool: return client.slots.size() == 3, 12000)
	assert_bool(seated).override_failure_message("never sent the match").is_true()
	assert_bool(client.rules.showdown()).is_true()
	assert_array(Array(client.rules.fighters)).is_equal([0, 2])
	assert_str(client.arena.room.id).is_equal("the_yard")
	# The client took over the bot in the seat that sits it out.
	assert_int(client_session.local_slot).is_equal(1)
	assert_bool(client.slots[1].benched).is_true()
	await _wait_until(func() -> bool: return host.state == Match.State.PLAYING, 6000)
	host.kart_of(2).die(&"test", 0)
	var told := await _wait_until(func() -> bool: return client.state == Match.State.RESULTS, 6000)
	assert_bool(told).override_failure_message("never heard the whistle").is_true()
	assert_int(client.slots[2].out_at).is_equal(host.slots[2].out_at)
	assert_int(client.standings()[0].index).is_equal(0)
	get_tree().set_multiplayer(null, host_root.get_path())
	get_tree().set_multiplayer(null, client_root.get_path())


## Waits for [param condition], up to [param max_millis] of real time.
func _wait_until(condition: Callable, max_millis: int) -> bool:
	var waited := 0
	while not condition.call() and waited < max_millis:
		await await_millis(25)
		waited += 25
	return condition.call()


## A showdown and the run it settled, recorded at its whistle for this machine's player in seat 0.
func _record_showdown(lasted: Dictionary[int, int]) -> Profile:
	var run := _run_of_two()
	var last: Array[PlayerSlot] = [_seat(0, 100), _seat(1, 50)]
	run.score(last)
	run.begin_showdown()
	run.settle(lasted)
	var showdown: Match = auto_free(MATCH_SCENE.instantiate())
	showdown.rules = RULES.duplicate()
	showdown.rules.map = ArenaMaps.SHOWDOWN
	run.label(showdown.rules)
	showdown.arena_layout = ArenaMaps.layout_for(showdown.rules)
	showdown.with_hud = false
	Showdown.dress(showdown)
	var runner := scene_runner(showdown)
	showdown.start(
		[PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()] as Array[KartInput], 3
	)
	await runner.simulate_frames(2, 17)
	AchievementRecord.anywhere = true
	AchievementRecord.add_to(showdown, false)
	MatchRecord.add_to(showdown).record()
	AchievementRecord.anywhere = false
	return Game.settings.profile


## Winner Takes All, GAME.md 8.10: a Grand Prix won in its showdown, and not one lost in it.
func test_winner_takes_all() -> void:
	var lost: Dictionary[int, int] = {0: 400, 1: GrandPrix.STOOD + 1}
	var profile := await _record_showdown(lost)
	assert_float(LifetimeStats.value_of(profile, &"grand_prix_won")).is_equal(0.0)
	assert_bool(profile.achievements.has(&"winner_takes_all")).is_false()
	var won: Dictionary[int, int] = {0: GrandPrix.STOOD + 1, 1: 400}
	profile = await _record_showdown(won)
	assert_bool(profile.achievements.has(&"winner_takes_all")).is_true()
