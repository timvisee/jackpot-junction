extends GdUnitTestSuite
## The tutorial, GAME.md 9.4a: a map of rooms in a row joined by gates, a lesson in each, with a
## checklist, a hint over the kart, an arrow on the floor and the HUD arriving a piece at a time.

const LAYOUT: ArenaLayout = preload("res://data/maps/tutorial.tres")
const SCENE := preload("res://scenes/tutorial/tutorial.tscn")
const DT := 1.0 / 60.0

var _runner: GdUnitSceneRunner
var _was_path := ""
var _was_modes: Array[String] = []
var _was_done := false
var _was_offered := false


func before_test() -> void:
	# Nothing here writes the real settings file: the pads and the title's offer both save.
	_was_path = Game.settings.path
	_was_modes = Game.settings.drive_modes.duplicate()
	_was_done = Game.settings.tutorial_done
	_was_offered = Game.settings.tutorial_offered
	Game.settings.path = "user://tutorial_test.cfg"
	Game.settings.drive_modes = ["advanced", "", "", ""]


func after_test() -> void:
	for action: StringName in [
		InputActions.THROTTLE,
		InputActions.BRAKE,
		InputActions.STEER_LEFT,
		InputActions.STEER_RIGHT,
		InputActions.NITRO,
		InputActions.HANDBRAKE,
	]:
		Input.action_release(action)
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings.path = _was_path
	Game.settings.drive_modes = _was_modes
	Game.settings.tutorial_done = _was_done
	Game.settings.tutorial_offered = _was_offered


## Every cell that can be driven to from the spawn, treating [param blocking] as solid.
func _reachable(grid: ArenaGrid, blocking: Array[String]) -> Dictionary[Vector2i, bool]:
	var start: Vector2i = grid.spawns[0]
	var seen: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next := cell + step
			if seen.has(next) or next.x < 0 or next.y < 0:
				continue
			if next.x >= grid.width or next.y >= grid.height:
				continue
			if grid.glyph(next) in blocking:
				continue
			seen[next] = true
			queue.append(next)
	return seen


## The tutorial up and its first lesson running, with the way of driving already chosen so
## nothing is asked.
func _start() -> Tutorial:
	var tutorial: Tutorial = auto_free(SCENE.instantiate())
	_runner = scene_runner(tutorial)
	var up := [false]
	tutorial.loaded.connect(func() -> void: up[0] = true)
	for i: int in 200:
		if up[0]:
			break
		await _runner.simulate_frames(1, 17)
	assert_bool(up[0]).override_failure_message("the tutorial never came up").is_true()
	await _runner.simulate_frames(3, 17)
	return tutorial


## Puts the kart at [param cell], facing [param way], standing still.
func _put(tutorial: Tutorial, cell: Vector2i, way: Vector3) -> void:
	tutorial.run.kart().respawn(tutorial.run.cell(cell), way, 0.0)


## The rooms chain: every gate shut, nothing past the first room can be reached; open, the way
## through is blocked only by the boxes of the gallery; those broken too, the portal at the end is.
func test_the_map_is_rooms_in_a_row_joined_by_gates() -> void:
	assert_array(LAYOUT.validate()).is_empty()
	var grid := LAYOUT.parse()
	assert_int(grid.spawns.size()).is_equal(1)
	assert_int(grid.portals.size()).is_equal(1)
	assert_int(grid.gates.size()).is_equal(6)
	assert_int(grid.targets.size()).is_equal(5)
	assert_object(grid.junction).is_equal(Rect2i())
	assert_int(grid.pits.size()).is_equal(0)
	var shut := _reachable(grid, ["#", "G"] as Array[String])
	assert_bool(shut.has(TutorialDrive.new().next_cell)).is_false()
	var open := _reachable(grid, ["#", "B"] as Array[String])
	assert_bool(open.has(TutorialShoot.WALL.position)).is_false()
	assert_bool(open.has(grid.portals[0])).is_false()
	var broken := _reachable(grid, ["#"] as Array[String])
	assert_bool(broken.has(grid.portals[0])).is_true()
	# Every lesson's cells are where the map has them: its gate a gate, its spawn floor.
	for lesson: TutorialLesson in [
		TutorialDrive.new(),
		TutorialSteer.new(),
		TutorialReverse.new(),
		TutorialNitro.new(),
		TutorialDrift.new(),
		TutorialShoot.new(),
	]:
		assert_str(grid.glyph(lesson.gate_cell)).override_failure_message(lesson.title).is_equal(
			"G"
		)
		assert_str(grid.glyph(lesson.next_cell)).override_failure_message(lesson.title).is_equal(
			"."
		)
		assert_bool(grid.glyph(lesson.spawn_cell) in [".", "S"]).is_true()


## A gate is a wall until it opens: it sinks into the floor and stops standing in the way, and
## rises again shut.
func test_a_gate_sinks_open_and_rises_shut() -> void:
	var layout := ArenaLayout.new()
	layout.grid = "######\n#S.G.#\n######"
	layout.room = load("res://data/rooms/garage.tres")
	var arena: Arena = auto_free(load("res://scenes/arena/arena.tscn").instantiate())
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
	var rows := run.list.task_rows(lesson)
	assert_int(rows.size()).is_equal(1)
	assert_str((rows[0]["label"] as Label).text).is_equal("Drive forward")
	assert_bool(rows[0].has("bar")).is_true()
	assert_str(run.hint.words()).is_equal("Hold %s to drive")
	var gate := tutorial.match_node.arena.gate_at(lesson.gate_cell)
	assert_bool(gate.is_open).is_false()
	# Bare: no nitro, no hand, no pot, and the corner's own hints never.
	var parts := tutorial.match_node.hud.block_parts(0)
	assert_bool((parts["nitro"] as Control).visible).is_false()
	assert_bool((parts["pot"] as Control).visible).is_false()
	assert_bool(tutorial.match_node.hud.hand_of(0).visible).is_false()
	Input.action_press(InputActions.THROTTLE)
	var opened := false
	for i: int in 600:
		await _runner.simulate_frames(1, 17)
		if gate.is_open:
			opened = true
			break
	assert_bool(opened).override_failure_message("the gate never opened").is_true()
	assert_bool(lesson.is_done()).is_true()
	assert_bool((rows[0]["mark"] as TutorialList.Mark).done).is_true()
	assert_object(run.waiting_at).is_same(gate)
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
	assert_int(run.list.listed()).is_equal(2)
	# The pads of the steering room are down, lit for the way in use.
	var pads := tutorial.match_node.find_children("ModePad_*", "", false, false)
	assert_int(pads.size()).is_equal(2)


## Steering counts the heading, left then right, only while moving forward; sawing the wheel back
## and forth does not add up, and one direction alone is not enough.
func test_steering_counts_both_ways_from_the_heading() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(1)
	var lesson := run.current_lesson() as TutorialSteer
	var kart := run.kart()
	_put(tutorial, Vector2i(18, 42), Vector3(0.0, 0.0, -1.0))
	await _runner.simulate_frames(2, 17)
	# Standing still and turning the wheel is nothing.
	kart.motor.heading += 2.0
	await _runner.simulate_frames(2, 17)
	assert_float(lesson._left.progress).is_equal(0.0)
	# Moving and turning left fills the left task, and nothing of the right one.
	Input.action_press(InputActions.THROTTLE)
	Input.action_press(InputActions.STEER_LEFT)
	for i: int in 400:
		await _runner.simulate_frames(1, 17)
		if lesson._left.done:
			break
	Input.action_release(InputActions.STEER_LEFT)
	assert_bool(lesson._left.done).override_failure_message("left never filled").is_true()
	assert_float(lesson._right.progress).is_equal(0.0)
	Input.action_press(InputActions.STEER_RIGHT)
	for i: int in 400:
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
	simple._on_body_entered(tutorial.run.kart())
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_SIMPLE)
	assert_bool(simple.is_lit()).is_true()
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
	assert_bool((parts["nitro"] as Control).visible).is_true()
	assert_bool((parts["speed"] as Control).visible).is_true()
	assert_bool((parts["pot"] as Control).visible).is_false()
	assert_bool(run.reveal.is_pointing()).is_true()
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
	kart.motor.drifting = true
	kart.motor.drift_time = 0.3
	lesson.step(DT)
	assert_bool(lesson._tap.done).is_true()
	lesson.step(DT)
	assert_float(lesson._turbo.progress).is_between(0.3, 0.7)
	kart.motor.drifting = false
	await _runner.simulate_frames(1, 17)
	assert_int(run.list.task_rows(lesson).size()).is_equal(2)
	for i: int in TutorialDrift.TURBOS:
		Events.drift_boosted.emit(kart.slot)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_true()
	assert_str(run.list.task_rows(lesson)[1]["label"].text).contains("3/3")


## Shooting: each target counts once, its light going green, the loose boxes count for nothing,
## and the wall of boxes down is the way out.
func test_shooting_the_targets_and_through_the_boxes() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(5)
	var lesson := run.current_lesson() as TutorialShoot
	var arena := tutorial.match_node.arena
	var shot: Bullet = auto_free(Bullet.new())
	shot.owner_slot = 0
	# A light beside every target, red until it is counted.
	var lights := lesson.lights()
	assert_int(lights.size()).is_equal(TutorialShoot.TARGETS)
	for light: TrafficLight in lights:
		assert_bool(light.green).is_false()
	arena.targets[0].take_hit(shot)
	await _runner.simulate_frames(1, 17)
	assert_int(lesson._hit.count).is_equal(1)
	var greens := 0
	for light: TrafficLight in lesson.lights():
		greens += 1 if light.green else 0
	assert_int(greens).is_equal(1)
	# The same target again, once it is back up, is not another.
	arena.targets[0]._stand(true)
	arena.targets[0].take_hit(shot)
	assert_int(lesson._hit.count).is_equal(1)
	for i: int in range(1, arena.targets.size()):
		arena.targets[i].take_hit(shot)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson._hit.done).is_true()
	assert_bool(lesson.is_done()).is_false()
	var grid := arena.grid
	for i: int in arena.crates.size():
		if not TutorialShoot.WALL.has_point(grid.crates[i]):
			arena.crates[i].hit(0)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_false()
	for i: int in arena.crates.size():
		if TutorialShoot.WALL.has_point(grid.crates[i]):
			arena.crates[i].hit(0)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_true()
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


## Once the lessons so far are done the run is over, and the sign at the end is up.
func test_the_last_gate_leads_to_the_end_for_now() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(5)
	var lesson := run.current_lesson()
	run.skip()
	await _runner.simulate_frames(2, 17)
	_put(tutorial, lesson.next_cell, Vector3(-1.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	assert_bool(run.is_over()).is_true()
	var signs := tutorial.find_children("*", "Label3D", false, false)
	var said := false
	for sign: Label3D in signs:
		said = said or sign.text.begins_with("THAT'S ALL")
	assert_bool(said).is_true()


## The title offers the tutorial once, the first time Play is pressed: Not now goes on to play
## and is never asked again.
func test_the_title_offers_the_tutorial_once() -> void:
	Game.settings.tutorial_offered = false
	Game.settings.tutorial_done = false
	var title: Control = auto_free(load("res://scenes/ui/title.tscn").instantiate())
	add_child(title)
	await await_idle_frame()
	var went := [0]
	title.offer_tutorial(func() -> void: went[0] += 1)
	var pane: ConfirmPane = title.find_child("TutorialOffer", true, false)
	assert_object(pane).is_not_null()
	assert_str(pane.said()).contains("New here?")
	assert_int(went[0]).is_equal(0)
	pane.no_button().pressed.emit()
	assert_int(went[0]).is_equal(1)
	assert_bool(Game.settings.tutorial_offered).is_true()
	await await_idle_frame()
	assert_object(title.find_child("TutorialOffer", true, false)).is_null()
	title.offer_tutorial(func() -> void: went[0] += 1)
	assert_int(went[0]).is_equal(2)
	assert_object(title.find_child("TutorialOffer", true, false)).is_null()
