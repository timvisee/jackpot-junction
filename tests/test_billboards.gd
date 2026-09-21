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


## Two boards, out past the far corners rather than out at the sides, where the camera of 8.2
## never looks.
func test_the_room_puts_up_two_hoardings_behind_the_far_wall() -> void:
	var match_node := _match()
	await _runner.simulate_frames(4, 17)
	var boards := match_node.arena.billboards.get_children()
	assert_int(boards.size()).is_equal(2)
	var half := match_node.arena.world_size() * 0.5
	for board: Billboard in boards:
		assert_float(board.position.z).is_less(-half.y)
		assert_float(absf(board.position.x)).is_less(half.x)
		# And each is turned to face the table rather than standing side on to it. A board is
		# built facing +Z, so that is the axis its face looks along.
		assert_float(board.global_basis.z.z).is_greater(0.5)


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
