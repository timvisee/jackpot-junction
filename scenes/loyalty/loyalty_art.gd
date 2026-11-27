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
	&"paint": 0,
	&"hat": 1,
	&"flag": 2,
	&"trail": 3,
	&"frame": 4,
	&"marks": 5,
	&"body": 6,
	&"card_back": 7,
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
## The pin's drawing: how big its box is for its height, and where in that box its needle's point
## and its head's middle are and how big the head is, as shares of the box; the needle's steel.
const PIN_BOX := 1.34
const PIN_TIP := Vector2(0.302, 0.885)
const PIN_HEAD := Vector2(0.604, 0.354)
const PIN_HEAD_SIZE := 0.229
const PIN_STEEL := Color(0.55, 0.56, 0.6)
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
## The bulbs chasing round the sign the cursor is at: every this many is bright at a time.
const CHASE_GAP := 3
## The stamp on a won landmark: how big round, its word, shown through tr(), and how far it is
## turned.
const STAMP := 24.0
const STAMP_WORD := "WON"
const STAMP_TURN := -0.32
## The stamp's ring in its drawing, in the drawing's 48 units, and the word's size for its radius.
const STAMP_RING := 20.0
const STAMP_WORD_SIZE := 0.5
## A keystone's crest: its disc's radius at zoom 1, and in its drawing's 48 units.
const CREST := 9.5
const CREST_DISC := 19.0
## Kit's tick: its lowest point in its drawing's 48 units, and how wide it is there.
const TICK_FOOT := Vector2(20.0, 38.5)
const TICK_WIDE := 36.0
## The Strip's seal on a won landmark: how big round, how far it is turned, and its ribbons' red;
## where its disc is in its drawing, and its radius there, in the drawing's 48 units.
const SEAL := 21.0
const SEAL_TURN := 0.18
const SEAL_MIDDLE := Vector2(24.0, 16.0)
const SEAL_DISC := 15.0
const RIBBON := Color(0.72, 0.13, 0.12)
## How far a lit marquee's glow reaches onto the paper round it.
const GLOW := 13.0
## Kit's tick on a landmark won off the books, how big, and the loop he draws round its sign.
const TICK := 17.0
const LOOP_ROOM := 9.0
## The NEW tag on a landmark won and not yet looked at, as the catalog's card wears it.
const NEW_SIZE := 11.0
## How many pixels across the soft dot of [method dots] is drawn at.
const DOT_PIXELS := 12
## The ink the cursor's gold edge is cased in on the map, round a sign and round the roundabout.
const SELECTED_CASING := Color(HouseTheme.INK, 0.85)

static var _dot_made: Texture2D


## Draws [param landmark]'s sign into [param rect] on [param on], at [param zoom], as it
## [param stands], see [enum Loyalty.Standing]; a marquee's bulbs chasing round it at the step
## [param chase], none for -1 or while it is closed.
static func draw_sign(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, stands: int, zoom: float, chase := -1
) -> void:
	var lit := stands == Loyalty.Standing.WON
	var closed := stands == Loyalty.Standing.CLOSED
	match landmark.district:
		LoyaltyLandmark.District.STRIP:
			_marquee(on, rect, landmark, lit, zoom, -1 if closed else chase)
		LoyaltyLandmark.District.DEPARTMENT:
			_road_sign(on, rect, landmark, SIGN_BLUE, zoom)
		LoyaltyLandmark.District.OFF_THE_BOOKS:
			_sketch(on, rect, landmark, zoom)
		_:
			_road_sign(on, rect, landmark, MOTORWAY, zoom)
	if closed:
		_pale(on, rect, landmark, zoom)
	# Over the pale, which would leave the half of it over the sign's top paler than the rest.
	if landmark.keystone:
		_crest(on, rect, landmark, zoom, PALE if closed else 0.0)
	if lit:
		draw_won(on, rect, landmark, zoom)


## A keystone's crest over the middle of its sign's top, a drawing of GAME.md 8.3a: a disc of its
## district's color with a ring cut inside it and a star on it, gone [param pale] of the way to the
## paper, as a closed sign's pale leaves it.
static func _crest(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, zoom: float, pale := 0.0
) -> void:
	var at := Vector2(rect.get_center().x, rect.position.y - 2.0 * zoom)
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	var disc := (
		PENCIL
		if kit
		else (HouseTheme.FOIL if landmark.district == LoyaltyLandmark.District.STRIP else SIGN_BLUE)
	)
	var face := IconPress.CREAM if disc == HouseTheme.FOIL else SIGN_WHITE
	on.draw_circle(at, 11.0 * zoom, Color(HouseTheme.PAPER, 1.0))
	# The printed disc, its star cream on it, faded toward the paper as far as the sign is.
	var side := CREST * zoom * 48.0 / CREST_DISC
	var box := Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	var ink := Color(disc, 1.0 - pale)
	IconPress.draw(on, box, &"crest_disc", ink, IconPress.Ground.TWO_INKS, face, true)


## The gold NEW tag over [param rect]'s top left corner, at [param zoom], clear of the stamp.
static func draw_new(on: CanvasItem, rect: Rect2, zoom: float) -> void:
	var rects: Array[Rect2] = [rect]
	draw_new_tags(on, rects, zoom)


## The NEW tags of the signs at [param rects] on [param on], the tags first and the words after, so
## however many there are they are drawn in a draw or two rather than a few each.
static func draw_new_tags(on: CanvasItem, rects: Array[Rect2], zoom: float) -> void:
	var font := Type.STRONG
	var size := maxi(roundi(NEW_SIZE * zoom), 1)
	var word := Lang.t(CatalogCell.NEW)
	var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var tags: Array[Rect2] = []
	for rect: Rect2 in rects:
		tags.append(
			Rect2(
				Vector2(rect.position.x - 4.0 * zoom, rect.position.y - 9.0 * zoom),
				Vector2(wide + 10.0 * zoom, size + 5.0 * zoom)
			)
		)
	for tag: Rect2 in tags:
		on.draw_rect(Rect2(tag.position + Vector2.ONE * 2.0 * zoom, tag.size), Color(0, 0, 0, 0.3))
	for tag: Rect2 in tags:
		on.draw_rect(tag, HouseTheme.FOIL)
	for tag: Rect2 in tags:
		var base := tag.position + Vector2(5.0 * zoom, 2.5 * zoom + font.get_ascent(size))
		on.draw_string(font, base, word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, HouseTheme.ON_FOIL)


## Whether a picture in [param ink] is printed on paper: the program draws its cards and items in
## its dark ink on the map, the slip and the stamp, and in a light one on the blueprint's blue.
static func paper_ink(ink: Color) -> bool:
	return ink.get_luminance() < 0.5


## The picture of what [param landmark] pays, into [param box] on [param on] in [param ink]: the
## first of its cards or its items, or its part of the dress, the Showroom's roller door, a loose
## note's scrap, or for the slip road the program's card.
static func draw_reward(on: CanvasItem, box: Rect2, landmark: LoyaltyLandmark, ink: Color) -> void:
	if not landmark.jokers.is_empty():
		JokerArt.draw_into(on, box, landmark.jokers[0], ink, paper_ink(ink))
	elif not landmark.items.is_empty():
		PowerUpArt.draw_into(on, box, landmark.items[0], ink, paper_ink(ink))
	elif PARTS.has(landmark.dress_part):
		DressArt.draw_into(on, box, PARTS[landmark.dress_part], ink)
	elif landmark.showroom:
		roller_door(on, box, ink)
	elif landmark.note != &"":
		scrap(on, box, ink)
	else:
		DressArt.draw_into(on, box, PARTS[&"card_back"], ink)


## A marquee of the Strip: the dark board in its gold frame, a row of bulbs along its top and its
## foot, lit once [param lit], and the picture and the name in gold. Where [param chase] is a
## step, the bulbs chase round it from that step on, as a casino's marquee lights do.
static func _marquee(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, lit: bool, zoom: float, chase := -1
) -> void:
	if lit:
		# Lit, its bulbs throw a glow on the paper round it.
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color(BULB_ON, 0.0)
		glow.shadow_color = Color(BULB_ON, 0.7)
		glow.shadow_size = maxi(roundi(GLOW * zoom), 1)
		glow.set_corner_radius_all(maxi(roundi(CORNER * zoom), 1))
		on.draw_style_box(glow, rect)
	_board(on, rect, MARQUEE, zoom)
	var frame := rect.grow(-FRAME * 0.5 * zoom)
	_rounded(on, frame, HouseTheme.FOIL if lit else HouseTheme.FOIL_LOW, false, FRAME * zoom, zoom)
	var bulb := BULB_ON if lit else BULB_OFF
	var step := BULB_STEP * zoom
	var count := maxi(int((rect.size.x - CORNER * 2.0 * zoom) / step), 2)
	var start := rect.position.x + (rect.size.x - step * (count - 1)) * 0.5
	# Round the sign: along its top left to right, and back along its foot.
	var bulbs := PackedVector2Array()
	for i: int in count:
		bulbs.append(Vector2(start + step * i, rect.position.y + 4.0 * zoom))
	for i: int in range(count - 1, -1, -1):
		bulbs.append(Vector2(start + step * i, rect.end.y - 4.0 * zoom))
	# Chasing round it, every third bulb bright, a step on each time it is drawn.
	var bright := PackedVector2Array()
	if chase >= 0:
		var rest := PackedVector2Array()
		for i: int in bulbs.size():
			if posmod(i - chase, CHASE_GAP) == 0:
				bright.append(bulbs[i])
			else:
				rest.append(bulbs[i])
		bulbs = rest
	if lit:
		dots(on, bulbs, BULB * 2.0 * zoom, Color(bulb, 0.25))
	dots(on, bulbs, BULB * zoom, bulb)
	if not bright.is_empty():
		dots(on, bright, BULB * 2.6 * zoom, Color(BULB_ON, 0.4))
		dots(on, bright, BULB * 1.25 * zoom, Color.WHITE.lerp(BULB_ON, 0.4))
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


## The landmark's own picture at the left of [param rect], see [LandmarkIcons], and the name beside
## it in [param ink], two lines at most, in the house's print or, off the books, Kit's hand.
static func _face(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, ink: Color, zoom: float
) -> void:
	var room := ROOM * zoom
	var side := rect.size.y - room * 2.0
	var picture := Rect2(rect.position + Vector2(room, room), Vector2(side, side))
	LandmarkIcons.draw_into(on, picture, landmark, ink)
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	var font: Font = HAND if kit else Type.STRONG
	var size := maxi(roundi(TITLE_SIZE * zoom * (HAND_SCALE if kit else 1.0)), 1)
	var left := picture.end.x + room * 0.8
	var wide := rect.end.x - room - left
	var lines := lines_of(font, Lang.t(landmark.title), size, wide, 2)
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


## A won landmark marked, each district its own way so none is lost on its own colors: on the Strip
## a seal of gold foil with red ribbons, see [method seal]; in the Department and on the slip road
## the program's red stamp; and off the books Kit's tick in pencil and a loop round the sign, see
## [method _ticked]. Over its sign's top right corner, the way a stamp comes down on the edge of a
## sheet rather than over the name; [param grow] times as big, coming down as the map shows the bet
## being won, see [LoyaltyReveal].
static func draw_won(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, zoom: float, grow := 1.0
) -> void:
	match landmark.district:
		LoyaltyLandmark.District.OFF_THE_BOOKS:
			_ticked(on, rect, landmark, zoom, grow)
		LoyaltyLandmark.District.STRIP:
			var at := Vector2(rect.end.x + SEAL * 0.1 * zoom, rect.position.y + SEAL * 0.05 * zoom)
			seal(on, at, SEAL * zoom * grow)
		_:
			var at := Vector2(
				rect.end.x + STAMP * 0.15 * zoom, rect.position.y - STAMP * 0.05 * zoom
			)
			stamp(on, at, STAMP * zoom * grow, HouseTheme.STAMP_RED)


## The Strip's seal, [param radius] round [param at], a drawing of GAME.md 8.3a printed in two
## inks: two red ribbons cut to a swallowtail hanging under a disc of gold, its edge cut in points
## and a ring cut inside it, its shadow side screened; and the word in the gold's dark over it.
## Under [param base], the transform it is drawn under, a little turned.
static func seal(on: CanvasItem, at: Vector2, radius: float, base := Transform2D.IDENTITY) -> void:
	on.draw_set_transform_matrix(base * Transform2D(SEAL_TURN, at))
	# The drawing's disc is SEAL_DISC across its 48 units, its middle at SEAL_MIDDLE.
	var unit := radius / SEAL_DISC
	var box := Rect2(-SEAL_MIDDLE * unit, Vector2.ONE * 48.0 * unit)
	var two := IconPress.Ground.TWO_INKS
	IconPress.draw(on, box, &"medal_seal_red", RIBBON, two, IconPress.CREAM, true)
	IconPress.draw(on, box, &"medal_seal", HouseTheme.FOIL, two, IconPress.CREAM, true)
	var font := Type.display_font()
	var size := maxi(roundi(radius * 0.62), 1)
	var word_at := Vector2(-radius, font.get_ascent(size) * 0.5 - size * 0.12)
	on.draw_string(
		font,
		word_at,
		Lang.t(STAMP_WORD),
		HORIZONTAL_ALIGNMENT_CENTER,
		radius * 2.0,
		size,
		HouseTheme.ON_FOIL
	)
	on.draw_set_transform_matrix(base)


## A landmark won off the books, as Kit marks one done: a loop drawn round its sign by hand, running
## on past where it started, gone over twice, and a big tick over its top right corner, a drawing of
## GAME.md 8.3a in his pencil, [param grow] times as big.
static func _ticked(
	on: CanvasItem, rect: Rect2, landmark: LoyaltyLandmark, zoom: float, grow := 1.0
) -> void:
	var seed := float(landmark.mark.unicode_at(0))
	var middle := rect.get_center()
	var reach := rect.size * 0.5 + Vector2.ONE * LOOP_ROOM * zoom
	for pass_at: int in 2:
		var loop := PackedVector2Array()
		var start := -2.3 + sin(seed) * 0.4 + pass_at * 0.25
		for i: int in 41:
			var angle := start + TAU * 1.08 * i / 40.0
			# A loop round a box is a squashed circle, a little wider than the box at its ends.
			var out := Vector2(cos(angle), sin(angle))
			var round_by := 1.0 + 0.08 * sin(angle * 2.0 + seed) + pass_at * 0.03
			loop.append(middle + out * reach * Vector2(1.12, 1.25) * round_by)
		on.draw_polyline(
			loop, Color(PENCIL, 0.7 - pass_at * 0.35), (1.6 - pass_at * 0.5) * zoom, true
		)
	var at := Vector2(rect.end.x - 2.0 * zoom, rect.position.y + 2.0 * zoom)
	# The printed tick, its foot where the drawn one's was, as wide as it was.
	var tick := TICK * zoom * grow
	var unit := tick * 1.6 / TICK_WIDE
	var foot := at + Vector2(-0.2, 0.55) * tick
	var box := Rect2(foot - TICK_FOOT * unit, Vector2.ONE * 48.0 * unit)
	IconPress.draw(on, box, &"tick_print", PENCIL, IconPress.Ground.PAPER)


## The program's stamp, [param radius] round [param at], a drawing of GAME.md 8.3a pressed in
## [param ink]: a heavy ring, a fine one inside it, a star over the word and one under it, the word
## across the middle, a little askew. Its outer ring once stopped short of closing, and read as a
## stamp drawn wrong rather than one pressed unevenly.
## Under [param base], the transform it is drawn under, as the seal is.
static func stamp(
	on: CanvasItem, at: Vector2, radius: float, ink: Color, base := Transform2D.IDENTITY
) -> void:
	on.draw_set_transform_matrix(base * Transform2D(STAMP_TURN, at))
	on.draw_circle(Vector2.ZERO, radius, Color(HouseTheme.PAPER, 0.55))
	var unit := radius / STAMP_RING
	var box := Rect2(-Vector2.ONE * 24.0 * unit, Vector2.ONE * 48.0 * unit)
	IconPress.draw(on, box, &"stamp_ring", ink, IconPress.Ground.PAPER)
	var font := Type.display_font()
	var size := maxi(roundi(radius * STAMP_WORD_SIZE), 1)
	var wide := radius * 2.0
	var word_at := Vector2(-radius, font.get_ascent(size) * 0.5 - size * 0.12)
	var word := Lang.t(STAMP_WORD)
	on.draw_string(font, word_at, word, HORIZONTAL_ALIGNMENT_CENTER, wide, size, ink)
	on.draw_set_transform_matrix(base)


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


## The Showroom's roller door, what its bet pays: the Showroom's own drawing, the door rolled down
## under its sign, see [LandmarkIcons].
static func roller_door(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconPress.draw(on, box, &"landmark_showroom", ink, IconPress.Ground.PAPER)


## The House's star, a drawing of GAME.md 8.3a, filling [param box]: the roundabout's, where the
## loyalty program says what a lap of it pays.
static func house_star(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconPress.draw(on, box, &"ui_star", ink, IconPress.Ground.PAPER)


## A note's scrap, what a bet pays when it pays one of Kit's notes: a scrap of paper torn along its
## foot with lines written on it, a drawing of GAME.md 8.3a.
static func scrap(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconPress.draw(on, box, &"note_scrap", ink, IconPress.Ground.PAPER)


## [param text] in [param font] at [param size] broken into lines no wider than [param wide], at
## most [param most] of them, the last cut short with an ellipsis where it runs on.
static func lines_of(
	font: Font, text: String, size: int, wide: float, most: int
) -> PackedStringArray:
	var lines := Type.rows(text, font, size, wide)
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


## A map pin stuck in at [param at], [param tall] high, the Pin button's drawing, see
## [method HouseArt.pin]: a steel needle up from its point and a red head on it, its shadow side
## screened, or a flat darker red while it is small, the head's shadow on the paper; what is pinned
## wears it, GAME.md 8.9.
static func draw_pin(on: CanvasItem, at: Vector2, tall: float) -> void:
	var side := tall * PIN_BOX
	var box := Rect2(at - PIN_TIP * side, Vector2(side, side))
	var head := box.position + PIN_HEAD * side
	on.draw_circle(head + Vector2(1.5, 2.0), PIN_HEAD_SIZE * side, Color(0.0, 0.0, 0.0, 0.3))
	IconPress.draw(on, box, &"ui_pin", PIN_RED, IconPress.Ground.TWO_INKS, PIN_STEEL, true)


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
