class_name SettingsScreen
extends Control
## The settings screen from GAME.md 8.5: the license first, controls with rebinding, the players,
## audio, video and accessibility. Changes apply at once and are saved on Back.
##
## From the title it is a screen of its own. From a room's pause menu it is laid over the room
## instead, see [member overlay], so the match, and online the connection and everybody on it,
## carries on underneath rather than being thrown away and built again from the lobby's settings.

## Back, from a screen laid over a room: it has gone, and the room is the pause menu's again.
signal closed

## The Controls page's groups, GAME.md 8.5, by their headings, and the actions bound in each: how
## the first player drives and the bindings for driving, fighting and the game down the left, the
## controllers and the bindings for jokers and emotes down the right.
const DRIVING := "Driving"
const FIGHTING := "Fighting"
const GAME := "Game"
const CONTROLLERS := "Controllers"
const JOKERS := "Jokers"
const EMOTES := "Emotes"
const BINDINGS: Dictionary[String, Array] = {
	DRIVING:
	[
		InputActions.THROTTLE,
		InputActions.BRAKE,
		InputActions.STEER_LEFT,
		InputActions.STEER_RIGHT,
		InputActions.DRIVE_UP,
		InputActions.DRIVE_DOWN,
		InputActions.HANDBRAKE,
		InputActions.NITRO,
	],
	FIGHTING: [InputActions.FIRE, InputActions.USE_ITEM],
	GAME: [InputActions.PAUSE, InputActions.JOIN, InputActions.MUTE_MUSIC],
	JOKERS:
	[
		InputActions.JOKER_MENU,
		InputActions.JOKER_PREV,
		InputActions.JOKER_NEXT,
		InputActions.JOKER_DESTROY,
		InputActions.DETAILS,
	],
	EMOTES:
	[
		InputActions.EMOTE_1,
		InputActions.EMOTE_2,
		InputActions.EMOTE_3,
		InputActions.EMOTE_4,
		InputActions.EMOTE_WHEEL,
	],
}
## What each action is called down the left of its sockets, to a screen reader and while its new
## key is awaited: in sentence case as every other row of the settings is, and for the jokers'
## by what they do.
const ACTION_WORDS: Dictionary[StringName, String] = {
	InputActions.THROTTLE: "Throttle",
	InputActions.BRAKE: "Brake",
	InputActions.STEER_LEFT: "Steer left",
	InputActions.STEER_RIGHT: "Steer right",
	InputActions.DRIVE_UP: "Drive up",
	InputActions.DRIVE_DOWN: "Drive down",
	InputActions.HANDBRAKE: "Handbrake",
	InputActions.NITRO: "Nitro",
	InputActions.FIRE: "Fire",
	InputActions.USE_ITEM: "Use item",
	InputActions.PAUSE: "Pause",
	InputActions.JOIN: "Join",
	InputActions.MUTE_MUSIC: "Mute music",
	InputActions.JOKER_MENU: "Joker menu",
	InputActions.JOKER_PREV: "Previous joker",
	InputActions.JOKER_NEXT: "Next joker",
	InputActions.JOKER_DESTROY: "Destroy joker",
	InputActions.DETAILS: "Joker details",
	InputActions.EMOTE_1: "Emote 1",
	InputActions.EMOTE_2: "Emote 2",
	InputActions.EMOTE_3: "Emote 3",
	InputActions.EMOTE_4: "Emote 4",
	InputActions.EMOTE_WHEEL: "Emote wheel",
}
## The Audio page's groups, GAME.md 8.5, by their headings.
const VOLUME := "Volume"
const MUSIC := "Music"
const REBINDABLE: Array[StringName] = [
	InputActions.THROTTLE,
	InputActions.BRAKE,
	InputActions.STEER_LEFT,
	InputActions.STEER_RIGHT,
	InputActions.DRIVE_UP,
	InputActions.DRIVE_DOWN,
	InputActions.FIRE,
	InputActions.HANDBRAKE,
	InputActions.NITRO,
	InputActions.USE_ITEM,
	InputActions.JOKER_MENU,
	InputActions.JOKER_PREV,
	InputActions.JOKER_NEXT,
	InputActions.JOKER_DESTROY,
	InputActions.DETAILS,
	InputActions.EMOTE_1,
	InputActions.EMOTE_2,
	InputActions.EMOTE_3,
	InputActions.EMOTE_4,
	InputActions.EMOTE_WHEEL,
	InputActions.PAUSE,
	InputActions.JOIN,
	InputActions.MUTE_MUSIC,
]
## How the bindings themselves are drawn in the two sockets of a row, GAME.md 8.3 and 8.1a: the
## size their key caps are drawn at, their ink, and how big a socket is, tall enough for a key cap
## with the socket's own room above and below it.
const BINDING_SIZE := 18
const BINDING_INK := Color(0.90, 0.90, 0.94)
const BINDING_CELL := Vector2(270.0, 46.0)
## How wide the action's name is down the left of its sockets, and the room between the three: the
## settings' own row, so the sockets stand under the other rows' controls, and two of them a column
## of half a 1080p page, see [SettingsColumns].
const BINDING_NAME := 260.0
const BINDING_ROOM := 24
## The room between the two ways to drive and Help me choose.
const DRIVING_ROOM := 8
## What a socket says while it listens for a new key or button.
## The heads of the bindings' columns, and what a socket with nothing bound in it says.
const BINDING_HEADS: Array[String] = ["Action", "Keyboard and mouse", "Gamepad"]
const NOT_BOUND := "Not bound"
const LISTENING_KEY := "Press a key"
const LISTENING_PAD := "Press a button"
## The question Reset bindings to defaults asks first, as what was bound cannot come back: its words
## and its two answers.
const RESET_SURE := "Reset all bindings?"
const RESET_LINE := "Every key and button goes back to the game's own. The ones you set are lost."
const RESET_YES := "Reset"
const RESET_NO := "Cancel"
## How the page keys that step through the tabs are drawn beside them, GAME.md 8.5, see
## [PageBinds]: on a pad the tab bar is otherwise a long way round by focus.
const TAB_HINT_INK := Color(0.60, 0.60, 0.63)
const TAB_HINT_SIZE := 18
## The room round the screen, at its sides and at its top and foot, and how wide Back is at the top
## right, GAME.md 8.5.
const MARGIN := Vector2(48.0, 28.0)
const BACK_WIDE := 220.0
## The page of the seats at this screen, GAME.md 8.5, and what it is for, said at its top.
const SEATS := "Seats"
const PLAYERS_LINE := "What each seat at this screen is called, and how it drives."
## Simple driving's Auto throttle switch on a seat, GAME.md 4.2, and what it says to the mouse.
const AUTO := "Auto throttle"
const AUTO_TIP := (
	"Simple driving works the gas and brake for you. Off, the triggers or the touch screen's own"
	+ " gas and brake do, and the stick only steers. The keyboard always works them for you."
)
## What a seat's row says beside it while another profile sits in it, GAME.md 3.8.
const LINKED_TO := "Linked to %s"
## How big a color is drawn in a seat's row.
const SWATCH := 30.0
## What a screen reader is told of the swatch ringed in gold, the seat's favorite color.
const FAVORITE := "Favorite"
## Room kept round whatever has the cursor as a page scrolls to it, for the cursor's mark, which
## stands out past it, see [FocusMark].
const FOCUS_ROOM := 16

## The page the next settings screen opens on, by its name, or the first.
static var opening_on := ""

var tabs: TabContainer
## Back, at the top right of the head.
var back: Button
## The row of tabs over the pages, a bar of its own so the page keys can stand beside it.
var tab_bar: TabBar
## The page keys that turn the pages, Q and E or a pad's shoulders, see [PageBinds].
var tab_hint: PageBinds
var status: Label
## Laid over the room it was opened from rather than a scene of its own. Back closes it instead of
## changing scene.
var overlay := false

var _settings: Settings
var _listening_action := &""
var _listening_keyboard := true
var _binding_labels: Dictionary[StringName, Array] = {}
## How the first seat drives, on the Controls tab, and the small switch after each seat's name on
## the Seats tab: the first seat's is on both, so each says so when the other changes it.
var _first_driving: DrivePicker
var _seat_driving: Array[Callable] = []
## Each seat's row of colors on the Seats tab, drawn again in the palette the Accessibility tab
## has just chosen, see [method _color_choice].
var _seat_colors: Array[Callable] = []


func _ready() -> void:
	_settings = Game.settings
	MenuTheme.background(self)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, int(MARGIN.x))
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, int(MARGIN.y))
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	back = _head(column)
	var pages := VBoxContainer.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.add_theme_constant_override("separation", 0)
	column.add_child(pages)
	tabs = TabContainer.new()
	tabs.name = "Pages"
	tabs.tabs_visible = false
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# In the order GAME.md 8.5 has them, the license's named by the story's stage.
	tabs.add_child(LicenseTab.make(_settings, overlay))
	tabs.set_tab_title(0, LicenseTab.tab_word(Story.stage_here()))
	tabs.add_child(_players_tab())
	tabs.add_child(_controls_tab())
	tabs.add_child(_audio_tab())
	tabs.add_child(VideoTab.make(_settings))
	var access := AccessibilityTab.make(_settings)
	access.palette_chosen.connect(
		func() -> void:
			for shown: Callable in _seat_colors:
				shown.call()
	)
	access.aim_guide_reset.connect(func() -> void: status.text = "Aim guide reset")
	tabs.add_child(access)
	tabs.add_child(StatsTab.make(_settings))
	tabs.add_child(ProfilesTab.make(_settings, not overlay, _on_profile_switched))
	tabs.add_child(AboutTab.new())
	# Where the story is, and buttons to move it, for trying it out: debug builds alone.
	if OS.is_debug_build():
		tabs.add_child(StoryDebugTab.make(_settings))
	# The engine looks for the next control only in the part of a scroll that shows, unless the
	# scroll follows the cursor: in one column, under a big UI scale, down from the foot of Driving
	# found nothing, Fighting's heading pushing its first row out of sight. The License page keeps
	# its own way, round the license's mark.
	for page: Node in tabs.get_children():
		if page is ScrollContainer and not page is LicenseTab:
			(page as ScrollContainer).follow_focus = true
	if not opening_on.is_empty():
		var page := tabs.get_node_or_null(NodePath(opening_on))
		if page != null:
			tabs.current_tab = page.get_index()
		opening_on = ""
	pages.add_child(_tabs_row())
	pages.add_child(tabs)
	get_viewport().gui_focus_changed.connect(_keep_in_view)
	tabs.tab_changed.connect(func(_tab: int) -> void: _aim_down())
	_aim_down()
	# The cursor on the page rather than on Back, GAME.md 8.5: Back only for a page with nothing
	# for it, or with a box to type in first, which would take the keys, or put a phone's keyboard
	# up.
	var first := _first_focusable(tabs.get_current_tab_control())
	(back if first == null or first is LineEdit else first).grab_focus()


## The page in view scrolled to [param control] as it takes the cursor, its mark and all: the cursor
## walked down a page past its foot, onto the last button of Debug, say, went out of sight. The
## License page does this itself, round the license's mark, see [LicenseTab].
func _keep_in_view(control: Control) -> void:
	var page := tabs.get_current_tab_control() as ScrollContainer
	if control == null or page == null or page is LicenseTab or not page.is_ancestor_of(control):
		return
	scroll_to(page, control, FOCUS_ROOM)


## [param page] scrolled as little as it takes to show [param control] with [param room] round it,
## as far as it goes either way.
static func scroll_to(page: ScrollContainer, control: Control, room: float) -> void:
	var view := page.get_global_rect()
	var wanted := control.get_global_rect().grow(room)
	if wanted.position.y < view.position.y:
		page.scroll_vertical -= ceili(view.position.y - wanted.position.y)
	elif wanted.end.y > view.end.y:
		page.scroll_vertical += ceili(wanted.end.y - view.end.y)
	if wanted.position.x < view.position.x:
		page.scroll_horizontal -= ceili(view.position.x - wanted.position.x)
	elif wanted.end.x > view.end.x:
		page.scroll_horizontal += ceili(wanted.end.x - view.end.x)


## The head of the screen, GAME.md 8.5: the title at the left, what was last done beside it, and
## Back at the top right, which leaves the whole of the foot to the page. Returns Back.
func _head(column: VBoxContainer) -> Button:
	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", 24)
	column.add_child(head)
	var title := MenuTheme.title("Settings", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.add_child(title)
	status = Label.new()
	status.name = "Status"
	Type.text(status, Type.LABEL, HouseTheme.QUIET)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.clip_text = true
	head.add_child(status)
	var button := MenuTheme.button("Back", 28)
	button.name = "Back"
	button.custom_minimum_size.x = BACK_WIDE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_back)
	head.add_child(button)
	return button


## The row of tabs, a bar of its own over the pages and kept with them, and right after the tabs
## the page keys that turn them, as the loyalty program and the catalog have theirs, GAME.md 8.5.
func _tabs_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "TabsRow"
	row.add_theme_constant_override("separation", 16)
	tab_bar = TabBar.new()
	tab_bar.name = "Tabs"
	tab_bar.clip_tabs = true
	tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuTheme.tabs(tab_bar)
	for i: int in tabs.get_tab_count():
		tab_bar.add_tab(tabs.get_tab_title(i))
	tab_bar.current_tab = tabs.current_tab
	tab_bar.tab_changed.connect(
		func(tab: int) -> void:
			if tabs.current_tab != tab:
				tabs.current_tab = tab
	)
	tabs.tab_changed.connect(
		func(tab: int) -> void:
			if tab_bar.current_tab != tab:
				tab_bar.current_tab = tab
	)
	row.add_child(tab_bar)
	tab_hint = PageBinds.new()
	tab_hint.name = "TabHint"
	row.add_child(tab_hint)
	DialogBinds.beside_tabs(row, tab_bar, tab_hint.name)
	return row


## Whether a gamepad is plugged in, for the shoulder buttons to be drawn: one the engine knows for
## a gamepad, which a keyboard that says it is a joystick as well, as some do, is not, or one of
## Steam Input's.
static func pad_plugged_in() -> bool:
	for pad: int in Input.get_connected_joypads():
		if Input.is_joy_known(pad):
			return true
	return not DeviceInput.steam_pads.is_empty()


## Another profile is playing now, or one was made or thrown away: the settings come up again for
## it, every page reading the profile that is playing, on the Profiles page it was done on.
func _on_profile_switched(_id: String) -> void:
	_settings.save_to_disk()
	# Up over a room, a page of their own would leave the room stopped under it for good.
	if overlay:
		return
	opening_on = ProfilesTab.TITLE
	Game.go_to_settings(Game.settings_return)


## The page keys turn the pages, Q and E or a pad's shoulders, and B on a pad, or Escape, is the
## Back button, GAME.md 4.2. While a rebind is listening each is a binding like any other button,
## see [method _input].
func _unhandled_input(event: InputEvent) -> void:
	if _listening_action != &"":
		return
	# Kept before acting: Back over a room hands the screen back to the pause menu, which takes
	# it out of the tree, and a node out of the tree has no viewport to tell.
	var viewport := get_viewport()
	var step := 0
	if event.is_action_pressed(InputActions.MENU_PAGE_PREV):
		step = -1
	elif event.is_action_pressed(InputActions.MENU_PAGE_NEXT):
		step = 1
	if step != 0:
		switch_tab(step)
		viewport.set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel"):
		MenuTheme.back_sound()
		_back()
		if viewport != null:
			viewport.set_input_as_handled()


## A rebind listening takes the next press, whatever it is on. Heard before the buttons are, rather
## than after: a mouse button pressed over this screen is a click on it, which the screen's own
## controls took, so a mouse button could never be bound.
func _input(event: InputEvent) -> void:
	if _listening_action == &"":
		return
	var key := event as InputEventKey
	if key != null and key.pressed and key.physical_keycode == KEY_ESCAPE:
		_stop_listening("Rebind canceled")
		get_viewport().set_input_as_handled()
		return
	if not _is_bindable_press(event):
		return
	var descriptor := InputActions.descriptor_from_event(event)
	if (
		descriptor.is_empty()
		or InputActions.is_keyboard_descriptor(descriptor) != _listening_keyboard
	):
		return
	InputActions.rebind(_listening_action, descriptor)
	_settings.remember_binding(_listening_action)
	_refresh_bindings()
	_stop_listening("Bound %s" % event.as_text())
	get_viewport().set_input_as_handled()


## Steps [param step] tabs on, wrapping round at the ends. Focus left behind in the tab being
## left goes to the first thing in the new one, or it would be on a control nobody can see; to the
## tabs for a page with nothing to take it, Statistics say, so the cursor is somewhere and the right
## stick scrolls the page under them, see [StickScroll].
func switch_tab(step: int) -> void:
	tabs.current_tab = posmod(tabs.current_tab + step, tabs.get_tab_count())
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and focus.is_visible_in_tree():
		return
	var first := _first_focusable(tabs.get_current_tab_control())
	(first if first != null else tab_bar as Control).grab_focus()


## Down from the head, Back or the tabs, goes to the first thing on the page rather than to
## whatever is nearest under it: on the License page the license, not Kit's folder beside it.
func _aim_down() -> void:
	var first := _first_focusable(tabs.get_current_tab_control())
	for head: Control in [back, tab_bar]:
		head.focus_neighbor_bottom = head.get_path_to(first) if first != null else NodePath()


static func _first_focusable(node: Node) -> Control:
	var control := node as Control
	if control != null and control.focus_mode != Control.FOCUS_NONE and control.visible:
		return control
	for child: Node in node.get_children():
		var found := _first_focusable(child)
		if found != null:
			return found
	return null


func _is_bindable_press(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null:
		return key.pressed and not key.echo
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return mouse.pressed
	var button := event as InputEventJoypadButton
	if button != null:
		return button.pressed
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return absf(motion.axis_value) > 0.6
	return false


## The Controls page, GAME.md 8.5, in groups under headings as the Video page has, see
## [SettingsColumns]: the controllers, how the first player drives and the bindings for driving and
## fighting down the left; the bindings for the game, jokers and emotes down the right.
func _controls_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "Controls"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var groups := SettingsColumns.new()
	groups.name = "Groups"
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(groups)
	# The controllers first, Show controls and Reset at the top of the page however it stands.
	var column := SettingsColumns.group(CONTROLLERS)
	groups.add_child(column)
	# The pad drawn whole with what each button does, GAME.md 8.3b.
	column.add_child(PadLeaflet.row(self))
	# Steam Input, GAME.md 10.8, in a game with Steam on.
	SteamInputRow.add_to(column, _settings)
	var deadzone := HSlider.new()
	deadzone.min_value = 0.05
	deadzone.max_value = 0.5
	deadzone.step = 0.01
	deadzone.value = _settings.stick_deadzone
	deadzone.custom_minimum_size = Vector2(300.0, 0.0)
	deadzone.value_changed.connect(
		func(value: float) -> void:
			_settings.stick_deadzone = value
			_settings.apply_input()
	)
	column.add_child(MenuTheme.row("Stick dead zone", deadzone))
	var reset := MenuTheme.button("Reset bindings to defaults", 22)
	reset.name = "ResetBindings"
	var answer := func(yes: bool) -> void:
		if yes:
			_settings.reset_bindings()
			_refresh_bindings()
			status.text = "Bindings reset"
	reset.pressed.connect(
		func() -> void:
			var question := ConfirmPane.over_screen(reset, "ResetQuestion", answer)
			question.ask(RESET_SURE, RESET_LINE, RESET_YES, RESET_NO)
	)
	column.add_child(MenuTheme.row("", reset))
	column = SettingsColumns.group(DRIVING)
	groups.add_child(column)
	# How the first player drives, GAME.md 4.2. Everybody else says in the lobby, or in the pause
	# menu over their own corner.
	var driving := DrivePicker.make(_settings.drive_mode(0))
	_first_driving = driving
	driving.chosen.connect(
		func(mode: String) -> void:
			_settings.drive_modes[0] = mode
			_show_seat_driving()
	)
	# And the question the first Play asked, again, for the two side by side with what each is.
	var again := MenuTheme.button("Help me choose", Type.BODY)
	again.custom_minimum_size = Vector2(0.0, 52.0)
	var answered := func() -> void:
		driving.mode = _settings.drive_mode(0)
		_show_seat_driving()
		again.grab_focus()
	again.pressed.connect(func() -> void: DriveChoice.ask(self, answered, 0))
	driving.add_child(again)
	# A little closer together than a picker's own, so the three fit half a 1080p page.
	driving.add_theme_constant_override("separation", DRIVING_ROOM)
	column.add_child(MenuTheme.row("Driving", driving))
	# Its Auto throttle, as on its card on the Seats tab, while it drives the simple way.
	var auto := _auto_switch(0)
	auto.name = "AutoThrottle"
	var auto_row := MenuTheme.row(AUTO, auto)
	column.add_child(auto_row)
	var simple := func() -> void:
		auto_row.visible = _settings.drive_mode(0) == Settings.DRIVE_SIMPLE
	simple.call()
	_seat_driving.append(simple)
	# How a touch screen drives, GAME.md 4.2, first where it is the controls in the player's hand.
	if TouchInput.enabled:
		var touch := DrivePicker.make(_settings.touch_layout, Settings.TOUCH_LAYOUTS)
		touch.chosen.connect(func(layout: String) -> void: _settings.touch_layout = layout)
		column.add_child(MenuTheme.row("Touch driving", touch))
	_add_bindings(column, BINDINGS[DRIVING])
	column = SettingsColumns.group(FIGHTING)
	groups.add_child(column)
	_add_bindings(column, BINDINGS[FIGHTING])
	groups.split = groups.get_child_count()
	for named: String in [GAME, JOKERS, EMOTES]:
		column = SettingsColumns.group(named)
		groups.add_child(column)
		_add_bindings(column, BINDINGS[named])
	return scroll


## The keyboard's and the pad's columns named over their sockets, then a row for each of
## [param actions] into [param column]: in every group of them, so each reads on its own.
func _add_bindings(column: VBoxContainer, actions: Array) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", BINDING_ROOM)
	var under_names := Control.new()
	under_names.custom_minimum_size = Vector2(BINDING_NAME, 0.0)
	header.add_child(under_names)
	for text: String in BINDING_HEADS.slice(1):
		var label := Label.new()
		label.text = SteamInputRow.head(text)
		label.uppercase = true
		label.custom_minimum_size = Vector2(BINDING_CELL.x, 0.0)
		# Over the middle of its sockets, as the keys in them are.
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Type.strong(label, Type.SMALL, HouseTheme.QUIET)
		header.add_child(label)
	column.add_child(header)
	for action: StringName in actions:
		column.add_child(_binding_row(action))


func _binding_row(action: StringName) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", BINDING_ROOM)
	var name := Label.new()
	name.text = _action_words(action)
	name.custom_minimum_size = Vector2(BINDING_NAME, 0.0)
	Type.text(name, Type.BODY, Color(0.86, 0.86, 0.9))
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(name)
	var buttons: Array = []
	for keyboard: bool in [true, false]:
		var button := Button.new()
		button.theme_type_variation = HouseTheme.SOCKET
		button.custom_minimum_size = BINDING_CELL
		Type.set_font(button, Type.STRONG, Type.BODY)
		button.pressed.connect(_start_listening.bind(action, keyboard, button))
		line.add_child(button)
		buttons.append(button)
	_binding_labels[action] = buttons
	_refresh_binding(action)
	return line


func _start_listening(action: StringName, keyboard: bool, button: Button) -> void:
	if not keyboard and SteamInputRow.rebound_in_steam(status):
		return
	_listening_action = action
	_listening_keyboard = keyboard
	_clear(button)
	button.text = LISTENING_KEY if keyboard else LISTENING_PAD
	status.text = (
		"Press a %s input for %s, Escape cancels"
		% ["keyboard or mouse" if keyboard else "gamepad", _action_words(action)]
	)


func _stop_listening(message: String) -> void:
	_listening_action = &""
	_refresh_bindings()
	status.text = message


func _refresh_bindings() -> void:
	for action: StringName in _binding_labels:
		_refresh_binding(action)


## What an action is bound to, drawn as the keys and buttons themselves rather than written out,
## GAME.md 8.3. This is the one screen where every binding of an action is shown rather than the
## first, since it is the screen for changing them.
func _refresh_binding(action: StringName) -> void:
	var buttons: Array = _binding_labels[action]
	for i: int in 2:
		var button := buttons[i] as Button
		_clear(button)
		button.text = ""
		var row := _bound_glyphs(action, i == 0)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(row)
		# Its keys are pictures: a screen reader is told the action, the column and what is bound.
		var bound := SteamInputRow.bound_text(action, i == 0)
		var named := ScreenReader.line([_action_words(action), BINDING_HEADS[i + 1]])
		ScreenReader.name(button, named, NOT_BOUND if bound == "-" else bound)


## What the row of [param action] is called, down the left of its sockets.
static func _action_words(action: StringName) -> String:
	return ACTION_WORDS.get(action, String(action).replace("_", " ").capitalize())


static func _bound_glyphs(action: StringName, keyboard: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	if not keyboard and SteamInputRow.pad() >= 0:
		SteamInputRow.add_glyph(row, action, BINDING_INK, BINDING_SIZE)
	elif InputMap.has_action(action):
		for event: InputEvent in InputMap.action_get_events(action):
			var descriptor := InputActions.descriptor_from_event(event)
			if descriptor.is_empty() or InputActions.is_keyboard_descriptor(descriptor) != keyboard:
				continue
			var glyph := InputGlyph.of_event(event, BINDING_INK, BINDING_SIZE)
			# At its own height in the middle of the socket rather than stretched to fill it.
			glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(glyph)
	if row.get_child_count() == 0:
		var empty := Label.new()
		empty.text = NOT_BOUND
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Type.text(empty, Type.LABEL, HouseTheme.QUIET)
		empty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(empty)
	return row


static func _clear(button: Button) -> void:
	for child: Node in button.get_children():
		button.remove_child(child)
		child.queue_free()


## What each seat at this machine is called, GAME.md 3.8, a box per seat. Anybody who leaves theirs
## empty is handed a name off the funny list when they sit down. Online the first seat's name is
## the one this machine gives, and the online screen shows the same box. After each box, a small
## switch for how that seat drives, GAME.md 4.2. Down the middle of the page, as the License,
## Statistics and About pages are.
func _players_tab() -> Control:
	var column := VBoxContainer.new()
	column.name = SEATS
	column.add_theme_constant_override("separation", 8)
	page_head(column, SEATS, PLAYERS_LINE)
	for seat: int in _settings.player_names.size():
		column.add_child(_seat_card(seat))
	return column


## [param seat] as a seat card, see [SeatCard], as the profiles and a hosted game's players are:
## its chip in its color with its number on it, the box its name is typed into over the profile it
## is linked to, its colors, and how it drives.
func _seat_card(seat: int) -> SeatCard:
	var linked := _settings.seat_profile(seat)
	var says := LINKED_TO % linked.display_name() if linked != null else ""
	var card := SeatCard.make("", _chip_color(seat), str(seat + 1), says)
	card.name = "Seat%d" % seat
	card.custom_minimum_size.x = SeatCard.WIDE
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.plate.visible = false
	if linked != null:
		card.line.name = "Linked%d" % seat
	# A seat another profile sits in, GAME.md 3.8, is that profile's name and way of driving.
	var field := MenuTheme.field(
		_settings.seat_name(seat), PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH
	)
	field.custom_minimum_size = Vector2(300.0, 40.0)
	ScreenReader.name(field, KartOwner.SEAT % (seat + 1), says)
	field.set_meta(SteamKeyboard.IN_DIALOG, "%s's name" % (KartOwner.SEAT % (seat + 1)))
	field.text_changed.connect(
		func(text: String) -> void: _settings.set_seat_name(seat, PlayerNames.clean(text))
	)
	card.name_with(field)
	card.actions.add_child(_color_choice(seat, card))
	card.actions.add_child(_drive_switch(seat))
	card.actions.add_child(_auto_throttle(seat))
	return card


## Whether [param seat]'s simple driving works the pedals by itself, GAME.md 4.2: a switch by its
## way of driving, there while it drives the simple way, its words saying a keyboard's always does.
func _auto_throttle(seat: int) -> CheckButton:
	var auto := _auto_switch(seat)
	auto.name = "Auto%d" % seat
	auto.text = AUTO
	auto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Its room kept on every card whether it is there or not, so the cards stand the same width.
	var shown := func() -> void:
		var simple := _settings.drive_mode(seat) == Settings.DRIVE_SIMPLE
		auto.modulate.a = 1.0 if simple else 0.0
		auto.disabled = not simple
		auto.focus_mode = Control.FOCUS_ALL if simple else Control.FOCUS_NONE
		auto.mouse_filter = Control.MOUSE_FILTER_STOP if simple else Control.MOUSE_FILTER_IGNORE
	shown.call()
	_seat_driving.append(shown)
	return auto


## [param seat]'s Auto throttle switch, the first seat's on the Controls tab as well as on its card:
## each says so when the other is switched.
func _auto_switch(seat: int) -> CheckButton:
	var auto := MenuTheme.toggle(_settings.auto_throttle(seat))
	auto.tooltip_text = AUTO_TIP
	auto.toggled.connect(
		func(on: bool) -> void:
			_settings.set_auto_throttle(seat, on)
			_show_seat_driving()
	)
	_seat_driving.append(func() -> void: auto.set_pressed_no_signal(_settings.auto_throttle(seat)))
	return auto


## The color [param seat]'s chip is in: its favorite, or the one its place gives it.
func _chip_color(seat: int) -> Color:
	var chosen := _settings.seat_color(seat)
	return Palette.player_color(chosen if chosen >= 0 else seat)


## The line at the top of a page that says what it is for, GAME.md 8.5: short, gray and to the
## left, where the page's rows start.
static func page_line(text: String) -> Label:
	var line := Label.new()
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Type.text(line, Type.LABEL, Color(0.72, 0.72, 0.78))
	return line


## A page's heading, [param title], over [param line], as the License and Statistics pages are
## headed, and a little air under them before the page's rows.
static func page_head(column: VBoxContainer, title: String, line: String) -> void:
	var heading := MenuTheme.title(title, Type.HEADING)
	heading.name = "Heading"
	column.add_child(heading)
	column.add_child(MenuTheme.subtitle(line, Type.LABEL))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap)


## [method page_line] down the middle of a page, for a page whose rows are.
static func centered_line(text: String) -> Label:
	var line := page_line(text)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return line


## [param seat]'s favorite color, GAME.md 3.8, chosen from all of them in a row, each a chip in the
## palette worn, drawn again when the palette changes, the one chosen ringed in gold, and the seat's
## own chip on [param card] in it: the color the seat is given wherever it is free, the kart on the
## license in it too. A single swatch that moved on round them was a guess at what came next.
func _color_choice(seat: int, card: SeatCard) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Colors%d" % seat
	row.add_theme_constant_override("separation", 4)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var swatches: Array[Button] = []
	for color: int in Palette.PLAYER_COLORS.size():
		var swatch := Button.new()
		swatch.name = "Color%d" % color
		swatch.custom_minimum_size = Vector2(SWATCH, SWATCH)
		swatch.tooltip_text = Palette.color_name(color)
		swatch.focus_mode = Control.FOCUS_ALL
		var empty := StyleBoxEmpty.new()
		for state: String in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			swatch.add_theme_stylebox_override(state, empty)
		swatch.draw.connect(_draw_swatch.bind(swatch))
		swatch.pressed.connect(
			func() -> void:
				_settings.set_seat_color(seat, color)
				_ring_chosen(swatches, color)
				card.set_chip(_chip_color(seat), str(seat + 1))
		)
		row.add_child(swatch)
		swatches.append(swatch)
	var shown := func() -> void:
		_ring_chosen(swatches, _settings.seat_color(seat))
		card.set_chip(_chip_color(seat), str(seat + 1))
	shown.call()
	_seat_colors.append(shown)
	return row


## Each of [param swatches] in its own color, [param chosen] ringed in gold, see
## [method _draw_swatch].
static func _ring_chosen(swatches: Array[Button], chosen: int) -> void:
	for color: int in swatches.size():
		swatches[color].set_meta(&"fill", Palette.player_color(color))
		swatches[color].set_meta(&"chosen", color == chosen)
		swatches[color].accessibility_description = FAVORITE if color == chosen else ""
		swatches[color].queue_redraw()


## A swatch, a chip in its color, GAME.md 8.1a: the chosen one ringed in gold and standing a little
## bigger, and the one the cursor is on ringed in white.
static func _draw_swatch(swatch: Button) -> void:
	var fill: Color = swatch.get_meta(&"fill", Color.WHITE)
	var chosen: bool = swatch.get_meta(&"chosen", false)
	var middle := swatch.size * 0.5
	var radius := minf(swatch.size.x, swatch.size.y) * 0.5
	var lit := swatch.is_hovered() or swatch.has_focus()
	ChipArt.chip(
		swatch, middle, radius - (2.0 if chosen else 4.5), fill.lightened(0.1 if lit else 0.0)
	)
	if chosen:
		swatch.draw_arc(middle, radius - 1.0, 0.0, TAU, 32, HouseTheme.FOIL, 2.2, true)
	if swatch.has_focus():
		swatch.draw_arc(middle, radius - 0.5, 0.0, TAU, 32, Color.WHITE, 1.6, true)


## A small button with the way [param seat] drives on it, simple or advanced, that changes it to
## the other: the switch over their corner in the pause menu, without the words.
func _drive_switch(seat: int) -> Button:
	var toggle := MenuTheme.button("", Type.BODY)
	toggle.name = "Driving%d" % seat
	toggle.custom_minimum_size = Vector2(48.0, 44.0)
	var picture := DriveArt.picture(_settings.drive_mode(seat), Palette.CHIP_GOLD, 34.0)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: int in [SIDE_LEFT, SIDE_TOP]:
		picture.set_offset(side, 5.0)
	for side: int in [SIDE_RIGHT, SIDE_BOTTOM]:
		picture.set_offset(side, -5.0)
	toggle.add_child(picture)
	var shown := func() -> void:
		picture.mode = _settings.drive_mode(seat)
		toggle.tooltip_text = DriveSwitches.WORDS[picture.mode]
	shown.call()
	_seat_driving.append(shown)
	toggle.pressed.connect(
		func() -> void:
			var simple := _settings.drive_mode(seat) == Settings.DRIVE_SIMPLE
			_settings.set_drive_mode(
				seat, Settings.DRIVE_ADVANCED if simple else Settings.DRIVE_SIMPLE
			)
			# Its Auto throttle switch with it, there only in simple driving.
			_show_seat_driving()
			if seat == 0 and _first_driving != null:
				_first_driving.mode = _settings.drive_mode(0)
	)
	return toggle


func _show_seat_driving() -> void:
	for shown: Callable in _seat_driving:
		shown.call()


## The Audio page, GAME.md 8.5, in two groups under headings as the Video page has, see
## [SettingsColumns]: how loud each part of the sound is, and how the music behaves.
func _audio_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "Audio"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var groups := SettingsColumns.new()
	groups.name = "Groups"
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(groups)
	var column := SettingsColumns.group(VOLUME)
	groups.add_child(column)
	var master := func(v: float) -> void: _settings.master_volume = v
	column.add_child(MenuTheme.row("Master", _volume_slider(_settings.master_volume, master)))
	var music := func(v: float) -> void: _settings.music_volume = v
	column.add_child(MenuTheme.row("Music", _volume_slider(_settings.music_volume, music)))
	var effects := func(v: float) -> void: _settings.sfx_volume = v
	column.add_child(MenuTheme.row("Effects", _volume_slider(_settings.sfx_volume, effects)))
	var karts := func(v: float) -> void: _settings.kart_volume = v
	column.add_child(MenuTheme.row("Karts", _volume_slider(_settings.kart_volume, karts)))
	groups.split = groups.get_child_count()
	column = SettingsColumns.group(MUSIC)
	groups.add_child(column)
	# How much louder the music gets as the room heats up, on top of the level above, GAME.md 8.5.
	var swell := SwellSlider.make(_settings.music_swell)
	swell.name = "IntenseMusic"
	swell.changed.connect(func(v: float) -> void: _settings.music_swell = v)
	column.add_child(MenuTheme.row("Intense music", swell))
	column.add_child(MenuTheme.row("Music muted", _check(_settings.music_muted, _set_music_muted)))
	var muffle := func(on: bool) -> void: _settings.muffle_on_death = on
	column.add_child(
		MenuTheme.row("Muffle music on death", _check(_settings.muffle_on_death, muffle))
	)
	return scroll


func _set_music_muted(on: bool) -> void:
	_settings.music_muted = on
	_settings.apply_audio()


func _volume_slider(value: float, setter: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(320.0, 0.0)
	slider.value_changed.connect(
		func(v: float) -> void:
			setter.call(v)
			_settings.apply_audio()
	)
	return slider


func _check(value: bool, setter: Callable) -> CheckButton:
	var box := MenuTheme.toggle(value)
	box.toggled.connect(func(on: bool) -> void: setter.call(on))
	return box


func _back() -> void:
	_settings.save_to_disk()
	if overlay:
		closed.emit()
		queue_free()
		return
	# Back at the title from here, nothing is put up there but the invitation, see [TitleCards].
	TitleCards.from_the_menus = Game.settings_return == Game.TITLE_SCENE
	get_tree().change_scene_to_file(Game.settings_return)


## A room that goes while its settings are open, online when the host moves everybody on, takes
## them with it. What was changed has already been applied, and is kept.
func _exit_tree() -> void:
	if overlay and not is_queued_for_deletion():
		_settings.save_to_disk()
