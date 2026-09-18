class_name JokerCard
extends Panel
## One joker drawn as a playing card, GAME.md 8.3. The hand along the bottom of the screen and
## the pick-a-joker cards in the middle are both made of these, so a joker looks the same
## wherever it turns up: framed in its kind's colour, with its initials big and its name under
## them. Highlighting swaps the frame for a bright gold one, or a red one when the card is the
## one about to be destroyed.
##
## Under the name sit one, two or three pips for how rare the joker is. Count and colour say the
## same thing twice on purpose: colour alone is not something every player can read, and a card
## already spends its colour on saying what kind of joker it is.
##
## Cards are pivoted at their bottom centre, so a fan tilt or a scale turns about the point the
## hand is held at rather than about a corner.

const SIZE := Vector2(120.0, 168.0)
## The red that marks a card for destruction, on its frame and on the cross over it.
const DOOMED := Color("#FF3B30")
const KIND_NAMES: Dictionary[int, String] = {
	Joker.Kind.STAT: "Stat", Joker.Kind.RULE: "Rule", Joker.Kind.CURSED: "Cursed"
}
const RARITY_NAMES: Dictionary[int, String] = {
	Joker.Rarity.COMMON: "Common", Joker.Rarity.UNCOMMON: "Uncommon", Joker.Rarity.RARE: "Rare"
}
## Steel, then the two neon colours of the room, kept clear of the kind colours so that a card
## says two different things rather than one thing twice over.
const RARITY_COLORS: Dictionary[int, Color] = {
	Joker.Rarity.COMMON: Color("#9AA3AD"),
	Joker.Rarity.UNCOMMON: Palette.NEON_CYAN,
	Joker.Rarity.RARE: Palette.NEON_MAGENTA
}
## Side of one rarity pip, and the gap between two of them.
const PIP := 9.0
const PIP_GAP := 5

var joker: Joker

var _pips: HBoxContainer
var _normal: StyleBoxFlat
var _chosen: StyleBoxFlat
var _doomed: StyleBoxFlat


static func create(for_joker: Joker) -> JokerCard:
	var card := JokerCard.new()
	card.joker = for_joker
	card._build()
	return card


## The colour that stands for a joker's kind, shared by the cards and the HUD text.
static func kind_color(for_joker: Joker) -> Color:
	match for_joker.kind:
		Joker.Kind.STAT:
			return Color("#dddddd")
		Joker.Kind.CURSED:
			return Color("#ff6b6b")
	return Palette.CHIP_GOLD


static func kind_name(for_joker: Joker) -> String:
	return KIND_NAMES[for_joker.kind]


## The colour that stands for how rare a joker is, shared by the cards and the detail pane.
static func rarity_color(for_joker: Joker) -> Color:
	return RARITY_COLORS[for_joker.rarity]


static func rarity_name(for_joker: Joker) -> String:
	return RARITY_NAMES[for_joker.rarity]


## How many pips this card is wearing: one for a common joker, three for a rare one.
func rarity_pips() -> int:
	return _pips.get_child_count()


## Lights the card up as the one under the cursor. [param doomed] marks it as the one that is
## about to be thrown away rather than taken, which is a different answer to a different
## question and must not look the same.
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
	add_theme_stylebox_override("panel", _normal)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var kind := Label.new()
	kind.text = kind_name(joker).to_upper()
	kind.add_theme_font_size_override("font_size", 13)
	kind.add_theme_color_override("font_color", color)
	var initials := Label.new()
	initials.text = joker.initials()
	initials.add_theme_font_size_override("font_size", 46)
	initials.add_theme_color_override("font_color", color)
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initials.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = joker.display_name
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Palette.CHIP_WHITE)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label: Label in [kind, initials, title]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(label)
	stack.add_child(_build_pips())


## One pip per step up the rarity scale, in a row under the name.
func _build_pips() -> HBoxContainer:
	_pips = HBoxContainer.new()
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	_pips.add_theme_constant_override("separation", PIP_GAP)
	for i: int in int(joker.rarity) + 1:
		var pip := ColorRect.new()
		pip.color = rarity_color(joker)
		pip.custom_minimum_size = Vector2(PIP, PIP)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pips.add_child(pip)
	return _pips
