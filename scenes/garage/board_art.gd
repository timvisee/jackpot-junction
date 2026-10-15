class_name BoardArt
extends RefCounted
## The pegboards of the kart dialog, GAME.md 4.4a, and the frame round it: a stand either side of
## the lift, a black pegboard with a hole every inch in a red powder-coated steel frame, screwed at
## its corners, on legs and casters. On it a hook for each part of the kart, a shadow board's: the
## piece worn hanging from a peg on a black clip over its outline painted in yellow, the part
## stenciled beside it and the piece's name on a strip of masking tape, and a screw eye at its edge
## nearer the kart, which a rope is tied to while it is looked at, see [KartDialog]. Where the last
## hook on the right would be, the shuffle is a machine's plate rather than a hook, so it is never
## taken for one: hazard stripes round dark steel, a big red push button with a die's five on it,
## and SHUFFLE stenciled by it. Each board's foot says half the Garage's motto, EVERY PART and BACK
## IN ITS PLACE, which the dialog's frame says whole.
##
## Still, so drawn into the bay's picture, see [BayCover]; only what hangs on a hook, what its tape
## says and the shuffle's push button are drawn over it, see [PartHook]. The rack of a part's pieces
## is a pegboard of the same make, see [PartTray] and [method draw_rack].

## The boards, left and right of the lift, how thick their frames are, and the room between holes.
const BOARDS: Array[Rect2] = [Rect2(24.0, 150.0, 404.0, 700.0), Rect2(1432.0, 150.0, 404.0, 700.0)]
const FRAME := 18.0
const STEP := 26.0
## A hook's room on its board, and where each part's is: which board and which row, the kart's back
## to the left, its front and top to the right, the card back and the shuffle at their feet.
const SLOT := Vector2(348.0, 148.0)
const ROW := 164.0
const HOOKS: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(1, 0),
	Vector2i(0, 0),
	Vector2i(0, 2),
	Vector2i(0, 1),
	Vector2i(1, 2),
	Vector2i(0, 3),
	Vector2i(1, 3),
]
## The shuffle's hook, past the card back's.
const SHUFFLE := 7
## How wide a hook's tape is, and how far in from its edge its words start.
const TAPE_WIDE := 186.0
## The dialog's frame round the bay, while there is room round it: how thick, and what its foot
## says.
const EDGE := 26.0
const MOTTO := "THE GARAGE  ·  EVERY PART BACK IN ITS PLACE"
const HALVES: Array[String] = ["EVERY PART", "BACK IN ITS PLACE"]
## The shuffle's plate: how wide its hazard stripes are round it, how big its push button is, and
## what is stenciled by it.
const HAZARD := 14.0
const PUSH := 36.0
## The reel the push button's die faces run down on as it rolls, see [method draw_push]: how big
## round its drum is and how far apart its faces are along it, as shares of the button, and how
## far out from the button's middle its pips are seen, how much nearer they fade out.
const REEL_DRUM := 0.95
const REEL_PITCH := 1.5
const REEL_REACH := 30.0
const REEL_FADE := 10.0
const SHUFFLE_WORD := "SHUFFLE"
const SHUFFLE_SAYS := "PARTS AND COLOR AT RANDOM"

const PEG_RED := Color("#a3262b")
const PEGBOARD := Color("#1b1c20")
const HOLE := Color("#060607")
const PAINT := Color("#e8c23c")
const CLIP := Color("#2a2a30")
const STAND := Color("#3a3d44")
const CASTER := Color("#141416")
const STEEL_FRAME := Color("#2c2f35")
const STEEL_FRAME_HIGH := Color("#5a5f68")
const HAZARD_BLACK := Color("#1b1b1f")
const PUSH_RED := Color("#d8352a")
const PIP := Color("#f6eedc")
const STENCIL_PLATE := Color("#141416")


## Whether the hook of [param part] is on the left board, toward the kart's back.
static func on_left(part: int) -> bool:
	return HOOKS[part].x == 0


static func hook_rect(part: int) -> Rect2:
	var place := HOOKS[part]
	var board := BOARDS[place.x]
	return Rect2(board.position + Vector2(28.0, 30.0 + place.y * ROW), SLOT)


## The outline a piece hangs in: the end of its hook away from the kart.
static func outline_of(part: int) -> Rect2:
	var slot := hook_rect(part)
	var x := slot.position.x + 8.0 if on_left(part) else slot.end.x - 136.0
	return Rect2(Vector2(x, slot.position.y + 26.0), Vector2(128.0, 114.0))


## Where the piece itself is drawn in its outline.
static func picture_of(part: int) -> Rect2:
	var room := outline_of(part).grow(-10.0)
	if part == 4:
		return Rect2(room.position + Vector2(0.0, 30.0), Vector2(room.size.x, 36.0))
	return room


## The peg its clip hangs from, over the middle of its outline.
static func peg_of(part: int) -> Vector2:
	var outline := outline_of(part)
	return Vector2(outline.get_center().x, outline.position.y - 14.0)


## The screw eye a rope is tied to: the hook's edge nearer the kart.
static func eye_of(part: int) -> Vector2:
	var slot := hook_rect(part)
	var x := slot.end.x - 8.0 if on_left(part) else slot.position.x + 8.0
	return Vector2(x, slot.get_center().y)


## Where its words start: past its outline.
static func words_from(part: int) -> float:
	var slot := hook_rect(part)
	return slot.position.x + (150.0 if on_left(part) else 18.0)


## The strip of masking tape the piece's name is written on.
static func tape_of(part: int) -> Rect2:
	var slot := hook_rect(part)
	return Rect2(Vector2(words_from(part), slot.position.y + 58.0), Vector2(TAPE_WIDE, 44.0))


## The shuffle's plate, over its hook's room.
static func shuffle_plate() -> Rect2:
	return hook_rect(SHUFFLE).grow(-4.0)


## The middle of the shuffle's push button, at the plate's end nearer the kart.
static func push_of() -> Vector2:
	var inside := shuffle_plate().grow(-HAZARD)
	return Vector2(inside.position.x + 58.0, inside.get_center().y)


# --- the boards ----------------------------------------------------------------------------------


## Both boards on their stands, and every hook on them, on [param on] in the stage's space.
static func draw_boards(on: CanvasItem) -> void:
	for i: int in BOARDS.size():
		_board(on, BOARDS[i], HALVES[i])
	for part: int in SHUFFLE:
		_hook(on, part)
	_shuffle(on)


## A board on its stand: legs and casters under it, its red frame, the pegboard in it with its
## holes, a screw at each corner, and half the motto stenciled on its foot.
static func _board(on: CanvasItem, board: Rect2, half: String) -> void:
	for x: float in [board.position.x + 40.0, board.end.x - 52.0]:
		on.draw_rect(Rect2(Vector2(x, board.end.y - 10.0), Vector2(12.0, 34.0)), STAND)
		on.draw_rect(Rect2(Vector2(x - 14.0, board.end.y + 20.0), Vector2(40.0, 8.0)), STAND)
		on.draw_circle(Vector2(x + 6.0, board.end.y + 36.0), 11.0, CASTER)
		on.draw_circle(Vector2(x + 6.0, board.end.y + 36.0), 4.0, BayArt.CHROME_LOW)
	BayArt.shadow(on, board, 10.0, 14, 0.45)
	var shape := FeltArt.rounded(board, 10.0)
	var colors := PackedColorArray()
	for point: Vector2 in shape:
		var t := (point.y - board.position.y) / board.size.y
		colors.append(PEG_RED.lightened(0.08).lerp(PEG_RED.darkened(0.25), t))
	on.draw_polygon(shape, colors)
	on.draw_colored_polygon(shape, Color(1, 1, 1, 0.05), _uvs(shape, 120.0), FeltArt.grain())
	BayArt.ring(on, board.grow(-1.0), 10.0, Color(1, 0.8, 0.8, 0.3), 1.5)
	var inside := board.grow(-FRAME)
	on.draw_rect(inside.grow(2.0), Color(0, 0, 0, 0.5))
	on.draw_rect(inside, PEGBOARD)
	_holes(on, inside)
	for corner: Vector2 in [
		inside.position,
		Vector2(inside.end.x, inside.position.y),
		inside.end,
		Vector2(inside.position.x, inside.end.y)
	]:
		BayArt.screw(on, corner + (inside.get_center() - corner).sign() * 12.0, 5.0, 0.8)
	BayArt.words(
		on,
		Vector2(board.get_center().x, board.end.y - FRAME * 0.5),
		half,
		12,
		Color(PAINT, 0.9),
		Type.display_font()
	)


## A hole every [constant STEP] across [param rect], each one dark with a glint under it, as two
## triangle meshes rather than a draw for each.
static func _holes(on: CanvasItem, rect: Rect2) -> void:
	var glints := PackedVector2Array()
	var holes := PackedVector2Array()
	var y := rect.position.y + STEP * 0.5
	while y < rect.end.y:
		var x := rect.position.x + STEP * 0.5
		while x < rect.end.x:
			holes.append(Vector2(x, y))
			x += STEP
		y += STEP
	for at: Vector2 in holes:
		glints.append(at + Vector2(0.0, 0.8))
	_dots(on, glints, 3.6, Color(1, 1, 1, 0.06))
	_dots(on, holes, 3.4, HOLE)


## A round dot of [param reach] at each of [param points], all in one mesh.
static func _dots(on: CanvasItem, points: PackedVector2Array, reach: float, ink: Color) -> void:
	var corners := PackedVector2Array()
	var order := PackedInt32Array()
	var sides := 8
	for at: Vector2 in points:
		var first := corners.size()
		corners.append(at)
		for k: int in sides:
			corners.append(at + Vector2.from_angle(TAU * k / sides) * reach)
		for k: int in sides:
			order.append_array([first, first + 1 + k, first + 1 + (k + 1) % sides])
	var inks := PackedColorArray()
	inks.resize(corners.size())
	inks.fill(ink)
	RenderingServer.canvas_item_add_triangle_array(on.get_canvas_item(), order, corners, inks)


## A hook's still part: its outline painted on the board, the peg and clip over it, the part
## stenciled beside it with its picture, the tape for its name, and the screw eye at its edge.
static func _hook(on: CanvasItem, part: int) -> void:
	var outline := outline_of(part)
	var painted := FeltArt.rounded(outline, 10.0)
	painted.append(painted[0])
	on.draw_polyline(painted, Color(PAINT, 0.8), 3.0, true)
	var slot := hook_rect(part)
	var word := BayArt.part_word(part)
	var from := words_from(part)
	var wide := BayArt.wide_of(word, 22, Type.mark_font())
	BayArt.left(on, Vector2(from, slot.position.y + 32.0), word, 22, PAINT, Type.mark_font())
	DressArt.draw_into(
		on,
		Rect2(Vector2(from + wide + 8.0, slot.position.y + 19.0), Vector2(26.0, 26.0)),
		part,
		Color(PAINT, 0.7)
	)
	BayArt.draw_tape(on, tape_of(part))
	peg_and_clip(on, peg_of(part))
	var eye := eye_of(part)
	on.draw_arc(eye, 6.0, 0.0, TAU, 16, BayArt.CHROME, 2.5, true)
	on.draw_circle(eye + Vector2(0.0, 7.0), 2.0, BayArt.CHROME_LOW)


## A peg out of the board at [param at] and the black clip hanging from it.
static func peg_and_clip(on: CanvasItem, at: Vector2) -> void:
	on.draw_line(at, at + Vector2(0.0, 12.0), BayArt.CHROME_LOW, 3.0, true)
	on.draw_circle(at, 3.6, BayArt.CHROME)
	on.draw_circle(at - Vector2(1.0, 1.0), 1.4, BayArt.CHROME_HIGH)
	var clip := Rect2(at + Vector2(-11.0, 10.0), Vector2(22.0, 12.0))
	on.draw_rect(Rect2(clip.position + Vector2(1.0, 2.0), clip.size), Color(0, 0, 0, 0.45))
	on.draw_rect(clip, CLIP)
	on.draw_line(
		clip.position + Vector2(1.0, 1.0),
		Vector2(clip.end.x - 1.0, clip.position.y + 1.0),
		Color(1, 1, 1, 0.3),
		1.0
	)


## The shuffle's plate, bolted over the last hook's room on the right: hazard stripes round a plate
## of dark steel with a screw at each corner, the yellow collar its push button stands in, the
## dark well under the button, and SHUFFLE stenciled past it with what it does. The button itself
## is drawn over it, lit and pressed as it is, see [method draw_push].
static func _shuffle(on: CanvasItem) -> void:
	var plate := shuffle_plate()
	BayArt.shadow(on, plate, 6.0, 12, 0.55, 5.0)
	stripes(on, plate, Color(HouseTheme.FOIL, 0.92), 16.0, 34.0)
	var inside := plate.grow(-HAZARD)
	var shape := FeltArt.rounded(inside, 4.0)
	var colors := PackedColorArray()
	for point: Vector2 in shape:
		var t := (point.y - inside.position.y) / inside.size.y
		colors.append(STEEL_FRAME.lightened(0.1).lerp(STEEL_FRAME.darkened(0.25), t))
	on.draw_polygon(shape, colors)
	BayArt.ring(on, inside, 4.0, Color(0, 0, 0, 0.6), 2.0)
	for corner: Vector2 in [
		inside.position,
		Vector2(inside.end.x, inside.position.y),
		inside.end,
		Vector2(inside.position.x, inside.end.y)
	]:
		BayArt.screw(on, corner + (inside.get_center() - corner).sign() * 9.0, 4.0, 0.6)
	var push := push_of()
	on.draw_circle(push + Vector2(0.0, 3.0), PUSH + 13.0, Color(0, 0, 0, 0.5))
	on.draw_circle(push, PUSH + 13.0, HouseTheme.FOIL)
	on.draw_arc(push, PUSH + 13.0, 0.0, TAU, 48, Color(0, 0, 0, 0.45), 2.0, true)
	on.draw_circle(push, PUSH + 4.0, HAZARD_BLACK)
	var from := push.x + PUSH + 26.0
	BayArt.left(on, Vector2(from, push.y - 14.0), SHUFFLE_WORD, 32, PAINT, Type.mark_font())
	BayArt.left(
		on, Vector2(from, push.y + 20.0), SHUFFLE_SAYS, 12, Color(BayArt.ENAMEL, 0.85), Type.STRONG
	)


## The shuffle's push button on [param on], its middle at [param at]: a red cap with a die's
## [param face] on it, standing up out of its collar, lit for [param lit] and pushed down into it
## for [param down]. Rolling, the faces of [param reel] run down through it instead, as a slot
## machine's do, [param run] faces on from the first, see [method _draw_reel].
static func draw_push(
	on: CanvasItem,
	at: Vector2,
	lit: bool,
	down: bool,
	face := 5,
	reel := PackedInt32Array(),
	run := 0.0,
	blur := 0.0
) -> void:
	var red := PUSH_RED.lightened(0.18) if lit else PUSH_RED
	if lit:
		on.draw_circle(at, PUSH + 22.0, Color(PUSH_RED, 0.16))
	var top := at + Vector2(0.0, 2.0 if down else -3.0)
	if not down:
		on.draw_circle(at + Vector2(0.0, 3.0), PUSH, red.darkened(0.45))
	on.draw_circle(top, PUSH, red)
	on.draw_arc(top, PUSH - 1.0, 0.0, TAU, 48, red.darkened(0.3), 2.0, true)
	on.draw_circle(top + Vector2(-PUSH * 0.32, -PUSH * 0.36), PUSH * 0.34, Color(1, 1, 1, 0.16))
	if not reel.is_empty():
		_draw_reel(on, top, reel, run, blur)
		return
	for pip: Vector2 in NameDie.PIPS[clampi(face, 1, 6) - 1]:
		on.draw_circle(top + pip * PUSH * 0.42, PUSH * 0.13, PIP)


## A die's faces on a slot machine's reel turning down behind the push button's cap at [param top]:
## each face of [param reel] a pitch above the one before, the whole [param run] faces on, so the
## next comes in over the top as the last goes out under the bottom. Round the drum the pips flatten
## and fade toward its top and bottom, out of sight before the cap's edge, and are drawn out along
## it by [param blur], 0 to 1, as it spins fast. A face at rest is seen round, as on the cap.
static func _draw_reel(
	on: CanvasItem, top: Vector2, reel: PackedInt32Array, run: float, blur: float
) -> void:
	var drum := PUSH * REEL_DRUM
	var pitch := PUSH * REEL_PITCH
	var resting := cos(PUSH * 0.42 / drum)
	var nearest := roundi(run)
	for k: int in range(maxi(nearest - 1, 0), mini(nearest + 2, reel.size())):
		for pip: Vector2 in NameDie.PIPS[clampi(reel[k], 1, 6) - 1]:
			var round_by := ((run - k) * pitch + pip.y * PUSH * 0.42) / drum
			if absf(round_by) >= PI * 0.5:
				continue
			var y := sin(round_by) * drum
			var shade := clampf((REEL_REACH - absf(y)) / REEL_FADE, 0.0, 1.0)
			if shade <= 0.0:
				continue
			var tall := minf(cos(round_by) / resting, 1.0) * (1.0 + blur)
			on.draw_set_transform(top + Vector2(pip.x * PUSH * 0.42, y), 0.0, Vector2(1.0, tall))
			on.draw_circle(Vector2.ZERO, PUSH * 0.13, Color(PIP, shade))
	on.draw_set_transform(Vector2.ZERO)


## Hazard stripes across [param band], [param ink] on black, [param wide] each and [param every]
## apart, leaning back as far as the band is tall.
static func stripes(on: CanvasItem, band: Rect2, ink: Color, wide := 14.0, every := 32.0) -> void:
	on.draw_rect(band, HAZARD_BLACK)
	var room := PackedVector2Array(
		[
			band.position,
			Vector2(band.end.x, band.position.y),
			band.end,
			Vector2(band.position.x, band.end.y)
		]
	)
	var lean := band.size.y
	var x := band.position.x - lean
	while x < band.end.x:
		var stripe := PackedVector2Array(
			[
				Vector2(x, band.end.y),
				Vector2(x + wide, band.end.y),
				Vector2(x + wide + lean, band.position.y),
				Vector2(x + lean, band.position.y)
			]
		)
		var cut := Geometry2D.intersect_polygons(stripe, room)
		if not cut.is_empty() and cut[0].size() >= 3:
			on.draw_colored_polygon(cut[0], ink)
		x += every


# --- the rack of a part's pieces -----------------------------------------------------------------


## The rack a part's pieces hang on, as the dialog's [PartTray] is drawn, in [param rack]: a
## pegboard of the boards' make set down over the bench, its red frame [param band] deep along its
## top for its words and [param edge] round the rest, the board in it with its holes, and its
## shadow on the bench.
static func draw_rack(on: CanvasItem, rack: Rect2, band: float, edge: float) -> void:
	BayArt.shadow(on, rack, 10.0, 16, 0.55, 8.0)
	var shape := FeltArt.rounded(rack, 10.0)
	var colors := PackedColorArray()
	for point: Vector2 in shape:
		var t := (point.y - rack.position.y) / rack.size.y
		colors.append(PEG_RED.lightened(0.08).lerp(PEG_RED.darkened(0.25), t))
	on.draw_polygon(shape, colors)
	on.draw_colored_polygon(shape, Color(1, 1, 1, 0.05), _uvs(shape, 120.0), FeltArt.grain())
	BayArt.ring(on, rack.grow(-1.0), 10.0, Color(1, 0.8, 0.8, 0.3), 1.5)
	var inside := Rect2(
		rack.position + Vector2(edge, band), rack.size - Vector2(edge * 2.0, band + edge)
	)
	on.draw_rect(inside.grow(2.0), Color(0, 0, 0, 0.5))
	on.draw_rect(inside, PEGBOARD)
	_holes(on, inside)


## A piece's place on the rack, round [param outline]: painted in yellow, or the house's gold for
## the one [param worn], and its peg and clip over it where it [param hangs]; a piece not won yet
## is an outline painted in dashes with only a peg, nothing hung there. Its paint is worn into the
## board, see [method on_board], so it is the same drawn into a kept picture as drawn as itself.
static func draw_place(on: CanvasItem, outline: Rect2, hangs: bool, worn: bool) -> void:
	if hangs:
		var painted := FeltArt.rounded(outline, 8.0)
		painted.append(painted[0])
		on.draw_polyline(
			painted, HouseTheme.FOIL if worn else on_board(0.8), 3.5 if worn else 2.5, true
		)
		peg_and_clip(on, Vector2(outline.get_center().x, outline.position.y - 14.0))
		return
	var ink := on_board(0.4)
	var corners: Array[Vector2] = [
		outline.position,
		Vector2(outline.end.x, outline.position.y),
		outline.end,
		Vector2(outline.position.x, outline.end.y)
	]
	for k: int in 4:
		on.draw_dashed_line(corners[k], corners[(k + 1) % 4], ink, 2.5, 8.0)
	var peg := Vector2(outline.get_center().x, outline.position.y - 14.0)
	on.draw_circle(peg, 3.6, BayArt.CHROME)
	on.draw_circle(peg - Vector2(1.0, 1.0), 1.4, BayArt.CHROME_HIGH)


## The board's yellow paint worn down to [param share] of itself on the black pegboard, solid: a
## see-through paint drawn into a kept picture loses its alpha twice over and comes out fainter.
static func on_board(share: float) -> Color:
	return PEGBOARD.lerp(PAINT, share)


## A small black plate with stenciled words on it, as the motto's on the frame, in [param plate]:
## a button of the rack's, lit while the mouse is over it, faded while it cannot be pressed.
static func draw_stencil_plate(on: CanvasItem, plate: Rect2, lit: bool, faded: bool) -> void:
	BayArt.box(on, Rect2(plate.position + Vector2(1.0, 2.0), plate.size), 4.0, Color(0, 0, 0, 0.5))
	BayArt.box(
		on, plate, 4.0, STENCIL_PLATE.lightened(0.14) if lit and not faded else STENCIL_PLATE
	)
	BayArt.ring(on, plate.grow(-2.0), 3.0, Color(PAINT, 0.12 if faded else 0.3), 1.0)


## A chevron stenciled in [param ink] in the middle of [param box], pointing [param way], -1 left
## and 1 right.
static func chevron(on: CanvasItem, box: Rect2, way: int, ink: Color) -> void:
	var middle := box.get_center()
	var reach := minf(box.size.x, box.size.y) * 0.32
	var tip := middle + Vector2(reach * 0.6 * way, 0.0)
	var back := middle - Vector2(reach * 0.6 * way, 0.0)
	var arm := reach * 0.42
	on.draw_colored_polygon(
		PackedVector2Array(
			[
				back + Vector2(0.0, -reach),
				back + Vector2(arm * way, -reach),
				tip + Vector2(arm * way * 0.5, 0.0),
				back + Vector2(arm * way, reach),
				back + Vector2(0.0, reach),
				tip - Vector2(arm * way * 0.5, 0.0)
			]
		),
		ink
	)


# --- the frame round the dialog ------------------------------------------------------------------


## The frame round the bay while the dialog leaves room round it: dark steel [constant EDGE] thick
## round [param inside], lit along its top, a rivet every so often, a band of hazard stripes along
## its foot with the motto stenciled across it, and its shadow on the screen under it.
static func draw_frame(on: CanvasItem, outside: Rect2) -> void:
	BayArt.shadow(on, outside, 14.0, 18, 0.5, 6.0, false)
	var inside := outside.grow(-EDGE)
	# A ring rather than a plate the bay is drawn over, so a bay filmed under it shows through.
	var rim := FeltArt.rounded(outside, 14.0)
	var hole := FeltArt.rounded(inside, 4.0)
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var grain := PackedColorArray()
	for line: PackedVector2Array in [rim, hole]:
		for point: Vector2 in line:
			var t := (point.y - outside.position.y) / outside.size.y
			points.append(point)
			colors.append(STEEL_FRAME.lightened(0.12).lerp(STEEL_FRAME.darkened(0.2), t))
			grain.append(Color(1, 1, 1, 0.04))
	var order := PackedInt32Array()
	var around := rim.size()
	for i: int in around:
		var j := (i + 1) % around
		order.append_array([i, j, around + j, i, around + j, around + i])
	var item := on.get_canvas_item()
	RenderingServer.canvas_item_add_triangle_array(item, order, points, colors)
	RenderingServer.canvas_item_add_triangle_array(
		item,
		order,
		points,
		grain,
		_uvs(points, 90.0),
		PackedInt32Array(),
		PackedFloat32Array(),
		FeltArt.grain().get_rid()
	)
	BayArt.ring(on, outside.grow(-1.0), 14.0, Color(STEEL_FRAME_HIGH, 0.7), 1.5)
	BayArt.ring(on, inside.grow(2.0), 4.0, Color(0, 0, 0, 0.6), 3.0)
	# The hazard band along the foot, the motto over it on a black plate.
	var band := Rect2(
		Vector2(inside.position.x, inside.end.y + 4.0), Vector2(inside.size.x, EDGE - 8.0)
	)
	stripes(on, band, Color(HouseTheme.FOIL, 0.85))
	var plate_wide := BayArt.wide_of(MOTTO, 13, Type.display_font()) + 40.0
	var plate := Rect2(
		Vector2(band.get_center().x - plate_wide * 0.5, band.position.y - 2.0),
		Vector2(plate_wide, band.size.y + 4.0)
	)
	BayArt.box(on, plate, 4.0, STENCIL_PLATE)
	BayArt.words(on, plate.get_center(), MOTTO, 13, PAINT, Type.display_font())
	# Rivets along the top and the sides.
	var rivets := PackedVector2Array()
	var along := outside.position.x + 60.0
	while along < outside.end.x - 40.0:
		rivets.append(Vector2(along, outside.position.y + EDGE * 0.5))
		along += 120.0
	var down := outside.position.y + 80.0
	while down < outside.end.y - 60.0:
		rivets.append(Vector2(outside.position.x + EDGE * 0.5, down))
		rivets.append(Vector2(outside.end.x - EDGE * 0.5, down))
		down += 120.0
	_dots(on, BayArt.moved(rivets, Vector2(0.6, 1.2)), 4.4, Color(0, 0, 0, 0.5))
	_dots(on, rivets, 4.0, STEEL_FRAME_HIGH)


static func _uvs(points: PackedVector2Array, tile: float) -> PackedVector2Array:
	var found := PackedVector2Array()
	for p: Vector2 in points:
		found.append(p / tile)
	return found
