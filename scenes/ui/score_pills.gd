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
## shown, see [Palette]. Each pill ends in the thing it counts, GAME.md 8.1a: a chip in the chips'
## blue, and the die the mult is picked up as.

## What a pill ends in.
enum Icon { CHIP, DIE }

## How wide each pill is at its narrowest. A floor rather than a fixed size: the pane round the
## line is the thing that must not shuffle, GAME.md 8.3, and it is a fixed width of its own, so a
## pill is free to grow into it when the number outgrows the pill. Clipped instead, a mult of 24.5
## lost its last digit, which is the one that says how much the pot is worth.
const CHIP_WIDTH := 48.0
const MULT_WIDTH := 36.0
## The pill itself: how much of its color is behind the number, how bright the rim is, and how
## much room the number has inside it.
const FILL := 0.22
const RIM := 0.75
const PAD_X := 8
const PAD_Y := 1
## How wide the total after the pills is at the least.
const TOTAL_WIDTH := 56.0
## Round at both ends, with the chip or the die in the round end the same distance from its curve
## all the way round: as far from the end as from the top and the bottom, see [method _build].
const RADIUS := 18
## How big the chip or the die at the end of a pill is.
const ICON := 20.0
## While the line burns, GAME.md 3.4: how solid a pill goes, and the gold the total is written in.
const BURN_FILL := 0.95
const BURN_TOTAL := Color(1.0, 0.86, 0.35)
const TOTAL_INK := Color(0.94, 0.94, 0.97)
## The shiver of a burning pill, as if straining to hold the heat in: how far it tilts either
## way, in radians, how often it snaps to a new tilt, in seconds, and how quickly it gets there.
const SHIVER := 0.04
const SHIVER_EVERY := 0.06
const SHIVER_SNAP := 45.0
## Now and then a jolt on top: how much bigger the pill pops, how long it takes to settle again,
## and how long between two of them, at the least and the most.
const JOLT := 0.09
const JOLT_SETTLE := 0.16
const JOLT_EVERY := Vector2(0.45, 1.3)
## The glow round a burning pill: how far it spreads, in pixels, how strong it is, and how much
## it flickers either way, both as a share, and how fast.
const GLOW := 9
const GLOW_ALPHA := 0.7
const GLOW_FLICKER := 0.3
const GLOW_SPEED := 13.0

var chips: Label
var mult: Label
var total: Label

## The pills and the signs, hidden together when there is a word to show instead.
var _parts: Array[Control] = []
var _note: Label
## The two pills, each with the label in it and its color, for the fire to rise off.
var _pills: Array[Array] = []
## What the fire is drawn in, behind the pills, and a sheet of it for each pill.
var _fire: Node2D
var _flames: Array[PotFlame] = []
var _burning := false
## For each pill: the tilt it is snapping to, when it picks the next, how much of a jolt it still
## has on it, and when the next one comes.
var _aims: Array[float] = []
var _next_aim: Array[float] = []
var _jolts: Array[float] = []
var _next_jolt: Array[float] = []
## Each pill's look while it burns, kept to make its glow flicker.
var _burn_skins: Array[StyleBoxFlat] = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()
## How far in from its round end a pill's chip or die stands, worked out from how tall the pill is.
var _end_pad := 6.0


## Puts a pot line in [param parent], reading left to right whichever corner it is in.
static func add_to(parent: Control, right: bool) -> ScorePills:
	var pills := ScorePills.new()
	pills.name = "ScorePills"
	pills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pills.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	pills.add_theme_constant_override("separation", 4)
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


## Sets the line alight, for a pot that banked would win the match, GAME.md 3.4: each pill goes
## solid in its own color and shivers, a sheet of fire in that color climbing off it, and the
## total goes gold. Out again, it is as it was.
func set_burning(on: bool) -> void:
	if on == _burning:
		return
	_burning = on
	if on and _fire == null:
		_fire = Node2D.new()
		_fire.name = "Fire"
		add_child(_fire)
		# First, so the pills and the numbers are drawn over it; a container leaves a node that
		# is not a control where it is.
		move_child(_fire, 0)
		for i: int in _pills.size():
			var flame := PotFlame.in_ink(_pills[i][2], i * 7.3)
			_fire.add_child(flame)
			_flames.append(flame)
			_aims.append(0.0)
			_next_aim.append(0.0)
			_jolts.append(0.0)
			_next_jolt.append(_rng.randf_range(JOLT_EVERY.x, JOLT_EVERY.y))
			_burn_skins.append(_glowing_skin(_pills[i][2]))
	if _fire != null:
		_fire.visible = on
	for i: int in _pills.size():
		var pill: Array = _pills[i]
		var panel: PanelContainer = pill[0]
		var ink: Color = pill[2]
		panel.add_theme_stylebox_override("panel", _burn_skins[i] if on else _skin(ink, FILL))
		(pill[1] as Label).add_theme_color_override(
			"font_color", Color.WHITE if on else ink.lightened(0.5)
		)
		panel.rotation = 0.0
		panel.scale = Vector2.ONE
	total.add_theme_color_override("font_color", BURN_TOTAL if on else TOTAL_INK)


func is_burning() -> bool:
	return _burning


func _process(delta: float) -> void:
	if not _burning:
		return
	_time += delta
	for i: int in _pills.size():
		# The glow flickers with the fire, each pill's on a beat of its own.
		var flicker := sin(_time * GLOW_SPEED + i * 1.7) * 0.6 + sin(_time * 29.0 + i) * 0.4
		var glow := _burn_skins[i]
		glow.shadow_color.a = GLOW_ALPHA * (1.0 + GLOW_FLICKER * flicker)
		glow.shadow_size = roundi(GLOW * (1.0 + GLOW_FLICKER * 0.5 * flicker))
		var panel: PanelContainer = _pills[i][0]
		panel.pivot_offset = panel.size * 0.5
		# A new tilt every so often, never quite on a beat, snapped to rather than swung to.
		_next_aim[i] -= delta
		if _next_aim[i] <= 0.0:
			_next_aim[i] = SHIVER_EVERY * _rng.randf_range(0.6, 1.5)
			_aims[i] = _rng.randf_range(-SHIVER, SHIVER)
		panel.rotation = lerpf(panel.rotation, _aims[i], 1.0 - exp(-SHIVER_SNAP * delta))
		_next_jolt[i] -= delta
		if _next_jolt[i] <= 0.0:
			_next_jolt[i] = _rng.randf_range(JOLT_EVERY.x, JOLT_EVERY.y)
			_jolts[i] = JOLT
		_jolts[i] = move_toward(_jolts[i], 0.0, JOLT / JOLT_SETTLE * delta)
		panel.scale = Vector2.ONE * (1.0 + _jolts[i])
		_flames[i].cover(panel.get_rect())


## Something to say instead of a pot, such as how long until this player is back on the floor.
func say(words: String) -> void:
	for part: Control in _parts:
		part.visible = false
	_note.visible = true
	_note.text = words


func _build() -> void:
	var sample := _text(Color.WHITE)
	sample.text = "0"
	var tall := sample.get_minimum_size().y + PAD_Y * 2.0
	sample.free()
	_end_pad = maxf((tall - ICON) * 0.5, 0.0)
	chips = _pill(Palette.CHIPS, CHIP_WIDTH, Icon.CHIP)
	_sign("×")
	mult = _pill(Palette.MULT, MULT_WIDTH, Icon.DIE)
	_sign("=")
	total = _text(TOTAL_INK)
	total.clip_text = false
	total.custom_minimum_size = Vector2(TOTAL_WIDTH, 0.0)
	add_child(total)
	_parts.append(total)
	_note = _text(Color(0.82, 0.82, 0.88))
	# Measured, like the signs: clipped, with nothing else on the line asking for room, it was
	# nought pixels wide, and a player waiting to come back was never shown how long for.
	_note.clip_text = false
	_note.visible = false
	add_child(_note)


## One half of the pot: a number in a pill of its own color, ending in what it counts.
func _pill(ink: Color, width: float, icon: Icon) -> Label:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", _skin(ink, FILL))
	var inside := HBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_theme_constant_override("separation", 4)
	box.add_child(inside)
	var end := Control.new()
	end.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end.custom_minimum_size = Vector2(ICON, ICON)
	end.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	end.draw.connect(_draw_end.bind(end, icon, ink))
	inside.add_child(end)
	var label := _text(ink.lightened(0.5))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Measured rather than clipped, so the pill asks for the room its number needs and the
	# minimum below is only the width it never goes under.
	label.clip_text = false
	label.custom_minimum_size = Vector2(width, 0.0)
	inside.add_child(label)
	add_child(box)
	_parts.append(box)
	_pills.append([box, label, ink])
	return label


## The chip or the die at the end of a pill.
func _draw_end(end: Control, icon: Icon, ink: Color) -> void:
	var box := Rect2(Vector2.ZERO, end.size)
	if icon == Icon.DIE:
		ChipArt.die(end, box.grow(-2.0))
	else:
		ChipArt.chip(end, box.get_center(), box.size.x * 0.5, ink.lightened(0.1), 6)


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


## A pill burning: solid, with a pale rim and a glow of its own color round it.
func _glowing_skin(ink: Color) -> StyleBoxFlat:
	var style := _skin(ink, BURN_FILL)
	style.border_color = ink.lerp(Color.WHITE, 0.55)
	style.set_border_width_all(2)
	style.shadow_color = Color(ink.lerp(Color.WHITE, 0.35), GLOW_ALPHA)
	style.shadow_size = GLOW
	return style


func _skin(ink: Color, fill: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(ink.r, ink.g, ink.b, fill)
	style.border_color = Color(ink.r, ink.g, ink.b, RIM)
	style.set_border_width_all(1)
	style.set_corner_radius_all(RADIUS)
	style.content_margin_left = _end_pad
	style.content_margin_right = PAD_X
	style.content_margin_top = PAD_Y
	style.content_margin_bottom = PAD_Y
	return style
