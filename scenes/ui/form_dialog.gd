class_name FormDialog
extends Control
## A few boxes to fill in, over the screen they are asked from, GAME.md 9.3 and 9.3a: a server's
## name, address and port, or a LAN host's; or none, and a bar for something being waited on, a
## server being connected to or a game being made, with what went wrong said in it after. Laid out
## the way the match settings are, see [HostSettings]: a shade over the screen, and in the middle
## the game's pane with a title in gold, a line under it in gray, a row each for the boxes, a line
## in red for what is wrong with them, and the buttons that answer it in a row under them. Back, or
## B, puts it away, which the screen asking says, since it knows what Back does there.
##
## The cursor stays on the dialog while it is up: down off the last button is the first box again,
## and nothing behind the shade can be reached, by the cursor or by a click.

## How far apart the buttons stand.
const BUTTON_GAP := 16

var _title: Label
var _line: Label
var _rows: VBoxContainer
var _column: VBoxContainer
var _pane: PanelContainer
var _buttons: HBoxContainer
var _wrong: Label
## What has the cursor first, as the dialog comes up.
var _first: Control


static func add_to(parent: Control, title: String, line: String) -> FormDialog:
	var dialog := FormDialog.new()
	dialog.name = "Form"
	parent.add_child(dialog)
	dialog._build(title, line)
	return dialog


func _build(title: String, line: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(middle)
	var pane := MenuTheme.pane()
	middle.add_child(pane)
	_pane = pane
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pane.add_child(column)
	_column = column
	_title = MenuTheme.title(title, 44)
	column.add_child(_title)
	_line = MenuTheme.subtitle(line, Type.LABEL)
	column.add_child(_line)
	column.add_child(MenuTheme.perforation())
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	column.add_child(_rows)
	_wrong = ServerGames.red_line()
	column.add_child(_wrong)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", BUTTON_GAP)
	column.add_child(_buttons)


## A row of the form: [param label] beside [param box].
func add_box(label: String, box: Control) -> Control:
	var row := MenuTheme.row(label, box)
	_rows.add_child(row)
	return row


## A bar under the boxes, for something being waited on, see [method LoadingScreen.bar].
func add_bar() -> ProgressBar:
	var bar := LoadingScreen.bar()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_column.add_child(bar)
	_column.move_child(bar, _rows.get_index() + 1)
	return bar


## A button under the boxes, in the row of them, saying [param text]; in foil where it is
## [param onward], the way on from the dialog, GAME.md 8.1a.
func add_button(text: String, onward := false) -> Button:
	var button := MenuTheme.button(text)
	if onward:
		MenuTheme.primary(button)
	button.custom_minimum_size = Vector2(200.0, button.custom_minimum_size.y)
	_buttons.add_child(button)
	return button


## Up, with the cursor on [param first], or on nothing for a dialog with nothing to press while it
## waits, and whatever was said wrong last time gone.
func open(first: Control) -> void:
	_first = first
	say("")
	visible = true
	MenuTheme.deal(_pane)
	_confine()
	if first != null:
		first.grab_focus.call_deferred()
	elif is_inside_tree():
		get_viewport().gui_release_focus()


## The cursor on [param control] again, the buttons having changed under it.
func focus(control: Control) -> void:
	_confine()
	control.grab_focus.call_deferred()


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


## What the dialog is called, and the line under its title.
func set_title(title: String, line: String) -> void:
	_title.text = title
	_line.text = line


## What is wrong with what was filled in, in red, or nothing.
func say(text: String) -> void:
	_wrong.text = text
	_wrong.visible = not text.is_empty()


func said() -> String:
	return _wrong.text


## The boxes and the buttons that can be reached, in the order the cursor goes through them.
func _reachable() -> Array[Control]:
	var found: Array[Control] = []
	for row: Node in _rows.get_children():
		if not (row as Control).visible:
			continue
		for each: Node in row.get_children():
			var control := each as Control
			if control != null and control.focus_mode != Control.FOCUS_NONE:
				found.append(control)
	for each: Node in _buttons.get_children():
		var button := each as Button
		if button != null and button.visible:
			found.append(button)
	return found


## Every box and button pointed at the next and the one before, going round, so the cursor never
## walks off the dialog onto what is behind the shade.
func _confine() -> void:
	var order := _reachable()
	if order.is_empty():
		return
	var buttons: Array[Control] = []
	for each: Control in order:
		if each is Button:
			buttons.append(each)
	var boxes := order.size() - buttons.size()
	for i: int in order.size():
		var here := order[i]
		var next := order[(i + 1) % order.size()]
		var before := order[(i - 1 + order.size()) % order.size()]
		here.focus_next = next.get_path()
		here.focus_previous = before.get_path()
		if here is Button:
			var at := buttons.find(here)
			var last_box := order[boxes - 1] if boxes > 0 else here
			var first_box := order[0]
			here.focus_neighbor_top = last_box.get_path()
			here.focus_neighbor_bottom = first_box.get_path()
			here.focus_neighbor_left = buttons[maxi(at - 1, 0)].get_path()
			here.focus_neighbor_right = buttons[mini(at + 1, buttons.size() - 1)].get_path()
		else:
			here.focus_neighbor_top = before.get_path()
			here.focus_neighbor_bottom = next.get_path()
			here.focus_neighbor_left = here.get_path()
			here.focus_neighbor_right = here.get_path()
