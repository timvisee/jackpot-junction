extends GdUnitTestSuite
## Whether a client is looking at the same match as the host, GAME.md 10.3. A puppet match is
## fed a host's snapshots and every number either machine shows a player has to agree.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func _rules() -> MatchRules:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	return rules


## GAME.md 6.2: only a bullet knocks a shooting target down, and a client runs no bullets of its
## own. No shipped map places one yet, so this builds a map that does.
func test_a_client_sees_which_shooting_targets_are_standing() -> void:
	var base: ArenaLayout = load("res://data/maps/lucky_crossing.tres")
	var layout: ArenaLayout = base.duplicate()
	# Two crates become two targets, which is the one glyph no map uses.
	layout.grid = base.grid.replace("B", "R")
	var host: Match = auto_free(MATCH_SCENE.instantiate())
	host.rules = _rules()
	host.arena_layout = layout
	host.with_hud = false
	var runner := scene_runner(host)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	host.start(inputs, 91)
	await runner.simulate_frames(12, 17)
	assert_int(host.arena.targets.size()).is_greater(0)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules()
	client.arena_layout = layout
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	assert_int(client.arena.targets.size()).is_equal(host.arena.targets.size())
	assert_bool(client.arena.targets[0].alive).is_true()
	# Down on the host: a client has no bullet to knock it over with, so it has to be told.
	var bullet: Bullet = auto_free(Bullet.new())
	bullet.owner_slot = 0
	assert_bool(host.arena.targets[0].take_hit(bullet)).is_true()
	client.apply_snapshot(host.build_snapshot())
	assert_bool(host.arena.targets[0].alive).is_false()
	assert_bool(client.arena.targets[0].alive).is_false()
	assert_bool(client.arena.targets[0].visible).is_false()
	# And back up with it rather than on a clock of its own.
	await runner.simulate_frames(20, 17)
	client.apply_snapshot(host.build_snapshot())
	assert_bool(client.arena.targets[0].alive).is_false()
	await runner.simulate_frames(260, 17)
	client.apply_snapshot(host.build_snapshot())
	assert_bool(host.arena.targets[0].alive).is_true()
	assert_bool(client.arena.targets[0].alive).is_true()
