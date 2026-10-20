class_name HudBlock
extends RefCounted
## A player's corner of the match HUD, GAME.md 8.3 and 8.1a: their name, what they have banked, the
## pot, kills and deaths, the lives, the speed dial and the nitro cells, the item row and the hints,
## on a strip of the house's stock bled off the corner of the screen, its inner end slanted and
## striped in the player's color. Built here and kept up to date by [MatchHud], which holds what
## this hands back.

## How far the strip's inner end leans over its height, and how wide its stripe is.
const SLANT := 30.0
const STRIPE := 8.0
## The room inside the strip: on the edge it comes off, on its slanted end past the slant and the
## stripe, above, and below over the microprint along its foot.
const OUTER := 20.0
const INNER := SLANT + STRIPE + 12.0
const ABOVE := 12.0
const BELOW := 18.0
## How big the speed dial is, and the nitro cells under it.
const DIAL := 88.0
const CELLS := Vector2(118.0, 12.0)
## How much of the name's row the kills and deaths keep for themselves.
const STATS_WIDTH := 92.0
## How tall the robot's head after a bot's name is, against the name's line.
const BOT_SHARE := 0.62
## The ticket the control hints are on, hung from the strip: how far in from the screen's edge it
## hangs, the notch of its free corners, and the room round the hints, across and down.
const TAB_INSET := 14.0
const TAB_NOTCH := 7.0
const TAB_ROOM := Vector2(12.0, 6.0)
## How tall the tab of hints is, for the room kept under a block before it has been shown.
const TAB_TALL := 36.0
## The microprint along the foot of each strip, and the engraving's strength on it.
const MICRO := "SEAT %d · JACKPOT JUNCTION · DEPT. OF KARTS · "
const ENGRAVED := 0.07


## The block for [param slot] in [param corner] of [param hud], with a heart for each of the
## [param lives] a kart has, added to it. What is in it, for the HUD to keep up to date.
static func make(hud: CanvasLayer, slot: PlayerSlot, corner: int, lives_each: int) -> Dictionary:
	var right := corner % 2 == 1
	var bottom := corner >= 2
	# A strip bled off the corner rather than a card standing off it, GAME.md 8.1a: the corner of
	# the screen is the edge of the strip, so it reads as part of the screen's frame rather than
	# as one more thing laid over the table.
	var card := PanelContainer.new()
	card.name = "Block%d" % slot.index
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", strip(slot, right, bottom))
	card.custom_minimum_size = Vector2(MatchHud.BLOCK_WIDTH, 0.0)
	card.set_anchors_and_offsets_preset(MatchHud.BLOCK_ANCHORS[corner])
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	hud.add_child(card)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var align := HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	var line_up := BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	var name_label := Label.new()
	name_label.text = slot.display_name()
	Type.strong(name_label, Type.LARGE, slot.color())
	# A robot's head after the name while a bot drives the seat, as the standings have, see
	# [method place_bot]: the demo for a booth's seats, GAME.md 9.8, until somebody takes one.
	var bot := Control.new()
	bot.name = "Bot"
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot.visible = false
	bot.draw.connect(
		func() -> void:
			IconShapes.robot(bot, Rect2(Vector2.ZERO, bot.size), slot.color(), HouseTheme.STOCK)
	)
	name_label.add_child(bot)
	var stats := Label.new()
	Type.set_font(stats, Type.numbers_text_font(), Type.LABEL)
	stats.add_theme_color_override("font_color", HouseTheme.QUIET)
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Room for two counts in double figures, so the row never moves as they climb.
	stats.custom_minimum_size = Vector2(STATS_WIDTH, 0.0)
	# Beside the name, a warning while this player's line to the host is slow, GAME.md 10.3.
	var lag := LagWarning.make(18.0, true)
	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 10)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heading: Array[Control] = [name_label, lag, stats]
	if right:
		heading.reverse()
	for part: Control in heading:
		name_row.add_child(part)
	box.add_child(name_row)
	var banked := Label.new()
	# The banked score is the number a player checks mid-corner, so it is set the largest and in the
	# heaviest cut there is, GAME.md 8.3; smaller where it runs to more figures than the corner is
	# wide, see [method HudText.fit], the line keeping its height so the corner never moves.
	Type.numbers(banked, Type.SCORE)
	banked.custom_minimum_size.y = banked.get_theme_font(&"font").get_height(Type.SCORE)
	banked.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for label: Label in [name_label, banked, stats]:
		label.horizontal_alignment = align
		# Clipped rather than measured: a label that asks for the width of its own text is what
		# made the block breathe in and out with the speedometer.
		label.clip_text = true
		HudText.shadowed(label)
	# The score and the pot on the edge the strip comes off, the dial and the tank on its inner end,
	# toward the middle of the screen: one number to read and one gauge to glance at.
	var middle := HBoxContainer.new()
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.add_theme_constant_override("separation", 10)
	box.add_child(middle)
	var counts := VBoxContainer.new()
	counts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counts.add_theme_constant_override("separation", 2)
	counts.add_child(banked)
	var lives := HBoxContainer.new()
	lives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lives.add_theme_constant_override("separation", 6)
	lives.alignment = line_up
	var pips: Array = []
	for i: int in lives_each:
		pips.append(_pip(lives, slot))
	# In team play what this player banked of the team's, small beside the lives, GAME.md 3.14.
	var share := Label.new()
	Type.set_font(share, Type.numbers_text_font(), Type.LABEL)
	share.add_theme_color_override("font_color", HouseTheme.QUIET)
	share.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	share.visible = false
	HudText.shadowed(share)
	var life_line := HBoxContainer.new()
	life_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_line.add_theme_constant_override("separation", 12)
	life_line.alignment = line_up
	for part: Control in [share, lives] if right else [lives, share]:
		life_line.add_child(part)
	counts.add_child(life_line)
	var gauge := VBoxContainer.new()
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.add_theme_constant_override("separation", 6)
	gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dial_box := Control.new()
	dial_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dial_box.custom_minimum_size = Vector2(DIAL, DIAL)
	dial_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var speed_dial := SpeedDial.new()
	speed_dial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	speed_dial.tooltip_text = "Speed"
	dial_box.add_child(speed_dial)
	var speed := Label.new()
	speed.text = "0"
	Type.set_font(speed, Type.numbers_font(), Type.HEADING)
	speed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speed.offset_top = -4.0
	speed.offset_bottom = -4.0
	speed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dial_box.add_child(speed)
	gauge.add_child(dial_box)
	var nitro := NitroCells.new()
	nitro.custom_minimum_size = CELLS
	nitro.ink = slot.color()
	nitro.value = 100.0
	nitro.tooltip_text = "Nitro"
	nitro.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gauge.add_child(nitro)
	for part: Control in [gauge, counts] if right else [counts, gauge]:
		middle.add_child(part)
	# The pot goes under the banked score, GAME.md 8.3, on a line of its own the width of the strip:
	# its pills grow with their numbers, and beside the dial they had nowhere to grow into.
	var pot := ScorePills.add_to(box, right)
	# What is in hand and what is running, GAME.md 8.3: one thing in one place, see [ItemRow].
	var item := ItemRow.add_to(box, right)
	# The control hints, GAME.md 8.3, on a tab of the strip rather than in it: they come and go as
	# they are worth pressing, and in the strip they made it grow and shrink under everything else
	# in it. Above the layout rather than in it, so the card never fits it.
	var hints := PanelContainer.new()
	hints.name = "Hints"
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hints.add_theme_stylebox_override("panel", tab(bottom))
	hints.top_level = true
	hints.visible = false
	card.add_child(hints)
	var hang := func() -> void: _hang(hints, card, right, bottom)
	card.item_rect_changed.connect(hang)
	hints.resized.connect(hang)
	return {
		"box": card,
		"name": name_label,
		"bot": bot,
		"lag": lag,
		"corner": corner,
		"banked": banked,
		"share": share,
		"pot": pot,
		"stats": stats,
		"lives": pips,
		"nitro": nitro,
		"speed_dial": speed_dial,
		"speed": speed,
		"item": item,
		"item_art": item.art,
		"item_name": item.label,
		"hints": hints,
		"hint_stamp": "",
		"worn": _worn(slot),
	}


## Hangs [param hints] off [param card]: under it for a block at the top of the screen, over it for
## one at the bottom, lined up with the writing in it on the edge the strip comes off.
static func _hang(hints: Control, card: Control, right: bool, bottom: bool) -> void:
	var rect := card.get_global_rect()
	var tall := hints.size.y
	var y := rect.position.y - tall if bottom else rect.end.y
	var x := rect.end.x - TAB_INSET - hints.size.x if right else rect.position.x + TAB_INSET
	hints.global_position = Vector2(x, y)


## How far down the screen [param block], at the top of it, reaches, the tab of control hints under
## it counted in wherever the hints are drawn at all, shown or not: what hangs under it, the kill
## feed in the top right, keeps clear of it and does not jump about as the hints come and go.
static func foot(block: Dictionary) -> float:
	var bottom := (block["box"] as Control).get_global_rect().end.y
	if not Game.settings.control_hints or TouchInput.enabled:
		return bottom
	return bottom + maxf((block["hints"] as Control).size.y, TAB_TALL)


## The ticket the corner's control hints are on, GAME.md 8.1a: of the HUD's stock, hung from
## the foot of [param bottom]'s strip, or standing on its top for a block on the bottom of the
## screen, a little in from the screen's edge: square where it meets the strip and notched only at
## the two corners of its free end, a faint foil hairline inside its edge.
static func tab(bottom: bool) -> TicketStyle:
	var style := TicketStyle.cut(Color(HouseTheme.STOCK, 0.86), TAB_NOTCH, TAB_ROOM.x, TAB_ROOM.y)
	style.notch_top = bottom
	style.notch_bottom = not bottom
	style.frame = Color(HouseTheme.FOIL, 0.2)
	style.frame_inset = 4.0
	Surface.wear(style, "hud")
	return style


## The strip a corner block is cut from, GAME.md 8.1a: off the left or the right edge of the
## screen, wide at the top for a block hung from the top and at the bottom for one standing on it,
## its inner end striped in [param slot]'s color, waves engraved in it and its seat in microprint
## along its foot. No seal: the dial is the round thing in a corner.
static func strip(slot: PlayerSlot, right: bool, bottom: bool) -> StripStyle:
	var style := StripStyle.cut(right, SLANT, OUTER, INNER, ABOVE)
	style.content_margin_bottom = BELOW
	style.wide_at_bottom = bottom
	style.stripe = slot.color()
	style.stripe_width = STRIPE
	style.engraving = Color(HouseTheme.FOIL, ENGRAVED)
	style.waves = true
	# What the microprint says moves with the story, STORY.md 6.4; MICRO is its first stage's.
	var micro := str(StoryLines.at(StoryLines.MICRO_HUD, Story.stage_here(), MICRO))
	style.micro = micro % (slot.index + 1)
	style.micro_size = StripStyle.MICRO_TOUCH if TouchInput.enabled else StripStyle.MICRO_SIZE
	return style


## Keeps [param block] in [param slot]'s name and color, which a player can change in the lobby
## and the Garage, GAME.md 4.4, and a client hears about from the host, and in the palette, which
## the settings over the room can change, 8.5. Only on a change.
static func follow(block: Dictionary, slot: PlayerSlot) -> void:
	var worn := _worn(slot)
	if block["worn"] == worn:
		return
	block["worn"] = worn
	var name_label: Label = block["name"]
	name_label.text = slot.display_name()
	name_label.add_theme_color_override("font_color", slot.color())
	(block["nitro"] as NitroCells).ink = slot.color()
	var card: Control = block["box"]
	var style := card.get_theme_stylebox(&"panel") as StripStyle
	if style != null:
		style.stripe = slot.color()


## Shows the robot's head of [param block] while a bot drives [param slot], GAME.md 9.8, just
## after the end of the name, on whichever side the name is lined up from, and hides it once
## somebody has taken the seat. The name keeps clear of it, a little smaller where the two would
## not fit side by side, as the banked score does, see [method HudText.fit].
static func place_bot(block: Dictionary, slot: PlayerSlot) -> void:
	var bot: Control = block["bot"]
	var label: Label = block["name"]
	var shown := slot.bot_driven() and not label.text.is_empty()
	var font := label.get_theme_font(&"font")
	var side := roundf(font.get_height(Type.LARGE) * BOT_SHARE)
	var gap := roundf(side * 0.3)
	_keep_clear(label, side + gap if shown else 0.0)
	bot.visible = shown
	if not shown:
		return
	# Where the name is drawn, off its letters rather than its measured width, which leaves out
	# whatever the label keeps round its text.
	var first := label.get_character_bounds(0)
	var last := label.get_character_bounds(label.text.length() - 1)
	var x := minf(last.end.x + gap, label.size.x - side)
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = maxf(first.position.x - gap - side, 0.0)
	var at := Vector2(roundf(x), roundf((label.size.y - side) * 0.5))
	if bot.position != at or bot.size.x != side:
		bot.position = at
		bot.size = Vector2(side, side)
		bot.queue_redraw()


## Keeps [param room] of [param label] free on the side its text runs to, for the robot's head,
## and sets the name small enough to fit in what is left. Only on a change, as this runs a frame.
static func _keep_clear(label: Label, room: float) -> void:
	var asked := "%s|%.0f|%.0f" % [label.text, label.size.x, room]
	if label.get_meta(&"kept_clear", "") == asked:
		return
	label.set_meta(&"kept_clear", asked)
	var right := label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT
	var margin := StyleBoxEmpty.new()
	margin.content_margin_left = room if right else 0.0
	margin.content_margin_right = 0.0 if right else room
	label.add_theme_stylebox_override(&"normal", margin)
	var font := label.get_theme_font(&"font")
	var need := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Type.LARGE).x
	var wide := label.size.x - room
	var size := Type.LARGE
	if room > 0.0 and wide > 0.0 and need > wide:
		size = maxi(floori(Type.LARGE * wide / need), HudText.FIT_SMALLEST)
	label.add_theme_font_size_override(&"font_size", size)


## The tag the HUD's smaller pieces stand on, GAME.md 8.1a: the driving test's checklist, its
## notices and its boss bar, the pointer a lesson shows a piece of the corner with, and the
## switches over a corner in the pause menu. A small ticket of the house's stock, a little clear,
## with a foil hairline just inside its edge.
static func scrim() -> TicketStyle:
	var style := TicketStyle.cut(Color(HouseTheme.STOCK, 0.82), 8.0, 14.0, 10.0)
	style.content_margin_bottom = 12.0
	style.frame = Color(HouseTheme.FOIL, 0.2)
	style.frame_inset = 4.0
	return style


## A gauge for what fills up over the HUD, a lesson's task or the driving test's last boss, GAME.md
## 8.1a: the dashboard's own, a row of slanted cells lit in [param ink] as far as it has got, as
## the nitro tank is, see [NitroCells]. From 0 to 100.
static func bar(size: Vector2, ink: Color) -> Range:
	var cells := NitroCells.new()
	cells.custom_minimum_size = size
	cells.ink = ink
	cells.value = 0.0
	return cells


## The pips of [param block] made up to [param most], the lives its kart may have, which a joker
## can raise, GAME.md 3.6: one more is added where there are too few, and one too many is hidden.
static func fit_lives(block: Dictionary, slot: PlayerSlot, most: int) -> Array:
	var pips: Array = block["lives"]
	while pips.size() < most and not pips.is_empty():
		pips.append(_pip((pips[0] as Control).get_parent(), slot))
	for i: int in pips.size():
		(pips[i] as Control).visible = i < most
	return pips.slice(0, mini(most, pips.size()))


static func _pip(row: Node, slot: PlayerSlot) -> Heart:
	var pip := Heart.new()
	pip.custom_minimum_size = Vector2(MatchHud.LIFE_SIZE, MatchHud.LIFE_SIZE)
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip.color = slot.color()
	row.add_child(pip)
	return pip


## What a block was drawn for: the name, the color, its team's in team play, and the palette it is
## in, GAME.md 8.5.
static func _worn(slot: PlayerSlot) -> String:
	return "%d|%s|%s" % [slot.paint_index(), Palette.vision, slot.display_name()]


## What [param slot]'s corner says is banked, GAME.md 8.3: its own, or in team play its team's
## bank, big, with the player's own share of it small beside their lives, 3.14.
static func show_bank(block: Dictionary, slot: PlayerSlot, slots: Array[PlayerSlot]) -> void:
	var banked: Label = block["banked"]
	HudText.fit(banked, str(Teams.score_of(slots, slot)), Type.SCORE)
	var share: Label = block["share"]
	share.visible = slot.team >= 0 and banked.visible
	var text := "yours %d" % slot.banked
	if share.visible and share.text != text:
		share.text = text
