class_name AtlasArt
extends RefCounted
## The House's road atlas the loyalty program's dialog is dressed as, GAME.md 8.9. Its pane is the
## atlas's cover: navy book cloth over a board, its weave fine and worn lighter and darker in
## patches, a survey's contours etched faint over it in gold; the House's rules stamped round it in
## gold, a heavy one and a fine one inside it with its corners turned in, and the atlas's name in a
## break in their foot; a brass cap on each corner with a rivet in it; and a red ribbon and a gold
## one out from under its foot. Laid on it in the foot where there is room, a pencil of the House's
## and a pair of dividers; over the map, tape at its corners, and the card held at its own in gray
## photo corners. On a short screen, where the pane fills it, the cover is a little bigger than
## the screen, its edge and its round corners past it, and nothing hangs out from under it.
## [AtlasCover] draws all of it once into a picture.

## The cloth as it is laid over the weave, and how dark its wear is at the most.
const CLOTH := Color("#405078")
const WEAR := 0.28
## How big the weave's tile is, and how many of the cover's pixels its tile spans.
const WEAVE_TILE := 64
const WEAVE_SPAN := 40.0
## How many pixels of the cover a tile of the wear's patches spans.
const WEAR_SPAN := 256.0
## The gold the rules and the name are stamped in, and the brass of the corners.
const GOLD := Color("#e3b549")
const BRASS := Color("#c9a24a")
const BRASS_HIGH := Color("#f6dc93")
const BRASS_LOW := Color("#6e5220")
## How round the cover's corners are, and how far past the screen's edges it runs where the pane
## fills the screen.
const ROUND := 10.0
const PAST := 14.0
## How far in from the cover's edge its heavy rule is, with room and short of it; how far inside
## that the fine one is, and how far in the fine one's corners turn.
const RULE := 17.0
const RULE_SHORT := 7.0
const RULE_GAP := 5.0
const RULE_TURN := 10.0
## The size of the atlas's name in the break in the rules' foot, with room and short of it, and the
## room either side of it in the break; its words are the story's, see [constant StoryLines.ATLAS].
const NAME_SIZE := 15
const NAME_SIZE_SHORT := 13
const NAME_ROOM := 15.0
## How far along each edge a corner's brass cap reaches, with room and short of it.
const CAP := 46.0
const CAP_SHORT := 34.0
## The ribbons, each its lit side and its shaded one, where the first comes out as a share of the
## cover's width, how wide each is, how far it hangs and how deep the notch in its end is.
const RIBBONS: Array[Array] = [
	[Color("#8a1824"), Color("#5e0f18")],
	[Color("#c9a24a"), Color("#8c6c2a")],
]
const RIBBON_AT := 0.2
const RIBBON_WIDE := 22.0
const RIBBON_HANGS := 34.0
const RIBBON_NOTCH := 9.0
## The cover's shadow on whatever is under the dialog: how far it reaches and how far down it falls.
const SHADOW := 18
const SHADOW_DOWN := 4.0
## The hills the contours are etched round, each where it stands as a share of the cover, how many
## lines it has, and the turn its lines are given; the ink of a line, and of every fifth one, and
## how far apart they are.
const HILLS: Array[Array] = [
	[Vector2(0.86, 0.9), 15, 0.3],
	[Vector2(0.06, 0.05), 12, 1.7],
	[Vector2(0.55, 1.02), 9, 2.9],
	[Vector2(0.98, 0.12), 8, 4.1],
]
const CONTOUR := Color(0.95, 0.76, 0.31, 0.07)
const CONTOUR_HEAVY := Color(0.95, 0.76, 0.31, 0.13)
const CONTOUR_STEP := 30.0
## The pencil: its body's half width, how long its sharpened point and its eraser's end are, and
## the words on it.
const PENCIL_HALF := 7.0
const PENCIL_POINT := 34.0
const PENCIL_END := 26.0
const PENCIL_WORDS := "THE HOUSE  ·  HB"
## The dividers' steel, how far either leg turns from the way they point, and how long the brass
## stem past their hinge is.
const STEEL := Color("#b9bec6")
const DIVIDERS_OPEN := 0.15
const DIVIDERS_STEM := 26.0
## The wire coil binding a slip along its top, as a pad's pages are bound: how far in from either
## end its first and last loops are and how far apart, how far down from the top edge its holes are
## and how big, how far up over the edge a loop goes, and how far down the picture of it reaches
## under the edge; its steel and the dark of its holes.
const COIL_IN := 18.0
const COIL_STEP := 22.0
const COIL_HOLE := 11.0
const COIL_HOLE_SIZE := Vector2(7.0, 10.0)
const COIL_OVER := 12.0
const COIL_UP := 22.0
const COIL_DOWN := 26.0
const COIL_STEEL := Color("#b9bec6")
const COIL_STEEL_LOW := Color("#5d636d")
const COIL_HOLE_INK := Color("#141820")
## A strip of tape: its paper, and how wide it is as a share of how long.
const TAPE := Color(0.9, 0.84, 0.66, 0.92)
const TAPE_WIDE := 0.32
## How far along the card's edges a photo corner reaches over its corner, how far out past the
## corner it goes, and its gray card, darker toward its fold.
const SLIT := 34.0
const SLIT_OUT := 6.0
const CORNER_CARD := Color("#8a8d94")
const CORNER_FOLD := Color("#5c5f66")

static var _weave: Texture2D


## Where the things laid on the cover lie, in the pane's own room: the pencil from its eraser's end
## to its point, and the dividers' hinge, the way their legs point and how long they are, a length
## of nothing leaving either out; and the middle of the atlas's name across the cover, or nothing
## for the cover's own middle.
class Places:
	var pencil_from := Vector2.ZERO
	var pencil_to := Vector2.ZERO
	var hinge := Vector2.ZERO
	var toward := 0.0
	var reach := 0.0
	var name_at := 0.0

	## The places as words, rounded, for the picture of the cover to be known by them.
	func key() -> String:
		return (
			"%s|%s|%s|%.2f|%d|%d"
			% [pencil_from.round(), pencil_to.round(), hinge.round(), toward, reach, name_at]
		)


## The weave of the cloth, a seamless tile: threads over and under each other two pixels wide,
## each a little lighter or darker than the next.
static func weave() -> Texture2D:
	if _weave == null:
		var image := Image.create(WEAVE_TILE, WEAVE_TILE, false, Image.FORMAT_L8)
		var rolls := RandomNumberGenerator.new()
		rolls.seed = 9
		var rows: Array[float] = []
		var columns: Array[float] = []
		for i: int in WEAVE_TILE:
			rows.append(rolls.randf_range(-0.07, 0.07))
			columns.append(rolls.randf_range(-0.07, 0.07))
		for y: int in WEAVE_TILE:
			for x: int in WEAVE_TILE:
				var level := 0.86 + rolls.randf_range(-0.03, 0.03)
				if ((x >> 1) + (y >> 1)) % 2 == 0:
					level += rows[y >> 1] + (0.06 if y % 2 == 0 else -0.04)
				else:
					level += columns[x >> 1] + (0.06 if x % 2 == 0 else -0.04)
				image.set_pixel(x, y, Color(level, level, level))
		_weave = ImageTexture.create_from_image(image)
	return _weave


## The whole cover over [param rect], the pane's, on [param on], the atlas's name [param name] in
## the foot of its rules, with what is laid on it at [param places]; [param short] where the pane
## fills the screen. [param on] needs its texture repeat on, for the cloth to run its whole size,
## and is drawn on through [param base], the transform it is drawn with already.
static func cover(
	on: CanvasItem,
	rect: Rect2,
	short: bool,
	name: String,
	places: Places,
	base := Transform2D.IDENTITY
) -> void:
	var board := rect.grow(PAST) if short else rect
	var shape := FeltArt.rounded(board, 0.0 if short else ROUND)
	if not short:
		ribbons(on, rect)
		shadow(on, rect)
	cloth(on, shape)
	if not short:
		_ring(on, FeltArt.rounded(rect.grow(-0.5), ROUND), CLOTH.lightened(0.24), 1.0)
		var worn := Color(CLOTH.lightened(0.14), 0.6)
		_ring(on, FeltArt.rounded(rect.grow(-2.0), ROUND - 2.0), worn, 2.0)
	var rule := RULE_SHORT if short else RULE
	contours(on, rect, rect.grow(-rule - RULE_GAP - 2.0))
	var name_at := places.name_at if places.name_at > 0.0 else rect.get_center().x
	rules(on, rect, rule, name, name_at, NAME_SIZE_SHORT if short else NAME_SIZE)
	caps(on, rect, shape, CAP_SHORT if short else CAP)
	if places.reach > 0.0:
		dividers(on, places.hinge, places.toward, places.reach)
	if places.pencil_from != places.pencil_to:
		pencil(on, places.pencil_from, places.pencil_to, base)


## The cloth over [param shape]: its weave, and its wear in patches over that.
static func cloth(on: CanvasItem, shape: PackedVector2Array) -> void:
	on.draw_colored_polygon(shape, CLOTH, _tiled(shape, WEAVE_SPAN), weave())
	var wear := Color(0.0, 0.0, 0.0, WEAR)
	on.draw_colored_polygon(shape, wear, _tiled(shape, WEAR_SPAN), FeltArt.patches())


## The cover's shadow round [param rect], fallen a little down.
static func shadow(on: CanvasItem, rect: Rect2) -> void:
	for i: int in SHADOW:
		var ring := FeltArt.rounded(rect.grow(i + 0.5), ROUND + i)
		for j: int in ring.size():
			ring[j].y += SHADOW_DOWN
		var ink := Color(0.0, 0.0, 0.0, 0.32 * pow(1.0 - float(i) / SHADOW, 2.0))
		_ring(on, ring, ink, 1.0)


## The ribbons out from under the foot of [param rect], each notched at its end, side by side.
static func ribbons(on: CanvasItem, rect: Rect2) -> void:
	var x := rect.position.x + rect.size.x * RIBBON_AT
	var top := rect.end.y - 6.0
	var foot := rect.end.y + RIBBON_HANGS
	for colors: Array in RIBBONS:
		var lit: Color = colors[0]
		var shaded: Color = colors[1]
		var tail := PackedVector2Array(
			[
				Vector2(x, top),
				Vector2(x + RIBBON_WIDE, top),
				Vector2(x + RIBBON_WIDE, foot),
				Vector2(x + RIBBON_WIDE * 0.5, foot - RIBBON_NOTCH),
				Vector2(x, foot),
			]
		)
		on.draw_colored_polygon(_moved(tail, Vector2(3.0, 4.0)), Color(0.0, 0.0, 0.0, 0.4))
		on.draw_polygon(tail, PackedColorArray([shaded, lit, lit, shaded, shaded]))
		x += RIBBON_WIDE + 2.0


## A survey's contours round a few hills, etched faint over the cover, kept inside [param inside]
## so they stop at the rules; every fifth line heavier.
static func contours(on: CanvasItem, rect: Rect2, inside: Rect2) -> void:
	for hill: Array in HILLS:
		var middle: Vector2 = rect.position + rect.size * (hill[0] as Vector2)
		var lines: int = hill[1]
		var turn: float = hill[2]
		for k: int in lines:
			var loop := PackedVector2Array()
			for i: int in 181:
				var a := TAU * i / 180.0
				var reach := (
					(26.0 + CONTOUR_STEP * k)
					* (
						1.0
						+ 0.2 * sin(3.0 * a + turn + k * 0.12)
						+ 0.09 * sin(5.0 * a + turn * 2.0)
						+ 0.04 * sin(9.0 * a)
					)
				)
				loop.append(middle + Vector2.from_angle(a) * reach)
			var heavy := k % 5 == 4
			_clipped(on, loop, inside, CONTOUR_HEAVY if heavy else CONTOUR, 1.3 if heavy else 1.0)


## The House's rules [param rule] in from the edge of [param rect], stamped into the cloth, and the
## atlas's [param name] in a break in their foot round [param name_at] across, the cloth's own
## weave under it.
static func rules(
	on: CanvasItem, rect: Rect2, rule: float, name: String, name_at: float, name_size: int
) -> void:
	var heavy := rect.grow(-rule)
	_stamped(on, _turned(heavy, 0.0), GOLD, 1.8)
	_stamped(on, _turned(heavy.grow(-RULE_GAP), RULE_TURN), Color(GOLD, 0.8), 1.0)
	var font := Type.mark_font()
	var wide := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
	var middle := Vector2(name_at, heavy.end.y - RULE_GAP * 0.5)
	var gap := Rect2(
		middle - Vector2(wide * 0.5 + NAME_ROOM, 7.0), Vector2(wide + NAME_ROOM * 2.0, 14.0)
	)
	cloth(on, _corners(gap))
	var at := Vector2(middle.x - wide * 0.5, middle.y + name_size * 0.35)
	var dent := Color(0.0, 0.0, 0.0, 0.5)
	on.draw_string(
		font, at + Vector2(0.0, 1.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, dent
	)
	on.draw_string(font, at, name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, GOLD)


## A brass cap [param long] along each edge from each corner of [param rect], cut to the cover's
## [param shape], lit toward its corner, a rivet in it.
static func caps(on: CanvasItem, rect: Rect2, shape: PackedVector2Array, long: float) -> void:
	for corner: Array in corners_of(rect):
		var at: Vector2 = corner[0]
		var inward: Vector2 = corner[1]
		var along := at + Vector2(long * inward.x, 0.0)
		var down := at + Vector2(0.0, long * inward.y)
		var cap := PackedVector2Array([at, along, down])
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(cap, shape):
			var fallen := _moved(piece, Vector2(2.0 * inward.x, 2.5))
			on.draw_colored_polygon(fallen, Color(0.0, 0.0, 0.0, 0.4))
			var colors := PackedColorArray()
			for point: Vector2 in piece:
				var t := clampf((absf(point.x - at.x) + absf(point.y - at.y)) / long, 0.0, 1.0)
				var lit := BRASS_HIGH.lerp(BRASS, minf(t * 1.4, 1.0))
				colors.append(lit.lerp(BRASS_LOW, maxf(t - 0.7, 0.0) * 2.0))
			on.draw_polygon(piece, colors)
		on.draw_line(along, down, BRASS_LOW, 1.5, true)
		rivet(on, at + inward * long * 0.28, 2.6)


## A brass rivet's head at [param at], [param size] across from its middle.
static func rivet(on: CanvasItem, at: Vector2, size: float) -> void:
	on.draw_circle(at + Vector2(0.8, 1.4), size, Color(0.0, 0.0, 0.0, 0.45))
	on.draw_circle(at, size, BRASS_LOW)
	on.draw_circle(at - Vector2(0.4, 0.4), size * 0.8, BRASS)
	on.draw_circle(at - Vector2(size * 0.3, size * 0.35), size * 0.32, BRASS_HIGH)


## A pencil of the House's lying from [param from], its eraser's end, to [param to], its point: a
## black hexagonal body in three faces with its name in gold, the cut wood and the lead, a brass
## ferrule and its eraser; its shadow on the cloth. Its name is turned along it through
## [param base], the transform [param on] is drawn with already, and put back to that after.
static func pencil(
	on: CanvasItem, from: Vector2, to: Vector2, base := Transform2D.IDENTITY
) -> void:
	var along := (to - from).normalized()
	var across := Vector2(-along.y, along.x) * PENCIL_HALF
	var body_from := from + along * PENCIL_END
	var body_to := to - along * PENCIL_POINT
	var fallen := _moved(PackedVector2Array([from + across, to, from - across]), Vector2(3.0, 5.0))
	on.draw_colored_polygon(fallen, Color(0.0, 0.0, 0.0, 0.3))
	var faces: Array[Array] = [
		[1.0, 0.33, Color("#2a2a33")],
		[0.33, -0.33, Color("#3c3c48")],
		[-0.33, -1.0, Color("#16161c")],
	]
	for face: Array in faces:
		var a: Vector2 = across * (face[0] as float)
		var b: Vector2 = across * (face[1] as float)
		var side := PackedVector2Array([body_from + a, body_to + a, body_to + b, body_from + b])
		on.draw_colored_polygon(side, face[2])
	var shine := Color(1.0, 1.0, 1.0, 0.12)
	on.draw_line(body_from - across * 0.14, body_to - across * 0.14, shine, 1.0, true)
	on.draw_set_transform_matrix(base * Transform2D(along.angle(), body_from.lerp(body_to, 0.32)))
	var words := Color(HouseTheme.FOIL, 0.9)
	var font := Type.mark_font()
	on.draw_string(font, Vector2(0.0, 3.5), PENCIL_WORDS, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, words)
	on.draw_set_transform_matrix(base)
	var lead := to - along * 9.0
	var wood := PackedVector2Array(
		[body_to + across, lead + across * 0.31, lead - across * 0.31, body_to - across]
	)
	on.draw_colored_polygon(wood, Color("#d9b98a"))
	var cut := PackedVector2Array(
		[
			body_to + across * 0.33,
			lead + across * 0.17,
			lead - across * 0.09,
			body_to - across * 0.33
		]
	)
	on.draw_colored_polygon(cut, Color("#c79f6c"))
	var point := PackedVector2Array([lead + across * 0.31, to, lead - across * 0.31])
	on.draw_colored_polygon(point, Color("#3a3a40"))
	var ferrule := from + along * 12.0
	var band := PackedVector2Array(
		[ferrule + across, body_from + across, body_from - across, ferrule - across]
	)
	on.draw_colored_polygon(band, BRASS)
	for k: int in 3:
		var ring := ferrule.lerp(body_from, (k + 1) / 4.0)
		on.draw_line(ring + across, ring - across, BRASS_LOW, 1.0, true)
	var eraser := PackedVector2Array(
		[from + across * 0.9, ferrule + across, ferrule - across, from - across * 0.9]
	)
	on.draw_colored_polygon(eraser, Color("#b85a5a"))


## A pair of dividers lying open, their brass hinge at [param hinge] and their steel legs
## [param reach] long, pointing [param toward] and a little apart; their shadows on the cloth.
static func dividers(on: CanvasItem, hinge: Vector2, toward: float, reach: float) -> void:
	for turn: float in [-DIVIDERS_OPEN, DIVIDERS_OPEN]:
		var along := Vector2.from_angle(toward + turn)
		var across := Vector2(-along.y, along.x)
		var leg := hinge + along * reach
		var knee := hinge.lerp(leg, 0.82)
		var whole := PackedVector2Array(
			[
				hinge + across * 5.0,
				knee + across * 3.0,
				leg,
				knee - across * 3.0,
				hinge - across * 5.0
			]
		)
		on.draw_colored_polygon(_moved(whole, Vector2(3.0, 5.0)), Color(0.0, 0.0, 0.0, 0.3))
		var upper := PackedVector2Array(
			[hinge + across * 5.0, knee + across * 3.0, knee - across * 3.0, hinge - across * 5.0]
		)
		on.draw_colored_polygon(upper, STEEL.darkened(0.15))
		on.draw_line(
			hinge + across * 2.0, knee + across * 1.2, Color(1.0, 1.0, 1.0, 0.5), 1.0, true
		)
		var tip := PackedVector2Array([knee + across * 3.0, leg, knee - across * 3.0])
		on.draw_colored_polygon(tip, STEEL.darkened(0.35))
	var stem := hinge - Vector2.from_angle(toward) * DIVIDERS_STEM
	on.draw_line(hinge, stem, BRASS_LOW, 5.0, true)
	on.draw_line(hinge, stem, BRASS, 3.0, true)
	on.draw_circle(hinge + Vector2(1.5, 2.5), 10.0, Color(0.0, 0.0, 0.0, 0.35))
	on.draw_circle(hinge, 10.0, BRASS_LOW)
	on.draw_circle(hinge, 8.0, BRASS)
	on.draw_circle(hinge - Vector2(2.5, 2.5), 3.0, BRASS_HIGH)


## A strip of tape [param long] long lying along [param along] across its middle at [param at]: its
## two ends torn, its shadow under it.
static func tape(on: CanvasItem, at: Vector2, along: float, long: float) -> void:
	var half := Vector2(long, long * TAPE_WIDE) * 0.5
	var points := PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y)])
	for i: int in 7:
		var torn := 2.5 * sin(i * 2.3 + at.x) if i % 2 == 0 else 2.0
		points.append(Vector2(half.x + torn, lerpf(-half.y, half.y, (i + 1) / 8.0)))
	points.append(Vector2(half.x, half.y))
	points.append(Vector2(-half.x, half.y))
	for i: int in 7:
		var torn := 2.5 * sin(i * 1.7 + at.y) if i % 2 == 0 else 2.0
		points.append(Vector2(-half.x - torn, lerpf(half.y, -half.y, (i + 1) / 8.0)))
	var place := Transform2D(along, at)
	var laid := place * points
	on.draw_colored_polygon(_moved(laid, Vector2(0.8, 1.6)), Color(0.0, 0.0, 0.0, 0.18))
	on.draw_colored_polygon(laid, TAPE)
	var shine := Color(1.0, 1.0, 1.0, 0.35)
	var edge := Vector2(half.x - 3.0, 2.0 - half.y)
	on.draw_line(place * Vector2(-edge.x, edge.y), place * edge, shine)


## The wire coil binding a slip [param wide] across along its top edge, from its top left corner at
## [param at]: a hole punched through the paper for each loop, and the wire up out of it, over the
## edge and down behind, its shadow on the paper and its shine along its crown.
static func coil(on: CanvasItem, at: Vector2, wide: float) -> void:
	var loops := maxi(int((wide - COIL_IN * 2.0) / COIL_STEP) + 1, 1)
	var first := at.x + (wide - (loops - 1) * COIL_STEP) * 0.5
	for i: int in loops:
		var x := first + i * COIL_STEP
		var hole := Rect2(Vector2(x, at.y + COIL_HOLE) - COIL_HOLE_SIZE * 0.5, COIL_HOLE_SIZE)
		on.draw_rect(hole.grow(1.0), Color(0.0, 0.0, 0.0, 0.12))
		on.draw_rect(hole, COIL_HOLE_INK)
		var wire := PackedVector2Array()
		for k: int in 17:
			var t := k / 16.0
			var point := Vector2(x + lerpf(1.5, -9.0, t), at.y + lerpf(COIL_HOLE + 2.0, -1.0, t))
			point.y -= sin(PI * t) * COIL_OVER
			wire.append(point)
		on.draw_polyline(_moved(wire, Vector2(1.5, 3.0)), Color(0.0, 0.0, 0.0, 0.4), 4.0, true)
		on.draw_polyline(wire, COIL_STEEL_LOW, 4.2, true)
		on.draw_polyline(wire, COIL_STEEL, 2.6, true)
		var shine := _moved(wire.slice(4, 13), Vector2(-0.7, -0.7))
		on.draw_polyline(shine, Color(1.0, 1.0, 1.0, 0.85), 1.1, true)


## The photo corner holding a card at its corner [param corner], [param inward] pointing into the
## card, as an album holds a picture: a pocket of gray card glued to the cover, lighter at its
## corner and darker toward the fold across it, its shadow on the card and its fold catching the
## light.
static func slit(on: CanvasItem, corner: Vector2, inward: Vector2) -> void:
	var at := corner - inward * SLIT_OUT
	var along := at + Vector2(SLIT * inward.x, 0.0)
	var down := at + Vector2(0.0, SLIT * inward.y)
	var flap := PackedVector2Array([at, along, down])
	on.draw_colored_polygon(_moved(flap, inward * 2.0), Color(0.0, 0.0, 0.0, 0.55))
	var lit := CORNER_CARD.lightened(0.12)
	on.draw_polygon(flap, PackedColorArray([lit, CORNER_FOLD, CORNER_FOLD]))
	var grain := Color(0.0, 0.0, 0.0, 0.12)
	on.draw_colored_polygon(flap, grain, _tiled(flap, WEAVE_SPAN), weave())
	on.draw_line(along, down, Color(1.0, 1.0, 1.0, 0.35), 1.2, true)


## Each corner of [param rect] and the way into it from there, clockwise from its top left.
static func corners_of(rect: Rect2) -> Array[Array]:
	return [
		[rect.position, Vector2(1.0, 1.0)],
		[Vector2(rect.end.x, rect.position.y), Vector2(-1.0, 1.0)],
		[rect.end, Vector2(-1.0, -1.0)],
		[Vector2(rect.position.x, rect.end.y), Vector2(1.0, -1.0)],
	]


## A rectangle's outline, its corners turned in a quarter circle [param turn] across as a binder's
## rule turns, or square with none; closed.
static func _turned(rect: Rect2, turn: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if turn <= 0.0:
		points = _corners(rect)
	else:
		# Clockwise from the top left, each corner's quarter circle round the corner itself, from
		# the edge it comes along to the edge it goes on along.
		var corners := _corners(rect)
		for k: int in 4:
			for step: int in 9:
				var a := PI * 0.5 * (k + 1) - PI * 0.5 * step / 8.0
				points.append(corners[k] + Vector2.from_angle(a) * turn)
	points.append(points[0])
	return points


static func _corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		]
	)


## A line stamped into the cloth: gold, with the dark of its dent just under it.
static func _stamped(on: CanvasItem, line: PackedVector2Array, ink: Color, wide: float) -> void:
	on.draw_polyline(_moved(line, Vector2(0.0, 1.0)), Color(0.0, 0.0, 0.0, 0.45), wide, true)
	on.draw_polyline(line, ink, wide, true)


static func _ring(on: CanvasItem, outline: PackedVector2Array, ink: Color, wide: float) -> void:
	var closed := outline.duplicate()
	closed.append(outline[0])
	on.draw_polyline(closed, ink, wide, true)


## [param points] drawn as one line only where they are inside [param inside], in pieces.
static func _clipped(
	on: CanvasItem, points: PackedVector2Array, inside: Rect2, ink: Color, wide: float
) -> void:
	var run := PackedVector2Array()
	for point: Vector2 in points:
		if inside.has_point(point):
			run.append(point)
			continue
		if run.size() > 1:
			on.draw_polyline(run, ink, wide, true)
		run = PackedVector2Array()
	if run.size() > 1:
		on.draw_polyline(run, ink, wide, true)


static func _moved(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point: Vector2 in points:
		moved.append(point + by)
	return moved


## Where a texture whose tile spans [param span] pixels of the cover falls at each of
## [param points].
static func _tiled(points: PackedVector2Array, span: float) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for point: Vector2 in points:
		uvs.append(point / span)
	return uvs
