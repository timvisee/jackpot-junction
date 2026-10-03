extends TutorialSuite
## The tutorial, GAME.md 9.4a: the map of rooms in a row joined by gates, and the first lessons,
## driving to shooting, with the checklist, the hint over the kart, the arrow on the floor and the
## HUD arriving a piece at a time.


## The rooms chain: every gate shut, nothing past the first room can be reached; open, the way
## through is blocked only by the boxes of the gallery.
## The last room, which three lessons share, is no bigger than the smallest map's floor and wider
## than it is tall.
func test_the_map_is_rooms_in_a_row_joined_by_gates() -> void:
	assert_array(LAYOUT.validate()).is_empty()
	var grid := LAYOUT.parse()
	assert_int(grid.spawns.size()).is_equal(5)
	assert_int(grid.portals.size()).is_equal(0)
	assert_int(grid.gates.size()).is_equal(11)
	assert_int(grid.targets.size()).is_equal(9)
	assert_int(grid.junctions.size()).is_equal(1)
	assert_object(grid.junction).is_equal(grid.junctions[0])
	assert_int(grid.pits.size()).is_equal(2)
	assert_int(grid.jackpots.size()).is_equal(2)
	assert_int(grid.flush_pads.size()).is_equal(4)
	assert_int(grid.coin_pads.size()).is_equal(6)
	assert_str(grid.glyph(TutorialJokers.PIT)).is_equal("X")
	# The last room is one room, the jokers room another, and a gate is wall.
	var last_room := grid.region_of(TutorialPads.SPAWN)
	assert_int(last_room).is_greater_equal(0)
	assert_int(grid.region_of(TutorialBank.JUNCTION)).is_equal(last_room)
	assert_int(grid.region_of(TutorialJokers.PIT)).is_not_equal(last_room)
	assert_int(grid.region_of(Vector2i(17, 36))).is_equal(-1)
	var low := Vector2i(grid.width, grid.height)
	var high := Vector2i(0, 0)
	for y: int in grid.height:
		for x: int in grid.width:
			if grid.region_of(Vector2i(x, y)) == last_room:
				low = Vector2i(mini(low.x, x), mini(low.y, y))
				high = Vector2i(maxi(high.x, x), maxi(high.y, y))
	var size := high - low + Vector2i.ONE
	assert_int(size.x).is_less_equal(31)
	assert_int(size.y).is_less_equal(15)
	assert_int(size.x).is_greater(size.y)
	var shut := _reachable(grid, ["#", "G"] as Array[String])
	assert_bool(shut.has(TutorialDrive.new().next_cell)).is_false()
	var open := _reachable(grid, ["#", "B"] as Array[String])
	assert_bool(open.has(TutorialShoot.WALL.position)).is_false()
	var broken := _reachable(grid, ["#"] as Array[String])
	assert_bool(broken.has(TutorialPads.SPAWN)).is_true()
	# Every lesson's cells are where the map has them: its gate a gate, its spawn floor.
	for lesson: TutorialLesson in [
		TutorialDrive.new(),
		TutorialSteer.new(),
		TutorialReverse.new(),
		TutorialNitro.new(),
		TutorialDrift.new(),
		TutorialShoot.new(),
		TutorialItems.new(),
		TutorialJokers.new(),
		TutorialPads.new(),
		TutorialBank.new(),
		TutorialFight.new(),
	]:
		if lesson.gate_cell.x >= 0:
			var gate := grid.glyph(lesson.gate_cell)
			assert_str(gate).override_failure_message(lesson.title).is_equal("G")
			var next := grid.glyph(lesson.next_cell)
			assert_str(next).override_failure_message(lesson.title).is_equal(".")
		assert_bool(grid.glyph(lesson.spawn_cell) in [".", "S"]).is_true()
	for cell: Vector2i in TutorialFight.PEN_GATES:
		assert_str(grid.glyph(cell)).is_equal("G")
	# The driving school's props stand on wall tops and the edges of the road, never in the way.
	for sign: Array in SchoolProps.SIGNS:
		assert_str(grid.glyph(sign[1])).is_equal("#")
	for cell: Vector2i in SchoolProps.BUNTING + [SchoolProps.EXAM_PLATE]:
		assert_str(grid.glyph(cell)).is_equal("#")
	for cell: Vector2i in (
		SchoolProps.CORRIDOR_CONES + SchoolProps.PILLAR_CONES + SchoolProps.BLOCKS
	):
		assert_str(grid.glyph(cell)).is_equal(".")
	for cell: Vector2i in [SchoolProps.BOOTH.position, SchoolProps.BOOTH.end - Vector2i.ONE]:
		assert_str(grid.glyph(cell)).is_equal("#")
	# The inspectors stand on wall tops, or outside the arena altogether.
	for post: Array in SchoolInspectors.POSTS:
		var cell: Vector2i = post[0]
		var inside := cell.x >= 0 and cell.y >= 0 and cell.x < grid.width and cell.y < grid.height
		if post[1]:
			assert_str(grid.glyph(cell)).is_equal("#")
		else:
			assert_bool(inside).is_false()
	# The pocket's target is past its pillar: no straight line from the window reaches it.
	for cell: Vector2i in [
		TutorialItems.POCKET,
		TutorialItems.WINDOW,
		Vector2i(19, 16),
		Vector2i(23, 15),
		Vector2i(23, 16)
	]:
		assert_str(grid.glyph(cell)).is_not_equal("#")
	for cell: Vector2i in [Vector2i(22, 15), Vector2i(22, 16), Vector2i(19, 14), Vector2i(19, 17)]:
		assert_str(grid.glyph(cell)).is_equal("#")
	# The guard's run is a dead end at its end, and the row sits in a pocket of its own, sealed
	# to the wall.
	assert_str(grid.glyph(Vector2i(3, 6))).is_equal("#")
	for cell: Vector2i in [
		Vector2i(2, 8),
		Vector2i(3, 8),
		Vector2i(4, 8),
		Vector2i(2, 14),
		Vector2i(3, 14),
		Vector2i(4, 14),
	]:
		assert_str(grid.glyph(cell)).is_equal("#")
	var sealed := _reachable(grid, ["#", "G"] as Array[String])
	assert_bool(sealed.has(TutorialItems.ROW[1])).is_false()
	for i: int in TutorialItems.ROW_WINDOW_TALL:
		assert_str(grid.glyph(TutorialItems.ROW_WINDOW + Vector2i(0, i))).is_equal(".")


## A gate is a wall until it opens: it sinks into the floor and stops standing in the way, and
## rises again shut.
func test_a_gate_sinks_open_and_rises_shut() -> void:
	var layout := ArenaLayout.new()
	layout.grid = "######\n#S.G.#\n######"
	layout.room = ROOM
	var arena: Arena = auto_free(ARENA_SCENE.instantiate())
	arena.layout = layout
	arena.bake_scenery = false
	add_child(arena)
	assert_int(arena.gates.size()).is_equal(1)
	var gate := arena.gates[0]
	assert_bool(gate.is_open).is_false()
	assert_array(gate.cells).is_equal([Vector2i(3, 1)] as Array[Vector2i])
	assert_object(arena.gate_at(Vector2i(3, 1))).is_same(gate)
	assert_object(arena.gate_at(Vector2i(1, 1))).is_null()
	assert_int(gate._bar_count).is_greater_equal(1)
	# Tweened in frame time, so the renderer is told not to interpolate the bars itself.
	assert_int(gate._bars.physics_interpolation_mode).is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	gate.open()
	await get_tree().create_timer(Gate.SECONDS + 0.2).timeout
	assert_float(gate.drop).is_equal_approx(1.0, 0.01)
	assert_bool(gate._shape.disabled).is_true()
	gate.close()
	await get_tree().create_timer(Gate.SECONDS * 0.3).timeout
	# A wall again from the first moment, while the bars are still on their way up.
	assert_bool(gate._shape.disabled).is_false()
	await get_tree().create_timer(Gate.SECONDS).timeout
	assert_float(gate.drop).is_equal_approx(0.0, 0.01)


## Lesson one: the list says so, driving fills the bar, the gate opens on it, and the kart through
## shuts it behind and starts the next lesson in the next room, with the HUD still bare.
func test_driving_up_the_corridor_opens_the_first_gate_and_the_next_lesson() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var lesson := run.current_lesson()
	assert_int(run.index).is_equal(0)
	assert_str(lesson.title).is_equal("Driving")
	assert_int(run.list.listed()).is_equal(1)
	assert_str(run.list._title.text).is_equal("Driving test  ·  Driving")
	assert_bool(tutorial._skip_entry.visible).is_true()
	# No word at the top: the driving school greeted the player already.
	assert_bool(run.notice.visible).is_false()
	assert_bool(run.kart().banks_passively).is_false()
	# The kill feed hangs under the list, not behind it.
	var feed := tutorial.match_node.hud.kill_feed()
	assert_float(feed.offset_top).is_greater_equal(run.list.offset_top + run.list.size.y)
	var rows := run.list.task_rows(lesson)
	assert_int(rows.size()).is_equal(1)
	# The arrow points up the corridor at the gate, and a gate gets no ring.
	await _runner.simulate_frames(1, 17)
	assert_bool(run.arrow._ring.visible).is_false()
	assert_str((rows[0]["label"] as RichTextLabel).get_parsed_text()).is_equal("Drive forward")
	assert_bool(rows[0].has("bar")).is_true()
	assert_str(run.hint.words()).is_equal("Hold %s to drive")
	var gate := tutorial.match_node.arena.gate_at(lesson.gate_cell)
	assert_bool(gate.is_open).is_false()
	# The kart is in the corridor, and the camera follows it alone, not the parked karts and the
	# penned bots rooms away.
	assert_float(run.kart().global_position.distance_to(run.cell(lesson.spawn_cell))).is_less(0.5)
	assert_array(tutorial.match_node.camera_rig.targets).is_equal([run.kart()] as Array[Node3D])
	# Bare: no corner block at all, no hand, and the corner's own hints never.
	var parts := tutorial.match_node.hud.block_parts(0)
	assert_bool((parts["box"] as Control).visible).is_false()
	assert_bool((parts["nitro"] as Control).visible).is_false()
	assert_bool((parts["pot"] as Control).visible).is_false()
	assert_bool(tutorial.match_node.hud.hand_of(0).visible).is_false()
	# The pads of the steering room and the lamps of the gallery are down from the start.
	assert_int(tutorial.match_node.find_children("ModePad_*", "", false, false).size()).is_equal(2)
	assert_int((run.lessons[5] as TutorialShoot).lights().size()).is_equal(TutorialShoot.TARGETS)
	Input.action_press(InputActions.THROTTLE)
	var opened := false
	for i: int in 600:
		await _runner.simulate_frames(1, 17)
		if gate.is_open:
			opened = true
			break
	assert_bool(opened).override_failure_message("the gate never opened").is_true()
	assert_bool(lesson.is_done()).is_true()
	assert_object(run.waiting_at).is_same(gate)
	# The list is a big green check for a second, under the lesson's name, then nothing until
	# the next lesson.
	assert_bool(run.list.is_checking()).is_true()
	assert_int(run.list.listed()).is_equal(1)
	assert_bool(run.list._title.visible).is_true()
	assert_bool(run.list._rows.visible).is_false()
	assert_bool(run.list._check.visible).is_true()
	# The arrow points at the gate now, and a doorway gets no ring.
	await _runner.simulate_frames(1, 17)
	assert_bool(run.arrow.visible).is_true()
	assert_bool(run.arrow._ring.visible).is_false()
	var aimed := run.arrow.target
	(
		assert_float(
			Vector2(aimed.x, aimed.z).distance_to(
				Vector2(gate.global_position.x, gate.global_position.z)
			)
		)
		. is_less(0.5)
	)
	# On through it, into the steering room.
	var started := false
	for i: int in 600:
		await _runner.simulate_frames(1, 17)
		if run.index == 1:
			started = true
			break
	Input.action_release(InputActions.THROTTLE)
	assert_bool(started).override_failure_message("the next lesson never started").is_true()
	assert_bool(gate.is_open).is_false()
	assert_str(run.current_lesson().title).is_equal("Steering")
	await _runner.simulate_frames(1, 17)
	assert_int(run.list.listed()).is_equal(1)
	assert_str(run.list._title.text).contains("Steering")


## Steering counts the heading, left then right, only while moving forward; sawing the wheel back
## and forth does not add up, and one direction alone is not enough.
func test_steering_counts_both_ways_from_the_heading() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(1)
	var lesson := run.current_lesson() as TutorialSteer
	var kart := run.kart()
	assert_array(lesson._left.actions).is_equal([InputActions.STEER_LEFT] as Array[StringName])
	assert_array(lesson._right.actions).is_equal([InputActions.STEER_RIGHT] as Array[StringName])
	# By the pads the word at the top is about the two ways to drive; away from them it is not.
	_put(tutorial, Vector2i(18, 33), Vector3(0.0, 0.0, -1.0))
	await _runner.simulate_frames(2, 17)
	assert_bool(run.notice.is_saying(&"modes")).is_true()
	assert_str(run.notice.said()).contains("Choose Simple or Advanced driving")
	assert_bool(run.notice._info.visible).is_true()
	# The menu's key is drawn into the second line, not written as a word.
	assert_int(run.notice._lines.get_child_count()).is_equal(2)
	var second := run.notice._lines.get_child(1) as HBoxContainer
	var drawn := false
	for part: Node in second.get_children():
		drawn = drawn or part is InputGlyph
	assert_bool(drawn).is_true()
	assert_float(run.notice.offset_top).is_equal(TutorialNotice.TOP)
	assert_bool(lesson.show_all).is_true()
	assert_str(lesson._left.text).is_equal("Turn left")
	assert_int(run.list.task_rows(lesson).size()).is_equal(2)
	_put(tutorial, Vector2i(18, 42), Vector3(0.0, 0.0, -1.0))
	await _runner.simulate_frames(2, 17)
	assert_bool(run.notice.is_saying(&"modes")).is_false()
	# Turning on the spot counts, to the left; back again counts to the right, each its own.
	kart.motor.heading += 0.5
	lesson.step(DT)
	assert_float(lesson._left.progress).is_equal_approx(0.5 / (TutorialSteer.TURNS * TAU), 0.001)
	assert_float(lesson._right.progress).is_equal(0.0)
	kart.motor.heading -= 0.5
	lesson.step(DT)
	assert_float(lesson._left.progress).is_equal_approx(0.5 / (TutorialSteer.TURNS * TAU), 0.001)
	assert_float(lesson._right.progress).is_equal_approx(0.5 / (TutorialSteer.TURNS * TAU), 0.001)
	lesson._right.progress = 0.0
	# Moving and turning left fills the left task, and nothing of the right one.
	# Pressed again every frame: a stray axis event from a keyboard with a joystick in it would
	# release the action under the test.
	for i: int in 400:
		Input.action_press(InputActions.THROTTLE)
		Input.action_press(InputActions.STEER_LEFT)
		await _runner.simulate_frames(1, 17)
		if lesson._left.done:
			break
	Input.action_release(InputActions.STEER_LEFT)
	assert_bool(lesson._left.done).override_failure_message("left never filled").is_true()
	assert_float(lesson._right.progress).is_less(0.3)
	for i: int in 400:
		Input.action_press(InputActions.THROTTLE)
		Input.action_press(InputActions.STEER_RIGHT)
		await _runner.simulate_frames(1, 17)
		if lesson.is_done():
			break
	Input.action_release(InputActions.STEER_RIGHT)
	Input.action_release(InputActions.THROTTLE)
	assert_bool(lesson.is_done()).override_failure_message("right never filled").is_true()


## A pad of the steering room switches the way of driving, and says so.
func test_a_mode_pad_switches_the_way_of_driving() -> void:
	var tutorial := await _start()
	tutorial.run._start(1)
	await _runner.simulate_frames(2, 17)
	var pads := tutorial.match_node.find_children("ModePad_*", "", false, false)
	var simple: ModePad = null
	for pad: ModePad in pads:
		if pad.mode == Settings.DRIVE_SIMPLE:
			simple = pad
	assert_bool(simple.is_lit()).is_false()
	assert_float(simple._ring.emission_energy_multiplier).is_equal(0.0)
	assert_object(simple._label.get_theme_color("font_color")).is_equal(ModePad.OFF_PICTURE)
	assert_str(simple._label.text).is_equal("SIMPLE")
	assert_object(simple.find_child("*", true, false) as Label3D).is_null()
	simple._on_body_entered(tutorial.run.kart())
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_SIMPLE)
	assert_bool(simple.is_lit()).is_true()
	await _runner.simulate_frames(1, 17)
	assert_float(simple._ring.emission_energy_multiplier).is_greater(0.0)
	assert_object(simple._label.get_theme_color("font_color")).is_equal(Palette.CHIP_WHITE)
	# Simple driving says the tasks its own way, within the hint's quarter second.
	await _runner.simulate_frames(20, 17)
	assert_str(tutorial.run.hint.words()).contains("Push %s")


## A player who has never said how they drive is asked before the kart will move, and the first
## lesson starts on the answer; one who has is not asked.
func test_a_player_who_never_chose_how_to_drive_is_asked_first() -> void:
	Game.settings.drive_modes = ["", "", "", ""]
	var tutorial := await _start()
	var kart := tutorial.run.kart()
	assert_bool(kart.frozen).is_true()
	assert_int(tutorial.run.index).is_equal(-1)
	var choice: DriveChoice = tutorial.layer.find_child("DriveChoice", true, false)
	assert_object(choice).override_failure_message("nobody asked").is_not_null()
	choice.card(Settings.DRIVE_SIMPLE).pressed.emit()
	await _runner.simulate_frames(2, 17)
	assert_bool(kart.frozen).is_false()
	assert_int(tutorial.run.index).is_equal(0)
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_SIMPLE)


## Braking from speed, then reversing, in that order.
func test_braking_then_reversing() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(2)
	var lesson := run.current_lesson() as TutorialReverse
	_put(tutorial, Vector2i(33, 26), Vector3(1.0, 0.0, 0.0))
	Input.action_press(InputActions.THROTTLE)
	await _runner.simulate_frames(90, 17)
	Input.action_release(InputActions.THROTTLE)
	assert_bool(lesson._stop.done).is_false()
	Input.action_press(InputActions.BRAKE)
	for i: int in 300:
		await _runner.simulate_frames(1, 17)
		if lesson._stop.done:
			break
	assert_bool(lesson._stop.done).override_failure_message("never stopped").is_true()
	for i: int in 600:
		await _runner.simulate_frames(1, 17)
		if lesson.is_done():
			break
	Input.action_release(InputActions.BRAKE)
	assert_bool(lesson.is_done()).override_failure_message("never reversed far enough").is_true()


## Nitro: the tank comes full, the nitro and the speed come into the corner with a pointer, the
## bar is how much is burnt, and running it dry is the lesson; the pointer goes with the task.
func test_burning_the_tank_dry_with_the_nitro_pointed_out() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(3)
	var lesson := run.current_lesson() as TutorialNitro
	var kart := run.kart()
	assert_float(kart.nitro_charge).is_equal(1.0)
	var parts := tutorial.match_node.hud.block_parts(0)
	await _runner.simulate_frames(2, 17)
	assert_bool((parts["box"] as Control).visible).is_true()
	assert_bool((parts["nitro"] as Control).visible).is_true()
	assert_bool((parts["speed"] as Control).visible).is_true()
	assert_bool((parts["pot"] as Control).visible).is_false()
	assert_bool(run.reveal.is_pointing()).is_true()
	assert_str(run.notice.said()).contains("Use nitro to boost your speed")
	assert_bool(run.arrow.visible).is_false()
	assert_bool(run.arrow._ring.visible).is_false()
	assert_bool(run.reveal._ring.visible).is_true()
	assert_bool(run.reveal._pointer is PanelContainer).is_true()
	var card := run.reveal._pointer as Control
	var ring := run.reveal._ring as Control
	var apart := (ring.position + ring.size * 0.5).distance_to(
		card.position + card.get_combined_minimum_size() * 0.5
	)
	assert_float(apart).is_less(2.0)
	var screen := tutorial.match_node.hud.get_viewport().get_visible_rect().size.length()
	assert_float(ring.size.x).is_equal_approx(screen * HudReveal.RING_FROM * 2.0, 1.0)
	_put(tutorial, Vector2i(50, 26), Vector3(1.0, 0.0, 0.0))
	Input.action_press(InputActions.THROTTLE)
	Input.action_press(InputActions.NITRO)
	await _runner.simulate_frames(30, 17)
	assert_float(lesson._burn.progress).is_between(0.05, 0.95)
	for i: int in 300:
		await _runner.simulate_frames(1, 17)
		if lesson.is_done():
			break
	Input.action_release(InputActions.NITRO)
	Input.action_release(InputActions.THROTTLE)
	assert_bool(lesson.is_done()).override_failure_message("the tank never ran dry").is_true()
	await _runner.simulate_frames(2, 17)
	assert_bool(run.reveal.is_pointing()).is_false()


## Drifting: a drift started is the tap, and three turbos out of drifts are the rest, the bar
## being the drift's charge toward one.
func test_drifting_counts_the_tap_and_three_turbos() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(4)
	var lesson := run.current_lesson() as TutorialDrift
	var kart := run.kart()
	# Looked at between ticks: the kart's own tick would put the slide down again, since the kart
	# is standing still.
	assert_array(lesson._turbo.steps).is_equal(TutorialDrift.STEPS)
	assert_str(TutorialDrift.STEPS[1]).is_equal("Hold the drift to build turbo")
	assert_str(TutorialDrift.STEPS[2]).is_equal("Straighten up to launch")
	assert_str(run.notice.said()).contains("Drift in tight corners")
	assert_int(lesson._tap.steps_done).is_equal(0)
	# Tires and barrels to drift round, each with a body in it, where the map has floor.
	var props := tutorial.match_node.find_children("DriftProp*", "", false, false)
	assert_int(props.size()).is_equal(TutorialDrift.PROPS.size())
	var barrels := tutorial.match_node.get_node("DriftProp1") as StaticBody3D
	var body := (barrels.get_child(0) as CollisionShape3D).shape as BoxShape3D
	assert_vector(body.size).is_equal(TutorialDrift.BARRELS_BODY)
	for rect: Rect2i in TutorialDrift.PROPS:
		assert_str(tutorial.match_node.arena.grid.glyph(rect.position)).is_equal(".")
	assert_object(tutorial.match_node.arena.get_node_or_null("Props")).is_not_null()
	await _runner.simulate_frames(1, 17)
	assert_str(run.hint.words()).is_equal("steps")
	kart.motor.drifting = true
	kart.motor.drift_time = 0.3
	lesson.step(DT)
	assert_bool(lesson._tap.done).is_true()
	assert_int(lesson._turbo.steps_done).is_equal(1)
	lesson.step(DT)
	assert_float(lesson._turbo.progress).is_between(0.3, 0.7)
	# Long enough and fast enough for the turbo: the second step is ticked.
	kart.motor.drift_time = kart.stats.drift_min_duration + 0.1
	kart.motor.velocity = Vector3(0.0, 0.0, -kart.stats.top_speed)
	lesson.step(DT)
	assert_int(lesson._turbo.steps_done).is_equal(2)
	# The turbo launched: all three for a moment, then round again from the start.
	kart.motor.drifting = false
	Events.drift_boosted.emit(kart.slot)
	lesson.step(DT)
	assert_int(lesson._turbo.steps_done).is_equal(3)
	assert_int(lesson._turbo.count).is_equal(1)
	lesson.step(TutorialDrift.LAUNCHED_FOR)
	assert_int(lesson._turbo.steps_done).is_equal(0)
	await _runner.simulate_frames(1, 17)
	assert_int(run.list.task_rows(lesson).size()).is_equal(2)
	for i: int in TutorialDrift.TURBOS - 1:
		Events.drift_boosted.emit(kart.slot)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_true()
	assert_str(run.list.task_rows(lesson)[1]["label"].text).contains("3/3")


## Shooting: each target counts once, its light going green, the loose boxes count for nothing,
## and one row of the wall of boxes down, both deep, is the way out.
func test_shooting_the_targets_and_through_the_boxes() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(5)
	var lesson := run.current_lesson() as TutorialShoot
	var arena := tutorial.match_node.arena
	# In the gallery: from the start corridor the kart would count as through the gallery's gate.
	_put(tutorial, lesson.spawn_cell, Vector3(-1.0, 0.0, 0.0))
	# Nothing to say at the top in here.
	assert_bool(run.notice.visible).is_false()
	var shot: Bullet = auto_free(Bullet.new())
	shot.owner_slot = 0
	# A light beside every target, red until it is counted.
	var lights := lesson.lights()
	assert_int(lights.size()).is_equal(TutorialShoot.TARGETS)
	for light: TrafficLight in lights:
		assert_bool(light.green).is_false()
	# The gallery's own five; the rooms after have targets of their own, which count for nothing.
	var gallery: Array[Target] = []
	for cell: Vector2i in [
		Vector2i(40, 5), Vector2i(57, 5), Vector2i(48, 10), Vector2i(40, 16), Vector2i(57, 16)
	]:
		gallery.append(lesson.target_at(cell))
	var elsewhere := lesson.target_at(TutorialItems.POCKET)
	elsewhere.take_hit(shot)
	await _runner.simulate_frames(1, 17)
	assert_int(lesson._hit.count).is_equal(0)
	gallery[0].take_hit(shot)
	await _runner.simulate_frames(1, 17)
	assert_int(lesson._hit.count).is_equal(1)
	var greens := 0
	for light: TrafficLight in lesson.lights():
		greens += 1 if light.green else 0
	assert_int(greens).is_equal(1)
	# The same target again, once it is back up, is not another.
	gallery[0]._stand(true)
	gallery[0].take_hit(shot)
	assert_int(lesson._hit.count).is_equal(1)
	for i: int in range(1, gallery.size()):
		gallery[i].take_hit(shot)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson._hit.done).is_true()
	assert_bool(lesson.is_done()).is_false()
	var grid := arena.grid
	for i: int in arena.crates.size():
		if not TutorialShoot.WALL.has_point(grid.crates[i]):
			arena.crates[i].hit(0)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_false()
	# The ring goes round the whole wall of boxes.
	await _runner.simulate_frames(1, 17)
	assert_object(lesson.current()).is_same(lesson._boxes)
	assert_float(run.arrow.ring_radius).is_greater(2.0)
	# One box of a row, and one of another: no way through yet.
	_crate_at(arena, Vector2i(32, 9)).hit(0)
	_crate_at(arena, Vector2i(33, 10)).hit(0)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_way_through()).is_false()
	assert_bool(lesson.is_done()).is_false()
	_crate_at(arena, Vector2i(33, 9)).hit(0)
	await _runner.simulate_frames(4, 17)
	var now := lesson.current()
	(
		assert_bool(lesson.is_done())
		. override_failure_message(
			"down %s, on %s" % [lesson._down.keys(), now.text if now != null else "nothing"]
		)
		. is_true()
	)
	assert_bool(arena.gate_at(lesson.gate_cell).is_open).is_true()


## The pause menu's Skip step passes the lesson, and a kart that dies comes back in its own room.
func test_skipping_a_lesson_and_coming_back_in_the_room() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(3)
	var lesson := run.current_lesson()
	run.skip()
	await _runner.simulate_frames(2, 17)
	assert_bool(lesson.is_done()).is_true()
	assert_object(run.waiting_at).is_not_null()
	var kart := run.kart()
	kart.die(&"pit", -1)
	var back := false
	for i: int in 300:
		await _runner.simulate_frames(1, 17)
		if kart.alive:
			back = true
			break
	assert_bool(back).is_true()
	assert_float(kart.global_position.distance_to(run.cell(lesson.spawn_cell))).is_less(0.5)


## A debug build's Skip to end, on the pause menu, passes the test on the spot: the run is over,
## the kart is down in the last room, and the license is numbered with nothing earned.
func test_skip_to_end_passes_the_test_on_the_spot() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var entries: Array[String] = []
	for button: Button in tutorial.menu.find_children("*", "Button", true, false):
		entries.append(button.text)
	assert_array(entries).contains(["Skip to end"])
	assert_int(entries.find("Skip to end")).is_equal(entries.find("Skip lesson") + 1)
	Game.settings.license_number = ""
	var over: Array[bool] = []
	run.finished.connect(func() -> void: over.append(true))
	run.skip_to_end()
	assert_int(over.size()).is_equal(1)
	var last := run.lessons[run.lessons.size() - 1]
	assert_float(run.kart().global_position.distance_to(run.cell(last.spawn_cell))).is_less(0.5)
	assert_str(Game.settings.license_number).starts_with("JJ-")
	assert_int(Game.settings.license_endorsements.size()).is_equal(0)
	# Asked again, nothing: the test is over.
	run.skip_to_end()
	assert_int(over.size()).is_equal(1)
