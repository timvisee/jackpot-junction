class_name SlipPage
extends VBoxContainer
## One page of the payout slip, GAME.md 3.8: its heading, what it is a page of under that, a band of
## foil, the podium framed as the photo on the license is, and a line of the receipt for each
## player, see [method fill_map] and [method fill_run]. The slip's pages are printed one under
## another on one long bill, see [PayoutBill].
##
## A line has the player's place on a chip, their name, dotted leaders across to what they banked,
## and the awards underneath as stubs of their own rather than run together into one sentence. The
## winner's line is stamped WINNER with the driving test's stamp.

const PLACES: Array[String] = ["1st", "2nd", "3rd", "4th", "5th", "6th"]
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
## The size the story's microprint under a line is printed at, STORY.md 6.2.
const STORY_MICRO := 10
## How big a place's chip is on a line.
const PLACE_CHIP := 36.0
## Air between the podium and the table of players: one is a picture and the other a list.
const PODIUM_GAP := 10.0
## Past this many players the lines are compact, GAME.md 3.8: the sizes a compact line writes its
## name, its score and the rest in, and the size of its place's chip. A slip of eight at the full
## size runs on for a screen and a half. The stamp stays as big as it is, lying over the line under
## it the way a rubber stamp does: its lettering is drawn for that size.
const COMPACT_PAST := 4
## On a short screen, a phone's under a big UI scale, the lines are compact whoever is in the room,
## and the podium is drawn this much of its size, so more than a couple of lines fit under it.
const SHORT_PODIUM := 0.62
const COMPACT_NAME := 22
const COMPACT_SCORE := 26
const COMPACT_SMALL := 14
const COMPACT_CHIP := 28.0

var match_node: Match
var heading: Label
var caption: Label
## A line under the caption, what happens to the jokers on the way to the next map.
var note: Label
var podium: ResultsPodium
## The podium's photo, its frame and its caption: on the map's page, and not on a Grand Prix's
## standings, whose podium is the finale's in the room, GAME.md 9.7.
var photo: Control
var rows: VBoxContainer
## Whether the lines are compact: more than [constant COMPACT_PAST] players, or a short screen.
var compact := false
## Whether the screen is short, see [constant SHORT_PODIUM]; said before the page is filled.
var short := false


## A page of the slip of [param for_match], empty until it is filled in.
static func create(for_match: Match) -> SlipPage:
	var page := SlipPage.new()
	page.match_node = for_match
	page._build()
	return page


## Headed [param title], with [param under] under it, and [param said] under that if anything is.
func head(title: String, under: String, said: String) -> void:
	heading.text = title
	caption.text = under
	caption.visible = not under.is_empty()
	note.text = said
	note.visible = not said.is_empty()


## The map just played, GAME.md 3.8: everybody in [param standings] ranked on what they banked,
## with what they did most of under each.
func fill_map(standings: Array[PlayerSlot]) -> void:
	_clear(standings)
	photo.visible = true
	var everyone: Array[PlayerStats] = []
	for slot: PlayerSlot in match_node.slots:
		everyone.append(slot.stats)
	var rank := 1
	# A showdown is ranked by who lasted rather than on banked, GAME.md 9.7a: no line is level.
	var showdown := match_node.rules.showdown()
	for slot: PlayerSlot in standings:
		var tied := PackedStringArray() if showdown else TieWords.of_map(slot, standings)
		rows.add_child(_entry(slot, rank, everyone, tied))
		rank += 1


## How a Grand Prix stands, GAME.md 9.7: everybody in [param standings] ranked on the points of
## [param run] so far.
func fill_run(standings: Array[PlayerSlot], run: GrandPrix) -> void:
	_clear(standings)
	# No photo finish of the run so far: the run ends on a podium of its own, in the room.
	photo.visible = false
	podium.draw_while(false)
	var rank := 1
	for slot: PlayerSlot in standings:
		rows.add_child(_run_entry(slot, rank, run))
		rank += 1


## The lines cleared, sized for [param standings], and the top three stood on the podium.
func _clear(standings: Array[PlayerSlot]) -> void:
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.free()
	compact = standings.size() > COMPACT_PAST or short
	rows.add_theme_constant_override("separation", 3 if compact else 6)
	podium.custom_minimum_size = ResultsPodium.SIZE * (SHORT_PODIUM if short else 1.0)
	podium.show_top(standings)


func _build() -> void:
	name = "Page"
	add_theme_constant_override("separation", 14)
	heading = MenuTheme.title("", Type.TITLE)
	heading.name = "Heading"
	# Printed in the slip's ink rather than stamped in foil: gold on cream is gold nobody can read.
	heading.add_theme_color_override("font_color", INK)
	heading.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	add_child(heading)
	caption = MenuTheme.subtitle("", Type.LABEL)
	caption.name = "Caption"
	caption.add_theme_color_override("font_color", FAINT)
	caption.visible = false
	add_child(caption)
	note = MenuTheme.subtitle("", Type.LABEL)
	note.name = "Note"
	note.add_theme_color_override("font_color", FAINT)
	note.visible = false
	add_child(note)
	var band := ColorRect.new()
	band.color = HouseTheme.FOIL
	band.custom_minimum_size = Vector2(0.0, 3.0)
	add_child(band)
	photo = _photo()
	photo.name = "Photo"
	add_child(photo)
	rows = VBoxContainer.new()
	rows.name = "Rows"
	rows.add_theme_constant_override("separation", 6)
	add_child(rows)


## The podium framed as the photo on the license is, with a gold edge, captioned under it, GAME.md
## 8.1a, and taken against a stage at night, see [PhotoBackdrop].
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
	var backdrop := PhotoBackdrop.new()
	backdrop.name = "Backdrop"
	frame.add_child(backdrop)
	podium = ResultsPodium.create()
	podium.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_child(podium)
	backdrop.podium = podium
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


## One player: their place and name on the left, what they banked on the right, and what they
## did most of underneath, three awards at most. In a Grand Prix the points a place paid are said
## on the run's standings, the page after, see [method _run_entry], not here among the awards.
func _entry(
	slot: PlayerSlot, rank: int, everyone: Array[PlayerStats], tied: PackedStringArray
) -> PanelContainer:
	var row := _row(slot)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3 if compact else 6)
	row.add_child(box)
	box.add_child(_headline(slot, rank))
	var awards := _award_chips(slot, everyone)
	# Level on what it banked with another line, what put it in its place, GAME.md 3.8, before
	# anything it did most of.
	if not tied.is_empty():
		if awards == null:
			awards = HBoxContainer.new()
			awards.add_theme_constant_override("separation", 8)
		var chip := _chip(tied[0], tied[1])
		chip.name = "Tie"
		awards.add_child(chip)
		awards.move_child(chip, 0)
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
	box.add_theme_constant_override("separation", 3 if compact else 6)
	row.add_child(box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	line.add_child(_place_chip(slot, rank))
	# Up or down since the map before, beside the place it changed: a column of its own while anybody
	# moved, and none at all when nobody did, rather than a gap before every name.
	if _anybody_moved(run):
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
		maps.add_child(_chip(named, "%s · %d" % [ordinal, paid[i]]))
	# Level on points with another row, where its showdown put it or what else did, GAME.md 9.7a.
	var tied := TieWords.of_run(slot.index, run, match_node.slots)
	if not tied.is_empty():
		var chip := _chip(tied[0], tied[1])
		chip.name = "Tie"
		maps.add_child(chip)
	box.add_child(maps)
	return row


## Whether anybody's place in [param run] has changed since the map before, for the standings to
## keep a column for the arrows.
func _anybody_moved(run: GrandPrix) -> bool:
	for slot: PlayerSlot in match_node.slots:
		if run.moved(slot.index, match_node.slots) != 0:
			return true
	return false


## The line a player's row is printed on: dashes under it, and the reader's own marked as with a
## highlighter.
func _row(slot: PlayerSlot) -> PanelContainer:
	var row := PanelContainer.new()
	var style := DashStyle.new()
	style.wash = ROW_MINE if _is_mine(slot) else Color(0.0, 0.0, 0.0, 0.0)
	style.dash = DASH
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 5.0 if compact else 10.0
	style.content_margin_bottom = 6.0 if compact else 12.0
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
	var side := COMPACT_CHIP if compact else PLACE_CHIP
	chip.custom_minimum_size = Vector2(side, side)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var placed := "%d" % rank
	var face := slot.color()
	chip.draw.connect(
		func() -> void: ChipArt.numbered(chip, chip.size * 0.5, chip.size.x * 0.5, face, placed)
	)
	return chip


## A player's name as it is printed on the slip: their own color, darkened until it reads on paper,
## and for a bot a robot's head after it, as the standings in the room have, GAME.md 8.3.
func _name(slot: PlayerSlot) -> Control:
	var size := _sized(30, COMPACT_NAME)
	var name_label := _label(slot.display_name(), size, HouseTheme.on_paper(slot.color()))
	name_label.name = "Name"
	Type.set_font(name_label, Type.STRONG, size)
	if slot.is_human() or slot.is_dummy():
		return name_label
	var named := HBoxContainer.new()
	named.add_theme_constant_override("separation", 8)
	named.add_child(name_label)
	var bot := Control.new()
	bot.name = "Bot"
	bot.custom_minimum_size = Vector2(size * 0.8, size * 0.8)
	bot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bot.draw.connect(
		func() -> void:
			IconShapes.robot(bot, Rect2(Vector2.ZERO, bot.size), FAINT, HouseTheme.PAPER)
	)
	named.add_child(bot)
	return named


## [param full], or [param compact_size] on the slip of a room of more than four, GAME.md 3.8.
func _sized(full: int, compact_size: int) -> int:
	return compact_size if compact else full


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
