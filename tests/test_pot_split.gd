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
	# The lost share goes into a can that comes up beside the wreck, and says how much from it.
	assert_int(split._cans.size()).is_equal(1)
	await _runner.simulate_frames(150, 17)
	assert_bool(split._coins.is_empty()).is_true()
	assert_bool(split._cans.is_empty()).is_true()
	assert_bool(split._words.is_empty()).is_true()
	assert_bool(split.is_processing()).is_false()


## Nothing to split, nothing to show; a pot that banks all of it has nothing to crumble.
func test_only_the_shares_there_are_are_shown() -> void:
	var match_node := await _ready_match()
	var split: PotSplit = match_node.hud._pot_split
	split.play(0, 40, 0)
	assert_bool(split._coins.all(func(coin: Dictionary) -> bool: return coin["bank"])).is_true()
	assert_bool(split._cans.is_empty()).is_true()
	assert_int(split._words.size()).is_equal(1)
	assert_int(PotSplit._count(1)).is_equal(PotSplit.FEWEST)
	assert_int(PotSplit._count(100000)).is_equal(PotSplit.MOST)


func _ready_match() -> Match:
	var match_node := _match()
	await _runner.simulate_frames(20, 17)
	return match_node


## GAME.md 3.4: a pot being banked on the Junction sends chips into it the whole time it drains,
## not only in the burst once the cash-out is done, and stops once the bank has.
func test_chips_go_into_the_junction_the_whole_time_a_pot_banks() -> void:
	var match_node := await _ready_match()
	var bursts := func() -> int:
		return match_node.find_children("*", "ChipBurst", false, false).size()
	var before: int = bursts.call()
	for i: int in 12:
		Events.bank_tick.emit(0, 10)
		await _runner.simulate_frames(1, 17)
	var during: int = bursts.call()
	assert_int(during - before).is_greater_equal(2)
	# Once the ticks stop, so does the stream.
	var stream: BankStream = match_node.hud.get_node("BankStream")
	assert_bool(stream._banking.has(0)).is_true()
	await _runner.simulate_frames(30, 17)
	assert_bool(stream._banking.is_empty()).is_true()


## The can is for the players at this screen: a bot's loss, or another machine's player's, is not
## thrown away on this screen, though what it banked still flies to its row of the standings. The
## can is drawn under the rest of the HUD, and a coin flying into a score over it.
func test_only_this_screens_players_throw_their_loss_away() -> void:
	var match_node := await _ready_match()
	var split: PotSplit = match_node.hud._pot_split
	split.play(1, 30, 30)
	assert_bool(split._cans.is_empty()).is_true()
	assert_bool(split._coins.all(func(coin: Dictionary) -> bool: return coin["bank"])).is_true()
	assert_int(split._words.size()).is_equal(1)
	assert_int(split.z_index).is_less(0)
	assert_int(split._front.z_index + split.z_index).is_greater(0)


## GAME.md 8.3: a player on this screen picking an item up sees it beside their kart, turning like
## the roulette in their corner and then settled, until it fades; used, it goes at once. A bot's
## pickup puts nothing up.
func test_a_picked_item_is_shown_beside_the_kart() -> void:
	var match_node := await _ready_match()
	var tag: ItemTag = match_node.hud.get_node("ItemTag")
	var boost: PowerUp = load("res://data/powerups/boost.tres")
	match_node.kart_of(1).hold_item(boost, 0.5)
	assert_bool(tag._tags.has(1)).is_false()
	var kart := match_node.kart_of(0)
	kart.hold_item(boost, 0.5)
	assert_bool(tag._tags.has(0)).is_true()
	await _runner.simulate_frames(40, 17)
	assert_bool(tag._tags.has(0)).is_true()
	await _runner.simulate_frames(120, 17)
	assert_bool(tag._tags.has(0)).is_false()
	kart.hold_item(boost, 0.0)
	assert_bool(tag._tags.has(0)).is_true()
	kart.use_item()
	assert_bool(tag._tags.has(0)).is_false()
