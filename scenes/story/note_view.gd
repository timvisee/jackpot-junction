class_name NoteView
extends Control
## One of Kit's notes taken off its page for a closer look, STORY.md 7.2: the note alone, larger,
## in the middle of the screen over the folder darkened behind it, the way the license comes up in
## full, growing up off its page as it comes and going back down onto it when it is put back, and
## like the license it turns a little toward the mouse, the stick or the phone and
## catches the light, see [TiltedCard]. It can be looked at closer and moved about, turned over to
## its back, see [constant StoryNotes.BACKS], and put back; with the note at its own size left and
## right go to the note before and after it, the one in view sliding out as the next slides in. A
## note is read as soon as it is taken out.

## Put back, the folder to open at the spread of note [param index], the last one looked at.
signal put_back(index: int)

## How much of the screen the note fills at its own size, room kept under it for the buttons, how
## much closer it can be looked at, by how much a step goes, and how fast it moves on a pad's stick
## or the arrow keys.
const SCREEN_SHARE := 0.86
const BUTTON_ROOM := 150.0
const CLOSEST := 3.0
const STEP := 1.25
const MOVE_RATE := 900.0
const STICK_COUNTS := 0.2
## A trigger pulled less than this is resting, and how much of the way to where a trigger says the
## note goes each second.
const TRIGGER_REST := 0.04
const TRIGGER_FOLLOW := 16.0
## Turning over: how long, and how faint the front shows through on a back that lets it.
const TURN := 0.32
## How long it takes to grow up off its page, and to go back down onto it; how long a step to the
## note beside it takes, and how far to the side, as a share of the screen's width, the one going
## goes and the one coming comes from.
const FLY := 0.32
const FLY_BACK := 0.26
const SLIDE := 0.26
const SLIDE_OFF := 1.0
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
## The House's invitation and its golden ticket, kept at the back of the folder, and the first
## invitation at its front, are foil on card: the gold catches the light, as bright and as spread as
## when they were held up, see [HeldCard], and the rest of the card not; the first invitation's
## foil where a picture of where it shines says, its stub's gold being matt.
const FOIL_SHEEN := HeldCard.SHINE
const FOIL_TIGHT := HeldCard.SHINE_TIGHT
const FOIL_RELIEF := 0.8
## The most pixels a face is drawn at across, however close it is looked at.
const SHARPEST := 4096
const SETTLE_MS := 150
const ARROW_WIDTH := 88.0
## How wide Turn over and Put back are, turning arrows and a cross on them rather than their words,
## which are their tooltips.
const ICON_WIDTH := 136.0
const TURN_WORD := "Turn over"
const BACK_WORD := "Put back"
const HINT_MOUSE := "Click it to turn it over, beside it to put it back, scroll to look closer"
const HINT_KEYS := "+ and - look closer, the arrows move it"
const HINT_PAD := "The triggers look closer, the right stick moves it"
const HINT_TOUCH := "Tap it to turn it over, beside it to put it back, pinch to look closer"

## The folder it was taken out of, and which of its pages is looked at.
var folder: NotesFolder
var index := 0
var zoom := 1.0
var pan := Vector2.ZERO
## Whether it shows its back.
var turned := false
var keyboard := true

var _card: Control
## Growing up off its page and going back down onto it: how far, 0 on the page and 1 in its place,
## where it was on the page in this view's own units, its middle, size and turn, and what is hidden
## on the page while it is up, see [method NotesFolder.lift_of].
var _fly := 1.0
var _from_center := Vector2.ZERO
var _from_scale := 1.0
var _from_turn := 0.0
var _lifted: CanvasItem
## How far to the side of its place it is while it slides in, and whether it is going back down.
var _slide := 0.0
var _sliding: Tween
var _putting_back := false
## Which way the stick was last pushed over, 0 for the middle, so a push steps one note; and
## whether the mouse is in hand rather than keys or a pad, see [ButtonBinds].
var _stick := 0
var _pointer := false
## Whether the triggers are holding it closer, or letting it go back to its own size.
var _squeezed := false
## The shade behind it, the strip under the buttons and the buttons, which fade in and out round it.
var _shade: ColorRect
var _foot: ColorRect
var _chrome: Array[CanvasItem] = []
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
## Whether the light is told where the note shines by a picture of it, the first invitation's, and
## the pictures of where its front and its back shine, see [method _mask].
var _masked := false
var _front_shine: SubViewport
var _back_shine: SubViewport
var _dragging := false
var _moved := false
## The fingers on it, by index, where each is; how far apart the first two were and where between
## them at the last step of a pinch; and whether this touch has pinched, after which nothing let go
## is a tap.
var _fingers: Dictionary[int, Vector2] = {}
var _pinch_apart := 0.0
var _pinch_middle := Vector2.ZERO
var _pinched := false
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
	_shade = MenuTheme.closer_shade(0.84)
	add_child(_shade)
	# A dark strip under the buttons, for a note looked at closer than the screen is tall.
	_foot = ColorRect.new()
	_foot.color = Color(0.0, 0.0, 0.0, 0.6)
	_foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_foot.offset_top = -BUTTON_ROOM + 30.0
	add_child(_foot)
	var under := VBoxContainer.new()
	under.add_theme_constant_override("separation", 10.0 + ButtonBinds.ROOM)
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
	_chrome = [_shade, _foot, under]
	_build()
	resized.connect(_place)
	gui_input.connect(_on_input)
	_lift_off()
	# Nothing here takes the cursor: the buttons are for the mouse, and keys and pads have their
	# binds drawn on them.
	get_viewport().gui_release_focus()
	_pointer = Game.last_input_pointer
	say_how()
	_show_binds()
	_held = Input.get_gravity()
	Audio.play_sfx(&"leaf", -8.0, 0.1)


## The arrows to the notes either side, Turn over, turning arrows, and Put back, a cross: for the
## mouse, never taking the cursor, each marked with what does it on keys or a pad.
func _buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var before := MenuTheme.button("‹", Type.HEADING)
	before.name = "Previous"
	before.focus_mode = Control.FOCUS_NONE
	before.custom_minimum_size.x = ARROW_WIDTH
	before.pressed.connect(step.bind(-1))
	ButtonBinds.mark(before, &"ui_left", KEY_LEFT, JOY_BUTTON_LEFT_SHOULDER)
	row.add_child(before)
	_turn_button = MenuTheme.button("", Type.BODY)
	_turn_button.name = "TurnOver"
	_turn_button.icon = HouseArt.turning()
	_turn_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_button.tooltip_text = TURN_WORD
	_turn_button.custom_minimum_size.x = ICON_WIDTH
	_turn_button.focus_mode = Control.FOCUS_NONE
	_turn_button.pressed.connect(turn_over)
	ButtonBinds.mark(_turn_button, InputActions.JOKER_MENU)
	row.add_child(_turn_button)
	var back := MenuTheme.button("", Type.BODY)
	back.name = "PutBack"
	back.icon = HouseArt.cross()
	back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.tooltip_text = BACK_WORD
	back.custom_minimum_size.x = ICON_WIDTH
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(close)
	ButtonBinds.mark(back, &"ui_cancel")
	row.add_child(back)
	var after := MenuTheme.button("›", Type.HEADING)
	after.name = "Next"
	after.focus_mode = Control.FOCUS_NONE
	after.custom_minimum_size.x = ARROW_WIDTH
	after.pressed.connect(step.bind(1))
	ButtonBinds.mark(after, &"ui_right", KEY_RIGHT, JOY_BUTTON_RIGHT_SHOULDER)
	row.add_child(after)
	return row


## The binds on the buttons, for the device in hand, while keys or a pad are.
func _show_binds() -> void:
	var buttons: Array[Button] = []
	for button: Node in _turn_button.get_parent().get_children():
		buttons.append(button as Button)
	ButtonBinds.show(buttons, keyboard, not _pointer)


## The note at [member index], front up, at its own size: the note alone off its page, and its back
## with the front showing through where the paper lets it.
func _build() -> void:
	if _turning != null and _turning.is_valid():
		_turning.kill()
	# A card of its own each time, so the one before can slide away while this one comes.
	_card = Control.new()
	_card.name = "Card"
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	move_child(_card, _foot.get_index())
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
	_masked = number == StoryNotes.OPENING
	var foil := number == StoryNotes.INVITATION or number == StoryNotes.TICKET or _masked
	_material.set_shader_parameter("relief", FOIL_RELIEF if foil else RELIEF)
	_material.set_shader_parameter("sheen", FOIL_SHEEN if foil else SHEEN)
	_material.set_shader_parameter("sheen_tight", FOIL_TIGHT if foil else SHEEN_TIGHT)
	_material.set_shader_parameter("foil", 1.0 if foil and not _masked else 0.0)
	if _masked:
		var shines := NotePage.make(number, folder.profile)
		shines.layer = &"shine"
		_front_shine = _mask(shines, rect)
		var back_shines := NotePage.make(number, folder.profile)
		back_shines.layer = &"shine_back"
		_back_shine = _mask(back_shines, rect)
		_material.set_shader_parameter("shine", _front_shine.get_texture())
	_material.set_shader_parameter("shine_masked", 1.0 if _masked else 0.0)
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
	# Taken out for a closer look, it is read, STORY.md 7.2.
	folder.read([number])
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


## A picture of where [param page]'s note shines, drawn once, white on black, laid over its face as
## the face is, for the light to catch it there alone; not shown itself.
func _mask(page: NotePage, rect: Rect2) -> SubViewport:
	var room := Vector2.ONE * maxf(rect.size.x, rect.size.y) * ROOM
	var picture := (rect.size + room * 2.0).ceil()
	var sheet := SubViewport.new()
	sheet.transparent_bg = true
	sheet.disable_3d = true
	sheet.gui_disable_input = true
	sheet.size = Vector2i(picture)
	sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	page.position = -rect.position + room
	sheet.add_child(page)
	_card.add_child(sheet)
	return sheet


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
	# Between its page and its place while it grows up off the page or goes back down onto it, and
	# to the side while it slides in.
	var center := middle + pan
	var shown := by
	var turn := 0.0
	if _fly < 1.0:
		center = _from_center.lerp(center, _fly)
		shown = lerpf(_from_scale, by, _fly)
		turn = lerp_angle(_from_turn, 0.0, _fly)
	center.x += _slide
	_card.scale = Vector2(shown, shown)
	_card.rotation = turn
	_card.position = center - _card.size * 0.5
	_sharpen(by)


## Up off its page to its place, the shade and the buttons coming up round it; straight to its place
## when its page is not open.
func _lift_off() -> void:
	var show := create_tween().set_parallel(true)
	for part: CanvasItem in _chrome:
		part.modulate.a = 0.0
		show.tween_property(part, "modulate:a", 1.0, FLY)
	var lift := folder.lift_of(index)
	if lift.is_empty():
		return
	_take_from(lift)
	_set_fly(0.0)
	show.tween_method(_set_fly, 0.0, 1.0, FLY).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Where it goes from and back to, on its page as [param lift] has it, and what is hidden there.
func _take_from(lift: Dictionary) -> void:
	var into := get_global_transform()
	_from_center = into.affine_inverse() * (lift["center"] as Vector2)
	_from_scale = float(lift["scale"]) / into.get_scale().x
	_from_turn = float(lift["rotation"]) - into.get_rotation()
	_show_lifted()
	_lifted = lift["held"]
	if _lifted != null:
		_lifted.visible = false


## What was hidden on the page shown again.
func _show_lifted() -> void:
	if _lifted != null and is_instance_valid(_lifted):
		_lifted.visible = true
	_lifted = null


func _set_fly(amount: float) -> void:
	_fly = amount
	_place()


func _set_slide(offset: float) -> void:
	_slide = offset
	_place()


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
## round as it passes edge-on, the way the license turns, taking [param takes].
func turn_over(takes := TURN) -> void:
	if _turning != null and _turning.is_valid():
		return
	_from = turned
	var way := -1.0 if _from else 1.0
	_turning = create_tween()
	_turning.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turning.tween_method(_turn_by, 0.0, PI * way, takes)
	_turning.tween_callback(_turn_by.bind(0.0))
	Audio.play_sfx(&"leaf", -10.0, 0.12)


func _turn_by(angle: float) -> void:
	_over = angle
	_aim()


## The note turned as it is: the tilt, the turn over on top of it, the side in view the one the eye
## would see, which changes as it passes edge-on. The tilt up or down is carried round with it, see
## [method TiltedCard.pitch], so it comes to rest as it was, without a jump.
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
			# Where the face in view shines, front or back.
			if _masked:
				var shines := _back_shine if turned else _front_shine
				_material.set_shader_parameter("shine", shines.get_texture())
	var pitch := TiltedCard.pitch(_tilt.y * TiltedCard.TURN, _over)
	_material.set_shader_parameter("turn", Vector2(yaw, pitch))


## The note [param by] along in the folder, front up at its own size: the one in view slides out
## the way it goes, and this one in from the other side.
func step(by: int) -> void:
	var to := index + signi(by)
	if _putting_back or to < 0 or to >= folder.pages.size():
		return
	_show_lifted()
	_fly = 1.0
	var leaving := _card
	var off := size.x * SLIDE_OFF * signi(by)
	index = to
	_build()
	# Both go the same way at the same pace, a screen apart, so they never overlap.
	var away := create_tween().set_parallel(true)
	away.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	away.tween_property(leaving, "position:x", leaving.position.x - off, SLIDE)
	away.tween_property(leaving, "modulate:a", 0.0, SLIDE)
	away.chain().tween_callback(leaving.queue_free)
	if _sliding != null and _sliding.is_valid():
		_sliding.kill()
	_set_slide(off)
	_sliding = create_tween()
	_sliding.tween_method(_set_slide, off, 0.0, SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_OUT
	)
	Audio.play_sfx(&"leaf", -10.0, 0.1)


## The arrows gone where there is no note to go to, keeping their room, and carrying a new note's
## pencil mark where the note they go to is new.
func _mark_ends() -> void:
	var row := _turn_button.get_parent()
	var before := row.get_node("Previous") as Button
	var after := row.get_node("Next") as Button
	var story := folder.profile.story
	ButtonBinds.show_arrow(before, index > 0)
	ButtonBinds.show_arrow(after, index < folder.pages.size() - 1)
	NotePage.mark_button(before, not before.disabled and story.is_new(folder.pages[index - 1]))
	NotePage.mark_button(after, not after.disabled and story.is_new(folder.pages[index + 1]))
	_show_binds()


## A pad's triggers zoom and its right stick moves it, and the arrow keys move it while it is
## closer.
func _process(delta: float) -> void:
	# Turned toward the mouse, the stick or the phone, less the closer it is looked at.
	var pull := Input.get_gravity()
	if _held.is_zero_approx():
		_held = pull
	else:
		_held = _held.lerp(pull, 1.0 - exp(-TiltedCard.PHONE_SETTLE * delta))
	# Flat while it grows up off its page or goes back down onto it.
	var toward := TiltedCard.wanted(_card.get_global_rect(), _mouse, _held) * TILT / zoom * _fly
	_tilt = _tilt.lerp(toward, 1.0 - exp(-TiltedCard.FOLLOW * delta))
	_aim()
	if _putting_back:
		return
	var squeeze := 0.0
	var move := Vector2.ZERO
	for pad: int in Input.get_connected_joypads():
		squeeze = maxf(
			squeeze,
			maxf(
				Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT),
				Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT)
			)
		)
		var stick := Vector2(
			Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
		)
		if stick.length() > STICK_COUNTS:
			move -= stick
	if zoom > 1.001:
		move -= Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	_squeeze(squeeze, delta)
	if move != Vector2.ZERO and zoom > 1.001:
		pan += move * MOVE_RATE * delta
		_place()


## A pad's triggers hold it closer as far as they are pulled, [param pulled] of the way, all the
## way pulled at the closest, and let go it goes back to its own size; followed quickly rather than
## jumped to, so a trigger that clicks rather than travels still eases.
func _squeeze(pulled: float, delta: float) -> void:
	if pulled > TRIGGER_REST:
		_squeezed = true
	if not _squeezed:
		return
	var wanted := lerpf(1.0, CLOSEST, clampf(pulled, 0.0, 1.0))
	var eased := lerpf(zoom, wanted, 1.0 - exp(-TRIGGER_FOLLOW * delta))
	zoom_by(eased / zoom)
	if pulled <= TRIGGER_REST and zoom <= 1.01:
		_squeezed = false
		zoom_by(1.0 / zoom)


## Before the focus takes them: turning over, looking closer and the notes either side.
func _input(event: InputEvent) -> void:
	if _putting_back:
		return
	var motion := event as InputEventMouseMotion
	if motion != null and not TouchInput.enabled:
		_mouse = motion.global_position
	var was := keyboard
	var was_pointer := _pointer
	keyboard = LicenseView.keyboard_after(event, keyboard)
	_pointer = ButtonBinds.pointer_after(event, _pointer)
	if was != keyboard or was_pointer != _pointer:
		say_how()
		_show_binds()
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	if (
		event.is_action_pressed(InputActions.JOKER_MENU)
		or event.is_action_pressed(&"ui_accept")
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
	elif (
		pad != null
		and pad.pressed
		and pad.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]
	):
		# A pad's shoulder buttons step to the notes either side however close it is looked at,
		# as they turn the folder's pages.
		get_viewport().set_input_as_handled()
		step(-1 if pad.button_index == JOY_BUTTON_LEFT_SHOULDER else 1)
	elif NotesFolder.turn_of(event) != 0 and key != null and key.physical_keycode in [KEY_A, KEY_D]:
		# A and D step to the notes either side, as they turn the folder's pages.
		get_viewport().set_input_as_handled()
		step(NotesFolder.turn_of(event))
	elif zoom <= 1.001 and NotesFolder.is_stick_across(event):
		# The stick steps a note a push, let go between, as it turns the folder's pages.
		get_viewport().set_input_as_handled()
		var way := NotesFolder.stick_way(event)
		if way != _stick:
			_stick = way
			if way != 0:
				step(way)
	elif zoom <= 1.001 and event.is_action_pressed(&"ui_left", true):
		# Held down, the arrows step on and on, as they turn the folder's pages.
		get_viewport().set_input_as_handled()
		step(-1)
	elif zoom <= 1.001 and event.is_action_pressed(&"ui_right", true):
		get_viewport().set_input_as_handled()
		step(1)
	elif zoom > 1.001 and (event.is_action(&"ui_left") or event.is_action(&"ui_right")):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _putting_back:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		MenuTheme.back_sound()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


## The mouse's wheel and a pinch look closer, a drag moves it, a click turns it over and a right
## click puts it back; on a touch screen a tap on it turns it over and a tap beside it puts it back,
## see [method _touched].
func _on_input(event: InputEvent) -> void:
	if _zoomed_by(event):
		accept_event()
		return
	var mouse := event as InputEventMouse
	if mouse != null and mouse.device == InputEvent.DEVICE_ID_EMULATION:
		# A phone's finger made into a mouse as well: the finger itself is heard.
		accept_event()
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		accept_event()
		_touched(event)
		return
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		if click.pressed and Time.get_ticks_msec() - _shown_at >= SETTLE_MS:
			close()
	elif click != null and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_pressed(click, null)
	else:
		var drag := event as InputEventMouseMotion
		if _dragging and drag != null:
			if drag.relative.length() > 2.0:
				_moved = true
			if zoom > 1.001:
				pan += drag.relative
				_place()
			accept_event()


## A finger down, moving or let go: one alone drags it and taps it as the mouse does; two pinch
## it, closer as they spread and less close as they close, about the middle between them, which
## moves it as it moves. A phone sends no pinch of its own, only its fingers. Once two have been
## down nothing let go is a tap, and a finger left down after a pinch goes on moving it.
func _touched(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_fingers[touch.index] = touch.position
		else:
			_fingers.erase(touch.index)
		if _fingers.size() >= 2:
			_pinched = true
			_dragging = false
			_pinch_step(false)
		elif _pinched:
			_dragging = not _fingers.is_empty()
			_moved = true
			_pinched = not _fingers.is_empty()
		else:
			_pressed(null, touch)
		return
	var swipe := event as InputEventScreenDrag
	if not _fingers.has(swipe.index):
		return
	_fingers[swipe.index] = swipe.position
	if _fingers.size() >= 2:
		_pinch_step(true)
	elif _dragging:
		if swipe.relative.length() > 2.0:
			_moved = true
		if zoom > 1.001:
			pan += swipe.relative
			_place()


## The first two fingers' step of a pinch: how far apart they are and the middle between them, and
## when [param moving], the note looked at as much closer as they spread and moved as their middle
## moved since the last.
func _pinch_step(moving: bool) -> void:
	var down := _fingers.keys()
	down.sort()
	var first: Vector2 = _fingers[down[0]]
	var second: Vector2 = _fingers[down[1]]
	var apart := first.distance_to(second)
	var middle := (first + second) * 0.5
	if moving and _pinch_apart > 0.0 and apart > 0.0:
		zoom_by(apart / _pinch_apart, middle)
		if zoom > 1.001:
			pan += middle - _pinch_middle
			_place()
	_pinch_apart = apart
	_pinch_middle = middle


## Whether [param event] was the wheel or a pinch, looking closer by it.
func _zoomed_by(event: InputEvent) -> bool:
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed:
		if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(STEP, wheel.position)
			return true
		if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / STEP, wheel.position)
			return true
	var pinch := event as InputEventMagnifyGesture
	if pinch != null:
		zoom_by(pinch.factor, pinch.position)
		return true
	return false


## A press or a release of the mouse's left button, [param click], or a finger, [param touch]: a
## drag begins with it, and let go without one, a click or a tap on it turns it over and one
## beside it puts it back. Only a press that came here is let go here: a phone sends a tap's mouse
## before its finger, so a finger let go over Next as Next goes, on to the last note, falls through
## to here without ever having come down here. The buttons' row is never beside it, the room of an
## arrow out of sight included.
func _pressed(click: InputEventMouseButton, touch: InputEventScreenTouch) -> void:
	var pressed: bool = click.pressed if click != null else touch.pressed
	var where: Vector2 = click.position if click != null else touch.position
	if pressed:
		_dragging = true
		_moved = false
		return
	var came := _dragging
	_dragging = false
	if not came or _moved or Time.get_ticks_msec() - _shown_at < SETTLE_MS:
		return
	var at := where + global_position
	if _card.get_global_rect().has_point(at):
		turn_over()
	elif not _turn_button.get_parent().get_global_rect().has_point(at):
		close()


## Put back: the folder told which note it was at once, so it opens that note's spread and has
## the cursor back, and the note goes back down onto its page there, turned face up on the way;
## then gone.
func close() -> void:
	if _putting_back or is_queued_for_deletion():
		return
	_putting_back = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	put_back.emit(index)
	Audio.play_sfx(&"leaf", -18.0, 0.1)
	if turned:
		turn_over(FLY_BACK)
	var down := create_tween().set_parallel(true)
	for part: CanvasItem in _chrome:
		down.tween_property(part, "modulate:a", 0.0, FLY_BACK)
	var lift := folder.lift_of(index)
	if lift.is_empty():
		down.tween_property(_card, "modulate:a", 0.0, FLY_BACK)
	else:
		_take_from(lift)
		down.tween_method(_set_fly, _fly, 0.0, FLY_BACK).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_IN_OUT
		)
	down.chain().tween_callback(
		func() -> void:
			_show_lifted()
			queue_free()
	)


## The line under the buttons: how to look closer, move it and turn it over, for the device in hand;
## with keys or a pad only what the binds on the buttons do not say.
func say_how() -> void:
	if _hint == null or not is_instance_valid(_hint):
		return
	for old: Node in _hint.get_children():
		_hint.remove_child(old)
		old.queue_free()
	var row: Control
	if TouchInput.enabled:
		row = MenuTheme.subtitle(HINT_TOUCH, Type.LABEL)
	elif _pointer:
		row = MenuTheme.subtitle(HINT_MOUSE, Type.LABEL)
	else:
		row = MenuTheme.subtitle(HINT_KEYS if keyboard else HINT_PAD, Type.LABEL)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	_hint.add_child(row)
