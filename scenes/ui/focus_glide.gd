class_name FocusGlide
extends CanvasLayer
## The cursor moving, GAME.md 8.1a: when the focus goes from one control to the next, a gold frame
## slides from where it was to where it is, so a player on a pad sees where it went rather than
## having to find it. The control with the focus wears its own frame all along; this is only the
## move between two of them, and it fades as it lands.

## How long the slide takes, and the layer it is drawn on, over every menu and pane.
const TIME := 0.14
const LAYER := 126

var _from := Rect2()
var _to := Rect2()
var _t := 1.0
var _last: Control
var _frame: Control
var _look: TicketStyle


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_look = TicketStyle.cut(Color(0.0, 0.0, 0.0, 0.0), MenuTheme.BUTTON_NOTCH, 0.0, 0.0)
	_look.border = HouseTheme.FOIL
	_frame = Control.new()
	_frame.name = "Frame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.visible = false
	_frame.draw.connect(
		func() -> void: _frame.draw_style_box(_look, Rect2(Vector2.ZERO, _frame.size))
	)
	add_child(_frame)
	get_viewport().gui_focus_changed.connect(_on_focus)


func _on_focus(control: Control) -> void:
	var before := _last
	_last = control
	if not _glides(control) or before == null or not is_instance_valid(before):
		return
	if not before.is_visible_in_tree() or not _glides(before) or before == control:
		return
	_from = before.get_global_rect()
	_to = control.get_global_rect()
	_t = 0.0
	_frame.visible = true


func _process(delta: float) -> void:
	if _t >= 1.0:
		_frame.visible = false
		return
	_t = minf(_t + delta / TIME, 1.0)
	var eased := 1.0 - pow(1.0 - _t, 3.0)
	var at := Rect2(_from.position.lerp(_to.position, eased), _from.size.lerp(_to.size, eased))
	_frame.position = at.position
	_frame.size = at.size
	_frame.modulate.a = 1.0 - _t * _t
	_frame.queue_redraw()


## Whether [param control] is one the frame slides between: the house's buttons, boxes and switches.
static func _glides(control: Control) -> bool:
	return control is BaseButton
