extends GdUnitTestSuite
## The kill feed, GAME.md 8.3: who took out whom, how it is worded, and how lines age out.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


## A match of two karts with one life each, going.
func _match() -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = false
	match_node.offer_size = 0
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	match_node.rules = rules
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new(), KartInput.new()] as Array[KartInput], 3)
	return match_node


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
	feed.add_kill("P2", blue, "P1", red, &"turret")
	assert_str(feed.newest_text()).is_equal("P1's turret shot P2")
	feed.add_kill("P1", red, "P1", red, &"turret")
	assert_str(feed.newest_text()).is_equal("P1 was shot by their own turret")
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
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 29)
	await _runner.simulate_frames(12, 17)
	assert_int(match_node.hud._kill_feed.row_count()).is_equal(0)
	Events.kart_killed.emit(1, 0, &"bullet")
	await _runner.simulate_frames(2, 17)
	assert_int(match_node.hud._kill_feed.row_count()).is_equal(1)
	assert_str(match_node.hud._kill_feed.newest_text()).contains("shot")
	assert_str(match_node.hud._kill_feed.newest_text()).contains(match_node.slots[0].display_name())


## A decoy's kill says it was the decoy, GAME.md 8.3, and so does a decoy's end, with the owner's
## name in their color: a kill is the owner's either way, but the player taken out wants to know it
## was the copy. A decoy that ran out of time is no news.
func test_a_decoys_kills_and_end_say_it_was_the_decoy() -> void:
	var match_node := _match()
	await _runner.simulate_frames(2, 17)
	var feed := _feed()
	feed.match_node = match_node
	var ann := match_node.slots[0].display_name()
	var bo := match_node.slots[1].display_name()
	Events.kill_detailed.emit(1, true, 0)
	Events.kart_killed.emit(1, 0, &"bullet")
	assert_str(feed.newest_text()).is_equal("%s's decoy shot %s" % [ann, bo])
	assert_str(feed._rows[0].text).contains(match_node.slots[0].color().to_html(false))
	# The next kill is told nothing, and is the owner's own.
	Events.kart_killed.emit(1, 0, &"ram")
	assert_str(feed.newest_text()).is_equal("%s rammed %s" % [ann, bo])
	Events.decoy_destroyed.emit(0, 1, &"bullet")
	assert_str(feed.newest_text()).is_equal("%s shot %s's decoy" % [bo, ann])
	Events.decoy_destroyed.emit(0, -1, &"pit")
	assert_str(feed.newest_text()).is_equal("%s's decoy fell in" % ann)
	var rows := feed.row_count()
	Events.decoy_destroyed.emit(0, 0, &"bullet")
	assert_str(feed.newest_text()).is_equal("%s took out their own decoy" % ann)
	assert_int(feed.row_count()).is_equal(rows + 1)
	assert_bool(&"kill_detailed" in NetEvents.RELAYED).is_true()
	assert_bool(&"decoy_destroyed" in NetEvents.RELAYED).is_true()


## The host says what it was: a decoy's bullet or ram that kills tells the feed so before the kill,
## and a decoy destroyed is said, one that ran out of time not.
func test_the_match_says_a_decoy_did_it() -> void:
	var match_node := _match()
	await _runner.simulate_frames(20, 17)
	var told: Array[String] = []
	var detail := func(slot: int, decoy: bool, bounces: int) -> void:
		told.append("%d %s %d" % [slot, decoy, bounces])
	var gone := func(owner: int, by: int, cause: StringName) -> void:
		told.append("decoy %d %d %s" % [owner, by, cause])
	Events.kill_detailed.connect(detail)
	Events.decoy_destroyed.connect(gone)
	var victim := match_node.kart_of(1)
	victim.protection_left = 0.0
	KartCollisions.ram(victim, 0, true)
	assert_bool(victim.alive).is_false()
	var decoy: PowerUp = load("res://data/powerups/decoy_kart.tres")
	decoy.activate(match_node.kart_of(0))
	await _runner.simulate_frames(2, 17)
	var copy: Kart = null
	for node: Node in match_node.get_children():
		if node is Kart and (node as Kart).is_decoy():
			copy = node
	copy.protection_left = 0.0
	copy.die(&"bullet", 1)
	var other := match_node.kart_of(0)
	decoy.activate(other)
	await _runner.simulate_frames(2, 17)
	for node: Node in match_node.get_children():
		if node is Kart and (node as Kart).is_decoy() and (node as Kart).alive:
			(node as Kart).die(&"expired", -1)
	Events.kill_detailed.disconnect(detail)
	Events.decoy_destroyed.disconnect(gone)
	assert_array(told).is_equal(["1 true 0", "decoy 0 1 bullet"] as Array[String])


## A kill by a bullet off a wall has the mark of a ricochet at its end, GAME.md 8.3, and how many
## walls beside it past one, and no words for it; the bullet counts the walls and the death says
## them before the kill.
func test_a_ricochet_kill_has_the_mark_of_a_bounce() -> void:
	var match_node := _match()
	await _runner.simulate_frames(20, 17)
	var feed := _feed()
	feed.match_node = match_node
	var ann := match_node.slots[0].display_name()
	var bo := match_node.slots[1].display_name()
	Events.kill_detailed.emit(1, false, 1)
	Events.kart_killed.emit(1, 0, &"bullet")
	var once := feed.newest_text()
	assert_str(once).starts_with("%s shot %s" % [ann, bo])
	assert_str(once).not_contains("\u00d7")
	assert_str(once).not_contains("wall")
	Events.kill_detailed.emit(1, true, 3)
	Events.kart_killed.emit(1, 0, &"bullet")
	assert_str(feed.newest_text()).starts_with("%s's decoy shot %s" % [ann, bo])
	assert_str(feed.newest_text()).ends_with("\u00d73")
	# The match: a bullet that came off two walls and killed says so.
	var told: Array[int] = []
	var detail := func(_slot: int, _decoy: bool, bounces: int) -> void: told.append(bounces)
	Events.kill_detailed.connect(detail)
	var victim := match_node.kart_of(1)
	victim.protection_left = 0.0
	var shot: Bullet = auto_free(Bullet.new())
	shot.owner_slot = 0
	shot.bounced_times = 2
	shot._strike(victim)
	Events.kill_detailed.disconnect(detail)
	assert_bool(victim.alive).is_false()
	assert_array(told).is_equal([2] as Array[int])
	var mark := BounceIcon.draw(Color.WHITE)
	(
		assert_float(mark.get_pixelv(Vector2i(roundi(BounceIcon.WALL * BounceIcon.PIXELS), 24)).a)
		. is_greater(0.9)
	)
	assert_float(mark.get_pixel(1, 1).a).is_equal(0.0)
