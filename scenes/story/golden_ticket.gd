class_name GoldenTicket
extends Control
## The House's golden ticket to the Final Hand, STORY.md 8.1: gold card stock with notched corners,
## fine waves engraved across it the way a banknote has them, the House's seal on the left, THE
## HOUSE REQUESTS YOUR COMPANY over FINAL HAND, the player's name typed on a dotted line, the table
## under it, and on the right, past a perforation, a stub reading ADMIT ONE numbered with the
## player's license. The stub is a child of its own, [member stub], so it can be torn off along the
## perforation, see [method tear]: the edges either side of the tear go ragged, matching, the tear
## running down the perforation from its top, the part torn leaning away from the ticket more the
## further it is from where the tear has got to, as the opening invitation's stub does, STORY.md
## 6.1a. Drawn in code, at [constant SIZE].

const SIZE := Vector2(820.0, 330.0)
## How wide the stub is, how big the notches at the corners and the bites either side of the
## perforation are, and how far in the engraved border runs.
const STUB := 170.0
const NOTCH := 22.0
const BITE := 14.0
const BORDER := 10.0
const GOLD_HIGH := Color(1.0, 0.9, 0.6)
const GOLD_LOW := Color(0.6, 0.43, 0.13)
const INK := Color(0.16, 0.11, 0.05)
const SHADOW := Color(0.0, 0.0, 0.0, 0.4)
## How far the ragged edge of a tear wanders either side of the perforation, and how often it turns.
const RAGGED := 3.5
const RAGGED_STEP := 7.0
## The stub torn off: torn down the perforation from its top, leaning away as it goes, then let go
## and falling, turning as it goes.
const TEAR := 0.7
const TEAR_LEAN := 0.12
const FALL := 0.75
const FALL_TURN := 0.6
## How much sharper the torn stub's picture is drawn than it is shown.
const SHARPEN := 2.0

## Whose name is typed on it, and the number on its stub.
var holder := ""
var serial := ""
## Whether its stub has been torn off, and whether it lies face down: the back of the ticket kept
## once its stub is gone, see [method show_torn], its ragged edge on the left as it is turned over.
var torn := false
var face_down := false
## The stub, past the perforation.
var stub: Control

## The ragged edge of the tear, from top to bottom, along the perforation.
var _tear := PackedVector2Array()
## The stub drawn torn once, into a picture of its own, and its two parts as it tears: the part
## still on, its holes still punched, and the part torn, leaning away; and how far down the
## perforation the tear has got.
var _torn_sheet: SubViewport
var _attached: Node2D
var _torn: Node2D
var _front := 0.0


## A ticket for [param named], numbered from [param license]: the license's digits.
static func make(named: String, license: String) -> GoldenTicket:
	var ticket := GoldenTicket.new()
	ticket.name = "GoldenTicket"
	ticket.holder = named
	ticket.serial = number_of(license)
	return ticket


## The number on the stub of a ticket for [param license]: its digits, six at the least.
static func number_of(license: String) -> String:
	var digits := ""
	for character: String in license:
		if character >= "0" and character <= "9":
			digits += character
	return digits.lpad(6, "0")


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(serial)
	# Wandering either side of the perforation between its two ends, which stay where the bites
	# meet it, so the outlines either side close cleanly.
	var x := SIZE.x - STUB
	_tear.append(Vector2(x, BITE))
	var y := BITE + RAGGED_STEP
	while y < SIZE.y - BITE - RAGGED_STEP * 0.5:
		_tear.append(Vector2(x + rng.randf_range(-RAGGED, RAGGED), y))
		y += RAGGED_STEP * rng.randf_range(0.6, 1.3)
	_tear.append(Vector2(x, SIZE.y - BITE))
	stub = Control.new()
	stub.name = "Stub"
	stub.size = SIZE
	stub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stub.draw.connect(func() -> void: _draw_stub_on(stub, torn))
	add_child(stub)
	# The stub as it will come away, torn, drawn now while nothing is moving.
	var torn_stub := Control.new()
	torn_stub.size = SIZE
	torn_stub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	torn_stub.draw.connect(func() -> void: _draw_stub_on(torn_stub, true))
	_torn_sheet = SubViewport.new()
	_torn_sheet.name = "TornStub"
	_torn_sheet.transparent_bg = true
	_torn_sheet.disable_3d = true
	_torn_sheet.gui_disable_input = true
	_torn_sheet.msaa_2d = Viewport.MSAA_4X
	_torn_sheet.size = Vector2i(_sheet_size() * SHARPEN)
	_torn_sheet.size_2d_override = Vector2i(_sheet_size())
	_torn_sheet.size_2d_override_stretch = true
	_torn_sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	_torn_sheet.add_child(torn_stub)
	add_child(_torn_sheet)
	_attached = Node2D.new()
	_attached.name = "Attached"
	_attached.visible = false
	_attached.draw.connect(_draw_attached)
	add_child(_attached)
	_torn = Node2D.new()
	_torn.name = "Torn"
	_torn.visible = false
	_torn.draw.connect(_draw_torn)
	add_child(_torn)


## Its stub torn off along the perforation: the ticket's edge goes ragged, the tear runs down from
## the top, the part torn leaning away, and the stub, torn all along, falls out of sight;
## [param then] called once it is gone.
func tear(then: Callable = Callable()) -> void:
	if torn:
		return
	torn = true
	queue_redraw()
	stub.visible = false
	Audio.play_sfx(&"tear", -4.0, 0.05)
	_set_tear(0.0)
	var off := create_tween()
	off.tween_method(_set_tear, 0.0, TEAR + FALL, TEAR + FALL)
	off.tween_callback(
		func() -> void:
			_attached.visible = false
			_torn.visible = false
	)
	if then.is_valid():
		off.tween_callback(then)


## How big the torn stub's picture is: the ticket and its shadow.
static func _sheet_size() -> Vector2:
	return SIZE + Vector2(8.0, 12.0)


## The stub [param at] seconds into coming away: torn down the perforation as far as
## [member _front], the part torn leaning away from the ticket more the further it is from there,
## which keeps it whole with the part still on; and once torn all along, let go, turning and
## falling out of sight.
func _set_tear(at: float) -> void:
	var down := smoothstep(0.0, 1.0, clampf(at / TEAR, 0.0, 1.0))
	var was := _front
	_front = lerpf(BITE, SIZE.y - BITE, down)
	var lean := TEAR_LEAN * down
	var leaning := Transform2D(Vector2(1.0, 0.0), Vector2(-lean, 1.0), Vector2(lean * _front, 0.0))
	var fall := clampf((at - TEAR) / FALL, 0.0, 1.0)
	var falling := Transform2D.IDENTITY
	if fall > 0.0:
		var pivot := Vector2(SIZE.x - STUB, SIZE.y - BITE)
		var drop := Vector2(0.0, get_viewport_rect().size.y * 1.6 * fall * fall)
		falling = Transform2D(FALL_TURN * fall * fall, pivot + drop) * Transform2D(0.0, -pivot)
	_torn.transform = falling * leaning
	_torn.visible = true
	_attached.visible = _front < SIZE.y - BITE
	if at == 0.0 or not is_equal_approx(was, _front):
		_attached.queue_redraw()
		_torn.queue_redraw()


## The part of the stub still on, from where the tear has got to down, its holes still punched.
func _draw_attached() -> void:
	var wide := _sheet_size().x
	var from := _front
	_attached.draw_texture_rect_region(
		_torn_sheet.get_texture(),
		Rect2(0.0, from, wide, _sheet_size().y - from),
		Rect2(0.0, from * SHARPEN, wide * SHARPEN, (_sheet_size().y - from) * SHARPEN)
	)
	var y := 26.0
	while y < SIZE.y - 26.0:
		if y > _front + 2.2:
			_attached.draw_circle(Vector2(SIZE.x - STUB, y), 2.2, Color(INK, 0.6))
		y += 10.0


## The part of the stub torn, down to where the tear has got to. Fully torn, the attached part is
## gone, see [method _set_tear], so the torn part takes in the last of the stub and its gold edge
## rather than leaving that strip undrawn as the stub turns and falls.
func _draw_torn() -> void:
	var wide := _sheet_size().x
	var down := _sheet_size().y if _front >= SIZE.y - BITE else _front
	_torn.draw_texture_rect_region(
		_torn_sheet.get_texture(),
		Rect2(0.0, 0.0, wide, down),
		Rect2(0.0, 0.0, wide * SHARPEN, down * SHARPEN)
	)


## The ticket without its stub, the edge where it came off ragged: as it is kept afterwards.
func show_torn() -> void:
	torn = true
	stub.visible = false
	queue_redraw()


func _draw() -> void:
	if face_down:
		_draw_back()
		return
	var body := _body()
	_shadow_of(self, body)
	_gild(self, body)
	var inner := Rect2(
		Vector2.ONE * BORDER, Vector2(SIZE.x - STUB - BORDER - 4.0, SIZE.y - BORDER * 2.0)
	)
	draw_rect(inner, Color(INK, 0.5), false, 1.4, true)
	# Engraved waves across the face, as on a banknote.
	for row: int in 14:
		var wave := PackedVector2Array()
		for i: int in 61:
			var x := 30.0 + (SIZE.x - STUB - 60.0) * float(i) / 60.0
			wave.append(Vector2(x, 40.0 + float(row) * 18.0 + sin(x * 0.05 + float(row)) * 6.0))
		draw_polyline(wave, Color(GOLD_HIGH, 0.25), 1.0, true)
	if not torn:
		var y := 26.0
		while y < SIZE.y - 26.0:
			draw_circle(Vector2(SIZE.x - STUB, y), 2.2, Color(INK, 0.6))
			y += 10.0
	_draw_seal(Vector2(118.0, SIZE.y * 0.5))
	_draw_words()


## The back of the torn ticket: the outline the other way round, the ragged edge on the left; the
## House's seal pressed into the gold, and the small print under it.
func _draw_back() -> void:
	var wide := SIZE.x - STUB
	var shape := PackedVector2Array()
	for point: Vector2 in _body():
		shape.append(Vector2(wide - point.x, point.y))
	shape.reverse()
	_shadow_of(self, shape)
	_gild(self, shape)
	var inner := Rect2(
		Vector2(BORDER + 4.0, BORDER), Vector2(wide - BORDER - 4.0, SIZE.y - BORDER * 2.0)
	)
	draw_rect(inner, Color(INK, 0.5), false, 1.4, true)
	var middle := Vector2(wide * 0.5, SIZE.y * 0.38)
	for ring: float in [52.0, 42.0, 20.0]:
		draw_arc(middle + Vector2(-1.0, -1.0), ring, 0.0, TAU, 64, Color(GOLD_HIGH, 0.6), 2.0, true)
		draw_arc(middle + Vector2(1.0, 1.0), ring, 0.0, TAU, 64, Color(INK, 0.35), 2.0, true)
	var y := SIZE.y * 0.38 + 84.0
	for line: String in StoryLines.TICKET_BACK:
		var line_wide := NotePage.TYPED.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(
			NotePage.TYPED,
			Vector2((wide - line_wide) * 0.5, y),
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color(INK, 0.85)
		)
		y += 20.0


## The stub on [param canvas]: ADMIT ONE turned on its side, and the number under it, its edge
## ragged when [param ragged].
func _draw_stub_on(canvas: Control, ragged: bool) -> void:
	var shape := _stub_shape(ragged)
	_shadow_of(canvas, shape)
	_gild(canvas, shape)
	var x := SIZE.x - STUB
	var inner := Rect2(x + 4.0, BORDER, STUB - BORDER - 4.0, SIZE.y - BORDER * 2.0)
	canvas.draw_rect(inner, Color(INK, 0.5), false, 1.4, true)
	var mark := Type.mark_font()
	var admit := StoryLines.ADMIT_ONE
	canvas.draw_set_transform(Vector2(x + STUB * 0.5 + 10.0, SIZE.y * 0.5), -PI * 0.5, Vector2.ONE)
	var wide := mark.get_string_size(admit, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	canvas.draw_string(
		mark, Vector2(-wide * 0.5, 0.0), admit, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, INK
	)
	var number := StoryLines.TICKET_NUMBER % serial
	var number_wide := NotePage.TYPED.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	canvas.draw_string(
		NotePage.TYPED,
		Vector2(-number_wide * 0.5, 34.0),
		number,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		INK
	)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The ticket's outline but for the stub, clockwise from the top left: the notches at its corners,
## half of each bite, and down the perforation between them, straight or as it tore.
func _body() -> PackedVector2Array:
	var x := SIZE.x - STUB
	var shape := PackedVector2Array()
	_arc(shape, Vector2.ZERO, NOTCH, PI * 0.5, 0.0)
	_arc(shape, Vector2(x, 0.0), BITE, PI, PI * 0.5)
	shape.append_array(_edge())
	_arc(shape, Vector2(x, SIZE.y), BITE, -PI * 0.5, -PI)
	_arc(shape, Vector2(0.0, SIZE.y), NOTCH, 0.0, -PI * 0.5)
	return _cleaned(shape)


## The stub's outline, clockwise from the top of the perforation.
func _stub_shape(ragged := torn) -> PackedVector2Array:
	var x := SIZE.x - STUB
	var shape := PackedVector2Array()
	_arc(shape, Vector2(x, 0.0), BITE, PI * 0.5, 0.0)
	_arc(shape, Vector2(SIZE.x, 0.0), NOTCH, PI, PI * 0.5)
	_arc(shape, SIZE, NOTCH, PI * 1.5, PI)
	_arc(shape, Vector2(x, SIZE.y), BITE, 0.0, -PI * 0.5)
	var up := _edge(ragged)
	up.reverse()
	shape.append_array(up)
	return _cleaned(shape)


## Down the perforation, between the bites: straight, or ragged once torn.
func _edge(ragged := torn) -> PackedVector2Array:
	var x := SIZE.x - STUB
	if ragged and not _tear.is_empty():
		return _tear
	return PackedVector2Array([Vector2(x, BITE), Vector2(x, SIZE.y - BITE)])


## [param shape] without a point where the one before it already is, the way the arcs and the
## perforation meet, which a polygon cannot be filled with.
static func _cleaned(shape: PackedVector2Array) -> PackedVector2Array:
	var kept := PackedVector2Array()
	for point: Vector2 in shape:
		if kept.is_empty() or not point.is_equal_approx(kept[kept.size() - 1]):
			kept.append(point)
	if kept.size() > 1 and kept[0].is_equal_approx(kept[kept.size() - 1]):
		kept.remove_at(kept.size() - 1)
	return kept


## A golden ticket drawn small on [param canvas] in [param rect], for where the ticket itself would
## be too small to read: its shape in gold, notched at the corners and bitten at its stub, the
## perforation, a star where the seal is, and a line or two where its words are.
static func draw_icon(canvas: CanvasItem, rect: Rect2) -> void:
	var notch := rect.size.y * 0.18
	var bite := rect.size.y * 0.12
	var stub := rect.position.x + rect.size.x * 0.76
	var shape := PackedVector2Array()
	_arc(shape, rect.position, notch, PI * 0.5, 0.0)
	_arc(shape, Vector2(stub, rect.position.y), bite, PI, 0.0)
	_arc(shape, Vector2(rect.end.x, rect.position.y), notch, PI, PI * 0.5)
	_arc(shape, rect.end, notch, PI * 1.5, PI)
	_arc(shape, Vector2(stub, rect.end.y), bite, 0.0, -PI)
	_arc(shape, Vector2(rect.position.x, rect.end.y), notch, 0.0, -PI * 0.5)
	var tints := PackedColorArray()
	for point: Vector2 in shape:
		var down := clampf((point.y - rect.position.y) / rect.size.y, 0.0, 1.0)
		tints.append(GOLD_HIGH.lerp(GOLD_LOW, down * 0.9))
	_fill(canvas, _cleaned(shape), tints)
	var ink := Color(INK, 0.7)
	var y := rect.position.y + bite + 1.5
	while y < rect.end.y - bite - 1.0:
		canvas.draw_circle(Vector2(stub, y), 0.7, ink)
		y += 3.0
	var seal := Vector2(rect.position.x + rect.size.y * 0.55, rect.get_center().y)
	canvas.draw_arc(seal, rect.size.y * 0.26, 0.0, TAU, 16, ink, 1.0, true)
	var left := seal.x + rect.size.y * 0.42
	for row: float in [-0.14, 0.06, 0.22]:
		var at := rect.get_center().y + rect.size.y * row
		var wide := (stub - 3.0 - left) * (1.0 if row < 0.0 else 0.7)
		canvas.draw_line(
			Vector2(left, at), Vector2(left + wide, at), ink, 1.0 if row < 0.0 else 0.8
		)


## A notch or a bite cut into the outline: round [param middle] from [param from] to [param to].
static func _arc(
	shape: PackedVector2Array, middle: Vector2, radius: float, from: float, to: float
) -> void:
	for i: int in 9:
		shape.append(middle + Vector2.from_angle(lerpf(from, to, float(i) / 8.0)) * radius)


func _shadow_of(canvas: CanvasItem, shape: PackedVector2Array) -> void:
	var under := PackedVector2Array()
	var tints := PackedColorArray()
	for point: Vector2 in shape:
		under.append(point + Vector2(6.0, 10.0))
		tints.append(SHADOW)
	_fill(canvas, under, tints)


## [param shape] in gold, lighter at the top and darker at the foot, as foil catches a light above.
func _gild(canvas: CanvasItem, shape: PackedVector2Array) -> void:
	var tints := PackedColorArray()
	for point: Vector2 in shape:
		tints.append(GOLD_HIGH.lerp(GOLD_LOW, clampf(point.y / SIZE.y, 0.0, 1.0) * 0.9))
	_fill(canvas, shape, tints)


## [param shape] filled, [param tints] at its points, as a fan from the middle of it: every point
## of either outline can be seen from its middle, and a fan needs no working out of triangles,
## which the engine's own gives up on along the ragged edge of a tear.
static func _fill(canvas: CanvasItem, shape: PackedVector2Array, tints: PackedColorArray) -> void:
	var bounds := Rect2(shape[0], Vector2.ZERO)
	var middle_tint := Color(0.0, 0.0, 0.0, 0.0)
	for i: int in shape.size():
		bounds = bounds.expand(shape[i])
		middle_tint += tints[i] / float(shape.size())
	var points := PackedVector2Array([bounds.get_center()])
	points.append_array(shape)
	var colors := PackedColorArray([middle_tint])
	colors.append_array(tints)
	var fan := PackedInt32Array()
	for i: int in shape.size():
		fan.append_array([0, 1 + i, 1 + (i + 1) % shape.size()])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), fan, points, colors)


## The House's seal, engraved.
func _draw_seal(middle: Vector2) -> void:
	for ring: float in [64.0, 52.0, 26.0]:
		draw_arc(middle, ring, 0.0, TAU, 64, Color(INK, 0.8), 2.4, true)
	var star := PackedVector2Array()
	for i: int in 10:
		var reach := 16.0 if i % 2 == 0 else 7.0
		star.append(middle + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * reach)
	draw_colored_polygon(star, INK)


## Who it is from and what for, whose it is on a dotted line, and the table.
func _draw_words() -> void:
	var x := 210.0
	var from := " ".join(StoryLines.TICKET_FROM.split(""))
	draw_string(NotePage.OLD, Vector2(x, 78.0), from, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	draw_string(
		Type.mark_font(),
		Vector2(x - 2.0, 170.0),
		StoryLines.FINAL_HAND,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		92,
		INK
	)
	var dots := x
	while dots < SIZE.x - STUB - 30.0:
		draw_circle(Vector2(dots, 232.0), 1.3, Color(INK, 0.7))
		dots += 7.0
	draw_string(
		NotePage.TYPED, Vector2(x, 222.0), holder.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK
	)
	# The table, as small as it takes to stay short of the perforation.
	var table := StoryLines.TICKET_TABLE
	var room := SIZE.x - STUB - 24.0 - x
	var table_size := 14
	while (
		table_size > 9
		and (
			NotePage.TYPED.get_string_size(table, HORIZONTAL_ALIGNMENT_LEFT, -1, table_size).x
			> room
		)
	):
		table_size -= 1
	draw_string(
		NotePage.TYPED,
		Vector2(x, 272.0),
		table,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		table_size,
		Color(INK, 0.8)
	)
