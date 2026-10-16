class_name JokerCard
extends Panel
## One joker drawn as a playing card, GAME.md 8.3. The hand along the bottom of the screen and
## the pick-a-joker cards in the middle are both made of these, so a joker looks the same
## wherever it turns up: framed in its kind's color, with its own picture in the middle of it,
## its name under that, and its kind and its suit in the top left corner, the corner a fanned hand
## leaves showing. Highlighting swaps the frame for a bright gold one, or a red one when the card
## is the one about to be destroyed.
##
## Under the name sit one, two or three pips for how rare the joker is. Count and color say the
## same thing twice on purpose: color alone is not something every player can read, and a card
## already spends its color on saying what kind of joker it is.
##
## Cards are pivoted at their bottom center, so a fan tilt or a scale turns about the point the
## hand is held at rather than about a corner.
##
## A card is the one shape of GAME.md 8.1a that is not cut from the house's stock: it stays a card,
## rounded, framed in its kind's color, and engraved in it too, a hairline inside the frame, rings
## round the picture and waves across the foot, at a whisper.

const SIZE := Vector2(120.0, 168.0)
## The red that marks a card for destruction, on its frame and on the cross over it.
const DOOMED := Color("#FF3B30")
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
## Side of one rarity pip, and the gap between two of them. Round: anything round is a chip.
const PIP := 9.0
const PIP_GAP := 5
## How strongly the engraving on a card's face shows, and how far in its hairline runs.
const ENGRAVED := 0.15
const HAIRLINE := 0.35
const INSET := 5.0
## How far the kind stands in from the card's margin, clear of the hairline's round corner.
const KIND_ROOM := 4.0
## How big the cat is in the corner of a Copy Cat's copied face, GAME.md 7.3.
const COPY_BADGE := 26.0
## The suit before the kind, GAME.md 7.3: how big, and how far from the kind.
const SUIT_SIDE := 13.0
const SUIT_GAP := 3
## How far in from the card's margin the suit stands.
const INDEX_IN := 2
## A card baking its face, see [member bakes]: the group it waits in for its picture, the step its
## pixels go up by, and how many frames its size has to hold before it is drawn again for it.
const PICTURES := &"joker_card_pictures"
const PICTURE_STEP := 8
const STEADY := 6


## What is engraved on a card's face, under everything else on it, in its kind's color.
class Face:
	extends Control

	var ink := Color.WHITE
	var _lines: Array[PackedVector2Array] = []
	var _box := PackedVector2Array()
	var _kept := {}
	var _finish: Array = [Surface.Kind.NONE, 0.0, 0.0]

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var size_of := JokerCard.SIZE
		var inner := Rect2(Vector2.ONE * (INSET + 1.0), size_of - Vector2.ONE * (INSET + 1.0) * 2.0)
		var box := PackedVector2Array(
			[
				inner.position,
				Vector2(inner.end.x, inner.position.y),
				inner.end,
				Vector2(inner.position.x, inner.end.y),
			]
		)
		var lines := Engraving.rings(
			Vector2(size_of.x * 0.5, size_of.y * 0.46),
			size_of.x * 0.3,
			size_of.x * 0.03,
			14,
			8,
			200
		)
		var foot := Rect2(inner.position.x, inner.end.y - 30.0, inner.size.x, 28.0)
		lines.append_array(Engraving.waves(foot, 5.0, 1.6, 26.0, 0.6, 4.0))
		_lines = Engraving.inside(lines, box)
		_finish = Surface.finish("card")
		_box = box

	func _draw() -> void:
		Surface.draw(
			get_canvas_item(),
			_kept,
			_box,
			JokerCard.SIZE,
			_finish[0] as Surface.Kind,
			float(_finish[1]),
			get_global_transform().get_scale().x
		)
		var hairline := StyleBoxFlat.new()
		hairline.draw_center = false
		hairline.set_border_width_all(1)
		hairline.border_color = Color(ink, HAIRLINE)
		hairline.set_corner_radius_all(6)
		hairline.anti_aliasing = true
		draw_style_box(hairline, Rect2(Vector2.ONE * INSET, size - Vector2.ONE * INSET * 2.0))
		Engraving.draw_on(self, _lines, Color(ink, ENGRAVED), 0.8)


var joker: Joker
## Whether the card shows its face as a picture of itself once that is drawn, GAME.md 10.7: its
## engraving, index, art, name and pips are a few dozen draws as themselves and one as a picture,
## and a hand or a pick holds several. The frame, its glow and what is laid over the face stay
## themselves. The catalog draws whole cards as pictures of its own, see [CatalogCell].
var bakes := false

## A Copy Cat's card showing what it copies, GAME.md 7.3: the copied card's face over its own, a
## cat in its corner to say it is a copy, and a sheen across the card as it turns from one to the
## other, see [method show_copy].
var _copy_face: JokerCard
var _copy_of := &""
var _sheen: Sheen

var _pips: HBoxContainer
var _face_picture: Texture2D
var _face_shown: TextureRect
var _content: Array[Control] = []
## The size the face is wanted at, in pixels across, and for how many frames it has held.
var _wanted_pixels := 0
var _held_for := 0
var _normal: StyleBoxFlat
var _chosen: StyleBoxFlat
var _doomed: StyleBoxFlat
var _glowing: StyleBoxFlat


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
	ScreenReader.name(card, for_joker.display_name, told(for_joker))
	return card


## What a screen reader is told of [param for_joker] after its name, see [ScreenReader]: its suit,
## how rare it is and its kind, as its corner and its pips say, and its words for [param copies].
static func told(for_joker: Joker, copies := 1) -> String:
	var said := PackedStringArray(
		[
			JokerSuits.name_of(for_joker.suit),
			"%s %s" % [rarity_name(for_joker), kind_name(for_joker)],
			for_joker.describe(copies),
		]
	)
	return ScreenReader.line(said)


## The color that stands for a joker's kind, shared by the cards and the HUD text.
static func kind_color(for_joker: Joker) -> Color:
	match for_joker.kind:
		Joker.Kind.STAT:
			return Color("#dddddd")
		Joker.Kind.CURSED:
			return Color("#ff6b6b")
	return Palette.CHIP_GOLD


static func kind_name(for_joker: Joker) -> String:
	return KIND_NAMES[for_joker.kind]


## The color that stands for how rare a joker is, shared by the cards and the detail pane.
static func rarity_color(for_joker: Joker) -> Color:
	return RARITY_COLORS[for_joker.rarity]


static func rarity_name(for_joker: Joker) -> String:
	return RARITY_NAMES[for_joker.rarity]


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


## How many pips this card is wearing: one for a common joker, three for a rare one.
func rarity_pips() -> int:
	return _pips.get_child_count()


## Lights the card up as the one under the cursor. [param doomed] marks it as the one that is
## about to be thrown away rather than taken, which is a different answer to a different
## question and must not look the same.
## A frame of [constant GLOW] with a glow round it, for a joker that has just done something by
## itself, GAME.md 8.3: [param amount] from 1, as it goes off, down to 0, the card's own frame.
func set_glowing(amount: float) -> void:
	if amount <= 0.0:
		set_highlighted(false)
		return
	_glowing.border_color = _normal.border_color.lerp(GLOW, amount)
	_glowing.shadow_color = Color(GLOW, 0.9 * amount)
	_glowing.shadow_size = roundi(26.0 * amount)
	add_theme_stylebox_override("panel", _glowing)


func set_highlighted(on: bool, doomed: bool = false) -> void:
	if not on:
		add_theme_stylebox_override("panel", _normal)
		return
	add_theme_stylebox_override("panel", _doomed if doomed else _chosen)


func _build() -> void:
	var color := kind_color(joker)
	size = SIZE
	pivot_offset = Vector2(SIZE.x * 0.5, SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal = StyleBoxFlat.new()
	_normal.bg_color = Color(0.11, 0.11, 0.14, 0.96)
	_normal.set_corner_radius_all(10)
	_normal.set_border_width_all(3)
	_normal.border_color = color
	_normal.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	_normal.shadow_size = 6
	_chosen = StyleBoxFlat.new()
	_chosen.bg_color = Color(0.22, 0.18, 0.08, 1.0)
	_chosen.set_corner_radius_all(10)
	_chosen.set_border_width_all(5)
	_chosen.border_color = Palette.CHIP_WHITE
	_chosen.shadow_color = Color(Palette.CHIP_GOLD, 0.75)
	_chosen.shadow_size = 18
	_doomed = StyleBoxFlat.new()
	_doomed.bg_color = Color(0.26, 0.09, 0.09, 1.0)
	_doomed.set_corner_radius_all(10)
	_doomed.set_border_width_all(5)
	_doomed.border_color = DOOMED
	_doomed.shadow_color = Color(DOOMED, 0.75)
	_doomed.shadow_size = 18
	_glowing = _chosen.duplicate()
	_glowing.bg_color = Color(0.24, 0.21, 0.12, 1.0)
	add_theme_stylebox_override("panel", _normal)
	var face := Face.new()
	face.name = "Face"
	face.ink = color
	add_child(face)
	_content.append(face)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	add_child(margin)
	_content.append(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var kind := Label.new()
	kind.text = kind_name(joker).to_upper()
	Type.set_font(kind, Type.STRONG, 13)
	kind.add_theme_color_override("font_color", color)
	# The joker's own picture rather than its initials: a card is recognized across the table by
	# its shape, and two letters at that size are a shape you have to read first, GAME.md 8.3.
	var art := JokerArt.picture(joker.id, color)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = joker.display_name
	Type.set_font(title, Type.STRONG, 15)
	title.add_theme_color_override("font_color", Palette.CHIP_WHITE)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The suit and then the kind in the top left corner, as a playing card's index is, a hair in
	# from the frame: the corner a fanned hand leaves showing, GAME.md 7.3.
	var inset := MarginContainer.new()
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_theme_constant_override("margin_left", INDEX_IN)
	var index := HBoxContainer.new()
	index.mouse_filter = Control.MOUSE_FILTER_IGNORE
	index.add_theme_constant_override("separation", SUIT_GAP)
	var suit := JokerSuits.Mark.new(joker.suit)
	suit.name = "Suit"
	suit.custom_minimum_size = Vector2.ONE * SUIT_SIDE
	suit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	index.add_child(suit)
	index.add_child(kind)
	inset.add_child(index)
	stack.add_child(inset)
	stack.add_child(art)
	stack.add_child(title)
	stack.add_child(_build_pips())


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
		"joker_face|%s" % joker.id,
		pixels,
		func() -> Control:
			var holder := Control.new()
			var copy := JokerCard.create(of)
			copy.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
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


## One pip per step up the rarity scale, in a row under the name.
func _build_pips() -> HBoxContainer:
	_pips = HBoxContainer.new()
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	_pips.add_theme_constant_override("separation", PIP_GAP)
	var ink := rarity_color(joker)
	for i: int in int(joker.rarity) + 1:
		var pip := Control.new()
		pip.custom_minimum_size = Vector2(PIP, PIP)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.draw.connect(
			func() -> void: pip.draw_circle(pip.size * 0.5, PIP * 0.5, ink, true, -1.0, true)
		)
		_pips.add_child(pip)
	return _pips
