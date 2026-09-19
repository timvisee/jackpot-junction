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
	for name: String in PlayerNames.NAMES:
		assert_int(name.length()).is_between(1, PlayerNames.MAX_LENGTH)
		assert_str(PlayerNames.clean(name)).is_equal(name)


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
	# Bots are named after the way they drive, and nothing that is not a player is named at all.
	assert_str(match_node.slots[2].player_name).is_equal("")
	assert_str(match_node.slots[2].display_name()).starts_with("P3")
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
