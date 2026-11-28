class_name ItemCard
extends Panel
## A power-up drawn as a card for the catalog of GAME.md 8.8, so the items sit in a grid the way the
## jokers beside them do: the size, the shape and the print of a [JokerCard], framed in the item's
## own color, ITEM in its corner where a joker has its suit and kind, its picture of 8.3a in the
## middle. Its stub is the label of the crate it comes out of in the arena: solid in its color, the
## name printed out of it in small capitals, the screen rising from it. No gems: an item has no
## rarity.

## The word over the picture, as a joker's card has its kind, shown through tr().
const KIND := "Item"
## The name on the stub: its size and how far apart its letters are set, and the smallest it is
## set at where a word is too long for the stub, see [method name_set].
const NAME_SIZE := 13
const NAME_TRACKING := 2
const NAME_SMALLEST := 10
## How much room a word keeps clear of the stub's frame either side.
const NAME_CLEAR := 3.0

## The name's font for each spacing of its letters, made the first time it is asked for.
static var _spaced: Dictionary[int, FontVariation] = {}

var item: PowerUp

var _normal: JokerCard.CardStyle
var _chosen: JokerCard.CardStyle
var _body: JokerCard.Body


## The size and the spacing of the letters [param text], a name in capitals, is set at on the stub:
## the crate label's small capitals spaced out, or where a word of it is too long to cross the stub,
## as a language's long compound is (Geschutstoren), closer together and then a point smaller at a
## time, never broken in the middle of the word.
static func name_set(text: String) -> Vector2i:
	var room := JokerCard.NAME_ON.size.x - NAME_CLEAR * 2.0
	var tries: Array[Vector2i] = []
	for tracking: int in range(NAME_TRACKING, -1, -1):
		tries.append(Vector2i(NAME_SIZE, tracking))
	for size: int in range(NAME_SIZE - 1, NAME_SMALLEST - 1, -1):
		tries.append(Vector2i(size, 0))
	for set_at: Vector2i in tries:
		var font := spaced(set_at.y)
		var fits := true
		for word: String in text.split(" ", false):
			if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, set_at.x).x > room:
				fits = false
				break
		if fits:
			return set_at
	return tries[-1]


## The stub's font with its letters [param tracking] apart.
static func spaced(tracking: int) -> FontVariation:
	if not _spaced.has(tracking):
		var font := FontVariation.new()
		font.base_font = Type.STRONG
		font.spacing_glyph = tracking
		_spaced[tracking] = font
	return _spaced[tracking]


static func create(for_item: PowerUp) -> ItemCard:
	var card := ItemCard.new()
	card.item = for_item
	card._build()
	ScreenReader.name(card, Lang.t(for_item.display_name), Lang.t(for_item.description))
	return card


## Lights the card up as the one under the cursor, as [method JokerCard.set_highlighted] does.
func set_highlighted(on: bool) -> void:
	add_theme_stylebox_override("panel", _chosen if on else _normal)
	_body.queue_redraw()


func _build() -> void:
	size = JokerCard.SIZE
	pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, JokerCard.SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := PowerUp.ink_of(item)
	_normal = JokerCard.style_of(Color(0.11, 0.11, 0.14, 0.96), ink, 3.0, Color(0, 0, 0, 0.5), 6)
	_chosen = JokerCard.style_of(
		Color(0.22, 0.18, 0.08, 1.0), Palette.CHIP_WHITE, 5.0, Color(Palette.CHIP_GOLD, 0.75), 18
	)
	add_theme_stylebox_override("panel", _normal)
	_body = JokerCard.Body.new()
	_body.name = "Body"
	add_child(_body)
	var face := JokerCard.Face.new()
	face.name = "Face"
	face.ink = ink
	face.item = true
	add_child(face)
	var kind := Label.new()
	kind.text = tr(KIND).to_upper()
	kind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(kind, Type.STRONG, 13)
	kind.add_theme_color_override("font_color", ink)
	kind.add_theme_color_override("font_outline_color", CardPrint.STOCK)
	kind.add_theme_constant_override("outline_size", JokerCard.INDEX_OUTLINE)
	kind.position = JokerCard.INDEX_AT - Vector2(0.0, 4.0)
	add_child(kind)
	var art := PowerUpArt.picture(item.id, ink)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.position = JokerCard.PICTURE_AT.position
	art.size = JokerCard.PICTURE_AT.size
	add_child(art)
	# The crate's label: the name in small capitals, printed out of the stub in the card's dark.
	var title := Label.new()
	title.text = tr(item.display_name).to_upper()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var set_at := name_set(title.text)
	title.add_theme_font_override("font", spaced(set_at.y))
	title.add_theme_font_size_override("font_size", set_at.x)
	title.add_theme_color_override("font_color", CardPrint.STOCK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = JokerCard.NAME_ON.position
	title.size = JokerCard.NAME_ON.size
	add_child(title)
