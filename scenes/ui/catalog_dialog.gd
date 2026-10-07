class_name CatalogDialog
extends CanvasLayer
## The catalog of GAME.md 8.8: every joker and every power-up the profile playing ever took, a page
## each, the ones never taken lying face down. A large dialog over whatever screen opens it, the
## title's for now: a shade over the screen and the house's pane over nearly all of it, on a layer
## of its own over a room's pause menu too, so it can be laid over any screen, and Back or a click
## beside it puts it away again with the cursor back where it was.
##
## The cards fill a grid on the left of each page, see [CardGrid], and the card under the cursor
## lifts and is described in the pane on the right: a joker's in the pane a match describes it in,
## [JokerDetail], with the details the hand shows only for the key held, and Full stack for how a
## whole stack of it reads; an item's in [PowerUpDetail], with the numbers no match shows. Each tab
## says how many of how many were found. Read only, but for the NEW tags, which go as the cursor
## comes to them and are kept gone as the dialog is put away.

## Put away, the cursor back where it was.
signal put_away

## Over a room's pause menu, under the notices and the loading screen.
const LAYER := PauseMenu.LAYER + 5
const TITLE := "Catalog"
const JOKERS := "Jokers"
const ITEMS := "Power-ups"
## A tab's words: the page and how many of how many it has found.
const COUNT := "%s  %d/%d"
## What a card face down says, and how many times one face up was taken.
const NOT_FOUND := "Not found yet"
const TAKE_ONE := "Take one in a match to read it here."
const PICK_ONE := "Pick one up in a match to read it here."
const TAKEN_ONCE := "Taken once"
const TAKEN := "Taken %d times"
const FULL_STACK := "Full stack"
## The line of facts that says which set an item comes in, in the lobby's words, GAME.md 9.6.
const SET := "Set"
const BASIC_SET := "Basic items"
const LATER_SET := "All items only"
## How much of the screen is left round the pane, a share of its shorter side and at least a few
## pixels, so the shade shows round it and a click there can put it away.
const AROUND := 0.04
const AROUND_LEAST := 16.0
const SHADE := Color(0.0, 0.0, 0.0, 0.55)
## The room between the grid and the pane, and how wide the pane's column is kept.
const PANE_GAP := 32.0
const PANE_ROOM := JokerDetail.WIDTH + 44.0
## How far past their own size the power-ups' cards may grow: there are a third as many.
const ITEMS_MOST := 1.3

const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const FIRST: PowerUpTable = preload("res://data/powerups/first_set.tres")
const LATER: PowerUpTable = preload("res://data/powerups/later_set.tres")

var tabs: TabContainer
## The tabs drawn in a row of their own, the shoulder buttons that turn them at its right end while
## a gamepad is plugged in, as the settings have them, GAME.md 8.5.
var tab_bar: TabBar
var tab_hint: Control
var joker_grid: CardGrid
var item_grid: CardGrid
var joker_pane: JokerDetail
var item_pane: PowerUpDetail
var full_stack: CheckButton
var back: Button
## Whether the jokers that stack are shown as their whole stack, see [member full_stack].
var stacked := false

var _settings: Settings
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
var _closing := false
## Whether the mouse is in hand, which has no binds drawn on the buttons, see [ButtonBinds].
var _pointer := false
var _keyboard := true


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


## What a pane's foot says of how many times something was taken.
static func taken_words(times: int) -> String:
	return TAKEN_ONCE if times == 1 else TAKEN % times


## The debug build's catalog argument, `++ --catalog-all`: every joker and power-up taken once more
## by the profile playing in [param settings], the ones not taken before new, and kept. Nothing in a
## released game.
static func read_arguments(args: PackedStringArray, settings: Settings) -> void:
	if not OS.is_debug_build() or "--catalog-all" not in args:
		return
	for joker: Joker in CATALOG.jokers:
		settings.profile.catalog.take_joker(joker.id)
	for item: PowerUp in items_in_order():
		settings.profile.catalog.take_item(item.id)
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
	column.add_child(MenuTheme.title(TITLE, Type.TITLE))
	# Whose record this is, as the story goes, STORY.md 6.6a.
	var kept := str(StoryLines.at(StoryLines.CATALOG_LINE, _stage()))
	if not kept.is_empty():
		var line := MenuTheme.subtitle(kept, Type.LABEL)
		line.name = "Kept"
		column.add_child(line)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.tabs_visible = false
	MenuTheme.tabs(tabs)
	tabs.add_child(_jokers_page())
	tabs.add_child(_items_page())
	column.add_child(_tabs_row())
	column.add_child(tabs)
	_count_tabs()
	var foot := HBoxContainer.new()
	column.add_child(foot)
	var room := Control.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(room)
	back = MenuTheme.button("Back")
	back.name = "Back"
	back.custom_minimum_size.x = 200.0
	back.pressed.connect(close)
	foot.add_child(back)
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
	var cell := _joker_at if tabs.current_tab == 0 else _item_at
	if cell == null:
		var grid := joker_grid if tabs.current_tab == 0 else item_grid
		cell = grid.get_child(0) as CatalogCell
	cell.grab_focus()


## Shows every joker that stacks as its whole stack, or as one copy, see [member stacked].
func set_stacked(on: bool) -> void:
	stacked = on
	full_stack.set_pressed_no_signal(on)
	if _joker_at != null:
		_describe_joker(_joker_at)


## The cell for [param id] on whichever page has it, or null.
func cell_of(id: StringName) -> CatalogCell:
	for grid: CardGrid in [joker_grid, item_grid]:
		var cell := grid.get_node_or_null(NodePath(String(id))) as CatalogCell
		if cell != null:
			return cell
	return null


## The shoulders turn the pages, the details key is Full stack, and B on a pad, or Escape, is Back.
## Nothing gets past the dialog to the screen under it.
func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	var viewport := get_viewport()
	var pad := event as InputEventJoypadButton
	var shoulders := [SettingsScreen.TAB_BACK, SettingsScreen.TAB_ON]
	if pad != null and pad.pressed and pad.button_index in shoulders:
		switch_tab(-1 if pad.button_index == SettingsScreen.TAB_BACK else 1)
	elif event.is_action_pressed(InputActions.DETAILS) and not event.is_echo():
		if tabs.current_tab == 0:
			set_stacked(not stacked)
	elif event.is_action_pressed(&"ui_cancel"):
		Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
		close()
	elif not (event is InputEventKey or event is InputEventJoypadButton):
		return
	viewport.set_input_as_handled()


## The binds on the buttons follow what is in hand: none for the mouse, see [ButtonBinds].
func _input(event: InputEvent) -> void:
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	if pointer != _pointer or keyboard != _keyboard:
		_pointer = pointer
		_keyboard = keyboard
		_show_binds()


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


## The pane over nearly all the screen, the shade showing round it.
func _fit() -> void:
	var room := _root.size
	var around := maxf(minf(room.x, room.y) * AROUND, AROUND_LEAST)
	for side: String in ["left", "right", "top", "bottom"]:
		_around.add_theme_constant_override("margin_%s" % side, int(around))


func _jokers_page() -> Control:
	var page := HBoxContainer.new()
	page.name = JOKERS
	page.add_theme_constant_override("separation", int(PANE_GAP))
	var catalog := _settings.profile.catalog
	joker_grid = _grid()
	page.add_child(joker_grid)
	for joker: Joker in jokers_in_order():
		var taken := catalog.found(joker.id)
		var face: Control = JokerCard.create(joker) if taken else CardBack.new()
		var cell := CatalogCell.holding(joker.id, taken, face)
		cell.set_fresh(taken and catalog.is_fresh(joker.id))
		cell.looked_at.connect(_on_joker_looked_at)
		joker_grid.add_child(cell)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = PANE_ROOM
	side.add_theme_constant_override("separation", 18)
	page.add_child(side)
	joker_pane = JokerDetail.new()
	joker_pane.name = "Pane"
	side.add_child(joker_pane)
	full_stack = MenuTheme.toggle(stacked)
	full_stack.name = "FullStack"
	full_stack.text = FULL_STACK
	Type.set_font(full_stack, Type.STRONG, Type.BODY)
	full_stack.focus_mode = Control.FOCUS_NONE
	full_stack.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	full_stack.toggled.connect(set_stacked)
	ButtonBinds.mark(full_stack, InputActions.DETAILS)
	side.add_child(full_stack)
	return page


func _items_page() -> Control:
	var page := HBoxContainer.new()
	page.name = ITEMS
	page.add_theme_constant_override("separation", int(PANE_GAP))
	var catalog := _settings.profile.catalog
	item_grid = _grid()
	item_grid.most = ITEMS_MOST
	page.add_child(item_grid)
	for item: PowerUp in items_in_order():
		var taken := catalog.found(item.id)
		var face: Control = ItemCard.create(item) if taken else CardBack.new()
		var cell := CatalogCell.holding(item.id, taken, face)
		cell.set_fresh(taken and catalog.is_fresh(item.id))
		cell.looked_at.connect(_on_item_looked_at)
		item_grid.add_child(cell)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = PANE_ROOM
	page.add_child(side)
	item_pane = PowerUpDetail.new()
	item_pane.name = "Pane"
	side.add_child(item_pane)
	return page


func _grid() -> CardGrid:
	var grid := CardGrid.new()
	grid.name = "Grid"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return grid


## Each tab says how many of its page were found, with a gold tick once all of them were.
func _count_tabs() -> void:
	var catalog := _settings.profile.catalog
	var pages: Array[Array] = [[JOKERS, ids_of(CATALOG.jokers)], [ITEMS, ids_of(items_in_order())]]
	for i: int in pages.size():
		var ids: Array[StringName] = pages[i][1]
		var found := catalog.found_of(ids)
		tabs.set_tab_title(i, COUNT % [pages[i][0], found, ids.size()])
		tabs.set_tab_icon(i, MenuTheme.tick() if found >= ids.size() else null)
		tab_bar.set_tab_title(i, tabs.get_tab_title(i))
		tab_bar.set_tab_icon(i, tabs.get_tab_icon(i))


## The row of tabs over the pages, and at its right end the shoulder buttons that turn them, shown
## only while a gamepad is plugged in, as the settings' are.
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
	tab_hint = _tab_hint()
	tab_hint.name = "TabHint"
	tab_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tab_hint.visible = SettingsScreen.pad_plugged_in()
	row.add_child(tab_hint)
	return row


func _on_pad_plugged(_device: int, _connected: bool) -> void:
	if tab_hint != null:
		tab_hint.visible = SettingsScreen.pad_plugged_in()


func _on_joker_looked_at(cell: CatalogCell) -> void:
	_joker_at = cell
	_describe_joker(cell)
	_look_at(cell)


func _on_item_looked_at(cell: CatalogCell) -> void:
	_item_at = cell
	if not cell.found:
		item_pane.show_unknown(NOT_FOUND, PICK_ONE)
		item_pane.set_hints(null)
	else:
		var item: PowerUp = (cell.card as ItemCard).item
		item_pane.show_item(item, facts_of(item))
		item_pane.set_hints(_foot(cell.id))
	_look_at(cell)


func _describe_joker(cell: CatalogCell) -> void:
	if not cell.found:
		joker_pane.show_unknown(NOT_FOUND, TAKE_ONE)
		joker_pane.set_hints(null)
		return
	var joker: Joker = (cell.card as JokerCard).joker
	var copies := maxi(joker.most, 1) if stacked and joker.stackable else 1
	joker_pane.show_joker(joker, copies, false, true)
	joker_pane.set_hints(_foot(cell.id))


## The pane's foot: how many times what is in it was taken.
func _foot(id: StringName) -> Label:
	var line := Label.new()
	line.name = "Taken"
	line.text = taken_words(_settings.profile.catalog.times(id))
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.text(line, Type.LABEL, JokerDetail.hint_ink())
	return line


## The cursor has come to [param cell]: no longer new.
func _look_at(cell: CatalogCell) -> void:
	if cell.is_fresh():
		cell.set_fresh(false)
		_looked = _settings.profile.catalog.look_at(cell.id) or _looked


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
	var first := joker_grid.get_child(0) as CatalogCell
	if first != null:
		first.grab_focus()


## The binds hung on Full stack while keys or a pad are in hand, on the page it is on.
func _show_binds() -> void:
	var buttons: Array[Button] = [full_stack]
	ButtonBinds.show(buttons, _keyboard, not _pointer and tabs.current_tab == 0)


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
