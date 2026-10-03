class_name LicenseTab
extends ScrollContainer
## The License tab of the settings, GAME.md 8.5: while the driving school or its test is under way,
## only that, see [method _underway]; otherwise the driver license earned at the driving school,
## 9.4a, to look at, in full on a click or a tap on it or on the hand's button, drawn under it, see
## [LicenseView], with the plate on the back of the kart to change under it, 4.4, and a button
## to retake the test; or, before one is earned, a word on where to get one, the button that goes
## there, and the learner's L the kart wears meanwhile.

const NONE_YET := "Missing license."
const HOW := "Pass the driving school's test to earn one. It takes a few minutes."
const EARN := "Earn it now"
const MEANWHILE := "Until then, your kart wears this."
const PLATE_LINE := "Up to %d letters, digits, spaces and dashes, on the back of your kart."
const RETAKE := "Retake the driving test"
const UNDERWAY := "License in progress"
const UNDERWAY_HOW := "You're taking the driving test right now. Finish it to earn your license."
const UNDERWAY_KEPT := "Your current license stays until you pass."
const CARD_SCALE := 0.7
## How big the hand's button is drawn on the card's bottom right corner, and where its middle
## sits from the corner of the card's box: on the rounded corner itself, so a quarter of it is over
## the card.
const LOOK_SIZE := 22
const LOOK_AT := -Vector2.ONE * LicenseCard.RADIUS * CARD_SCALE * (1.0 - 0.7071)

var field: PlateField
## The way to the driving school: Earn it now on a tab with no license to show, and Retake the
## driving test under a license.
var earn: Button
var retake: Button
## The license in full while it is up.
var view: LicenseView

var _settings: Settings
## The hand's button under the card, whether a keyboard and mouse are in hand rather than a pad,
## and what had the cursor before the license came up in full.
var _look: Control
var _keyboard := true
var _was_focused: Control


static func make(settings: Settings) -> LicenseTab:
	var tab := LicenseTab.new()
	tab.name = "License"
	tab._settings = settings
	return tab


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	_keyboard = Game.last_input_keyboard
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	if DrivingSchool.underway:
		_underway(column)
	elif _settings.license_number.is_empty():
		_none_yet(column)
	else:
		_license(column)


## In the school or its test: what is under way, and no way to the school, which would leave the
## test for the start of another. A license already held stays until the new one is earned.
func _underway(column: VBoxContainer) -> void:
	column.add_child(MenuTheme.title(UNDERWAY, Type.HEADING))
	column.add_child(MenuTheme.subtitle(UNDERWAY_HOW, Type.BODY))
	if not _settings.license_number.is_empty():
		column.add_child(MenuTheme.subtitle(UNDERWAY_KEPT, Type.LABEL))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 8.0)
	column.add_child(gap)
	var learner := SchoolFigure.of(SchoolFigure.Kind.LEARNER, 96.0)
	learner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(learner)


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
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_card_input)
	holder.add_child(card)
	column.add_child(holder)
	# A point over the card's bottom right corner the button is centered on, see [method _say_look].
	_look = Control.new()
	_look.name = "Look"
	_look.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_look.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_look.offset_left = LOOK_AT.x
	_look.offset_right = LOOK_AT.x
	_look.offset_top = LOOK_AT.y
	_look.offset_bottom = LOOK_AT.y
	holder.add_child(_look)
	_say_look()
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap)
	field = PlateField.make(_settings.license_plate)
	field.plate_changed.connect(_on_plate_typed)
	column.add_child(PlateField.row("License plate", field))
	column.add_child(MenuTheme.subtitle(PLATE_LINE % LicensePlate.MOST, Type.LABEL))
	var gap_after := Control.new()
	gap_after.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap_after)
	retake = MenuTheme.button(RETAKE, Type.BODY)
	retake.name = "Retake"
	retake.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retake.pressed.connect(_to_the_school)
	column.add_child(retake)


## The hand's button shows the license in full, before the focus takes the key for walking the
## controls; and what was pressed says which button to draw. Only while the tab is up.
func _input(event: InputEvent) -> void:
	if _look == null or not is_visible_in_tree():
		return
	var was := _keyboard
	_keyboard = LicenseView.keyboard_after(event, _keyboard)
	if was != _keyboard:
		_say_look()
	if event.is_action_pressed(InputActions.JOKER_MENU) and view == null:
		get_viewport().set_input_as_handled()
		look_closer()


## A click or a tap on the card shows it in full.
func _on_card_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
	):
		get_viewport().set_input_as_handled()
		look_closer()


## The license in full over the whole screen the settings are on, as the title shows it; put
## away, the cursor goes back where it was.
func look_closer() -> void:
	if view != null:
		return
	_was_focused = get_viewport().gui_get_focus_owner()
	var top: Control = self
	while top.get_parent() is Control:
		top = top.get_parent() as Control
	# Over the screen the tab is on; a tab on its own has the window, under whatever holds it.
	view = LicenseView.open(top if top != self else get_parent(), _keyboard)
	view.put_away.connect(_on_put_away)


func _on_put_away() -> void:
	view = null
	if _was_focused != null and is_instance_valid(_was_focused):
		_was_focused.grab_focus()


## The hand's button, drawn alone for the device in hand on the card's bottom right corner, over
## the card, the way the title draws it beside its own; on a touch screen the finger, for the tap.
## A click on it is a click on the card under it.
func _say_look() -> void:
	if _look == null:
		return
	for old: Node in _look.get_children():
		_look.remove_child(old)
		old.queue_free()
	var glyph := (
		InputGlyph.of_finger(Palette.CHIP_WHITE, LOOK_SIZE)
		if TouchInput.enabled
		else InputGlyph.of_action(InputActions.JOKER_MENU, _keyboard, Palette.CHIP_WHITE, LOOK_SIZE)
	)
	if glyph == null:
		return
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_look.add_child(glyph)
	# Its middle on the corner, which is where the point it hangs from is, whatever size it is.
	_on_the_corner(glyph)
	glyph.minimum_size_changed.connect(_on_the_corner.bind(glyph))


func _on_the_corner(glyph: Control) -> void:
	glyph.size = glyph.get_combined_minimum_size()
	glyph.position = -glyph.size * 0.5


## Out of whatever room the settings were opened over, and to the school.
func _to_the_school() -> void:
	Net.close()
	Game.go_to_tutorial()


## The plate as typed, cleaned on the way, see [PlateField].
func _on_plate_typed(cleaned: String) -> void:
	_settings.license_plate = cleaned
