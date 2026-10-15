class_name ProofArt
extends RefCounted
## The press proof the catalog is dressed as, GAME.md 8.8: the House prints its cards, and the
## catalog is the profile's proof sheet of them, a card printed on it once it was taken and only
## the line its die would cut it along until then, see [DieLine].
##
## The pane is a charcoal cutting mat, its grid printed faint over it and a ruler's marks along its
## top. The page's cards lie on a sheet of the House's card stock, the other page's sheet under it
## a little up and along; the sheet's margins carry the printer's marks, a color bar of the cards'
## inks and the press's, and in its foot the job's line and the story's motto. On the mat in the
## foot lie a steel rule, a fan of ink swatches spilling off the mat's edge and an open tin of the
## House's gold. Over the column, a loupe on the large card, a bulldog clip on the spec sheet and
## the printer's job ticket; round the first card taken, the pressman's grease pencil.
## [ProofCover] draws the mat and the sheet once into a picture, and each thing over them once.

## The mat, how round its corners are, and how far past the screen's edges it runs where the pane
## fills the screen.
const MAT := Color("#23282c")
const MAT_ROUND := 12.0
const PAST := 14.0
## The mat's printed grid: its ink, how far apart its lines are, how far in from the mat's edge it
## stops, how strong a line is and every fifth one; and the ruler's marks along the mat's top.
const GRID_INK := Color(0.86, 0.92, 0.82)
const GRID := 32.0
const GRID_IN := 14.0
const GRID_LINE := 0.06
const GRID_HEAVY := 0.13
const TICK := 0.45
## The sheets: the House's card stock, and the one under it a shade darker, up from the sheet's top
## and out past its right edge by this much.
const PAPER := HouseTheme.PAPER
const UNDER := 0.12
const UNDER_UP := 7.0
const UNDER_OUT := 9.0
## The printer's ink, the marks' strength, the registration targets' size, and how far the crop
## marks stand off the cards and how long they are.
const INK := HouseTheme.INK
const MARKS := 0.75
const TARGET := 8.0
const CROP_OFF := 3.0
const CROP_LONG := 11.0
## The color bar along the sheet's head: how big each swatch is and how far in from the sheet's
## right edge the bar ends.
const SWATCH := Vector2(16.0, 10.0)
const BAR_IN := 40.0
## The job's line and the motto in the sheet's foot: their size and how far in from its edges.
const SLUG_SIZE := 10
const SLUG_IN := 40.0
## The die's magenta a card not printed yet is outlined in, its dashes, and the question mark's ink.
const DIE := Color("#d6337a")
const DIE_DASH := 9.0
const DIE_GAP := 6.0
const DIE_MARK := Color(HouseTheme.INK, 0.12)
## The pressman's grease pencil round the first card taken, in red, the one taken most and the
## joker that went off most, in pencils of their own: how far out round the card a loop goes, as
## a share of the card, and the words beside it for each, a line each, and their size. All of it
## stays within the room round a card, so a card in the grid's top row or at either end of a row
## is not cut off at the grid's edge.
const GREASE := HouseTheme.STAMP_RED
## The pressman's other grease pencils: blue for the card taken most, green for the joker that
## went off most, so each reason reads at a glance and a card with two has two loops.
const GREASE_BLUE := Color("#2d5fb8")
const GREASE_GREEN := Color("#2c8a4a")
const RING_OUT := Vector2(0.6, 0.56)
const RING_FIRST := "1st!"
const RING_MOST := "Fave!"
const RING_BEST := "MVP!"
const RING_WORDS_SIZE := 22
## The steel rule in the foot: how tall, and how long at the most and the least.
const RULE_TALL := 28.0
const RULE_LONG := 620.0
const RULE_LEAST := 300.0
## The swatch fan: how long and wide a strip is, how many tints each shows, the way the first
## strip points, how far each next one turns, down off the mat, and the inks, the cards' first.
const FAN_LONG := 190.0
const FAN_WIDE := 30.0
const FAN_TINTS := 5
const FAN_FROM := 0.14
const FAN_STEP := 0.105
## The tin of the House's gold, as big as it is across, and how far its lid lies beside it.
const TIN := 42.0
const LID_BESIDE := 92.0
## The loupe: how far its bezel is out from the large card's ring, how thick, the way its handle
## points, up and to the right, and how long its collar and its wood are.
const LOUPE_OUT := 6.0
const LOUPE_RIM := 12.0
const HANDLE_TOWARD := -0.384
const COLLAR := 24.0
const HANDLE_LONG := 128.0
## The handle's wood, and the steel and brass.
const WOOD := Color("#6e3d1f")
const CHROME := Color("#c3c8cf")
const CHROME_HIGH := Color("#f4f6f9")
const CHROME_LOW := Color("#5b6068")
## The stamp across the sheet's head while it shows one suit's cards alone, GAME.md 8.8: how big
## its words are, how tall it is and how far it is turned.
const STAMP_SIZE := 17
const STAMP_TALL := 26.0
const STAMP_TURN := -0.025
## The little card of the large card's suit lying under the loupe's bezel at its lower left, as
## one slid under the glass: how big, how far round the bezel and how far it is turned.
const SUIT_CARD := Vector2(40.0, 56.0)
const SUIT_CARD_AT := PI * 0.78
const SUIT_CARD_TURN := -0.32
const BRASS := Color("#c9a24a")
const BRASS_HIGH := Color("#f6dc93")
const BRASS_LOW := Color("#6e5220")
## The job ticket: its paper, the band across its head, its words' size, and how far it is turned.
const TICKET := Color("#efe2bf")
const TICKET_SIZE := Vector2(340.0, 150.0)
const TICKET_HEAD := 28.0
const TICKET_WORDS := 13
const TICKET_TURN := -0.044
const TICKET_SIGNED := "OK -H."
## The jokers' page's ticket, the pay table of the hands: its head, how tall a line is and how big
## a line's cards.
const PAY_TABLE := "PAY TABLE  ·  HANDS"
const PAY_ROW := 19.0
const PAY_CARD := Vector2(9.0, 13.0)
## The fonts the job ticket is typed in and the pressman writes in.
const TYPED: Font = preload("res://assets/fonts/CourierPrime-Regular.ttf")
const MARKER: Font = preload("res://assets/fonts/PermanentMarker-Regular.ttf")
## The shadow under the mat, under what lies on it, and how dark.
const SHADOW := 18
const FALL := Vector2(3.0, 5.0)
const FALLEN := Color(0.0, 0.0, 0.0, 0.4)


## Where the things in the mat's foot lie, in the pane's own room: the steel rule's rect, the tin's
## middle and the swatch fan's rivet, a size or a point of nothing leaving each out.
class Places:
	var rule := Rect2()
	var tin := Vector2.ZERO
	var fan := Vector2.ZERO

	## The places as words, rounded, for the picture of the mat to be known by them.
	func key() -> String:
		return "%s|%s" % [Rect2(rule.position.round(), rule.size.round()), tin.round()]


## The mat over [param rect], the pane's, on [param on]; the sheet over [param sheet] and the one
## under it; and what lies in the foot at [param places]. [param short] where the pane fills the
## screen: the mat a little past its edges, square, its corners off the screen. The same for
## either page: what the sheet says in its foot is the page's, see [method foot_line].
static func mat(on: CanvasItem, rect: Rect2, sheet: Rect2, places: Places, short: bool) -> void:
	var board := rect.grow(PAST) if short else rect
	var shape := FeltArt.rounded(board, 0.0 if short else MAT_ROUND)
	if not short:
		_shadow(on, board)
	on.draw_colored_polygon(shape, MAT)
	on.draw_colored_polygon(
		shape, Color(1.0, 1.0, 1.0, 0.04), _tiled(shape, 160.0), FeltArt.grain()
	)
	on.draw_colored_polygon(
		shape, Color(0.0, 0.0, 0.0, 0.16), _tiled(shape, 400.0), FeltArt.patches()
	)
	if not short:
		var rim := shape.duplicate()
		rim.append(rim[0])
		on.draw_polyline(rim, Color(1.0, 1.0, 1.0, 0.14), 1.0, true)
	_grid(on, rect.grow(-GRID_IN))
	if sheet.has_area():
		_sheets(on, sheet, short)
	if places.rule.has_area():
		steel_rule(on, places.rule)
	if places.tin != Vector2.ZERO:
		ink_tin(on, places.tin)


## The cutting mat's grid over [param inside], a line every [constant GRID], every fifth heavier and
## numbered along the top, the ruler's ticks along the mat's top and left edges outside it.
static func _grid(on: CanvasItem, inside: Rect2) -> void:
	var lines := PackedVector2Array()
	var heavy := PackedVector2Array()
	var ticks := PackedVector2Array()
	var count := 1
	var x := inside.position.x + GRID
	while x < inside.end.x:
		var five := count % 5 == 0
		(heavy if five else lines).append_array(
			[Vector2(x, inside.position.y), Vector2(x, inside.end.y)]
		)
		var top := inside.position.y - GRID_IN
		ticks.append_array([Vector2(x, top + 4.0), Vector2(x, top + (10.0 if five else 7.0))])
		if five:
			on.draw_string(
				Type.micro_font(),
				Vector2(x + 2.0, top + 12.0),
				str(count),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				9,
				Color(GRID_INK, 0.5)
			)
		x += GRID
		count += 1
	count = 1
	var y := inside.position.y + GRID
	while y < inside.end.y:
		var five := count % 5 == 0
		(heavy if five else lines).append_array(
			[Vector2(inside.position.x, y), Vector2(inside.end.x, y)]
		)
		var left := inside.position.x - GRID_IN
		ticks.append_array([Vector2(left + 4.0, y), Vector2(left + (10.0 if five else 7.0), y)])
		y += GRID
		count += 1
	on.draw_multiline(lines, Color(GRID_INK, GRID_LINE), 1.0)
	on.draw_multiline(heavy, Color(GRID_INK, GRID_HEAVY), 1.0)
	on.draw_multiline(ticks, Color(GRID_INK, TICK), 1.0)


## The sheet over [param sheet] and the other page's under it, the color bar along its head and
## the registration targets in its margins. A short screen's sheet has narrower margins, and
## neither the color bar nor the target at its head, which the crop marks would cross.
static func _sheets(on: CanvasItem, sheet: Rect2, short: bool) -> void:
	var under := Rect2(
		sheet.position - Vector2(0.0, UNDER_UP), sheet.size + Vector2(UNDER_OUT, UNDER_UP)
	)
	_paper(on, under, PAPER.darkened(UNDER))
	_paper(on, sheet, PAPER)
	var swatches: Array[Color] = [
		JokerCard.RARITY_COLORS[Joker.Rarity.COMMON],
		Palette.NEON_CYAN,
		Palette.NEON_MAGENTA,
		HouseTheme.FOIL,
		JokerCard.DOOMED,
		Color("#00a3e0"),
		Color("#e0007a"),
		Color("#ffe100"),
		Color("#111111"),
		Color(0.07, 0.07, 0.07, 0.75),
		Color(0.07, 0.07, 0.07, 0.5),
		Color(0.07, 0.07, 0.07, 0.25),
	]
	var ink := Color(INK, MARKS)
	if not short:
		var bar := Vector2(
			sheet.end.x - BAR_IN - swatches.size() * (SWATCH.x + 1.0), sheet.position.y + 6.0
		)
		for i: int in swatches.size():
			on.draw_rect(Rect2(bar + Vector2(i * (SWATCH.x + 1.0), 0.0), SWATCH), swatches[i])
		var framed := Rect2(
			bar - Vector2.ONE, Vector2(swatches.size() * (SWATCH.x + 1.0) + 1.0, 12.0)
		)
		on.draw_rect(framed, Color(INK, 0.5), false, 1.0)
		target(on, Vector2(sheet.position.x + 60.0, sheet.position.y + 13.0), ink)
	target(on, Vector2(sheet.position.x + 13.0, sheet.get_center().y), ink)
	target(on, Vector2(sheet.end.x - 13.0, sheet.get_center().y), ink)


## What the sheet over [param sheet] says in its foot: the page's job line [param slug] on its left
## and the story's [param motto] on its right, the motto alone where the two would run into each
## other.
static func foot_line(on: CanvasItem, sheet: Rect2, slug: String, motto: String) -> void:
	var ink := Color(INK, MARKS)
	var font := Type.micro_font()
	var foot := sheet.end.y - 9.0
	var wide := font.get_string_size(motto, HORIZONTAL_ALIGNMENT_LEFT, -1, SLUG_SIZE).x
	var slug_wide := font.get_string_size(slug, HORIZONTAL_ALIGNMENT_LEFT, -1, SLUG_SIZE).x
	if slug_wide + wide + SLUG_IN * 3.0 <= sheet.size.x:
		on.draw_string(
			font,
			Vector2(sheet.position.x + SLUG_IN, foot),
			slug,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			SLUG_SIZE,
			ink
		)
	on.draw_string(
		font,
		Vector2(sheet.end.x - SLUG_IN - wide, foot),
		motto,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		SLUG_SIZE,
		ink
	)


## A sheet of card stock over [param rect] in [param paper], its shadow on the mat, a little
## mottled.
static func _paper(on: CanvasItem, rect: Rect2, paper: Color) -> void:
	var shape := _corners(rect)
	on.draw_colored_polygon(_moved(shape, FALL), FALLEN)
	on.draw_colored_polygon(shape, paper)
	on.draw_colored_polygon(
		shape, Color(0.0, 0.0, 0.0, 0.05), _tiled(shape, 220.0), FeltArt.patches()
	)
	on.draw_colored_polygon(
		shape, Color(0.4, 0.3, 0.2, 0.05), _tiled(shape, 120.0), FeltArt.grain()
	)


## A registration target at [param at]: a ring, its cross, and two of its quarters filled.
static func target(on: CanvasItem, at: Vector2, ink: Color) -> void:
	on.draw_arc(at, TARGET * 0.62, 0.0, TAU, 32, ink, 1.0, true)
	on.draw_line(at - Vector2(TARGET, 0.0), at + Vector2(TARGET, 0.0), ink, 1.0)
	on.draw_line(at - Vector2(0.0, TARGET), at + Vector2(0.0, TARGET), ink, 1.0)
	on.draw_arc(at, TARGET * 0.3, 0.0, PI * 0.5, 8, ink, TARGET * 0.3)
	on.draw_arc(at, TARGET * 0.3, PI, PI * 1.5, 8, ink, TARGET * 0.3)


## The crop marks in the sheet's margins round [param shown], the part of the sheet the cards show
## in: at [param across], the cards' left and right edges, over and under it, and at [param down],
## the edges of the rows showing, either side of it.
static func crop_marks(
	on: CanvasItem, shown: Rect2, across: PackedFloat32Array, down: PackedFloat32Array
) -> void:
	var marks := PackedVector2Array()
	for x: float in across:
		var at := roundf(x) + 0.5
		(
			marks
			. append_array(
				[
					Vector2(at, shown.position.y - CROP_OFF - CROP_LONG),
					Vector2(at, shown.position.y - CROP_OFF),
					Vector2(at, shown.end.y + CROP_OFF),
					Vector2(at, shown.end.y + CROP_OFF + CROP_LONG),
				]
			)
		)
	for y: float in down:
		var at := roundf(y) + 0.5
		(
			marks
			. append_array(
				[
					Vector2(shown.position.x - CROP_OFF - CROP_LONG, at),
					Vector2(shown.position.x - CROP_OFF, at),
					Vector2(shown.end.x + CROP_OFF, at),
					Vector2(shown.end.x + CROP_OFF + CROP_LONG, at),
				]
			)
		)
	if not marks.is_empty():
		on.draw_multiline(marks, Color(INK, MARKS), 1.0)


## A card not printed yet over [param rect]: its die line, dashed in the die's magenta round the
## card's own round corners, and a faint question mark where its face would be.
static func die_line(on: CanvasItem, rect: Rect2) -> void:
	var line := FeltArt.rounded(rect.grow(-2.0), 7.0)
	line.append(line[0])
	on.draw_multiline(LeatherArt.dashes(line, DIE_DASH, DIE_GAP), Color(DIE, 0.8), 1.5)
	var font := Type.display_font()
	var size := int(rect.size.y * 0.34)
	var wide := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := rect.get_center().y + size * Type.CAP_HEIGHT * 0.5
	on.draw_string(
		font,
		Vector2(rect.get_center().x - wide * 0.5, base),
		"?",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		DIE_MARK
	)


## The pressman's grease pencil round the card over [param rect]: a loop that does not quite close,
## a little more than once round, and beside it [param words], why, a line each, on its right, or on
## its left where [param left] says the card ends its row and there is no room on its right.
static func grease_ring(
	on: CanvasItem, rect: Rect2, left := false, words := PackedStringArray([RING_FIRST])
) -> void:
	var reach := rect.size * RING_OUT
	# A loop in each reason's pencil, each started somewhere else round and a little further out,
	# as a second pencil round the same card would.
	for mark: int in words.size():
		var loop := PackedVector2Array()
		var start := -2.2 + mark * 1.9
		var out := 1.0 + mark * 0.06
		for i: int in 70:
			var turn := start + TAU * 1.08 * i / 69.0
			var wobble := 1.0 + 0.04 * sin(turn * 3.0 + mark)
			loop.append(rect.get_center() + Vector2(cos(turn), sin(turn)) * reach * wobble * out)
			loop[i].y += i * 0.08
		on.draw_polyline(loop, Color(grease_of(words[mark]), 0.85), 3.0, true)
	var size := RING_WORDS_SIZE
	for line: int in words.size():
		var wide := MARKER.get_string_size(words[line], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var at := rect.get_center() + Vector2(reach.x * 0.9, -reach.y * 0.5 + line * size * 0.95)
		if left:
			at.x = rect.get_center().x - reach.x * 0.9 - wide
		on.draw_set_transform(at, -0.16, Vector2.ONE)
		on.draw_string(
			MARKER,
			Vector2.ZERO,
			words[line],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			size,
			Color(grease_of(words[line]), 0.9)
		)
	on.draw_set_transform(Vector2.ZERO)


## The pencil a reason for a ring is written in: red for the first found, blue for the one taken
## most, green for the joker that went off most.
static func grease_of(word: String) -> Color:
	match word:
		RING_MOST:
			return GREASE_BLUE
		RING_BEST:
			return GREASE_GREEN
	return GREASE


## A steel rule over [param rect]: brushed, lit along its top, a tick every few pixels, longer each
## fifth and tenth, its numbers and the House's name stamped along its foot.
static func steel_rule(on: CanvasItem, rect: Rect2) -> void:
	on.draw_colored_polygon(_moved(_corners(rect), FALL), FALLEN)
	on.draw_polygon(
		_corners(rect),
		PackedColorArray([CHROME_HIGH, CHROME, CHROME_LOW.lightened(0.3), CHROME.darkened(0.1)])
	)
	on.draw_line(
		rect.position + Vector2(0.0, 1.0),
		Vector2(rect.end.x, rect.position.y + 1.0),
		Color(1.0, 1.0, 1.0, 0.8),
		1.0
	)
	var ink := Color(0.15, 0.15, 0.17)
	var words := "THE HOUSE  ·  STAINLESS"
	var font := Type.micro_font()
	var named := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	var ticks := PackedVector2Array()
	for i: int in int(rect.size.x / 6.0):
		var x := rect.position.x + 6.0 + i * 6.0
		var long := 9.0 if i % 10 == 9 else (6.0 if i % 5 == 4 else 3.5)
		ticks.append_array(
			[Vector2(x, rect.position.y + 1.0), Vector2(x, rect.position.y + 1.0 + long)]
		)
		if i % 10 == 9 and x < rect.end.x - named - 20.0:
			on.draw_string(
				font,
				Vector2(x - 3.0, rect.end.y - 4.0),
				str((i + 1) / 10),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				9,
				ink
			)
	on.draw_multiline(ticks, Color(ink, 0.85), 1.0)
	on.draw_string(
		font,
		Vector2(rect.end.x - named - 8.0, rect.end.y - 4.0),
		words,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		9,
		Color(ink, 0.7)
	)


## An open tin of the House's gold at [param middle]: its lid lying beside it, label up, and the
## ink in it swirled where the knife was, a drip down its side.
static func ink_tin(on: CanvasItem, middle: Vector2) -> void:
	var lid := middle + Vector2(LID_BESIDE, 6.0)
	on.draw_circle(lid + FALL, TIN, FALLEN)
	on.draw_circle(lid, TIN, CHROME_LOW)
	on.draw_circle(lid, TIN - 3.0, CHROME)
	on.draw_circle(lid, TIN - 9.0, Color("#1c1a22"))
	_centered(on, lid + Vector2(0.0, -10.0), "HOUSE GOLD", 12, HouseTheme.FOIL, Type.display_font())
	_centered(on, lid + Vector2(0.0, 6.0), "OFFSET INK", 8, Color(1.0, 1.0, 1.0, 0.7))
	_centered(on, lid + Vector2(0.0, 18.0), "1 KG", 8, Color(1.0, 1.0, 1.0, 0.7))
	on.draw_arc(lid, TIN - 1.5, PI * 1.1, PI * 1.6, 16, CHROME_HIGH, 2.0, true)
	var gold := HouseTheme.FOIL.darkened(0.15)
	on.draw_circle(middle + FALL, TIN + 2.0, FALLEN)
	on.draw_circle(middle, TIN + 2.0, CHROME_LOW)
	on.draw_circle(middle, TIN, CHROME)
	on.draw_circle(middle, TIN - 4.0, gold)
	for k: int in 4:
		var swirl := PackedVector2Array()
		for i: int in 24:
			swirl.append(
				middle + Vector2.from_angle(k * 1.4 + i * 0.22) * (6.0 + i * 1.2 + k * 2.0)
			)
		on.draw_polyline(swirl, Color(1.0, 0.95, 0.7, 0.35), 2.0, true)
	on.draw_arc(middle, TIN - 1.0, PI * 1.05, PI * 1.6, 16, CHROME_HIGH, 2.0, true)
	on.draw_line(
		middle + Vector2(TIN - 2.0, 4.0), middle + Vector2(TIN + 1.0, 18.0), gold, 4.0, true
	)


## A fan of ink swatches riveted at the origin of [param base], the transform [param on] is drawn
## with, open down and to the right: a strip for each of the cards' inks and the press's, each a
## run of that ink's tints and its number.
static func swatch_fan(on: CanvasItem, base: Transform2D) -> void:
	var inks: Array[Color] = [
		Color("#111111"),
		JokerCard.DOOMED,
		HouseTheme.FOIL,
		Palette.NEON_MAGENTA,
		Palette.NEON_CYAN,
		JokerCard.RARITY_COLORS[Joker.Rarity.COMMON],
		Color("#2f7a4a"),
	]
	for k: int in inks.size():
		on.draw_set_transform_matrix(base * Transform2D(FAN_FROM + k * FAN_STEP, Vector2.ZERO))
		var strip := Rect2(Vector2(-10.0, -FAN_WIDE * 0.5), Vector2(FAN_LONG, FAN_WIDE))
		on.draw_rect(
			Rect2(strip.position + Vector2(2.0, 4.0), strip.size), Color(0.0, 0.0, 0.0, 0.3)
		)
		on.draw_rect(strip, Color("#f6f3ea"))
		on.draw_rect(strip, Color(0.0, 0.0, 0.0, 0.15), false, 1.0)
		var step := (FAN_LONG - 40.0) / FAN_TINTS
		for i: int in FAN_TINTS:
			var tint := Color.WHITE.lerp(inks[k], 1.0 - i * 0.14)
			on.draw_rect(
				Rect2(
					Vector2(strip.position.x + 34.0 + i * step, strip.position.y + 4.0),
					Vector2(step - 2.0, FAN_WIDE - 8.0)
				),
				tint
			)
		on.draw_string(
			Type.micro_font(),
			Vector2(strip.position.x + 13.0, 3.0),
			str(7400 + k * 3),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			7,
			Color(INK, 0.7)
		)
	on.draw_set_transform_matrix(base)
	on.draw_circle(Vector2(1.0, 2.0), 6.0, FALLEN)
	on.draw_circle(Vector2.ZERO, 6.0, CHROME_LOW)
	on.draw_circle(-Vector2.ONE, 4.0, CHROME)
	on.draw_circle(-Vector2.ONE * 2.0, 1.5, CHROME_HIGH)


## How far the swatch fan reaches from its rivet: right, and down past it.
static func fan_reach() -> Rect2:
	var reach := Rect2(Vector2(-16.0, -FAN_WIDE), Vector2.ZERO)
	for k: int in 7:
		var way := Vector2.from_angle(FAN_FROM + k * FAN_STEP)
		var across := Vector2(-way.y, way.x) * FAN_WIDE * 0.5
		for point: Vector2 in [way * FAN_LONG + across, way * FAN_LONG - across]:
			reach = reach.expand(point)
	return reach.grow(6.0)


## A loupe over a picture round the origin of [param base], the transform [param on] is drawn with,
## its glass [param reach] across from its middle: the print's dots under it, a chrome bezel with a
## glint, and its turned handle up and to the right.
static func loupe(on: CanvasItem, reach: float, base: Transform2D) -> void:
	on.draw_set_transform_matrix(base)
	var middle := Vector2.ZERO
	var step := 7.0
	var dots := 0
	var y := middle.y - reach
	while y < middle.y + reach:
		var x := middle.x - reach + (step * 0.5 if dots % 2 == 1 else 0.0)
		while x < middle.x + reach:
			if Vector2(x, y).distance_to(middle) < reach - 10.0:
				on.draw_circle(Vector2(x, y), 1.3, Color(0.0, 0.0, 0.0, 0.16))
			x += step
		y += step * 0.87
		dots += 1
	_handle(on, middle, reach + LOUPE_OUT + 6.0)
	var bezel := reach + LOUPE_OUT
	on.draw_arc(middle + FALL, bezel, 0.0, TAU, 72, Color(0.0, 0.0, 0.0, 0.35), 8.0, true)
	on.draw_arc(middle, bezel, 0.0, TAU, 72, CHROME_LOW, LOUPE_RIM, true)
	on.draw_arc(middle, bezel, PI * 0.95, PI * 1.75, 40, CHROME_HIGH, 4.0, true)
	on.draw_arc(middle, reach + 1.0, 0.0, TAU, 72, Color(0.0, 0.0, 0.0, 0.5), 1.5, true)
	on.draw_arc(middle, reach - 14.0, PI * 1.1, PI * 1.45, 24, Color(1.0, 1.0, 1.0, 0.4), 5.0, true)
	on.draw_arc(
		middle, reach - 10.0, PI * 0.12, PI * 0.3, 10, Color(1.0, 1.0, 1.0, 0.18), 3.0, true
	)
	var at := Vector2.from_angle(PI * 0.25) * bezel
	on.draw_set_transform_matrix(base * Transform2D(-PI * 0.25, at))
	_centered(on, Vector2.ZERO, "10×", 10, Color(INK, 0.9))
	on.draw_set_transform_matrix(base)


## How far the loupe reaches round its middle, its glass [param reach] across: the bezel all round
## and its handle up and to the right.
static func loupe_reach(reach: float) -> Rect2:
	var bezel := reach + LOUPE_OUT + LOUPE_RIM
	var whole := Rect2(-Vector2.ONE * bezel, Vector2.ONE * bezel * 2.0)
	var tip := Vector2.from_angle(HANDLE_TOWARD) * (reach + LOUPE_OUT + COLLAR + HANDLE_LONG + 16.0)
	return whole.expand(tip + Vector2(14.0, -14.0)).expand(tip + Vector2(14.0, 14.0)).grow(8.0)


## The loupe's handle out of its bezel [param from] out from [param middle]: a ridged brass collar,
## then turned wood swelling to a grip, a waist, a brass band and a round end, lit along its top
## and shaded along its foot.
static func _handle(on: CanvasItem, middle: Vector2, from: float) -> void:
	var along := Vector2.from_angle(HANDLE_TOWARD)
	var across := Vector2(-along.y, along.x)
	var start := middle + along * (from - 8.0)
	var wood_from := start + along * COLLAR
	var steps := 40
	var top := PackedVector2Array()
	var low := PackedVector2Array()
	var halves := PackedFloat32Array()
	for k: int in steps + 1:
		var t := float(k) / steps
		halves.append(_handle_half(t))
		top.append(wood_from + along * HANDLE_LONG * t - across * halves[k])
		low.append(wood_from + along * HANDLE_LONG * t + across * halves[k])
	var end := wood_from + along * HANDLE_LONG
	var shape := top.duplicate()
	for k: int in 13:
		shape.append(
			end + Vector2.from_angle(HANDLE_TOWARD - PI * 0.5 + PI * k / 12.0) * halves[steps]
		)
	low.reverse()
	shape.append_array(low)
	low.reverse()
	on.draw_colored_polygon(_moved(shape, Vector2(5.0, 8.0)), Color(0.0, 0.0, 0.0, 0.32))
	on.draw_colored_polygon(shape, WOOD)
	for band: Array in [
		[0.55, 1.0, Color(0.18, 0.08, 0.03, 0.55)],
		[0.2, 0.55, Color(0.18, 0.08, 0.03, 0.22)],
		[-0.75, -0.35, Color(1.0, 0.78, 0.55, 0.22)],
		[-0.62, -0.48, Color(1.0, 0.9, 0.75, 0.35)],
	]:
		var strip := PackedVector2Array()
		var back := PackedVector2Array()
		for k: int in steps + 1:
			var at := wood_from + along * HANDLE_LONG * float(k) / steps
			strip.append(at + across * halves[k] * (band[0] as float))
			back.append(at + across * halves[k] * (band[1] as float))
		back.reverse()
		strip.append_array(back)
		on.draw_colored_polygon(strip, band[2])
	var rolls := RandomNumberGenerator.new()
	rolls.seed = 31
	for g: int in 7:
		var off := rolls.randf_range(-0.8, 0.8)
		var grain := PackedVector2Array()
		for k: int in range(2, steps - 1):
			var t := float(k) / steps
			var wave := sin(t * 9.0 + g * 1.7) * 0.06
			grain.append(wood_from + along * HANDLE_LONG * t + across * halves[k] * (off + wave))
		on.draw_polyline(grain, Color(0.15, 0.06, 0.02, 0.28), 1.0, true)
	var band_at := wood_from + along * HANDLE_LONG * 0.8
	var band_half := _handle_half(0.8) + 1.5
	(
		on
		. draw_polygon(
			PackedVector2Array(
				[
					band_at - across * band_half - along * 4.0,
					band_at - across * band_half + along * 4.0,
					band_at + across * band_half + along * 4.0,
					band_at + across * band_half - along * 4.0,
				]
			),
			PackedColorArray([BRASS_HIGH, BRASS_HIGH, BRASS_LOW, BRASS_LOW])
		)
	)
	var collar := PackedVector2Array(
		[
			start - across * 8.0,
			wood_from - across * 9.5,
			wood_from + across * 9.5,
			start + across * 8.0
		]
	)
	on.draw_colored_polygon(_moved(collar, Vector2(4.0, 6.0)), Color(0.0, 0.0, 0.0, 0.32))
	on.draw_polygon(collar, PackedColorArray([BRASS_HIGH, BRASS_HIGH, BRASS_LOW, BRASS_LOW]))
	for k: int in 4:
		var at := start + along * (5.0 + k * 5.0)
		var half := lerpf(8.0, 9.5, (5.0 + k * 5.0) / COLLAR)
		on.draw_line(at - across * half, at + across * half, Color(BRASS_LOW, 0.9), 1.2, true)


## Half the handle's width [param t] of the way along its wood: a neck out of the collar, the grip
## swelling a third along, a waist, then its end swelling a little again to its round tip.
static func _handle_half(t: float) -> float:
	if t < 0.35:
		return lerpf(7.5, 13.0, sin(t / 0.35 * PI * 0.5))
	if t < 0.7:
		return lerpf(13.0, 9.0, 0.5 - 0.5 * cos((t - 0.35) / 0.35 * PI))
	return lerpf(9.0, 10.5, sin((t - 0.7) / 0.3 * PI * 0.5))


## The pay table of the hands, GAME.md 7.3, typed on a ticket round the origin of [param base], the
## transform [param on] is drawn with, as the job ticket is: its head, and a line for every hand,
## its cards fanned, its name and in short what it pays.
static func pay_ticket(on: CanvasItem, base: Transform2D) -> void:
	var turned := base * Transform2D(TICKET_TURN, Vector2.ZERO)
	on.draw_set_transform_matrix(turned)
	var card := Rect2(-TICKET_SIZE * 0.5, TICKET_SIZE)
	on.draw_rect(Rect2(card.position + Vector2(3.0, 5.0), card.size), FALLEN)
	on.draw_rect(card, TICKET)
	on.draw_rect(Rect2(card.position, Vector2(card.size.x, TICKET_HEAD)), INK)
	var head := card.position + Vector2(12.0, 20.0)
	on.draw_string(TYPED, head, PAY_TABLE, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, TICKET)
	for hand: int in JokerHands.Hand.size():
		var y := card.position.y + TICKET_HEAD + 13.0 + hand * PAY_ROW
		HandsArt.fan(
			on, Vector2(card.position.x + 12.0, y), JokerHands.SHOWN[hand], PAY_CARD, turned
		)
		on.draw_set_transform_matrix(turned)
		var at := Vector2(card.position.x + 70.0, y + 4.0)
		var named := JokerHands.name_of(hand).to_upper()
		on.draw_string(TYPED, at, named, HORIZONTAL_ALIGNMENT_LEFT, -1, TICKET_WORDS - 1, INK)
		var pays := Vector2(card.position.x + 190.0, y + 4.0)
		var short_pay := JokerHands.SHORT[hand]
		on.draw_string(TYPED, pays, short_pay, HORIZONTAL_ALIGNMENT_LEFT, -1, TICKET_WORDS - 1, INK)
	on.draw_set_transform_matrix(base)


## The little card of [param suit] round the origin of [param base], the transform [param on] is
## drawn with: cream, the suit in the House's ink of it, a shadow under it.
static func suit_card(on: CanvasItem, suit: int, base: Transform2D) -> void:
	on.draw_set_transform_matrix(base * Transform2D(SUIT_CARD_TURN, Vector2.ZERO))
	var face := StyleBoxFlat.new()
	face.set_corner_radius_all(5)
	face.anti_aliasing = true
	face.bg_color = HouseTheme.PAPER
	face.set_border_width_all(1)
	face.border_color = Color(0.0, 0.0, 0.0, 0.5)
	face.shadow_color = FALLEN
	face.shadow_size = 5
	face.shadow_offset = Vector2(2.0, 3.0)
	on.draw_style_box(face, Rect2(-SUIT_CARD * 0.5, SUIT_CARD))
	var side := SUIT_CARD.x * 0.65
	JokerSuits.draw_mark(on, Rect2(-Vector2.ONE * side * 0.5, Vector2.ONE * side), suit, true)
	on.draw_set_transform_matrix(base)


## The stamp of a sheet showing [param suit]'s cards alone round the origin of [param base], the
## transform [param on] is drawn with: the suit and [param words] in the House's stamp red, in a
## frame, as a proof marked up by hand.
static func filter_stamp(on: CanvasItem, suit: int, words: String, base: Transform2D) -> void:
	on.draw_set_transform_matrix(base * Transform2D(STAMP_TURN, Vector2.ZERO))
	var font := Type.display_font()
	var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, STAMP_SIZE).x
	var mark := float(STAMP_SIZE)
	var across := 12.0 + mark + 8.0 + wide + 12.0
	var box := Rect2(-across * 0.5, -STAMP_TALL * 0.5, across, STAMP_TALL)
	var ink := Color(HouseTheme.STAMP_RED, 0.88)
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.set_border_width_all(2)
	frame.border_color = ink
	frame.set_corner_radius_all(4)
	frame.anti_aliasing = true
	on.draw_style_box(frame, box)
	var at := Rect2(Vector2(box.position.x + 12.0, -mark * 0.5), Vector2.ONE * mark)
	if suit == Joker.Suit.WILD:
		JokerSuits.draw_mark(on, at, suit, true)
	else:
		SuitArt.draw_into(on, at, suit, ink)
	var baseline := Vector2(at.end.x + 8.0, STAMP_SIZE * 0.36)
	on.draw_string(font, baseline, words, HORIZONTAL_ALIGNMENT_LEFT, -1, STAMP_SIZE, ink)
	on.draw_set_transform_matrix(base)


## How far a sheet's stamp reaches round its middle.
static func filter_stamp_reach() -> Rect2:
	return Rect2(-260.0, -24.0, 520.0, 48.0)


## How far the little card of a suit reaches round its middle, turned and shadowed.
static func suit_card_reach() -> Rect2:
	var reach := SUIT_CARD.length() * 0.5 + 8.0
	return Rect2(-Vector2.ONE * reach, Vector2.ONE * reach * 2.0)


## A bulldog clip on an edge at the origin of [param base], the transform [param on] is drawn with:
## its black jaw over the edge and its wire handles up.
static func bulldog_clip(on: CanvasItem, base: Transform2D) -> void:
	on.draw_set_transform_matrix(base)
	var at := Vector2.ZERO
	var jaw := Rect2(at + Vector2(-34.0, -10.0), Vector2(68.0, 30.0))
	on.draw_colored_polygon(_moved(_corners(jaw), FALL), Color(0.0, 0.0, 0.0, 0.45))
	on.draw_polygon(
		_corners(jaw),
		PackedColorArray([Color("#2b2b31"), Color("#2b2b31"), Color("#111114"), Color("#111114")])
	)
	on.draw_line(
		jaw.position + Vector2(2.0, 2.0),
		Vector2(jaw.end.x - 2.0, jaw.position.y + 2.0),
		Color(1.0, 1.0, 1.0, 0.25),
		1.0
	)
	for side: float in [-1.0, 1.0]:
		var wire := PackedVector2Array(
			[
				at + Vector2(side * 26.0, -6.0),
				at + Vector2(side * 22.0, -36.0),
				at + Vector2(side * 8.0, -40.0)
			]
		)
		on.draw_polyline(_moved(wire, Vector2(2.0, 3.0)), Color(0.0, 0.0, 0.0, 0.4), 3.0, true)
		on.draw_polyline(wire, CHROME, 3.0, true)
	on.draw_line(at + Vector2(-8.0, -40.0), at + Vector2(8.0, -40.0), CHROME, 3.0, true)


## The printer's job ticket round the origin of [param base], the transform [param on] is drawn
## with, turned a little: its head [param head], [param lines] typed under it, each its words and
## what it says, and the pressman's OK in its corner.
static func job_ticket(
	on: CanvasItem, head: String, lines: Array[PackedStringArray], base: Transform2D
) -> void:
	on.draw_set_transform_matrix(base * Transform2D(TICKET_TURN, Vector2.ZERO))
	var card := Rect2(-TICKET_SIZE * 0.5, TICKET_SIZE)
	on.draw_rect(Rect2(card.position + Vector2(3.0, 5.0), card.size), FALLEN)
	on.draw_rect(card, TICKET)
	on.draw_rect(Rect2(card.position, Vector2(card.size.x, TICKET_HEAD)), INK)
	on.draw_string(
		TYPED, card.position + Vector2(12.0, 20.0), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, TICKET
	)
	for i: int in lines.size():
		var y := card.position.y + TICKET_HEAD + 18.0 + i * 18.0
		if y > card.end.y - 8.0:
			break
		for column: int in 2:
			on.draw_string(
				TYPED,
				Vector2(card.position.x + 12.0 + column * 82.0, y),
				lines[i][column],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				TICKET_WORDS,
				INK
			)
	on.draw_string(
		MARKER,
		Vector2(card.end.x - 96.0, card.end.y - 10.0),
		TICKET_SIGNED,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(GREASE, 0.9)
	)
	on.draw_set_transform_matrix(base)


## The mat's shadow on whatever is under the dialog round [param rect].
static func _shadow(on: CanvasItem, rect: Rect2) -> void:
	for i: int in SHADOW:
		var ring := FeltArt.rounded(rect.grow(i + 0.5), MAT_ROUND + i)
		ring.append(ring[0])
		var strength := 0.32 * pow(1.0 - float(i) / SHADOW, 2.0)
		on.draw_polyline(_moved(ring, Vector2(0.0, 4.0)), Color(0.0, 0.0, 0.0, strength), 1.0)


static func _centered(
	on: CanvasItem, at: Vector2, words: String, size: int, ink: Color, font: Font = null
) -> void:
	var face := font if font != null else Type.mark_font()
	var wide := face.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	on.draw_string(
		face,
		at - Vector2(wide * 0.5, -size * 0.35),
		words,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		ink
	)


static func _corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
	)


static func _moved(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point: Vector2 in points:
		moved.append(point + by)
	return moved


## The texture coordinates for [param points], a tile of a texture every [param span] pixels.
static func _tiled(points: PackedVector2Array, span: float) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for point: Vector2 in points:
		uvs.append(point / span)
	return uvs
