extends SceneTree
## What the achievements dialog costs a frame, GAME.md 10.7: it is opened over a plain backdrop on
## a profile with a few earned and a few along, held still for two seconds and scrolled for two
## more as a wheel would, and the draw calls and frame times of those four seconds are said. It
## fails when a frame averages more draw calls than the budget: every chip in the case drawn as
## its hundred shapes again, rather than from the picture it was drawn into once, is about a
## thousand.
##
##   make achievements-bench
##   tools/achievements_bench -- --budget=300

## Frames for the dialog to open and its chips to be drawn into their pictures, and the frames
## measured, the second half of them scrolling.
const SETTLE := 60
const MEASURED := 240
const SCROLL := 12

var _budget := 300.0
var _frames := 0
var _dialog: Node
var _last := 0
var _draws: Array[float] = []
var _frame_ms: Array[float] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--budget="):
			_budget = float(arg.get_slice("=", 1))


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		_open()
	elif _frames > SETTLE and _frames <= SETTLE + MEASURED:
		_measure()
	elif _frames > SETTLE + MEASURED:
		return _report()
	return false


## The dialog on a profile in the user directory this runs in, with six earned, one of them new,
## and jokers and items along for the bars, by path rather than by class_name, as the game's own
## scripts are only known once the autoloads are up.
func _open() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var profile: Object = root.get_node("/root/Game").get("settings").get("profile")
	var achievements := load("res://scripts/achievements/achievements.gd")
	var state: Object = profile.get("achievements")
	var now := int(Time.get_unix_time_from_system())
	for id: StringName in [
		&"street_legal", &"bank_shot", &"two_birds", &"plus_one", &"off_the_books", &"untouchable"
	]:
		state.call("earn", id, now - 86400 * 3)
	state.call("look_at", &"street_legal")
	var catalog: Object = profile.get("catalog")
	var jokers: Array = achievements.call("joker_ids")
	for i: int in 21:
		catalog.call("take_joker", jokers[i])
	var items: Array = achievements.call("item_ids")
	for i: int in 5:
		catalog.call("use_item", items[i])
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.16, 0.14, 0.2)
	backdrop.size = root.get_visible_rect().size
	root.add_child(backdrop)
	_dialog = load("res://scenes/achievements/achievements_dialog.gd").call("open", backdrop)


func _measure() -> void:
	var now := Time.get_ticks_usec()
	if _last > 0:
		_frame_ms.append((now - _last) / 1000.0)
	_last = now
	_draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if _frames > SETTLE + MEASURED / 2:
		var scroll: ScrollContainer = _dialog.get("scroll")
		scroll.follow_focus = false
		scroll.scroll_vertical += SCROLL


func _report() -> bool:
	var draws := _average(_draws)
	print(
		(
			(
				"achievements bench: draw calls a frame avg %.0f max %.0f (budget %.0f), "
				+ "frame avg %.2f ms max %.2f ms"
			)
			% [draws, _draws.max(), _budget, _average(_frame_ms), _frame_ms.max()]
		)
	)
	if draws > _budget:
		printerr("achievements bench failed: %.0f draw calls a frame, over %.0f" % [draws, _budget])
		quit(1)
	else:
		quit(0)
	return false


func _average(values: Array[float]) -> float:
	var sum := 0.0
	for value: float in values:
		sum += value
	return sum / maxf(values.size(), 1.0)
