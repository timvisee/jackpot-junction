class_name FocusGlide
extends CanvasLayer
## The cursor moving, GAME.md 8.1a: when the focus goes from one control to the next, a gold frame
## slides from where it was to where it is, so a player on a pad sees where it went rather than
## having to find it. The control with the focus wears its own frame all along; this is only the
## move between two of them, and it fades as it lands.
##
## It slides to wherever the control is each frame rather than to where it was when the focus
## came to it: a button in a pane that has only just been opened is not laid out yet, and then it
## rises into place with its pane. And it is drawn at the very point it has got to rather than
## moved there as a control, which is snapped to whole pixels of the interface and on a big screen
## steps along a few of the screen's pixels at a time.

## How long the slide takes, and the layer it is drawn on, over every menu and pane.
const TIME := 0.16
const LAYER := 126

var _from := Rect2()
var _at := Rect2()
var _t := 1.0
var _last: Control
var _target: Control
var _canvas: Control
var _look: TicketStyle


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_look = TicketStyle.cut(Color(0.0, 0.0, 0.0, 0.0), MenuTheme.BUTTON_NOTCH, 0.0, 0.0)
	_look.border = HouseTheme.FOIL
	_canvas = Control.new()
	_canvas.name = "Frame"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.visible = false
	_canvas.draw.connect(func() -> void: _canvas.draw_style_box(_look, _at))
	add_child(_canvas)
	get_viewport().gui_focus_changed.connect(_on_focus)


func _on_focus(control: Control) -> void:
	var before := _last
	_last = control
	if not _glides(control) or before == null or not is_instance_valid(before):
		return
	# Switched off in Accessibility for anybody the motion bothers, GAME.md 8.5.
	if Game.settings != null and not Game.settings.cursor_glide:
		return
	if not before.is_visible_in_tree() or not _glides(before) or before == control:
		return
	_from = _rect_of(before)
	_target = control
	_t = 0.0


func _process(delta: float) -> void:
	if _t >= 1.0 or not is_instance_valid(_target) or not _target.is_visible_in_tree():
		_t = 1.0
		_canvas.visible = false
		return
	var to := _rect_of(_target)
	# Not laid out yet: the slide waits for it rather than heading for the corner of the screen.
	if to.size.x < 1.0 or to.size.y < 1.0:
		_canvas.visible = false
		return
	_t = minf(_t + delta / TIME, 1.0)
	var eased := 1.0 - pow(1.0 - _t, 3.0)
	_at = Rect2(_from.position.lerp(to.position, eased), _from.size.lerp(to.size, eased))
	_canvas.modulate.a = 1.0 - _t * _t
	_canvas.visible = true
	_canvas.queue_redraw()


## Where [param control] is on the screen, whatever layer it is drawn on.
static func _rect_of(control: Control) -> Rect2:
	var placed := control.get_global_transform_with_canvas()
	return Rect2(placed.origin, control.size * placed.get_scale())


## Whether [param control] is one the frame slides between: the house's buttons, boxes and switches.
static func _glides(control: Control) -> bool:
	return control is BaseButton
