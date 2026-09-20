class_name InputHint
extends RefCounted
## Lines of hint built out of [InputGlyph] pictures and words, GAME.md 8.3.
##
## Every hint in the game names a binding, and the bindings are the player's rather than the
## game's, so the lines are templates with a gap per binding: "%s drift   %s nitro". This fills
## the gaps with pictures of whatever those two are bound to on whichever device the player last
## touched, and puts the words in between.
##
## The same row goes into the world as goes onto the screen. A hint on a kart or on a wall is the
## row rendered by a [SubViewport] and shown on a billboarded sprite, so there is one piece of
## layout code and 3D never has to be told how to draw a key cap.

## Air between a picture and the word it belongs to, and between one pair and the next.
const WORD_GAP := 5
const GROUP_GAP := 15.0
const FONT_SIZE := 15
## The card a hint hanging in the world sits on, so it is readable over felt, walls and karts
## alike rather than only over whatever it happened to be tested against.
const CARD_BG := Color(0.05, 0.05, 0.07, 0.72)
const CARD_PAD := 12.0


## One action as a picture, or null when nothing is bound to it on that device.
static func glyph(action: StringName, keyboard: bool, ink: Color, size: int) -> Control:
	return InputGlyph.of_action(action, keyboard, ink, size)


## Two actions that are the two ends of one control, GAME.md 8.3. On a pad that is one stick and
## it is drawn as one; on a keyboard they really are two keys and both are drawn.
static func pair(
	left: StringName, right: StringName, keyboard: bool, ink: Color, size: int
) -> Control:
	if not keyboard and not InputActions.shared_stick(left, right).is_empty():
		var stick := glyph(left, keyboard, ink, size) as InputGlyph
		if stick != null:
			# Both halves of the axis are in play here, so the stick is drawn sitting in the
			# middle of its gate rather than pushed one way.
			stick.both_ways = true
			stick.along = stick.along.abs()
		return stick
	var both := HBoxContainer.new()
	both.mouse_filter = Control.MOUSE_FILTER_IGNORE
	both.add_theme_constant_override("separation", 3)
	for action: StringName in [left, right]:
		var one := glyph(action, keyboard, ink, size)
		if one != null:
			both.add_child(one)
	return both


## A line of hint: [param template] split on its gaps with [param parts] dropped into them. A gap
## with nothing bound to it is left out along with the words that went with it, rather than
## printed as a dash.
static func row(template: String, parts: Array, ink: Color, size: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", WORD_GAP)
	var chunks := template.split("%s")
	for i: int in chunks.size():
		var part: Control = parts[i - 1] if i > 0 and i <= parts.size() else null
		if part != null:
			if box.get_child_count() > 0:
				box.add_child(_gap())
			box.add_child(part)
		var words: String = chunks[i].strip_edges()
		if not words.is_empty() and (i == 0 or part != null):
			box.add_child(_words(words, ink, size))
	return box


## The same row on a dark card, for a hint that hangs in the world, where what is behind it is
## whatever colour that stretch of the arena happens to be.
static func card(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.set_corner_radius_all(10)
	style.content_margin_left = CARD_PAD
	style.content_margin_right = CARD_PAD
	style.content_margin_top = CARD_PAD * 0.6
	style.content_margin_bottom = CARD_PAD * 0.6
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(content)
	return panel


## The same row hung in the world instead of on the screen: rendered by a viewport of its own and
## shown on a sprite that always faces the camera, the way the labels it replaces did.
static func billboard(content: Control, pixel_size: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Hint"
	var viewport := SubViewport.new()
	viewport.name = "Render"
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(viewport)
	viewport.add_child(content)
	# Sized after a layout pass rather than now: a container works out how big it is when it is
	# sorted, which has not happened yet, and a viewport cut to the answer from before that is a
	# hint with its last word chopped off.
	content.minimum_size_changed.connect(_fit.bind(viewport, content))
	_fit.call_deferred(viewport, content)
	var sprite := Sprite3D.new()
	sprite.name = "Face"
	sprite.texture = viewport.get_texture()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.shaded = false
	sprite.double_sided = true
	sprite.pixel_size = pixel_size
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	holder.add_child(sprite)
	return holder


## Cuts the viewport to whatever the row turned out to be.
static func _fit(viewport: SubViewport, content: Control) -> void:
	if not is_instance_valid(viewport) or not is_instance_valid(content):
		return
	var wanted := content.get_combined_minimum_size()
	var cut := Vector2i(maxi(ceili(wanted.x), 1), maxi(ceili(wanted.y), 1))
	if viewport.size == cut:
		return
	viewport.size = cut
	content.size = Vector2(cut)


static func _gap() -> Control:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.custom_minimum_size = Vector2(GROUP_GAP - WORD_GAP * 2, 0.0)
	return spacer


static func _words(text: String, ink: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", ink)
	return label
