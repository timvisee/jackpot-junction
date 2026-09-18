extends GdUnitTestSuite
## Local multiplayer from GAME.md 9.2: joining in the lobby, colours, joining mid-match by taking
## over a bot or a free slot, and handing a kart back to a bot.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LOBBY_SCENE := preload("res://scenes/ui/lobby.tscn")

var _runner: GdUnitSceneRunner


func _start_match(inputs: Array[KartInput], colors: Array[int] = []) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 17, colors)
	return match_node


func test_lobby_join_claims_p1_then_adds_and_drops_players_with_distinct_colours() -> void:
	var lobby: Control = auto_free(LOBBY_SCENE.instantiate())
	add_child(lobby)
	assert_int(lobby.devices[0]).is_equal(DeviceInput.ANY)
	lobby.toggle_join(0)
	assert_int(lobby.devices[0]).is_equal(0)
	lobby.toggle_join(DeviceInput.KEYBOARD)
	lobby.toggle_join(1)
	assert_int(lobby.devices.size()).is_equal(3)
	assert_array(lobby.colors).contains_exactly([0, 1, 2])
	lobby.cycle_color(1, 1)
	assert_int(lobby.colors[1]).is_equal(3)
	lobby.cycle_color(2, -1)
	assert_int(lobby.colors[2]).is_equal(1)
	lobby.toggle_join(1)
	assert_int(lobby.devices.size()).is_equal(2)
	lobby.toggle_join(0)
	assert_int(lobby.devices.size()).is_equal(2)
	lobby.bots_option.selected = 3
	var config: MatchConfig = lobby.config()
	assert_int(config.human_devices.size()).is_equal(2)
	assert_int(config.bot_count).is_equal(2)
	assert_array(config.colors()).contains_exactly([0, 3, 1, 2])


func test_colours_reach_karts_and_slots() -> void:
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
