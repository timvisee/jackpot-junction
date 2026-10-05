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
## falls back on Inter for what Barlow does not draw, a name in Cyrillic or Greek say.

const TEXT := preload("res://assets/fonts/Barlow-Medium.ttf")
const STRONG := preload("res://assets/fonts/BarlowSemiCondensed-SemiBold.ttf")
const DISPLAY := preload("res://assets/fonts/BarlowCondensed-ExtraBold.ttf")
## The heaviest cut, for the one line that is a mark rather than a heading: the name on the
## title, GAME.md 8.1a.
const MARK := preload("res://assets/fonts/BarlowCondensed-Black.ttf")
const FALLBACK := preload("res://assets/fonts/Inter-Regular.ttf")

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


static func _static_init() -> void:
	for font: FontFile in [TEXT, STRONG, DISPLAY, MARK]:
		if font.fallbacks.is_empty():
			font.fallbacks = [FALLBACK]


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
