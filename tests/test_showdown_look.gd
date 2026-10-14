extends GdUnitTestSuite
## How a showdown looks, GAME.md 9.7a: the opening over the lamps, the clock's tag, the standings
## down the right by who lasted, the corner of a player out of it, and the room's calls.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner
var _calls: Array[String] = []


func before_test() -> void:
	_calls.clear()
	Events.announced.connect(_heard)


func after_test() -> void:
	Events.announced.disconnect(_heard)
	Audio.hush_music(false)


func _heard(slot: int, call: String) -> void:
	_calls.append("%d %s" % [slot, call])


## A showdown with a HUD, this machine's player in seat 0, [param fighters] in it, or everybody;
## [param rounds] maps to the run it settles, none for a quick match's.
func _showdown(seats: int, fighters: Array[int] = [], rounds := 0) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.map = ArenaMaps.SHOWDOWN
	rules.countdown = 0.4
	rules.rounds = rounds
	rules.round = rounds
	rules.fighters = PackedInt32Array(fighters)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = ArenaMaps.layout_for(rules)
	match_node.with_hud = true
	match_node.offer_size = 0
	Showdown.dress(match_node)
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0)]
	for i: int in seats - 1:
		inputs.append(KartInput.new())
	match_node.start(inputs, 31)
	return match_node


func _dressing(match_node: Match) -> ShowdownHud:
	return match_node.hud.get_node("Showdown") as ShowdownHud


## Over the lamps: the SHOWDOWN plate with the names of the karts in it, the rig's heads shared out
## between those karts, the crowd still and the music hushed. At the flag the plate goes, and the
## rig and the crowd are the room's again.
func test_the_opening_over_the_lamps() -> void:
	var fighters: Array[int] = [0, 2]
	var match_node := _showdown(3, fighters)
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.state).is_equal(Match.State.COUNTDOWN)
	var dressing := _dressing(match_node)
	assert_object(dressing).is_not_null()
	var plate: CallBanner = dressing._plate
	assert_bool(plate.visible).is_true()
	assert_str(plate.said()).is_equal("SHOWDOWN")
	assert_int(plate.dress).is_equal(CallBanner.Dress.PAIR)
	assert_int(plate._names.get_child_count()).is_equal(2)
	assert_str((plate._names.get_child(1) as Label).text).is_equal(
		match_node.slots[2].display_name()
	)
	var disco := match_node.arena.disco
	assert_array(disco._spread).contains_exactly([match_node.kart_of(0), match_node.kart_of(2)])
	assert_bool(match_node.arena.crowd.still).is_true()
	assert_bool(Audio.is_music_hushed()).is_true()
	await _runner.simulate_frames(40, 17)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	await _runner.simulate_frames(60, 17)
	assert_bool(plate.visible).is_false()
	assert_bool(disco._spread.is_empty()).is_true()
	assert_bool(match_node.arena.crowd.still).is_false()
	assert_bool(Audio.is_music_hushed()).is_false()


## The clock says what kind of time it is and how many are left, in red once it is running.
func test_the_clock_says_showdown_and_how_many_are_left() -> void:
	var match_node := _showdown(3)
	await _runner.simulate_frames(40, 17)
	var clock: ClockBoard = match_node.hud.get_node("Clock")
	assert_str(clock.under).is_equal("SHOWDOWN  ·  3 LEFT")
	assert_bool(clock.hot).is_true()
	match_node.kart_of(1).die(&"test", 0)
	await _runner.simulate_frames(3, 17)
	assert_str(clock.under).is_equal("SHOWDOWN  ·  2 LEFT")


## The standings down the right are the showdown's: who is in, a heart for each of their lives, and
## under them who is out, with a skull, at the place they went out in; nobody sitting it out, and
## nothing banked.
func test_the_standings_go_by_who_lasted() -> void:
	var fighters: Array[int] = [0, 1, 2]
	var match_node := _showdown(4, fighters)
	await _runner.simulate_frames(40, 17)
	match_node.kart_of(1).die(&"test", 0)
	await _runner.simulate_frames(3, 17)
	var board := match_node.hud._scoreboard
	var order := board.order()
	assert_int(order.size()).is_equal(3)
	assert_int(order[-1].index).is_equal(1)
	assert_bool(match_node.slots[3] in order).is_false()
	await _runner.simulate_frames(2, 17)
	var out: Dictionary = board._rows[1]
	assert_bool((out["fate"] as Control).visible).is_true()
	assert_bool(board.score_label(1).visible).is_false()
	assert_object(out["fate_said"]).is_equal(Vector2i(0, 1))
	var first := order[0].index
	var lives := match_node.kart_of(first).lives
	assert_object(board._rows[first]["fate_said"]).is_equal(Vector2i(lives, 0))
	# As wide as its hearts, and the skull as wide as one.
	var fate: Control = board._rows[first]["fate"]
	assert_float(fate.custom_minimum_size.x).is_greater(
		(out["fate"] as Control).custom_minimum_size.x
	)


## A player out of it, or sitting it out, says so in their corner, and nothing about money.
func test_the_corner_says_who_is_out_and_who_is_watching() -> void:
	var fighters: Array[int] = [1, 2]
	var match_node := _showdown(3, fighters)
	await _runner.simulate_frames(40, 17)
	var block: Dictionary = match_node.hud._blocks[0]
	var pot: ScorePills = block["pot"]
	assert_bool(pot.visible).is_true()
	assert_str(pot._note.text).is_equal("watching the tie-breaker")
	assert_bool((block["banked"] as Control).visible).is_false()
	assert_str(Showdown.corner_words(match_node.slots[1])).is_equal("out of the showdown")


## Every kart that goes out is called as out, outranking what its killer's kill was worth; the
## whistle calls whoever is left, as breaking the tie in a run's and winning in a quick match's.
func test_the_room_calls_who_goes_out_and_who_is_left() -> void:
	var match_node := _showdown(3, [], 2)
	await _runner.simulate_frames(40, 17)
	match_node.kart_of(1).die(&"test", 0)
	await _runner.simulate_frames(3, 17)
	assert_array(_calls).contains_exactly(["1 OUT"])
	match_node.kart_of(2).die(&"test", 0)
	await _runner.simulate_frames(3, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_array(_calls).contains_exactly(["1 OUT", "2 OUT", "0 BREAKS THE TIE"])


## A quick match's showdown is won rather than a tie broken: there is no run to settle.
func test_a_quick_match_showdown_is_won() -> void:
	var quick := _showdown(2)
	await _runner.simulate_frames(40, 17)
	quick.kart_of(0).die(&"test", 1)
	await _runner.simulate_frames(3, 17)
	assert_array(_calls).contains_exactly(["0 OUT", "1 WINS THE SHOWDOWN"])


## The rig shares its heads out a kart each, and goes back to one or to the room.
func test_the_rig_shares_its_heads_out() -> void:
	var match_node := _showdown(2)
	await _runner.simulate_frames(2, 17)
	var disco := match_node.arena.disco
	var karts: Array[Node3D] = [match_node.kart_of(0), match_node.kart_of(1)]
	disco.focus_each(karts)
	var heads: Array[Node3D] = []
	for head: Dictionary in disco._heads:
		heads.append(disco._target_of(head))
	assert_int(heads.count(karts[0])).is_equal(heads.count(karts[1]))
	disco.focus(karts[1])
	assert_object(disco._target_of(disco._heads[0])).is_same(karts[1])
	disco.clear_focus()
	assert_bool(disco._focused()).is_false()


## No score tanks on a showdown's table, GAME.md 9.7a, but a card standing for every kart in the
## fight, which folds as the kart goes out.
func test_a_card_stands_for_every_kart_in_it_and_folds() -> void:
	var fighters: Array[int] = [0, 2, 3]
	var match_node := _showdown(4, fighters)
	await _runner.simulate_frames(40, 17)
	assert_bool(match_node.score_tanks.wanted()).is_false()
	assert_bool(match_node.score_tanks.visible).is_false()
	var cards := match_node.get_node("ShowdownCards") as ShowdownCards
	assert_object(cards).is_not_null()
	assert_int(cards._cards.size()).is_equal(3)
	assert_bool(cards._cards.has(1)).is_false()
	match_node.kart_of(2).die(&"test", 0)
	await _runner.simulate_frames(60, 17)
	assert_bool(cards.folded(2)).is_true()
	assert_bool(cards.folded(0)).is_false()
	assert_float(cards._cards[2].rotation_degrees.x).is_equal_approx(90.0, 1.0)


## Any other map keeps its tanks, and stands no cards.
func test_any_other_map_keeps_its_tanks() -> void:
	var rules: MatchRules = RULES.duplicate()
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new(), KartInput.new()] as Array[KartInput], 3)
	await _runner.simulate_frames(4, 17)
	assert_bool(match_node.score_tanks.wanted()).is_true()
	assert_object(match_node.get_node_or_null("ShowdownCards")).is_null()


## A player out of the showdown, or sitting it out, emotes all the same, GAME.md 9.7a: with no
## kart in the fight to put it over, it floats up from the bottom of the screen in their color.
func test_a_player_out_of_it_emotes_from_the_bottom() -> void:
	var match_node := _showdown(3)
	# Any device, so a pressed action reads as it would off a key.
	var player := PlayerInput.new(DeviceInput.ANY, 0)
	match_node.slots[0].input = player
	match_node.kart_of(0).input = player
	await _runner.simulate_frames(40, 17)
	match_node.kart_of(0).die(&"test", 1)
	await _runner.simulate_frames(3, 17)
	assert_int(match_node.state).is_equal(Match.State.PLAYING)
	Input.action_press(InputActions.EMOTES[1])
	await _runner.simulate_frames(3, 17)
	Input.action_release(InputActions.EMOTES[1])
	var floating := match_node.hud.get_node("WatcherEmotes").get_node_or_null("WatcherEmote")
	assert_object(floating).override_failure_message("nothing floated up").is_not_null()


## And so does a player sitting it out, who never had a kart in the fight.
func test_a_player_sitting_it_out_emotes_from_the_bottom() -> void:
	var fighters: Array[int] = [1, 2]
	var match_node := _showdown(3, fighters)
	var player := PlayerInput.new(DeviceInput.ANY, 0)
	match_node.slots[0].input = player
	match_node.kart_of(0).input = player
	await _runner.simulate_frames(40, 17)
	assert_bool(match_node.slots[0].benched).is_true()
	Input.action_press(InputActions.EMOTES[2])
	await _runner.simulate_frames(3, 17)
	Input.action_release(InputActions.EMOTES[2])
	var floating := match_node.hud.get_node("WatcherEmotes").get_node_or_null("WatcherEmote")
	assert_object(floating).override_failure_message("nothing floated up").is_not_null()
