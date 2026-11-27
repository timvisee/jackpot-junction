class_name NameDialog
extends Control
## A name asked for over the whole screen, GAME.md 8.5: a title, a box to type it in, and a button
## each for going ahead and for not, on the pane every panel in the game is cut from, over a shade.
## Enter in the box goes ahead and Back does not. Going ahead wants a name, so its button is off
## while the box is empty. A die beside the box rolls a name the house makes up, as the bay's does,
## GAME.md 4.4a, where one can be rolled, see [member _roll]. While it is up the keys are the box's,
## not a kart's, and the screen under it hears nothing: no tab of the settings switches.

## The name typed, cleaned, once the player went ahead with it; or by the second way ahead, where
## there is one, see [method open].
signal named(name: String)
signal named_also(name: String)
## Up no longer, whichever way it went.
signal put_away

## The button that puts it away, shown through tr().
const CANCEL := "Cancel"
## The button that goes ahead in a box's words typed again, see [method retype], shown through tr().
const DONE := "Done"
## How wide the box is.
const WIDE := 420.0
## The tooltip on the die that rolls a name, where the box has one, shown through tr().
const ROLL_TIP := "Roll a name"

var field: LineEdit
## The die beside the box that rolls a random name, or null where none can be rolled, see
## [member _roll].
var die: NameDie
var ok_button: Button
## The second way ahead, beside the first, or null where there is none.
var also_button: Button
var cancel_button: Button

## The pane and the shade, for putting away, and whether it is on its way.
var _pane: PanelContainer
var _shade: ColorRect
var _closing := false
## Makes a fresh random name for the die to put in the box, see [method _roll_name]; invalid where
## the box has no die.
var _roll: Callable


## Puts the question [param title] up over the whole screen [param from] is on, the box holding
## [param text], and [param ok] on the button that goes ahead, the one Enter presses; and with
## [param also] a second way ahead beside it, which says [signal named_also] instead; and with
## [param roll] a die beside the box that fills it with what [param roll] makes up.
static func open(
	from: Control,
	title: String,
	text: String,
	ok: String,
	also := "",
	roll := Callable(),
	like: LineEdit = null
) -> NameDialog:
	var top: Control = from
	while top.get_parent() is Control:
		top = top.get_parent() as Control
	var dialog := NameDialog.new()
	dialog.name = "NameDialog"
	dialog._roll = roll
	# Over the screen it is on; a page on its own has the window, under whatever holds it.
	(top if top != from else from.get_parent()).add_child(dialog)
	dialog._build(title, text, ok, also, like)
	return dialog


## [param box]'s words typed again over the whole screen it is on, under [param title], GAME.md
## 10.8: for a box low on the screen, which Steam's keyboard would come up over, see
## [SteamKeyboard]. The box in the dialog is one like [param box], a plate for a plate, with Steam's
## keyboard up for it at once and the cursor at the end of what it reads; gone ahead with, what was
## typed goes back into [param box] as if it had been typed there, Enter and all, and the cursor
## goes back onto it.
static func retype(box: LineEdit, title: String) -> NameDialog:
	var dialog := open(box, title, box.text, Lang.t(DONE), "", Callable(), box)
	dialog.named.connect(_put_back.bind(box))
	dialog.put_away.connect(
		func() -> void:
			if is_instance_valid(box) and box.is_visible_in_tree():
				box.grab_focus()
	)
	return dialog


## [param typed] into [param box], as if typed there: what listens to the box hears it change and
## be gone ahead with.
static func _put_back(typed: String, box: LineEdit) -> void:
	if not is_instance_valid(box):
		return
	box.text = typed
	box.text_changed.emit(box.text)
	box.text_submitted.emit(box.text)


## A box for [param text] like [param like], see [method retype]: a plate for a plate, and otherwise
## one as long and as hinted as it; a box for a name where there is none to be like.
static func _box_like(like: LineEdit, text: String) -> LineEdit:
	if like is PlateField:
		var plate := PlateField.make(text)
		plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return plate
	var longest := PlayerNames.MAX_LENGTH
	var hint := Lang.t(PlayerNames.PLACEHOLDER)
	if like != null:
		longest = like.max_length if like.max_length > 0 else longest
		hint = like.placeholder_text if not like.placeholder_text.is_empty() else hint
	var box := MenuTheme.field(text, hint, longest)
	box.custom_minimum_size.x = WIDE
	if like != null:
		box.virtual_keyboard_type = like.virtual_keyboard_type
	return box


func _build(title: String, text: String, ok: String, also: String, like: LineEdit) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(middle)
	var pane := PanelContainer.new()
	pane.add_theme_stylebox_override("panel", MenuTheme.pane_style())
	middle.add_child(pane)
	MenuTheme.deal(pane)
	_pane = pane
	_shade = shade
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pane.add_child(column)
	column.add_child(MenuTheme.title(title, Type.TITLE))
	column.add_child(MenuTheme.perforation())
	field = _box_like(like, text)
	field.text_changed.connect(func(_typed: String) -> void: _say_ok())
	field.text_submitted.connect(func(_typed: String) -> void: _go_ahead())
	if _roll.is_valid():
		# The box and the die side by side, the die square at the box's height off its right end.
		var box_row := HBoxContainer.new()
		box_row.add_theme_constant_override("separation", 12)
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box_row.add_child(field)
		die = NameDie.new()
		die.name = "Die"
		die.custom_minimum_size = Vector2.ONE * MenuTheme.box_height()
		die.tooltip_text = tr(ROLL_TIP)
		die.pressed.connect(_roll_name)
		box_row.add_child(die)
		column.add_child(box_row)
	else:
		column.add_child(field)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	ok_button = MenuTheme.primary(MenuTheme.button(ok, Type.BODY))
	ok_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_button.pressed.connect(_go_ahead)
	buttons.add_child(ok_button)
	if not also.is_empty():
		also_button = MenuTheme.button(also, Type.BODY)
		also_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		also_button.pressed.connect(_go_ahead.bind(true))
		buttons.add_child(also_button)
	cancel_button = MenuTheme.button(tr(CANCEL), Type.BODY)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.pressed.connect(close)
	buttons.add_child(cancel_button)
	_confine()
	_say_ok()
	PlayerInput.typing = true
	# A dialog put up for the box alone: Steam's keyboard comes up for it at once, GAME.md 10.8.
	field.set_meta(SteamKeyboard.AT_ONCE, true)
	if like == null:
		field.grab_focus.call_deferred()
		field.select_all.call_deferred()
		return
	# A box's words typed again: the cursor at the end of them.
	_start_at_end.call_deferred()


func _start_at_end() -> void:
	if not is_instance_valid(field):
		return
	field.grab_focus()
	field.edit()
	field.deselect()
	field.caret_column = field.text.length()


## The cursor stays on the box, the die and the buttons, rather than walking off them onto the page
## under them. The box and the die are the top row, the buttons the row under it.
func _confine() -> void:
	var top: Array[Control] = [field]
	if die != null:
		top.append(die)
	var row: Array[Control] = [ok_button]
	if also_button != null:
		row.append(also_button)
	row.append(cancel_button)
	var order: Array[Control] = []
	order.append_array(top)
	order.append_array(row)
	for i: int in order.size():
		var each := order[i]
		var here := each.get_path()
		each.focus_next = order[(i + 1) % order.size()].get_path()
		each.focus_previous = order[i - 1].get_path()
		each.focus_neighbor_left = here
		each.focus_neighbor_right = here
		each.focus_neighbor_top = here
		each.focus_neighbor_bottom = here
	# The top row side by side, each down to the buttons; the buttons side by side, each up to the box.
	for i: int in top.size():
		top[i].focus_neighbor_bottom = ok_button.get_path()
		if i > 0:
			top[i].focus_neighbor_left = top[i - 1].get_path()
		if i < top.size() - 1:
			top[i].focus_neighbor_right = top[i + 1].get_path()
	for i: int in row.size():
		row[i].focus_neighbor_top = field.get_path()
		if i > 0:
			row[i].focus_neighbor_left = row[i - 1].get_path()
		if i < row.size() - 1:
			row[i].focus_neighbor_right = row[i + 1].get_path()


## The die rolled: a fresh name in the box, and the ways ahead told it is no longer empty. The box
## keeps its text as set rather than firing [signal LineEdit.text_changed], so it is told by hand.
func _roll_name() -> void:
	if not _roll.is_valid():
		return
	field.text = _roll.call()
	_say_ok()


func _say_ok() -> void:
	ok_button.disabled = PlayerNames.clean(field.text).is_empty()
	if also_button != null:
		also_button.disabled = ok_button.disabled


func _go_ahead(also := false) -> void:
	var typed := PlayerNames.clean(field.text)
	if typed.is_empty():
		return
	close()
	if also:
		named_also.emit(typed)
	else:
		named.emit(typed)


## Down, without a name: said at once, and gone the way it came, see [method MenuTheme.put_away].
func close() -> void:
	if is_queued_for_deletion() or _closing:
		return
	_closing = true
	PlayerInput.typing = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shades: Array[CanvasItem] = [_shade]
	MenuTheme.put_away(_pane, queue_free, shades)
	put_away.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		MenuTheme.back_sound()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
