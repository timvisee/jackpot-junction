extends GdUnitTestSuite
## Player names, GAME.md 3.8: everybody may set one of 1 to 16 characters, anybody who does not
## is handed a funny one, and whatever they end up with is what every screen calls them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	return rules


func _start(inputs: Array[KartInput], names: Array[String] = []) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules()
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 29, [], names)
	return match_node


func test_a_name_is_trimmed_shortened_and_stripped_of_markup() -> void:
	assert_str(PlayerNames.clean("  Ada  ")).is_equal("Ada")
	assert_str(PlayerNames.clean("")).is_equal("")
	assert_str(PlayerNames.clean("   ")).is_equal("")
	# Sixteen characters, no more. The results screen has a column, not a paragraph.
	var long_one := PlayerNames.clean("Bartholomew Winterbottom")
	assert_int(long_one.length()).is_equal(PlayerNames.MAX_LENGTH)
	assert_str(long_one).is_equal("Bartholomew Wint")
	# The standings and the kill feed are drawn with BBCode, so a name is never markup.
	assert_str(PlayerNames.clean("[color=red]Ada[/color]")).is_equal("color=redAda/col")
	assert_str(PlayerNames.clean("two\nlines")).is_equal("twolines")


func test_every_name_on_the_list_fits_the_limit() -> void:
	for name: String in PlayerNames.NAMES + PlayerNames.WATCHER_NAMES:
		assert_int(name.length()).is_between(1, PlayerNames.MAX_LENGTH)
		assert_str(PlayerNames.clean(name)).is_equal(name)


## The two lists are apart: a name says whether it is somebody driving or somebody watching, and
## nobody is ever handed a name off one that is on the other.
func test_the_watchers_list_is_its_own() -> void:
	for name: String in PlayerNames.WATCHER_NAMES:
		assert_array(PlayerNames.NAMES).not_contains([name])
	var seen: Dictionary[String, bool] = {}
	for name: String in PlayerNames.WATCHER_NAMES:
		seen[name] = true
	assert_int(seen.size()).is_equal(PlayerNames.WATCHER_NAMES.size())
	var rng := RandomNumberGenerator.new()
	assert_array(PlayerNames.WATCHER_NAMES).contains([PlayerNames.pick_watcher(rng)])


func test_a_drawn_name_is_never_one_somebody_already_has() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var taken: Array[String] = []
	for i: int in PlayerNames.NAMES.size():
		var drawn := PlayerNames.pick(rng, taken)
		assert_array(taken).not_contains([drawn])
		taken.append(drawn)
	# With the whole list in use there is still an answer, rather than an empty name.
	assert_str(PlayerNames.pick(rng, taken)).is_not_empty()


func test_players_keep_the_name_they_gave_and_the_rest_are_handed_one() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(), PlayerInput.new(), BotInput.new(), KartInput.new()
	]
	var match_node := _start(inputs, ["Ada", ""])
	await _runner.simulate_frames(12, 17)
	assert_str(match_node.slots[0].player_name).is_equal("Ada")
	assert_str(match_node.slots[0].display_name()).is_equal("Ada")
	# The second seat gave nothing, so it is somebody off the list rather than P2.
	var handed := match_node.slots[1].player_name
	assert_array(PlayerNames.NAMES).contains([handed])
	assert_str(match_node.slots[1].display_name()).is_equal(handed)
	# A bot is handed a robot's name off a list of the bots' own, and nothing that is neither a
	# player nor a bot is named at all.
	var bot := match_node.slots[2].player_name
	assert_array(PlayerNames.BOT_NAMES).contains([bot])
	assert_array(PlayerNames.NAMES).not_contains([bot])
	assert_str(match_node.slots[2].display_name()).is_equal(bot)
	assert_str(match_node.slots[3].player_name).is_equal("")


## A name given in the lobby is longer than the limit or full of markup like any other, and is
## cut down to size on the way in rather than on the way to the screen.
func test_a_name_from_the_lobby_is_cleaned_up() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new()]
	var match_node := _start(inputs, ["[b]Bartholomew Winterbottom[/b]"])
	await _runner.simulate_frames(12, 17)
	assert_int(match_node.slots[0].player_name.length()).is_less_equal(PlayerNames.MAX_LENGTH)
	assert_bool(match_node.slots[0].player_name.contains("[")).is_false()


## Starting again is the same room playing another match, not a new set of strangers.
func test_a_rematch_keeps_everybody_is_name() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), PlayerInput.new()]
	var match_node := _start(inputs, ["Ada", ""])
	await _runner.simulate_frames(12, 17)
	var before: Array[String] = [match_node.slots[0].player_name, match_node.slots[1].player_name]
	match_node.rematch()
	await _runner.simulate_frames(12, 17)
	assert_str(match_node.slots[0].player_name).is_equal(before[0])
	assert_str(match_node.slots[1].player_name).is_equal(before[1])


## GAME.md 10.3: a client is looking at the same room, so it reads the same names off it.
func test_names_reach_a_client_in_the_snapshot() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), BotInput.new()]
	var host := _start(inputs, ["Ada"])
	await _runner.simulate_frames(12, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	await _runner.simulate_frames(2, 17)
	assert_str(client.slots[0].player_name).is_equal("Ada")
	assert_str(client.slots[0].display_name()).is_equal("Ada")
	assert_str(client.slots[1].display_name()).is_equal(host.slots[1].display_name())


## The bots' names are theirs alone, GAME.md 3.8: none on the players' list, none too long, and a
## room of bots is handed as many different ones, the same for the same seed.
func test_bots_are_handed_robots_names_of_their_own() -> void:
	for named: String in PlayerNames.BOT_NAMES:
		assert_array(PlayerNames.NAMES).not_contains([named])
		assert_int(named.length()).is_less_equal(PlayerNames.MAX_LENGTH)
		assert_str(PlayerNames.clean(named)).is_equal(named)
	var taken: Array[String] = []
	for seat: int in 7:
		var named := PlayerNames.pick_bot(1000 + seat, taken)
		assert_array(taken).not_contains([named])
		taken.append(named)
	assert_str(PlayerNames.pick_bot(1000)).is_equal(PlayerNames.pick_bot(1000))


## Somebody sitting down where a bot was goes by their own name, not the bot's, GAME.md 3.8.
func test_a_player_taking_a_bots_seat_is_not_called_after_it() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new()]
	var match_node := _start(inputs, ["Ada", "Bea"])
	await _runner.simulate_frames(12, 17)
	var bot := match_node.slots[1].player_name
	assert_array(PlayerNames.BOT_NAMES).contains([bot])
	DeviceInput.recent = [DeviceInput.KEYBOARD]
	var joined := match_node.join_human(0)
	assert_object(joined).is_not_null()
	assert_str(joined.player_name).is_not_equal(bot)
	assert_array(PlayerNames.BOT_NAMES).not_contains([joined.player_name])
