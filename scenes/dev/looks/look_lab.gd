extends Node
## The rendering lab of GAME.md 8.1b: [RenderLook]'s looks laid over the playground's room one
## after another, to be held against each other. Asked to, it prints the time the card takes over
## each frame once a run has settled, holds one frame of the match still and saves it under every
## look in turn, or shows every look for a while each with its name on the screen, to be recorded.
## Development only: the playground's `--look=`, `--gpu-time=`, `--look-sheet=` and
## `--look-cycle=` put it in.

## Frames left to settle before the time is counted: the first ones compile shaders.
const WARMUP := 180
## Frames each look is given on the held frame before it is saved, so its pass has run.
const SETTLE := 4

var look := ""
var frames := 0
## Where the held frame's pictures go, one per look, and at which frame of the run it is held.
var sheet_dir := ""
var sheet_at := 0
## Frames each look is shown for in turn; none for one look all the run.
var cycle := 0

var _rid: RID
var _seen := 0
var _total := 0.0
var _cpu := 0.0
var _sheet: Array[String] = []
var _wait := 0
var _caption: Label


## Lays [param name] over the room, or keeps the settings' look for an empty one, and counts the
## card's time over [param count] frames when that is more than nothing. Returns the lab node.
static func attach(camera: Camera3D, name: String, count := 0) -> Node:
	var lab := _made()
	lab.look = name
	lab.frames = count
	camera.add_child(lab)
	return lab


## Shows every look in turn for [param each] frames, with a caption naming it, from the first frame.
static func cycling(camera: Camera3D, each: int) -> Node:
	var lab := _made()
	lab.cycle = each
	camera.add_child(lab)
	return lab


## Holds the match at frame [param at] and saves the frame under every look into [param dir].
static func sheet(camera: Camera3D, dir: String, at: int) -> Node:
	var lab := _made()
	lab.sheet_dir = dir
	lab.sheet_at = at
	camera.add_child(lab)
	return lab


static func _made() -> Node:
	var lab: Node = load("res://scenes/dev/looks/look_lab.gd").new()
	lab.name = "LookLab"
	return lab


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not look.is_empty():
		_show(look)
	if frames > 0:
		_rid = get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(_rid, true)
	elif sheet_dir.is_empty() and cycle <= 0:
		set_process(false)
	if cycle > 0:
		var layer := CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		_caption = Label.new()
		_caption.add_theme_font_size_override("font_size", 30)
		_caption.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
		_caption.add_theme_constant_override("outline_size", 10)
		_caption.anchor_right = 1.0
		_caption.anchor_top = 1.0
		_caption.anchor_bottom = 1.0
		_caption.offset_top = -64.0
		_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layer.add_child(_caption)


func _show(name: String) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		RenderLook.of(game).use(name)


func _title(name: String) -> String:
	return RenderLook.NAMES[maxi(RenderLook.LOOKS.find(name), 0)]


func _process(_delta: float) -> void:
	_seen += 1
	if not sheet_dir.is_empty():
		_step_sheet()
		return
	if cycle > 0:
		var index := mini(_seen / cycle, RenderLook.LOOKS.size() - 1)
		var name := RenderLook.LOOKS[index]
		if _caption.text != _title(name):
			_show(name)
			_caption.text = _title(name)
			print("cycle %s from frame %d" % [name, _seen])
		return
	if _seen <= WARMUP:
		return
	_total += RenderingServer.viewport_get_measured_render_time_gpu(_rid)
	_cpu += RenderingServer.viewport_get_measured_render_time_cpu(_rid)
	if _seen == WARMUP + frames:
		var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
		print(
			(
				"look %s on %s: gpu %.3f ms, render cpu %.3f ms, over %d frames at %s"
				% [
					look if not look.is_empty() else "as set",
					method,
					_total / frames,
					_cpu / frames,
					frames,
					get_viewport().get_visible_rect().size
				]
			)
		)


func _step_sheet() -> void:
	if _seen < sheet_at:
		return
	if _seen == sheet_at:
		get_tree().paused = true
		_sheet.assign(RenderLook.LOOKS)
		_show(_sheet[0])
		_wait = SETTLE
		return
	_wait -= 1
	if _wait > 0:
		return
	var image := get_viewport().get_texture().get_image()
	var path := sheet_dir.path_join("%s.png" % _sheet[0])
	print("sheet %s: %s" % [path, error_string(image.save_png(path))])
	_sheet.remove_at(0)
	if _sheet.is_empty():
		get_tree().quit()
		return
	_show(_sheet[0])
	_wait = SETTLE
