class_name TheoryText
extends RefCounted
## The text of the driving school's theory book, GAME.md 9.4a, the Highway Code of the Junction:
## the title page, then a code in chapters, each a heading and its sections, a rule worth reading
## in bold with a few clauses of filler under it, and figures falling among the clauses where they
## will, all drawn by a seeded generator so it reads the same every time the book is opened. Its
## numbers only go up, and go on up when the book comes round to the start again, see [method
## words]. [SchoolTheory] lays it out, cuts it into pages and turns them.

const TITLE := "The Highway Code\nof the Junction"
const EDITION := "212th edition, abridged for karts"
const PUBLISHER := "DEPT. OF KARTS  ·  JACKPOT JUNCTION"
const FIGURE_SIDE := 104.0
const MARK_SIDE := 104.0
## The figures among the clauses, each with its caption, numbered as they come, in the order of
## the chapters they go with.
const FIGURES: Array[Array] = [
	[SchoolFigure.Kind.SPEED, "The speed limit. Advisory."],
	[SchoolFigure.Kind.WARNING, "Karts crossing. They will not stop."],
	[SchoolFigure.Kind.JACKPOT, "A Jackpot, filling. Wait in it."],
	[SchoolFigure.Kind.JUNCTION, "The Junction. Bank here, and only here."],
	[SchoolFigure.Kind.FLUSH, "A Royal Flush: four pads, held at once."],
	[SchoolFigure.Kind.DIE, "A mult die. Multiplies."],
	[SchoolFigure.Kind.DRIFT, "A drift, held. Note the turbo."],
	[SchoolFigure.Kind.PIT, "A pit. Do not."],
	[SchoolFigure.Kind.ROUNDABOUT, "A roundabout. Go round it."],
]
## The code's chapters, each its title and the rules worth reading that open its sections, each
## true, more or less: the sections are numbered on through the chapters, and every section has
## clauses of filler under it, numbered after it.
const CHAPTERS: Array[Array] = [
	[
		"The kart",
		[
			"A kart shall at all times be a kart.",
			"Give way to anything bigger, faster, or on fire.",
			"Overtaking is permitted on the left, on the right, and over the top where a ramp is.",
		],
	],
	[
		"Signs and markings",
		[
			"A sign shall be obeyed by any kart able to read it.",
			"Hazard stripes mean hazard. They are not decoration, whatever they look like.",
			"Arrows on the floor point the way. Karts may go the other way at their own risk.",
		],
	],
	[
		"Chips and pots",
		[
			"Chips collected go to your pot. The pot is yours until it isn't.",
			"Only banked points are safe. Nothing else is. Not even this book.",
			"A kart that dies loses part of its pot. The remainder is the kart's own business.",
			"When in doubt, the Junction is in the middle.",
		],
	],
	[
		"Pads and the mult",
		[
			"A Royal Flush is four pads held at once. It is not a plumbing matter.",
			"Mult multiplies. That is all it does, and it does it very well.",
		],
	],
	[
		"Handling",
		[
			"Drifting is permitted in tight corners and encouraged in wide ones.",
			"Nitro refills over time. Patience does not.",
			"On meeting a pit, the recommended procedure is: not that.",
		],
	],
	[
		"Items",
		[
			"An item held is an item not yet used. Use it.",
			"A shield is a hat for the whole kart.",
			"Oil goes on the floor, not on other drivers' feelings.",
		],
	],
	["Jokers", ["Jokers bend rules in your favor. This rule is not a joker."]],
	[
		"Hazards",
		[
			"Shots bounce. Plan accordingly, or don't, and see what happens.",
			"A turret left running is a turret left running.",
		],
	],
	[
		"Bots",
		[
			"Bots drive like bots. Do not take it personally.",
			"A bot that says gg means it, more or less.",
		],
	],
	[
		"Emotes",
		[
			"An emote is a statement. A second emote is an argument.",
			"Emoting while banking is permitted, and encouraged.",
		],
	],
	[
		"Bounties",
		[
			"A crown makes you a target. Wear it with pride, briefly.",
			"The bounty on your head is a compliment.",
		],
	],
	[
		"Overtime",
		[
			"Overtime is the same as time, only more so.",
			"In sudden death, death is sudden.",
		],
	],
	[
		"Examinations",
		[
			"Examiners are always right. Examiners are also bots.",
			"Reading this far is itself an endorsement.",
		],
	],
]
## The back cover: what the publisher says of the book, what its readers say, each with who said
## it, its number for the barcode and its price.
const BLURB := (
	"Everything a kart needs to know, and a fair amount it does not. "
	+ "Revised for the 212th time, and still not finished."
)
const QUOTES: Array[Array] = [
	["\u201cImpossible to put down. It shuts itself.\u201d", "The Examiner"],
	["\u201cI read it cover to cover. Quickly.\u201d", "A learner"],
	["\u201cBank first. Read later.\u201d", "The Junction"],
]
const ISBN := "ISBN 0-212-2120-K"
const PRICE := "212 CHIPS"
## The end of the book, on its last page: a chapter of its own after the one the page across
## from it is in, its one section concluding the code with a clause or two under it, and THE END
## over the printer's note, see [method ending_after].
const CLOSING_TITLE := "Final provisions"
const CLOSING_RULE := "This concludes the Highway Code of the Junction."
const CLOSING_CLAUSES: Array[String] = [
	"The holder, having read every word of it, is now fully informed, and will be asked about it.",
	"Any part of it not read is deemed read.",
]
const THE_END := "The End"
const COLOPHON := (
	"Printed and bound at the Junction. No karts were harmed in the making of this book. "
	+ "Most were merely inconvenienced."
)
## How many clauses a section has under its rule, fewest and most; how many paragraphs at least
## stand between two figures, and the chance of one after any paragraph past that.
const CLAUSES_FEWEST := 3
const CLAUSES_MOST := 7
const FIGURE_GAP := 2
const FIGURE_CHANCE := 0.3
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
	"count their chips",
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
const SEED := 212

## The text, an item at a time: the title page, then chapter headings, rules and their clauses,
## and figures; and how many sections and figures it has, by which the numbers go on when the
## book comes round again.
var items: Array[Dictionary] = []
var sections := 0
var figures := 0


func _init() -> void:
	_compose()


## The book's text, the same every time: the title page first, then the chapters, each its
## heading and its sections, a rule in bold with a few clauses of filler under it, and figures
## falling among the clauses where they will.
func _compose() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	items = [{"kind": &"title"}]
	var since_figure := 0
	# Every item knows the chapter and the section it is in, so the end can be numbered on from
	# whichever of them the book gets to.
	for chapter: int in CHAPTERS.size():
		var number := chapter + 1
		items.append(
			{
				"kind": &"chapter",
				"number": number,
				"chapter": number,
				"section": sections,
				"text": CHAPTERS[chapter][0]
			}
		)
		for rule: String in CHAPTERS[chapter][1]:
			sections += 1
			items.append({"kind": &"rule", "chapter": number, "section": sections, "text": rule})
			since_figure += 1
			for clause: int in rng.randi_range(CLAUSES_FEWEST, CLAUSES_MOST):
				var said := _filler(rng)
				items.append(
					{
						"kind": &"clause",
						"chapter": number,
						"section": sections,
						"clause": clause + 1,
						"text": said
					}
				)
				since_figure += 1
				if since_figure >= FIGURE_GAP and rng.randf() < FIGURE_CHANCE:
					figures += 1
					items.append(
						{
							"kind": &"figure",
							"chapter": number,
							"section": sections,
							"number": figures
						}
					)
					since_figure = 0


## The book's last page, to come right after [param last], the last item on the page across from
## it: a chapter numbered on from the one [param last] is in, a section on from its section, so
## read the same lap as that page, see [method words], its numbers go on from it.
func ending_after(last: Dictionary) -> Array[Dictionary]:
	var chapter := int(last.get("chapter", CHAPTERS.size())) + 1
	var section := int(last.get("section", sections)) + 1
	var ending: Array[Dictionary] = [
		{"kind": &"chapter", "number": chapter, "text": CLOSING_TITLE},
		{"kind": &"rule", "section": section, "text": CLOSING_RULE},
	]
	for clause: int in CLOSING_CLAUSES.size():
		ending.append(
			{
				"kind": &"clause",
				"section": section,
				"clause": clause + 1,
				"text": CLOSING_CLAUSES[clause]
			}
		)
	ending.append({"kind": &"end"})
	return ending


## [param item] of the text as it reads the [param lap]th time the book comes round to it, from
## 0: its numbers on by as many sections, figures and chapters as the text has, each time.
func build(item: Dictionary, lap: int) -> Control:
	match item["kind"]:
		&"title":
			return _title_page()
		&"chapter":
			return _heading(words(item, lap))
		&"rule":
			return _paragraph(words(item, lap), true)
		&"figure":
			var entry: Array = FIGURES[(int(item["number"]) - 1) % FIGURES.size()]
			return _figure(entry[0], words(item, lap))
		&"end":
			return _the_end()
	return _paragraph(words(item, lap), false)


## THE END, in the middle of the page under a rule, and the printer's note under it.
func _the_end() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var air := Control.new()
	air.custom_minimum_size = Vector2(0.0, 18.0)
	box.add_child(air)
	var rule := ColorRect.new()
	rule.color = Color(SchoolTheory.INK, 0.4)
	rule.custom_minimum_size = Vector2(120.0, 1.0)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)
	box.add_child(_line(THE_END.to_upper(), Type.display_font(), Type.HEADING, SchoolTheory.INK))
	var note := _line(COLOPHON, Type.TEXT, Type.SMALL, SchoolTheory.FAINT_INK)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(SchoolTheory.PAGE.x - SchoolTheory.MARGIN * 2.0, 0.0)
	box.add_child(note)
	return box


## What [param item] says, numbered for the [param lap]th time round.
func words(item: Dictionary, lap: int) -> String:
	match item["kind"]:
		&"chapter":
			var number := int(item["number"]) + lap * CHAPTERS.size()
			return "Chapter %s  ·  %s" % [roman(number), item["text"]]
		&"rule":
			return "§ %d. %s" % [int(item["section"]) + lap * sections, item["text"]]
		&"clause":
			var section := int(item["section"]) + lap * sections
			return "§ %d.%d. %s" % [section, item["clause"], item["text"]]
		&"figure":
			var number := int(item["number"]) + lap * figures
			var entry: Array = FIGURES[(int(item["number"]) - 1) % FIGURES.size()]
			return "Fig. %d. %s" % [number, entry[1]]
	return ""


## [param number] in Roman numerals, the way a chapter of a code is numbered.
static func roman(number: int) -> String:
	var values: Array[int] = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var marks: Array[String] = [
		"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"
	]
	var out := ""
	var left := number
	for i: int in values.size():
		while left >= values[i]:
			out += marks[i]
			left -= values[i]
	return out


## A chapter's heading, in the middle of the page with a little air over it and a rule under.
func _heading(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var air := Control.new()
	air.custom_minimum_size = Vector2(0.0, 4.0)
	box.add_child(air)
	var label := _line(text.to_upper(), Type.STRONG, Type.SMALL, SchoolTheory.INK)
	label.custom_minimum_size = Vector2(SchoolTheory.PAGE.x - SchoolTheory.MARGIN * 2.0, 0.0)
	box.add_child(label)
	var rule := ColorRect.new()
	rule.color = Color(SchoolTheory.INK, 0.3)
	rule.custom_minimum_size = Vector2(60.0, 1.0)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)
	return box


## The title page, a page tall, so the text starts at the top of the page across from it: the
## game's mark and name, the book's own, and its edition.
func _title_page() -> Control:
	var page := VBoxContainer.new()
	page.custom_minimum_size = Vector2(
		SchoolTheory.PAGE.x - SchoolTheory.MARGIN * 2.0, SchoolTheory.leaf_height() - 10.0
	)
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_theme_constant_override("separation", 10)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := LogoArt.new()
	mark.plate = false
	mark.custom_minimum_size = Vector2(MARK_SIDE, MARK_SIDE)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(mark)
	page.add_child(_line("Jackpot Junction", Type.display_font(), Type.LARGE, SchoolTheory.INK))
	page.add_child(_line(PUBLISHER, Type.TEXT, Type.SMALL, SchoolTheory.FAINT_INK))
	var rule := ColorRect.new()
	rule.color = Color(SchoolTheory.INK, 0.4)
	rule.custom_minimum_size = Vector2(120.0, 1.0)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(rule)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	page.add_child(gap)
	page.add_child(_line(TITLE, Type.display_font(), Type.HEADING, SchoolTheory.INK))
	page.add_child(_line(EDITION, Type.TEXT, Type.LABEL, SchoolTheory.FAINT_INK))
	return page


## A centered line of the title page.
func _line(text: String, font: Font, font_size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(label, font, font_size)
	label.add_theme_color_override("font_color", ink)
	return label


## A clause of filler, a sentence or two, drawn from [param rng]; its number is its section's.
func _filler(rng: RandomNumberGenerator) -> String:
	var line := _sentence(rng)
	var more := rng.randf()
	if more < 0.3:
		var again := OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)]
		line += " Where this is not possible, the holder shall %s instead." % again
	elif more < 0.5:
		line += " " + _sentence(rng)
	return line


func _sentence(rng: RandomNumberGenerator) -> String:
	var subject := SUBJECTS[rng.randi_range(0, SUBJECTS.size() - 1)]
	var verb := VERBS[rng.randi_range(0, VERBS.size() - 1)]
	var object := OBJECTS[rng.randi_range(0, OBJECTS.size() - 1)]
	var tail := TAILS[rng.randi_range(0, TAILS.size() - 1)]
	return "%s %s %s%s" % [subject, verb, object, tail]


func _paragraph(text: String, strong: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(SchoolTheory.PAGE.x - SchoolTheory.MARGIN * 2.0, 0.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if strong:
		Type.strong(label, Type.LABEL, SchoolTheory.INK)
	else:
		Type.text(label, Type.LABEL, SchoolTheory.INK)
	return label


## A figure of [param kind] with [param caption_text] as its caption under it, in the middle of
## the page.
func _figure(kind: SchoolFigure.Kind, caption_text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := SchoolFigure.of(kind, FIGURE_SIDE, SchoolTheory.INK)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picture)
	var caption := Label.new()
	caption.text = caption_text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(SchoolTheory.PAGE.x - SchoolTheory.MARGIN * 2.0, 0.0)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.text(caption, Type.SMALL, SchoolTheory.FAINT_INK)
	box.add_child(caption)
	return box
