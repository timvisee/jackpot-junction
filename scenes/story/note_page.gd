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
## A pencil arrow between two of a note's lines: how far out into the margin it bows, how close it
## comes to the paper's edge at most, how long the strokes of its head are, how far they spread
## either side of it, and how steeply it rises into the line it points at.
const ARROW_BOW := 22.0
const ARROW_EDGE := 6.0
const ARROW_HEAD := 10.0
const ARROW_SPREAD := 0.45
const ARROW_RISE := 0.5
## The scrap of paper a new note's pencil mark is drawn on where it marks a button, and its lean.
const TAG := Vector2(32.0, 32.0)
const TAG_TILT := -0.12
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
	&"half_card": [Vector2(250.0, 214.0), Color(0.97, 0.97, 0.95), 11, 18.0],
	&"calendar": [Vector2(340.0, 480.0), Color(0.97, 0.96, 0.92), 12, 18.0],
	&"legal_pad": [Vector2(360.0, 360.0), Color(0.98, 0.95, 0.66), 12, 40.0],
	&"engineering": [Vector2(370.0, 320.0), Color(0.87, 0.93, 0.85), 13, 22.0],
	&"index_card": [Vector2(340.0, 240.0), Color(0.99, 0.98, 0.95), 12, 20.0],
	&"stub": [Vector2(400.0, 132.0), Palette.CHIP_GOLD, 12, 22.0],
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
## What is drawn: [code]full[/code] the folder's page, leaf, title and number, the note laid on it
## askew under what holds it, see [NoteOnPage]; [code]lying[/code] the note as it lies there, with
## its shadow; [code]paper[/code] the note alone, as it is looked at closer, see [NoteView];
## [code]back[/code] the note turned over, see [constant StoryNotes.BACKS].
var layer := &"full"
## Its number in the folder, pencilled at its foot; 0 for none.
var page_number := 0

## Whether the hand-drawn ink is kept off this picture and set aside to be drawn over the note
## instead, crisp at the size it is shown, see [NoteCharts], [NoteView]; false on the folder's page,
## where the ink is drawn in place. The ink set aside goes into [member _ink_strokes].
var hide_ink := false
var _ink_strokes: Array[Dictionary] = []

var _rng := RandomNumberGenerator.new()
## Where each of the note's lines was written, for an arrow drawn between two of them.
var _spans: Array[Rect2] = []


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


func _ready() -> void:
	if layer == &"full" and number != 0:
		NoteOnPage.lay(self)
	elif number < 0:
		FolderBack.lay(self, number, profile)
	_cut_dogear()
	_cut_feed()


## A dog-eared note's folded corner cut away see-through, over the note alone and its back, where it
## is looked at closer, see [NoteCut]: the flap is drawn in [method NoteWear.flap], the corner left
## showing what is behind the note rather than the leaf, STORY.md 7.3.
func _cut_dogear() -> void:
	if (layer != &"paper" and layer != &"back") or number <= 0:
		return
	if paper() not in NoteWear.WORN_PAPERS:
		return
	var g := NoteWear.dogear(paper_rect(), number)
	if not g.is_empty():
		NoteCut.over(self, PackedVector2Array([g[&"corner"], g[&"a"], g[&"b"]]))


## Continuous-form paper's sprocket holes cut see-through, over the note alone and its back, where
## it is looked at closer, see [NoteCut]: [method NoteCharts.feed] draws the rim the punch left, the
## holes themselves left showing what is behind the note, STORY.md 7.3.
func _cut_feed() -> void:
	if (layer != &"paper" and layer != &"back") or number <= 0:
		return
	if StoryNotes.NOTES.get(number, {}).get("feed", false):
		NoteCut.holes(self, NoteCharts.feed_holes(paper_rect()), NoteCharts.FEED_RADIUS)


func paper() -> StringName:
	return StringName(StoryNotes.NOTES.get(number, {}).get("paper", &"sheet"))


## Where the note's paper lies on the leaf.
func paper_rect() -> Rect2:
	if number < 0:
		return FolderBack.paper_rect(number)
	var spec: Array = PAPERS.get(paper(), PAPERS[&"sheet"])
	var wide: Vector2 = spec[0]
	var room := Rect2(0.0, TITLE_ROOM, SIZE.x, SIZE.y - TITLE_ROOM - MARGIN * 0.5)
	return Rect2(room.get_center() - wide * 0.5, wide)


## Where a stamp comes down on [param rect] and how far it is turned, varied by the note so they do
## not all land in the same place at the same angle, STORY.md 7.3; [param salt] sets a note's front
## and back apart. Returns [position, angle].
func _stamp_spot(rect: Rect2, salt: int) -> Array:
	var seeded := RandomNumberGenerator.new()
	seeded.seed = number * 104729 + salt
	var across := seeded.randf_range(0.42, 0.72)
	var down := seeded.randf_range(0.66, 0.86)
	return [rect.position + rect.size * Vector2(across, down), seeded.randf_range(-0.34, 0.12)]


func _draw() -> void:
	_rng.seed = number * 7919
	_ink_strokes.clear()
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
		if page_number > 0:
			var said := str(page_number)
			var wide := HAND.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(
				HAND,
				Vector2((SIZE.x - wide) * 0.5, SIZE.y - 10.0),
				said,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				22,
				Color(PENCIL, 0.8)
			)
	# The back of the folder, after the ending: no note's paper, what the player kept, which lies on
	# the folder's page as a child of its own, as a note does.
	if number < 0:
		if not full:
			FolderBack.draw(self, number, profile)
		return
	# The note itself lies on the page as a child of its own, see [NoteOnPage].
	if full:
		return
	var rect := paper_rect()
	var kind := paper()
	var spec: Array = PAPERS.get(kind, PAPERS[&"sheet"])
	# A shadow under the paper, so it lies on the leaf rather than in it; what was torn off a flyer
	# casts none.
	var shadow := rect
	if kind == &"flyer":
		shadow.size.y *= 0.74
	if layer == &"lying":
		draw_rect(
			Rect2(shadow.position + Vector2(3.0, 4.0), shadow.size), Color(0.0, 0.0, 0.0, 0.12)
		)
	NotePaper.draw_paper(self, kind, rect, spec[1], false, number)
	var inside := rect.grow(-float(spec[3]))
	# The strip's words keep to its left: the pen's warning has the right of it, see
	# [method NoteCharts.warning].
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
		&"stub":
			_draw_stub(rect)
			return
		&"chart":
			_draw_chart(inside, int(spec[2]))
			return
		&"form":
			inside.position.y += 26.0
			inside.size.y -= 26.0
		&"memo":
			inside.position.y += 18.0
		&"letter":
			inside.position.y += 40.0
	inside = NoteCharts.dress(self, rect, inside)
	if inside.size != Vector2.ZERO:
		_write_lines(inside, int(spec[2]), kind)
		NoteCharts.arrow(self)
		var tally := int(StoryNotes.NOTES.get(number, {}).get("tally", 0))
		if tally > 0 and not _spans.is_empty():
			var beside: Rect2 = _spans[_spans.size() - 1]
			NoteCharts.tally(self, beside.position + Vector2(-12.0 - 8.0 * tally, 2.0), tally)
		var stamp := str(StoryNotes.NOTES.get(number, {}).get("stamp", ""))
		if kind == &"form":
			stamp = "RECEIVED"
		if not stamp.is_empty():
			var spot := _stamp_spot(rect, 1)
			NotePaper.draw_stamp(self, stamp, spot[0], spot[1], rect)
		if kind == &"graph" and number == StoryNotes.number_of(&"table_one"):
			NotePaper.draw_sketch(self, rect)
		if kind == &"strip":
			NoteCharts.warning(self, rect)
	NoteCharts.overlay(self, rect, _spans)


## The note's lines down [param inside], each in its voice, wrapped to the paper, the House's
## dotted leaders run out to the paper's width.
func _write_lines(inside: Rect2, type_size: int, kind: StringName) -> void:
	_write(StoryNotes.NOTES.get(number, {}).get("lines", []), inside, type_size, kind)


## [param lines] written down [param inside], each in its voice; where they ended.
func _write(lines: Array, inside: Rect2, type_size: int, kind: StringName) -> float:
	var y := inside.position.y
	_spans.clear()
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
				NoteCharts.underline(self, text.get_slice(" ", 0), font, font_size, Vector2(x, top))
		if line.size() > 2 and bool(line[2]):
			NoteCharts.strike(self, Rect2(x - 4.0, top, width + 8.0, y - top))
		_spans.append(Rect2(x, top, width, y - top))
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
	if number < 0:
		FolderBack.draw_back(self, number)
		return
	var rect := paper_rect()
	var kind := paper()
	var spec: Array = PAPERS.get(kind, PAPERS[&"sheet"])
	var back := StoryNotes.back_of(number)
	var color: Color = back.get("color", spec[1])
	var shown_as := StringName(back.get("paper", kind))
	# Turned over: the paper's outline the other way round.
	draw_set_transform(Vector2(rect.position.x * 2.0 + rect.size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	NotePaper.draw_paper(self, shown_as, rect, color, true, number)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The dog-eared corner folds through to the back too, its flap in the back's own paper; the cut
	# itself is laid on in [method _cut_dogear], see [NoteCut].
	if kind in NoteWear.WORN_PAPERS:
		NoteWear.flap(self, rect, number, color)
	# Continuous-form paper is punched through, so its sprocket track shows on the back as well; the
	# holes are cut in [method _cut_feed], this lays down the rim round them, see [NoteCharts.feed].
	if back.get("feed", StoryNotes.NOTES.get(number, {}).get("feed", false)):
		NoteCharts.feed(self, rect)
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
			NoteCharts.arc(self, middle, ring, Palette.CHIP_GOLD, 2.0)
	if StringName(back.get("sketch", &"")) == &"junction":
		_draw_junction(rect)
		inside.position.y = rect.position.y + rect.size.y * 0.7
	var lines: Array = back.get("lines", [])
	if int(back.get("tally", 0)) > 0:
		var count := int(back["tally"])
		var over := inside.position.y
		if back.has("at"):
			over = rect.position.y + rect.size.y * float(back["at"])
		NoteCharts.tally(self, Vector2(inside.position.x + 4.0, over - 30.0), count)
	# Turned, where the back says, about the middle of where its lines start.
	var tilt := float(back.get("tilt", 0.0))
	# Under the words that show through, where there are some, or as far down as the back says.
	if back.get("through", false):
		inside.position.y = rect.position.y + rect.size.y * 0.66
	if back.has("at"):
		inside.position.y = rect.position.y + rect.size.y * float(back["at"])
	if not lines.is_empty():
		var top := inside.position.y
		if tilt != 0.0:
			var turn := Transform2D(tilt, Vector2.ZERO)
			var pivot := inside.position + Vector2(inside.size.x * 0.5, 0.0)
			draw_set_transform_matrix(Transform2D(tilt, pivot - turn.basis_xform(pivot)))
		var bottom := _write(lines, inside, int(spec[2]), &"back")
		draw_set_transform_matrix(Transform2D.IDENTITY)
		if back.get("box", false):
			draw_rect(
				Rect2(inside.position.x - 8.0, top - 6.0, inside.size.x + 16.0, bottom - top + 6.0),
				STAMP_INK,
				false,
				2.0
			)
	var stamp := str(back.get("stamp", ""))
	if not stamp.is_empty():
		var spot := _stamp_spot(rect, 2)
		NotePaper.draw_stamp(self, stamp, spot[0], spot[1], rect)


## The stub's face as the invitation printed it, STORY.md 6.1a and 7.3: ADMIT ONE DRIVER over the
## line the school's free lesson is in, the player's own number to the right under them, and the
## asterisk's small print along its foot, in the stub's dark ink on its matt gold.
func _draw_stub(rect: Rect2) -> void:
	var ink := OpeningCard.STUB_INK
	var left := rect.position.x + 22.0
	var top := rect.position.y + 18.0
	var mark := Type.mark_font()
	draw_string(
		mark, Vector2(left, top + mark.get_ascent(30)), StoryLines.OPENING_ADMIT, 0, -1, 30, ink
	)
	draw_string(
		Type.TEXT, Vector2(left, top + 50.0), StoryLines.OPENING_NO_EXPERIENCE, 0, -1, 12, ink
	)
	var number_said := (
		"%s %s" % [StoryLines.OPENING_NUMBER, profile.story.invitation if profile != null else ""]
	)
	var wide := TYPED.get_string_size(number_said, 0, -1, 13).x
	draw_string(TYPED, Vector2(rect.end.x - 22.0 - wide, top + 74.0), number_said, 0, -1, 13, ink)
	draw_string(
		Type.TEXT,
		Vector2(left, rect.end.y - 22.0),
		StoryLines.OPENING_SMALL_PRINT,
		0,
		rect.size.x - 44.0,
		8,
		OpeningCard.STUB_FINE
	)


## The Junction as Kit drew it from above on the back of table one's page, STORY.md 7.3: the ring
## of it, the hub, the four notches, and a dimension across it, in pencil.
func _draw_junction(rect: Rect2) -> void:
	var middle := rect.position + rect.size * Vector2(0.5, 0.32)
	var outer := rect.size.y * 0.22
	NoteCharts.arc(self, middle, outer, PENCIL, 1.4)
	NoteCharts.arc(self, middle, outer * 0.62, PENCIL, 1.2)
	NoteCharts.arc(self, middle, outer * 0.18, PENCIL, 1.2)
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


## The first word written so hard the pencil went through the paper, STORY.md 7.3: gone over again.
func _through(word: String, font: Font, font_size: int, at: Vector2) -> void:
	var baseline := at.y + font.get_ascent(font_size)
	_scrawl(word, Vector2(at.x + 0.8, baseline + 0.5), font_size, PENCIL, 0.3, font)


## The pencilled mark of a note not yet read, STORY.md 7.2: an exclamation mark in a ring, drawn on
## [param canvas] round [param middle], [param scale] times its size on a page, in [param ink]: the
## pencil, or something lighter on dark paper.
static func new_mark(canvas: CanvasItem, middle: Vector2, scale := 1.0, ink := PENCIL) -> void:
	canvas.draw_arc(middle, 15.0 * scale, 0.3, TAU + 0.1, 24, ink, 1.6 * scale, true)
	# The ! in two strokes of the pencil, upright in the middle of the ring: a line leaning a touch
	# and the dot under it, drawn rather than set so it sits in the ring at any size.
	canvas.draw_line(
		middle + Vector2(0.7, -8.5) * scale,
		middle + Vector2(0.0, 3.2) * scale,
		ink,
		2.4 * scale,
		true
	)
	canvas.draw_circle(middle + Vector2(-0.2, 7.6) * scale, 1.6 * scale, ink)


## [param button] wearing a new note's pencil mark on a scrap of paper at its top right corner, or
## not, as [param on] says: an arrow that goes to something new, STORY.md 7.2.
static func mark_button(button: Button, on: bool) -> void:
	var tag := button.get_node_or_null("NewMark") as Control
	if tag == null:
		if not on:
			return
		tag = Control.new()
		tag.name = "NewMark"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tag.offset_left = -TAG.x * 0.7
		tag.offset_top = -TAG.y * 0.35
		tag.offset_right = TAG.x * 0.3
		tag.offset_bottom = TAG.y * 0.65
		tag.draw.connect(func() -> void: _draw_tag(tag, TAG * 0.5))
		button.add_child(tag)
	tag.visible = on


## A scrap of the notes' paper with the pencil mark on it, for a mark on something that is not
## paper itself, round [param middle].
static func _draw_tag(canvas: CanvasItem, middle: Vector2) -> void:
	canvas.draw_set_transform(middle, TAG_TILT, Vector2.ONE)
	var scrap := Rect2(-TAG * 0.5, TAG)
	canvas.draw_rect(
		Rect2(scrap.position + Vector2(1.5, 2.0), scrap.size), Color(0.0, 0.0, 0.0, 0.3)
	)
	canvas.draw_rect(scrap, LEAF)
	new_mark(canvas, Vector2.ZERO, TAG.x / 40.0)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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


## One post's box with its name in it: dashed for a post that is vacant, and crossed through in
## red pen where the note says, STORY.md 7.3.
func _post(box: Rect2, text: String, type_size: int, ink: Color) -> void:
	if text.contains("(vacant)"):
		_dashed_box(box, ink)
	else:
		draw_rect(box, ink, false, 1.2)
	var crossed := str(StoryNotes.NOTES.get(number, {}).get("crossed", ""))
	if not crossed.is_empty() and text.contains(crossed):
		var red := Color(0.78, 0.12, 0.12)
		var over := box.grow_individual(10.0, 6.0, 10.0, 6.0)
		NoteCharts.seg(self, over.position, over.end, red, 2.6)
		NoteCharts.seg(
			self,
			Vector2(over.end.x, over.position.y),
			Vector2(over.position.x, over.end.y),
			red,
			2.6
		)
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


## The calendar page, STORY.md 7.3: a page of the House's own wall calendar, the month after the one
## ringed on the Workbench, see [StoryDressing], torn off its pad along the top with the nail hole
## through it; the month's picture, the House's seal on its red over the slogan; the days under it,
## the weekends shaded; blank but for the first, ringed in pencil, where Kit has written across the
## week; and the House's print along its foot.
func _draw_calendar(rect: Rect2) -> void:
	var note: Dictionary = StoryNotes.NOTES[number]
	var red := Color(0.72, 0.24, 0.2)
	var gold := NotePaper.HOUSE_GOLD
	var ink := Color(0.5, 0.48, 0.48)
	# Torn off the pad: the perforation's stubs along the top, and where it hung on its nail.
	for i: int in int(rect.size.x / 10.0):
		draw_circle(Vector2(rect.position.x + 5.0 + float(i) * 10.0, rect.position.y), 2.2, LEAF)
	var nail := Vector2(rect.get_center().x, rect.position.y + 13.0)
	draw_circle(nail, 4.5, Color(0.36, 0.33, 0.3))
	draw_circle(nail, 2.4, LEAF)
	# The month's picture: the House's seal in gold on its red, the slogan under it.
	var picture := Rect2(
		rect.position + Vector2(14.0, 28.0), Vector2(rect.size.x - 28.0, rect.size.y * 0.34)
	)
	draw_rect(picture, red)
	draw_rect(picture.grow(-6.0), gold, false, 1.0)
	var seal := Vector2(picture.get_center().x, picture.position.y + picture.size.y * 0.4)
	for ring: float in [28.0, 21.0, 10.0]:
		NoteCharts.arc(self, seal, ring, gold, 1.8)
	var star := PackedVector2Array()
	for i: int in 10:
		var reach := 7.0 if i % 2 == 0 else 3.0
		star.append(seal + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * reach)
	draw_colored_polygon(star, gold)
	var slogan := str(note.get("slogan", ""))
	var face := Type.display_font()
	var slogan_size := 17
	var slogan_wide := face.get_string_size(slogan, HORIZONTAL_ALIGNMENT_LEFT, -1, slogan_size).x
	draw_string(
		face,
		Vector2(picture.get_center().x - slogan_wide * 0.5, picture.end.y - 22.0),
		slogan,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		slogan_size,
		Color(0.96, 0.92, 0.84)
	)
	# The days, under their initials, the weekends shaded.
	var month: Vector2i = StoryDressing.MONTHS[1]
	var top := picture.end.y + 26.0
	var grid := Rect2(
		Vector2(rect.position.x + 14.0, top), Vector2(rect.size.x - 28.0, rect.end.y - 30.0 - top)
	)
	var cell := Vector2(grid.size.x / 7.0, grid.size.y / 5.0)
	for i: int in 7:
		var initial := "MTWTFSS"[i]
		draw_string(
			TYPED,
			Vector2(grid.position.x + cell.x * (float(i) + 0.5) - 3.0, top - 8.0),
			initial,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			ink
		)
	draw_rect(
		Rect2(grid.position + Vector2(cell.x * 5.0, 0.0), Vector2(cell.x * 2.0, grid.size.y)),
		Color(0.0, 0.0, 0.0, 0.05)
	)
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
	# The first ringed in pencil, and Kit's words from it on, across the week under it.
	var first := month.y
	var first_at := (
		grid.position + Vector2(cell.x * (first % 7) + 7.0, cell.y * floorf(first / 7.0) + 9.0)
	)
	var ring := PackedVector2Array()
	for i: int in 26:
		var a := TAU * float(i) / 24.0 - 0.4
		ring.append(first_at + Vector2(cos(a) * 11.0, sin(a) * 8.0))
	draw_polyline(ring, PENCIL, 1.4, true)
	var from := (
		grid.position + Vector2(cell.x * (first % 7) + 4.0, cell.y * floorf(first / 7.0) + 20.0)
	)
	var words := str(note["lines"][0][1])
	var rows := _rows(words, HAND, 20, grid.end.x - from.x - 4.0)
	if rows.size() > 2:
		from.x = grid.position.x + 6.0
		rows = _rows(words, HAND, 20, grid.size.x - 12.0)
	var y := from.y + 14.0
	for row: String in rows:
		_scrawl(row, Vector2(from.x, y), 20, PENCIL, 0.5)
		y += 19.0
	# The House's print along the foot.
	var footer := str(note.get("footer", ""))
	var footer_wide := TYPED.get_string_size(footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(
		TYPED,
		Vector2(rect.get_center().x - footer_wide * 0.5, rect.end.y - 12.0),
		footer,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		8,
		ink
	)
