class_name Terms
extends RefCounted
## The game's own words in the lessons, GAME.md 9.4a: a counter of the HUD, the chips, the mult, the
## pot, the bank, the nitro and the lives, is drawn bold in the color the HUD shows it in, and a
## place on the floor, the Jackpot, the Junction and a Royal Flush, bold in a color of their own,
## so "Mult will multiply your pot" reads as two things on the screen and not a sentence about
## them. A line marks them with braces, "{Mult} will multiply your {pot}", and whatever draws it
## draws them, see [method words]; anywhere else the braces are dropped, see [method plain].

## The color of a place.
const PLACE := Color("#7EE08F")
## The nitro's and the lives', as the HUD has them where the palette has no name for them.
const NITRO := Color(1.0, 0.75, 0.3)
const LIVES := Color(1.0, 0.4, 0.35)
## Each word, in lower case, to its color.
const COLORS: Dictionary[String, Color] = {
	"chip": Palette.CHIPS,
	"chips": Palette.CHIPS,
	"mult": Palette.MULT,
	"pot": Palette.CHIP_GOLD,
	"pots": Palette.CHIP_GOLD,
	"bank": Palette.CHIP_GOLD,
	"banked": Palette.CHIP_GOLD,
	"nitro": NITRO,
	"life": LIVES,
	"lives": LIVES,
	"jackpot": PLACE,
	"jackpots": PLACE,
	"junction": PLACE,
	"royal flush": PLACE,
}


## [param text] with its marks taken out, for anything that shows it as it is.
static func plain(text: String) -> String:
	return text.replace("{", "").replace("}", "")


## [param text] as bbcode: each marked word bold in its color, or bold alone for a word with none,
## or with no color at all when [param lit] is false, for a line that is dimmed. Its colors
## darkened to read on cream [param on_paper], see [method HouseTheme.on_paper].
static func bbcode(text: String, lit := true, on_paper := false) -> String:
	var said := ""
	var rest := text
	while true:
		var open := rest.find("{")
		var close := rest.find("}", open + 1)
		if open < 0 or close < 0:
			break
		said += rest.left(open)
		var word := rest.substr(open + 1, close - open - 1)
		var color: Color = COLORS.get(word.to_lower(), Color.TRANSPARENT)
		if on_paper and color.a > 0.0:
			color = HouseTheme.on_paper(color)
		if lit and color.a > 0.0:
			said += "[b][color=#%s]%s[/color][/b]" % [color.to_html(false), word]
		else:
			said += "[b]%s[/b]" % word if lit else word
		rest = rest.substr(close + 1)
	return said + rest


## [param text] drawn in [param ink] at [param size]: a plain label when nothing in it is marked,
## and the marked words in their colors when something is.
static func words(text: String, ink: Color, size: int) -> Control:
	if not text.contains("{"):
		var label := Label.new()
		label.text = text
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", ink)
		return label
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_OFF
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rich.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rich.add_theme_font_override("bold_font", Type.STRONG)
	rich.add_theme_font_size_override("normal_font_size", size)
	rich.add_theme_font_size_override("bold_font_size", size)
	rich.add_theme_color_override("default_color", ink)
	rich.text = bbcode(text)
	return rich
