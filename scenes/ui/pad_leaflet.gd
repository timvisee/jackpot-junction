class_name PadLeaflet
extends Control
## The gamepad drawn whole, GAME.md 8.3b: How to hold the wheel, a blueprint of the Dept. of Karts'
## engineers, see [BlueprintArt], lying over nearly all the screen as the catalog does, dealt in and
## put away as its pane is, and over all of it on a short screen, with the pad drawn on it, see
## [PadDiagram],
## and a line from each of its buttons out to what it does as the player has it bound, the button's
## name under it as their pad prints it. Three sheets, driving, the jokers and the menus, their tabs
## cut from its top edge and turned with the page keys or a click, and Back a tab across from them.
## Up over the settings' Controls page, 8.5, and the room's menu, 3.8; the pad drawn is the one the
## player touched last, a generic one if they have touched none. Beside the page keys, a tab for the
## keyboard and one for each pad plugged in, numbered as the menus number them, or one stepping
## through the pads where there is no room for a tab each; the switch's key steps through them all,
## and Mine, a pad's View or N, turns it to the keyboard or the pad it was pressed on.

signal put_away

const TITLE := "How to hold the wheel"
const ENTRY := "Show controls"
## The settings' Controls page's row it is on, 8.5.
const ROW := "Overview"
## The switch between the keyboard's sheets and each pad's, and the words on its tabs: the
## keyboard's, and a pad's by its family, a generic pad's where none is plugged in.
const SWITCH := InputActions.MENU_VIEW
const SWITCH_WORDS: Array[String] = ["KEYBOARD", "GAMEPAD"]
const PAD_WORDS: Dictionary[PadFamily.Family, String] = {
	PadFamily.Family.GENERIC: "GAMEPAD",
	PadFamily.Family.XBOX: "XBOX",
	PadFamily.Family.PLAYSTATION: "PLAYSTATION",
	PadFamily.Family.PLAYSTATION_4: "PLAYSTATION 4",
	PadFamily.Family.NINTENDO: "NINTENDO",
	PadFamily.Family.STEAM_DECK: "STEAM DECK",
	PadFamily.Family.STEAM_CONTROLLER: "STEAM CONTROLLER",
}
## How small a switch tab is at the least, and the room beside its words: round them, for a pad's
## number in its ring before them, and for the dots of a tab stepping through the pads after them.
const SWITCH_SIZE := Vector2(186.0, SHEET_TOP)
const SWITCH_ROOM := 48.0
const NUMBER_ROOM := 30.0
const DOTS_STEP := 13.0
## What a switch tab is for, besides a pad by its id: the keyboard, a generic pad with none plugged
## in, and every pad in turn, see [member _stepping].
const KEYBOARD_TAB := -2
const ANY_PAD_TAB := -3
const STEP_TAB := -4
## The key that turns it to the keyboard or the pad it was pressed on, the dialogs' Next new: a
## pad's View, the left of its middle buttons, Select or Share as others print it, and N; and its
## words after the switch. Nothing in the blueprint is new.
const MINE := InputActions.MENU_NEXT_NEW
const MINE_WORDS := "MINE"
## What the sheet says of the keyboard drawn, as [constant FAMILY_WORDS] says of a pad.
const KEYBOARD_WORDS := "Your keyboard"
const PAGES: Array[String] = ["Driving", "Jokers", "Menus"]
## The room the pad and its words are laid out in, in the sheet's own units: the sheet is scaled so
## that this fits its pane, and is as wide and as tall as the pane at that scale, so it fills the
## pane whatever shape the screen is, with the pad and its words in its middle, see
## [method _fit_sheet]. How far down the pane the sheet's top edge is, the room over it the tabs'.
const SIZE := Vector2(1920.0, 1080.0)
const SHEET_TOP := 48.0
## The tabs: how far in from the sheet's left edge the first stands and how far on each next one,
## and how big each is, down to the sheet's top edge; and Back's, how far in from its right edge.
const TAB_FIRST := 60.0
const TAB_STEP := 240.0
const TAB_SIZE := Vector2(228.0, SHEET_TOP)
const BACK_SIZE := Vector2(200.0, SHEET_TOP)
const BACK_IN := 30.0
## Where the pad is drawn on the sheet and how big; how far out from it the words stand, how far the
## lines run level before them, and how close two lines of words come down a side.
const ART_SCALE := 0.66
const ART_TOP := 245.0
const COLUMN_OUT := 70.0
const ELBOW := 40.0
const ROW_GAP := 84.0
const LINE_WIDTH := 1.6
const INK := BlueprintArt.INK
const FAINT := BlueprintArt.FAINT
## What the sheet says of the pad drawn, by its family.
const FAMILY_WORDS: Dictionary[PadFamily.Family, String] = {
	PadFamily.Family.GENERIC: "Your controller",
	PadFamily.Family.XBOX: "Xbox controller",
	PadFamily.Family.PLAYSTATION: "PlayStation controller",
	PadFamily.Family.PLAYSTATION_4: "PlayStation 4 controller",
	PadFamily.Family.NINTENDO: "Nintendo controller",
	PadFamily.Family.STEAM_DECK: "Steam Deck",
	PadFamily.Family.STEAM_CONTROLLER: "Steam Controller",
}
## Which side of the pad each button's words stand: left, right, or over it for the middle ones.
const SIDES: Dictionary[StringName, int] = {
	&"lt": -1,
	&"lb": -1,
	&"ls": -1,
	&"dpad": -1,
	&"rt": 1,
	&"rb": 1,
	&"rs": 1,
	&"north": 1,
	&"east": 1,
	&"west": 1,
	&"south": 1,
	&"view": 0,
	&"menu": 0,
	&"touch": 0,
}
## The line from the left of the four under the thumb goes down round the bottom one first, in the
## drawing's pixels, rather than through the two right of it.
const AROUND: Dictionary[StringName, Vector2] = {&"west": Vector2(0.0, 150.0)}

var family := PadFamily.Family.GENERIC
## The pad drawn, by its id, or -1 for a pad of [member family] without one plugged in.
var pad := -1
## Whether the keyboard and the mouse are drawn, see [KeyboardDiagram], rather than the pad.
var keyboard := false
## Whether the first player drives the simple way, GAME.md 4.2, where the stick says the way to go.
var simple := false
var page := 0
var diagram: PadDiagram

var _shade: ColorRect
var _around: MarginContainer
var _pane: Control
var _sheet: Control
## Whether it fills the screen, short of room, rather than lying over it.
var _full := false
var _keys: Control
var _tabs: Array[Button] = []
var _back: Button
## The switch's tabs, what each is for, see [constant KEYBOARD_TAB], and the switch's key; none on a
## touch screen. The pads plugged in, numbered, see [method DeviceInput.numbered]; whether they
## share one tab stepping through them, there being no room for one each; and where the switch's
## band is down the room over the sheet.
var _switch: Array[Button] = []
var _switch_for: Array[int] = []
var _switch_key: Control
## Mine's glyph and its words after the switch, see [constant MINE].
var _mine: Array[Control] = []
var _pads: Array[int] = []
var _stepping := false
var _band := 0.0
var _from: Control
var _closing := false


## The button that puts the leaflet up over [param parent], for the keyboard where keys or the
## mouse were touched last, and otherwise for the pad touched last; shown wherever a pad may be in
## hand, which on a phone is only once one is plugged in, and not in the booth's demo, whose menu
## is kept to what a passer-by needs, GAME.md 9.8.
static func entry(parent: Node, size := Type.LARGE) -> Button:
	var button := MenuTheme.button(ENTRY, size)
	button.name = "PadLeafletButton"
	var pad_here := not TouchInput.enabled or not DeviceInput.pads().is_empty()
	button.visible = pad_here and not Demo.on
	button.pressed.connect(
		func() -> void:
			var simple_driving := Game.settings.drive_mode(0) == Settings.DRIVE_SIMPLE
			var keys := Game.last_input_keyboard and not TouchInput.enabled
			# The pad touched last, or the first plugged in before any was touched.
			var held := PadFamily.last_pad()
			if held < 0 and not DeviceInput.numbered().is_empty():
				held = DeviceInput.numbered()[0]
			open(parent, PadFamily.shown(), simple_driving, button, keys, held)
	)
	return button


## The Overview row of the settings' Controls page, 8.5, with the button in it: hidden where the
## button is.
static func row(parent: Node) -> HBoxContainer:
	var button := entry(parent, Type.BODY)
	var line := MenuTheme.row(ROW, button)
	line.visible = button.visible
	button.visible = true
	return line


## The leaflet up over [param parent] for a pad of [param for_family], the pad [param device] where
## one is given, or with [param keys] for the keyboard; the cursor back on [param from] once it is
## put away.
static func open(
	parent: Node,
	for_family: PadFamily.Family,
	simple_driving := false,
	from: Control = null,
	keys := false,
	device := -1
) -> PadLeaflet:
	var leaflet := PadLeaflet.new()
	leaflet.name = "PadLeaflet"
	leaflet.family = for_family
	leaflet.pad = device
	leaflet.keyboard = keys
	leaflet.simple = simple_driving
	leaflet._from = from
	parent.add_child(leaflet)
	return leaflet


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pads = DeviceInput.numbered()
	if _pads.has(pad):
		family = PadFamily.of_device(pad)
	else:
		pad = -1
	diagram = PadDiagram.of(family)
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = CatalogDialog.SHADE
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.gui_input.connect(_on_beside)
	add_child(_shade)
	_around = MarginContainer.new()
	_around.name = "Around"
	_around.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_around.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_around)
	# The pane the sheet lies in, which is what is dealt in and put away; the sheet in it is scaled,
	# which a container would undo, so the pane is a plain control.
	_pane = Control.new()
	_pane.name = "Pane"
	_pane.mouse_filter = Control.MOUSE_FILTER_STOP
	_pane.resized.connect(_fit_sheet)
	_around.add_child(_pane)
	_sheet = Control.new()
	_sheet.name = "Sheet"
	_sheet.size = SIZE
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sheet.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_sheet.draw.connect(_draw_sheet)
	_pane.add_child(_sheet)
	for i: int in PAGES.size():
		var tab := _tab_button("%d  ·  %s" % [i + 1, PAGES[i].to_upper()])
		tab.name = "Tab%d" % i
		tab.position = Vector2(TAB_FIRST + i * TAB_STEP, 0.0)
		tab.pressed.connect(_turn_to.bind(i))
		_tabs.append(tab)
	# The page keys beside the tabs, as the big dialogs have them, on their own dark chips, level
	# with the words on the tabs behind.
	_keys = DialogBinds.pages(Game.last_input_keyboard, Palette.CHIP_WHITE, 18)
	var keys_tall := _keys.get_combined_minimum_size().y
	var band := (SHEET_TOP + BlueprintArt.TAB_BEHIND) * 0.5
	_keys.position = Vector2(TAB_FIRST + PAGES.size() * TAB_STEP + 10.0, band - keys_tall * 0.5)
	_sheet.add_child(_keys)
	_back = _tab_button("BACK")
	_back.name = "Back"
	_back.size = BACK_SIZE
	_back.pressed.connect(close)
	ScreenReader.name(_back, "Back")
	var key := InputGlyph.of_action(&"ui_cancel", Game.last_input_keyboard, INK, 16)
	if key != null:
		key.position = Vector2(24.0, band - key.custom_minimum_size.y * 0.5)
		_back.add_child(key)
		(_back.get_theme_stylebox(&"normal") as StyleBoxEmpty).content_margin_left = 40.0
	if not TouchInput.enabled:
		_make_switch(band)
	_link_cursor()
	resized.connect(_fit)
	_fit()
	_fit_sheet()
	_turn_to(page, false)
	_tabs[page].grab_focus()
	MenuTheme.deal(_pane)


## The switch between the keyboard and the pads, small tabs after the page keys with its key
## before them, at [param band] down the room over the sheet: the keyboard's, then a tab for each
## pad plugged in, numbered, or one stepping through them all where they do not fit before Back;
## a generic pad's where none is plugged in.
func _make_switch(band: float) -> void:
	_band = band
	for each: Node in _switch:
		each.free()
	_switch.clear()
	_switch_for.clear()
	if _switch_key != null:
		_switch_key.free()
	for each: Control in _mine:
		each.free()
	_mine.clear()
	var x := TAB_FIRST + PAGES.size() * TAB_STEP + 10.0 + _keys.get_combined_minimum_size().x + 24.0
	_switch_key = InputGlyph.of_action(SWITCH, Game.last_input_keyboard, Palette.CHIP_WHITE, 18)
	if _switch_key != null:
		_switch_key.position = Vector2(x, band - _switch_key.custom_minimum_size.y * 0.5)
		_sheet.add_child(_switch_key)
		x += _switch_key.custom_minimum_size.x + 10.0
	var kinds: Array[int] = [KEYBOARD_TAB]
	kinds.append_array(_pads if not _pads.is_empty() else [ANY_PAD_TAB] as Array[int])
	_make_mine()
	var room := SIZE.x - BACK_IN - BACK_SIZE.x - 16.0 - x - _mine_wide()
	_stepping = _pads.size() > 1 and _wide(kinds) > room
	if _stepping:
		kinds = [KEYBOARD_TAB, STEP_TAB]
	for kind: int in kinds:
		var side := _switch_tab(kind)
		side.position = Vector2(x, 0.0)
		x += side.size.x + 8.0
		_switch.append(side)
		_switch_for.append(kind)
	_word_switch()
	# Mine after the tabs, level with the words on them, see [constant MINE].
	x += 8.0
	for each: Control in _mine:
		var tall := each.get_combined_minimum_size().y
		each.position = Vector2(x, band - tall * 0.5)
		x += each.get_combined_minimum_size().x + 6.0


## Mine's glyph and its words, see [constant MINE], placed by [method _make_switch].
func _make_mine() -> void:
	var key := InputGlyph.of_action(MINE, Game.last_input_keyboard, Palette.CHIP_WHITE, 18)
	if key != null:
		_sheet.add_child(key)
		_mine.append(key)
	var words := Label.new()
	words.name = "Mine"
	words.text = MINE_WORDS
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.strong(words, 18, FAINT)
	_sheet.add_child(words)
	_mine.append(words)


## How wide Mine's glyph and its words stand after the tabs.
func _mine_wide() -> float:
	var wide := 8.0
	for each: Control in _mine:
		wide += each.get_combined_minimum_size().x + 6.0
	return wide


## How wide the tabs for [param kinds] stand side by side, each as [method _switch_tab] makes it.
func _wide(kinds: Array[int]) -> float:
	var wide := 0.0
	for kind: int in kinds:
		var side := _switch_tab(kind)
		wide += side.size.x + 8.0
		side.free()
	return wide


## A switch tab for [param kind], see [constant KEYBOARD_TAB], as wide as its words and the room
## round them, its number's or its dots' room kept beside them.
func _switch_tab(kind: int) -> Button:
	var side := _tab_button(_switch_words(kind))
	side.name = "Gamepad"
	if kind == KEYBOARD_TAB:
		side.name = "Keyboard"
	elif kind >= 0:
		side.name = "Gamepad%d" % DeviceInput.number_of(kind)
	Type.set_font(side, Type.STRONG, 18)
	var plain := (side.get_theme_stylebox(&"normal") as StyleBoxEmpty).duplicate() as StyleBoxEmpty
	if kind >= 0 or kind == STEP_TAB:
		plain.content_margin_left = NUMBER_ROOM
	if kind == STEP_TAB:
		plain.content_margin_right = DOTS_STEP * _pads.size()
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"hover_pressed"]:
		side.add_theme_stylebox_override(state, plain)
	var words := side.get_combined_minimum_size().x
	if kind == STEP_TAB:
		for each: int in _pads:
			side.text = _switch_words(each)
			words = maxf(words, side.get_combined_minimum_size().x)
	side.size = Vector2(maxf(SWITCH_SIZE.x, words + SWITCH_ROOM), SWITCH_SIZE.y)
	side.pressed.connect(_on_switch.bind(kind))
	return side


## The words on a switch tab for [param kind]: a pad's by its family.
func _switch_words(kind: int) -> String:
	if kind == KEYBOARD_TAB:
		return SWITCH_WORDS[0]
	if kind == ANY_PAD_TAB:
		return SWITCH_WORDS[1]
	if kind == STEP_TAB:
		return _switch_words(pad if pad >= 0 else _pads[0])
	return PAD_WORDS[PadFamily.of_device(kind)]


## The stepping tab's words the pad's it shows, and every tab named for a screen reader.
func _word_switch() -> void:
	for i: int in _switch.size():
		var kind := _switch_for[i]
		_switch[i].text = _switch_words(kind)
		var shows := pad if kind == STEP_TAB else kind
		var named := _switch[i].text.capitalize()
		if shows >= 0:
			named = "Gamepad %d, %s" % [DeviceInput.number_of(shows), named]
		ScreenReader.name(_switch[i], named)


## A switch tab pressed: the keyboard's sheets, a pad's, or the next pad's.
func _on_switch(kind: int) -> void:
	if kind == KEYBOARD_TAB:
		show_keyboard(true)
	elif kind == ANY_PAD_TAB:
		show_keyboard(false)
	elif kind >= 0:
		show_pad(kind)
	elif keyboard and pad >= 0:
		show_pad(pad)
	else:
		show_pad(_pads[(_pads.find(pad) + 1) % _pads.size()])


## Whether switch tab [param i] is for what is drawn.
func _switch_shown(i: int) -> bool:
	var kind := _switch_for[i]
	if kind == KEYBOARD_TAB:
		return keyboard
	if kind >= 0:
		return not keyboard and kind == pad
	return not keyboard


## The keyboard's sheets for [param keys], or the pad's.
func show_keyboard(keys: bool) -> void:
	if keys == keyboard:
		return
	Audio.play_sfx(&"ui_move", MenuTheme.MOVE_DB, 0.0)
	keyboard = keys
	if not keys and pad < 0 and not _pads.is_empty():
		show_pad(_pads[0])
		return
	_turn_to(page, false)


## The sheets of the pad [param device], plugged in, drawn as its family is.
func show_pad(device: int) -> void:
	if device == pad and not keyboard:
		return
	if not keyboard:
		Audio.play_sfx(&"ui_move", MenuTheme.MOVE_DB, 0.0)
	keyboard = false
	pad = device
	family = PadFamily.of_device(device)
	diagram = PadDiagram.of(family)
	if not _switch.is_empty():
		_word_switch()
	_turn_to(page, false)


## The switch's key: on to the next of the keyboard and the pads in their order, and round again.
func _step_switch() -> void:
	if _pads.is_empty():
		show_keyboard(not keyboard)
	elif keyboard:
		show_pad(_pads[0])
	elif _pads.find(pad) + 1 < _pads.size():
		show_pad(_pads[_pads.find(pad) + 1])
	else:
		show_keyboard(true)


## A tab's button: its words alone, the tab itself drawn on the sheet, see [method _draw_sheet].
func _tab_button(words: String) -> Button:
	var tab := Button.new()
	tab.text = words
	tab.size = TAB_SIZE
	Type.set_font(tab, Type.STRONG, 21)
	# Its words level between the tops of the page's tab and of those behind.
	var plain := StyleBoxEmpty.new()
	plain.content_margin_top = BlueprintArt.TAB_BEHIND * 0.5
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"hover_pressed"]:
		tab.add_theme_stylebox_override(state, plain)
	# The cursor and the mouse light the tab up along its own edges, see [method BlueprintArt.tab],
	# rather than a frame round it, the house's or the glide's.
	tab.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	tab.add_to_group(FocusGlide.OWN)
	for told: Signal in [tab.focus_entered, tab.focus_exited, tab.mouse_entered, tab.mouse_exited]:
		told.connect(_sheet.queue_redraw)
	_sheet.add_child(tab)
	return tab


## Whether [param button] is lit up: the cursor on it, or the mouse while the mouse is in hand, so a
## pointer left resting on a tab lights no second one for a player on a pad.
static func _lit(button: Button) -> bool:
	return button.has_focus() or (button.is_hovered() and Game.last_input_pointer)


## The tabs' words: the page's in the sheet's white, the rest quieter, Back as the pages behind.
func _ink_tabs() -> void:
	for i: int in _tabs.size():
		var ink := INK if i == page else FAINT
		for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
			_tabs[i].add_theme_color_override(state, ink)
		_tabs[i].add_theme_color_override(&"font_focus_color", INK)
	for state: StringName in [&"font_color", &"font_pressed_color"]:
		_back.add_theme_color_override(state, FAINT)
	_back.add_theme_color_override(&"font_hover_color", INK)
	_back.add_theme_color_override(&"font_focus_color", INK)
	for i: int in _switch.size():
		var ink := INK if _switch_shown(i) else FAINT
		for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
			_switch[i].add_theme_color_override(state, ink)
		_switch[i].add_theme_color_override(&"font_focus_color", INK)


## The pane over nearly all the screen, the shade showing round it for a look round and a click
## there to put it away, or over all of it short of room, as the catalog's is, see
## [method CatalogDialog.fill_screen].
func _fit() -> void:
	var room := size if size != Vector2.ZERO else get_viewport_rect().size
	_full = room.y < CatalogDialog.SHORT
	var around := minf(room.x, room.y) * CatalogDialog.AROUND
	var margin := 0.0 if _full else maxf(around, CatalogDialog.AROUND_LEAST)
	for side: String in ["left", "right", "top", "bottom"]:
		_around.add_theme_constant_override("margin_%s" % side, int(margin))
	_sheet.queue_redraw()


## The sheet scaled so the pad and its words fit the pane, see [constant SIZE], and as big as the
## pane at that scale; Back at its right.
func _fit_sheet() -> void:
	if _back == null:
		return
	var scale := minf(_pane.size.x / SIZE.x, _pane.size.y / SIZE.y)
	if scale <= 0.0:
		return
	_sheet.scale = Vector2.ONE * scale
	_sheet.size = _pane.size / scale
	_back.position = Vector2(_sheet.size.x - BACK_IN - BACK_SIZE.x, 0.0)
	_sheet.queue_redraw()


## The cursor kept on the tabs, along them and on to Back and round again.
func _link_cursor() -> void:
	var row: Array[Button] = _tabs.duplicate()
	row.append_array(_switch)
	row.append(_back)
	for i: int in row.size():
		var button := row[i]
		button.focus_neighbor_left = button.get_path_to(row[posmod(i - 1, row.size())])
		button.focus_neighbor_right = button.get_path_to(row[posmod(i + 1, row.size())])
		button.focus_neighbor_top = button.get_path_to(button)
		button.focus_neighbor_bottom = button.get_path_to(button)


func _turn(by: int) -> void:
	_turn_to(posmod(page + by, PAGES.size()))


func _turn_to(to: int, sound := true) -> void:
	if sound and to != page:
		Audio.play_sfx(&"ui_move", MenuTheme.MOVE_DB, 0.0)
	page = to
	_ink_tabs()
	for i: int in _tabs.size():
		var said := _said(i)
		ScreenReader.name(_tabs[i], ScreenReader.line([TITLE, "%s page" % PAGES[i]]), said)
	if _tabs[page].is_inside_tree() and get_viewport().gui_get_focus_owner() in _tabs:
		_tabs[page].grab_focus()
	_sheet.queue_redraw()


## What the page [param on_page] says, for a screen reader: each button's words and its name.
func _said(on_page: int) -> String:
	var parts: PackedStringArray = []
	if keyboard:
		var by_key := KeyboardDiagram.said(on_page, simple)
		for at: int in by_key:
			var words: Array[String] = by_key[at]
			parts.append("%s: %s" % [PadSheets.joined(words), KeyboardDiagram.name_of(at)])
		return ". ".join(parts)
	var said := PadSheets.labels(on_page, simple, diagram)
	for spot: StringName in said:
		var words: Array[String] = said[spot]["words"]
		parts.append("%s: %s" % [PadSheets.joined(words), diagram.name_of(spot)])
	return ". ".join(parts)


## Mine pressed, [param event]: the keyboard's sheets for a key, or the sheets of the pad it was
## pressed on, one plugged in since it came up given its tab.
func _show_mine(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		show_keyboard(true)
		return
	var device := event.device
	if not (event is InputEventJoypadButton or event is InputEventAction):
		return
	if not DeviceInput.pads().has(device):
		return
	if not _pads.has(device):
		_pads = DeviceInput.numbered()
		if not _switch.is_empty():
			_make_switch(_band)
			_link_cursor()
			if get_viewport().gui_get_focus_owner() == null:
				_tabs[page].grab_focus()
	show_pad(device)


## The page keys turn it, and Back, the pause button or a right click put it away, before anything
## under it hears them.
func _input(event: InputEvent) -> void:
	if _closing:
		return
	var click := event as InputEventMouseButton
	if event.is_action_pressed(InputActions.MENU_PAGE_PREV):
		_turn(-1)
	elif event.is_action_pressed(InputActions.MENU_PAGE_NEXT):
		_turn(1)
	elif event.is_action_pressed(SWITCH) and not _switch.is_empty():
		_step_switch()
	elif event.is_action_pressed(MINE):
		_show_mine(event)
	elif event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(InputActions.PAUSE):
		MenuTheme.back_sound()
		close()
	elif click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Up over a screen, the screen under it hears nothing: no tab of the settings switches.
	if not _closing and (event is InputEventKey or event is InputEventJoypadButton):
		get_viewport().set_input_as_handled()


## A click or a tap beside the card puts it away.
func _on_beside(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed) or (touch != null and touch.pressed):
		get_viewport().set_input_as_handled()
		close()


## Puts it away the way the catalog goes, the cursor back where it was.
func close() -> void:
	if _closing:
		return
	_closing = true
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shades: Array[CanvasItem] = [_shade]
	MenuTheme.put_away(_pane, _gone, shades)


func _gone() -> void:
	put_away.emit()
	if _from != null and is_instance_valid(_from) and _from.is_visible_in_tree():
		_from.grab_focus()
	queue_free()


## Where the pad's drawing is laid among its words, see [constant SIZE], and how big.
func _art_rect() -> Rect2:
	var drawn := diagram.size * ART_SCALE
	return Rect2(Vector2((SIZE.x - drawn.x) * 0.5, ART_TOP), drawn)


## Where on the sheet the button at [param spot] is, or the point the line from it goes round.
func _on_card(spot: StringName, around := false) -> Vector2:
	var art := _art_rect()
	var at: Vector2 = diagram.spots[spot]
	if around:
		at += AROUND.get(spot, Vector2.ZERO)
	return art.position + at * ART_SCALE


## The tabs behind, the sheet with the page's tab cut from it, its marks and its foot, and the pad
## and its words in its middle.
func _draw_sheet() -> void:
	var paper := Rect2(0.0, SHEET_TOP, _sheet.size.x, _sheet.size.y - SHEET_TOP)
	if not _full:
		BlueprintArt.shadow(_sheet, paper)
	for i: int in PAGES.size():
		if i != page:
			BlueprintArt.tab(_sheet, _tabs[i].get_rect(), _lit(_tabs[i]))
	BlueprintArt.tab(_sheet, _back.get_rect(), _lit(_back))
	for i: int in _switch.size():
		BlueprintArt.tab(_sheet, _switch[i].get_rect(), _lit(_switch[i]), _switch_shown(i))
		_mark_switch(i)
	BlueprintArt.sheet(_sheet, paper, _tabs[page].get_rect(), _lit(_tabs[page]))
	BlueprintArt.folds(_sheet, paper)
	var inside := paper.grow(-BlueprintArt.BORDER)
	BlueprintArt.marks(_sheet, inside, Type.micro_font())
	_draw_foot(inside)
	_sheet.draw_set_transform(((_sheet.size - SIZE) * 0.5).round())
	if keyboard:
		KeyboardDiagram.draw(_sheet, page, simple)
		_sheet.draw_set_transform(Vector2.ZERO)
		return
	var art := _art_rect()
	diagram.draw(_sheet, art.position, ART_SCALE, Color(INK, 0.96))
	diagram.print_faces(_sheet, art.position, ART_SCALE, INK, Type.STRONG)
	var said := PadSheets.labels(page, simple, diagram)
	var sides: Array[Array] = [[], [], []]
	for spot: StringName in said:
		sides[SIDES.get(spot, 0) + 1].append(spot)
	_draw_column(sides[0], said, -1, art.position.x - COLUMN_OUT)
	_draw_column(sides[2], said, 1, art.end.x + COLUMN_OUT)
	_draw_over(sides[1], said)
	_sheet.draw_set_transform(Vector2.ZERO)


## Switch tab [param i]'s marks: a pad's number in a ring before its words, as the menus number it,
## and on the tab stepping through the pads a dot for each, the one drawn filled.
func _mark_switch(i: int) -> void:
	var kind := _switch_for[i]
	var shows := pad if kind == STEP_TAB else kind
	if shows < 0:
		return
	var rect := _switch[i].get_rect()
	var ink := INK if _switch_shown(i) or _lit(_switch[i]) else FAINT
	var level := rect.position.y + (rect.size.y + BlueprintArt.TAB_BEHIND * 0.5) * 0.5
	var ring := Vector2(rect.position.x + BlueprintArt.TAB_LEAN + 16.0, level)
	_sheet.draw_arc(ring, 10.0, 0.0, TAU, 24, ink, 1.6, true)
	var number := str(DeviceInput.number_of(shows))
	var font := Type.STRONG
	var wide := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	_sheet.draw_string(font, ring + Vector2(-wide * 0.5, 5.0), number, 0, -1, 14, ink)
	if kind != STEP_TAB:
		return
	for each: int in _pads.size():
		var dot := Vector2(
			rect.end.x - BlueprintArt.TAB_LEAN - 12.0 - DOTS_STEP * (_pads.size() - 1 - each), level
		)
		if _pads[each] == pad and not keyboard:
			_sheet.draw_circle(dot, 4.0, ink)
		else:
			_sheet.draw_arc(dot, 3.6, 0.0, TAU, 16, ink, 1.4, true)


## The sheet's foot: its scale bar on the left, and on the right what drawing and which sheet it
## is, in the fine print a title block has, its name among it, and in red pencil over that whose
## pad it is drawn for. The room over the sheet is the tabs' and Back's alone.
func _draw_foot(inside: Rect2) -> void:
	BlueprintArt.scale_bar(
		_sheet,
		inside.position + Vector2(40.0, inside.size.y - 40.0),
		Type.micro_font(),
		"ONE KEYBOARD" if keyboard else "ONE PAD"
	)
	var corner := inside.end - Vector2(24.0, 22.0)
	var sheet := (
		"DEPT. OF KARTS   ·   %s   ·   SHEET %d OF %d   ·   %s"
		% [TITLE.to_upper(), page + 1, PAGES.size(), PAGES[page].to_upper()]
	)
	_words(Type.micro_font(), sheet, corner, 14, FAINT, -1)
	var whose := "%s, as you have it bound" % (KEYBOARD_WORDS if keyboard else FAMILY_WORDS[family])
	_words(BayArt.hand_font(), whose, corner - Vector2(0.0, 26.0), 28, BlueprintArt.PENCIL, -1)


## The words down one side of the pad, [param side] of it at [param edge], each beside its button
## and moved apart only as far as they must be, and a line from each button out to its words.
func _draw_column(
	spots: Array, said: Dictionary[StringName, Dictionary], side: int, edge: float
) -> void:
	spots.sort_custom(
		func(a: StringName, b: StringName) -> bool: return _on_card(a, true).y < _on_card(b, true).y
	)
	var art := _art_rect()
	var heights: Array[float] = []
	for spot: StringName in spots:
		heights.append(_on_card(spot, true).y)
	_spread(heights, art.position.y + 10.0, art.end.y - 10.0)
	for i: int in spots.size():
		var spot: StringName = spots[i]
		var y := heights[i]
		var button := _on_card(spot)
		var elbow := Vector2(edge - side * ELBOW, y)
		var face := PadDiagram.FACES.has(spot)
		var first := _on_card(spot, true) if AROUND.has(spot) else elbow
		# A line to one of the four under the thumb starts at its rim, leaving what is on it clear.
		var from := button
		if face:
			from += (first - button).normalized() * (diagram.face_radius * ART_SCALE + 2.0)
		else:
			_dot(button)
		if AROUND.has(spot):
			_sheet.draw_line(from, first, INK, LINE_WIDTH, true)
			from = first
		_sheet.draw_line(from, elbow, INK, LINE_WIDTH, true)
		_sheet.draw_line(elbow, Vector2(edge, y), INK, LINE_WIDTH, true)
		var words: Array[String] = said[spot]["words"]
		var x := edge + side * 12.0
		_words(Type.STRONG, PadSheets.joined(words), Vector2(x, y + 6.0), 28, INK, side)
		_words(Type.TEXT, diagram.name_of(spot), Vector2(x, y + 32.0), 17, FAINT, side)
		var note: String = said[spot]["note"]
		if not note.is_empty():
			var at := Vector2(x + side * 10.0, y - 26.0)
			_words(BayArt.hand_font(), note, at, 30, BlueprintArt.PENCIL, side)


## Where a line leaves a button: a white dot, ringed in the sheet's blue so it reads over the
## drawing's own lines.
func _dot(at: Vector2) -> void:
	_sheet.draw_circle(at, 5.5, BlueprintArt.BLUE)
	_sheet.draw_circle(at, 3.8, INK)


## [param heights] each as near the button it is for as it can be, at least a row apart, between
## [param top] and [param bottom]; spread evenly over that where they would not fit.
static func _spread(heights: Array[float], top: float, bottom: float) -> void:
	var count := heights.size()
	if count == 0:
		return
	for i: int in range(1, count):
		heights[i] = maxf(heights[i], heights[i - 1] + ROW_GAP)
	heights[count - 1] = minf(heights[count - 1], bottom)
	for i: int in range(count - 2, -1, -1):
		heights[i] = minf(heights[i], heights[i + 1] - ROW_GAP)
	if heights[0] < top:
		for i: int in count:
			heights[i] = top + i * (bottom - top) / maxf(count - 1, 1)


## The middle buttons' words over the pad: one in the middle, two either side of it.
func _draw_over(spots: Array, said: Dictionary[StringName, Dictionary]) -> void:
	spots.sort_custom(
		func(a: StringName, b: StringName) -> bool: return _on_card(a).x < _on_card(b).x
	)
	var y := ART_TOP - 10.0
	for i: int in spots.size():
		var spot: StringName = spots[i]
		var middle := SIZE.x * 0.5
		if spots.size() > 1:
			middle += (i - (spots.size() - 1) * 0.5) * 340.0
		var words: Array[String] = said[spot]["words"]
		var line := PadSheets.joined(words)
		var wide := Type.STRONG.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 20.0
		_words(Type.STRONG, line, Vector2(middle, y - 12.0), 26, INK, 0)
		var button := _on_card(spot)
		var end := Vector2(middle + clampf(button.x - middle, -wide * 0.5, wide * 0.5), y)
		_sheet.draw_line(Vector2(middle - wide * 0.5, y), Vector2(middle + wide * 0.5, y), INK, 1.6)
		_sheet.draw_line(button, end, INK, LINE_WIDTH, true)
		_dot(button)


## [param line] at [param at]: ending there for [param align] -1, centered on it for 0, and starting
## there for 1.
func _words(font: Font, line: String, at: Vector2, tall: int, ink: Color, align: int) -> void:
	var wide := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, tall).x
	var x := at.x
	if align == 0:
		x -= wide * 0.5
	elif align < 0:
		x -= wide
	_sheet.draw_string(font, Vector2(x, at.y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, tall, ink)
