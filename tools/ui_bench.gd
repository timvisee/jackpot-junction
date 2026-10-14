extends SceneTree
## What the UI of a screen costs a frame, GAME.md 10.7: the draw calls it adds and how long a frame
## takes with it up, for a screen that is the UI alone, the title, the settings and the driving
## school, against nothing, and for one laid over a match, the HUD and the pause menu, against the
## same match with it hidden. Two seconds each way. It fails when the UI averages more draw calls
## than the view's budget: a chip, a seal, the backdrop's lines or the clock's segments drawn as
## themselves every frame again, rather than from the pictures they were drawn into once.
##
##   make ui-bench
##   tools/ui_bench --view=hud --budget=320

## Frames to let the screen settle and draw its pictures, and the frames measured each way.
const SETTLE := 90
const MEASURED := 120
## Each view: what it is, and the draw calls it may add.
const VIEWS: Dictionary[String, float] = {
	"hud": 320.0,
	"pause": 160.0,
	"title": 400.0,
	"settings": 260.0,
	"school": 400.0,
}

var _view := "hud"
var _budget := -1.0
var _frames := 0
var _scene: Node
## What is shown and hidden to tell the UI's cost from the rest of the frame, or null for a screen
## that is all UI, measured against the empty frame after it is gone.
var _ui: Object
var _with: Array[float] = []
var _without: Array[float] = []
var _ms_with: Array[float] = []
var _last := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--view="):
			_view = arg.get_slice("=", 1)
		elif arg.begins_with("--budget="):
			_budget = float(arg.get_slice("=", 1))
	if not VIEWS.has(_view):
		printerr("ui bench: no view called %s, only %s" % [_view, VIEWS.keys()])
		quit(2)
	if _budget < 0.0:
		_budget = VIEWS[_view]


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		_open()
	elif _frames == SETTLE:
		_find_ui()
	elif _frames > SETTLE and _frames <= SETTLE + MEASURED:
		_sample(_with, true)
	elif _frames == SETTLE + MEASURED + 1:
		_hide()
	elif _frames > SETTLE + MEASURED + 10 and _frames <= SETTLE + MEASURED * 2 + 10:
		_sample(_without, false)
	elif _frames > SETTLE + MEASURED * 2 + 10:
		return _report()
	return false


func _open() -> void:
	match _view:
		"hud", "pause":
			_scene = load("res://scenes/dev/playground.tscn").instantiate()
			root.add_child(_scene)
		"title":
			_scene = load("res://scenes/ui/title.tscn").instantiate()
			root.add_child(_scene)
		"settings":
			_scene = load("res://scenes/ui/settings_screen.tscn").instantiate()
			root.add_child(_scene)
		"school":
			_scene = load("res://scenes/tutorial/school/driving_school.tscn").instantiate()
			root.add_child(_scene)


func _find_ui() -> void:
	match _view:
		"hud":
			_ui = _scene.get("match_node").get("hud")
		"pause":
			var menu: Node = load("res://scenes/match/pause_menu.gd").call("add_to", _scene, null)
			menu.get("_panel").set("visible", true)
			_ui = menu
		_:
			_ui = _scene


func _hide() -> void:
	if _ui is CanvasItem:
		(_ui as CanvasItem).visible = false
	elif _ui is CanvasLayer:
		(_ui as CanvasLayer).visible = false


func _sample(into: Array[float], timed: bool) -> void:
	var now := Time.get_ticks_usec()
	if timed and _last > 0:
		_ms_with.append((now - _last) / 1000.0)
	_last = now
	into.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _report() -> bool:
	var cost := _average(_with) - _average(_without)
	print(
		(
			(
				"ui bench, %s: %.0f draw calls a frame for the UI (%.0f with it, %.0f without; "
				+ "budget %.0f), frame avg %.2f ms max %.2f ms"
			)
			% [
				_view,
				cost,
				_average(_with),
				_average(_without),
				_budget,
				_average(_ms_with),
				_ms_with.max() if not _ms_with.is_empty() else 0.0
			]
		)
	)
	if cost > _budget:
		printerr(
			"ui bench failed: the %s, %.0f draw calls a frame, over %.0f" % [_view, cost, _budget]
		)
		quit(1)
	else:
		quit(0)
	return false


func _average(values: Array[float]) -> float:
	var sum := 0.0
	for value: float in values:
		sum += value
	return sum / maxf(values.size(), 1.0)
