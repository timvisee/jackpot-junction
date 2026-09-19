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

const MINUTES: Array[int] = [3, 5, 8]
## A minute, for a match somebody is testing rather than playing: long enough to reach the
## Junction and the results screen, short enough to do it again straight away. Only in a debug
## build, because it is not a length anybody wants a real game to be.
const DEBUG_MINUTES := 1
const TARGETS: Array[int] = [0, 2000, 3000, 5000]
const BOTS: Array[int] = [0, 1, 2, 3]
const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]
const ITEM_SETS: Array[String] = ["first", "all"]
## Index order of the own-bullets option: off first, so it is the default.
const OWN_BULLETS: Array[bool] = [false, true]
## Index order of the overtime option: on first, so it is the default.
const OVERTIME: Array[bool] = [true, false]
const MAX_HUMANS := 4

var minutes_option: OptionButton
var target_option: OptionButton
var bots_option: OptionButton
var difficulty_option: OptionButton
var items_option: OptionButton
var own_bullets_option: OptionButton
var overtime_option: OptionButton
var start_button: Button
## Devices of the joined players in slot order; the first entry may be ANY until claimed.
var devices: Array[int] = [DeviceInput.ANY]
var colors: Array[int] = [0]
## What each joined player has typed, in the same order. Empty means a seat that wants whatever
## the match hands it, GAME.md 3.8.
var player_names: Array[String] = [""]

var _players_label: RichTextLabel
## One name box per seat, built once and shown as far down as the roster reaches.
var _name_fields: Array[LineEdit] = []
var _name_rows: Array[HBoxContainer] = []
var _steer_was_down: Dictionary[String, bool] = {}


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("Lobby", 64))
	_players_label = RichTextLabel.new()
	_players_label.bbcode_enabled = true
	_players_label.fit_content = true
	_players_label.scroll_active = false
	_players_label.custom_minimum_size = Vector2(700.0, 0.0)
	_players_label.add_theme_font_size_override("normal_font_size", 22)
	column.add_child(_players_label)
	var settings := Game.settings
	player_names[0] = _remembered_name(0)
	_build_name_rows(column)
	var lengths := _match_lengths()
	minutes_option = MenuTheme.option(
		_labels(lengths, "%d min"), maxi(lengths.find(settings.match_minutes), 0)
	)
	target_option = MenuTheme.option(_target_labels(), TARGETS.find(settings.target_score))
	bots_option = MenuTheme.option(BOTS, BOTS.find(settings.bot_count))
	difficulty_option = MenuTheme.option(
		["Easy", "Normal", "Hard"], DIFFICULTIES.find(settings.difficulty)
	)
	items_option = MenuTheme.option(["First set", "All items"], ITEM_SETS.find(settings.item_set))
	column.add_child(MenuTheme.row("Match length", minutes_option))
	column.add_child(MenuTheme.row("Target score", target_option))
	column.add_child(MenuTheme.row("Bots", bots_option))
	column.add_child(MenuTheme.row("Bot difficulty", difficulty_option))
	column.add_child(MenuTheme.row("Items", items_option))
	own_bullets_option = MenuTheme.option(
		["Stop harmlessly", "Are deadly"], OWN_BULLETS.find(settings.own_bullets_hurt)
	)
	column.add_child(MenuTheme.row("Your own bullets", own_bullets_option))
	overtime_option = MenuTheme.option(
		["Last one standing", "Match ends"], OVERTIME.find(settings.overtime)
	)
	column.add_child(MenuTheme.row("Out of time", overtime_option))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 24.0)
	column.add_child(spacer)
	start_button = MenuTheme.button("Start match")
	start_button.pressed.connect(_start)
	column.add_child(start_button)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(back)
	start_button.grab_focus()
	_refresh_players()


func _unhandled_input(event: InputEvent) -> void:
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
	result.duration = _match_lengths()[minutes_option.selected] * 60.0
	result.target_score = TARGETS[target_option.selected]
	result.bot_count = mini(BOTS[bots_option.selected], MAX_HUMANS - devices.size())
	result.difficulty = DIFFICULTIES[difficulty_option.selected]
	result.item_set = ITEM_SETS[items_option.selected]
	result.own_bullets_hurt = OWN_BULLETS[own_bullets_option.selected]
	result.overtime = OVERTIME[overtime_option.selected]
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
	settings.match_minutes = _match_lengths()[minutes_option.selected]
	settings.target_score = TARGETS[target_option.selected]
	settings.bot_count = BOTS[bots_option.selected]
	settings.difficulty = DIFFICULTIES[difficulty_option.selected]
	settings.item_set = ITEM_SETS[items_option.selected]
	settings.own_bullets_hurt = OWN_BULLETS[own_bullets_option.selected]
	settings.overtime = OVERTIME[overtime_option.selected]
	settings.save_to_disk()
	Game.start_match(config())


func _refresh_players() -> void:
	var lines: PackedStringArray = []
	for i: int in devices.size():
		var name := _device_name(devices[i])
		var color := Palette.player_color(colors[i]).to_html(false)
		lines.append("[color=#%s]■[/color]  P%d  %s" % [color, i + 1, name])
	var hint := (
		"Press %s or %s on another device to join. Steer left or right to change colour."
		% [
			InputActions.binding_text(InputActions.JOIN, true),
			InputActions.binding_text(InputActions.JOIN, false)
		]
	)
	_players_label.text = (
		"[center]%s\n[color=#9a9aa0]%s[/color][/center]" % ["\n".join(lines), hint]
	)
	_refresh_names()


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


## Shows as many boxes as there are players, each holding whatever its player is called.
func _refresh_names() -> void:
	for i: int in _name_rows.size():
		_name_rows[i].visible = i < devices.size()
		_name_fields[i].text = player_names[i] if i < player_names.size() else ""


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


## The match lengths on offer, shortest first. A debug build gets the one-minute match in front
## of the real ones, where somebody testing will find it without hunting.
func _match_lengths() -> Array[int]:
	if not OS.is_debug_build():
		return MINUTES
	var with_short: Array[int] = [DEBUG_MINUTES]
	with_short.append_array(MINUTES)
	return with_short


func _labels(values: Array[int], format: String) -> Array:
	var result: Array = []
	for value: int in values:
		result.append(format % value)
	return result


func _target_labels() -> Array:
	var result: Array = ["Off"]
	for value: int in TARGETS.slice(1):
		result.append(str(value))
	return result
