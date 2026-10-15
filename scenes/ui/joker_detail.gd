class_name JokerDetail
extends PanelContainer
## The pane that describes one joker, GAME.md 8.3. The hand uses it for the card lifted out of
## the fan, and the respawn pick uses it for the card under the cursor and again for the card
## being destroyed, so wherever a player is reading about a joker it reads the same way.
##
## Cut as every pane is, the ticket of GAME.md 8.1a, with the joker's own kind color as the foil
## round its header and engraved under it. The name, how rare the joker is and what kind it is
## share the header, a perforation tears it from what the joker actually does, and the keys for it
## sit at the foot in gray, so they are told apart at a glance rather than run together in one
## paragraph.
##
## A joker that stacks, held more than once, says how many beside its name, see [method
## show_joker], and what the whole stack does in its words, every number the stack has changed
## in the same gold, so it reads as the stack's rather than the card's own.
##
## The catalog prints it on the House's paper instead, its spec sheet, see [method print_on_paper].

const WIDTH := 400.0
const HINT := Color(0.62, 0.62, 0.68)
## How strongly the kind's color shows as the foil round the header, round the body, and in the
## lines engraved under the header.
const FRAME := 0.8
const FRAME_BODY := 0.16
const ENGRAVED := 0.1
const STACK := Color(1.0, 0.84, 0.36)
## How big the suit is on its line, GAME.md 7.3. A space stands between it and the count, or
## between it and the wild card's words, and none before the colon of a suit's.
const SUIT_SIDE := 16.0
## How big the suit before the name is, where it is shown there.
const TITLE_SUIT := 26.0
const SPACE := "\u00a0"
## What the hand makes, under the suit's line in a match, GAME.md 7.3.
const ACTIVE := "Your hand: %s."

var _style: TicketStyle
## Whether it is printed on the House's paper, see [method print_on_paper].
var _paper := false
var _name: Label
## The card's suit before its name, in the catalog where the loupe has no room to show it, GAME.md
## 8.8, and which suit, or -1 for none.
var _title_mark: JokerSuits.Mark
var _title_suit := -1
var _stack: Label
var _rarity: Label
var _kind: Label
var _body: RichTextLabel
## The perforation under the header, as wide as the pane's words, see [method set_width].
var _tear: Control
## The term the card is, in the House's words, under what it does from the story's second stage,
## STORY.md 6.3. Never in place of the effect, which is the whole of what a card does.
var _term: Label
## The card's suit and what three of it pay, GAME.md 7.3, under what it does: "3×", the suit drawn,
## and what it pays.
var _suit_row: HBoxContainer
var _suit_count: Label
var _suit_mark: JokerSuits.Mark
var _suit_words: Label
## What the hand the card is in makes, in a match, GAME.md 7.3, see [method show_active].
var _active: Label
var _box: VBoxContainer
var _hints: Control
## The joker the pane is filled in for and the stack it said, so filling it in again for the same
## is nothing: the hand and the pick ask every frame, and painting the top edge again is a new
## layout each time.
var _joker: Joker
## The card a Copy Cat was copying as the pane was filled in, GAME.md 7.3, for its words to follow.
var _standing: Joker
var _stack_said := ""
var _details := false
var _stage := -1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = TicketStyle.cut(MenuTheme.PANE_BG, 10.0, 18.0, 18.0)
	_style.frame_inset = 5.0
	_style.bite = 8.0
	_style.waves = 64.0
	_style.shadow = 12.0
	add_theme_stylebox_override("panel", _style)
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 9)
	add_child(_box)
	var box := _box
	var heading := HBoxContainer.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_theme_constant_override("separation", 14)
	box.add_child(heading)
	_title_mark = JokerSuits.Mark.new()
	_title_mark.custom_minimum_size = Vector2.ONE * TITLE_SUIT
	_title_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title_mark.visible = false
	heading.add_child(_title_mark)
	_name = _line(28, Color(0.97, 0.97, 1.0))
	Type.set_font(_name, Type.display_font(), 28)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(_name)
	_stack = _line(20, STACK)
	_stack.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stack.visible = false
	heading.add_child(_stack)
	_rarity = _line(16, Color.WHITE)
	Type.set_font(_rarity, Type.STRONG, 16)
	_rarity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_rarity)
	_kind = _line(16, Color.WHITE)
	Type.set_font(_kind, Type.STRONG, 16)
	_kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_kind.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_kind)
	var tear := MenuTheme.perforation()
	tear.custom_minimum_size.x = WIDTH
	box.add_child(tear)
	_tear = tear
	_body = RichTextLabel.new()
	_body.fit_content = true
	_body.scroll_active = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH, 0.0)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.bbcode_enabled = true
	_body.add_theme_font_size_override("normal_font_size", 18)
	box.add_child(_body)
	_suit_row = HBoxContainer.new()
	_suit_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_suit_row.add_theme_constant_override("separation", 0)
	_suit_count = _line(15, HINT)
	_suit_count.text = "%d×%s" % [JokerSuits.SUITED, SPACE]
	_suit_row.add_child(_suit_count)
	_suit_mark = JokerSuits.Mark.new()
	_suit_mark.custom_minimum_size = Vector2.ONE * SUIT_SIDE
	_suit_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_suit_row.add_child(_suit_mark)
	_suit_words = _line(15, HINT)
	_suit_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# What is left of the line once the count and the suit have theirs, never more: a line wider than
	# the pane would widen the pane.
	_suit_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_suit_row.add_child(_suit_words)
	box.add_child(_suit_row)
	_active = _line(15, STACK)
	_active.name = "Active"
	_active.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_active.custom_minimum_size = Vector2(WIDTH, 0.0)
	_active.visible = false
	box.add_child(_active)
	_term = _line(15, HINT)
	_term.name = "Term"
	_term.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_term.custom_minimum_size = Vector2(WIDTH, 0.0)
	_term.visible = false
	box.add_child(_term)


## Prints the pane on the House's cream paper, as the catalog's spec sheet, GAME.md 8.8: its words
## in ink, every color in it the darker one that reads on paper, see [method HouseTheme.on_paper].
## Plain paper, without the waves engraved across its head, a dozen draws a frame fewer.


## Puts [param suit] before the card's name, by [enum Joker.Suit], or nothing for -1: the catalog's,
## where its loupe has no room to show it, GAME.md 8.8.
func show_title_suit(suit: int) -> void:
	_title_suit = suit
	_title_mark.visible = suit >= 0
	if suit >= 0:
		_title_mark.suit = suit as Joker.Suit
		_title_mark.paper = _paper
		_title_mark.queue_redraw()


## The suit before the name, or -1 for none.
func title_suit() -> int:
	return _title_suit


func print_on_paper() -> void:
	_paper = true
	var look := TicketStyle.cut(HouseTheme.PAPER, 10.0, 18.0, 18.0)
	look.frame_inset = _style.frame_inset
	look.bite = _style.bite
	look.shadow = _style.shadow
	look.frame = _style.frame
	look.frame_body = _style.frame_body
	_style = look
	add_theme_stylebox_override("panel", _style)
	_name.add_theme_color_override("font_color", HouseTheme.INK)
	_stack.add_theme_color_override("font_color", _ink(STACK))
	_term.add_theme_color_override("font_color", faint())
	_suit_words.add_theme_color_override("font_color", faint())
	_suit_count.add_theme_color_override("font_color", faint())
	_suit_mark.paper = true
	_body.add_theme_color_override("default_color", HouseTheme.INK)
	_joker = null


## The gray what is said about the rest is in: the House's faint ink on paper.
func faint() -> Color:
	return HouseTheme.INK_FAINT if _paper else HINT


## [param color] as the pane shows it: as it is on the dark stock, darker on paper.
func _ink(color: Color) -> Color:
	return HouseTheme.on_paper(color) if _paper else color


## Fills the pane for one joker and puts its kind's color round the header. [param held] is how
## many copies of it the player holds; a joker that stacks, held more than once, says so beside
## its name, and [param taking] says what taking one more would make it instead. [param details]
## is the player holding the key for more, see [method Joker.describe].
func show_joker(joker: Joker, held := 1, taking := false, details := false) -> void:
	var copies := held + 1 if taking else held
	var said := ""
	if joker.stackable and copies > 1:
		said = ("makes ×%d" if taking else "×%d") % copies
	var stage := Story.stage_here()
	var standing := joker.standing_for
	var same := joker == _joker and said == _stack_said and details == _details
	if same and stage == _stage and standing == _standing:
		return
	_joker = joker
	_standing = standing
	_stack_said = said
	_details = details
	_stage = stage
	var term: String = StoryLines.TERMS.get(joker.id, "")
	_term.text = term
	_term.visible = stage >= StoryLines.TERMS_FROM and not term.is_empty()
	_stack.text = said
	_stack.visible = not said.is_empty()
	var color := _ink(JokerCard.kind_color(joker))
	_style.frame = Color(color, FRAME)
	_style.frame_body = Color(color, FRAME_BODY)
	_style.engraving = Color(color, 0.0 if _paper else ENGRAVED)
	_name.text = joker.display_name
	_rarity.visible = true
	_kind.visible = true
	_body.visible = true
	_rarity.text = JokerCard.rarity_name(joker).to_upper()
	_rarity.add_theme_color_override("font_color", _ink(JokerCard.rarity_color(joker)))
	_kind.text = JokerCard.kind_name(joker).to_upper()
	_kind.add_theme_color_override("font_color", color)
	var gold := _ink(STACK).to_html(false)
	_body.text = joker.describe(copies, "[color=#%s]%%s[/color]" % gold, details)
	_suit_row.visible = true
	_suit_mark.suit = joker.suit
	_suit_mark.queue_redraw()
	var wild := joker.suit == Joker.Suit.WILD
	_suit_words.text = (SPACE if wild else "") + JokerSuits.words(joker.suit)
	_suit_count.visible = not wild
	_light_suit(false)
	_active.visible = false


## Says what the hand the card is in makes, in a match while its key is held, GAME.md 7.3: its
## suit's line lit gold while [param made] is Suited in it, a wild card's in the suit [param lead]
## it joins, and under it the hands made, only with [param details] asked for, the details key held.
## Nothing in the catalog, which shows a card on its own.
func show_active(made: JokerHands.Made, lead: int, details := true) -> void:
	if _joker == null:
		return
	var suit := lead if _joker.suit == Joker.Suit.WILD else _joker.suit
	_light_suit(suit in made.suited)
	_active.visible = details and made.best() >= 0
	if not _active.visible:
		return
	var named: Array[String] = []
	for hand: int in made.hands:
		named.append(JokerHands.name_of(hand))
	_active.text = ACTIVE % ", ".join(named)


## The suit's line in gold while the hand is Suited in it, or as the pane's hints otherwise.
func _light_suit(lit: bool) -> void:
	var ink := _ink(STACK) if lit else faint()
	_suit_words.add_theme_color_override("font_color", ink)
	_suit_count.add_theme_color_override("font_color", ink)


## Fills the pane for a card lying face down, GAME.md 8.8: [param words] in its name's place and
## [param under] in gray under them, and nothing else, neither what it does nor what kind it is nor
## how rare, framed in gray.
func show_unknown(words: String, under: String) -> void:
	_joker = null
	_stack_said = ""
	_stage = -1
	_name.text = words
	_stack.visible = false
	_rarity.visible = false
	_kind.visible = false
	_body.visible = true
	_body.text = "[color=#%s]%s[/color]" % [faint().to_html(false), under]
	_term.visible = false
	_suit_row.visible = false
	_active.visible = false
	var gray := _ink(CardBack.INK)
	_style.frame = Color(gray, FRAME)
	_style.frame_body = Color(gray, FRAME_BODY)
	_style.engraving = Color(gray, 0.0 if _paper else ENGRAVED)


## The controls for whatever the player can do from here, as a row of pictures and words built
## by [InputHint]. Null takes the row away, for a pane with nothing to say about the controls.
func set_hints(line: Control) -> void:
	if _hints != null:
		_box.remove_child(_hints)
		_hints.queue_free()
	_hints = line
	if _hints != null:
		_box.add_child(_hints)


## The pane's words set [param across] wide rather than [constant WIDTH], for a pick sharing the
## screen that has no room beside its cards for the whole of it, see [JokerPicker]. The words wrap
## onto more lines instead.
func set_width(across: float) -> void:
	for part: Control in [_tear, _body, _term]:
		if part != null:
			part.custom_minimum_size.x = across


## The color the hint row is drawn in, so whoever builds one matches the pane it goes in.
static func hint_ink() -> Color:
	return HINT


func _line(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
