class_name TicketStyle
extends StyleBox
## The house's ticket, GAME.md 8.1a: the shape every pane, button, box and question is cut from.
## A card of stock with its four corners notched inward the way a ticket is punched, a hairline of
## foil just inside its edge, the fine lines of [Engraving] under it where it asks for them, and
## across a pane with a header a perforation with a bite out of either side.
##
## Drawn rather than taken from a [StyleBoxFlat], which has no inward corner and no perforation.
## The shape and its lines are worked out once for a size and kept, so a control that is only
## redrawn pays for the drawing and not the geometry; a list's rows and a bar's tabs are several
## sizes a draw, so a few sizes are kept at once.

## How many straight pieces a notch, a bite and a chevron are drawn in.
const NOTCH_STEPS := 6
## The holes of a perforation: how far apart, how big, in what ink.
const HOLE_GAP := 9.0
const HOLE_RADIUS := 1.3
const HOLE_INK := Color(0.25, 0.24, 0.29)
## The lane chevron that says which control has the cursor: how far in from the left edge, how
## tall, how far apart the two of it are, and how thick.
const CHEVRON_AT := 13.0
const CHEVRON_HALF := 6.0
const CHEVRON_GAP := 7.0
const CHEVRON_WIDTH := 2.4
## How wide a ticket has to be to wear the chevron: on a button that is only a picture, a trash can
## or an arrow, the chevron would stand on the picture, and the gold round it says enough.
const CHEVRON_ROOM := 110.0
## How the waves across a header are laid: apart, high and long, see [method Engraving.waves].
const WAVE_GAP := 9.0
const WAVE_HEIGHT := 3.5
const WAVE_LENGTH := 130.0
## How many sizes are kept worked out at once.
const KEPT := 8

## The stock, and what it darkens or lightens to at the foot; clear for the same all the way.
@export var fill := HouseTheme.STOCK:
	set = _set_fill
@export var fill_low := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_fill_low
## How deep a notch is cut into each corner, and whether the top two are cut at all: a pane hung
## under a row of tabs has its top edge to give to them.
@export var notch := 9.0:
	set = _set_notch
@export var notch_top := true:
	set = _set_notch_top
## Where perforations cross, down from the top, and how deep the bite out of either side is.
@export var perforations := PackedFloat32Array():
	set = _set_perforations
@export var bite := 10.0:
	set = _set_bite
## The foil hairline inside the edge: round the header, above the first perforation, or round the
## whole ticket where there is none, and round the body under it; how far in it runs.
@export var frame := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_frame
@export var frame_body := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_frame_body
@export var frame_inset := 4.0:
	set = _set_frame_inset
## A line round the outside, the gold of the control with the cursor, and how thick.
@export var border := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_border
@export var border_width := 2.0:
	set = _set_border_width
## The lane chevron at the left end, see [constant CHEVRON_AT]; clear for none.
@export var chevron := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_chevron
## The engraving: its ink, how far down the waves across the head reach, and how big the seal in
## the top right corner is; nothing for either at zero.
@export var engraving := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_engraving
@export var waves := 0.0:
	set = _set_waves
@export var seal := 0.0:
	set = _set_seal
## A soft shadow under the ticket, how far it spreads and how dark it is at its darkest.
@export var shadow := 0.0:
	set = _set_shadow
@export var shadow_color := Color(0.0, 0.0, 0.0, 0.45):
	set = _set_shadow_color

## What has been worked out, by size.
var _kept: Dictionary[Vector2, Dictionary] = {}
var _order: Array[Vector2] = []


## A ticket of [param stock] with [param notch]-deep corners and content margins [param across]
## either side and [param down] above and below.
static func cut(stock: Color, notch_depth: float, across: float, down: float) -> TicketStyle:
	var style := TicketStyle.new()
	style.fill = stock
	style.notch = notch_depth
	style.content_margin_left = across
	style.content_margin_right = across
	style.content_margin_top = down
	style.content_margin_bottom = down
	return style


## The outline of a ticket [param size] big with its top left at the origin: [param depth]-deep
## notches, bites [param bite_depth] deep at [param bites] down either side, and the top corners
## left square without [param top_notched].
static func outline(
	size: Vector2,
	depth: float,
	bites := PackedFloat32Array(),
	bite_depth := 10.0,
	top_notched := true
) -> PackedVector2Array:
	var w := size.x
	var h := size.y
	var n := clampf(depth, 0.0, minf(w, h) * 0.5 - 1.0)
	# A bite that would run into a notch is left out rather than cut across it.
	var kept := PackedFloat32Array()
	for y: float in bites:
		if y > n + bite_depth and y < h - n - bite_depth:
			kept.append(y)
	bites = kept
	var points := PackedVector2Array()
	if top_notched and n > 0.0:
		_arc(points, Vector2(w, 0.0), n, PI, PI * 0.5)
	else:
		points.append(Vector2(w, 0.0))
	for y: float in bites:
		_arc(points, Vector2(w, y), bite_depth, PI * 1.5, PI * 0.5)
	if n > 0.0:
		_arc(points, Vector2(w, h), n, PI * 1.5, PI)
		_arc(points, Vector2(0.0, h), n, TAU, PI * 1.5)
	else:
		points.append(Vector2(w, h))
		points.append(Vector2(0.0, h))
	var up := Array(bites)
	up.reverse()
	for y: float in up:
		_arc(points, Vector2(0.0, y), bite_depth, PI * 0.5, -PI * 0.5)
	if top_notched and n > 0.0:
		_arc(points, Vector2(0.0, 0.0), n, PI * 0.5, 0.0)
	else:
		points.append(Vector2.ZERO)
	return points


## Points along an arc of [param radius] round [param center] from [param from] to [param to],
## both ends included.
static func _arc(
	points: PackedVector2Array, center: Vector2, radius: float, from: float, to: float
) -> void:
	for s: int in NOTCH_STEPS + 1:
		var angle := lerpf(from, to, float(s) / float(NOTCH_STEPS))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	var made := _made(rect.size)
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D(0.0, rect.position))
	for layer: PackedVector2Array in made["shadow"]:
		RenderingServer.canvas_item_add_polygon(
			to_canvas_item, layer, [Color(shadow_color, shadow_color.a / 4.0)]
		)
	var edge: PackedVector2Array = made["outline"]
	if fill.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, edge, made["fill"])
		# The polygon's own edge is a staircase; a soft line along it is what makes it a cut.
		RenderingServer.canvas_item_add_polyline(to_canvas_item, made["closed"], [fill], 1.0, true)
	Engraving.draw(to_canvas_item, made["lines"], engraving, made["inks"])
	var frames: Array[PackedVector2Array] = made["frames"]
	for i: int in frames.size():
		var ink := frame if i == 0 else frame_body
		if ink.a > 0.0 and frames[i].size() >= 2:
			RenderingServer.canvas_item_add_polyline(to_canvas_item, frames[i], [ink], 1.0, true)
	for hole: Vector2 in made["holes"]:
		RenderingServer.canvas_item_add_circle(to_canvas_item, hole, HOLE_RADIUS, HOLE_INK, true)
	if border.a > 0.0:
		RenderingServer.canvas_item_add_polyline(
			to_canvas_item, made["border"], [border], border_width, true
		)
	if chevron.a > 0.0 and rect.size.x >= CHEVRON_ROOM:
		var middle := rect.size.y * 0.5
		for i: int in 2:
			var x := CHEVRON_AT + float(i) * CHEVRON_GAP
			var points := PackedVector2Array(
				[
					Vector2(x, middle - CHEVRON_HALF),
					Vector2(x + CHEVRON_HALF * 0.85, middle),
					Vector2(x, middle + CHEVRON_HALF),
				]
			)
			var ink := Color(chevron, chevron.a * (0.5 if i == 0 else 1.0))
			RenderingServer.canvas_item_add_polyline(
				to_canvas_item, points, [ink], CHEVRON_WIDTH, true
			)
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D.IDENTITY)


## Everything that depends only on the size, worked out the first time it is asked for.
func _made(size: Vector2) -> Dictionary:
	if _kept.has(size):
		return _kept[size]
	var made := {}
	var edge := outline(size, notch, perforations, bite, notch_top)
	made["outline"] = edge
	var closed := edge.duplicate()
	closed.append(edge[0])
	made["closed"] = closed
	var inks := PackedColorArray()
	var low := fill_low if fill_low.a > 0.0 else fill
	for point: Vector2 in edge:
		inks.append(fill.lerp(low, point.y / size.y))
	made["fill"] = inks
	made["shadow"] = _shadow_layers(edge)
	var lines: Array[PackedVector2Array] = []
	var inks_of: Array[PackedColorArray] = []
	if engraving.a > 0.0:
		var band := minf(waves, size.y)
		if band > 0.0:
			lines.append_array(
				Engraving.waves(
					Rect2(0.0, WAVE_GAP * 0.5, size.x, band), WAVE_GAP, WAVE_HEIGHT, WAVE_LENGTH
				)
			)
		if seal > 0.0:
			var middle := Vector2(size.x - seal * 1.05, seal * 0.85)
			lines.append_array(Engraving.rings(middle, seal, seal * 0.08, 18, 10, 180))
			lines.append_array(Engraving.rosette(middle, seal * 0.62))
		lines = Engraving.inside(lines, edge)
		inks_of = Engraving.faded(lines, engraving, 0.0, maxf(band, seal * 2.2))
	made["lines"] = lines
	made["inks"] = inks_of
	made["frames"] = _frames(size)
	made["holes"] = _holes(size)
	var half := border_width * 0.5
	var inner := outline(
		size - Vector2.ONE * border_width,
		maxf(notch - half, 0.0),
		_shifted(perforations, -half),
		bite + half,
		notch_top
	)
	inner.append(inner[0])
	for i: int in inner.size():
		inner[i] += Vector2.ONE * half
	made["border"] = inner
	if _order.size() >= KEPT:
		_kept.erase(_order.pop_front())
	_kept[size] = made
	_order.append(size)
	return made


## The hairlines inside the edge: one round the header and one round the body when there is a
## perforation, one round the whole otherwise.
func _frames(size: Vector2) -> Array[PackedVector2Array]:
	var frames: Array[PackedVector2Array] = []
	if frame.a <= 0.0 and frame_body.a <= 0.0:
		return frames
	var inset := frame_inset
	var depth := maxf(notch - inset * 0.5, 2.0)
	var parts: Array[Rect2] = []
	if perforations.is_empty():
		parts.append(Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0))
	else:
		var first := perforations[0]
		parts.append(Rect2(inset, inset, size.x - inset * 2.0, first - bite - 3.0 - inset))
		var below := first + bite + 3.0
		parts.append(Rect2(inset, below, size.x - inset * 2.0, size.y - inset - below))
	for i: int in parts.size():
		var part := parts[i]
		if part.size.x < 4.0 or part.size.y < 4.0:
			frames.append(PackedVector2Array())
			continue
		var top := notch_top or i > 0
		var line := outline(part.size, depth, PackedFloat32Array(), 0.0, top)
		line.append(line[0])
		for p: int in line.size():
			line[p] += part.position
		frames.append(line)
	return frames


func _holes(size: Vector2) -> PackedVector2Array:
	var holes := PackedVector2Array()
	for y: float in perforations:
		var x := bite + 8.0
		while x <= size.x - bite - 8.0:
			holes.append(Vector2(x, y))
			x += HOLE_GAP
	return holes


func _shadow_layers(edge: PackedVector2Array) -> Array[PackedVector2Array]:
	var layers: Array[PackedVector2Array] = []
	if shadow <= 0.0 or shadow_color.a <= 0.0:
		return layers
	var dropped := edge.duplicate()
	for i: int in dropped.size():
		dropped[i] += Vector2(0.0, shadow * 0.3)
	for step: int in [4, 3, 2, 1]:
		var grown := Geometry2D.offset_polygon(
			dropped, shadow * float(step) / 4.0, Geometry2D.JOIN_ROUND
		)
		if not grown.is_empty():
			layers.append(grown[0])
	return layers


static func _shifted(values: PackedFloat32Array, by: float) -> PackedFloat32Array:
	var moved := values.duplicate()
	for i: int in moved.size():
		moved[i] += by
	return moved


## Anything that changes the shape or its lines throws away what was worked out.
func _changed() -> void:
	_kept.clear()
	_order.clear()
	emit_changed()


func _set_fill(value: Color) -> void:
	fill = value
	_changed()


func _set_fill_low(value: Color) -> void:
	fill_low = value
	_changed()


func _set_notch(value: float) -> void:
	notch = value
	_changed()


func _set_notch_top(value: bool) -> void:
	notch_top = value
	_changed()


func _set_perforations(value: PackedFloat32Array) -> void:
	if value == perforations:
		return
	perforations = value
	_changed()


func _set_bite(value: float) -> void:
	bite = value
	_changed()


func _set_frame(value: Color) -> void:
	frame = value
	_changed()


func _set_frame_body(value: Color) -> void:
	frame_body = value
	_changed()


func _set_frame_inset(value: float) -> void:
	frame_inset = value
	_changed()


func _set_border(value: Color) -> void:
	border = value
	_changed()


func _set_border_width(value: float) -> void:
	border_width = value
	_changed()


func _set_chevron(value: Color) -> void:
	chevron = value
	emit_changed()


func _set_engraving(value: Color) -> void:
	engraving = value
	_changed()


func _set_waves(value: float) -> void:
	waves = value
	_changed()


func _set_seal(value: float) -> void:
	seal = value
	_changed()


func _set_shadow(value: float) -> void:
	shadow = value
	_changed()


func _set_shadow_color(value: Color) -> void:
	shadow_color = value
	_changed()
