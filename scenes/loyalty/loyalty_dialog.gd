class_name LoyaltyDialog
extends CanvasLayer
## The loyalty program, GAME.md 8.9: a large dialog over whatever screen opens it, the title's
## Clubhouse or a room's pause menu, on a layer of its own as the catalog of 8.8 is, with its shade
## and its pane; Back, B, Escape or a click on the shade beside the pane puts it away, the cursor
## back where it was.
##
## The pane holds the program's map, [LoyaltyMapView], its cursor driving the roads,
## [LoyaltyCursor], and beside it the house's pane describing the landmark under the cursor,
## [LoyaltyPane]. A switch over the pane, List, which the details key also flips as in the catalog,
## puts every open bet in a list in the map's place, [LoyaltyList]. Its title is the program's name
## by the story's stage, STORY.md 6.6b, with the line under it in the House's capitals. Read only,
## but for the NEW tags, which go as the cursor comes to them and are kept gone as it is put away.

## Put away, the cursor back where it was.
signal put_away

## Over a room's pause menu, under the notices and the loading screen, as the catalog is.
const LAYER := CatalogDialog.LAYER
## The layer it is held on, see [member held]: under the screen it opens over.
const HELD_LAYER := -1
const SHADE := CatalogDialog.SHADE
## Less room than this from top to bottom and the head is the settings', Back in it, and the dialog
## fills the screen, as the catalog's; less than this across the map's room and it opens on the
## list.
const SHORT := CatalogDialog.SHORT
const NARROW := 700.0
## The side column's share of a narrow screen's width, and the least it is, the map having the
## rest; never wider than the pane is on a wide one.
const SIDE_SHARE := 0.3
const SIDE_LEAST := 300.0
## The switch over the pane, and the bind that flips it.
const LIST := "List"
const LIST_ACTION := InputActions.DETAILS
## The binds that zoom the map, in the row over it: a pad's triggers, smoothly for as long and as
## fast as they are pulled, and on keys minus and plus, a notch a press.
const ZOOM := "Zoom"
## What the arrows or the stick do on the map, in the same row.
const SELECT := "Select landmark"
## The map's two sheets, see [LoyaltyMapLayout.Sheet]: their tabs over the map once Kit's is on
## it, and the bind that turns from one to the other; on a pad the shoulders step through them, as
## through the settings' tabs, GAME.md 8.5, the left to the House's and the right to Kit's.
const HOUSE_SHEET := "The House's map"
const KIT_SHEET := "Kit's map"
const SHEET_ACTION := InputActions.JOKER_MENU
const SHEET_BACK := SettingsScreen.TAB_BACK
const SHEET_ON := SettingsScreen.TAB_ON
const ZOOM_OUT := JOY_AXIS_TRIGGER_LEFT
const ZOOM_IN := JOY_AXIS_TRIGGER_RIGHT
## A pad on the map: how fast a trigger pulled all the way zooms it, in doublings a second, and how
## fast the right stick all the way over moves it, in pixels a second; and how little of a pull or
## a push is resting.
const ZOOM_RATE := 2.0
const PAN_RATE := 1800.0
const TRIGGER_REST := 0.04
const STICK_REST := 0.2
## The short word on what the program is, the first time the House's welcome opens it, GAME.md 8.9,
## and its one button.
const INTRO_LINE := (
	"Each landmark on this map holds an objective and a reward. Every match you play counts toward"
	+ " them. Win a landmark's objective to collect its reward and open the roads beyond it."
	+ " Select a landmark to read its objective, and pin it to track its progress while you play."
)
const INTRO_OK := "Got it"
## The bind that shows the program's card in full, drawn on the card's corner: the cursor never goes
## to the card, which would take it out of the map.
const CARD_ACTION := InputActions.USE_ITEM
const ZOOM_KEYS_OUT: Array[Key] = [KEY_MINUS, KEY_KP_SUBTRACT]
const ZOOM_KEYS_IN: Array[Key] = [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]
## Where every profile starts, GAME.md 8.9.
const START := &"slip_road"
const PANE_GAP := CatalogDialog.PANE_GAP
const PANE_AROUND := CatalogDialog.PANE_AROUND
## The room left and right of the pane in its column, less than over and under it so the map has
## the room; and how wide that column is at most, the pane's own width and that room.
const SIDE_AROUND := 6
## The room over the details in their column, for the coil binding the slip to go over its top
## edge in; and under what is at the column's foot, only as much as Back's shadow takes, so that
## Back stands about level with the map's foot.
const COIL_ROOM := 24
const FOOT_ROOM := 6
const SIDE_MOST := LoyaltyPane.WIDTH + 12.0 + SIDE_AROUND * 2.0
## The program's card in the map's corner, over the pane, a share of its own size; and the map
## unfolding as the welcome opens it, from folded in three to open, GAME.md 8.9.
const CARD_SCALE := 0.62
const UNFOLD := 0.6
const FOLDED := 0.34

## Whether the list is in the map's place, and where the cursor stood, kept for the run, so the
## program opens again as it was left.
static var listed := false
static var stood_at := &""

var map_view: LoyaltyMapView
var cursor: LoyaltyCursor
var list: LoyaltyList
var pane: LoyaltyPane
var list_switch: CheckButton
var back: Button
## The program's card, at the foot of the column under the pane.
var card_corner: Control
## The atlas cover the pane is dressed as, and over it the tape and the card's corners, see
## [AtlasCover].
var cover: AtlasCover
## Whether it opens unfolding, as the welcome opens it the first time.
var unfolding := false
## Whether it is held behind what opens it until [method reveal], as the welcome holds it behind
## its letter: laid out and drawn, its pictures made, so the card carried to it does not wait on
## that, but under the screen it opens over, unseen, taking no input.
var held := false
## The landmark it opens at on the map when asked from elsewhere, as the pause menu's pinned note
## asks, over where the cursor was left and an edition owed; none for those.
var start_at := &""
## The card shown in full while it is up, see [method show_card].
var card_view: LoyaltyCardView
## The short word on what the program is while it is up, see [method introduce].
var intro: Control
## The map's sheets' tabs, over its top left once Kit's is on it.
var sheet_tabs: TabBar

var _profile: Profile
var _root: Control
var _shade: ColorRect
var _around: MarginContainer
var _pane: PanelContainer
var _well: ListBox.Well
var _spare: AtlasCover.Spare
var _sheet_row: HBoxContainer
var _head: HBoxContainer
var _side: ScrollContainer
var _title: Label
var _line: Label
var _column: VBoxContainer
var _switches: HBoxContainer
var _hint_row: HBoxContainer
## The binds of the map's keys among them, which go where the head has no room for them.
var _how: Control
## The sheets' binds at the right end of their tabs, as the settings' are.
var _sheet_hint: HBoxContainer
## What had the cursor before the dialog came up, for it to go back to.
var _from: Control
## Whether a NEW tag has gone, to be kept as the dialog goes.
var _looked := false
var _closing := false
var _keyboard := true
var _pointer := false
var _opened := false
## The editions being chosen, over the map, while they are, see [LoyaltyEditions].
var _editions: LoyaltyEditions
## Where the cursor last stood on each sheet, to go back to as the map is turned to it.
var _stood_on: Dictionary[int, StringName] = {}
## The way each stick axis was last pushed over, -1, 1 or 0 in the middle, see [method _drive_by].
var _stick_ways: Dictionary[int, int] = {}


## The program over [param parent], for the profile playing, the cursor where it stood last, or
## on the map at [param at]; [param unfold] for the map unfolding as it opens, as the welcome opens
## it, and [param hold] for it held unseen until [method reveal], see [member held].
static func open(parent: Node, unfold := false, at := &"", hold := false) -> LoyaltyDialog:
	var dialog := LoyaltyDialog.new()
	dialog.name = "Loyalty"
	dialog.unfolding = unfold
	dialog.held = hold
	dialog.start_at = at
	if parent.is_inside_tree():
		dialog._from = parent.get_viewport().gui_get_focus_owner()
	parent.add_child(dialog)
	return dialog


## The program's name by the story's stage, STORY.md 6.6b, as [param profile]'s screens show it:
## the first stage's with its story off.
static func program_name(profile: Profile) -> String:
	return str(StoryLines.at(StoryLines.PROGRAM, _stage_of(profile)))


## The line under the program's name, in the House's capitals.
static func program_line(profile: Profile) -> String:
	var line := str(StoryLines.at(StoryLines.PROGRAM_LINE, _stage_of(profile)))
	return line.replace("{license}", Game.settings.license_number.to_upper())


## The atlas's name stamped in the foot of its cover, STORY.md 6.6b.
static func atlas_name(profile: Profile) -> String:
	var name_of := str(StoryLines.at(StoryLines.ATLAS, _stage_of(profile)))
	return name_of.replace("{license}", Game.settings.license_number.to_upper())


static func _stage_of(profile: Profile) -> int:
	if Story.override >= 0:
		return Story.stage_here()
	return Story.shown_of(profile)


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_profile = Game.settings.profile
	_keyboard = Game.last_input_keyboard
	_pointer = Game.last_input_pointer
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = SHADE
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.gui_input.connect(_on_shade_input)
	_root.add_child(_shade)
	_around = MarginContainer.new()
	_around.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_around.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_around)
	# The pane is the cover of the House's road atlas, GAME.md 8.9, see [AtlasCover].
	_pane = PanelContainer.new()
	_pane.add_theme_stylebox_override("panel", AtlasCover.inside())
	_pane.name = "Pane"
	_pane.mouse_filter = Control.MOUSE_FILTER_STOP
	_around.add_child(_pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_pane.add_child(column)
	_head = HBoxContainer.new()
	_head.name = "Head"
	_head.add_theme_constant_override("separation", 24)
	column.add_child(_head)
	_title = MenuTheme.title(program_name(_profile), Type.TITLE)
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_head.add_child(_title)
	# The line beside the title, in the middle of the row as the switch is, where it fits.
	_line = MenuTheme.subtitle(program_line(_profile), Type.LABEL)
	_line.name = "Line"
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_line.clip_text = true
	_head.add_child(_line)
	_head.add_child(_switch_row())
	column.add_child(_body())
	# Back at the foot of the column beside the map, under the card, so the map runs down to the
	# cover's foot; a ticket a little short of a menu's button, a finger's still.
	back = AtlasTicketStyle.ticket("Back", 200.0)
	back.name = "Back"
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(close)
	_column.add_child(back)
	var parts: Dictionary[StringName, Control] = {
		&"well": _well,
		&"tabs": _sheet_row,
		&"line": _line,
		&"switches": _switches,
		&"card": card_corner,
		&"back": back,
		&"spare": _spare,
		&"slip": pane,
	}
	cover = AtlasCover.dress(_pane, parts, atlas_name(_profile))
	var start := stood_at
	var at := Loyalty.map().landmark(start)
	var drawn := at != null and Loyalty.is_drawn(_profile, at)
	if not drawn and start != Loyalty.ROUNDABOUT:
		start = START
	# An edition owed for a lap: the roundabout, calling, wherever the cursor was left.
	if _profile.loyalty.owed > 0:
		start = Loyalty.ROUNDABOUT
	# Asked for one: on the map at it, the list left for the map.
	if start_at != &"":
		start = start_at
		listed = false
	map_view.stand_at(start)
	_describe(start)
	_root.resized.connect(_fit)
	_fit()
	_show_binds()
	Input.joy_connection_changed.connect(_on_pad_plugged)
	if held:
		layer = HELD_LAYER
		_root.modulate.a = 0.0
		return
	MenuTheme.deal(_pane)
	_open_as_left.call_deferred()


## Brought up from where it was held, see [member held]: on its own layer, dealt and opened as it
## would have been.
func reveal() -> void:
	if not held:
		return
	held = false
	layer = LAYER
	_root.modulate.a = 1.0
	MenuTheme.deal(_pane)
	_open_as_left()


func _exit_tree() -> void:
	_keep_looks()
	if Input.joy_connection_changed.is_connected(_on_pad_plugged):
		Input.joy_connection_changed.disconnect(_on_pad_plugged)


## Puts the dialog away, the cursor going back to whatever had it before.
func close() -> void:
	if _closing:
		return
	_closing = true
	cursor.finish()
	stood_at = cursor.at
	_keep_looks()
	var shades: Array[CanvasItem] = [_shade]
	MenuTheme.put_away(_pane, _gone, shades)


func is_closing() -> bool:
	return _closing


## Puts the list of open bets in the map's place, or the map back, see [member listed].
func set_listed(on: bool) -> void:
	listed = on
	_show_list(on)


## The map's well and the pane's column beside it.
func _body() -> HBoxContainer:
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", int(PANE_GAP))
	# The map's well, the tabs of its sheets on its top edge.
	var map_side := VBoxContainer.new()
	map_side.name = "MapSide"
	map_side.add_theme_constant_override("separation", 0)
	map_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(map_side)
	# In from the well's cut corner, so the tabs stand on its straight top edge.
	var sheet_in := MarginContainer.new()
	sheet_in.name = "SheetIn"
	sheet_in.add_theme_constant_override("margin_left", ListBox.INSET)
	map_side.add_child(sheet_in)
	var sheet_row := HBoxContainer.new()
	_sheet_row = sheet_row
	sheet_row.name = "SheetRow"
	sheet_row.add_theme_constant_override("separation", 14)
	sheet_in.add_child(sheet_row)
	sheet_tabs = _sheet_bar()
	sheet_row.add_child(sheet_tabs)
	_sheet_hint = HBoxContainer.new()
	_sheet_hint.name = "SheetHint"
	_sheet_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sheet_row.add_child(_sheet_hint)
	# The map right to the well's edge, nothing of it lost to a border.
	var well := ListBox.Well.new()
	_well = well
	well.name = "Well"
	well.flush = true
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_side.add_child(well)
	map_view = LoyaltyMapView.new()
	map_view.name = "Map"
	map_view.profile = _profile
	map_view.program = program_name(_profile)
	cursor = LoyaltyCursor.new()
	cursor.name = "Cursor"
	map_view.cursor = cursor
	map_view.add_child(cursor)
	map_view.picked.connect(_on_picked)
	map_view.chosen.connect(_describe)
	map_view.sheet_changed.connect(_on_sheet_changed)
	well.inside().add_child(map_view)
	# The list keeps the room round its rows that the map runs into.
	var list_room := MarginContainer.new()
	list_room.name = "ListRoom"
	list_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge: String in ["left", "right", "top", "bottom"]:
		list_room.add_theme_constant_override("margin_%s" % edge, ListBox.INSET)
	well.inside().add_child(list_room)
	list = LoyaltyList.new()
	list.name = "List"
	list.visible = false
	list.looked_at.connect(_describe)
	list.chosen.connect(_on_chosen)
	list_room.add_child(list)
	# The card and the pane scroll where they say more than the screen is tall, a phone's at a big
	# UI scale, rather than pushing the dialog off it; the room round them inside, so the pane's
	# shadow is not cut off.
	var side := ScrollContainer.new()
	_side = side
	side.name = "Side"
	side.custom_minimum_size.x = SIDE_MOST
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.follow_focus = true
	body.add_child(side)
	var around := MarginContainer.new()
	around.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	around.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right"]:
		around.add_theme_constant_override("margin_%s" % edge, SIDE_AROUND)
	around.add_theme_constant_override("margin_top", maxi(PANE_AROUND, COIL_ROOM))
	around.add_theme_constant_override("margin_bottom", FOOT_ROOM)
	side.add_child(around)
	var column := VBoxContainer.new()
	_column = column
	column.name = "Column"
	column.add_theme_constant_override("separation", 18)
	around.add_child(column)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pane = LoyaltyPane.new()
	pane.turns = true
	pane.name = "Landmark"
	pane.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pane.edition_asked.connect(choose_edition)
	pane.pin_asked.connect(toggle_pin)
	column.add_child(pane)
	# The profile's card, small, at the column's foot under the pane, as the welcome put it there,
	# in its pocket in the cover; the room between, which on a short screen has a pencil lying in it.
	_spare = AtlasCover.Spare.new()
	_spare.name = "Under"
	column.add_child(_spare)
	card_corner = LoyaltyCardView.corner(_profile, CARD_SCALE, show_card, false)
	var pocket := AtlasCover.Pocket.new()
	pocket.name = "Pocket"
	pocket.card = card_corner
	column.add_child(pocket)
	return body


## The map's sheets as index tabs on its top edge, as the settings' pages are on theirs, GAME.md
## 8.5: the House's map and Kit's, there once Kit's is on it.
func _sheet_bar() -> TabBar:
	var bar := TabBar.new()
	bar.name = "Sheets"
	bar.add_tab(HOUSE_SHEET)
	bar.add_tab(KIT_SHEET)
	bar.tab_alignment = TabBar.ALIGNMENT_LEFT
	bar.focus_mode = Control.FOCUS_NONE
	bar.clip_tabs = false
	MenuTheme.tabs(bar)
	AtlasTicketStyle.dress_tabs(bar, 16.0 if TouchInput.enabled else 11.0)
	bar.visible = Loyalty.district_open(_profile, LoyaltyLandmark.District.OFF_THE_BOOKS)
	bar.tab_changed.connect(func(tab: int) -> void: turn_to(tab as LoyaltyMapLayout.Sheet))
	return bar


## The map turned to its sheet [param to], see [LoyaltyMapLayout.Sheet], the cursor standing where
## it last stood on it, or at its way in, and the pane saying that.
func turn_to(to: LoyaltyMapLayout.Sheet) -> void:
	if to == map_view.sheet:
		return
	_stood_on[map_view.sheet] = cursor.at
	var at: StringName = _stood_on.get(to, _way_in(to))
	map_view.set_sheet(to)
	map_view.stand_at(at)
	_describe(at)


## Where a sheet is come onto with nothing stood on it yet: the slip road for the House's, and for
## Kit's his first landmark.
func _way_in(to: LoyaltyMapLayout.Sheet) -> StringName:
	if to == LoyaltyMapLayout.Sheet.HOUSE:
		return START
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		if LoyaltyMapLayout.sheet_of(each) == to and each.entry:
			return each.id
	return START


## The map turned to [param to], by a tab, a bind or the cursor going over a sheet's edge: the tabs
## and the binds say so.
func _on_sheet_changed(to: LoyaltyMapLayout.Sheet) -> void:
	if sheet_tabs.current_tab != to:
		sheet_tabs.current_tab = to
	_show_binds()


## The card shown in full over the map, as the license is, grown up off the corner's; put away, the
## cursor back on the map, which it never leaves.
func show_card() -> void:
	if card_view != null or _closing:
		return
	card_view = LoyaltyCardView.open(_root, _profile, card_corner, _keyboard)
	# Its bind lies over it on the cover, and goes with it while it is up.
	var bind := cover.get_node_or_null("CardBind") as CanvasItem
	if bind != null:
		bind.hide()
	card_view.put_away.connect(
		func() -> void:
			card_view = null
			cover.hold_bind(null)
			_show_binds()
			map_view.grab_focus()
	)


## The List switch at the head's right, its words before it, and the binds of it and of the zoom
## after it while keys or a pad are in hand.
func _switch_row() -> HBoxContainer:
	_switches = HBoxContainer.new()
	_switches.name = "Switches"
	_switches.add_theme_constant_override("separation", 14)
	_switches.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hint_row = HBoxContainer.new()
	_hint_row.name = "Binds"
	_hint_row.add_theme_constant_override("separation", 14)
	_hint_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_switches.add_child(_hint_row)
	var named := Label.new()
	named.text = LIST
	Type.strong(named, Type.BODY, HouseTheme.WORDS)
	named.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_switches.add_child(named)
	list_switch = MenuTheme.toggle(listed)
	AtlasTicketStyle.dress_switch(list_switch)
	list_switch.name = "ListSwitch"
	list_switch.focus_mode = Control.FOCUS_NONE
	list_switch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		list_switch.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	list_switch.toggled.connect(set_listed)
	_switches.add_child(list_switch)
	return _switches


## The keys of the map: the details key is List, an arrow, the stick or the cross drives the cursor
## along the road that way, and minus and plus or a pad's shoulders zoom. Heard before the cursor
## would take an arrow to move on.
func _input(event: InputEvent) -> void:
	if held:
		return
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_show_binds()
	# Every move of the stick heard, whatever is up, so a stick let go meanwhile is not still held.
	var pushed := _pushed(event)
	if _closing or event.is_echo() or _editions != null or intro != null:
		return
	# The card in full hears its own keys, see [LoyaltyCardView]; the map hears none while it is up.
	if card_view != null:
		return
	if event.is_action_pressed(CARD_ACTION) and card_corner.is_visible_in_tree():
		show_card()
	elif (
		not listed
		and event.is_action_pressed(&"ui_accept")
		and cursor.at == Loyalty.ROUNDABOUT
		and _profile.loyalty.owed > 0
	):
		choose_edition()
	elif not listed and event.is_action_pressed(LoyaltyPane.PIN_ACTION) and pane.pin.visible:
		toggle_pin()
	elif event.is_action_pressed(LIST_ACTION):
		set_listed(not listed)
	elif not listed and sheet_tabs.visible and event.is_action_pressed(SHEET_ACTION):
		var house := map_view.sheet == LoyaltyMapLayout.Sheet.HOUSE
		turn_to(LoyaltyMapLayout.Sheet.KIT if house else LoyaltyMapLayout.Sheet.HOUSE)
	elif not listed and sheet_tabs.visible and _sheet_by(event):
		pass
	elif not listed and _drive_by(event, pushed):
		pass
	elif not listed and _zoom_by(event):
		pass
	else:
		return
	get_viewport().set_input_as_handled()


## Drives the cursor the way [param event] pushes, if it is a push. True if it was, or if it was the
## stick still held over, [param pushed] false: a stick drives a landmark a push, and on only as
## [PadRepeat] has it.
func _drive_by(event: InputEvent, pushed: bool) -> bool:
	var ways := {
		&"ui_left": Vector2i.LEFT,
		&"ui_right": Vector2i.RIGHT,
		&"ui_up": Vector2i.UP,
		&"ui_down": Vector2i.DOWN,
	}
	for action: StringName in ways:
		if event.is_action_pressed(action):
			if pushed:
				map_view.drive_toward(ways[action])
			return true
	return false


## Whether [param event] is a push: anything but a stick, or a stick just pushed over a way it was
## not before, rather than moving on where it already was, as every move of one held over reads.
func _pushed(event: InputEvent) -> bool:
	var stick := event as InputEventJoypadMotion
	if stick == null:
		return true
	var over := absf(stick.axis_value) >= InputMap.action_get_deadzone(&"ui_right")
	var way := int(signf(stick.axis_value)) if over else 0
	var was: int = _stick_ways.get(stick.axis, 0)
	_stick_ways[stick.axis] = way
	return way != 0 and way != was


## Turns to the sheet a shoulder [param event] steps to: the left the House's, the right Kit's.
## True if it was a shoulder.
func _sheet_by(event: InputEvent) -> bool:
	var pad := event as InputEventJoypadButton
	if pad == null or not pad.pressed or pad.button_index not in [SHEET_BACK, SHEET_ON]:
		return false
	var back := pad.button_index == SHEET_BACK
	turn_to(LoyaltyMapLayout.Sheet.HOUSE if back else LoyaltyMapLayout.Sheet.KIT)
	return true


## Zooms the map in or out a notch for [param event], if it is a zoom key. True if it was, or if it
## was a trigger, which zooms as it is held, see [method _process].
func _zoom_by(event: InputEvent) -> bool:
	var key := event as InputEventKey
	var pull := event as InputEventJoypadMotion
	if pull != null:
		return pull.axis in [ZOOM_OUT, ZOOM_IN]
	var by := 0.0
	if key != null and key.pressed:
		by = -1.0 if key.keycode in ZOOM_KEYS_OUT else (1.0 if key.keycode in ZOOM_KEYS_IN else 0.0)
	if by == 0.0:
		return false
	map_view.zoom_to(map_view.zoom * pow(LoyaltyMapView.ZOOM_STEP, by), map_view.size * 0.5)
	map_view.show_point(cursor.point, false)
	return true


## A pad on the map, GAME.md 8.9: its triggers zoom it in and out for as long as they are held,
## faster the further they are pulled, about the landmark the cursor is at while it is in view, and
## its right stick moves it about, as a drag does.
func _process(delta: float) -> void:
	if held:
		return
	if _closing or _editions != null or card_view != null or listed or map_view == null:
		return
	if intro != null:
		return
	var zooming := 0.0
	var push := Vector2.ZERO
	for pad: int in Input.get_connected_joypads():
		var into := Input.get_joy_axis(pad, ZOOM_IN)
		var out := Input.get_joy_axis(pad, ZOOM_OUT)
		zooming += (into if into > TRIGGER_REST else 0.0) - (out if out > TRIGGER_REST else 0.0)
		var stick := Vector2(
			Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
		)
		if stick.length() > STICK_REST:
			push += stick
	pad_on_map(zooming, push, delta)


## The map zoomed [param zooming] of a trigger's whole pull, in for more than none and out for less,
## and moved by the right stick pushed [param push] of the way, for [param delta] seconds, see
## [method _process]: pushed right, more of the map to the right comes into view.
func pad_on_map(zooming: float, push: Vector2, delta: float) -> void:
	if zooming != 0.0:
		var about := map_view.offset + cursor.point * map_view.zoom
		if not Rect2(Vector2.ZERO, map_view.size).has_point(about):
			about = map_view.size * 0.5
		map_view.zoom_to(map_view.zoom * pow(2.0, ZOOM_RATE * zooming * delta), about)
	if push != Vector2.ZERO:
		map_view.pan_by(-push.limit_length(1.0) * PAN_RATE * delta)


## B on a pad, or Escape, is Back, out of the editions first. Nothing gets past the dialog to the
## screen under it.
func _unhandled_input(event: InputEvent) -> void:
	if held or _closing or card_view != null:
		return
	if intro != null and event.is_action_pressed(&"ui_cancel"):
		_put_intro_away()
	elif _editions != null and event.is_action_pressed(&"ui_cancel"):
		_editions_done()
	elif event.is_action_pressed(&"ui_cancel"):
		Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
		close()
	elif not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()


## A short word on what the program is, over the map, the first time the House's welcome opens it
## and its card has come to rest, so a player shown the map out of nowhere knows what it is for:
## what it holds, what picking a landmark says, and what pinning one does. One button, Got it, the
## cursor on it; it or Back puts it away, the cursor on the map.
func introduce() -> void:
	if intro != null or _closing:
		return
	intro = Control.new()
	intro.name = "Intro"
	intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(intro)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.add_child(middle)
	var said := ConfirmPane.new()
	middle.add_child(said)
	said.ask(program_name(_profile), INTRO_LINE, INTRO_OK, "", RoadSign.Kind.QUESTION)
	said.no_button().visible = false
	said.yes_button().grab_focus()
	said.answered.connect(func(_yes: bool) -> void: _put_intro_away())


func _put_intro_away() -> void:
	if intro == null:
		return
	intro.queue_free()
	intro = null
	map_view.grab_focus()


## A click or a tap on the shade beside the pane puts the dialog away.
func _on_shade_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed) or (touch != null and touch.pressed):
		_shade.accept_event()
		close()


func _gone() -> void:
	if _from != null and is_instance_valid(_from) and _from.is_inside_tree():
		_from.grab_focus()
	put_away.emit()
	queue_free()


## A click or a tap on a landmark: the pane says it at once, and the cursor drives there.
func _on_picked(id: StringName) -> void:
	map_view.drive_to(id)


## A row of the list pressed: the map, the cursor at that landmark; the roundabout's while an
## edition is owed, the editions over it too.
func _on_chosen(id: StringName) -> void:
	set_listed(false)
	map_view.stand_at(id)
	_describe(id)
	if id == Loyalty.ROUNDABOUT and _profile.loyalty.owed > 0:
		choose_edition()


## What the pane says pinned, GAME.md 8.9, or unpinned if it was: one pin at a time, kept in the
## profile, its mark on the map and the list again.
func toggle_pin() -> void:
	var id := StringName(pane.shown)
	if not Loyalty.can_pin(_profile, id):
		return
	var state := _profile.loyalty
	state.pinned = &"" if state.pinned == id else id
	Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0)
	if not Game.is_headless():
		Game.settings.save_to_disk()
	_describe(id)
	map_view.queue_redraw()
	# The strip by a match's clock says it at once, the match paused under the menu or not.
	get_tree().call_group(PinnedNote.STRIPS, &"look")
	if listed:
		list.fill(_profile)
		list.focus_on(id)


## The editions a lap of the roundabout pays, chosen over the map, GAME.md 8.9; put away, the
## pane says the roundabout as it now is and the profile keeps what was chosen.
func choose_edition() -> void:
	if _editions != null or _profile.loyalty.owed <= 0:
		return
	_editions = LoyaltyEditions.for_profile(_profile)
	_editions.name = "Editions"
	_editions.set_anchors_preset(Control.PRESET_CENTER)
	_editions.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_editions.grow_vertical = Control.GROW_DIRECTION_BOTH
	_editions.done.connect(_editions_done)
	_root.add_child(_editions)


func _editions_done() -> void:
	if _editions == null:
		return
	_editions.queue_free()
	_editions = null
	Game.settings.save_to_disk()
	_describe(cursor.at)
	map_view.grab_focus()


## The pane says the landmark [param id], and its NEW tag goes.
func _describe(id: StringName) -> void:
	var landmark := Loyalty.map().landmark(id)
	if id == Loyalty.ROUNDABOUT:
		pane.show_roundabout(_profile)
	elif landmark != null:
		pane.show_landmark(_profile, landmark)
		if _profile.loyalty.look_at(id):
			_looked = true
			map_view.queue_redraw()
	ButtonBinds.show(pane.bound(), _keyboard, not _pointer)


## The NEW tags gone are kept in the profile.
func _keep_looks() -> void:
	if _looked:
		_looked = false
		Game.settings.save_to_disk()


## The pane over nearly all the screen, the shade showing round it, or over all of it short of
## room, see [method CatalogDialog.fill_screen]; and its head as the room has it.
func _fit() -> void:
	var room := _root.size
	CatalogDialog.fill_screen(_pane, _around, room)
	cover.fit(room.y < SHORT)
	_lay_head(room.y < SHORT)
	var wide := side_wide(room.x, card_corner.visible)
	_side.custom_minimum_size.x = wide
	pane.set_wide(wide - SIDE_MOST + LoyaltyPane.WIDTH)
	_fit_head.call_deferred()


## How wide the side column is on a screen [param room] wide, the card in it or not: the pane's own
## width, or less on a narrow screen, [constant SIDE_SHARE] of it, so the map has the rest.
static func side_wide(room: float, card: bool) -> float:
	var least := SIDE_LEAST
	if card:
		least = maxf(least, LoyaltyCard.SIZE.x * CARD_SCALE + SIDE_AROUND * 2.0)
	return clampf(room * SIDE_SHARE, least, SIDE_MOST)


## The head on the one row the screen has room for, so it never pushes the pane wider than that:
## the title, the switch and its bind, and Back where it is there, always; the binds of the map's
## keys where they fit beside them, and the line beside the title where all of it fits as well.
func _fit_head() -> void:
	if not is_inside_tree():
		return
	var gap := float(_head.get_theme_constant(&"separation"))
	var between := float(_hint_row.get_theme_constant(&"separation"))
	_line.visible = false
	if _how != null:
		_how.visible = false
	var room := head_room() + gap
	for child: Node in _head.get_children():
		var each := child as Control
		if each != null and each.visible:
			room -= each.get_combined_minimum_size().x + gap
	if _how != null:
		var how := _how.get_combined_minimum_size().x + between
		_how.visible = how <= room
		room -= how if _how.visible else 0.0
	var font := _line.get_theme_font(&"font")
	var size_of := _line.get_theme_font_size(&"font_size")
	var wide := font.get_string_size(_line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_of).x
	_line.visible = wide + gap <= room
	# Where the line is not, the title takes its room, the switch kept at the right.
	_title.size_flags_horizontal = (
		Control.SIZE_FILL if _line.visible else Control.SIZE_EXPAND_FILL
	)


## How wide the head can be: the inside of the pane as wide as the screen lets it be, whatever is
## in it, see [method _fit].
func head_room() -> float:
	var around := float(_around.get_theme_constant(&"margin_left"))
	around += float(_around.get_theme_constant(&"margin_right"))
	var look := _pane.get_theme_stylebox(&"panel")
	return _root.size.x - around - look.get_margin(SIDE_LEFT) - look.get_margin(SIDE_RIGHT)


## Short of room, see [constant SHORT]: Back at the head's right, after the switch, as the settings
## have it, GAME.md 8.5. Otherwise Back at the foot of the column beside the map, under the card.
func _lay_head(short: bool) -> void:
	if short == (back.get_parent() == _head):
		return
	var had_cursor := back.has_focus()
	back.reparent(_head if short else _column, false)
	# The card gives its room to the pane where there is little.
	card_corner.visible = not short
	if had_cursor:
		back.grab_focus()


## Opens on the list where it was left on it, or where the map's room is too narrow to read, as a
## phone's is at a big UI scale; otherwise on the map, the cursor on it.
func _open_as_left() -> void:
	if not is_inside_tree() or _closing:
		return
	_opened = true
	var narrow := map_view.size.x > 0.0 and map_view.size.x < NARROW
	if unfolding:
		_show_list(false)
		_unfold()
		return
	_show_list(listed or narrow)


## The map unfolding, from folded in three to open, panel after panel as a map opens out.
func _unfold() -> void:
	map_view.pivot_offset = map_view.size * 0.5
	map_view.scale = Vector2(FOLDED, 1.0)
	map_view.modulate.a = 0.0
	var opening := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	opening.tween_property(map_view, "scale", Vector2.ONE, UNFOLD)
	opening.parallel().tween_property(map_view, "modulate:a", 1.0, UNFOLD * 0.4)
	Audio.play_sfx(&"page", -4.0, 0.05)


## The list in the map's place, or the map, the cursor in whichever is up.
func _show_list(on: bool) -> void:
	list_switch.set_pressed_no_signal(on)
	list.visible = on
	map_view.visible = not on
	if on:
		list.fill(_profile)
		if not list.focus_on(cursor.at):
			back.grab_focus()
	else:
		map_view.grab_focus()
		map_view.show_point(cursor.point, false)
	_show_binds()


func _on_pad_plugged(_device: int, _connected: bool) -> void:
	_show_binds()


## The binds before the switch: the details key that flips it, and on the map the zoom's, keys' or
## a pad's while they are in hand; none for the mouse alone.
func _show_binds() -> void:
	for row: HBoxContainer in [_hint_row, _sheet_hint]:
		for child: Node in row.get_children():
			(child as Control).hide()
			child.queue_free()
	_how = null
	_card_bind(null)
	_fit_head.call_deferred()
	var pad := SettingsScreen.pad_plugged_in()
	var keys := _keyboard and not _pointer
	# A touch screen has no keys to draw, and fingers say for themselves what they do.
	if TouchInput.enabled or (not keys and not pad):
		return
	var ink := SettingsScreen.TAB_HINT_INK
	var size := SettingsScreen.TAB_HINT_SIZE
	if not listed and sheet_tabs.visible:
		_sheet_hint.add_child(LoyaltyBinds.sheets(keys, ink, size))
	if not listed:
		# How to drive the cursor to another landmark: the arrows, or the stick pushed every way.
		var parts: Array = [LoyaltyBinds.ways(keys, ink, size)]
		if keys:
			parts.append(LoyaltyBinds.key(KEY_MINUS, ink, size))
			parts.append(LoyaltyBinds.key(KEY_EQUAL, ink, size))
		else:
			for trigger: int in [ZOOM_OUT, ZOOM_IN]:
				var pull := InputEventJoypadMotion.new()
				pull.axis = trigger as JoyAxis
				pull.axis_value = 1.0
				parts.append(InputGlyph.of_event(pull, ink, size))
		_how = InputHint.row("%s " + SELECT + "   %s %s " + ZOOM, parts, ink, size)
		_how.name = "How"
		_hint_row.add_child(_how)
	# The switch's own bind just before its word, which says what it does.
	var list_bind := InputGlyph.of_action(LIST_ACTION, keys, ink, size)
	_hint_row.add_child(InputHint.row("%s", [list_bind], ink, size))
	_card_bind(InputGlyph.of_action(CARD_ACTION, keys, ink, size))
	ButtonBinds.show(pane.bound(), _keyboard, not _pointer)


## [param glyph], the bind that shows the card in full, on the card's bottom right corner over the
## photo corner there, the one there before taken off; none for null. The cover holds it, being
## over the photo corners, see [method AtlasCover.hold_bind].
func _card_bind(glyph: Control) -> void:
	if cover != null:
		cover.hold_bind(glyph)
	elif glyph != null:
		glyph.queue_free()
