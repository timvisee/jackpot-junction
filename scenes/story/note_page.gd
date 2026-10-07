class_name NotePage
extends Control
## One page of the notes folder, STORY.md 7.2 and 7.3: a leaf of the folder's plain paper with a
## note clipped to it as it was found, folds and all, its title pencilled over it. Every note is on
## the paper it was found on and in the hand it was written in, drawn here in code the way every
## picture in the game is: the House's paperwork typed, Kit's in pencil and the other hands among
## the notes in theirs, see [constant HANDS], the first edition in an old book's face. A note found
## and not yet read carries a pencilled mark in the top corner. No number anywhere: a player never
## learns how many there are.

## The leaf, the folder's own paper, and its pencil.
const SIZE := Vector2(440.0, 580.0)
const LEAF := Color(0.95, 0.94, 0.9)
const LEAF_EDGE := Color(0.8, 0.78, 0.72)
const PENCIL := Color(0.32, 0.32, 0.35)
const MARGIN := 26.0
const TITLE_SIZE := 30
## How far apart two posts side by side on the organization chart are.
const CHART_GAP := 14.0
## Where the note's paper sits on the leaf: under the title, in the middle of what is left.
const TITLE_ROOM := 70.0
## The faces: the House's typewriter, Kit's hand, the first edition's old face.
const TYPED: Font = preload("res://assets/fonts/CourierPrime-Regular.ttf")
const HAND: Font = preload("res://assets/fonts/Caveat-Variable.ttf")
const OLD: Font = preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
## The other hands among the notes, STORY.md 7.3: the forklift driver's, notes 3 and 7, and the
## napkin's and the envelope's, 8 and 14; and the marker on the folder's front.
const DRIVER_HAND: Font = preload("res://assets/fonts/Kalam-Regular.ttf")
const STRANGER_HAND: Font = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const MARKER: Font = preload("res://assets/fonts/PermanentMarker-Regular.ttf")
## Each hand by the name a note gives it, Kit's when it gives none: its face, how much bigger it is
## set than a voice asks so the hands read at one size, and how close its lines run.
const HANDS := {
	&"kit": [HAND, 1.5, 0.92],
	&"driver": [DRIVER_HAND, 1.15, 0.84],
	&"stranger": [STRANGER_HAND, 1.35, 0.9],
}
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
	&"strip": [Vector2(400.0, 150.0), Color(0.94, 0.91, 0.82), 13, 18.0],
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
## What is drawn: [code]full[/code] the folder's page, leaf, title, note and clip;
## [code]paper[/code] the note alone, as it is looked at closer, see [NoteView]; [code]back[/code]
## the note turned over, see [constant StoryNotes.BACKS].
var layer := &"full"

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
	if layer == &"back":
		_draw_back()
		return
	var full := layer == &"full"
	if full:
		draw_rect(Rect2(Vector2.ZERO, SIZE), LEAF)
		draw_rect(Rect2(Vector2.ZERO, SIZE), LEAF_EDGE, false, 1.0)
		_scrawl(StoryNotes.title_of(number), Vector2(MARGIN, 46.0), TITLE_SIZE, PENCIL, 0.4)
		if new:
			new_mark(self, Vector2(SIZE.x - MARGIN - 6.0, 36.0))
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
	if full:
		draw_rect(
			Rect2(shadow.position + Vector2(3.0, 4.0), shadow.size), Color(0.0, 0.0, 0.0, 0.12)
		)
	NotePaper.draw_paper(self, kind, rect, spec[1])
	var inside := rect.grow(-float(spec[3]))
	# The strip's words keep to its left: the pen's warning has the right of it, see
	# [method _draw_warning].
	if kind == &"strip":
		inside.size.x *= 0.6
	match kind:
		&"blueprint":
			var margin := str(StoryNotes.NOTES.get(number, {}).get("margin", ""))
			NotePaper.draw_blueprint(self, rect, margin)
			inside = NotePaper.blueprint_block(rect).grow_individual(-8.0, -5.0, -8.0, -5.0)
		&"calendar":
			_draw_calendar(rect)
			return
		&"chart":
			_draw_chart(inside, int(spec[2]))
			if full:
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
		_draw_warning(rect)
		return
	if full:
		NotePaper.draw_clip(self, rect)


## The note's lines down [param inside], each in its voice, wrapped to the paper, the House's
## dotted leaders run out to the paper's width.
func _write_lines(inside: Rect2, type_size: int, kind: StringName) -> void:
	_write(StoryNotes.NOTES.get(number, {}).get("lines", []), inside, type_size, kind)


## [param lines] written down [param inside], each in its voice; where they ended.
func _write(lines: Array, inside: Rect2, type_size: int, kind: StringName) -> float:
	var y := inside.position.y
	for line: Array in lines:
		var voice: StringName = line[0]
		var text := StoryFill.fill(str(line[1]), profile) if profile != null else str(line[1])
		var spec: Array = VOICES.get(voice, VOICES[&"print"])
		var font: Font = spec[0] if spec[0] != null else Type.display_font()
		var font_size := maxi(roundi(type_size * float(spec[2])), 7)
		if font == HAND:
			var hand: Array = HANDS[hand_of(number)]
			font = hand[0]
			font_size = roundi(font_size * float(hand[1]))
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
		var written := _is_hand(font)
		if leader.size() == 2:
			y = leader_line(leader[0], leader[1], font, font_size, ink, x, y, width)
		else:
			var jitter: float = spec[3]
			y = _wrap(text, font, font_size, ink, x, y, width, jitter, voice == &"hard")
			if voice == &"hurried":
				_through(text.get_slice(" ", 0), font, font_size, Vector2(x, top))
				_underline(text.get_slice(" ", 0), font, font_size, Vector2(x, top))
		if line.size() > 2 and bool(line[2]):
			_strike(Rect2(x - 4.0, top, width + 8.0, y - top))
		y += font_size * (0.55 if font == TYPED else (0.2 if written else 0.35))
	return y


## Whose hand note [param numbered] is in: Kit's, unless it says otherwise, STORY.md 7.3.
static func hand_of(numbered: int) -> StringName:
	return StringName(StoryNotes.NOTES.get(numbered, {}).get("hand", &"kit"))


static func _is_hand(font: Font) -> bool:
	for hand: Array in HANDS.values():
		if hand[0] == font:
			return true
	return false


## How close [param font]'s lines run: a hand's own, see [constant HANDS], and a printed face's as
## it is.
static func _tight(font: Font) -> float:
	for hand: Array in HANDS.values():
		if hand[0] == font:
			return float(hand[2])
	return 1.0


## The note turned over, STORY.md 7.3: its paper the other way round, and whatever the back of it
## has on it, see [constant StoryNotes.BACKS]. What shows through from the front is laid over it by
## whatever shows it, see [NoteView].
func _draw_back() -> void:
	var rect := paper_rect()
	var kind := paper()
	var spec: Array = PAPERS.get(kind, PAPERS[&"sheet"])
	var back := StoryNotes.back_of(number)
	var color: Color = back.get("color", spec[1])
	var shown_as := StringName(back.get("paper", kind))
	# Turned over: the paper's outline the other way round.
	draw_set_transform(Vector2(rect.position.x * 2.0 + rect.size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	NotePaper.draw_paper(self, shown_as, rect, color, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var inside := rect.grow(-float(spec[3]))
	if back.get("band", false):
		var band := Rect2(rect.position + Vector2(0.0, 14.0), Vector2(rect.size.x, 54.0))
		draw_rect(band, Color(0.78, 0.2, 0.24, 0.16))
		inside.position.y = band.position.y + 10.0
	if back.get("window", false):
		var window := Rect2(
			rect.position + rect.size * Vector2(0.08, 0.52), rect.size * Vector2(0.5, 0.3)
		)
		draw_rect(window, Color(1.0, 1.0, 1.0, 0.3))
		draw_rect(window, Color(0.0, 0.0, 0.0, 0.18), false, 1.0)
	if back.get("seal", false):
		var middle := rect.get_center()
		for ring: float in [34.0, 26.0, 12.0]:
			draw_arc(middle, ring, 0.0, TAU, 48, Palette.CHIP_GOLD, 2.0, true)
	if StringName(back.get("sketch", &"")) == &"junction":
		_draw_junction(rect)
		inside.position.y = rect.position.y + rect.size.y * 0.7
	var lines: Array = back.get("lines", [])
	# Under the words that show through, where there are some, or as far down as the back says.
	if back.get("through", false):
		inside.position.y = rect.position.y + rect.size.y * 0.66
	if back.has("at"):
		inside.position.y = rect.position.y + rect.size.y * float(back["at"])
	if not lines.is_empty():
		var top := inside.position.y
		var bottom := _write(lines, inside, int(spec[2]), &"back")
		if back.get("box", false):
			draw_rect(
				Rect2(inside.position.x - 8.0, top - 6.0, inside.size.x + 16.0, bottom - top + 6.0),
				STAMP_INK,
				false,
				2.0
			)
	var stamp := str(back.get("stamp", ""))
	if not stamp.is_empty():
		NotePaper.draw_stamp(self, stamp, rect.position + rect.size * Vector2(0.7, 0.78), -0.2)


## The Junction as Kit drew it from above on the back of table one's page, STORY.md 7.3: the ring
## of it, the hub, the four notches, and a dimension across it, in pencil.
func _draw_junction(rect: Rect2) -> void:
	var middle := rect.position + rect.size * Vector2(0.5, 0.32)
	var outer := rect.size.y * 0.22
	draw_arc(middle, outer, 0.0, TAU, 48, PENCIL, 1.4, true)
	draw_arc(middle, outer * 0.62, 0.0, TAU, 40, PENCIL, 1.2, true)
	draw_arc(middle, outer * 0.18, 0.0, TAU, 20, PENCIL, 1.2, true)
	for i: int in 4:
		var a := TAU * float(i) / 4.0 + PI * 0.25
		draw_line(
			middle + Vector2.from_angle(a) * outer * 0.62,
			middle + Vector2.from_angle(a) * outer,
			PENCIL,
			1.2,
			true
		)
	var y := middle.y + outer + 14.0
	draw_line(Vector2(middle.x - outer, y), Vector2(middle.x + outer, y), PENCIL, 1.0, true)
	for end: float in [-1.0, 1.0]:
		var x := middle.x + outer * end
		draw_line(Vector2(x, y - 5.0), Vector2(x, y + 5.0), PENCIL, 1.0, true)
	_scrawl("40 cm", Vector2(middle.x - 18.0, y + 22.0), 20, PENCIL, 0.4)


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
	var line_height := font.get_height(font_size) * _tight(font)
	for row: String in _rows(text, font, font_size, width):
		var baseline := y + font.get_ascent(font_size)
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
	var baseline := at.y + font.get_ascent(font_size)
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


## The first word underlined three times in pen, hard, each stroke a little longer and steeper than
## the one before, STORY.md 7.3.
func _underline(word: String, font: Font, font_size: int, at: Vector2) -> void:
	var baseline := at.y + font.get_ascent(font_size)
	var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	for i: int in 3:
		var y := baseline + 5.0 + float(i) * 4.0
		var stroke := PackedVector2Array()
		for j: int in 7:
			var t := float(j) / 6.0
			stroke.append(
				Vector2(
					at.x - 3.0 + t * (wide + 6.0 + float(i) * 6.0),
					y + _rng.randf_range(-0.8, 0.8) - t * float(i) * 1.5
				)
			)
		draw_polyline(stroke, PEN_INK, 2.2, true)


## Kit's last strip gone over in pen, STORY.md 7.3: a warning triangle drawn twice round, two big
## exclamation marks beside it, and a scribble under them where the pen would not stop.
func _draw_warning(rect: Rect2) -> void:
	var middle := Vector2(rect.end.x - 96.0, rect.position.y + rect.size.y * 0.4)
	var size := 36.0
	for round: int in 2:
		var corners := PackedVector2Array()
		for k: int in 4:
			var a := -PI * 0.5 + TAU * float(k % 3) / 3.0 + 0.08
			corners.append(
				(
					middle
					+ Vector2.from_angle(a) * (size + float(round) * 3.0)
					+ Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-2.0, 2.0))
				)
			)
		draw_polyline(corners, PEN_INK, 3.0 if round == 0 else 1.8, true)
	draw_char(HAND, middle + Vector2(-6.0, 15.0), "!", 42, PEN_INK)
	for k: int in 2:
		var at := Vector2(rect.end.x - 56.0 + float(k) * 20.0, middle.y + 26.0)
		for over: int in 2:
			draw_char(HAND, at + Vector2(float(over) * 1.0, float(over) * 0.6), "!", 72, PEN_INK)
	# Round and round, bigger and smaller, faster at the end.
	var coil := PackedVector2Array()
	var from := Vector2(rect.end.x - 150.0, rect.end.y - 24.0)
	for k: int in 90:
		var t := float(k) / 89.0
		var turn := t * 34.0 + t * t * 10.0
		var radius := 7.0 + sin(t * 11.0) * 3.0 + _rng.randf_range(-1.0, 1.0)
		coil.append(
			from + Vector2(t * 132.0 + cos(turn) * radius, sin(turn) * radius * 0.8 - t * 6.0)
		)
	draw_polyline(coil, PEN_INK, 1.5, true)


## A line struck through by hand, in ink, not quite straight.
func _strike(over: Rect2) -> void:
	var middle := over.position.y + over.size.y * 0.45
	var points := PackedVector2Array()
	for i: int in 9:
		var t := float(i) / 8.0
		points.append(Vector2(over.position.x + over.size.x * t, middle + sin(t * 9.0) * 1.2))
	draw_polyline(points, PEN_INK, 2.0, true)


## The pencilled mark of a note not yet read, STORY.md 7.2: an exclamation mark in a ring, drawn on
## [param canvas] round [param middle], [param scale] times its size on a page.
static func new_mark(canvas: CanvasItem, middle: Vector2, scale := 1.0) -> void:
	canvas.draw_arc(middle, 15.0 * scale, 0.3, TAU + 0.1, 24, PENCIL, 1.6 * scale, true)
	canvas.draw_char(HAND, middle + Vector2(-3.0, 10.0) * scale, "!", roundi(30.0 * scale), PENCIL)


## The organization chart, a copy of a copy, STORY.md 7.3: a box round each post, joined by lines,
## a vacant post's box dashed and posts in one line side by side under a bar; and at the foot, on
## its own, the empty box of the post nobody holds.
func _draw_chart(inside: Rect2, type_size: int) -> void:
	var lines: Array = StoryNotes.NOTES[number]["lines"]
	var ink := Color(0.22, 0.22, 0.24)
	var tall := TYPED.get_height(type_size) + 8.0
	var y := inside.position.y + 2.0
	var above := Rect2()
	for i: int in lines.size() - 1:
		var posts := str(lines[i][1]).split(" · ")
		var boxes: Array[Rect2] = []
		var total := CHART_GAP * float(posts.size() - 1)
		for post: String in posts:
			var wide := TYPED.get_string_size(post, HORIZONTAL_ALIGNMENT_LEFT, -1, type_size).x
			boxes.append(Rect2(0.0, y, wide + 16.0, tall))
			total += wide + 16.0
		for j: int in boxes.size():
			boxes[j].position.x = (
				inside.get_center().x
				- total * 0.5
				+ _widths_before(boxes, j)
				+ CHART_GAP * float(j)
			)
		_chart_lines(above, boxes, ink)
		for j: int in boxes.size():
			_post(boxes[j], posts[j], type_size, ink)
		above = boxes[0] if boxes.size() == 1 else Rect2()
		y += tall + 18.0
	# On its own at the foot, joined to nothing: an empty box, dashed, its post written small in
	# its corner, and under it what the chart says of it.
	var last := str(lines[lines.size() - 1][1])
	var leader := _leader_of(last)
	var post := leader[0] if leader.size() == 2 else last
	var foot := Rect2(
		inside.get_center().x - inside.size.x * 0.3, y + 4.0, inside.size.x * 0.6, 40.0
	)
	_dashed_box(foot, ink)
	var small := type_size - 2
	draw_string(
		TYPED,
		foot.position + Vector2(6.0, TYPED.get_ascent(small) + 4.0),
		post,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		small,
		ink
	)
	if leader.size() == 2:
		var said := leader[1]
		var wide := TYPED.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, type_size).x
		draw_string(
			TYPED,
			Vector2(
				inside.get_center().x - wide * 0.5, foot.end.y + 6.0 + TYPED.get_ascent(type_size)
			),
			said,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			type_size,
			ink
		)


static func _widths_before(boxes: Array[Rect2], index: int) -> float:
	var wide := 0.0
	for j: int in index:
		wide += boxes[j].size.x
	return wide


## The lines down from [param above] to [param boxes]: straight to one, or to a bar over several and
## down from it to each. Nothing for a row with nothing above it.
func _chart_lines(above: Rect2, boxes: Array[Rect2], ink: Color) -> void:
	if above.size == Vector2.ZERO or boxes.is_empty():
		return
	var from := Vector2(above.get_center().x, above.end.y)
	var to := boxes[0].position.y
	if boxes.size() == 1:
		draw_line(from, Vector2(from.x, to), ink, 1.0)
		return
	var bar := to - 9.0
	draw_line(from, Vector2(from.x, bar), ink, 1.0)
	var first := boxes[0].get_center().x
	var last := boxes[boxes.size() - 1].get_center().x
	draw_line(Vector2(first, bar), Vector2(last, bar), ink, 1.0)
	for box: Rect2 in boxes:
		draw_line(Vector2(box.get_center().x, bar), Vector2(box.get_center().x, to), ink, 1.0)


## One post's box with its name in it: dashed for a post that is vacant.
func _post(box: Rect2, text: String, type_size: int, ink: Color) -> void:
	if text.contains("(vacant)"):
		_dashed_box(box, ink)
	else:
		draw_rect(box, ink, false, 1.2)
	var wide := TYPED.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, type_size).x
	draw_string(
		TYPED,
		Vector2(
			box.get_center().x - wide * 0.5, box.position.y + 4.0 + TYPED.get_ascent(type_size)
		),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		type_size,
		ink
	)


func _dashed_box(box: Rect2, ink: Color) -> void:
	var corners := [
		box.position,
		Vector2(box.end.x, box.position.y),
		box.end,
		Vector2(box.position.x, box.end.y)
	]
	for i: int in 4:
		draw_dashed_line(corners[i], corners[(i + 1) % 4], ink, 1.2, 5.0)


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
	var rows := _rows(words, HAND, 20, grid.end.x - from.x - 4.0)
	if rows.size() > 2:
		from.x = grid.position.x + 6.0
		rows = _rows(words, HAND, 20, grid.size.x - 12.0)
	var y := from.y + 14.0
	for row: String in rows:
		_scrawl(row, Vector2(from.x, y), 20, PENCIL, 0.5)
		y += 19.0
	NotePaper.draw_clip(self, rect)
