extends GdUnitTestSuite
## Live electrical cabinets, GAME.md 6.2: one charges, a wall, and then is live until a kart touches
## it, which is electrocuted, credited as a pit's fall is, and spends it; nothing spares it that
## does not spare a fall; each charges on the match's clock from the flag and from its own last
## kart; a shot meets one as it meets a wall; the bots keep off them as they keep off holes while
## they are live; and the House's word is painted in front of one. Played on Crossfire, the map
## that has them, 6.3.

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


## GAME.md 6.2: driven into while it is live, a cabinet electrocutes the kart, and with nobody to
## blame the kill is nobody's, as a fall into a hole is; the cabinet's beacon flashes and its zap
## is heard, from the word every machine hears; and the cabinet is spent, charging again.
func test_driving_into_a_cabinet_is_death() -> void:
	var input := KartInput.new()
	var match_node := _match([input] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	assert_int(match_node.arena.cabinets.size()).is_equal(2)
	var kart := match_node.kart_of(0)
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	cabinet.charge_for(LiveCabinet.CHARGE + 0.5)
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
	assert_bool(cabinet.live()).is_false()
	assert_float(cabinet.charged_for()).is_less(0.1)
	# Solid as a wall: it did not drive through it on the way.
	var reach := cabinet.global_position.distance_to(kart.global_position)
	assert_float(reach).is_greater(LiveCabinet.SIZE.z * 0.5)


## GAME.md 6.2: while it charges a cabinet is a wall like any other, driven into flat out and
## leaned on; and a kart still against it as it goes live is touching it, and is electrocuted
## there, standing still, with nothing run into.
func test_a_charging_cabinet_is_a_wall_until_it_goes_live() -> void:
	var input := KartInput.new()
	var match_node := _match([input] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	cabinet.charge_for(0.5)
	assert_bool(cabinet.live()).is_false()
	_drive_at(kart, cabinet, 3.0, input)
	var died: bool = await _dies(kart, 90)
	assert_bool(died).override_failure_message("a charging cabinet killed").is_false()
	var reach := cabinet.global_position.distance_to(kart.global_position)
	assert_float(reach).is_less(LiveCabinet.SIZE.z * 0.5 + LiveCabinet.KART.y * 0.5 + 0.1)
	assert_bool(cabinet.touching(kart)).is_true()
	# Let off and stopped against it, as it goes live.
	input.throttle = 0.0
	kart.motor.velocity = Vector3.ZERO
	kart.velocity = Vector3.ZERO
	await _runner.simulate_frames(5, 17)
	assert_bool(kart.alive).is_true()
	cabinet.charge_for(LiveCabinet.CHARGE + 0.1)
	died = await _dies(kart, 3)
	assert_bool(died).override_failure_message("lived against a live cabinet").is_true()
	assert_float(kart.global_position.distance_to(cabinet.global_position)).is_less(reach + 0.05)


## GAME.md 6.2: from the flag a cabinet charges for six seconds of the match's clock, and is then
## live, and stays live, a minute on as at the moment it went; a kart it catches spends it, and it
## charges again from then, the other one live all along; the meter on its roof fills as it
## charges.
func test_a_cabinet_stays_live_until_it_catches_a_kart() -> void:
	var match_node := _match([KartInput.new(), KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var rules := match_node.rules
	var cabinets := match_node.arena.cabinets
	for played: float in [0.5, LiveCabinet.CHARGE - 0.2, LiveCabinet.CHARGE + 0.2, 40.0, 80.0]:
		match_node.time_left = rules.duration - played
		await _runner.simulate_frames(2, 17)
		for cabinet: LiveCabinet in cabinets:
			# The few ticks the frames take run the match's clock on a little past where it was put.
			assert_float(cabinet.charged_for()).is_between(played - 0.02, played + 0.1)
			assert_bool(cabinet.live()).is_equal(played >= LiveCabinet.CHARGE)
	var caught: LiveCabinet = cabinets[0]
	var other: LiveCabinet = cabinets[1]
	caught.shock(match_node.kart_of(0))
	assert_bool(match_node.kart_of(0).alive).is_false()
	assert_bool(caught.live()).is_false()
	assert_bool(other.live()).is_true()
	# Charging from then, a wall to the next kart, and live again once charged.
	caught.shock(match_node.kart_of(1))
	assert_bool(match_node.kart_of(1).alive).is_true()
	match_node.time_left -= LiveCabinet.CHARGE - 0.5
	await _runner.simulate_frames(2, 17)
	assert_bool(caught.live()).is_false()
	assert_bool(other.live()).is_true()
	match_node.time_left -= 1.0
	await _runner.simulate_frames(2, 17)
	assert_bool(caught.live()).is_true()
	var look := caught.look()
	look.step(0.016, LiveCabinet.CHARGE * 0.25, 0.0)
	assert_float(look.meter()).is_equal_approx(0.25, 0.001)
	assert_float(look.halo()).is_equal(0.0)


## GAME.md 6.2 and 8.5: a live cabinet's beacon breathes, slowly, well under once a second, never
## dark, with the glow round it, a map's detail rather than an alarm; for fewer flashes it holds
## steady. Charging, it is dimmer than at the low of a breath and has no glow, so the two read
## apart.
func test_a_live_beacon_breathes_slowly() -> void:
	var match_node := _match([KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var look := (match_node.arena.cabinets[0] as LiveCabinet).look()
	var was := Game.settings.flash_reduction
	var seen: Dictionary[bool, Array] = {}
	for steady: bool in [false, true]:
		Game.settings.flash_reduction = steady
		seen[steady] = []
		# Four seconds of it live, a frame at a time.
		for i: int in 240:
			look.step(1.0 / 60.0, LiveCabinet.CHARGE + i / 60.0, 0.0)
			assert_float(look.meter()).is_equal(1.0)
			assert_float(look.halo()).is_greater(0.0)
			seen[steady].append(look.beacon())
	Game.settings.flash_reduction = was
	var breaths: Array = seen[false]
	assert_float(breaths.min()).is_greater_equal(CabinetLook.LOW - 0.01)
	assert_float(breaths.max()).is_less_equal(CabinetLook.TOP + 0.01)
	var tops := 0
	var steepest := 0.0
	for i: int in range(1, breaths.size() - 1):
		steepest = maxf(steepest, absf(breaths[i] - breaths[i - 1]))
		if breaths[i] > breaths[i - 1] and breaths[i] >= breaths[i + 1]:
			tops += 1
	# Under once a second over four seconds, and never a jump from one frame to the next.
	assert_int(tops).is_less_equal(3)
	assert_float(steepest).is_less(0.05)
	assert_float(seen[true].min()).is_equal(seen[true].max())
	look.step(0.016, LiveCabinet.CHARGE * 0.9, 0.0)
	assert_float(look.beacon()).is_less(CabinetLook.LOW)
	assert_float(look.halo()).is_equal(0.0)


## GAME.md 6.2: an electrocuted kart is held where it died for a moment in its shock, flickering
## black and white, but for fewer flashes, 8.5, which holds it black, with black smoke rising off
## it, and only then springs apart as any wreck does, over a scorch on the floor; a room keeps the
## newest few scorches, the oldest going as another is laid.
func test_an_electrocuted_kart_flickers_smokes_and_leaves_a_scorch() -> void:
	var match_node := _match([KartInput.new(), KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	var was := Game.settings.flash_reduction
	for steady: bool in [false, true]:
		Game.settings.flash_reduction = steady
		var kart := match_node.kart_of(1 if steady else 0)
		kart.global_position = cabinet.global_position + cabinet.global_basis.z * 1.2
		var wrecks := _all(match_node, KartWreck)
		cabinet.charge_for(LiveCabinet.CHARGE + 0.5)
		cabinet.shock(kart)
		assert_bool(kart.alive).is_false()
		var shock := _all(match_node, KartShock).back() as KartShock
		assert_object(shock).is_not_null()
		assert_bool(KartShock.holds(kart)).is_true()
		assert_array(_all(match_node, KartWreck)).is_equal(wrecks)
		var scorch := _all(match_node, Scorch).back() as Scorch
		assert_object(scorch).is_not_null()
		var flat := Vector2(scorch.global_position.x - kart.global_position.x, 0.0)
		flat.y = scorch.global_position.z - kart.global_position.z
		assert_float(flat.length()).is_less(0.01)
		var black := 0
		var white := 0
		for i: int in 30:
			await get_tree().process_frame
			if not shock.holding():
				break
			if shock.blackened():
				black += 1
			else:
				white += 1
		assert_int(black).is_greater(0)
		if steady:
			assert_int(white).override_failure_message("flickered for fewer flashes").is_equal(0)
		else:
			assert_int(white).override_failure_message("never flickered").is_greater(0)
		await _runner.simulate_frames(int(KartShock.HOLD * 60.0) + 5, 17)
		assert_bool(shock.holding()).is_false()
		assert_bool(KartShock.holds(kart)).is_false()
		var sprung := _all(match_node, KartWreck).filter(
			func(n: Node) -> bool: return n not in wrecks
		)
		assert_int(sprung.size()).is_equal(1)
		assert_object(shock.get_node("Smoke")).is_not_null()
	Game.settings.flash_reduction = was
	# The newest few kept, the oldest going.
	var parent := cabinet.get_parent()
	var laid: Array[Scorch] = []
	for i: int in Scorch.MOST + 2:
		laid.append(Scorch.lay(parent, cabinet.global_position + Vector3(2.0, 0.0, i * 0.5)))
	var going := 0
	for node: Node in parent.get_children():
		if node is Scorch and (node as Scorch).going():
			going += 1
	assert_int(going).is_greater_equal(2)
	assert_bool(laid[0].going()).is_true()
	assert_bool(laid[laid.size() - 1].going()).is_false()


## GAME.md 6.2 and 8.4: a kart electrocuted is heard as a zap of its own, and the glass of its
## wreck once it springs apart, as long after as it is held in its shock.
func test_a_shock_is_heard_as_a_zap() -> void:
	assert_bool(Audio.LIBRARY.has(&"zap")).is_true()
	for file: String in Audio.LIBRARY[&"zap"]:
		assert_object(load(Audio.SFX_DIR + file)).override_failure_message(file).is_not_null()
	assert_float(Audio.SHOCK_HOLD).is_equal(KartShock.HOLD)


## Every node of the script [param kind] under [param match_node], oldest first.
func _all(match_node: Match, kind: Script) -> Array[Node]:
	var found: Array[Node] = []
	for node: Node in match_node.find_children("*", "", true, false):
		if is_instance_of(node, kind) and not node.is_queued_for_deletion():
			found.append(node)
	return found


## GAME.md 3.6: the kill is whoever shoved the kart in, within the window a pit's fall is credited
## in, and a teammate's shove into one is nobody's, not an own goal.
func test_a_shove_onto_a_cabinet_is_the_shovers_kill() -> void:
	var input := KartInput.new()
	var match_node := _match([input, KartInput.new()] as Array[KartInput])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	cabinet.charge_for(LiveCabinet.CHARGE + 0.5)
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
	cabinet.charge_for(LiveCabinet.CHARGE + 0.5)
	var kart := match_node.kart_of(0)
	kart.set_shielded(true)
	kart.protection_left = 3.0
	assert_int(kart.lives).is_greater(1)
	cabinet.shock(kart)
	assert_bool(kart.alive).override_failure_message("a shield or protection spared it").is_false()
	var other := match_node.kart_of(1)
	other.coast()
	cabinet.charge_for(LiveCabinet.CHARGE + 0.5)
	cabinet.shock(other)
	assert_bool(cabinet.live()).override_failure_message("spent by a kart it spared").is_true()
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
## the last word on a bot's driving keeps it off one as it keeps it out of a hole while it is live,
## or about to be: a bot sent past a live cabinet along its wall, or flat out straight at its door
## from a few meters out, lives, and keeps its body clear of it rather than hugging it. One
## charging, a good while from going live, is a wall to it like another.
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
	# Beside its door, rolling at it: a hole near it while the cabinet is live or nearly, and none
	# while it has charging to do yet.
	kart.global_position = cabinet.global_position + out * 1.6
	kart.face(-out)
	kart.motor.forward_speed = 3.0
	for at: float in [0.5, LiveCabinet.CHARGE - 1.0, LiveCabinet.CHARGE + 1.0]:
		cabinet.charge_for(at)
		brain.pits._holes_near()
		var feared := brain.pits._near.any(
			func(hole: Rect2) -> bool: return hole.encloses(cabinet.ground)
		)
		var lead := LiveCabinet.CHARGE - at <= BotPits.HORIZON + LiveCabinet.BOT_LEAD
		assert_bool(feared).override_failure_message("charged for %s" % at).is_equal(lead)
	cabinet.charge_for(LiveCabinet.CHARGE + 0.5)
	var closest := INF
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
			closest = minf(closest, cabinet._reach_of(kart.global_position))
	assert_bool(cabinet.live()).is_true()
	# Its middle never nearer the cabinet than half a kart and a little: its body clear of it.
	prints("MEASURE bots: nearest a live cabinet %.2f m" % closest)
	assert_float(closest).is_greater(LiveCabinet.KART.x * 0.5 + 0.1)


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
