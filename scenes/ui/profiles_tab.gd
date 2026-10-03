class_name ProfilesTab
extends ScrollContainer
## The Profiles tab of the settings, GAME.md 8.5: every profile kept on this machine, see
## [Profile], the one playing marked, each named for its first player, a name Edit changes in a
## [NameDialog], and its plate. One can be switched to, a new one made, up to
## [constant Profile.MOST], named as it is made and gone to, and any but the one playing thrown
## away, which asks first by asking the button to be pressed again. Switching is from the title's
## settings: inside a room the names at the table are already the ones playing, and the tab says
## where to go to switch; a profile made there is only made, for a seat to sit in as, 3.8.

const TITLE := "Profiles"
## What the page is for, said at its top.
const LINE := "Each person's names, karts, license and statistics. Switch to play as another."
const PLAYING := "Playing"
const SWITCH := "Switch"
const EDIT := "Edit"
const RENAME := "Rename profile"
const SAVE := "Save"
const MAKE := "Make"
const DELETE := "Delete"
const SURE := "Delete it?"
const NEW := "New profile"
const ONLY_FROM_TITLE := "Switch profiles from the title screen."
const FULL := "That is as many profiles as a machine keeps."
const MAPS := "%d maps"
## How long the second press of Delete is waited for, in seconds.
const SURE_FOR := 3.0
## How wide a name is, and how wide the plate beside it is drawn.
const NAME_WIDE := 320.0
const PLATE_WIDE := 112.0

## Whether a profile can be switched to here: off inside a room, see the class.
var can_switch := true
## Each profile's row, by its id, with its name, its edit, its switch and its delete.
var rows: Dictionary[String, Dictionary] = {}
var new_button: Button
## The name asked for just now, or null.
var dialog: NameDialog

var _settings: Settings
## Run with the id switched to, so the settings can be put up again for the profile now playing.
var _switched: Callable


static func make(settings: Settings, switching: bool, switched: Callable) -> ProfilesTab:
	var tab := ProfilesTab.new()
	tab.name = TITLE
	tab._settings = settings
	tab.can_switch = switching
	tab._switched = switched
	return tab


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	# Down the left, the way the Players page is.
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	column.add_child(SettingsScreen.page_line(LINE))
	var kept := _settings.profiles()
	for profile: Profile in kept:
		column.add_child(_row(profile))
	new_button = MenuTheme.button(NEW, Type.BODY)
	new_button.name = "New"
	new_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	new_button.disabled = kept.size() >= Profile.MOST
	new_button.pressed.connect(_new)
	column.add_child(new_button)
	if not can_switch:
		column.add_child(SettingsScreen.page_line(ONLY_FROM_TITLE))
	elif new_button.disabled:
		column.add_child(SettingsScreen.page_line(FULL))


## One profile: its name, its plate, and what can be done with it.
func _row(profile: Profile) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Profile%s" % profile.id
	row.add_theme_constant_override("separation", 18)
	var playing := profile.id == _settings.profile.id
	var named := Label.new()
	named.text = profile.display_name()
	named.custom_minimum_size = Vector2(NAME_WIDE, 0.0)
	named.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	named.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Type.strong(named, Type.BODY, Palette.CHIP_GOLD if playing else Palette.CHIP_WHITE)
	row.add_child(named)
	row.add_child(_plate_of(profile))
	var played := Label.new()
	played.text = MAPS % roundi(LifetimeStats.value_of(profile, &"maps"))
	played.custom_minimum_size = Vector2(120.0, 0.0)
	played.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Type.text(played, Type.LABEL, Color(0.72, 0.72, 0.78))
	row.add_child(played)
	var edit := MenuTheme.button(EDIT, Type.BODY)
	edit.custom_minimum_size = Vector2(120.0, MenuTheme.box_height())
	edit.pressed.connect(_edit.bind(profile))
	row.add_child(edit)
	var switch := MenuTheme.button(PLAYING if playing else SWITCH, Type.BODY)
	switch.custom_minimum_size = Vector2(170.0, MenuTheme.box_height())
	switch.disabled = playing or not can_switch
	switch.pressed.connect(_switch.bind(profile.id))
	row.add_child(switch)
	var delete := MenuTheme.button(DELETE, Type.BODY)
	delete.custom_minimum_size = Vector2(170.0, MenuTheme.box_height())
	delete.disabled = playing
	delete.pressed.connect(_delete.bind(profile.id, delete))
	row.add_child(delete)
	rows[profile.id] = {"row": row, "name": named, "edit": edit, "switch": switch, "delete": delete}
	return row


## What a profile's kart wears on its back: its plate, or before a license the learner's L itself
## rather than a plate reading L, in the plate's room.
static func _plate_of(profile: Profile) -> Control:
	var room := CenterContainer.new()
	room.custom_minimum_size = Vector2(
		PLATE_WIDE, PLATE_WIDE * LicensePlate.SIZE.y / LicensePlate.SIZE.x
	)
	room.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shown: Control
	if profile.license_number.is_empty():
		shown = SchoolFigure.of(SchoolFigure.Kind.LEARNER, room.custom_minimum_size.y)
		shown.name = "Learner"
	else:
		shown = LicensePlate.of(profile.license_plate, PLATE_WIDE)
		shown.name = "Plate"
	room.add_child(shown)
	return room


## Asks for [param profile]'s name, its first player's, and calls it that.
func _edit(profile: Profile) -> void:
	_ask(RENAME, profile.player_names[0], SAVE, _rename.bind(profile))


## [param profile]'s first player is called [param named] from now on.
func _rename(named: String, profile: Profile) -> void:
	if named == profile.player_names[0]:
		return
	profile.player_names[0] = named
	if profile.id == _settings.profile.id:
		_settings.player_names[0] = named
		_settings.save_to_disk()
	else:
		profile.save_to_disk()
	(rows[profile.id]["name"] as Label).text = profile.display_name()


## The name [param title] asks for, [param text] in the box to start with, [param ok] on the
## button that goes ahead with it into [param then]; the cursor back where it was after.
func _ask(title: String, text: String, ok: String, then: Callable) -> void:
	if dialog != null:
		return
	var was := get_viewport().gui_get_focus_owner()
	dialog = NameDialog.open(self, title, text, ok)
	dialog.named.connect(then)
	dialog.put_away.connect(
		func() -> void:
			dialog = null
			if was != null and is_instance_valid(was) and was.is_inside_tree():
				was.grab_focus()
	)


func _switch(id: String) -> void:
	if not can_switch:
		return
	_settings.switch_profile(id)
	if _switched.is_valid():
		_switched.call(id)


## Asks for the new profile's name, makes it, and goes to it; inside a room only makes it.
func _new() -> void:
	_ask(NEW, "", MAKE, _make)


func _make(named: String) -> void:
	var made := _settings.new_profile()
	if made == null:
		return
	made.player_names[0] = named
	made.save_to_disk()
	if can_switch:
		_settings.switch_profile(made.id)
	if _switched.is_valid():
		_switched.call(_settings.profile.id)


## The first press asks, and the second, within [constant SURE_FOR], throws it away.
func _delete(id: String, button: Button) -> void:
	if button.text != SURE:
		button.text = SURE
		get_tree().create_timer(SURE_FOR).timeout.connect(
			func() -> void:
				if is_instance_valid(button) and button.text == SURE:
					button.text = DELETE
		)
		return
	if _settings.delete_profile(id) and _switched.is_valid():
		_switched.call(_settings.profile.id)
