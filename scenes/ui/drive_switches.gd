class_name DriveSwitches
extends Control
## A switch over each local player's corner of the HUD while the pause menu is up, GAME.md 3.8 and
## 4.2: their name, and a button with the way they drive on it, simple or advanced, that changes
## it to the other. Each player's is over their own corner, so four people at one screen each
## find theirs where they already look, and it is saved at once.

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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Puts a switch over the corner of everybody playing at this screen in the room's match, taking
## down any left from before: somebody may have joined since.
func put_up() -> void:
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


func take_down() -> void:
	for each: Dictionary in _up:
		(each["pane"] as Control).queue_free()
	_up.clear()


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
	var each := {
		"pane": pane,
		"button": pressable,
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
