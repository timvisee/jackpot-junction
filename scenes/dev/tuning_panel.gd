class_name TuningPanel
extends CanvasLayer
## F4 toggles live editing of the kart and cannon stats. A switch at the top flips a group of
## numbers between two candidate handlings so the idea can be judged while driving. Save writes the
## resources and the settings to disk.

## Each trial: a label and the properties it switches, as [old, new] pairs per resource.
## Groups of numbers that can be flipped between two candidates while driving; empty for now.
const TRIALS: Array[Dictionary] = []

var stats: KartStats
var cannon_stats: CannonStats
## Called after every change, so karts can rebuild their own copies of the stats.
var on_change: Callable

var _panel: PanelContainer
var _column: VBoxContainer
var _status: Label


func _ready() -> void:
	layer = 11
	visible = false
	# For the overlay to say F4 opens it, here and nowhere else.
	add_to_group(DebugOverlay.TUNING_GROUP)
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -520.0
	_panel.offset_top = 12.0
	_panel.offset_right = -12.0
	_panel.offset_bottom = -12.0
	add_child(_panel)
	_rebuild()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F4:
		visible = not visible


func _rebuild() -> void:
	for child: Node in _panel.get_children():
		child.queue_free()
	var scroll := ScrollContainer.new()
	_panel.add_child(scroll)
	_column = VBoxContainer.new()
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_column)
	if not TRIALS.is_empty():
		_add_title("Under evaluation (F4)")
		for trial: Dictionary in TRIALS:
			_column.add_child(_make_trial_row(trial))
	_add_title("Kart")
	_add_resource_rows(stats)
	_add_title("Cannon")
	_add_resource_rows(cannon_stats)
	var save := Button.new()
	save.text = "Save kart, cannon and settings"
	save.pressed.connect(_save)
	_column.add_child(save)
	_status = Label.new()
	_column.add_child(_status)


func _add_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Palette.CHIP_GOLD)
	_column.add_child(label)


func _add_resource_rows(resource: Resource) -> void:
	if resource == null:
		return
	for property: Dictionary in resource.get_property_list():
		if not (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var name := String(property["name"])
		match int(property["type"]):
			TYPE_FLOAT:
				_column.add_child(_make_float_row(resource, name))
			TYPE_INT:
				_column.add_child(_make_int_row(resource, name))
			TYPE_BOOL:
				_column.add_child(_make_bool_row(resource, name))


func _make_trial_row(trial: Dictionary) -> CheckBox:
	var box := CheckBox.new()
	box.text = trial["label"]
	box.button_pressed = _trial_is_on(trial)
	box.toggled.connect(
		func(on: bool) -> void:
			_apply_trial(trial, on)
			_rebuild()
	)
	return box


## A trial counts as on when its first property holds the new value.
func _trial_is_on(trial: Dictionary) -> bool:
	for kind: String in ["kart", "cannon", "settings"]:
		if not trial.has(kind):
			continue
		var changes: Dictionary = trial[kind]
		var target := _target(kind)
		for name: String in changes:
			var pair: Array = changes[name]
			return target != null and is_equal_approx_variant(target.get(name), pair[1])
	return false


static func is_equal_approx_variant(a: Variant, b: Variant) -> bool:
	if a is float and b is float:
		return is_equal_approx(a, b)
	return a == b


func _apply_trial(trial: Dictionary, on: bool) -> void:
	for kind: String in ["kart", "cannon", "settings"]:
		if not trial.has(kind):
			continue
		var target := _target(kind)
		if target == null:
			continue
		var changes: Dictionary = trial[kind]
		for name: String in changes:
			var pair: Array = changes[name]
			target.set(name, pair[1] if on else pair[0])
	_changed()


func _target(kind: String) -> Object:
	match kind:
		"kart":
			return stats
		"cannon":
			return cannon_stats
	return Game.settings


func _make_float_row(resource: Resource, property: String) -> HBoxContainer:
	var row := _row(property)
	var spinner := SpinBox.new()
	var current: float = resource.get(property)
	spinner.min_value = 0.0
	spinner.max_value = maxf(10.0, current * 5.0)
	spinner.step = 0.01
	spinner.value = current
	spinner.custom_minimum_size = Vector2(130.0, 0.0)
	spinner.value_changed.connect(
		func(value: float) -> void:
			resource.set(property, value)
			_changed()
	)
	row.add_child(spinner)
	return row


func _make_int_row(resource: Resource, property: String) -> HBoxContainer:
	var row := _row(property)
	var spinner := SpinBox.new()
	var current: int = resource.get(property)
	spinner.min_value = 0
	spinner.max_value = maxi(10, current * 5)
	spinner.step = 1
	spinner.value = current
	spinner.custom_minimum_size = Vector2(130.0, 0.0)
	spinner.value_changed.connect(
		func(value: float) -> void:
			resource.set(property, int(value))
			_changed()
	)
	row.add_child(spinner)
	return row


func _make_bool_row(resource: Resource, property: String) -> HBoxContainer:
	var row := _row(property)
	var box := CheckBox.new()
	box.button_pressed = resource.get(property)
	box.toggled.connect(
		func(on: bool) -> void:
			resource.set(property, on)
			_changed()
	)
	row.add_child(box)
	return row


func _row(property: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = property
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _changed() -> void:
	if on_change.is_valid():
		on_change.call()


func _save() -> void:
	var errors: PackedStringArray = []
	for resource: Resource in [stats, cannon_stats]:
		if resource == null or resource.resource_path.is_empty():
			continue
		var error := ResourceSaver.save(resource, resource.resource_path)
		if error != OK:
			errors.append("%s: %s" % [resource.resource_path.get_file(), error_string(error)])
	var settings_error := Game.settings.save_to_disk()
	if settings_error != OK:
		errors.append("settings: %s" % error_string(settings_error))
	_status.text = "saved" if errors.is_empty() else "save failed: " + ", ".join(errors)
