class_name LoyaltyMapView
extends Control
## The loyalty program's map, GAME.md 8.9: a road map the house printed on its cream paper, with
## the creases of a map that has been folded, larger than the room it is shown in. It scrolls to
## keep the cursor in view, a wheel or a pinch zooms it between the whole map and close enough to
## read every sign, and a mouse or a finger drags it; a click or a tap on a landmark sends the
## cursor there.
##
## Where everything goes is [LoyaltyMapLayout]'s, worked out once as it opens; the paper, the
## washes, the roads and the little drawings are [LoyaltyMapArt]'s, drawn under the zoom's own
## transform so the lines are sharp at every zoom; the signs are [LoyaltyArt]'s, and every word on
## the map is printed at the zoom's own size rather than scaled, so the type is sharp too. All of
## that is drawn once into a picture of the whole sheet, see [LoyaltyMapBake], and only what moves
## or changes is drawn over it each time: the kart, the landmark it is at, the NEW tags and pins.

## A click or a tap on the landmark [param id].
signal picked(id: StringName)
## The cursor has come to the landmark [param id].
signal arrived(id: StringName)
## The landmark [param id] has been chosen, the cursor sent to it: said at once, whether or not the
## cursor is there yet.
signal chosen(id: StringName)
## The view has turned to the sheet [param to], see [method set_sheet].
signal sheet_changed(to: LoyaltyMapLayout.Sheet)

## The label of a sign's bet under it, at a zoom of one.
const BET_SIZE := 11.0
const BET_LINES := 3
const BAR := 4.0
## The districts' names, printed over them, and Kit's over the pencil.
const STRIP := "THE STRIP"
const DEPARTMENT := "DEPARTMENT OF KARTS"
const OFF_THE_BOOKS := "off the books"
const DISTRICT_SIZE := 24.0
const DISTRICT_SPACING := 4
const POT := "JACKPOT"
## The legend's words, and the title block's.
const LEGEND := "LEGEND"
const LEGEND_LINES: Array[String] = [
	"The House's road", "Not open yet", "The Strip", "Dept. of Karts", "Won"
]
## What Kit pencils in under the House's legend, once Kit's roads are on the map, and how far
## askew.
const KIT_LEGEND := "my roads"
const KIT_LEGEND_TURN := -0.06
const IMPRINT := "ROAD MAP  ·  NOT TO SCALE"
const PRINTED := "Printed by the House for its members"
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
## The cursor drawn, at a zoom of one, and how far from a sign's edge it stands on the road in.
const KART := 96.0
## How far short of the sheet's edge a road off Kit's sheet ends in its arrow, and what is written
## beside it.
const WAY_OFF_SHORT := 34.0
const WAY_OFF := "to %s"
const KIT_MAP := "Kit's map"
const KART_CLEAR := 18.0
## A little drawing's own box, which its size is a share of.
const DOODLE_BOX := 30.0

static var _spaced: FontVariation

## The profile whose map it is, and the cursor driving it.
var profile: Profile
var cursor: LoyaltyCursor
## How far it is zoomed, and where the paper's top left corner is drawn.
var zoom := ZOOM_START
var offset := Vector2.ZERO
## The program's name, printed in the title block.
var program := ""
## Whether this is the sheet drawn whole into the picture the view shows, see [LoyaltyMapBake],
## rather than the view: nothing that moves, nothing to press.
var baking := false
## Where everything on the map goes, worked out as it opens, and which sheet of it is shown: the
## House's, or Kit's, see [LoyaltyMapLayout].
var layout: LoyaltyMapLayout
var sheet := LoyaltyMapLayout.Sheet.HOUSE

var _map: LoyaltyMap
## The landmarks of the drive the kart is on, or was on last.
var _driven: Array[StringName] = []
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
var _laid := false
## Whether the player has dragged or zoomed the map since it was put up.
var _moved := false
## The sheet drawn once into a picture, which is what is shown.
var _bake: LoyaltyMapBake


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_map = Loyalty.map()
	if layout == null:
		layout = LoyaltyMapLayout.of(_map, profile, sheet)
	if baking:
		set_process(false)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
		clip_contents = false
		return
	# Over the map, the roundabout calling while an edition is owed.
	add_child(LoyaltyBeacon.new(self))
	_bake = LoyaltyMapBake.new(self)
	add_child(_bake)
	resized.connect(_on_resized)
	if cursor != null:
		cursor.moved.connect(_on_cursor_moved)
		cursor.arrived.connect(_on_cursor_arrived)


## Turns to the sheet [param to] of the map, see [LoyaltyMapLayout.Sheet]: laid out afresh, the
## cursor standing on it again where it is on it, the map round it, or round the sheet's middle.
func set_sheet(to: LoyaltyMapLayout.Sheet) -> void:
	if to == sheet:
		return
	sheet = to
	layout = LoyaltyMapLayout.of(_map, profile, sheet)
	zoom = clampf(zoom, minf(fit_zoom(), ZOOM_MOST), ZOOM_MOST)
	if _bake != null:
		_bake.refresh()
	if cursor != null and is_on_sheet(cursor.at):
		stand_at(cursor.at)
	else:
		show_point(layout.paper * 0.5, false)
	sheet_changed.emit(sheet)
	queue_redraw()


## Whether the landmark [param id] is on the sheet shown.
func is_on_sheet(id: StringName) -> bool:
	return LoyaltyMapLayout.sheet_of_id(id) == sheet


## Stands the cursor at the landmark [param id], on the first road into it, before its sign; the
## map round it, turned to its sheet.
func stand_at(id: StringName) -> void:
	if cursor == null:
		return
	if not is_on_sheet(id):
		set_sheet(LoyaltyMapLayout.sheet_of_id(id))
	var into := PackedVector2Array()
	for other: StringName in _roads_from(id):
		into = layout.road(other, id)
		if into.size() >= 2:
			break
	if into.size() < 2:
		var at: Vector2 = layout.points.get(id, Vector2.ZERO)
		into = PackedVector2Array([at - Vector2(1.0, 0.0), at])
	var stop := _stop_on(into, id)
	cursor.place(id, stop[-1], (stop[-1] - stop[-2]).normalized())
	show_point(cursor.point, false)


## Sends the cursor along the road from where it stands in [param way] on the map, to the next
## landmark that way. False where no road it can drive goes that way.
func drive_toward(way: Vector2i) -> bool:
	if cursor == null:
		return false
	for id: StringName in _roads_from(cursor.at):
		if _way_to(cursor.at, id) == way:
			if not is_on_sheet(id):
				_over_the_edge(id)
			elif cursor.is_driving():
				_drive_from_here(id)
			else:
				_drive([cursor.at, id])
			return true
	return false


## The cursor to [param id] on the other sheet: turned to it, the cursor standing at it.
func _over_the_edge(id: StringName) -> void:
	stand_at(id)
	chosen.emit(id)
	arrived.emit(id)


## The way the road from [param from] to [param to] leaves [param from] on the grid: its first
## step, or for the roundabout's roads straight across to it or away.
func _way_to(from: StringName, to: StringName) -> Vector2i:
	if from == Loyalty.ROUNDABOUT or to == Loyalty.ROUNDABOUT:
		var there: Vector2 = layout.ring_middle if to == Loyalty.ROUNDABOUT else layout.points[to]
		var here: Vector2 = (
			layout.ring_middle if from == Loyalty.ROUNDABOUT else layout.points[from]
		)
		return Vector2i(int(signf(there.x - here.x)), 0)
	var cells := _map.path(from, to)
	return cells[1] - cells[0] if cells.size() >= 2 else Vector2i.ZERO


## Sends the cursor to the landmark [param id], along the roads it can drive, the fewest of them.
## False for one it cannot reach.
func drive_to(id: StringName) -> bool:
	if cursor == null:
		return false
	if id == cursor.at:
		chosen.emit(id)
		if not cursor.is_driving():
			arrived.emit(id)
		return true
	if not is_on_sheet(id) or not is_on_sheet(cursor.at):
		_over_the_edge(id)
		return true
	if cursor.is_driving() and _driven.size() >= 2:
		return _drive_from_here(id)
	var route := _route(cursor.at, id)
	if route.is_empty():
		return false
	_drive(route)
	return true


## Every landmark drawn on the profile's map.
func drawn() -> Array[LoyaltyLandmark]:
	return layout.drawn()


## The House's landmark one of Kit's roads off the foot of his sheet leads to, where its arrow and
## its name are under [param at] in the view; none elsewhere.
func way_off_at(at: Vector2) -> StringName:
	for road: Dictionary in layout.roads:
		var to: StringName = road.get("off_to", &"")
		if to == &"":
			continue
		var line: PackedVector2Array = road["points"]
		var tip := _to_view(_way_off_tip(line))
		if Rect2(tip - Vector2(30.0, 40.0) * zoom, Vector2(260.0, 80.0) * zoom).has_point(at):
			return to
	return &""


## Where the arrow at the end of a road off the foot of Kit's sheet, [param line], points to: a
## little short of the sheet's edge.
static func _way_off_tip(line: PackedVector2Array) -> Vector2:
	var way := (line[-1] - line[-2]).normalized() if line.size() >= 2 else Vector2.DOWN
	return line[-1] - way * WAY_OFF_SHORT


## The landmark whose sign is under [param at] in the view, or null.
func landmark_at(at: Vector2) -> LoyaltyLandmark:
	for each: LoyaltyLandmark in drawn():
		if sign_rect(each.id).grow(4.0 * zoom).has_point(at):
			return each
	return null


## Where the sign of [param id] is in the view.
func sign_rect(id: StringName) -> Rect2:
	var rect := layout.sign_rect(id)
	return Rect2(_to_view(rect.position), rect.size * zoom)


## The zoom at which the whole map fits the room.
func fit_zoom() -> float:
	if layout == null or layout.paper.x <= 0.0 or size.x <= 0.0:
		return ZOOM_START
	return minf(size.x / layout.paper.x, size.y / layout.paper.y)


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
			var off := way_off_at(button.position) if clicked else &""
			if landmark != null:
				picked.emit(landmark.id)
			elif off != &"":
				picked.emit(off)
			elif (
				clicked
				and sheet == LoyaltyMapLayout.Sheet.HOUSE
				and sign_rect(Loyalty.ROUNDABOUT).has_point(button.position)
			):
				picked.emit(Loyalty.ROUNDABOUT)


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
	_moved = true
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
	zoom = clampf(zoom, minf(fit_zoom(), ZOOM_MOST), ZOOM_MOST)
	# Laid out again round the cursor, as the room settles, until the player moves the map.
	if cursor != null and not _moved:
		show_point(cursor.point, false)
	offset = _clamped(offset)
	queue_redraw()


func _on_cursor_moved() -> void:
	queue_redraw()


func _on_cursor_arrived(id: StringName) -> void:
	queue_redraw()
	arrived.emit(id)


## Sends the cursor along the roads of [param route], a landmark after another, from where it
## stands: off the first sign onto its road, along each road in turn, and to a stop before the
## last sign on the road it comes in by.
func _drive(route: Array[StringName]) -> void:
	var points := _route_points(route)
	if points.size() < 2:
		return
	var leaving := layout.sign_rect(route[0]).grow(KART_CLEAR)
	while points.size() > 2 and leaving.has_point(points[1]):
		points.remove_at(0)
	points.remove_at(0)
	var to := route[-1]
	_driven = route
	cursor.drive(_stop_on(points, to), to)
	_chosen_shown(to)


## The roads of [param route], one after another, from its first landmark to its last.
func _route_points(route: Array[StringName]) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in range(1, route.size()):
		var leg := layout.road(route[i - 1], route[i])
		points.append_array(leg.slice(0 if points.is_empty() else 1))
	return points


## [param to] chosen while the kart is on its way somewhere: from where it is on the road it is on,
## on to that road's far end or back to its near one, whichever is the shorter way there. False
## where there is no way.
func _drive_from_here(to: StringName) -> bool:
	var on := _road_under_kart()
	if on.is_empty():
		return false
	var line: PackedVector2Array = on["line"]
	var cut: int = on["cut"]
	var best: Dictionary = {}
	for end: int in 2:
		var via: StringName = on["ends"][end]
		var route := _route(via, to)
		if route.is_empty():
			continue
		# Along the road to that end from the kart, then the roads from there.
		var part := PackedVector2Array()
		if end == 1:
			part = line.slice(cut + 1)
		else:
			part = line.slice(0, cut + 1)
			part.reverse()
		var whole := _length([cursor.point] + Array(part)) + _length(Array(_route_points(route)))
		if best.is_empty() or whole < float(best["whole"]):
			best = {"whole": whole, "part": part, "route": route}
	if best.is_empty():
		return false
	var points: PackedVector2Array = best["part"]
	var rest := _route_points(best["route"])
	points.append_array(rest.slice(1) if rest.size() > 1 else PackedVector2Array())
	if points.is_empty():
		return false
	_driven = best["route"]
	cursor.drive(_stop_on(points, to), to)
	_chosen_shown(to)
	return true


## The road of the drive under way that the kart is on now: its two landmarks, its points from the
## first to the second, and the stretch of them the kart is on, the one it is nearest.
func _road_under_kart() -> Dictionary:
	var best: Dictionary = {}
	var nearest := INF
	for i: int in range(1, _driven.size()):
		var line := layout.road(_driven[i - 1], _driven[i])
		for k: int in range(1, line.size()):
			var on := Geometry2D.get_closest_point_to_segment(cursor.point, line[k - 1], line[k])
			var away := on.distance_to(cursor.point)
			if away < nearest:
				nearest = away
				best = {"ends": [_driven[i - 1], _driven[i]], "line": line, "cut": k - 1}
	return best


static func _length(points: Array) -> float:
	var whole := 0.0
	for i: int in range(1, points.size()):
		whole += (points[i - 1] as Vector2).distance_to(points[i])
	return whole


## [param to] chosen and the kart sent there: said, and brought into view if it is not.
func _chosen_shown(to: StringName) -> void:
	chosen.emit(to)
	# The map comes round to what was chosen only when it is not in view already: never after the
	# kart, which drives there on its own.
	var keep := size * KEEP
	if not Rect2(keep, size - keep * 2.0).encloses(sign_rect(to)):
		show_point(layout.points.get(to, cursor.point), true)


## [param points] of a road into [param id], cut short where it comes to its sign, so the cursor
## stops before it on that road.
func _stop_on(points: PackedVector2Array, id: StringName) -> PackedVector2Array:
	var sign := layout.sign_rect(id).grow(KART_CLEAR)
	var kept := points.duplicate()
	while kept.size() > 2 and sign.has_point(kept[-2]):
		kept.remove_at(kept.size() - 1)
	if kept.size() >= 2 and sign.has_point(kept[-1]):
		# The last stretch runs into the sign: stop where it meets its edge.
		var from := kept[-2]
		var to := kept[-1]
		var reach := 0.0
		for step: int in 20:
			if sign.has_point(from.lerp(to, (step + 1) / 20.0)):
				break
			reach = (step + 1) / 20.0
		kept[-1] = from.lerp(to, reach)
	if kept[-1].distance_to(kept[-2]) < 0.5 and kept.size() > 2:
		kept.remove_at(kept.size() - 1)
	return kept


## The landmarks [param id] has a road to that the profile's map draws, the roundabout among them
## for a keystone on a road into it, and its keystones for the roundabout.
func _roads_from(id: StringName) -> Array[StringName]:
	var roads: Array[StringName] = []
	if id == Loyalty.ROUNDABOUT:
		for each: LoyaltyLandmark in drawn():
			if _map.reaches_roundabout(each.id):
				roads.append(each.id)
		return roads
	for other: StringName in _map.roads_of(id):
		var landmark := _map.landmark(other)
		if landmark != null and Loyalty.is_drawn(profile, landmark):
			roads.append(other)
	if _map.reaches_roundabout(id):
		roads.append(Loyalty.ROUNDABOUT)
	return roads


## The landmarks from [param from] to [param to] along the fewest drawn roads, both ends in it;
## none where no road goes.
func _route(from: StringName, to: StringName) -> Array[StringName]:
	var came := {from: from}
	var next: Array[StringName] = [from]
	while not next.is_empty() and not came.has(to):
		var here: StringName = next.pop_front()
		for other: StringName in _roads_from(here):
			# The roads of the sheet shown alone: the other is over its edge.
			if not came.has(other) and is_on_sheet(other):
				came[other] = here
				next.append(other)
	var route: Array[StringName] = []
	if not came.has(to):
		return route
	route.append(to)
	while route[0] != from:
		route.push_front(came[route[0]])
	return route


## [param at], a point on the paper at a zoom of one, where it is in the view.
func _to_view(at: Vector2) -> Vector2:
	return offset + at * zoom


## [param wanted] for the paper's corner, kept so the paper fills the room, or is in the middle of
## it where it is smaller.
func _clamped(wanted: Vector2) -> Vector2:
	var shown := layout.paper * zoom
	var kept := wanted
	for axis: int in 2:
		if shown[axis] <= size[axis]:
			kept[axis] = (size[axis] - shown[axis]) * 0.5
		else:
			kept[axis] = clampf(wanted[axis], size[axis] - shown[axis], 0.0)
	return kept


## [param text] printed at [param at] on the paper, in [param font] at [param size] at a zoom of
## one, made at the zoom's own size so it is sharp.
func _say(
	at: Vector2,
	text: String,
	font: Font,
	size_of: float,
	ink: Color,
	align := HORIZONTAL_ALIGNMENT_LEFT,
	wide := -1.0
) -> void:
	var px := maxi(roundi(size_of * zoom), 1)
	draw_string(font, _to_view(at), text, align, wide * zoom if wide > 0.0 else -1.0, px, ink)


func _draw() -> void:
	if layout == null:
		return
	if baking or not _bake.draw_on():
		_draw_sheet()
	if not baking:
		_draw_moving()


## The sheet, everything on it that stands still: drawn into the picture the view shows, or by
## the view until that is drawn.
func _draw_sheet() -> void:
	var base := Transform2D(0.0, Vector2.ONE * zoom, 0.0, offset)
	var shown := Rect2(-offset / zoom, size / zoom).grow(40.0)
	draw_set_transform_matrix(base)
	var house := sheet == LoyaltyMapLayout.Sheet.HOUSE
	if house:
		LoyaltyMapArt.paper(self, layout.paper)
	else:
		LoyaltyMapArt.graph_paper(self, layout.paper)
	for district: int in layout.washes:
		LoyaltyMapArt.wash(self, layout.washes[district], district)
	for street: PackedVector2Array in layout.streets:
		LoyaltyMapArt.street(self, street)
	for doodle: Dictionary in layout.doodles:
		var at: Vector2 = doodle["at"]
		if not shown.has_point(at):
			continue
		var scale_of: float = doodle["size"] / DOODLE_BOX
		draw_set_transform_matrix(
			base * Transform2D(doodle["turn"], Vector2.ONE * scale_of, 0.0, at)
		)
		LoyaltyMapArt.doodle(self, doodle["kind"])
	draw_set_transform_matrix(base)
	_draw_roads()
	if house:
		LoyaltyMapArt.roundabout(self, layout.ring_middle, layout.ring, _ring_open())
		LoyaltyMapArt.compass(self, layout.compass, LoyaltyMapLayout.COMPASS)
		LoyaltyMapArt.box(self, layout.legend)
		LoyaltyMapArt.box(self, layout.cartouche)
		_draw_legend_samples(base)
		if Loyalty.ring_open(profile):
			LoyaltyMapArt.ring_bets(self, layout.ring_middle, layout.ring, profile)
	_draw_ways_off()
	draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_words()
	for each: LoyaltyLandmark in drawn():
		_draw_landmark(each)


## What moves or changes over the sheet, drawn every time: the landmark the cursor is at lit and
## drawn again over it, every NEW tag and pin in view, the roundabout's pin and ring, and the kart.
func _draw_moving() -> void:
	var room := Rect2(Vector2.ZERO, size)
	for each: LoyaltyLandmark in drawn():
		var rect := sign_rect(each.id)
		if not rect.grow(LoyaltyMapLayout.SIGN_TALL * zoom * 2.0).intersects(room):
			continue
		if cursor != null and cursor.at == each.id:
			var glow := rect.grow(5.0 * zoom)
			draw_rect(glow, Color(HouseTheme.FOIL, 0.35), true)
			draw_rect(glow, HouseTheme.FOIL, false, 2.0 * zoom)
			_draw_landmark(each)
		if profile.loyalty.is_fresh(each.id):
			LoyaltyArt.draw_new(self, rect, zoom)
		if profile.loyalty.pinned == each.id:
			LoyaltyArt.draw_pin(self, rect.position + Vector2(6.0, 4.0) * zoom, 26.0 * zoom)
	var house := sheet == LoyaltyMapLayout.Sheet.HOUSE
	if house and Loyalty.pinned_of(profile) == Loyalty.ROUNDABOUT:
		var ring := sign_rect(Loyalty.ROUNDABOUT)
		LoyaltyArt.draw_pin(self, ring.position + ring.size * Vector2(0.2, 0.2), 30.0 * zoom)
	if cursor != null and cursor.at == Loyalty.ROUNDABOUT and house:
		var rect := sign_rect(Loyalty.ROUNDABOUT)
		draw_arc(
			rect.get_center(),
			rect.size.x * 0.5 + 6.0 * zoom,
			0.0,
			TAU,
			64,
			HouseTheme.FOIL,
			3.0 * zoom,
			true
		)
	_draw_cursor()


## Every road drawn: the casings, dashes and pencil first, then the gold inside the house's open
## roads, so where two meet the gold runs on through.
func _draw_roads() -> void:
	# The House's roads in passes, casings, lanes and middle lines, each over all of the one before,
	# so where roads meet they run on through each other.
	var house: Array[Array] = []
	for road: Dictionary in layout.roads:
		var open := false
		for id: StringName in road["ends"]:
			open = open or profile.loyalty.has_won(id)
		var points: PackedVector2Array = road["points"]
		LoyaltyMapArt.road(self, points, road["pencil"], open)
		if not road["pencil"]:
			house.append([points, open])
	for each: Array in house:
		LoyaltyMapArt.road_inside(self, each[0], each[1])
	for each: Array in house:
		LoyaltyMapArt.road_middle(self, each[0], each[1])


## The arrows at the ends of Kit's roads off the foot of his sheet, in pencil, the way they go.
func _draw_ways_off() -> void:
	for road: Dictionary in layout.roads:
		if road.get("off_to", &"") == &"":
			continue
		var line: PackedVector2Array = road["points"]
		var tip := _way_off_tip(line)
		var way := (line[-1] - line[-2]).normalized() if line.size() >= 2 else Vector2.DOWN
		for side: float in [-1.0, 1.0]:
			var back := tip - way.rotated(side * 0.5) * 16.0
			draw_line(tip, back, Color(LoyaltyArt.PENCIL, 0.85), 1.8, true)


## Where each of Kit's roads off a sheet goes, in his hand beside its arrow: off his, to the House's
## landmark it leads to; off the House's, to his map.
func _say_ways_off() -> void:
	for road: Dictionary in layout.roads:
		var to: StringName = road.get("off_to", &"")
		if to == &"":
			continue
		var line: PackedVector2Array = road["points"]
		var there := _map.landmark(to)
		var named := there.title if there != null else String(to)
		var up := line.size() >= 2 and line[-1].y < line[-2].y
		if up:
			named = KIT_MAP
		var at := _way_off_tip(line) + Vector2(18.0, 20.0 if up else -6.0)
		_say(at, WAY_OFF % named, LoyaltyArt.HAND, 13.0 * LoyaltyArt.HAND_SCALE, LoyaltyArt.PENCIL)


## Whether the roundabout is open: every keystone of the house's on a road into it won.
func _ring_open() -> bool:
	for each: LoyaltyLandmark in _map.landmarks:
		if each.keystone and _map.reaches_roundabout(each.id):
			if not profile.loyalty.has_won(each.id):
				return false
	return true


## The legend's samples, at its left: a road, one not open yet, the Strip's board, the Department's
## sign, and a stamp, a line each; and once Kit's roads show, Kit's pencil road under them, drawn in
## by hand a little askew, [param base] the map's transform.
func _draw_legend_samples(base: Transform2D) -> void:
	var box := layout.legend
	for i: int in LEGEND_LINES.size():
		var y := box.position.y + 40.0 + i * 19.0
		var from := Vector2(box.position.x + 16.0, y)
		var to := from + Vector2(42.0, 0.0)
		match i:
			0:
				LoyaltyMapArt.house_road(self, PackedVector2Array([from, to]), true)
			1:
				LoyaltyMapArt.house_road(self, PackedVector2Array([from, to]), false)
			2:
				draw_rect(Rect2(from - Vector2(0, 7), Vector2(42, 14)), LoyaltyArt.MARQUEE)
				draw_rect(Rect2(from - Vector2(0, 7), Vector2(42, 14)), HouseTheme.FOIL, false, 1.4)
			3:
				draw_rect(Rect2(from - Vector2(0, 7), Vector2(42, 14)), LoyaltyArt.SIGN_BLUE)
				draw_rect(Rect2(from - Vector2(-2, 5), Vector2(38, 10)), Color.WHITE, false, 0.8)
			4:
				draw_arc(from + Vector2(21, 0), 8.0, 0.0, TAU, 24, HouseTheme.STAMP_RED, 1.8, true)
	if not kit_legend_shown():
		return
	var at := _kit_legend_at()
	draw_set_transform_matrix(base * Transform2D(KIT_LEGEND_TURN, at))
	var drawn_in := PackedVector2Array(
		[Vector2(-2.0, 1.0), Vector2(20.0, -1.5), Vector2(44.0, 1.0)]
	)
	LoyaltyMapArt.road(self, drawn_in, true, true)
	draw_set_transform_matrix(base)


## Whether Kit's pencil is in the legend: once Kit's roads are on the map.
func kit_legend_shown() -> bool:
	return Loyalty.district_open(profile, LoyaltyLandmark.District.OFF_THE_BOOKS)


## Where Kit's line in the legend starts, on the map: under the House's last.
func _kit_legend_at() -> Vector2:
	var box := layout.legend
	return Vector2(box.position.x + 16.0, box.position.y + 44.0 + LEGEND_LINES.size() * 19.0)


## The map's words: each district's name over it, the pot's, the compass's north, the legend's and
## the title block's.
func _draw_words() -> void:
	var names := {
		LoyaltyLandmark.District.STRIP: [STRIP, HouseTheme.FOIL_LOW],
		LoyaltyLandmark.District.DEPARTMENT: [DEPARTMENT, LoyaltyArt.SIGN_BLUE],
		LoyaltyLandmark.District.OFF_THE_BOOKS: [OFF_THE_BOOKS, LoyaltyArt.PENCIL],
	}
	for district: int in layout.names_at:
		var named: Array = names.get(district, ["", Color.WHITE])
		var kit := district == LoyaltyLandmark.District.OFF_THE_BOOKS
		var font: Font = LoyaltyArt.HAND if kit else _spaced_font()
		var size_of := DISTRICT_SIZE * (LoyaltyArt.HAND_SCALE if kit else 1.0)
		_say(layout.names_at[district], named[0], font, size_of, named[1])
	_say_ways_off()
	if sheet != LoyaltyMapLayout.Sheet.HOUSE:
		return
	var display := Type.display_font()
	var pot := layout.ring * 0.52 * 0.3
	var pot_at := layout.ring_middle + Vector2(-layout.ring, pot * 0.36)
	# As pale as the paper over the pot while the roundabout is shut.
	var pot_ink := HouseTheme.ON_FOIL
	if not _ring_open():
		pot_ink.a = 1.0 - LoyaltyArt.PALE
	_say(pot_at, POT, display, pot, pot_ink, HORIZONTAL_ALIGNMENT_CENTER, layout.ring * 2.0)
	if profile.loyalty.laps > 0:
		var lap := LoyaltyCard.LAP % profile.loyalty.laps
		_say(
			pot_at + Vector2(0.0, pot * 0.95),
			lap,
			Type.STRONG,
			pot * 0.55,
			HouseTheme.ON_FOIL,
			HORIZONTAL_ALIGNMENT_CENTER,
			layout.ring * 2.0
		)
	var north := layout.compass + Vector2(-20.0, -LoyaltyMapLayout.COMPASS - 6.0)
	_say(north, "N", display, 16.0, HouseTheme.STAMP_RED, HORIZONTAL_ALIGNMENT_CENTER, 40.0)
	var box := layout.legend
	_say(box.position + Vector2(16.0, 24.0), LEGEND, display, 15.0, HouseTheme.INK)
	for i: int in LEGEND_LINES.size():
		var at := box.position + Vector2(70.0, 44.0 + i * 19.0)
		_say(at, LEGEND_LINES[i], Type.STRONG, 12.0, HouseTheme.INK)
	if kit_legend_shown():
		var written := _to_view(_kit_legend_at() + Vector2(54.0, 5.0))
		draw_set_transform(written, KIT_LEGEND_TURN, Vector2.ONE)
		var px := maxi(roundi(12.0 * LoyaltyArt.HAND_SCALE * zoom), 1)
		draw_string(
			LoyaltyArt.HAND,
			Vector2.ZERO,
			KIT_LEGEND,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			px,
			LoyaltyArt.PENCIL
		)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	var title := layout.cartouche
	var wide := title.size.x - 24.0
	_say(
		title.position + Vector2(12.0, 40.0),
		program.to_upper(),
		display,
		26.0,
		HouseTheme.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide
	)
	_say(
		title.position + Vector2(12.0, 66.0),
		IMPRINT,
		Type.STRONG,
		12.0,
		HouseTheme.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide
	)
	_say(
		title.position + Vector2(12.0, 92.0),
		PRINTED,
		LoyaltyArt.HAND,
		15.0,
		HouseTheme.INK_FAINT,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide
	)


## The display face spaced out, for the districts' names across their washes, made once.
static func _spaced_font() -> FontVariation:
	if _spaced == null:
		_spaced = FontVariation.new()
		_spaced.base_font = Type.display_font()
		_spaced.spacing_glyph = DISTRICT_SPACING
	return _spaced


## [param landmark]'s sign as it stands, its bet under it on a label of the paper while it is
## open, with the bar of how far it has come, and the NEW tag while it is won and not looked at.
func _draw_landmark(landmark: LoyaltyLandmark) -> void:
	var rect := sign_rect(landmark.id)
	if not rect.grow(LoyaltyMapLayout.SIGN_TALL * zoom * 2.0).intersects(Rect2(Vector2.ZERO, size)):
		return
	var stands := Loyalty.standing(profile, landmark)
	LoyaltyArt.draw_sign(self, rect, landmark, stands, zoom)
	if stands == Loyalty.Standing.OPEN and landmark.kind != LoyaltyLandmark.Kind.CARD:
		_draw_bet(landmark, rect)


## The bet of [param landmark] on a label of the paper under its sign [param rect], with its bar.
func _draw_bet(landmark: LoyaltyLandmark, rect: Rect2) -> void:
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	var font: Font = LoyaltyArt.HAND if kit else Type.TEXT
	var size_of := maxi(roundi(BET_SIZE * zoom * (LoyaltyArt.HAND_SCALE if kit else 1.0)), 1)
	var wide := maxf(rect.size.x + 10.0 * zoom, 140.0 * zoom)
	var lines := LoyaltyArt.lines_of(font, Loyalty.bet_of(landmark), size_of, wide, BET_LINES)
	var tall := font.get_height(size_of) * (0.82 if kit else 0.95)
	var bar := Loyalty.progress(profile, landmark)
	var said := Loyalty.progress_text(profile, landmark)
	var under := tall * lines.size() + (BAR * zoom + tall + 4.0 * zoom if bar.y > 0.0 else 0.0)
	var label := Rect2(
		Vector2(rect.get_center().x - wide * 0.5, rect.end.y + 4.0 * zoom),
		Vector2(wide, under + 6.0 * zoom)
	)
	var ink := LoyaltyArt.PENCIL if kit else HouseTheme.INK
	draw_rect(label, Color(HouseTheme.PAPER, 0.94))
	if not kit:
		draw_rect(label, Color(ink, 0.3), false, 1.0)
	for i: int in lines.size():
		var top := 3.0 * zoom + tall * i + font.get_ascent(size_of) * 0.92
		draw_string(
			font,
			label.position + Vector2(0.0, top),
			lines[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			wide,
			size_of,
			ink
		)
	if bar.y <= 0.0:
		return
	var top := label.position.y + 3.0 * zoom + tall * lines.size() + 2.0 * zoom
	var track := Rect2(
		Vector2(label.position.x + 14.0 * zoom, top), Vector2(wide - 28.0 * zoom, BAR * zoom)
	)
	draw_rect(track, Color(ink, 0.18))
	draw_rect(Rect2(track.position, Vector2(track.size.x * bar.x / bar.y, track.size.y)), ink)
	var small := maxi(roundi(BET_SIZE * 0.92 * zoom), 1)
	var base := Vector2(label.position.x, track.end.y + Type.STRONG.get_ascent(small) + 2.0 * zoom)
	draw_string(Type.STRONG, base, said, HORIZONTAL_ALIGNMENT_CENTER, wide, small, Color(ink, 0.8))


## The cursor's kart where it is, over everything on the map, on the sheet it is on.
func _draw_cursor() -> void:
	if cursor == null or cursor.texture() == null or not is_on_sheet(cursor.at):
		return
	var side := KART * zoom
	var at := _to_view(cursor.point)
	draw_texture_rect(
		cursor.texture(), Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side), false
	)
