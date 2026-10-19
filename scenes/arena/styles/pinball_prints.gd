class_name PinballPrints
extends Control
## The Arcade's prints, GAME.md 8.1c, each drawn once: the playfield's art from the map's grid, in
## a pinball artist's hand under the House's layout; the sheet of plastics the guides wear; the
## pieces of playfield the machine's parts past the rail stand on; and the backglass of its head.
##
## The playfield is what a restored machine of the sixties wears rather than a new one, and is kept
## quiet, since the pieces standing on it are where the machine is: a plum ground, a sunburst at a
## whisper behind the Junction on a teal medallion, a teal band round the field, an ochre
## starburst behind each Jackpot, and the light of the machine's own bulbs on the coat, a warm
## pool under every guide's plastic and round each insert. The House's layout is laid over it as
## the floor's detail, so none of this says anything the layout says; it is the paper it is
## printed on. The picture covers the arena from corner to corner, as [LayoutPrint]'s does, and
## lights the coat a little from below, see [constant PinballStyle.FIELD_GLOW].
##
## The backglass is the machine's head, painted on the back of its glass and lit from behind: the
## name arched over a wheel, a score window in each seat's color, and the windows a machine lights
## between games, GAME OVER, SAME PLAYER SHOOTS AGAIN and TILT, all dark.

enum Print { FIELD, GLASS, PLASTICS, PANEL }
## The plastics over the guides, printed side by side on one sheet: a long guide's fan of cards, a
## short one's pair of dice and a post's star; and under them the faces of the drop targets, a
## card's rank each, see [method PinballStyle.crate].
enum Plastic { CARDS, DICE, STAR, TARGET_A, TARGET_K, TARGET_Q, TARGET_J, TARGET_10 }

## How many pixels a cell of the playfield is drawn at: soft fields need fewer than the layout's
## fine lines do.
const CELL_PIXELS := 32
## The backglass's picture.
const GLASS_PIXELS := Vector2i(1024, 576)
const FONT := preload("res://assets/fonts/BarlowCondensed-Black.ttf")
const GROUND := Color("#312536")
const RAYS := Color("#43304A")
const TEAL := Color("#1F414E")
const OCHRE := Color("#C4943F")
const CREAM := Color("#E7DABA")
const INK := Color("#141017")
## The pool of light round an insert: a coin's blue, an item's warm white; and the warm light the
## bulbs under a guide's plastic throw on the coat round it.
const COIN_POOL := Color("#5C8FD6")
const ITEM_POOL := Color("#F0C77A")
const GI := Color("#E9B873")
## The light the coat gives back of its own print, warm as the bulbs under it are, see
## [constant PinballStyle.FIELD_GLOW].
const COAT_GLOW := Color("#F6E5C7")
## How many pixels a cell of a guide's plastic is printed at, and the sheet they are printed on:
## the long guide's six cells across the top, the short one's two and the post's one under it, and
## the drop targets' faces along the foot.
const PLASTIC_CELL := 128
const PLASTICS_PIXELS := Vector2i(PLASTIC_CELL * 6, PLASTIC_CELL * 3)
## The drop targets' ranks, in the order of [enum Plastic] from TARGET_A, and their suits.
const TARGETS := 5
const RANKS: Array[String] = ["A", "K", "Q", "J", "10"]
const RANK_SUITS: Array[int] = [
	SuitArt.Suit.SPADE,
	SuitArt.Suit.HEART,
	SuitArt.Suit.CLUB,
	SuitArt.Suit.DIAMOND,
	SuitArt.Suit.SPADE
]
## How many pixels a meter of a piece of playfield past the rail is drawn at.
const PANEL_PIXELS := 24
const CARD := Color("#EFE6D0")
const PIP_RED := Color("#B4473C")
## The windows of the backglass in the seats' colors, the first four.
const SEATS: Array[Color] = [Color("#E23D3D"), Color("#3D6FE2"), Color("#F2D23D"), Color("#43C463")]

var print_kind := Print.FIELD
var grid: ArenaGrid


## The playfield's art for [param on].
static func field(on: ArenaGrid) -> PinballPrints:
	var art := PinballPrints.new()
	art.grid = on
	art.print_kind = Print.FIELD
	return art


static func glass() -> PinballPrints:
	var art := PinballPrints.new()
	art.print_kind = Print.GLASS
	return art


## The sheet of screened plastics the guides wear, see [method PinballStyle.wall].
static func plastics() -> PinballPrints:
	var art := PinballPrints.new()
	art.print_kind = Print.PLASTICS
	return art


## Where on the sheet of [method plastics] the plastic of [param kind] is, in its UV.
static func plastic_uv(kind: Plastic) -> Rect2:
	var cell := Vector2(1.0 / 6.0, 1.0 / 3.0)
	match kind:
		Plastic.CARDS:
			return Rect2(Vector2.ZERO, Vector2(1.0, cell.y))
		Plastic.DICE:
			return Rect2(Vector2(0.0, cell.y), cell * Vector2(2.0, 1.0))
		Plastic.STAR:
			return Rect2(Vector2(cell.x * 2.0, cell.y), cell)
	return Rect2(Vector2(cell.x * float(kind - Plastic.TARGET_A), cell.y * 2.0), cell)


## A piece of the playfield past the House's rail, for the parts of the machine that stand there:
## the ground and the band round it, drawn [constant PANEL_PIXELS] to a meter.
static func panel() -> PinballPrints:
	var art := PinballPrints.new()
	art.print_kind = Print.PANEL
	return art


## The size of the playfield's picture for [param on].
static func field_pixels(on: ArenaGrid) -> Vector2i:
	return Vector2i(on.width * CELL_PIXELS, on.height * CELL_PIXELS)


func _draw() -> void:
	match print_kind:
		Print.GLASS:
			_glass()
		Print.PLASTICS:
			_plastics()
		Print.PANEL:
			_panel()
		_:
			if grid != null:
				_field()


# --- the playfield ---------------------------------------------------------------


func _field() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GROUND)
	var middle := size * 0.5
	var radius := CELL_PIXELS * 2.0
	if not grid.junctions.is_empty():
		var rect: Rect2i = grid.junctions[0]
		middle = (Vector2(rect.position) + Vector2(rect.size) * 0.5) * CELL_PIXELS
		radius = rect.size.x * 0.5 * CELL_PIXELS
	_sunburst(middle, radius * 1.4, minf(size.x, size.y) * 0.5)
	_band()
	for rect: Rect2i in grid.jackpots:
		var at := (Vector2(rect.position) + Vector2(rect.size) * 0.5) * CELL_PIXELS
		_starburst(at, rect.size.x * 0.75 * CELL_PIXELS, rect.size.x * 1.05 * CELL_PIXELS)
	# The medallion the Junction stands in, under the House's terms round it.
	var medallion := radius + CELL_PIXELS * 1.3
	draw_circle(middle, medallion + 3.0, INK, true, -1.0, true)
	draw_circle(middle, medallion, TEAL, true, -1.0, true)
	draw_arc(middle, medallion - 5.0, 0.0, TAU, 96, Color(OCHRE, 0.5), 2.0, true)
	for rect: Rect2i in grid.walls:
		if not grid.is_border(rect):
			_glow(Rect2(Vector2(rect.position) * CELL_PIXELS, Vector2(rect.size) * CELL_PIXELS))
	for cell: Vector2i in grid.coin_pads:
		_pool(_at(cell), CELL_PIXELS * 0.9, COIN_POOL, 0.2)
	for cell: Vector2i in grid.power_pads:
		_pool(_at(cell), CELL_PIXELS * 1.2, ITEM_POOL, 0.18)


## Rays fanning out from the Junction, a shade off the ground and fading as they go.
func _sunburst(at: Vector2, from: float, reach: float) -> void:
	var rays := 36
	for i: int in rays:
		if i % 2 == 1:
			continue
		var a := TAU * float(i) / float(rays)
		var b := TAU * float(i + 1) / float(rays)
		var points := PackedVector2Array(
			[
				at + Vector2.from_angle(a) * from,
				at + Vector2.from_angle(a) * reach,
				at + Vector2.from_angle(b) * reach,
				at + Vector2.from_angle(b) * from,
			]
		)
		var colors := PackedColorArray([RAYS, Color(RAYS, 0.0), Color(RAYS, 0.0), RAYS])
		draw_polygon(points, colors)


## The teal band round the field, inside the House's rail, its inside corners rounded as a
## printer's mask is and keylined in ink, with a sparse run of ochre stars along its top and its
## foot.
func _band() -> void:
	var outer := Rect2(Vector2.ONE * CELL_PIXELS, size - Vector2.ONE * CELL_PIXELS * 2.0)
	var inner := outer.grow(-CELL_PIXELS * 0.95)
	var corner := CELL_PIXELS * 0.9
	draw_rect(outer, TEAL)
	draw_rect(inner, GROUND)
	var a := inner.position
	var b := inner.end
	for line: Array in [
		[Vector2(a.x + corner, a.y), Vector2(b.x - corner, a.y)],
		[Vector2(a.x + corner, b.y), Vector2(b.x - corner, b.y)],
		[Vector2(a.x, a.y + corner), Vector2(a.x, b.y - corner)],
		[Vector2(b.x, a.y + corner), Vector2(b.x, b.y - corner)],
	]:
		draw_line(line[0], line[1], INK, 3.0, true)
	for i: int in 4:
		var at := Vector2(a.x if i % 2 == 0 else b.x, a.y if i < 2 else b.y)
		var toward := Vector2(1.0 if i % 2 == 0 else -1.0, 1.0 if i < 2 else -1.0)
		var square := Rect2(at, Vector2.ZERO).expand(at + toward * corner)
		draw_rect(square, TEAL)
		var middle := at + toward * corner
		draw_circle(middle, corner, GROUND)
		var facing := (-toward).angle()
		draw_arc(middle, corner, facing - PI * 0.25, facing + PI * 0.25, 10, INK, 3.0, true)
	for k: int in 20:
		var x := lerpf(outer.position.x, outer.end.x, (float(k) + 0.5) / 20.0)
		_star(Vector2(x, outer.position.y + CELL_PIXELS * 0.45), 3.0, Color(OCHRE, 0.4))
		_star(Vector2(x, outer.end.y - CELL_PIXELS * 0.45), 3.0, Color(OCHRE, 0.4))


## An ochre starburst behind a Jackpot, spikes out from [param inner] to [param outer].
func _starburst(at: Vector2, inner: float, outer: float) -> void:
	var spikes := 16
	var points := PackedVector2Array()
	for i: int in spikes * 2:
		var reach := outer if i % 2 == 0 else inner
		points.append(at + Vector2.from_angle(TAU * float(i) / float(spikes * 2)) * reach)
	draw_colored_polygon(points, Color(OCHRE, 0.2))


## The light of the bulbs under a guide's plastic on the coat round [param rect]: warm, soft at
## its edge and gone a cell out, as a machine's general illumination is.
func _glow(rect: Rect2) -> void:
	var light := StyleBoxFlat.new()
	light.bg_color = Color(GI, 0.16)
	light.set_corner_radius_all(int(CELL_PIXELS * 0.4))
	light.shadow_color = Color(GI, 0.2)
	light.shadow_size = int(CELL_PIXELS * 0.9)
	draw_style_box(light, rect)


## A four-pointed sparkle.
func _star(at: Vector2, reach: float, ink: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 8:
		var r := reach if i % 2 == 0 else reach * 0.3
		points.append(at + Vector2.from_angle(PI * 0.25 * float(i) - PI * 0.5) * r)
	draw_colored_polygon(points, ink)


## The warm pool an insert's bulb throws on the coat round it, soft at its edge.
func _pool(at: Vector2, reach: float, light: Color, strength: float) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var sides := 32
	points.append(at)
	colors.append(Color(light, strength))
	for i: int in sides + 1:
		points.append(at + Vector2.from_angle(TAU * float(i) / float(sides)) * reach)
		colors.append(Color(light, 0.0))
	for i: int in sides:
		draw_polygon(
			PackedVector2Array([points[0], points[i + 1], points[i + 2]]),
			PackedColorArray([colors[0], colors[i + 1], colors[i + 2]])
		)


func _at(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2.ONE * 0.5) * CELL_PIXELS


## A piece of the playfield past the rail: the ground inside the teal band, its inside corners
## rounded and keylined as the field's are.
func _panel() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	var band := Rect2(Vector2.ONE * 3.0, size - Vector2.ONE * 6.0)
	draw_rect(band, TEAL)
	var ground := band.grow(-PANEL_PIXELS * 0.45)
	var corner := PANEL_PIXELS * 0.8
	var light := StyleBoxFlat.new()
	light.bg_color = GROUND
	light.set_corner_radius_all(int(corner))
	light.border_color = INK
	light.set_border_width_all(3)
	draw_style_box(light, ground)


# --- the plastics ----------------------------------------------------------------


## The sheet of plastics, each in its own place on it, see [method plastic_uv].
func _plastics() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), CREAM)
	var cell := float(PLASTIC_CELL)
	_plastic(Rect2(0.0, 0.0, cell * 6.0, cell), Plastic.CARDS)
	_plastic(Rect2(0.0, cell, cell * 2.0, cell), Plastic.DICE)
	_plastic(Rect2(cell * 2.0, cell, cell, cell), Plastic.STAR)
	for i: int in TARGETS:
		_target(Rect2(cell * float(i), cell * 2.0, cell, cell), i)


## A drop target's face over [param rect] of the sheet: a card's cream face keylined in ink, its
## rank [param rank] of [constant RANKS] large in the middle and its suit under it, the hearts and
## diamonds in the pips' red.
func _target(rect: Rect2, rank: int) -> void:
	var face := rect.grow(-rect.size.x * 0.06)
	draw_rect(face, INK)
	draw_rect(face.grow(-4.0), CARD)
	var suit := RANK_SUITS[rank]
	var red := suit == SuitArt.Suit.HEART or suit == SuitArt.Suit.DIAMOND
	var ink := PIP_RED if red else INK
	var text: String = RANKS[rank]
	var font_size := int(rect.size.y * 0.5)
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var spot := Vector2(rect.get_center().x - width * 0.5, rect.position.y + rect.size.y * 0.56)
	draw_string(FONT, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
	var pip := rect.size.x * 0.22
	var glyph := Rect2(
		Vector2(rect.get_center().x - pip * 0.5, rect.position.y + rect.size.y * 0.64),
		Vector2.ONE * pip
	)
	SuitArt.draw_into(self, glyph, suit, ink)


## A plastic over [param rect] of the sheet: the teal of the field under a cream border keylined in
## ink, and its picture in the middle, kept to a few shapes, since it is seen from across the table.
func _plastic(rect: Rect2, kind: Plastic) -> void:
	var border := rect.size.y * 0.1
	var field := rect.grow(-border)
	draw_rect(field.grow(3.0), INK)
	draw_rect(field, TEAL.lightened(0.12))
	var middle := rect.get_center()
	var high := field.size.y
	match kind:
		Plastic.CARDS:
			_fan(middle, high * 0.8)
			for side: float in [-1.0, 1.0]:
				_star(middle + Vector2(side * field.size.x * 0.36, 0.0), high * 0.22, OCHRE)
		Plastic.DICE:
			_die(middle + Vector2(-high * 0.5, 0.0), high * 0.62, -0.2, 3)
			_die(middle + Vector2(high * 0.5, 0.0), high * 0.62, 0.15, 4)
		_:
			draw_circle(middle, high * 0.36, INK, true, -1.0, true)
			draw_circle(middle, high * 0.32, CREAM, true, -1.0, true)
			_star(middle, high * 0.26, OCHRE)


## A royal flush fanned out, five cards [param high] tall round a point under [param at].
func _fan(at: Vector2, high: float) -> void:
	var card := Vector2(high * 0.68, high)
	var pivot := at + Vector2(0.0, high * 0.7)
	for i: int in 5:
		var turn := (float(i) - 2.0) * 0.26
		draw_set_transform(pivot, turn)
		var box := Rect2(Vector2(-card.x * 0.5, -high * 1.2), card)
		draw_rect(box.grow(2.0), INK)
		draw_rect(box, CARD)
		var suit: int = SuitArt.Suit.SPADE if i % 2 == 0 else SuitArt.Suit.HEART
		var glyph := Rect2(
			box.get_center() - Vector2.ONE * card.x * 0.25, Vector2.ONE * card.x * 0.5
		)
		SuitArt.draw_into(self, glyph, suit, INK if i % 2 == 0 else PIP_RED)
	draw_set_transform(Vector2.ZERO)


## A die [param side] across at [param at], turned [param turn], showing [param spots].
func _die(at: Vector2, side: float, turn: float, spots: int) -> void:
	draw_set_transform(at, turn)
	var box := Rect2(-Vector2.ONE * side * 0.5, Vector2.ONE * side)
	draw_rect(box.grow(2.0), INK)
	draw_rect(box, CARD)
	var places: Array[Vector2] = [Vector2(-1, -1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1)]
	if spots == 3:
		places = [Vector2(-1, -1), Vector2.ZERO, Vector2(1, 1)]
	for place: Vector2 in places:
		draw_circle(place * side * 0.26, side * 0.1, PIP_RED)
	draw_set_transform(Vector2.ZERO)


# --- the backglass ---------------------------------------------------------------


func _glass() -> void:
	var bands := 24
	for i: int in bands:
		var t := float(i) / float(bands - 1)
		var band := Rect2(
			0.0, size.y * float(i) / float(bands), size.x, size.y / float(bands) + 1.0
		)
		draw_rect(band, Color("#3A2140").lerp(Color("#140B18"), t))
	var wheel := Vector2(size.x * 0.5, size.y * 0.56)
	_sunburst_glass(wheel)
	_wheel(wheel, size.y * 0.2)
	_title(Vector2(size.x * 0.5, size.y * 0.25), size.x * 0.9)
	var windows := 4
	var wide := size.x * 0.16
	for i: int in windows:
		var x := size.x * (0.5 + (float(i) - 1.5) * 0.205)
		_score(Rect2(x - wide * 0.5, size.y * 0.86, wide, size.y * 0.09), SEATS[i], i)
	_lamp_window(Rect2(size.x * 0.05, size.y * 0.5, size.x * 0.17, size.y * 0.12), "GAME OVER")
	_lamp_window(Rect2(size.x * 0.78, size.y * 0.5, size.x * 0.17, size.y * 0.12), "TILT")
	var line := "SAME PLAYER SHOOTS AGAIN"
	var font_size := int(size.y * 0.04)
	var width := FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var spot := Vector2(size.x * 0.5 - width * 0.5, size.y * 0.81)
	draw_string(FONT, spot, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#6B3A3A"))
	var edge := Rect2(Vector2.ONE * 8.0, size - Vector2.ONE * 16.0)
	draw_rect(edge, Color(OCHRE, 0.8), false, 3.0)
	draw_rect(edge.grow(-8.0), Color(CREAM, 0.35), false, 1.5)


func _sunburst_glass(at: Vector2) -> void:
	var rays := 28
	for i: int in rays:
		if i % 2 == 1:
			continue
		var a := TAU * float(i) / float(rays)
		var b := TAU * float(i + 1) / float(rays)
		var reach := size.x * 0.7
		var points := PackedVector2Array(
			[at, at + Vector2.from_angle(a) * reach, at + Vector2.from_angle(b) * reach]
		)
		draw_polygon(
			points, PackedColorArray([Color(OCHRE, 0.28), Color(OCHRE, 0.0), Color(OCHRE, 0.0)])
		)


## The wheel under the name: a walnut rim, muted pockets and a brass middle.
func _wheel(at: Vector2, radius: float) -> void:
	draw_circle(at, radius + 6.0, INK)
	draw_circle(at, radius, Color("#5A3424"))
	var pockets := 24
	for i: int in pockets:
		var a := TAU * float(i) / float(pockets)
		var b := TAU * float(i + 1) / float(pockets)
		var ink := Color("#2F6B4E") if i == 0 else (Color("#9A3C34") if i % 2 == 1 else INK)
		var points := PackedVector2Array(
			[
				at + Vector2.from_angle(a) * radius * 0.62,
				at + Vector2.from_angle(a) * radius * 0.9,
				at + Vector2.from_angle(b) * radius * 0.9,
				at + Vector2.from_angle(b) * radius * 0.62,
			]
		)
		draw_colored_polygon(points, ink)
	draw_circle(at, radius * 0.6, Color("#3B2741"))
	for i: int in 4:
		var turn := PI * 0.25 + PI * 0.5 * float(i)
		draw_line(at, at + Vector2.from_angle(turn) * radius * 0.55, OCHRE, 5.0, true)
	draw_circle(at, radius * 0.12, OCHRE)


## JACKPOT JUNCTION arched over the wheel, its middle at [param top] on an arch [param arc]
## round, cream with an ink edge and an ochre shadow.
func _title(top: Vector2, arc: float) -> void:
	var text := "JACKPOT JUNCTION"
	var font_size := int(size.y * 0.15)
	var widths: Array[float] = []
	var total := 0.0
	for letter: String in text:
		var width := FONT.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		widths.append(width)
		total += width
	var wheel := top + Vector2(0.0, arc)
	var angle := -PI * 0.5 - total / arc * 0.5
	for i: int in text.length():
		var step := widths[i] / arc
		var at_angle := angle + step * 0.5
		var at := wheel + Vector2.from_angle(at_angle) * arc
		draw_set_transform(at, at_angle + PI * 0.5)
		var spot := Vector2(-widths[i] * 0.5, font_size * 0.35)
		draw_string_outline(FONT, spot + Vector2(3.0, 4.0), text[i], 0, -1, font_size, 8, OCHRE)
		draw_string_outline(FONT, spot, text[i], 0, -1, font_size, 8, INK)
		draw_string(FONT, spot, text[i], 0, -1, font_size, CREAM)
		draw_set_transform(Vector2.ZERO)
		angle += step


## A seat's score window: a dark window framed in its color with its score in it.
func _score(rect: Rect2, ink: Color, seat: int) -> void:
	draw_rect(rect.grow(4.0), INK)
	draw_rect(rect, Color("#0B080D"))
	draw_rect(rect, ink, false, 3.0)
	var font_size := int(rect.size.y * 0.78)
	var text := "%d %03d" % [seat + 1, (seat * 370 + 250) % 1000]
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var spot := rect.get_center() + Vector2(-width * 0.5, font_size * 0.36)
	draw_string(FONT, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)


## A window the machine lights between games, dark.
func _lamp_window(rect: Rect2, words: String) -> void:
	draw_rect(rect.grow(3.0), INK)
	draw_rect(rect, Color("#24161F"))
	var font_size := int(rect.size.y * 0.5)
	var width := FONT.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var spot := rect.get_center() + Vector2(-width * 0.5, font_size * 0.36)
	draw_string(FONT, spot, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#6B3A3A"))
