class_name TourTag
extends PanelContainer
## A tag of the House's cream card, GAME.md 8.9 "The first look": what one step of the House's tour
## of its map says, beside what it speaks of, see [LoyaltyTour]. Perforated along its top as the
## map's tickets are, a red chip on it counting the step, a heading in the House's capitals and one
## line under it, and its buttons along its foot: Skip tour at the left, its bind drawn on it while
## keys or a pad are in hand, and at the right what goes on, the cursor on the last of them.

## A button along its foot pressed, by its words.
signal pressed(words: String)

## How wide it is at the most, and the least it is ever made, the screen's room allowing; how much
## room is round what it says, and the dots of its perforation, how big and how far apart.
const WIDE := 600.0
const LEAST := 300.0
const ROOM := Vector2(26.0, 22.0)
const DOT := 2.6
const DOT_STEP := 15.0
const DOTS_DOWN := 9.0
const CHIP := Color(0.8, 0.17, 0.14)
const EDGE := Color(0.58, 0.5, 0.36, 0.7)
const DOT_INK := Color(0.72, 0.66, 0.54)
## A button's height, a finger's on a touch screen, the least it is across, and the room kept
## either side of its words for the cursor's chevrons.
const BUTTON_TALL := 44.0
const BUTTON_LEAST := 120.0
const CHEVRON_ROOM := 34.0
const SKIP := "Skip tour"

var heading: Label
var line: Label
var chip: Label
## Skip tour, and the buttons that go on, in order, the last the one the cursor goes to.
var skip: Button
var goes: Array[Button] = []

var _foot: HBoxContainer


func _init() -> void:
	name = "Tag"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var look := StyleBoxFlat.new()
	look.bg_color = HouseTheme.PAPER
	look.set_corner_radius_all(6)
	look.set_border_width_all(1)
	look.border_color = EDGE
	look.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	look.shadow_size = 14
	look.shadow_offset = Vector2(4.0, 8.0)
	look.content_margin_left = ROOM.x
	look.content_margin_right = ROOM.x
	look.content_margin_top = ROOM.y + DOTS_DOWN
	look.content_margin_bottom = ROOM.y - 6.0
	add_theme_stylebox_override("panel", look)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(head)
	chip = Label.new()
	chip.name = "Chip"
	Type.display(chip, Type.LABEL + 3, HouseTheme.PAPER)
	var red := StyleBoxFlat.new()
	red.bg_color = CHIP
	red.set_corner_radius_all(4)
	red.content_margin_left = 10.0
	red.content_margin_right = 10.0
	red.content_margin_top = 2.0
	red.content_margin_bottom = 2.0
	chip.add_theme_stylebox_override("normal", red)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(chip)
	heading = Label.new()
	heading.name = "Heading"
	heading.uppercase = true
	Type.display(heading, Type.HEADING, HouseTheme.INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(heading)
	line = Label.new()
	line.name = "Line"
	Type.text(line, Type.BODY, HouseTheme.INK)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(line)
	var rule := ColorRect.new()
	rule.color = Color(EDGE, 0.5)
	rule.custom_minimum_size.y = 1.0
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	_foot = HBoxContainer.new()
	_foot.name = "Foot"
	_foot.add_theme_constant_override("separation", 12)
	column.add_child(_foot)
	skip = _button(SKIP, false)
	skip.name = "Skip"
	ButtonBinds.mark(skip, &"ui_cancel")
	_foot.add_child(skip)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foot.add_child(gap)


## Says step [param step] of [param steps]: [param title] and [param said], and along its foot
## Skip tour, where [param skippable], and [param going], the buttons that go on, the last of them
## the House's own ink, the cursor on it.
func say(
	step: int, steps: int, title: String, said: String, going: Array[String], skippable := true
) -> void:
	chip.text = "%d/%d" % [step, steps]
	heading.text = title
	line.text = said
	skip.visible = skippable
	for button: Button in goes:
		button.hide()
		button.queue_free()
	goes.clear()
	for i: int in going.size():
		var button := _button(going[i], i == going.size() - 1)
		_foot.add_child(button)
		goes.append(button)
	# Left and right between them, and nowhere else.
	var row: Array[Button] = []
	if skippable:
		row.append(skip)
	row.append_array(goes)
	for i: int in row.size():
		var here := row[i].get_path()
		row[i].focus_neighbor_left = row[maxi(i - 1, 0)].get_path()
		row[i].focus_neighbor_right = row[mini(i + 1, row.size() - 1)].get_path()
		row[i].focus_neighbor_top = here
		row[i].focus_neighbor_bottom = here
		row[i].focus_next = row[(i + 1) % row.size()].get_path()
		row[i].focus_previous = row[(i - 1 + row.size()) % row.size()].get_path()
	ScreenReader.name(self, ScreenReader.spoken(title), said)


## The button the cursor goes to: the last that goes on.
func main() -> Button:
	return goes[-1] if not goes.is_empty() else skip


## As wide as [param room] lets it be, up to [constant WIDE].
func fit_to(room: float) -> void:
	var wide := clampf(room, minf(LEAST, room), WIDE)
	custom_minimum_size.x = wide
	size = Vector2(wide, 0.0)
	reset_size()


## The binds hung on Skip tour for keys, [param keyboard], or a pad, while [param shown].
func show_binds(keyboard: bool, shown: bool) -> void:
	ButtonBinds.show([skip], keyboard, shown and skip.visible)


func _button(words: String, inked: bool) -> Button:
	var button := MenuTheme.button(words, Type.LABEL + 1)
	button.theme_type_variation = HouseTheme.PAPER_PRIMARY if inked else HouseTheme.PAPER_BUTTON
	# Room either side of its words for the cursor's chevrons.
	var font := button.get_theme_font(&"font")
	var words_wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, Type.LABEL + 1).x
	var tall := BUTTON_TALL if not TouchInput.enabled else 56.0
	button.custom_minimum_size = Vector2(maxf(BUTTON_LEAST, words_wide + CHEVRON_ROOM * 2.0), tall)
	button.pressed.connect(func() -> void: pressed.emit(words))
	return button


func _draw() -> void:
	# The perforation along its top, as a ticket torn off a book of them has.
	var y := DOTS_DOWN + 2.0
	var x := DOT_STEP
	while x < size.x - DOT_STEP * 0.5:
		draw_circle(Vector2(x, y), DOT, DOT_INK)
		x += DOT_STEP
