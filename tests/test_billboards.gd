extends GdUnitTestSuite
## The hoardings over the crowd, GAME.md 8.1: two of them advertising the house and one keeping
## the match clock, which is the same clock the HUD keeps in the corner.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES := preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _match(timed := true) -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 65.0
	rules.timed = timed
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 4)
	return match_node


## Two boards, outside the arena and never on the near side: where each room puts them is its
## own business, GAME.md 8.1, but none of them stands on the floor or between the camera of 8.2
## and the table.
func test_the_room_puts_its_hoardings_up_outside_the_arena() -> void:
	var match_node := _match()
	await _runner.simulate_frames(4, 17)
	var boards := match_node.arena.billboards.get_children()
	assert_int(boards.size()).is_equal(2)
	var half := match_node.arena.world_size() * 0.5
	for board: Billboard in boards:
		var outside := absf(board.position.x) > half.x or absf(board.position.z) > half.y
		assert_bool(outside).override_failure_message("a board is standing on the floor").is_true()
		assert_float(board.position.z).is_less(half.y)
		# And each is turned to face the table rather than standing side on to it. A board is
		# built facing +Z, so that is the axis its face looks along.
		var toward := -Vector3(board.position.x, 0.0, board.position.z).normalized()
		assert_float(board.global_basis.z.dot(toward)).is_greater(0.9)


## GAME.md 8.1: the clock reads the match, in minutes and seconds, and turns red for Last Call.
func test_the_clock_board_reads_the_match_clock() -> void:
	var match_node := _match()
	await _runner.simulate_frames(4, 17)
	var clock := match_node.led_clock
	assert_bool(clock.wanted()).is_true()
	match_node.time_left = 65.0
	assert_str(clock._clock_text()).is_equal("0105")
	match_node.time_left = 9.0
	assert_str(clock._clock_text()).is_equal("0009")
	# However long is left, it is four digits: the board has four and no more.
	match_node.time_left = 100000.0
	assert_int(clock._clock_text().length()).is_equal(4)
	match_node.time_left = -1.0
	assert_str(clock._clock_text()).is_equal("0000")


## Every numeral the clock can show lights segments the display actually has.
func test_every_numeral_lights_segments_the_display_has() -> void:
	for numeral: String in LedClock.NUMERALS:
		var lit: String = LedClock.NUMERALS[numeral]
		assert_int(lit.length()).is_greater(1)
		for name: String in lit.split(""):
			assert_bool("abcdefg".contains(name)).is_true()


## A room with no clock to keep has no clock board, the same way it has no tanks.
func test_a_room_with_no_clock_shows_no_clock_board() -> void:
	var match_node := _match(false)
	await _runner.simulate_frames(4, 17)
	assert_bool(match_node.led_clock.wanted()).is_false()
	assert_bool(match_node.led_clock.visible).is_false()


## GAME.md 8.1: at the two moments the board has something better than a number to say, it says
## it. The countdown counts the field down with the gantry, sudden death says so in red, and the
## whistle names whoever won.
func test_the_clock_board_says_its_piece_at_the_start_and_the_finish() -> void:
	var match_node := _match()
	await _runner.simulate_frames(4, 17)
	var clock := match_node.led_clock
	match_node.state = Match.State.COUNTDOWN
	match_node.countdown_left = match_node.rules.countdown
	assert_str(clock._word_now()).is_equal("READY")
	match_node.countdown_left = match_node.rules.countdown * 0.4
	assert_str(clock._word_now()).is_equal("SET")
	# The drop is a moment rather than a state: caught as the countdown hands over, and gone a
	# second and a bit later, which is when the clock comes back.
	clock._was_state = Match.State.COUNTDOWN
	match_node.state = Match.State.PLAYING
	clock._step_state(0.1)
	assert_str(clock._word_now()).is_equal("GO!")
	clock._step_state(LedClock.GO_TIME)
	assert_str(clock._word_now()).is_empty()
	match_node.state = Match.State.OVERTIME
	assert_str(clock._word_now()).is_equal("OVERTIME")
	match_node.state = Match.State.RESULTS
	var winner := match_node.standings()[0]
	assert_str(clock._word_now()).is_equal(winner.display_name())
	assert_bool(clock._word_color().is_equal_approx(winner.color())).is_true()


## GAME.md 8.5: sudden death flashes, and holds still for anybody who has asked for fewer
## flashing things.
func test_the_overtime_word_flashes_unless_flashes_are_turned_down() -> void:
	var match_node := _match()
	await _runner.simulate_frames(4, 17)
	var clock := match_node.led_clock
	match_node.state = Match.State.OVERTIME
	var was := Game.settings.flash_reduction
	Game.settings.flash_reduction = false
	clock._now = 0.0
	var lit := clock._word_color()
	clock._now = LedClock.FLASH * 0.75
	var dark := clock._word_color()
	assert_bool(lit.is_equal_approx(dark)).is_false()
	Game.settings.flash_reduction = true
	clock._now = 0.0
	var steady := clock._word_color()
	clock._now = LedClock.FLASH * 0.75
	assert_bool(steady.is_equal_approx(clock._word_color())).is_true()
	Game.settings.flash_reduction = was
