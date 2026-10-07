class_name NoteView
extends Control
## One of Kit's notes taken off its page for a closer look, STORY.md 7.2: the note alone, larger,
## in the middle of the screen over the folder darkened behind it, the way the license comes up in
## full, and like the license it turns a little toward the mouse, the stick or the phone and
## catches the light, see [TiltedCard]. It can be looked at closer and moved about, turned over to
## its back, see [constant StoryNotes.BACKS], and put back; with the note at its own size left and
## right go to the note before and after it. A note looked at closer for a second is read.

## Put back, the folder to open at the spread of note [param index], the last one looked at.
signal put_back(index: int)

## How much of the screen the note fills at its own size, room kept under it for the buttons, how
## much closer it can be looked at, by how much a step goes, and how fast it zooms and moves on a
## pad's triggers and stick or the arrow keys.
const SCREEN_SHARE := 0.86
const BUTTON_ROOM := 150.0
const CLOSEST := 3.0
const STEP := 1.25
const ZOOM_RATE := 1.6
const MOVE_RATE := 900.0
const STICK_COUNTS := 0.2
## Turning over: how long, and how faint the front shows through on a back that lets it.
const TURN := 0.32
const THROUGH := 0.13
## Room round the note in its picture for its corners as it turns, as a share of its longer side;
## how far it turns toward the mouse, as a share of how far the license does, a sheet of paper
## being bigger; how much lighter its near side is and darker its far side, less than the
## license's, white paper burning out sooner; and the light on it, faint and spread wide, as on
## paper rather than on the license's laminate, which has a gloss.
const ROOM := 0.15
const TILT := 0.75
const RELIEF := 0.45
const SHEEN := 0.08
const SHEEN_TIGHT := 4.0
## The most pixels a face is drawn at across, however close it is looked at.
const SHARPEST := 4096
## How long a note is looked at before it counts as read.
const READ_AFTER := 1.0
const SETTLE_MS := 150
const ARROW_WIDTH := 88.0
## How wide Turn over and Put back are, turning arrows and a cross on them rather than their words,
## which are their tooltips.
const ICON_WIDTH := 120.0
const TURN_WORD := "Turn over"
const BACK_WORD := "Put back"
const HINT_MOUSE := "Scroll to look closer, drag to move it, %s to turn it over"
const HINT_PAD := "Triggers look closer, the right stick moves it, %s turns it over"
const HINT_TOUCH := "Pinch to look closer, drag to move it, tap beside it to put it back"

## The folder it was taken out of, and which of its pages is looked at.
var folder: NotesFolder
var index := 0
var zoom := 1.0
var pan := Vector2.ZERO
## Whether it shows its back.
var turned := false
var keyboard := true

var _card: Control
var _front: Control
var _back: Control
## Each face's picture, drawn at the size it is shown at, see [method _face].
var _sheets: Array[SubViewport] = []
var _turning: Tween
## The turn right over under way, in radians, zero while there is none, and which side was up as
## it began.
var _over := 0.0
var _from := false
## Where the note is turned toward, -1 to 1 either way, smoothed; where the mouse was last seen,
## null until it has moved; and the phone's pull as the note came up, see [TiltedCard].
var _tilt := Vector2.ZERO
var _mouse: Variant = null
var _held := Vector3.ZERO
var _material: ShaderMaterial
var _dragging := false
var _moved := false
var _looked := 0.0
var _shown_at := 0
var _hint: Control
var _turn_button: Button


## Page [param at] of [param over] taken out for a closer look, over it.
static func open(over: NotesFolder, at: int) -> NoteView:
	var view := NoteView.new()
	view.name = "NoteView"
	view.folder = over
	view.index = at
	view.keyboard = over.keyboard
	over.add_child(view)
	return view


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_shown_at = Time.get_ticks_msec()
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_card = Control.new()
	_card.name = "Card"
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	# A dark strip under the buttons, for a note looked at closer than the screen is tall.
	var foot := ColorRect.new()
	foot.color = Color(0.0, 0.0, 0.0, 0.6)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -BUTTON_ROOM + 30.0
	add_child(foot)
	var under := VBoxContainer.new()
	under.add_theme_constant_override("separation", 10)
	under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	under.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	under.grow_horizontal = Control.GROW_DIRECTION_BOTH
	under.grow_vertical = Control.GROW_DIRECTION_BEGIN
	under.offset_bottom = -18.0
	add_child(under)
	under.add_child(_buttons())
	_hint = Control.new()
	_hint.custom_minimum_size = Vector2(0.0, 24.0)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	under.add_child(_hint)
	say_how()
	_build()
	resized.connect(_place)
	gui_input.connect(_on_input)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	_turn_button.grab_focus()
	_held = Input.get_gravity()
	Audio.play_sfx(&"leaf", -8.0, 0.1)


## The arrows to the notes either side, Turn over, turning arrows, which has the cursor, and Put
## back, a cross.
func _buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var before := MenuTheme.button("‹", Type.HEADING)
	before.name = "Previous"
	before.focus_mode = Control.FOCUS_NONE
	before.custom_minimum_size.x = ARROW_WIDTH
	before.pressed.connect(step.bind(-1))
	row.add_child(before)
	_turn_button = MenuTheme.button("", Type.BODY)
	_turn_button.name = "TurnOver"
	_turn_button.icon = HouseArt.turning()
	_turn_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_button.tooltip_text = TURN_WORD
	_turn_button.custom_minimum_size.x = ICON_WIDTH
	_turn_button.pressed.connect(turn_over)
	row.add_child(_turn_button)
	var back := MenuTheme.button("", Type.BODY)
	back.name = "PutBack"
	back.icon = HouseArt.cross()
	back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.tooltip_text = BACK_WORD
	back.custom_minimum_size.x = ICON_WIDTH
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(close)
	row.add_child(back)
	var after := MenuTheme.button("›", Type.HEADING)
	after.name = "Next"
	after.focus_mode = Control.FOCUS_NONE
	after.custom_minimum_size.x = ARROW_WIDTH
	after.pressed.connect(step.bind(1))
	row.add_child(after)
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_turn_button.set_focus_neighbor(side, NodePath("."))
	return row


## The note at [member index], front up, at its own size: the note alone off its page, and its back
## with the front showing through where the paper lets it.
func _build() -> void:
	if _turning != null and _turning.is_valid():
		_turning.kill()
	for old: Node in _card.get_children():
		_card.remove_child(old)
		old.queue_free()
	_sheets.clear()
	var number := folder.pages[index]
	var front := NotePage.make(number, folder.profile)
	front.layer = &"paper"
	var rect := front.paper_rect()
	_card.size = rect.size
	_card.pivot_offset = rect.size * 0.5
	var room := maxf(rect.size.x, rect.size.y) * ROOM
	var picture := rect.size + Vector2.ONE * room * 2.0
	_material = ShaderMaterial.new()
	_material.shader = TiltedCard.SHADER
	_material.set_shader_parameter("extent", picture * 0.5 / rect.size.x)
	_material.set_shader_parameter("depth", TiltedCard.DEPTH * maxf(1.0, rect.size.y / rect.size.x))
	_material.set_shader_parameter("relief", RELIEF)
	_material.set_shader_parameter("sheen", SHEEN)
	_material.set_shader_parameter("sheen_tight", SHEEN_TIGHT)
	_front = _face([front], rect)
	var back := NotePage.make(number, folder.profile)
	back.layer = &"back"
	var on_back: Array[NotePage] = [back]
	if StoryNotes.back_of(number).get("through", false):
		var through := NotePage.make(number, folder.profile)
		through.layer = &"paper"
		through.modulate.a = THROUGH
		through.scale = Vector2(-1.0, 1.0)
		through.position = Vector2(rect.end.x, -rect.position.y)
		on_back.append(through)
	_back = _face(on_back, rect)
	_back.visible = false
	turned = false
	zoom = 1.0
	pan = Vector2.ZERO
	_over = 0.0
	_looked = 0.0
	_mark_ends()
	_place()
	_aim()


## A face of the card: [param pages] set so the note's paper fills it, drawn into a picture of its
## own at the size it is shown at, its letters drawn at that size rather than blown up, see
## [method _sharpen], with room round it for its corners as it turns, and shown through the
## shader that turns it.
func _face(pages: Array[NotePage], rect: Rect2) -> Control:
	var room := Vector2.ONE * maxf(rect.size.x, rect.size.y) * ROOM
	var picture := (rect.size + room * 2.0).ceil()
	var face := TextureRect.new()
	face.position = -room
	face.size = picture
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_SCALE
	face.material = _material
	var sheet := SubViewport.new()
	sheet.transparent_bg = true
	sheet.disable_3d = true
	sheet.gui_disable_input = true
	sheet.size = Vector2i(picture)
	sheet.size_2d_override = Vector2i(picture)
	sheet.size_2d_override_stretch = true
	sheet.oversampling = true
	sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	for page: NotePage in pages:
		page.position = (-rect.position if page.position == Vector2.ZERO else page.position) + room
		sheet.add_child(page)
	face.add_child(sheet)
	face.texture = sheet.get_texture()
	_card.add_child(face)
	_sheets.append(sheet)
	return face


## Each face drawn again at [param by] times its own size, as it is shown, when that has changed.
func _sharpen(by: float) -> void:
	for sheet: SubViewport in _sheets:
		var wanted := Vector2i((Vector2(sheet.size_2d_override) * by).ceil())
		wanted = wanted.min(Vector2i.ONE * SHARPEST).max(Vector2i.ONE)
		if (wanted - sheet.size).abs().x <= 2 and (wanted - sheet.size).abs().y <= 2:
			continue
		sheet.size = wanted
		sheet.render_target_update_mode = SubViewport.UPDATE_ONCE


## As big as the screen has room for at its own size, closer by [member zoom], moved by
## [member pan] but never off the screen, and as far round as it has turned.
func _place() -> void:
	if _card == null:
		return
	var screen := size
	var by := _fit() * zoom
	var drawn := _card.size * by
	var middle := Vector2(screen.x * 0.5, (screen.y - BUTTON_ROOM) * 0.5)
	var slack := ((drawn - Vector2(screen.x, screen.y - BUTTON_ROOM)) * 0.5).max(Vector2.ZERO)
	pan = pan.clamp(-slack - Vector2.ONE * 40.0, slack + Vector2.ONE * 40.0)
	if zoom <= 1.001:
		pan = Vector2.ZERO
	_card.scale = Vector2(by, by)
	_card.position = middle + pan - _card.size * 0.5
	_sharpen(by)


func _fit() -> float:
	var room := Vector2(size.x, size.y - BUTTON_ROOM) * SCREEN_SHARE
	return maxf(minf(room.x / _card.size.x, room.y / _card.size.y), 0.1)


## Closer by [param factor], keeping what is under [param at] on the screen where it is.
func zoom_by(factor: float, at := Vector2(-1.0, -1.0)) -> void:
	var was := zoom
	zoom = clampf(zoom * factor, 1.0, CLOSEST)
	if is_equal_approx(was, zoom):
		return
	var middle := Vector2(size.x * 0.5, (size.y - BUTTON_ROOM) * 0.5)
	if at.x < 0.0:
		at = middle
	pan = (at - middle) - (at - middle - pan) * (zoom / was)
	_place()


## Turned over, front to back or back to front, about its upright axis, the other side coming
## round as it passes edge-on, the way the license turns.
func turn_over() -> void:
	if _turning != null and _turning.is_valid():
		return
	_from = turned
	var way := -1.0 if _from else 1.0
	_turning = create_tween()
	_turning.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turning.tween_method(_turn_by, 0.0, PI * way, TURN)
	_turning.tween_callback(_turn_by.bind(0.0))
	Audio.play_sfx(&"leaf", -10.0, 0.12)


func _turn_by(angle: float) -> void:
	_over = angle
	_aim()


## The note turned as it is: the tilt, the turn over on top of it, the side in view the one the eye
## would see, which changes as it passes edge-on.
func _aim() -> void:
	if _material == null:
		return
	var yaw := _tilt.x * TiltedCard.TURN + _over
	if _over != 0.0:
		var side := _from != (cos(yaw) < 0.0)
		if side != turned:
			turned = side
			_front.visible = not turned
			_back.visible = turned
	_material.set_shader_parameter("turn", Vector2(yaw, _tilt.y * TiltedCard.TURN))


## The note [param by] along in the folder, front up at its own size.
func step(by: int) -> void:
	var to := index + signi(by)
	if to < 0 or to >= folder.pages.size() or folder.pages[to] < 0:
		return
	index = to
	_build()
	Audio.play_sfx(&"leaf", -10.0, 0.1)


## The arrows greyed where there is no note to go to.
func _mark_ends() -> void:
	var row := _turn_button.get_parent()
	(row.get_node("Previous") as Button).disabled = index <= 0
	var last := index >= folder.pages.size() - 1 or folder.pages[index + 1] < 0
	(row.get_node("Next") as Button).disabled = last


## Looked at for a second, it is read; a pad's triggers zoom and its right stick moves it, and the
## arrow keys move it while it is closer.
func _process(delta: float) -> void:
	_looked += delta
	if _looked >= READ_AFTER:
		folder.read([folder.pages[index]])
	# Turned toward the mouse, the stick or the phone, less the closer it is looked at.
	var pull := Input.get_gravity()
	if _held.is_zero_approx():
		_held = pull
	else:
		_held = _held.lerp(pull, 1.0 - exp(-TiltedCard.PHONE_SETTLE * delta))
	var toward := TiltedCard.wanted(_card.get_global_rect(), _mouse, _held) * TILT / zoom
	_tilt = _tilt.lerp(toward, 1.0 - exp(-TiltedCard.FOLLOW * delta))
	_aim()
	var closer := 0.0
	var move := Vector2.ZERO
	for pad: int in Input.get_connected_joypads():
		closer += (
			Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT)
			- Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT)
		)
		var stick := Vector2(
			Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
		)
		if stick.length() > STICK_COUNTS:
			move -= stick
	if zoom > 1.001:
		move -= Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if absf(closer) > 0.05:
		zoom_by(pow(ZOOM_RATE, closer * delta * 2.0))
	if move != Vector2.ZERO and zoom > 1.001:
		pan += move * MOVE_RATE * delta
		_place()


## Before the focus takes them: turning over, looking closer and the notes either side.
func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and not TouchInput.enabled:
		_mouse = motion.global_position
	var was := keyboard
	keyboard = LicenseView.keyboard_after(event, keyboard)
	if was != keyboard:
		say_how()
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	if (
		event.is_action_pressed(InputActions.JOKER_MENU)
		or (key != null and key.pressed and not key.echo and key.keycode == KEY_F)
		or (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_Y)
	):
		get_viewport().set_input_as_handled()
		turn_over()
	elif key != null and key.pressed and key.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]:
		get_viewport().set_input_as_handled()
		zoom_by(STEP)
	elif key != null and key.pressed and key.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
		get_viewport().set_input_as_handled()
		zoom_by(1.0 / STEP)
	elif zoom <= 1.001 and event.is_action_pressed(&"ui_left"):
		get_viewport().set_input_as_handled()
		step(-1)
	elif zoom <= 1.001 and event.is_action_pressed(&"ui_right"):
		get_viewport().set_input_as_handled()
		step(1)
	elif zoom > 1.001 and (event.is_action(&"ui_left") or event.is_action(&"ui_right")):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


## The mouse's wheel and a pinch look closer, a drag moves it, and a click or a tap beside the note
## puts it back.
func _on_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed:
		if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(STEP, wheel.position)
			accept_event()
			return
		if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / STEP, wheel.position)
			accept_event()
			return
	var pinch := event as InputEventMagnifyGesture
	if pinch != null:
		zoom_by(pinch.factor, pinch.position)
		accept_event()
		return
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.button_index == MOUSE_BUTTON_LEFT) or touch != null:
		var pressed: bool = click.pressed if click != null else touch.pressed
		var where: Vector2 = click.position if click != null else touch.position
		accept_event()
		if pressed:
			_dragging = true
			_moved = false
			return
		_dragging = false
		if not _moved and Time.get_ticks_msec() - _shown_at >= SETTLE_MS:
			if not _card.get_global_rect().has_point(where + global_position):
				close()
		return
	var drag := event as InputEventMouseMotion
	var swipe := event as InputEventScreenDrag
	if _dragging and (drag != null or swipe != null):
		var by: Vector2 = drag.relative if drag != null else swipe.relative
		if by.length() > 2.0:
			_moved = true
		if zoom > 1.001:
			pan += by
			_place()
		accept_event()


## Put back: the folder told which note it was, and gone.
func close() -> void:
	if is_queued_for_deletion():
		return
	put_back.emit(index)
	Audio.play_sfx(&"note_down", -8.0, 0.08)
	queue_free()


## The line under the buttons: how to look closer, move it and turn it over, for the device in hand.
func say_how() -> void:
	if _hint == null or not is_instance_valid(_hint):
		return
	for old: Node in _hint.get_children():
		_hint.remove_child(old)
		old.queue_free()
	var ink := Color(0.72, 0.72, 0.78)
	var row: Control
	if TouchInput.enabled:
		row = MenuTheme.subtitle(HINT_TOUCH, Type.LABEL)
	else:
		var glyph := InputGlyph.of_action(InputActions.JOKER_MENU, keyboard, ink, Type.LABEL)
		var words := HINT_MOUSE if keyboard else HINT_PAD
		if glyph == null:
			row = MenuTheme.subtitle(
				words % InputActions.short_binding_text(InputActions.JOKER_MENU, keyboard),
				Type.LABEL
			)
		else:
			row = InputHint.row(words, [glyph], ink, Type.LABEL)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	_hint.add_child(row)
