class_name LoyaltyMapView
extends Control
## The loyalty program's map, GAME.md 8.9: a road map the house printed on its cream paper, with
## the creases of a map that has been folded, drawn from the grid of [LoyaltyMap] and larger than
## the room it is shown in. It scrolls to keep the cursor in view, a wheel or a pinch zooms it
## between the whole map and close enough to read every sign, and a mouse or a finger drags it; a
## click or a tap on a landmark sends the cursor there.
##
## Drawn at the zoom rather than drawn once and scaled, so the type and the lines are sharp at
## every zoom. The grid's columns with a landmark in them are wide and the rest narrow, its rows
## with a landmark in them tall and the rest short, so the grid's runs of road between landmarks
## read as roads rather than as characters.

## A click or a tap on the landmark [param id].
signal picked(id: StringName)
## The cursor has come to the landmark [param id].
signal arrived(id: StringName)

## How wide a column of the grid with a landmark in it is, and one without, and how tall a row with
## one and a row without, at a zoom of one; and the paper round the grid.
const WIDE := 168.0
const NARROW := 12.0
const TALL := 126.0
const SHORT := 44.0
const MARGIN := Vector2(96.0, 84.0)
## A sign, and the label of its bet under it, at a zoom of one.
const SIGN := Vector2(138.0, 52.0)
const SIGN_LIFT := 16.0
const BET_SIZE := 11.0
const BET_LINES := 3
const BAR := 4.0
## The roads: the house's, its casing and the paper inside it, and Kit's pencil, at a zoom of one;
## how faint a road no landmark at either end of has been won.
const ROAD := 9.0
const ROAD_INSIDE := 4.5
const PENCIL_LINE := 2.2
const FAINT := 0.24
const FAINT_LINE := 2.6
## The roundabout: how far round it is, its ring as wide as a road, and the pot in the middle.
const RING := 0.42
const POT := "JACKPOT"
## The districts' names, printed over them, and Kit's over the pencil.
const STRIP := "THE STRIP"
const DEPARTMENT := "DEPARTMENT OF KARTS"
const OFF_THE_BOOKS := "off the books"
const DISTRICT_SIZE := 22.0
## What the map says in its corner, under the program's name.
const IMPRINT := "Road map  ·  Not to scale"
## The creases: folded in three across and two down.
const FOLDS := Vector2i(3, 2)
const FOLD_DARK := Color(0.0, 0.0, 0.0, 0.1)
const FOLD_LIGHT := Color(1.0, 1.0, 1.0, 0.35)
## How far the zoom goes in, and each notch of the wheel; how far a press moves before it is a drag
## rather than a click; and how quickly the map comes round to where the cursor is.
const ZOOM_MOST := 1.7
const ZOOM_START := 1.0
const ZOOM_STEP := 1.15
const DRAG := 9.0
const FOLLOW := 9.0
## How much room the cursor keeps from the edge before the map moves to keep it in view, a share
## of the room each way.
const KEEP := 0.22
## The cursor drawn, at a zoom of one, and where it stands by a sign: before it, on the road it
## came in by.
const KART := 96.0
const KART_OFF := 10.0

## The profile whose map it is, and the cursor driving it.
var profile: Profile
var cursor: LoyaltyCursor
## How far it is zoomed, and where the paper's top left corner is drawn.
var zoom := ZOOM_START
var offset := Vector2.ZERO
## The program's name, printed in the corner.
var program := ""

var _map: LoyaltyMap
var _cols := PackedFloat32Array()
var _rows := PackedFloat32Array()
var _first_row := 0
var _paper := Vector2.ZERO
## The cells each district's drawn landmarks stand in, from its first to its last, by district;
## and the roundabout's middle and how far round its ring is, on the paper at a zoom of one.
var _spans: Dictionary[int, Rect2i] = {}
var _ring_middle := Vector2.ZERO
var _ring := 0.0
## Where the map is coming round to, while it follows the cursor; and whether it does.
var _goal := Vector2.ZERO
var _following := false
## A press of the mouse or a finger: where it went down and where the paper was then, and whether
## it has become a drag; the fingers down, for a pinch.
var _pressed := false
var _press_at := Vector2.ZERO
var _press_offset := Vector2.ZERO
var _dragged := false
var _fingers: Dictionary[int, Vector2] = {}
var _pinch := 0.0
## The way the cursor came in to the landmark it stands at, so it stands before it on that road.
var _came := Vector2.RIGHT
var _laid := false
## Whether the player has dragged or zoomed the map since it was put up.
var _moved := false


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_map = Loyalty.map()
	_lay_grid()
	resized.connect(_on_resized)
	if cursor != null:
		cursor.moved.connect(_on_cursor_moved)
		cursor.arrived.connect(_on_cursor_arrived)


## Stands the cursor at the landmark [param id], the map round it.
func stand_at(id: StringName) -> void:
	if cursor == null:
		return
	cursor.place(id, _stop_at(id, _came), _came)
	show_point(cursor.point, false)


## Sends the cursor along the road from where it stands in [param way] on the map, to the next
## landmark that way. False where no road it can drive goes that way.
func drive_toward(way: Vector2i) -> bool:
	if cursor == null:
		return false
	cursor.finish()
	for id: StringName in _roads_from(cursor.at):
		var cells := _map.path(cursor.at, id)
		if cells.size() >= 2 and cells[1] - cells[0] == way:
			_drive(cells, id)
			return true
	return false


## Sends the cursor to the landmark [param id], along the roads it can drive, the fewest of them.
## False for one it cannot reach.
func drive_to(id: StringName) -> bool:
	if cursor == null:
		return false
	cursor.finish()
	if id == cursor.at:
		arrived.emit(id)
		return true
	var route := _route(cursor.at, id)
	if route.is_empty():
		return false
	var cells: Array[Vector2i] = []
	for i: int in range(1, route.size()):
		var leg := _map.path(route[i - 1], route[i])
		cells.append_array(leg.slice(0 if cells.is_empty() else 1))
	_drive(cells, id)
	return true


## Every landmark drawn on the profile's map.
func drawn() -> Array[LoyaltyLandmark]:
	var shown: Array[LoyaltyLandmark] = []
	for each: LoyaltyLandmark in _map.landmarks:
		if Loyalty.is_drawn(profile, each):
			shown.append(each)
	return shown


## The landmark whose sign is under [param at] in the view, or null.
func landmark_at(at: Vector2) -> LoyaltyLandmark:
	for each: LoyaltyLandmark in drawn():
		if sign_rect(each.id).grow(4.0 * zoom).has_point(at):
			return each
	return null


## Where the sign of [param id] is in the view.
func sign_rect(id: StringName) -> Rect2:
	var middle := _to_view(_middle(_map.at(id))) - Vector2(0.0, SIGN_LIFT * zoom)
	return Rect2(middle - SIGN * zoom * 0.5, SIGN * zoom)


## The zoom at which the whole map fits the room.
func fit_zoom() -> float:
	if _paper.x <= 0.0 or size.x <= 0.0:
		return ZOOM_START
	return minf(size.x / _paper.x, size.y / _paper.y)


## Zooms to [param to], the point [param about] of the view staying where it is.
func zoom_to(to: float, about: Vector2) -> void:
	var least := minf(fit_zoom(), ZOOM_MOST)
	var was := zoom
	zoom = clampf(to, least, ZOOM_MOST)
	offset = about - (about - offset) * (zoom / was)
	_following = false
	_moved = true
	offset = _clamped(offset)
	queue_redraw()


## Moves the map so [param at], a point on it, is in the middle of the room as far as the paper
## goes, coming round to it or there at once.
func show_point(at: Vector2, smoothly: bool) -> void:
	_goal = _clamped(size * 0.5 - at * zoom)
	_following = smoothly
	if not smoothly:
		offset = _goal
	queue_redraw()


func _process(delta: float) -> void:
	if not _following:
		return
	offset = offset.lerp(_goal, 1.0 - exp(-FOLLOW * delta))
	if offset.distance_to(_goal) < 0.5:
		offset = _goal
		_following = false
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	var finger := event as InputEventScreenDrag
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if touch != null:
		_on_touch(touch)
	elif finger != null:
		_on_finger(finger)
	elif button != null:
		_on_button(button)
	elif motion != null and _pressed and _fingers.size() < 2:
		if not _dragged and motion.position.distance_to(_press_at) > DRAG:
			_dragged = true
		if _dragged:
			_following = false
			_moved = true
			offset = _clamped(_press_offset + motion.position - _press_at)
			queue_redraw()
	elif event is InputEventMagnifyGesture:
		var magnify := event as InputEventMagnifyGesture
		zoom_to(zoom * magnify.factor, magnify.position)
	elif event is InputEventPanGesture:
		var pan := event as InputEventPanGesture
		_following = false
		_moved = true
		offset = _clamped(offset - pan.delta * 12.0)
		queue_redraw()
	else:
		return
	accept_event()


func _on_button(button: InputEventMouseButton) -> void:
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP when button.pressed:
			zoom_to(zoom * ZOOM_STEP, button.position)
		MOUSE_BUTTON_WHEEL_DOWN when button.pressed:
			zoom_to(zoom / ZOOM_STEP, button.position)
		MOUSE_BUTTON_LEFT:
			if button.pressed:
				_pressed = true
				_dragged = false
				_press_at = button.position
				_press_offset = offset
				grab_focus()
				return
			var clicked := _pressed and not _dragged and _fingers.size() < 2
			_pressed = false
			var landmark := landmark_at(button.position) if clicked else null
			if landmark != null:
				picked.emit(landmark.id)


## A second finger down starts a pinch; the mouse a finger is taken for drags the map otherwise.
func _on_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		_fingers[touch.index] = touch.position
	else:
		_fingers.erase(touch.index)
	if _fingers.size() >= 2:
		_dragged = true
		_pinch = _spread()


func _on_finger(finger: InputEventScreenDrag) -> void:
	if not _fingers.has(finger.index):
		return
	var middle_was := _middle_of_fingers()
	_fingers[finger.index] = finger.position
	if _fingers.size() < 2:
		return
	var spread := _spread()
	var middle := _middle_of_fingers()
	_following = false
	offset = _clamped(offset + middle - middle_was)
	if _pinch > 0.0 and spread > 0.0:
		zoom_to(zoom * spread / _pinch, middle)
	_pinch = spread
	queue_redraw()


func _spread() -> float:
	var points := _fingers.values()
	return (points[0] as Vector2).distance_to(points[1]) if points.size() >= 2 else 0.0


func _middle_of_fingers() -> Vector2:
	var sum := Vector2.ZERO
	for point: Vector2 in _fingers.values():
		sum += point
	return sum / maxf(float(_fingers.size()), 1.0)


func _on_resized() -> void:
	if not _laid and size.x > 0.0:
		_laid = true
		zoom = clampf(ZOOM_START, minf(fit_zoom(), ZOOM_MOST), ZOOM_MOST)
		if cursor != null:
			show_point(cursor.point, false)
		return
	zoom = clampf(zoom, minf(fit_zoom(), ZOOM_MOST), ZOOM_MOST)
	# Laid out again round the cursor, as the room settles, until the player moves the map.
	if cursor != null and not _moved:
		show_point(cursor.point, false)
	offset = _clamped(offset)
	queue_redraw()


func _on_cursor_moved() -> void:
	if cursor.is_driving():
		var at := _to_view(cursor.point)
		var keep := size * KEEP
		if not Rect2(keep, size - keep * 2.0).has_point(at):
			show_point(cursor.point, true)
	queue_redraw()


func _on_cursor_arrived(id: StringName) -> void:
	queue_redraw()
	arrived.emit(id)


## Sends the cursor along [param cells] to [param id], standing before its sign on the road in.
func _drive(cells: Array[Vector2i], id: StringName) -> void:
	var points := PackedVector2Array()
	for i: int in range(1, cells.size() - 1):
		points.append(_middle(cells[i]))
	var last := cells[-1] - cells[-2]
	_came = Vector2(last)
	points.append(_stop_at(id, _came))
	cursor.drive(points, id)
	show_point(_middle(cells[-1]), true)


## Where the cursor stands at [param id], come in [param way]: before its sign on that road.
func _stop_at(id: StringName, way: Vector2) -> Vector2:
	var middle := _middle(_map.at(id)) - Vector2(0.0, SIGN_LIFT)
	var reach := SIGN * 0.5 + Vector2.ONE * (KART * 0.5 - KART_OFF)
	return middle - way * reach


## The landmarks [param id] has a road to that the profile's map draws.
func _roads_from(id: StringName) -> Array[StringName]:
	var roads: Array[StringName] = []
	for other: StringName in _map.roads_of(id):
		var landmark := _map.landmark(other)
		if landmark != null and Loyalty.is_drawn(profile, landmark):
			roads.append(other)
	return roads


## The landmarks from [param from] to [param to] along the fewest drawn roads, both ends in it;
## none where no road goes.
func _route(from: StringName, to: StringName) -> Array[StringName]:
	var came := {from: from}
	var next: Array[StringName] = [from]
	while not next.is_empty() and not came.has(to):
		var here: StringName = next.pop_front()
		for other: StringName in _roads_from(here):
			if not came.has(other):
				came[other] = here
				next.append(other)
	var route: Array[StringName] = []
	if not came.has(to):
		return route
	route.append(to)
	while route[0] != from:
		route.push_front(came[route[0]])
	return route


## Works out how wide each column of the grid is and how tall each row, and the paper round them;
## off the books' rows only where it is drawn.
func _lay_grid() -> void:
	var cells := _map.size()
	var wide := {}
	var tall := {}
	_first_row = cells.y
	_spans.clear()
	for each: LoyaltyLandmark in drawn():
		var at := _map.at(each.id)
		wide[at.x] = true
		tall[at.y] = true
		_first_row = mini(_first_row, at.y)
		var span: Rect2i = _spans.get(each.district, Rect2i(at, Vector2i.ZERO))
		_spans[each.district] = span.expand(at)
	for each: LoyaltyLandmark in _map.landmarks:
		wide[_map.at(each.id).x] = true
	_cols = PackedFloat32Array()
	var x := MARGIN.x
	for column: int in cells.x + 1:
		_cols.append(x)
		x += WIDE if wide.has(column) else NARROW
	_rows = PackedFloat32Array()
	var y := MARGIN.y
	for row: int in cells.y + 1:
		_rows.append(y)
		if row >= _first_row:
			y += TALL if tall.has(row) else SHORT
	_paper = Vector2(x + MARGIN.x, y + MARGIN.y * 0.6)
	var ring: Array[Vector2i] = []
	for row: int in cells.y:
		for column: int in cells.x:
			if _map.cell(Vector2i(column, row)) == LoyaltyMap.ROUNDABOUT:
				ring.append(Vector2i(column, row))
	if ring.is_empty():
		return
	_ring_middle = (_middle(ring[0]) + _middle(ring[-1])) * 0.5
	_ring = (
		minf(_cols[ring[-1].x + 1] - _cols[ring[0].x], _rows[ring[-1].y + 1] - _rows[ring[0].y])
		* RING
	)


## The middle of [param cell] on the paper, at a zoom of one.
func _middle(cell: Vector2i) -> Vector2:
	var column := clampi(cell.x, 0, _cols.size() - 2)
	var row := clampi(cell.y, 0, _rows.size() - 2)
	return Vector2((_cols[column] + _cols[column + 1]) * 0.5, (_rows[row] + _rows[row + 1]) * 0.5)


## [param at], a point on the paper at a zoom of one, where it is in the view.
func _to_view(at: Vector2) -> Vector2:
	return offset + at * zoom


## [param wanted] for the paper's corner, kept so the paper fills the room, or is in the middle of
## it where it is smaller.
func _clamped(wanted: Vector2) -> Vector2:
	var shown := _paper * zoom
	var kept := wanted
	for axis: int in 2:
		if shown[axis] <= size[axis]:
			kept[axis] = (size[axis] - shown[axis]) * 0.5
		else:
			kept[axis] = clampf(wanted[axis], size[axis] - shown[axis], 0.0)
	return kept


func _draw() -> void:
	if _paper == Vector2.ZERO:
		return
	_draw_paper()
	_draw_districts()
	_draw_roads()
	_draw_roundabout()
	for each: LoyaltyLandmark in drawn():
		_draw_landmark(each)
	_draw_cursor()


## The paper: its shadow, the cream, the panels of its folds a shade apart, the creases, a rule
## round its edge and the imprint in its corner.
func _draw_paper() -> void:
	var sheet := Rect2(offset, _paper * zoom)
	draw_rect(Rect2(sheet.position + Vector2(5.0, 7.0) * zoom, sheet.size), Color(0, 0, 0, 0.35))
	draw_rect(sheet, HouseTheme.PAPER)
	var panel := sheet.size / Vector2(FOLDS)
	for across: int in FOLDS.x:
		for down: int in FOLDS.y:
			if (across + down) % 2 == 1:
				var at := sheet.position + panel * Vector2(across, down)
				draw_rect(Rect2(at, panel), Color(HouseTheme.PAPER_LOW, 0.22))
	for across: int in range(1, FOLDS.x):
		var x := sheet.position.x + panel.x * across
		draw_line(Vector2(x, sheet.position.y), Vector2(x, sheet.end.y), FOLD_DARK, 1.5)
		draw_line(
			Vector2(x + 1.5, sheet.position.y), Vector2(x + 1.5, sheet.end.y), FOLD_LIGHT, 1.0
		)
	for down: int in range(1, FOLDS.y):
		var y := sheet.position.y + panel.y * down
		draw_line(Vector2(sheet.position.x, y), Vector2(sheet.end.x, y), FOLD_DARK, 1.5)
		draw_line(
			Vector2(sheet.position.x, y + 1.5), Vector2(sheet.end.x, y + 1.5), FOLD_LIGHT, 1.0
		)
	var rule := sheet.grow(-22.0 * zoom)
	draw_rect(rule, Color(HouseTheme.INK, 0.55), false, 1.2 * zoom)
	draw_rect(rule.grow(-4.0 * zoom), Color(HouseTheme.INK, 0.3), false, 0.8 * zoom)
	var font := Type.display_font()
	var size_of := maxi(roundi(18.0 * zoom), 1)
	var small := maxi(roundi(11.0 * zoom), 1)
	var wide := 420.0 * zoom
	var right := rule.end - Vector2(wide + 16.0 * zoom, 16.0 * zoom)
	draw_string(
		font,
		right - Vector2(0.0, 15.0 * zoom),
		program.to_upper(),
		HORIZONTAL_ALIGNMENT_RIGHT,
		wide,
		size_of,
		HouseTheme.INK
	)
	draw_string(
		Type.STRONG, right, IMPRINT, HORIZONTAL_ALIGNMENT_RIGHT, wide, small, HouseTheme.INK_FAINT
	)


## The districts' names over them: the Strip's and the Department's in the house's print, off the
## books in Kit's hand over the pencil, where it is drawn.
func _draw_districts() -> void:
	var names := {
		LoyaltyLandmark.District.STRIP: [STRIP, Color(HouseTheme.FOIL_LOW, 0.95), false],
		LoyaltyLandmark.District.DEPARTMENT: [DEPARTMENT, Color(LoyaltyArt.SIGN_BLUE, 0.9), true],
		LoyaltyLandmark.District.OFF_THE_BOOKS:
		[OFF_THE_BOOKS, Color(LoyaltyArt.PENCIL, 0.85), false],
	}
	for district: int in names:
		if not _spans.has(district):
			continue
		var span := _spans[district]
		var kit := district == LoyaltyLandmark.District.OFF_THE_BOOKS
		var font: Font = LoyaltyArt.HAND if kit else Type.display_font()
		var size_of := maxi(
			roundi(DISTRICT_SIZE * zoom * (LoyaltyArt.HAND_SCALE if kit else 1.0)), 1
		)
		var left := _to_view(Vector2(_cols[span.position.x], _rows[span.position.y]))
		var right := _to_view(Vector2(_cols[span.end.x + 1], 0.0)).x
		var named: Array = names[district]
		var at := left - Vector2(0.0, (16.0 if kit else 26.0) * zoom - SIGN_LIFT * zoom)
		var align := HORIZONTAL_ALIGNMENT_RIGHT if named[2] else HORIZONTAL_ALIGNMENT_LEFT
		draw_string(font, at, named[0], align, right - left.x, size_of, named[1])


## Every run of road on the drawn map: the house's in ink, cased, solid once a landmark at an end
## of it is won and faint until then; Kit's in pencil, the same.
func _draw_roads() -> void:
	for pass_at: int in 2:
		for run: Dictionary in _map.runs():
			var ends: Array[StringName] = []
			ends.assign(run["ends"])
			if not _run_drawn(ends):
				continue
			var solid := false
			for id: StringName in ends:
				solid = solid or profile.loyalty.has_won(id)
			var pencil: bool = run["pencil"]
			if pencil and pass_at == 1:
				continue
			var cells: Array[Vector2i] = []
			cells.assign(run["cells"])
			_draw_run(cells, pencil, solid, pass_at)


## Whether a run of road between [param ends] is drawn: every landmark at its ends drawn.
func _run_drawn(ends: Array[StringName]) -> bool:
	for id: StringName in ends:
		var landmark := _map.landmark(id)
		if landmark == null or not Loyalty.is_drawn(profile, landmark):
			return false
	return true


## One run of road through [param cells]: each to every cell it runs on into, the casing the first
## time over and the paper inside it the second.
func _draw_run(cells: Array[Vector2i], pencil: bool, solid: bool, pass_at: int) -> void:
	# Faint in a lighter ink rather than see-through, so where two stretches meet is no darker.
	var ink := HouseTheme.INK if solid else HouseTheme.PAPER.lerp(HouseTheme.INK, FAINT)
	var width := ROAD * zoom
	if pencil:
		ink = HouseTheme.PAPER.lerp(LoyaltyArt.PENCIL, 0.85 if solid else FAINT * 1.6)
		width = PENCIL_LINE * zoom
	elif pass_at == 1:
		if not solid:
			return
		ink = HouseTheme.PAPER
		width = ROAD_INSIDE * zoom
	elif not solid:
		width = FAINT_LINE * zoom
	var bounds := Rect2i(Vector2i.ZERO, _map.size())
	for here: Vector2i in cells:
		var from := _to_view(_middle(here))
		for step: Vector2i in _ways(_map.cell(here)):
			var there := here + step
			var to := _to_view(_middle(there))
			var bend := _map.cell(here) == LoyaltyMap.BEND
			if not bounds.has_point(there):
				# A road runs on off the edge; a bend only turns where there is road to turn into.
				if bend:
					continue
				to = _to_edge(from, Vector2(step))
			elif bend and _is_road(_map.cell(there)) and step not in _ways(_map.cell(there)):
				continue
			elif _map.cell(there) == LoyaltyMap.ROUNDABOUT:
				var middle := _to_view(_ring_middle)
				to = middle + (from - middle).normalized() * _ring * zoom
			elif _map.cell(there) == " ":
				continue
			# Each stretch once over, from the cell further on or up, but those that run into a
			# landmark or off the map, which only this end draws.
			var ahead := there.y > here.y or (there.y == here.y and there.x > here.x)
			if not ahead and _is_road(_map.cell(there)):
				continue
			# A bar rather than a line: the roads run only across and down, and bars of one ink
			# laid end on end meet with no seam, square at a bend.
			var low := from.min(to) - Vector2.ONE * width * 0.5
			draw_rect(Rect2(low, (from - to).abs() + Vector2.ONE * width), ink)


## Where a road from [param from] in the view, running [param way] off the grid, meets the
## paper's edge.
func _to_edge(from: Vector2, way: Vector2) -> Vector2:
	var sheet := Rect2(offset, _paper * zoom)
	var to := from
	if way.x != 0.0:
		to.x = sheet.end.x if way.x > 0.0 else sheet.position.x
	if way.y != 0.0:
		to.y = sheet.end.y if way.y > 0.0 else sheet.position.y
	return to


## The roundabout round the pot in the middle of the map: its ring a road like the others, faint
## until it opens, and the pot marked JACKPOT.
func _draw_roundabout() -> void:
	if _ring <= 0.0:
		return
	var middle := _to_view(_ring_middle)
	var radius := _ring * zoom
	var open := true
	for each: LoyaltyLandmark in _map.landmarks:
		if each.keystone and _map.reaches_roundabout(each.id):
			open = open and profile.loyalty.has_won(each.id)
	if open:
		draw_arc(middle, radius, 0.0, TAU, 64, HouseTheme.INK, ROAD * zoom, true)
		draw_arc(middle, radius, 0.0, TAU, 64, HouseTheme.PAPER, ROAD_INSIDE * zoom, true)
	else:
		draw_arc(
			middle, radius, 0.0, TAU, 64, Color(HouseTheme.INK, FAINT), ROAD_INSIDE * zoom, true
		)
	draw_circle(middle, radius * 0.62, HouseTheme.FOIL_LOW)
	draw_circle(middle, radius * 0.55, HouseTheme.FOIL)
	draw_arc(middle, radius * 0.47, 0.0, TAU, 48, Color(HouseTheme.ON_FOIL, 0.5), 1.2 * zoom, true)
	var font := Type.display_font()
	var size_of := maxi(roundi(radius * 0.3), 1)
	var base := middle + Vector2(-radius, font.get_ascent(size_of) * 0.38)
	draw_string(
		font, base, POT, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, size_of, HouseTheme.ON_FOIL
	)


## [param landmark]'s sign as it stands, its bet under it on a label of the paper while it is
## open, with the bar of how far it has come, and the NEW tag while it is won and not looked at.
func _draw_landmark(landmark: LoyaltyLandmark) -> void:
	var rect := sign_rect(landmark.id)
	if not rect.grow(SIGN.y * zoom).intersects(Rect2(Vector2.ZERO, size)):
		return
	var stands := Loyalty.standing(profile, landmark)
	if cursor != null and cursor.at == landmark.id:
		var glow := rect.grow(5.0 * zoom)
		draw_rect(glow, Color(HouseTheme.FOIL, 0.35), true)
		draw_rect(glow, HouseTheme.FOIL, false, 2.0 * zoom)
	LoyaltyArt.draw_sign(self, rect, landmark, stands, zoom)
	if stands == Loyalty.Standing.OPEN and landmark.kind != LoyaltyLandmark.Kind.CARD:
		_draw_bet(landmark, rect)
	if profile.loyalty.is_fresh(landmark.id):
		LoyaltyArt.draw_new(self, rect, zoom)


## The bet of [param landmark] on a label of the paper under its sign [param rect], with its bar.
func _draw_bet(landmark: LoyaltyLandmark, rect: Rect2) -> void:
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	var font: Font = LoyaltyArt.HAND if kit else Type.TEXT
	var size_of := maxi(roundi(BET_SIZE * zoom * (LoyaltyArt.HAND_SCALE if kit else 1.0)), 1)
	var wide := rect.size.x + 10.0 * zoom
	var lines := LoyaltyArt.lines_of(font, Loyalty.bet_of(landmark), size_of, wide, BET_LINES)
	var tall := font.get_height(size_of) * (0.82 if kit else 0.95)
	var bar := Loyalty.progress(profile, landmark)
	var said := Loyalty.progress_text(profile, landmark)
	var under := tall * lines.size() + (BAR * zoom + tall + 4.0 * zoom if bar.y > 0.0 else 0.0)
	var label := Rect2(
		Vector2(rect.position.x - 5.0 * zoom, rect.end.y + 4.0 * zoom),
		Vector2(wide, under + 6.0 * zoom)
	)
	var ink := LoyaltyArt.PENCIL if kit else HouseTheme.INK
	draw_rect(label, HouseTheme.PAPER)
	for i: int in lines.size():
		var base := (
			label.position + Vector2(0.0, 3.0 * zoom + tall * i + font.get_ascent(size_of) * 0.92)
		)
		draw_string(font, base, lines[i], HORIZONTAL_ALIGNMENT_CENTER, wide, size_of, ink)
	if bar.y <= 0.0:
		return
	var top := label.position.y + 3.0 * zoom + tall * lines.size() + 2.0 * zoom
	var track := Rect2(
		Vector2(rect.position.x + 8.0 * zoom, top), Vector2(rect.size.x - 16.0 * zoom, BAR * zoom)
	)
	draw_rect(track, Color(ink, 0.18))
	draw_rect(Rect2(track.position, Vector2(track.size.x * bar.x / bar.y, track.size.y)), ink)
	var small := maxi(roundi(BET_SIZE * 0.92 * zoom), 1)
	var base := Vector2(label.position.x, track.end.y + Type.STRONG.get_ascent(small) + 2.0 * zoom)
	draw_string(Type.STRONG, base, said, HORIZONTAL_ALIGNMENT_CENTER, wide, small, Color(ink, 0.8))


## The cursor's kart where it is, over everything on the map.
func _draw_cursor() -> void:
	if cursor == null or cursor.texture() == null:
		return
	var side := KART * zoom
	var at := _to_view(cursor.point)
	draw_texture_rect(
		cursor.texture(), Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side), false
	)


static func _ways(what: String) -> Array:
	match what:
		LoyaltyMap.INK_ACROSS, LoyaltyMap.PENCIL_ACROSS:
			return [Vector2i.LEFT, Vector2i.RIGHT]
		LoyaltyMap.INK_DOWN, LoyaltyMap.PENCIL_DOWN:
			return [Vector2i.UP, Vector2i.DOWN]
		LoyaltyMap.BEND:
			return [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	return []


static func _is_road(what: String) -> bool:
	return not _ways(what).is_empty()
