extends GdUnitTestSuite
## A run of the demo for a booth, GAME.md 9.8: a Grand Prix dealt as it starts, seats with a name,
## a color, a dress and a plate each, every kart dressed from everything there is, and the title
## standing between runs with nothing on it to press.

const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings


func after_test() -> void:
	Demo.on = false
	Demo.seats = Demo.SEATS
	Demo.bots = Demo.BOTS
	Demo.map_seconds = Demo.MAP_SECONDS
	DemoRun.current = null
	Game.grand_prix = null
	Game.settings = _settings_were


func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


## A Grand Prix of three maps, the waiting room left out: two seats and two bots at Normal, three
## minutes a map to 3000, every rule of 9.8 on, and the run's first map to go to.
func test_a_run_is_a_grand_prix_dealt_at_once() -> void:
	var config := DemoRun.deal(_rng(3))
	var run := Game.grand_prix
	assert_object(run).is_not_null()
	assert_int(run.playlist.size()).is_equal(DemoRun.MAPS)
	assert_str(String(config.map)).is_equal(String(run.current_map()))
	assert_int(config.rounds).is_equal(DemoRun.MAPS)
	assert_int(config.keep_jokers).is_equal(GrandPrix.Keep.CHOOSE)
	assert_bool(config.tie_breaker and config.overtime).is_true()
	assert_int(config.human_devices.size()).is_equal(2)
	assert_int(config.bot_count).is_equal(2)
	assert_str(config.difficulty).is_equal("normal")
	assert_float(config.duration).is_equal(180.0)
	assert_int(config.target_score).is_equal(3000)
	assert_int(config.teams).is_equal(0)
	assert_str(config.item_set).is_equal("all")
	assert_int(run.bots.size()).is_equal(2)


## Each seat has a funny name, a color nobody else has and a dress of its own; its bot a way of
## driving and its kart a plate, the same for every map of the run.
func test_the_seats_are_dealt_for_the_run() -> void:
	Demo.seats = 3
	Demo.bots = 1
	var config := DemoRun.deal(_rng(4))
	assert_int(config.human_names.size()).is_equal(3)
	var colors := config.colors()
	for i: int in colors.size():
		assert_int(colors.count(colors[i])).is_equal(1)
	for name: String in config.human_names:
		assert_str(name).is_not_empty()
		assert_int(config.human_names.count(name)).is_equal(1)
	var inputs := DemoRun.inputs(config)
	assert_int(inputs.size()).is_equal(4)
	for seat: int in 3:
		var input := inputs[seat] as DemoInput
		assert_object(input).is_not_null()
		assert_int(input.seat).is_equal(seat)
		assert_object(input.bot_trait).is_same(DemoRun.current.traits[seat])
		assert_str(input.plate).is_equal(DemoRun.current.plates[seat])
		assert_str(input.plate).is_not_equal("L")
	assert_bool(inputs[3] is BotInput).is_true()
	var again := DemoRun.inputs(config)
	assert_object((again[0] as DemoInput).bot_trait).is_same((inputs[0] as DemoInput).bot_trait)


## Every kart is dressed from all there is, won pieces and finishes too, never in the crown.
func test_the_dress_is_drawn_from_everything() -> void:
	var rng := _rng(5)
	var crown := KartStyle.HATS.find("Crown")
	var seen: Array[Dictionary] = []
	for part: int in KartStyle.CHOICES.size():
		seen.append({})
	var finished := 0
	var by_finish := [0, 0, 0, 0]
	for i: int in 400:
		var style := KartStyle.dressed_up(rng)
		assert_int(style.hat).is_not_equal(crown)
		var picked := [style.paint, style.hat, style.flag, style.trail, style.frame, style.marks]
		for part: int in picked.size():
			seen[part][picked[part]] = true
		# An edition now and then, never more than one piece of a kart in one.
		var pieces := 0
		for part: int in picked.size():
			if style.finish(part) > 0:
				pieces += 1
				by_finish[style.finish(part)] += 1
		assert_int(pieces).is_less_equal(1)
		finished += pieces
	for part: int in KartStyle.CHOICES.size():
		var wanted: int = KartStyle.CHOICES[part].size() - (1 if part == 1 else 0)
		assert_int(seen[part].size()).is_equal(wanted)
	# Rare, as editions are, and the higher the rarer.
	assert_int(finished).is_between(20, 100)
	assert_int(by_finish[1]).is_greater(by_finish[2])
	assert_int(by_finish[2]).is_greater_equal(by_finish[3])
	# And the bots of a run are dressed the same way rather than in everybody's plain choices.
	var config := DemoRun.deal(_rng(6))
	assert_int(config.human_styles.size()).is_equal(2)
	var won := false
	for dressed: Array in Game.grand_prix.bot_styles + config.human_styles:
		var style := KartStyle.from_array(dressed)
		won = won or style.frame > 0 or style.marks > 0 or style.paint not in KartStyle.EVERYBODY[0]
	assert_bool(won).is_true()


## A seat's kart wears the plate made up for it.
func test_a_seat_wears_its_plate() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = false
	add_child(match_node)
	var seat := DemoInput.new(0)
	seat.plate = "WW-123"
	match_node.start([seat, BotInput.new()] as Array[KartInput], 7)
	assert_str(KartVisuals.plate_worn(match_node.kart_of(0))).is_equal("WW-123")


## Between runs the title is the mark and the name, its menu hidden and no opening played.
func test_the_title_has_nothing_to_press_in_the_demo() -> void:
	Game.settings = Settings.new()
	Game.settings.path = ""
	Demo.on = true
	Demo.set_up(Game.settings, false)
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var play: Button = title.get("play_button")
	assert_bool(play.visible).is_false()
	assert_object(title.get("_intro")).is_null()
	assert_object(title.get("invitation")).is_null()
	assert_object(title.get("welcome")).is_null()
	for button: Button in title.find_children("*", "Button", true, false):
		assert_bool(button.is_visible_in_tree()).override_failure_message(button.text).is_false()


## The first run is dealt as soon as the shaders are compiled, and every one after it once the
## title has stood for ten seconds; five, once the demo has taken over again from the full game.
func test_the_title_stands_between_runs() -> void:
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	var title: Node = auto_free(Node.new())
	assert_bool(host.title_done(title, 0.016)).is_true()
	host._first = false
	host._title = null
	var after: Node = auto_free(Node.new())
	var stood := 0.0
	while not host.title_done(after, 0.5):
		stood += 0.5
	assert_float(stood).is_equal_approx(DemoHost.TITLE_SECONDS - 0.5, 0.01)
	host._back = true
	var back: Node = auto_free(Node.new())
	stood = 0.0
	while not host.title_done(back, 0.5):
		stood += 0.5
	assert_float(stood).is_equal_approx(DemoHost.BACK_SECONDS - 0.5, 0.01)


## The title says how long it stands, so it never looks stuck: the next run's wait between runs,
## the demo's own after the full game, in whole seconds rounded up; nothing on the first start,
## which deals at once.
func test_the_title_counts_down_to_the_next_run() -> void:
	Game.settings = Settings.new()
	Game.settings.path = ""
	Demo.on = true
	Demo.set_up(Game.settings, false)
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	host.title_done(title, 0.016)
	assert_object(title.find_child("DemoWait", true, false)).is_null()
	host._first = false
	host._title = null
	host.title_done(title, 0.4)
	var wait := title.find_child("DemoWait", true, false) as DemoWait
	assert_object(wait).is_not_null()
	assert_bool(wait.is_visible_in_tree()).is_true()
	assert_str(wait.text).is_equal("The next Grand Prix starts in 10 seconds")
	host.title_done(title, DemoHost.TITLE_SECONDS - 1.2)
	assert_str(wait.text).is_equal("The next Grand Prix starts in 1 second")
	host._back = true
	host._title = null
	host.title_done(title, 3.0)
	assert_object(title.find_child("DemoWait", true, false)).is_same(wait)
	assert_str(wait.text).is_equal("The demo starts in 2 seconds")
