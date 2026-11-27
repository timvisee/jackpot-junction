class_name JokerSuits
extends RefCounted
## The suits of the jokers, GAME.md 7.3, Suits: what each is called and drawn in, which suits a
## hand is Suited in, and what being Suited in each pays. The suits are the four of the Royal Flush
## pads and of the teams, in cream for Spades and Clubs and red for Hearts and Diamonds as a deck
## has them; a wild card wears a jester's hat, the joker's own. As marks they are drawings of
## GAME.md 8.3a, printed flat like type, wherever a suit is shown: on a card, on the arena's pads
## and its pinball table, under the clock, for a team. What needs a suit as a shape rather than a
## picture, a kart's sticker, a team's pennant, a suit with a ring round it, takes the outline
## traced off the same drawing, see [method outline].

## How many cards of a suit make a hand Suited in it, GAME.md 7.3, unless a joker says otherwise.
const SUITED := 3
## Each suit by name, shown through tr(); [method name_of] gives it in English, as the stats and the
## bonuses go by it.
const NAMES: Array[String] = ["Spades", "Hearts", "Diamonds", "Clubs", "Wild"]
## Each suit as a letter of words, where it is said rather than drawn.
const SYMBOLS: Array[String] = ["♠", "♥", "♦", "♣", "★"]
## What being Suited in each suit pays, as the pane that describes a card says it, shown through
## tr().
const PAYS: Array[String] = [
	"your bullets fly 20% faster",
	"come back holding a Shield",
	"every chip you pick up is worth one more",
	"every drift boost gives +0.5 mult",
]
## The red of Hearts and Diamonds, bright enough to read on a card's dark.
const RED := Color("#F0524F")
## Each suit's drawing, in [enum Joker.Suit] order, and the jester's in two: its points in red, then
## its band and bells in gold over them.
const PICTURES: Array[StringName] = [&"suit_spade", &"suit_heart", &"suit_diamond", &"suit_club"]
const JESTER := &"suit_jester"
const JESTER_BAND := &"suit_jester_band"
## How far a mark's outline reaches, in pixels, and in how many steps round it is drawn.
const HALO := 1.4
const HALO_STEPS := 8
## How much bigger than its room a suit on the table is printed, see [method filled].
const FILLED := 1.16
## The dark of the ring round an outlined suit, see [method draw_outlined], and of a pad's.
const OUTLINE := Color(0.05, 0.05, 0.06)
## How many pixels a side a drawing is traced at for its outline, and how far off it the outline
## may stray, in those pixels: a five-hundredth of the suit, under a pixel anywhere it is shown.
const TRACED := 512
const TRACE_EPSILON := 1.0
## How big a unit square is made while a suit is grown into its ring: the corners are rounded only
## to a quarter of a unit, which in a unit square is no rounding at all.
const WORK_SCALE := 100.0
## How wide the line that softens an outlined suit's edges is, in pixels.
const SOFT_EDGE := 1.0

## Each suit's outline, traced the first time it is asked for, and its grown outline and ring for
## each width it has been drawn at.
static var _outlines: Dictionary[int, PackedVector2Array] = {}
static var _grown: Dictionary[Vector2i, PackedVector2Array] = {}
static var _rings: Dictionary[Vector2i, Array] = {}


## A suit drawn into a control: a card's corner, the pane's line, the hand's Suited sign.
class Mark:
	extends Control

	var suit := Joker.Suit.WILD
	var paper := false
	## An outline of this round the mark, for one set over a screen, as a card's corner is; none
	## while clear.
	var halo := Color(0.0, 0.0, 0.0, 0.0)

	func _init(of_suit: int = Joker.Suit.WILD, on_paper := false) -> void:
		suit = of_suit as Joker.Suit
		paper = on_paper
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var box := Rect2(Vector2.ZERO, size)
		if halo.a > 0.0:
			for step: int in HALO_STEPS:
				var out := Vector2.from_angle(TAU * step / HALO_STEPS) * HALO
				JokerSuits.draw_shadow(self, Rect2(box.position + out, box.size), suit, halo)
		JokerSuits.draw_mark(self, box, suit, paper)


## [param box] grown round its middle so that a suit printed into it fills it nearly edge to edge,
## as a suit on a pad or a card on the table does: the drawings keep their grid's margin round them.
static func filled(box: Rect2) -> Rect2:
	return box.grow(minf(box.size.x, box.size.y) * (FILLED - 1.0) * 0.5)


## Prints [param suit] flat in [param ink] into [param box] on [param on], filling it as a suit on
## the table does, see [method filled]. Any number is a suit: the fifth is a spade again.
static func draw_filled(on: CanvasItem, box: Rect2, suit: int, ink: Color) -> void:
	var picture := PICTURES[posmod(suit, PICTURES.size())]
	IconPress.draw(on, filled(box), picture, ink, IconPress.Ground.PAPER)


## Draws [param suit] into [param box] on [param on] in [param ink], filling it as [method
## draw_filled] does, with a ring of [constant OUTLINE] [param edge] pixels wide round it, for a
## suit that has to read on any ground, a team's or one under the clock. The ring is a shape of its
## own round the suit, its outline grown, round at the corners, with the suit taken out of it: a
## see-through ink shows what is under the suit rather than the ring, and a line along the edge
## would stand out in a spike past every sharp point.
static func draw_outlined(on: CanvasItem, box: Rect2, suit: int, ink: Color, edge: float) -> void:
	suit = posmod(suit, PICTURES.size())
	var shape := _placed(outline(suit), box)
	on.draw_colored_polygon(shape, ink)
	if edge <= 0.0:
		return
	var width := edge / box.size.x
	for piece: PackedVector2Array in ring(suit, width):
		on.draw_colored_polygon(_placed(piece, box), OUTLINE)
	# A filled polygon has a hard, stepped edge, which at the size of a suit under the clock is
	# most of what there is to see of it: a thin line down both edges of the ring softens them.
	for edge_line: PackedVector2Array in [shape, _placed(grown(suit, width), box)]:
		var closed := edge_line.duplicate()
		closed.append(edge_line[0])
		on.draw_polyline(closed, OUTLINE, SOFT_EDGE, true)


## [param suit]'s outline in a unit square, the suit filling it as [method draw_filled] prints it:
## traced off its drawing the first time it is asked for, its largest shape, the suits having no
## holes. Any number is a suit.
static func outline(suit: int) -> PackedVector2Array:
	suit = posmod(suit, PICTURES.size())
	if _outlines.has(suit):
		return _outlines[suit]
	var image := IconPress.printed(PICTURES[suit], Color.WHITE, TRACED, IconPress.Ground.PAPER)
	var bits := BitMap.new()
	bits.create_from_image_alpha(image, 0.5)
	var traced := _largest(
		bits.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), TRACE_EPSILON)
	)
	var shape := PackedVector2Array()
	for point: Vector2 in traced:
		shape.append((point / float(TRACED) - Vector2.ONE * 0.5) * FILLED + Vector2.ONE * 0.5)
	_outlines[suit] = shape
	return shape


## [param suit]'s outline grown outward by [param width] of a unit square, round at the corners.
static func grown(suit: int, width: float) -> PackedVector2Array:
	suit = posmod(suit, PICTURES.size())
	var key := Vector2i(suit, roundi(width * 100000.0))
	if not _grown.has(key):
		var work := _scaled(outline(suit), WORK_SCALE)
		var out := Geometry2D.offset_polygon(
			work, width * WORK_SCALE, Geometry2D.PolyJoinType.JOIN_ROUND
		)
		_grown[key] = _scaled(_largest(out), 1.0 / WORK_SCALE)
	return _grown[key]


## The ring round [param suit], [param width] of a unit square wide, as the pieces it is drawn in:
## cut down the middle, so that each half, with the suit taken out of it, has no hole in it,
## which is all a polygon can be drawn as.
static func ring(suit: int, width: float) -> Array:
	suit = posmod(suit, PICTURES.size())
	var key := Vector2i(suit, roundi(width * 100000.0))
	if _rings.has(key):
		return _rings[key]
	var inner := _scaled(outline(suit), WORK_SCALE)
	var outer := _scaled(grown(suit, width), WORK_SCALE)
	var middle := WORK_SCALE * 0.5
	var far := WORK_SCALE * 2.0
	var pieces: Array[PackedVector2Array] = []
	for half: Rect2 in [
		Rect2(-far, -far, middle + far, far * 2.0 + WORK_SCALE),
		Rect2(middle, -far, middle + far, far * 2.0 + WORK_SCALE),
	]:
		var cut := PackedVector2Array(
			[
				half.position,
				Vector2(half.end.x, half.position.y),
				half.end,
				Vector2(half.position.x, half.end.y)
			]
		)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(outer, cut):
			for piece: PackedVector2Array in Geometry2D.clip_polygons(part, inner):
				pieces.append(_scaled(piece, 1.0 / WORK_SCALE))
	_rings[key] = pieces
	return pieces


## The biggest of [param polygons] by its area.
static func _largest(polygons: Array[PackedVector2Array]) -> PackedVector2Array:
	var best := PackedVector2Array()
	var most := -1.0
	for polygon: PackedVector2Array in polygons:
		var area := 0.0
		for i: int in polygon.size():
			area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
		if absf(area) > most:
			most = absf(area)
			best = polygon
	return best


static func _scaled(polygon: PackedVector2Array, by: float) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for point: Vector2 in polygon:
		scaled.append(point * by)
	return scaled


static func _placed(polygon: PackedVector2Array, box: Rect2) -> PackedVector2Array:
	var placed := PackedVector2Array()
	for point: Vector2 in polygon:
		placed.append(box.position + point * box.size)
	return placed


static func name_of(suit: int) -> String:
	return NAMES[clampi(suit, 0, NAMES.size() - 1)]


## The color [param suit] is drawn in: red for Hearts and Diamonds, cream for the rest, the
## House's darker ink of each on [param paper].
static func color_of(suit: int, paper := false) -> Color:
	var red := suit == Joker.Suit.HEARTS or suit == Joker.Suit.DIAMONDS
	var color := RED if red else Palette.CHIP_WHITE
	if paper:
		return HouseTheme.on_paper(color) if red else HouseTheme.INK
	return color


## Draws [param suit] into [param box] on [param on]: the suit itself, or for a wild card a
## jester's hat, see [method draw_jester].
static func draw_mark(on: CanvasItem, box: Rect2, suit: int, paper := false) -> void:
	if suit < 0 or suit >= PICTURES.size():
		draw_jester(on, box, paper)
		return
	IconPress.draw(on, box, PICTURES[suit], color_of(suit, paper), IconPress.Ground.PAPER)


## [param suit]'s mark in [param ink] alone, its shape without its colors: what its outline is drawn
## of, see [member Mark.halo].
static func draw_shadow(on: CanvasItem, box: Rect2, suit: int, ink: Color) -> void:
	if suit < 0 or suit >= PICTURES.size():
		IconPress.draw(on, box, JESTER, ink, IconPress.Ground.PAPER, ink)
		IconPress.draw(on, box, JESTER_BAND, ink, IconPress.Ground.PAPER, ink)
		return
	IconPress.draw(on, box, PICTURES[suit], ink, IconPress.Ground.PAPER)


## A jester's hat, the wild card's mark, GAME.md 7.3, the Jokers table card's: two points in red
## flopping out and down with a cream one standing up between them, over a gold band, a gold bell
## on the end of each. On [param paper] the cream is the House's ink, as a spade is.
static func draw_jester(on: CanvasItem, box: Rect2, paper := false) -> void:
	var red := color_of(Joker.Suit.HEARTS, paper)
	var cream := color_of(Joker.Suit.SPADES, paper)
	var gold := HouseTheme.on_paper(Palette.CHIP_GOLD) if paper else Palette.CHIP_GOLD
	IconPress.draw(on, box, JESTER, red, IconPress.Ground.PAPER, cream)
	IconPress.draw(on, box, JESTER_BAND, gold, IconPress.Ground.PAPER, cream)


## What [param suit] is for in a hand, as the pane that describes a card says it after the suit
## itself: what three of it pay, the pane setting "3×" and the suit in front, or where a wild card
## goes.
static func words(suit: int) -> String:
	if suit == Joker.Suit.WILD:
		return Lang.t("Wild: joins the suit you hold most of.")
	# TRANSLATORS: After "3×" and a suit drawn, what three cards of that suit pay: ": your bullets
	# fly 20% faster."
	return Lang.t(": %s.") % Lang.t(PAYS[suit])


## How many of each suit [param jokers] holds, the wild cards left out, by [enum Joker.Suit].
static func counts(jokers: Array[Joker]) -> Array[int]:
	var counted: Array[int] = [0, 0, 0, 0]
	for joker: Joker in jokers:
		if joker.suit != Joker.Suit.WILD and not joker.contraband:
			counted[joker.suit] += 1
	return counted


## The suit [param jokers] holds most of, the first of Spades, Hearts, Diamonds and Clubs where two
## are level, or -1 for a hand of nothing but wild cards.
static func leading(jokers: Array[Joker]) -> int:
	var counted := counts(jokers)
	var best := -1
	for suit: int in counted.size():
		if counted[suit] > 0 and (best < 0 or counted[suit] > counted[best]):
			best = suit
	return best


## The suit a pick for [param kart] leans toward, GAME.md 7.3: the one its hand holds most of, or
## -1 at a table without Suits & hands, 3.17, where a suit is only a corner of a card.
static func lean(kart: Kart) -> int:
	if kart.rules != null and not kart.rules.has_card(TableCards.Card.SUITS):
		return -1
	return leading(kart.jokers.jokers)


## The suits [param jokers] is Suited in, GAME.md 7.3: three of one, or as many as a joker in it
## says, the wild cards joining the suit held most of so that they count once.
static func suited(jokers: Array[Joker]) -> Array[int]:
	var counted := counts(jokers)
	var wild := 0
	var needed := SUITED
	for joker: Joker in jokers:
		if joker.suit == Joker.Suit.WILD and not joker.contraband:
			wild += 1
		needed = joker.modify_suited(needed)
	var lead := leading(jokers)
	counted[maxi(lead, 0)] += wild
	var result: Array[int] = []
	for suit: int in counted.size():
		if counted[suit] >= needed:
			result.append(suit)
	return result
