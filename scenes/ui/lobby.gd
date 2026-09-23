extends Control
## The lobby from GAME.md 3.8 and 9.2: match options with the document's values as defaults and
## the last choice remembered, and local joining. The first join press claims a device for P1;
## further presses on other devices add players, and a second press on a joined device drops
## that player again. Steering left or right on a device cycles that player's colour.
##
## Every player who has joined also gets a box to type a name into, remembered between sessions
## for that seat. Left empty, the match hands out a name off the funny list in [PlayerNames], so
## a gamepad player with no keyboard to type on is still somebody rather than P3. Steering does
## not cycle colours while a box has the focus, since the letters somebody is typing are also
## the keys that steer.
##
## Beside the name is how that player's kart is dressed, GAME.md 4.4, remembered the same way.

const MAX_HUMANS := 4

## What the match is going to be, the same rows the waiting room of 9.6 puts in front of a host.
var options: MatchOptions
var start_button: Button
## Devices of the joined players in slot order; the first entry may be ANY until claimed.
var devices: Array[int] = [DeviceInput.ANY]
var colors: Array[int] = [0]
## What each joined player has typed, in the same order. Empty means a seat that wants whatever
## the match hands it, GAME.md 3.8.
var player_names: Array[String] = [""]

var _players_label: RichTextLabel
var _join_hint: HBoxContainer
## One name box per seat, built once and shown as far down as the roster reaches.
var _name_fields: Array[LineEdit] = []
var _name_rows: Array[HBoxContainer] = []
## One row of dress choices per seat, each a list of option buttons in [constant
## KartStyle.CHOICES] order.
var _style_rows: Array[HBoxContainer] = []
var _style_pickers: Array[Array] = []
var _steer_was_down: Dictionary[String, bool] = {}


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	var playing := Game.lobby_for == Game.LobbyFor.PLAY
	column.add_child(MenuTheme.title("Play" if playing else "Quick play", 64))
	_players_label = RichTextLabel.new()
	_players_label.bbcode_enabled = true
	_players_label.fit_content = true
	_players_label.scroll_active = false
	_players_label.custom_minimum_size = Vector2(700.0, 0.0)
	_players_label.add_theme_font_size_override("normal_font_size", 22)
	column.add_child(_players_label)
	# The two ways in are drawn as the buttons themselves, GAME.md 8.3, so this is a row of its
	# own under the list rather than another line of the same block of text.
	_join_hint = HBoxContainer.new()
	_join_hint.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_join_hint)
	var settings := Game.settings
	player_names[0] = _remembered_name(0)
	_build_name_rows(column)
	_build_style_rows(column)
	options = MatchOptions.add_to(
		column, settings, MatchOptions.Mode.PLAY if playing else MatchOptions.Mode.QUICK_PLAY
	)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 24.0)
	column.add_child(spacer)
	start_button = MenuTheme.button("Start" if playing else "Start match")
	start_button.pressed.connect(_start)
	column.add_child(start_button)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(back)
	start_button.grab_focus()
	_refresh_players()


func _unhandled_input(event: InputEvent) -> void:
	# B on a pad, or Escape, is the Back button, GAME.md 4.2.
	if event.is_action_pressed(&"ui_cancel"):
		Game.go_to_title()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(InputActions.JOIN):
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	toggle_join(device)
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# The letters somebody is typing are the same keys that steer, so a name being typed is not
	# also a colour being cycled.
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	for i: int in devices.size():
		var device := devices[i]
		if device == DeviceInput.ANY:
			continue
		if _just_pressed(InputActions.STEER_RIGHT, device):
			cycle_color(i, 1)
		elif _just_pressed(InputActions.STEER_LEFT, device):
			cycle_color(i, -1)


## Claims P1's device, adds a player, or drops a player who presses again. P1 never drops.
func toggle_join(device: int) -> void:
	var existing := devices.find(device)
	if existing > 0:
		devices.remove_at(existing)
		colors.remove_at(existing)
		player_names.remove_at(existing)
		Audio.play_sfx(&"ui_back", -6.0, 0.0)
	elif existing == 0:
		return
	elif devices[0] == DeviceInput.ANY:
		devices[0] = device
		Audio.play_sfx(&"ui_click", -6.0, 0.0)
	elif devices.size() < MAX_HUMANS:
		devices.append(device)
		colors.append(_free_color())
		player_names.append(_remembered_name(devices.size() - 1))
		Audio.play_sfx(&"ui_click", -6.0, 0.0)
	_refresh_players()


## Moves a player's colour to the next one nobody else uses.
func cycle_color(player: int, direction: int) -> void:
	var candidate := colors[player]
	for i: int in Palette.PLAYER_COLORS.size():
		candidate = posmod(candidate + direction, Palette.PLAYER_COLORS.size())
		if candidate not in colors:
			colors[player] = candidate
			break
	Audio.play_sfx(&"ui_move", -10.0, 0.0)
	_refresh_players()


## The configuration the current options describe.
func config() -> MatchConfig:
	var result := MatchConfig.new()
	result.human_devices = devices.duplicate()
	result.human_colors = colors.duplicate()
	result.human_names = names()
	result.human_styles = styles()
	options.apply_to(result)
	result.bot_count = mini(result.bot_count, MAX_HUMANS - devices.size())
	return result


## How each joined player dressed their kart, in slot order.
func styles() -> Array:
	var result: Array = []
	for i: int in devices.size():
		var picked := PackedInt32Array()
		for option: OptionButton in _style_pickers[i]:
			picked.append(option.selected)
		result.append(picked)
	return result


## What each joined player is called, cleaned up, in slot order.
func names() -> Array[String]:
	var result: Array[String] = []
	for name: String in player_names:
		result.append(PlayerNames.clean(name))
	return result


func _start() -> void:
	var settings := Game.settings
	var typed := names()
	for i: int in mini(typed.size(), settings.player_names.size()):
		settings.player_names[i] = typed[i]
	var dressed := styles()
	for i: int in mini(dressed.size(), settings.kart_styles.size()):
		settings.kart_styles[i] = dressed[i]
	options.remember(settings)
	settings.save_to_disk()
	# Play starts in the waiting room of GAME.md 9.6, and its first map is dealt once everybody
	# there is ready, see 9.7. Quick play goes straight onto the map it chose.
	if options.is_grand_prix():
		Game.go_to_waiting(config())
	else:
		Game.start_match(config())


func _refresh_players() -> void:
	var lines: PackedStringArray = []
	for i: int in devices.size():
		var name := _device_name(devices[i])
		var color := Palette.player_color(colors[i]).to_html(false)
		lines.append("[color=#%s]■[/color]  P%d  %s" % [color, i + 1, name])
	_players_label.text = "[center]%s[/center]" % "\n".join(lines)
	_refresh_join_hint()
	_refresh_names()


## How to get in, with both ways drawn as the buttons they are. Built once: the bindings only
## change in Settings, which is a different screen.
func _refresh_join_hint() -> void:
	if _join_hint.get_child_count() > 0:
		return
	var ink := Color(0.60, 0.60, 0.63)
	var size := 18
	var parts: Array = [
		InputHint.glyph(InputActions.JOIN, true, ink, size),
		InputHint.glyph(InputActions.JOIN, false, ink, size),
	]
	_join_hint.add_child(
		InputHint.row(
			"Press %s or %s on another device to join. Steer to change colour.", parts, ink, size
		)
	)


## A box per seat, all of them built up front. What has been typed lives in [member
## player_names] rather than in the boxes, so it follows its own player through somebody else
## joining or leaving rather than staying at the position it was typed at.
func _build_name_rows(column: VBoxContainer) -> void:
	for i: int in MAX_HUMANS:
		var field := MenuTheme.field("", PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH)
		field.text_changed.connect(
			func(text: String) -> void:
				if i < player_names.size():
					player_names[i] = text
		)
		_name_fields.append(field)
		var row := MenuTheme.row("P%d name" % (i + 1), field)
		_name_rows.append(row)
		column.add_child(row)


## A row of dress choices per seat, built up front like the name boxes and shown with them. The
## kart is the thing a player looks at for the whole match, so the choices are here rather than
## behind a screen of their own.
func _build_style_rows(column: VBoxContainer) -> void:
	for i: int in MAX_HUMANS:
		var pickers: Array = []
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		for choice: int in KartStyle.CHOICES.size():
			var option := MenuTheme.option(KartStyle.CHOICES[choice], _remembered_style(i, choice))
			option.custom_minimum_size = Vector2(150.0, 40.0)
			pickers.append(option)
			line.add_child(option)
		_style_pickers.append(pickers)
		var row := MenuTheme.row("P%d kart" % (i + 1), line)
		_style_rows.append(row)
		column.add_child(row)


func _remembered_style(seat: int, choice: int) -> int:
	var stored := Game.settings.kart_styles
	if seat >= stored.size():
		return 0
	var packed := PackedInt32Array(stored[seat])
	return packed[choice] if choice < packed.size() else 0


## Shows as many boxes as there are players, each holding whatever its player is called.
func _refresh_names() -> void:
	for i: int in _name_rows.size():
		_name_rows[i].visible = i < devices.size()
		_name_fields[i].text = player_names[i] if i < player_names.size() else ""
		_style_rows[i].visible = i < devices.size()


func _remembered_name(seat: int) -> String:
	var stored := Game.settings.player_names
	return stored[seat] if seat < stored.size() else ""


func _device_name(device: int) -> String:
	match device:
		DeviceInput.ANY:
			return "keyboard or any gamepad"
		DeviceInput.KEYBOARD:
			return "keyboard"
	return "gamepad %d" % (device + 1)


func _free_color() -> int:
	var index := 0
	while index in colors:
		index += 1
	return index


func _just_pressed(action: StringName, device: int) -> bool:
	var key := "%s:%d" % [action, device]
	var down := DeviceInput.pressed(action, device)
	var was: bool = _steer_was_down.get(key, false)
	_steer_was_down[key] = down
	return down and not was
