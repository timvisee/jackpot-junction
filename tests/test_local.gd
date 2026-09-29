extends GdUnitTestSuite
## Local multiplayer from GAME.md 9.2: joining in the lobby, colors, joining mid-match by taking
## over a bot or a free slot, and handing a kart back to a bot.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match(
	inputs: Array[KartInput], colors: Array[int] = [], names: Array[String] = [], styles := []
) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 17, colors, names, styles)
	return match_node


func test_colors_reach_karts_and_slots() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, [5, 2])
	assert_int(match_node.slots[0].color_index).is_equal(5)
	assert_int(match_node.kart_of(1).color_index).is_equal(2)
	assert_object(match_node.slots[0].color()).is_equal(Palette.player_color(5))


func test_joining_mid_match_takes_over_a_bot_and_settles_the_any_device_player() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), BotInput.new(), BotInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	assert_int(match_node.hud._blocks.size()).is_equal(1)
	var joined := match_node.join_human(1)
	assert_object(joined).is_not_null()
	assert_int(joined.index).is_equal(1)
	assert_bool(joined.is_human()).is_true()
	assert_int(joined.device()).is_equal(1)
	assert_object(joined.bot_trait).is_null()
	await _runner.simulate_frames(2, 17)
	assert_object(joined.kart.get_node_or_null("Brain")).is_null()
	assert_int(match_node.slots[0].device()).is_equal(DeviceInput.KEYBOARD)
	assert_int(match_node.hud._blocks.size()).is_equal(2)
	# Two players sitting here, so two corners: the one who was already here keeps theirs.
	assert_int(match_node.hud._blocks[0]["corner"]).is_equal(0)
	assert_int(match_node.hud._blocks[1]["corner"]).is_equal(1)
	assert_object(match_node.join_human(1)).is_null()
	match_node.leave_human(joined)
	assert_bool(joined.is_human()).is_false()
	assert_object(joined.bot_trait).is_not_null()
	assert_object(joined.kart.get_node_or_null("Brain")).is_not_null()
	assert_int(match_node.hud._blocks.size()).is_equal(1)
	# And the corner they gave up is the one the next player to sit down takes.
	var again := match_node.join_human(1)
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.hud._blocks[again.index]["corner"]).is_equal(1)


## GAME.md 4.4: somebody sitting down in a bot's kart is dressed and named for their own seat, not
## left in the kart as the bot drove it; a player at another machine takes neither of this
## machine's seats, since they say their own.
func test_a_player_taking_over_a_bot_wears_their_own_seats_dress() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new(), BotInput.new()
	]
	var names: Array[String] = ["Ann", "Bea"]
	var styles: Array = [PackedInt32Array([1, 1, 1, 1]), PackedInt32Array([2, 3, 1, 2])]
	var match_node := _start_match(inputs, [], names, styles)
	await _runner.simulate_frames(12, 17)
	var joined := match_node.join_human(1)
	assert_int(joined.index).is_equal(1)
	assert_str(joined.player_name).is_equal("Bea")
	assert_array(Array(joined.style.to_array())).is_equal([2, 3, 1, 2])
	assert_array(Array(joined.kart.style.to_array())).is_equal([2, 3, 1, 2])
	var visitor := match_node.join_network(NetInput.new())
	assert_int(visitor.index).is_equal(2)
	assert_str(visitor.player_name).is_not_equal("Ann")
	assert_str(visitor.player_name).is_not_equal("Bea")
	assert_array(Array(visitor.style.to_array())).is_equal([0, 0, 0, 0])


func test_joining_without_bots_spawns_a_fresh_slot_until_the_match_is_full() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), PlayerInput.new(0)]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var third := match_node.join_human(1)
	assert_object(third).is_not_null()
	assert_int(match_node.slots.size()).is_equal(3)
	assert_int(third.color_index).is_equal(2)
	assert_int(third.banked).is_equal(0)
	assert_bool(third.kart.alive).is_true()
	assert_float(third.kart.protection_left).is_greater(0.0)
	var fourth := match_node.join_human(2)
	assert_object(fourth).is_not_null()
	assert_object(match_node.join_human(3)).is_null()
	assert_int(match_node.camera_rig.targets.size()).is_equal(4)


## GAME.md 3.8: a minute is on offer in every build, and a debug build offers five seconds in
## front of it, straight through to the podium for somebody testing what comes after it. A real
## build does not, because it is not a length anybody wants a game to be.
func test_a_debug_build_offers_a_short_match() -> void:
	var pane: HostSettings = auto_free(HostSettings.add_to(self, true))
	var lengths: Array[int] = MatchOptions.match_lengths()
	assert_bool(lengths.has(60)).is_true()
	if OS.is_debug_build():
		(
			assert_int(lengths[0])
			. override_failure_message("a debug build did not offer the short match first")
			. is_equal(MatchOptions.DEBUG_LENGTH)
		)
		assert_int(lengths.size()).is_equal(MatchOptions.LENGTHS.size() + 1)
	else:
		assert_array(lengths).is_equal(MatchOptions.LENGTHS)
	assert_str(MatchOptions.length_words(5.0)).is_equal("5 s")
	assert_str(MatchOptions.length_words(180.0)).is_equal("3 min")
	# Whichever it is, picking one gives a match that long and nothing else.
	pane.options.minutes_option.selected = 0
	var config := MatchConfig.new()
	pane.options.apply_to(config)
	assert_float(config.duration).is_equal_approx(float(lengths[0]), 0.001)


## GAME.md 9.6: back to the lobby from a map, everybody who played it at this machine comes too,
## as who they were in it, and a bot does not.
func test_the_players_here_are_carried_back_to_the_lobby() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1), BotInput.new()
	]
	var match_node := _start_match(inputs, [4, 1, 2])
	match_node.slots[1].player_name = "Grace"
	match_node.slots[1].style = KartStyle.from_array([1, 2, 0, 0])
	var config := MatchConfig.new()
	config.take_locals(match_node)
	assert_array(config.human_devices).contains_exactly([DeviceInput.KEYBOARD, 0])
	assert_array(config.human_colors).contains_exactly([4, 1])
	assert_str(config.human_names[1]).is_equal("Grace")
	assert_array(Array(config.human_styles[1])).contains_exactly([1, 2, 0, 0])


## GAME.md 3.8: the names of the seats at this machine are in the settings, a box each.
func test_the_seats_are_named_in_the_settings() -> void:
	var real := Game.settings
	Game.settings = Settings.new()
	var screen: SettingsScreen = auto_free(
		load("res://scenes/ui/settings_screen.tscn").instantiate()
	)
	add_child(screen)
	var players: Control = screen.tabs.get_node("Players")
	var boxes := players.find_children("*", "LineEdit", true, false)
	assert_int(boxes.size()).is_equal(4)
	(boxes[2] as LineEdit).text_changed.emit("  [b]Grace[/b]  ")
	assert_str(Game.settings.player_names[2]).is_equal("bGrace/b")
	Game.settings = real
