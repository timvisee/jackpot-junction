class_name Type
extends RefCounted
## The type the game is set in, GAME.md 8.3. Three cuts of Inter and a scale of sizes, so a
## number on the HUD and a heading on a menu look like they came out of the same game.
##
## The rule is weight for role rather than size for importance: anything a player reads at a
## glance mid-corner is set in the display cut, anything they read a sentence of is set in the
## text cut, and the middle weight carries names and labels. A size is picked off the scale
## rather than typed in, because a screen with nine sizes on it reads as nine screens.

const TEXT := preload("res://assets/fonts/Inter-Regular.ttf")
const STRONG := preload("res://assets/fonts/Inter-SemiBold.ttf")
const DISPLAY := preload("res://assets/fonts/Inter-Black.ttf")

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


## The display cut, tracked out a little. A [FontVariation] rather than the file itself, because
## tracking is the one thing that makes a heavy face read as a heading rather than as a shout.
static func display_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = DISPLAY
	font.spacing_glyph = int(DISPLAY_TRACKING)
	return font


## The display cut with tabular figures: every digit the same width, so a score counting up or a
## clock counting down stays put instead of jittering sideways as the digits change. Anything
## that shows a number that changes is set in this.
static func numbers_font() -> FontVariation:
	var font := display_font()
	font.opentype_features = {TABULAR: 1}
	return font


## The middle weight with the same tabular figures, for the numbers that are not headlines.
static func numbers_text_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = STRONG
	font.opentype_features = {TABULAR: 1}
	return font


## A number that changes: a score, a clock, a speed.
static func numbers(label: Label, size: int, ink: Color = Color.WHITE) -> Label:
	set_font(label, numbers_font(), size)
	label.add_theme_color_override("font_color", ink)
	return label


## Sets [param node] in one of the three cuts at one of the sizes off the scale.
static func set_font(node: Control, font: Font, size: int) -> void:
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", size)


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
