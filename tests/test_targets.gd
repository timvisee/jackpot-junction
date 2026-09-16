extends GdUnitTestSuite
## Shooting targets and joker pads, GAME.md 6.2: what a bullet does to a target, and the parser
## and arena picking both elements up.

const GRID := "########\n#.RR.D.#\n#......#\n########"


func _bullet(slot: int) -> Bullet:
	var bullet: Bullet = auto_free(Bullet.new())
	bullet.owner_slot = slot
	add_child(bullet)
	return bullet


func test_a_bullet_knocks_a_target_down_and_it_comes_back() -> void:
	var target: Target = auto_free(Target.new())
	add_child(target)
	target.coins = 4
	var runner: GdUnitSceneRunner = scene_runner(target)
	var events := monitor_signals(Events, false)
	assert_bool(target.alive).is_true()
	assert_bool(target.take_hit(_bullet(1))).is_true()
	assert_bool(target.alive).is_false()
	assert_bool(target.visible).is_false()
	await assert_signal(events).is_emitted("target_struck", [1, 4])
	# A second bullet passes through the empty stand rather than dying on nothing.
	assert_bool(target.take_hit(_bullet(1))).is_false()
	target._left = 0.02
	await runner.simulate_frames(4, 17)
	assert_bool(target.alive).is_true()
	assert_bool(target.visible).is_true()


func test_the_parser_and_the_arena_pick_up_targets_and_joker_pads() -> void:
	var layout := ArenaLayout.new()
	layout.grid = GRID
	var grid := layout.parse()
	assert_int(grid.targets.size()).is_equal(2)
	assert_int(grid.joker_pads.size()).is_equal(1)
	var arena: Arena = auto_free(Arena.new())
	arena.layout = layout
	add_child(arena)
	assert_int(arena.targets.size()).is_equal(2)
	assert_int(arena.joker_pads.size()).is_equal(1)
	var rules: MatchRules = load("res://data/match/default.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	arena.start_economy(rules, rng, null, load("res://data/jokers/catalog.tres"))
	assert_int(arena.targets[0].coins).is_equal(rules.target_coins)
	# The pad puts a card out straight away and holds one for whoever turns up.
	assert_object(arena.joker_pads[0].current).is_not_null()
	assert_object(arena.joker_pads[0].current.joker).is_not_null()
