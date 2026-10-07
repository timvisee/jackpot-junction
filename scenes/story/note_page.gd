class_name NotePage
extends Control
## One page of the notes folder, STORY.md 7.2 and 7.3: a leaf of the folder's plain paper with a
## note clipped to it as it was found, folds and all, its title pencilled over it. Every note is on
## the paper it was found on and in the hand it was written in, drawn here in code the way every
## picture in the game is: the House's paperwork typed, Kit's in pencil, ballpoint or felt-tip, the
## first edition in an old book's face. A note found and not yet read carries a pencilled mark in
## the top corner. No number anywhere: a player never learns how many there are.

## The leaf, the folder's own paper, and its pencil.
const SIZE := Vector2(440.0, 580.0)
const LEAF := Color(0.95, 0.94, 0.9)
const LEAF_EDGE := Color(0.8, 0.78, 0.72)
const PENCIL := Color(0.32, 0.32, 0.35)
const MARGIN := 26.0
const TITLE_SIZE := 22
## Where the note's paper sits on the leaf: under the title, in the middle of what is left.
const TITLE_ROOM := 70.0
## The faces: the House's typewriter, Kit's hand, the first edition's old face.
const TYPED: Font = preload("res://assets/fonts/CourierPrime-Regular.ttf")
const HAND: Font = preload("res://assets/fonts/HomemadeApple-Regular.ttf")
const OLD: Font = preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
## Inks: the House's black, pencil, ballpoint, felt-tip, a stamp's red, the blueprint's white and
## the old book's brown.
const TYPED_INK := Color(0.13, 0.13, 0.15)
const PEN_INK := Color(0.12, 0.2, 0.5)
const FELT_INK := Color(0.06, 0.06, 0.08)
const STAMP_INK := Color(0.75, 0.12, 0.12, 0.82)
const BLUEPRINT_INK := Color(0.9, 0.95, 1.0)
const OLD_INK := Color(0.28, 0.2, 0.12)
## Each paper: its size on the leaf, its color, the size its type is set at, and how far in from its
## edge the words start.
const PAPERS := {
	&"receipt": [Vector2(260.0, 250.0), Color(0.97, 0.97, 0.95), 12, 18.0],
	&"graph": [Vector2(370.0, 320.0), Color(0.93, 0.95, 0.97), 13, 22.0],
	&"graph_torn": [Vector2(370.0, 420.0), Color(0.93, 0.95, 0.97), 13, 22.0],
	&"form": [Vector2(380.0, 360.0), Color(0.95, 0.94, 0.88), 11, 18.0],
	&"flyer": [Vector2(360.0, 300.0), Color(0.1, 0.12, 0.2), 13, 22.0],
	&"sheet": [Vector2(360.0, 270.0), Color(0.98, 0.98, 0.97), 11, 20.0],
	&"slip": [Vector2(320.0, 280.0), Color(0.95, 0.92, 0.84), 13, 24.0],
	&"napkin": [Vector2(310.0, 310.0), Color(0.98, 0.97, 0.95), 13, 30.0],
	&"pamphlet": [Vector2(320.0, 300.0), Color(0.92, 0.92, 0.9), 8, 18.0],
	&"old_page": [Vector2(370.0, 340.0), Color(0.88, 0.8, 0.6), 17, 26.0],
	&"clipboard": [Vector2(360.0, 330.0), Color(0.98, 0.98, 0.97), 11, 20.0],
	&"memo": [Vector2(380.0, 340.0), Color(0.98, 0.98, 0.97), 10, 18.0],
	&"envelope": [Vector2(380.0, 270.0), Color(0.88, 0.8, 0.62), 13, 26.0],
	&"roll": [Vector2(300.0, 420.0), Color(0.97, 0.97, 0.95), 10, 16.0],
	&"blueprint": [Vector2(400.0, 440.0), Color(0.13, 0.32, 0.62), 8, 16.0],
	&"chart": [Vector2(390.0, 300.0), Color(0.84, 0.84, 0.82), 10, 16.0],
	&"letter": [Vector2(370.0, 340.0), Color(0.98, 0.98, 0.97), 11, 24.0],
	&"strip": [Vector2(390.0, 120.0), Color(0.94, 0.91, 0.82), 13, 18.0],
	&"card": [Vector2(340.0, 214.0), Color(0.11, 0.1, 0.13), 10, 20.0],
	&"calendar": [Vector2(330.0, 400.0), Color(0.97, 0.96, 0.92), 12, 18.0],
}
## Each voice: its face, its ink, its size against the paper's type, and how much its letters
## wander.
const VOICES := {
	&"print": [TYPED, TYPED_INK, 1.0, 0.0],
	&"small": [TYPED, Color(0.35, 0.35, 0.38), 0.8, 0.0],
	&"hand": [HAND, PENCIL, 1.15, 0.6],
	&"pen": [HAND, PEN_INK, 1.15, 0.5],
	&"felt": [HAND, FELT_INK, 1.3, 0.4],
	&"shaky": [HAND, PENCIL, 1.15, 2.2],
	&"hard": [HAND, Color(0.2, 0.2, 0.22), 1.15, 0.6],
	&"hurried": [HAND, PENCIL, 1.2, 1.4],
	&"margin": [HAND, PENCIL, 0.9, 0.5],
	&"old": [OLD, OLD_INK, 1.0, 0.0],
	&"display": [null, Palette.CHIP_GOLD, 2.4, 0.0],
}

## Which note this page holds, and whose folder it is, for the placeholders.
var number := 0
var profile: Profile
## Whether the note is new: found and not yet read, STORY.md 7.2.
var new := false

var _rng := RandomNumberGenerator.new()


## A page holding note [param numbered] for [param of].
static func make(numbered: int, of: Profile, is_new := false) -> NotePage:
	var page := NotePage.new()
	page.name = "NotePage%d" % numbered
	page.number = numbered
	page.profile = of
	page.new = is_new
	page.custom_minimum_size = SIZE
	page.size = SIZE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return page


func paper() -> StringName:
	return StringName(StoryNotes.NOTES.get(number, {}).get("paper", &"sheet"))


## Where the note's paper lies on the leaf.
func paper_rect() -> Rect2:
	var spec: Array = PAPERS.get(paper(), PAPERS[&"sheet"])
	var wide: Vector2 = spec[0]
	var room := Rect2(0.0, TITLE_ROOM, SIZE.x, SIZE.y - TITLE_ROOM - MARGIN * 0.5)
	return Rect2(room.get_center() - wide * 0.5, wide)


func _draw() -> void:
	_rng.seed = number * 7919
	draw_rect(Rect2(Vector2.ZERO, SIZE), LEAF)
	draw_rect(Rect2(Vector2.ZERO, SIZE), LEAF_EDGE, false, 1.0)
	_scrawl(StoryNotes.title_of(number), Vector2(MARGIN, 46.0), TITLE_SIZE, PENCIL, 0.4)
	if new:
		_draw_new_mark()
	# The back of the folder, after the ending: no note's paper, what the player kept.
	if number < 0:
		FolderBack.draw(self, number, profile)
		return
	var rect := paper_rect()
	var kind := paper()
	var spec: Array = PAPERS.get(kind, PAPERS[&"sheet"])
	# A shadow under the paper, so it lies on the leaf rather than in it; what was torn off a flyer
	# casts none.
	var shadow := rect
	if kind == &"flyer":
		shadow.size.y *= 0.74
	draw_rect(Rect2(shadow.position + Vector2(3.0, 4.0), shadow.size), Color(0.0, 0.0, 0.0, 0.12))
	NotePaper.draw_paper(self, kind, rect, spec[1])
	var inside := rect.grow(-float(spec[3]))
	match kind:
		&"blueprint":
			NotePaper.draw_blueprint(self, rect)
			inside = Rect2(
				rect.position + Vector2(rect.size.x * 0.32, rect.size.y * 0.66),
				Vector2(rect.size.x * 0.64, rect.size.y * 0.3)
			)
		&"calendar":
			_draw_calendar(rect)
			return
		&"chart":
			_draw_chart(inside, int(spec[2]))
			NotePaper.draw_clip(self, rect)
			return
		&"form":
			inside.position.y += 26.0
			inside.size.y -= 26.0
		&"memo":
			inside.position.y += 18.0
		&"letter":
			inside.position.y += 40.0
	_write_lines(inside, int(spec[2]), kind)
	var stamp := str(StoryNotes.NOTES.get(number, {}).get("stamp", ""))
	if kind == &"form":
		stamp = "RECEIVED"
	if not stamp.is_empty():
		NotePaper.draw_stamp(self, stamp, rect.position + rect.size * Vector2(0.7, 0.84), -0.18)
	if kind == &"graph" and number == 2:
		NotePaper.draw_sketch(self, rect)
	if kind == &"strip":
		return
	NotePaper.draw_clip(self, rect)


## The note's lines down [param inside], each in its voice, wrapped to the paper, the House's
## dotted leaders run out to the paper's width.
func _write_lines(inside: Rect2, type_size: int, kind: StringName) -> void:
	var y := inside.position.y
	for line: Array in StoryNotes.NOTES.get(number, {}).get("lines", []):
		var voice: StringName = line[0]
		var text := StoryFill.fill(str(line[1]), profile) if profile != null else str(line[1])
		var spec: Array = VOICES.get(voice, VOICES[&"print"])
		var font: Font = spec[0] if spec[0] != null else Type.display_font()
		var font_size := maxi(roundi(type_size * float(spec[2])), 7)
		var ink: Color = spec[1]
		if kind == &"blueprint":
			ink = BLUEPRINT_INK
		elif kind == &"card" and voice == &"print":
			ink = Palette.CHIP_GOLD
		elif kind == &"flyer" and voice != &"display":
			ink = Color(0.92, 0.9, 0.84)
		var x := inside.position.x
		var width := inside.size.x
		if voice == &"margin":
			# In the margin, beside what it is about: indented, a little down, at a slant.
			x += width * 0.18
			width *= 0.8
			y += 4.0
		var top := y
		var leader := _leader_of(text) if font == TYPED else PackedStringArray()
		if leader.size() == 2:
			y = leader_line(leader[0], leader[1], font, font_size, ink, x, y, width)
		else:
			var jitter: float = spec[3]
			y = _wrap(text, font, font_size, ink, x, y, width, jitter, voice == &"hard")
			if voice == &"hurried":
				_through(text.get_slice(" ", 0), font, font_size, Vector2(x, top))
		if line.size() > 2 and bool(line[2]):
			_strike(Rect2(x - 4.0, top, width + 8.0, y - top))
		y += font_size * (0.55 if font == TYPED else 0.35)


## [param text] split at its dotted leader into what is on either side of it, or nothing.
static func _leader_of(text: String) -> PackedStringArray:
	var found := RegEx.create_from_string("^(.*?\\S)\\s*\\.{2,}\\s*(\\S.*)?$").search(text)
	if found == null:
		return PackedStringArray()
	return PackedStringArray([found.get_string(1), found.get_string(2)])


## A typed line with a dotted leader: the left part, dots to the right part set against the
## paper's edge, or the right part on a line of its own if both do not fit.
func leader_line(
	left: String,
	right: String,
	font: Font,
	font_size: int,
	ink: Color,
	x: float,
	y: float,
	width: float
) -> float:
	var line := font.get_height(font_size)
	var left_wide := font.get_string_size(left + " ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var right_wide := font.get_string_size(" " + right, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var dot := font.get_string_size(".", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := y + font.get_ascent(font_size)
	draw_string(font, Vector2(x, baseline), left, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
	if left_wide + right_wide + dot * 2.0 > width:
		# Too long for one line: what is right of the dots goes under, indented, wrapped if need be.
		if right_wide > width:
			return _wrap(right, font, font_size, ink, x + dot * 2.0, y + line, width - dot * 2.0)
		baseline += line
		y += line
		left_wide = 0.0
	var dots := floori((width - left_wide - right_wide) / dot)
	if dots > 0 and left_wide > 0.0:
		draw_string(
			font,
			Vector2(x + left_wide, baseline),
			".".repeat(dots),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			ink
		)
	draw_string(
		font,
		Vector2(x + width - right_wide, baseline),
		" " + right,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		ink
	)
	return y + line


## [param text] wrapped to [param width] from ([param x], [param y]), returning where it ended. A
## hand wanders by [param jitter]; written [param hard] it is gone over twice.
func _wrap(
	text: String,
	font: Font,
	font_size: int,
	ink: Color,
	x: float,
	y: float,
	width: float,
	jitter := 0.0,
	hard := false
) -> float:
	var line_height := font.get_height(font_size) * (0.82 if font == HAND else 1.0)
	for row: String in _rows(text, font, font_size, width):
		var baseline := y + font.get_ascent(font_size) * (0.8 if font == HAND else 1.0)
		if jitter > 0.0:
			_scrawl(row, Vector2(x, baseline), font_size, ink, jitter, font)
			if hard:
				_scrawl(row, Vector2(x + 0.7, baseline + 0.4), font_size, ink, jitter * 0.3, font)
		else:
			draw_string(
				font, Vector2(x, baseline), row, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink
			)
		y += line_height
	return y


## [param text] broken into rows no wider than [param width].
static func _rows(text: String, font: Font, font_size: int, width: float) -> PackedStringArray:
	var rows := PackedStringArray()
	var row := ""
	for word: String in text.split(" ", false):
		var tried := word if row.is_empty() else row + " " + word
		if font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			if not row.is_empty():
				rows.append(row)
			row = word
		else:
			row = tried
	if not row.is_empty():
		rows.append(row)
	return rows


## Handwriting: each letter drawn on its own, a little off the line, the more so the shakier the
## hand.
func _scrawl(
	text: String, at: Vector2, font_size: int, ink: Color, jitter: float, font: Font = HAND
) -> void:
	var x := at.x
	for i: int in text.length():
		var letter := text.unicode_at(i)
		var off := Vector2(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-1.0, 1.0)) * jitter
		draw_char(font, Vector2(x, at.y) + off, text.substr(i, 1), font_size, ink)
		x += font.get_char_size(letter, font_size).x


## The first word written so hard the pencil went through the paper, STORY.md 7.3: gone over
## again, and a slit torn under it with the leaf showing through.
func _through(word: String, font: Font, font_size: int, at: Vector2) -> void:
	var baseline := at.y + font.get_ascent(font_size) * 0.8
	_scrawl(word, Vector2(at.x + 0.8, baseline + 0.5), font_size, PENCIL, 0.3, font)
	var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var slit := PackedVector2Array()
	for i: int in 7:
		var t := float(i) / 6.0
		slit.append(
			Vector2(at.x + wide * (0.15 + t * 0.7), baseline + 3.0 + (1.5 if i % 2 == 0 else 0.0))
		)
	for i: int in range(6, -1, -1):
		var t := float(i) / 6.0
		slit.append(
			Vector2(at.x + wide * (0.15 + t * 0.7), baseline + 5.0 + (0.0 if i % 2 == 0 else 1.5))
		)
	draw_colored_polygon(slit, LEAF)
	draw_polyline(slit, Color(0.0, 0.0, 0.0, 0.35), 1.0, true)


## A line struck through by hand, in ink, not quite straight.
func _strike(over: Rect2) -> void:
	var middle := over.position.y + over.size.y * 0.45
	var points := PackedVector2Array()
	for i: int in 9:
		var t := float(i) / 8.0
		points.append(Vector2(over.position.x + over.size.x * t, middle + sin(t * 9.0) * 1.2))
	draw_polyline(points, PEN_INK, 2.0, true)


## The pencilled mark of a note not yet read, STORY.md 7.2: an exclamation mark in a ring, in the
## top corner.
func _draw_new_mark() -> void:
	var middle := Vector2(SIZE.x - MARGIN - 6.0, 36.0)
	draw_arc(middle, 15.0, 0.3, TAU + 0.1, 24, PENCIL, 1.6, true)
	draw_char(HAND, middle + Vector2(-4.0, 9.0), "!", 22, PENCIL)


## The organization chart: each office centered under the one over it, joined by a line, and the
## vacancy under them all.
func _draw_chart(inside: Rect2, type_size: int) -> void:
	var lines: Array = StoryNotes.NOTES[number]["lines"]
	var y := inside.position.y + 6.0
	var ink := Color(0.22, 0.22, 0.24)
	for i: int in lines.size() - 1:
		var text := str(lines[i][1])
		var rows := _rows(text, TYPED, type_size, inside.size.x)
		for row: String in rows:
			var wide := TYPED.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, type_size).x
			var x := inside.get_center().x - wide * 0.5
			draw_string(
				TYPED,
				Vector2(x, y + TYPED.get_ascent(type_size)),
				row,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				type_size,
				ink
			)
			y += TYPED.get_height(type_size)
		if i < lines.size() - 2:
			var mid := inside.get_center().x
			draw_line(Vector2(mid, y + 2.0), Vector2(mid, y + 20.0), ink, 1.0)
			y += 24.0
	y += 26.0
	_leader_or_wrap(
		str(lines[lines.size() - 1][1]), type_size, ink, inside.position.x, y, inside.size.x
	)


func _leader_or_wrap(
	text: String, type_size: int, ink: Color, x: float, y: float, width: float
) -> void:
	var leader := _leader_of(text)
	if leader.size() == 2:
		leader_line(leader[0], leader[1], TYPED, type_size, ink, x, y, width)
	else:
		_wrap(text, TYPED, type_size, ink, x, y, width)


## The calendar page: the month after the ringed one, see [StoryDressing], its days in a grid
## under a red band, blank but for the first, where Kit has written.
func _draw_calendar(rect: Rect2) -> void:
	var band := Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.2))
	draw_rect(band, Color(0.72, 0.24, 0.2))
	var month: Vector2i = StoryDressing.MONTHS[1]
	var grid := Rect2(
		rect.position + Vector2(14.0, band.size.y + 14.0),
		Vector2(rect.size.x - 28.0, rect.size.y - band.size.y - 28.0)
	)
	var cell := Vector2(grid.size.x / 7.0, grid.size.y / 5.0)
	var ink := Color(0.62, 0.6, 0.6)
	for i: int in 8:
		var x := grid.position.x + cell.x * i
		draw_line(Vector2(x, grid.position.y), Vector2(x, grid.end.y), ink, 1.0)
	for i: int in 6:
		var y := grid.position.y + cell.y * i
		draw_line(Vector2(grid.position.x, y), Vector2(grid.end.x, y), ink, 1.0)
	for day: int in month.x:
		var index := month.y + day
		var at := grid.position + Vector2(cell.x * (index % 7) + 4.0, cell.y * floorf(index / 7.0))
		draw_string(
			TYPED, at + Vector2(0.0, 13.0), str(day + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ink
		)
	# Kit's words from the first day on, across the week under it.
	var first := month.y
	var from := (
		grid.position + Vector2(cell.x * (first % 7) + 4.0, cell.y * floorf(first / 7.0) + 20.0)
	)
	var words := str(StoryNotes.NOTES[number]["lines"][0][1])
	var rows := _rows(words, HAND, 14, grid.end.x - from.x - 4.0)
	if rows.size() > 2:
		from.x = grid.position.x + 6.0
		rows = _rows(words, HAND, 14, grid.size.x - 12.0)
	var y := from.y + 14.0
	for row: String in rows:
		_scrawl(row, Vector2(from.x, y), 14, PENCIL, 0.5)
		y += 18.0
	NotePaper.draw_clip(self, rect)
