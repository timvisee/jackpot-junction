class_name NotesFolder
extends Control
## The folder of Kit's notes opened over a shade, STORY.md 7.2: a plain manila folder, the notes
## found clipped inside in the story's order, one on each side of a leaf, see [NotePage], so an open
## spread shows two, the leaves turning the way the Highway Code's do. It comes out from where it
## peeked in, its cover, see [FolderCover], swinging open over the spine, and opens on its first
## spread, turning quickly on to the first note not yet read, which a press cuts short. A spread
## open for a second is read, and its pencil marks go. Left and right, a click or a tap on a page,
## or the arrows under the folder turn it; a click or a tap on a note, or Look closer, which has
## the cursor, takes it off its page for a closer look, see [NoteView]; Back, Put it away, or a
## click or a tap beside it shuts it and sends it back where it came from. Nothing in it is the
## House's.

signal put_away

## The folder: a page each side of the spine, the gap at the spine and the manila round them.
const PAGE := NotePage.SIZE
const GUTTER := 16.0
const EDGE := 14.0
const FOLDER := Vector2(PAGE.x * 2.0 + GUTTER + EDGE * 2.0, PAGE.y + EDGE * 2.0)
## The cover, the right half of the folder, hinged at the spine.
const COVER := Vector2(FOLDER.x * 0.5, FOLDER.y)
const MANILA := Color(0.82, 0.69, 0.45)
const MANILA_DARK := Color(0.66, 0.53, 0.32)
const MANILA_INSIDE := Color(0.86, 0.75, 0.53)
## A turning leaf: how long it takes, how much room it is given over and under the folder to come
## up into, and how far off the eye is, in pages, as the theory book has it.
const TURN := 0.5
const LIFT_ROOM := 72.0
const TURN_DEPTH := 7.0
const TURN_SHADER: Shader = preload("res://scenes/tutorial/school/page_turn.gdshader")
## Coming out and going back: the slide from the edge, and the cover's swing over the spine.
const SLIDE := 0.4
const SWING := 0.5
## Turning on to the first new note after opening: the whole of it at most, and how long a leaf
## takes at the slowest and the fastest, the leaves quickening as they go.
const FLIP_AT_MOST := 1.0
const FLIP_SLOWEST := 0.28
const FLIP_FASTEST := 0.07
## How long a spread is open before its notes count as read.
const READ_AFTER := 1.0
## Room kept round the folder on the screen, for the line under it.
const ROOM := Vector2(32.0, 124.0)
const SETTLE_MS := 150
## How wide the arrows either side of Put it away are.
const ARROW_WIDTH := 88.0
const AWAY_MOUSE := "Click beside the folder, or press %s, to put it away"
const AWAY_PAD := "Press %s to put it away"
const AWAY_TOUCH := "Tap a page to turn it, or beside the folder to put it away"
const LOOK_WORD := "Look closer"

## Whose notes, the notes in order, and which spread is open: 0 the first, the inside of the cover
## on the left and the first note on the right.
var profile: Profile
var pages := PackedInt32Array()
var at := 0
var keyboard := true
## What it peeked in as, kept out of sight while it is out, and where that is on the screen, for
## coming out of and going back to; none for the edge.
var peek: Control
var from := Rect2()
var folder: Control
var away: Button
var look: Button
var away_line: Control
## A note taken off its page for a closer look, while it is.
var view: NoteView

var _holder: Control
var _buttons_row: Control
var _shade: ColorRect
var _left: Control
var _right: Control
var _leaf: TextureRect
var _faces: Array[SubViewport] = []
var _cover: TextureRect
var _turning: Tween
var _moving: Tween
var _open_for := 0.0
var _shown_at := 0
## The spread it turns on to once open, and whether it is turning on to it now.
var _target := 0
var _flipping := false
## Whether the cover is down over the pages: shut, coming out or going back.
var _shut := true
var _closing := false


## The folder of [param of]'s notes up over [param parent], its lines drawn for a keyboard and
## mouse when [param on_keyboard] or for a pad otherwise, coming out of [param peeked], the folder
## peeking in on the screen, or from the left edge when it is not given.
static func open(
	parent: Node, of: Profile, on_keyboard: bool, peeked: Control = null
) -> NotesFolder:
	var view := NotesFolder.new()
	view.name = "NotesFolder"
	view.profile = of
	view.keyboard = on_keyboard
	view.peek = peeked
	if peeked != null:
		view.from = peeked.get_global_rect()
	view.pages = in_order(of.story)
	view._target = first_open(of.story)
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


## The spread the folder turns on to: the first new note's, or the first.
static func first_open(story: StoryState) -> int:
	var found := in_order(story)
	for i: int in found.size():
		if story.is_new(found[i]):
			return spread_of(i)
	return 0


## The spread page [param index] is on: the first page on the right of the first spread, then two
## to a spread, the back of a leaf on the left and the front of the next on the right.
static func spread_of(index: int) -> int:
	return (index + 1) / 2


## How many spreads [param count] pages make.
static func spreads(count: int) -> int:
	return count / 2 + 1


## The pages on [param spread]'s left and right, -1 for none: the inside of the cover on the left of
## the first, the inside of the back on the right of the last when its pages run out.
static func left_of(spread: int) -> int:
	return spread * 2 - 1


static func right_of(spread: int) -> int:
	return spread * 2


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_shown_at = Time.get_ticks_msec()
	_shade = ColorRect.new()
	_shade.color = Color(0.0, 0.0, 0.0, 0.72)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
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
	_buttons_row = _buttons()
	column.add_child(_buttons_row)
	# The one button the cursor has, kept on it rather than walking off to the screen under.
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		look.set_focus_neighbor(side, look.get_path())
	look.focus_next = look.get_path()
	look.focus_previous = look.get_path()
	away_line = Control.new()
	away_line.custom_minimum_size = Vector2(0.0, 24.0)
	away_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(away_line)
	say_away()
	resized.connect(_fit)
	_fit()
	_show(0)
	gui_input.connect(_on_click)
	_shade.modulate.a = 0.0
	_buttons_row.modulate.a = 0.0
	away_line.modulate.a = 0.0
	look.grab_focus()
	# Hidden until the layout has put it where it opens, so it can start from where it peeked in.
	folder.modulate.a = 0.0
	_come_out.call_deferred()


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
	_left.draw.connect(_draw_inside.bind(_left))
	folder.add_child(_left)
	_right = Control.new()
	_right.name = "Right"
	_right.position = Vector2(EDGE + PAGE.x + GUTTER, EDGE)
	_right.size = PAGE
	_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right.draw.connect(_draw_inside.bind(_right))
	folder.add_child(_right)
	folder.add_child(_leaf_over())
	folder.add_child(_cover_over())


## The manila round the pages, a shade darker at the spine where it folds: only the back half while
## the cover is down over it, since the front half is the cover, swung over.
func _draw_folder() -> void:
	var back := StyleBoxFlat.new()
	back.bg_color = MANILA
	back.set_corner_radius_all(6)
	var spine := FOLDER.x * 0.5
	if _shut:
		folder.draw_style_box(back, Rect2(spine, 0.0, spine, FOLDER.y))
		return
	folder.draw_style_box(back, Rect2(Vector2.ZERO, FOLDER))
	folder.draw_rect(Rect2(spine - GUTTER * 0.5, 0.0, GUTTER, FOLDER.y), MANILA_DARK)


## The inside of the folder where a side has no page: the cover's inside on the left of the first
## spread, the back's on the right of the last.
func _draw_inside(side: Control) -> void:
	if side.get_child_count() == 0 and not _shut:
		side.draw_rect(Rect2(Vector2.ZERO, PAGE).grow(-2.0), MANILA_INSIDE)


## A turning leaf: its front a page and its back the page on the other side of it, each drawn into
## a picture of its own as a turn begins, as the theory book's are.
func _leaf_over() -> TextureRect:
	_leaf = _turning_rect("Leaf", PAGE, EDGE, GUTTER * 0.5)
	_faces = _faces_of(_leaf, PAGE)
	return _leaf


## The cover, swinging open over the spine and shut again: its front, see [FolderCover], and its
## manila inside.
func _cover_over() -> TextureRect:
	_cover = _turning_rect("Cover", COVER, 0.0, 0.0)
	var faces := _faces_of(_cover, COVER)
	var front := Control.new()
	front.size = COVER
	front.draw.connect(
		func() -> void:
			var shape := StyleBoxFlat.new()
			shape.bg_color = MANILA
			shape.set_corner_radius_all(6)
			shape.border_color = MANILA_DARK.darkened(0.1)
			shape.set_border_width_all(1)
			front.draw_style_box(shape, Rect2(Vector2.ZERO, COVER))
			FolderCover.draw_front(front, Rect2(Vector2.ZERO, COVER))
	)
	faces[0].add_child(front)
	var inside := ColorRect.new()
	inside.color = MANILA
	inside.size = COVER
	faces[1].add_child(inside)
	for face: SubViewport in faces:
		face.render_target_update_mode = SubViewport.UPDATE_ONCE
	_cover.visible = true
	(_cover.material as ShaderMaterial).set_shader_parameter("angle", 0.0)
	return _cover


## A rect over the folder for something [param size] big to turn over the spine in, standing
## [param inner] off it with its top [param top] down from the folder's.
func _turning_rect(named: String, size_of: Vector2, top: float, inner: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = named
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2(0.0, -LIFT_ROOM)
	rect.size = Vector2(FOLDER.x, FOLDER.y + LIFT_ROOM * 2.0)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.visible = false
	var turn := ShaderMaterial.new()
	turn.shader = TURN_SHADER
	turn.set_shader_parameter("rect_size", rect.size)
	turn.set_shader_parameter("hinge", FOLDER.x * 0.5)
	turn.set_shader_parameter("inner", inner)
	turn.set_shader_parameter("page", size_of)
	turn.set_shader_parameter("top", LIFT_ROOM + top)
	turn.set_shader_parameter("depth", TURN_DEPTH * PAGE.x)
	rect.material = turn
	return rect


## The front and back of [param rect], each a picture [param size_of] big.
func _faces_of(rect: TextureRect, size_of: Vector2) -> Array[SubViewport]:
	var made: Array[SubViewport] = []
	var turn := rect.material as ShaderMaterial
	for side: String in ["front", "back"]:
		var face := SubViewport.new()
		face.name = side.capitalize()
		face.size = Vector2i(size_of)
		face.transparent_bg = true
		face.disable_3d = true
		face.gui_disable_input = true
		face.render_target_update_mode = SubViewport.UPDATE_DISABLED
		rect.add_child(face)
		made.append(face)
		turn.set_shader_parameter(side, face.get_texture())
	rect.texture = made[0].get_texture()
	return made


## Previous and next either side of Look closer, which has the cursor, and Put it away: left and
## right turn the pages whatever has it.
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
	look = MenuTheme.button(LOOK_WORD, Type.BODY)
	look.name = "Look"
	look.pressed.connect(look_closer)
	row.add_child(look)
	away = MenuTheme.button("Put it away", Type.BODY)
	away.name = "Away"
	away.focus_mode = Control.FOCUS_NONE
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
	_holder.custom_minimum_size = FOLDER * _fit_scale()
	if _moving == null or not _moving.is_valid():
		folder.scale = Vector2.ONE * _fit_scale()
		folder.position = Vector2.ZERO


func _fit_scale() -> float:
	var room := get_viewport_rect().size - ROOM
	return clampf(minf(room.x / FOLDER.x, room.y / FOLDER.y), 0.25, 1.0)


## Where the shut folder starts and ends up, in the holder: the cover's middle on the folder it
## peeked in as, at that size, or off the left edge of the screen when there was none.
func _peek_place() -> Array:
	var size_by := _fit_scale()
	var middle := Vector2(-COVER.x * size_by, get_viewport_rect().size.y * 0.7)
	if from.size != Vector2.ZERO:
		size_by = from.size.x / COVER.x
		middle = from.get_center()
	var local := _holder.get_global_transform().affine_inverse() * middle
	var corner := local - Vector2(FOLDER.x * 0.75, FOLDER.y * 0.5) * size_by
	return [corner, size_by]


## Out from where it peeked in, shut, then the cover swung open over the spine; then on to the
## first new note.
func _come_out() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var start := _peek_place()
	folder.position = start[0]
	folder.scale = Vector2.ONE * float(start[1])
	folder.modulate.a = 1.0
	# Out of where it peeked in: the peek goes until it is back.
	if peek != null and is_instance_valid(peek):
		peek.self_modulate.a = 0.0
		var shown := peek
		tree_exiting.connect(
			func() -> void:
				if is_instance_valid(shown):
					shown.self_modulate.a = 1.0
		)
	_moving = create_tween()
	_moving.set_parallel(true)
	_moving.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_moving.tween_property(folder, "position", Vector2.ZERO, SLIDE)
	_moving.tween_property(folder, "scale", Vector2.ONE * _fit_scale(), SLIDE)
	_moving.tween_property(_shade, "modulate:a", 1.0, SLIDE)
	_moving.chain().tween_callback(_swing.bind(true))


## The cover over the spine: open, it lands as the inside of the cover on the left; shut, it comes
## back down over the pages.
func _swing(to_open: bool) -> void:
	var material := _cover.material as ShaderMaterial
	_cover.visible = true
	if not to_open:
		_shut = true
		_left.visible = false
		folder.queue_redraw()
	var swing := create_tween()
	(
		swing
		. tween_method(
			func(angle: float) -> void: material.set_shader_parameter("angle", angle),
			0.0 if to_open else PI,
			PI if to_open else 0.0,
			SWING
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	if to_open:
		swing.tween_callback(_opened)
		var fade := create_tween().set_parallel(true)
		fade.tween_property(_buttons_row, "modulate:a", 1.0, SWING)
		fade.tween_property(away_line, "modulate:a", 1.0, SWING)
	else:
		swing.tween_callback(_go_back)
	Audio.play_sfx(&"folder_open" if to_open else &"folder_shut", -4.0, 0.05)


func _opened() -> void:
	_shut = false
	_cover.visible = false
	_left.visible = true
	folder.queue_redraw()
	_left.queue_redraw()
	_right.queue_redraw()
	_open_for = 0.0
	if _target > at:
		_flipping = true
		_flip_on()


## The next leaf of the turning on to the first new note, quicker than the one before.
func _flip_on() -> void:
	if not _flipping or at >= _target:
		_flipping = false
		return
	var leaves := _target
	var each := clampf(FLIP_AT_MOST / float(leaves), FLIP_FASTEST, FLIP_SLOWEST)
	var quicken := lerpf(1.0, 0.6, float(at) / float(maxi(leaves - 1, 1)))
	turn(1, each * quicken)


## Straight to the first new note, the turning on to it cut short.
func skip_flip() -> void:
	if not _flipping:
		return
	_flipping = false
	if _turning != null and _turning.is_valid():
		_turning.kill()
	_turning = null
	_leaf.visible = false
	_show(_target)


## Spread [param spread] open, at once.
func _show(spread: int) -> void:
	at = clampi(spread, 0, spreads(pages.size()) - 1)
	_set_side(_left, left_of(at))
	_set_side(_right, right_of(at))
	_open_for = 0.0
	_mark_ends()


## [param side] showing page [param index], or the folder's inside where there is none.
func _set_side(side: Control, index: int) -> void:
	for old: Node in side.get_children():
		side.remove_child(old)
		old.queue_free()
	if index >= 0 and index < pages.size():
		side.add_child(_page_of(index))
	side.queue_redraw()


func _page_of(index: int) -> NotePage:
	var number := pages[index]
	return NotePage.make(number, profile, profile.story.is_new(number))


## The arrows greyed at the ends of the folder.
func _mark_ends() -> void:
	var row := away.get_parent()
	(row.get_node("Previous") as Button).disabled = at <= 0
	(row.get_node("Next") as Button).disabled = at >= spreads(pages.size()) - 1


## Turns [param by] spreads, a leaf at a time, over the spine, taking [param takes]: forward, the
## leaf on the right lifts off and lands on the left, its back up; back, the leaf on the left lifts
## and lands on the right, its front up.
func turn(by: int, takes := TURN) -> void:
	var to := at + signi(by)
	if by == 0 or to < 0 or to >= spreads(pages.size()) or is_turning() or _shut:
		return
	var forward := by > 0
	var leaf := at if forward else to
	_set_face(_faces[0], right_of(leaf))
	_set_face(_faces[1], left_of(leaf + 1))
	for face: SubViewport in _faces:
		face.render_target_update_mode = SubViewport.UPDATE_ONCE
	var material := _leaf.material as ShaderMaterial
	material.set_shader_parameter("angle", 0.0 if forward else PI)
	# Under the leaf as it goes: forward, the next spread's right and this one's left; back, the
	# spread before's left and this one's right.
	if forward:
		_set_side(_right, right_of(to))
	else:
		_set_side(_left, left_of(to))
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
			takes
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	_turning.tween_callback(_landed.bind(to))
	Audio.play_sfx(&"leaf", -6.0 if takes >= TURN else -12.0, 0.08)


## A face of the turning leaf showing page [param index], or bare paper where there is none.
func _set_face(face: SubViewport, index: int) -> void:
	for old: Node in face.get_children():
		face.remove_child(old)
		old.queue_free()
	if index >= 0 and index < pages.size():
		face.add_child(_page_of(index))
	else:
		var blank := ColorRect.new()
		blank.color = NotePage.LEAF
		blank.size = PAGE
		face.add_child(blank)


func _landed(to: int) -> void:
	_leaf.visible = false
	_turning = null
	_show(to)
	if _flipping:
		_flip_on()


func is_turning() -> bool:
	return _turning != null and _turning.is_valid()


## Whether it is coming out, turning on to the first new note, turning or going back.
func is_busy() -> bool:
	return _shut or _flipping or is_turning() or _closing


## A spread open for a second, and not turning, is read: its new notes written into the profile and
## saved, their marks gone.
func _process(delta: float) -> void:
	if pages.is_empty() or is_busy():
		return
	_open_for += delta
	if _open_for < READ_AFTER:
		return
	var shown: Array[int] = []
	for index: int in [left_of(at), right_of(at)]:
		if index >= 0 and index < pages.size():
			shown.append(pages[index])
	read(shown)


## [param numbers] read: the new ones among them written into the profile and saved, and their
## marks gone from the pages open.
func read(numbers: Array) -> void:
	var any := false
	for number: int in numbers:
		if profile.story.is_new(number):
			profile.story.notes_read.append(number)
			any = true
	if not any:
		return
	if not Game.is_headless():
		Game.settings.save_to_disk()
	for side: Control in [_left, _right]:
		for page: Node in side.get_children():
			var open_page := page as NotePage
			open_page.new = profile.story.is_new(open_page.number)
			open_page.queue_redraw()


## A note taken off its page for a closer look, see [NoteView]: page [param index], or the open
## spread's right one, or its left where there is no right.
func look_closer(index := -1) -> void:
	if view != null or is_busy() or pages.is_empty():
		return
	if index < 0:
		index = right_of(at) if right_of(at) < pages.size() else left_of(at)
	if index < 0 or index >= pages.size() or pages[index] < 0:
		return
	view = NoteView.open(self, index)
	view.put_back.connect(_on_put_back)
	# The folder's own buttons and line under the note go while it is up.
	_buttons_row.visible = false
	away_line.visible = false


## Put back: the folder open at the spread of the note last looked at.
func _on_put_back(index: int) -> void:
	view = null
	_buttons_row.visible = true
	away_line.visible = true
	if spread_of(index) != at:
		_show(spread_of(index))
	look.grab_focus()


## Left and right turn the pages, before the focus takes them for walking buttons; what was pressed
## says which lines to draw. A press while it turns on to the first new note cuts that short.
func _input(event: InputEvent) -> void:
	if _closing or view != null:
		return
	var was := keyboard
	keyboard = LicenseView.keyboard_after(event, keyboard)
	if was != keyboard:
		say_away()
	if _flipping and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		skip_flip()
		return
	if event.is_action_pressed(&"ui_left"):
		get_viewport().set_input_as_handled()
		turn(-1)
	elif event.is_action_pressed(&"ui_right"):
		get_viewport().set_input_as_handled()
		turn(1)


func _unhandled_input(event: InputEvent) -> void:
	if _closing or view != null:
		return
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
	if _closing or view != null or Time.get_ticks_msec() - _shown_at < SETTLE_MS:
		return
	var where: Vector2 = click.position if click != null else touch.position
	var on := folder.get_global_rect()
	on.position -= global_position
	if not on.has_point(where):
		close()
		return
	# On a note itself, a closer look at it; anywhere else on a page, a turn.
	for side: Control in [_left, _right]:
		if side.get_child_count() == 0:
			continue
		var page := side.get_child(0) as NotePage
		var inside := page.get_global_transform().affine_inverse() * (where + global_position)
		if page.number > 0 and page.paper_rect().has_point(inside):
			look_closer(left_of(at) if side == _left else right_of(at))
			return
	turn(1 if where.x >= on.get_center().x else -1)


## Put away: said at once, so whatever opened it has its cursor back, and then shut and sent back
## where it came from, and gone.
func close() -> void:
	if _closing or is_queued_for_deletion():
		return
	_closing = true
	_flipping = false
	put_away.emit()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _turning != null and _turning.is_valid():
		_turning.kill()
	_leaf.visible = false
	var fade := create_tween().set_parallel(true)
	fade.tween_property(_buttons_row, "modulate:a", 0.0, SWING * 0.5)
	fade.tween_property(away_line, "modulate:a", 0.0, SWING * 0.5)
	if _shut:
		_go_back()
	else:
		_swing(false)


func _go_back() -> void:
	var end := _peek_place()
	_moving = create_tween()
	_moving.set_parallel(true)
	_moving.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_moving.tween_property(folder, "position", end[0], SLIDE)
	_moving.tween_property(folder, "scale", Vector2.ONE * float(end[1]), SLIDE)
	_moving.tween_property(_shade, "modulate:a", 0.0, SLIDE)
	_moving.chain().tween_callback(queue_free)


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
