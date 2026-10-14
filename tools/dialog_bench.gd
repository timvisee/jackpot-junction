extends SceneTree
## What a large dialog costs a frame, GAME.md 10.7: the achievements dialog, the catalog or the
## loyalty program's, opened over a plain backdrop on a profile with a few achievements earned, some
## jokers and items found and a few bets won, held still for two seconds, then for two more the
## achievements scrolled as a wheel would, the catalog's cursor walked along its cards or the
## program's map dragged, and the draw calls and frame times of those four seconds said. It fails
## when a frame averages more draw calls than the dialog's budget: the achievements' chips, the
## catalog's cards or the atlas cover the program's map lies on drawn as themselves every frame
## again, rather than from the pictures they were drawn into once.
##
##   make dialog-bench
##   tools/dialog_bench --dialog=catalog --budget=600

## Frames for the dialog to open and its pictures to be drawn, and the frames measured, the second
## half of them scrolling or walking; how far a frame scrolls, and how many frames the cursor rests
## on each card.
const SETTLE := 60
const MEASURED := 240
const SCROLL := 12
const WALK := 10
## How far a frame drags the program's map, a little each way.
const DRAG := Vector2(3.0, 1.0)
## The bets won on the program's map, so that it has roads open and seals on it.
const WON: Array[StringName] = [&"slip_road", &"dealers_visor", &"rare_cards", &"racing_stripes"]
## Each dialog, its script, and the draw calls a frame it may average.
const DIALOGS: Dictionary[String, Array] = {
	"achievements": ["res://scenes/achievements/achievements_dialog.gd", 300.0],
	"catalog": ["res://scenes/ui/catalog_dialog.gd", 600.0],
	"loyalty": ["res://scenes/loyalty/loyalty_dialog.gd", 300.0],
}

var _dialog_name := "achievements"
var _budget := -1.0
var _frames := 0
var _dialog: Node
var _last := 0
var _draws: Array[float] = []
var _frame_ms: Array[float] = []
## The longest frame while it opened, when its pictures are drawn.
var _opening_ms := 0.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--budget="):
			_budget = float(arg.get_slice("=", 1))
		elif arg.begins_with("--dialog="):
			_dialog_name = arg.get_slice("=", 1)
	if not DIALOGS.has(_dialog_name):
		printerr("dialog bench: no dialog called %s, only %s" % [_dialog_name, DIALOGS.keys()])
		quit(2)
	if _budget < 0.0:
		_budget = DIALOGS[_dialog_name][1]


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		_open()
	elif _frames <= SETTLE:
		var now := Time.get_ticks_usec()
		if _last > 0:
			_opening_ms = maxf(_opening_ms, (now - _last) / 1000.0)
		_last = now
	elif _frames <= SETTLE + MEASURED:
		_measure()
	elif _frames > SETTLE + MEASURED:
		return _report()
	return false


## The dialog on a profile in the user directory this runs in, with six achievements earned, one
## of them new, and jokers and items found, by path rather than by class_name, as the game's own
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
	var loyalty: Object = profile.get("loyalty")
	for id: StringName in WON:
		loyalty.call("win", id)
	load("res://scripts/loyalty/loyalty.gd").call("settle", profile)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.16, 0.14, 0.2)
	backdrop.size = root.get_visible_rect().size
	root.add_child(backdrop)
	_dialog = load(DIALOGS[_dialog_name][0]).call("open", backdrop)


func _measure() -> void:
	var now := Time.get_ticks_usec()
	if _last > 0:
		_frame_ms.append((now - _last) / 1000.0)
	_last = now
	_draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if _frames <= SETTLE + MEASURED / 2:
		return
	if _dialog_name == "achievements":
		var scroll: ScrollContainer = _dialog.get("scroll")
		scroll.follow_focus = false
		scroll.scroll_vertical += SCROLL
	elif _dialog_name == "loyalty":
		var way := 1.0 if (_frames / 60) % 2 == 0 else -1.0
		(_dialog.get("map_view") as Control).call("pan_by", DRAG * way)
	elif _frames % WALK == 0:
		var cards := (_dialog.get("joker_grid") as Node).get_children()
		(cards[(_frames / WALK) % cards.size()] as Control).grab_focus()


func _report() -> bool:
	var draws := _average(_draws)
	print(
		(
			(
				"dialog bench, %s: draw calls a frame avg %.0f max %.0f (budget %.0f), "
				+ "frame avg %.2f ms max %.2f ms, opening at most %.2f ms"
			)
			% [
				_dialog_name,
				draws,
				_draws.max(),
				_budget,
				_average(_frame_ms),
				_frame_ms.max(),
				_opening_ms
			]
		)
	)
	if draws > _budget:
		printerr(
			(
				"dialog bench failed: the %s, %.0f draw calls a frame, over %.0f"
				% [_dialog_name, draws, _budget]
			)
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
