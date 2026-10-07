class_name NotesFolder
extends Control
## The folder of Kit's notes opened over a shade, STORY.md 7.2: a plain manila folder, the notes
## found clipped inside one to a page in the story's order, see [NotePage], the note on the right
## and the back of the page before it on the left, the pages turning the way the Highway Code's do.
## It opens at the first note not yet read, or at the first page; a page open for a second is read,
## and its pencil mark goes. Left and right, a click or a tap on a page, or the arrows under the
## folder turn it; Back, Put it away, or a click or a tap beside it puts it away. Nothing in it is
## the House's.

signal put_away

## The folder: a page each side of the spine, the gap at the spine and the manila round them.
const PAGE := NotePage.SIZE
const GUTTER := 16.0
const EDGE := 14.0
const FOLDER := Vector2(PAGE.x * 2.0 + GUTTER + EDGE * 2.0, PAGE.y + EDGE * 2.0)
const MANILA := Color(0.82, 0.69, 0.45)
const MANILA_DARK := Color(0.66, 0.53, 0.32)
## A turning leaf: how long it takes, how much room it is given over and under the folder to come
## up into, and how far off the eye is, in pages, as the theory book has it.
const TURN := 0.5
const LIFT_ROOM := 72.0
const TURN_DEPTH := 7.0
const TURN_SHADER: Shader = preload("res://scenes/tutorial/school/page_turn.gdshader")
## How long a page is open before it counts as read.
const READ_AFTER := 1.0
## Room kept round the folder on the screen, for the line under it.
const ROOM := Vector2(32.0, 124.0)
const SETTLE_MS := 150
## How wide the arrows either side of Put it away are.
const ARROW_WIDTH := 88.0
const AWAY_MOUSE := "Click beside the folder, or press %s, to put it away"
const AWAY_PAD := "Press %s to put it away"
const AWAY_TOUCH := "Tap a page to turn it, or beside the folder to put it away"

## Whose notes, the notes in order, and which is open.
var profile: Profile
var pages := PackedInt32Array()
var at := 0
var keyboard := true
var folder: Control
var away: Button
var away_line: Control

var _holder: Control
var _left: Control
var _right: Control
var _leaf: TextureRect
var _faces: Array[SubViewport] = []
var _turning: Tween
var _open_for := 0.0
var _shown_at := 0
## Whether the left shows the folder's inside rather than the back of a page.
var _left_cover := true


## The folder of [param of]'s notes up over [param parent], its lines drawn for a keyboard and
## mouse when [param on_keyboard] or for a pad otherwise.
static func open(parent: Node, of: Profile, on_keyboard: bool) -> NotesFolder:
	var view := NotesFolder.new()
	view.name = "NotesFolder"
	view.profile = of
	view.keyboard = on_keyboard
	view.pages = in_order(of.story)
	view.at = first_open(of.story)
	parent.add_child(view)
	return view


## The notes [param story] has found, in the story's order rather than the order found, and after
## the ending what the player kept of it at the back, STORY.md 7.2.
static func in_order(story: StoryState) -> PackedInt32Array:
	var found := story.notes.duplicate()
	found.sort()
	if story.ended():
		found.append(StoryNotes.FINAL_SLIP)
		found.append(StoryNotes.TERMS_CARD)
	return found


## Which page the folder opens at: the first new note's, or the first.
static func first_open(story: StoryState) -> int:
	var found := in_order(story)
	for i: int in found.size():
		if story.is_new(found[i]):
			return i
	return 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_shown_at = Time.get_ticks_msec()
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	_holder = Control.new()
	_holder.name = "Holder"
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_holder)
	_build_folder()
	column.add_child(_buttons())
	# The one button the cursor has, kept on it rather than walking off to the screen under.
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		away.set_focus_neighbor(side, away.get_path())
	away.focus_next = away.get_path()
	away.focus_previous = away.get_path()
	away_line = Control.new()
	away_line.custom_minimum_size = Vector2(0.0, 24.0)
	away_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(away_line)
	say_away()
	resized.connect(_fit)
	_fit()
	_show(at)
	gui_input.connect(_on_click)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	away.grab_focus()
	Audio.play_sfx(&"page", -6.0, 0.0)


func _build_folder() -> void:
	folder = Control.new()
	folder.name = "Folder"
	folder.size = FOLDER
	folder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder.draw.connect(_draw_folder)
	_holder.add_child(folder)
	_left = Control.new()
	_left.name = "Left"
	_left.position = Vector2(EDGE, EDGE)
	_left.size = PAGE
	_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left.draw.connect(_draw_left)
	folder.add_child(_left)
	_right = Control.new()
	_right.name = "Right"
	_right.position = Vector2(EDGE + PAGE.x + GUTTER, EDGE)
	_right.size = PAGE
	_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder.add_child(_right)
	folder.add_child(_leaf_over())


## The manila round the pages, a shade darker at the spine where it folds.
func _draw_folder() -> void:
	var back := StyleBoxFlat.new()
	back.bg_color = MANILA
	back.set_corner_radius_all(6)
	folder.draw_style_box(back, Rect2(Vector2.ZERO, FOLDER))
	var spine := FOLDER.x * 0.5
	folder.draw_rect(Rect2(spine - GUTTER * 0.5, 0.0, GUTTER, FOLDER.y), MANILA_DARK)


## The left of the spread: the folder's inside before the first page, the back of the page
## turned over after it.
func _draw_left() -> void:
	if _left_cover or pages.is_empty():
		_left.draw_rect(Rect2(Vector2.ZERO, PAGE).grow(-2.0), MANILA.lightened(0.06))
		return
	_left.draw_rect(Rect2(Vector2.ZERO, PAGE), NotePage.LEAF)
	_left.draw_rect(Rect2(Vector2.ZERO, PAGE), NotePage.LEAF_EDGE, false, 1.0)


## The turning leaf, its front a page and its back the back of one, each drawn into a picture of its
## own as a turn begins, as the theory book's are.
func _leaf_over() -> TextureRect:
	_leaf = TextureRect.new()
	_leaf.name = "Leaf"
	_leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leaf.position = Vector2(0.0, -LIFT_ROOM)
	_leaf.size = Vector2(FOLDER.x, FOLDER.y + LIFT_ROOM * 2.0)
	_leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_leaf.stretch_mode = TextureRect.STRETCH_SCALE
	_leaf.visible = false
	var turn := ShaderMaterial.new()
	turn.shader = TURN_SHADER
	turn.set_shader_parameter("rect_size", _leaf.size)
	turn.set_shader_parameter("hinge", FOLDER.x * 0.5)
	turn.set_shader_parameter("inner", GUTTER * 0.5)
	turn.set_shader_parameter("page", PAGE)
	turn.set_shader_parameter("top", LIFT_ROOM + EDGE)
	turn.set_shader_parameter("depth", TURN_DEPTH * PAGE.x)
	for side: String in ["front", "back"]:
		var face := SubViewport.new()
		face.name = side.capitalize()
		face.size = Vector2i(PAGE)
		face.transparent_bg = true
		face.disable_3d = true
		face.gui_disable_input = true
		face.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_leaf.add_child(face)
		_faces.append(face)
		turn.set_shader_parameter(side, face.get_texture())
	var blank := ColorRect.new()
	blank.color = NotePage.LEAF
	blank.size = PAGE
	_faces[1].add_child(blank)
	_leaf.texture = _faces[0].get_texture()
	_leaf.material = turn
	return _leaf


## Previous and next, either side of Put it away, which has the cursor: left and right turn the
## pages whatever has it.
func _buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var back := MenuTheme.button("‹", Type.HEADING)
	back.name = "Previous"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size.x = ARROW_WIDTH
	back.pressed.connect(turn.bind(-1))
	row.add_child(back)
	away = MenuTheme.button("Put it away", Type.BODY)
	away.name = "Away"
	away.pressed.connect(close)
	row.add_child(away)
	var on := MenuTheme.button("›", Type.HEADING)
	on.name = "Next"
	on.focus_mode = Control.FOCUS_NONE
	on.custom_minimum_size.x = ARROW_WIDTH
	on.pressed.connect(turn.bind(1))
	row.add_child(on)
	return row


## As big as the screen has room for, never bigger than drawn.
func _fit() -> void:
	if folder == null:
		return
	var room := get_viewport_rect().size - ROOM
	var scale_by := clampf(minf(room.x / FOLDER.x, room.y / FOLDER.y), 0.25, 1.0)
	folder.scale = Vector2.ONE * scale_by
	_holder.custom_minimum_size = FOLDER * scale_by


## Page [param index] open on the right, at once.
func _show(index: int) -> void:
	at = clampi(index, 0, maxi(pages.size() - 1, 0))
	for old: Node in _right.get_children():
		_right.remove_child(old)
		old.queue_free()
	if not pages.is_empty():
		_right.add_child(_page_of(at))
	_left_cover = at == 0
	_left.queue_redraw()
	_open_for = 0.0
	_mark_ends()


func _page_of(index: int) -> NotePage:
	var number := pages[index]
	return NotePage.make(number, profile, profile.story.is_new(number))


## The arrows greyed at the ends of the folder.
func _mark_ends() -> void:
	var row := away.get_parent()
	(row.get_node("Previous") as Button).disabled = at <= 0
	(row.get_node("Next") as Button).disabled = at >= pages.size() - 1


## Turns [param by] pages, one at a time, the leaf going over the spine: forward, the page open
## lifts off the right and lands on the left as the back of a page; back, the back on the left
## lifts and lands on the right as the page before.
func turn(by: int) -> void:
	var to := at + signi(by)
	if by == 0 or to < 0 or to >= pages.size() or is_turning():
		return
	var forward := by > 0
	var from := at
	var moving := _page_of(from if forward else to)
	for old: Node in _faces[0].get_children():
		_faces[0].remove_child(old)
		old.queue_free()
	_faces[0].add_child(moving)
	for face: SubViewport in _faces:
		face.render_target_update_mode = SubViewport.UPDATE_ONCE
	var material := _leaf.material as ShaderMaterial
	material.set_shader_parameter("angle", 0.0 if forward else PI)
	# Under the leaf, as it goes: forward, the next page on the right and the left as it was; back,
	# the left as it will be.
	if forward:
		_show(to)
		_left_cover = from == 0
	else:
		_left_cover = to == 0
	_left.queue_redraw()
	_turning = create_tween()
	# A frame for the faces to be drawn before the leaf shows.
	_turning.tween_interval(0.02)
	_turning.tween_callback(func() -> void: _leaf.visible = true)
	(
		_turning
		. tween_method(
			func(angle: float) -> void: material.set_shader_parameter("angle", angle),
			0.0 if forward else PI,
			PI if forward else 0.0,
			TURN
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	_turning.tween_callback(_landed.bind(to, forward))
	Audio.play_sfx(&"page", -8.0, 0.08)


func _landed(to: int, forward: bool) -> void:
	_leaf.visible = false
	_turning = null
	if forward:
		_left_cover = false
	else:
		_show(to)
	_left.queue_redraw()


func is_turning() -> bool:
	return _turning != null and _turning.is_valid()


## A page open for a second, and not turning, is read: written into the profile and saved, its
## mark gone.
func _process(delta: float) -> void:
	if pages.is_empty() or is_turning():
		return
	_open_for += delta
	var number := pages[at]
	if _open_for < READ_AFTER or not profile.story.is_new(number):
		return
	profile.story.notes_read.append(number)
	if not Game.is_headless():
		Game.settings.save_to_disk()
	for page: Node in _right.get_children():
		(page as NotePage).new = false
		(page as NotePage).queue_redraw()


## Left and right turn the pages, before the focus takes them for walking buttons; what was pressed
## says which lines to draw.
func _input(event: InputEvent) -> void:
	var was := keyboard
	keyboard = LicenseView.keyboard_after(event, keyboard)
	if was != keyboard:
		say_away()
	if event.is_action_pressed(&"ui_left"):
		get_viewport().set_input_as_handled()
		turn(-1)
	elif event.is_action_pressed(&"ui_right"):
		get_viewport().set_input_as_handled()
		turn(1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


## A click or a tap on the right page turns forward, on the left back, and beside the folder puts
## it away, once the view has settled.
func _on_click(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if not ((click != null and click.pressed) or (touch != null and touch.pressed)):
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() - _shown_at < SETTLE_MS:
		return
	var where: Vector2 = click.position if click != null else touch.position
	var on := folder.get_global_rect()
	on.position -= global_position
	if not on.has_point(where):
		close()
		return
	turn(1 if where.x >= on.get_center().x else -1)


## Put away: said, and gone.
func close() -> void:
	if is_queued_for_deletion():
		return
	put_away.emit()
	queue_free()


## The line under the folder: how to turn the pages and how to put it away, for the device in hand.
func say_away() -> void:
	if away_line == null or not is_instance_valid(away_line):
		return
	for old: Node in away_line.get_children():
		away_line.remove_child(old)
		old.queue_free()
	var ink := Color(0.72, 0.72, 0.78)
	var row: Control
	if TouchInput.enabled:
		row = MenuTheme.subtitle(AWAY_TOUCH, Type.LABEL)
	else:
		var glyph := InputGlyph.of_action(&"ui_cancel", keyboard, ink, Type.LABEL)
		var words := AWAY_MOUSE if keyboard else AWAY_PAD
		if glyph == null:
			row = MenuTheme.subtitle(
				words % InputActions.short_binding_text(&"ui_cancel", keyboard), Type.LABEL
			)
		else:
			row = InputHint.row(words, [glyph], ink, Type.LABEL)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	away_line.add_child(row)
