class_name AtlasKitScrap
extends Control
## Kit's scrap over the details' slip on his sheet, GAME.md 8.9: a piece of his graph paper torn
## off a pad and taped down over the House's slip, which shows round its edges, what the slip says
## written on it in his hand in pencil, see [LoyaltyPane]. A rule in pencil under its heading in
## the slip's dotted line's place; for a landmark not open yet, his marks over it, see [Later]; and
## how far a bet has come drawn by him too, see [Bar]. It stands in the slip under its words, and
## takes no input.

## How far in from the slip's edges the scrap lies, over the band for the coil at its top and
## clear of the teeth at its foot; how far apart its torn edge's points are and how far they stray.
const IN := Vector2(9.0, 24.0)
const IN_FOOT := 14.0
const TEAR_STEP := 12.0
const TEAR := 2.5
## The paper, and its grid: how far apart its lines are, every how many a firmer one, and their
## inks, the sheet's own.
const PAPER := LoyaltyMapArt.GRAPH_PAPER
const GRID := 12.0
const GRID_FIRM := 5
const GRID_FINE_INK := LoyaltyMapArt.GRAPH_FINE
const GRID_FIRM_INK := LoyaltyMapArt.GRAPH_FIRM
## Its shadow on the slip, the tape over its top, how long and how far right of the middle and
## how turned, and the pencil's rule under the heading, its ink and how far it strays.
const SHADOW := Vector2(1.5, 2.5)
const SHADOW_INK := Color(0.0, 0.0, 0.0, 0.25)
const TAPE := 74.0
const TAPE_RIGHT := 30.0
const TAPE_TURN := -0.12
const RULE_INK := Color(0.22, 0.22, 0.25, 0.5)
const RULE_STRAY := 1.2

## Whether the scrap is on the slip, Kit's sheet's landmark shown.
var showing := false:
	set(on):
		showing = on
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(AtlasCover.PICTURES)
	resized.connect(queue_redraw)


## Where the slip's dotted line runs, from the slip's top, for the rule in its place.
func rule_at(at: float) -> void:
	set_meta(&"rule", at)
	queue_redraw()


func _draw() -> void:
	if not showing:
		return
	var slip := Rect2(-position, get_parent_control().size)
	var area := Rect2(slip.position + IN, slip.size - Vector2(IN.x * 2.0, IN.y + IN_FOOT))
	var edge := _torn(area)
	var fallen := PackedVector2Array()
	for point: Vector2 in edge:
		fallen.append(point + SHADOW)
	draw_colored_polygon(fallen, SHADOW_INK)
	draw_colored_polygon(edge, PAPER)
	_grid(area.grow(-TEAR - 0.5))
	var rule: float = get_meta(&"rule", 0.0)
	if rule > 0.0:
		_rule(slip.position.y + rule, area)
	var tape_at := Vector2(area.get_center().x + TAPE_RIGHT, area.position.y + 2.0)
	AtlasCover.piece(self, AtlasCover.Kind.TAPE, tape_at, TAPE_TURN, TAPE)


## The scrap's outline round [param area], torn: its points straying either way, the same way
## every time.
func _torn(area: Rect2) -> PackedVector2Array:
	var rolls := RandomNumberGenerator.new()
	rolls.seed = 5
	var corners := PackedVector2Array(
		[
			area.position,
			Vector2(area.end.x, area.position.y),
			area.end,
			Vector2(area.position.x, area.end.y)
		]
	)
	var edge := PackedVector2Array()
	for side: int in 4:
		var from := corners[side]
		var to := corners[(side + 1) % 4]
		var out := (to - from).normalized().orthogonal()
		var steps := maxi(int(from.distance_to(to) / TEAR_STEP), 1)
		for i: int in steps:
			edge.append(from.lerp(to, float(i) / steps) + out * rolls.randf_range(-TEAR, TEAR))
	return edge


## The graph paper's grid over [param area], its fine lines in one draw and its firmer in another.
func _grid(area: Rect2) -> void:
	var fine := PackedVector2Array()
	var firm := PackedVector2Array()
	var count := 0
	var x := area.position.x
	while x <= area.end.x:
		var into := firm if count % GRID_FIRM == 0 else fine
		into.append_array(PackedVector2Array([Vector2(x, area.position.y), Vector2(x, area.end.y)]))
		x += GRID
		count += 1
	count = 0
	var y := area.position.y
	while y <= area.end.y:
		var into := firm if count % GRID_FIRM == 0 else fine
		into.append_array(PackedVector2Array([Vector2(area.position.x, y), Vector2(area.end.x, y)]))
		y += GRID
		count += 1
	draw_multiline(fine, GRID_FINE_INK, 1.0)
	draw_multiline(firm, GRID_FIRM_INK, 1.0)


## A rule in pencil across [param area] at [param y], drawn twice over by hand.
func _rule(y: float, area: Rect2) -> void:
	var rolls := RandomNumberGenerator.new()
	rolls.seed = 7
	for again: int in 2:
		var line := PackedVector2Array()
		for i: int in 25:
			var x := lerpf(area.position.x + 5.0, area.end.x - 5.0, i / 24.0)
			line.append(Vector2(x, y + rolls.randf_range(-RULE_STRAY, RULE_STRAY) + again * 0.8))
		draw_polyline(line, Color(RULE_INK, RULE_INK.a * (1.0 - again * 0.4)), 1.4, true)


## Kit's marks over what he wrote of a landmark not open yet: its hidden objective crossed out in
## pencil, and "later" written beside it and gone round with a loop, an arrow from it to the
## objective, as he would leave himself a note. It stands in the slip over its words, and takes
## no input.
class Later:
	extends Control

	## The word, how big and how turned, how far in from the slip's right side its middle is, and
	## the room round it inside its loop; the pencil.
	const WORD := "later"
	const WORD_SIZE := 30
	const WORD_TURN := -0.12
	const WORD_IN := 66.0
	const LOOP_ROOM := Vector2(14.0, 0.62)
	const INK := Color(0.22, 0.22, 0.25, 0.85)
	## How much more than once round the loop goes, and how much it grows as it goes.
	const LOOP_MORE := 8
	const LOOP_GROW := 0.08
	## The line through the objective: how far past its words it runs and how much it bows.
	const STRIKE_PAST := 4.0
	const STRIKE_BOW := 2.5

	## The objective's line it crosses out, and the line beside which it writes "later".
	var over: Label
	var beside: Control
	## Whether it is drawn, a landmark of Kit's not open yet shown.
	var showing := false:
		set(on):
			showing = on
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		over.item_rect_changed.connect(queue_redraw)
		resized.connect(queue_redraw)

	func _draw() -> void:
		if not showing:
			return
		var line := over.get_global_rect()
		line.position -= get_global_rect().position
		var font := over.get_theme_font(&"font")
		var size_of := over.get_theme_font_size(&"font_size")
		var wide := minf(
			font.get_string_size(over.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_of).x, line.size.x
		)
		var y := line.position.y + line.size.y * 0.55
		var from := Vector2(line.position.x - STRIKE_PAST, y)
		var to := Vector2(line.position.x + wide + STRIKE_PAST, y - 1.5)
		_stroke(from, to, 3, 1.6)
		_stroke(from + Vector2(2.0, 3.0), to + Vector2(2.0, 2.5), 53, 1.2)
		var slip_right := get_parent_control().size.x - position.x
		var near := beside.get_global_rect().get_center().y - get_global_rect().position.y
		var at := Vector2(slip_right - WORD_IN, near - 2.0)
		_later(at)
		_arrow(at + Vector2(-50.0, -10.0), Vector2(line.position.x + wide * 0.62, line.end.y - 4.0))

	## A stroke in pencil from [param from] to [param to], bowing a little, the same way every
	## time for [param seed_of].
	func _stroke(from: Vector2, to: Vector2, seed_of: int, wide: float) -> void:
		var rolls := RandomNumberGenerator.new()
		rolls.seed = seed_of
		var bow := rolls.randf_range(-STRIKE_BOW, STRIKE_BOW)
		var across := (to - from).normalized().orthogonal()
		var points := PackedVector2Array()
		for i: int in 19:
			var t := i / 18.0
			var stray := rolls.randf_range(-0.6, 0.6)
			points.append(from.lerp(to, t) + across * (sin(t * PI) * bow + stray))
		draw_polyline(points, INK, wide, true)

	## "later" in Kit's hand round [param at], a loop gone round it a little more than once.
	func _later(at: Vector2) -> void:
		var hand := LoyaltyPane.KIT_HAND
		var wide := hand.get_string_size(WORD, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x
		draw_set_transform(at, WORD_TURN, Vector2.ONE)
		var word_at := Vector2(-wide * 0.5, WORD_SIZE * 0.3)
		draw_string(hand, word_at, WORD, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE, INK)
		var rolls := RandomNumberGenerator.new()
		rolls.seed = 6
		var round_by := Vector2(wide * 0.5 + LOOP_ROOM.x, WORD_SIZE * LOOP_ROOM.y)
		var loop := PackedVector2Array()
		var steps := 64
		for i: int in steps + LOOP_MORE:
			var a := -0.4 + TAU * i / steps
			var grow := 1.0 + LOOP_GROW * i / steps + rolls.randf_range(-0.02, 0.02)
			loop.append(Vector2(cos(a), sin(a)) * round_by * grow)
		draw_polyline(loop, INK, 1.7, true)
		draw_set_transform(Vector2.ZERO)

	## An arrow in pencil from [param from] to [param to], bowed, its head at [param to].
	func _arrow(from: Vector2, to: Vector2) -> void:
		var bend := (from + to) * 0.5 + (to - from).orthogonal().normalized() * 14.0
		var points := PackedVector2Array()
		for i: int in 17:
			var t := i / 16.0
			points.append(from.lerp(bend, t).lerp(bend.lerp(to, t), t))
		draw_polyline(points, INK, 1.5, true)
		var way := (to - points[14]).normalized()
		draw_line(to, to - way.rotated(0.5) * 10.0, INK, 1.5, true)
		draw_line(to, to - way.rotated(-0.5) * 10.0, INK, 1.5, true)


## How far one of Kit's bets has come, drawn by him in pencil, see [method ProgressBar]: as the
## track, a box sketched twice over, its corners overshot; as the fill, hatching up to as far as
## it has come.
class Bar:
	extends StyleBox

	## How far the box's lines stray, how far past its corners they run, and the pencil; how far
	## apart the hatching's strokes are, how far each leans, and how far they stray.
	const STRAY := 1.1
	const OVERSHOOT := 3.0
	const INK := Color(0.22, 0.22, 0.25, 0.8)
	const HATCH := 5.0
	const LEAN := 6.0
	const HATCH_STRAY := 0.8

	## Whether it is the fill, hatched, or the track, a box.
	var fill := false

	func _draw(item: RID, rect: Rect2) -> void:
		var rolls := RandomNumberGenerator.new()
		rolls.seed = 11
		if fill:
			_hatch(item, rect, rolls)
		else:
			for again: int in 2:
				_box(item, rect.grow(-0.5 + again * 0.6), rolls, 1.3 - again * 0.4)

	## The box round [param rect], each side a stroke of its own run a little past the corners.
	func _box(item: RID, rect: Rect2, rolls: RandomNumberGenerator, wide: float) -> void:
		var corners := PackedVector2Array(
			[
				rect.position,
				Vector2(rect.end.x, rect.position.y),
				rect.end,
				Vector2(rect.position.x, rect.end.y),
			]
		)
		var strokes := PackedVector2Array()
		for side: int in 4:
			var from := corners[side]
			var to := corners[(side + 1) % 4]
			var way := (to - from).normalized()
			var jog := way.orthogonal() * rolls.randf_range(-STRAY, STRAY)
			strokes.append(from - way * rolls.randf_range(0.0, OVERSHOOT) + jog)
			strokes.append(to + way * rolls.randf_range(0.0, OVERSHOOT) - jog)
		RenderingServer.canvas_item_add_multiline(
			item, strokes, PackedColorArray([INK]), wide, true
		)

	## Hatching across [param rect], strokes leaning up to the right, each a little off its place.
	func _hatch(item: RID, rect: Rect2, rolls: RandomNumberGenerator) -> void:
		var strokes := PackedVector2Array()
		var x := rect.position.x - LEAN
		while x < rect.end.x:
			var from := Vector2(x + rolls.randf_range(-HATCH_STRAY, HATCH_STRAY), rect.end.y)
			var to := Vector2(from.x + LEAN, rect.position.y)
			# Kept inside the rect, cut where it leaves it at either side.
			var cut_from := clampf((rect.position.x - from.x) / LEAN, 0.0, 1.0)
			var cut_to := clampf((rect.end.x - from.x) / LEAN, 0.0, 1.0)
			if cut_to > cut_from:
				strokes.append(from.lerp(to, cut_from))
				strokes.append(from.lerp(to, cut_to))
			x += HATCH
		if not strokes.is_empty():
			RenderingServer.canvas_item_add_multiline(
				item, strokes, PackedColorArray([INK]), 1.3, true
			)
