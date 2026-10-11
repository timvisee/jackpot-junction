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
const CARD_BG := Color(0.075, 0.07, 0.094, 0.78)
const CARD_PAD := 12.0
## The render layer a hint hung in the world is drawn on, the last of them, apart from the room:
## a camera filming the room for a picture, the Showroom's, leaves it out, see [ShowroomView].
const WORLD_LAYER := 1 << 19


## One action as a picture, or null when nothing is bound to it on that device. On a touch screen
## it is the button on the screen, GAME.md 4.2, whatever the keys and the pads have it bound to.
static func glyph(action: StringName, keyboard: bool, ink: Color, size: int) -> Control:
	if TouchInput.enabled:
		return InputGlyph.of_touch(action, ink, size)
	return InputGlyph.of_action(action, keyboard, ink, size)


## Two actions that are the two ends of one control, GAME.md 8.3. On a pad that is one stick and
## it is drawn as one; on a keyboard they really are two keys and both are drawn.
static func pair(
	left: StringName, right: StringName, keyboard: bool, ink: Color, size: int
) -> Control:
	# Steering on a touch screen is the one stick under the left thumb.
	if TouchInput.enabled:
		return glyph(left, keyboard, ink, size)
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


## The push of simple driving, GAME.md 4.2, as the one control it is: the stick pushed every way on
## a pad or a touch screen, and on a keyboard the four keys, up, left, down and right, the way
## WASD is written. A pad whose two halves are on different sticks gets both pairs.
static func way(keyboard: bool, ink: Color, size: int) -> Control:
	var left := InputActions.STEER_LEFT
	var right := InputActions.STEER_RIGHT
	var up := InputActions.DRIVE_UP
	var down := InputActions.DRIVE_DOWN
	var across := InputActions.shared_stick(left, right)
	var one_stick := not across.is_empty() and across == InputActions.shared_stick(up, down)
	if TouchInput.enabled or (not keyboard and one_stick):
		var stick := glyph(left, keyboard, ink, size) as InputGlyph
		if stick != null:
			stick.every_way = true
		return stick
	var keys := HBoxContainer.new()
	keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keys.add_theme_constant_override("separation", 3)
	var actions: Array[StringName] = [up, left, down, right]
	if not keyboard:
		keys.add_child(pair(left, right, keyboard, ink, size))
		keys.add_child(pair(up, down, keyboard, ink, size))
		return keys
	for action: StringName in actions:
		var one := glyph(action, keyboard, ink, size)
		if one != null:
			keys.add_child(one)
	return keys


## A line of hint: [param template] split on its gaps with [param parts] dropped into them. A gap
## with nothing bound to it is left out along with the words that went with it, rather than
## printed as a dash.
##
## A run of spaces in the template is where one group ends and the next begins, and gets the wide
## gap: "%s drift   %s nitro". A single space is a single space, so a sentence with a button in
## the middle of it -- "Press %s or %s to join" -- reads as a sentence, not as a list with a hole
## in front of every button.
static func row(template: String, parts: Array, ink: Color, size: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", WORD_GAP)
	var chunks := template.split("%s")
	for i: int in chunks.size():
		var part: Control = parts[i - 1] if i > 0 and i <= parts.size() else null
		if part != null:
			if box.get_child_count() > 0 and chunks[i - 1].ends_with("  "):
				box.add_child(_gap())
			box.add_child(part)
		var words: String = chunks[i].strip_edges()
		if not words.is_empty() and (i == 0 or part != null):
			box.add_child(_words(words, ink, size))
	# A part the template has no gap for is freed, rather than left out of the tree for good and
	# reported as leaked when the game quits.
	for i: int in range(chunks.size() - 1, parts.size()):
		var spare: Variant = parts[i]
		if spare is Node:
			(spare as Node).free()
	return box


## What a row of [param actions] drawn for [param keyboard] depends on: the scheme and what each
## is bound to. A row built again only when this changes is not rebuilt, node by node, every frame
## it is up.
static func stamp(actions: Array[StringName], keyboard: bool) -> String:
	var bound: Array[String] = []
	for action: StringName in actions:
		bound.append(InputActions.short_binding_text(action, keyboard))
	return "%s|%s" % [keyboard, "/".join(bound)]


## The same row on a dark card, for a hint that hangs in the world, where what is behind it is
## whatever color that stretch of the arena happens to be: the house's tag, GAME.md 8.1a, a small
## ticket of its stock with a foil hairline inside its edge, as the HUD's smaller pieces stand on.
static func card(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := TicketStyle.cut(CARD_BG, 7.0, CARD_PAD, CARD_PAD * 0.6)
	style.frame = Color(HouseTheme.FOIL, 0.22)
	style.frame_inset = 3.0
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(content)
	return panel


## The same row hung in the world instead of on the screen: rendered by a viewport of its own and
## shown on a sprite that always faces the camera, the way the labels it replaces did. The picture
## is drawn once, and again only when the row changes size: nothing on it moves, and a viewport
## drawn every frame is a whole pass of the renderer each frame for each sign and hint up.
static func billboard(content: Control, pixel_size: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Hint"
	var viewport := SubViewport.new()
	viewport.name = "Render"
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	holder.add_child(viewport)
	# Sized once the row is ready in the tree rather than now, with its minimum size worked out,
	# and again whenever that changes: a viewport cut to the answer from before that is a hint
	# with its last word chopped off. On ready rather than deferred, so a hint freed before the
	# end of the frame leaves no call behind to find it gone.
	content.ready.connect(_fit.bind(viewport, content), CONNECT_ONE_SHOT)
	content.minimum_size_changed.connect(_fit.bind(viewport, content))
	viewport.add_child(content)
	var sprite := Sprite3D.new()
	sprite.name = "Face"
	sprite.texture = viewport.get_texture()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.shaded = false
	sprite.double_sided = true
	sprite.pixel_size = pixel_size
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.layers = WORLD_LAYER
	holder.add_child(sprite)
	return holder


## Draws [param content] on [param holder], a billboard from [method billboard], in place of what
## it showed: the viewport and the sprite stay, so a hint that changes its words is not a new
## render target each time it does.
static func redraw(holder: Node3D, content: Control) -> void:
	var viewport: SubViewport = holder.get_node("Render")
	for old: Node in viewport.get_children():
		viewport.remove_child(old)
		old.queue_free()
	content.ready.connect(_fit.bind(viewport, content), CONNECT_ONE_SHOT)
	content.minimum_size_changed.connect(_fit.bind(viewport, content))
	viewport.add_child(content)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Cuts the viewport to whatever the row turned out to be, and draws it again.
static func _fit(viewport: SubViewport, content: Control) -> void:
	if not is_instance_valid(viewport) or not is_instance_valid(content):
		return
	var wanted := content.get_combined_minimum_size()
	var cut := Vector2i(maxi(ceili(wanted.x), 1), maxi(ceili(wanted.y), 1))
	if viewport.size == cut:
		return
	viewport.size = cut
	content.size = Vector2(cut)
	# Drawn again at the new size, once.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


static func _gap() -> Control:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.custom_minimum_size = Vector2(GROUP_GAP - WORD_GAP * 2, 0.0)
	return spacer


## The words between two controls, with the game's own words in them marked, see [Terms].
static func _words(text: String, ink: Color, size: int) -> Control:
	return Terms.words(text, ink, size)
