class_name TableTag
extends PanelContainer
## A card of the table said in words, GAME.md 3.17: on the House's cream, a chip, the card's name
## in capitals and its one line of what it does. The loading screen's tag naming a card new to the
## player, 8.6, NEW on a chip in the neon's magenta, and the hint over a card of the match
## settings' strip while it is under the mouse or the cursor, 9.6, which says when a sealed card
## opens on a chip of gold and has no chip for the rest, and under the cursor with keys or a pad in
## hand, the bind that turns the card over, see [method show_bind].

enum Chip { NONE, NEW, SEALED }

## The new card's chip, the neon's magenta; and a sealed card's, the strip's gold band.
const NEW_INK := Color("#ff4fa3")
const SEALED_INK := Palette.CHIP_GOLD

var card := -1
var _chip: Label
var _chip_look: StyleBoxFlat
var _name: Label
var _line: Label
## The line saying what turns the card over, and what it was drawn for, so it is drawn again only
## once that changes.
var _bind: Control
var _bind_row: Control
var _bind_for := ""


static func make() -> TableTag:
	var tag := TableTag.new()
	tag.name = "TableTag"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := StyleBoxFlat.new()
	look.bg_color = HouseTheme.PAPER
	look.set_corner_radius_all(6)
	look.set_content_margin_all(10)
	look.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	look.shadow_size = 6
	tag.add_theme_stylebox_override(&"panel", look)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	tag.add_child(row)
	tag._chip = Label.new()
	tag._chip_look = StyleBoxFlat.new()
	tag._chip_look.set_corner_radius_all(3)
	tag._chip_look.set_content_margin_all(3)
	tag._chip.add_theme_stylebox_override(&"normal", tag._chip_look)
	tag._chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(tag._chip)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_theme_constant_override("separation", 2)
	row.add_child(words)
	tag._name = Label.new()
	Type.display(tag._name, Type.BODY, HouseTheme.INK)
	words.add_child(tag._name)
	tag._line = Label.new()
	Type.text(tag._line, Type.LABEL, HouseTheme.INK)
	words.add_child(tag._line)
	tag._bind = MarginContainer.new()
	tag._bind.name = "Bind"
	tag._bind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag._bind.add_theme_constant_override("margin_top", 4)
	tag._bind.visible = false
	words.add_child(tag._bind)
	return tag


## Says [param card_in], with the chip [param chip], one of [enum Chip].
func show_card(card_in: int, chip: int) -> void:
	card = card_in
	_name.text = TableCards.NAMES[card].to_upper()
	_line.text = TableCards.LINES[card]
	_chip.visible = chip != Chip.NONE
	if chip == Chip.NEW:
		_chip.text = " NEW "
		_chip_look.bg_color = NEW_INK
		Type.display(_chip, Type.LABEL, Color.WHITE)
	elif chip == Chip.SEALED:
		_chip.text = " AFTER MAP %d " % TableCards.opens_after(card)
		_chip_look.bg_color = SEALED_INK
		Type.display(_chip, Type.LABEL, HouseTheme.ON_FOIL)
	reset_size()


## The accept button drawn before [param words], what it does to the card, for a keyboard or a pad
## as [param keyboard] says, GAME.md 9.6; nothing for no words, or with nothing bound to it.
func show_bind(keyboard: bool, words: String) -> void:
	var stamp := "" if words.is_empty() else InputHint.stamp([&"ui_accept"], keyboard) + words
	if stamp != _bind_for:
		_bind_for = stamp
		# The old line out of sight at once and gone at the frame's end, kept in the tree meanwhile.
		if _bind_row != null:
			_bind_row.visible = false
			_bind_row.queue_free()
			_bind_row = null
		var glyph: InputGlyph = null
		if not words.is_empty():
			glyph = InputGlyph.of_action(&"ui_accept", keyboard, HouseTheme.INK, Type.LABEL)
		if glyph != null:
			_bind_row = InputHint.row("%s " + words, [glyph], HouseTheme.INK, Type.LABEL)
			InputGlyph.look_under(_bind_row, GlyphArt.Look.DARK)
			_bind.add_child(_bind_row)
	_bind.visible = _bind_row != null
	reset_size()
