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


## A wind-up toy driving into a bomb sets it off, as a kart driving over one does.
func test_the_toy_sets_off_a_bomb_it_drives_into() -> void:
	var match_node := await _match(&"toy_box")
	var toy: WindUpToy = match_node.arena.get_node("Toys/Toy0")
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	var at := toy.global_position + toy.global_basis.z.normalized() * 0.5
	bomb.global_position = Vector3(at.x, 0.0, at.z)
	await _frames(3)
	assert_array(_heard).is_not_empty()


## A laser tripwire's beam sets off a bomb lying across it while it is on, and leaves it be while it
## is off.
func test_a_tripwire_sets_off_a_bomb_across_its_beam() -> void:
	var match_node := await _match(&"vault")
	var wire: Tripwire = match_node.arena.get_node("Tripwires/Tripwire0")
	wire.run_to(0.5)
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	bomb.global_position = Vector3(wire.global_position.x, 0.0, wire.global_position.z)
	assert_bool(wire.crosses(bomb.global_position)).is_true()
	await _frames(3)
	assert_array(_heard).is_empty()
	wire.run_to(Tripwire.OFF + 0.1)
	await _frames(3)
	assert_array(_heard).is_not_empty()


## A live cabinet sets off a bomb against it and stays live, a kart the one thing that spends it;
## one still charging leaves the bomb be.
func test_a_live_cabinet_sets_off_a_bomb_against_it() -> void:
	var match_node := await _match(&"crossfire")
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	cabinet.charge_for(0.0)
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	var out := cabinet.global_basis.z.normalized()
	var at := cabinet.global_position + out * (LiveCabinet.SIZE.z * 0.5 + 0.3)
	bomb.global_position = Vector3(at.x, 0.0, at.z)
	await _frames(3)
	assert_array(_heard).is_empty()
	cabinet.charge_for(LiveCabinet.CHARGE + 1.0)
	await _frames(3)
	assert_array(_heard).is_not_empty()
	assert_bool(cabinet.live()).is_true()


## A turbo pad launches a bomb lying on it rolling down its arrow, slowing, as a pinball is fired,
## once each time it comes onto it.
func test_a_turbo_pad_launches_a_bomb_down_its_lane() -> void:
	var match_node := await _match(&"pin_alley")
	var pad: TurboPad = match_node.arena.turbo_pads[0]
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	var start := Vector3(pad.global_position.x, 0.0, pad.global_position.z)
	bomb.global_position = start
	await _frames(2)
	assert_float(bomb.rolling.length()).is_greater(Bomb.LAUNCH_SPEED * 0.8)
	assert_float(bomb.rolling.normalized().dot(pad.direction.normalized())).is_greater(0.99)
	await _frames(20)
	var gone := bomb.global_position - start
	assert_float(gone.dot(pad.direction.normalized())).is_greater(1.0)
	assert_float(bomb.rolling.length()).is_less(Bomb.LAUNCH_SPEED)


## A pop bumper kicks a bomb rolling into it straight back off its middle, lit as for a kart, and
## leaves one lying still against it be.
func test_a_bumper_kicks_a_bomb_rolling_into_it() -> void:
	var match_node := await _match(&"pin_alley")
	var bumper: Bumper = null
	for node: Node in get_tree().get_nodes_in_group(&"bumpers"):
		if match_node.is_ancestor_of(node):
			bumper = node as Bumper
			break
	assert_object(bumper).is_not_null()
	var out := Vector3(-bumper.global_position.x, 0.0, -bumper.global_position.z).normalized()
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	var against := bumper.global_position + out * (Bumper.RADIUS + Bomb.BODY_RADIUS + 0.05)
	bomb.global_position = Vector3(against.x, 0.0, against.z)
	await _frames(5)
	assert_vector(bomb.rolling).is_equal(Vector3.ZERO)
	assert_float(bomb.global_position.distance_to(Vector3(against.x, 0.0, against.z))).is_less(0.01)
	bomb.rolling = -out * 3.0
	await _frames(2)
	assert_float(bomb.rolling.dot(out)).is_greater(Bomb.KICK_SPEED * 0.5)
	assert_bool(bumper.lit()).is_true()
