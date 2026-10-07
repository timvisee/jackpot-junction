class_name GoldenTicket
extends Control
## The House's golden ticket to the Final Hand, STORY.md 8.1: gold card stock with notched corners,
## fine waves engraved across it the way a banknote has them, the House's seal on the left, THE
## HOUSE REQUESTS YOUR COMPANY over FINAL HAND, the player's name typed on a dotted line, the table
## under it, and on the right, past a perforation, a stub reading ADMIT ONE numbered with the
## player's license. The stub is a child of its own, [member stub], so it can be torn off along the
## perforation, see [method tear]: the edges either side of the tear go ragged, matching. Drawn in
## code, at [constant SIZE].

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
## The stub torn off: pulled away from the ticket, then falling, turning as it goes.
const PULL := 0.14
const FALL := 0.75
const FALL_TURN := 0.6

## Whose name is typed on it, and the number on its stub.
var holder := ""
var serial := ""
## Whether its stub has been torn off.
var torn := false
## The stub, past the perforation.
var stub: Control

## The ragged edge of the tear, from top to bottom, along the perforation.
var _tear := PackedVector2Array()


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
	stub.draw.connect(_draw_stub)
	add_child(stub)


## Its stub torn off along the perforation: the edge goes ragged, the stub is pulled away and falls
## out of sight; [param then] called once it is gone.
func tear(then: Callable = Callable()) -> void:
	if torn:
		return
	torn = true
	queue_redraw()
	stub.queue_redraw()
	stub.pivot_offset = Vector2(SIZE.x - STUB, SIZE.y)
	Audio.play_sfx(&"tear", -4.0, 0.05)
	var off := create_tween()
	off.set_trans(Tween.TRANS_QUAD)
	off.tween_property(stub, "position", Vector2(26.0, -10.0), PULL).set_ease(Tween.EASE_OUT)
	off.parallel().tween_property(stub, "rotation", 0.12, PULL).set_ease(Tween.EASE_OUT)
	off.tween_property(stub, "position:y", get_viewport_rect().size.y * 1.6, FALL).set_ease(
		Tween.EASE_IN
	)
	off.parallel().tween_property(stub, "rotation", FALL_TURN, FALL).set_ease(Tween.EASE_IN)
	off.tween_callback(func() -> void: stub.visible = false)
	if then.is_valid():
		off.tween_callback(then)


## The ticket without its stub, the edge where it came off ragged: as it is kept afterwards.
func show_torn() -> void:
	torn = true
	stub.visible = false
	queue_redraw()


func _draw() -> void:
	var body := _body()
	_shadow_of(self, body)
	_gild(self, body)
	var inner := Rect2(
		Vector2.ONE * BORDER, Vector2(SIZE.x - STUB - BORDER - 4.0, SIZE.y - BORDER * 2.0)
	)
	draw_rect(inner, Color(INK, 0.5), false, 1.4)
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


## The stub: ADMIT ONE turned on its side, and the number under it.
func _draw_stub() -> void:
	var shape := _stub_shape()
	_shadow_of(stub, shape)
	_gild(stub, shape)
	var x := SIZE.x - STUB
	var inner := Rect2(x + 4.0, BORDER, STUB - BORDER - 4.0, SIZE.y - BORDER * 2.0)
	stub.draw_rect(inner, Color(INK, 0.5), false, 1.4)
	var mark := Type.mark_font()
	var admit := StoryLines.ADMIT_ONE
	stub.draw_set_transform(Vector2(x + STUB * 0.5 + 10.0, SIZE.y * 0.5), -PI * 0.5, Vector2.ONE)
	var wide := mark.get_string_size(admit, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	stub.draw_string(mark, Vector2(-wide * 0.5, 0.0), admit, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, INK)
	var number := StoryLines.TICKET_NUMBER % serial
	var number_wide := NotePage.TYPED.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	stub.draw_string(
		NotePage.TYPED,
		Vector2(-number_wide * 0.5, 34.0),
		number,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		INK
	)
	stub.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
func _stub_shape() -> PackedVector2Array:
	var x := SIZE.x - STUB
	var shape := PackedVector2Array()
	_arc(shape, Vector2(x, 0.0), BITE, PI * 0.5, 0.0)
	_arc(shape, Vector2(SIZE.x, 0.0), NOTCH, PI, PI * 0.5)
	_arc(shape, SIZE, NOTCH, PI * 1.5, PI)
	_arc(shape, Vector2(x, SIZE.y), BITE, 0.0, -PI * 0.5)
	var up := _edge()
	up.reverse()
	shape.append_array(up)
	return _cleaned(shape)


## Down the perforation, between the bites: straight, or ragged once torn.
func _edge() -> PackedVector2Array:
	var x := SIZE.x - STUB
	if torn and not _tear.is_empty():
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
	draw_string(
		NotePage.TYPED,
		Vector2(x, 272.0),
		StoryLines.TICKET_TABLE,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color(INK, 0.8)
	)
