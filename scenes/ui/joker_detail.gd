class_name JokerDetail
extends PanelContainer
## The pane that describes one joker, GAME.md 8.3. The hand uses it for the card lifted out of
## the fan, and the respawn pick uses it for the card under the cursor and again for the card
## being destroyed, so wherever a player is reading about a joker it reads the same way.
##
## Laid out like a standings row so the two read as the same game: a dark translucent card with
## room to breathe and a bar of the joker's own kind colour along the top. The name and the kind
## share the first line, a rule separates them from what the joker actually does, and the keys
## for it sit at the foot in grey, so the three are told apart at a glance rather than run
## together in one paragraph.

const WIDTH := 400.0
const BG := Color(0.07, 0.07, 0.09, 0.92)
const RULE := Color(1.0, 1.0, 1.0, 0.13)
const HINT := Color(0.62, 0.62, 0.68)
## The colour bar along the top edge, thick enough to be the pane's heading rather than a line.
const EDGE := 6

var _style: StyleBoxFlat
var _name: Label
var _kind: Label
var _body: RichTextLabel
var _hints: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = StyleBoxFlat.new()
	_style.bg_color = BG
	_style.set_corner_radius_all(8)
	_style.content_margin_left = 18.0
	_style.content_margin_right = 18.0
	_style.content_margin_top = 13.0
	_style.content_margin_bottom = 13.0
	_style.border_width_top = EDGE
	add_theme_stylebox_override("panel", _style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 9)
	add_child(box)
	var heading := HBoxContainer.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_theme_constant_override("separation", 14)
	box.add_child(heading)
	_name = _line(24, Color(0.97, 0.97, 1.0))
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(_name)
	_kind = _line(16, Color.WHITE)
	_kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_kind.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_kind)
	var rule := ColorRect.new()
	rule.color = RULE
	rule.custom_minimum_size = Vector2(WIDTH, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)
	_body = RichTextLabel.new()
	_body.fit_content = true
	_body.scroll_active = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH, 0.0)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_theme_font_size_override("normal_font_size", 18)
	box.add_child(_body)
	_hints = _line(15, HINT)
	_hints.visible = false
	box.add_child(_hints)


## Fills the pane for one joker and paints the top edge in its kind's colour.
func show_joker(joker: Joker) -> void:
	var color := JokerCard.kind_color(joker)
	_style.border_color = color
	_name.text = joker.display_name
	_kind.text = JokerCard.kind_name(joker).to_upper()
	_kind.add_theme_color_override("font_color", color)
	_body.text = joker.description


## The keys for whatever the player can do from here. An empty line takes the row away, for a
## pane with nothing to say about the controls.
func set_hints(text: String) -> void:
	_hints.text = text
	_hints.visible = not text.is_empty()


func _line(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
