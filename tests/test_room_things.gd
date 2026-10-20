extends GdUnitTestSuite
## The rooms' own moving things, GAME.md 6.2: the Count Room's conveyor belts, the Workbench's
## magnets, the Stitch's sewing needles, the Playset's wind-up toys and After Hours' tripwires, each
## on the map of its room, 6.3.

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


## A kart under the needle as it comes down spins out; one beside the seam does not.
func test_the_needle_spins_out_a_kart_under_it() -> void:
	var match_node: Match = await _match(&"lucky_crossing_xl", 2)
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
	var match_node: Match = await _match(&"crossfire_xl")
	var toys := match_node.arena.get_node("Toys")
	var toy: WindUpToy = toys.get_child(0)
	var twin: WindUpToy = toys.get_child(1)
	await get_tree().physics_frame
	assert_vector(twin.position).is_equal_approx(-toy.position, Vector3.ONE * 0.05)
	var kart := match_node.kart_of(0)
	toy.run_to(0.0)
	await get_tree().physics_frame
	var ahead := toy.position + toy.global_basis.z * 1.0
	_place(kart, ahead)
	var thrown := false
	for i: int in 30:
		await get_tree().physics_frame
		thrown = thrown or kart.motor.thrown()
	assert_bool(thrown).override_failure_message("the toy drove through it").is_true()


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
