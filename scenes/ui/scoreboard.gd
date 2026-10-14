class_name Scoreboard
extends GridContainer
## The running order down the right-hand side, GAME.md 8.3. Every kart gets a row: its banked
## score, and next to it what it is still carrying around unbanked. Rows are ordered by what is
## banked alone, which is the order the match is actually won in: a pot is worth nothing until it
## reaches the Junction, and a board that counted it had a leader who had won nothing yet and
## dropped three places on being shot. The leader's row is the biggest and the last place the
## smallest, and the players on this screen are boxed in their own color. A carried pot big
## enough to win the match on the next cash-out blinks, GAME.md 3.4, whoever is carrying it.
##
## Each row is a strip bled off the right edge of the screen, GAME.md 8.1a, its place on a chip of
## its player's color; the leader's row is edged in foil, and a player on this screen has their
## own color striped along the row's slanted end.
##
## A room of more than four, GAME.md 9.3, has smaller rows, and on a short screen shows four of
## them: the top of the order, with a player on this screen who is further down in the last.
##
## In team play, GAME.md 3.14, it has a row for each team and none for its karts: the team's
## place, suit and name, its bank and what its karts carry, ordered by bank, the leading team's
## edged in foil, and the crown on the row of the team whose kart carries the bounty. A row for
## every kart under its team's was too many rows. The waiting room's list goes by team as well,
## GAME.md 9.6: each team's suit and name, and the names of who is on it under them, smaller and on
## shorter strips, so the team's row reaches further in and stands out over them.

## The leader's row and the last place's, kept small, GAME.md 8.2: the standings run down the
## right of the room, and every row of them is table nobody can see a kart on.
const TOP_FONT := 24
const BOTTOM_FONT := 15
## The leader's and the last place's sizes in a room of eight, and the most rows a room of more
## than four shows on a screen shorter than [constant SHORT], in its own units after the UI scale,
## GAME.md 8.5: a phone, or a big UI scale.
const CROWDED_TOP := 19
const CROWDED_BOTTOM := 13
const SHORT := 800.0
const SHORT_ROWS := 4
const RISK_FONT := 15
const DIM := Color(0.82, 0.82, 0.86)
## Blinks a second of the carried pot that would end the match.
const WIN_BLINK := 3.2
## How big a name is on the roster of the waiting room, where nobody is ahead of anybody.
const ROSTER_FONT := 22
## How far a row's end leans, and how wide the stripe along it is.
const SLANT := 12.0
const STRIPE := 6.0
## How strong the wash of a row's own color is at its two ends, see [member StripStyle.glow].
const GLOW := 0.32
## How strongly the foil edges the leader's row.
const LEADER := Color(HouseTheme.FOIL, 0.9)
## How wide each heart of a showdown's row is, as a share of the row's type size.
const FATE_HEART := 0.95
## In the waiting room's list in team play, how much smaller a name under its team is set, and how
## much further in the team's row reaches than the longest of them, GAME.md 9.6.
const SUB_DROP := 5
const SUB_INDENT := 44.0

var match_node: Match
## A list of who is in the room rather than a running order, GAME.md 9.6: everybody at one size,
## in the order they arrived, with no place and no score, since nothing is being played for. Past
## four of them, in two columns.
var roster := false

## Slot index to its row's parts, and in team play team to its head row's, GAME.md 3.14.
var _rows: Dictionary[int, Dictionary] = {}
var _heads: Dictionary[int, Dictionary] = {}
## Where the blink is in its cycle, shared by every row so they flash together rather than
## drifting apart into a fairground.
var _beat := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	grow_vertical = Control.GROW_DIRECTION_BOTH
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	# Off the edge, as a strip is, GAME.md 8.1a.
	offset_right = 0.0
	# The middle of the right-hand side is the drift and nitro buttons' on a touch screen, GAME.md
	# 4.2, so there the board hangs from the top right corner instead, under the menu button.
	if TouchInput.enabled:
		set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		grow_vertical = Control.GROW_DIRECTION_END
		grow_horizontal = Control.GROW_DIRECTION_BEGIN
		offset_right = 0.0
		offset_top = TouchControls.below_menu()
	add_theme_constant_override("v_separation", 3)
	add_theme_constant_override("h_separation", 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The scoreboard's own view of the order, which is the results screen's: by what is banked, then
## by the tie-breaks the match uses. Highest first.
func order() -> Array[PlayerSlot]:
	var ranked := match_node.slots.duplicate()
	# A showdown's goes by who lasted, and leaves out everybody sitting it out, GAME.md 9.7a.
	if match_node.rules.showdown() and not roster:
		ranked = match_node.standings().filter(
			func(slot: PlayerSlot) -> bool: return not slot.benched
		)
	elif not roster:
		ranked.sort_custom(PlayerSlot.by_banked)
	return ranked


func _process(delta: float) -> void:
	if match_node == null or match_node.slots.is_empty() or not visible:
		return
	_beat += delta
	var ranked := order()
	if match_node.rules.teams > 0:
		_show_teams()
		return
	for head: Dictionary in _heads.values():
		(head["panel"] as Control).visible = false
	var shown := shown_of(ranked)
	var wanted := 2 if roster and ranked.size() > SHORT_ROWS else 1
	if columns != wanted:
		columns = wanted
	for rank: int in ranked.size():
		var slot := ranked[rank]
		var row := _row(slot)
		var panel: PanelContainer = row["panel"]
		if panel.get_index() != rank:
			move_child(panel, rank)
		panel.visible = slot in shown
		if panel.visible:
			_update_row(row, slot, rank, shown.find(slot), shown.size())


## The rows of [param ranked] there is room for: all of them, and on a short screen four of a room
## of more, the top of the order with whoever plays on this screen further down in the last of
## them, at their own place. A roster in two columns has room for everybody.
func shown_of(ranked: Array[PlayerSlot]) -> Array[PlayerSlot]:
	if roster or ranked.size() <= SHORT_ROWS or get_viewport_rect().size.y >= SHORT:
		return ranked
	var shown := ranked.slice(0, SHORT_ROWS)
	for slot: PlayerSlot in ranked.slice(SHORT_ROWS):
		if not slot.is_local_human():
			continue
		for i: int in range(shown.size() - 1, -1, -1):
			if not shown[i].is_local_human():
				shown.remove_at(i)
				shown.append(slot)
				break
	return shown


## The teams in order, GAME.md 3.14: the leading team's row the biggest and the last's the
## smallest, and no row for a kart. As the waiting room's list, 9.6, the teams in the suits' order,
## each with the names of who is on it under it.
func _show_teams() -> void:
	if columns != 1:
		columns = 1
	var teams := _roster_teams() if roster else Teams.standings(match_node.slots)
	for row: Dictionary in _rows.values():
		(row["panel"] as Control).visible = false
	for team: int in _heads:
		(_heads[team]["panel"] as Control).visible = team in teams
	var at := 0
	var widest := 0.0
	for rank: int in teams.size():
		var team := teams[rank]
		var share := 0.0 if teams.size() < 2 else float(rank) / float(teams.size() - 1)
		var size := ROSTER_FONT if roster else roundi(lerpf(TOP_FONT, BOTTOM_FONT, share))
		var head := _head(team)
		var panel: PanelContainer = head["panel"]
		if panel.get_index() != at:
			move_child(panel, at)
		panel.visible = true
		_update_head(head, team, rank, size, teams.size())
		at += 1
		if not roster:
			continue
		for slot: PlayerSlot in Teams.members(match_node.slots, team):
			var row := _row(slot)
			var line: PanelContainer = row["panel"]
			if line.get_index() != at:
				move_child(line, at)
			line.visible = true
			_update_row(row, slot, 0, 0, 1, true)
			widest = maxf(widest, line.get_combined_minimum_size().x)
			at += 1
	# Each team's row reaching further in than the names under it, see [constant SUB_INDENT].
	if roster:
		for team: int in teams:
			var head: PanelContainer = _heads[team]["panel"]
			head.custom_minimum_size.x = widest + SUB_INDENT


## The teams somebody in the waiting room is on, in the suits' order, GAME.md 9.6.
func _roster_teams() -> Array[int]:
	var teams: Array[int] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.team >= 0 and slot.team not in teams:
			teams.append(slot.team)
	teams.sort()
	return teams


## Draws [param team]'s head row at its [param rank] of [param count] teams, in [param size].
func _update_head(head: Dictionary, team: int, rank: int, size: int, count: int) -> void:
	var slots := match_node.slots
	var place: Label = head["place"]
	var placed := "%d" % (rank + 1)
	if place.text != placed:
		place.text = placed
		(head["chip"] as Control).queue_redraw()
	var leading := rank == 0 and count > 1 and not roster
	var mine := false
	var carried := 0
	var winning := false
	var hunted := false
	for slot: PlayerSlot in Teams.members(slots, team):
		mine = mine or slot.is_local_human()
		carried += slot.kart.pot.value() if slot.kart != null else 0
		winning = winning or match_node.would_win(slot)
		hunted = hunted or match_node.bounty_slot == slot.index
	(head["bounty"] as Control).visible = hunted
	for style: StripStyle in [head["plain"], head["own"]]:
		var edge := LEADER if leading else Color(0.0, 0.0, 0.0, 0.0)
		if style.edge_top != edge:
			style.edge_top = edge
			style.edge_bottom = Color(edge, edge.a * 0.5)
	var score: Label = head["score"]
	var risk: Label = head["risk"]
	# The waiting room's list plays for nothing: no place, no bank, nothing carried.
	for part: Control in [head["chip"], score, risk]:
		part.visible = not roster
	score.text = str(Teams.bank(slots, team))
	risk.text = "+%d" % carried if carried > 0 else ""
	for label: Label in [place, head["name"], score]:
		Type.set_font(label, Type.numbers_text_font(), size)
	Type.set_font(risk, Type.numbers_text_font(), maxi(size - 8, RISK_FONT))
	var side := float(size) + 6.0
	for mark: Control in [head["chip"], head["suit"]]:
		if mark.custom_minimum_size.x != side:
			mark.custom_minimum_size = Vector2(side, side)
	Type.ink(score, Color.WHITE if mine else DIM)
	_blink(risk, winning)
	var panel: PanelContainer = head["panel"]
	var skin: StyleBox = head["own"] if mine else head["plain"]
	if panel.get_theme_stylebox(&"panel") != skin:
		panel.add_theme_stylebox_override(&"panel", skin)
	panel.custom_minimum_size = Vector2(0.0, size + 4.0)


## A carried pot that would win the match blinks, GAME.md 3.4; otherwise it is plain gold.
func _blink(risk: Label, winning: bool) -> void:
	if winning:
		var wave := 0.5 + 0.5 * sin(_beat * WIN_BLINK * TAU)
		Type.ink(risk, Palette.CHIP_GOLD.lerp(Color.WHITE, wave))
		risk.modulate = Color(1.0, 1.0, 1.0, lerpf(0.45, 1.0, wave))
	else:
		Type.ink(risk, Palette.CHIP_GOLD)
		risk.modulate = Color.WHITE


## Draws [param slot]'s row at its [param rank] in the order, the [param at]th of [param count]
## rows shown: the leader biggest and the last shown smallest, all of them smaller in a room of
## more than four. A name under its team in the waiting room's list, [param sub], is set smaller on
## a strip only as long as it, GAME.md 9.6.
func _update_row(
	row: Dictionary, slot: PlayerSlot, rank: int, at: int, count: int, sub := false
) -> void:
	var share := 0.0 if count < 2 else float(at) / float(count - 1)
	var crowd := clampf(float(count - SHORT_ROWS) / float(SHORT_ROWS), 0.0, 1.0)
	var top := lerpf(TOP_FONT, CROWDED_TOP, crowd)
	var bottom := lerpf(BOTTOM_FONT, CROWDED_BOTTOM, crowd)
	var size := ROSTER_FONT if roster else roundi(lerpf(top, bottom, share))
	if sub:
		size -= SUB_DROP
	var local := slot.is_local_human()
	var color := slot.color()
	var place: Label = row["place"]
	var name_label: Label = row["name"]
	var score: Label = row["score"]
	var risk: Label = row["risk"]
	var placed := "%d" % (rank + 1)
	var chip_ink: Color = row["chip_ink"]
	if place.text != placed or chip_ink != color:
		place.text = placed
		row["chip_ink"] = color
		(row["chip"] as Control).queue_redraw()
		# A color changed, the player's own over the room or every one for a kind of color
		# blindness: the stripe and glow of a row of this screen's with it, as its chip.
		var own: StripStyle = row["own"]
		own.stripe = color
		own.glow = Color(color, GLOW)
	(row["chip"] as Control).visible = not roster
	var leading := rank == 0 and not roster and count > 1
	for style: StripStyle in [row["plain"], row["own"]]:
		var edge := LEADER if leading else Color(0.0, 0.0, 0.0, 0.0)
		if style.edge_top != edge:
			style.edge_top = edge
			style.edge_bottom = Color(edge, edge.a * 0.5)
	name_label.text = FinalHand.name_of(slot)
	score.text = str(slot.banked)
	var unbanked := slot.kart.pot.value() if slot.kart != null else 0
	risk.text = "+%d" % unbanked if unbanked > 0 else ""
	_show_fate(row, slot, size)
	var hunted := match_node.bounty_slot == slot.index
	(row["bounty"] as Control).visible = hunted
	(row["lag"] as LagWarning).show_trip(slot.round_trip)
	# The place is drawn on its chip; the label only keeps the number and its size.
	place.visible = false
	score.visible = not roster and not match_node.rules.showdown()
	risk.visible = score.visible
	# Every one of these is set only on a change, see [method Type.set_font]: this runs for every
	# row of every frame, and a row that has not changed costs nothing.
	for label: Label in [place, name_label, score]:
		Type.set_font(label, Type.numbers_text_font(), size)
	Type.set_font(risk, Type.numbers_text_font(), maxi(size - 8, RISK_FONT))
	var chip: Control = row["chip"]
	var side := float(size) + 6.0
	if chip.custom_minimum_size.x != side:
		chip.custom_minimum_size = Vector2(side, side)
	# A seat taken over by a bot, or by a player from a bot, says so as it changes.
	var bot: Control = row["bot"]
	bot.visible = not slot.is_human() and not slot.is_dummy()
	if bot.custom_minimum_size.x != float(size):
		bot.custom_minimum_size = Vector2(float(size), 0.0)
	Type.ink(name_label, color)
	Type.ink(score, Color.WHITE if local else DIM)
	# Enough in the pot to win by banking it: the number says so itself rather than waiting for
	# the results screen to. Everyone's row blinks, so a rival about to finish it is as plain as
	# your own chance to.
	_blink(risk, match_node.would_win(slot))
	var panel: PanelContainer = row["panel"]
	var skin: StyleBox = row["own"] if local else row["plain"]
	if panel.get_theme_stylebox(&"panel") != skin:
		panel.add_theme_stylebox_override(&"panel", skin)
	panel.custom_minimum_size = Vector2(0.0, size + 4.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END if sub else Control.SIZE_FILL


## In a showdown, GAME.md 9.7a, a row says how its kart stands rather than what it banked: a heart
## for every life of a kart still in, in its color, and a skull for one that is out. Drawn again
## only when that changes.
func _show_fate(row: Dictionary, slot: PlayerSlot, size: int) -> void:
	var fate: Control = row["fate"]
	fate.visible = match_node.rules.showdown() and not roster
	if not fate.visible:
		return
	var out := slot.out_at >= 0
	var lives := 0 if out or slot.kart == null else slot.kart.lives
	var wide := float(size) * (FATE_HEART * maxi(lives, 1) if not out else 1.0)
	if fate.custom_minimum_size.x != wide:
		fate.custom_minimum_size = Vector2(wide, 0.0)
	var said := Vector2i(lives, int(out))
	if row["fate_said"] != said:
		row["fate_said"] = said
		fate.queue_redraw()


## Draws [param slot]'s hearts or skull into [param fate], see [method _show_fate].
func _draw_fate(fate: Control, slot: PlayerSlot) -> void:
	var side := minf(fate.size.y, fate.size.x)
	if slot.out_at >= 0:
		var box := Rect2((fate.size - Vector2(side, side)) * 0.5, Vector2(side, side))
		IconShapes.skull(fate, box, DIM, HouseTheme.STOCK)
		return
	var lives := slot.kart.lives if slot.kart != null else 0
	var each := fate.size.x / float(maxi(lives, 1))
	for i: int in lives:
		var box := Rect2(Vector2(each * i, (fate.size.y - each) * 0.5), Vector2(each, each))
		IconShapes.heart(fate, box, 0.5, 0.5, 0.4, slot.color())


## Builds a row the first time its slot shows up. Rows live as long as the scoreboard; only their
## order and their contents change.
## The label [param slot]'s banked score is written in, or null while it has no row.
func score_label(slot: int) -> Label:
	return _rows[slot]["score"] if _rows.has(slot) else null


## The panel [param slot]'s row is drawn on, or null while it has none.
func row_panel(slot: int) -> Control:
	return _rows[slot]["panel"] if _rows.has(slot) else null


func _row(slot: PlayerSlot) -> Dictionary:
	if _rows.has(slot.index):
		return _rows[slot.index]
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plain := StripStyle.cut(true, SLANT, 16.0, SLANT + 10.0, 3.0)
	plain.fill = Color(HouseTheme.STOCK, 0.72)
	var own := StripStyle.cut(true, SLANT, 16.0, SLANT + STRIPE + 12.0, 3.0)
	own.fill = Color(HouseTheme.STOCK, 0.88)
	own.stripe = slot.color()
	own.stripe_width = STRIPE
	own.glow = Color(slot.color(), GLOW)
	panel.add_theme_stylebox_override("panel", plain)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(line)
	# The place, on a chip of the player's color, GAME.md 8.1a.
	var chip := Control.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var place := _label(HORIZONTAL_ALIGNMENT_CENTER, 0.0)
	place.visible = false
	chip.add_child(place)
	chip.draw.connect(
		func() -> void:
			var radius := minf(chip.size.x, chip.size.y) * 0.5
			ChipArt.numbered(chip, chip.size * 0.5, radius, slot.color(), place.text)
	)
	var name_label := _label(HORIZONTAL_ALIGNMENT_LEFT, 0.0)
	# The name and the robot's head after it, together, taking the room the name always took.
	var named := HBoxContainer.new()
	named.mouse_filter = Control.MOUSE_FILTER_IGNORE
	named.add_theme_constant_override("separation", 6)
	named.custom_minimum_size = Vector2(120.0, 0.0)
	named.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	named.add_child(name_label)
	var score := _label(HORIZONTAL_ALIGNMENT_RIGHT, 64.0)
	var risk := _label(HORIZONTAL_ALIGNMENT_RIGHT, 48.0)
	# The bounty, GAME.md 3.6, as the crown its kart wears.
	var bounty := Control.new()
	bounty.name = "Bounty"
	bounty.custom_minimum_size = Vector2(22.0, 0.0)
	bounty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bounty.visible = false
	bounty.draw.connect(
		func() -> void:
			var side := minf(bounty.size.x, bounty.size.y) * 0.9
			var box := Rect2((bounty.size - Vector2(side, side)) * 0.5, Vector2(side, side))
			IconShapes.crown(bounty, box, Palette.CHIP_GOLD)
	)
	# A bot, a robot's head after its name, so a room of players and bots says which is which.
	var bot := Control.new()
	bot.name = "Bot"
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot.visible = not slot.is_human() and not slot.is_dummy()
	bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bot.draw.connect(
		func() -> void:
			var side := minf(bot.size.x, bot.size.y) * 0.85
			var box := Rect2((bot.size - Vector2(side, side)) * 0.5, Vector2(side, side))
			IconShapes.robot(bot, box, DIM, HouseTheme.STOCK)
	)
	named.add_child(bot)
	# A slow line to the host, beside the name, GAME.md 10.3.
	var lag := LagWarning.make(16.0, false)
	lag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# How a kart stands in a showdown, see [method _show_fate].
	var fate := Control.new()
	fate.name = "Fate"
	fate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fate.visible = false
	fate.draw.connect(func() -> void: _draw_fate(fate, slot))
	for label: Control in [chip, named, lag, score, risk, fate, bounty]:
		line.add_child(label)
	add_child(panel)
	var row: Dictionary = {
		"panel": panel,
		"place": place,
		"chip": chip,
		"chip_ink": slot.color(),
		"name": name_label,
		"score": score,
		"risk": risk,
		"bounty": bounty,
		"bot": bot,
		"lag": lag,
		"fate": fate,
		"fate_said": Vector2i(-1, -1),
		"plain": plain,
		"own": own
	}
	_rows[slot.index] = row
	return row


## Builds [param team]'s head row the first time it shows up, GAME.md 3.14: its place on a chip of
## its color, its suit, its name, its bank and what its karts carry.
func _head(team: int) -> Dictionary:
	if _heads.has(team):
		return _heads[team]
	var color := Teams.color(team)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plain := StripStyle.cut(true, SLANT, 16.0, SLANT + 10.0, 3.0)
	plain.fill = Color(HouseTheme.STOCK, 0.9)
	var own := StripStyle.cut(true, SLANT, 16.0, SLANT + STRIPE + 12.0, 3.0)
	own.fill = Color(HouseTheme.STOCK, 0.94)
	own.stripe = color
	own.stripe_width = STRIPE
	own.glow = Color(color, GLOW)
	panel.add_theme_stylebox_override("panel", plain)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(line)
	var chip := Control.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var place := _label(HORIZONTAL_ALIGNMENT_CENTER, 0.0)
	place.visible = false
	chip.add_child(place)
	chip.draw.connect(
		func() -> void:
			var radius := minf(chip.size.x, chip.size.y) * 0.5
			ChipArt.numbered(chip, chip.size * 0.5, radius, Teams.color(team), place.text)
	)
	var suit := Control.new()
	suit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	suit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	suit.draw.connect(
		func() -> void:
			var side := minf(suit.size.x, suit.size.y) * 0.86
			TeamArt.draw_suit(
				suit, Rect2((suit.size - Vector2(side, side)) * 0.5, Vector2.ONE * side), team
			)
	)
	var name_label := _label(HORIZONTAL_ALIGNMENT_LEFT, 0.0)
	name_label.text = Teams.name_of(team)
	name_label.custom_minimum_size = Vector2(94.0, 0.0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Type.ink(name_label, color)
	var score := _label(HORIZONTAL_ALIGNMENT_RIGHT, 64.0)
	var risk := _label(HORIZONTAL_ALIGNMENT_RIGHT, 48.0)
	# The bounty's crown, GAME.md 3.10, while a kart of the team carries it.
	var bounty := Control.new()
	bounty.name = "Bounty"
	bounty.custom_minimum_size = Vector2(22.0, 0.0)
	bounty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bounty.visible = false
	bounty.draw.connect(
		func() -> void:
			var side := minf(bounty.size.x, bounty.size.y) * 0.9
			var box := Rect2((bounty.size - Vector2(side, side)) * 0.5, Vector2(side, side))
			IconShapes.crown(bounty, box, Palette.CHIP_GOLD)
	)
	for part: Control in [chip, suit, name_label, score, risk, bounty]:
		line.add_child(part)
	add_child(panel)
	var head: Dictionary = {
		"panel": panel,
		"place": place,
		"chip": chip,
		"suit": suit,
		"name": name_label,
		"score": score,
		"risk": risk,
		"bounty": bounty,
		"plain": plain,
		"own": own,
	}
	_heads[team] = head
	return head


func _label(align: HorizontalAlignment, width: float) -> Label:
	var label := Label.new()
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(width, 0.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return HudText.shadowed(label, 1)
