class_name ProfilesTab
extends ScrollContainer
## The Profiles tab of the settings, GAME.md 8.5: every profile kept on this machine, see
## [Profile], the one playing marked, each named for its first player, a name Edit changes in a
## [NameDialog], and its plate. One can be switched to, a new one made, up to
## [constant Profile.MOST], named as it is made and gone to, and any but the one playing thrown
## away, which asks first in a question over the screen. Edit and Delete are the pencil and the
## trash can the kept servers of Play Online wear, see [IconButton], and Switch two arrows trading
## places, first of the three, since it is what a row is most often pressed for. All of that is
## done from the title's settings: inside a room the names at the table are already the ones
## playing, so there the tab only lists them and says where to go. Making one in a room once froze
## the game, the settings going to a page of their own under a room that was stopped.

const TITLE := "Profiles"
## What the page is for, said at its top.
const LINE := "Each person's names, karts, license and statistics. Switch to play as another."
const PLAYING := "Playing"
const SWITCH := "Switch"
const EDIT := "Edit"
const RENAME := "Rename profile"
const SAVE := "Save"
const MAKE := "Make"
const MAKE_AND_SWITCH := "Make and switch"
const DELETE := "Delete"
## The question Delete asks first, and its answers.
const SURE := "Delete this profile?"
const SURE_LINE := "%s's names, karts, license and statistics are thrown away for good."
const KEEP := "Keep"
## The Demo button, the question it asks first, and its answers: it restarts the game in demo mode
## on a separate throwaway profile, see [Demo] and [constant DEMO_FLAG].
const DEMO := "Demo"
const DEMO_SURE := "Start demo mode?"
const DEMO_LINE := (
	"The game restarts in demo mode, which plays itself on a separate temporary profile. "
	+ "Your own profiles are left untouched."
)
const DEMO_START := "Start demo"
const CANCEL := "Cancel"
const DEMO_FLAG := "--demo"
const NEW := "New profile"
const ONLY_FROM_TITLE := "Manage profiles from the title screen."
const FULL := "Maximum number of profiles reached."
const MAPS := "%d maps"
const PLAYING_NOW := "Playing now  ·  %s"
## How big a row's icon buttons are.
const ICON := Vector2(56.0, 44.0)

## Whether profiles can be made, changed, switched to and thrown away here: off inside a room, see
## the class.
var can_switch := true
## Each profile's row, by its id, with its name, its edit, its switch and its delete.
var rows: Dictionary[String, Dictionary] = {}
var new_button: Button
## Restarts the game in demo mode, after a question, see [method _demo].
var demo_button: Button
## The name asked for just now, or null.
var dialog: NameDialog
## The question asked before a profile is thrown away, while it is up, or null.
var question: ConfirmPane

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
	# Down the middle, the way the Seats, License, Statistics and About pages are.
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	SettingsScreen.page_head(column, TITLE, LINE)
	var kept := _settings.profiles()
	for profile: Profile in kept:
		column.add_child(_row(profile))
	new_button = MenuTheme.button(NEW, Type.BODY)
	new_button.name = "New"
	new_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_button.disabled = kept.size() >= Profile.MOST or not can_switch
	new_button.pressed.connect(_new)
	column.add_child(new_button)
	demo_button = MenuTheme.button(DEMO, Type.BODY)
	demo_button.name = "Demo"
	demo_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	demo_button.disabled = not can_switch
	demo_button.pressed.connect(_demo)
	column.add_child(demo_button)
	if not can_switch:
		column.add_child(SettingsScreen.centered_line(ONLY_FROM_TITLE))
	elif new_button.disabled:
		column.add_child(SettingsScreen.centered_line(FULL))


## One profile, as a seat card, see [SeatCard]: its chip in its first player's color with the
## name's initial on it, the name over how much it has played, its plate, and what can be done with
## it. The one playing is rimmed in foil.
func _row(profile: Profile) -> SeatCard:
	var playing := profile.id == _settings.profile.id
	var maps := MAPS % roundi(LifetimeStats.value_of(profile, &"maps"))
	var card := SeatCard.make(
		profile.display_name(),
		_color_of(profile),
		profile.display_name().left(1).to_upper(),
		PLAYING_NOW % maps if playing else maps,
		playing
	)
	card.name = "Profile%s" % profile.id
	card.custom_minimum_size.x = SeatCard.WIDE
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.show_plate(_worn_by(profile))
	var switch := IconButton.of(IconButton.Kind.SWAP, PLAYING if playing else SWITCH)
	switch.name = "Switch"
	switch.custom_minimum_size = ICON
	switch.disabled = playing or not can_switch
	switch.pressed.connect(_switch.bind(profile.id))
	card.actions.add_child(switch)
	var edit := IconButton.of(IconButton.Kind.PENCIL, EDIT)
	edit.name = "Edit"
	edit.custom_minimum_size = ICON
	edit.disabled = not can_switch
	edit.pressed.connect(_edit.bind(profile))
	card.actions.add_child(edit)
	var delete := IconButton.of(IconButton.Kind.TRASH, DELETE)
	delete.name = "Delete"
	delete.custom_minimum_size = ICON
	delete.disabled = playing or not can_switch
	delete.pressed.connect(_delete.bind(profile, delete))
	card.actions.add_child(delete)
	rows[profile.id] = {
		"row": card, "name": card.name_label, "edit": edit, "switch": switch, "delete": delete
	}
	return card


## The color of [param profile]'s first player, or the first seat's for one with none chosen.
static func _color_of(profile: Profile) -> Color:
	var chosen := profile.colors[0] if not profile.colors.is_empty() else -1
	return Palette.player_color(chosen if chosen >= 0 else 0)


## What a profile's kart wears on its back: its plate, or before a license the learner's L.
static func _worn_by(profile: Profile) -> String:
	return "L" if profile.license_number.is_empty() else profile.license_plate


## Asks for [param profile]'s name, its first player's, and calls it that.
func _edit(profile: Profile) -> void:
	if not can_switch:
		return
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
	(rows[profile.id]["row"] as SeatCard).set_chip(
		_color_of(profile), profile.display_name().left(1).to_upper()
	)


## The name [param title] asks for, [param text] in the box to start with, [param ok] on the
## button that goes ahead with it into [param then], and with [param also] a second way ahead into
## [param also_then]; the cursor back where it was after.
func _ask(
	title: String, text: String, ok: String, then: Callable, also := "", also_then := Callable()
) -> void:
	if dialog != null:
		return
	var was := get_viewport().gui_get_focus_owner()
	dialog = NameDialog.open(self, title, text, ok, also)
	dialog.named.connect(then)
	if also_then.is_valid():
		dialog.named_also.connect(also_then)
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


## Asks for the new profile's name and makes it: Make leaves the one playing as it is, and Make and
## switch goes to the new one as well.
func _new() -> void:
	if can_switch:
		_ask(NEW, Store.persona(), MAKE, _make.bind(false), MAKE_AND_SWITCH, _make.bind(true))


func _make(named: String, switch: bool) -> void:
	var made := _settings.new_profile()
	if made == null:
		return
	made.player_names[0] = named
	made.save_to_disk()
	if switch:
		_settings.switch_profile(made.id)
	# The page up again either way, with the new profile on it.
	if _switched.is_valid():
		_switched.call(_settings.profile.id)


## A question put over the whole screen, shaded, with [param kind]'s sign: Delete's and the demo's.
## [param on_yes] runs on yes; the cursor goes back to [param from] on no. One at a time.
func _confirm(
	title: String,
	line: String,
	yes: String,
	no: String,
	kind: RoadSign.Kind,
	from: Control,
	on_yes: Callable
) -> void:
	if question != null:
		return
	var top: Control = self
	while top.get_parent() is Control:
		top = top.get_parent() as Control
	var holder := Control.new()
	holder.name = "Question"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	(top if top != self else get_parent()).add_child(holder)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(middle)
	question = ConfirmPane.new()
	middle.add_child(question)
	question.answered.connect(
		func(yes_pressed: bool) -> void:
			holder.queue_free()
			question = null
			if yes_pressed:
				on_yes.call()
			elif from != null and is_instance_valid(from) and from.is_inside_tree():
				from.grab_focus()
	)
	question.ask(title, line, yes, no, kind)


## Asks first, over the screen, with the warning sign, since what goes cannot come back; thrown
## away on yes, and the cursor back on [param button] on no.
func _delete(profile: Profile, button: Button) -> void:
	if not can_switch:
		return
	_confirm(
		SURE,
		SURE_LINE % profile.display_name(),
		DELETE,
		KEEP,
		RoadSign.Kind.WARNING,
		button,
		func() -> void:
			if _settings.delete_profile(profile.id) and _switched.is_valid():
				_switched.call(_settings.profile.id)
	)


## Asks first, then restarts the game in demo mode, GAME.md 8.5: it plays itself on a separate
## throwaway profile, see [Demo], so the player's own are left as they are. It relaunches with
## [constant DEMO_FLAG], the way the demo is started from the command line, rather than switching
## modes in place, so the two are kept apart.
func _demo() -> void:
	if not can_switch:
		return
	_confirm(
		DEMO_SURE,
		DEMO_LINE,
		DEMO_START,
		CANCEL,
		RoadSign.Kind.QUESTION,
		demo_button,
		func() -> void:
			OS.set_restart_on_exit(true, PackedStringArray([DEMO_FLAG]))
			get_tree().quit()
	)
