class_name TableTag
extends PanelContainer
## A card of the table said in words, GAME.md 3.17: on the House's cream, a chip, the card's name
## in capitals and its one line of what it does. The loading screen's tag naming a card new to the
## player, 8.6, NEW on a chip in the neon's magenta, and the hint over a card of the match
## settings' strip while it is under the mouse or the cursor, 9.6, which says when a sealed card
## opens on a chip of gold and has no chip for the rest.

enum Chip { NONE, NEW, SEALED }

## The new card's chip, the neon's magenta; and a sealed card's, the strip's gold band.
const NEW_INK := Color("#ff4fa3")
const SEALED_INK := Palette.CHIP_GOLD

var card := -1
var _chip: Label
var _chip_look: StyleBoxFlat
var _name: Label
var _line: Label


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
