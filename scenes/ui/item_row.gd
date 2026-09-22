class_name ItemRow
extends VBoxContainer
## What a player is carrying and what is running on them, GAME.md 8.3.
##
## Two lines in one place, because they are one question: an item is picked up, held, played, and
## then it is doing something for a few seconds. The first line is the item in hand, with its own
## picture beside its name; the second is whatever it started, named the same and counting down.
## Neither line is there when there is nothing to say.

## The picture beside the name, and how fast the picture flicks through the others while the box
## a player just drove into is still opening.
const ICON := 30.0
const SPIN := 0.06
const SPINNING := Color(0.72, 0.72, 0.78)
## The countdown under a running effect.
const BAR := Vector2(112.0, 5.0)

var art: PowerUpArt.Picture
var label: Label
var running: Label
var clock: ProgressBar

var _held: HBoxContainer
var _effect: HBoxContainer


## Puts the two lines in [param parent], reading outward from the edge of the screen the block is
## on, the way the rest of the block does.
static func add_to(parent: Control, right: bool) -> ItemRow:
	var rows := ItemRow.new()
	rows.name = "ItemRow"
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 3)
	parent.add_child(rows)
	rows._build(right)
	return rows


## What the kart is holding and what it has running, every frame.
func show_kart(kart: Kart) -> void:
	_held.visible = kart.held_item != null
	if _held.visible:
		if kart.item_reveal_left > 0.0:
			var spin := PowerUpArt.known()
			art.id = spin[int(kart.item_reveal_left / SPIN) % spin.size()]
			art.ink = SPINNING
			label.text = ""
		else:
			art.id = kart.held_item.id
			art.ink = kart.held_item.color
			label.text = kart.held_item.display_name
			label.add_theme_color_override("font_color", kart.held_item.color)
	var longest := _longest(kart)
	_effect.visible = longest != null
	if longest == null:
		return
	running.text = longest.display_name
	running.add_theme_color_override("font_color", longest.color)
	clock.modulate = longest.color
	clock.value = 100.0 * longest.time_left / maxf(longest.duration, 0.001)


## The effect with the most time left on it that has a name to show. A kart can be carrying two at
## once; the one with longest to run is the one worth a line.
func _longest(kart: Kart) -> KartEffect:
	var best: KartEffect = null
	for effect: KartEffect in kart.effects:
		if effect.display_name.is_empty():
			continue
		if best == null or effect.time_left > best.time_left:
			best = effect
	return best


func _build(right: bool) -> void:
	var edge := BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	_held = HBoxContainer.new()
	_held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held.alignment = edge
	_held.add_theme_constant_override("separation", 7)
	art = PowerUpArt.picture(&"", Palette.NEON_MAGENTA)
	art.custom_minimum_size = Vector2(ICON, ICON)
	label = _name(right)
	Type.set_font(label, Type.STRONG, Type.BODY)
	if right:
		_held.add_child(label)
		_held.add_child(art)
	else:
		_held.add_child(art)
		_held.add_child(label)
	add_child(_held)
	_effect = HBoxContainer.new()
	_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effect.alignment = edge
	_effect.add_theme_constant_override("separation", 8)
	running = _name(right)
	Type.set_font(running, Type.numbers_text_font(), Type.LABEL)
	clock = _clock()
	if right:
		_effect.add_child(running)
		_effect.add_child(clock)
	else:
		_effect.add_child(clock)
		_effect.add_child(running)
	add_child(_effect)


func _name(right: bool) -> Label:
	var text := Label.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.clip_text = true
	text.custom_minimum_size = Vector2(150.0, 0.0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	HudText.shadowed(text)
	return text


## The time left on it, as a bar rather than as a number: what a player needs off this is whether
## there is a lot of it left or a little.
func _clock() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = BAR
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.value = 100.0
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.1, 0.13, 0.75)
	back.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 1.0, 1.0)
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	return bar
