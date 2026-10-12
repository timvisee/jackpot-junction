class_name LoyaltyMapPrint
extends RefCounted
## The words printed on the loyalty program's map, GAME.md 8.9, and what goes with them, for
## [LoyaltyMapView] to draw: each district's name over it, the places of the country named, the
## pot's word, the compass's north, the legend with its samples, the house's title block, where
## Kit's roads off a sheet go, and an open landmark's bet on its ticket under its sign. Every word
## is printed at the zoom's own size rather than scaled, so it is sharp at every zoom.

## The ticket of a sign's bet under it, at a zoom of one: its type, how many lines of it at most,
## how far in from either side of its sign it is cut, and how far it is tucked up under the sign;
## the room under the bet for how far it has come and the little road that shows it; the notches
## at its foot and its sides; and the paper it is printed on.
const BET_SIZE := 11.0
const BET_LINES := 4
const TICKET_IN := 7.0
const TICKET_TUCK := 7.0
const TICKET_ROAD := 17.0
const NOTCH := 4.5
const ROAD := 5.0
const TICKET_PAPER := Color("#f8f1df")
## The districts' names, printed over them, and Kit's over the pencil.
const STRIP := "THE STRIP"
const DEPARTMENT := "DEPARTMENT OF KARTS"
const OFF_THE_BOOKS := "off the books"
const DISTRICT_SIZE := 24.0
const DISTRICT_SPACING := 4
const POT := "JACKPOT"
## The places of the country named, in a slanted face: water in its blue, the rest in green.
const PLACE_SIZE := 13.0
const PLACE_SLANT := 0.22
const PLACE_SPACING := 2
const WATER_INK := Color(0.25, 0.45, 0.66, 0.9)
const LAND_INK := Color(0.3, 0.42, 0.24, 0.9)
## The legend's words, and the title block's.
const LEGEND := "LEGEND"
const LEGEND_LINES: Array[String] = [
	"The House's road", "Not open yet", "The Strip", "Dept. of Karts", "Won"
]
## What Kit pencils in under the House's legend, once Kit's roads are on the map, and how far
## askew.
const KIT_LEGEND := "my roads"
const KIT_LEGEND_TURN := -0.06
const IMPRINT := "ROAD MAP  ·  NOT TO SCALE"
const PRINTED := "Printed by the House for its members"
## What is written beside the arrow at the end of one of Kit's roads off a sheet.
const WAY_OFF := "to %s"
const KIT_MAP := "Kit's map"
## What is written by the arrow on Kit's road onto his sheet, which his first landmark is on.
const WAY_IN := "the back way in"

static var _spaced: FontVariation
static var _slanted: FontVariation


## How wide the ticket under a sign [param sign_wide] across is, at a zoom of one: a little
## narrower than the sign, so it hangs from under it.
static func ticket_wide(sign_wide: float) -> float:
	return sign_wide - TICKET_IN * 2.0


## The map's words on [param view]: each district's name over it, the places of the country, where
## Kit's roads off the sheet go, the pot's, the compass's north, the legend's and the title block's.
static func words(view: LoyaltyMapView) -> void:
	var layout := view.layout
	var names := {
		LoyaltyLandmark.District.STRIP: [STRIP, HouseTheme.FOIL_LOW],
		LoyaltyLandmark.District.DEPARTMENT: [DEPARTMENT, LoyaltyArt.SIGN_BLUE],
		LoyaltyLandmark.District.OFF_THE_BOOKS: [OFF_THE_BOOKS, LoyaltyArt.PENCIL],
	}
	for district: int in layout.names_at:
		var named: Array = names.get(district, ["", Color.WHITE])
		var kit := district == LoyaltyLandmark.District.OFF_THE_BOOKS
		var font: Font = LoyaltyArt.HAND if kit else _spaced_font()
		var size_of := DISTRICT_SIZE * (LoyaltyArt.HAND_SCALE if kit else 1.0)
		view.say(layout.names_at[district], named[0], font, size_of, named[1])
	for place: Dictionary in layout.places:
		var ink := WATER_INK if place["water"] else LAND_INK
		var named: String = place["name"]
		var wide := place_font().get_string_size(named, HORIZONTAL_ALIGNMENT_LEFT, -1, PLACE_SIZE).x
		view.say(place["at"] - Vector2(wide * 0.5, 0.0), named, place_font(), PLACE_SIZE, ink)
	_say_ways_off(view)
	if view.sheet != LoyaltyMapLayout.Sheet.HOUSE:
		return
	var display := Type.display_font()
	var pot := layout.ring * 0.52 * 0.3
	var pot_at := layout.ring_middle + Vector2(-layout.ring, pot * 0.36)
	# As pale as the paper over the pot while the roundabout is shut.
	var pot_ink := HouseTheme.ON_FOIL
	if not view.ring_open():
		pot_ink.a = 1.0 - LoyaltyArt.PALE
	view.say(pot_at, POT, display, pot, pot_ink, HORIZONTAL_ALIGNMENT_CENTER, layout.ring * 2.0)
	var laps := view.profile.loyalty.laps
	if laps > 0:
		view.say(
			pot_at + Vector2(0.0, pot * 0.95),
			LoyaltyCard.LAP % laps,
			Type.STRONG,
			pot * 0.55,
			HouseTheme.ON_FOIL,
			HORIZONTAL_ALIGNMENT_CENTER,
			layout.ring * 2.0
		)
	var north := layout.compass + Vector2(-20.0, -LoyaltyMapLayout.COMPASS - 6.0)
	view.say(north, "N", display, 16.0, HouseTheme.STAMP_RED, HORIZONTAL_ALIGNMENT_CENTER, 40.0)
	_legend_words(view, display)
	_title_words(view, display)


## The legend's heading and its lines, and Kit's line pencilled in under them once it shows.
static func _legend_words(view: LoyaltyMapView, display: Font) -> void:
	var box := view.layout.legend
	view.say(box.position + Vector2(16.0, 24.0), LEGEND, display, 15.0, HouseTheme.INK)
	for i: int in LEGEND_LINES.size():
		var at := box.position + Vector2(70.0, 44.0 + i * 19.0)
		view.say(at, LEGEND_LINES[i], Type.STRONG, 12.0, HouseTheme.INK)
	if not kit_legend_shown(view.profile):
		return
	var written := view.to_view(_kit_legend_at(view.layout) + Vector2(54.0, 5.0))
	view.draw_set_transform(written, KIT_LEGEND_TURN, Vector2.ONE)
	var px := maxi(roundi(12.0 * LoyaltyArt.HAND_SCALE * view.zoom), 1)
	view.draw_string(
		LoyaltyArt.HAND,
		Vector2.ZERO,
		KIT_LEGEND,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		px,
		LoyaltyArt.PENCIL
	)
	view.draw_set_transform_matrix(Transform2D.IDENTITY)


## The title block's three lines: the program's name, the imprint and who printed it.
static func _title_words(view: LoyaltyMapView, display: Font) -> void:
	var title := view.layout.cartouche
	var wide := title.size.x - 24.0
	var lines := [
		[40.0, view.program.to_upper(), display, 26.0, HouseTheme.INK],
		[66.0, IMPRINT, Type.STRONG, 12.0, HouseTheme.INK],
		[92.0, PRINTED, LoyaltyArt.HAND, 15.0, HouseTheme.INK_FAINT],
	]
	for line: Array in lines:
		view.say(
			title.position + Vector2(12.0, line[0]),
			line[1],
			line[2],
			line[3],
			line[4],
			HORIZONTAL_ALIGNMENT_CENTER,
			wide
		)


## The legend's samples on [param view], at its left, under the map's transform [param base]: a
## road, one not open yet, the Strip's board, the Department's sign, and the Strip's seal beside
## the Department's stamp, a line each; and once Kit's roads show, Kit's pencil road under them,
## drawn in by hand a little askew.
static func legend_samples(view: LoyaltyMapView, base: Transform2D) -> void:
	var box := view.layout.legend
	for i: int in LEGEND_LINES.size():
		var y := box.position.y + 40.0 + i * 19.0
		var from := Vector2(box.position.x + 16.0, y)
		var to := from + Vector2(42.0, 0.0)
		var board := Rect2(from - Vector2(0, 7), Vector2(42, 14))
		match i:
			0, 1:
				LoyaltyMapArt.house_road(view, PackedVector2Array([from, to]), i == 0)
			2:
				view.draw_rect(board, LoyaltyArt.MARQUEE)
				view.draw_rect(board, HouseTheme.FOIL, false, 1.4)
			3:
				view.draw_rect(board, LoyaltyArt.SIGN_BLUE)
				view.draw_rect(
					Rect2(from - Vector2(-2, 5), Vector2(38, 10)), Color.WHITE, false, 0.8
				)
			4:
				LoyaltyArt.seal(view, from + Vector2(9.0, -1.0), 7.5, base)
				LoyaltyArt.stamp(view, from + Vector2(32.0, 0.0), 8.0, HouseTheme.STAMP_RED, base)
	if not kit_legend_shown(view.profile):
		return
	view.draw_set_transform_matrix(base * Transform2D(KIT_LEGEND_TURN, _kit_legend_at(view.layout)))
	var drawn_in := PackedVector2Array(
		[Vector2(-2.0, 1.0), Vector2(20.0, -1.5), Vector2(44.0, 1.0)]
	)
	LoyaltyMapArt.road(view, drawn_in, true, true)
	view.draw_set_transform_matrix(base)


## Whether Kit's pencil is in the legend of [param profile]'s map: once Kit's roads are on it.
static func kit_legend_shown(profile: Profile) -> bool:
	return Loyalty.district_open(profile, LoyaltyLandmark.District.OFF_THE_BOOKS)


## Kit's way onto his sheet along [param line], said in his hand under its arrow, kept on the paper.
static func _say_way_in(view: LoyaltyMapView, line: PackedVector2Array) -> void:
	var size_of := 13.0 * LoyaltyArt.HAND_SCALE
	var wide := (
		LoyaltyArt.HAND.get_string_size(WAY_IN, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(size_of)).x
	)
	var at := LoyaltyMapView.way_off_tip(line) + Vector2(-wide * 0.5, 30.0)
	at.x = clampf(at.x, 12.0, view.layout.paper.x - wide - 12.0)
	view.say(at, WAY_IN, LoyaltyArt.HAND, size_of, LoyaltyArt.PENCIL)


## Where Kit's line in the legend starts, on the map: under the House's last.
static func _kit_legend_at(layout: LoyaltyMapLayout) -> Vector2:
	var box := layout.legend
	return Vector2(box.position.x + 16.0, box.position.y + 44.0 + LEGEND_LINES.size() * 19.0)


## The arrows at the ends of Kit's roads off a sheet on [param view], in pencil, the way they go:
## off it, or onto it for his way in; under the map's transform.
static func ways_off(view: LoyaltyMapView) -> void:
	for road: Dictionary in view.layout.roads:
		var way_in := is_way_in(road)
		if road.get("off_to", &"") == &"" and not way_in:
			continue
		var line: PackedVector2Array = road["points"]
		var tip := LoyaltyMapView.way_off_tip(line)
		var way := (line[-1] - line[-2]).normalized() if line.size() >= 2 else Vector2.DOWN
		for side: float in [-1.0, 1.0]:
			var back := tip + way.rotated(side * 0.5) * 16.0 * (1.0 if way_in else -1.0)
			view.draw_line(tip, back, Color(LoyaltyArt.PENCIL, 0.85), 1.8, true)


## Whether [param road] is Kit's way onto his sheet: a road in his pencil off its edge that goes
## to no landmark of the House's, so a player sees where his map is come into.
static func is_way_in(road: Dictionary) -> bool:
	return road["pencil"] and road["edge"] and road.get("off_to", &"") == &""


## Where each of Kit's roads off a sheet goes, in his hand beside its arrow: off his, to the House's
## landmark it leads to; off the House's, to his map.
static func _say_ways_off(view: LoyaltyMapView) -> void:
	for road: Dictionary in view.layout.roads:
		var to: StringName = road.get("off_to", &"")
		var line: PackedVector2Array = road["points"]
		if is_way_in(road):
			_say_way_in(view, line)
		if to == &"":
			continue
		var there := Loyalty.map().landmark(to)
		var named := there.title if there != null else String(to)
		var up := line.size() >= 2 and line[-1].y < line[-2].y
		if up:
			named = KIT_MAP
		var at := LoyaltyMapView.way_off_tip(line) + Vector2(18.0, 20.0 if up else -6.0)
		var size_of := 13.0 * LoyaltyArt.HAND_SCALE
		view.say(at, WAY_OFF % named, LoyaltyArt.HAND, size_of, LoyaltyArt.PENCIL)


## The bet of [param landmark], open, on a ticket hung from under its sign [param rect] on
## [param view], in the view's own pixels, drawn before the sign so its top is tucked under it and
## a little narrower than it. The House's is a stub of cream card edged in its district's color and
## notched at its foot, the bet printed on it and, under a perforation with a bite out of either
## side, how far it has come along a little road filling in gold, as a pinned bet's does, the count
## at its end. Kit's is a scrap of the paper torn off along its foot, in his hand, the way along
## shaded in pencil.
static func bet(view: LoyaltyMapView, landmark: LoyaltyLandmark, rect: Rect2) -> void:
	var zoom := view.zoom
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	var font: Font = LoyaltyArt.HAND if kit else Type.TEXT
	var size_of := maxi(roundi(BET_SIZE * zoom * (LoyaltyArt.HAND_SCALE if kit else 1.0)), 1)
	var wide := ticket_wide(rect.size.x / zoom) * zoom
	var room := 7.0 * zoom
	var lines := LoyaltyArt.lines_of(
		font, Loyalty.bet_of(landmark), size_of, wide - room * 2.0, BET_LINES
	)
	var tall := font.get_height(size_of) * (0.82 if kit else 0.95)
	var bar := Loyalty.progress(view.profile, landmark)
	var tuck := TICKET_TUCK * zoom
	var said_tall := tuck + tall * lines.size() + 7.0 * zoom
	var road_room := TICKET_ROAD * zoom if bar.y > 0.0 else 0.0
	var ticket := Rect2(
		Vector2(rect.get_center().x - wide * 0.5, rect.end.y - tuck),
		Vector2(wide, said_tall + road_room)
	)
	var cut := ticket.position.y + said_tall if road_room > 0.0 else -1.0
	var ink := LoyaltyArt.PENCIL if kit else HouseTheme.INK
	if kit:
		_scrap(view, ticket, zoom)
	else:
		_ticket(view, ticket, cut, _edge_of(landmark), zoom)
	for i: int in lines.size():
		var top := tuck + 4.0 * zoom + tall * i + font.get_ascent(size_of) * 0.92
		view.draw_string(
			font,
			ticket.position + Vector2(room, top),
			lines[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			wide - room * 2.0,
			size_of,
			ink
		)
	if road_room <= 0.0:
		return
	var said := Loyalty.progress_text(view.profile, landmark)
	var count_font: Font = LoyaltyArt.HAND if kit else Type.STRONG
	var small := maxi(roundi(BET_SIZE * 0.92 * zoom * (LoyaltyArt.HAND_SCALE if kit else 1.0)), 1)
	var said_wide := count_font.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x
	var middle := cut + road_room * 0.5
	var from := Vector2(ticket.position.x + room * 1.4, middle)
	var to := Vector2(ticket.end.x - room * 1.6 - said_wide, middle)
	var share := clampf(bar.x / bar.y, 0.0, 1.0)
	if kit:
		_pencil_way(view, from, to, share, zoom)
	else:
		_little_road(view, from, to, share, zoom)
	var base := Vector2(
		ticket.end.x - room - said_wide, middle + count_font.get_ascent(small) * 0.36
	)
	var count_ink := ink if kit else PinnedNote.GOLD_INK.darkened(0.25)
	view.draw_string(count_font, base, said, HORIZONTAL_ALIGNMENT_LEFT, -1, small, count_ink)


## The edge of [param landmark]'s ticket: the Strip's gold, the Department's blue.
static func _edge_of(landmark: LoyaltyLandmark) -> Color:
	if landmark.district == LoyaltyLandmark.District.STRIP:
		return HouseTheme.FOIL_LOW
	return LoyaltyArt.SIGN_BLUE


## The House's ticket over [param rect] on [param on]: a shadow under it, the card, a notch out of
## each corner of its foot and, at [param cut] where it is above the foot, a bite out of either
## side and a perforation across between them; its edge in [param edge].
static func _ticket(on: CanvasItem, rect: Rect2, cut: float, edge: Color, zoom: float) -> void:
	var notch := NOTCH * zoom
	var outline := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)])
	if cut > 0.0:
		_bite(outline, Vector2(rect.end.x, cut), notch * 0.8, PI * 1.5, PI * 0.5, -1.0)
	_bite(outline, rect.end, notch, PI * 1.5, PI, -1.0)
	_bite(outline, Vector2(rect.position.x, rect.end.y), notch, 0.0, PI * -0.5, -1.0)
	if cut > 0.0:
		_bite(outline, Vector2(rect.position.x, cut), notch * 0.8, PI * 0.5, PI * -0.5, -1.0)
	var shadow := outline.duplicate()
	for i: int in shadow.size():
		shadow[i] += Vector2(1.5, 2.5) * zoom
	on.draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.2))
	on.draw_colored_polygon(outline, TICKET_PAPER)
	# Round from its top right to its top left, the top under the sign.
	var edged := outline.slice(1)
	edged.append(outline[0])
	on.draw_polyline(edged, Color(edge, 0.85), 1.2 * zoom, true)
	if cut <= 0.0:
		return
	var holes := PackedVector2Array()
	var x := rect.position.x + notch * 1.6
	while x < rect.end.x - notch * 1.4:
		holes.append(Vector2(x, cut))
		x += 4.0 * zoom
	LoyaltyArt.dots(on, holes, 0.8 * zoom, Color(edge, 0.6))


## A bite [param radius] round [param at] added to [param outline], from the angle [param from] to
## [param to], in steps the way [param way] turns.
static func _bite(
	outline: PackedVector2Array, at: Vector2, radius: float, from: float, to: float, way: float
) -> void:
	var steps := 6
	var turn := to - from
	if signf(turn) != signf(way):
		turn += TAU * way
	for i: int in steps + 1:
		outline.append(at + Vector2.from_angle(from + turn * i / steps) * radius)


## How far a bet has come on the House's ticket: a stretch of the map's own road from [param from]
## to [param to], gold as far as [param share], its middle line dashed along it.
static func _little_road(
	on: CanvasItem, from: Vector2, to: Vector2, share: float, zoom: float
) -> void:
	var wide := ROAD * zoom
	on.draw_line(from, to, PinnedNote.CASING, wide + 2.6 * zoom, true)
	on.draw_line(from, to, LoyaltyMapArt.ROAD_SHUT, wide, true)
	if share > 0.0:
		on.draw_line(from, from.lerp(to, share), LoyaltyMapArt.ROAD_FILL, wide, true)
	var middle := PackedVector2Array([from, to])
	var pattern := Vector2(4.0, 3.5) * zoom
	LoyaltyMapArt.dashed(on, middle, LoyaltyMapArt.CENTER_ON_GOLD, 0.9 * zoom, pattern, false)


## How far a bet has come on Kit's scrap: a way drawn in pencil from [param from] to [param to],
## shaded in as far as [param share].
static func _pencil_way(
	on: CanvasItem, from: Vector2, to: Vector2, share: float, zoom: float
) -> void:
	var half := 3.0 * zoom
	var box := Rect2(from - Vector2(0.0, half), Vector2(to.x - from.x, half * 2.0))
	var shade := PackedVector2Array()
	var x := box.position.x
	while x < box.position.x + box.size.x * share:
		shade.append(Vector2(x, box.end.y))
		shade.append(Vector2(minf(x + half * 1.4, box.end.x), box.position.y))
		x += 2.6 * zoom
	if not shade.is_empty():
		on.draw_multiline(shade, Color(LoyaltyArt.PENCIL, 0.55), 1.0 * zoom, true)
	var line := Color(LoyaltyArt.PENCIL, 0.8)
	on.draw_line(box.position, Vector2(box.end.x, box.position.y), line, 1.1 * zoom, true)
	on.draw_line(Vector2(box.position.x, box.end.y), box.end, line, 1.1 * zoom, true)


## Kit's scrap over [param rect] on [param on]: torn along its foot, a shadow under it.
static func _scrap(on: CanvasItem, rect: Rect2, zoom: float) -> void:
	var outline := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)])
	var bites := maxi(roundi(rect.size.x / (12.0 * zoom)), 4)
	for i: int in bites + 1:
		var across := rect.end.x - rect.size.x * float(i) / bites
		var deep := (2.0 + 3.0 * absf(sin(float(i) * 2.3 + 0.7))) * zoom
		outline.append(Vector2(across, rect.end.y + 3.0 * zoom - deep))
	var shadow := outline.duplicate()
	for i: int in shadow.size():
		shadow[i] += Vector2(1.5, 2.0) * zoom
	on.draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.16))
	on.draw_colored_polygon(outline, Color(HouseTheme.PAPER, 0.97))


## The display face spaced out, for the districts' names across their washes, made once.
static func _spaced_font() -> FontVariation:
	if _spaced == null:
		_spaced = FontVariation.new()
		_spaced.base_font = Type.display_font()
		_spaced.spacing_glyph = DISTRICT_SPACING
	return _spaced


## The house's print slanted and spaced a little, for the places of the country, as a map names its
## woods and its water, made once.
static func place_font() -> FontVariation:
	if _slanted == null:
		_slanted = FontVariation.new()
		_slanted.base_font = Type.STRONG
		_slanted.variation_transform = Transform2D(
			Vector2(1.0, PLACE_SLANT), Vector2(0.0, 1.0), Vector2.ZERO
		)
		_slanted.spacing_glyph = PLACE_SPACING
	return _slanted
