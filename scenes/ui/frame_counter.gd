class_name FrameCounter
extends CanvasLayer
## The frame rate in the top left corner of every screen, while Show FPS is on in the Video
## settings, GAME.md 8.5: a number for a player finding out what their settings cost, over the
## title, the menus and the match alike. It sits in the strip above the first player's corner
## block, where nothing else is drawn, and is small and faint, since a number that is always
## changing is a number the eye goes to.

## How often the number changes, in seconds: every frame is a blur nobody can read.
const EVERY := 0.25
const INK := Color(0.86, 0.86, 0.9, 0.8)

var _label: Label
var _left := 0.0


func _ready() -> void:
	name = "FrameCounter"
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.position = Vector2(6.0, 0.0)
	Type.text(_label, Type.SMALL, INK)
	HudText.shadowed(_label, 2)
	add_child(_label)
	_show()


func _process(delta: float) -> void:
	visible = Game.settings.show_fps
	if not visible:
		return
	_left -= delta
	if _left <= 0.0:
		_left = EVERY
		_show()


func _show() -> void:
	_label.text = "%d fps" % roundi(Engine.get_frames_per_second())
