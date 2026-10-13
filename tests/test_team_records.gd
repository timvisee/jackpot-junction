extends GdUnitTestSuite
## What team play counts toward, GAME.md 8.10 and 3.14: a team's win is every member's, "against"
## counts the other teams, By a Nose, All In and Last Kart Standing read the teams, a teammate's
## bullet is no parry, and Partners in Crime for a cash-out beside a teammate's.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_team_records.cfg"

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.player_names[0] = "Ann"
	Game.settings.save_to_disk()


func after_test() -> void:
	AchievementRecord.anywhere = false
	MatchRecord.anywhere = false
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A player here in seat 0 and bots, in two teams as [param dealt] says, with a record that keeps
## the achievements.
func _room(dealt: Array[int]) -> Match:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0)]
	for i: int in dealt.size() - 1:
		inputs.append(BotInput.new())
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES.duplicate()
	match_node.rules.teams = 2
	match_node.rules.max_players = 8
	match_node.rules.target_score = 1000
	match_node.arena_layout = LAYOUT
	match_node.joker_catalog = JOKERS
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, inputs.size(), [], [], [], dealt)
	AchievementRecord.add_to(match_node)
	AchievementRecord.anywhere = true
	return match_node


func _has(id: StringName) -> bool:
	return Game.settings.profile.achievements.has(id)


func _record(match_node: Match) -> AchievementRecord:
	return match_node.get_node("AchievementRecord") as AchievementRecord


func _won(match_node: Match) -> void:
	AchievementRecord.map_played(match_node, match_node.slots[0], Game.settings.profile, true)


## A map won by a team is won by every kart of it.
func test_a_teams_win_is_every_members() -> void:
	var match_node: Match = await _room([0, 1, 0, 1])
	match_node.slots[2].banked = 500
	var first := match_node.standings()[0]
	assert_int(first.index).is_equal(2)
	assert_bool(MatchRecord._first(first, match_node.slots[0])).is_true()
	assert_bool(MatchRecord._first(first, match_node.slots[1])).is_false()


## Against counts the other teams: a win of three against one is against one, too few for
## Flawless, and two against two is against two.
func test_against_counts_the_other_teams() -> void:
	var match_node: Match = await _room([0, 0, 0, 1])
	await _runner.simulate_frames(2, 17)
	_won(match_node)
	assert_bool(_has(&"flawless")).is_false()
	match_node = await _room([0, 1, 0, 1])
	await _runner.simulate_frames(2, 17)
	_won(match_node)
	assert_bool(_has(&"flawless")).is_true()


## By a Nose is the team's margin over the next team.
func test_by_a_nose_is_the_teams_margin() -> void:
	var match_node: Match = await _room([0, 1, 0, 1])
	await _runner.simulate_frames(2, 17)
	match_node.slots[0].banked = 900
	match_node.slots[2].banked = 100
	match_node.slots[1].banked = 800
	match_node.slots[3].banked = 140
	_won(match_node)
	assert_bool(_has(&"by_a_nose")).is_false()
	match_node.slots[3].banked = 160
	_won(match_node)
	assert_bool(_has(&"by_a_nose")).is_true()


## A teammate's shot met in the air is no parry; the other team's are.
func test_a_teammates_shot_is_no_parry() -> void:
	await _room([0, 1, 0, 1])
	await _runner.simulate_frames(2, 17)
	for i: int in 5:
		Events.bullets_met.emit(0, 2)
	assert_bool(_has(&"parry")).is_false()
	for i: int in 5:
		Events.bullets_met.emit(0, 1)
	assert_bool(_has(&"parry")).is_true()


## All In in teams: the player's one cash-out, the one that took the team to its target.
func test_all_in_is_the_cash_out_that_closed_it() -> void:
	var match_node: Match = await _room([0, 1, 0, 1, 0, 1])
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.rules.team_target()).is_equal(3000)
	Events.bank_started.emit(0)
	match_node.slots[0].banked = 1000
	Events.bank_completed.emit(0, 100, 10.0, 1000)
	_won(match_node)
	assert_bool(_has(&"all_in")).is_false()
	match_node.slots[2].banked = 2100
	Events.bank_completed.emit(0, 100, 10.0, 1000)
	_won(match_node)
	assert_bool(_has(&"all_in")).is_true()


## Last Kart Standing in teams is the very last kart, three or more of the other teams in it as
## sudden death began.
func test_last_kart_standing_is_the_very_last() -> void:
	var match_node: Match = await _room([0, 1, 0, 1, 0, 1])
	await _runner.simulate_frames(2, 17)
	var record := _record(match_node)
	record._on_state(Match.State.OVERTIME)
	for i: int in [1, 3, 5, 2]:
		match_node.slots[i].kart.alive = false
	record._last_standing()
	assert_bool(_has(&"last_kart_standing")).is_false()
	match_node.slots[4].kart.alive = false
	record._last_standing()
	assert_bool(_has(&"last_kart_standing")).is_true()


## Partners in Crime: cashing out on the Junction while a teammate does, and winning as a team.
func test_partners_in_crime() -> void:
	var match_node: Match = await _room([0, 1, 0, 1])
	await _runner.simulate_frames(2, 17)
	var pad := match_node.arena.junctions[0].global_position
	var mine := match_node.slots[0].kart
	var mate := match_node.slots[2].kart
	mine.global_position = pad + Vector3(-0.4, 0.0, 0.0)
	mine.pot.add_coins(30)
	await _runner.simulate_frames(2, 17)
	_won(match_node)
	assert_bool(_has(&"partners_in_crime")).is_false()
	mate.global_position = pad + Vector3(0.4, 0.0, 0.0)
	mate.pot.add_coins(30)
	await _runner.simulate_frames(2, 17)
	AchievementRecord.map_played(match_node, match_node.slots[0], Game.settings.profile, false)
	assert_bool(_has(&"partners_in_crime")).is_false()
	_won(match_node)
	assert_bool(_has(&"partners_in_crime")).is_true()
