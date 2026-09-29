extends GdUnitTestSuite
## The results screen, GAME.md 3.8: everybody ranked by what they banked, each on a row of their
## own with their awards beside them, built like the joker detail pane so the two read as the
## same game.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


## A test that hosts is on its own connection, and it goes with the test rather than being left
## open for the next one.
func after_test() -> void:
	Net.close()


func _finished_match() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.overtime = false
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new(), KartInput.new()]
	match_node.start(inputs, 31, [], ["Ada", "Grace", "Linus"])
	return match_node


## The podium is held back for a couple of seconds after the whistle, GAME.md 3.8. A test that
## is about what ends up on the screen rather than about the wait skips to the end of it.
func _skip_the_pause(match_node: Match) -> void:
	match_node.hud._podium_wait = 0.0
	await _runner.simulate_frames(2, 17)


## Every label the screen carries, flattened, so a test can ask what it says without walking the
## boxes it is laid out in.
func _texts(node: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	var label := node as Label
	if label != null:
		found.append(label.text)
	for child: Node in node.get_children():
		found.append_array(_texts(child))
	return found


func test_the_screen_ranks_everybody_with_their_score_and_awards() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	match_node.slots[1].banked = 900
	match_node.slots[0].banked = 400
	match_node.slots[0].kills = 2
	match_node.slots[0].stats.add(&"crates", 9.0)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	await _skip_the_pause(match_node)
	var screen: ResultsScreen = match_node.hud._results
	assert_bool(screen.visible).is_true()
	# The hand of cards belongs to a match being played, not to one that is over.
	for hand: JokerHand in match_node.hud._hands.values():
		assert_bool(hand.visible).is_false()
	var texts := _texts(screen)
	assert_array(texts).contains([ResultsScreen.TITLE, "Grace", "Ada", "900", "400", "2 kills"])
	# Ranked by what is banked, so the winner's row comes first.
	assert_int(Array(texts).find("Grace")).is_less(Array(texts).find("Ada"))
	# The award for what somebody did most of is on their row, as a chip of its own.
	assert_array(texts).contains(["Demolition Crew", "9 crates broken"])
	# The bar along the top wears the winner's color, the way the joker pane wears the kind's.
	assert_object(screen._style.border_color).is_equal(match_node.slots[1].color())


## The same screen filled in twice says the same thing, which is what a client does every time
## the host repeats that the match is over.
func test_filling_the_screen_in_again_does_not_double_it_up() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	await _skip_the_pause(match_node)
	var screen: ResultsScreen = match_node.hud._results
	var before := _texts(screen).size()
	screen.fill_in()
	assert_int(_texts(screen).size()).is_equal(before)


## GAME.md 3.8: the top three stand on a podium, the winner on the tallest step in the middle.
func test_the_top_three_stand_on_the_podium() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	match_node.slots[1].banked = 900
	match_node.slots[0].banked = 400
	match_node.slots[2].banked = 100
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	await _skip_the_pause(match_node)
	var podium: ResultsPodium = match_node.hud._results._podium
	assert_bool(podium.visible).is_true()
	assert_int(podium._karts.size()).is_equal(3)
	# The winner is in the middle on the tallest step, and the steps come down from there.
	assert_float(podium._karts[0].position.x).is_equal(0.0)
	assert_float(podium._karts[0].position.y).is_greater(podium._karts[1].position.y)
	assert_float(podium._karts[1].position.y).is_greater(podium._karts[2].position.y)
	# And second and third stand on opposite sides of the winner.
	assert_float(podium._karts[1].position.x * podium._karts[2].position.x).is_less(0.0)
	# They turn on the spot, so the karts are looked at rather than merely listed.
	var facing := podium._karts[0].rotation.y
	await _runner.simulate_frames(20, 17)
	assert_float(podium._karts[0].rotation.y).is_not_equal(facing)


## A match of two has two on the podium rather than an empty step, and filling the screen in
## twice does not stack a second podium on the first.
func test_the_podium_only_holds_who_is_there() -> void:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.overtime = false
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 31)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	await _skip_the_pause(match_node)
	var podium: ResultsPodium = match_node.hud._results._podium
	assert_int(podium._karts.size()).is_equal(2)
	match_node.hud._results.fill_in()
	assert_int(podium._karts.size()).is_equal(2)


## GAME.md 3.8: the whistle is not the podium. The karts roll to a halt and the rig swings onto
## the winner first, and the screen comes up into a quieter room a couple of seconds later.
func test_the_podium_waits_for_the_whistle_to_finish() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	var hud := match_node.hud
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_bool(hud._results.visible).is_false()
	assert_bool(hud._podium_pending).is_true()
	# The cards are still the player's while the karts are still rolling.
	for hand: JokerHand in hud._hands.values():
		assert_bool(hand.visible).is_true()
	await _skip_the_pause(match_node)
	assert_bool(hud._results.visible).is_true()
	for hand: JokerHand in hud._hands.values():
		assert_bool(hand.visible).is_false()
	# And the music steps back under it.
	assert_float(Audio._duck_target).is_equal_approx(Audio.PODIUM_DUCK_DB, 0.001)
	Audio.duck_music(false)


## GAME.md 3.8: the podium comes up on its own, so it hands the cursor to Rematch rather than
## leaving a pad holder hunting for a button.
func test_the_podium_points_at_the_rematch_button() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	await _skip_the_pause(match_node)
	var screen: ResultsScreen = match_node.hud._results
	assert_object(screen._rematch.get_viewport().gui_get_focus_owner()).is_equal(screen._rematch)


## A quick match's podium goes back to the lobby as well as to a rematch or the title, GAME.md 3.8.
## The host of an online one takes everybody back to the waiting room with it, and the cursor
## starts there, since that is where a room of people wanting another go goes next; on one machine
## it starts on Rematch, and Back to lobby is beside it.
func test_a_quick_match_goes_back_to_the_lobby() -> void:
	var match_node := _finished_match()
	await _runner.simulate_frames(12, 17)
	var session := Net.open(match_node)
	assert_int(session.host(7831)).is_equal(OK)
	match_node.time_left = 0.02
	await _runner.simulate_frames(10, 17)
	await _skip_the_pause(match_node)
	var screen: ResultsScreen = match_node.hud._results
	assert_bool(screen._lobby.visible).is_true()
	assert_object(screen._lobby.get_viewport().gui_get_focus_owner()).is_equal(screen._lobby)
	Net.close()
	screen.fill_in()
	assert_bool(screen._lobby.visible).is_true()
	assert_bool(screen._rematch.visible).is_true()
	assert_object(screen._lobby.get_viewport().gui_get_focus_owner()).is_equal(screen._rematch)
