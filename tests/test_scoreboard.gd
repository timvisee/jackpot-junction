extends GdUnitTestSuite
## The running order on the left, GAME.md 8.3: ordered by banked plus unbanked, the leader
## largest, the players on this screen boxed in their own colour.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match(players: int) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in 4:
		inputs.append(PlayerInput.new(i) if i < players else KartInput.new())
	match_node.start(inputs, 31)
	return match_node


func test_unbanked_coins_move_a_kart_up_the_board() -> void:
	var match_node := _start_match(1)
	await _runner.simulate_frames(12, 17)
	var board := match_node.hud._scoreboard
	match_node.slots[2].banked = 500
	match_node.slots[0].banked = 300
	await _runner.simulate_frames(2, 17)
	assert_int(board.order()[0].index).is_equal(2)
	# 250 unbanked is enough to take the lead, and losing them gives it straight back.
	match_node.kart_of(0).pot.add_coins(250)
	await _runner.simulate_frames(2, 17)
	assert_int(Scoreboard.total_of(match_node.slots[0])).is_equal(550)
	assert_int(board.order()[0].index).is_equal(0)
	assert_str((board._rows[0]["risk"] as Label).text).is_equal("+250")
	match_node.kart_of(0).pot.reset()
	await _runner.simulate_frames(2, 17)
	assert_int(board.order()[0].index).is_equal(2)
	assert_str((board._rows[0]["risk"] as Label).text).is_equal("")


func test_the_leader_is_biggest_and_the_local_player_is_boxed() -> void:
	var match_node := _start_match(1)
	await _runner.simulate_frames(12, 17)
	var board := match_node.hud._scoreboard
	match_node.slots[3].banked = 900
	await _runner.simulate_frames(2, 17)
	var ranked := board.order()
	assert_int(ranked[0].index).is_equal(3)
	var first: Label = board._rows[ranked[0].index]["score"]
	var last: Label = board._rows[ranked[3].index]["score"]
	assert_int(first.get_theme_font_size("font_size")).is_equal(Scoreboard.TOP_FONT)
	assert_int(last.get_theme_font_size("font_size")).is_equal(Scoreboard.BOTTOM_FONT)
	# Only the kart on this screen gets the boxed row.
	for slot: PlayerSlot in match_node.slots:
		var row: Dictionary = board._rows[slot.index]
		var style := (row["panel"] as PanelContainer).get_theme_stylebox("panel")
		assert_bool(style == row["own"]).is_equal(slot.index == 0)


func test_the_board_stands_down_in_a_four_corner_game() -> void:
	var match_node := _start_match(4)
	await _runner.simulate_frames(20, 17)
	assert_int(match_node.hud._blocks.size()).is_equal(4)
	assert_bool(match_node.hud._scoreboard.visible).is_false()
