class_name TuningPanel
extends CanvasLayer
## F4 toggles live editing of a [KartStats] resource. Changes apply at once to every kart that
## shares the resource; Save writes them back to its .tres file so they survive a restart.

var stats: KartStats
## Called after every change, so karts can rebuild their own copies of the stats.
var on_change: Callable

var _panel: PanelContainer
var _status: Label


func _ready() -> void:
	layer = 11
	visible = false
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -420.0
	_panel.offset_top = 12.0
	_panel.offset_right = -12.0
	_panel.offset_bottom = -12.0
	add_child(_panel)
	var scroll := ScrollContainer.new()
	_panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var title := Label.new()
	title.text = "Kart tuning (F4)"
	column.add_child(title)
	if stats != null:
		for property: Dictionary in stats.get_property_list():
			if property["type"] != TYPE_FLOAT:
				continue
			if not (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			column.add_child(_make_row(String(property["name"])))
	var save := Button.new()
	save.text = "Save to %s" % (stats.resource_path if stats != null else "?")
	save.pressed.connect(_save)
	column.add_child(save)
	_status = Label.new()
	column.add_child(_status)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F4:
		visible = not visible


func _make_row(property: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = property
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var spinner := SpinBox.new()
	var current: float = stats.get(property)
	spinner.min_value = 0.0
	spinner.max_value = maxf(10.0, current * 5.0)
	spinner.step = 0.01
	spinner.value = current
	spinner.custom_minimum_size = Vector2(130.0, 0.0)
	spinner.value_changed.connect(
		func(value: float) -> void:
			stats.set(property, value)
			if on_change.is_valid():
				on_change.call()
	)
	row.add_child(spinner)
	return row


func _save() -> void:
	if stats == null or stats.resource_path.is_empty():
		_status.text = "nothing to save"
		return
	var error := ResourceSaver.save(stats, stats.resource_path)
	_status.text = "saved" if error == OK else "save failed: %s" % error_string(error)
