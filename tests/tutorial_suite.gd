class_name TutorialSuite
extends GdUnitTestSuite
## What the tutorial's suites share, GAME.md 9.4a: the map and the scene, the settings kept off the
## real file, and the tutorial brought up with the kart put where a test wants it. No tests of its
## own: test_tutorial.gd has the first lessons and test_tutorial_rooms.gd the rooms after them.

const LAYOUT: ArenaLayout = preload("res://data/maps/tutorial.tres")
const SCENE := preload("res://scenes/tutorial/tutorial.tscn")
const ARENA_SCENE := preload("res://scenes/arena/arena.tscn")
const ROOM: RoomLook = preload("res://data/rooms/garage.tres")
const DT := 1.0 / 60.0

var _runner: GdUnitSceneRunner
var _was_path := ""
var _was_modes: Array[String] = []
var _was_done := false
var _was_license := ""
var _was_endorsements := PackedStringArray()


func before_test() -> void:
	# Nothing here writes the real settings file: the pads and the license both save.
	_was_path = Game.settings.path
	_was_modes = Game.settings.drive_modes.duplicate()
	_was_done = Game.settings.tutorial_done
	_was_license = Game.settings.license_number
	_was_endorsements = Game.settings.license_endorsements.duplicate()
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
	Settings.remove_files(Game.settings.path)
	Game.settings.path = _was_path
	Game.settings.drive_modes = _was_modes
	Game.settings.tutorial_done = _was_done
	Game.settings.license_number = _was_license
	Game.settings.license_endorsements = _was_endorsements


## Every cell that can be driven to from the player's spawn, the corridor's, treating
## [param blocking] as solid.
func _reachable(grid: ArenaGrid, blocking: Array[String]) -> Dictionary[Vector2i, bool]:
	var start: Vector2i = TutorialDrive.new().spawn_cell
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


## The crate standing on [param cell].
func _crate_at(arena: Arena, cell: Vector2i) -> Crate:
	for i: int in arena.crates.size():
		if arena.grid.crates[i] == cell:
			return arena.crates[i]
	return null
