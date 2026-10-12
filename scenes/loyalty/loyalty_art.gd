class_name LoyaltyArt
extends RefCounted
## The pictures of the loyalty program's map, GAME.md 8.9, drawn rather than loaded, so the map
## stays sharp at any zoom: each landmark's sign in its district's shape, with the picture of what
## it pays on it, pale while it is closed and stamped once it is won; and the reward pictures the
## pane and the list share.
##
## The Strip's signs are the house's marquees, a dark board in a gold frame with a row of bulbs
## along its top and its foot, lit once won. The Department's are road signs, white on its blue. Off
## the books is Kit's pencil on the house's paper: a box drawn by hand and a name in Kit's hand. The
## slip road's is a motorway sign, the way onto the map.

## Each kind of dress by the name a landmark gives it, as [DressArt] draws them.
const PARTS := {
	&"paint": 0, &"hat": 1, &"flag": 2, &"trail": 3, &"frame": 4, &"marks": 5, &"card_back": 6
}
## The Strip's marquee: its board, and its bulbs unlit and lit.
const MARQUEE := Color("#1d1a22")
const BULB_OFF := Color("#6e5523")
const BULB_ON := Color("#ffe9ad")
## The Department's road sign, and the slip road's motorway green.
const SIGN_BLUE := RoadSign.BLUE
const SIGN_WHITE := Color("#f4f6fa")
const MOTORWAY := Color("#1e6b45")
## Kit's pencil, and Kit's hand: how much bigger it is set than the house's print, as a note's is.
const PENCIL := NotePage.PENCIL
## A map pin's red, for what is pinned, GAME.md 8.9.
const PIN_RED := Color(0.86, 0.2, 0.18)
const HAND := NotePage.HAND
const HAND_SCALE := 1.45
## How much of the paper shows through a closed landmark, printed pale.
const PALE := 0.66
## A sign's corners, its frame, the room inside its edge, and its type, at a zoom of one.
const CORNER := 6.0
const FRAME := 2.5
const ROOM := 7.0
const TITLE_SIZE := 14.0
const BULB := 2.2
const BULB_STEP := 11.0
## The stamp on a won landmark: how big round, its word, and how far it is turned.
const STAMP := 22.0
const STAMP_WORD := "WON"
const STAMP_TURN := -0.32
## The NEW tag on a landmark won and not yet looked at, as the catalog's card wears it.
const NEW_SIZE := 11.0
## How many pixels across the soft dot of [method dots] is drawn at.
const DOT_PIXELS := 12
## The ink the cursor's gold edge is cased in on the map, round a sign and round the roundabout.
const SELECTED_CASING := Color(HouseTheme.INK, 0.85)

static var _dot_made: Texture2D


## Draws [param landmark]'s sign into [param rect] on [param on], at [param zoom], as it
## [param stands], see [enum Loyalty.Standing].
static func draw_sign(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, stands: int, zoom: float
) -> void:
	var lit := stands == Loyalty.Standing.WON
	match landmark.district:
		LoyaltyLandmark.District.STRIP:
			_marquee(on, rect, landmark, lit, zoom)
		LoyaltyLandmark.District.DEPARTMENT:
			_road_sign(on, rect, landmark, SIGN_BLUE, zoom)
		LoyaltyLandmark.District.OFF_THE_BOOKS:
			_sketch(on, rect, landmark, zoom)
		_:
			_road_sign(on, rect, landmark, MOTORWAY, zoom)
	if landmark.keystone:
		_crest(on, rect, landmark, zoom)
	if stands == Loyalty.Standing.CLOSED:
		_pale(on, rect, landmark, zoom)
	elif lit:
		_won(on, rect, landmark, zoom)


## A keystone's crest over the middle of its sign's top: a star in a disc of its district's color.
static func _crest(on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, zoom: float) -> void:
	var at := Vector2(rect.get_center().x, rect.position.y - 2.0 * zoom)
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	var disc := (
		PENCIL
		if kit
		else (HouseTheme.FOIL if landmark.district == LoyaltyLandmark.District.STRIP else SIGN_BLUE)
	)
	on.draw_circle(at, 11.0 * zoom, Color(HouseTheme.PAPER, 1.0))
	on.draw_circle(at, 9.5 * zoom, disc)
	var star := PackedVector2Array()
	for i: int in 10:
		var reach := (7.0 if i % 2 == 0 else 3.0) * zoom
		star.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * reach)
	on.draw_colored_polygon(star, HouseTheme.ON_FOIL if disc == HouseTheme.FOIL else SIGN_WHITE)


## The gold NEW tag over [param rect]'s top left corner, at [param zoom], clear of the stamp.
static func draw_new(on: CanvasItem, rect: Rect2, zoom: float) -> void:
	var font := Type.STRONG
	var size := maxi(roundi(NEW_SIZE * zoom), 1)
	var wide := font.get_string_size(CatalogCell.NEW, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var tag := Rect2(
		Vector2(rect.position.x - 4.0 * zoom, rect.position.y - 9.0 * zoom),
		Vector2(wide + 10.0 * zoom, size + 5.0 * zoom)
	)
	on.draw_rect(Rect2(tag.position + Vector2.ONE * 2.0 * zoom, tag.size), Color(0, 0, 0, 0.3))
	on.draw_rect(tag, HouseTheme.FOIL)
	var base := tag.position + Vector2(5.0 * zoom, 2.5 * zoom + font.get_ascent(size))
	on.draw_string(
		font, base, CatalogCell.NEW, HORIZONTAL_ALIGNMENT_LEFT, -1, size, HouseTheme.ON_FOIL
	)


## The picture of what [param landmark] pays, into [param box] on [param on] in [param ink]: the
## first of its cards or its items, or its part of the dress, the Showroom's roller door, a loose
## note's scrap, or for the slip road the program's card.
static func draw_reward(on: CanvasItem, box: Rect2, landmark: LoyaltyLandmark, ink: Color) -> void:
	if not landmark.jokers.is_empty():
		JokerArt.draw_into(on, box, landmark.jokers[0], ink)
	elif not landmark.items.is_empty():
		PowerUpArt.draw_into(on, box, landmark.items[0], ink)
	elif PARTS.has(landmark.dress_part):
		DressArt.draw_into(on, box, PARTS[landmark.dress_part], ink)
	elif landmark.showroom:
		roller_door(on, box, ink)
	elif landmark.note != &"":
		scrap(on, box, ink)
	else:
		DressArt.draw_into(on, box, PARTS[&"card_back"], ink)


## A marquee of the Strip: the dark board in its gold frame, a row of bulbs along its top and its
## foot, lit once [param lit], and the picture and the name in gold.
static func _marquee(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, lit: bool, zoom: float
) -> void:
	_board(on, rect, MARQUEE, zoom)
	var frame := rect.grow(-FRAME * 0.5 * zoom)
	_rounded(on, frame, HouseTheme.FOIL if lit else HouseTheme.FOIL_LOW, false, FRAME * zoom, zoom)
	var bulb := BULB_ON if lit else BULB_OFF
	var step := BULB_STEP * zoom
	var count := maxi(int((rect.size.x - CORNER * 2.0 * zoom) / step), 2)
	var start := rect.position.x + (rect.size.x - step * (count - 1)) * 0.5
	var bulbs := PackedVector2Array()
	for i: int in count:
		for y: float in [rect.position.y + 4.0 * zoom, rect.end.y - 4.0 * zoom]:
			bulbs.append(Vector2(start + step * i, y))
	if lit:
		dots(on, bulbs, BULB * 2.0 * zoom, Color(bulb, 0.25))
	dots(on, bulbs, BULB * zoom, bulb)
	var gold := HouseTheme.FOIL_HIGH if lit else HouseTheme.FOIL
	_face(on, rect.grow_individual(0.0, -3.0 * zoom, 0.0, -3.0 * zoom), landmark, gold, zoom)


## A road sign: [param fill] with a white rim inside its edge, the picture and the name in white.
static func _road_sign(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, fill: Color, zoom: float
) -> void:
	_board(on, rect, fill, zoom)
	_rounded(on, rect.grow(-3.0 * zoom), SIGN_WHITE, false, 1.6 * zoom, zoom)
	_face(on, rect, landmark, SIGN_WHITE, zoom)


## Kit's box in pencil, drawn twice over by hand and not quite closed, the name in Kit's hand.
static func _sketch(on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, zoom: float) -> void:
	on.draw_rect(rect, Color(HouseTheme.PAPER, 0.92))
	var seed := float(landmark.mark.unicode_at(0))
	for pass_at: int in 2:
		var wobble := (1.2 + pass_at * 0.9) * zoom
		var corners: Array[Vector2] = [
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
		for i: int in 4:
			var from := corners[i] + _jitter(seed + i + pass_at * 4.0, wobble)
			var to := corners[(i + 1) % 4] + _jitter(seed + i + 1.0 + pass_at * 4.0, wobble)
			# Over the corner a little, the way a hand runs on.
			to += (to - from).normalized() * 3.0 * zoom
			on.draw_line(from, to, Color(PENCIL, 0.75 - pass_at * 0.3), 1.4 * zoom, true)
	_face(on, rect, landmark, PENCIL, zoom)


## The picture at the left of [param rect] and the name beside it in [param ink], two lines at
## most, in the house's print or, off the books, Kit's hand.
static func _face(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, ink: Color, zoom: float
) -> void:
	var room := ROOM * zoom
	var side := rect.size.y - room * 2.0
	var picture := Rect2(rect.position + Vector2(room, room), Vector2(side, side))
	draw_reward(on, picture, landmark, ink)
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	var font: Font = HAND if kit else Type.STRONG
	var size := maxi(roundi(TITLE_SIZE * zoom * (HAND_SCALE if kit else 1.0)), 1)
	var left := picture.end.x + room * 0.8
	var wide := rect.end.x - room - left
	var lines := lines_of(font, landmark.title, size, wide, 2)
	var tall := font.get_height(size) * (0.82 if kit else 0.92)
	var top := rect.position.y + (rect.size.y - tall * lines.size()) * 0.5
	for i: int in lines.size():
		var base := Vector2(left, top + tall * i + font.get_ascent(size) * (0.86 if kit else 0.9))
		on.draw_string(font, base, lines[i], HORIZONTAL_ALIGNMENT_LEFT, wide, size, ink)


## A board of [param fill] with rounded corners and a shadow under it on the paper.
static func _board(on: CanvasItem, rect: Rect2, fill: Color, zoom: float) -> void:
	_rounded(
		on,
		Rect2(rect.position + Vector2(2.0, 3.0) * zoom, rect.size),
		Color(0, 0, 0, 0.22),
		true,
		0.0,
		zoom
	)
	_rounded(on, rect, fill, true, 0.0, zoom)


## A closed landmark printed pale: the paper over it, so it shows what it pays and little else.
static func _pale(on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, zoom: float) -> void:
	var over := rect.grow(2.0 * zoom)
	if landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS:
		on.draw_rect(over, Color(HouseTheme.PAPER, PALE * 0.8))
		return
	_rounded(on, over, Color(HouseTheme.PAPER, PALE), true, 0.0, zoom)


## A won landmark stamped: in gold foil on the Strip, in red in the Department and on the slip
## road, and off the books a tick in pencil, over its sign's top right corner.
static func _won(on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, zoom: float) -> void:
	# Off the corner rather than over the name, the way a stamp comes down on the edge of a sheet.
	var at := Vector2(rect.end.x + STAMP * 0.15 * zoom, rect.position.y - STAMP * 0.05 * zoom)
	if landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS:
		var tick := PackedVector2Array(
			[at + Vector2(-9, -2) * zoom, at + Vector2(-3, 5) * zoom, at + Vector2(10, -11) * zoom]
		)
		on.draw_polyline(tick, PENCIL, 2.6 * zoom, true)
		return
	var ink := (
		HouseTheme.FOIL
		if landmark.district == LoyaltyLandmark.District.STRIP
		else HouseTheme.STAMP_RED
	)
	stamp(on, at, STAMP * zoom, ink)


## The program's stamp, [param radius] round [param at]: a closed ring and the word across it, a
## little askew and its inner ring fainter, the way ink is. Its outer ring once stopped short of
## closing for the same reason, and read as a stamp drawn wrong rather than one pressed unevenly.
static func stamp(on: CanvasItem, at: Vector2, radius: float, ink: Color) -> void:
	on.draw_set_transform(at, STAMP_TURN, Vector2.ONE)
	on.draw_circle(Vector2.ZERO, radius, Color(HouseTheme.PAPER, 0.55))
	on.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, ink, radius * 0.14, true)
	on.draw_arc(Vector2.ZERO, radius * 0.74, 0.0, TAU, 32, Color(ink, 0.6), radius * 0.05, true)
	var font := Type.display_font()
	var size := maxi(roundi(radius * 0.72), 1)
	var wide := radius * 2.0
	var base := Vector2(-radius, font.get_ascent(size) * 0.5 - size * 0.12)
	on.draw_string(font, base, STAMP_WORD, HORIZONTAL_ALIGNMENT_CENTER, wide, size, ink)
	on.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A rectangle with rounded corners, filled or as a line [param width] wide.
static func _rounded(
	on: CanvasItem, rect: Rect2, ink: Color, filled: bool, width: float, zoom: float
) -> void:
	var corner := minf(CORNER * zoom, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var corners: Array[Vector2] = [
		rect.position + Vector2(corner, corner),
		Vector2(rect.end.x - corner, rect.position.y + corner),
		rect.end - Vector2(corner, corner),
		Vector2(rect.position.x + corner, rect.end.y - corner),
	]
	for i: int in 4:
		for step: int in 5:
			var angle := PI + i * PI * 0.5 + step * PI * 0.125
			points.append(corners[i] + Vector2(cos(angle), sin(angle)) * corner)
	if filled:
		on.draw_colored_polygon(points, ink)
		return
	points.append(points[0])
	on.draw_polyline(points, ink, width, true)


## The Showroom's roller door: its frame, the slats of the door, and the gap under it.
static func roller_door(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.bar(on, box, 0.1, 0.12, 0.8, 0.1, ink)
	IconShapes.bar(on, box, 0.1, 0.12, 0.1, 0.8, ink)
	IconShapes.bar(on, box, 0.8, 0.12, 0.1, 0.8, ink)
	for y: float in [0.3, 0.44, 0.58]:
		IconShapes.bar(on, box, 0.24, y, 0.52, 0.08, IconShapes.behind(ink))


## A loose note: a scrap of paper torn at its foot, lines of writing on it.
static func scrap(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var points := PackedVector2Array(
		[
			IconShapes.at(box, 0.2, 0.12),
			IconShapes.at(box, 0.8, 0.16),
			IconShapes.at(box, 0.78, 0.8),
			IconShapes.at(box, 0.62, 0.86),
			IconShapes.at(box, 0.48, 0.79),
			IconShapes.at(box, 0.34, 0.88),
			IconShapes.at(box, 0.22, 0.82),
		]
	)
	points.append(points[0])
	on.draw_polyline(points, ink, maxf(IconShapes.width(box), 1.0), true)
	for y: float in [0.34, 0.48, 0.62]:
		IconShapes.line(on, box, 0.32, y, 0.68, y + 0.01, IconShapes.behind(ink))


## [param text] in [param font] at [param size] broken into lines no wider than [param wide], at
## most [param most] of them, the last cut short with an ellipsis where it runs on.
static func lines_of(
	font: Font, text: String, size: int, wide: float, most: int
) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word: String in text.split(" ", false):
		var tried := word if line.is_empty() else line + " " + word
		if (
			line.is_empty()
			or font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= wide
		):
			line = tried
		else:
			lines.append(line)
			line = word
	if not line.is_empty():
		lines.append(line)
	if lines.size() > most:
		var kept := lines.slice(0, most)
		kept[most - 1] = kept[most - 1] + "…"
		return kept
	return lines


## A hand's wobble at a corner, the same every time it is drawn for the same [param seed].
static func _jitter(seed: float, by: float) -> Vector2:
	return Vector2(sin(seed * 12.9898) * by, cos(seed * 78.233) * by)


## A dot [param radius] round each of [param spots] in [param ink], each the one soft dot drawn
## once, see [method _dot]: a texture drawn again is batched as one, where a smoothed circle is
## worked out and drawn on its own every time.
static func dots(on: CanvasItem, spots: PackedVector2Array, radius: float, ink: Color) -> void:
	var dot := _dot()
	var across := Vector2.ONE * radius * 2.0
	for at: Vector2 in spots:
		on.draw_texture_rect(dot, Rect2(at - across * 0.5, across), false, ink)


## The soft dot of [method dots]: a white disc with a smoothed edge, made once.
static func _dot() -> Texture2D:
	if _dot_made != null:
		return _dot_made
	var image := Image.create_empty(DOT_PIXELS, DOT_PIXELS, false, Image.FORMAT_LA8)
	var middle := Vector2.ONE * DOT_PIXELS * 0.5
	for y: int in DOT_PIXELS:
		for x: int in DOT_PIXELS:
			var out := (Vector2(x, y) + Vector2.ONE * 0.5).distance_to(middle)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(middle.x - out + 0.5, 0.0, 1.0)))
	_dot_made = ImageTexture.create_from_image(image)
	return _dot_made


## A map pin stuck in at [param at], [param tall] high: a needle up from its point and a red head on
## it, a glint on the head; what is pinned wears it, GAME.md 8.9.
static func draw_pin(on: CanvasItem, at: Vector2, tall: float) -> void:
	var head := at + Vector2(tall * 0.3, -tall * 0.72)
	on.draw_line(at, head, Color(0.55, 0.56, 0.6), maxf(tall * 0.07, 1.0), true)
	on.draw_circle(head + Vector2(1.5, 2.0), tall * 0.3, Color(0.0, 0.0, 0.0, 0.3))
	on.draw_circle(head, tall * 0.3, PIN_RED)
	on.draw_circle(head - Vector2(tall * 0.09, tall * 0.09), tall * 0.09, Color(1.0, 1.0, 1.0, 0.7))


## The cursor's mark round the sign at [param rect] the cursor is at, GAME.md 8.9: the sign lifted
## off the paper on a soft shadow, and round it the buttons' own gold edge with its two chevrons,
## see [FocusMark], cased in ink so it shows on the Strip's gold as well as on the Department's blue
## and on the paper. A wash of gold over the sign and a thin gold line round it were lost on the
## Strip, whose signs are gold already.
static func draw_selected(on: CanvasItem, rect: Rect2) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	shadow.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	shadow.shadow_size = 10
	shadow.shadow_offset = Vector2(0.0, 5.0)
	shadow.set_corner_radius_all(6)
	on.draw_style_box(shadow, rect)
	FocusMark.draw_on(on, rect, 4.0, SIDE_LEFT, 1.0, SELECTED_CASING)
