class_name NoticePane
extends CanvasLayer
## Something the player has to be told and can do nothing about, on the pane every panel in the
## game is cut from: what happened, a line under it, and OK. It takes nobody's controls -- the room
## goes on around it and the players in it are still driving, on the keys and the pads a menu would
## have taken -- so it goes by itself after a few seconds, or at OK under the mouse or a finger.

const LAYER := 40
## How long it stays up, in seconds, unless it is closed first.
const SHOWN_FOR := 4.0
const WIDTH := 560.0

var _pane: PanelContainer
var _title: Label
var _message: Label
var _ok: Button
var _left := 0.0
## What it is to say, kept for when it is built if it is told before it is in the tree.
var _words: Array[String] = ["", ""]


## Puts [param title] up over [param parent], with [param message] under it, in the one notice
## [param parent] has: asked again, the notice already up says it again rather than stacking.
static func tell(parent: Node, title: String, message: String) -> NoticePane:
	var notice := parent.get_node_or_null("Notice") as NoticePane
	if notice == null:
		notice = NoticePane.new()
		notice.name = "Notice"
		parent.add_child(notice)
	notice._say(title, message)
	return notice


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(middle)
	_pane = PanelContainer.new()
	_pane.add_theme_stylebox_override("panel", MenuTheme.pane_style())
	middle.add_child(_pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	_pane.add_child(column)
	_title = MenuTheme.title("", Type.TITLE)
	column.add_child(_title)
	_message = MenuTheme.subtitle("", Type.BODY)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(WIDTH, 0.0)
	column.add_child(_message)
	_ok = MenuTheme.button("OK")
	# Pressed with the mouse or a finger only: the keys and the pads are driving.
	_ok.focus_mode = Control.FOCUS_NONE
	_ok.pressed.connect(close)
	column.add_child(_ok)
	_title.text = _words[0]
	_message.text = _words[1]


func _say(title: String, message: String) -> void:
	_words = [title, message]
	if _title != null:
		_title.text = title
		_message.text = message
	_left = SHOWN_FOR
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	if _left <= 0.0:
		close()


func close() -> void:
	visible = false


## What it says just now, for the tests.
func said() -> String:
	return "%s %s" % [_title.text, _message.text] if visible and _title != null else ""
