extends Control
## Every icon in the game at once, `make jokers`: the power-ups first and then the joker
## cards, so the pictures of GAME.md 8.3a can be looked at as the one set they are meant to
## be. Consistency is the whole point of the vocabulary they are built from, and consistency
## is not something that can be judged one card at a time.
##
## Reads the catalogue off disk rather than from a list here, so a joker added tomorrow turns up
## on the sheet without this being touched.

## How many cards to a row, and the air between them.
const COLUMNS := 8
const GAP := 14


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.09, 0.09, 0.11)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, GAP * 2)
	add_child(margin)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(grid)
	for item: PowerUp in _items():
		var slot := Control.new()
		slot.custom_minimum_size = JokerCard.SIZE
		slot.add_child(_item_card(item))
		grid.add_child(slot)
	for joker: Joker in _catalogue():
		# The card positions itself from its bottom centre, so it is hung in a slot of its own
		# size rather than handed to the grid, which would place its top left corner instead.
		var slot := Control.new()
		slot.custom_minimum_size = JokerCard.SIZE
		slot.add_child(JokerCard.create(joker))
		grid.add_child(slot)


## One power-up shown the way a card is, so the two sets can be judged against each other: the
## picture in the item's own colour with its name under it.
static func _item_card(item: PowerUp) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.14, 0.96)
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.border_color = item.color
	for side: String in ["content_margin_left", "content_margin_right"]:
		style.set(side, 8.0)
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = JokerCard.SIZE
	var stack := VBoxContainer.new()
	card.add_child(stack)
	var art := PowerUpArt.picture(item.id, item.color)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(art)
	var title := Label.new()
	title.text = item.display_name
	title.add_theme_font_size_override("font_size", 15)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(title)
	return card


## Every power-up in the game, in the order the folder reads.
static func _items() -> Array[PowerUp]:
	var found: Array[PowerUp] = []
	var files := DirAccess.get_files_at("res://data/powerups/")
	files.sort()
	for file: String in files:
		if file in ["all.tres", "first_set.tres", "later_set.tres"] or not file.ends_with(".tres"):
			continue
		found.append(load("res://data/powerups/" + file))
	return found


## Every joker in the game, by name, so the sheet reads in the order the folder does.
static func _catalogue() -> Array[Joker]:
	var found: Array[Joker] = []
	var files := DirAccess.get_files_at("res://data/jokers/")
	files.sort()
	for file: String in files:
		if file == "catalog.tres" or not file.ends_with(".tres"):
			continue
		found.append(load("res://data/jokers/" + file))
	return found
