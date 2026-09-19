extends GdUnitTestSuite
## The kill feed, GAME.md 8.3: who took out whom, how it is worded, and how lines age out.


func _feed() -> KillFeed:
	var feed: KillFeed = auto_free(KillFeed.new())
	add_child(feed)
	return feed


func test_every_kind_of_death_reads_as_a_sentence() -> void:
	var feed := _feed()
	var red := Palette.player_color(0)
	var blue := Palette.player_color(1)
	feed.add_kill("P2", blue, "P1", red, &"bullet")
	assert_str(feed.newest_text()).is_equal("P1 shot P2")
	feed.add_kill("P2", blue, "P1", red, &"ram")
	assert_str(feed.newest_text()).is_equal("P1 rammed P2")
	feed.add_kill("P2", blue, "P1", red, &"bomb")
	assert_str(feed.newest_text()).is_equal("P1 bombed P2")
	feed.add_kill("P2", blue, "P1", red, &"pit")
	assert_str(feed.newest_text()).is_equal("P1 shoved P2 in")
	feed.add_kill("P2", blue, "", KillFeed.NEUTRAL, &"pit")
	assert_str(feed.newest_text()).is_equal("P2 fell in")
	feed.add_kill("P2", blue, "P2", blue, &"bullet")
	assert_str(feed.newest_text()).is_equal("P2 wrecked itself")
	assert_str(feed._rows[0].text).contains(blue.to_html(false))


func test_only_the_newest_lines_are_kept_and_they_fade_away() -> void:
	var feed := _feed()
	for i: int in KillFeed.MAX_ROWS + 3:
		feed.add_kill("P%d" % i, Color.WHITE, "P1", Color.RED, &"bullet")
	assert_int(feed.row_count()).is_equal(KillFeed.MAX_ROWS)
	assert_str(feed.newest_text()).is_equal("P1 shot P7")
	# Held at full strength, then faded out and dropped.
	feed._process(KillFeed.HOLD - 0.1)
	assert_float(feed._rows[0].modulate.a).is_equal_approx(1.0, 0.001)
	feed._process(0.2 + KillFeed.FADE * 0.5)
	assert_float(feed._rows[0].modulate.a).is_between(0.2, 0.8)
	feed._process(KillFeed.FADE)
	assert_int(feed.row_count()).is_equal(0)


func test_the_hud_feeds_it_from_the_match() -> void:
	var scene: PackedScene = load("res://scenes/match/match.tscn")
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	var match_node: Match = auto_free(scene.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	var runner: GdUnitSceneRunner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 29)
	await runner.simulate_frames(12, 17)
	assert_int(match_node.hud._kill_feed.row_count()).is_equal(0)
	Events.kart_killed.emit(1, 0, &"bullet")
	await runner.simulate_frames(2, 17)
	assert_int(match_node.hud._kill_feed.row_count()).is_equal(1)
	assert_str(match_node.hud._kill_feed.newest_text()).contains("shot")
	assert_str(match_node.hud._kill_feed.newest_text()).contains(match_node.slots[0].display_name())
