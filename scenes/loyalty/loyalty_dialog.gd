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
## but for the NEW tags, which go as the cursor comes to them and are kept gone as it is put away;
## Next new, or N or a pad's View, sets it down at the next one, see [LoyaltyNextNew].

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
## The switch over the pane, and the bind that flips it, the dialogs' view key, see [DialogBinds].
const LIST := "List"
const LIST_ACTION := InputActions.MENU_VIEW
## The binds that zoom the map, in the row over it: a pad's triggers, smoothly for as long and as
## fast as they are pulled, and on keys minus and plus, a notch a press.
const ZOOM := "Zoom"
## What the arrows or the stick do on the map, in the same row.
const SELECT := "Select landmark"
## The map's two sheets, see [LoyaltyMapLayout.Sheet]: their tabs over the map once Kit's is on
## it, see [SheetTabs], and the dialogs' page keys turn from one to the other, Q or the left
## shoulder to the House's and E or the right to Kit's, as they turn the catalog's pages, see
## [DialogBinds].
const SHEET_BACK := InputActions.MENU_PAGE_PREV
const SHEET_ON := InputActions.MENU_PAGE_NEXT
const ZOOM_OUT := JOY_AXIS_TRIGGER_LEFT
const ZOOM_IN := JOY_AXIS_TRIGGER_RIGHT
## A pad on the map: how fast a trigger pulled all the way zooms it, in doublings a second, and how
## fast the right stick all the way over moves it, in pixels a second; and how little of a pull or
## a push is resting.
const ZOOM_RATE := 2.0
const PAN_RATE := 1800.0
const TRIGGER_REST := 0.04
const STICK_REST := 0.2
## How it works in the head, which shows the House's first look again, see [LoyaltyTour], and its
## bind, H or a pad's Back; and its question mark where the head has no room for its words.
const HOW := "How it works"
const HOW_SHORT := "?"
const HOW_ACTION := InputActions.MENU_HELP
const HOW_ACROSS := 14.0
## The bind that shows the program's card in full, drawn on the card's corner, the dialogs' option
## key, see [DialogBinds]: the cursor never goes to the card, which would take it out of the map.
const CARD_ACTION := InputActions.MENU_OPTION
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
## The House showing the member round its map while it is, see [method start_tour].
var tour: LoyaltyTour
## How it works, in the head.
var how_ticket: Button
## The map's sheets' tabs, over its top left once Kit's is on it.
var sheet_tabs: SheetTabs
## Next new, at the head's right before the switch, see [LoyaltyNextNew].
var next_new: NextNew

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
## The bets it opens showing being won, see [LoyaltyReveal], and their showing while it is under
## way; and whether the House's tour comes once it is open, which shows the slip road's itself.
var _showing: Array[StringName] = []
var _reveal: LoyaltyReveal
var _touring := false


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
	# A finger on it is its own: nothing under it, a room's menu say, hears it first.
	TouchInput.keep_touches(self)
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
	next_new = LoyaltyNextNew.add_to(self, _head, _profile)
	_head.add_child(_switch_row())
	var opening := LoyaltyOpening.of(_profile, start_at, stood_at, unfolding)
	var start := opening.start
	_showing = opening.showing
	_touring = opening.touring
	# Asked for a landmark, or shown round, on the map.
	if start_at != &"" or _touring:
		listed = false
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
	map_view.stand_at(start)
	# A bet to be shown being won is said as the cursor comes to it, its NEW tag going then.
	if _touring or _showing.is_empty():
		_describe(start)
	_root.resized.connect(_fit)
	_fit()
	# The card left out under a pane too tall for both, rather than the side scrolling.
	var pocket := card_corner.get_parent() as AtlasCover.Pocket
	_side.resized.connect(pocket.fit_in.bind(_side))
	pane.minimum_size_changed.connect(pocket.fit_in.bind(_side))
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
	# Its binds clear of the last tab's NEW tag, which stands out past its corner.
	sheet_row.add_theme_constant_override("separation", 14 + int(CatalogCell.NEW_OUT.x))
	sheet_in.add_child(sheet_row)
	sheet_tabs = SheetTabs.of(_profile)
	sheet_tabs.tab_changed.connect(func(tab: int) -> void: turn_to(tab as LoyaltyMapLayout.Sheet))
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
	# Drawn as it was before the bets it shows being won, from its first picture.
	map_view.profile = _profile
	if not _showing.is_empty():
		map_view.profile = LoyaltyReveal.held_back(_profile, _showing)
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
	# shadow is not cut off. The scroll bar's room is kept for it, so the map beside is not made
	# narrower as it comes, which would move the map from what was chosen.
	var side := ScrollContainer.new()
	_side = side
	side.name = "Side"
	side.custom_minimum_size.x = SIDE_MOST
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
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


## The map turned to its sheet [param to], see [LoyaltyMapLayout.Sheet], the cursor standing where
## it last stood on it, or at its way in, and the pane saying that.
func turn_to(to: LoyaltyMapLayout.Sheet) -> void:
	if to == map_view.sheet:
		return
	_stood_on[map_view.sheet] = cursor.at
	var at: StringName = _stood_on.get(to, _way_in(to))
	# Its bets won since it was last shown, shown being won, the first of them where it opens.
	var due: Array[StringName] = []
	if LoyaltyOpening.watched and tour == null and _reveal == null:
		due = LoyaltyReveal.due(_profile, to)
	if not due.is_empty():
		at = due[0]
		map_view.profile = LoyaltyReveal.held_back(_profile, due)
	map_view.set_sheet(to)
	map_view.stand_at(at)
	_describe(at)
	if not due.is_empty():
		reveal_now(due)


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
	# How it works, the House's first look shown again: a ticket as tall as Next new's beside it, in
	# the head's own size of words, its bind hung on it while keys or a pad are in hand, as the
	# slip's Pin has.
	how_ticket = ScreenReader.name(AtlasTicketStyle.ticket(HOW, 0.0), HOW) as Button
	how_ticket.name = "HowItWorks"
	Type.set_font(how_ticket, Type.STRONG, Type.LABEL + 1)
	# Narrower round its words than Back, so the House's pencil still has the head's room.
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var look := how_ticket.get_theme_stylebox(state)
		look.content_margin_left = HOW_ACROSS
		look.content_margin_right = HOW_ACROSS
	how_ticket.focus_mode = Control.FOCUS_NONE
	how_ticket.pressed.connect(start_tour)
	ButtonBinds.mark(how_ticket, HOW_ACTION)
	_switches.add_child(how_ticket)
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
	list_switch = ScreenReader.name(MenuTheme.toggle(listed), LIST) as CheckButton
	AtlasTicketStyle.dress_switch(list_switch)
	list_switch.name = "ListSwitch"
	list_switch.focus_mode = Control.FOCUS_NONE
	list_switch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		list_switch.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	list_switch.toggled.connect(set_listed)
	_switches.add_child(list_switch)
	return _switches


## The keys of the map, the dialogs' own, see [DialogBinds]: the view key is List, the option key
## shows the card, the page keys turn the sheets, an arrow, WASD, the stick or the cross drives the
## cursor along the road that way, and minus and plus or a pad's triggers zoom. Heard before the
## cursor would take an arrow to move on.
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
	var pushed := LoyaltyMapKeys.pushed(event, _stick_ways)
	# The card in full hears its own keys, see [LoyaltyCardView], and the tour its own, see
	# [LoyaltyTour]; the map hears none while either is up.
	if _closing or _editions != null or tour != null or card_view != null:
		return
	# A press while bets are shown being won shows the rest at once.
	if _reveal != null and not _reveal.is_done() and LoyaltyReveal.is_press(event):
		_reveal.finish_now()
		get_viewport().set_input_as_handled()
		return
	# WASD down the list moves the cursor as the arrows do.
	if listed and DialogBinds.moved_focus(event, get_viewport()):
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	if event.is_action_pressed(CARD_ACTION) and card_corner.is_visible_in_tree():
		show_card()
	elif event.is_action_pressed(HOW_ACTION):
		start_tour()
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
	elif next_new.heard(event):
		pass
	elif not listed and sheet_tabs.visible and _sheet_by(event):
		pass
	elif not listed and LoyaltyMapKeys.drive_by(map_view, event, pushed):
		pass
	elif not listed and LoyaltyMapKeys.zoom_by(map_view, event):
		pass
	else:
		return
	get_viewport().set_input_as_handled()


## Turns to the sheet a page key [param event] steps to: the page before the House's, the page
## after Kit's. True if it was one.
func _sheet_by(event: InputEvent) -> bool:
	if event.is_action_pressed(SHEET_BACK):
		turn_to(LoyaltyMapLayout.Sheet.HOUSE)
	elif event.is_action_pressed(SHEET_ON):
		turn_to(LoyaltyMapLayout.Sheet.KIT)
	else:
		return false
	return true


## A pad on the map, GAME.md 8.9, see [method LoyaltyMapKeys.pads]: its triggers zoom it for as
## long as they are held and its right stick moves it about, as a drag does.
func _process(delta: float) -> void:
	if held or _closing or _editions != null or card_view != null or tour != null:
		return
	if listed or map_view == null:
		return
	var pads := LoyaltyMapKeys.pads()
	pad_on_map(pads.x, Vector2(pads.y, pads.z), delta)


## The map zoomed [param zooming] of a trigger's whole pull and moved by the right stick pushed
## [param push] of the way, for [param delta] seconds, see [method LoyaltyMapKeys.pad_on].
func pad_on_map(zooming: float, push: Vector2, delta: float) -> void:
	LoyaltyMapKeys.pad_on(map_view, zooming, push, delta)


## B on a pad, or Escape, is Back, out of the editions first. Nothing gets past the dialog to the
## screen under it.
func _unhandled_input(event: InputEvent) -> void:
	if held or _closing or card_view != null or tour != null:
		return
	if _editions != null and event.is_action_pressed(&"ui_cancel"):
		_editions_done()
	elif event.is_action_pressed(&"ui_cancel"):
		Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
		close()
	elif not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()


## The House showing the member round its map, GAME.md 8.9 "The first look", from its first step,
## see [LoyaltyTour]: on the map, any showing of bets won brought all at once first.
func start_tour() -> void:
	if tour != null or _closing or held:
		return
	if listed or not map_view.visible:
		listed = false
		_show_list(false)
	if _reveal != null:
		_reveal.finish_now()
	tour = LoyaltyTour.over(self)
	pane.pin_asked.connect(tour.pinned_from_slip)
	tour.ended.connect(_tour_ended)


func _tour_ended(_finished: bool) -> void:
	if tour != null and pane.pin_asked.is_connected(tour.pinned_from_slip):
		pane.pin_asked.disconnect(tour.pinned_from_slip)
	tour = null
	_show_binds()
	map_view.grab_focus()


## The bets [param ids] shown being won, the cursor at each as it is, see [LoyaltyReveal].
func reveal_now(ids: Array[StringName]) -> LoyaltyReveal:
	if _reveal != null:
		_reveal.finish_now()
	var showing := LoyaltyReveal.over(map_view, _profile, ids)
	_reveal = showing
	showing.came_to.connect(_describe)
	showing.passed.connect(_seen)
	showing.finished.connect(
		func() -> void:
			if _reveal == showing:
				_reveal = null
	)
	return showing


## [param id] shown being won with others, the cursor elsewhere: its NEW tag gone all the same.
func _seen(id: StringName) -> void:
	if _profile.loyalty.look_at(id):
		_looked = true
		map_view.queue_redraw()
		sheet_tabs.tag(_profile)


## The dialog's own root, which the tour is put up in.
func root() -> Control:
	return _root


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


## The pane says the landmark [param id], and its NEW tag goes, with its sheet's once it was the
## last on it.
func _describe(id: StringName) -> void:
	var landmark := Loyalty.map().landmark(id)
	if id == Loyalty.ROUNDABOUT:
		pane.show_roundabout(_profile)
	elif landmark != null:
		pane.show_landmark(_profile, landmark)
		if _profile.loyalty.look_at(id):
			_looked = true
			map_view.queue_redraw()
			sheet_tabs.tag(_profile)
			next_new.show_left(LoyaltyNextNew.left(_profile))
	ButtonBinds.show(pane.bound(), _keyboard, not _pointer)
	ScreenReader.say(map_view, ScreenReader.words_in(pane))


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
	how_ticket.text = HOW
	var room := head_room() + gap
	for child: Node in _head.get_children():
		var each := child as Control
		if each != null and each.visible:
			room -= each.get_combined_minimum_size().x + gap
	# Short of room for How it works' words even so, a question mark alone.
	if room < 0.0:
		var full := how_ticket.get_combined_minimum_size().x
		how_ticket.text = HOW_SHORT
		room += full - how_ticket.get_combined_minimum_size().x
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
	if _touring:
		_show_list(false)
		start_tour()
		return
	var on_list := listed or narrow
	if on_list and not _showing.is_empty():
		# Nothing shown being won on the list: their NEW tags say it, the cursor where it rests.
		_showing.clear()
		map_view.profile = _profile
		map_view.redraw_sheet()
		var rest := LoyaltyOpening.resting(_profile, stood_at)
		map_view.stand_at(rest)
		_describe(rest)
	_show_list(on_list)
	if not _showing.is_empty():
		reveal_now(_showing)


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
	next_new.show_bind(keys, keys or pad)
	ButtonBinds.show([how_ticket], keys, keys or pad)
	# A touch screen has no keys to draw, and fingers say for themselves what they do.
	if TouchInput.enabled or (not keys and not pad):
		return
	var ink := SettingsScreen.TAB_HINT_INK
	var size := SettingsScreen.TAB_HINT_SIZE
	if not listed and sheet_tabs.visible:
		_sheet_hint.add_child(DialogBinds.pages(keys, ink, size))
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
