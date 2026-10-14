class_name PowerUpDetail
extends PanelContainer
## The pane that describes one power-up in the catalog, GAME.md 8.8: cut as a joker's pane is, see
## [JokerDetail], and framed in the item's own color. Its name in the header, a perforation, what it
## does in a sentence, and then the numbers no match shows, a line each, what and how much, read
## from the item, see [method PowerUp.facts], the set it comes in among them. A face-down item's
## pane says only that it has not been found. The catalog prints it on the House's paper, its spec
## sheet, see [method print_on_paper].

const WIDTH := JokerDetail.WIDTH
const HINT := JokerDetail.HINT
const FRAME := JokerDetail.FRAME
const FRAME_BODY := JokerDetail.FRAME_BODY
const ENGRAVED := JokerDetail.ENGRAVED
## How the facts are drawn: what each is, and how much.
const FACT_NAME := Color(0.7, 0.7, 0.76)
const FACT_VALUE := Color(0.97, 0.97, 1.0)
const FACT_SIZE := 17
const BODY := Color(0.94, 0.94, 0.97)

var _style: TicketStyle
## Whether it is printed on the House's paper, see [method print_on_paper].
var _paper := false
var _name: Label
var _body: Label
var _facts: GridContainer
var _box: VBoxContainer
var _hints: Control
## The item the pane is filled in for, so filling it in again for the same is nothing.
var _item: PowerUp


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = TicketStyle.cut(MenuTheme.PANE_BG, 10.0, 18.0, 18.0)
	_style.frame_inset = 5.0
	_style.bite = 8.0
	_style.waves = 64.0
	_style.shadow = 12.0
	add_theme_stylebox_override("panel", _style)
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 9)
	add_child(_box)
	_name = Label.new()
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(_name, Type.display_font(), 28)
	_name.add_theme_color_override("font_color", Color(0.97, 0.97, 1.0))
	_box.add_child(_name)
	var tear := MenuTheme.perforation()
	tear.custom_minimum_size.x = WIDTH
	_box.add_child(tear)
	_body = Label.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH, 0.0)
	Type.text(_body, 18, BODY)
	_box.add_child(_body)
	_facts = GridContainer.new()
	_facts.name = "Facts"
	_facts.columns = 2
	_facts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_facts.add_theme_constant_override("h_separation", 24)
	_facts.add_theme_constant_override("v_separation", 4)
	_box.add_child(_facts)


## Prints the pane on the House's cream paper, as a joker's is, see [method
## JokerDetail.print_on_paper].
func print_on_paper() -> void:
	_paper = true
	var look := TicketStyle.cut(HouseTheme.PAPER, 10.0, 18.0, 18.0)
	look.frame_inset = _style.frame_inset
	look.bite = _style.bite
	look.shadow = _style.shadow
	look.frame = _style.frame
	look.frame_body = _style.frame_body
	_style = look
	add_theme_stylebox_override("panel", _style)
	_name.add_theme_color_override("font_color", HouseTheme.INK)
	_item = null


## Fills the pane for [param item], with [param facts] its lines of numbers, the set it comes in
## among them, and puts its color round the header.
func show_item(item: PowerUp, facts: Array[PackedStringArray]) -> void:
	if item == _item:
		return
	_item = item
	_wear(PowerUp.ink_of(item))
	_name.text = item.display_name
	_body.text = item.description
	_body.add_theme_color_override("font_color", HouseTheme.INK if _paper else BODY)
	_facts.visible = true
	for child: Node in _facts.get_children():
		_facts.remove_child(child)
		child.queue_free()
	for line: PackedStringArray in facts:
		var named := Label.new()
		named.text = line[0]
		named.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Type.text(named, FACT_SIZE, HouseTheme.INK_FAINT if _paper else FACT_NAME)
		_facts.add_child(named)
		var value := Label.new()
		value.text = line[1]
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		Type.strong(value, FACT_SIZE, HouseTheme.INK if _paper else FACT_VALUE)
		_facts.add_child(value)


## Fills the pane for an item lying face down: [param words] in its name's place, [param under] in
## gray under them, and nothing else.
func show_unknown(words: String, under: String) -> void:
	_item = null
	_wear(CardBack.INK)
	_name.text = words
	_body.text = under
	_body.add_theme_color_override("font_color", HouseTheme.INK_FAINT if _paper else HINT)
	_facts.visible = false


## What the pane says of what is under it: the lines of facts, each its words and its value.
func facts_shown() -> Array[PackedStringArray]:
	var lines: Array[PackedStringArray] = []
	var cells := _facts.get_children()
	for i: int in range(0, cells.size() - 1, 2):
		lines.append(PackedStringArray([(cells[i] as Label).text, (cells[i + 1] as Label).text]))
	return lines


## What the pane's header says.
func title() -> String:
	return _name.text


## The row at the pane's foot, as [method JokerDetail.set_hints] has it, or none for null.
func set_hints(line: Control) -> void:
	if _hints != null:
		_box.remove_child(_hints)
		_hints.queue_free()
	_hints = line
	if _hints != null:
		_box.add_child(_hints)


func _wear(color: Color) -> void:
	var ink := HouseTheme.on_paper(color) if _paper else color
	_style.frame = Color(ink, FRAME)
	_style.frame_body = Color(ink, FRAME_BODY)
	_style.engraving = Color(ink, 0.0 if _paper else ENGRAVED)
