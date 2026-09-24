class_name DriveSwitches
extends Control
## A switch over each local player's corner of the HUD while the pause menu is up, GAME.md 3.8 and
## 4.2: their name, and a button with the way they drive on it, simple or advanced, that changes
## it to the other. Each player's is over their own corner, so four people at one screen each
## find theirs where they already look, and it is saved at once. A pad's cursor goes out to them
## from the menu sideways and back toward the middle, and up and down between those on one side.

## How far in from the edges of the screen a switch keeps, whatever its corner.
const EDGE := 12.0
const ICON := 30.0
const WORDS: Dictionary[String, String] = {
	Settings.DRIVE_SIMPLE: "Simple driving",
	Settings.DRIVE_ADVANCED: "Advanced driving",
}

## Each switch up, with what it is for: the pane, its button, its picture, the player's controls
## and their corner of the HUD.
var _up: Array[Dictionary] = []
## The menu's buttons the switches were joined to, for letting go of them again.
var _menu: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Puts a switch over the corner of everybody playing at this screen in the room's match, taking
## down any left from before: somebody may have joined since. [param menu] is the pause menu's own
## column of buttons, to join the switches to for a pad.
func put_up(menu: Array[Button] = []) -> void:
	take_down()
	var match_node := get_tree().get_first_node_in_group(&"match") as Match
	if match_node == null or match_node.hud == null:
		return
	for slot: PlayerSlot in match_node.slots:
		var player := slot.input as PlayerInput
		var corner := match_node.hud.get_node_or_null("Block%d" % slot.index) as Control
		if player == null or player.seat < 0 or corner == null:
			continue
		_up.append(_switch(slot, player, corner))
	_place()
	_link(menu)


func take_down() -> void:
	for each: Dictionary in _up:
		(each["pane"] as Control).queue_free()
	_up.clear()
	_link([])


## Joins the switches to [param menu] for a pad's cursor: out to either side from any of the
## menu's buttons is the top switch on that side, back toward the middle from a switch is the
## menu's first button, and up and down go between the switches on one side. Joined afresh each
## time, and let go of when they come down, so the menu never points at a switch that has gone.
func _link(menu: Array[Button]) -> void:
	for button: Button in _menu:
		if is_instance_valid(button):
			button.focus_neighbor_left = NodePath()
			button.focus_neighbor_right = NodePath()
	_menu = menu
	if menu.is_empty():
		return
	var home := menu[0].get_path()
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
		var side: Array[Button] = []
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


func _switch(slot: PlayerSlot, player: PlayerInput, corner: Control) -> Dictionary:
	var pane := MenuTheme.pane(slot.color())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pane.add_child(column)
	var name_label := Label.new()
	name_label.text = slot.display_name()
	Type.strong(name_label, Type.BODY, slot.color())
	column.add_child(name_label)
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
	pressable.custom_minimum_size = Vector2(280.0, 52.0)
	column.add_child(pressable)
	add_child(pane)
	var buttons: Array[Button] = [pressable]
	var each := {
		"pane": pane,
		"button": pressable,
		"buttons": buttons,
		"picture": picture,
		"word": word,
		"player": player,
		"corner": corner
	}
	pressable.pressed.connect(_flip.bind(each))
	_show(each)
	return each


## Over to the other way to drive, for the player whose switch it is.
func _flip(each: Dictionary) -> void:
	var settings := Game.settings
	var seat := (each["player"] as PlayerInput).seat
	var now := settings.drive_mode(seat)
	var other := Settings.DRIVE_ADVANCED if now == Settings.DRIVE_SIMPLE else Settings.DRIVE_SIMPLE
	settings.drive_modes[seat] = other
	settings.save_to_disk()
	_show(each)


func _show(each: Dictionary) -> void:
	var mode := Game.settings.drive_mode((each["player"] as PlayerInput).seat)
	(each["picture"] as DriveArt.Picture).mode = mode
	(each["word"] as Label).text = WORDS[mode]


static func _corner_at(each: Dictionary) -> Rect2:
	return (each["corner"] as Control).get_global_rect()


## Held over the middle of each corner every frame, kept on the screen: the corner sits where the
## HUD put it, which is its own business, and on a touch screen it is drawn smaller than the rest.
func _process(_delta: float) -> void:
	_place()


func _place() -> void:
	for each: Dictionary in _up:
		var pane := each["pane"] as Control
		var corner := each["corner"] as Control
		if not is_instance_valid(corner):
			pane.visible = false
			continue
		pane.size = pane.get_combined_minimum_size()
		var room := size - pane.size - Vector2(EDGE, EDGE)
		var middle := corner.get_global_rect().get_center() - pane.size * 0.5
		pane.position = middle.clamp(Vector2(EDGE, EDGE), room.max(Vector2(EDGE, EDGE)))
