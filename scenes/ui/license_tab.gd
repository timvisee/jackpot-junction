class_name LicenseTab
extends ScrollContainer
## The License tab of the settings, GAME.md 8.5: the driver license earned at the driving school,
## 9.4a, to look at, with the plate on the back of the kart to change under it, 4.4, and a button
## to retake the test; or, before one is earned, a word on where to get one, the button that goes
## there, and the learner's L the kart wears meanwhile.

const NONE_YET := "Missing license."
const HOW := "Pass the driving school's test to earn one. It takes a few minutes."
const EARN := "Earn it now"
const MEANWHILE := "Until then, your kart wears this."
const PLATE_LINE := "Up to %d letters, digits, spaces and dashes, on the back of your kart."
const RETAKE := "Retake the driving test"
const CARD_SCALE := 0.9

var field: LineEdit
var preview: LicensePlate
## The way to the driving school: Earn it now on a tab with no license to show, and Retake the
## driving test under a license.
var earn: Button
var retake: Button

var _settings: Settings


static func make(settings: Settings) -> LicenseTab:
	var tab := LicenseTab.new()
	tab.name = "License"
	tab._settings = settings
	return tab


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	if _settings.license_number.is_empty():
		_none_yet(column)
	else:
		_license(column)


## No license: where to get one, and the L worn until then.
func _none_yet(column: VBoxContainer) -> void:
	column.add_child(MenuTheme.title(NONE_YET, Type.HEADING))
	column.add_child(MenuTheme.subtitle(HOW, Type.BODY))
	earn = MenuTheme.button(EARN)
	earn.name = "Earn"
	earn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	earn.pressed.connect(_to_the_school)
	column.add_child(earn)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 8.0)
	column.add_child(gap)
	var learner := SchoolFigure.of(SchoolFigure.Kind.LEARNER, 96.0)
	learner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(learner)
	column.add_child(MenuTheme.subtitle(MEANWHILE, Type.LABEL))


## The license, stamped as it was, and the plate under it.
func _license(column: VBoxContainer) -> void:
	var card := LicenseCard.from_settings()
	card.name = "LicenseCard"
	var holder := Control.new()
	holder.custom_minimum_size = LicenseCard.SIZE * CARD_SCALE
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.scale = Vector2.ONE * CARD_SCALE
	card.position = (LicenseCard.SIZE * CARD_SCALE - LicenseCard.SIZE) * 0.5
	holder.add_child(card)
	column.add_child(holder)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap)
	field = MenuTheme.field(_settings.license_plate, LicensePlate.BLANK, LicensePlate.MOST)
	field.name = "Plate"
	field.custom_minimum_size = Vector2(240.0, MenuTheme.box_height())
	field.text_changed.connect(_on_plate_typed)
	var row := MenuTheme.row("License plate", field)
	preview = LicensePlate.of(_settings.license_plate, 168.0)
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(preview)
	column.add_child(row)
	column.add_child(MenuTheme.subtitle(PLATE_LINE % LicensePlate.MOST, Type.LABEL))
	var gap_after := Control.new()
	gap_after.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap_after)
	retake = MenuTheme.button(RETAKE, Type.BODY)
	retake.name = "Retake"
	retake.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retake.pressed.connect(_to_the_school)
	column.add_child(retake)


## Out of whatever room the settings were opened over, and to the school.
func _to_the_school() -> void:
	Net.close()
	Game.go_to_tutorial()


## The plate as typed, cleaned on the way: the box shows what the plate will read.
func _on_plate_typed(text: String) -> void:
	var cleaned := LicensePlate.clean(text)
	if cleaned != text:
		var caret := field.caret_column
		field.text = cleaned
		field.caret_column = mini(caret, cleaned.length())
	_settings.license_plate = cleaned
	preview.set_text(cleaned)
