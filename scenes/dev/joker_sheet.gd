extends Control
## Every joker card at once, `make jokers`, so the pictures of GAME.md 8.3a can be looked at as a
## set. Consistency is the whole point of the vocabulary they are built from, and consistency is
## not something that can be judged one card at a time.
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
	for joker: Joker in _catalogue():
		# The card positions itself from its bottom centre, so it is hung in a slot of its own
		# size rather than handed to the grid, which would place its top left corner instead.
		var slot := Control.new()
		slot.custom_minimum_size = JokerCard.SIZE
		slot.add_child(JokerCard.create(joker))
		grid.add_child(slot)


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
