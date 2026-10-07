class_name ResultsScreen
extends PanelContainer
## The end of a match, GAME.md 3.8: everybody ranked by what they banked, with kills and deaths
## beside it and up to three awards under each name for whatever they did most.
##
## Its own screen rather than part of [MatchHud], which is about the match while it is being
## played. This is about the match once it is over, and it is the last thing anybody looks at.
##
## A payout slip, GAME.md 8.1a: a document rather than a pane, cream paper torn off the house's
## printer with the winner's color in the hairline inside its edge. The top three stand on a
## podium at the head of it, framed as the photo on the license is, see [ResultsPodium], and under
## that each player is a line of the receipt: their place on a chip, their name, dotted leaders
## across to what they banked, and the awards underneath as stubs of their own rather than run
## together into one sentence. The winner's line is stamped WINNER with the driving test's stamp,
## a barcode closes the slip, and the ways on are its stub, torn off along a perforation.

## What the screen is headed. A podium is what is on it and what the last minute of a match is
## about; "Results" is the name of a state machine's last state. The end of a Grand Prix is headed
## with the name of what has just been won.
const TITLE := "Payout slip"
const GRAND_PRIX_TITLE := "Grand Prix"
const PLACES: Array[String] = ["1st", "2nd", "3rd", "4th", "5th", "6th"]
const WIDTH := 980.0
## The ink the slip is printed in: the dark of a line, and the quieter ink of what goes with it.
const INK := HouseTheme.INK
const FAINT := HouseTheme.INK_FAINT
## The line of the player reading this slip is marked the way a line is with a highlighter, and the
## lines are parted by dashes.
const ROW_MINE := Color(HouseTheme.FOIL, 0.24)
const DASH := Color(HouseTheme.INK, 0.22)
## The photo finish's frame: the license's dark back with a gold edge, and what it is captioned.
const PHOTO_BACK := Color(0.18, 0.2, 0.26)
const PHOTO_WORDS := "PHOTO FINISH"
## The stamp on the winner's line, in the driving test's red.
const STAMP := "WINNER"
const STAMP_INK := Color(0.8, 0.17, 0.14, 0.82)
const STAMP_RADIUS := 44.0
## How far the stamp's ring keeps from the figures it stands beside.
const STAMP_CLEAR := 9.0
## The small print by the barcode, as the first stage of the story prints it, STORY.md 6.2.
const SMALL_PRINT := "PAID IN CHIPS, NOT CASH  ·  NO REFUNDS ON A BAD LAP"
## The size the story's lines on the slip are printed at, STORY.md 6.2.
const STORY_PRINT := 11
const STORY_MICRO := 10
## How big a place's chip is on a line.
const PLACE_CHIP := 36.0
## Air between the podium and the table of players: one is a picture and the other a list.
const PODIUM_GAP := 10.0
## The least room kept between the pane and the edges of the screen.
const EDGE := 12.0
## How long a watcher's podium is up before it goes on to how the run stands, in seconds.
const WATCHER_WAIT := 6.0
## How wide the buttons along the foot are at the least: narrower than a menu's, since the arrows
## and the host's word share the row with them.
const WAY_WIDTH := 240.0
## Past this many players the lines are compact, GAME.md 3.8: the sizes a compact line writes its
## name, its score and the rest in, and the size of its place's chip. A slip of eight at the full
## size runs past any screen. The stamp stays as big as it is, lying over the line under it the
## way a rubber stamp does: its lettering is drawn for that size.
const COMPACT_PAST := 4
const COMPACT_NAME := 22
const COMPACT_SCORE := 26
const COMPACT_SMALL := 14
const COMPACT_CHIP := 28.0
## How far a press of up or down moves the slip, GAME.md 3.8.
const SCROLL_STEP := 64

var match_node: Match

var _style: TicketStyle
var _title: Label
## The photo, the lines and the small print, which scroll on a short screen.
var _body: FitScroll
## The barcode and the small print at the foot of the slip, numbered for the match it pays out.
var _barcode: Control
var _code := "JJ-0000-0"
## The small print beside the barcode and the House's bulletin under it, STORY.md 6.2, drawn once a
## slip so a podium filled in again keeps what it said.
var _small_words: Label
var _bulletin: Label
var _bulletin_drawn := false
var _podium: ResultsPodium
var _rows: VBoxContainer
## Whether the lines are compact: more than [constant COMPACT_PAST] players.
var _compact := false
## The ways on from here, kept so the screen can point at one when it comes up.
var _next: Button
## In a Grand Prix, the map's podium and the run's standings as two pages, see [method _ways_on]:
## on to the standings, and back from them to the podium in the middle of a run, [method _show_map].
var _pager: ResultsPager
var _standings: Button
var _map_podium: Button
## After a run's last map, the one way on from its podium: on to the party in the room and the
## final standings. Its podium is the only page there is, so there are no pages to turn.
var _continue: Button
## The foot of the pane, in three: the arrows on the left, who decides in the middle, and the
## ways on on the right, see [method _ways_on].
var _foot: HBoxContainer
var _left: HBoxContainer
var _middle: HBoxContainer
var _right: HBoxContainer
var _rematch: Button
var _lobby: Button
var _quit: Button
## Tells a client what happens next and who decides it, since it is not them.
var _host_decides: Label
## Which map of a Grand Prix this was, GAME.md 9.7, under the title.
var _caption: Label
## Whether a map's podium has moved on to the run's standings, see [method _show_run].
var _showing_run := false
## Whether the run's standings have been up at all, which a watcher's podium goes on to by itself
## the once: one they went back from is one they are looking at.
var _run_seen := false
## Seconds until a watcher's podium goes on to the run's by itself, see [method _process], and the
## ring beside the host's word that empties as they run out, so it is not a surprise.
var _watcher_left := WATCHER_WAIT
var _watcher_ring: CountdownRing
## What happens to everybody's jokers on the way to the next map, under the caption.
var _keep_note: Label
## Whether the House has taken the slip's foot for its stamp, at the Final Hand, STORY.md 8.4.
var _house := false


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
	# And the host's say can come to a client of a dedicated server while it is up, GAME.md 9.3a.
	if Net.session != null:
		Net.session.host_controls.granted_changed.connect(screen._on_say_changed)
	return screen


## Fills the screen in and shows it. Called at the whistle, and again on a client every time the
## host says the match is over, so it is built to be filled in more than once.
func fill_in() -> void:
	_watcher_left = WATCHER_WAIT
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.free()
	var everyone: Array[PlayerStats] = []
	for slot: PlayerSlot in match_node.slots:
		everyone.append(slot.stats)
	# How a Grand Prix stands, GAME.md 9.7, is a podium of its own: everybody ranked on the points
	# of the run so far rather than on what they banked on the map just played. Every map gets
	# its own podium first, and the run's comes after it, the last map's as its final standings.
	var run := _run()
	var final := run != null and _showing_run
	var standings := run.standings(match_node.slots) if final else match_node.standings()
	if not standings.is_empty():
		MenuTheme.wear(_style, standings[0].color())
	_podium.show_top(standings)
	var stage := Story.stage_here()
	_title.text = GRAND_PRIX_TITLE if final else StorySlip.heading(stage)
	_story_print(stage)
	var winner_score := standings[0].banked if not standings.is_empty() else 0
	_code = "JJ-%04d-%d" % [absi(hash(match_node.rules.map)) % 10000, winner_score]
	_barcode.queue_redraw()
	_compact = standings.size() > COMPACT_PAST
	_rows.add_theme_constant_override("separation", 3 if _compact else 6)
	var rank := 1
	for slot: PlayerSlot in standings:
		_rows.add_child(_run_entry(slot, rank, run) if final else _entry(slot, rank, everyone))
		rank += 1
	visible = true
	_ways_on()
	# Sized and centered on what it now holds, every time. Left to size itself, a screen already
	# up measured itself partway through being filled in again -- the new title with the rows
	# cleared out -- and when the rows came back it was the size it had been before, so nothing
	# measured it again and the run's standings hung out of the bottom of a pane without them.
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Too tall for a short screen under a big UI scale, its lines scroll, see [FitScroll], GAME.md
	# 8.5; too wide for a narrow one, it is shrunk about its middle to the width there is.
	_body.fit()
	var room := get_parent_area_size() - Vector2.ONE * EDGE * 2.0
	pivot_offset = size * 0.5
	scale = Vector2.ONE * clampf(room.x / maxf(size.x, 1.0), 0.1, 1.0)
	# This is the one screen nobody asked for: it arrives on its own at the whistle, so it points
	# at what most people want next rather than waiting to be found.
	# On a map's podium that is the run's standings, with Next map beside them for a host in a
	# hurry; on the standings it is the next map. After a quick match it is another go: in the
	# lobby for a room of people online, who go back to it together, and a rematch on one machine.
	var order: Array[Button] = [_next, _continue, _standings, _map_podium]
	order.append_array([_lobby, _rematch] if Net.online() else [_rematch, _lobby])
	order.append(_quit)
	if not _showing_run:
		order.push_front(_standings)
	for first: Button in order:
		if _can_press(first):
			first.grab_focus()
			break


## Whether [param button] is up on this screen to be pressed: shown, in a part of the foot that is
## shown, and not dimmed. Asked of the screen rather than the tree, which may be hidden yet.
func _can_press(button: Button) -> bool:
	var node: Node = button
	while node != self and node is CanvasItem:
		if not (node as CanvasItem).visible:
			return false
		node = node.get_parent()
	return not button.disabled


## Which ways on the screen offers. Asked at the whistle rather than when the screen was built,
## which was the start of the match: who is hosting is a question about who is still here at the
## end of it.
##
## In a Grand Prix, GAME.md 9.7, every map's podium leads to how the run stands, and that leads
## on: to the next map, from a map that is not the last, and nowhere else -- there is no rematch of
## a map in the middle of a run, and no leaving from the podium, which is for the next map (the
## pause menu is still the way out). The two are pages, turned with the arrows, and in the middle
## of a run they can be looked at in turn. The last map's standings end the run, with no way back
## to its podium, and lead back to the lobby. A client decides none of it, and is told who does.
func _ways_on() -> void:
	var rules := match_node.rules
	var decides := not match_node.puppet or _deciding_here()
	var grand_prix := rules.rounds > 0
	var more := grand_prix and rules.round < rules.rounds
	var last := grand_prix and not more
	var standing := grand_prix and _showing_run
	var run_up := last and standing
	# A run whose points have not arrived has no standings to show, and the map goes on from its
	# own podium rather than from nowhere.
	var scored := _run() != null
	# On either page, for whoever decides: looking at the run is not a step on the way to the next
	# map, and a host who has seen enough goes on from the podium.
	_next.visible = decides and more
	# Looking at the run is only looking, so it is everybody's to do, a client's as much as the
	# host's; it is there once the run's points are in. Pages in the middle of a run only: after
	# the last map there is one page at a time, its podium and then the run's, which the party in
	# the room comes between, so a single way on takes the place of the arrows.
	_pager.visible = more and scored
	_pager.show_page(1 if standing else 0, standing, not standing)
	_continue.visible = last and not standing and scored
	_rematch.visible = decides and not grand_prix
	_lobby.visible = decides and (run_up or not grand_prix)
	_quit.visible = not grand_prix or run_up
	_host_decides.visible = not decides and Net.online() and (not last or run_up)
	_host_decides.text = (
		"The host starts the next map." if more else "The host takes everybody back to the lobby."
	)
	_lay_out_the_foot(grand_prix)
	_caption.visible = grand_prix
	if grand_prix:
		var named := ArenaMaps.NAMES[ArenaMaps.index_of(rules.map)]
		_caption.text = "%s \u00b7 map %d of %d" % [named, rules.round, rules.rounds]
		if run_up:
			_caption.text = "Final standings after %d maps" % rules.rounds
		elif standing:
			_caption.text = "Standings after map %d of %d" % [rules.round, rules.rounds]
	_keep_note.visible = more
	if more:
		_keep_note.text = _keeping_words(rules.keep_jokers)


## Somebody watching has nothing to press and nobody to press it for them, GAME.md 10.3: a map's
## podium goes on to how the run stands by itself, once it has been up long enough to be read.
func _process(delta: float) -> void:
	var going_on := _pager.visible or _continue.visible
	var counting := visible and going_on and not _showing_run and not _run_seen
	counting = counting and _watching()
	_watcher_ring.visible = counting
	if not counting:
		return
	_watcher_left -= delta
	_watcher_ring.value = _watcher_left / WATCHER_WAIT
	if _watcher_left <= 0.0:
		_watcher_left = WATCHER_WAIT
		_on_standings()


## The foot's three parts, each as wide as the others so the middle is the middle of the pane. A
## single map has no pages and its ways on are the whole row, centered, as a menu's are.
func _lay_out_the_foot(grand_prix: bool) -> void:
	_left.visible = grand_prix
	_middle.visible = grand_prix or _host_decides.visible
	_right.visible = false
	for way: Button in [_next, _continue, _lobby, _rematch, _quit]:
		_right.visible = _right.visible or way.visible
	_right.alignment = (
		BoxContainer.ALIGNMENT_END if _middle.visible else BoxContainer.ALIGNMENT_CENTER
	)
	# A part with nothing in it still holds its third, so the others stay where they are.
	if grand_prix:
		_right.visible = true
	_foot.visible = (_left.visible or _middle.visible or _right.visible) and not _house


## The shoulders on a pad turn the pages, GAME.md 9.7, the left back and the right on, as they turn
## the settings' tabs.
func _unhandled_input(event: InputEvent) -> void:
	if visible and (_pager.turn(event) or _scroll_lines(event)):
		get_viewport().set_input_as_handled()


## Up and down move a slip that does not all fit, GAME.md 3.8: a pad's and the keys' way to the
## lines a scroll away, since the cursor is on the buttons along the foot, which are a row and take
## left and right.
func _scroll_lines(event: InputEvent) -> bool:
	var bar := _body.get_v_scroll_bar()
	var hidden := roundi(bar.max_value - bar.page)
	if hidden <= 0:
		return false
	var step := 0
	if event.is_action_pressed(&"ui_up", true):
		step = -SCROLL_STEP
	elif event.is_action_pressed(&"ui_down", true):
		step = SCROLL_STEP
	if step == 0:
		return false
	_body.scroll_vertical = clampi(_body.scroll_vertical + step, 0, hidden)
	return true


static func _watching() -> bool:
	return Net.online() and Net.session != null and Net.session.watching


## Whether the host's say is at this client, as it is at a dedicated server's, GAME.md 9.3a.
static func _deciding_here() -> bool:
	return Net.session != null and not Net.session.is_host and Net.session.host_controls.mine()


func _on_say_changed(_mine: bool) -> void:
	if visible:
		fill_in()


## What happens to everybody's jokers on the way to the next map, said the once under the caption.
func _keeping_words(keep: int) -> String:
	match keep:
		GrandPrix.Keep.NONE:
			return "Nobody takes their jokers on to the next map."
		GrandPrix.Keep.CHOOSE:
			return "As the next map starts, everybody picks which of their jokers to keep."
		GrandPrix.Keep.ALL:
			return "Everybody takes all their jokers on to the next map."
	return "Everybody keeps one of their jokers for the next map, at random."


## The last map's podium hands over to the party in the room first, GAME.md 9.7, and the run's
## standings come up over it once the camera is there. Any other map's go straight up.
func _on_standings() -> void:
	var rules := match_node.rules
	var run := _run()
	if rules.round < rules.rounds or run == null or match_node.arena == null:
		_show_run()
		return
	visible = false
	GrandPrixFinale.stage(match_node, run.standings(match_node.slots), _show_run)


## From a map's podium to the run's, GAME.md 9.7. After the last map the arena's board names the
## champion from here on, not before: until the run's podium is up, what is being looked at is the
## last map. After any other map there is no champion yet to name.
func _show_run() -> void:
	_showing_run = true
	_run_seen = true
	var rules := match_node.rules
	if Game.grand_prix != null and rules.round >= rules.rounds:
		Game.grand_prix.revealed = true
	fill_in()


## Back from the run's standings to the podium of the map just played, in the middle of a run.
func _show_map() -> void:
	_showing_run = false
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
## did most of underneath, three awards at most. In a Grand Prix the points a place paid are said
## on the run's standings, which come next, see [method _run_entry], not here among the awards.
func _entry(slot: PlayerSlot, rank: int, everyone: Array[PlayerStats]) -> PanelContainer:
	var row := _row(slot)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3 if _compact else 6)
	row.add_child(box)
	box.add_child(_headline(slot, rank))
	var awards := _award_chips(slot, everyone)
	if awards != null:
		awards.add_theme_constant_override("separation", 8)
	if awards != null:
		box.add_child(awards)
	# How the House classified a player at this screen, in microprint under their line, STORY.md
	# 6.2: worked out from the same numbers as the awards over them.
	if _is_mine(slot) and slot.bot_trait == null:
		var played := maxf(match_node.rules.duration - match_node.time_left, 0.0)
		var said := StorySlip.classified(Story.stage_here(), slot, played)
		if not said.is_empty():
			var micro := Label.new()
			micro.name = "Classified"
			micro.text = said
			Type.set_font(micro, Type.micro_font(), STORY_MICRO)
			micro.add_theme_color_override("font_color", FAINT)
			box.add_child(micro)
	return row


## One player on a Grand Prix's standings: place and name, how many maps they won, what the map just
## played paid them, in green, and their points over the whole run, with a chip for each map saying
## where they finished it and what it paid.
func _run_entry(slot: PlayerSlot, rank: int, run: GrandPrix) -> PanelContainer:
	var row := _row(slot)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3 if _compact else 6)
	row.add_child(box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	line.add_child(_place_chip(slot, rank))
	# Up or down since the map before, beside the place it changed.
	var moved := run.moved(slot.index, match_node.slots)
	var marker: Control = RankArrow.create(moved > 0) if moved != 0 else Control.new()
	marker.custom_minimum_size = RankArrow.SIZE
	line.add_child(marker)
	line.add_child(_name(slot))
	line.add_child(_leader())
	var won := run.wins(slot.index)
	var wins := "%d %s" % [won, "win" if won == 1 else "wins"]
	line.add_child(_label(wins, _sized(18, COMPACT_SMALL), FAINT))
	var paid: Array = run.points.get(slot.index, [])
	if not paid.is_empty():
		var up := HouseTheme.on_paper(RankArrow.UP)
		var gained := _label("+%d" % int(paid[-1]), _sized(22, COMPACT_SMALL + 4), up)
		gained.name = "Gained"
		line.add_child(gained)
	var points := _sized(34, COMPACT_SCORE)
	var total := _label("%d pts" % run.total(slot.index), points, INK)
	Type.set_font(total, Type.numbers_font(), points)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total.custom_minimum_size = Vector2(150.0, 0.0)
	line.add_child(total)
	if rank == 1:
		_stamp_onto(total)
	box.add_child(line)
	var maps := HBoxContainer.new()
	maps.add_theme_constant_override("separation", 8)
	var places: Array = run.places.get(slot.index, [])
	for i: int in mini(places.size(), run.playlist.size()):
		var named := ArenaMaps.NAMES[ArenaMaps.index_of(run.playlist[i])]
		var place: int = places[i]
		var ordinal := PLACES[place - 1] if place <= PLACES.size() else "%dth" % place
		maps.add_child(_chip(named, "%s \u00b7 %d" % [ordinal, paid[i]]))
	box.add_child(maps)
	return row


## The line a player's row is printed on: dashes under it, and the reader's own marked as with a
## highlighter.
func _row(slot: PlayerSlot) -> PanelContainer:
	var row := PanelContainer.new()
	var style := DashStyle.new()
	style.wash = ROW_MINE if _is_mine(slot) else Color(0.0, 0.0, 0.0, 0.0)
	style.dash = DASH
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 5.0 if _compact else 10.0
	style.content_margin_bottom = 6.0 if _compact else 12.0
	row.add_theme_stylebox_override("panel", style)
	return row


## Place, name, banked score and record, on one line, with dotted leaders from the name across to
## the score the way a receipt runs a line out to its price.
func _headline(slot: PlayerSlot, rank: int) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	line.add_child(_place_chip(slot, rank))
	line.add_child(_name(slot))
	line.add_child(_leader())
	line.add_child(_label("%d kills" % slot.kills, _sized(18, COMPACT_SMALL), FAINT))
	line.add_child(_label("%d deaths" % slot.deaths, _sized(18, COMPACT_SMALL), FAINT))
	var figures := _sized(34, COMPACT_SCORE)
	var score := _label(str(slot.banked), figures, INK)
	Type.set_font(score, Type.numbers_font(), figures)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.custom_minimum_size = Vector2(150.0, 0.0)
	line.add_child(score)
	if rank == 1:
		_stamp_onto(score)
	return line


## A player's place on a chip of their color, as the standings show it, GAME.md 8.1a.
func _place_chip(slot: PlayerSlot, rank: int) -> Control:
	var chip := Control.new()
	var side := COMPACT_CHIP if _compact else PLACE_CHIP
	chip.custom_minimum_size = Vector2(side, side)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var placed := "%d" % rank
	var face := slot.color()
	chip.draw.connect(
		func() -> void: ChipArt.numbered(chip, chip.size * 0.5, chip.size.x * 0.5, face, placed)
	)
	return chip


## A player's name as it is printed on the slip: their own color, darkened until it reads on paper.
func _name(slot: PlayerSlot) -> Label:
	var size := _sized(30, COMPACT_NAME)
	var name_label := _label(slot.display_name(), size, HouseTheme.on_paper(slot.color()))
	Type.set_font(name_label, Type.STRONG, size)
	return name_label


## [param full], or [param compact] on the slip of a room of more than four, GAME.md 3.8.
func _sized(full: int, compact: int) -> int:
	return compact if _compact else full


## The dotted leaders from a name across to its score, taking whatever room is between them.
static func _leader() -> Control:
	var dots := Control.new()
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.custom_minimum_size = Vector2(24.0, 0.0)
	dots.draw.connect(
		func() -> void:
			var y := dots.size.y * 0.62
			var x := 4.0
			while x < dots.size.x - 4.0:
				dots.draw_circle(Vector2(x, y), 1.4, Color(INK, 0.4), true, -1.0, true)
				x += 8.0
	)
	return dots


## The driving test's stamp on [param score], the winner's line, a little askew, see [StampArt]:
## a control of its own over the score's label, which lays out nothing it holds.
func _stamp_onto(score: Label) -> void:
	var stamp := Control.new()
	stamp.name = "Stamp"
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var day := LicenseCard.today()
	stamp.draw.connect(
		func() -> void:
			# In the room the figures leave at the left of the label, never over them: a long
			# score pushes it onto the gray beside it rather than onto what was won.
			var font := score.get_theme_font(&"font")
			var points := score.get_theme_font_size(&"font_size")
			var figures := font.get_string_size(score.text, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
			var at := Vector2(
				score.size.x - figures - STAMP_RADIUS - STAMP_CLEAR,
				score.size.y * 0.5 - STAMP_RADIUS * 0.1
			)
			StampArt.stamp(stamp, at, STAMP_RADIUS, STAMP, "DEPT. OF KARTS", day, -0.24, STAMP_INK)
	)
	score.add_child(stamp)


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


## One award as a stub of its own, a small ticket printed in outline on the slip: what it is
## called, then what it was worth.
func _chip(title: String, value: String) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := TicketStyle.cut(Color(0.0, 0.0, 0.0, 0.0), 5.0, 10.0, 3.0)
	style.border = Color(INK, 0.34)
	style.border_width = 1.0
	chip.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 7)
	chip.add_child(line)
	var size := _sized(15, COMPACT_SMALL - 1)
	var named := _label(title, size, INK)
	Type.set_font(named, Type.STRONG, size)
	line.add_child(named)
	line.add_child(_label(value, size, FAINT))
	return chip


## Whether this row belongs to somebody sitting at this screen, so theirs stands out of the list.
func _is_mine(slot: PlayerSlot) -> bool:
	if match_node.puppet:
		return match_node.is_local_seat(slot.index)
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
	_style = MenuTheme.slip_style()
	add_theme_stylebox_override("panel", _style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	_title = MenuTheme.title(TITLE, Type.TITLE)
	# Printed in the slip's ink rather than stamped in foil: gold on cream is gold nobody can read.
	_title.add_theme_color_override("font_color", INK)
	_title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	column.add_child(_title)
	_caption = MenuTheme.subtitle("", Type.LABEL)
	_caption.add_theme_color_override("font_color", FAINT)
	_caption.visible = false
	column.add_child(_caption)
	_keep_note = MenuTheme.subtitle("", Type.LABEL)
	_keep_note.add_theme_color_override("font_color", FAINT)
	_keep_note.visible = false
	column.add_child(_keep_note)
	var band := ColorRect.new()
	band.color = HouseTheme.FOIL
	band.custom_minimum_size = Vector2(WIDTH, 3.0)
	column.add_child(band)
	# The photo, the lines and the small print scroll on a screen too short for the slip, GAME.md
	# 8.5, and the title over them and the buttons under them stay put.
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.add_child(_photo())
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	body.add_child(_rows)
	body.add_child(_small_print())
	_body = FitScroll.around(body, self)
	_body.name = "Body"
	# The slip's own ink, so the edge with more lines past it darkens as paper does in shadow.
	_body.fade = Color(HouseTheme.INK, 0.3)
	column.add_child(_body.shaded())
	var tear := MenuTheme.perforation()
	column.add_child(tear)
	# Scrolled, the lines run right up to the foil band over them and down to the hairline over
	# the tear, and the shades lie against those rather than in the paper between.
	var gap := float(column.get_theme_constant(&"separation"))
	_body.reach(gap, gap + tear.line_over())
	column.add_child(_build_the_foot())


## The Final Hand's slip, STORY.md 8.4: [param section] under the lines, past them, and
## [param ways] in place of the ways on, which go.
func take_the_house(section: Control, ways: Control) -> void:
	_house = true
	_rows.get_parent().add_child(section)
	_foot.add_sibling(ways)
	_foot.visible = false


## The podium framed as the photo on the license is: a dark back with a gold edge, captioned under
## it, GAME.md 8.1a.
func _photo() -> Control:
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 4)
	var frame := PanelContainer.new()
	var back := StyleBoxFlat.new()
	back.bg_color = PHOTO_BACK
	back.set_corner_radius_all(8)
	back.set_border_width_all(3)
	back.border_color = HouseTheme.FOIL
	back.anti_aliasing = true
	frame.add_theme_stylebox_override("panel", back)
	_podium = ResultsPodium.create()
	_podium.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_child(_podium)
	holder.add_child(frame)
	var words := Label.new()
	words.text = PHOTO_WORDS
	Type.strong(words, 11, FAINT)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(words)
	# The podium is a picture and the rows are a table; they want air between them rather than
	# the spacing that holds one row off the next.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, PODIUM_GAP)
	holder.add_child(gap)
	return holder


## The foot of the slip: the match's number as a barcode on the left and the small print on the
## right, GAME.md 8.1a, and the House's bulletin on a line of its own under it, STORY.md 6.2.
func _small_print() -> Control:
	var foot := VBoxContainer.new()
	foot.add_theme_constant_override("separation", 2)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	_barcode = Control.new()
	_barcode.custom_minimum_size = Vector2(Barcode.width_of("JJ-0000-00000") + 8.0, 46.0)
	_barcode.draw.connect(
		func() -> void:
			Barcode.draw(
				_barcode, Rect2(Vector2(0.0, 4.0), _barcode.size - Vector2(0.0, 4.0)), _code, INK
			)
	)
	line.add_child(_barcode)
	_small_words = Label.new()
	_small_words.name = "SmallPrint"
	_small_words.text = SMALL_PRINT
	Type.strong(_small_words, STORY_PRINT, FAINT)
	_small_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_small_words.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_small_words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(_small_words)
	foot.add_child(line)
	_bulletin = Label.new()
	_bulletin.name = "Bulletin"
	Type.strong(_bulletin, STORY_PRINT, FAINT)
	_bulletin.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bulletin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bulletin.visible = false
	foot.add_child(_bulletin)
	return foot


## The story's small print and bulletin for [param stage], STORY.md 6.2, the bulletin drawn once.
func _story_print(stage: int) -> void:
	var profile := Game.settings.profile
	_small_words.text = StorySlip.small_print(stage, profile)
	if not _bulletin_drawn:
		_bulletin_drawn = true
		var draw := RandomNumberGenerator.new()
		draw.randomize()
		_bulletin.text = StorySlip.bulletin(stage, profile, match_node.slots, draw)
	_bulletin.visible = not _bulletin.text.is_empty()


## The foot's three parts, see [method _lay_out_the_foot].
func _build_the_foot() -> HBoxContainer:
	_foot = HBoxContainer.new()
	_foot.add_theme_constant_override("separation", 24)
	_left = _part(BoxContainer.ALIGNMENT_BEGIN)
	_pager = ResultsPager.create(true)
	_pager.visible = false
	_standings = _pager.on
	_standings.pressed.connect(_on_standings)
	_map_podium = _pager.back
	_map_podium.pressed.connect(_show_map)
	_left.add_child(_pager)
	_middle = _part(BoxContainer.ALIGNMENT_CENTER)
	_middle.add_theme_constant_override("separation", 12)
	_host_decides = MenuTheme.subtitle("The host takes everybody back to the lobby.", Type.LABEL)
	_host_decides.add_theme_color_override("font_color", FAINT)
	_host_decides.visible = false
	_middle.add_child(_host_decides)
	_watcher_ring = CountdownRing.create()
	_watcher_ring.visible = false
	_middle.add_child(_watcher_ring)
	_right = _buttons()
	for part: HBoxContainer in [_left, _middle, _right]:
		_foot.add_child(part)
	return _foot


static func _part(alignment: BoxContainer.AlignmentMode) -> HBoxContainer:
	var part := HBoxContainer.new()
	part.alignment = alignment
	part.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	part.add_theme_constant_override("separation", 24)
	return part


## The ways on from here, all built and shown as they apply, see [method _ways_on]. The host of
## an online match can take everybody back to the waiting room of GAME.md 9.6, where the next one
## is chosen and whoever wants to leave can.
func _buttons() -> HBoxContainer:
	var buttons := _part(BoxContainer.ALIGNMENT_END)
	_next = MenuTheme.button("Next map", 26)
	_next.pressed.connect(func() -> void: Game.next_map(match_node))
	_next.visible = false
	buttons.add_child(_next)
	_continue = MenuTheme.button("Continue", 26)
	_continue.pressed.connect(_on_standings)
	_continue.visible = false
	buttons.add_child(_continue)
	_rematch = MenuTheme.button("Rematch", 26)
	_rematch.pressed.connect(func() -> void: Game.rematch(match_node))
	_rematch.visible = not match_node.puppet
	buttons.add_child(_rematch)
	_lobby = MenuTheme.button("Back to lobby", 26)
	_lobby.pressed.connect(_back_to_lobby)
	_lobby.visible = false
	buttons.add_child(_lobby)
	_quit = MenuTheme.button("Back to title", 26)
	_quit.pressed.connect(func() -> void: Game.go_to_title())
	buttons.add_child(_quit)
	# Printed on the slip, GAME.md 8.1a: the ways on that carry the match on are tickets of ink with
	# foil words, the rest only ways out, drawn in ink.
	for way: Button in [_next, _continue, _lobby, _rematch, _quit]:
		way.custom_minimum_size.x = WAY_WIDTH
		way.theme_type_variation = HouseTheme.PAPER_BUTTON
	for onward: Button in [_next, _continue, _rematch]:
		onward.theme_type_variation = HouseTheme.PAPER_PRIMARY
	return buttons


## Online, back to the waiting room with everybody; on one machine, back to the lobby a Grand
## Prix was set up in, since that is where the next one is.
func _back_to_lobby() -> void:
	if Net.online():
		Game.back_to_the_room()
	else:
		Game.go_to_lobby(match_node)
