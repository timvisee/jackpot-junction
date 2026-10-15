extends GdUnitTestSuite
## The payout slip of the demo for a booth goes on by itself, GAME.md 9.8: the podium, the run's
## standings and the next map; after the last map the party and the final standings, and back to
## the title; a gold ring emptying beside the way on it is about to take.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _settings_were: Settings
## The ways on pressed, by their words, in place of where they would have gone.
var _pressed: Array[String] = []


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = ""
	Demo.on = true
	Demo.set_up(Game.settings, false)
	_pressed.clear()


func after_test() -> void:
	Demo.on = false
	Audio.hush_music(false)
	Game.grand_prix = null
	Game.pending_config = null
	Game.settings = _settings_were


func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


## A run of [param rounds] maps on its [param round]th, the maps before it already scored.
func _run_at(round: int, rounds: int) -> void:
	Game.grand_prix = GrandPrix.start(rounds, _rng(9))
	for i: int in round - 1:
		var standings: Array[PlayerSlot] = []
		Game.grand_prix.score(standings)
		Game.grand_prix.advance()


## The slip at the whistle of map [param round] of [param rounds], a seat of the demo's and a bot
## at the table.
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
	var inputs: Array[KartInput] = [DemoInput.new(0), BotInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(12, 17)
	match_node.slots[0].banked = 400
	match_node.time_left = 0.02
	await runner.simulate_frames(10, 17)
	Game.grand_prix.score(match_node.standings())
	match_node.hud._podium_wait = 0.0
	await runner.simulate_frames(2, 17)
	return match_node.hud._results


## Every way on of [param screen] says it was pressed rather than going anywhere.
func _held(screen: ResultsScreen) -> void:
	for way: Button in [screen._next, screen._tie, screen._quit, screen._lobby]:
		for connection: Dictionary in way.pressed.get_connections():
			way.pressed.disconnect(connection["callable"])
		way.pressed.connect(func() -> void: _pressed.append(way.text))


## The demo's hand on [param screen], stepped by the test alone from the start of its wait.
func _slip_of(screen: ResultsScreen) -> DemoSlip:
	var slip: DemoSlip = screen.get_node("DemoSlip")
	slip.set_process(false)
	slip._waiting_on = ""
	return slip


## In the middle of a run the podium goes on to the standings by itself, a bar filling along the
## foot of the arrow down, and the standings to the next map, the bar along Next map's.
func test_the_slip_of_a_map_goes_on_by_itself() -> void:
	_run_at(1, 3)
	var screen := await _podium_after(1, 3)
	_held(screen)
	var slip := _slip_of(screen)
	slip._process(DemoSlip.PODIUM * 0.5)
	var fill: CountdownFill = slip._fill
	assert_bool(fill.visible).is_true()
	assert_object(fill.get_parent()).is_same(screen.pager_on())
	assert_float(fill.value).is_equal_approx(0.5, 0.01)
	assert_int(screen.bill.aim()).is_equal(0)
	slip._process(DemoSlip.PODIUM)
	assert_int(screen.bill.aim()).is_equal(1)
	assert_array(_pressed).is_empty()
	slip._process(0.0)
	slip._process(DemoSlip.STANDINGS * 0.5)
	assert_object(fill.get_parent()).is_same(screen._next)
	assert_float(fill.value).is_equal_approx(0.5, 0.01)
	assert_array(_pressed).is_empty()
	slip._process(DemoSlip.STANDINGS)
	assert_array(_pressed).contains_exactly(["Next map"])


## After the last map the podium goes on to the party, and the final standings after it back to
## the title, with no lobby to go back to.
func test_the_slip_of_a_run_ends_at_the_title() -> void:
	_run_at(3, 3)
	var screen := await _podium_after(3, 3)
	_held(screen)
	var slip := _slip_of(screen)
	slip._process(DemoSlip.PODIUM + 0.1)
	var finale := screen.match_node.finale
	assert_object(finale).is_not_null()
	finale.skip()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(screen.run_shown()).is_true()
	assert_bool(screen._lobby.visible).is_false()
	assert_object(screen.way_on()).is_same(screen._quit)
	slip._process(0.0)
	slip._process(DemoSlip.FINAL * 0.5)
	assert_object(slip._fill.get_parent()).is_same(screen._quit)
	assert_array(_pressed).is_empty()
	slip._process(DemoSlip.FINAL)
	assert_array(_pressed).contains_exactly(["Back to title"])


## Outside the demo the slip waits for somebody, as it always has.
func test_the_slip_outside_the_demo_waits() -> void:
	Demo.on = false
	_run_at(1, 3)
	var screen := await _podium_after(1, 3)
	assert_object(screen.get_node_or_null("DemoSlip")).is_null()
