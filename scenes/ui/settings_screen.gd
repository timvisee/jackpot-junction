class_name SettingsScreen
extends Control
## The settings screen from GAME.md 8.5: controls with rebinding, audio, video and
## accessibility. Changes apply at once and are saved on Back.
##
## From the title it is a screen of its own. From a room's pause menu it is laid over the room
## instead, see [member overlay], so the match, and online the connection and everybody on it,
## carries on underneath rather than being thrown away and built again from the lobby's settings.

## Back, from a screen laid over a room: it has gone, and the room is the pause menu's again.
signal closed

const REBINDABLE: Array[StringName] = [
	InputActions.THROTTLE,
	InputActions.BRAKE,
	InputActions.STEER_LEFT,
	InputActions.STEER_RIGHT,
	InputActions.FIRE,
	InputActions.HANDBRAKE,
	InputActions.NITRO,
	InputActions.USE_ITEM,
	InputActions.JOKER_MENU,
	InputActions.JOKER_PREV,
	InputActions.JOKER_NEXT,
	InputActions.JOKER_DESTROY,
	InputActions.PAUSE,
	InputActions.JOIN,
	InputActions.MUTE_MUSIC,
]
## How the bindings themselves are drawn on the two buttons of a row, GAME.md 8.3.
const BINDING_SIZE := 18
const BINDING_INK := Color(0.90, 0.90, 0.94)

var tabs: TabContainer
var status: Label
## Laid over the room it was opened from rather than a scene of its own. Back closes it instead of
## changing scene.
var overlay := false

var _settings: Settings
var _listening_action := &""
var _listening_keyboard := true
var _binding_labels: Dictionary[StringName, Array] = {}


func _ready() -> void:
	_settings = Game.settings
	MenuTheme.background(self)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 48)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	column.add_child(MenuTheme.title("Settings", 56))
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 22)
	column.add_child(tabs)
	tabs.add_child(_controls_tab())
	tabs.add_child(_audio_tab())
	tabs.add_child(_video_tab())
	tabs.add_child(_accessibility_tab())
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	column.add_child(status)
	var back := MenuTheme.button("Back", 28)
	back.pressed.connect(_back)
	column.add_child(back)
	back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _listening_action == &"":
		# B on a pad, or Escape, is the Back button, GAME.md 4.2. While a rebind is listening it
		# is a binding like any other button, which the rest of this handles.
		if event.is_action_pressed(&"ui_cancel"):
			_back()
			get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and key.physical_keycode == KEY_ESCAPE:
		_stop_listening("Rebind canceled")
		get_viewport().set_input_as_handled()
		return
	if not _is_bindable_press(event):
		return
	var descriptor := InputActions.descriptor_from_event(event)
	if (
		descriptor.is_empty()
		or InputActions.is_keyboard_descriptor(descriptor) != _listening_keyboard
	):
		return
	InputActions.rebind(_listening_action, descriptor)
	_settings.remember_binding(_listening_action)
	_refresh_bindings()
	_stop_listening("Bound %s" % event.as_text())
	get_viewport().set_input_as_handled()


func _is_bindable_press(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null:
		return key.pressed and not key.echo
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return mouse.pressed
	var button := event as InputEventJoypadButton
	if button != null:
		return button.pressed
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return absf(motion.axis_value) > 0.6
	return false


func _controls_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "Controls"
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	var header := HBoxContainer.new()
	for text: String in ["Action", "Keyboard / mouse", "Gamepad"]:
		var label := Label.new()
		label.text = text
		label.custom_minimum_size = Vector2(300.0, 0.0)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Palette.CHIP_GOLD)
		header.add_child(label)
	column.add_child(header)
	for action: StringName in REBINDABLE:
		column.add_child(_binding_row(action))
	var deadzone := HSlider.new()
	deadzone.min_value = 0.05
	deadzone.max_value = 0.5
	deadzone.step = 0.01
	deadzone.value = _settings.stick_deadzone
	deadzone.custom_minimum_size = Vector2(300.0, 0.0)
	deadzone.value_changed.connect(
		func(value: float) -> void:
			_settings.stick_deadzone = value
			_settings.apply_input()
	)
	column.add_child(MenuTheme.row("Stick dead zone", deadzone))
	var reset := MenuTheme.button("Reset bindings to defaults", 22)
	reset.pressed.connect(
		func() -> void:
			_settings.reset_bindings()
			_refresh_bindings()
			status.text = "Bindings reset"
	)
	column.add_child(reset)
	return scroll


func _binding_row(action: StringName) -> HBoxContainer:
	var line := HBoxContainer.new()
	var name := Label.new()
	name.text = String(action).replace("_", " ").capitalize()
	name.custom_minimum_size = Vector2(300.0, 0.0)
	name.add_theme_font_size_override("font_size", 22)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(name)
	var buttons: Array = []
	for keyboard: bool in [true, false]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(290.0, 40.0)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_start_listening.bind(action, keyboard, button))
		line.add_child(button)
		buttons.append(button)
	_binding_labels[action] = buttons
	_refresh_binding(action)
	return line


func _start_listening(action: StringName, keyboard: bool, button: Button) -> void:
	_listening_action = action
	_listening_keyboard = keyboard
	_clear(button)
	button.text = "press..."
	status.text = (
		"Press a %s input for %s, Escape cancels"
		% ["keyboard or mouse" if keyboard else "gamepad", String(action)]
	)


func _stop_listening(message: String) -> void:
	_listening_action = &""
	_refresh_bindings()
	status.text = message


func _refresh_bindings() -> void:
	for action: StringName in _binding_labels:
		_refresh_binding(action)


## What an action is bound to, drawn as the keys and buttons themselves rather than written out,
## GAME.md 8.3. This is the one screen where every binding of an action is shown rather than the
## first, since it is the screen for changing them.
func _refresh_binding(action: StringName) -> void:
	var buttons: Array = _binding_labels[action]
	for i: int in 2:
		var button := buttons[i] as Button
		_clear(button)
		button.text = ""
		var row := _bound_glyphs(action, i == 0)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(row)


static func _bound_glyphs(action: StringName, keyboard: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	if InputMap.has_action(action):
		for event: InputEvent in InputMap.action_get_events(action):
			var descriptor := InputActions.descriptor_from_event(event)
			if InputActions.is_keyboard_descriptor(descriptor) != keyboard:
				continue
			row.add_child(InputGlyph.of_event(event, BINDING_INK, BINDING_SIZE))
	if row.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "-"
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.add_theme_color_override("font_color", BINDING_INK)
		row.add_child(empty)
	return row


static func _clear(button: Button) -> void:
	for child: Node in button.get_children():
		button.remove_child(child)
		child.queue_free()


func _audio_tab() -> Control:
	var column := VBoxContainer.new()
	column.name = "Audio"
	column.add_theme_constant_override("separation", 12)
	column.add_child(
		MenuTheme.row(
			"Master",
			_volume_slider(
				_settings.master_volume, func(v: float) -> void: _settings.master_volume = v
			)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Music",
			_volume_slider(
				_settings.music_volume, func(v: float) -> void: _settings.music_volume = v
			)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Effects",
			_volume_slider(_settings.sfx_volume, func(v: float) -> void: _settings.sfx_volume = v)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Karts",
			_volume_slider(_settings.kart_volume, func(v: float) -> void: _settings.kart_volume = v)
		)
	)
	column.add_child(MenuTheme.row("Music muted", _check(_settings.music_muted, _set_music_muted)))
	return column


func _set_music_muted(on: bool) -> void:
	_settings.music_muted = on
	_settings.apply_audio()


func _volume_slider(value: float, setter: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(320.0, 0.0)
	slider.value_changed.connect(
		func(v: float) -> void:
			setter.call(v)
			_settings.apply_audio()
	)
	return slider


func _video_tab() -> Control:
	var column := VBoxContainer.new()
	column.name = "Video"
	column.add_theme_constant_override("separation", 12)
	var fullscreen := MenuTheme.toggle(_settings.fullscreen)
	fullscreen.toggled.connect(
		func(on: bool) -> void:
			_settings.fullscreen = on
			_settings.apply_video(get_tree())
	)
	column.add_child(MenuTheme.row("Fullscreen", fullscreen))
	var vsync := MenuTheme.toggle(_settings.vsync)
	vsync.toggled.connect(
		func(on: bool) -> void:
			_settings.vsync = on
			_settings.apply_video(get_tree())
	)
	column.add_child(MenuTheme.row("V-sync", vsync))
	var scale := HSlider.new()
	scale.min_value = 0.5
	scale.max_value = 1.0
	scale.step = 0.05
	scale.value = _settings.render_scale
	scale.custom_minimum_size = Vector2(320.0, 0.0)
	scale.value_changed.connect(
		func(v: float) -> void:
			_settings.render_scale = v
			_settings.apply_video(get_tree())
	)
	column.add_child(MenuTheme.row("Render scale", scale))
	# The two passes over the whole screen, GAME.md 8.5. Both take effect at once: the smoothing
	# on the viewport, the bloom the next time a room is lit.
	var bloom := MenuTheme.toggle(_settings.bloom)
	bloom.toggled.connect(
		func(on: bool) -> void:
			_settings.bloom = on
			ArenaEnvironment.relight(get_tree())
	)
	column.add_child(MenuTheme.row("Bloom", bloom))
	var smoothing := MenuTheme.toggle(_settings.antialiasing)
	smoothing.toggled.connect(
		func(on: bool) -> void:
			_settings.antialiasing = on
			_settings.apply_video(get_tree())
	)
	column.add_child(MenuTheme.row("Edge smoothing", smoothing))
	return column


func _accessibility_tab() -> Control:
	var column := VBoxContainer.new()
	column.name = "Accessibility"
	column.add_theme_constant_override("separation", 12)
	column.add_child(
		MenuTheme.row(
			"Screen shake",
			_check(_settings.screen_shake, func(on: bool) -> void: _settings.screen_shake = on)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Reduce flashing",
			_check(
				_settings.flash_reduction, func(on: bool) -> void: _settings.flash_reduction = on
			)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Rumble", _check(_settings.rumble, func(on: bool) -> void: _settings.rumble = on)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Aim guide",
			_check(_settings.aim_guide, func(on: bool) -> void: _settings.aim_guide = on)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Disco lights",
			_check(_settings.disco_lights, func(on: bool) -> void: _settings.disco_lights = on)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Crowd", _check(_settings.crowd, func(on: bool) -> void: _settings.crowd = on)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Control hints",
			_check(_settings.control_hints, func(on: bool) -> void: _settings.control_hints = on)
		)
	)
	column.add_child(
		MenuTheme.row(
			"Fixed camera",
			_check(_settings.fixed_camera, func(on: bool) -> void: _settings.fixed_camera = on)
		)
	)
	var assist := HSlider.new()
	assist.min_value = 0.0
	assist.max_value = 1.0
	assist.step = 0.05
	assist.value = _settings.aim_assist
	assist.custom_minimum_size = Vector2(320.0, 0.0)
	assist.value_changed.connect(func(v: float) -> void: _settings.aim_assist = v)
	column.add_child(MenuTheme.row("Aim assist strength", assist))
	return column


func _check(value: bool, setter: Callable) -> CheckButton:
	var box := MenuTheme.toggle(value)
	box.toggled.connect(func(on: bool) -> void: setter.call(on))
	return box


func _back() -> void:
	_settings.save_to_disk()
	if overlay:
		closed.emit()
		queue_free()
		return
	get_tree().change_scene_to_file(Game.settings_return)


## A room that goes while its settings are open, online when the host moves everybody on, takes
## them with it. What was changed has already been applied, and is kept.
func _exit_tree() -> void:
	if overlay and not is_queued_for_deletion():
		_settings.save_to_disk()
