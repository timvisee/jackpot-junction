class_name SchoolTheory
extends Control
## The driving school's theory, GAME.md 9.4a: the Highway Code of the Junction, a book in a
## leather cover, which reads itself. It comes up shut and opens, the front cover lifting off and
## the right half swinging out from the spine, at its title page, the game's mark and name over
## the book's, and stands there a moment; then its pages turn, a leaf
## at a time lifting off the right page and laid down on the left, the first after a couple of
## seconds anybody could read them in and each next one sooner, until the pages riffle past and
## the page numbers in the corners are racing to the 212th; then they slow, and the last leaf
## comes over onto the end of the book, which stands a moment. Ten seconds of
## that and the book folds shut, the right half swinging over onto the left and the front cover
## coming down on it with a thud and a puff of dust, and the one question, "Got that?", comes up
## beside the shut book where the right page was, which either answer gets past: the theory is a
## gag with a few true things in it, and the test is the test.

signal finished

const CAPTION := "Driving theory  ·  step 1 of 3"
const COVER_TITLE := "THE HIGHWAY\nCODE OF THE\nJUNCTION"
const HEADS: Array[String] = [
	"DEPT. OF KARTS  ·  212TH EDITION", "THE HIGHWAY CODE OF THE JUNCTION"
]
const PAGES := 212
## The opening: the shut book standing a moment, the front cover lifting off, and the right half
## swinging out from the spine, the way the shutting has it the other way round.
const OPEN_WAIT := 0.35
const COVER_UP := 0.3
const SWING_OUT := 0.34
const OPEN_FOR := OPEN_WAIT + COVER_UP + SWING_OUT
## How long after it comes up the open book starts reading, the title page having stood a while,
## how long it reads, and how fast the page numbers race to the last page, a growth a second.
const HOLD := OPEN_FOR + 1.6
const READ_FOR := HOLD + 10.0
const RAMP := 0.62
## The pages turning: the first after this long, each next one sooner by a factor, never sooner
## than the fastest a leaf can riffle past; each turn takes most of the time to the next, never
## longer than a slow one; and the camera the leaf is seen from stands this many pages off.
const TURN_FIRST := 2.0
const TURN_RAMP := 0.7
const TURN_FASTEST := 0.06
const TURN_SLOWEST := 0.55
const TURN_SHARE := 0.85
const TURN_DEPTH := 7.0
const TURN_SHADER := preload("res://scenes/tutorial/school/page_turn.gdshader")
## The end of the book: how long its last spread stands before the book shuts, and how long
## before the last leaf the riffle starts slowing, each turn later by the factor it was sooner.
const END_HOLD := 1.4
const SLOW_FOR := 0.8
## When the last leaf turns, onto the end, counted from when the reading starts.
const LAST_TURN := READ_FOR - HOLD - END_HOLD - TURN_SLOWEST
## Room over and under the book for the leaf to grow into as it comes up toward the camera.
const LIFT_ROOM := 72.0
## The page turning's sound: soft, softer still as the pages riffle, a touch higher as they race,
## and never closer together than this, so the riffle is not a rattle.
const PAGE_DB := -19.0
const RIFFLE_DB := -26.0
const RIFFLE_PITCH := 0.16
const PAGE_PITCHES := 0.07
const SOUND_GAP := 0.1
## Which of the pages is which: the spread's two, and the leaf's two faces.
const LEFT := 0
const RIGHT := 1
const FRONT := 2
const BACK := 3
## The shutting: a breath before it, the right half swinging over, the cover coming down, the
## closed book standing a while, and the question fading in beside it.
const BREATH := 0.25
const SWING := 0.34
const COVER_DOWN := 0.26
const SHUT_FOR := 2.6
const FADE := 0.25
## The pages: their size, the running head over the text and the page number under it, the
## margin round the text, the gutter between the pages, and how far the cover shows round them.
const PAGE := Vector2(400.0, 470.0)
const HEAD := 36.0
const FOOT := 30.0
const MARGIN := 24.0
const GUTTER := 22.0
const COVER := 18.0
const LEAVES := 4
const PAPER := Color(0.95, 0.92, 0.84)
const PAPER_EDGE := Color(0.8, 0.75, 0.64)
const LEAF := Color(0.88, 0.84, 0.74)
const COVER_INK := Color(0.32, 0.17, 0.11)
const COVER_LIGHT := Color(0.42, 0.24, 0.15)
const SPINE_INK := Color(0.22, 0.11, 0.07)
const TOOLING := Color(0.85, 0.7, 0.35, 0.7)
const GILT := Color(0.9, 0.75, 0.4)
const INK := SchoolFigure.BOOK_INK
const FAINT_INK := Color(0.42, 0.4, 0.38)
## The dust the shutting book throws up: how many motes, how far and how long.
const MOTES := 36
const DUST := Color(0.82, 0.76, 0.62)
const DUST_FOR := 0.9
const DUST_SPEED := 160.0
## The text is laid out for pages with its numbers as wide as the second time round has them, so
## a page holds the same however far on its numbers are, and with a little to spare.
const MEASURE_LAP := 2
const PAGE_SPARE := 6.0
## The dust's seed, so the book shuts the same every time.
const SEED := 212
const QUESTION := "Got that?"
const ANSWERS: Array[String] = ["Absolutely", "Not a word"]

var elapsed := 0.0
## The page the left of the spread is on, 1 to 211; the right is the next.
var page_shown := 1
## How many leaves have been turned.
var turns := 0
## The buttons of the question, once the book is shut.
var answers: Array[Button] = []

var _book: Control
## The two halves of the open book, each its half of the cover with its page on it, and the
## front cover that comes down over the left half as the book shuts.
var _halves: Array[Control] = []
var _lid: Control
## The opening, while it is under way.
var _opening: Tween
## Every page's text, the clip it runs under and its page number: the spread's left and right,
## and the leaf's front and back, see [constant LEFT].
var _columns: Array[VBoxContainer] = []
var _clips: Array[Control] = []
var _folios: Array[Label] = []
var _question: VBoxContainer
var _shut := false
## The text cut into pages, each the item it starts with, with where the text ends last, and how
## tall each page's items stand; empty until the text has been laid out.
var _page_first: PackedInt32Array = []
var _page_tall: PackedFloat32Array = []
## The copy of the whole text laid out to be cut into pages, drawing nothing.
var _measure: Control
## The text, see [TheoryText].
var _text: TheoryText
## The spread up, counting from the title's; the leaf turning over, its faces, and the turn
## under way: drawn this frame and turned from the next, landing as the left page and its folio.
var _spread := 0
var _leaf: TextureRect
var _faces: Array[SubViewport] = []
var _leaf_turn: Tween
var _preparing := false
var _landing := false
var _land_folio := 1
## When the next leaf turns, counted from when the reading starts, how long until the one after,
## how long the one under way takes, and how long until a page may make a sound again.
var _next_turn_at := TURN_FIRST
var _interval := TURN_FIRST
var _turn_for := TURN_SLOWEST
var _sound_left := 0.0
## Whether the last leaf has turned, onto the end; the page of the text it showed on its back,
## the last of a lap of it, and that lap, which the end is read in.
var _ended := false
var _final_left := -1
var _final_lap := 0


## How wide one half of the book is: its half of the cover, its page and its half of the gutter.
static func half_width() -> float:
	return COVER + PAGE.x + GUTTER * 0.5


## How tall the book is, cover and all.
static func book_height() -> float:
	return PAGE.y + COVER * 2.0


## How tall the text of a page is, between its running head and its page number.
static func leaf_height() -> float:
	return PAGE.y - HEAD - FOOT


## One half of the leather round the pages, [member side] 0 for the left: the cover with the
## spine along its inner edge, the edges of the leaves showing along the outside of the block,
## and, drawn over the page by [member over_page], the shade the page falls into at the spine.
class HalfCover:
	extends Control

	var side := 0
	var over_page := false

	func _draw() -> void:
		var inner := side == 0
		var width := size.x
		if over_page:
			_draw_gutter(inner, width)
			return
		var leather := StyleBoxFlat.new()
		leather.bg_color = COVER_INK
		leather.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
		leather.shadow_size = 18
		_outer_corners(leather, inner, 10)
		draw_style_box(leather, Rect2(Vector2.ZERO, size))
		var light := StyleBoxFlat.new()
		light.bg_color = COVER_LIGHT
		_outer_corners(light, inner, 8)
		var inset := Rect2(Vector2(3.0, 3.0), size - Vector2(6.0, 6.0))
		if inner:
			inset.size.x += 3.0
		else:
			inset.position.x -= 3.0
			inset.size.x += 3.0
		draw_style_box(light, inset)
		var tooled := StyleBoxFlat.new()
		tooled.draw_center = false
		tooled.set_border_width_all(1)
		tooled.border_color = TOOLING
		_outer_corners(tooled, inner, 6)
		draw_style_box(tooled, Rect2(Vector2(8.0, 8.0), size - Vector2(16.0, 16.0)))
		# The spine, along the inner edge.
		var spine_x := width - GUTTER * 0.5 - 4.0 if inner else 0.0
		draw_rect(Rect2(Vector2(spine_x, 0.0), Vector2(GUTTER * 0.5 + 4.0, size.y)), SPINE_INK)
		# The leaves under the page, stepped out toward the fore-edge and the foot.
		var away := -1.0 if inner else 1.0
		var page_at := Vector2(COVER if inner else GUTTER * 0.5, COVER)
		for i: int in LEAVES:
			var step := float(LEAVES - i) * 1.5
			var rect := Rect2(page_at + Vector2(away * step, step), PAGE)
			draw_rect(rect, LEAF.darkened(0.05 * float(i)))
			draw_rect(rect, PAPER_EDGE, false, 1.0)

	## Rounded on the outer corners alone: the inner edge is the spine, and square.
	static func _outer_corners(style: StyleBoxFlat, inner: bool, radius: int) -> void:
		style.corner_radius_top_left = radius if inner else 0
		style.corner_radius_bottom_left = radius if inner else 0
		style.corner_radius_top_right = 0 if inner else radius
		style.corner_radius_bottom_right = 0 if inner else radius

	func _draw_gutter(inner: bool, width: float) -> void:
		for i: int in 8:
			var reach := 4.0 + float(i) * 3.0
			var shade := Color(0.0, 0.0, 0.0, 0.07 - float(i) * 0.008)
			var x := width - GUTTER * 0.5 - reach if inner else GUTTER * 0.5 + reach - 3.0
			draw_rect(Rect2(Vector2(x, COVER), Vector2(3.0, PAGE.y)), shade)


## The front cover, as it comes down over the left half: leather, tooled, with the book's name
## in gilt and the game's mark under it.
class Lid:
	extends Control

	func _draw() -> void:
		var leather := StyleBoxFlat.new()
		leather.bg_color = COVER_INK
		leather.corner_radius_top_left = 10
		leather.corner_radius_bottom_left = 10
		leather.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
		leather.shadow_size = 22
		draw_style_box(leather, Rect2(Vector2.ZERO, size))
		var light := StyleBoxFlat.new()
		light.bg_color = COVER_LIGHT
		light.corner_radius_top_left = 8
		light.corner_radius_bottom_left = 8
		draw_style_box(light, Rect2(Vector2(3.0, 3.0), size - Vector2(3.0, 6.0)))
		var tooled := StyleBoxFlat.new()
		tooled.draw_center = false
		tooled.set_border_width_all(2)
		tooled.border_color = TOOLING
		tooled.corner_radius_top_left = 6
		tooled.corner_radius_bottom_left = 6
		draw_style_box(tooled, Rect2(Vector2(14.0, 14.0), size - Vector2(28.0, 28.0)))
		draw_rect(
			Rect2(Vector2(size.x - GUTTER * 0.5 - 4.0, 0.0), Vector2(GUTTER * 0.5 + 4.0, size.y)),
			SPINE_INK
		)
		var font := Type.display_font()
		var lines := COVER_TITLE.split("\n")
		var font_size := 30
		var top := size.y * 0.3
		for i: int in lines.size():
			var baseline := top + float(i) * 38.0 + font.get_ascent(font_size)
			draw_string(
				font,
				Vector2(0.0, baseline),
				lines[i],
				HORIZONTAL_ALIGNMENT_CENTER,
				size.x,
				font_size,
				GILT
			)
		draw_line(
			Vector2(size.x * 0.3, size.y * 0.3 - 18.0),
			Vector2(size.x * 0.7, size.y * 0.3 - 18.0),
			GILT,
			1.5
		)
		var foot := top + float(lines.size()) * 38.0 + 10.0
		draw_line(Vector2(size.x * 0.3, foot), Vector2(size.x * 0.7, foot), GILT, 1.5)
		draw_string(
			Type.STRONG,
			Vector2(0.0, foot + 26.0),
			"212TH EDITION",
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			12,
			GILT
		)


## The dust a book throws up as it shuts: motes drifting out from its edges, growing and fading.
class Dust:
	extends Control

	var motes: Array[Dictionary] = []
	var age := 0.0

	func _process(delta: float) -> void:
		age += delta
		if age >= DUST_FOR:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var share := age / DUST_FOR
		for mote: Dictionary in motes:
			var at: Vector2 = (
				mote["from"] + (mote["way"] as Vector2) * (1.0 - pow(1.0 - share, 2.0))
			)
			at.y -= share * share * 20.0
			var radius: float = mote["radius"] * (1.0 + share * 1.6)
			draw_circle(at, radius, Color(DUST, (1.0 - share) * 0.55))


static func add_to(parent: Control) -> SchoolTheory:
	var page := SchoolTheory.new()
	page.name = "Theory"
	parent.add_child(page)
	return page


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var pane := MenuTheme.pane()
	center.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	pane.add_child(column)
	column.add_child(MenuTheme.subtitle(CAPTION, Type.LABEL))
	_book = Control.new()
	_book.name = "Book"
	_book.custom_minimum_size = Vector2(half_width() * 2.0, book_height())
	_book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_book)
	for side: int in 2:
		_book.add_child(_half(side))
	_book.add_child(_leaf_over())
	_lid = Lid.new()
	_lid.name = "Lid"
	_lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lid.size = Vector2(half_width(), book_height())
	_lid.position = Vector2.ZERO
	# Hinged on the spine, which is its right edge: it comes down from there over the left half.
	_lid.pivot_offset = Vector2(half_width(), book_height() * 0.5)
	_lid.scale = Vector2(0.0, 1.0)
	_lid.visible = false
	_book.add_child(_lid)
	# The question, where the right page was once the book is shut, beside it.
	_question = VBoxContainer.new()
	_question.name = "Question"
	_question.add_theme_constant_override("separation", 16)
	_question.alignment = BoxContainer.ALIGNMENT_CENTER
	_question.position = Vector2(half_width() + GUTTER, 0.0)
	_question.size = Vector2(half_width() - GUTTER, book_height())
	_question.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_question.add_child(MenuTheme.title(QUESTION, Type.HEADING))
	for word: String in ANSWERS:
		var button := MenuTheme.button(word)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_answered)
		_question.add_child(button)
		answers.append(button)
	_question.visible = false
	_book.add_child(_question)
	# The title page at once; the page across from it once the text is laid out and cut.
	_text = TheoryText.new()
	_columns[LEFT].add_child(_text.build(_text.items[0], 0))
	_measure_text()
	_paginate()
	_open()


## The book comes up shut, the way it ends, and opens: a moment, the front cover lifts off the
## left half, and the right half swings out from the spine onto the spread.
func _open() -> void:
	_halves[1].scale.x = 0.0
	_lid.visible = true
	_lid.scale.x = 1.0
	_opening = create_tween()
	_opening.tween_interval(OPEN_WAIT)
	_opening.tween_callback(Audio.play_sfx.bind(&"page", PAGE_DB, PAGE_PITCHES, 0.9))
	_opening.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_opening.tween_property(_lid, "scale:x", 0.0, COVER_UP)
	_opening.tween_callback(func() -> void: _lid.visible = false)
	_opening.tween_callback(Audio.play_sfx.bind(&"page", PAGE_DB, PAGE_PITCHES, 1.0))
	_opening.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_opening.tween_property(_halves[1], "scale:x", 1.0, SWING_OUT)
	_opening.tween_callback(func() -> void: _opening = null)


## Whether the book is still opening.
func is_opening() -> bool:
	return _opening != null


## One half of the open book, [param side] 0 for the left: its half of the cover, its page on
## that, and the shade at the spine over the page. Hinged on the spine, so the right half can
## swing over onto the left.
func _half(side: int) -> Control:
	var half := Control.new()
	half.name = "Half%d" % side
	half.mouse_filter = Control.MOUSE_FILTER_IGNORE
	half.size = Vector2(half_width(), book_height())
	half.position = Vector2(half_width() * float(side), 0.0)
	half.pivot_offset = Vector2(half_width() if side == 0 else 0.0, book_height() * 0.5)
	var cover := HalfCover.new()
	cover.side = side
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	half.add_child(cover)
	var page := _page(side)
	page.position = Vector2(COVER if side == 0 else GUTTER * 0.5, COVER)
	half.add_child(page)
	var gutter := HalfCover.new()
	gutter.side = side
	gutter.over_page = true
	gutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gutter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	half.add_child(gutter)
	_halves.append(half)
	return half


## One page of the spread, [param side] 0 for the left: paper, the running head over a rule, the
## book's text running down it under a clip, and the page number in the outer corner.
func _page(side: int) -> Control:
	# A panel rather than a container: a container grows to hold its text, and this one's is
	# taller than the page and runs under it.
	var page := Panel.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.set_corner_radius_all(2)
	paper.set_border_width_all(1)
	paper.border_color = PAPER_EDGE
	page.add_theme_stylebox_override("panel", paper)
	page.custom_minimum_size = PAGE
	page.size = PAGE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outer := HORIZONTAL_ALIGNMENT_LEFT if side == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	var head := Label.new()
	head.text = HEADS[side]
	head.position = Vector2(MARGIN, 10.0)
	head.size = Vector2(PAGE.x - MARGIN * 2.0, 16.0)
	head.horizontal_alignment = outer
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.text(head, Type.SMALL, FAINT_INK)
	page.add_child(head)
	var rule := ColorRect.new()
	rule.color = Color(INK, 0.25)
	rule.position = Vector2(MARGIN, HEAD - 6.0)
	rule.size = Vector2(PAGE.x - MARGIN * 2.0, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(rule)
	var clip := Control.new()
	clip.clip_contents = true
	clip.position = Vector2(0.0, HEAD)
	clip.size = Vector2(PAGE.x, leaf_height())
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(clip)
	_clips.append(clip)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.position = Vector2(MARGIN, 0.0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(column)
	_columns.append(column)
	var folio := Label.new()
	folio.position = Vector2(MARGIN, PAGE.y - FOOT + 6.0)
	folio.size = Vector2(PAGE.x - MARGIN * 2.0, 18.0)
	folio.horizontal_alignment = outer
	folio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(folio, Type.numbers_text_font(), Type.SMALL)
	folio.add_theme_color_override("font_color", FAINT_INK)
	page.add_child(folio)
	_folios.append(folio)
	return page


## The leaf that turns over, seen through [constant TURN_SHADER] over the whole open book: its
## front a right page and its back a left one, each drawn into a picture of its own as a turn
## begins.
func _leaf_over() -> TextureRect:
	_leaf = TextureRect.new()
	_leaf.name = "Leaf"
	_leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leaf.position = Vector2(0.0, -LIFT_ROOM)
	_leaf.size = Vector2(half_width() * 2.0, book_height() + LIFT_ROOM * 2.0)
	_leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_leaf.stretch_mode = TextureRect.STRETCH_SCALE
	_leaf.visible = false
	var turn := ShaderMaterial.new()
	turn.shader = TURN_SHADER
	turn.set_shader_parameter("rect_size", _leaf.size)
	turn.set_shader_parameter("hinge", half_width())
	turn.set_shader_parameter("inner", GUTTER * 0.5)
	turn.set_shader_parameter("page", PAGE)
	turn.set_shader_parameter("top", LIFT_ROOM + COVER)
	turn.set_shader_parameter("depth", TURN_DEPTH * PAGE.x)
	# The front a right page, the back a left one: pages FRONT and BACK.
	for side: int in [1, 0]:
		var face := SubViewport.new()
		face.name = "Front" if side == 1 else "Back"
		face.size = Vector2i(PAGE)
		face.transparent_bg = true
		face.disable_3d = true
		face.gui_disable_input = true
		face.render_target_update_mode = SubViewport.UPDATE_DISABLED
		face.add_child(_page(side))
		_leaf.add_child(face)
		_faces.append(face)
		turn.set_shader_parameter("front" if side == 1 else "back", face.get_texture())
	_leaf.texture = _faces[0].get_texture()
	_leaf.material = turn
	return _leaf


## The whole text laid out once, its numbers as wide as they come round, out of sight under a
## clip with no room in it, to be cut into pages.
func _measure_text() -> void:
	_measure = Control.new()
	_measure.name = "Measure"
	_measure.clip_contents = true
	_measure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item: Dictionary in _text.items:
		column.add_child(_text.build(item, MEASURE_LAP))
	_measure.add_child(column)
	_book.add_child(_measure)


## Cuts the text into pages once it is laid out: a page holds what fits under its running head,
## and the item that does not starts the next one, so no line is cut across two pages; a chapter's
## heading goes over with the item after it rather than be left at the foot of a page.
func _paginate() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var column := _measure.get_child(0) as VBoxContainer
	var room := leaf_height() - PAGE_SPARE
	var first := 0
	_page_first = [0]
	for i: int in column.get_child_count():
		var item := column.get_child(i) as Control
		var top := (column.get_child(first) as Control).position.y
		if i > first and item.position.y + item.size.y - top > room:
			var from := i
			if i - 1 > first and _text.items[i - 1]["kind"] == &"chapter":
				from = i - 1
			_page_tall.append(_bottom(column, from - 1) - top)
			_page_first.append(from)
			first = from
	_page_tall.append(
		(
			_bottom(column, column.get_child_count() - 1)
			- (column.get_child(first) as Control).position.y
		)
	)
	_page_first.append(column.get_child_count())
	_measure.queue_free()
	_measure = null
	_show_page(LEFT, 0, page_shown)
	_show_page(RIGHT, 1, page_shown + 1)


func _bottom(column: VBoxContainer, index: int) -> float:
	var item := column.get_child(index) as Control
	return item.position.y + item.size.y


## How many pages the text was cut into, the title's first.
func _page_count() -> int:
	return maxi(_page_first.size() - 1, 1)


## The page of the text spread [param spread]'s left page, or its right with [param right], is,
## counting on past the end of the text, which comes round again from after the title's.
func _text_page(spread: int, right := false) -> int:
	return spread * 2 + (1 if right else 0)


## Shows text page [param text] on page [param which] of [constant LEFT] and the rest, numbered
## [param folio]: the items of that page, which past the end of the text are those of a page of it
## come round again with their numbers gone on.
func _show_page(which: int, text: int, folio: int) -> void:
	if _page_first.size() < 2:
		return
	var count := _page_count()
	var lap := 0
	var page := text
	if text >= count:
		var past := text - 1
		lap = past / maxi(count - 1, 1)
		page = 1 + past % maxi(count - 1, 1)
	var column := _columns[which]
	for old: Node in column.get_children():
		column.remove_child(old)
		old.queue_free()
	for i: int in range(_page_first[page], _page_first[page + 1]):
		column.add_child(_text.build(_text.items[i], lap))
	_folios[which].text = str(folio)


func _process(delta: float) -> void:
	if _shut:
		return
	elapsed += delta
	_sound_left = maxf(_sound_left - delta, 0.0)
	if not _page_first.is_empty():
		var reading := elapsed - HOLD
		if _preparing:
			_preparing = false
			_start_turn()
		elif not _ended and reading >= minf(_next_turn_at, LAST_TURN):
			_prepare_turn(reading >= LAST_TURN)
	if elapsed >= READ_FOR:
		shut()


## The next leaf drawn: its front the right page as it is, its back the next spread's left page,
## numbered as far on as the race has got, or, the [param last], the last page of the text the
## end comes after, numbered 211; it turns from the next frame, once both are drawn, so it never
## shows the turn before. The riffle slows again over its last moments.
func _prepare_turn(last := false) -> void:
	_land_now()
	_show_page(FRONT, _text_page(_spread, true), page_shown + 1)
	_spread += 1
	if last:
		_ended = true
		_aim_at_the_end()
		_show_page(BACK, _final_left, PAGES - 1)
		_land_folio = PAGES - 1
		_turn_for = TURN_SLOWEST
	else:
		var folio := mini(maxi(page_shown + 2, _page_by_now()), PAGES - 3)
		_show_page(BACK, _text_page(_spread), folio)
		_land_folio = folio
		if elapsed - HOLD >= LAST_TURN - SLOW_FOR:
			_interval = minf(_interval / TURN_RAMP, TURN_SLOWEST)
		else:
			_interval = maxf(_interval * TURN_RAMP, TURN_FASTEST)
		_next_turn_at += _interval
		_turn_for = clampf(_interval * TURN_SHARE, TURN_FASTEST * 0.8, TURN_SLOWEST)
	for face: SubViewport in _faces:
		face.render_target_update_mode = SubViewport.UPDATE_ONCE
	_preparing = true


## Which page of the text the end comes after: the last of the lap of it the right page is in, or
## of the next lap should the right page be that last one already, so the numbers only go up.
func _aim_at_the_end() -> void:
	var count := maxi(_page_count() - 1, 1)
	var right_now := _text_page(_spread - 1, true)
	_final_lap = right_now / count
	_final_left = (_final_lap + 1) * count
	if _final_left <= right_now:
		_final_lap += 1
		_final_left += count


## The book's last page on page [param which], numbered [param folio], see [member
## TheoryText.ending].
func _show_the_end(which: int, folio: int) -> void:
	var column := _columns[which]
	for old: Node in column.get_children():
		column.remove_child(old)
		old.queue_free()
	for item: Dictionary in _text.ending:
		column.add_child(_text.build(item, _final_lap))
	_folios[which].text = str(folio)


## The leaf lifts off the right page, which is the next spread's under it from here on, and comes
## over onto the left one with a soft rustle.
func _start_turn() -> void:
	turns += 1
	page_shown = _land_folio
	if _ended:
		_show_the_end(RIGHT, PAGES)
	else:
		_show_page(RIGHT, _text_page(_spread, true), page_shown + 1)
	_landing = true
	_turn_to(0.0)
	_leaf.visible = true
	_leaf_turn = create_tween()
	_leaf_turn.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_leaf_turn.tween_method(_turn_to, 0.0, PI, _turn_for)
	_leaf_turn.tween_callback(_landed)
	if _sound_left <= 0.0:
		var racing := clampf((TURN_FIRST - _interval) / (TURN_FIRST - TURN_FASTEST), 0.0, 1.0)
		Audio.play_sfx(
			&"page", lerpf(PAGE_DB, RIFFLE_DB, racing), PAGE_PITCHES, 1.0 + RIFFLE_PITCH * racing
		)
		_sound_left = SOUND_GAP


func _turn_to(angle: float) -> void:
	(_leaf.material as ShaderMaterial).set_shader_parameter("angle", angle)


func _landed() -> void:
	_leaf_turn = null
	_land_now()


## The leaf down on the left page, which is now the page it showed: the turn under way, if any,
## finished on the spot.
func _land_now() -> void:
	if not _landing:
		return
	_landing = false
	if _leaf_turn != null:
		_leaf_turn.kill()
		_leaf_turn = null
	_show_page(LEFT, _final_left if _ended else _text_page(_spread), page_shown)
	_leaf.visible = false


## Whether a leaf is turning over.
func is_turning() -> bool:
	return _landing


## The page the race has got to: up the same curve as the pace, from the first to the last page
## but the end's spread as the last leaf turns.
func _page_by_now() -> int:
	var reading := maxf(elapsed - HOLD, 0.0)
	var share := (exp(RAMP * reading) - 1.0) / (exp(RAMP * LAST_TURN) - 1.0)
	return clampi(1 + roundi(share * float(PAGES - 4)), 1, PAGES - 3)


## Whether the last leaf has turned, onto the end of the book.
func is_ended() -> bool:
	return _ended


## The book shuts: a breath, the right half swings over onto the left, the front cover comes
## down on it with a thud and a puff of dust, and after a moment the question comes up in its
## place.
func shut() -> void:
	if _shut:
		return
	_shut = true
	elapsed = READ_FOR
	# Open, should it still have been opening, to shut from there.
	if _opening != null:
		_opening.kill()
		_opening = null
		_lid.visible = false
		_lid.scale.x = 0.0
		_halves[1].scale.x = 1.0
	# The end of the book up, at once should the last leaf not have turned yet.
	_land_now()
	_preparing = false
	if not _ended and not _page_first.is_empty():
		_ended = true
		_spread += 1
		_aim_at_the_end()
		_show_page(LEFT, _final_left, PAGES - 1)
		_show_the_end(RIGHT, PAGES)
	page_shown = PAGES - 1
	_folios[LEFT].text = str(page_shown)
	_folios[RIGHT].text = str(PAGES)
	var fold := create_tween()
	fold.tween_interval(BREATH)
	fold.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fold.tween_property(_halves[1], "scale:x", 0.0, SWING)
	fold.tween_callback(func() -> void: _lid.visible = true)
	fold.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fold.tween_property(_lid, "scale:x", 1.0, COVER_DOWN)
	fold.tween_callback(_slammed)
	fold.tween_interval(SHUT_FOR)
	fold.tween_callback(_ask)


## The cover is down: the thud, the dust off the edges, and the book settling.
func _slammed() -> void:
	Audio.play_sfx(&"book", -4.0, 0.0)
	Audio.play_sfx(&"stamp", -12.0, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var dust := Dust.new()
	dust.name = "Dust"
	dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var closed := Rect2(Vector2.ZERO, Vector2(half_width(), book_height()))
	for i: int in MOTES:
		var mote := {}
		var along := rng.randf()
		var way: Vector2
		# Off the fore-edge, the foot and the head, away from the book.
		match i % 3:
			0:
				mote["from"] = Vector2(
					closed.position.x + rng.randf_range(-2.0, 4.0),
					closed.position.y + along * closed.size.y
				)
				way = Vector2(-1.0, rng.randf_range(-0.3, 0.3))
			1:
				mote["from"] = Vector2(
					closed.position.x + along * closed.size.x,
					closed.end.y + rng.randf_range(-4.0, 2.0)
				)
				way = Vector2(rng.randf_range(-0.3, 0.3), 1.0)
			_:
				mote["from"] = Vector2(
					closed.position.x + along * closed.size.x,
					closed.position.y + rng.randf_range(-2.0, 4.0)
				)
				way = Vector2(rng.randf_range(-0.3, 0.3), -1.0)
		mote["way"] = way.normalized() * DUST_SPEED * rng.randf_range(0.3, 1.0)
		mote["radius"] = rng.randf_range(2.0, 5.0)
		dust.motes.append(mote)
	_book.add_child(dust)
	var settle := create_tween()
	settle.tween_property(_halves[0], "position:x", 3.0, 0.04)
	settle.tween_property(_halves[0], "position:x", -2.0, 0.04)
	settle.tween_property(_halves[0], "position:x", 0.0, 0.04)


## The question comes up beside the shut book.
func _ask() -> void:
	_question.visible = true
	_question.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(_question, "modulate:a", 1.0, FADE)
	answers[0].grab_focus()


## Whether the book is shut and the question up.
func is_asking() -> bool:
	return _shut and _question.visible


## Whether the book's front cover is down: shut, past the swing.
func is_closed() -> bool:
	return _lid.visible and _lid.scale.x >= 0.999


func _answered() -> void:
	finished.emit()
