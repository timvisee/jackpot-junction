class_name PayoutBill
extends Control
## The payout slip as one long bill, GAME.md 3.8: cream paper torn off the house's printer along its
## top and its foot, its pages printed one under another with a perforation between each and the
## next, and the barcode and the small print at the foot of the last. It runs off the screen and is
## scrolled over rather than paged through: a page turned to comes to the middle of the screen, see
## [method turn_to], and a wheel, a finger or the screen's keys move it by hand, see
## [method scroll_by]. What is shown fades out at either end, so the paper goes off the screen
## rather than being cut. A page shorter than the longest is paper left blank at its foot, so every
## page turned to stands the same, its perforations just out of sight.

## Another page is the one most in view.
signal turned(page: int)

## How far either end of what is shown fades out, and the paper kept clear of the fades at either
## end of the bill, so its torn edges are seen whole when it is scrolled all the way.
const FADE := 44.0
const ROOM := 14.0
## How long a page takes to come to the middle.
const TURN := 0.45
## The air between a page's parts, and between a page and the perforation after it.
const SEPARATION := 14

## The paper the pages are printed on.
var paper: PanelContainer
## The page most in view, counted from 0.
var page := 0

var _scroll: ScrollContainer
var _mask: TextureRect
var _gradient: Gradient
var _column: VBoxContainer
var _sheets: VBoxContainer
## What is printed on each page, and the leaf it is printed on, as tall as the tallest.
var _pages: Array[Control] = []
var _leaves: Array[VBoxContainer] = []
var _podiums: Array[ResultsPodium] = []
var _turning: Tween
## The page being turned to, and one waiting to be until the pages are laid out.
var _target := 0
var _going := -1
var _going_slowly := true
## Frames since the pages last changed, which are laid out a frame or two later.
var _settling := 0
var _evening := false


## A bill printed on paper of [param style].
static func create(style: StyleBox, width: float) -> PayoutBill:
	var bill := PayoutBill.new()
	bill.name = "Bill"
	bill._build(style, width)
	return bill


## Prints [param contents] on the bill, a page each, and [param end] at the foot of the last.
## What was printed before and is not among them is thrown away. The same pages again print
## nothing new.
func set_pages(contents: Array[Control], end: Control) -> void:
	if contents == _pages and not _leaves.is_empty():
		if end == null or end.get_parent() == _leaves[-1]:
			return
	for leaf: VBoxContainer in _leaves:
		for child: Node in leaf.get_children():
			leaf.remove_child(child)
			if child != end and not contents.has(child):
				child.queue_free()
	for child: Node in _sheets.get_children():
		_sheets.remove_child(child)
		child.queue_free()
	_pages = contents.duplicate()
	_leaves.clear()
	for i: int in contents.size():
		if i > 0:
			_sheets.add_child(MenuTheme.perforation())
		var leaf := VBoxContainer.new()
		leaf.name = "Leaf%d" % i
		leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leaf.add_theme_constant_override("separation", SEPARATION)
		leaf.add_child(contents[i])
		var blank := Control.new()
		blank.name = "Blank"
		blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blank.size_flags_vertical = Control.SIZE_EXPAND_FILL
		leaf.add_child(blank)
		if end != null and i == contents.size() - 1:
			leaf.add_child(end)
			if not end.minimum_size_changed.is_connected(_even_out_later):
				end.minimum_size_changed.connect(_even_out_later)
		_sheets.add_child(leaf)
		_leaves.append(leaf)
		if not contents[i].minimum_size_changed.is_connected(_even_out_later):
			contents[i].minimum_size_changed.connect(_even_out_later)
	_podiums.clear()
	for podium: Node in _sheets.find_children("*", "ResultsPodium", true, false):
		_podiums.append(podium as ResultsPodium)
	_settling = 0
	_even_out_later()


func page_count() -> int:
	return _pages.size()


## Brings page [param index] to the middle of the screen, over a moment, or at once without
## [param slowly]; once the pages are laid out, if they are not yet.
func turn_to(index: int, slowly := true) -> void:
	if _pages.is_empty():
		return
	_going = clampi(index, 0, _pages.size() - 1)
	_going_slowly = slowly
	if _settling >= 2:
		_go()


## The page [param step] on from the one in view, or from the one being turned to.
func turn_by(step: int) -> void:
	turn_to(aim() + step)


## The page being turned to, or the one in view.
func aim() -> int:
	if _going >= 0:
		return _going
	return _target if is_turning() else page


func is_turning() -> bool:
	return _turning != null and _turning.is_valid() and _turning.is_running()


## Moves the bill [param step] down by hand, stopping a turn. Whether there was anywhere to move.
func scroll_by(step: int) -> bool:
	if _most() <= 0:
		return false
	_stop()
	_scroll.scroll_vertical = clampi(_scroll.scroll_vertical + step, 0, _most())
	return true


## How far down the bill is scrolled, and how far it can be.
func scrolled() -> int:
	return _scroll.scroll_vertical


func _most() -> int:
	return maxi(roundi(_column.size.y - _scroll.size.y), 0)


func _process(_delta: float) -> void:
	_settling += 1
	if _going >= 0 and _settling >= 2:
		_go()
	# On a screen the whole bill fits on, a page turned to is the page being read, there being
	# nothing to scroll.
	var now := _in_view() if _most() > 0 else clampi(_target, 0, maxi(_pages.size() - 1, 0))
	if now != page:
		page = now
		turned.emit(page)
	# A podium's little world is drawn only while it can be seen.
	var shown := get_global_rect()
	for podium: ResultsPodium in _podiums:
		if is_instance_valid(podium):
			podium.draw_while(is_visible_in_tree() and shown.intersects(podium.get_global_rect()))


func _go() -> void:
	var index := _going
	_going = -1
	_target = index
	_stop()
	var to := _rest_of(index)
	if not _going_slowly:
		_scroll.scroll_vertical = to
		return
	_turning = create_tween()
	(
		_turning
		. tween_property(_scroll, "scroll_vertical", to, TURN)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)


func _stop() -> void:
	if _turning != null and _turning.is_valid():
		_turning.kill()
	_turning = null


## Where the bill is scrolled to with page [param index] in the middle of what is shown, its top
## clear of the fade over it, as near as the ends of the bill let it be.
func _rest_of(index: int) -> int:
	var leaf := _leaves[index]
	var top := _top_of(leaf)
	var room := maxf((_scroll.size.y - leaf.size.y) * 0.5, FADE)
	return clampi(roundi(top - room), 0, _most())


## How far down the bill [param part] starts.
func _top_of(part: Control) -> float:
	var into := _column.get_global_transform().affine_inverse() * part.get_global_transform()
	return into.origin.y


## The page whose middle is nearest the middle of what is shown: the first at the top, the last
## at the foot.
func _in_view() -> int:
	if _leaves.size() < 2:
		return 0
	var at := _scroll.scroll_vertical
	if at <= 0:
		return 0
	if at >= _most():
		return _leaves.size() - 1
	var middle := at + _scroll.size.y * 0.5
	var nearest := 0
	var off := INF
	for i: int in _leaves.size():
		var away := absf(_top_of(_leaves[i]) + _leaves[i].size.y * 0.5 - middle)
		if away < off:
			off = away
			nearest = i
	return nearest


func _even_out_later() -> void:
	if not _evening:
		_evening = true
		_even_out.call_deferred()


## Every page as tall as the tallest, paper left blank at the foot of a shorter one.
func _even_out() -> void:
	_evening = false
	var tallest := 0.0
	for leaf: VBoxContainer in _leaves:
		if is_instance_valid(leaf):
			tallest = maxf(tallest, leaf.get_minimum_size().y)
	for leaf: VBoxContainer in _leaves:
		if is_instance_valid(leaf):
			leaf.custom_minimum_size.y = tallest
	_settling = 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _gradient != null:
		_shape_fade()


## Opaque but for [constant FADE] at either end, however tall it is.
func _shape_fade() -> void:
	var share := clampf(FADE / maxf(size.y, 1.0), 0.0, 0.5)
	_gradient.offsets = PackedFloat32Array([0.0, share, 1.0 - share, 1.0])
	_gradient.colors = PackedColorArray(
		[Color(1.0, 1.0, 1.0, 0.0), Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)]
	)


func _on_scroll_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if (wheel != null and wheel.pressed) or event is InputEventScreenDrag:
		_stop()


func _build(style: StyleBox, width: float) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Drawn only as a mask: what the bill's paper shows through, fading at either end.
	_mask = TextureRect.new()
	_mask.name = "Fade"
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mask.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mask.stretch_mode = TextureRect.STRETCH_SCALE
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_gradient = Gradient.new()
	var texture := GradientTexture2D.new()
	texture.gradient = _gradient
	texture.width = 4
	texture.height = 512
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	_mask.texture = texture
	_shape_fade()
	add_child(_mask)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.follow_focus = false
	_scroll.gui_input.connect(_on_scroll_input)
	_mask.add_child(_scroll)
	# As tall as what is shown when the bill is shorter, with the bill in its middle.
	_column = VBoxContainer.new()
	_column.name = "Column"
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(_column)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	margin.add_theme_constant_override("margin_top", roundi(FADE + ROOM))
	margin.add_theme_constant_override("margin_bottom", roundi(FADE + ROOM))
	_column.add_child(margin)
	paper = PanelContainer.new()
	paper.name = "Paper"
	paper.custom_minimum_size = Vector2(width, 0.0)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_theme_stylebox_override("panel", style)
	margin.add_child(paper)
	_sheets = VBoxContainer.new()
	_sheets.name = "Sheets"
	_sheets.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheets.add_theme_constant_override("separation", SEPARATION)
	paper.add_child(_sheets)
