class_name KeyRail
extends Control
## The kart dialog's key board, GAME.md 4.4a: a key hung from the timber rail along the top of the
## bay for each whose kart the dialog dresses, see [KeyTag], the seats' keys first and then the
## profiles' tags. Laid over the rail, from its left end past the page keys' glyphs to its right
## end, the keys hanging under it. More than it has room for, they scroll along it: to keep the one
## the dialog is on in sight as the page keys turn the tabs, by the mouse's wheel over it, and
## dragged along by the mouse or a finger, flung on a little as they are let go, and a railful at a
## time by a fob at either end, as the seats' keys are; while there are more past an end, the keys
## fade out toward it and its fob shows. A key pressed, rather than dragged, is picked. Each key is
## laid on a whole pixel of the screen, its picture's left edge, so it does not shimmer as it moves.

signal picked(index: int)

## Where the first key hangs from the rail's left end, and how deep the keys hang under it.
const LEAD := 24.0
const DEEP := 110.0
## How far in from either end the keys fade out over, how far a click of the wheel scrolls them,
## how far a press moves before it is a drag rather than a press, how quickly the keys ease to where
## they are scrolled to, and how far on they are flung for how fast they were dragged, and how long
## a drag held still before it is let go is no fling.
const FADE := 170.0
const WHEEL_STEP := 120.0
const SLOP := 8.0
const EASE_RATE := 0.08
const FLING := 0.2
const FLING_STILL := 0.08
## How much of a key has to be seen for it to be picked.
const PICKED_SEEN := 0.3
## The fobs at either end: how big, how far in from the end, and how long they take to show and to
## go; and the fob's plastic and the hole through it.
const ARROW := Vector2(46.0, 62.0)
const ARROW_IN := 4.0
const ARROW_FADE := 0.15
const FOB := Color("#34363d")
const FOB_HOLE := Color("#16161a")
## The fobs drawn once each way they look and kept, see [BayArt], as the keys are: how far round
## a fob its picture reaches, for its shadow, and the group told when one is ready.
const FOB_AROUND := 4.0
const FOBS := &"key_rail_fobs"

var keys: Array[KeyTag] = []
## The fobs, back toward the first key and on toward the last.
var arrows: Array[Button] = []
## Whether the page keys' glyphs are at the rail's left end, the back fob beside them rather than
## at the end.
var hinted := true:
	set(on):
		hinted = on
		_laid = -1.0

## Where each key hangs along the rail unscrolled, and how long they are end to end.
var _places: Array[float] = []
var _length := 0.0
## How far along they are scrolled to, how far they are now, and how far they were last laid out.
var _to := 0.0
var _at := 0.0
var _laid := -1.0
## A press on it: whether it is down, whether it has moved enough to be a drag, where it was, how
## far the keys were scrolled then, and how fast and when it last moved, for a fling.
var _pressed := false
var _dragging := false
var _grab := Vector2.ZERO
var _grab_from := 0.0
var _speed := 0.0
var _moved_at := 0
var _last_x := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	for way: int in [-1, 1]:
		var arrow := Button.new()
		arrow.name = "Back" if way < 0 else "On"
		arrow.flat = true
		arrow.focus_mode = Control.FOCUS_NONE
		arrow.size = ARROW
		for look: StringName in [
			&"normal", &"hover", &"pressed", &"disabled", &"focus", &"hover_pressed"
		]:
			arrow.add_theme_stylebox_override(look, StyleBoxEmpty.new())
		arrow.draw.connect(_draw_arrow.bind(arrow, way))
		arrow.add_to_group(FOBS)
		for told: Signal in [
			arrow.mouse_entered, arrow.mouse_exited, arrow.button_down, arrow.button_up
		]:
			told.connect(arrow.queue_redraw)
		arrow.pressed.connect(page.bind(way))
		arrow.modulate.a = 0.0
		arrow.visible = false
		add_child(arrow)
		arrows.append(arrow)


## Hangs [param key] on the rail after the others, under the chevrons.
func add_key(key: KeyTag) -> void:
	_places.append(_length + LEAD if keys.is_empty() else _length + BayArt.KEY_GAP)
	_length = _places[-1] + key.size.x
	add_child(key)
	for arrow: Button in arrows:
		move_child(arrow, -1)
	keys.append(key)
	_laid = -1.0


## Scrolled a railful, less its fades, toward [param way], -1 back to the first key and 1 on.
func page(way: int) -> void:
	scroll_to(_to + way * maxf(size.x - FADE * 2.0, FADE))


## How far the keys can scroll: as far as they reach past the rail.
func most() -> float:
	return maxf(_length + LEAD - size.x, 0.0)


## How far along they are scrolled now.
func scrolled() -> float:
	return _at


## Scrolled to have the key of [param index] in sight, in the middle of the rail as far as it goes,
## there at once for [param at_once].
func follow(index: int, at_once := false) -> void:
	if index < 0 or index >= keys.size():
		return
	var middle := _places[index] + keys[index].size.x * 0.5
	scroll_to(middle - size.x * 0.5, at_once)


## Scrolled to [param along], as far as it goes, there at once for [param at_once].
func scroll_to(along: float, at_once := false) -> void:
	_to = clampf(along, 0.0, most())
	if at_once:
		_at = _to
	_lay()


## The key at [param point] on it that is seen enough to be picked, or -1.
func key_at(point: Vector2) -> int:
	for i: int in keys.size():
		var key := keys[i]
		if key.visible and key.seen > PICKED_SEEN:
			if Rect2(key.position, key.size).has_point(point):
				return i
	return -1


func _process(delta: float) -> void:
	if not _dragging:
		_at = lerpf(_at, _to, 1.0 - exp(-delta / EASE_RATE))
		if absf(_at - _to) < 0.1:
			_at = _to
	if absf(_at - _laid) > 0.01:
		_lay()
	# Each fob only while there are more keys its way.
	for i: int in arrows.size():
		var arrow := arrows[i]
		var more := _at > 1.0 if i == 0 else _at < most() - 1.0
		arrow.modulate.a = move_toward(arrow.modulate.a, 1.0 if more else 0.0, delta / ARROW_FADE)
		arrow.visible = arrow.modulate.a > 0.0


## The keys where they are scrolled to, each faded by how near it is to an end there are more past:
## its fade worked out at its edges and wherever the rail's turns in between, see [member
## KeyTag.fades].
func _lay() -> void:
	_laid = _at
	var under := BayArt.RAIL.size.y
	if arrows.size() == 2:
		var rail_end := BayArt.RAIL.position.x - position.x
		arrows[0].position = Vector2((0.0 if hinted else rail_end) + ARROW_IN, under)
		arrows[1].position = Vector2(size.x - ARROW_IN - ARROW.x, under)
	var past_left := clampf(_at / FADE, 0.0, 1.0)
	var past_right := clampf((most() - _at) / FADE, 0.0, 1.0)
	var screen := Transform2D.IDENTITY
	if is_inside_tree():
		screen = get_viewport().get_final_transform() * get_global_transform_with_canvas()
	var pixel := 1.0 / maxf(screen.get_scale().x, 0.01)
	for i: int in keys.size():
		var key := keys[i]
		var x := _places[i] - _at
		var edge := (screen * Vector2(x - KeyTag.AROUND, 0.0)).x
		key.position = Vector2(x + (roundf(edge) - edge) * pixel, under)
		var left := key.position.x - KeyTag.AROUND
		var right := key.position.x + key.size.x + KeyTag.AROUND
		var along := PackedVector2Array()
		var shows := false
		for turn: float in [left, 0.0, FADE, size.x - FADE, size.x, right]:
			if (
				turn < left
				or turn > right
				or (not along.is_empty() and turn <= along[-1].x + key.position.x)
			):
				continue
			var faded := _seen(turn, past_left, past_right)
			along.append(Vector2(turn - key.position.x, faded))
			shows = shows or faded > 0.0
		key.fades = along
		key.seen = _seen(key.position.x + key.size.x * 0.5, past_left, past_right)
		key.visible = shows


## How much is seen at [param x] along the rail: faded out toward an end, as far as there are more
## past it, [param past_left] and [param past_right].
func _seen(x: float, past_left: float, past_right: float) -> float:
	var left := lerpf(1.0, clampf(x / FADE, 0.0, 1.0), past_left)
	var right := lerpf(1.0, clampf((size.x - x) / FADE, 0.0, 1.0), past_right)
	return left * right


## Taking the pointer only over a key, unless there are more than it has room for: then anywhere
## along it, to scroll it.
func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return false
	return most() > 0.0 or key_at(point) >= 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and not _pressed:
		_point_at(-1)


## The wheel scrolls it, either way it turns; a press picks the key it is on, unless it is dragged.
## A finger is heard as the mouse it stands in for.
func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		var factor := button.factor if button.factor > 0.0 else 1.0
		match button.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
				if button.pressed:
					scroll_to(_to - WHEEL_STEP * factor)
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
				if button.pressed:
					scroll_to(_to + WHEEL_STEP * factor)
			MOUSE_BUTTON_LEFT:
				_press(button.pressed, button.position)
			_:
				return
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		if _pressed:
			_drag(motion.position)
		else:
			_point_at(key_at(motion.position))
		accept_event()


func _press(down: bool, at: Vector2) -> void:
	if down:
		_pressed = true
		_dragging = false
		_grab = at
		_grab_from = _at
		_speed = 0.0
		_last_x = at.x
		_moved_at = Time.get_ticks_msec()
		return
	if not _pressed:
		return
	_pressed = false
	if _dragging:
		_dragging = false
		var still := (Time.get_ticks_msec() - _moved_at) * 0.001 > FLING_STILL
		scroll_to(_at + (0.0 if still else _speed * FLING))
		return
	var key := key_at(at)
	if key >= 0 and key == key_at(_grab):
		picked.emit(key)


func _drag(at: Vector2) -> void:
	if not _dragging and absf(at.x - _grab.x) > SLOP:
		_dragging = true
		_point_at(-1)
	if not _dragging:
		return
	var now := Time.get_ticks_msec()
	var took := maxf((now - _moved_at) * 0.001, 0.001)
	_speed = lerpf(_speed, (_last_x - at.x) / took, 0.5)
	_last_x = at.x
	_moved_at = now
	_at = clampf(_grab_from - (at.x - _grab.x), 0.0, most())
	_to = _at
	_lay()


func _point_at(index: int) -> void:
	for i: int in keys.size():
		keys[i].pointed = i == index


## A fob's look, see [method draw_fob], pointing [param way]: lit while the mouse is on it, pulled
## down a little while it is pressed. From its kept picture, one draw rather than a handful; drawn
## as itself until that is ready.
func _draw_arrow(arrow: Button, way: int) -> void:
	var down := arrow.get_draw_mode() in [BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED]
	var lit := arrow.is_hovered()
	var box := Rect2(Vector2.ONE * FOB_AROUND, arrow.size.round())
	var art := BayArt.kept(
		arrow,
		"fob:%d:%s:%s:%s" % [way, lit, down, box.size],
		box.grow(FOB_AROUND).size,
		func(on: CanvasItem) -> void: draw_fob(on, box, way, lit, down),
		FOBS
	)
	if art != null:
		arrow.draw_texture_rect(
			art, Rect2(-Vector2.ONE * FOB_AROUND, box.grow(FOB_AROUND).size), false
		)
	else:
		draw_fob(arrow, Rect2(Vector2.ZERO, arrow.size), way, lit, down)


## A dark plastic fob as the seats' keys are, see [method BayArt.draw_key], hung under the rail in
## [param box] from a split ring on a chrome hook, pointing [param way], -1 left and 1 right, with
## a white chevron on it: lighter and its chevron gold for [param lit], pulled down a little for
## [param down].
static func draw_fob(on: CanvasItem, box: Rect2, way: int, lit: bool, down: bool) -> void:
	var middle := box.get_center().x
	var drop := 3.0 if down else 0.0
	on.draw_line(
		Vector2(middle, box.position.y), Vector2(middle, 8.0 + drop), BayArt.CHROME, 3.0, true
	)
	var ring := Vector2(middle, box.position.y + 14.0 + drop)
	on.draw_arc(ring, 7.0, 0.0, TAU, 24, BayArt.CHROME, 2.4, true)
	var body := Rect2(
		Vector2(box.position.x + 4.0, box.position.y + 18.0 + drop),
		Vector2(box.size.x - 8.0, box.size.y - 22.0 - 3.0)
	)
	var shape := FeltArt.rounded(body, 12.0)
	_smooth(on, BayArt.moved(shape, Vector2(2.0, 4.0)), Color(0, 0, 0, 0.45))
	var plastic := FOB.lightened(0.16) if lit else FOB
	_smooth(on, shape, plastic)
	var grain := PackedVector2Array()
	for corner: Vector2 in shape:
		grain.append(corner / 90.0)
	on.draw_colored_polygon(shape, Color(1, 1, 1, 0.06), grain, FeltArt.grain())
	on.draw_circle(Vector2(middle, body.position.y + 7.0), 4.0, FOB_HOLE)
	var ink := HouseTheme.FOIL if lit else Color(1, 1, 1, 0.92)
	BoardArt.chevron(on, body.grow_individual(0.0, -12.0, 0.0, 0.0), way, ink)


## [param shape] filled with [param fill], its edge smoothed by a line of the same round it.
static func _smooth(on: CanvasItem, shape: PackedVector2Array, fill: Color) -> void:
	on.draw_colored_polygon(shape, fill)
	var edge := shape.duplicate()
	edge.append(shape[0])
	on.draw_polyline(edge, fill, 1.0, true)
