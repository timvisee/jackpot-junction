class_name ScorePills
extends HBoxContainer
## The two halves of a pot on the HUD, GAME.md 8.3: the chips a lap is worth and the mult they
## are multiplied by, each in a pill of its own color with the multiply sign between them and
## what the two come to after it.
##
## A pot is one number made of two, and which of the two is moving is the whole of what a player
## is deciding about: another lap for more chips, or the Junction for the mult before somebody
## takes it off them. Written as one line of text it read as arithmetic. Written as two colored
## pills it reads as two things, and the colors are the same two everywhere the halves are
## shown, see [Palette].

## How wide each pill is at its narrowest. A floor rather than a fixed size: the pane round the
## line is the thing that must not shuffle, GAME.md 8.3, and it is a fixed width of its own, so a
## pill is free to grow into it when the number outgrows the pill. Clipped instead, a mult of 24.5
## lost its last digit, which is the one that says how much the pot is worth.
const CHIP_WIDTH := 62.0
const MULT_WIDTH := 46.0
## The pill itself: how much of its color is behind the number, how bright the rim is, and how
## much room the number has inside it.
const FILL := 0.22
const RIM := 0.75
const PAD_X := 8
const PAD_Y := 1
const RADIUS := 7

var chips: Label
var mult: Label
var total: Label

## The pills and the signs, hidden together when there is a word to show instead.
var _parts: Array[Control] = []
var _note: Label


## Puts a pot line in [param parent], reading left to right whichever corner it is in.
static func add_to(parent: Control, right: bool) -> ScorePills:
	var pills := ScorePills.new()
	pills.name = "ScorePills"
	pills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pills.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	pills.add_theme_constant_override("separation", 6)
	parent.add_child(pills)
	pills._build()
	return pills


## A mult as it is written: whole when it is whole, one decimal when it is not.
static func mult_text(mult: float) -> String:
	if is_equal_approx(mult, roundf(mult)):
		return str(int(roundf(mult)))
	return "%.1f" % mult


## What the kart is carrying: so many chips, times so much.
func show_pot(coins: int, mult_value: float, value: int) -> void:
	for part: Control in _parts:
		part.visible = true
	_note.visible = false
	chips.text = str(coins)
	mult.text = mult_text(mult_value)
	total.text = str(value)


## Something to say instead of a pot, such as how long until this player is back on the floor.
func say(words: String) -> void:
	for part: Control in _parts:
		part.visible = false
	_note.visible = true
	_note.text = words


func _build() -> void:
	chips = _pill(Palette.CHIPS, CHIP_WIDTH)
	_sign("×")
	mult = _pill(Palette.MULT, MULT_WIDTH)
	_sign("=")
	total = _text(Color(0.94, 0.94, 0.97))
	total.clip_text = false
	total.custom_minimum_size = Vector2(76.0, 0.0)
	add_child(total)
	_parts.append(total)
	_note = _text(Color(0.82, 0.82, 0.88))
	# Measured, like the signs: clipped, with nothing else on the line asking for room, it was
	# nought pixels wide, and a player waiting to come back was never shown how long for.
	_note.clip_text = false
	_note.visible = false
	add_child(_note)


## One half of the pot: a number in a pill of its own color.
func _pill(ink: Color, width: float) -> Label:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", _skin(ink))
	var label := _text(ink.lightened(0.5))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Measured rather than clipped, so the pill asks for the room its number needs and the
	# minimum below is only the width it never goes under.
	label.clip_text = false
	label.custom_minimum_size = Vector2(width, 0.0)
	box.add_child(label)
	add_child(box)
	_parts.append(box)
	return label


func _sign(mark: String) -> void:
	var label := _text(Color(0.7, 0.7, 0.76))
	label.text = mark
	# A sign is one character wide and never changes, so it is measured rather than clipped: a
	# clipped label with nothing asking for room is a label nought pixels wide.
	label.clip_text = false
	add_child(label)
	_parts.append(label)


func _text(ink: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(label, Type.numbers_text_font(), Type.LARGE)
	label.add_theme_color_override("font_color", ink)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	HudText.shadowed(label)
	return label


func _skin(ink: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(ink.r, ink.g, ink.b, FILL)
	style.border_color = Color(ink.r, ink.g, ink.b, RIM)
	style.set_border_width_all(1)
	style.set_corner_radius_all(RADIUS)
	style.content_margin_left = PAD_X
	style.content_margin_right = PAD_X
	style.content_margin_top = PAD_Y
	style.content_margin_bottom = PAD_Y
	return style
