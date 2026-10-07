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

const WIDTH := 400.0
const HINT := Color(0.62, 0.62, 0.68)
## How strongly the kind's color shows as the foil round the header, round the body, and in the
## lines engraved under the header.
const FRAME := 0.8
const FRAME_BODY := 0.16
const ENGRAVED := 0.1
const STACK := Color(1.0, 0.84, 0.36)

var _style: TicketStyle
var _name: Label
var _stack: Label
var _rarity: Label
var _kind: Label
var _body: RichTextLabel
## The term the card is, in the House's words, under what it does from the story's second stage,
## STORY.md 6.3. Never in place of the effect, which is the whole of what a card does.
var _term: Label
var _box: VBoxContainer
var _hints: Control
## The joker the pane is filled in for and the stack it said, so filling it in again for the same
## is nothing: the hand and the pick ask every frame, and painting the top edge again is a new
## layout each time.
var _joker: Joker
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
	_body = RichTextLabel.new()
	_body.fit_content = true
	_body.scroll_active = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH, 0.0)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.bbcode_enabled = true
	_body.add_theme_font_size_override("normal_font_size", 18)
	box.add_child(_body)
	_term = _line(15, HINT)
	_term.name = "Term"
	_term.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_term.custom_minimum_size = Vector2(WIDTH, 0.0)
	_term.visible = false
	box.add_child(_term)


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
	if joker == _joker and said == _stack_said and details == _details and stage == _stage:
		return
	_joker = joker
	_stack_said = said
	_details = details
	_stage = stage
	var term: String = StoryLines.TERMS.get(joker.id, "")
	_term.text = term
	_term.visible = stage >= StoryLines.TERMS_FROM and not term.is_empty()
	_stack.text = said
	_stack.visible = not said.is_empty()
	var color := JokerCard.kind_color(joker)
	_style.frame = Color(color, FRAME)
	_style.frame_body = Color(color, FRAME_BODY)
	_style.engraving = Color(color, ENGRAVED)
	_name.text = joker.display_name
	_rarity.visible = true
	_kind.visible = true
	_body.visible = true
	_rarity.text = JokerCard.rarity_name(joker).to_upper()
	_rarity.add_theme_color_override("font_color", JokerCard.rarity_color(joker))
	_kind.text = JokerCard.kind_name(joker).to_upper()
	_kind.add_theme_color_override("font_color", color)
	_body.text = joker.describe(copies, "[color=#%s]%%s[/color]" % STACK.to_html(false), details)


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
	_body.text = "[color=#%s]%s[/color]" % [HINT.to_html(false), under]
	_term.visible = false
	_style.frame = Color(CardBack.INK, FRAME)
	_style.frame_body = Color(CardBack.INK, FRAME_BODY)
	_style.engraving = Color(CardBack.INK, ENGRAVED)


## The controls for whatever the player can do from here, as a row of pictures and words built
## by [InputHint]. Null takes the row away, for a pane with nothing to say about the controls.
func set_hints(line: Control) -> void:
	if _hints != null:
		_box.remove_child(_hints)
		_hints.queue_free()
	_hints = line
	if _hints != null:
		_box.add_child(_hints)


## The color the hint row is drawn in, so whoever builds one matches the pane it goes in.
static func hint_ink() -> Color:
	return HINT


func _line(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
