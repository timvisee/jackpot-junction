class_name ResultsScreen
extends PanelContainer
## The end of a match, GAME.md 3.8: everybody ranked by what they banked, with kills and deaths
## beside it and up to three awards under each name for whatever they did most.
##
## Its own screen rather than part of [MatchHud], which is about the match while it is being
## played. This is about the match once it is over, and it is the last thing anybody looks at.

var match_node: Match

var _rows: VBoxContainer


## Builds the screen for [param for_match] and hangs it off [param parent], hidden until the
## whistle goes.
static func create(parent: Node, for_match: Match) -> ResultsScreen:
	var screen := ResultsScreen.new()
	screen.name = "Results"
	screen.match_node = for_match
	parent.add_child(screen)
	screen._build()
	return screen


## Fills the screen in and shows it. Called at the whistle, and again on a client every time the
## host says the match is over, so it is built to be filled in more than once.
func fill_in() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.free()
	var everyone: Array[PlayerStats] = []
	for slot: PlayerSlot in match_node.slots:
		everyone.append(slot.stats)
	var rank := 1
	for slot: PlayerSlot in match_node.standings():
		_rows.add_child(_line(slot, rank))
		var awards := _awards_line(slot, everyone)
		if awards != null:
			_rows.add_child(awards)
		rank += 1
	visible = true


## One player's place, name, banked score and record.
func _line(slot: PlayerSlot, rank: int) -> Label:
	var row := Label.new()
	row.text = (
		"%d.  %s    %d    (%d kills, %d deaths)"
		% [rank, slot.display_name(), slot.banked, slot.kills, slot.deaths]
	)
	row.add_theme_font_size_override("font_size", 28)
	row.add_theme_color_override("font_color", slot.color())
	return row


## What this player did more of than anybody else, GAME.md 3.8, or null for a player who did
## nothing worth an award.
func _awards_line(slot: PlayerSlot, everyone: Array[PlayerStats]) -> Label:
	var parts: PackedStringArray = []
	for award: Array in PlayerStats.awards(slot.stats, everyone):
		parts.append("%s: %s" % [award[0], award[1]])
	if parts.is_empty():
		return null
	var awards := Label.new()
	awards.text = "      " + "   ·   ".join(parts)
	awards.add_theme_font_size_override("font_size", 17)
	awards.add_theme_color_override("font_color", Color(0.72, 0.72, 0.76))
	awards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	awards.custom_minimum_size = Vector2(840.0, 0.0)
	return awards


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(900.0, 0.0)
	visible = false
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Results"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_rows = VBoxContainer.new()
	column.add_child(_rows)
	column.add_child(_buttons())


## Play again, or go back. A client is not the one who decides there is another match.
func _buttons() -> HBoxContainer:
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	var rematch := Button.new()
	rematch.text = "Rematch"
	rematch.pressed.connect(func() -> void: match_node.rematch())
	rematch.visible = not match_node.puppet
	buttons.add_child(rematch)
	var quit := Button.new()
	quit.text = "Back to title"
	quit.pressed.connect(func() -> void: Game.go_to_title())
	buttons.add_child(quit)
	return buttons
