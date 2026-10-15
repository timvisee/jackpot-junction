class_name AboutTab
extends ScrollContainer
## The About page of the settings, GAME.md 8.5: the mark, the name and the version, that the game
## is an experiment made by AI and by which models, everything in it somebody else made, and the
## way to the game's page. Godot's own license closes it, which the engine's license asks every
## game made with it to carry.

const WIDTH := 900.0
const INK := Color(0.86, 0.86, 0.9)
const FAINT := Color(0.6, 0.6, 0.65)
## How big the mark is, and the room over it, off the page's top edge.
const MARK := 168.0
const MARK_ROOM := 18.0


func _init() -> void:
	name = "About"


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var middle := CenterContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(middle)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(WIDTH, 0.0)
	column.add_theme_constant_override("separation", 14)
	middle.add_child(column)
	var mark := LogoArt.new()
	mark.plate = false
	mark.custom_minimum_size = Vector2(MARK, MARK)
	var holder := CenterContainer.new()
	holder.custom_minimum_size.y = MARK + MARK_ROOM
	holder.add_child(mark)
	column.add_child(holder)
	column.add_child(MenuTheme.title("Jackpot Junction", Type.TITLE))
	column.add_child(MenuTheme.subtitle("Version %s" % Game.version(), Type.BODY))
	(
		column
		. add_child(
			_paragraph(
				(
					(
						"Jackpot Junction is an experiment in what an AI model can make. Everything in it "
						+ "that is not credited below, its design, its code, the pictures it draws and how "
						+ "it all fits together, was made by Anthropic's Claude: %s. "
						+ StoryLines.ABOUT
					)
					% Credits.models_in_words()
				)
			)
		)
	)
	var link := LinkButton.new()
	link.text = Credits.REPOSITORY.trim_prefix("https://")
	link.uri = Credits.REPOSITORY
	link.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	link.focus_mode = Control.FOCUS_ALL
	Type.set_font(link, Type.STRONG, Type.BODY)
	link.add_theme_color_override("font_color", Palette.CHIP_GOLD)
	link.add_theme_color_override("font_focus_color", Palette.CHIP_WHITE)
	link.add_theme_color_override("font_hover_color", Palette.CHIP_WHITE)
	column.add_child(link)
	column.add_child(_heading("Made with"))
	for thing: Dictionary in Credits.in_this_build():
		column.add_child(_credit(thing))
	column.add_child(_heading("Godot Engine license"))
	var license := _paragraph(Engine.get_license_text(), Type.LABEL, FAINT)
	license.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(license)


## Everything the page says, for asking what it says.
func said() -> String:
	return _words(self)


static func _words(node: Node) -> String:
	var parts: PackedStringArray = []
	if node is Label:
		parts.append((node as Label).text)
	elif node is RichTextLabel:
		parts.append((node as RichTextLabel).get_parsed_text())
	elif node is LinkButton:
		parts.append((node as LinkButton).text)
	for child: Node in node.get_children():
		parts.append(_words(child))
	return " ".join(parts)


static func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.strong(label, Type.HEADING, Palette.CHIP_GOLD)
	return label


static func _paragraph(text: String, size := Type.BODY, ink := INK) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(WIDTH, 0.0)
	Type.text(label, size, ink)
	return label


## One thing somebody else made: what it is in bold, then who, on what terms and where.
static func _credit(thing: Dictionary) -> RichTextLabel:
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.custom_minimum_size = Vector2(WIDTH, 0.0)
	line.add_theme_font_size_override("normal_font_size", Type.BODY)
	line.add_theme_font_size_override("bold_font_size", Type.BODY)
	line.add_theme_font_override("bold_font", Type.STRONG)
	line.add_theme_color_override("default_color", INK)
	line.text = (
		"[center][b]%s[/b] by %s, %s, [color=#%s]%s[/color][/center]"
		% [thing["what"], thing["who"], thing["terms"], FAINT.to_html(false), thing["where"]]
	)
	return line
