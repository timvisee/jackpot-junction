class_name LoyaltyDialog
extends CanvasLayer
## The loyalty program, GAME.md 8.9: a large dialog over whatever screen opens it, the title's
## Extras or a room's pause menu, on a layer of its own as the catalog of 8.8 is, with its shade and
## its pane; Back, B, Escape or a click on the shade beside the pane puts it away, the cursor back
## where it was.
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
const SHADE := CatalogDialog.SHADE
const AROUND := CatalogDialog.AROUND
const AROUND_LEAST := CatalogDialog.AROUND_LEAST
## Less room than this from top to bottom and the head is the settings', Back in it, as the
## catalog's; less than this across the map's room and it opens on the list.
const SHORT := CatalogDialog.SHORT
const NARROW := 700.0
## The switch over the pane, and the bind that flips it.
const LIST := "List"
const LIST_ACTION := InputActions.DETAILS
## The binds that zoom the map, in the row over it: a pad's shoulders, and on keys minus and plus.
const ZOOM := "Zoom"
const ZOOM_OUT := JOY_BUTTON_LEFT_SHOULDER
const ZOOM_IN := JOY_BUTTON_RIGHT_SHOULDER
const ZOOM_KEYS_OUT: Array[Key] = [KEY_MINUS, KEY_KP_SUBTRACT]
const ZOOM_KEYS_IN: Array[Key] = [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]
## Where every profile starts, GAME.md 8.9.
const START := &"slip_road"
const PANE_GAP := CatalogDialog.PANE_GAP
const PANE_AROUND := CatalogDialog.PANE_AROUND
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
## The program's card, in the corner over the pane.
var card_corner: Control
## Whether it opens unfolding, as the welcome opens it the first time.
var unfolding := false

var _profile: Profile
var _root: Control
var _shade: ColorRect
var _around: MarginContainer
var _pane: PanelContainer
var _head: HBoxContainer
var _title: Label
var _line: Label
var _foot_row: HBoxContainer
var _switches: HBoxContainer
var _hint_row: HBoxContainer
## What had the cursor before the dialog came up, for it to go back to.
var _from: Control
## Whether a NEW tag has gone, to be kept as the dialog goes.
var _looked := false
var _closing := false
var _keyboard := true
var _pointer := false
var _opened := false


## The program over [param parent], for the profile playing, the cursor where it stood last;
## [param unfold] for the map unfolding as it opens, as the welcome opens it.
static func open(parent: Node, unfold := false) -> LoyaltyDialog:
	var dialog := LoyaltyDialog.new()
	dialog.name = "Loyalty"
	dialog.unfolding = unfold
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
	_title = MenuTheme.title(program_name(_profile), Type.TITLE)
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_head.add_child(_title)
	_head.add_child(_switch_row())
	_line = MenuTheme.subtitle(program_line(_profile), Type.LABEL)
	_line.name = "Line"
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(_line)
	column.add_child(_body())
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
	var start := stood_at
	var at := Loyalty.map().landmark(start)
	if at == null or not Loyalty.is_drawn(_profile, at):
		start = START
	map_view.stand_at(start)
	_describe(start)
	_root.resized.connect(_fit)
	_fit()
	_show_binds()
	MenuTheme.deal(_pane)
	_open_as_left.call_deferred()
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
	var well := ListBox.Well.new()
	well.name = "Well"
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(well)
	map_view = LoyaltyMapView.new()
	map_view.name = "Map"
	map_view.profile = _profile
	map_view.program = program_name(_profile)
	cursor = LoyaltyCursor.new()
	cursor.name = "Cursor"
	map_view.cursor = cursor
	map_view.add_child(cursor)
	map_view.picked.connect(_on_picked)
	map_view.arrived.connect(_on_arrived)
	well.add_child(map_view)
	list = LoyaltyList.new()
	list.name = "List"
	list.visible = false
	list.looked_at.connect(_describe)
	list.chosen.connect(_on_chosen)
	well.add_child(list)
	var side := MarginContainer.new()
	side.name = "Side"
	side.custom_minimum_size.x = LoyaltyPane.WIDTH + 44.0
	for edge: String in ["left", "right", "top", "bottom"]:
		side.add_theme_constant_override("margin_%s" % edge, PANE_AROUND)
	body.add_child(side)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 18)
	side.add_child(column)
	card_corner = _card_corner()
	column.add_child(card_corner)
	pane = LoyaltyPane.new()
	pane.name = "Landmark"
	pane.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	column.add_child(pane)
	return body


## The profile's card, small, in the corner over the pane, as the welcome put it there.
func _card_corner() -> Control:
	var corner := Control.new()
	corner.name = "Card"
	corner.custom_minimum_size = LoyaltyCard.SIZE * CARD_SCALE
	corner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := LoyaltyCard.of(_profile)
	card.scale = Vector2.ONE * CARD_SCALE
	corner.add_child(card)
	return corner


## The List switch at the head's right, its words before it, and the binds of it and of the zoom
## after it while keys or a pad are in hand.
func _switch_row() -> HBoxContainer:
	_switches = HBoxContainer.new()
	_switches.name = "Switches"
	_switches.add_theme_constant_override("separation", 14)
	_switches.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hint_row = HBoxContainer.new()
	_hint_row.name = "Binds"
	_hint_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_switches.add_child(_hint_row)
	var named := Label.new()
	named.text = LIST
	Type.strong(named, Type.BODY, HouseTheme.WORDS)
	named.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_switches.add_child(named)
	list_switch = MenuTheme.toggle(listed)
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
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_show_binds()
	if _closing or event.is_echo():
		return
	if event.is_action_pressed(LIST_ACTION):
		set_listed(not listed)
	elif not listed and _drive_by(event):
		pass
	elif not listed and _zoom_by(event):
		pass
	else:
		return
	get_viewport().set_input_as_handled()


## Drives the cursor the way [param event] pushes, if it is a push. True if it was.
func _drive_by(event: InputEvent) -> bool:
	var ways := {
		&"ui_left": Vector2i.LEFT,
		&"ui_right": Vector2i.RIGHT,
		&"ui_up": Vector2i.UP,
		&"ui_down": Vector2i.DOWN,
	}
	for action: StringName in ways:
		if event.is_action_pressed(action):
			map_view.drive_toward(ways[action])
			return true
	return false


## Zooms the map in or out a notch for [param event], if it is a zoom key or shoulder. True if it
## was.
func _zoom_by(event: InputEvent) -> bool:
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	var by := 0.0
	if key != null and key.pressed:
		by = -1.0 if key.keycode in ZOOM_KEYS_OUT else (1.0 if key.keycode in ZOOM_KEYS_IN else 0.0)
	elif pad != null and pad.pressed:
		by = -1.0 if pad.button_index == ZOOM_OUT else (1.0 if pad.button_index == ZOOM_IN else 0.0)
	if by == 0.0:
		return false
	map_view.zoom_to(map_view.zoom * pow(LoyaltyMapView.ZOOM_STEP, by), map_view.size * 0.5)
	map_view.show_point(cursor.point, false)
	return true


## B on a pad, or Escape, is Back. Nothing gets past the dialog to the screen under it.
func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed(&"ui_cancel"):
		Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
		close()
	elif not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()


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


## A click or a tap on a landmark: the cursor drives there.
func _on_picked(id: StringName) -> void:
	map_view.drive_to(id)


## The cursor has come to [param id]: the pane says it, and it is no longer new.
func _on_arrived(id: StringName) -> void:
	_describe(id)


## A row of the list pressed: the map, the cursor at that landmark.
func _on_chosen(id: StringName) -> void:
	set_listed(false)
	map_view.stand_at(id)
	_describe(id)


## The pane says the landmark [param id], and its NEW tag goes.
func _describe(id: StringName) -> void:
	var landmark := Loyalty.map().landmark(id)
	if landmark == null:
		return
	pane.show_landmark(_profile, landmark)
	if _profile.loyalty.look_at(id):
		_looked = true
		map_view.queue_redraw()


## The NEW tags gone are kept in the profile.
func _keep_looks() -> void:
	if _looked:
		_looked = false
		Game.settings.save_to_disk()


## The pane over nearly all the screen, the shade showing round it, and its head as the room has
## it.
func _fit() -> void:
	var room := _root.size
	var around := maxf(minf(room.x, room.y) * AROUND, AROUND_LEAST)
	for side: String in ["left", "right", "top", "bottom"]:
		_around.add_theme_constant_override("margin_%s" % side, int(around))
	_lay_head(room.y < SHORT)


## Short of room, see [constant SHORT]: Back at the head's right, after the switch, and no foot, as
## the settings have it, GAME.md 8.5. Otherwise Back at the right of the foot.
func _lay_head(short: bool) -> void:
	if short == (back.get_parent() == _head):
		return
	var had_cursor := back.has_focus()
	back.reparent(_head if short else _foot_row, false)
	_foot_row.visible = not short
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
	for child: Node in _hint_row.get_children():
		(child as Control).hide()
		child.queue_free()
	var pad := SettingsScreen.pad_plugged_in()
	var keys := _keyboard and not _pointer
	if not keys and not pad:
		return
	var ink := SettingsScreen.TAB_HINT_INK
	var size := SettingsScreen.TAB_HINT_SIZE
	var parts: Array = []
	var template := ""
	if not listed:
		template = "%s %s " + ZOOM + "   "
		if keys:
			parts.append(_key_glyph(KEY_MINUS, ink, size))
			parts.append(_key_glyph(KEY_EQUAL, ink, size))
		else:
			for button: int in [ZOOM_OUT, ZOOM_IN]:
				var press := InputEventJoypadButton.new()
				press.button_index = button as JoyButton
				parts.append(InputGlyph.of_event(press, ink, size))
	# The switch's own bind just before its word, which says what it does.
	template += "%s"
	parts.append(InputGlyph.of_action(LIST_ACTION, keys, ink, size))
	_hint_row.add_child(InputHint.row(template, parts, ink, size))


static func _key_glyph(key: Key, ink: Color, size: int) -> InputGlyph:
	var press := InputEventKey.new()
	press.keycode = key
	return InputGlyph.of_event(press, ink, size)
