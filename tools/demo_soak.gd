extends SceneTree
## The demo for a booth played for several runs on end, GAME.md 9.8, to see that nothing piles up
## over a day at a booth. Each time the title comes up between runs it counts the memory in use, the
## nodes and the objects there are and the nodes left out of the tree; after the last run it holds
## the last count against the second, the first run having loaded what every run after it shares,
## and fails if anything has grown past what a run may leave behind, or on a run that never ends.
## It quits the way a player does.
##
##   godot --headless --fixed-fps 60 --path . -s tools/demo_soak.gd -- --demo \
##       --settings=demo-soak.cfg --demo-map-seconds=10 [--runs=4]
##
## `make demo-soak` runs it so.
##
## A script run with -s is compiled before the game's autoloads are there to be named, so this names
## nothing of the game's and reaches it by path and by name.

## How many runs it plays, unless `--runs=` says.
const RUNS := 4
## How long the title stands before it is counted, in seconds.
const SETTLE := 2.0
## The longest a run may take, maps, podiums, party and title, in seconds of the game's clock.
const LONGEST_RUN := 900.0
## What a run may leave behind: nodes, objects and nodes out of the tree, and memory in bytes.
const MOST_NODES := 0
const MOST_OBJECTS := 200
const MOST_ORPHANS := 0
const MOST_MEMORY := 8 * 1024 * 1024
const TITLE := "res://scenes/ui/title.tscn"
## The settings it plays on, named on its command line, and taken away again once it is done.
const SETTINGS := "user://demo-soak.cfg"

var _runs := RUNS
var _clock := 0.0
var _run_started := 0.0
var _scene := ""
var _on_title := 0.0
var _titles := 0
var _counted := false
var _counts: Array[Dictionary] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			_runs = maxi(arg.get_slice("=", 1).to_int(), 2)
	change_scene_to_file("res://scenes/boot/boot.tscn")


func _process(delta: float) -> bool:
	_clock += delta
	var scene := current_scene
	var path := scene.scene_file_path if scene != null else ""
	if path != _scene:
		_scene = path
		_on_title = 0.0
		_counted = false
		if path == TITLE:
			_titles += 1
			_run_started = _clock
	if path == TITLE:
		_on_title += delta
		# The first title is the start, before any run; every one after it ends a run.
		if _titles > 1 and not _counted and _on_title >= SETTLE:
			_counted = true
			_count()
			if _counts.size() >= _runs:
				_finish()
	if _clock - _run_started > LONGEST_RUN:
		_fail("a run took longer than %d s" % LONGEST_RUN)
	return false


func _count() -> void:
	var counted := {
		"memory": OS.get_static_memory_usage(),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
	}
	_counts.append(counted)
	print(
		(
			"run %d at %.0f s: %.1f MB, %d nodes, %d objects, %d orphans"
			% [
				_counts.size(),
				_clock,
				counted["memory"] / 1048576.0,
				counted["nodes"],
				counted["objects"],
				counted["orphans"]
			]
		)
	)


func _finish() -> void:
	var first: Dictionary = _counts[1] if _counts.size() > 2 else _counts[0]
	var last: Dictionary = _counts[-1]
	var grown := PackedStringArray()
	var most := {
		"memory": MOST_MEMORY, "nodes": MOST_NODES, "objects": MOST_OBJECTS, "orphans": MOST_ORPHANS
	}
	for key: String in most:
		var more: int = int(last[key]) - int(first[key])
		if more > int(most[key]):
			grown.append("%s +%d" % [key, more])
	if not grown.is_empty():
		_fail("the demo piles up over its runs: " + ", ".join(grown))
		return
	print("demo soak ok: %d runs in %.0f s of the game's clock" % [_counts.size(), _clock])
	_quit(0)


func _fail(why: String) -> void:
	printerr("demo soak failed: " + why)
	_quit(1)


func _quit(code: int) -> void:
	load("res://scripts/settings.gd").remove_files(SETTINGS)
	root.get_node("Game").quit(code)
