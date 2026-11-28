extends GdUnitTestSuite
## The rooms' own moving things, GAME.md 6.2: the Count Room's conveyor belts, the Workbench's
## magnets, which drag bombs too, the Stitch's sewing needles, the Playset's wind-up toys and After
## Hours' tripwires, each on the map of its room, 6.3.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _match(map: StringName, karts := 1) -> Match:
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
	var inputs: Array[KartInput] = []
	for i: int in karts:
		inputs.append(KartInput.new())
	match_node.start(inputs, 13)
	await _runner.simulate_frames(20, 17)
	return match_node


## Puts [param kart] at [param at], still, facing [param facing].
func _place(kart: Kart, at: Vector3, facing := Vector3.FORWARD) -> void:
	kart.global_position = at
	kart.face(facing)
	kart.motor.velocity = Vector3.ZERO
	kart.velocity = Vector3.ZERO
	kart.reset_physics_interpolation()


## A belt carries a kart standing on it along its length, the top one toward +x and its twin back,
## and leaves one beside it where it is.
func test_a_belt_carries_a_kart_along() -> void:
	var match_node: Match = await _match(&"house_rules", 2)
	var grid := match_node.arena.grid
	assert_int(grid.belts.size()).is_equal(2)
	var top := grid.belts[0]
	assert_vector(Conveyor.way(grid, top)).is_equal(Vector3.RIGHT)
	assert_vector(Conveyor.way(grid, grid.belts[1])).is_equal(Vector3.LEFT)
	var on := match_node.kart_of(0)
	var start := grid.cell_center(top.position + Vector2i(2, 0))
	_place(on, start, Vector3.BACK)
	var off := match_node.kart_of(1)
	var beside := grid.cell_center(Vector2i(16, 9))
	_place(off, beside)
	for i: int in 30:
		await get_tree().physics_frame
	var moved := on.global_position - start
	assert_float(moved.x).is_greater(Conveyor.SPEED * 0.3)
	assert_float(absf(moved.z)).is_less(0.2)
	assert_float(off.global_position.distance_to(beside)).is_less(0.05)


## A magnet pulls a kart within reach in toward it while it is on, and not while it is off.
func test_a_magnet_pulls_karts_in_while_it_is_on() -> void:
	var match_node: Match = await _match(&"lucky_crossing")
	var magnet: Magnet = match_node.arena.get_node("Magnets/Magnet0")
	var kart := match_node.kart_of(0)
	var start := magnet.global_position + Vector3(0.0, 0.0, -3.0)
	magnet.run_to(0.5)
	assert_bool(magnet.on()).is_false()
	assert_vector(magnet.carry_at(kart)).is_equal(Vector3.ZERO)
	_place(kart, start)
	magnet.run_to(Magnet.OFF + 0.1)
	assert_bool(magnet.on()).is_true()
	for i: int in 20:
		await get_tree().physics_frame
	var nearer := start.distance_to(magnet.global_position)
	nearer -= kart.global_position.distance_to(magnet.global_position)
	assert_float(nearer).is_greater(0.3)


## A magnet that is on drags a bomb lying on the floor in toward it, as it pulls a kart, and stops
## it short of itself; while off it leaves it be. A client's copy glides to where the host says it
## is rather than jumping there, GAME.md 6.2.
func test_a_magnet_drags_bombs_in_while_it_is_on() -> void:
	var match_node: Match = await _match(&"lucky_crossing")
	var magnet: Magnet = match_node.arena.get_node("Magnets/Magnet0")
	var start := magnet.global_position + Vector3(0.0, 0.0, -3.0)
	start.y = 0.0
	var bomb := Bomb.new()
	bomb.fuse = 60.0
	match_node.add_child(bomb)
	bomb.global_position = start
	magnet.run_to(0.5)
	for i: int in 10:
		await get_tree().physics_frame
	assert_float(bomb.global_position.distance_to(start)).is_less(0.01)
	magnet.run_to(Magnet.OFF + 0.1)
	for i: int in 20:
		await get_tree().physics_frame
	var middle := Vector3(magnet.global_position.x, 0.0, magnet.global_position.z)
	assert_float(start.distance_to(middle) - bomb.global_position.distance_to(middle)).is_greater(
		0.3
	)
	for i: int in 60:
		await get_tree().physics_frame
	assert_float(bomb.global_position.distance_to(middle)).is_between(0.9, Magnet.TOUCH + 0.05)
	var copy := Bomb.new()
	copy.puppet = true
	match_node.add_child(copy)
	copy.glide_to(start)
	assert_vector(copy.global_position).is_equal(start)
	var there := start + Vector3(0.5, 0.0, 0.0)
	copy.glide_to(there)
	await get_tree().physics_frame
	assert_float(copy.global_position.distance_to(start)).is_between(0.01, 0.4)
	for i: int in 30:
		await get_tree().physics_frame
	assert_float(copy.global_position.distance_to(there)).is_less(0.02)


## A magnet that is on drags a mine lying in wait and a chip a death dropped in toward it as it does
## a bomb; a chip that came off a pad it leaves where it lies, GAME.md 6.2.
func test_a_magnet_drags_mines_and_dropped_chips() -> void:
	var match_node: Match = await _match(&"lucky_crossing")
	var magnet: Magnet = match_node.arena.get_node("Magnets/Magnet0")
	var middle := Vector3(magnet.global_position.x, 0.0, magnet.global_position.z)
	var toward := (-middle).normalized()
	var side := Vector3(-toward.z, 0.0, toward.x)
	var mine: Bullet = auto_free(Bullet.new())
	match_node.bullets.add_child(mine)
	mine.owner_slot = 0
	mine.kind = &"mine"
	mine.blast_radius = 2.0
	mine.arm_radius = 0.1
	mine.lifetime_left = 60.0
	mine._at_rest = true
	mine.global_position = middle + toward * 3.0 + Vector3.UP * Bullet.GRENADE_REST_Y
	# Laid there rather than fired from somewhere, so there is no way from a gun to look along.
	mine.spawn_from = mine.global_position
	var dropped := Chip.new()
	dropped.dropped = true
	match_node.arena.place_drop(dropped, middle + toward * 3.0 + side * 1.2)
	var still := Chip.new()
	var put := middle + toward * 3.0 - side * 1.2
	match_node.arena.place_drop(still, put)
	var starts := [mine.global_position, dropped.global_position]
	magnet.run_to(Magnet.OFF + 0.1)
	for i: int in 20:
		await get_tree().physics_frame
	for k: int in 2:
		var thing: Node3D = [mine, dropped][k]
		var was: Vector3 = starts[k]
		var gained := Vector2(was.x - middle.x, was.z - middle.z).length()
		gained -= (
			Vector2(thing.global_position.x - middle.x, thing.global_position.z - middle.z).length()
		)
		assert_float(gained).override_failure_message("thing %d" % k).is_greater(0.3)
	assert_float(still.global_position.distance_to(put)).is_less(0.01)


## A kart under the needle as it comes down spins out; one beside the seam does not.
func test_the_needle_spins_out_a_kart_under_it() -> void:
	var match_node: Match = await _match(&"loose_threads", 2)
	var needle: SewingNeedle = match_node.arena.get_node("Needles/Needle0")
	var under := match_node.kart_of(0)
	var beside := match_node.kart_of(1)
	needle.run_to(2.0)
	var heard: Array[int] = []
	var hear := func(slot: int) -> void: heard.append(slot)
	Events.stitched.connect(hear)
	for i: int in 20:
		var at := needle.to_global(needle.foot())
		_place(under, at)
		_place(beside, at + Vector3(0.0, 0.0, 2.5))
		await get_tree().physics_frame
		if under.motor.spinning():
			break
	assert_bool(under.motor.spinning()).override_failure_message("the needle missed").is_true()
	Events.stitched.disconnect(hear)
	assert_array(heard).is_equal([under.slot])
	assert_bool(beside.motor.spinning()).is_false()


## The toy drives round its loop and throws off a kart in its way; its twin across the room is
## where the room's point symmetry puts it.
func test_the_toy_drives_round_and_throws_karts_off() -> void:
	var match_node: Match = await _match(&"toy_box")
	var toys := match_node.arena.get_node("Toys")
	var toy: WindUpToy = toys.get_child(0)
	var twin: WindUpToy = toys.get_child(1)
	await get_tree().physics_frame
	assert_vector(twin.position).is_equal_approx(-toy.position, Vector3.ONE * 0.05)
	var kart := match_node.kart_of(0)
	kart.protection_left = 1.0
	toy.run_to(0.0)
	await get_tree().physics_frame
	# Beside the toy, off its nose, so it is clipped and shoved rather than run over.
	var beside := toy.position + toy.global_basis.x * 1.0
	_place(kart, beside)
	var thrown := false
	for i: int in 30:
		await get_tree().physics_frame
		thrown = thrown or kart.motor.thrown()
	assert_bool(thrown).override_failure_message("the toy drove past it").is_true()


## A kart standing square in the toy's path is run over and wrecked, not merely shoved.
func test_the_toy_runs_a_kart_in_its_path_over() -> void:
	var match_node: Match = await _match(&"toy_box")
	var toys := match_node.arena.get_node("Toys")
	var toy: WindUpToy = toys.get_child(0)
	toy.run_to(0.0)
	await get_tree().physics_frame
	var kart := match_node.kart_of(0)
	kart.protection_left = 0.0
	kart.hurt_left = 0.0
	_place(kart, toy.position + toy.global_basis.z * 1.0)
	var wrecked := false
	for i: int in 30:
		await get_tree().physics_frame
		wrecked = wrecked or not kart.alive
	assert_bool(wrecked).override_failure_message("the toy drove over it unharmed").is_true()


## A kart through a tripwire while it is on has a bounty put on it, if none is up; while it is off,
## nothing happens.
func test_a_tripwire_puts_a_bounty_on_a_kart_through_it() -> void:
	var match_node: Match = await _match(&"vault")
	match_node.rules.bounties = true
	var wire: Tripwire = match_node.arena.get_node("Tripwires/Tripwire0")
	var kart := match_node.kart_of(0)
	wire.run_to(0.2)
	_place(kart, wire.global_position)
	await get_tree().physics_frame
	assert_bool(wire.crossing(kart)).is_true()
	assert_int(match_node.bounty_slot).is_equal(-1)
	wire.run_to(Tripwire.OFF + 0.2)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_int(match_node.bounty_slot).is_equal(kart.slot)
