class_name AboutTab
extends ScrollContainer
## The About page of the settings, GAME.md 8.5: the mark, the name and the version, that the game
## is an experiment made by AI and by which models, everything in it somebody else made, and the
## way to the game's page to play it from and to its source. The licenses close it: Godot's own,
## which the engine's license asks every game made with it to carry, and under a link at the foot,
## built the first time it is opened, every other notice the build carries, see [Licenses]. Where
## the Steam supporter pack is offered and not owned, a quiet word on it under the game's links, see
## [method _supporter].

const WIDTH := 900.0
const INK := Color(0.86, 0.86, 0.9)
const FAINT := Color(0.6, 0.6, 0.65)
## How big the mark is, and the room over it, off the page's top edge.
const MARK := 168.0
const MARK_ROOM := 18.0
## The Steam supporter pack, GAME.md 10.8: a faint line under the game's own links, and a link
## that opens its store page in Steam's overlay, each shown through tr(), the pack's star pinned
## beside it, how big.
const SUPPORTER_LINE := """Enjoying it? The Supporter Pack on Steam is a small way to chip in, and \
says thanks with a few pieces of kart dress."""
const SUPPORTER_LINK := "Get the Supporter Pack on Steam"
const SUPPORTER_PIN := 24.0
## The link at the foot that opens the third-party notices under it, and folds them away again,
## each shown through tr().
const SHOW_LICENSES := "Show third-party licenses"
const HIDE_LICENSES := "Hide third-party licenses"
## How many characters of the notices go in a frame once they open, how long a piece of a
## license's text runs before its next paragraph starts another, and how many pieces of Godot one
## list holds: all at once they held the page some 100 ms on a desktop, longer on a Deck or a
## phone, so they come in top first, a little a frame, the whole in a fraction of a second.
const NOTICE_BUDGET := 3000
const NOTICE_PIECE := 2000
const LIST_PIECE := 20
## The room over and under a heading among the notices, and between two pieces in a list, a list
## cut in two included, so that where a text or a list was cut reads as no cut at all.
const SUBHEADING_ROOM := Vector2(24.0, 8.0)
const LIST_GAP := 5

## The supporter pack's link, and the line over it below, while the pack is offered and not owned.
var supporter_link: LinkButton
## The link that opens the notices, and the notices, null until it first does: the page is built
## each time the settings open, and the notices run to some 70,000 characters.
var licenses_link: LinkButton
var notices: VBoxContainer
## The line over [member supporter_link].
var _supporter_line: Label
## The notices still to go in, in order, see [method _fill].
var _unfilled: Array[Control] = []


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
	column.add_child(MenuTheme.title("Jackpot Junction", Type.TITLE))  # NO_TRANSLATE
	column.add_child(MenuTheme.subtitle(tr("Version %s") % Game.version(), Type.BODY))
	var made := {"models": Credits.models_in_words(), "human": tr(StoryLines.ABOUT)}
	var experiment := tr(
		"""Jackpot Junction is an experiment in what an AI model can make. Everything \
in it that is not credited below, its design, its code, the pictures it draws and how it all fits \
together, was made by Anthropic's Claude: {models}. {human}"""
	)
	column.add_child(_paragraph(experiment.format(made)))
	# Where to get it, Steam and then itch.io, then where its source lives.
	column.add_child(_link(Credits.STEAM))
	column.add_child(_link(Credits.ITCH))
	column.add_child(_link(Credits.REPOSITORY))
	if Supporter.offered() and not Supporter.owned():
		_supporter(column)
	column.add_child(_heading(tr("Made with")))
	for thing: Dictionary in Credits.in_this_build():
		column.add_child(_credit(thing))
	column.add_child(_heading(tr("Licenses")))
	column.add_child(_subheading("Godot Engine"))  # NO_TRANSLATE
	column.add_child(_notice(Engine.get_license_text()))
	licenses_link = _link("")
	licenses_link.name = "LicensesLink"
	licenses_link.text = tr(SHOW_LICENSES)
	licenses_link.pressed.connect(toggle_licenses)
	column.add_child(licenses_link)


## Opens the notices under their link, building them the first time, or folds them away again.
func toggle_licenses() -> void:
	if notices == null:
		notices = VBoxContainer.new()
		notices.name = "Notices"
		# Every gap is the notices' own, see SUBHEADING_ROOM.
		notices.add_theme_constant_override("separation", 0)
		licenses_link.get_parent().add_child(notices)
		_unfilled = _notices()
		_fill()
	else:
		notices.visible = not notices.visible
	licenses_link.text = tr(HIDE_LICENSES) if notices.visible else tr(SHOW_LICENSES)


## Whether the notices are still coming in, see [method _fill].
func filling() -> bool:
	return not _unfilled.is_empty()


## Puts the next of the notices in, up to [constant NOTICE_BUDGET] characters of them and at least
## one: a label lays its text out as it goes in, and that is where the time goes.
func _fill() -> void:
	var spent := 0
	while not _unfilled.is_empty() and spent < NOTICE_BUDGET:
		var next: Control = _unfilled.pop_front()
		spent += _words(next).length()
		notices.add_child(next)


## The notices, see [Licenses], in order, none of them in the tree yet: the game's own third-party
## pieces whose terms have a text, whose they are and on what terms, the pieces inside Godot the
## same way, then each license's text, in pieces of about [constant NOTICE_PIECE] characters.
static func _notices() -> Array[Control]:
	var box: Array[Control] = []
	var things := Credits.in_this_build()
	var of := Licenses.pieces()
	var ours: Array[PackedStringArray] = []
	for thing: Dictionary in things:
		if thing.has("license"):
			var terms := Licenses.copyright(thing.get("copyright", []))
			terms.append(Licenses.title(thing["license"]))
			ours.append(PackedStringArray([thing["what"], ", ".join(terms)]))
	box.append(_subheading(Lang.t("In the game"), true))
	box.append(_list(ours))
	var godots: Array[PackedStringArray] = []
	for piece: Dictionary in of:
		var parts := PackedStringArray()
		for part: Dictionary in piece["parts"]:
			var terms := Licenses.copyright(part["copyright"])
			terms.append(Licenses.title(part["license"]))
			parts.append(", ".join(terms))
		godots.append(PackedStringArray([piece["name"], "; ".join(parts)]))
	box.append(_subheading(Lang.t("Inside Godot Engine"), true))
	for start: int in range(0, godots.size(), LIST_PIECE):
		box.append(_list(godots.slice(start, start + LIST_PIECE)))
	var texts := Engine.get_license_info()
	for key: String in Licenses.keys(things, of):
		box.append(_subheading(Licenses.title(key), true))
		var pieces := _pieces(texts[key])
		for i: int in pieces.size():
			# A piece after the first starts on the blank line its paragraph had.
			box.append(_notice(pieces[i] if i == 0 else "\n" + pieces[i]))
	return box


## [param text] cut at its paragraphs into pieces of about [constant NOTICE_PIECE] characters, a
## paragraph longer than that a piece of its own.
static func _pieces(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var piece := ""
	for paragraph: String in text.strip_edges().split("\n\n"):
		if not piece.is_empty() and piece.length() + paragraph.length() > NOTICE_PIECE:
			out.append(piece)
			piece = ""
		piece = paragraph if piece.is_empty() else piece + "\n\n" + paragraph
	if not piece.is_empty():
		out.append(piece)
	return out


## The supporter pack's word under the game's links, where it is offered and not owned: a faint
## line, and a gold link in the middle as the others are, with the pack's star pinned beside it,
## which opens its store page.
func _supporter(column: VBoxContainer) -> void:
	_supporter_line = _paragraph(tr(SUPPORTER_LINE), Type.BODY, FAINT)
	column.add_child(_supporter_line)
	var row := HBoxContainer.new()
	row.name = "SupporterLink"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 8)
	var pin := Control.new()
	pin.custom_minimum_size = Vector2.ONE * SUPPORTER_PIN
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.draw.connect(func() -> void: PartTray.draw_star(pin, pin.size / 2.0, SUPPORTER_PIN * 0.42))
	row.add_child(pin)
	supporter_link = _link(Credits.STEAM)
	supporter_link.uri = ""
	supporter_link.text = tr(SUPPORTER_LINK)
	supporter_link.pressed.connect(
		func() -> void:
			Audio.play_sfx(&"ui_click" if Store.open_supporter() else &"ui_back", -4.0, 0.05)
	)
	row.add_child(supporter_link)
	column.add_child(row)


## Notices not yet in go with the page, as they are not in the tree to go with it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for left: Control in _unfilled:
			left.free()
		_unfilled.clear()


## The notices come in, a little a frame, once opened, see [method _fill]. And bought while the
## page is up, the supporter pack's word goes, the cursor on the link before it.
func _process(_delta: float) -> void:
	if not _unfilled.is_empty():
		_fill()
	if supporter_link == null or not Supporter.owned():
		return
	var had := supporter_link.has_focus()
	var before := _supporter_line.get_parent().get_child(_supporter_line.get_index() - 1) as Control
	for gone: Control in [_supporter_line, supporter_link.get_parent() as Control]:
		gone.get_parent().remove_child(gone)
		gone.queue_free()
	supporter_link = null
	_supporter_line = null
	if had and before != null:
		before.grab_focus()


## A gold link to [param uri], its address shown without the scheme, which opens it on a press.
static func _link(uri: String) -> LinkButton:
	var link := LinkButton.new()
	link.text = uri.trim_prefix("https://")
	link.uri = uri
	link.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	link.focus_mode = Control.FOCUS_ALL
	Type.set_font(link, Type.STRONG, Type.BODY)
	link.add_theme_color_override("font_color", Palette.CHIP_GOLD)
	link.add_theme_color_override("font_focus_color", Palette.CHIP_WHITE)
	link.add_theme_color_override("font_hover_color", Palette.CHIP_WHITE)
	return link


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


## A heading inside the licenses, smaller than the page's own; among the notices, which have no gaps
## of their own, with [param room] over and under it.
static func _subheading(text: String, room := false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.strong(label, Type.BODY, INK)
	if room:
		var box := StyleBoxEmpty.new()
		box.content_margin_top = SUBHEADING_ROOM.x
		box.content_margin_bottom = SUBHEADING_ROOM.y
		label.add_theme_stylebox_override("normal", box)
	return label


## A license's text, small and faint, set from the left as it was written.
static func _notice(text: String) -> Label:
	var label := _paragraph(text, Type.LABEL, FAINT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


## Pieces one to a line, [param entries] each a name and what to say of it: the name in bold, then
## whose it is and on what terms, faint. Written through the label's own calls rather than BBCode,
## so a bracket in a name is a bracket.
static func _list(entries: Array[PackedStringArray]) -> RichTextLabel:
	var list := RichTextLabel.new()
	list.fit_content = true
	list.scroll_active = false
	list.custom_minimum_size = Vector2(WIDTH, 0.0)
	list.add_theme_font_size_override("normal_font_size", Type.LABEL)
	list.add_theme_font_size_override("bold_font_size", Type.LABEL)
	list.add_theme_font_override("bold_font", Type.STRONG)
	list.add_theme_color_override("default_color", FAINT)
	list.add_theme_constant_override("paragraph_separation", LIST_GAP)
	for i: int in entries.size():
		if i > 0:
			list.newline()
		list.push_color(INK)
		list.push_bold()
		list.add_text(entries[i][0])
		list.pop()
		list.pop()
		list.add_text("  " + entries[i][1])
	return list


static func _paragraph(text: String, size := Type.BODY, ink := INK) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(WIDTH, 0.0)
	Type.text(label, size, ink)
	return label


## One thing somebody else made: what it is in bold, then who, on what terms and where; each but
## where shown through tr(), see [Credits].
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
	var parts := {
		"what": "[b]%s[/b]" % Lang.t(thing["what"]),
		"who": Lang.t(thing["who"]),
		"terms": Lang.t(thing["terms"]),
		"where": "[color=#%s]%s[/color]" % [FAINT.to_html(false), whole(thing["where"])],
	}
	line.text = "[center]%s[/center]" % Lang.t("{what} by {who}, {terms}, {where}").format(parts)
	return line


## [param link] kept on one line, as a line of Chinese, which may break anywhere, would otherwise
## break it after a slash: a word joiner after each, which allows no break and shows nothing.
static func whole(link: String) -> String:
	return link.replace("/", "/⁠")
