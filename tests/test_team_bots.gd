extends GdUnitTestSuite
## Bots in team play, GAME.md 3.14 and 9.1: they pass over teammates, a teammate's bounty and a
## teammate about to win, dodge nothing a teammate fires that goes through them, and count their
## team's flush pads as their own.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


## A bot in seat 0 on Hearts with a teammate in seat 2, and Spades in seats 1 and 3.
func _start() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.teams = 2
	rules.target_score = 500
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [
		BotInput.new(), KartInput.new(), KartInput.new(), KartInput.new()
	]
	match_node.start(inputs, 9)
	await _runner.simulate_frames(30, 17)
	return match_node


func _brain(match_node: Match) -> BotBrain:
	return match_node.kart_of(0).get_node("Brain")


## The nearest kart is passed over when it is a teammate, for the nearest of the other team.
func test_a_bot_hunts_the_other_team() -> void:
	var match_node: Match = await _start()
	var bot := match_node.kart_of(0)
	var brain := _brain(match_node)
	match_node.kart_of(2).global_position = bot.global_position + Vector3(2.0, 0.0, 0.0)
	match_node.kart_of(1).global_position = bot.global_position + Vector3(6.0, 0.0, 0.0)
	match_node.kart_of(3).global_position = bot.global_position + Vector3(-12.0, 0.0, 0.0)
	await _runner.simulate_frames(2, 17)
	assert_object(brain._hunt_target()).is_same(match_node.kart_of(1))


## A teammate about to win the match for the team is nobody to chase, and nor is a teammate
## carrying the bounty.
func test_a_bot_leaves_a_teammate_alone() -> void:
	var match_node: Match = await _start()
	var bot := match_node.kart_of(0)
	var brain := _brain(match_node)
	var mate := match_node.kart_of(2)
	mate.global_position = bot.global_position + Vector3(2.0, 0.0, 0.0)
	match_node.kart_of(1).global_position = bot.global_position + Vector3(14.0, 0.0, 0.0)
	match_node.kart_of(3).global_position = bot.global_position + Vector3(-14.0, 0.0, 0.0)
	await _runner.simulate_frames(2, 17)
	var sure: BotTrait = brain.bot_trait.duplicate()
	sure.winner_chase = 1.0
	brain.bot_trait = sure
	match_node.slots[2].banked = 900
	mate.pot.add_coins(200)
	assert_bool(match_node.would_win(match_node.slots[2])).is_true()
	assert_object(brain._winning_rival()).is_null()
	match_node.bounty_slot = 2
	assert_object(brain._hunt_target()).is_not_same(mate)


## A teammate's shot that goes through the bot is nothing to dodge; the other team's is.
func test_a_bot_does_not_dodge_a_teammates_shot() -> void:
	var match_node: Match = await _start()
	var brain := _brain(match_node)
	var stats: CannonStats = match_node.kart_of(2).cannon.stats
	var mates := match_node.bullets.spawn(2, Vector3.ZERO, Vector3.RIGHT, stats, Color.WHITE)
	mates.owner_team = 0
	mates.spares_team = true
	var theirs := match_node.bullets.spawn(1, Vector3.ZERO, Vector3.RIGHT, stats, Color.WHITE)
	theirs.owner_team = 1
	theirs.spares_team = true
	assert_bool(brain._harmless(mates)).is_true()
	assert_bool(brain._harmless(theirs)).is_false()
	mates.spares_team = false
	assert_bool(brain._harmless(mates)).is_false()


## The team's pads are the bot's own: three held between it and its teammate make the fourth the
## flush, and a teammate's pad is not one to take.
func test_a_bot_counts_its_teams_pads_as_its_own() -> void:
	var match_node: Match = await _start()
	var brain := _brain(match_node)
	var pads := match_node.arena.flush_pads
	var mate := match_node.slots[2]
	pads[0].claim(2, mate.color(), 0)
	pads[1].claim(2, mate.color(), 0)
	pads[2].claim(0, mate.color(), 0)
	var context := {}
	brain._add_flush_context(context)
	assert_object(context.get("flush_pad")).is_same(pads[3])
	assert_float(context["flush_value"]).is_equal(BotBrain.PAD_FLUSH_VALUE)
