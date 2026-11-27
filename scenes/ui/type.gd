class_name Type
extends RefCounted
## The type the game is set in, GAME.md 8.1a. Three cuts of Barlow and a scale of sizes, so a
## number on the HUD and a heading on a menu look like they came out of the same game.
##
## The rule is weight for role rather than size for importance: anything a player reads at a
## glance mid-corner is set in the display cut, anything they read a sentence of is set in the
## text cut, and the middle weight carries names and labels. A size is picked off the scale
## rather than typed in, because a screen with nine sizes on it reads as nine screens.
##
## Barlow was drawn after the highway signs and plates of California, which is a road in a face;
## the display cut is the condensed one, so a score and a clock take less of the corner. Each cut
## falls back on Inter for what Barlow does not draw, a name in Cyrillic or Greek say, and every
## face the game is set in on its Chinese partner, see [method dress].

const TEXT := preload("res://assets/fonts/Barlow-Medium.ttf")
const STRONG := preload("res://assets/fonts/BarlowSemiCondensed-SemiBold.ttf")
const DISPLAY := preload("res://assets/fonts/BarlowCondensed-ExtraBold.ttf")
## The heaviest cut, for the one line that is a mark rather than a heading: the name on the
## title, GAME.md 8.1a.
const MARK := preload("res://assets/fonts/BarlowCondensed-Black.ttf")
const FALLBACK := preload("res://assets/fonts/Inter-Regular.ttf")
## Where the faces are, where their Chinese partners are, and which partner stands behind which
## face, written with the partners by `make fonts`, tools/partner_fonts.py, GAME.md 10.9.
const FACES := "res://assets/fonts/"
const PARTNERS := "res://assets/fonts/chinese/"
const PARTNERED := "res://assets/fonts/chinese/partners.json"

## The scale. Each step is about a quarter bigger than the one below it, which is far enough
## apart that two of them are never mistaken for the same size.
const HERO := 96
const SCORE := 68
const TITLE := 44
const HEADING := 32
const LARGE := 26
const BODY := 21
const LABEL := 17
const SMALL := 14

## The OpenType tag for tabular figures, packed the way a tag is: four characters in an int,
## big end first, which is "tnum".
const TABULAR := 0x746E756D
## How far apart the letters of a display line are set. Heavy uppercase wants air; text does not.
const DISPLAY_TRACKING := 1.0
## How tall Barlow's capitals and figures stand, as a share of the size it is set at. Its line keeps
## 1.0 of the size over the baseline and 0.2 under it, so capitals sit low in their own box: what
## centers a line of them, see [method MenuTheme.title], works from this.
const CAP_HEIGHT := 0.7

## The three variations, made once and shared: nothing changes one after it is made, and a
## scoreboard that asked for a new one on every row of every frame was making sixteen a frame,
## GAME.md 10.7.
static var _display: FontVariation
static var _numbers: FontVariation
static var _numbers_text: FontVariation
static var _mark: FontVariation
static var _micro: FontVariation
static var _dressed := false
## The faces dressed, held so that none is let go of with its partners behind it and loaded again
## without them.
static var _faces: Array[Font] = []


static func _static_init() -> void:
	dress()


## Hangs behind every face the game is set in what it does not draw itself, GAME.md 10.9: Inter
## behind Barlow's cuts, and behind each face its Chinese partner, cut to the face's size and line,
## and behind a hand's partner the text face's, which holds every character a name may have. Once,
## from the first use of this class and the start of the game, whichever comes first; and without
## the partners on a dedicated server, which draws nothing and leaves them out of its build.
static func dress() -> void:
	if _dressed:
		return
	_dressed = true
	for font: FontFile in [TEXT, STRONG, DISPLAY, MARK]:
		font.fallbacks = [FALLBACK]
	if OS.has_feature("dedicated_server") or not ResourceLoader.exists(PARTNERED):
		return
	var partners: Dictionary = (load(PARTNERED) as JSON).data
	var last := _partner(String(partners["last"]))
	var faces: Dictionary = partners["faces"]
	for face: String in faces:
		var font := load(FACES + face) as FontFile
		var partner := _partner(String(faces[face]))
		var behind: Array[Font] = font.fallbacks.duplicate()
		behind.append(partner)
		if partner != last:
			behind.append(last)
		font.fallbacks = behind
		_faces.append(font)


## The display cut, tracked out a little. A [FontVariation] rather than the file itself, because
## tracking is the one thing that makes a heavy face read as a heading rather than as a shout.
static func display_font() -> FontVariation:
	if _display == null:
		_display = FontVariation.new()
		_display.base_font = DISPLAY
		_display.spacing_glyph = int(DISPLAY_TRACKING)
	return _display


## The display cut with tabular figures: every digit the same width, so a score counting up or a
## clock counting down stays put instead of jittering sideways as the digits change. Anything
## that shows a number that changes is set in this.
static func numbers_font() -> FontVariation:
	if _numbers == null:
		_numbers = FontVariation.new()
		_numbers.base_font = DISPLAY
		_numbers.spacing_glyph = int(DISPLAY_TRACKING)
		_numbers.opentype_features = {TABULAR: 1}
	return _numbers


## The middle weight with the same tabular figures, for the numbers that are not headlines.
static func numbers_text_font() -> FontVariation:
	if _numbers_text == null:
		_numbers_text = FontVariation.new()
		_numbers_text.base_font = STRONG
		_numbers_text.opentype_features = {TABULAR: 1}
	return _numbers_text


## The wordmark's cut, the condensed Black, tracked out a little further than a heading, GAME.md
## 8.1a: the one line that is a mark rather than a heading.
static func mark_font() -> FontVariation:
	if _mark == null:
		_mark = FontVariation.new()
		_mark.base_font = MARK
		_mark.spacing_glyph = 3
	return _mark


## Small capitals spaced well apart, for microprint: a line from a step back and words up close.
static func micro_font() -> FontVariation:
	if _micro == null:
		_micro = FontVariation.new()
		_micro.base_font = STRONG
		_micro.spacing_glyph = 3
	return _micro


## The Chinese partner in [param file], said to draw Han: the engine takes a fallback for a script
## from those it reckons draw it, and reckons so from a font's own tables, which a partner cut down
## to a few hundred characters may not say, so a hand's Chinese would be drawn in the text face's
## partner, at its size, rather than in the hand's own.
static func _partner(file: String) -> FontFile:
	var partner := load(PARTNERS + file) as FontFile
	partner.set_script_support_override("Hani", true)  # NO_TRANSLATE
	return partner


## A number that changes: a score, a clock, a speed.
static func numbers(label: Label, size: int, ink: Color = Color.WHITE) -> Label:
	set_font(label, numbers_font(), size)
	label.add_theme_color_override("font_color", ink)
	return label


## Sets [param node] in one of the three cuts at one of the sizes off the scale. Only on a
## change: an override is a change whether or not the value is new, and every one has the label
## shape its text and the box round it lay itself out again, so the HUD sets its type through
## here every frame and pays for it only when something is different, GAME.md 10.7.
static func set_font(node: Control, font: Font, size: int) -> void:
	if node.get_theme_font(&"font") != font:
		node.add_theme_font_override(&"font", font)
	if node.get_theme_font_size(&"font_size") != size:
		node.add_theme_font_size_override(&"font_size", size)


## Sets [param node]'s text color, only on a change, for the same reason as [method set_font].
static func ink(node: Control, color: Color) -> void:
	if (
		node.has_theme_color_override(&"font_color")
		and node.get_theme_color(&"font_color") == color
	):
		return
	node.add_theme_color_override(&"font_color", color)


## A heading, a score, a timer: something read at a glance.
static func display(label: Label, size: int, ink: Color = Color.WHITE) -> Label:
	set_font(label, display_font(), size)
	label.add_theme_color_override("font_color", ink)
	return label


## A name, a button, a label on a row: read, but read quickly.
static func strong(label: Label, size: int, ink: Color = Color.WHITE) -> Label:
	set_font(label, STRONG, size)
	label.add_theme_color_override("font_color", ink)
	return label


## A sentence.
static func text(label: Label, size: int, ink: Color = Color.WHITE) -> Label:
	set_font(label, TEXT, size)
	label.add_theme_color_override("font_color", ink)
	return label


## The size to set [param text] at in [param font]: [param wanted], or smaller to be no wider than
## [param widest]. A translation drawn where only the English was measured is given the English's
## width, so a longer one shrinks to it rather than running off what it is drawn on, GAME.md 10.9.
static func fitting(text: String, font: Font, wanted: int, widest: float) -> int:
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, wanted).x
	return wanted if wide <= widest else maxi(floori(wanted * widest / wide), 1)


## The size to set [param text] at in [param font] on a line [param across] wide that it wraps on:
## [param wanted] if it fits on one line, else [param smaller], so the two lines a longer name
## takes, as a translation's can, stand no higher than they have to, GAME.md 10.9.
static func wrapping(text: String, font: Font, wanted: int, smaller: int, across: float) -> int:
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, wanted).x
	return wanted if wide <= across else smaller


## [param text] in [param font] at [param size] broken into rows no wider than [param width], at
## the places the text server says a line may break, GAME.md 10.9: after a space in English,
## between any two characters of Chinese, which has none, but never before a closing mark, nor
## after a dash that leads into a word, so a signature, —K., stays whole. Each row takes as many
## of the pieces between those places as fit, the spaces at its ends not counted and a run of
## them taken for one; a piece wider than [param width] keeps a row of its own rather than being
## cut.
static func rows(text: String, font: Font, size: int, width: float) -> PackedStringArray:
	# A run of spaces is one, as it always was on these rows.
	while text.contains("  "):
		text = text.replace("  ", " ")
	# Laid out one piece to a line: a paragraph too narrow for anything breaks at every place it
	# may.
	var pieces := TextParagraph.new()
	pieces.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	pieces.width = 1.0
	pieces.add_string(text, font, size)
	var found := PackedStringArray()
	var row := ""
	var led := ""
	for i: int in pieces.get_line_count():
		var span := pieces.get_line_range(i)
		var piece := led + text.substr(span.x, span.y - span.x)
		led = ""
		if piece.ends_with("—") and i < pieces.get_line_count() - 1:
			led = piece
			continue
		var tried := (row + piece).strip_edges()
		var wide := font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if not row.strip_edges().is_empty() and wide > width:
			found.append(row.strip_edges())
			row = piece
		else:
			row += piece
		if piece.contains("\n"):
			found.append(row.strip_edges())
			row = ""
	if not row.strip_edges().is_empty():
		found.append(row.strip_edges())
	return found
