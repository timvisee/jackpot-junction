class_name ResultsScreen
extends PanelContainer
## The end of a match, GAME.md 3.8: everybody ranked by what they banked, with kills and deaths
## beside it and up to three awards under each name for whatever they did most.
##
## Its own screen rather than part of [MatchHud], which is about the match while it is being
## played. This is about the match once it is over, and it is the last thing anybody looks at.
##
## Built like the joker detail pane in 8.3, so the two read as the same game: a dark translucent
## card with room to breathe and a bar of colour along the top, here the winner's. The top three
## stand on a podium at the head of it, see [ResultsPodium], and under that each player is a row
## of their own rather than a line of text, with the place and the name on the left, the score
## on the right, and the awards underneath as separate chips rather than run together into one
## sentence.

## What the screen is headed. A podium is what is on it and what the last minute of a match is
## about; "Results" is the name of a state machine's last state.
const TITLE := "Podium"
const WIDTH := 980.0
const BG := Color(0.07, 0.07, 0.09, 0.94)
const RULE := Color(1.0, 1.0, 1.0, 0.13)
const FAINT := Color(0.62, 0.62, 0.68)
## The colour bar along the top edge, thick enough to be the screen's heading rather than a line.
const EDGE := 6
## The row of the player reading this screen is lifted out of the rest of them.
const ROW_BG := Color(1.0, 1.0, 1.0, 0.04)
const ROW_MINE := Color(1.0, 1.0, 1.0, 0.09)
const CHIP_BG := Color(1.0, 1.0, 1.0, 0.07)
## Air between the podium and the table of players: one is a picture and the other a list.
const PODIUM_GAP := 10.0

var match_node: Match

var _style: StyleBoxFlat
var _podium: ResultsPodium
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
	var standings := match_node.standings()
	if not standings.is_empty():
		_style.border_color = standings[0].color()
	_podium.show_top(standings)
	var rank := 1
	for slot: PlayerSlot in standings:
		_rows.add_child(_entry(slot, rank, everyone))
		rank += 1
	visible = true


## One player: their place and name on the left, what they banked on the right, and what they
## did most of underneath.
func _entry(slot: PlayerSlot, rank: int, everyone: Array[PlayerStats]) -> PanelContainer:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = ROW_MINE if _is_mine(slot) else ROW_BG
	style.set_corner_radius_all(8)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	# The player's own colour down the leading edge, the way the standings wear it.
	style.border_width_left = 5
	style.border_color = slot.color()
	row.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	row.add_child(box)
	box.add_child(_headline(slot, rank))
	var awards := _award_chips(slot, everyone)
	if awards != null:
		box.add_child(awards)
	return row


## Place, name, banked score and record, on one line.
func _headline(slot: PlayerSlot, rank: int) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	line.add_child(_label("%d" % rank, 30, FAINT))
	var name_label := _label(slot.display_name(), 30, slot.color())
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	line.add_child(_label("%d kills" % slot.kills, 18, FAINT))
	line.add_child(_label("%d deaths" % slot.deaths, 18, FAINT))
	var score := _label(str(slot.banked), 34, Palette.CHIP_GOLD)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.custom_minimum_size = Vector2(150.0, 0.0)
	line.add_child(score)
	return line


## What this player did more of than anybody else, GAME.md 3.8, one chip each, or null for a
## player who did nothing worth an award.
func _award_chips(slot: PlayerSlot, everyone: Array[PlayerStats]) -> HBoxContainer:
	var awards := PlayerStats.awards(slot.stats, everyone)
	if awards.is_empty():
		return null
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	for award: Array in awards:
		line.add_child(_chip(award[0], award[1]))
	return line


## One award as a little pill: what it is called, then what it was worth.
func _chip(title: String, value: String) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CHIP_BG
	style.set_corner_radius_all(10)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	chip.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 7)
	chip.add_child(line)
	line.add_child(_label(title, 15, Color(0.9, 0.9, 0.95)))
	line.add_child(_label(value, 15, FAINT))
	return chip


## Whether this row belongs to somebody sitting at this screen, so theirs stands out of the list.
func _is_mine(slot: PlayerSlot) -> bool:
	if match_node.puppet:
		return slot.index == match_node.local_slot
	return slot.is_local_human()


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(WIDTH, 0.0)
	visible = false
	_style = StyleBoxFlat.new()
	_style.bg_color = BG
	_style.set_corner_radius_all(10)
	_style.content_margin_left = 26.0
	_style.content_margin_right = 26.0
	_style.content_margin_top = 20.0
	_style.content_margin_bottom = 22.0
	_style.border_width_top = EDGE
	_style.border_color = Palette.CHIP_GOLD
	_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	_style.shadow_size = 20
	add_theme_stylebox_override("panel", _style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	var title := Label.new()
	title.text = TITLE
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Palette.CHIP_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var rule := ColorRect.new()
	rule.color = RULE
	rule.custom_minimum_size = Vector2(WIDTH, 1.0)
	column.add_child(rule)
	_podium = ResultsPodium.create()
	column.add_child(_podium)
	# The podium is a picture and the rows are a table; they want air between them rather than
	# the spacing that holds one row off the next.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, PODIUM_GAP)
	column.add_child(gap)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	column.add_child(_rows)
	column.add_child(_buttons())


## Play again, or go back. A client is not the one who decides there is another match.
func _buttons() -> HBoxContainer:
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	var rematch := MenuTheme.button("Rematch", 26)
	rematch.pressed.connect(func() -> void: match_node.rematch())
	rematch.visible = not match_node.puppet
	buttons.add_child(rematch)
	var quit := MenuTheme.button("Back to title", 26)
	quit.pressed.connect(func() -> void: Game.go_to_title())
	buttons.add_child(quit)
	return buttons
