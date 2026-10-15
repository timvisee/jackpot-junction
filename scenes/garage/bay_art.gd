class_name BayArt
extends RefCounted
## How the kart dialog of GAME.md 4.4a is drawn over the Garage's bay, which is built in 3D with
## the kart in it, see [BaySet] and [KartStage], as an old workshop rather than a showroom: a
## pegboard stand either side with a hook for each part of the kart, see [BoardArt], a stack of
## tires, boxes and a drum of oil in the corners, and the workbench along the foot. The title on an
## enamel sign, the seats' keys on a key board, the colors in spray cans on the bench with a paint
## chip card saying which, and Back as a printed plate.
##
## All of it laid out on one stage of [constant STAGE], scaled as a whole to the screen, see
## [KartDialog]; the still parts drawn once and kept, see [BayCover].

## The stage everything is laid out on, and the parts of it.
const STAGE := Vector2(1860.0, 1032.0)
const SIGN := Rect2(30.0, 20.0, 380.0, 100.0)
const RAIL := Rect2(470.0, 20.0, 1070.0, 22.0)
const KEYS_FROM := 598.0
const KEY_WIDE := 200.0
const TAG_WIDE := 152.0
## A key or tag the mouse is on: hung nearer straight, by this much of its swing, and picked out in
## a soft white, see [method _picked_out].
const POINTED_SWING := 0.4
const POINTED_EDGE := Color(1.0, 1.0, 1.0, 0.7)
const KEY_GAP := 18.0
const BACK := Rect2(1626.0, 30.0, 200.0, 57.0)
## Where the kart is filmed: from under the lamps to the bench, between the boards, for room round
## it on the floor for its moves and its laps, see [KartStage].
const VIEW := Rect2(430.0, 110.0, 1000.0, 790.0)
const DRUM := Rect2(1700.0, 868.0, 124.0, 158.0)
const TIRES := Vector2(40.0, 976.0)
const BENCH_TOP := Rect2(430.0, 906.0, 1000.0, 22.0)
const APRON := Rect2(446.0, 928.0, 968.0, 98.0)
const CANS_FROM := 490.0
const CAN_GAP := 60.0
const CAN_FOOT := 908.0
const CAN := Vector2(56.0, 112.0)
const NAME_TAPE := Rect2(468.0, 956.0, 580.0, 52.0)
## The die that rolls a name, inside the right end of the name's tape.
const DIE := Rect2(990.0, 958.0, 48.0, 48.0)
const PLATE_AT := Vector2(1146.0, 944.0)
const PLATE_WIDE := 250.0
## The paint chip card by the cans, and how it leans.
const CHIP := Rect2(946.0, 800.0, 118.0, 104.0)
const CHIP_LEAN := -0.035
## The rack of a part's pieces, over the bench and clear of the boards' feet.
const TRAY := Rect2(230.0, 852.0, 1400.0, 176.0)
## Where the binds that turn the kart are shown: their middle, over the bench's right end.
const TURN_HINT := Vector2(1290.0, 878.0)
## How many bands a shadow fades out in, see [method shadow].
const SHADOW_BANDS := 6

const LIFT_RED := Color("#b82e29")
const WALL_HIGH := Color("#62656a")
const WALL_LOW := Color("#3e4842")
const RED_LINE := Color("#8e2a26")
const FLOOR := Color("#4b4e54")
const MANILA := Color("#d9bf86")
const MANILA_DARK := Color("#b89a5c")
const STAMP := Color("#b8322b")
const TWINE := Color("#e4dcc4")
const TIMBER := Color("#8c6b47")
const BURNT := Color("#2a1c10")
const CARDBOARD := Color("#9e7a57")
const BOX_TAPE := Color("#d6c79e")
const RUBBER := Color("#1a1a1c")
const DRUM_INK := Color("#385970")
const ENAMEL := Color("#efe6cf")
const ENAMEL_RED := Color("#a3262b")
const MARKER := Color("#1d1c22")
const MASKING := Color("#e4d8b4")
const LAMP_SHADE := Color("#3d6b4a")
const BULB := Color("#fff3c4")
const STEEL := Color("#6d7178")
const STEEL_SHELF := Color("#7d828a")
const STEEL_HIGH := Color("#a9aeb6")
const GALVANIZED := Color("#a7adb5")
const GALVANIZED_LOW := Color("#6c727a")
const COMPARTMENT := Color("#2a2d33")
const CHROME := Color("#c3c8cf")
const CHROME_HIGH := Color("#f4f6f9")
const CHROME_LOW := Color("#5b6068")
const SPRAY_BAND := Color("#ece6d6")
const CHIP_PAPER := Color("#f4efe2")
const SPRAY_SHOULDER := Color("#b9bec6")
const NOZZLE := Color("#e8e8ec")
const DIE_FACE := Color("#f2eee4")
const DIE_PIP := Color("#c23a2c")
const WORDS_ON_WALL := Color(1.0, 1.0, 1.0, 0.62)
## The boxes in the corners, and what is written on them, and on the drum.
const BOXES: Array[Array] = [
	[Rect2(236.0, 958.0, 118.0, 70.0), "BOLTS", 0.03],
	[Rect2(1556.0, 950.0, 126.0, 76.0), "SPARES", -0.03],
	[Rect2(1570.0, 890.0, 96.0, 62.0), "??", 0.04],
]
const DRUM_WORD := "OIL"
const TITLE := "YOUR KART"
const UNDER_TITLE := "THE GARAGE  ·  BAY 1"
const KEYS := "KEYS"
const COLOR_WORD := "COLOR"
const NAME_WORD := "NAME"
const PLATE_WORD := "PLATE"

## What everything is drawn under: the stage's place and scale on whatever it is drawn into, which a
## piece turned on its own goes back to after, see [method turn_at], so a picture kept of it at the
## screen's size keeps its scale and its place.
static var base := Transform2D.IDENTITY


## The spray can of color [param color]'s slot on the bench.
static func can_rect(color: int) -> Rect2:
	var foot := Vector2(CANS_FROM + color * CAN_GAP, CAN_FOOT)
	return Rect2(foot - Vector2(CAN.x * 0.5, CAN.y), CAN)


# --- the bay itself ------------------------------------------------------------------------------


## Everything drawn over the bay that never changes, in stage space on [param on]: the storage,
## the pegboards and their hooks, the bench and the words painted round it, the sign and the key
## board's rail; the wall, the floor, the lamps and the lift the kart is filmed among in 3D behind
## them, see [BaySet].
static func draw_bay(on: CanvasItem) -> void:
	_storage(on)
	BoardArt.draw_boards(on)
	_bench(on)
	_sign(on)
	_rail(on)


## The storage in the corners, under the pegboards: tires stacked with a box of bolts on the left,
## boxes and a drum of oil on the right.
static func _storage(on: CanvasItem) -> void:
	for k: int in 2:
		var tire := Rect2(TIRES + Vector2((k % 2) * 6.0, -k * 52.0), Vector2(180.0, 50.0))
		on.draw_colored_polygon(FeltArt.rounded(tire.grow(1.0), 20.0), Color(0, 0, 0, 0.5))
		on.draw_colored_polygon(FeltArt.rounded(tire, 20.0), RUBBER)
		var tread := PackedVector2Array()
		for t: int in 9:
			var x := tire.position.x + 20.0 + t * 18.0
			tread.append_array(
				[Vector2(x, tire.position.y + 6.0), Vector2(x - 6.0, tire.end.y - 6.0)]
			)
		on.draw_multiline(tread, Color(1, 1, 1, 0.07), 3.0)
		on.draw_line(
			tire.position + Vector2(18.0, 4.0),
			Vector2(tire.end.x - 18.0, tire.position.y + 4.0),
			Color(1, 1, 1, 0.12),
			2.0
		)
	for box: Array in BOXES:
		_box(on, box[0], box[1], box[2])
	var drum := DRUM
	var corners := PackedVector2Array(
		[
			drum.position,
			Vector2(drum.end.x, drum.position.y),
			drum.end,
			Vector2(drum.position.x, drum.end.y)
		]
	)
	on.draw_polygon(
		corners,
		PackedColorArray(
			[
				DRUM_INK.lightened(0.15),
				DRUM_INK.darkened(0.35),
				DRUM_INK.darkened(0.35),
				DRUM_INK.lightened(0.15)
			]
		)
	)
	for y: float in [drum.position.y + 46.0, drum.position.y + 104.0]:
		on.draw_rect(
			Rect2(Vector2(drum.position.x - 3.0, y), Vector2(drum.size.x + 6.0, 8.0)),
			DRUM_INK.darkened(0.45)
		)
	on.draw_rect(
		Rect2(drum.position - Vector2(3.0, 4.0), Vector2(drum.size.x + 6.0, 8.0)),
		DRUM_INK.darkened(0.25)
	)
	words(
		on,
		drum.get_center() + Vector2(0.0, 6.0),
		DRUM_WORD,
		26,
		Color(1, 1, 1, 0.55),
		Type.mark_font()
	)


## A cardboard box of parts, taped shut, written on in marker.
static func _box(on: CanvasItem, box: Rect2, label: String, turn: float) -> void:
	turn_at(on, box.get_center(), turn)
	var local := Rect2(-box.size * 0.5, box.size)
	on.draw_rect(Rect2(local.position + Vector2(3.0, 4.0), local.size), Color(0, 0, 0, 0.4))
	on.draw_rect(local, CARDBOARD)
	on.draw_rect(Rect2(local.position, Vector2(local.size.x, 6.0)), CARDBOARD.lightened(0.15))
	on.draw_rect(Rect2(Vector2(-10.0, local.position.y), Vector2(20.0, local.size.y)), BOX_TAPE)
	words(on, Vector2(0.0, 8.0), label, 20, MARKER, marker_font())
	unturn(on)


## The workbench along the foot: its timber top the cans stand on, its apron, and the words
## stenciled on it.
static func _bench(on: CanvasItem) -> void:
	on.draw_rect(Rect2(APRON.position + Vector2(6.0, 8.0), APRON.size), Color(0, 0, 0, 0.4))
	on.draw_rect(APRON, TIMBER.darkened(0.2))
	var grain := PackedVector2Array()
	for k: int in 3:
		var y := APRON.position.y + 24.0 + k * 30.0
		grain.append_array([Vector2(APRON.position.x, y), Vector2(APRON.end.x, y)])
	on.draw_multiline(grain, Color(0.2, 0.1, 0.0, 0.25), 1.5)
	on.draw_rect(BENCH_TOP, TIMBER.lightened(0.08))
	on.draw_rect(Rect2(BENCH_TOP.position, Vector2(BENCH_TOP.size.x, 4.0)), TIMBER.lightened(0.3))
	on.draw_rect(
		Rect2(
			BENCH_TOP.position + Vector2(0.0, BENCH_TOP.size.y - 3.0),
			Vector2(BENCH_TOP.size.x, 3.0)
		),
		Color(0, 0, 0, 0.3)
	)
	draw_tape(on, NAME_TAPE)
	left(
		on,
		Vector2(NAME_TAPE.position.x + 4.0, APRON.position.y + 14.0),
		NAME_WORD,
		12,
		WORDS_ON_WALL,
		Type.display_font()
	)
	left(on, PLATE_AT + Vector2(0.0, -16.0), PLATE_WORD, 12, WORDS_ON_WALL, Type.display_font())


## The title on an enamel sign, screwed to the wall, a chip off its corner.
static func _sign(on: CanvasItem) -> void:
	var sign := SIGN
	shadow(on, sign, 14.0, 10, 0.45, 4.0)
	box(on, sign, 14.0, ENAMEL)
	box(on, sign.grow(-6.0), 10.0, ENAMEL_RED)
	ring(on, sign.grow(-11.0), 7.0, ENAMEL, 2.0)
	words(
		on, sign.get_center() + Vector2(0.0, -10.0), TITLE, 52, Color("#f6eedc"), Type.mark_font()
	)
	words(
		on,
		sign.get_center() + Vector2(0.0, 30.0),
		UNDER_TITLE,
		14,
		Color("#f6eedc", 0.8),
		Type.display_font()
	)
	on.draw_colored_polygon(
		PackedVector2Array(
			[
				sign.end - Vector2(40.0, 8.0),
				sign.end - Vector2(18.0, 6.0),
				sign.end - Vector2(26.0, 18.0)
			]
		),
		Color("#2a2a2e")
	)
	for c: Vector2 in [
		sign.position + Vector2(14.0, 14.0),
		Vector2(sign.end.x - 14.0, sign.position.y + 14.0),
		Vector2(sign.position.x + 14.0, sign.end.y - 14.0),
		sign.end - Vector2(14.0, 14.0)
	]:
		screw(on, c, 4.0, 0.7)


## The key board's timber rail, with a hook under it for every seat's key.
static func _rail(on: CanvasItem) -> void:
	on.draw_rect(Rect2(RAIL.position + Vector2(2.0, 4.0), RAIL.size), Color(0, 0, 0, 0.4))
	on.draw_rect(RAIL, TIMBER)
	on.draw_rect(Rect2(RAIL.position, Vector2(RAIL.size.x, 4.0)), TIMBER.lightened(0.2))
	words(
		on,
		Vector2(RAIL.position.x + 40.0, RAIL.get_center().y + 1.0),
		KEYS,
		13,
		Color(BURNT, 0.8),
		Type.display_font()
	)


# --- the keys, cans, chip and Back ---------------------------------------------------------------


## What a part is stenciled as on its hook, the card back after the kart's own and the shuffle's
## after that.
static func part_word(part: int) -> String:
	return ["PAINT", "HAT", "FLAG", "TRAIL", "PLATE", "MARKS", "CARD BACK", "SHUFFLE"][part]


## A seat's key tag hanging from its hook at [param hook]: a plastic fob in the seat's
## [param color], a split ring through it, the seat over its name. Hanging straight and lit for
## the seat the dialog is on, picked out in gold, see [method _picked_out]; swung on its hook and
## dark otherwise.
static func draw_key(
	on: CanvasItem,
	hook: Vector2,
	color: Color,
	heading: String,
	named: String,
	here: bool,
	swing: float,
	pointed := false
) -> void:
	on.draw_line(hook, hook + Vector2(0.0, 10.0), CHROME, 3.0, true)
	on.draw_arc(hook + Vector2(4.0, 10.0), 4.0, 0.0, PI, 8, CHROME, 3.0, true)
	turn_at(
		on, hook + Vector2(0.0, 12.0), 0.0 if here else swing * (POINTED_SWING if pointed else 1.0)
	)
	var body := Rect2(Vector2(-14.0, 12.0), Vector2(KEY_WIDE, 56.0 if here else 50.0))
	var shape := FeltArt.rounded(body, 14.0)
	on.draw_colored_polygon(moved(shape, Vector2(3.0, 5.0)), Color(0, 0, 0, 0.45))
	var outline := HouseTheme.FOIL if here else POINTED_EDGE
	if here or pointed:
		_picked_out(on, shape, false, outline)
	var dark := 0.0 if here else (0.2 if pointed else 0.45)
	on.draw_colored_polygon(shape, color.darkened(dark))
	on.draw_colored_polygon(shape, Color(1, 1, 1, 0.06), _uvs(shape, 120.0), FeltArt.grain())
	if here or pointed:
		_picked_out(on, shape, true, outline)
	on.draw_circle(Vector2(0.0, 26.0), 7.0, Color("#202024"))
	on.draw_arc(Vector2(0.0, 10.0), 12.0, 0.0, TAU, 28, CHROME, 2.4, true)
	var ink := Color.WHITE if here else Color(1, 1, 1, 0.6)
	left(on, Vector2(16.0, 30.0), heading.to_upper(), 12, Color(ink, 0.75), Type.display_font())
	var size := 20
	while wide_of(named, size, strong_font()) > KEY_WIDE - 34.0 and size > 12:
		size -= 1
	left(on, Vector2(16.0, 52.0), named, size, ink, strong_font())
	unturn(on)


## A profile's manila tag on a string, [constant TAG_WIDE] wide, its name in pen across the middle
## of it, as big as fits and squeezed a little past that for the longest, hung from [param top].
## Hanging straight and picked out in gold for the profile the dialog is on, see
## [method _picked_out]; swung on its string and a little darker otherwise.
static func draw_profile_tag(
	on: CanvasItem, top: Vector2, named: String, here: bool, swing: float, pointed := false
) -> void:
	on.draw_circle(top, 4.0, CHROME)
	var turn := 0.0 if here else swing * (POINTED_SWING if pointed else 1.0)
	turn_at(on, top, turn)
	# Its cut corners as a luggage tag's, the left one longer, as wide as the tag is.
	var half := TAG_WIDE * 0.5 - 8.0
	var paper := PackedVector2Array()
	for corner: Vector2 in [
		Vector2(0.21, 14),
		Vector2(0.82, 14),
		Vector2(1, 26),
		Vector2(1, 60),
		Vector2(-1, 60),
		Vector2(-1, 26)
	]:
		paper.append(Vector2(corner.x * half, corner.y))
	on.draw_colored_polygon(moved(paper, Vector2(2.0, 4.0)), Color(0, 0, 0, 0.4))
	var outline := HouseTheme.FOIL if here else POINTED_EDGE
	if here or pointed:
		_picked_out(on, paper, false, outline)
	var paper_tone := MANILA.lightened(0.1) if here else MANILA.darkened(0.0 if pointed else 0.06)
	on.draw_colored_polygon(paper, paper_tone)
	if here or pointed:
		_picked_out(on, paper, true, outline)
	on.draw_line(Vector2.ZERO, Vector2(0.0, 22.0), TWINE, 1.4, true)
	on.draw_circle(Vector2(0.0, 22.0), 5.0, MANILA_DARK)
	on.draw_circle(Vector2(0.0, 22.0), 2.6, Color("#202024"))
	var room := half * 2.0 - 16.0
	var size := 18
	while wide_of(named, size, hand_font()) > room and size > 11:
		size -= 1
	var squeeze := minf(room / maxf(wide_of(named, size, hand_font()), 1.0), 1.0)
	on.draw_set_transform_matrix(
		base * Transform2D(turn, top) * Transform2D(0.0, Vector2(squeeze, 1.0), 0.0, Vector2.ZERO)
	)
	words(on, Vector2(0.0, 44.0), named, size, MARKER, hand_font())
	unturn(on)


## A key or tag picked out in [param ink]: the one the kart dialog is on in the house's gold, the
## one the mouse is on in a softer white, see [constant POINTED_EDGE]. A glow round [param shape]
## under it, as faint as the ink is, and over it, for [param over], a line of the ink round its
## edge, thinner for a fainter ink.
static func _picked_out(
	on: CanvasItem, shape: PackedVector2Array, over: bool, ink: Color = HouseTheme.FOIL
) -> void:
	if over:
		var edge := shape.duplicate()
		edge.append(shape[0])
		on.draw_polyline(edge, ink, 3.0 if ink.a >= 1.0 else 2.0, true)
		return
	for grow: float in [11.0, 8.0, 5.0, 2.5]:
		for ring: PackedVector2Array in Geometry2D.offset_polygon(
			shape, grow, Geometry2D.JOIN_ROUND
		):
			on.draw_colored_polygon(ring, Color(ink, 0.12 * ink.a))


## A spray can of [param ink] standing on the bench, its foot at the bottom middle of
## [param slot]: the one in use lifted, its cap off, on a spot of the house's gold; one somebody
## else in the room has, a tag on it with who.
static func draw_can(
	on: CanvasItem, slot: Rect2, ink: Color, chosen: bool, taken_by: String
) -> void:
	var foot := Vector2(slot.get_center().x, slot.end.y)
	var lift := -8.0 if chosen else 0.0
	var body := Rect2(foot + Vector2(-20.0, -66.0 + lift), Vector2(40.0, 66.0))
	on.draw_rect(Rect2(body.position + Vector2(3.0, 3.0), body.size), Color(0, 0, 0, 0.4))
	var corners := PackedVector2Array(
		[
			body.position,
			Vector2(body.end.x, body.position.y),
			body.end,
			Vector2(body.position.x, body.end.y)
		]
	)
	on.draw_polygon(
		corners,
		PackedColorArray(
			[ink.lightened(0.1), ink.darkened(0.45), ink.darkened(0.45), ink.lightened(0.1)]
		)
	)
	on.draw_rect(
		Rect2(body.position + Vector2(6.0, 0.0), Vector2(6.0, body.size.y)), Color(1, 1, 1, 0.2)
	)
	var band := Rect2(body.position + Vector2(0.0, 26.0), Vector2(body.size.x, 22.0))
	on.draw_rect(band, SPRAY_BAND)
	on.draw_rect(Rect2(band.position + Vector2(5.0, 7.0), Vector2(30.0, 8.0)), ink)
	var shoulder := PackedVector2Array(
		[
			body.position,
			Vector2(body.end.x, body.position.y),
			body.position + Vector2(32.0, -10.0),
			body.position + Vector2(8.0, -10.0)
		]
	)
	on.draw_colored_polygon(shoulder, SPRAY_SHOULDER)
	if not chosen:
		var cap := Rect2(body.position + Vector2(5.0, -34.0), Vector2(30.0, 25.0))
		box(on, cap, 5.0, ink.darkened(0.12))
		on.draw_rect(
			Rect2(cap.position + Vector2(4.0, 3.0), Vector2(5.0, cap.size.y - 6.0)),
			Color(1, 1, 1, 0.2)
		)
	else:
		on.draw_rect(Rect2(body.position + Vector2(15.0, -20.0), Vector2(10.0, 11.0)), NOZZLE)
		# Its spot on the bench painted gold under it, so the cursor's frame is the only frame.
		box(on, Rect2(foot + Vector2(-24.0, -3.0), Vector2(48.0, 7.0)), 3.0, HouseTheme.FOIL)
	if not taken_by.is_empty():
		var at := body.position + Vector2(30.0, 8.0)
		on.draw_line(at, at + Vector2(8.0, 16.0), TWINE, 1.2, true)
		turn_at(on, at + Vector2(8.0, 16.0), 0.25)
		var paper := Rect2(-16.0, 0.0, 32.0, 20.0)
		box(on, paper, 4.0, MANILA)
		var size := 12
		while wide_of(taken_by, size, Type.display_font()) > paper.size.x - 4.0 and size > 8:
			size -= 1
		words(on, Vector2(0.0, 10.0), taken_by, size, MARKER, Type.display_font())
		unturn(on)


## The strip of masking tape the name is written on, with its torn ends: of [param fill], and with
## a soft [param glow] round it where it has one, as the rack's place the cursor is on has, see
## [method PartTray.draw_place].
static func draw_tape(
	on: CanvasItem, tape: Rect2, fill: Color = MASKING, glow: Color = Color.TRANSPARENT
) -> void:
	var strip := PackedVector2Array(
		[
			tape.position + Vector2(-4.0, 2.0),
			Vector2(tape.end.x, tape.position.y - 2.0),
			tape.end + Vector2(4.0, 0.0),
			Vector2(tape.position.x - 2.0, tape.end.y + 2.0)
		]
	)
	if glow.a > 0.0:
		for grow: float in [10.0, 7.0, 4.5, 2.0]:
			for ring: PackedVector2Array in Geometry2D.offset_polygon(
				strip, grow, Geometry2D.JOIN_ROUND
			):
				on.draw_colored_polygon(ring, Color(glow, glow.a * 0.2))
	on.draw_colored_polygon(moved(strip, Vector2(2.0, 3.0)), Color(0, 0, 0, 0.35))
	on.draw_colored_polygon(strip, fill)
	on.draw_colored_polygon(strip, Color(0.4, 0.3, 0.1, 0.12), _uvs(strip, 60.0), FeltArt.grain())


## The paint chip card standing on the bench by the cans, in [param card]: COLOR over a swatch of
## [param ink] with [param named] under it, and [param says] what it is to the kart, worn or tried
## on. With no color yet, [param ink] clear, the swatch is empty but for a "?".
static func draw_chip(on: CanvasItem, card: Rect2, ink: Color, named: String, says: String) -> void:
	turn_at(on, card.get_center(), CHIP_LEAN)
	var local := Rect2(-card.size * 0.5, card.size)
	box(on, Rect2(local.position + Vector2(3.0, 4.0), local.size), 4.0, Color(0, 0, 0, 0.45))
	box(on, local, 4.0, CHIP_PAPER)
	left(
		on,
		local.position + Vector2(9.0, 11.0),
		COLOR_WORD,
		10,
		Color(MARKER, 0.6),
		Type.display_font()
	)
	var swatch := Rect2(local.position + Vector2(7.0, 21.0), Vector2(local.size.x - 14.0, 44.0))
	if ink.a > 0.0:
		on.draw_rect(swatch, ink)
		on.draw_rect(Rect2(swatch.position, Vector2(swatch.size.x, 7.0)), Color(1, 1, 1, 0.2))
	else:
		on.draw_rect(swatch, Color(MARKER, 0.07))
		words(on, swatch.get_center(), "?", 30, Color(MARKER, 0.4), hand_font())
	on.draw_rect(swatch, Color(0, 0, 0, 0.3), false, 1.0)
	var size := 17
	while wide_of(named, size, Type.STRONG) > local.size.x - 16.0 and size > 11:
		size -= 1
	left(on, Vector2(local.position.x + 9.0, swatch.end.y + 13.0), named, size, MARKER, Type.STRONG)
	left(
		on,
		Vector2(local.position.x + 9.0, swatch.end.y + 29.0),
		says.to_upper(),
		10,
		Color(MARKER, 0.6),
		Type.display_font()
	)
	unturn(on)


## A turntable's arrow in [param box], for turning the kart: a flat ring seen from the side, most
## of the way round, an arrowhead at its end.
static func draw_turntable(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var middle := box.get_center()
	var reach := Vector2(box.size.x * 0.44, box.size.y * 0.3)
	var from := PI * 0.2
	var to := PI * 1.75
	var line := PackedVector2Array()
	for k: int in 25:
		var angle := lerpf(from, to, k / 24.0)
		line.append(middle + Vector2(cos(angle) * reach.x, sin(angle) * reach.y))
	on.draw_polyline(line, ink, 2.4, true)
	var along := Vector2(-sin(to) * reach.x, cos(to) * reach.y).normalized()
	var side := along.orthogonal()
	var tip := line[line.size() - 1]
	on.draw_colored_polygon(
		PackedVector2Array(
			[tip + along * 6.0, tip - along * 2.0 + side * 5.0, tip - along * 2.0 - side * 5.0]
		),
		ink
	)


## Back, as a plate the Department of Karts printed, as the bench's own is, in [param plate]: its
## paper, its hairline, a screw in each top corner with DEPT. OF KARTS between them, and
## [param words_on] in its lettering. Lifted off the wall a little for [param lit], pressed onto
## it for [param down].
static func draw_back(
	on: CanvasItem, plate: Rect2, words_on: String, lit: bool, down: bool
) -> void:
	var off := Vector2(0.0, 2.0) if down else Vector2(0.0, -2.0) if lit else Vector2.ZERO
	var round_by := plate.size.y * 0.15
	box(
		on,
		Rect2(plate.position + Vector2(3.0, 6.0 if lit and not down else 4.0), plate.size),
		round_by,
		Color(0, 0, 0, 0.5)
	)
	turn_at(on, plate.position + off, 0.0)
	var paper := StyleBoxFlat.new()
	paper.bg_color = LicensePlate.PLATE.lightened(0.06) if lit else LicensePlate.PLATE
	paper.set_corner_radius_all(roundi(round_by))
	paper.anti_aliasing = true
	on.draw_style_box(paper, Rect2(Vector2.ZERO, plate.size))
	LicensePlate.dress(on, plate.size)
	var face := LicensePlate.lettering(plate.size.y)
	var size := roundi(plate.size.y * 0.5)
	on.draw_string(
		face,
		Vector2(0.0, plate.size.y * 0.6 + size * Type.CAP_HEIGHT * 0.5),
		words_on,
		HORIZONTAL_ALIGNMENT_CENTER,
		plate.size.x,
		size,
		LicensePlate.INK
	)
	unturn(on)


## The twine from a tag's hole at [param from] to its part on the kart at [param to], sagging a
## little, a knot at either end, as one strip of triangles on [param on].
static func draw_twine(on: CanvasItem, from: Vector2, to: Vector2, ink: Color) -> void:
	var sag := Vector2(0.0, 30.0 + from.distance_to(to) * 0.08)
	var middle := (from + to) * 0.5 + sag
	var line := PackedVector2Array()
	for k: int in 25:
		var t := k / 24.0
		line.append(from.lerp(middle, t).lerp(middle.lerp(to, t), t))
	on.draw_polyline(moved(line, Vector2(2.0, 3.0)), Color(0, 0, 0, 0.4), 3.0, true)
	on.draw_polyline(line, ink, 2.2, true)
	on.draw_circle(to, 5.0, ink)
	on.draw_arc(to, 8.0, 0.0, TAU, 16, Color(ink, 0.7), 1.6, true)
	on.draw_circle(from, 4.0, ink)


# --- helpers -------------------------------------------------------------------------------------


## Draws on [param on] from now on turned [param turn] about [param at], under [member base].
static func turn_at(on: CanvasItem, at: Vector2, turn: float) -> void:
	on.draw_set_transform_matrix(base * Transform2D(turn, at))


## Back to drawing under [member base] alone.
static func unturn(on: CanvasItem) -> void:
	on.draw_set_transform_matrix(base)


## A control that draws [member paint] under [member by], for a picture to be kept of it at the
## screen's size: [member BayArt.base] is that for as long as it draws.
class Drawn:
	extends Control

	var paint: Callable
	var by := Transform2D.IDENTITY

	func _init() -> void:
		# The grain and the patterns are tiles, laid over and over.
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		BayArt.base = by
		draw_set_transform_matrix(by)
		paint.call(self)
		BayArt.base = Transform2D.IDENTITY
		draw_set_transform_matrix(Transform2D.IDENTITY)


## The picture of [param key], [param logical] big on [param host] and drawn by [param paint] in
## its own space, kept at the screen's pixels; null until it is ready, the [param group] told then.
static func kept(
	host: CanvasItem, key: String, logical: Vector2, paint: Callable, group: StringName
) -> Texture2D:
	var by := maxf(KeptPictures.scale_of(host), 0.25)
	var pixels := Vector2i((logical * by).ceil())
	var made := func() -> Control:
		var drawn := Drawn.new()
		drawn.paint = paint
		drawn.by = Transform2D(0.0, Vector2.ONE * by, 0.0, Vector2.ZERO)
		return drawn
	return KeptPictures.of(host, "%s|%.3f" % [key, by], pixels, made, group)


static func marker_font() -> Font:
	return load("res://assets/fonts/PermanentMarker-Regular.ttf") as Font


static func typed_font() -> Font:
	return load("res://assets/fonts/CourierPrime-Regular.ttf") as Font


static func hand_font() -> Font:
	return load("res://assets/fonts/Caveat-Variable.ttf") as Font


static func strong_font() -> Font:
	return Type.STRONG


## [param text] centered on [param at].
static func words(
	on: CanvasItem, at: Vector2, text: String, size: int, ink: Color, face: Font
) -> void:
	var wide := wide_of(text, size, face)
	on.draw_string(
		face, at - Vector2(wide * 0.5, -size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink
	)


## [param text] from [param at] on, its middle at its height.
static func left(
	on: CanvasItem, at: Vector2, text: String, size: int, ink: Color, face: Font
) -> void:
	on.draw_string(
		face, at + Vector2(0.0, size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink
	)


static func wide_of(text: String, size: int, face: Font) -> float:
	return face.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func box(on: CanvasItem, rect: Rect2, radius: float, fill: Color) -> void:
	on.draw_colored_polygon(FeltArt.rounded(rect, radius), fill)


static func ring(on: CanvasItem, rect: Rect2, radius: float, ink: Color, wide := 1.0) -> void:
	var line := FeltArt.rounded(rect, maxf(radius, 0.0))
	line.append(line[0])
	on.draw_polyline(line, ink, wide, true)


## A soft shadow under [param rect], rounded [param radius], dropped [param drop] and fading from
## [param strength] at its edge to nothing [param reach] out: one mesh, the dark under it and a
## band out to each of [constant SHADOW_BANDS] rings, which shades smoothly at any scale, where a
## line a pixel wide for every step out striped it once it was scaled. Not [param filled], the dark
## is only round it, for a thing with a hole in it that something shows through.
static func shadow(
	on: CanvasItem,
	rect: Rect2,
	radius: float,
	reach := 16,
	strength := 0.32,
	drop := 4.0,
	filled := true
) -> void:
	var corners := PackedVector2Array([rect.get_center() + Vector2(0.0, drop)])
	var inks := PackedColorArray([Color(0, 0, 0, strength if filled else 0.0)])
	var around := 0
	for k: int in SHADOW_BANDS + 1:
		var out := float(reach) * k / SHADOW_BANDS
		var line := FeltArt.rounded(rect.grow(out), radius + out)
		around = line.size()
		var ink := Color(0, 0, 0, strength * pow(1.0 - float(k) / SHADOW_BANDS, 2.0))
		for point: Vector2 in line:
			corners.append(point + Vector2(0.0, drop))
			inks.append(ink)
	var order := PackedInt32Array()
	for i: int in around:
		order.append_array([0, 1 + i, 1 + (i + 1) % around])
	for k: int in SHADOW_BANDS:
		var inner := 1 + k * around
		var outer := inner + around
		for i: int in around:
			var j := (i + 1) % around
			order.append_array([inner + i, outer + i, outer + j, inner + i, outer + j, inner + j])
	RenderingServer.canvas_item_add_triangle_array(on.get_canvas_item(), order, corners, inks)


## A soft round glow of [param ink] at [param at], fading out to nothing [param reach] from it.
static func glow(on: CanvasItem, at: Vector2, reach: float, ink: Color) -> void:
	var points := PackedVector2Array([at])
	var inks := PackedColorArray([ink])
	var order := PackedInt32Array()
	for k: int in 33:
		points.append(at + Vector2.from_angle(TAU * k / 32.0) * reach)
		inks.append(Color(ink, 0.0))
	for k: int in 32:
		order.append_array([0, k + 1, k + 2])
	RenderingServer.canvas_item_add_triangle_array(on.get_canvas_item(), order, points, inks)


static func screw(on: CanvasItem, at: Vector2, size: float, turn: float) -> void:
	on.draw_circle(at + Vector2(0.6, 1.2), size, Color(0, 0, 0, 0.5))
	on.draw_circle(at, size, CHROME_LOW)
	on.draw_circle(at - Vector2(0.5, 0.5), size * 0.8, CHROME)
	var along := Vector2.from_angle(turn) * size * 0.6
	on.draw_line(at - along, at + along, CHROME_LOW, 1.4, true)


static func moved(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var found := PackedVector2Array()
	for p: Vector2 in points:
		found.append(p + by)
	return found


static func _uvs(points: PackedVector2Array, tile: float) -> PackedVector2Array:
	var found := PackedVector2Array()
	for p: Vector2 in points:
		found.append(p / tile)
	return found
