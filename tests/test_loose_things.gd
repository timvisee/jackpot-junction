extends GdUnitTestSuite
## What the rooms do to the loose things on their floors, GAME.md 6.2: the bombs, the mines lying in
## wait and the chips a death dropped, see [LooseThings]: carried along a belt, and down a hole once
## over one.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner
var _heard: Array[int] = []


func before_test() -> void:
	_heard.clear()
	Events.bomb_exploded.connect(_on_bomb_exploded)


func after_test() -> void:
	Events.bomb_exploded.disconnect(_on_bomb_exploded)


func _on_bomb_exploded(slot: int) -> void:
	_heard.append(slot)


func _match(map: StringName) -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	rules.map = map
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = ArenaMaps.layout(rules.map)
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new()]
	match_node.start(inputs, 13)
	await _runner.simulate_frames(20, 17)
	return match_node


## The middle of the first hole of [param match_node]'s room, on the floor.
static func _hole(match_node: Match) -> Vector3:
	var grid := match_node.arena.grid
	var at := grid.rect_center(grid.pits[0])
	return Vector3(at.x, 0.0, at.z)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


## A bomb over a hole goes down it, shrinking, and is gone without going off, a shot no longer aimed
## at it; the host says so, and a client's copy goes down with it and is only taken away.
func test_a_bomb_over_a_hole_goes_down_it_without_going_off() -> void:
	var match_node := await _match(&"lucky_crossing")
	var hole := _hole(match_node)
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	bomb.global_position = hole
	await _frames(2)
	assert_bool(bomb.falling).is_true()
	assert_bool(bomb.is_targetable()).is_false()
	var said: Array = MatchSnapshot._bombs(match_node)
	assert_int(said.size()).is_equal(1)
	assert_bool(said[0]["fall"]).is_true()
	var entry := {"id": 7, "x": hole.x, "z": hole.z, "c": Color.RED, "armed": true, "fall": true}
	MatchSnapshot._apply_bombs(match_node, [entry])
	var copy: Bomb = match_node.puppet_bombs[7]
	assert_bool(copy.falling).is_true()
	await _frames(ceili(Bomb.FALL_TIME * 60.0) + 6)
	assert_bool(is_instance_valid(bomb)).is_false()
	assert_bool(copy.visible).is_false()
	MatchSnapshot._apply_bombs(match_node, [])
	assert_bool(copy.is_queued_for_deletion()).is_true()
	assert_array(_heard).is_empty()


## A mine lying over a hole goes down it, gone without going off.
func test_a_mine_over_a_hole_goes_down_it() -> void:
	var match_node := await _match(&"lucky_crossing")
	var mine := Bullet.new()
	match_node.bullets.add_child(mine)
	mine.owner_slot = 0
	mine.kind = &"mine"
	mine.blast_radius = 2.0
	mine.arm_radius = 0.1
	mine.lifetime_left = 60.0
	mine._at_rest = true
	mine.global_position = _hole(match_node) + Vector3.UP * Bullet.GRENADE_REST_Y
	mine.spawn_from = mine.global_position
	await _frames(2)
	assert_bool(not is_instance_valid(mine) or mine.is_dead()).is_true()


## A chip the host says is gone while it lies over a hole went down it: a client drops it down there
## too, rather than flying it into whoever is nearest.
func test_a_chip_gone_over_a_hole_goes_down_it_on_a_client() -> void:
	var match_node := await _match(&"lucky_crossing")
	var hole := _hole(match_node)
	var chip_entry := {
		"id": 9,
		"kind": "chip",
		"value": 1,
		"gold": false,
		"dropped": true,
		"x": hole.x,
		"z": hole.z
	}
	MatchSnapshot._apply_pickups(match_node, [chip_entry], [], false)
	var chip: Pickup = match_node.puppet_pickups[9]
	MatchSnapshot._take_pickup(match_node, 9)
	assert_bool(chip.falling).is_true()
	assert_bool(chip.is_queued_for_deletion()).is_false()
	assert_bool(match_node.puppet_pickups.has(9)).is_false()


## A belt carries the bombs, the mines and a death's chips lying on it along it, as it does a kart,
## and down the hole it runs into, the bomb without going off, GAME.md 6.2.
func test_a_belt_carries_loose_things_down_its_hole() -> void:
	var match_node := await _match(&"house_rules")
	var grid := match_node.arena.grid
	var top := grid.belts[0]
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	bomb.global_position = grid.cell_center(top.position + Vector2i(1, 0))
	var chip := Chip.new()
	chip.dropped = true
	match_node.arena.place_drop(chip, grid.cell_center(top.position + Vector2i(3, 0)))
	var mine := Bullet.new()
	match_node.bullets.add_child(mine)
	mine.owner_slot = 0
	mine.kind = &"mine"
	mine.blast_radius = 2.0
	mine.arm_radius = 0.1
	mine.lifetime_left = 60.0
	mine._at_rest = true
	var laid := grid.cell_center(top.position + Vector2i(5, 0))
	mine.global_position = laid + Vector3.UP * Bullet.GRENADE_REST_Y
	mine.spawn_from = mine.global_position
	var starts := [bomb.global_position.x, chip.global_position.x]
	await _frames(20)
	assert_float(bomb.global_position.x).is_greater(starts[0] + 0.5)
	assert_float(chip.global_position.x).is_greater(starts[1] + 0.5)
	await _frames(240)
	assert_bool(not is_instance_valid(bomb) or bomb.falling).is_true()
	assert_bool(not is_instance_valid(chip) or chip.falling).is_true()
	assert_bool(not is_instance_valid(mine) or mine.is_dead()).is_true()
	assert_array(_heard).is_empty()


## A sewing needle coming down on a bomb sets it off, as it spins out a kart under it.
func test_the_needle_sets_off_a_bomb_it_stabs() -> void:
	var match_node := await _match(&"loose_threads")
	var needle: SewingNeedle = match_node.arena.get_node("Needles/Needle0")
	needle.run_to(2.0)
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	for i: int in 30:
		if not is_instance_valid(bomb) or not bomb.alive:
			break
		var at := needle.to_global(needle.foot())
		bomb.global_position = Vector3(at.x, 0.0, at.z)
		await get_tree().physics_frame
	assert_array(_heard).is_not_empty()
