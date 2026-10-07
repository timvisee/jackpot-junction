class_name NotePaper
extends RefCounted
## The papers Kit's notes are on, STORY.md 7.3, drawn onto a [NotePage]: each one's shape and what
## is printed on it before anybody wrote anything, its folds, the clip that holds it in the folder,
## a stamp, the sketch of table one and the blueprint. Static, drawn into whatever canvas asks.

const CLIP := Color(0.6, 0.62, 0.66)
const FOLD_DARK := Color(0.0, 0.0, 0.0, 0.1)
const FOLD_LIGHT := Color(1.0, 1.0, 1.0, 0.25)
const GRAPH_LINE := Color(0.55, 0.7, 0.85, 0.35)
const GRAPH_MAJOR := Color(0.45, 0.62, 0.8, 0.5)
const HOUSE_GOLD := Color(0.85, 0.68, 0.3)


## The paper of [param kind] in [param rect], [param color], as it is before the words.
static func draw_paper(canvas: CanvasItem, kind: StringName, rect: Rect2, color: Color) -> void:
	match kind:
		&"receipt", &"roll":
			canvas.draw_colored_polygon(_torn(rect, 6.0, true, true), color)
			# Curled: the long edges a shade darker, rolled toward the eye.
			for side: float in [0.0, 1.0]:
				var edge := Rect2(
					rect.position + Vector2(side * (rect.size.x - 14.0), 0.0),
					Vector2(14.0, rect.size.y)
				)
				canvas.draw_rect(
					edge.grow_individual(0.0, -6.0, 0.0, -6.0), Color(0.0, 0.0, 0.0, 0.06)
				)
		&"graph", &"graph_torn":
			var torn := kind == &"graph_torn"
			canvas.draw_colored_polygon(_torn(rect, 5.0, false, torn), color)
			_grid(canvas, rect.grow_individual(0.0, 0.0, 0.0, -10.0 if torn else 0.0), 12.0)
			_fold(canvas, rect, false, 0.5)
		&"flyer":
			# Torn across, the bottom of it gone.
			var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)])
			for i: int in range(12, -1, -1):
				var t := float(i) / 12.0
				var y := (
					lerpf(rect.size.y * 0.86, rect.size.y * 0.74, t) + (5.0 if i % 2 == 0 else -3.0)
				)
				points.append(rect.position + Vector2(rect.size.x * t, y))
			canvas.draw_colored_polygon(points, color)
			canvas.draw_rect(
				Rect2(rect.position + Vector2(8.0, 8.0), Vector2(rect.size.x - 16.0, 2.0)),
				HOUSE_GOLD
			)
		&"slip":
			canvas.draw_rect(rect, color)
			# The payout slip's print showing through from the other side, backward and faint.
			for i: int in 9:
				var y := rect.position.y + 30.0 + float(i) * 24.0
				canvas.draw_line(
					Vector2(rect.position.x + 40.0, y),
					Vector2(rect.end.x - 30.0 - float(i % 3) * 40.0, y),
					Color(0.0, 0.0, 0.0, 0.04),
					6.0
				)
			for i: int in int(rect.size.x / 10.0):
				canvas.draw_circle(
					Vector2(rect.position.x + 5.0 + float(i) * 10.0, rect.position.y),
					2.0,
					NotePage.LEAF
				)
			_fold(canvas, rect, false, 0.5)
		&"napkin":
			canvas.draw_rect(rect.grow(-4.0), color)
			for i: int in int(rect.size.x / 12.0) + 1:
				var x := rect.position.x + float(i) * 12.0
				canvas.draw_circle(Vector2(x, rect.position.y + 4.0), 5.0, color)
				canvas.draw_circle(Vector2(x, rect.end.y - 4.0), 5.0, color)
			for i: int in int(rect.size.y / 12.0) + 1:
				var y := rect.position.y + float(i) * 12.0
				canvas.draw_circle(Vector2(rect.position.x + 4.0, y), 5.0, color)
				canvas.draw_circle(Vector2(rect.end.x - 4.0, y), 5.0, color)
			canvas.draw_rect(rect.grow(-14.0), Color(0.7, 0.18, 0.2, 0.5), false, 1.5)
			_fold(canvas, rect, false, 0.5)
			_fold(canvas, rect, true, 0.5)
		&"pamphlet":
			canvas.draw_rect(rect, color)
			_fold(canvas, rect, true, 0.5)
		&"old_page":
			canvas.draw_rect(rect, color)
			# Gone darker at the edges, and spotted with age.
			for i: int in 6:
				var inset := float(i) * 3.0
				canvas.draw_rect(rect.grow(-inset), Color(0.4, 0.28, 0.1, 0.05), false, 3.0)
			var rng := RandomNumberGenerator.new()
			rng.seed = 1212
			for i: int in 14:
				var spot := (
					rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
				)
				canvas.draw_circle(spot, rng.randf_range(1.0, 3.5), Color(0.5, 0.33, 0.12, 0.12))
			_fold(canvas, rect, false, 0.62)
		&"clipboard":
			var board := rect.grow_individual(16.0, 30.0, 16.0, 16.0)
			canvas.draw_rect(board, Color(0.52, 0.37, 0.22))
			canvas.draw_rect(rect, color)
			var clip := Rect2(
				Vector2(rect.get_center().x - 46.0, board.position.y + 6.0), Vector2(92.0, 34.0)
			)
			canvas.draw_rect(clip, Color(0.66, 0.68, 0.72))
			canvas.draw_rect(clip.grow(-6.0), Color(0.5, 0.52, 0.56))
		&"envelope":
			canvas.draw_rect(rect, color)
			var flap := Color(0.0, 0.0, 0.0, 0.12)
			var tip := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.46)
			canvas.draw_line(rect.position, tip, flap, 1.5)
			canvas.draw_line(Vector2(rect.end.x, rect.position.y), tip, flap, 1.5)
			canvas.draw_line(
				Vector2(rect.position.x, rect.end.y), tip + Vector2(0.0, 30.0), flap, 1.0
			)
			canvas.draw_line(rect.end, tip + Vector2(0.0, 30.0), flap, 1.0)
		&"blueprint":
			canvas.draw_rect(rect, color)
			_grid(canvas, rect, 20.0, Color(1.0, 1.0, 1.0, 0.06), Color(1.0, 1.0, 1.0, 0.1))
			# Folded into eighths and soft at the folds.
			for i: int in [1, 2, 3]:
				_fold(canvas, rect, true, float(i) / 4.0)
			_fold(canvas, rect, false, 0.5)
		&"chart":
			canvas.draw_rect(rect, color)
			# A copy of a copy: speckled, and gray at the edges where the glass was dirty.
			var rng := RandomNumberGenerator.new()
			rng.seed = 18
			for i: int in 220:
				var speck := (
					rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
				)
				canvas.draw_rect(
					Rect2(speck, Vector2.ONE * rng.randf_range(0.6, 1.6)),
					Color(0.0, 0.0, 0.0, 0.18)
				)
			canvas.draw_rect(rect, Color(0.0, 0.0, 0.0, 0.15), false, 6.0)
			_fold(canvas, rect, false, 0.5)
		&"letter":
			canvas.draw_rect(rect, color)
			# The House's letterhead: its seal in gold over a rule.
			var seal := Vector2(rect.get_center().x, rect.position.y + 24.0)
			canvas.draw_arc(seal, 12.0, 0.0, TAU, 24, HOUSE_GOLD, 2.0, true)
			canvas.draw_arc(seal, 7.0, 0.0, TAU, 24, HOUSE_GOLD, 1.0, true)
			canvas.draw_line(
				Vector2(rect.position.x + 24.0, seal.y + 20.0),
				Vector2(rect.end.x - 24.0, seal.y + 20.0),
				HOUSE_GOLD,
				1.0
			)
			_fold(canvas, rect, false, 0.34)
			_fold(canvas, rect, false, 0.67)
		&"strip":
			canvas.draw_colored_polygon(_torn(rect, 5.0, true, true), color)
			# What is left of the page it was torn off: a few lines of the Code, too small to read.
			for i: int in 5:
				var y := rect.position.y + 14.0 + float(i) * 22.0
				canvas.draw_line(
					Vector2(rect.position.x + 12.0, y),
					Vector2(rect.end.x - 12.0 - float(i % 2) * 60.0, y),
					Color(0.0, 0.0, 0.0, 0.08),
					3.0
				)
		&"card":
			var card := StyleBoxFlat.new()
			card.bg_color = color
			card.set_corner_radius_all(10)
			card.set_border_width_all(2)
			card.border_color = HOUSE_GOLD
			canvas.draw_style_box(card, rect)
		&"form":
			canvas.draw_rect(rect, color)
			canvas.draw_rect(
				Rect2(rect.position, Vector2(rect.size.x, 30.0)), Color(0.0, 0.0, 0.0, 0.08)
			)
			canvas.draw_line(
				rect.position + Vector2(0.0, 30.0),
				Vector2(rect.end.x, rect.position.y + 30.0),
				Color(0.0, 0.0, 0.0, 0.3),
				1.0
			)
			_fold(canvas, rect, false, 0.5)
		&"memo":
			canvas.draw_rect(rect, color)
			canvas.draw_rect(
				Rect2(rect.position, Vector2(rect.size.x, 12.0)), Color(0.12, 0.1, 0.14)
			)
			canvas.draw_rect(
				Rect2(rect.position + Vector2(0.0, 12.0), Vector2(rect.size.x, 2.0)), HOUSE_GOLD
			)
			_fold(canvas, rect, false, 0.5)
		_:
			canvas.draw_rect(rect, color)
			canvas.draw_line(
				rect.position + Vector2(14.0, 12.0),
				Vector2(rect.end.x - 14.0, rect.position.y + 12.0),
				Color(0.0, 0.0, 0.0, 0.35),
				1.0
			)
			_fold(canvas, rect, false, 0.5)


## A crease across [param rect], down it with [param across], at [param at] of the way.
static func _fold(canvas: CanvasItem, rect: Rect2, across: bool, at: float) -> void:
	if across:
		var x := rect.position.x + rect.size.x * at
		canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), FOLD_DARK, 1.0)
		canvas.draw_line(
			Vector2(x + 1.0, rect.position.y), Vector2(x + 1.0, rect.end.y), FOLD_LIGHT, 1.0
		)
		return
	var y := rect.position.y + rect.size.y * at
	canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), FOLD_DARK, 1.0)
	canvas.draw_line(
		Vector2(rect.position.x, y + 1.0), Vector2(rect.end.x, y + 1.0), FOLD_LIGHT, 1.0
	)


static func _grid(
	canvas: CanvasItem,
	rect: Rect2,
	step: float,
	minor: Color = GRAPH_LINE,
	major: Color = GRAPH_MAJOR
) -> void:
	var i := 0
	var x := rect.position.x + step
	while x < rect.end.x:
		i += 1
		canvas.draw_line(
			Vector2(x, rect.position.y), Vector2(x, rect.end.y), major if i % 5 == 0 else minor, 1.0
		)
		x += step
	i = 0
	var y := rect.position.y + step
	while y < rect.end.y:
		i += 1
		canvas.draw_line(
			Vector2(rect.position.x, y), Vector2(rect.end.x, y), major if i % 5 == 0 else minor, 1.0
		)
		y += step


## [param rect] as a polygon with its top and bottom edges torn, ragged by [param ragged].
static func _torn(rect: Rect2, ragged: float, top: bool, bottom: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var teeth := int(rect.size.x / 9.0)
	for i: int in teeth + 1:
		var x := rect.position.x + rect.size.x * float(i) / float(teeth)
		var dent := (ragged if i % 2 == 0 else 0.0) if top else 0.0
		points.append(Vector2(x, rect.position.y + dent))
	for i: int in range(teeth, -1, -1):
		var x := rect.position.x + rect.size.x * float(i) / float(teeth)
		var dent := (ragged if i % 2 == 1 else 0.0) if bottom else 0.0
		points.append(Vector2(x, rect.end.y - dent))
	return points


## The paper clip holding a note to its leaf, over the paper's top edge at its left corner, in the
## margin the words keep.
static func draw_clip(canvas: CanvasItem, rect: Rect2) -> void:
	var at := Vector2(rect.position.x + 3.0, rect.position.y - 14.0)
	var loop := PackedVector2Array(
		[
			at + Vector2(0.0, 44.0),
			at + Vector2(0.0, 4.0),
			at + Vector2(5.0, 0.0),
			at + Vector2(11.0, 4.0),
			at + Vector2(11.0, 38.0),
			at + Vector2(7.0, 41.0),
			at + Vector2(4.0, 38.0),
			at + Vector2(4.0, 10.0),
		]
	)
	canvas.draw_polyline(loop, Color(0.0, 0.0, 0.0, 0.2), 3.0, true)
	canvas.draw_polyline(loop, CLIP, 2.0, true)


## A rubber stamp's word in a box, in red, at [param middle], turned by [param angle].
static func draw_stamp(canvas: CanvasItem, word: String, middle: Vector2, angle: float) -> void:
	var font := Type.display_font()
	var font_size := 22
	var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_set_transform(middle, angle, Vector2.ONE)
	var box := Rect2(Vector2(-wide * 0.5 - 10.0, -18.0), Vector2(wide + 20.0, 34.0))
	canvas.draw_rect(box, NotePage.STAMP_INK, false, 2.5)
	canvas.draw_string(
		font,
		Vector2(-wide * 0.5, 9.0),
		word,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		NotePage.STAMP_INK
	)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Kit's pencil sketch of table one in the corner of the graph paper: the table, its walls, the
## Junction in the middle and a pad in each corner, STORY.md 7.3.
static func draw_sketch(canvas: CanvasItem, rect: Rect2) -> void:
	var box := Rect2(rect.end - Vector2(130.0, 96.0), Vector2(110.0, 76.0))
	var lead := Color(0.32, 0.32, 0.35, 0.8)
	canvas.draw_rect(box, lead, false, 1.4)
	canvas.draw_rect(box.grow(-8.0), lead, false, 1.0)
	canvas.draw_arc(box.get_center(), 10.0, 0.0, TAU, 20, lead, 1.2, true)
	for corner: Vector2 in [
		Vector2(0.2, 0.25), Vector2(0.8, 0.25), Vector2(0.2, 0.75), Vector2(0.8, 0.75)
	]:
		canvas.draw_rect(
			Rect2(box.position + box.size * corner - Vector2(4.0, 4.0), Vector2(8.0, 8.0)),
			lead,
			false,
			1.0
		)
	canvas.draw_line(
		box.position + Vector2(30.0, 22.0), box.position + Vector2(30.0, 54.0), lead, 1.0
	)
	canvas.draw_line(
		box.position + Vector2(80.0, 22.0), box.position + Vector2(80.0, 54.0), lead, 1.0
	)


## The blueprint's drawing, STORY.md 7.3: a highway across the top, THE ECONOMY; a slip road off it,
## PEOPLE NO LONGER REQUIRED, down onto a roundabout round a pot, JACKPOT, with no way off it; in
## the title block's corner, a signature in ink and the Department's stamp. White lines on blue.
static func draw_blueprint(canvas: CanvasItem, rect: Rect2) -> void:
	var ink := NotePage.BLUEPRINT_INK
	var font := NotePage.TYPED
	var top := rect.position.y + 52.0
	# The highway: two edges and a dashed line down its middle, running off both sides.
	for edge: float in [-14.0, 14.0]:
		canvas.draw_line(
			Vector2(rect.position.x + 10.0, top + edge),
			Vector2(rect.end.x - 10.0, top + edge),
			ink,
			2.0
		)
	var x := rect.position.x + 14.0
	while x < rect.end.x - 20.0:
		canvas.draw_line(Vector2(x, top), Vector2(x + 10.0, top), ink, 1.0)
		x += 20.0
	canvas.draw_string(
		font,
		Vector2(rect.position.x + 16.0, top - 22.0),
		"THE ECONOMY",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		ink
	)
	# The slip road: off the highway's lower edge, curving down onto the roundabout.
	var ring := Vector2(rect.position.x + rect.size.x * 0.36, rect.position.y + rect.size.y * 0.5)
	var radius := 46.0
	for side: float in [-9.0, 9.0]:
		var road := PackedVector2Array()
		for i: int in 17:
			var t := float(i) / 16.0
			var from := Vector2(rect.end.x - 80.0, top + 14.0)
			var to := ring + Vector2.from_angle(-0.75) * (radius + 9.0)
			var bend := Vector2(lerpf(from.x, to.x, t), lerpf(from.y, to.y, t * t))
			road.append(bend + Vector2(side * 0.7, side * 0.7))
		canvas.draw_polyline(road, ink, 1.6, true)
	canvas.draw_set_transform(ring + Vector2(radius + 60.0, -radius * 1.35), 0.62, Vector2.ONE)
	canvas.draw_string(
		font, Vector2.ZERO, "PEOPLE NO LONGER REQUIRED", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ink
	)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The roundabout, a ring of road with no exit, and the pot in its middle.
	canvas.draw_arc(ring, radius + 9.0, 0.0, TAU, 48, ink, 1.6, true)
	canvas.draw_arc(ring, radius - 9.0, 0.0, TAU, 48, ink, 1.6, true)
	for i: int in 16:
		var a := TAU * float(i) / 16.0
		canvas.draw_line(
			ring + Vector2.from_angle(a) * radius,
			ring + Vector2.from_angle(a + 0.12) * radius,
			ink,
			1.0
		)
	canvas.draw_arc(ring, 18.0, 0.0, TAU, 32, ink, 1.4, true)
	var pot := font.get_string_size("JACKPOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	canvas.draw_string(
		font, ring + Vector2(-pot * 0.5, 4.0), "JACKPOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ink
	)
	# The title block, its signature in ink and the Department's stamp.
	var block := Rect2(
		rect.position + Vector2(rect.size.x * 0.3, rect.size.y * 0.64),
		Vector2(rect.size.x * 0.66, rect.size.y * 0.32)
	)
	canvas.draw_rect(block, ink, false, 1.4)
	var signed := block.position + Vector2(block.size.x * 0.34, block.size.y * 0.9)
	var scrawl := PackedVector2Array()
	for i: int in 22:
		var t := float(i) / 21.0
		scrawl.append(signed + Vector2(t * 92.0, sin(t * 17.0) * 7.0 - t * 6.0))
	canvas.draw_polyline(scrawl, Color(0.05, 0.08, 0.25), 1.6, true)
	var stamp := block.position + Vector2(block.size.x * 0.84, block.size.y * 0.72)
	canvas.draw_arc(stamp, 22.0, 0.0, TAU, 32, NotePage.STAMP_INK, 2.0, true)
	canvas.draw_arc(stamp, 16.0, 0.0, TAU, 32, NotePage.STAMP_INK, 1.0, true)
	var dept := font.get_string_size("D.O.K.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	canvas.draw_string(
		font,
		stamp + Vector2(-dept * 0.5, 3.0),
		"D.O.K.",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		9,
		NotePage.STAMP_INK
	)
