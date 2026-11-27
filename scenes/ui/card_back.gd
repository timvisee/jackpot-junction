class_name CardBack
extends Panel
## A card lying face down, GAME.md 8.8: a joker or an item the profile has never taken, in the
## catalog, and a card of the respawn pick before it is turned over, 3.7. The size and the shape of
## a [JokerCard], the bite out of either side at its stub, its frame and its shadow drawn by the
## same body, so it holds the same place in the grid and turns over into the same card, but in the
## house's gray rather than any kind's color, an engraved rosette over all its face and a question
## mark in the middle, saying neither what it is, what kind nor how rare. Under the cursor it lights
## up as a card does.
##
## Its back is the profile playing's choice of [constant STYLES], GAME.md 8.9, and this machine's
## alone: the house's, gilt, drawn in pencil, or the house's with Kit's doodles over it, see
## [method worn]; or one of the Steam supporter pack's, 10.8, where the pack is owned, see
## [SupporterBacks].

const INK := Color(0.42, 0.42, 0.48)
## How strongly the engraving shows, and the question mark and how big it is.
const ENGRAVED := 0.22
const MARK := "?"
const MARK_SIZE := 64
## The backs a card may wear, the first everybody's and the rest won in the loyalty program, by
## the names its landmarks pay them under, in English the dress's ids and shown through tr().
const STYLES: Array[String] = [
	"The house's", "Gilt", "Hand-drawn", "Doodled", "Beacon", "Constellation", "Aurora"
]
## Each back's ink, the paper or board under it, and how strongly its lines show: the house's gray
## on black, gold leaf on black, pencil on cream paper, and the house's again under Kit's pencil;
## and the supporter pack's, a cream rim on the night.
const INKS: Array[Color] = [
	INK,
	Color(0.87, 0.68, 0.22),
	Color(0.3, 0.29, 0.28),
	INK,
	Color(0.78, 0.74, 0.64),
	Color(0.7, 0.72, 0.82),
	Color(0.62, 0.7, 0.78),
]
const BOARDS: Array[Color] = [
	Color(0.09, 0.09, 0.11, 0.96),
	Color(0.07, 0.06, 0.05, 0.97),
	Color(0.92, 0.89, 0.8, 0.98),
	Color(0.09, 0.09, 0.11, 0.96),
	Color(0.05, 0.07, 0.13, 0.97),
	Color(0.05, 0.07, 0.13, 0.97),
	Color(0.03, 0.04, 0.08, 0.97),
]
const LINES: Array[float] = [ENGRAVED, 0.34, 0.42, ENGRAVED, ENGRAVED, ENGRAVED, ENGRAVED]
## The backs the Steam supporter pack lets be worn, GAME.md 10.8, each drawn by [SupporterBacks].
const SUPPORTER: Array[int] = [4, 5, 6]
## The back Kit has doodled on, and the pencil the doodles are in, light on the house's black.
const DOODLED := 3
const DOODLE := Color(0.82, 0.81, 0.76, 0.7)


## What is engraved over the back: rings at its middle and waves across all of it.
class Face:
	extends Control

	var ink := INK
	var lines := ENGRAVED
	var doodled := false
	var marked := true
	## With the card's bites, or whole, see [method CardBack.inside_outline].
	var bitten := true
	## Which of the supporter pack's backs it is, see [SupporterBacks], or -1 for another.
	var supporter := -1
	var _lines: Array[PackedVector2Array] = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if supporter >= 0:
			return
		var size_of := JokerCard.SIZE
		var inset := JokerCard.INSET + 1.0
		var inner := Rect2(Vector2.ONE * inset, size_of - Vector2.ONE * inset * 2.0)
		var drawn := Engraving.rings(size_of * 0.5, size_of.x * 0.3, size_of.x * 0.04, 12, 10, 200)
		drawn.append_array(Engraving.waves(inner, 7.0, 2.0, 30.0, 0.6, 4.0))
		_lines = Engraving.inside(drawn, CardBack.inside_outline(bitten))

	func _draw() -> void:
		# The hairline inside the frame, round the bites as the frame goes round them.
		var hairline := CardPrint.outline(JokerCard.INSET, 6.0, bitten)
		hairline.append(hairline[0])
		draw_polyline(hairline, Color(ink, JokerCard.HAIRLINE), 1.0, true)
		if supporter >= 0:
			SupporterBacks.draw(self, supporter, lines, bitten)
		else:
			Engraving.draw_on(self, _lines, Color(ink, lines), 0.8)
		if marked:
			if supporter >= 0:
				draw_circle(JokerCard.SIZE * 0.5, MARK_SIZE * 0.42, CardBack.BOARDS[0])
			CardBack.draw_mark(self, JokerCard.SIZE * 0.5, MARK_SIZE, ink)
		if doodled:
			CardBack.draw_doodles(self, JokerCard.SIZE)


## How many times its own size a back's picture is drawn at, see [method picture].
const PICTURE_SCALE := 2

## The pictures of the backs drawn so far this run, by the back and whether bitten, see
## [method picture].
static var _pictures: Dictionary[Vector2i, Texture2D] = {}

var _normal: JokerCard.CardStyle
var _chosen: JokerCard.CardStyle
var _body: JokerCard.Body


## A card face down in [param style] of [constant STYLES], the one worn for -1; with the question
## mark of a card not known yet, or not, as a card of the deck has none, [param marked]; and with a
## joker's bites, or whole, [param bitten], for a card whose face has no stub, the table's cards and
## the House's face on the loading screen.
func _init(style := -1, marked := true, bitten := true) -> void:
	var back := worn() if style < 0 else clampi(style, 0, STYLES.size() - 1)
	size = JokerCard.SIZE
	pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, JokerCard.SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal = JokerCard.style_of(BOARDS[back], INKS[back], 3.0, Color(0.0, 0.0, 0.0, 0.5), 6)
	var gold := Color(Palette.CHIP_GOLD, 0.6)
	_chosen = JokerCard.style_of(BOARDS[back], Palette.CHIP_WHITE, 5.0, gold, 18)
	_normal.bitten = bitten
	_chosen.bitten = bitten
	add_theme_stylebox_override("panel", _normal)
	_body = JokerCard.Body.new()
	_body.name = "Body"
	add_child(_body)
	var face := Face.new()
	face.name = "Face"
	face.ink = INKS[back]
	face.lines = LINES[back]
	face.doodled = back == DOODLED
	face.supporter = SUPPORTER.find(back)
	face.marked = marked
	face.bitten = bitten
	add_child(face)


## A picture of the back [param style], [constant PICTURE_SCALE] times a card's size, without the
## question mark of a card not known yet or the shadow of one lying on a screen, handed to
## [param wear]: for a card shown moved, turned and faded a frame rather than its engraving drawn
## again every frame. Drawn once a run under [param host], see [method DrawnTexture.kept], and
## handed at once after that. Whole rather than [param bitten] for a card whose face has no stub.
static func picture(style: int, host: Node, wear: Callable, bitten := true) -> void:
	var key := Vector2i(style, int(bitten))
	if _pictures.has(key):
		wear.call(_pictures[key])
		return
	var sheet := Control.new()
	var scaled := Node2D.new()
	scaled.scale = Vector2.ONE * PICTURE_SCALE
	sheet.add_child(scaled)
	var back := CardBack.new(style, false, bitten)
	back._normal.spread = 0.0
	scaled.add_child(back)
	var pixels := Vector2i(JokerCard.SIZE * PICTURE_SCALE)
	DrawnTexture.kept(
		host,
		sheet,
		pixels,
		func(drawn: Texture2D) -> void:
			_pictures[key] = drawn
			if wear.is_valid():
				wear.call(drawn)
	)


## The back the profile playing has chosen, as far as it has won it, GAME.md 8.9: the house's
## otherwise.
static func worn() -> int:
	var profile := Game.settings.profile if Game.settings != null else null
	if profile == null:
		return 0
	var chosen := profile.loyalty.card_back
	if chosen <= 0 or chosen >= STYLES.size():
		return 0
	if chosen in SUPPORTER:
		return chosen if Supporter.owned() else 0
	var dress: PackedStringArray = Loyalty.unlocks_of(profile)["dress"]
	return chosen if "card_back:%s" % STYLES[chosen] in dress else 0  # NO_TRANSLATE


## The question mark of a card face down, [param font_size] big in [param ink], with the middle
## of the mark itself on [param middle] rather than the middle of its line, which would put the mark
## low and a little to one side in the rings round it: across by its own width, and up and down by
## the height of the capitals it stands as tall as, see [constant Type.CAP_HEIGHT].
static func draw_mark(on: CanvasItem, middle: Vector2, font_size: int, ink: Color) -> void:
	var font := Type.display_font()
	var wide := font.get_string_size(MARK, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var base := middle.y + Type.CAP_HEIGHT * float(font_size) * 0.5
	on.draw_string(
		font,
		Vector2(middle.x - wide * 0.5, base),
		MARK,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		ink
	)


## Kit's doodles over the house's back, [param size] big, in pencil: a spiral in a corner, two
## stars, a pair of glasses on the question mark, an arrow, and K. at the foot.
static func draw_doodles(on: CanvasItem, size: Vector2) -> void:
	var spiral := PackedVector2Array()
	for i: int in 40:
		var turn := i * 0.42
		spiral.append(
			Vector2(size.x * 0.22, size.y * 0.16) + Vector2.from_angle(turn) * (1.0 + i * 0.42)
		)
	on.draw_polyline(spiral, DOODLE, 1.6, true)
	for star: Vector3 in [Vector3(0.78, 0.18, 9.0), Vector3(0.24, 0.82, 7.0)]:
		var points := PackedVector2Array()
		for i: int in 11:
			var reach := star.z if i % 2 == 0 else star.z * 0.42
			var angle := -PI * 0.5 + TAU * i / 10.0
			points.append(
				Vector2(size.x * star.x, size.y * star.y) + Vector2.from_angle(angle) * reach
			)
		on.draw_polyline(points, DOODLE, 1.4, true)
	var middle := size * 0.5 + Vector2(0.0, -14.0)
	for side: float in [-1.0, 1.0]:
		on.draw_arc(middle + Vector2(13.0 * side, 0.0), 9.0, 0.0, TAU, 20, DOODLE, 1.6, true)
	on.draw_line(middle + Vector2(-4.0, -1.0), middle + Vector2(4.0, -1.0), DOODLE, 1.6, true)
	var from := Vector2(size.x * 0.66, size.y * 0.8)
	var to := Vector2(size.x * 0.84, size.y * 0.7)
	on.draw_line(from, to, DOODLE, 1.6, true)
	on.draw_line(to, to + Vector2(-9.0, 1.0), DOODLE, 1.6, true)
	on.draw_line(to, to + Vector2(-3.0, 8.0), DOODLE, 1.6, true)
	on.draw_string(
		NotePage.HAND,
		Vector2(size.x * 0.66, size.y * 0.93),
		"K.",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		DOODLE
	)


## Lights the card up as the one under the cursor, as [method JokerCard.set_highlighted] does.
func set_highlighted(on: bool) -> void:
	add_theme_stylebox_override("panel", _chosen if on else _normal)
	_body.queue_redraw()


## The outline inside the frame a back's pictures are kept to, in a card's measures: the card's own,
## [constant JokerCard.INSET] in and a little more, round the bites as the card's sides go, or
## whole where not [param bitten].
static func inside_outline(bitten := true) -> PackedVector2Array:
	return CardPrint.outline(JokerCard.INSET + 1.0, 5.0, bitten)
