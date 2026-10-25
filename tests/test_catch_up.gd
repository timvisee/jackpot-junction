extends GdUnitTestSuite
## Rubber banding, GAME.md 3.16, see [CatchUp]: a player behind earns more per chip, pulls stronger
## items and draws a sooner bounty onto the leader -- none of it level or ahead, or off.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES := preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new(), KartInput.new()] as Array[KartInput], 11)
	return match_node


## A kart well behind the leader earns more from each chip; the leader earns the plain amount.
func test_a_trailing_player_earns_more_coins() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(16, 17)
	match_node.slots[1].banked = 1000
	CatchUp.update(match_node)
	var behind := match_node.kart_of(0)
	var leader := match_node.kart_of(1)
	assert_float(behind.coin_bonus).is_greater(1.0)
	assert_float(leader.coin_bonus).is_equal(1.0)
	behind.pot.coins = 0
	behind.collect_coins(10, auto_free(Chip.new()))
	assert_int(behind.pot.coins).is_greater(10)


## With the rule off, nobody earns a bonus however far behind they are.
func test_catch_up_off_gives_no_bonus() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(16, 17)
	match_node.rules.catch_up = false
	match_node.slots[1].banked = 1000
	CatchUp.update(match_node)
	assert_float(match_node.kart_of(0).coin_bonus).is_equal(1.0)


## A trailing player's item pick leans toward stronger items; the leader's does not, and the pick
## itself favours a high-power item under the bias.
func test_a_trailing_player_pulls_stronger_items() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(16, 17)
	match_node.slots[1].banked = 1000
	CatchUp.update(match_node)
	assert_float(CatchUp.item_bias(match_node.kart_of(0))).is_greater(0.0)
	assert_float(CatchUp.item_bias(match_node.kart_of(1))).is_equal(0.0)
	var weak := PowerUp.new()
	weak.weight = 10.0
	weak.power = 1.0
	var strong := PowerUp.new()
	strong.weight = 10.0
	strong.power = 3.0
	var table := PowerUpTable.new()
	table.entries = [weak, strong]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var strongs := 0
	for i: int in 300:
		if table.pick(rng, 2.0) == strong:
			strongs += 1
	# Equal weight, triple power, bias 2 -> strong is five times as likely: well over half.
	assert_int(strongs).is_greater(200)


## Catch up calls the leader bounty sooner and pays it more; off, both are the plain values.
func test_catch_up_sharpens_the_leader_bounty() -> void:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.catch_up = true
	assert_int(CatchUp.bounty_lead(rules, 120)).is_less(120)
	assert_int(CatchUp.bounty_reward(rules, 150)).is_greater(150)
	rules.catch_up = false
	assert_int(CatchUp.bounty_lead(rules, 120)).is_equal(120)
	assert_int(CatchUp.bounty_reward(rules, 150)).is_equal(150)
