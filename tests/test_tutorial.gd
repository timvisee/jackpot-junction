extends TutorialSuite
## The tutorial, GAME.md 9.4a: the one open lot whose pieces rise lesson by lesson, the first
## lessons, driving, speed and shooting, with the clipboard, the control over the kart, the arrow on
## the floor and the HUD arriving a piece at a time; skipping a lesson, and going straight to the
## exam.


## One open lot of a regular map's size, walled round, one room, with a trench across it wall to
## wall; every lesson's spots on its floor, where the map has what they need.
func test_the_lot_is_one_open_room_with_a_trench_across_it() -> void:
	assert_array(LAYOUT.validate()).is_empty()
	var grid := LAYOUT.parse()
	assert_int(grid.width).is_equal(32)
	assert_int(grid.height).is_equal(18)
	assert_int(grid.gates.size()).is_equal(0)
	assert_int(grid.portals.size()).is_equal(0)
	assert_int(grid.spawns.size()).is_equal(1 + TestGround.LIFTS.size())
	assert_int(grid.targets.size()).is_equal(TestGround.TARGETS.size())
	assert_int(grid.junctions.size()).is_equal(1)
	assert_int(grid.jackpots.size()).is_equal(2)
	assert_int(grid.flush_pads.size()).is_equal(4)
	assert_array(grid.pits).is_equal([TestGround.TRENCH] as Array[Rect2i])
	# The trench runs from wall to wall, and the lot is still one room either side of it.
	assert_str(grid.glyph(Vector2i(TestGround.TRENCH.position.x, 0))).is_equal("#")
	assert_str(grid.glyph(Vector2i(TestGround.TRENCH.position.x, grid.height - 1))).is_equal("#")
	var lot := grid.region_of(TestGround.START)
	assert_int(grid.region_of(TestGround.ACROSS)).is_equal(lot)
	assert_int(grid.region_of(TestGround.PARKED)).is_equal(lot)
	var all := _reachable(grid, ["#"] as Array[String])
	var dry := _reachable(grid, ["#", "X"] as Array[String])
	# The start and the far side of the trench are on the west; the parked kart east of it.
	assert_bool(all.has(TestGround.PARKED)).is_true()
	assert_bool(dry.has(TestGround.ACROSS)).is_true()
	assert_bool(dry.has(TestGround.PARKED)).is_false()
	assert_str(grid.glyph(TestGround.START)).is_equal("S")
	# Every other spot a lesson names is floor.
	var spots: Array[Vector2i] = [
		TestGround.SIMPLE_PAD,
		TestGround.ADVANCED_PAD,
		TestGround.ROUNDABOUT,
		TestGround.RUN_FROM,
		TestGround.DRIFT_RING,
		TestGround.ITEM_BOX,
		TestGround.PARKED,
		TestGround.ACROSS,
	]
	spots.append_array(TestGround.LANE)
	for spot: Vector2i in spots:
		assert_bool(grid.glyph(spot) == ".").override_failure_message(str(spot)).is_true()
	for spot: Vector2i in TestGround.TARGETS:
		assert_str(grid.glyph(spot)).is_equal("R")
	for spot: Vector2i in TestGround.FLUSH_PADS:
		assert_str(grid.glyph(spot)).is_equal("F")
	for spot: Vector2i in TestGround.LIFTS:
		assert_str(grid.glyph(spot)).is_equal("s")
	assert_str(grid.glyph(TestGround.JACKPOT)).is_equal("K")
	assert_str(grid.glyph(TestGround.JUNCTION)).is_equal("J")


## Up, the lot is bare but for the start, the pads beside it and the dressing: every piece a lesson
## brings is held under the floor, out of sight and out of play; the trench is shut, floor to a
## kart and to the bots' map. Six lessons, the first running.
func test_every_piece_waits_under_the_floor_and_the_trench_is_shut() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var arena := tutorial.match_node.arena
	assert_int(run.lessons.size()).is_equal(6)
	assert_int(run.index).is_equal(0)
	assert_str(run.current_lesson().title).is_equal("Driving")
	for pad: FlushPad in arena.flush_pads:
		assert_bool(pad.visible).is_false()
	for zone: JackpotZone in arena.jackpot_zones:
		assert_bool(zone.visible).is_false()
	for crate: Crate in arena.crates:
		assert_int(crate.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	for target: Target in arena.targets:
		assert_bool(target.visible).is_false()
	assert_bool(arena.junction.visible).is_false()
	# The parked kart and the bots are held too, and no turret takes them for a target.
	for slot: PlayerSlot in run.dummies + run.bots:
		assert_bool(slot.kart.visible).is_false()
		assert_bool(slot.kart.is_targetable()).is_false()
	# Shut, the trench is no pit: the bots' map goes over it, and its shaft is out of sight.
	assert_object(run.trench).is_not_null()
	assert_bool(run.trench.is_open()).is_false()
	assert_bool(arena.grid.pits.is_empty()).is_true()
	assert_bool(tutorial.match_node.nav.is_blocked(TestGround.TRENCH.position)).is_false()
	assert_bool(arena.pits[0].visible).is_false()
	# The kart on the start, facing up the lane; the camera on it alone.
	assert_float(run.kart().global_position.distance_to(run.cell(TestGround.START))).is_less(0.5)
	assert_array(tutorial.match_node.camera_rig.targets).is_equal([run.kart()] as Array[Node3D])
	# The dressing: the inspectors on the walls, the L on the kart.
	var inspectors: SchoolInspectors = arena.get_node("SchoolInspectors")
	assert_int(inspectors.people.size()).is_equal(SchoolInspectors.POSTS.size())
	var plate := run.kart().get_node_or_null("Body/Plate")
	assert_str(plate.get_meta(&"plate")).is_equal("L")


## A piece comes up in its outline, then out of the floor, and is in play once it is up, not
## before; a flat one turns over on a panel of the floor's look; one lowered goes back the way it
## came and is held there; one brought up at once is simply there.
func test_a_piece_rises_out_of_the_floor_and_is_in_play_once_up() -> void:
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var piece := Node3D.new()
	holder.add_child(piece)
	piece.position = Vector3(2.0, 0.0, 3.0)
	RisingPiece.hold(piece)
	assert_bool(piece.visible).is_false()
	assert_bool(RisingPiece.is_up(piece)).is_false()
	var up := [false]
	var coming := RisingPiece.bring(
		piece, Vector2.ONE, RisingPiece.Way.RISE, 0.0, null, func() -> void: up[0] = true
	)
	assert_object(coming).is_not_null()
	# Brought again while it comes, nothing more.
	assert_object(RisingPiece.bring(piece, Vector2.ONE)).is_null()
	await await_millis(int(RisingPiece.MARK * 500.0))
	assert_bool(piece.visible).is_false()
	assert_object(coming.get_node_or_null("Outline")).is_not_null()
	await await_millis(int((RisingPiece.MARK * 0.5 + RisingPiece.RISE * 0.3) * 1000.0))
	assert_bool(piece.visible).is_true()
	assert_float(piece.position.y).is_less(-0.05)
	assert_bool(RisingPiece.is_up(piece)).is_false()
	await await_millis(int(RisingPiece.RISE * 1000.0) + 200)
	assert_bool(up[0]).is_true()
	assert_bool(RisingPiece.is_up(piece)).is_true()
	assert_vector(piece.position).is_equal_approx(Vector3(2.0, 0.0, 3.0), Vector3.ONE * 0.001)
	assert_bool(is_instance_valid(coming)).is_false()
	# Lowered, it turns back over and is held.
	RisingPiece.lower(piece, Vector2.ONE)
	await await_millis(int(RisingPiece.FLIP * 1000.0) + 200)
	assert_bool(piece.visible).is_false()
	assert_int(piece.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	assert_vector(piece.position).is_equal_approx(Vector3(2.0, 0.0, 3.0), Vector3.ONE * 0.001)
	# Turned over: its back is the floor's until it is up.
	RisingPiece.bring(piece, Vector2.ONE, RisingPiece.Way.FLIP)
	await await_millis(int((RisingPiece.MARK + RisingPiece.FLIP * 0.3) * 1000.0))
	assert_object(piece.get_node_or_null("PanelBack")).is_not_null()
	# Brought up at once meanwhile, it is simply there.
	RisingPiece.at_once(piece)
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(RisingPiece.is_up(piece)).is_true()
	assert_vector(piece.rotation).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.001)


## Driving: the lane of cones and the ring come up; ten meters forward, then a full turn of the
## heading either way, sawing back and forth adding up to nothing. The pads beside the start say
## what they are while the kart is near, switch the way of driving, and go back into the floor
## once the lesson is done.
func test_driving_forward_then_round_the_cones() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var lesson := run.current_lesson() as TutorialDrive
	assert_int(lesson.piece_nodes().size()).is_equal(TestGround.LANE.size() + TestGround.RING_CONES)
	await await_millis(int((RisingPiece.MARK + RisingPiece.RISE) * 1000.0) + 900)
	for cone: Node3D in lesson.piece_nodes():
		assert_bool(RisingPiece.is_up(cone)).is_true()
	# Nothing said under the lesson's name but, by the pads, what they are.
	assert_bool(run.list.is_saying(&"modes")).is_true()
	assert_str(run.list.said()).contains("Choose Simple or Advanced driving")
	var rows := run.list.task_rows(lesson)
	assert_int(rows.size()).is_equal(1)
	assert_int((rows[0]["controls"] as Control).get_child_count()).is_equal(1)
	assert_str(run.hint.shows()).contains("|")
	for i: int in 400:
		Input.action_press(InputActions.THROTTLE)
		await _runner.simulate_frames(1, 17)
		if lesson._drive.done:
			break
	Input.action_release(InputActions.THROTTLE)
	assert_bool(lesson._drive.done).override_failure_message("never drove ten meters").is_true()
	assert_object(lesson.current()).is_same(lesson._round)
	await _runner.simulate_frames(1, 17)
	assert_int(run.list.task_rows(lesson).size()).is_equal(2)
	# Away from the pads, nothing said.
	assert_bool(run.list.is_saying(&"modes")).is_false()
	var motor := run.kart().motor
	motor.heading += 1.0
	lesson.step(DT)
	motor.heading -= 1.0
	lesson.step(DT)
	assert_float(lesson._round.progress).is_equal_approx(0.0, 0.001)
	for i: int in 8:
		motor.heading -= TAU / 7.0
		lesson.step(DT)
	assert_bool(lesson._round.done).is_true()
	var pads := lesson.pads()
	assert_int(pads.size()).is_equal(2)
	await _runner.simulate_frames(2, 17)
	assert_int(run.index).is_equal(1)
	await await_millis(int(RisingPiece.FLIP * 1000.0) + 200)
	for pad: ModePad in pads:
		assert_bool(pad.visible).is_false()


## A cone the player's kart hits goes over, away from the kart, down for good, counted for the
## license, and an inspector writes it down; a cone a bot knocks over is not the player's.
func test_a_cone_knocked_over_is_counted_and_noted() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var lesson := run.current_lesson() as TutorialDrive
	await await_millis(int((RisingPiece.MARK + RisingPiece.RISE) * 1000.0) + 900)
	var cone := lesson.piece_nodes()[0] as SchoolCone
	assert_bool(RisingPiece.is_up(cone)).is_true()
	var inspectors: SchoolInspectors = tutorial.match_node.arena.get_node("SchoolInspectors")
	for each: Dictionary in inspectors.people:
		each["writing"] = 0.0
		each["next_note"] = 99.0
	_put(tutorial, TestGround.START, TestGround.NORTH)
	cone._on_body_entered(run.kart())
	assert_bool(cone.down).is_true()
	assert_int(run.cones).is_equal(1)
	var noted := false
	for each: Dictionary in inspectors.people:
		noted = noted or is_zero_approx(float(each["next_note"]))
	assert_bool(noted).is_true()
	# Down for good: hit again, nothing more.
	cone._on_body_entered(run.kart())
	assert_int(run.cones).is_equal(1)
	await await_millis(int(SchoolCone.FALL * 1000.0) + 200)
	assert_float(cone.global_basis.y.dot(Vector3.UP)).is_less(0.2)
	var other := lesson.piece_nodes()[1] as SchoolCone
	other.knock(run.bots[0].index, other.global_position + Vector3.FORWARD)
	assert_bool(other.down).is_true()
	assert_int(run.cones).is_equal(1)


## A pad beside the start switches the way of driving, and says so.
func test_a_mode_pad_switches_the_way_of_driving() -> void:
	var tutorial := await _start()
	var pads := (tutorial.run.current_lesson() as TutorialDrive).pads()
	var simple: ModePad = null
	for pad: ModePad in pads:
		if pad.mode == Settings.DRIVE_SIMPLE:
			simple = pad
	assert_bool(simple.is_lit()).is_false()
	assert_str(simple._label.text).is_equal("SIMPLE")
	simple._on_body_entered(tutorial.run.kart())
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_SIMPLE)
	assert_bool(simple.is_lit()).is_true()
	# Simple driving shows the way to push, within the hint's quarter second.
	await _runner.simulate_frames(20, 17)
	assert_str(tutorial.run.hint.shows()).starts_with("true|")


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


## As a lesson starts the clipboard comes up large in the middle of the screen, then flies to its
## corner on its own after a moment and a half, or sooner once the kart drives, GAME.md 9.4a.
func test_the_clipboard_comes_up_in_the_middle_then_flies_to_its_corner() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run.skip()
	await _runner.simulate_frames(2, 17)
	assert_int(run.index).is_equal(1)
	var board := run.list.board
	# The PASSED stamp has its second first.
	await _past_the_stamp(run)
	assert_bool(run.list.is_flying_in()).is_true()
	await _runner.simulate_frames(2, 17)
	assert_float(board.scale.x).is_greater(1.2)
	var middle := run.list.get_global_transform() * (run.list.size * 0.5)
	assert_float(middle.distance_to(board.size * 0.5)).is_less(4.0)
	var wait := TutorialList.INTRO_HOLD + TutorialList.FLY_FOR + 0.3
	await _runner.simulate_frames(int(wait / 0.017), 17)
	assert_bool(run.list.is_flying_in()).is_false()
	assert_float(board.scale.x).is_equal_approx(1.0, 0.001)
	assert_vector(board.position).is_equal_approx(Vector2.ZERO, Vector2.ONE * 0.01)
	# The next lesson's comes up the same way, and driving sends it on its way at once.
	run.skip()
	await _runner.simulate_frames(1, 17)
	await _past_the_stamp(run)
	assert_int(run.index).is_equal(2)
	assert_bool(run.list.is_flying_in()).is_true()
	run.kart().velocity = Vector3(0.0, 0.0, -TutorialList.DRIVEN * 2.0)
	run.list._fly(0.0)
	assert_float(run.list._intro_left).is_equal(0.0)
	assert_object(run.list._flight).is_not_null()


## Speed: the tank comes full, the nitro and the speed come into the corner pointed at, the bar is
## how much is burnt, and running it dry is the lesson; the drift round the ring of cones is an
## extra, dimmer under Extra, which the lesson does not wait for and one turbo ticks.
func test_burning_the_tank_dry_with_a_drift_as_an_extra() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run.skip()
	await _runner.simulate_frames(2, 17)
	var lesson := run.current_lesson() as TutorialNitro
	var kart := run.kart()
	assert_float(kart.nitro_charge).is_equal(1.0)
	var parts := tutorial.match_node.hud.block_parts(0)
	assert_bool((parts["nitro"] as Control).visible).is_true()
	assert_bool(run.reveal.is_pointing()).is_true()
	assert_bool(run.reveal.has_card()).is_false()
	assert_str(run.list.said()).contains("Use nitro to boost your speed")
	assert_bool(lesson._drift.extra).is_true()
	assert_str(lesson._drift.label(false)).starts_with("Extra: ")
	assert_object(lesson.current()).is_same(lesson._burn)
	await _past_the_stamp(run)
	await _runner.simulate_frames(1, 17)
	assert_int(run.list.task_rows(lesson).size()).is_equal(2)
	# One turbo ticks the extra.
	Events.drift_boosted.emit(kart.slot)
	assert_bool(lesson._drift.done).is_true()
	assert_bool(lesson.is_done()).is_false()
	_put(tutorial, TestGround.RUN_FROM, TestGround.EAST)
	for i: int in 400:
		Input.action_press(InputActions.THROTTLE)
		Input.action_press(InputActions.NITRO)
		await _runner.simulate_frames(1, 17)
		if lesson._burn.done:
			break
	Input.action_release(InputActions.NITRO)
	Input.action_release(InputActions.THROTTLE)
	assert_bool(lesson._burn.done).override_failure_message("the tank never ran dry").is_true()
	await _runner.simulate_frames(2, 17)
	assert_int(run.index).is_equal(2)


## Shooting: the targets come up with their lamps; each counts once, its lamp green; then the box
## comes up with a Turret in it, the lamps go dark, and only the Turret's hits count, which it
## lands of its own accord, every turret hunting targets in here.
func test_shooting_the_targets_then_the_turret_hits_them() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	assert_bool(Turret.hunts_targets).is_true()
	run.skip()
	await _runner.simulate_frames(2, 17)
	run.skip()
	await _runner.simulate_frames(2, 17)
	var lesson := run.current_lesson() as TutorialShoot
	assert_str(lesson.title).is_equal("Shooting")
	await await_millis(int((RisingPiece.MARK + RisingPiece.RISE) * 1000.0) + 700)
	var targets := lesson._targets
	assert_int(targets.size()).is_equal(TestGround.TARGETS.size())
	for target: Target in targets:
		assert_bool(RisingPiece.is_up(target)).is_true()
	for light: TrafficLight in lesson.lights():
		assert_bool(light.green).is_false()
	# The player's own shots count once a target.
	targets[0].struck.emit(targets[0], 0)
	targets[0].struck.emit(targets[0], 0)
	assert_int(lesson._hit.count).is_equal(1)
	targets[1].struck.emit(targets[1], 0)
	targets[2].struck.emit(targets[2], 0)
	assert_bool(lesson._hit.done).is_true()
	# The lamps dark again, and the box coming up.
	for light: TrafficLight in lesson.lights():
		assert_bool(light.green).is_false()
	await await_millis(int((RisingPiece.MARK + RisingPiece.RISE) * 1000.0) + 600)
	assert_object(lesson._box).is_not_null()
	assert_bool(RisingPiece.is_up(lesson._box)).is_true()
	Events.item_picked.emit(0, &"turret")
	assert_bool(lesson._take.done).is_true()
	assert_bool(run.reveal.shown[&"item"]).is_true()
	# A shot of the player's own counts for nothing now; a turret's does.
	targets[0].struck.emit(targets[0], 0)
	assert_int(lesson._drop.count).is_equal(0)
	var turret := Turret.new()
	turret.owner_slot = 0
	turret.bullet_system = tutorial.match_node.bullets
	tutorial.match_node.add_child(turret)
	turret.global_position = run.cell(TestGround.TARGETS[1] + Vector2i(-4, 0))
	for i: int in 600:
		await _runner.simulate_frames(1, 17)
		if lesson._drop.count > 0:
			break
	turret.queue_free()
	assert_int(lesson._drop.count).override_failure_message("the turret never hit").is_greater(0)


## The pause menu's Skip lesson passes the lesson under way, its pieces up at once; it is gone
## from the menu from the exam on, which cannot be skipped.
func test_skipping_a_lesson_brings_its_pieces_up_at_once() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var first := run.current_lesson()
	run.skip()
	await _runner.simulate_frames(2, 17)
	for piece: Node3D in first.piece_nodes():
		assert_bool(RisingPiece.is_up(piece)).is_true()
	assert_int(run.index).is_equal(1)
	for i: int in 4:
		run.skip()
		await _runner.simulate_frames(2, 17)
	assert_int(run.index).is_equal(5)
	assert_bool(tutorial._skip_entry.visible).is_false()
	# Skipped through, the trench is shut, the parked kart gone, and the Junction up.
	assert_bool(run.trench.is_open()).is_false()
	assert_bool(run.dummies[0].kart.visible).is_false()
	assert_bool(RisingPiece.is_up(tutorial.match_node.arena.junction)).is_true()
	run.skip()
	await _runner.simulate_frames(2, 17)
	assert_int(run.index).is_equal(5)


## Enrolled for the exam alone, the test starts on it: every lesson before it settled, its pieces
## up and the corner whole, the trench shut and the parked kart nowhere.
func test_straight_to_the_exam() -> void:
	DrivingSchool.express = true
	var tutorial := await _start()
	DrivingSchool.express = false
	var run := tutorial.run
	assert_int(run.index).is_equal(5)
	assert_str(run.current_lesson().title).is_equal("Final exam")
	var arena := tutorial.match_node.arena
	for pad: FlushPad in arena.flush_pads:
		assert_bool(RisingPiece.is_up(pad)).is_true()
	assert_bool(RisingPiece.is_up(arena.junction)).is_true()
	for target: Target in arena.targets:
		assert_bool(target.visible).is_true()
	for piece: StringName in [&"nitro", &"item", &"lives", &"hand", &"pot", &"bank"]:
		assert_bool(run.reveal.shown[piece]).override_failure_message(piece).is_true()
	assert_bool(run.trench.is_open()).is_false()
	assert_bool(run.dummies[0].kart.visible).is_false()
	assert_bool(run.kart().banks_passively).is_true()
	assert_bool(tutorial.match_node.rules.offer_jokers).is_true()
	assert_bool(tutorial._skip_entry.visible).is_false()
	tutorial.queue_free()
	await await_idle_frame()
	assert_bool(TutorialRun.express).is_false()


## A debug build's Skip to end puts the test straight at its end, with nothing earned on the
## license: the bots gone, the license numbered.
func test_skip_to_end_passes_the_test_on_the_spot() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var over: Array[bool] = []
	run.finished.connect(func() -> void: over.append(true))
	Game.settings.license_number = ""
	run.skip_to_end()
	await _runner.simulate_frames(2, 17)
	assert_int(over.size()).is_equal(1)
	assert_bool(run.is_over()).is_true()
	assert_str(Game.settings.license_number).starts_with("JJ-")
	assert_int(Game.settings.license_endorsements.size()).is_equal(0)
	# Asked again, nothing: the test is over.
	run.skip_to_end()
	assert_int(over.size()).is_equal(1)


## On a touch screen the right thumb's controls are drawn over the driving test's checklist, which
## keeps its own place and size: it goes in their layer, just under them, still over the rest of
## the HUD; without them it is in the tutorial's own layer.
func test_the_touch_controls_are_drawn_over_the_checklist() -> void:
	var hud: CanvasLayer = auto_free(CanvasLayer.new())
	add_child(hud)
	var before := Control.new()
	hud.add_child(before)
	var touch := Control.new()
	touch.name = "TouchControls"
	hud.add_child(touch)
	var after := Control.new()
	hud.add_child(after)
	var layer: CanvasLayer = auto_free(CanvasLayer.new())
	add_child(layer)
	var list := TutorialList.add_to(layer, touch)
	assert_object(list.get_parent()).is_same(list.board)
	assert_object(list.board.get_parent()).is_same(hud)
	assert_int(list.board.get_index()).is_equal(touch.get_index() - 1)
	assert_int(list.board.get_index()).is_greater(before.get_index())
	var alone := TutorialList.add_to(layer)
	assert_object(alone.board.get_parent()).is_same(layer)


## Waits out the PASSED stamp of the lesson before, which has the clipboard for a second.
func _past_the_stamp(run: TutorialRun) -> void:
	for i: int in 120:
		if not run.list.is_checking():
			return
		await _runner.simulate_frames(1, 17)
