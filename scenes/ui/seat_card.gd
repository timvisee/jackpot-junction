class_name SeatCard
extends PanelContainer
## One person in a list of people, GAME.md 8.1a: the profiles in the settings, the seats at this
## screen, and everybody in a hosted game. Each the same row, so the three read as one list: a
## ticket of raised stock with a chip at its left end in the person's color, their seat or their
## initial on it, their name over a quiet line saying where they stand, the plate their kart wears,
## and at the right end what can be done with them. The row that is you is rimmed in foil.

## How wide a row is in the settings' lists, so the seats and the profiles line up page to page.
const WIDE := 820.0
## How big the chip is, how wide a plate is drawn, and how tall a row is at the least.
const CHIP := 40.0
const PLATE_WIDE := 96.0
const TALL := 60.0
## A chip for somebody with no color of their own: a watcher, who has no kart.
const NO_COLOR := Color(0.32, 0.31, 0.36)

## Their name, the line under it, the room the plate is shown in, and the buttons at the right end.
var name_label: Label
var line: Label
var plate: Control
var actions: HBoxContainer

var _chip: Control
var _ink := NO_COLOR
var _mark := ""
var _look: TicketStyle
var _words: VBoxContainer


## A row for [param named], their chip in [param ink] with [param mark] on it, [param says] under
## their name, rimmed in foil if [param mine].
static func make(named: String, ink: Color, mark: String, says := "", mine := false) -> SeatCard:
	var card := SeatCard.new()
	card._build()
	card.name_label.text = named
	card.set_chip(ink, mark)
	card.say(says)
	card.set_mine(mine)
	return card


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, TALL)
	_look = TicketStyle.cut(Color(HouseTheme.STOCK_RAISED, 0.92), 9.0, 14.0, 8.0)
	_look.frame_inset = 4.0
	Surface.wear(_look, "button")
	add_theme_stylebox_override("panel", _look)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	_chip = Control.new()
	_chip.name = "Chip"
	_chip.custom_minimum_size = Vector2(CHIP, CHIP)
	_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.draw.connect(_draw_chip)
	row.add_child(_chip)
	_words = VBoxContainer.new()
	_words.name = "Words"
	_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_words.alignment = BoxContainer.ALIGNMENT_CENTER
	_words.add_theme_constant_override("separation", 0)
	row.add_child(_words)
	name_label = Label.new()
	name_label.name = "Name"
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Type.strong(name_label, Type.BODY, HouseTheme.WORDS)
	_words.add_child(name_label)
	line = Label.new()
	line.name = "Line"
	Type.text(line, Type.LABEL, HouseTheme.QUIET)
	_words.add_child(line)
	plate = CenterContainer.new()
	plate.name = "PlateRoom"
	plate.custom_minimum_size = Vector2(PLATE_WIDE, 0.0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(plate)
	actions = HBoxContainer.new()
	actions.name = "Actions"
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(actions)


## The chip in [param ink] with [param mark] on it, a seat's number or an initial.
func set_chip(ink: Color, mark: String) -> void:
	_ink = ink
	_mark = mark
	_chip.queue_redraw()


## The line under the name, gone while it says nothing.
func say(says: String) -> void:
	line.text = says
	line.visible = not says.is_empty()


## Rimmed in foil, the row that is you, or not.
func set_mine(mine: bool) -> void:
	_look.fill = Color(HouseTheme.STOCK_LIT, 0.95) if mine else Color(HouseTheme.STOCK_RAISED, 0.92)
	_look.frame = Color(HouseTheme.FOIL, 0.6 if mine else HouseTheme.RIM)


## The plate [param worn] on the kart, as a list shows it, see [method LicensePlate.badge]: a plate,
## the learner's L, or nothing.
func show_plate(worn: String) -> void:
	for child: Node in plate.get_children():
		plate.remove_child(child)
		child.queue_free()
	plate.add_child(LicensePlate.badge(worn, PLATE_WIDE))


## [param control] in place of the name, a box to type it in say, with the line still under it.
func name_with(control: Control) -> void:
	name_label.visible = false
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_words.add_child(control)
	_words.move_child(control, 0)


func _draw_chip() -> void:
	var middle := _chip.size * 0.5
	var radius := minf(_chip.size.x, _chip.size.y) * 0.5
	if _mark.is_empty():
		ChipArt.kept_chip(_chip, middle, radius, _ink)
	else:
		ChipArt.numbered(_chip, middle, radius, _ink, _mark)
