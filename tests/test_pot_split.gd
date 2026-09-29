extends GdUnitTestSuite
## A pot split at a death or at the whistle, GAME.md 3.6 and 3.13, shown going where it went: the
## banked share flying into the score, in the player's corner or on the standings, and the lost
## share crumbling where the kart was.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new()]
	match_node.start(inputs, 5)
	return match_node


## The banked share goes into the score it went to: the corner's for the player on this screen,
## the standings' row for anybody else.
func test_the_banked_share_flies_to_where_the_score_is() -> void:
	var match_node := await _ready_match()
	var hud := match_node.hud
	var corner := hud.score_spot(0)
	var banked: Label = hud._blocks[0]["banked"]
	assert_int(corner.size()).is_equal(2)
	assert_bool(banked.get_global_rect().has_point(corner[0])).is_true()
	var row := hud.score_spot(1)
	assert_int(row.size()).is_equal(2)
	var score := hud._scoreboard.score_label(1)
	assert_bool(score.get_global_rect().has_point(row[0])).is_true()
	# The number said about it goes to the side of it, clear of the score itself.
	assert_float(corner[1].x).is_greater(corner[0].x)
	assert_float(row[1].x).is_less(hud._scoreboard.row_panel(1).get_global_rect().position.x)


## A death with something in its pot plays the split, and it plays out and stops: a coin a share,
## within the least and the most, and a number for each.
func test_a_death_plays_the_split_and_it_plays_out() -> void:
	var match_node := await _ready_match()
	var split: PotSplit = match_node.hud._pot_split
	var kart := match_node.kart_of(0)
	kart.pot.add_coins(30)
	kart.pot.add_mult(1.0)
	kart.die(&"pit", -1)
	var gold := split._coins.filter(func(coin: Dictionary) -> bool: return coin["bank"])
	var gray := split._coins.filter(func(coin: Dictionary) -> bool: return not coin["bank"])
	assert_int(gold.size()).is_equal(PotSplit._count(30))
	assert_int(gray.size()).is_equal(PotSplit._count(30))
	assert_int(split._words.size()).is_equal(2)
	assert_bool(split.is_processing()).is_true()
	await _runner.simulate_frames(150, 17)
	assert_bool(split._coins.is_empty()).is_true()
	assert_bool(split._dust.is_empty()).is_true()
	assert_bool(split._words.is_empty()).is_true()
	assert_bool(split.is_processing()).is_false()


## Nothing to split, nothing to show; a pot that banks all of it has nothing to crumble.
func test_only_the_shares_there_are_are_shown() -> void:
	var match_node := await _ready_match()
	var split: PotSplit = match_node.hud._pot_split
	split.play(0, 40, 0)
	assert_bool(split._coins.all(func(coin: Dictionary) -> bool: return coin["bank"])).is_true()
	assert_int(split._words.size()).is_equal(1)
	assert_int(PotSplit._count(1)).is_equal(PotSplit.FEWEST)
	assert_int(PotSplit._count(100000)).is_equal(PotSplit.MOST)


func _ready_match() -> Match:
	var match_node := _match()
	await _runner.simulate_frames(20, 17)
	return match_node
