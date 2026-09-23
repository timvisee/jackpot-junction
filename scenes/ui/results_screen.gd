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
## about; "Results" is the name of a state machine's last state. The end of a Grand Prix is headed
## with the name of what has just been won.
const TITLE := "Podium"
const GRAND_PRIX_TITLE := "Grand Prix"
const PLACES: Array[String] = ["1st", "2nd", "3rd", "4th", "5th", "6th"]
const WIDTH := 980.0
const RULE := Color(1.0, 1.0, 1.0, 0.13)
const FAINT := Color(0.62, 0.62, 0.68)
## The row of the player reading this screen is lifted out of the rest of them.
const ROW_BG := Color(1.0, 1.0, 1.0, 0.04)
const ROW_MINE := Color(1.0, 1.0, 1.0, 0.09)
const CHIP_BG := Color(1.0, 1.0, 1.0, 0.07)
## Air between the podium and the table of players: one is a picture and the other a list.
const PODIUM_GAP := 10.0

var match_node: Match

var _style: StyleBoxFlat
var _title: Label
var _podium: ResultsPodium
var _rows: VBoxContainer
## The two ways on from here, kept so the screen can point at one when it comes up.
var _next: Button
var _standings: Button
var _rematch: Button
var _lobby: Button
var _quit: Button
## Tells a client what happens next and who decides it, since it is not them.
var _host_decides: Label
## Which map of a Grand Prix this was, GAME.md 9.7, under the title.
var _caption: Label
## Whether the last map's podium has moved on to the run's, see [method _show_run].
var _showing_run := false
## What happens to everybody's jokers on the way to the next map, under the caption.
var _keep_note: Label
## Seat to the joker a player here chose to keep, so the choice outlives the screen being filled
## in again when the run's points arrive.
var _kept: Dictionary[int, StringName] = {}


## Builds the screen for [param for_match] and hangs it off [param parent], hidden until the
## whistle goes.
static func create(parent: Node, for_match: Match) -> ResultsScreen:
	var screen := ResultsScreen.new()
	screen.name = "Results"
	screen.match_node = for_match
	parent.add_child(screen)
	screen._build()
	# A client hears how a Grand Prix stands a moment after it hears the whistle, so a podium
	# already up is filled in again with the points once they are here.
	Events.grand_prix_scored.connect(screen._on_grand_prix_scored)
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
	# The end of a Grand Prix, GAME.md 9.7, is its own podium: everybody ranked on the points of
	# the whole run rather than on what they banked on its last map. The last map gets its own
	# podium first, like every map before it, and the run's comes after it.
	var run := _run()
	var final := run != null and _showing_run
	var standings := run.standings(match_node.slots) if final else match_node.standings()
	if not standings.is_empty():
		_style.border_color = standings[0].color()
	_podium.show_top(standings)
	_title.text = GRAND_PRIX_TITLE if final else TITLE
	var rank := 1
	for slot: PlayerSlot in standings:
		_rows.add_child(_run_entry(slot, rank, run) if final else _entry(slot, rank, everyone, run))
		rank += 1
	visible = true
	_ways_on()
	# This is the one screen nobody asked for: it arrives on its own at the whistle, so it points
	# at what most people want next rather than waiting to be found.
	for first: Button in [_next, _standings, _lobby, _rematch, _quit]:
		if first.visible:
			first.grab_focus()
			break


## Which ways on the screen offers. Asked at the whistle rather than when the screen was built,
## which was the start of the match: who is hosting is a question about who is still here at the
## end of it.
##
## In a Grand Prix, GAME.md 9.7, a map that is not the last leads to the next one and nowhere else:
## there is no rematch of a map in the middle of a run, and no leaving from the podium, which is
## for the next map (the pause menu is still the way out). The last map ends the run, and leads
## back to the lobby. A client decides none of it, and is told who does.
func _ways_on() -> void:
	var rules := match_node.rules
	var decides := not match_node.puppet
	var grand_prix := rules.rounds > 0
	var more := grand_prix and rules.round < rules.rounds
	var last := grand_prix and not more
	var run_up := last and _showing_run
	_next.visible = decides and more
	# Looking at the run is only looking, so it is everybody's to do, a client's as much as the
	# host's; it is there once the run's points are in.
	_standings.visible = last and not _showing_run and _run() != null
	_rematch.visible = decides and not grand_prix
	_lobby.visible = decides and (run_up or (not grand_prix and Net.hosting()))
	_quit.visible = not grand_prix or run_up
	_host_decides.visible = match_node.puppet and Net.online() and (not last or run_up)
	_host_decides.text = (
		"The host starts the next map." if more else "The host takes everybody back to the lobby."
	)
	_caption.visible = grand_prix
	if grand_prix:
		var named := ArenaMaps.NAMES[ArenaMaps.index_of(rules.map)]
		_caption.text = "%s \u00b7 map %d of %d" % [named, rules.round, rules.rounds]
		if run_up:
			_caption.text = "Final standings after %d maps" % rules.rounds
	_keep_note.visible = more
	if more:
		_keep_note.text = _keeping_words(rules.keep_jokers)


## What happens to everybody's jokers on the way to the next map, said the once under the caption.
func _keeping_words(keep: int) -> String:
	match keep:
		GrandPrix.Keep.NONE:
			return "Nobody takes their jokers on to the next map."
		GrandPrix.Keep.CHOOSE:
			return "Pick a joker to keep for the next map, or one is kept for you at random."
		GrandPrix.Keep.ALL:
			return "Everybody takes all their jokers on to the next map."
	return "Everybody keeps one of their jokers for the next map, at random."


## From the last map's podium to the run's, GAME.md 9.7. The arena's board names the champion from
## here on, not before: until the run's podium is up, what is being looked at is the last map.
func _show_run() -> void:
	_showing_run = true
	if Game.grand_prix != null:
		Game.grand_prix.revealed = true
	fill_in()


## The Grand Prix this map belongs to, with this map's result in, or null: a single map, or a
## client that has not been told the points yet.
func _run() -> GrandPrix:
	var rules := match_node.rules
	var run := Game.grand_prix
	if rules.rounds <= 0 or run == null or run.scored_round < rules.round - 1:
		return null
	return run


func _on_grand_prix_scored(_run_now: Dictionary) -> void:
	if visible:
		fill_in()


## One player: their place and name on the left, what they banked on the right, and what they
## did most of underneath. In a Grand Prix, what the place paid in points and where that leaves
## them over the run comes first under the name.
func _entry(
	slot: PlayerSlot, rank: int, everyone: Array[PlayerStats], run: GrandPrix
) -> PanelContainer:
	var row := _row(slot)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	row.add_child(box)
	box.add_child(_headline(slot, rank))
	var awards := _award_chips(slot, everyone)
	var keeping := _keep_row(slot) if run != null else null
	if run != null:
		if awards == null:
			awards = HBoxContainer.new()
			awards.add_theme_constant_override("separation", 8)
		var paid: Array = run.points.get(slot.index, [])
		var earned: int = (
			paid[match_node.rules.round - 1] if paid.size() >= match_node.rules.round else 0
		)
		var chip := _chip("+%d points" % earned, "%d in all" % run.total(slot.index))
		awards.add_child(chip)
		awards.move_child(chip, 0)
	if awards != null:
		box.add_child(awards)
	if keeping != null:
		box.add_child(keeping)
	return row


## For a Grand Prix that lets everybody choose a joker to keep, GAME.md 9.7: on the row of each
## player at this screen, the jokers they end the map holding, one button each, the chosen one
## lit. Null for anybody else, and for a map that is not followed by another.
func _keep_row(slot: PlayerSlot) -> HBoxContainer:
	var rules := match_node.rules
	if rules.keep_jokers != GrandPrix.Keep.CHOOSE or rules.round >= rules.rounds:
		return null
	if not _is_mine(slot) or slot.kart == null or slot.kart.jokers.jokers.is_empty():
		return null
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	line.add_child(_label("Keep for the next map", 15, FAINT))
	var group := ButtonGroup.new()
	for joker: Joker in slot.kart.jokers.jokers:
		var button := MenuTheme.button(joker.display_name, 15)
		button.custom_minimum_size = Vector2.ZERO
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
			style.content_margin_left = 10.0
			style.content_margin_right = 10.0
			style.content_margin_top = 3.0
			style.content_margin_bottom = 3.0
			button.add_theme_stylebox_override(state, style)
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = _kept.get(slot.index, &"") == joker.id
		button.pressed.connect(_keep.bind(slot.index, joker.id))
		line.add_child(button)
	return line


## A player here chose which joker to keep. The host holds the run, so a client tells it.
func _keep(seat: int, id: StringName) -> void:
	_kept[seat] = id
	if match_node.puppet:
		if Net.session != null:
			Net.session.keep_joker(id)
	elif Game.grand_prix != null:
		Game.grand_prix.choose(seat, id)


## One player at the end of a Grand Prix: place and name, how many maps they won, and their points
## over the whole run, with a chip for each map saying where they finished it and what it paid.
func _run_entry(slot: PlayerSlot, rank: int, run: GrandPrix) -> PanelContainer:
	var row := _row(slot)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	row.add_child(box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	line.add_child(_label("%d" % rank, 30, FAINT))
	var name_label := _label(slot.display_name(), 30, slot.color())
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	var won := run.wins(slot.index)
	line.add_child(_label("%d %s" % [won, "win" if won == 1 else "wins"], 18, FAINT))
	var total := _label("%d pts" % run.total(slot.index), 34, Palette.CHIP_GOLD)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total.custom_minimum_size = Vector2(150.0, 0.0)
	line.add_child(total)
	box.add_child(line)
	var maps := HBoxContainer.new()
	maps.add_theme_constant_override("separation", 8)
	var places: Array = run.places.get(slot.index, [])
	var paid: Array = run.points.get(slot.index, [])
	for i: int in mini(places.size(), run.playlist.size()):
		var named := ArenaMaps.NAMES[ArenaMaps.index_of(run.playlist[i])]
		var place: int = places[i]
		var ordinal := PLACES[place - 1] if place <= PLACES.size() else "%dth" % place
		maps.add_child(_chip(named, "%s \u00b7 %d" % [ordinal, paid[i]]))
	box.add_child(maps)
	return row


## The card a player's row sits on, their colour down its leading edge the way the standings wear
## it, and lifted a shade when it is the player reading it.
func _row(slot: PlayerSlot) -> PanelContainer:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = ROW_MINE if _is_mine(slot) else ROW_BG
	style.set_corner_radius_all(8)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.border_width_left = 5
	style.border_color = slot.color()
	row.add_theme_stylebox_override("panel", style)
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
	Type.set_font(label, Type.numbers_text_font(), size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(WIDTH, 0.0)
	visible = false
	_style = MenuTheme.pane_style()
	add_theme_stylebox_override("panel", _style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	_title = Label.new()
	_title.text = TITLE
	Type.set_font(_title, Type.display_font(), Type.TITLE)
	_title.add_theme_color_override("font_color", Palette.CHIP_GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_caption = MenuTheme.subtitle("", Type.LABEL)
	_caption.visible = false
	column.add_child(_caption)
	_keep_note = MenuTheme.subtitle("", Type.LABEL)
	_keep_note.visible = false
	column.add_child(_keep_note)
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
	_host_decides = MenuTheme.subtitle("The host takes everybody back to the lobby.", Type.LABEL)
	_host_decides.visible = false
	column.add_child(_host_decides)


## The ways on from here, all built and shown as they apply, see [method _ways_on]. The host of
## an online match can take everybody back to the waiting room of GAME.md 9.6, where the next one
## is chosen and whoever wants to leave can.
func _buttons() -> HBoxContainer:
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	_next = MenuTheme.button("Next map", 26)
	_next.pressed.connect(func() -> void: Game.next_map(match_node))
	_next.visible = false
	buttons.add_child(_next)
	_standings = MenuTheme.button("Grand Prix results", 26)
	_standings.pressed.connect(_show_run)
	_standings.visible = false
	buttons.add_child(_standings)
	_lobby = MenuTheme.button("Back to lobby", 26)
	_lobby.pressed.connect(_back_to_lobby)
	_lobby.visible = false
	buttons.add_child(_lobby)
	_rematch = MenuTheme.button("Rematch", 26)
	_rematch.pressed.connect(func() -> void: match_node.rematch())
	_rematch.visible = not match_node.puppet
	buttons.add_child(_rematch)
	_quit = MenuTheme.button("Back to title", 26)
	_quit.pressed.connect(func() -> void: Game.go_to_title())
	buttons.add_child(_quit)
	return buttons


## Online, back to the waiting room with everybody; on one machine, back to the lobby a Grand
## Prix was set up in, since that is where the next one is.
func _back_to_lobby() -> void:
	if Net.online():
		Game.back_to_the_room()
	else:
		Game.go_to_lobby(Game.LobbyFor.PLAY)
