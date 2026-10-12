class_name DriveSwitches
extends Control
## A switch over each local player's corner of the HUD while the pause menu is up, GAME.md 3.8 and
## 4.2: their name, and a button with the way they drive on it, simple or advanced, that changes
## it to the other, and in simple driving on a pad or the touch screen, one for Auto throttle. Each
## player's is over their own corner, so four people at one screen each
## find theirs where they already look, and it is saved at once. The player at a touch screen has
## a second button under it, for the slider or the buttons. A pad's cursor goes out to them
## from the menu sideways and back toward the middle, and up and down between those on one side.
##
## Beside each switch a small card says what that player is playing on, a keyboard, a pad or the
## touch screen, and the keys or the stick they drive with there, the way they drive: a player
## who does not know which of the four corners is theirs finds out from what is in their hands.
## It is on the side toward the middle of the screen: under the switch of a player in a top
## corner and over the switch of one in a bottom corner, where under it would be off the screen.
##
## With more than one player at this screen each switch ends in Leave, for one of them to get up
## and go while the others play on, GAME.md 9.2: in the lobby and the Garage their seat is emptied,
## and on a map a bot takes the kart and the score on, as it does for a pad unplugged.
##
## In the lobby and the Garage there is more to it, GAME.md 4.4: a box with the player's name in
## it, to type another, and a button with their color and its name on it that moves them on to the
## next one nobody else is in. See [SeatIdentity], which does it, online too.
##
## Every player here past the first has Link profile too, when this machine keeps another profile,
## GAME.md 3.8: in place of their switch it lists the profiles they can play as, then Unlink when
## they are one, then Back. See [SeatLink], which does it.

## How far in from the edges of the screen a switch keeps, whatever its corner.
const EDGE := 12.0
const ICON := 30.0
## How wide the things in a switch are, and how big its color swatch is.
const WIDTH := 280.0
const SWATCH := 26.0
## How the card under a switch is drawn.
const CARD_SIZE := 16
const CARD_INK := Color(0.86, 0.86, 0.9)
## Whether simple driving works the pedals by itself, GAME.md 4.2, as its switch says it.
const AUTO_ON := "auto_on"
const AUTO_OFF := "auto_off"
const WORDS: Dictionary[String, String] = {
	Settings.DRIVE_SIMPLE: "Simple driving",
	Settings.DRIVE_ADVANCED: "Advanced driving",
	Settings.TOUCH_SLIDER: "Slider controls",
	Settings.TOUCH_BUTTONS: "Button controls",
	AUTO_ON: "Auto throttle on",
	AUTO_OFF: "Auto throttle off",
}
## The two things a switch can have a button for: how its player drives, and how the touch screen
## does, which only the player at a touch screen has.
const DRIVING := &"driving"
const TOUCH := &"touch"
## And whether simple driving works the pedals by itself, for a player on a pad or the touch screen
## while they drive the simple way: a keyboard's always does.
const AUTO := &"auto"
const LINK := "Link profile"
const CHANGE := "Change profile"
## The line under the name of a seat sat in as another profile, and how wide its plate is drawn.
const LINKED := "%s's profile"
const LINKED_PLATE := 72.0
const UNLINK := "Unlink"
const BACK := "Back"

## Whether the players can change their names and colors here: in the lobby and the Garage.
var names_and_colors := false

## Each switch up, with what it is for: the pane, its controls top to bottom and what each shows,
## the player's controls and slot, their corner of the HUD, and the name and color it was drawn in.
var _up: Array[Dictionary] = []
## The menu's buttons the switches were joined to, for letting go of them again.
var _menu: Array[Button] = []
## The seat whose switch is the list of profiles it can play as just now, or -1.
var _choosing := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Puts a switch over the corner of everybody playing at this screen in the room's match, taking
## down any left from before: somebody may have joined since. [param menu] is the pause menu's own
## column of buttons, to join the switches to for a pad.
func put_up(menu: Array[Button] = []) -> void:
	_choosing = -1
	_put_up(menu)


func _put_up(menu: Array[Button]) -> void:
	take_down()
	var match_node := _room()
	if match_node == null or match_node.hud == null:
		return
	var here := _players_here(match_node)
	for slot: PlayerSlot in here:
		var corner := match_node.hud.get_node_or_null("Block%d" % slot.index) as Control
		if corner != null:
			_up.append(_switch(slot, slot.input as PlayerInput, corner, here.size() > 1))
	_place()
	_link(menu)


## The room's match: the one still in the tree, not one on its way out. A room being left for
## another, and a test starting on the heels of the last one, have both for a moment, and the one
## going has the players it had, not the ones here now.
func _room() -> Match:
	for node: Node in get_tree().get_nodes_in_group(&"match"):
		if not node.is_queued_for_deletion():
			return node as Match
	return null


## Everybody playing at this screen in [param match_node], in slot order.
static func _players_here(match_node: Match) -> Array[PlayerSlot]:
	var here: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		var player := slot.input as PlayerInput
		if player != null and player.seat >= 0:
			here.append(slot)
	return here


func take_down() -> void:
	for each: Dictionary in _up:
		# A name still being typed when the menu goes is the name they typed.
		if each.has("box"):
			_keep_name(each)
		(each["holder"] as Control).queue_free()
	_up.clear()
	_link([])
	PlayerInput.typing = false


## Joins the switches to [param menu] for a pad's cursor: out to either side from any of the
## menu's buttons is the top switch on that side, and only that; back toward the middle from a
## switch is the menu's first button, and up and down go between the switches on one side.
## Joined afresh each time, and let go of when they come down, so the menu never points at a
## switch that has gone.
func _link(menu: Array[Button]) -> void:
	for button: Button in _menu:
		if is_instance_valid(button):
			button.focus_neighbor_left = NodePath()
			button.focus_neighbor_right = NodePath()
			button.focus_neighbor_top = NodePath()
			button.focus_neighbor_bottom = NodePath()
	_menu = menu
	if menu.is_empty():
		return
	var home := menu[0].get_path()
	# Up off the top of the menu and down off the bottom of it stay in the menu: the switches are
	# out to the sides, and a cursor that went up into a corner looking for the next button has
	# left the menu without being asked to.
	menu[0].focus_neighbor_top = home
	menu[-1].focus_neighbor_bottom = menu[-1].get_path()
	for left: bool in [true, false]:
		var panes: Array[Dictionary] = []
		for each: Dictionary in _up:
			if (_corner_at(each).get_center().x < size.x * 0.5) == left:
				panes.append(each)
		# By the corners rather than by the buttons, which their panes have not laid out yet.
		panes.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool:
				return _corner_at(a).position.y < _corner_at(b).position.y
		)
		var side: Array[Control] = []
		for each: Dictionary in panes:
			side.append_array(each["buttons"])
		for i: int in side.size():
			var button := side[i]
			var here := button.get_path()
			button.focus_neighbor_left = here if left else home
			button.focus_neighbor_right = home if left else here
			button.focus_neighbor_top = side[i - 1].get_path() if i > 0 else here
			button.focus_neighbor_bottom = side[i + 1].get_path() if i + 1 < side.size() else here
		if side.is_empty():
			continue
		for button: Button in menu:
			if left:
				button.focus_neighbor_left = side[0].get_path()
			else:
				button.focus_neighbor_right = side[0].get_path()


## The button of the switch for [param seat], or null when there is none up.
func button(seat: int) -> Button:
	for each: Dictionary in _up:
		if (each["player"] as PlayerInput).seat == seat:
			return each["button"]
	return null


func _switch(slot: PlayerSlot, player: PlayerInput, corner: Control, can_leave: bool) -> Dictionary:
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 6)
	var pane := MenuTheme.pane(slot.color())
	holder.add_child(pane)
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", HudBlock.scrim())
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pane.add_child(column)
	var name_label := Label.new()
	name_label.text = slot.display_name()
	Type.strong(name_label, Type.BODY, slot.color())
	column.add_child(name_label)
	_linked_line(column, player.seat)
	var buttons: Array[Control] = []
	var each := {
		"holder": holder,
		"pane": pane,
		"card": card,
		"controls": "",
		"buttons": buttons,
		"toggles": [],
		"player": player,
		"slot": slot,
		"corner": corner,
		"name": name_label,
		"worn": "",
	}
	if player.seat == _choosing:
		_profile_list(column, each)
		add_child(holder)
		_show(each)
		return each
	if names_and_colors:
		each["box"] = _name_box(column, each)
		each["swatch"] = _color_button(column, each)
	each["button"] = _toggle(column, each, DRIVING)
	if player.simple() and can_pedal(player):
		_toggle(column, each, AUTO)
	# And how the touch screen drives, for the player at it, GAME.md 4.2: the one reading every
	# device rather than a pad of their own.
	if TouchInput.enabled and player.device == DeviceInput.ANY:
		_toggle(column, each, TOUCH)
	if player.seat > 0 and Game.settings.profiles().size() > 1:
		var words := LINK if Game.settings.seat_profile(player.seat) == null else CHANGE
		each["link"] = _wide_button(column, each, words, _choose_profile.bind(player.seat))
	if can_leave:
		var leave := MenuTheme.button("Leave", Type.BODY)
		leave.custom_minimum_size = Vector2(WIDTH, 52.0)
		leave.pressed.connect(_leave.bind(each))
		column.add_child(leave)
		each["leave"] = leave
		buttons.append(leave)
	add_child(holder)
	_show(each)
	return each


## [param each]'s player gets up and goes, and the switches are put up again for whoever is left,
## the cursor back on the menu.
func _leave(each: Dictionary) -> void:
	var match_node := _room()
	if match_node == null:
		return
	var slot: PlayerSlot = each["slot"]
	var session := Net.session if Net.online() else null
	if session != null and not session.is_host:
		# One of several players at a client: their seat is the host's to empty, GAME.md 10.3.
		session.leave_seat(slot.index)
	elif match_node.rules.timed:
		match_node.leave_human(slot)
	else:
		VacantSeat.leave(match_node, slot)
	var menu := _menu.duplicate()
	put_up(menu)
	if not menu.is_empty():
		menu[0].grab_focus()


## Under the name of a seat sat in as another profile, GAME.md 3.8, which profile it is: its plate,
## or the learner's L, and its name, so it is plain whose statistics the seat counts into. Nothing
## for the first seat and a guest.
static func _linked_line(column: VBoxContainer, seat: int) -> void:
	var profile := Game.settings.seat_profile(seat)
	if profile == null:
		return
	var line := HBoxContainer.new()
	line.name = "Linked"
	line.add_theme_constant_override("separation", 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var worn := "L" if profile.license_number.is_empty() else profile.license_plate
	line.add_child(LicensePlate.badge(worn, LINKED_PLATE))
	var words := Label.new()
	words.text = LINKED % profile.display_name()
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Type.text(words, Type.LABEL, Color(0.86, 0.86, 0.9))
	line.add_child(words)
	column.add_child(line)


## A button as wide as a switch, saying [param words], that does [param does], and is one of
## [param each]'s for a pad's cursor.
func _wide_button(column: VBoxContainer, each: Dictionary, words: String, does: Callable) -> Button:
	var pressable := MenuTheme.button(words, Type.BODY)
	pressable.custom_minimum_size = Vector2(WIDTH, 52.0)
	pressable.pressed.connect(does)
	column.add_child(pressable)
	var buttons: Array[Control] = each["buttons"]
	buttons.append(pressable)
	return pressable


## In place of [param each]'s switch, the profiles its seat can play as, the one it is marked and
## not pressable, then Unlink when it is one, then Back.
func _profile_list(column: VBoxContainer, each: Dictionary) -> void:
	var seat := (each["player"] as PlayerInput).seat
	var settings := Game.settings
	var now := settings.linked[seat] if seat < settings.linked.size() else ""
	for profile: Profile in settings.linkable(seat):
		var pick := _wide_button(column, each, profile.display_name(), _pick.bind(seat, profile.id))
		pick.name = "Profile%s" % profile.id
		pick.disabled = profile.id == now
	if not now.is_empty():
		var unlink := _wide_button(column, each, UNLINK, _pick.bind(seat, ""))
		unlink.name = "Unlink"
	var back := _wide_button(column, each, BACK, _picked.bind(seat))
	back.name = "Back"
	each["button"] = (each["buttons"] as Array)[0]


## [param seat]'s switch becomes the list of profiles it can play as, the cursor on the first.
func _choose_profile(seat: int) -> void:
	_choosing = seat
	_again(seat, func(each: Dictionary) -> Control: return each["button"])


## [param seat] plays as the profile kept as [param id], or as a guest for an empty one.
func _pick(seat: int, id: String) -> void:
	var match_node := _room()
	for each: Dictionary in _up:
		if match_node != null and (each["player"] as PlayerInput).seat == seat:
			SeatLink.link(match_node, each["slot"], id)
	_picked(seat)


## Back from the list to [param seat]'s switch, the cursor on Link profile.
func _picked(seat: int) -> void:
	_choosing = -1
	_again(seat, func(each: Dictionary) -> Control: return each.get("link", each["button"]))


## The switches put up again, the cursor on what [param focus] says of [param seat]'s.
func _again(seat: int, focus: Callable) -> void:
	_put_up(_menu.duplicate())
	for each: Dictionary in _up:
		if (each["player"] as PlayerInput).seat == seat:
			(focus.call(each) as Control).grab_focus.call_deferred()


## What [param player] is playing on, as the card under their switch says it.
static func device_words(player: PlayerInput) -> String:
	if TouchInput.enabled and player.device == DeviceInput.ANY:
		return "Touch screen"
	if player.device >= 0:
		return "Gamepad %d" % (player.device + 1)
	return "Keyboard" if DeviceInput.uses_keyboard(player.device) else "Gamepad"


## The card under [param each]'s switch, made again when what it says changes: the player picks
## up a pad, or is switched to the other way to drive.
func _show_controls(each: Dictionary) -> void:
	var player: PlayerInput = each["player"]
	var simple := player.simple()
	var pedals := player.works_the_pedals()
	var stamp := ControlHint.stamp(player.device, simple, pedals)
	var said := "%s|%s" % [device_words(player), stamp]
	if each["controls"] == said:
		return
	each["controls"] = said
	var card: PanelContainer = each["card"]
	for old: Node in card.get_children():
		card.remove_child(old)
		old.queue_free()
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var device := Label.new()
	device.text = device_words(player)
	device.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.strong(device, CARD_SIZE, CARD_INK)
	column.add_child(device)
	var keyboard := DeviceInput.uses_keyboard(player.device)
	var row: HBoxContainer
	# And the cannon, the other thing every map asks of them from the start.
	var fire := InputHint.glyph(InputActions.FIRE, keyboard, CARD_INK, CARD_SIZE)
	if simple and pedals:
		var parts: Array = [
			InputHint.way(keyboard, CARD_INK, CARD_SIZE),
			InputHint.glyph(InputActions.THROTTLE, keyboard, CARD_INK, CARD_SIZE),
			fire,
		]
		row = InputHint.row("%s steer   %s gas   %s fire", parts, CARD_INK, CARD_SIZE)
	elif simple:
		var parts: Array = [InputHint.way(keyboard, CARD_INK, CARD_SIZE), fire]
		row = InputHint.row("%s drive   %s fire", parts, CARD_INK, CARD_SIZE)
	else:
		var parts: Array = [
			InputHint.glyph(InputActions.THROTTLE, keyboard, CARD_INK, CARD_SIZE),
			InputHint.pair(
				InputActions.STEER_LEFT, InputActions.STEER_RIGHT, keyboard, CARD_INK, CARD_SIZE
			),
			fire,
		]
		row = InputHint.row("%s throttle   %s steer   %s fire", parts, CARD_INK, CARD_SIZE)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)


## The box a player types their name into: the one in their seat's settings, or empty with the
## funny name they were handed showing faintly in it, the way the Seats tab shows it. What is
## typed is kept once they are done with it: on Enter, on leaving the box, or on the menu going.
## While it has the cursor the keys are the box's, not the kart's.
func _name_box(column: VBoxContainer, each: Dictionary) -> LineEdit:
	var slot: PlayerSlot = each["slot"]
	var player: PlayerInput = each["player"]
	var box := LineEdit.new()
	box.max_length = PlayerNames.MAX_LENGTH
	box.custom_minimum_size = Vector2(WIDTH, 48.0)
	box.select_all_on_focus = true
	var kept := Game.settings.seat_name(player.seat)
	box.text = kept
	box.placeholder_text = slot.display_name() if kept.is_empty() else PlayerNames.PLACEHOLDER
	each["shown"] = kept
	Type.set_font(box, Type.TEXT, Type.BODY)
	box.text_submitted.connect(func(_typed: String) -> void: _keep_name(each))
	box.focus_entered.connect(func() -> void: PlayerInput.typing = true)
	box.focus_exited.connect(
		func() -> void:
			PlayerInput.typing = false
			_keep_name(each)
	)
	column.add_child(box)
	var buttons: Array[Control] = each["buttons"]
	buttons.append(box)
	return box


## The name in [param each]'s box for its player, if it is not the one it started with.
func _keep_name(each: Dictionary) -> void:
	var box: LineEdit = each["box"]
	if not is_instance_valid(box) or box.text == each["shown"]:
		return
	each["shown"] = box.text
	SeatIdentity.rename(each["slot"], box.text)


## The button that moves the player on to the next color nobody else is in, with theirs on it and
## what it is called.
func _color_button(column: VBoxContainer, each: Dictionary) -> ColorRect:
	var pressable := MenuTheme.button("", Type.BODY)
	var inside := HBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.alignment = BoxContainer.ALIGNMENT_CENTER
	inside.add_theme_constant_override("separation", 10)
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(SWATCH, SWATCH)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(swatch)
	var word := Label.new()
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(word, Type.STRONG, Type.BODY)
	inside.add_child(word)
	each["color_word"] = word
	pressable.add_child(inside)
	pressable.custom_minimum_size = Vector2(WIDTH, 52.0)
	column.add_child(pressable)
	pressable.pressed.connect(
		func() -> void:
			var match_node := _room()
			if match_node != null:
				SeatIdentity.recolor(match_node, each["slot"])
	)
	var buttons: Array[Control] = each["buttons"]
	buttons.append(pressable)
	return swatch


## One button of a switch, for [param kind]: [constant DRIVING] or [constant TOUCH].
func _toggle(column: VBoxContainer, each: Dictionary, kind: StringName) -> Button:
	var pressable := MenuTheme.button("", Type.BODY)
	var inside := HBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.alignment = BoxContainer.ALIGNMENT_CENTER
	inside.add_theme_constant_override("separation", 10)
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var picture := DriveArt.picture(Settings.DRIVE_SIMPLE, Palette.CHIP_GOLD, ICON)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inside.add_child(picture)
	var word := Label.new()
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(word, Type.STRONG, Type.BODY)
	inside.add_child(word)
	pressable.add_child(inside)
	pressable.custom_minimum_size = Vector2(WIDTH, 52.0)
	column.add_child(pressable)
	pressable.pressed.connect(_flip.bind(each, kind))
	var buttons: Array[Control] = each["buttons"]
	buttons.append(pressable)
	var toggles: Array = each["toggles"]
	toggles.append({"kind": kind, "picture": picture, "word": word})
	return pressable


## Over to the other one of [param kind] for the player whose switch it is, and saved at once.
func _flip(each: Dictionary, kind: StringName) -> void:
	var settings := Game.settings
	var now := _now(each, kind)
	var seat := (each["player"] as PlayerInput).seat
	if kind == TOUCH:
		var layout := Settings.TOUCH_SLIDER
		settings.touch_layout = Settings.TOUCH_BUTTONS if now == layout else layout
	elif kind == AUTO:
		settings.set_auto_throttle(seat, now == AUTO_OFF)
	else:
		var simple := Settings.DRIVE_SIMPLE
		settings.set_drive_mode(seat, Settings.DRIVE_ADVANCED if now == simple else simple)
	settings.save_to_disk()
	if kind == DRIVING:
		# Simple driving has its Auto throttle switch under it, and advanced none: put up again.
		_again(seat, func(again: Dictionary) -> Control: return again["button"])
		return
	_show(each)


## Whether [param player] could work the pedals in simple driving, see
## [method PlayerInput.works_the_pedals]: on a pad or the touch screen, not on the keyboard.
static func can_pedal(player: PlayerInput) -> bool:
	if TouchInput.enabled and player.device == DeviceInput.ANY:
		return true
	return not DeviceInput.uses_keyboard(player.held_device())


## What [param kind] is just now for the player whose switch it is.
static func _now(each: Dictionary, kind: StringName) -> String:
	if kind == TOUCH:
		return Game.settings.touch_layout
	if kind == AUTO:
		var seat := (each["player"] as PlayerInput).seat
		return AUTO_ON if Game.settings.auto_throttle(seat) else AUTO_OFF
	return Game.settings.drive_mode((each["player"] as PlayerInput).seat)


func _show(each: Dictionary) -> void:
	for toggle: Dictionary in each["toggles"]:
		var now := _now(each, toggle["kind"])
		var picture := toggle["picture"] as DriveArt.Picture
		# Auto throttle is a word alone, there being no picture of a pedal worked for you.
		picture.visible = toggle["kind"] != AUTO
		if picture.visible:
			picture.mode = now
		(toggle["word"] as Label).text = WORDS[now]
	_follow(each)


## The switch in its player's name and color, which they may just have changed, or which the host
## has just said they are in. Only on a change.
func _follow(each: Dictionary) -> void:
	_show_controls(each)
	var slot: PlayerSlot = each["slot"]
	var worn := "%d|%s|%s" % [slot.color_index, Palette.vision, slot.display_name()]
	if each["worn"] == worn:
		return
	each["worn"] = worn
	var color := slot.color()
	var name_label: Label = each["name"]
	name_label.text = slot.display_name()
	name_label.add_theme_color_override("font_color", color)
	(each["pane"] as PanelContainer).add_theme_stylebox_override(
		"panel", MenuTheme.pane_style(color)
	)
	if each.has("swatch"):
		(each["swatch"] as ColorRect).color = color
		(each["color_word"] as Label).text = Palette.color_name(slot.color_index)


## The card over [param each]'s switch for a corner in the bottom half of the screen, and under
## it for one in the top half.
func _card_toward_the_middle(each: Dictionary, corner: Control) -> void:
	var holder: Control = each["holder"]
	var card: Control = each["card"]
	var bottom := corner.get_global_rect().get_center().y > size.y * 0.5
	var wanted := 0 if bottom else holder.get_child_count() - 1
	if card.get_index() != wanted:
		holder.move_child(card, wanted)


static func _corner_at(each: Dictionary) -> Rect2:
	return (each["corner"] as Control).get_global_rect()


## Whether a player a switch is up for has got up since, a pad unplugged under them handing their
## kart to a bot: their corner gone with them, or their seat someone else's.
func _somebody_left() -> bool:
	for each: Dictionary in _up:
		var slot: PlayerSlot = each["slot"]
		if not is_instance_valid(each["corner"]) or slot.input != each["player"]:
			return true
	return false


## The switches put up again for whoever is still here, joined to the menu as they were, and the
## cursor back on the menu's first button if it was on a switch that went: up for a seat that has
## gone, a switch pointed at its freed corner every frame, and the room stopped at the error.
func _put_up_again() -> void:
	var menu := _menu.duplicate()
	# Whose switch has the cursor, before they all go: the cursor back on that player's new one.
	var held := get_viewport().gui_get_focus_owner()
	var on_seat := -2
	for each: Dictionary in _up:
		if held != null and (each["holder"] as Control).is_ancestor_of(held):
			on_seat = (each["player"] as PlayerInput).seat
	var leaving := _choosing
	_put_up(menu)
	if (
		leaving >= 0
		and not _up.any(func(each: Dictionary) -> bool: return each["player"].seat == leaving)
	):
		_choosing = -1
	if on_seat == -2:
		return
	var again := button(on_seat)
	if again != null:
		again.grab_focus()
	elif not menu.is_empty():
		(menu[0] as Control).grab_focus()


## Held over the middle of each corner every frame, kept on the screen: the corner sits where the
## HUD put it, which is its own business, and on a touch screen it is drawn smaller than the rest.
func _process(_delta: float) -> void:
	_place()


func _place() -> void:
	if _somebody_left():
		_put_up_again()
		return
	for each: Dictionary in _up:
		_follow(each)
		var pane := each["holder"] as Control
		var corner := each["corner"] as Control
		_card_toward_the_middle(each, corner)
		pane.size = pane.get_combined_minimum_size()
		var room := size - pane.size - Vector2(EDGE, EDGE)
		var middle := corner.get_global_rect().get_center() - pane.size * 0.5
		pane.position = middle.clamp(Vector2(EDGE, EDGE), room.max(Vector2(EDGE, EDGE)))
