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
## The blueprint's slip road, half its width, and the size of Kit's pencil in its margin.
const SLIP_HALF := 12.0
const MARGIN_SIZE := 20


## The paper of [param kind] in [param rect], [param color], as it is before the words.
static func draw_paper(canvas: CanvasItem, kind: StringName, rect: Rect2, color: Color) -> void:
	match kind:
		&"receipt", &"roll":
			canvas.draw_colored_polygon(torn(rect, 6.0, true, true), color)
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
			var ripped := kind == &"graph_torn"
			canvas.draw_colored_polygon(torn(rect, 5.0, false, ripped), color)
			_grid(canvas, rect.grow_individual(0.0, 0.0, 0.0, -10.0 if ripped else 0.0), 12.0)
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
			canvas.draw_colored_polygon(torn(rect, 5.0, true, true), color)
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
static func torn(rect: Rect2, ragged: float, top: bool, bottom: bool) -> PackedVector2Array:
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


## The blueprint's drawing, STORY.md 7.3, drawn the way a road engineer draws, white lines on blue:
## a four-lane highway across the top, THE ECONOMY, every arrow on it one way; a slip road off it,
## PEOPLE NO LONGER REQUIRED, down onto a roundabout round a pot, JACKPOT, its arrows going round
## and no way off it, which a callout says; a dimension line and a north arrow; the title block
## along the foot, see [method blueprint_block], with a signature in ink and the Department's stamp
## at APPROVED; and Kit's pencil in the margin with an arrow to the signature, [param margin].
static func draw_blueprint(canvas: CanvasItem, rect: Rect2, margin := "") -> void:
	var ink := NotePage.BLUEPRINT_INK
	var faint := Color(ink, 0.55)
	var font := NotePage.TYPED
	var w := rect.size.x
	var h := rect.size.y
	var o := rect.position
	# The highway: its two edges, a double line down the middle, a dashed line between each pair of
	# lanes, and an arrow in every lane, all of them pointing the same way.
	var top := o.y + 44.0
	var lane := 13.0
	for edge: float in [0.0, lane * 4.0]:
		canvas.draw_line(
			Vector2(o.x + 8.0, top + edge), Vector2(o.x + w - 8.0, top + edge), ink, 2.0
		)
	for off: float in [-1.6, 1.6]:
		var y := top + lane * 2.0 + off
		canvas.draw_line(Vector2(o.x + 8.0, y), Vector2(o.x + w - 8.0, y), ink, 1.0)
	for row: int in [1, 3]:
		_dashed(
			canvas,
			Vector2(o.x + 10.0, top + lane * row),
			Vector2(o.x + w - 10.0, top + lane * row),
			faint
		)
	for row: int in 4:
		var y := top + lane * (float(row) + 0.5)
		var x := o.x + 40.0 + float(row % 2) * 40.0
		while x < o.x + w - 40.0:
			_arrow(canvas, Vector2(x, y), Vector2(x + 22.0, y), faint)
			x += 110.0
	canvas.draw_string(
		font, Vector2(o.x + 12.0, top - 8.0), "THE ECONOMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink
	)
	# The slip road: one line down from the highway's lower edge into the roundabout's top right, its
	# two edges either side of it and its name along it.
	var ring := Vector2(o.x + w * 0.34, o.y + h * 0.47)
	var outer := 56.0
	var island := 28.0
	var low := top + lane * 4.0
	var start := Vector2(o.x + w * 0.74, low)
	var bend := Vector2(o.x + w * 0.7, low + 92.0)
	var into := ring + Vector2.from_angle(-0.62) * (outer + 4.0)
	var centre := PackedVector2Array()
	for i: int in 17:
		var t := float(i) / 16.0
		centre.append(start.lerp(bend, t).lerp(bend.lerp(into, t), t))
	var gap := PackedFloat32Array()
	for side: float in [-1.0, 1.0]:
		var road := PackedVector2Array()
		for i: int in centre.size():
			var ahead := centre[mini(i + 1, centre.size() - 1)] - centre[maxi(i - 1, 0)]
			road.append(centre[i] + ahead.normalized().orthogonal() * SLIP_HALF * side)
		canvas.draw_polyline(road, ink, 1.8, true)
		gap.append((road[road.size() - 1] - ring).angle())
	var at := centre.size() / 2
	var heading := (centre[at + 1] - centre[at - 1]).angle()
	# Read left to right whichever way the road runs.
	if absf(heading) > PI * 0.5:
		heading += PI
	canvas.draw_set_transform(centre[at], heading, Vector2.ONE)
	canvas.draw_string(
		font,
		Vector2(-70.0, SLIP_HALF + 12.0),
		"PEOPLE NO LONGER REQUIRED",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		9,
		ink
	)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The roundabout: its outer edge broken only where the slip road comes in, the island, a dashed
	# lane line and arrows going round it; the pot in the middle.
	var gap_from := minf(gap[0], gap[1])
	var gap_to := maxf(gap[0], gap[1])
	canvas.draw_arc(ring, outer, gap_to, gap_from + TAU, 64, ink, 1.8, true)
	canvas.draw_arc(ring, island, 0.0, TAU, 40, ink, 1.6, true)
	var middle := (outer + island) * 0.5
	for i: int in 24:
		var a := TAU * float(i) / 24.0
		canvas.draw_arc(ring, middle, a, a + 0.12, 4, faint, 1.0, true)
	for i: int in 3:
		var from := 0.4 + TAU * float(i) / 3.0
		var turn := PackedVector2Array()
		for step: int in 9:
			turn.append(ring + Vector2.from_angle(from + 0.7 * float(step) / 8.0) * (middle + 6.0))
		canvas.draw_polyline(turn, ink, 1.4, true)
		_head(canvas, turn[turn.size() - 2], turn[turn.size() - 1], ink)
	var pot := font.get_string_size("JACKPOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	canvas.draw_string(
		font, ring + Vector2(-pot * 0.5, 3.0), "JACKPOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ink
	)
	# The callout: no exit, off the roundabout's far side.
	var from_ring := ring + Vector2.from_angle(PI + 0.35) * outer
	var callout := Rect2(Vector2(o.x + 12.0, ring.y - outer - 18.0), Vector2(62.0, 20.0))
	canvas.draw_line(from_ring, Vector2(callout.get_center().x, callout.end.y), ink, 1.0)
	canvas.draw_circle(from_ring, 2.2, ink)
	canvas.draw_rect(callout, ink, false, 1.2)
	canvas.draw_string(
		font,
		callout.position + Vector2(6.0, 14.0),
		"NO EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		ink
	)
	# A dimension line across the roundabout, under it.
	var y := ring.y + outer + 14.0
	var left := Vector2(ring.x - outer, y)
	var right := Vector2(ring.x + outer, y)
	for end: Vector2 in [left, right]:
		canvas.draw_line(end + Vector2(0.0, -6.0), end + Vector2(0.0, 6.0), faint, 1.0)
	_arrow(canvas, Vector2(ring.x, y), left, faint)
	_arrow(canvas, Vector2(ring.x, y), right, faint)
	var size := font.get_string_size("Ø 24.000", HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	canvas.draw_string(
		font,
		Vector2(ring.x - size * 0.5, y - 3.0),
		"Ø 24.000",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		8,
		ink
	)
	# The north arrow, out of the way on the right.
	var north := Vector2(o.x + w * 0.88, o.y + h * 0.58)
	canvas.draw_arc(north, 15.0, 0.0, TAU, 28, ink, 1.2, true)
	canvas.draw_colored_polygon(
		PackedVector2Array(
			[north + Vector2(0.0, -13.0), north + Vector2(6.0, 9.0), north + Vector2(-6.0, 9.0)]
		),
		Color(ink, 0.8)
	)
	canvas.draw_string(
		font, north + Vector2(-4.0, -20.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink
	)
	# The title block, its signature in ink over APPROVED and the Department's stamp beside it.
	var block := blueprint_block(rect)
	canvas.draw_rect(block, ink, false, 1.4)
	canvas.draw_line(
		block.position + Vector2(0.0, 18.0),
		Vector2(block.end.x, block.position.y + 18.0),
		faint,
		1.0
	)
	var signed := Vector2(block.position.x + block.size.x * 0.4, block.end.y - 12.0)
	var scrawl := PackedVector2Array()
	for i: int in 26:
		var t := float(i) / 25.0
		scrawl.append(signed + Vector2(t * 96.0, sin(t * 17.0) * 6.0 - t * 5.0))
	canvas.draw_polyline(scrawl, Color(0.05, 0.08, 0.25), 1.7, true)
	var stamp := Vector2(block.end.x - 30.0, block.end.y - 22.0)
	canvas.draw_arc(stamp, 20.0, 0.0, TAU, 32, NotePage.STAMP_INK, 2.0, true)
	canvas.draw_arc(stamp, 14.0, 0.0, TAU, 32, NotePage.STAMP_INK, 1.0, true)
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
	if margin.is_empty():
		return
	# Kit's pencil in the margin left of the title block, pale on the blue, and an arrow from it to
	# the signature.
	var lead := Color(0.86, 0.88, 0.92, 0.92)
	var room := block.position.x - o.x - 18.0
	var rows := NotePage._rows(margin, NotePage.HAND, MARGIN_SIZE, room)
	var line := NotePage.HAND.get_height(MARGIN_SIZE) * 0.9
	var note := Vector2(o.x + 10.0, block.position.y + 30.0)
	var widest := 0.0
	for i: int in rows.size():
		var row := rows[i]
		canvas.draw_string(
			NotePage.HAND,
			note + Vector2(0.0, line * float(i)),
			row,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			MARGIN_SIZE,
			lead
		)
		widest = maxf(
			widest, NotePage.HAND.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, MARGIN_SIZE).x
		)
	var from := note + Vector2(widest * 0.4, line * float(rows.size() - 1) + 10.0)
	var end := signed + Vector2(-8.0, 2.0)
	var bow := Vector2(from.x + 10.0, end.y + 10.0)
	var curve := PackedVector2Array()
	for i: int in 13:
		var t := float(i) / 12.0
		curve.append(from.lerp(bow, t).lerp(bow.lerp(end, t), t))
	canvas.draw_polyline(curve, lead, 1.6, true)
	_head(canvas, curve[curve.size() - 2], end, lead)


## Where the blueprint's title block lies on [param rect]: along its foot, the right of it, with
## room left of it for a pencilled note.
static func blueprint_block(rect: Rect2) -> Rect2:
	return Rect2(
		rect.position + Vector2(rect.size.x * 0.3, rect.size.y * 0.69),
		Vector2(rect.size.x * 0.66, rect.size.y * 0.27)
	)


## A dashed line from [param from] to [param to].
static func _dashed(canvas: CanvasItem, from: Vector2, to: Vector2, ink: Color) -> void:
	canvas.draw_dashed_line(from, to, ink, 1.0, 8.0)


## A line from [param from] with an arrowhead at [param to].
static func _arrow(canvas: CanvasItem, from: Vector2, to: Vector2, ink: Color) -> void:
	canvas.draw_line(from, to, ink, 1.2, true)
	_head(canvas, from, to, ink)


## An open arrowhead at [param tip], pointing away from [param from].
static func _head(canvas: CanvasItem, from: Vector2, tip: Vector2, ink: Color) -> void:
	var back := (from - tip).normalized() * 6.0
	canvas.draw_polyline(
		PackedVector2Array([tip + back.rotated(0.5), tip, tip + back.rotated(-0.5)]), ink, 1.3, true
	)
