extends GdUnitTestSuite
## The running order on the left, GAME.md 8.3: ordered by what is banked, the leader largest, the
## players on this screen boxed in their own color.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match(players: int, karts := 4) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.max_players = karts
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in karts:
		inputs.append(PlayerInput.new(i) if i < players else KartInput.new())
	match_node.start(inputs, 31)
	return match_node


## Unbanked coins are shown but not counted. A pot is worth nothing until it reaches the
## Junction, so the board that says who is winning says it about what has been banked; counting
## the pot put a player who had won nothing at the top and dropped them for being shot.
func test_unbanked_coins_show_beside_the_score_without_moving_the_row() -> void:
	var match_node := _start_match(1)
	await _runner.simulate_frames(12, 17)
	var board := match_node.hud._scoreboard
	match_node.slots[2].banked = 500
	match_node.slots[0].banked = 300
	await _runner.simulate_frames(2, 17)
	assert_int(board.order()[0].index).is_equal(2)
	# Enough in the pot to pass the leader on paper, which moves nothing: the row says the pot is
	# there and the order goes on saying who is ahead.
	match_node.kart_of(0).pot.add_coins(250)
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.slots[0].score()).is_equal(550)
	assert_int(board.order()[0].index).is_equal(2)
	assert_str((board._rows[0]["risk"] as Label).text).is_equal("+250")
	# Banking it is what moves it.
	match_node.slots[0].banked = 550
	match_node.kart_of(0).pot.reset()
	await _runner.simulate_frames(2, 17)
	assert_int(board.order()[0].index).is_equal(0)
	assert_str((board._rows[0]["risk"] as Label).text).is_equal("")


## A bot wears a robot's head after its name, and a player none.
func test_a_bot_is_marked_after_its_name() -> void:
	var match_node := _start_match(1, 3)
	await _runner.simulate_frames(12, 17)
	var board := match_node.hud._scoreboard
	assert_bool((board._rows[0]["bot"] as Control).visible).is_false()
	for slot: int in [1, 2]:
		var bot: Control = board._rows[slot]["bot"]
		assert_bool(bot.visible).is_true()
		var name_label: Label = board._rows[slot]["name"]
		assert_object(bot.get_parent()).is_same(name_label.get_parent())
		assert_int(bot.get_index()).is_equal(name_label.get_index() + 1)


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


## GAME.md 8.3: a room of eight, 9.3, has smaller rows, the leader still the biggest. On a short
## screen, a phone or a big UI scale, it shows four: the top of the order, and a player on this
## screen further down in the last of them, at their own place.
func test_a_room_of_eight_has_smaller_rows_and_four_on_a_short_screen() -> void:
	var root := get_tree().root
	var scale_was := root.content_scale_factor
	root.content_scale_factor = 0.5
	var match_node := _start_match(1, 8)
	await _runner.simulate_frames(12, 17)
	var board := match_node.hud._scoreboard
	for slot: PlayerSlot in match_node.slots:
		slot.banked = slot.index * 100
	await _runner.simulate_frames(2, 17)
	var ranked := board.order()
	assert_int(ranked[0].index).is_equal(7)
	assert_int(_font(board, ranked[0])).is_equal(Scoreboard.CROWDED_TOP)
	assert_int(_font(board, ranked[7])).is_equal(Scoreboard.CROWDED_BOTTOM)
	for slot: PlayerSlot in ranked:
		assert_bool((board._rows[slot.index]["panel"] as Control).visible).is_true()
	# Short whatever the window: a headless one is square, and tall at a UI scale of two.
	root.content_scale_factor = 3.0
	await _runner.simulate_frames(2, 17)
	assert_float(board.get_viewport_rect().size.y).is_less(Scoreboard.SHORT)
	var shown: Array[int] = []
	for slot: PlayerSlot in ranked:
		if (board._rows[slot.index]["panel"] as Control).visible:
			shown.append(slot.index)
	assert_array(shown).is_equal([7, 6, 5, 0])
	assert_str((board._rows[0]["place"] as Label).text).is_equal("8")
	assert_int(_font(board, ranked[0])).is_equal(Scoreboard.TOP_FONT)
	assert_int(_font(board, match_node.slots[0])).is_equal(Scoreboard.BOTTOM_FONT)
	# The room's list of who is in it goes into two columns past four instead, GAME.md 9.6.
	match_node.hud.waiting = true
	await _runner.simulate_frames(2, 17)
	assert_int(board.columns).is_equal(2)
	for slot: PlayerSlot in ranked:
		assert_bool((board._rows[slot.index]["panel"] as Control).visible).is_true()
	root.content_scale_factor = scale_was


func _font(board: Scoreboard, slot: PlayerSlot) -> int:
	return (board._rows[slot.index]["score"] as Label).get_theme_font_size("font_size")


func test_the_board_stands_down_in_a_four_corner_game() -> void:
	var match_node := _start_match(4)
	await _runner.simulate_frames(20, 17)
	assert_int(match_node.hud._blocks.size()).is_equal(4)
	assert_bool(match_node.hud._scoreboard.visible).is_false()


## GAME.md 3.4: a pot that would win the match says so on the spot, on the Junction ring and on
## the row of whoever is carrying it.
func test_a_pot_that_would_win_the_match_blinks_on_the_board_and_the_junction() -> void:
	var match_node := _start_match(1)
	await _runner.simulate_frames(12, 17)
	var board := match_node.hud._scoreboard
	var junction := match_node.arena.junction
	match_node.rules.target_score = 1000
	# Nowhere near it: neither the row nor the ring has anything to say.
	match_node.slots[0].banked = 400
	match_node.kart_of(0).pot.add_coins(100)
	await _runner.simulate_frames(4, 17)
	assert_bool(match_node.slots[0].would_win(1000)).is_false()
	assert_bool(junction.winning).is_false()
	assert_float((board._rows[0]["risk"] as Label).modulate.a).is_equal(1.0)
	# Banked plus pot reaches the target, so cashing in now ends it.
	match_node.kart_of(0).pot.add_coins(500)
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.slots[0].score()).is_equal(1000)
	assert_bool(junction.winning).is_true()
	# The blink is a blink: over a second the row's pot value is not always at full strength.
	var dimmest := 1.0
	for i: int in 40:
		await _runner.simulate_frames(1, 17)
		dimmest = minf(dimmest, (board._rows[0]["risk"] as Label).modulate.a)
	assert_float(dimmest).is_less(0.9)
	# A rival carrying it counts too, even though the ring only speaks for this screen.
	match_node.kart_of(0).pot.reset()
	match_node.slots[2].banked = 900
	match_node.kart_of(2).pot.add_coins(200)
	await _runner.simulate_frames(4, 17)
	assert_bool(match_node.slots[2].would_win(1000)).is_true()
	assert_bool(junction.winning).is_false()
	# Banking it empties the pot, so there is nothing left to promise.
	match_node.kart_of(2).pot.reset()
	await _runner.simulate_frames(4, 17)
	assert_bool(match_node.slots[2].would_win(1000)).is_false()
