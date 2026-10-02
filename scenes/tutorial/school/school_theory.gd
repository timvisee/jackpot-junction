class_name SchoolTheory
extends Control
## The driving school's theory, GAME.md 9.4a: the Highway Code of the Junction, open at a spread
## of two pages, which reads itself. It starts at a pace anybody could follow, with figures among
## the rules, and speeds up on an exponential until the pages are a blur and the counter in the
## corner is racing to the 212th, with a line under the pages for how the pace is going. Nine
## seconds of that and the book slams shut, and the one question is "Got that?", which either
## answer gets past: the theory is a gag with a few true things in it, and the test is the test.

signal finished

const TITLE := "The Highway Code of the Junction"
const EDITION := "212th edition, abridged for karts"
const PAGES := 212
## How long the book is open, and how it reads: a pace in pixels a second that grows by a factor
## every second, up to a ceiling that is a blur on any screen.
const READ_FOR := 9.0
const START_SPEED := 36.0
const RAMP := 0.62
const TOP_SPEED := 16000.0
## The pages, the gutter between them, and the paper.
const PAGE := Vector2(400.0, 440.0)
const MARGIN := 24.0
const GUTTER := 26.0
const PAPER := Color(0.95, 0.92, 0.84)
const PAPER_EDGE := Color(0.8, 0.75, 0.64)
const INK := SchoolFigure.BOOK_INK
const FAINT_INK := Color(0.42, 0.4, 0.38)
## How the pace is described under the pages, from each second on.
const PACE: Array[Array] = [
	[0.0, "comfortable"],
	[2.2, "brisk"],
	[4.2, "alarming"],
	[6.2, "unreasonable"],
	[7.8, "please stop"],
]
## The least time between two page sounds, so the blur is not a rattle.
const FLIP_GAP := 0.12
const FIGURE_SIDE := 104.0
## The figures among the rules, each with its caption.
const FIGURES: Array[Array] = [
	[SchoolFigure.Kind.SPEED, "Fig. 1. The speed limit. Advisory."],
	[SchoolFigure.Kind.JACKPOT, "Fig. 2. A Jackpot, filling. Wait in it."],
	[SchoolFigure.Kind.WARNING, "Fig. 3. Karts crossing. They will not stop."],
	[SchoolFigure.Kind.JUNCTION, "Fig. 4. The Junction. Bank here, and only here."],
	[SchoolFigure.Kind.DRIFT, "Fig. 5. A drift, held. Note the turbo."],
	[SchoolFigure.Kind.PIT, "Fig. 6. A pit. Do not."],
	[SchoolFigure.Kind.FLUSH, "Fig. 7. A Royal Flush: four pads, held at once."],
	[SchoolFigure.Kind.DIE, "Fig. 8. A mult die. Multiplies."],
	[SchoolFigure.Kind.ROUNDABOUT, "Fig. 9. A roundabout. Go round it."],
]
## The rules worth reading, in among the filler: each true, more or less.
const RULES: Array[String] = [
	"§ 1. A kart shall at all times be a kart.",
	"§ 2. Give way to anything bigger, faster, or on fire.",
	"§ 3. Coins collected go to your pot. The pot is yours until it isn't.",
	"§ 4. Only banked points are safe. Nothing else is. Not even this book.",
	"§ 5. A Royal Flush is four pads held at once. It is not a plumbing matter.",
	"§ 6. Mult multiplies. That is all it does, and it does it very well.",
	"§ 7. Drifting is permitted in tight corners and encouraged in wide ones.",
	"§ 8. On meeting a pit, the recommended procedure is: not that.",
	"§ 9. Jokers bend rules in your favor. This rule is not a joker.",
	"§ 10. Nitro refills over time. Patience does not.",
	"§ 11. Shots bounce. Plan accordingly, or don't, and see what happens.",
	"§ 12. When in doubt, the Junction is in the middle.",
	"§ 13. A kart that dies loses part of its pot. The remainder is the kart's own business.",
	"§ 14. Overtaking is permitted on the left, on the right, and over the top where a ramp is.",
	"§ 15. A turret left running is a turret left running.",
	"§ 16. Examiners are always right. Examiners are also bots.",
	"§ 17. Reading this far is itself an endorsement.",
]
## What the filler is made of: a subject, a verb, an object and a tail, drawn by a seeded
## generator so the book reads the same every time it is opened.
const SUBJECTS: Array[String] = [
	"A kart",
	"The driver",
	"Any licensed vehicle",
	"The pot",
	"A learner",
	"The examiner",
	"Every Junction",
	"A parked kart",
	"The holder of a Class K license",
]
const VERBS: Array[String] = [
	"shall",
	"must",
	"may not",
	"is advised to",
	"will under no circumstances",
	"is expected to",
	"may, with care,",
]
const OBJECTS: Array[String] = [
	"yield to the mult",
	"signal before drifting",
	"keep two chips' distance",
	"declare any jokers held",
	"bank before the music stops",
	"proceed at a reasonable speed",
	"stop at every pad",
	"respect the hazard stripes",
	"count their coins",
	"mind the pit",
	"take the turret's shot on a shield",
	"hold all four pads at once",
]
const TAILS: Array[String] = [
	" except on Tuesdays.",
	", see Appendix F.",
	" unless told otherwise.",
	", whichever comes first.",
	". Penalties apply.",
	", as amended.",
	".",
	", within reason.",
	" and will be asked about it later.",
]
const ITEMS := 130
const SEED := 212
const QUESTION := "Got that?"
const ANSWERS: Array[String] = ["Absolutely", "Not a word"]

var elapsed := 0.0
## The buttons of the question, once the book is shut.
var answers: Array[Button] = []

var _book: Control
var _pages: Array[Control] = []
var _columns: Array[VBoxContainer] = []
var _pace: Label
var _counter: Label
var _question: VBoxContainer
var _offset := 0.0
var _shown_page := 1
var _flip_left := 0.0
var _shut := false


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
	column.add_theme_constant_override("separation", 12)
	pane.add_child(column)
	column.add_child(MenuTheme.title(TITLE, Type.TITLE))
	column.add_child(MenuTheme.subtitle(EDITION, Type.LABEL))
	_book = Control.new()
	_book.name = "Book"
	_book.custom_minimum_size = Vector2(PAGE.x * 2.0 + GUTTER, PAGE.y)
	_book.pivot_offset = _book.custom_minimum_size * 0.5
	column.add_child(_book)
	for side: int in 2:
		var page := _page()
		page.position = Vector2((PAGE.x + GUTTER) * float(side), 0.0)
		_book.add_child(page)
	var under := HBoxContainer.new()
	under.custom_minimum_size = Vector2(_book.custom_minimum_size.x, 0.0)
	_pace = MenuTheme.subtitle("", Type.LABEL)
	_pace.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_pace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	under.add_child(_pace)
	_counter = Label.new()
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Type.set_font(_counter, Type.numbers_text_font(), Type.LABEL)
	_counter.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	under.add_child(_counter)
	column.add_child(under)
	_question = VBoxContainer.new()
	_question.name = "Question"
	_question.add_theme_constant_override("separation", 16)
	_question.alignment = BoxContainer.ALIGNMENT_CENTER
	_question.add_child(MenuTheme.title(QUESTION, Type.HEADING))
	for word: String in ANSWERS:
		var button := MenuTheme.button(word)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_answered)
		_question.add_child(button)
		answers.append(button)
	_question.visible = false
	column.add_child(_question)
	_show_pace()


## One page of the spread: paper, with the book's text running down it under a clip.
func _page() -> Control:
	# A panel rather than a container: a container grows to hold its text, and this one's is
	# taller than the page and runs under it.
	var page := Panel.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.set_corner_radius_all(4)
	paper.set_border_width_all(1)
	paper.border_color = PAPER_EDGE
	paper.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	paper.shadow_size = 8
	page.add_theme_stylebox_override("panel", paper)
	page.custom_minimum_size = PAGE
	page.size = PAGE
	page.clip_contents = true
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.position = Vector2(MARGIN, MARGIN)
	# Not laid out by the page: it is taller than the page and moves under it.
	column.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_fill(column)
	page.add_child(column)
	_pages.append(page)
	_columns.append(column)
	return page


## The book's text, the same every time: the rules, the filler between them and the figures
## among them.
func _fill(column: VBoxContainer) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var rule := 0
	var figure := 0
	var section := 1
	for i: int in ITEMS:
		if i % 9 == 4:
			column.add_child(_figure(FIGURES[figure % FIGURES.size()]))
			figure += 1
		elif i % 3 == 0 and rule < RULES.size():
			column.add_child(_paragraph(RULES[rule], true))
			rule += 1
		else:
			section += 1
			column.add_child(_paragraph(_filler(rng, section), false))


func _filler(rng: RandomNumberGenerator, section: int) -> String:
	var subject := SUBJECTS[rng.randi_range(0, SUBJECTS.size() - 1)]
	var verb := VERBS[rng.randi_range(0, VERBS.size() - 1)]
	var object := OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)]
	var tail := TAILS[rng.randi_range(0, TAILS.size() - 1)]
	var line := (
		"§ %d.%d. %s %s %s%s" % [section, rng.randi_range(1, 9), subject, verb, object, tail]
	)
	if rng.randf() < 0.35:
		var again := OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)]
		line += " Where this is not possible, the holder shall %s instead." % again
	return line


func _paragraph(text: String, strong: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(PAGE.x - MARGIN * 2.0, 0.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if strong:
		Type.strong(label, Type.LABEL, INK)
	else:
		Type.text(label, Type.LABEL, INK)
	return label


## A figure with its caption under it, in the middle of the page.
func _figure(entry: Array) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := SchoolFigure.of(entry[0], FIGURE_SIDE, INK)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picture)
	var caption := Label.new()
	caption.text = entry[1]
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(PAGE.x - MARGIN * 2.0, 0.0)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.text(caption, Type.SMALL, FAINT_INK)
	box.add_child(caption)
	return box


func _process(delta: float) -> void:
	if _shut:
		return
	elapsed += delta
	_flip_left = maxf(_flip_left - delta, 0.0)
	var speed := minf(START_SPEED * exp(RAMP * elapsed), TOP_SPEED)
	_offset += speed * delta
	# The text runs down the left page and on down the right one, and comes round again: the
	# book is longer than nine seconds at any pace.
	var length := maxf(_columns[0].size.y + MARGIN, PAGE.y * 2.0 + 1.0)
	for side: int in 2:
		var at := fmod(_offset + PAGE.y * float(side), length)
		_columns[side].position.y = MARGIN - at
	_show_pace()
	if elapsed >= READ_FOR:
		shut()


## The pace under the pages, and the page the counter is on, which runs up the same curve and
## reaches the last page as the book shuts.
func _show_pace() -> void:
	var words: String = PACE[0][1]
	for step: Array in PACE:
		if elapsed >= float(step[0]):
			words = step[1]
	_pace.text = "Reading pace: %s" % words
	var share := (exp(RAMP * elapsed) - 1.0) / (exp(RAMP * READ_FOR) - 1.0)
	var page := clampi(1 + roundi(share * float(PAGES - 1)), 1, PAGES)
	if page != _shown_page:
		_shown_page = page
		if _flip_left <= 0.0:
			Audio.play_sfx(&"page", -14.0, 0.0)
			_flip_left = FLIP_GAP
	_counter.text = "page %d of %d" % [page, PAGES]


## The book slams shut, and the question comes up in its place.
func shut() -> void:
	if _shut:
		return
	_shut = true
	elapsed = READ_FOR
	Audio.play_sfx(&"book", -6.0, 0.0)
	var slam := create_tween()
	slam.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	slam.tween_property(_book, "scale:x", 0.0, 0.22)
	slam.tween_callback(_ask)


func _ask() -> void:
	_book.visible = false
	_pace.visible = false
	_counter.visible = false
	_question.visible = true
	_question.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(_question, "modulate:a", 1.0, 0.25)
	answers[0].grab_focus()


## Whether the book is shut and the question up.
func is_asking() -> bool:
	return _shut and _question.visible


func _answered() -> void:
	finished.emit()
