class_name CatalogDialog
extends CanvasLayer
## The catalog of GAME.md 8.8: every joker the profile playing ever took and every power-up it ever
## used, a page each, the rest lying face down. A large dialog over whatever screen opens it, the
## title's for now: a shade over the screen and the house's pane over nearly all of it, on a layer
## of its own over a room's pause menu too, so it can be laid over any screen, and Back or a click
## beside it puts it away again with the cursor back where it was.
##
## The cards of a page lie in a well sunk into the pane, the one Play Online lists its servers in,
## see [ListBox], every card the one size in rows across the well, see [CardGrid], which scrolls
## where they are more than it has room for. The card under the cursor lifts and is described in
## the pane on the right, under its picture large in its ring where there is room, see
## [CardPreview]: a
## joker's in the pane a match describes it in, [JokerDetail], with a switch under it, Detailed, for
## what the hand says only for the details key held, and a field for the stack it is shown as, up
## to the biggest the profile held; an item's in [PowerUpDetail], with the numbers no match shows.
## Each tab says how many of how many were found, and the row of tabs carries the gamepad's binds
## at its right end, as the settings' does. Read only, but for the NEW tags, which go as the cursor
## comes to them and are kept gone as the dialog is put away.

## Put away, the cursor back where it was.
signal put_away

## Over a room's pause menu, under the notices and the loading screen.
const LAYER := PauseMenu.LAYER + 5
const TITLE := "Catalog"
const JOKERS := "Jokers"
const ITEMS := "Power-ups"
## A tab's words: the page and how many of how many it has found.
const COUNT := "%s  %d / %d"
## What a page with nothing found on it yet says in place of its cards, GAME.md 8.8.
const NO_JOKERS := "Start a match and take a joker to unlock this page."
const NO_ITEMS := "Start a match and use a power-up to unlock this page."
## What a card face down says, and how many times one face up was taken.
const NOT_FOUND := "Not found yet"
const TAKE_ONE := "Take one in a match to read it here."
const USE_ONE := "Use one in a match to read it here."
## Under a card the profile's loyalty program has yet to add, GAME.md 8.9: the program's name and
## the bet that adds it.
const NOT_DEALT := "Not in your deck yet. %s: %s."
const NOT_ON_TABLES := "Not on your tables yet. %s: %s."
const TAKEN_ONCE := "Taken once"
const TAKEN := "Taken %d times"
const USED_ONCE := "Used once"
const USED := "Used %d times"
## The switch and the stack's field under a joker's pane, and the binds that flip the one and step
## the other on, in the row of tabs; and what the field says beside it, of the biggest stack held.
const DETAILED := "Detailed"
const STACK := "Stack"
const DETAILED_ACTION := InputActions.DETAILS
const STACK_ACTION := InputActions.JOKER_MENU
const HELD_UP_TO := "Held up to ×%d"
## The stack asked for that is every joker's whole stack, whatever it stacks to.
const WHOLE_STACK := 99
const NO_STACK := "Does not stack"
## Between how often a joker was taken and the biggest stack held, at the pane's foot.
const FOOT_JOIN := "  ·  "
## The line of facts that says which set an item comes in, in the lobby's words, GAME.md 9.6.
const SET := "Set"
const BASIC_SET := "Basic items"
const LATER_SET := "All items only"
## How much of the screen is left round the pane, a share of its shorter side and at least a few
## pixels, so the shade shows round it and a click there can put it away.
const AROUND := 0.04
const AROUND_LEAST := 16.0
const SHADE := Color(0.0, 0.0, 0.0, 0.55)
## The room between the well and the pane's column, how wide that column is, and the room round the
## pane in it and between the pane and its switches.
const PANE_GAP := 24.0
const PANE_ROOM := JokerDetail.WIDTH + 44.0
const PANE_AROUND := 16
const SWITCHES_UNDER := 28
## The room kept for the pane under the large card, as tall as the most a pane says, measured: a
## joker's at its whole stack with the details on and both lines at its foot, Curve Ball's at 242;
## so the card stays the one size whatever the card under the cursor says. A pane taller still
## takes what it needs from the card.
const PANE_KEPT := 250.0
## How wide the words before the switch and the stack's field are, so the two line up one over the
## other, and the room between those words, the controls and what is said after them.
const NAMES_WIDE := 130.0
const SWITCHES_ACROSS := 18
const SWITCHES_DOWN := 14
## Less room than this from top to bottom, as a phone's screen has at its UI scale or a desktop's at
## a large one, and the head is the settings', see [method _lay_head], leaving the cards every row
## it can; and the dialog fills the screen, see [method fill_screen].
const SHORT := 900.0
## How far in from its edge a pane that fills the screen holds what is in it: clear of the hairline
## inside its edge, and no further; how far in a well in it holds its cards or its map; and the
## room between a well and the column beside it.
const FULL_INSIDE := MenuTheme.PANE_INSET + 10.0
const FULL_WELL_INSET := 6
const FULL_GAP := 12.0

const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const FIRST: PowerUpTable = preload("res://data/powerups/first_set.tres")
const LATER: PowerUpTable = preload("res://data/powerups/later_set.tres")

## Whether a joker's pane says what the hand says only for the details key held, and how big a
## stack it is shown as, as far as each joker goes, see [method stack_limit]: every joker at its
## whole stack to start with, [constant WHOLE_STACK]. Kept for the run, so the catalog opens again
## as it was left.
static var detailed := false
static var stack := WHOLE_STACK

var tabs: TabContainer
## The tabs drawn in a row of their own, and at its right end, while a gamepad is plugged in, as
## the settings have them, GAME.md 8.5: the binds of the switches on the page showing, and the
## shoulder buttons that turn the pages.
var tab_bar: TabBar
var tab_hint: Control
var switch_hint: Control
## Each tab's NEW tag while a card on its page has not been looked at, or null, GAME.md 8.8.
var tab_tags: Array[Control] = [null, null]
var joker_grid: CardGrid
var item_grid: CardGrid
var joker_pane: JokerDetail
var item_pane: PowerUpDetail
var detailed_switch: CheckButton
## The stack's field, and the words after it.
var stepper: StackStepper
var stack_note: Label
## The card under the cursor shown large over each page's pane, where the room lets it be.
var joker_preview: CardPreview
var item_preview: CardPreview
var back: Button

var _settings: Settings
## The head over the tabs, with the title in it, the story's line under it or beside it, and the
## foot Back stands in where there is the room, see [method _lay_head].
var _head: HBoxContainer
var _title: Label
var _kept: Label
var _foot_row: HBoxContainer
var _root: Control
var _shade: ColorRect
var _around: MarginContainer
var _pane: PanelContainer
## What had the cursor before the dialog came up, for it to go back to.
var _from: Control
## The cell each page last had under its cursor, which its pane describes.
var _joker_at: CatalogCell
var _item_at: CatalogCell
## Whether a NEW tag has gone, to be kept as the dialog goes.
var _looked := false
## Each page's words for nothing found yet, by the page's index, shown in place of its cards.
var _empty: Array[Control] = []
var _closing := false
## Whether keys are in hand rather than a pad, and whether the mouse is, for the binds the row of
## tabs draws, see [method _show_binds]; and which device's binds it draws now.
var _keyboard := true
var _pointer := false
var _binds_for := ""


## The catalog over [param parent], for the profile playing, with the cursor on its first card.
static func open(parent: Node) -> CatalogDialog:
	var dialog := CatalogDialog.new()
	dialog.name = "Catalog"
	if parent.is_inside_tree():
		dialog._from = parent.get_viewport().gui_get_focus_owner()
	parent.add_child(dialog)
	return dialog


## Every joker, in the catalog's order, GAME.md 8.8: by rarity, common first, then by kind, stat,
## rule and cursed, then by name.
static func jokers_in_order() -> Array[Joker]:
	var ordered := CATALOG.jokers.duplicate()
	ordered.sort_custom(
		func(a: Joker, b: Joker) -> bool:
			if a.rarity != b.rarity:
				return a.rarity < b.rarity
			if a.kind != b.kind:
				return a.kind < b.kind
			return a.display_name.naturalnocasecmp_to(b.display_name) < 0
	)
	return ordered


## Every power-up, the first set and then the later one, as each lists them.
static func items_in_order() -> Array[PowerUp]:
	var ordered: Array[PowerUp] = []
	for item: PowerUp in FIRST.entries + LATER.entries:
		if item not in ordered:
			ordered.append(item)
	return ordered


## The ids of [param things], jokers or power-ups, for counting what was found among them.
static func ids_of(things: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for thing: Resource in things:
		ids.append(thing.get(&"id"))
	return ids


## What a joker's pane's foot says of how many times it was taken.
static func taken_words(times: int) -> String:
	return TAKEN_ONCE if times == 1 else TAKEN % times


## What a power-up's pane's foot says of how many times it was used.
static func used_words(times: int) -> String:
	return USED_ONCE if times == 1 else USED % times


## The debug build's catalog argument, `++ --catalog-all`: every joker taken and every power-up used
## once more by the profile playing in [param settings], the ones not found before new, every joker
## that stacks held as its whole stack, so the stack's field goes as far as it can, and kept.
## Nothing in a released game.
static func read_arguments(args: PackedStringArray, settings: Settings) -> void:
	if not OS.is_debug_build() or "--catalog-all" not in args:
		return
	for joker: Joker in CATALOG.jokers:
		settings.profile.catalog.take_joker(joker.id)
		if joker.stackable:
			settings.profile.catalog.hold(joker.id, maxi(joker.most, 1))
	for item: PowerUp in items_in_order():
		settings.profile.catalog.use_item(item.id)
	settings.save_to_disk()


## The lines of facts an item's pane shows: its own, then the set it comes in.
static func facts_of(item: PowerUp) -> Array[PackedStringArray]:
	var lines := item.facts()
	lines.append(PowerUp.fact(SET, LATER_SET if item in LATER.entries else BASIC_SET))
	return lines


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings = Game.settings
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
	_pane = MenuTheme.pane()
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
	_title = MenuTheme.title(TITLE, Type.TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_head.add_child(_title)
	# Whose record this is, as the story goes, STORY.md 6.6a.
	var kept := str(StoryLines.at(StoryLines.CATALOG_LINE, _stage()))
	if not kept.is_empty():
		_kept = MenuTheme.subtitle(kept, Type.LABEL)
		_kept.name = "Kept"
		_kept.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_kept.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		column.add_child(_kept)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.tabs_visible = false
	MenuTheme.tabs(tabs)
	tabs.add_child(_jokers_page())
	tabs.add_child(_items_page())
	# The tabs and their pages one piece, as the settings' are: no air between the row and the page.
	var pages := VBoxContainer.new()
	pages.name = "Pages"
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.add_theme_constant_override("separation", 0)
	column.add_child(pages)
	pages.add_child(_tabs_row())
	pages.add_child(tabs)
	_count_tabs()
	_foot_row = HBoxContainer.new()
	_foot_row.name = "Foot"
	column.add_child(_foot_row)
	var room := Control.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_foot_row.add_child(room)
	back = MenuTheme.button("Back")
	back.name = "Back"
	back.custom_minimum_size.x = 200.0
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	_foot_row.add_child(back)
	tabs.tab_changed.connect(func(_tab: int) -> void: _show_binds())
	_root.resized.connect(_fit)
	_fit()
	_show_binds()
	MenuTheme.deal(_pane)
	_focus_first.call_deferred()
	Input.joy_connection_changed.connect(_on_pad_plugged)


func _exit_tree() -> void:
	_keep_looks()
	if Input.joy_connection_changed.is_connected(_on_pad_plugged):
		Input.joy_connection_changed.disconnect(_on_pad_plugged)


## Puts the dialog away, the cursor going back to whatever had it before.
func close() -> void:
	if _closing:
		return
	_closing = true
	_keep_looks()
	var shades: Array[CanvasItem] = [_shade]
	MenuTheme.put_away(_pane, _gone, shades)


func is_closing() -> bool:
	return _closing


## Steps [param step] pages on, round at the ends, the cursor going to the card the new page last
## had under it, or its first.
func switch_tab(step: int) -> void:
	tabs.current_tab = posmod(tabs.current_tab + step, tabs.get_tab_count())
	_focus_page()


## Whether the page [param index] has nothing found on it yet, and says so in place of its cards.
func is_empty(index: int) -> bool:
	return _empty[index].visible


## Has a joker's pane say what the hand says only for the details key held, or not, see
## [member detailed].
func set_detailed(on: bool) -> void:
	detailed = on
	detailed_switch.set_pressed_no_signal(on)
	if _joker_at != null:
		_describe_joker(_joker_at)


## Shows the joker under the cursor, and every one after it, as a stack of [param copies], as far as
## each goes, see [method stack_limit].
func set_stack(copies: int) -> void:
	stack = maxi(copies, 1)
	if _joker_at != null:
		_describe_joker(_joker_at)


## The stack the joker under the cursor is shown as, one card on: round to one again past the
## biggest it can be shown as.
func step_stack() -> void:
	if _joker_at == null or not _joker_at.found:
		return
	var limit := stack_limit((_joker_at.card as JokerCard).joker)
	var now := clampi(stack, 1, limit)
	set_stack(now + 1 if now < limit else 1)


## The biggest stack [param joker] is shown as: as many as it stacks to, GAME.md 8.8, whatever the
## profile held of it, which is said beside the field and in the pane; one for a joker that does
## not stack.
func stack_limit(joker: Joker) -> int:
	if not joker.stackable:
		return 1
	if joker.most > 0:
		return joker.most
	return maxi(_settings.profile.catalog.best_stack(joker.id), 1)


## The cell for [param id] on whichever page has it, or null.
func cell_of(id: StringName) -> CatalogCell:
	for grid: CardGrid in [joker_grid, item_grid]:
		var cell := grid.get_node_or_null(NodePath(String(id))) as CatalogCell
		if cell != null:
			return cell
	return null


## The keys of the switch and the field, heard before the cursor would take Tab to move on: the
## details key is Detailed, and the hand's button steps the stack on, on the jokers' page.
func _input(event: InputEvent) -> void:
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_show_binds()
	if _closing or tabs.current_tab != 0 or event.is_echo():
		return
	if event.is_action_pressed(DETAILED_ACTION):
		set_detailed(not detailed)
	elif event.is_action_pressed(STACK_ACTION):
		step_stack()
	else:
		return
	get_viewport().set_input_as_handled()


## The shoulders turn the pages and B on a pad, or Escape, is Back. Nothing gets past the dialog to
## the screen under it.
func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	var viewport := get_viewport()
	var pad := event as InputEventJoypadButton
	var shoulders := [SettingsScreen.TAB_BACK, SettingsScreen.TAB_ON]
	if pad != null and pad.pressed and pad.button_index in shoulders:
		switch_tab(-1 if pad.button_index == SettingsScreen.TAB_BACK else 1)
	elif event.is_action_pressed(&"ui_cancel"):
		MenuTheme.back_sound()
		close()
	elif not (event is InputEventKey or event is InputEventJoypadButton):
		return
	viewport.set_input_as_handled()


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


## The pane over nearly all the screen, the shade showing round it, or over all of it short of
## room, see [method fill_screen]; and its head as the room has it.
func _fit() -> void:
	var room := _root.size
	fill_screen(_pane, _around, room)
	_lay_head(room.y < SHORT)


## A dialog's [param pane] in [param around] on a screen [param room] big: short of room, see
## [constant SHORT], as a phone's is, it fills the screen from edge to edge, its corners square as a
## ticket's are where it runs off the screen, and holds what is in it only [constant FULL_INSIDE]
## in from its edge, each well in it its cards or its map [constant FULL_WELL_INSET] in and
## [constant FULL_GAP] from the column beside it, so that has all the screen there is. Otherwise
## it stands over nearly all of it, [constant AROUND] of its shorter side left round it for the
## shade to show and a click there to put it away.
static func fill_screen(pane: PanelContainer, around: MarginContainer, room: Vector2) -> void:
	var full := room.y < SHORT
	var margin := 0.0 if full else maxf(minf(room.x, room.y) * AROUND, AROUND_LEAST)
	for side: String in ["left", "right", "top", "bottom"]:
		around.add_theme_constant_override("margin_%s" % side, int(margin))
	var look := pane.get_theme_stylebox(&"panel") as TicketStyle
	# Changed only as it turns, as each change has the ticket worked out again.
	if look == null or look.notch_top != full:
		return
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		look.set_content_margin(
			side, FULL_INSIDE if full else MenuTheme.PANE_INSET + MenuTheme.PANE_GAP
		)
	look.notch_top = not full
	look.notch_bottom = not full
	look.notch_left = not full
	look.notch_right = not full
	for found: Node in pane.find_children("*", "MarginContainer", true, false):
		var well := found as ListBox.Well
		if well == null:
			continue
		well.set_inset(FULL_WELL_INSET if full else ListBox.INSET)
		var row := well.get_parent() as HBoxContainer
		if row != null:
			row.add_theme_constant_override("separation", int(FULL_GAP if full else PANE_GAP))


## Short of room, see [constant SHORT]: the title at the left of the head and Back at its right, as
## the settings have them, GAME.md 8.5, the story's line between them, and no foot. Otherwise the
## title over the middle, the line under it, and Back at the right of the foot.
func _lay_head(short: bool) -> void:
	if short == (back.get_parent() == _head):
		return
	# Moved, Back leaves the tree for a moment, and the cursor with it.
	var had_cursor := back.has_focus()
	_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if short else HORIZONTAL_ALIGNMENT_CENTER
	)
	var column := _head.get_parent()
	if _kept != null:
		_kept.reparent(_head if short else column, false)
		if not short:
			column.move_child(_kept, _head.get_index() + 1)
		_kept.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT if short else HORIZONTAL_ALIGNMENT_CENTER
		)
		_kept.size_flags_horizontal = (Control.SIZE_EXPAND_FILL if short else Control.SIZE_FILL)
		_title.size_flags_horizontal = Control.SIZE_FILL if short else Control.SIZE_EXPAND_FILL
	back.reparent(_head if short else _foot_row, false)
	_foot_row.visible = not short
	if had_cursor:
		back.grab_focus()


func _jokers_page() -> Control:
	var catalog := _settings.profile.catalog
	joker_grid = CardGrid.new()
	for joker: Joker in jokers_in_order():
		var taken := catalog.found(joker.id)
		var cell := CatalogCell.holding(
			joker.id,
			taken,
			func() -> Control: return JokerCard.create(joker) if taken else CardBack.new()
		)
		cell.set_fresh(taken and catalog.is_fresh(joker.id))
		cell.looked_at.connect(_on_joker_looked_at)
		joker_grid.add_child(cell)
	joker_pane = JokerDetail.new()
	joker_preview = CardPreview.new()
	var page := _page(JOKERS, joker_grid, joker_pane, joker_preview, NO_JOKERS)
	# Two rows of three, so the switch and the stack's field stand one over the other: what each is,
	# the control, and what is said after it.
	var switches := GridContainer.new()
	switches.name = "Switches"
	switches.columns = 3
	switches.add_theme_constant_override("h_separation", SWITCHES_ACROSS)
	switches.add_theme_constant_override("v_separation", SWITCHES_DOWN)
	switches.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	(page.get_node("Side/Column") as Control).add_child(switches)
	switches.add_child(_name(DETAILED))
	detailed_switch = _switch(detailed, set_detailed)
	detailed_switch.name = "Detailed"
	switches.add_child(detailed_switch)
	switches.add_child(Control.new())
	switches.add_child(_name(STACK))
	stepper = StackStepper.new()
	stepper.name = "Stack"
	stepper.stepped.connect(
		func(by: int) -> void:
			if _joker_at != null and _joker_at.found:
				var joker: Joker = (_joker_at.card as JokerCard).joker
				set_stack(clampi(stack, 1, stack_limit(joker)) + by)
	)
	switches.add_child(stepper)
	stack_note = Label.new()
	stack_note.name = "Held"
	Type.text(stack_note, Type.LABEL, JokerDetail.hint_ink())
	switches.add_child(stack_note)
	return page


## What the switch or the field beside it is, in the words a switch's own would be.
func _name(words: String) -> Label:
	var named := Label.new()
	named.text = words
	named.custom_minimum_size.x = NAMES_WIDE
	Type.strong(named, Type.BODY, HouseTheme.WORDS)
	return named


func _items_page() -> Control:
	var catalog := _settings.profile.catalog
	item_grid = CardGrid.new()
	for item: PowerUp in items_in_order():
		var taken := catalog.found(item.id)
		var cell := CatalogCell.holding(
			item.id,
			taken,
			func() -> Control: return ItemCard.create(item) if taken else CardBack.new()
		)
		cell.set_fresh(taken and catalog.is_fresh(item.id))
		cell.looked_at.connect(_on_item_looked_at)
		item_grid.add_child(cell)
	item_pane = PowerUpDetail.new()
	item_preview = CardPreview.new()
	return _page(ITEMS, item_grid, item_pane, item_preview, NO_ITEMS)


## A page called [param named]: [param grid] in the well, scrolling down it where the cards are more
## than it has room for, and in the column beside it, with room round them, [param preview] over
## [param pane], the one taking whatever room the column has left. With none of its cards found
## yet, [param none] in the middle of the well in place of them, and no column, there being nothing
## to describe.
func _page(
	named: String, grid: CardGrid, pane: Control, preview: CardPreview, none: String
) -> HBoxContainer:
	var page := HBoxContainer.new()
	page.name = named
	page.add_theme_constant_override("separation", int(PANE_GAP))
	var well := ListBox.Well.new()
	well.name = "Well"
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(well)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	well.add_child(scroll)
	# On a touch screen a swipe scrolls the cards and only a tap picks one.
	TouchScroll.attach(scroll)
	grid.name = "Grid"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	var found := false
	for cell: Node in grid.get_children():
		found = found or (cell as CatalogCell).found
	var empty := Label.new()
	empty.name = "Empty"
	empty.text = none
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Type.text(empty, Type.BODY, HouseTheme.QUIET)
	empty.visible = not found
	well.add_child(empty)
	_empty.append(empty)
	scroll.visible = found
	var side := MarginContainer.new()
	side.name = "Side"
	side.custom_minimum_size.x = PANE_ROOM
	for edge: String in ["left", "right", "top", "bottom"]:
		side.add_theme_constant_override("margin_%s" % edge, PANE_AROUND)
	page.add_child(side)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", SWITCHES_UNDER)
	side.add_child(column)
	preview.name = "Preview"
	column.add_child(preview)
	pane.name = "Pane"
	column.add_child(pane)
	side.visible = found
	var sizing := _size_preview.bind(column, preview, pane)
	column.resized.connect(sizing)
	pane.resized.connect(sizing)
	return page


## The large picture's room in [param column]: whatever the column has over [param pane] and what
## is under it, the pane counted as at least [constant PANE_KEPT] tall, so the picture's size does
## not move with what the pane says, nor its top with anything; and no more than the picture takes,
## so the pane stands right under it.
func _size_preview(column: VBoxContainer, preview: CardPreview, pane: Control) -> void:
	var gap := float(column.get_theme_constant(&"separation"))
	var rest := 0.0
	for child: Node in column.get_children():
		var control := child as Control
		if control == null or control == preview or not control.visible:
			continue
		var tall := control.size.y
		if control == pane:
			tall = maxf(tall, PANE_KEPT)
		rest += tall + gap
	var room := clampf(floorf(column.size.y - rest), 0.0, CardPreview.MOST)
	if not is_equal_approx(preview.custom_minimum_size.y, room):
		preview.custom_minimum_size.y = room


## The switch under a joker's pane, on as [param on] says, calling [param flip] when it is flipped,
## its words beside it rather than on it. Left to the mouse and a finger: keys and a pad have its
## bind, see [method _input], drawn in the row of tabs.
func _switch(on: bool, flip: Callable) -> CheckButton:
	var switch := MenuTheme.toggle(on)
	switch.focus_mode = Control.FOCUS_NONE
	switch.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# No room round the picture, the way the stack's field has none, so the two line up.
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		switch.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	switch.toggled.connect(flip)
	return switch


## Each tab says how many of its page were found, with a gold tick once all of them were.
func _count_tabs() -> void:
	var catalog := _settings.profile.catalog
	var pages: Array[Array] = [[JOKERS, ids_of(CATALOG.jokers)], [ITEMS, ids_of(items_in_order())]]
	for i: int in pages.size():
		var ids: Array[StringName] = pages[i][1]
		var found := catalog.found_of(ids)
		# Nothing found yet is no count: the page says how to unlock it instead.
		var named: String = pages[i][0]
		tabs.set_tab_title(i, named if found == 0 else COUNT % [named, found, ids.size()])
		tabs.set_tab_icon(i, MenuTheme.tick() if found >= ids.size() else null)
		tab_bar.set_tab_title(i, tabs.get_tab_title(i))
		tab_bar.set_tab_icon(i, tabs.get_tab_icon(i))
	_tag_tabs()


## The ids of each page's cards, the jokers' and the power-ups', in the order of the tabs.
static func page_ids() -> Array[Array]:
	return [ids_of(CATALOG.jokers), ids_of(items_in_order())]


## Each tab wears the NEW tag while a card found on its page has not been looked at yet, as the
## cards themselves do, so a new one on the other page is seen without turning to it.
func _tag_tabs() -> void:
	var catalog := _settings.profile.catalog
	var pages := page_ids()
	for i: int in pages.size():
		var fresh := false
		for id: StringName in pages[i]:
			if catalog.found(id) and catalog.is_fresh(id):
				fresh = true
				break
		var worn := tab_tags[i]
		if fresh == (worn != null):
			continue
		if worn != null:
			worn.queue_free()
			tab_tags[i] = null
			continue
		var tag := CatalogCell.new_tag()
		tag.name = "New%d" % i
		tag.set_anchors_preset(Control.PRESET_TOP_LEFT)
		tag.resized.connect(_place_tab_tags)
		tab_bar.add_child(tag)
		tab_tags[i] = tag
	_place_tab_tags.call_deferred()


## Each tab's tag hung over its tab's top right corner, as a card's is over the card's.
func _place_tab_tags() -> void:
	if tab_bar == null:
		return
	for i: int in tab_tags.size():
		var tag := tab_tags[i]
		if tag == null or not is_instance_valid(tag) or i >= tab_bar.tab_count:
			continue
		var tab := tab_bar.get_tab_rect(i)
		tag.position = Vector2(
			tab.end.x + CatalogCell.NEW_OUT.x - tag.size.x, tab.position.y + CatalogCell.NEW_OUT.y
		)


## The row of tabs over the pages, and at its right end the gamepad's binds, the switches' and the
## shoulder buttons that turn the pages, shown only while a gamepad is plugged in, as the
## settings' are.
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
				switch_tab(tab - tabs.current_tab)
	)
	tabs.tab_changed.connect(
		func(tab: int) -> void:
			if tab_bar.current_tab != tab:
				tab_bar.current_tab = tab
	)
	row.add_child(tab_bar)
	tab_bar.resized.connect(_place_tab_tags)
	switch_hint = Control.new()
	switch_hint.name = "SwitchHint"
	row.add_child(switch_hint)
	tab_hint = _tab_hint()
	tab_hint.name = "TabHint"
	tab_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tab_hint)
	return row


func _on_pad_plugged(_device: int, _connected: bool) -> void:
	_show_binds()


## The binds in the row of tabs: the shoulder buttons while a gamepad is plugged in, as the
## settings', and on the jokers' page, where the switch and the field are, their keys while keys are
## in hand and their pad buttons otherwise while a gamepad is plugged in; none for the mouse alone.
func _show_binds() -> void:
	var pad := SettingsScreen.pad_plugged_in()
	tab_hint.visible = pad
	var keys := _keyboard and not _pointer
	var wanted := "keys" if keys else ("pad" if pad else "")
	if wanted != _binds_for and not wanted.is_empty():
		var row := switch_hint.get_parent()
		var at := switch_hint.get_index()
		switch_hint.name = "Gone"
		switch_hint.hide()
		switch_hint.queue_free()
		switch_hint = _switch_hint(keys)
		switch_hint.name = "SwitchHint"
		switch_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(switch_hint)
		row.move_child(switch_hint, at)
	_binds_for = wanted if not wanted.is_empty() else _binds_for
	switch_hint.visible = not wanted.is_empty() and tabs.current_tab == 0 and not is_empty(0)


func _on_joker_looked_at(cell: CatalogCell) -> void:
	_joker_at = cell
	_describe_joker(cell)
	_look_at(cell)


func _on_item_looked_at(cell: CatalogCell) -> void:
	_item_at = cell
	var item_card := cell.card as ItemCard
	if item_card != null:
		item_preview.show_item(item_card.item)
	else:
		item_preview.show_unknown()
	if not cell.found:
		item_pane.show_unknown(NOT_FOUND, _until_added(USE_ONE, NOT_ON_TABLES, cell.id))
		item_pane.set_hints(null)
	else:
		var item: PowerUp = (cell.card as ItemCard).item
		item_pane.show_item(item, facts_of(item))
		item_pane.set_hints(_foot(used_words(_settings.profile.catalog.times(cell.id))))
	_look_at(cell)


## [param under] for a card or item never found, and for one the profile's loyalty program has
## yet to add, [param line] after it, naming the program and the bet that adds it, GAME.md 8.9.
func _until_added(under: String, line: String, id: StringName) -> String:
	var adder := Loyalty.adder_of(id)
	if adder == null or _settings.profile.loyalty.has_won(adder.id):
		return under
	var program: String = StoryLines.at(StoryLines.PROGRAM, Story.stage_here())
	return under + "\n" + line % [program, Loyalty.bet_of(adder)]


func _describe_joker(cell: CatalogCell) -> void:
	if not cell.found:
		joker_pane.show_unknown(NOT_FOUND, _until_added(TAKE_ONE, NOT_DEALT, cell.id))
		joker_pane.set_hints(null)
		_show_stack(0, 0, "")
		joker_preview.show_unknown()
		return
	var joker: Joker = (cell.card as JokerCard).joker
	joker_preview.show_joker(joker)
	var limit := stack_limit(joker)
	var copies := clampi(stack, 1, limit)
	var held := HELD_UP_TO % _settings.profile.catalog.best_stack(joker.id)
	_show_stack(copies, limit, held if joker.stackable else NO_STACK)
	joker_pane.show_joker(joker, copies, false, detailed)
	var taken := taken_words(_settings.profile.catalog.times(cell.id))
	joker_pane.set_hints(_foot(taken + FOOT_JOIN + held if joker.stackable else taken))


## The stack's field showing [param copies] of at most [param limit], or nothing for none, with
## [param said] after it.
func _show_stack(copies: int, limit: int, said: String) -> void:
	stepper.show_stack(copies, limit)
	stack_note.text = said


## The pane's foot: [param words] of how many times what is in it was taken or used.
func _foot(words: String) -> Label:
	var line := Label.new()
	line.name = "Taken"
	line.text = words
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.text(line, Type.LABEL, JokerDetail.hint_ink())
	return line


## The cursor has come to [param cell]: no longer new.
func _look_at(cell: CatalogCell) -> void:
	if cell.is_fresh():
		cell.set_fresh(false)
		_looked = _settings.profile.catalog.look_at(cell.id) or _looked
		_tag_tabs()


## The NEW tags gone are kept in the profile.
func _keep_looks() -> void:
	if _looked:
		_looked = false
		_settings.save_to_disk()


## The stage the dialog is for: the profile playing's, or the one a test or a debug build asks for.
func _stage() -> int:
	if Story.override >= 0:
		return Story.stage_here()
	return Story.shown_of(_settings.profile)


func _focus_first() -> void:
	if not is_inside_tree() or _closing:
		return
	_focus_page()


## The cursor on the card the page showing last had under it, or its first; or on Back for a page
## with nothing found on it yet, which has no cards to go to.
func _focus_page() -> void:
	var index := tabs.current_tab
	if is_empty(index):
		back.grab_focus()
		return
	var cell := _joker_at if index == 0 else _item_at
	if cell == null:
		var grid := joker_grid if index == 0 else item_grid
		cell = grid.get_child(0) as CatalogCell
	cell.grab_focus()


## The binds of the switch and the field, each its key on a [param keyboard] or its pad button, and
## its word.
func _switch_hint(keyboard: bool) -> HBoxContainer:
	var ink := SettingsScreen.TAB_HINT_INK
	var size := SettingsScreen.TAB_HINT_SIZE
	var parts: Array = [
		InputGlyph.of_action(DETAILED_ACTION, keyboard, ink, size),
		InputGlyph.of_action(STACK_ACTION, keyboard, ink, size),
	]
	return InputHint.row("%s " + DETAILED + "   %s " + STACK, parts, ink, size)


## The shoulder buttons, drawn, without words: beside the tabs they say what they do.
func _tab_hint() -> HBoxContainer:
	var ink := SettingsScreen.TAB_HINT_INK
	var size := SettingsScreen.TAB_HINT_SIZE
	var parts: Array = []
	for button: int in [SettingsScreen.TAB_BACK, SettingsScreen.TAB_ON]:
		var press := InputEventJoypadButton.new()
		press.button_index = button as JoyButton
		parts.append(InputGlyph.of_event(press, ink, size))
	return InputHint.row("%s %s", parts, ink, size)
