class_name FitScroll
extends ScrollContainer
## The part of a pane that scrolls when the pane would not fit on the screen, GAME.md 8.5: as tall
## as what is in it while there is room for that, and no taller than the screen leaves once
## everything else in the pane has its room, the header over it and the buttons under it, which
## stay where they can be seen and pressed. A big UI scale on a short screen, a phone's say, is
## what runs out of room. It follows the cursor down what it holds, and a finger drags it. An edge
## with more past it is shaded darker, fading in, so it is plain there is more to scroll to.

## How much of the screen is kept clear above and below the pane, and how short it is ever made.
const EDGE := 12.0
const SHORTEST := 120.0
## How tall the shade at an edge with more past it is, and how far it has to be scrolled from an
## end before the shade is at its darkest.
const FADE := 30.0
const FADE_AFTER := 24.0

## The pane it is in, whose other parts it leaves room for; its parent when not given.
var pane: Control
## The shade at an edge with more past it: the dark of what it is laid on.
var fade := Color(0.0, 0.0, 0.0, 0.45):
	set = _set_fade

var _fades: Array[TextureRect] = []
## How far it reaches out either side, see [method reach].
var _sides := 0.0
var _over: Control
var _holder: MarginContainer
var _padding: MarginContainer


## A scroll holding [param content], in [param in_pane].
static func around(content: Control, in_pane: Control = null) -> FitScroll:
	var scroll := FitScroll.new()
	scroll.pane = in_pane
	scroll.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return scroll


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	_set_fade(fade)
	get_viewport().size_changed.connect(fit)
	for child: Node in get_children():
		if child is Control:
			(child as Control).minimum_size_changed.connect(fit)
	fit.call_deferred()


## The scroll in a holder with its shades laid over it, to be put in the pane in its place: the
## shades follow the scroll wherever the pane is and however it is scaled.
func shaded() -> Container:
	var holder := MarginContainer.new()
	holder.name = name + "Holder"
	_holder = holder
	# What it holds, in padding of its own, which [method reach] gives the gaps round it to.
	var content := get_child(0) as Control
	remove_child(content)
	_padding = MarginContainer.new()
	_padding.name = "Padding"
	_padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_padding.add_child(content)
	add_child(_padding)
	holder.add_child(self)
	_over = Control.new()
	_over.name = "Shades"
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_over)
	for down: bool in [false, true]:
		var shade := TextureRect.new()
		shade.name = "FadeBottom" if down else "FadeTop"
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.flip_v = down
		shade.set_anchors_and_offsets_preset(
			Control.PRESET_BOTTOM_WIDE if down else Control.PRESET_TOP_WIDE
		)
		if down:
			shade.offset_top = -FADE
		else:
			shade.offset_bottom = FADE
		shade.visible = false
		_over.add_child(shade)
		_fades.append(shade)
	_set_fade(fade)
	return holder


## Reaches [param above] up over the gap over it and [param below] down over the one under it, to
## the lines either side, with what it holds padded by as much, so at rest everything stands where
## it did and scrolled the lines run right up to them, the shades against them rather than
## beginning in the empty paper of the gap; and [param sides] out over the gaps beside it, so what
## hangs off the side of what it holds, a NEW tag off a button's corner, is not cut off there, the
## shades staying over what it holds. After [method shaded].
func reach(above: float, below: float, sides := 0.0) -> void:
	if _holder == null:
		return
	_sides = sides
	_holder.add_theme_constant_override("margin_top", -roundi(above))
	_holder.add_theme_constant_override("margin_bottom", -roundi(below))
	_padding.add_theme_constant_override("margin_top", roundi(above))
	_padding.add_theme_constant_override("margin_bottom", roundi(below))
	for side: String in ["margin_left", "margin_right"]:
		_holder.add_theme_constant_override(side, -roundi(sides))
		_padding.add_theme_constant_override(side, roundi(sides))
	fit()


## Sizes it again for what it holds and the room there is on the screen.
func fit() -> void:
	if not is_inside_tree() or get_child_count() == 0:
		return
	var content := get_child(0) as Control
	if content == null:
		return
	var want := content.get_combined_minimum_size().y
	var holder := pane if pane != null else get_parent_control()
	var around := 0.0
	if holder != null:
		around = maxf(holder.get_combined_minimum_size().y - custom_minimum_size.y, 0.0)
	var room := get_viewport_rect().size.y - around - EDGE * 2.0
	var tall := minf(want, maxf(room, SHORTEST))
	if not is_equal_approx(tall, custom_minimum_size.y):
		custom_minimum_size.y = tall


func _process(_delta: float) -> void:
	_place_fades()


## The shades over the top and the bottom, as dark as there is more past each.
func _place_fades() -> void:
	if _fades.is_empty():
		return
	var bar := get_v_scroll_bar()
	var past := maxf(bar.max_value - bar.page - scroll_vertical, 0.0)
	var above := clampf(scroll_vertical / FADE_AFTER, 0.0, 1.0)
	var below := clampf(past / FADE_AFTER, 0.0, 1.0)
	for i: int in 2:
		var shade := _fades[i]
		# Clear of the scroll bar, which has its own say about where the page is.
		shade.offset_left = _sides
		shade.offset_right = -_sides - (bar.size.x if bar.visible else 0.0)
		shade.modulate.a = above if i == 0 else below
		shade.visible = shade.modulate.a > 0.01


func _set_fade(value: Color) -> void:
	fade = value
	if _fades.is_empty():
		return
	var ramp := Gradient.new()
	ramp.set_color(0, fade)
	ramp.set_color(1, Color(fade, 0.0))
	var made := GradientTexture2D.new()
	made.gradient = ramp
	made.fill_from = Vector2(0.0, 0.0)
	made.fill_to = Vector2(0.0, 1.0)
	made.width = 4
	made.height = 64
	for shade: TextureRect in _fades:
		shade.texture = made
