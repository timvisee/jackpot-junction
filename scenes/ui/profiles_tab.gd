class_name ProfilesTab
extends ScrollContainer
## The Profiles tab of the settings, first among them, GAME.md 8.5: every profile kept on this
## machine, see [Profile], the one playing marked, each named for its first player, a name that can
## be typed over here, and its plate. One can be switched to, a new one made, up to
## [constant Profile.MOST], and any but the one playing thrown away, which asks first by asking
## the button to be pressed again. Switching is from the title's settings: inside a room the names
## at the table are already the ones playing, and the tab says where to go to switch.

const TITLE := "Profiles"
const PLAYING := "Playing"
const SWITCH := "Switch"
const DELETE := "Delete"
const SURE := "Delete it?"
const NEW := "New profile"
const ONLY_FROM_TITLE := "Switch profiles from the title screen."
const FULL := "That is as many profiles as a machine keeps."
## How long the second press of Delete is waited for, in seconds.
const SURE_FOR := 3.0
## How wide a name is, and how wide the plate beside it is drawn.
const NAME_WIDE := 320.0
const PLATE_WIDE := 112.0

## Whether a profile can be switched to here: off inside a room, see the class.
var can_switch := true
## Each profile's row, by its id, with its name, its switch and its delete.
var rows: Dictionary[String, Dictionary] = {}
var new_button: Button

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
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	column.add_child(MenuTheme.title(TITLE, Type.HEADING))
	var kept := _settings.profiles()
	for profile: Profile in kept:
		column.add_child(_row(profile))
	new_button = MenuTheme.button(NEW, Type.BODY)
	new_button.name = "New"
	new_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_button.disabled = kept.size() >= Profile.MOST
	new_button.pressed.connect(_new)
	column.add_child(new_button)
	if not can_switch:
		column.add_child(MenuTheme.subtitle(ONLY_FROM_TITLE, Type.LABEL))
	elif new_button.disabled:
		column.add_child(MenuTheme.subtitle(FULL, Type.LABEL))


## One profile: its name to type over, its plate, and what can be done with it.
func _row(profile: Profile) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Profile%s" % profile.id
	row.add_theme_constant_override("separation", 18)
	var playing := profile.id == _settings.profile.id
	var named := MenuTheme.field(
		profile.player_names[0], profile.display_name(), PlayerNames.MAX_LENGTH
	)
	named.custom_minimum_size = Vector2(NAME_WIDE, MenuTheme.box_height())
	named.text_submitted.connect(func(_text: String) -> void: _rename(profile, named))
	named.focus_exited.connect(_rename.bind(profile, named))
	row.add_child(named)
	var plate := LicensePlate.of(_plate_of(profile), PLATE_WIDE)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(plate)
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
	rows[profile.id] = {"row": row, "name": named, "switch": switch, "delete": delete}
	return row


## What a profile's kart wears on its back: its plate, the learner's L before a license, or the
## blank plate for a bare bumper.
static func _plate_of(profile: Profile) -> String:
	if profile.license_number.is_empty():
		return "L"
	return profile.license_plate


## A name typed over: the profile's first player is called it, cleaned the way a name is.
func _rename(profile: Profile, field: LineEdit) -> void:
	var named := PlayerNames.clean(field.text)
	if named == profile.player_names[0]:
		return
	profile.player_names[0] = named
	if profile.id == _settings.profile.id:
		_settings.player_names[0] = named
		_settings.save_to_disk()
	else:
		profile.save_to_disk()


func _switch(id: String) -> void:
	if not can_switch:
		return
	_settings.switch_profile(id)
	if _switched.is_valid():
		_switched.call(id)


func _new() -> void:
	var made := _settings.new_profile()
	if made != null and _switched.is_valid():
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
