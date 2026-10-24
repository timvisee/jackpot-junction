class_name DebugGrantMenu
extends CanvasLayer
## A developer's cheat sheet: F5 opens a menu that hands the local player any joker or item pickup
## at once, for trying cards and shots out without waiting for the floor to deal them. Built only in
## a debug run, never in an export, so a shipped game cannot be cheated with it. It sits beside the
## F3 readout of [DebugOverlay].

const JOKERS_PATH := "res://data/jokers/catalog.tres"
const ITEMS_PATH := "res://data/powerups/all.tres"
## The ink a joker's button is drawn in, by [enum Joker.Rarity]: common, uncommon, rare.
const RARITY_INK: Array[Color] = [
	Color(0.86, 0.9, 0.95), Color(0.46, 0.84, 1.0), Color(1.0, 0.79, 0.4)
]
const COLUMN_SIZE := Vector2(240.0, 430.0)

var match_node: Match

var _status: Label


## Hangs one over [param parent], watching [param watching] and hidden until F5 asks for it. Does
## nothing outside a debug run: handing out items at will is a tool to test with, not a feature to
## ship. Returns the menu, or null where there is none to add.
static func add_to(parent: Node, watching: Match) -> DebugGrantMenu:
	if not OS.is_debug_build():
		return null
	var menu := DebugGrantMenu.new()
	menu.name = "DebugGrantMenu"
	menu.match_node = watching
	menu.visible = false
	parent.add_child(menu)
	return menu


func _ready() -> void:
	layer = 12
	_build()


## F5 shows or hides the menu; Escape closes it before the pause menu can hear the key.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F5:
		visible = not visible
		get_viewport().set_input_as_handled()
	elif visible and key.keycode == KEY_ESCAPE:
		visible = false
		get_viewport().set_input_as_handled()


## The window: a panel of two scrolling columns, the jokers and the items, centred over the arena.
func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _backdrop())
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	box.add_child(_label("Debug — grant to you  (F5, Esc closes)", 18))
	_status = _label("Click a joker or item to gain it.", 13)
	_status.add_theme_color_override("font_color", Color(0.78, 0.84, 0.9))
	box.add_child(_status)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	box.add_child(columns)
	columns.add_child(_joker_column())
	columns.add_child(_item_column())


## A button per printed joker, each in its rarity's ink, that hands over a copy when pressed.
func _joker_column() -> VBoxContainer:
	var catalog := load(JOKERS_PATH) as JokerCatalog
	var jokers: Array[Joker] = catalog.printed() if catalog != null else []
	jokers.sort_custom(func(a: Joker, b: Joker) -> bool: return a.display_name < b.display_name)
	var column := VBoxContainer.new()
	column.add_child(_label("Jokers (%d)" % jokers.size(), 15))
	var list := _scroll_into(column)
	for joker: Joker in jokers:
		var ink := RARITY_INK[clampi(joker.rarity, 0, RARITY_INK.size() - 1)]
		var button := _entry(joker.display_name, ink)
		button.pressed.connect(_give_joker.bind(joker))
		list.add_child(button)
	return column


## A button per item, each in the item's own colour, that puts it in the player's hand to use.
func _item_column() -> VBoxContainer:
	var table := load(ITEMS_PATH) as PowerUpTable
	var items: Array[PowerUp] = table.entries.duplicate() if table != null else []
	items.sort_custom(func(a: PowerUp, b: PowerUp) -> bool: return a.display_name < b.display_name)
	var column := VBoxContainer.new()
	column.add_child(_label("Items (%d)" % items.size(), 15))
	var list := _scroll_into(column)
	for item: PowerUp in items:
		var button := _entry(item.display_name, item.color)
		button.pressed.connect(_give_item.bind(item))
		list.add_child(button)
	return column


## Adds a scrolling box under [param column] and returns the list its buttons go in.
func _scroll_into(column: VBoxContainer) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = COLUMN_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	return list


func _give_joker(joker: Joker) -> void:
	var kart := _local_kart()
	if kart == null:
		_say("No local player in this scene to grant to.")
		return
	kart.jokers.add(joker)
	_say("Gave joker: %s." % joker.display_name)


func _give_item(item: PowerUp) -> void:
	var kart := _local_kart()
	if kart == null:
		_say("No local player in this scene to grant to.")
		return
	kart.hold_item(item, 0.0)
	_say("Holding item: %s — press Use to set it off." % item.display_name)


## The human playing on this machine, the one the grants land on; null before a kart is seated.
func _local_kart() -> Kart:
	if match_node == null:
		return null
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human() and slot.kart != null and is_instance_valid(slot.kart):
			return slot.kart
	return null


func _say(text: String) -> void:
	if _status != null:
		_status.text = text


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return HudText.shadowed(label, 1)


func _backdrop() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(4)
	return style


func _entry(text: String, tint: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color", tint)
	return button
