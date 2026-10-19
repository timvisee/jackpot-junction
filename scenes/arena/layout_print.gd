class_name LayoutPrint
extends Control
## The betting layout the House prints on a table for its map, GAME.md 8.1b, as a casino table
## wears its own: a double border, the House's terms round the Junction in arcs, a betting circle
## round every coin pad, INSURANCE round the item pads, PASS LINE down the turbo lanes, JACKPOT
## round the Jackpots, a square round each Royal Flush pad, the seats at the spawns, DROP
## by the pits and the maker's line along the foot. Drawn once from the map's grid in the room's
## own inks and laid over the felt as the floor's detail layer, at a low enough share of ink that
## the floor stays muted, GAME.md 1.1.
##
## The picture covers the arena from corner to corner, x across and z down it, which is how the
## floor's second UV is laid, see [method Arena._quad].

## How many pixels a cell is drawn at.
const CELL_PIXELS := 64
## How much of its ink each kind of mark lays on the felt.
const LINE_INK := 0.78
const WORD_INK := 0.72
const FAINT_INK := 0.5
const FONT := preload("res://assets/fonts/BarlowCondensed-ExtraBold.ttf")
const SERIF := preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
## The terms round the Junction, over it and under it.
## Each short enough to lie in the clear floor between the Junction and the coin pads at its
## corners, which on Lucky Crossing is a quarter of the way round.
const OVER := "JUNCTION PAYS THE POT"
const UNDER := "DYING BANKS HALF"
const MAKER := "LAYOUT No. 000001  ·  PRINTED BY THE HOUSE  ·  NOT VALID AS CURRENCY"

var grid: ArenaGrid
## The room's style, which may print the floor under the House's layout, see
## [method RoomStyle.print_under].
var style: RoomStyle
## The inks: the lines and the words.
var line := Color("#E3B341")
var word := Color("#E8D8A0")


## The layout for [param on], in the inks of [param room], ready to be drawn into a texture of
## [method pixels].
static func for_grid(on: ArenaGrid, room: RoomLook) -> LayoutPrint:
	var layout := LayoutPrint.new()
	layout.grid = on
	if room != null:
		layout.line = room.trim
		layout.word = room.marking
	return layout


## Prints the layout for [param on] in [param room]'s inks on [param felt], the floor's material,
## as its detail layer once it has been drawn under [param host]: a frame or two after the room
## goes up, and never without a screen to draw it on. The floor's second UV runs corner to corner
## over the arena, see [method Arena._quad].
static func lay(host: Node, felt: BaseMaterial3D, on: ArenaGrid, room: RoomLook) -> void:
	var layout := for_grid(on, room)
	var kit: Variant = host.get("kit")
	var style: RoomStyle = kit.style if kit is RoomKit else null
	var inks: Array[Color] = []
	if style != null:
		inks = style.layout_inks()
	if inks.size() >= 2:
		layout.line = inks[0]
		layout.word = inks[1]
	layout.style = style
	DrawnTexture.kept(
		host,
		layout,
		pixels(on),
		func(texture: Texture2D) -> void:
			felt.detail_enabled = true
			felt.detail_albedo = texture
			felt.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
			felt.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	)


## The size of the picture for [param on].
static func pixels(on: ArenaGrid) -> Vector2i:
	return Vector2i(on.width * CELL_PIXELS, on.height * CELL_PIXELS)


func _draw() -> void:
	if grid == null:
		return
	if style != null:
		style.print_under(self)
	_border()
	for cell: Vector2i in grid.coin_pads:
		_betting_circle(_at(cell), CELL_PIXELS * 0.64)
	for cell: Vector2i in grid.power_pads:
		_insurance(cell)
	for rect: Rect2i in grid.turbo_sections():
		_pass_line(rect)
	for rect: Rect2i in grid.jackpots:
		_jackpot(rect)
	for cell: Vector2i in grid.flush_pads:
		_square(cell)
	var seat := 1
	for cell: Vector2i in grid.spawns:
		if grid.glyph(cell) == ArenaGrid.SPAWN:
			_seat(cell, seat)
			seat += 1
	for rect: Rect2i in grid.pits:
		_drop(rect)
	for rect: Rect2i in grid.junctions:
		_terms(rect)
	_maker()


## The middle of [param cell] on the picture.
func _at(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2.ONE * 0.5) * CELL_PIXELS


func _ink(color: Color, share: float) -> Color:
	return Color(color, share)


func _border() -> void:
	var inset := CELL_PIXELS * 1.45
	var rect := Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0)
	_rounded(rect, CELL_PIXELS * 0.8, _ink(line, LINE_INK), 4.0)
	var inner := rect.grow(-CELL_PIXELS * 0.16)
	_rounded(inner, CELL_PIXELS * 0.64, _ink(word, FAINT_INK), 2.0)


## A rectangle with rounded corners, as a line.
func _rounded(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var a := rect.position
	var b := rect.end
	draw_line(Vector2(a.x + r, a.y), Vector2(b.x - r, a.y), color, width, true)
	draw_line(Vector2(a.x + r, b.y), Vector2(b.x - r, b.y), color, width, true)
	draw_line(Vector2(a.x, a.y + r), Vector2(a.x, b.y - r), color, width, true)
	draw_line(Vector2(b.x, a.y + r), Vector2(b.x, b.y - r), color, width, true)
	draw_arc(Vector2(a.x + r, a.y + r), r, PI, PI * 1.5, 12, color, width, true)
	draw_arc(Vector2(b.x - r, a.y + r), r, PI * 1.5, TAU, 12, color, width, true)
	draw_arc(Vector2(b.x - r, b.y - r), r, 0.0, PI * 0.5, 12, color, width, true)
	draw_arc(Vector2(a.x + r, b.y - r), r, PI * 0.5, PI, 12, color, width, true)


## A betting circle: a ring with a chip's notches round it and a fainter ring inside.
func _betting_circle(at: Vector2, radius: float) -> void:
	draw_arc(at, radius, 0.0, TAU, 48, _ink(line, LINE_INK), 4.5, true)
	draw_arc(at, radius * 0.86, 0.0, TAU, 40, _ink(word, FAINT_INK), 1.5, true)
	for k: int in 8:
		var angle := k * TAU / 8.0
		var dir := Vector2.from_angle(angle)
		draw_line(
			at + dir * radius * 0.9, at + dir * radius * 1.08, _ink(line, LINE_INK), 5.0, true
		)


func _insurance(cell: Vector2i) -> void:
	var at := _at(cell)
	var half := Vector2.ONE * CELL_PIXELS * 1.05
	_notched(Rect2(at - half, half * 2.0), CELL_PIXELS * 0.22, _ink(line, LINE_INK), 4.5)
	_word("INSURANCE", at + Vector2(0.0, half.y + CELL_PIXELS * 0.32), CELL_PIXELS * 0.34, SERIF)


## A ticket's outline: a rectangle with its corners notched inward.
func _notched(rect: Rect2, notch: float, color: Color, width: float) -> void:
	var a := rect.position
	var b := rect.end
	draw_line(Vector2(a.x + notch, a.y), Vector2(b.x - notch, a.y), color, width, true)
	draw_line(Vector2(a.x + notch, b.y), Vector2(b.x - notch, b.y), color, width, true)
	draw_line(Vector2(a.x, a.y + notch), Vector2(a.x, b.y - notch), color, width, true)
	draw_line(Vector2(b.x, a.y + notch), Vector2(b.x, b.y - notch), color, width, true)
	draw_arc(a, notch, 0.0, PI * 0.5, 8, color, width, true)
	draw_arc(Vector2(b.x, a.y), notch, PI * 0.5, PI, 8, color, width, true)
	draw_arc(b, notch, PI, PI * 1.5, 8, color, width, true)
	draw_arc(Vector2(a.x, b.y), notch, PI * 1.5, TAU, 8, color, width, true)


## PASS LINE down a turbo lane: its two edges ruled and the words set along it.
func _pass_line(rect: Rect2i) -> void:
	var a := Vector2(rect.position) * CELL_PIXELS
	var b := Vector2(rect.end) * CELL_PIXELS
	var long_down := (b.y - a.y) >= (b.x - a.x)
	var color := _ink(line, FAINT_INK + 0.1)
	if long_down:
		draw_dashed_line(Vector2(a.x, a.y), Vector2(a.x, b.y), color, 2.5, 14.0, true, true)
		draw_dashed_line(Vector2(b.x, a.y), Vector2(b.x, b.y), color, 2.5, 14.0, true, true)
		_word_turned("PASS LINE", Vector2((a.x + b.x) * 0.5, (a.y + b.y) * 0.5), -PI * 0.5)
	else:
		draw_dashed_line(Vector2(a.x, a.y), Vector2(b.x, a.y), color, 2.5, 14.0, true, true)
		draw_dashed_line(Vector2(a.x, b.y), Vector2(b.x, b.y), color, 2.5, 14.0, true, true)
		_word_turned("PASS LINE", Vector2((a.x + b.x) * 0.5, (a.y + b.y) * 0.5), 0.0)


func _jackpot(rect: Rect2i) -> void:
	var box := Rect2(Vector2(rect.position) * CELL_PIXELS, Vector2(rect.size) * CELL_PIXELS)
	box = box.grow(CELL_PIXELS * 0.3)
	_notched(box, CELL_PIXELS * 0.28, _ink(line, LINE_INK), 4.5)
	var middle := box.get_center()
	_word(
		"JACKPOT",
		middle - Vector2(0.0, box.size.y * 0.5 + CELL_PIXELS * 0.36),
		CELL_PIXELS * 0.5,
		SERIF
	)
	_word(
		"PAYS ALL IT HOLDS",
		middle + Vector2(0.0, box.size.y * 0.5 + CELL_PIXELS * 0.3),
		CELL_PIXELS * 0.26,
		FONT
	)


## A square round a Royal Flush pad, the pad's own shape.
func _square(cell: Vector2i) -> void:
	var at := _at(cell)
	var half := Vector2.ONE * 0.62 * CELL_PIXELS
	_rounded(Rect2(at - half, half * 2.0), CELL_PIXELS * 0.16, _ink(line, LINE_INK), 4.5)


func _seat(cell: Vector2i, seat: int) -> void:
	var at := _at(cell)
	draw_arc(at, CELL_PIXELS * 0.95, 0.0, TAU, 48, _ink(word, FAINT_INK), 2.0, true)
	_word("SEAT %d" % seat, at + Vector2(0.0, CELL_PIXELS * 1.25), CELL_PIXELS * 0.3, FONT)


## DROP over a pit, where the floor over it is open.
func _drop(rect: Rect2i) -> void:
	var over := Vector2i(rect.position.x, rect.position.y - 1)
	if grid.glyph(over) != ArenaGrid.FLOOR:
		return
	var at := Vector2((rect.position.x + rect.size.x * 0.5) * CELL_PIXELS, over.y * CELL_PIXELS)
	# Not inside the Junction's terms, which it would be printed over.
	for junction: Rect2i in grid.junctions:
		var middle := (Vector2(junction.position) + Vector2(junction.size) * 0.5) * CELL_PIXELS
		if at.distance_to(middle) < (junction.size.x * 0.5 + 1.2) * CELL_PIXELS:
			return
	_word("DROP", at + Vector2(0.0, CELL_PIXELS * 0.62), CELL_PIXELS * 0.32, FONT)


## The House's terms in arcs round the Junction, letter by letter, leaving out any letter that
## would fall on a wall, a pit or a pad.
func _terms(rect: Rect2i) -> void:
	var middle := (Vector2(rect.position) + Vector2(rect.size) * 0.5) * CELL_PIXELS
	var radius := (rect.size.x * 0.5 + 0.62) * CELL_PIXELS
	draw_arc(middle, radius - CELL_PIXELS * 0.3, 0.0, TAU, 96, _ink(line, LINE_INK), 4.0, true)
	draw_arc(middle, radius + CELL_PIXELS * 0.3, 0.0, TAU, 96, _ink(line, FAINT_INK), 2.5, true)
	_arc_words(OVER, middle, radius, -PI * 0.5, true)
	_arc_words(UNDER, middle, radius, PI * 0.5, false)


func _arc_words(text: String, middle: Vector2, radius: float, around: float, over: bool) -> void:
	var font_size := int(CELL_PIXELS * 0.28)
	var widths: Array[float] = []
	var total := 0.0
	for letter: String in text:
		var width := SERIF.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		widths.append(width)
		total += width
	var span := total / radius
	var angle := around - span * 0.5 if over else around + span * 0.5
	for i: int in text.length():
		var step := widths[i] / radius
		var at_angle := angle + (step * 0.5 if over else -step * 0.5)
		var at := middle + Vector2.from_angle(at_angle) * radius
		var cell := Vector2i(floori(at.x / CELL_PIXELS), floori(at.y / CELL_PIXELS))
		if grid.glyph(cell) == ArenaGrid.FLOOR:
			var turn := at_angle + PI * 0.5 if over else at_angle - PI * 0.5
			draw_set_transform(at, turn)
			draw_string(
				SERIF,
				Vector2(-widths[i] * 0.5, font_size * 0.35),
				text[i],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				_ink(word, WORD_INK)
			)
			draw_set_transform(Vector2.ZERO)
		angle += step if over else -step


func _maker() -> void:
	var at := Vector2(size.x * 0.5, size.y - CELL_PIXELS * 1.05)
	_word(MAKER, at, CELL_PIXELS * 0.2, FONT, FAINT_INK)


func _word(text: String, at: Vector2, height: float, font: Font, share := WORD_INK) -> void:
	var font_size := int(height)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		at + Vector2(-width * 0.5, font_size * 0.35),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		_ink(word, share)
	)


func _word_turned(text: String, at: Vector2, angle: float) -> void:
	draw_set_transform(at, angle)
	_word(text, Vector2.ZERO, CELL_PIXELS * 0.3, FONT, FAINT_INK + 0.05)
	draw_set_transform(Vector2.ZERO)
