class_name PlateField
extends LineEdit
## A license plate that is its own text box, GAME.md 4.4: the pale plate with its dark rim and its
## bolts, and the letters typed straight onto it in the plate's own lettering, rather than a box to
## type into with the plate drawn beside it to show what it would read. Gold round the rim while
## it is being typed into. What is typed is cleaned as it goes, upper case and nothing a plate
## cannot hold, see [method LicensePlate.clean], but a space at the end stands until the box is
## left, or nobody could type one between two words.

## The plate as it now reads, cleaned, as it is typed and once the box is left.
signal plate_changed(plate: String)

## How wide the plate is drawn, as a text box.
const WIDE := 288.0
## How the line beside it says it can be typed into, by the device in hand.
const TAP := "Tap to edit"
const CLICK := "Click to edit"
const PRESS := "%s to edit"


## A plate reading [param words] to be typed into, [param wide] pixels across.
static func make(words: String, wide := WIDE) -> PlateField:
	var field := PlateField.new()
	field.text = words
	field.custom_minimum_size = Vector2(wide, wide * LicensePlate.SIZE.y / LicensePlate.SIZE.x)
	return field


## [param field] in a row of its own, centered: [param label_text] just before it, at its own width
## rather than in a settings row's column, which left a gap the plate looked lost after, and the
## line saying it can be typed into after it.
static func row(label_text: String, field: PlateField) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Type.text(label, Type.BODY, Color(0.86, 0.86, 0.9))
	line.add_child(label)
	line.add_child(field)
	var how := hint(Color(0.72, 0.72, 0.78), Type.LABEL)
	how.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(how)
	return line


## The line that says a plate can be typed into, for the device in hand: a tap, a click, or the
## pad's accept button.
static func hint(ink: Color, font_size: int) -> Control:
	if TouchInput.enabled or Game.last_input_keyboard:
		var line := Label.new()
		line.text = TAP if TouchInput.enabled else CLICK
		Type.text(line, font_size, ink)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return line
	var accept := InputGlyph.of_action(&"ui_accept", false, ink, font_size)
	return InputHint.row(PRESS, [accept], ink, font_size)


func _ready() -> void:
	name = "Plate"
	max_length = LicensePlate.MOST
	placeholder_text = LicensePlate.BLANK
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_menu_enabled = false
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tall := custom_minimum_size.y
	var plate := StyleBoxFlat.new()
	plate.bg_color = LicensePlate.PLATE
	plate.set_corner_radius_all(roundi(tall * 0.12))
	plate.set_border_width_all(maxi(roundi(tall * 0.05), 1))
	plate.border_color = LicensePlate.RIM
	plate.content_margin_left = tall * 0.3
	plate.content_margin_right = tall * 0.3
	add_theme_stylebox_override("normal", plate)
	add_theme_stylebox_override("read_only", plate)
	var lit := StyleBoxFlat.new()
	lit.draw_center = false
	lit.set_corner_radius_all(roundi(tall * 0.12))
	lit.set_border_width_all(maxi(roundi(tall * 0.07), 2))
	lit.border_color = Palette.CHIP_GOLD
	add_theme_stylebox_override("focus", lit)
	add_theme_font_override("font", Type.display_font())
	add_theme_font_size_override("font_size", roundi(tall * 0.52))
	add_theme_color_override("font_color", LicensePlate.INK)
	add_theme_color_override("font_placeholder_color", Color(LicensePlate.INK, 0.3))
	add_theme_color_override("caret_color", LicensePlate.INK)
	add_theme_color_override("selection_color", Color(Palette.CHIP_GOLD, 0.45))
	text_changed.connect(_typed)
	focus_exited.connect(_settle)


func _typed(raw: String) -> void:
	var kept := LicensePlate.clean_typed(raw)
	if kept != raw:
		var caret := caret_column
		text = kept
		caret_column = mini(caret, kept.length())
	plate_changed.emit(LicensePlate.clean(kept))


## Left, the plate reads as it will be worn: no space at its end.
func _settle() -> void:
	var done := LicensePlate.clean(text)
	if done != text:
		text = done
	plate_changed.emit(done)


## The bolts in its top corners, over the plate the box is drawn as.
func _draw() -> void:
	var inset := size.y * 0.16
	for x: float in [inset, size.x - inset]:
		draw_circle(Vector2(x, inset), size.y * 0.05, LicensePlate.BOLT)
