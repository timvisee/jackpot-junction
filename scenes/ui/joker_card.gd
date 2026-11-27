class_name JokerCard
extends Panel
## One joker drawn as a playing card, GAME.md 8.3. The hand along the bottom of the screen and
## the pick-a-joker cards in the middle are both made of these, so a joker looks the same
## wherever it turns up: framed in its kind's color, its kind and its suit in the top left corner,
## the corner a fanned hand leaves showing, its own picture in the middle, and its name on the stub
## along its foot. Highlighting swaps the frame for a bright gold one, or a red one when the card is
## the one about to be destroyed.
##
## Over the stub, on the card itself, stand one, two or three gems for how rare the joker is. Count
## and color say the same thing twice on purpose: color alone is not something every player can
## read, and a card already spends its color on saying what kind of joker it is.
##
## Cards are pivoted at their bottom center, so a fan tilt or a scale turns about the point the
## hand is held at rather than about a corner.
##
## A card is the one shape of GAME.md 8.1a that is not cut from the house's stock: it stays a card,
## rounded, framed in its kind's color, with a bite out of either side where its stub was torn
## along a perforation, and printed with the House's fine print, see [CardPrint].

const SIZE := Vector2(120.0, 168.0)
## The red that marks a card for destruction, on its frame and on the cross over it.
const DOOMED := Color("#FF3B30")
## The kinds and the rarities by name, each shown through tr().
const KIND_NAMES: Dictionary[int, String] = {
	Joker.Kind.STAT: "Stat", Joker.Kind.RULE: "Rule", Joker.Kind.CURSED: "Cursed"
}
const RARITY_NAMES: Dictionary[int, String] = {
	Joker.Rarity.COMMON: "Common", Joker.Rarity.UNCOMMON: "Uncommon", Joker.Rarity.RARE: "Rare"
}
## Steel, then the two neon colors of the room, kept clear of the kind colors so that a card
## says two different things rather than one thing twice over.
const RARITY_COLORS: Dictionary[int, Color] = {
	Joker.Rarity.COMMON: Color("#9AA3AD"),
	Joker.Rarity.UNCOMMON: Palette.NEON_CYAN,
	Joker.Rarity.RARE: Palette.NEON_MAGENTA
}
## The pale gold of a card that has just gone off by itself, see [method set_glowing].
const GLOW := Color(1.0, 0.9, 0.55)
## A rarity gem: half its width and half its height, how far apart two stand, and how far over the
## tear line they stand, in the card's units.
const GEM := Vector2(3.6, 5.0)
const GEM_GAP := 13.0
const GEM_ABOVE := 12.0
## How far in a card's hairline runs, kept for the backs that are drawn to match, see [CardBack].
const HAIRLINE := 0.35
const INSET := 5.0
## How big a card's name is: on one line, or smaller on the two a longer name wraps onto, see
## [method Type.wrapping]; and how far in from the card's edges Kit's words stand.
const TITLE := 15
const TITLE_WRAPPED := 12
const MARGIN := 8
## How big the cat is in the corner of a Copy Cat's copied face, GAME.md 7.3.
const COPY_BADGE := 26.0
## The suit before the kind, GAME.md 7.3: how big, how far from the kind, and where the corner's
## index stands.
const SUIT_SIDE := 13.0
const SUIT_GAP := 3
const INDEX_AT := Vector2(10.0, 10.0)
## How wide the outline round the corner's suit and kind is, in the card's own dark, so they read
## over the screen without a hole cut in it.
const INDEX_OUTLINE := 4
## Where the picture stands on the card, and the stub its name is set on, in its units.
const PICTURE_AT := Rect2(28.0, 34.0, 64.0, 64.0)
const NAME_ON := Rect2(6.0, 126.0, 108.0, 36.0)
## A card baking its face, see [member bakes]: the group it waits in for its picture, the step its
## pixels go up by, and how many frames its size has to hold before it is drawn again for it.
const PICTURES := &"joker_card_pictures"
const PICTURE_STEP := 8
const STEADY := 6
## One of Kit's cards, STORY.md 6.3, as a screen reader is told it, shown through tr(); and its
## corner, Kit's initial.
const KIT_CARD := "One of Kit's cards"
const KIT_MARK := "K."


## How a card stands, for its body and frame, see [JokerCard.Body]: the shadow round it is the
## style's own, and its fill, frame color and frame width are drawn by the body, bites and all.
class CardStyle:
	extends StyleBoxFlat

	var fill := Color(0.11, 0.11, 0.14, 0.96)
	var frame := Color.WHITE
	var frame_width := 3.0

	func _init() -> void:
		draw_center = false
		set_corner_radius_all(10)


## The card's body under everything on it: its stock in the shape of the card, a bite out of either
## side at the stub, and the frame round it, as the card's style says.
class Body:
	extends Control

	var _shape := PackedVector2Array()

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var style := get_parent().get_theme_stylebox(&"panel") as CardStyle
		if style == null:
			return
		if _shape.is_empty():
			_shape = CardPrint.outline(0.0, 10.0)
		draw_colored_polygon(_shape, style.fill)
		var half := style.frame_width * 0.5
		var frame := CardPrint.outline(half, 10.0 - half)
		frame.append(frame[0])
		draw_polyline(frame, style.frame, style.frame_width, true)


## What is printed on a card's face, under everything else on it: the linen of its stock, the
## House's fine print in its ink, see [CardPrint], and the gems of its rarity; or for one of Kit's
## cards, the squares of his graph paper.
class Face:
	extends Control

	var ink := Color.WHITE
	## A power-up's card, a rare joker's and a cursed one's, for the print.
	var item := false
	var rare := false
	var cursed := false
	## How many gems it wears, in the color of its rarity: none on a power-up's or Kit's.
	var gems := 0
	var gem_ink := Color.WHITE
	## Kit's graph paper's squares under the pencil, for one of Kit's cards, rather than the
	## House's print.
	var graph := false
	var _box := PackedVector2Array()
	var _kept := {}
	var _finish: Array = [Surface.Kind.NONE, 0.0, 0.0]

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var inner := Rect2(Vector2.ONE * (INSET + 1.0), SIZE - Vector2.ONE * (INSET + 1.0) * 2.0)
		_box = PackedVector2Array(
			[
				inner.position,
				Vector2(inner.end.x, inner.position.y),
				inner.end,
				Vector2(inner.position.x, inner.end.y),
			]
		)
		_finish = Surface.finish("card")

	## How many pixels across the card shows.
	func pixels() -> float:
		return SIZE.x * KeptPictures.scale_of(self)

	func _draw() -> void:
		if graph:
			var step := 9.0
			var x := INSET + step
			while x < size.x - INSET:
				draw_line(Vector2(x, INSET), Vector2(x, size.y - INSET), KitCards.SQUARES, 1.0)
				x += step
			var y := INSET + step
			while y < size.y - INSET:
				draw_line(Vector2(INSET, y), Vector2(size.x - INSET, y), KitCards.SQUARES, 1.0)
				y += step
			return
		var shown := pixels()
		Surface.draw(
			get_canvas_item(),
			_kept,
			_box,
			SIZE,
			_finish[0] as Surface.Kind,
			float(_finish[1]),
			get_global_transform().get_scale().x
		)
		var printed := CardPrint.texture(ink, shown, item, rare, cursed)
		if printed != null:
			draw_texture_rect(printed, Rect2(Vector2.ZERO, SIZE), false)
		if gems > 0:
			var grow := 1.45 if CardPrint.level_of(shown) == CardPrint.Level.FLAT else 1.0
			JokerCard.draw_gems(
				self, Vector2(SIZE.x * 0.5, CardPrint.STUB - GEM_ABOVE * grow), gems, gem_ink, grow
			)


var joker: Joker
## Whether the card shows its face as a picture of itself once that is drawn, GAME.md 10.7: its
## print, index, art, name and gems are a few dozen draws as themselves and one as a picture,
## and a hand or a pick holds several. The frame, its glow and what is laid over the face stay
## themselves. The catalog draws whole cards as pictures of its own, see [CatalogCell].
var bakes := false

## A Copy Cat's card showing what it copies, GAME.md 7.3: the copied card's face over its own, a
## cat in its corner to say it is a copy, and a sheen across the card as it turns from one to the
## other, see [method show_copy].
var _copy_face: JokerCard
var _copy_of := &""
var _sheen: Sheen

var _gems := 0
var _body: Body
var _index_word: Label
var _face_picture: Texture2D
var _face_shown: TextureRect
var _content: Array[Control] = []
## The size the face is wanted at, in pixels across, and for how many frames it has held.
var _wanted_pixels := 0
var _held_for := 0
var _normal: CardStyle
var _chosen: CardStyle
var _doomed: CardStyle
var _glowing: CardStyle


## A band of light sweeping across a card, from its top left corner to its bottom right, at
## [member at] of the way, nothing at 0 or 1.
class Sheen:
	extends Control

	var at := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if at <= 0.0 or at >= 1.0:
			return
		var reach := size.x + size.y
		var middle := lerpf(-size.y * 0.3, reach, at)
		var band := size.x * 0.28
		var shape := PackedVector2Array(
			[
				Vector2(middle - band, 0.0),
				Vector2(middle, 0.0),
				Vector2(middle - size.y, size.y),
				Vector2(middle - size.y - band, size.y),
			]
		)
		draw_colored_polygon(shape, Color(1.0, 0.96, 0.85, 0.38 * sin(at * PI)))


static func create(for_joker: Joker) -> JokerCard:
	var card := JokerCard.new()
	card.joker = for_joker
	card._build()
	ScreenReader.name(card, Lang.t(for_joker.display_name), told(for_joker))
	return card


## What a screen reader is told of [param for_joker] after its name, see [ScreenReader]: its suit,
## how rare it is and its kind, as its corner and its pips say, and its words for [param copies].
static func told(for_joker: Joker, copies := 1) -> String:
	if for_joker.contraband:
		return ScreenReader.line(
			[Lang.t(KIT_CARD), for_joker.describe(copies), '"%s"' % Lang.t(for_joker.kit_line)]
		)
	# TRANSLATORS: How rare a joker is and its kind, as a screen reader says them: Common Stat.
	var said := PackedStringArray(
		[
			Lang.t(JokerSuits.name_of(for_joker.suit)),
			Lang.t("{rarity} {kind}").format(
				{"rarity": rarity_name(for_joker), "kind": kind_name(for_joker)}
			),
			for_joker.describe(copies),
		]
	)
	return ScreenReader.line(said)


## What a screen reader is told of [param for_joker] as the [param index]th of [param count] cards,
## from 1, [param copies] of it held: where it is, its name, then the rest, see [method told].
static func told_at(index: int, count: int, for_joker: Joker, copies := 1) -> String:
	var place := Lang.t("{index} of {count}").format({"index": index, "count": count})
	var said := PackedStringArray([place, Lang.t(for_joker.display_name), told(for_joker, copies)])
	return ScreenReader.line(said)


## The color that stands for a joker's kind, shared by the cards and the HUD text: for one of Kit's
## cards, which is no kind of the House's, Kit's pencil.
static func kind_color(for_joker: Joker) -> Color:
	if for_joker.contraband:
		return KitCards.PENCIL_LIGHT
	match for_joker.kind:
		Joker.Kind.STAT:
			return Color("#dddddd")
		Joker.Kind.CURSED:
			return Color("#ff6b6b")
	return Palette.CHIP_GOLD


## The joker's kind, in the language spoken.
static func kind_name(for_joker: Joker) -> String:
	return Lang.t(KIND_NAMES[for_joker.kind])


## The color that stands for how rare a joker is, shared by the cards and the detail pane.
static func rarity_color(for_joker: Joker) -> Color:
	return RARITY_COLORS[for_joker.rarity]


## How rare the joker is, in the language spoken.
static func rarity_name(for_joker: Joker) -> String:
	return Lang.t(RARITY_NAMES[for_joker.rarity])


## Lays the face of [param face], the card this Copy Cat copies, over its own, built again only when
## that card changes; null takes it away, see [method show_copy].
func copying(face: Joker) -> void:
	var id := face.id if face != null else &""
	if id == _copy_of:
		return
	_copy_of = id
	if _copy_face != null:
		_copy_face.queue_free()
		_copy_face = null
	if face == null:
		if _sheen != null:
			_sheen.queue_free()
			_sheen = null
		return
	_copy_face = JokerCard.create(face)
	_copy_face.name = "Copied"
	_copy_face.pivot_offset = Vector2.ZERO
	_copy_face.modulate.a = 0.0
	# The cat in the copied face's corner, across from its kind, so it reads as a copy.
	var cat := JokerArt.picture(&"copy_cat", JokerCard.kind_color(joker))
	cat.size = Vector2.ONE * COPY_BADGE
	cat.position = Vector2(SIZE.x - COPY_BADGE - 8.0, 8.0)
	_copy_face.add_child(cat)
	add_child(_copy_face)
	if _sheen == null:
		_sheen = Sheen.new()
		_sheen.name = "Sheen"
		add_child(_sheen)
	move_child(_sheen, -1)


## How much of the copied face shows over this Copy Cat's own, 0 to 1, and how far across the card
## the sheen of its turning is, see [method copying].
func show_copy(amount: float, sheen: float) -> void:
	if _copy_face == null:
		return
	_copy_face.modulate.a = amount
	if _sheen.at != sheen:
		_sheen.at = sheen
		_sheen.queue_redraw()


## How many gems this card is wearing: one for a common joker, three for a rare one, none for one
## of Kit's.
func rarity_pips() -> int:
	return _gems


## Lights the card up as the one under the cursor. [param doomed] marks it as the one that is
## about to be thrown away rather than taken, which is a different answer to a different
## question and must not look the same.
## A frame of [constant GLOW] with a glow round it, for a joker that has just done something by
## itself, GAME.md 8.3: [param amount] from 1, as it goes off, down to 0, the card's own frame.
func set_glowing(amount: float) -> void:
	if amount <= 0.0:
		set_highlighted(false)
		return
	_glowing.frame = _normal.frame.lerp(GLOW, amount)
	_glowing.shadow_color = Color(GLOW, 0.9 * amount)
	_glowing.shadow_size = roundi(26.0 * amount)
	add_theme_stylebox_override("panel", _glowing)
	_body.queue_redraw()


func set_highlighted(on: bool, doomed: bool = false) -> void:
	if not on:
		add_theme_stylebox_override("panel", _normal)
	else:
		add_theme_stylebox_override("panel", _doomed if doomed else _chosen)
	_body.queue_redraw()


## A card's style: its stock's [param fill], a frame of [param frame] [param width] wide, and a
## shadow or glow of [param shadow] [param spread] out.
static func style_of(
	fill: Color, frame: Color, width: float, shadow: Color, spread: int
) -> CardStyle:
	var style := CardStyle.new()
	style.fill = fill
	style.frame = frame
	style.frame_width = width
	style.shadow_color = shadow
	style.shadow_size = spread
	return style


func _build() -> void:
	var color := kind_color(joker)
	size = SIZE
	pivot_offset = Vector2(SIZE.x * 0.5, SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal = style_of(Color(0.11, 0.11, 0.14, 0.96), color, 3.0, Color(0.0, 0.0, 0.0, 0.5), 6)
	var gold := Color(Palette.CHIP_GOLD, 0.75)
	_chosen = style_of(Color(0.22, 0.18, 0.08, 1.0), Palette.CHIP_WHITE, 5.0, gold, 18)
	_doomed = style_of(Color(0.26, 0.09, 0.09, 1.0), DOOMED, 5.0, Color(DOOMED, 0.75), 18)
	_glowing = style_of(Color(0.24, 0.21, 0.12, 1.0), Palette.CHIP_WHITE, 5.0, gold, 18)
	var kit := joker.contraband
	if kit:
		# One of the House's cards painted over and drawn on again in pencil, STORY.md 6.3.
		color = KitCards.PENCIL
		_normal.fill = KitCards.PAINTED
		_normal.frame = KitCards.PENCIL
		_normal.frame_width = 2.0
		# Lit or chosen, still the paint it was painted over with, its pencil to be read.
		for lit: CardStyle in [_chosen, _glowing]:
			lit.fill = KitCards.PAINTED.lightened(0.08)
	add_theme_stylebox_override("panel", _normal)
	_body = Body.new()
	_body.name = "Body"
	add_child(_body)
	var face := Face.new()
	face.name = "Face"
	face.ink = color
	face.graph = kit
	add_child(face)
	_content.append(face)
	if kit:
		_in_pencil(color)
		return
	face.rare = joker.rarity == Joker.Rarity.RARE
	face.cursed = joker.kind == Joker.Kind.CURSED
	_gems = int(joker.rarity) + 1
	face.gems = _gems
	face.gem_ink = rarity_color(joker)
	# The suit and then the kind in the top left corner, as a playing card's index is: the corner a
	# fanned hand leaves showing, GAME.md 7.3. Outlined in the card's dark, they read over the
	# screen printed along the top.
	var index := HBoxContainer.new()
	index.name = "Index"
	index.mouse_filter = Control.MOUSE_FILTER_IGNORE
	index.add_theme_constant_override("separation", SUIT_GAP)
	index.position = INDEX_AT - Vector2(0.0, 4.0)
	var suit := JokerSuits.Mark.new(joker.suit)
	suit.name = "Suit"
	suit.halo = CardPrint.STOCK
	suit.custom_minimum_size = Vector2.ONE * SUIT_SIDE
	suit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	index.add_child(suit)
	_index_word = Label.new()
	_index_word.text = kind_name(joker).to_upper()
	_index_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(_index_word, Type.STRONG, 13)
	_index_word.add_theme_color_override("font_color", color)
	_index_word.add_theme_color_override("font_outline_color", CardPrint.STOCK)
	_index_word.add_theme_constant_override("outline_size", INDEX_OUTLINE)
	index.add_child(_index_word)
	add_child(index)
	_content.append(index)
	# The joker's own picture rather than its initials: a card is recognized across the table by
	# its shape, and two letters at that size are a shape you have to read first, GAME.md 8.3.
	var art := JokerArt.picture(joker.id, color)
	art.position = PICTURE_AT.position
	art.size = PICTURE_AT.size
	add_child(art)
	_content.append(art)
	# The name alone on the stub, in its middle.
	var title := Label.new()
	title.text = tr(joker.display_name)
	Type.set_font(title, Type.STRONG, title_size(title.text))
	title.add_theme_color_override("font_color", Palette.CHIP_WHITE)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.position = NAME_ON.position
	title.size = NAME_ON.size
	add_child(title)
	_content.append(title)


## The size a card's name [param text] is set at on its stub, see [constant TITLE].
static func title_size(text: String) -> int:
	return Type.wrapping(text, Type.STRONG, TITLE, TITLE_WRAPPED, NAME_ON.size.x)


## One of Kit's cards: K. in its corner in pencil where the suit and kind would be, its picture, its
## name in Kit's hand, and along its foot where the House's term would be, Kit's line.
func _in_pencil(ink: Color) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, MARGIN)
	add_child(margin)
	_content.append(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var kind := Label.new()
	kind.text = tr(KIT_MARK)
	kind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(kind, NotePage.HAND, 18)
	kind.add_theme_color_override("font_color", KitCards.PENCIL)
	stack.add_child(kind)
	var art := JokerArt.picture(joker.id, ink)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(art)
	var title := Label.new()
	title.text = tr(joker.display_name)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.set_font(title, NotePage.HAND, 20)
	title.add_theme_color_override("font_color", KitCards.PENCIL)
	stack.add_child(title)
	var line := Label.new()
	line.name = "KitLine"
	line.text = tr(joker.kit_line)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.set_font(line, NotePage.HAND, 12)
	line.add_theme_color_override("font_color", Color(KitCards.PENCIL, 0.85))
	line.add_theme_constant_override("line_spacing", -4)
	stack.add_child(line)


func _ready() -> void:
	set_process(bakes)
	if bakes:
		add_to_group(PICTURES)


## The face as a picture once its size has held for a few frames: a card sliding or growing
## shows the picture it has, stretched for the moment, or itself until it has one.
func _process(_delta: float) -> void:
	var pixels := KeptPictures.step_up(SIZE.x * KeptPictures.scale_of(self), PICTURE_STEP)
	if pixels != _wanted_pixels:
		_wanted_pixels = pixels
		_held_for = 0
		return
	_held_for += 1
	if _held_for == STEADY:
		_ask_picture()


## Asks for the face at the size it is wanted, and shows it once it is there, see [KeptPictures].
func _ask_picture() -> void:
	if _wanted_pixels <= 0 or not is_inside_tree():
		return
	var pixels := Vector2i(_wanted_pixels, roundi(_wanted_pixels * SIZE.y / SIZE.x))
	var of := joker
	var drawn := KeptPictures.of(
		self,
		"joker_face|%s" % joker.id,  # NO_TRANSLATE
		pixels,
		func() -> Control:
			var holder := Control.new()
			var copy := JokerCard.create(of)
			copy.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			copy._body.visible = false
			copy.pivot_offset = Vector2.ZERO
			copy.scale = Vector2.ONE * (pixels.x / SIZE.x)
			holder.add_child(copy)
			return holder,
		PICTURES,
		&"_on_picture_ready"
	)
	if drawn == null:
		return
	_face_picture = drawn
	if _face_shown == null:
		# Over the frame and under whatever is laid over the face. Drawn onto nothing, its faint
		# lines and smoothed edges are already as faint as they are dark, so it is laid on
		# premultiplied, as the backdrop's curtains are, or they would be faint twice over.
		_face_shown = TextureRect.new()
		_face_shown.name = "FacePicture"
		_face_shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_face_shown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_face_shown.stretch_mode = TextureRect.STRETCH_SCALE
		_face_shown.size = SIZE
		var premultiplied := CanvasItemMaterial.new()
		premultiplied.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		_face_shown.material = premultiplied
		add_child(_face_shown)
		move_child(_face_shown, 0)
	_face_shown.texture = drawn
	for part: Control in _content:
		part.visible = false


## A face drawn for some card: this one's, if it is waiting for one.
func _on_picture_ready() -> void:
	if _held_for >= STEADY:
		_ask_picture()


## Draws [param count] gems of [param ink] in a row round [param middle] on [param on], [param grow]
## times their size: a stone each, cut to a point at its top and its foot, a glint on it.
static func draw_gems(on: CanvasItem, middle: Vector2, count: int, ink: Color, grow := 1.0) -> void:
	var half := GEM * grow
	var gap := GEM_GAP * grow
	var left := middle.x - (count - 1) * gap * 0.5
	for i: int in count:
		var at := Vector2(left + i * gap, middle.y)
		var stone := PackedVector2Array(
			[
				at + Vector2(0.0, -half.y),
				at + Vector2(half.x, 0.0),
				at + Vector2(0.0, half.y),
				at + Vector2(-half.x, 0.0),
			]
		)
		on.draw_colored_polygon(stone, ink)
		stone.append(stone[0])
		on.draw_polyline(stone, ink, 0.8 * grow, true)
		var glint := Color(1.0, 1.0, 1.0, 0.6)
		on.draw_line(
			at + Vector2(-1.2, -2.2) * grow,
			at + Vector2(-0.2, -3.4) * grow,
			glint,
			0.8 * grow,
			true
		)
