extends GdUnitTestSuite
## Live electrical cabinets, GAME.md 6.2: a kart that touches one is electrocuted, credited as a
## pit's fall is; nothing spares it that does not spare a fall; a shot meets one as it meets a wall;
## the bots keep off them as they keep off holes; and the House's word is painted in front of one.
## Played on Crossfire, the map that has them, 6.3.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 120.0
	rules.map = &"crossfire"
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = ArenaMaps.layout(rules.map)
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 13)
	return match_node


## Puts [param kart] [param back] meters off [param cabinet]'s face, nose on it, throttle down.
func _drive_at(kart: Kart, cabinet: LiveCabinet, back: float, input: KartInput) -> void:
	var out := cabinet.global_basis.z.normalized()
	kart.global_position = cabinet.global_position + out * back
	kart.face(-out)
	kart.motor.velocity = Vector3.ZERO
	kart.velocity = Vector3.ZERO
	kart.reset_physics_interpolation()
	input.throttle = 1.0


## Ticks until [param kart] is dead, up to [param ticks]; whether it died.
func _dies(kart: Kart, ticks: int) -> bool:
	for i: int in ticks:
		await get_tree().physics_frame
		if not kart.alive:
			return true
	return false


## GAME.md 6.2: driven into, a cabinet electrocutes the kart, and with nobody to blame the kill is
## nobody's, as a fall into a hole is; the cabinet's beacon flashes and its zap is heard, from the
## word every machine hears.
func test_driving_into_a_cabinet_is_death() -> void:
	var input := KartInput.new()
	var match_node := _match([input] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	assert_int(match_node.arena.cabinets.size()).is_equal(2)
	var kart := match_node.kart_of(0)
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	var kills: Array = []
	var heard := func(victim: int, killer: int, cause: StringName) -> void:
		kills.append([victim, killer, cause])
	Events.kart_killed.connect(heard)
	_drive_at(kart, cabinet, 3.0, input)
	var died: bool = await _dies(kart, 120)
	Events.kart_killed.disconnect(heard)
	assert_bool(died).override_failure_message("drove into a live cabinet and lived").is_true()
	assert_array(kills).is_equal([[0, -1, LiveCabinet.CAUSE]])
	assert_bool(cabinet.flashing()).is_true()
	# Solid as a wall: it did not drive through it on the way.
	var reach := cabinet.global_position.distance_to(kart.global_position)
	assert_float(reach).is_greater(LiveCabinet.SIZE.z * 0.5)


## GAME.md 3.6: the kill is whoever shoved the kart in, within the window a pit's fall is credited
## in, and a teammate's shove into one is nobody's, not an own goal.
func test_a_shove_onto_a_cabinet_is_the_shovers_kill() -> void:
	var input := KartInput.new()
	var match_node := _match([input, KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	var killers: Array[int] = []
	var heard := func(_victim: int, killer: int, _cause: StringName) -> void: killers.append(killer)
	Events.kart_killed.connect(heard)
	kart.last_bump_slot = 1
	kart.last_bump_time = Time.get_ticks_msec() * 0.001
	cabinet.shock(kart)
	Events.kart_killed.disconnect(heard)
	assert_bool(kart.alive).is_false()
	assert_array(killers).is_equal([1])
	assert_int(match_node.slots[1].kills).is_equal(1)


## Consistent with a hole, GAME.md 3.6: a shield, the lives a kart has left and a respawn's
## protection spare it nothing; a kart rolling out the end of the match is touched by nothing.
func test_nothing_spares_a_kart_that_a_fall_would_not() -> void:
	var match_node := _match([KartInput.new(), KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	var kart := match_node.kart_of(0)
	kart.set_shielded(true)
	kart.protection_left = 3.0
	assert_int(kart.lives).is_greater(1)
	cabinet.shock(kart)
	assert_bool(kart.alive).override_failure_message("a shield or protection spared it").is_false()
	var other := match_node.kart_of(1)
	other.coast()
	cabinet.shock(other)
	assert_bool(other.alive).is_true()


## GAME.md 6.2: a shot meets a cabinet as it meets a wall, stopping there or, with a bounce in it,
## coming off; the cabinet stands.
func test_a_shot_meets_a_cabinet_as_a_wall() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	var stats: CannonStats = load("res://data/cannons/default.tres").duplicate()
	stats.aim_assist = false
	var out := cabinet.global_basis.z.normalized()
	var from := cabinet.global_position + out * 4.0
	for bounces: int in [0, 1]:
		stats.bounces = bounces
		var shot := match_node.bullets.spawn(1, from, -out, stats, Color.RED)
		var gone := false
		for i: int in 40:
			await get_tree().physics_frame
			gone = not is_instance_valid(shot) or shot.is_dead()
			if gone or shot.turns > 0:
				break
		if bounces == 0:
			assert_bool(gone).override_failure_message("a shot went through a cabinet").is_true()
		else:
			assert_bool(gone).is_false()
			assert_int(shot.bounces_left).is_equal(0)
			assert_float(shot.velocity.dot(out)).is_greater(0.0)
			shot.destroy()
	assert_int(cabinet.collision_layer).is_equal(Layers.WORLD)
	assert_bool(cabinet.is_inside_tree()).is_true()


## GAME.md 9.1: the bots' map has a cabinet solid and the floor round it dear, as a hole's is, and
## the last word on a bot's driving keeps it off one as it keeps it out of a hole: a bot sent past
## a cabinet along its wall, or flat out straight at its door from a few meters out, lives.
func test_the_bots_keep_off_a_cabinet() -> void:
	var match_node := _match([BotInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var nav := match_node.nav
	var grid := match_node.arena.grid
	for run: Rect2i in grid.cabinets:
		for y: int in range(run.position.y, run.end.y):
			assert_bool(nav.is_blocked(Vector2i(run.position.x, y))).is_true()
			var door := Vector2i(run.position.x, y) + LiveCabinet.facing(grid, run)
			assert_float(nav.astar.get_point_weight_scale(door)).is_greater(1.0)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	var out := cabinet.global_basis.z.normalized()
	var past := Vector3(0.0, 0.0, -4.0)
	for run: Array in [[out * 6.0, past], [Vector3(0.0, 0.0, 4.5), past]]:
		kart.global_position = cabinet.global_position + (run[0] as Vector3)
		kart.face(-(run[0] as Vector3))
		kart.motor.forward_speed = kart.stats.top_speed
		kart.motor.velocity = kart.motor.forward_vector() * kart.stats.top_speed
		kart.reset_physics_interpolation()
		# An errand on the far side of it, held, so the bot drives there and decides nothing else.
		brain.goal = &"wander"
		brain.target = cabinet.global_position + (run[1] as Vector3)
		brain.target_node = null
		brain._elsewhere_left = 999.0
		for i: int in 60 * 4:
			await get_tree().physics_frame
			assert_bool(kart.alive).override_failure_message("a bot drove onto a cabinet").is_true()
			if not kart.alive:
				return


## GAME.md 6.3 and STORY.md 6.1: Crossfire's cabinets stand flush against the wall either side of
## the Junction, each a run of two `E` along the wall block it stands in the middle of, their doors
## toward the Junction, a mirror image of each other left to right; each with the box in front of
## its door turned to go with it and in line with it, its line against the hazard paint at the
## cabinet's foot: the House's word is road paint in the left one's, and the right one's is hatched.
func test_the_word_keeps_a_cabinet_clear() -> void:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = ArenaMaps.layout(&"crossfire")
	add_child(arena)
	var grid := arena.grid
	assert_array(grid.cabinets).is_equal([Rect2i(10, 8, 1, 2), Rect2i(21, 8, 1, 2)])
	var doors: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT]
	var lettered := 0
	var painted: Array[Rect2] = []
	for i: int in grid.cabinets.size():
		var run := grid.cabinets[i]
		var door := LiveCabinet.facing(grid, run)
		assert_vector(door).is_equal(doors[i])
		var cabinet: LiveCabinet = arena.cabinets[i]
		var out := Vector3(float(door.x), 0.0, float(door.y))
		assert_float(cabinet.global_basis.z.dot(out)).is_greater(0.99)
		# In the middle of the wall block behind it, which is the run's length, and flush: its back
		# a centimeter off the wall's face.
		var wall := grid.rect_center(Rect2i(run.position - door, run.size))
		assert_str(grid.glyph(run.position - door)).is_equal(ArenaGrid.WALL)
		assert_str(grid.glyph(run.end - Vector2i.ONE - door)).is_equal(ArenaGrid.WALL)
		assert_float(cabinet.global_position.z).is_equal_approx(wall.z, 0.001)
		var face := wall + out * grid.cell_size * 0.5
		var gap := (cabinet.global_position - face).dot(out) - LiveCabinet.SIZE.z * 0.5
		assert_float(gap).is_between(0.0, 0.05)
		# The box: three cells across, two out from the run, in line with the cabinet.
		var box := LiveCabinet.keep_clear(grid, run)
		var across := Vector2(LiveCabinet.BOX.y, LiveCabinet.BOX.x)
		assert_vector(box.size).is_equal_approx(across, Vector2.ONE * 0.001)
		var middle := (box.get_center() - Vector2(grid.width, grid.height) * 0.5) * grid.cell_size
		assert_float(middle.y).is_equal_approx(cabinet.global_position.z, 0.001)
		# The paint's near edge on the hazard band's, no floor showing between them.
		var paint := YardStyle._painted(grid, run)
		var band := YardStyle._foot(grid, run).grow(YardStyle.FOOT_GAP + YardStyle.HAZARD_BAND)
		var near := paint.position.x if door.x > 0 else paint.end.x
		var edge := band.end.x if door.x > 0 else band.position.x
		var line := YardStyle._box_line(grid, paint)
		assert_float(absf(near - edge)).is_less_equal(line * 0.5 + 0.001)
		painted.append(paint)
		if LiveCabinet.lettered(grid, run):
			lettered += 1
	assert_int(lettered).is_equal(2)
	assert_object(YardStyle._word_cabinet(grid)).is_equal(grid.cabinets[0])
	# A mirror image left to right: the cabinets, and the boxes painted in front of them.
	var left: LiveCabinet = arena.cabinets[0]
	var right: LiveCabinet = arena.cabinets[1]
	assert_float(left.global_position.x).is_equal_approx(-right.global_position.x, 0.001)
	assert_float(left.global_position.z).is_equal_approx(right.global_position.z, 0.001)
	assert_float(painted[0].position.x).is_equal_approx(grid.width - painted[1].end.x, 0.001)
	assert_vector(painted[0].size).is_equal_approx(painted[1].size, Vector2.ONE * 0.001)
	assert_float(painted[0].position.y).is_equal_approx(painted[1].position.y, 0.001)
