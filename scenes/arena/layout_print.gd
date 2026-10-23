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

## How many pixels a cell is laid out at, and drawn at on a screen no taller than
## [constant SHARP_HEIGHT], see [method screen_scale].
const CELL_PIXELS := 64
## The tallest screen a print is drawn at its own pixels for, and the most times as many a side it
## is drawn at for a taller one, within [constant MOST_PIXELS] in all, see [method screen_scale].
const SHARP_HEIGHT := 1440.0
const MOST_SCALE := 1.75
const MOST_PIXELS := 3584 * 3584
## Ultra's, see [method scale_for]: never less than twice a side, nor more than three times and
## [constant ULTRA_PIXELS] in all, an XL map at three times; and never wider than the card can
## hold a picture, [constant WIDEST] where it cannot say.
const ULTRA_LEAST := 2.0
const ULTRA_MOST := 3.0
const ULTRA_PIXELS := 6144 * 6144
const WIDEST := 16384
## How the layout's edges are smoothed as it is drawn, see [method DrawnTexture.of]: its lines,
## arcs and words are smooth of themselves, and what a room prints under them, a lane's arrows, a
## kerb's stones or a playfield's inserts, is polygons, whose edges are not, and a floor worn this
## large shows every pixel along them. Four samples a pixel, while it is drawn and never after.
const SMOOTH := Viewport.MSAA_4X
## Drawn half again as fine or finer, see [method screen_scale], two samples a pixel leave it as
## smooth as four did at its own size, and take half the memory while it is drawn: 101 MB rather
## than 202 at the most an XL map is drawn at.
const SMOOTH_FINER := Viewport.MSAA_2X
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
## goes up, and never without a screen to draw it on; drawn for the screen, and again should the
## setting change how finely, see [ScreenPrint]. The floor's second UV runs corner to corner over
## the arena, see [method Arena._quad].
static func lay(host: Node, felt: BaseMaterial3D, on: ArenaGrid, room: RoomLook) -> void:
	var kit: Variant = host.get("kit")
	var style: RoomStyle = kit.style if kit is RoomKit else null
	var inks: Array[Color] = []
	if style != null:
		inks = style.layout_inks()
	var make := func() -> Control:
		var layout := for_grid(on, room)
		if inks.size() >= 2:
			layout.line = inks[0]
			layout.word = inks[1]
		layout.style = style
		return layout
	ScreenPrint.lay(
		host,
		make,
		pixels(on),
		func(texture: Texture2D) -> void:
			felt.detail_enabled = true
			felt.detail_albedo = texture
			felt.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
			felt.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			if style != null:
				style.layout_printed(felt, texture)
	)


## The size of the picture for [param on], as it is laid out.
static func pixels(on: ArenaGrid) -> Vector2i:
	return Vector2i(on.width * CELL_PIXELS, on.height * CELL_PIXELS)


## How many times as many pixels a side a print of [param laid_out] is drawn at, GAME.md 8.1b,
## as the Texture detail setting asks, see [method scale_for]: for the tallest screen there is,
## not the window, so a window made larger or fullscreen in a match, or moved to the other screen,
## wants nothing drawn again.
static func screen_scale(laid_out: Vector2i) -> float:
	var tallest := DisplayServer.window_get_size().y
	for screen: int in DisplayServer.get_screen_count():
		tallest = maxi(tallest, DisplayServer.screen_get_size(screen).y)
	var detail := Game.settings.texture_detail if Game.settings != null else Settings.TEXTURES_AUTO
	var card := RenderingServer.get_rendering_device()
	var widest := WIDEST
	if card != null:
		widest = mini(card.limit_get(RenderingDevice.LIMIT_MAX_TEXTURE_SIZE_2D), WIDEST)
	return scale_for(detail, tallest, laid_out, Settings.full_renderer(), widest)


## Which of Low or High the Auto detail comes out as on this screen, for the Video page to show in
## brackets, see [method scale_for]: High where it draws a print finer than its own size, which is
## on a tall screen by the desktop's renderer; Low at its own size, on a short screen or a phone's.
static func auto_detail(full_renderer := Settings.full_renderer()) -> String:
	var tallest := DisplayServer.window_get_size().y
	for screen: int in DisplayServer.get_screen_count():
		tallest = maxi(tallest, DisplayServer.screen_get_size(screen).y)
	var high := full_renderer and float(tallest) / SHARP_HEIGHT > 1.0
	return Settings.TEXTURES_HIGH if high else Settings.TEXTURES_LOW


## How many times as many pixels a side a print of [param laid_out] is drawn at for
## [param detail], one of [constant Settings.TEXTURE_DETAILS], on a screen [param tallest] pixels
## tall, by the desktop's renderer or not, [param full_renderer], on a card that holds a picture
## [param widest] pixels wide at most. The floor fills about as much of a screen whatever its size,
## so a print drawn at one size for all of them is enlarged on a big one, and soft: at 4K by half
## again, at 5K twice. Auto draws it at its own size on a screen [constant SHARP_HEIGHT] tall or
## shorter and as much finer as a taller one is taller, and at its own size on a phone's renderer,
## short of memory; Low always at its own size; and High always as finely as Auto ever does, for a
## closer look than the screen's own; none more than [constant MOST_SCALE] a side, nor than
## [constant MOST_PIXELS] in all. Ultra draws it twice as finely as Auto would, for the camera at
## its closest, and never less than [constant ULTRA_LEAST], up to [constant ULTRA_MOST] and
## [constant ULTRA_PIXELS]; a phone's renderer, which does not offer it, draws it as High.
static func scale_for(
	detail: String, tallest: int, laid_out: Vector2i, full_renderer := true, widest := WIDEST
) -> float:
	var scale := 1.0
	var most := MOST_PIXELS
	var screen := float(tallest) / SHARP_HEIGHT
	if detail == Settings.TEXTURES_ULTRA and full_renderer:
		scale = clampf(screen * 2.0, ULTRA_LEAST, ULTRA_MOST)
		most = ULTRA_PIXELS
	elif detail in [Settings.TEXTURES_HIGH, Settings.TEXTURES_ULTRA]:
		scale = MOST_SCALE
	elif detail == Settings.TEXTURES_AUTO and full_renderer:
		scale = clampf(screen, 1.0, MOST_SCALE)
	var room := sqrt(float(most) / float(maxi(laid_out.x * laid_out.y, 1)))
	var wide := float(widest) / float(maxi(maxi(laid_out.x, laid_out.y), 1))
	return maxf(minf(scale, minf(room, wide)), 1.0)


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


## [param color] laid on at [param share] of its ink, and at less where the room's own ink is
## see-through, see [method RoomStyle.layout_inks].
func _ink(color: Color, share: float) -> Color:
	return Color(color, color.a * share)


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
