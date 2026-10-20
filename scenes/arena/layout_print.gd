class_name LayoutPrint
extends Control
## The betting layout the House prints on a table for its map, GAME.md 8.1b, as a casino table
## wears its own, kept to the few marks that say whose table it is: a double border, the House's
## terms in arcs round the Junction, JACKPOT by each Jackpot and the maker's line along the foot.
## A mark round every piece on the floor was tried first and read as noise, so the pieces carry
## nothing printed round them. Drawn once from the map's grid in the room's own inks and laid over
## the felt as the floor's detail layer, at a low enough share of ink that the floor stays muted,
## GAME.md 1.1.
##
## The picture covers the arena from corner to corner, x across and z down it, which is how the
## floor's second UV is laid, see [method Arena._quad].

## How many pixels a cell is drawn at.
const CELL_PIXELS := 64
## How the layout's edges are smoothed as it is drawn, see [method DrawnTexture.of]: its lines,
## arcs and words are smooth of themselves, and what a room prints under them, a lane's arrows, a
## kerb's stones or a playfield's inserts, is polygons, whose edges are not, and a floor worn this
## large shows every pixel along them. Four samples a pixel, while it is drawn and never after.
const SMOOTH := Viewport.MSAA_4X
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
			felt.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX,
		SMOOTH
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
	for rect: Rect2i in grid.jackpots:
		_jackpot(rect)
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


## JACKPOT over a Jackpot, or under it where the floor over it is not open all the way along the
## word, in the serif the House's terms are set in; none where neither is.
func _jackpot(rect: Rect2i) -> void:
	var middle := (Vector2(rect.position) + Vector2(rect.size) * 0.5) * CELL_PIXELS
	var reach := rect.size.y * 0.5 * CELL_PIXELS + CELL_PIXELS * 0.5
	var height := CELL_PIXELS * 0.5
	var half := SERIF.get_string_size("JACKPOT", HORIZONTAL_ALIGNMENT_LEFT, -1, int(height)).x * 0.5
	for side: float in [-1.0, 1.0]:
		var row := rect.position.y - 1 if side < 0.0 else rect.end.y
		var open := true
		for x: int in range(
			floori((middle.x - half) / CELL_PIXELS), ceili((middle.x + half) / CELL_PIXELS)
		):
			open = open and grid.glyph(Vector2i(x, row)) == ArenaGrid.FLOOR
		if open:
			_word("JACKPOT", middle + Vector2(0.0, reach * side), height, SERIF)
			return


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
