class_name LicenseView
extends Control
## The driver license of GAME.md 9.4a shown in full over a shade, the way a joker is shown out of
## the hand, 3.7, held up to be looked at on a [TiltedCard]: a click or a tap on the card, the
## hand's button or the turning arrows under it turn it over, and a right click, a click or a tap
## beside it, Back or the cross under it puts it away, as Kit's folder and its closer look have
## it, STORY.md 7.2. The buttons are for the mouse and never take the cursor; keys and pads have
## their binds drawn on them, see [ButtonBinds]. The title's, 3.8, and the License tab's of the
## settings, 8.5, alike.

signal put_away

## How big the card is shown.
const FULL := 1.15
## How to turn it over and put it away, by the device in hand, and what the buttons say to the
## mouse.
const AWAY_MOUSE := "Click the card to turn it over, beside it to put it away"
const AWAY_TOUCH := "Tap the card to turn it over, or beside it to put it away"
const TURN_WORD := "Turn over"
const AWAY_WORD := "Put it away"
const ICON_WIDTH := 136.0
## Growing up off the card it was shown from and going back down onto it, as a note does off its
## page in Kit's folder, see [NoteView]: how long each takes.
const FLY := 0.32
const FLY_BACK := 0.26
## How long after the view comes up a press beside the card is let be: a tap comes with a mouse
## press made of it a moment later, which would put the view away as soon as the tap brought it up.
const SETTLE_MS := 150
## A stick has to be pushed this far to count as the device in hand: a keyboard with a joystick in
## it, or a pad on the desk, whispers small motions all the time.
const STICK_COUNTS := 0.5

var stand: TiltedCard
var card: LicenseCard
var turn: Button
var away: Button
## The line under the card saying what puts it away, and whether a keyboard and mouse are in hand
## rather than a pad.
var away_line: Control
var keyboard := true

var _shown_at := 0
## Whether the mouse is in hand rather than keys or a pad, see [ButtonBinds].
var _pointer := false
## The card it grows up off and goes back down onto, the title's peeking in, hidden while it is up;
## none for one that just comes up.
var _from: Control
## How far it has grown, 0 on the card it came from and 1 in its place; where that card was, its
## middle, size and turn; and the room it has in its place, the shade, and what fades round it.
var _fly := 1.0
var _from_center := Vector2.ZERO
var _from_scale := 1.0
var _from_turn := 0.0
var _from_tint := Color.WHITE
var _place: Control
var _shade: ColorRect
var _round: Array[CanvasItem] = []
var _closing := false


## The license from the settings, up over [param parent], its line drawn for a keyboard and mouse
## when [param on_keyboard] or for a pad otherwise.
## The license from the settings, up over [param parent], its line drawn for a keyboard and mouse
## when [param on_keyboard] or for a pad otherwise; growing up off [param grows_from], a card
## showing the license, where there is one.
static func open(parent: Node, on_keyboard: bool, grows_from: Control = null) -> LicenseView:
	var view := LicenseView.new()
	view.name = "LicenseView"
	view.keyboard = on_keyboard
	view._from = grows_from
	parent.add_child(view)
	return view


## Whether a keyboard and mouse are in hand after [param event], [param was] if it says nothing.
static func keyboard_after(event: InputEvent, was: bool) -> bool:
	var stick := event as InputEventJoypadMotion
	if event is InputEventJoypadButton or (stick != null and absf(stick.axis_value) > STICK_COUNTS):
		return false
	if event is InputEventKey or event is InputEventMouseButton:
		return true
	return was


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_shown_at = Time.get_ticks_msec()
	_shade = ColorRect.new()
	_shade.color = Color(0.0, 0.0, 0.0, 0.7)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	card = LicenseCard.from_settings()
	card.name = "LicenseFull"
	stand = TiltedCard.of(card, FULL)
	stand.name = "LicenseStand"
	# Its place in the column, the stand inside it free to fly to and from it.
	_place = Control.new()
	_place.name = "Place"
	_place.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_place)
	_place.add_child(stand)
	_place.custom_minimum_size = stand.size
	var row := HBoxContainer.new()
	row.name = "Buttons"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	turn = _icon_button("TurnOver", HouseArt.turning(), TURN_WORD, InputActions.JOKER_MENU)
	turn.pressed.connect(stand.turn_over)
	row.add_child(turn)
	away = _icon_button("Away", HouseArt.cross(), AWAY_WORD, &"ui_cancel")
	away.pressed.connect(close)
	row.add_child(away)
	away_line = Control.new()
	away_line.custom_minimum_size = Vector2(0.0, 24.0)
	away_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(away_line)
	_pointer = Game.last_input_pointer
	say_away()
	_show_binds()
	gui_input.connect(_on_beside)
	_round = [_shade, row, away_line]
	if _from != null and is_instance_valid(_from):
		_rise()
	else:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	# Nothing here takes the cursor, so whatever had it under the view lets it go.
	get_viewport().gui_release_focus()
	Audio.play_sfx(&"joker_offer", MenuTheme.MOVE_DB, 0.0)


## Up off the card it was shown from to its place, the shade and the buttons coming up round it,
## once the column has laid it out.
func _rise() -> void:
	stand.visible = false
	for part: CanvasItem in _round:
		part.modulate.a = 0.0
	await get_tree().process_frame
	if not is_instance_valid(_from) or _closing:
		stand.visible = true
		return
	_take_from()
	_from.visible = false
	_set_fly(0.0)
	stand.visible = true
	var up := create_tween().set_parallel(true)
	for part: CanvasItem in _round:
		up.tween_property(part, "modulate:a", 1.0, FLY)
	up.tween_method(_set_fly, 0.0, 1.0, FLY).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Where the card it came from is now: its middle, how big it is drawn against the stand's card,
## and how it is turned.
func _take_from() -> void:
	var on := _from.get_global_transform()
	_from_center = on * (LicenseCard.SIZE * 0.5)
	_from_scale = on.get_scale().x / FULL
	_from_turn = on.get_rotation()
	_from_tint = _from.modulate


## The stand between the card it came from and its place, [param amount] of the way.
func _set_fly(amount: float) -> void:
	_fly = amount
	var rest := _place.global_position + _place.size * 0.5
	stand.pivot_offset = stand.size * 0.5
	stand.scale = Vector2.ONE * lerpf(_from_scale, 1.0, amount)
	stand.rotation = lerp_angle(_from_turn, 0.0, amount)
	stand.global_position = _from_center.lerp(rest, amount) - stand.size * 0.5
	# As dim as the card it came from where it came from, and still on the way, so it neither pops
	# brighter as it leaves nor darker as it lands, nor swings about under the mouse.
	stand.modulate = _from_tint.lerp(Color.WHITE, amount)
	stand.calm = amount


## A button for the mouse under the card: [param picture] on it, [param word] its tooltip, and the
## bind of [param action] drawn on it for keys and pads.
func _icon_button(named: String, picture: Texture2D, word: String, action: StringName) -> Button:
	var button := MenuTheme.button("", Type.BODY)
	button.name = named
	button.icon = picture
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.tooltip_text = word
	button.custom_minimum_size.x = ICON_WIDTH
	button.focus_mode = Control.FOCUS_NONE
	ButtonBinds.mark(button, action)
	return button


## The binds on the buttons, for the device in hand, while keys or a pad are.
func _show_binds() -> void:
	ButtonBinds.show([turn, away] as Array[Button], keyboard, not _pointer)


## The hand's button or accept turns the card over and a right click anywhere puts it away, before
## anything under takes them; and what was pressed says which line and binds to draw.
func _input(event: InputEvent) -> void:
	if _closing:
		return
	var was := keyboard
	var was_pointer := _pointer
	keyboard = keyboard_after(event, keyboard)
	_pointer = ButtonBinds.pointer_after(event, _pointer)
	if was != keyboard or was_pointer != _pointer:
		say_away()
		_show_binds()
	var click := event as InputEventMouseButton
	if event.is_action_pressed(InputActions.JOKER_MENU) or event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		stand.turn_over()
	elif click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if Time.get_ticks_msec() - _shown_at >= SETTLE_MS:
			close()


func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		# Up over a screen, the screen under it hears nothing: no tab of the settings switches.
		get_viewport().set_input_as_handled()


## Beside the card, once the view has settled, a click or a tap puts it away; one on the card turns
## it over, see [TiltedCard].
func _on_beside(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed) or (touch != null and touch.pressed):
		get_viewport().set_input_as_handled()
		if Time.get_ticks_msec() - _shown_at >= SETTLE_MS:
			close()


## Put away: said at once, so the screen under has its cursor back, and gone once it is back down
## on the card it came from, if it came from one.
func close() -> void:
	if _closing or is_queued_for_deletion():
		return
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	put_away.emit()
	if _from == null or not is_instance_valid(_from):
		queue_free()
		return
	# Back down onto the card it came from, following it as it settles where the screen under puts
	# it, turned face up on the way if it was over, and the card shown again once it is there.
	if card.flipped and not stand.is_turning():
		stand.turn_over(FLY_BACK)
	var down := create_tween().set_parallel(true)
	for part: CanvasItem in _round:
		down.tween_property(part, "modulate:a", 0.0, FLY_BACK)
	(
		down
		. tween_method(
			func(amount: float) -> void:
				if is_instance_valid(_from):
					_take_from()
				_set_fly(amount),
			_fly,
			0.0,
			FLY_BACK
		)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_IN_OUT)
	)
	down.chain().tween_callback(
		func() -> void:
			if is_instance_valid(_from):
				_from.visible = true
			queue_free()
	)


## The line under the card saying how to turn it over and put it away with a mouse or a finger.
## Nothing with keys or a pad, whose binds are on the buttons already.
func say_away() -> void:
	if away_line == null or not is_instance_valid(away_line):
		return
	for old: Node in away_line.get_children():
		away_line.remove_child(old)
		old.queue_free()
	var row: Control
	if TouchInput.enabled:
		row = MenuTheme.subtitle(AWAY_TOUCH, Type.LABEL)
	elif _pointer:
		row = MenuTheme.subtitle(AWAY_MOUSE, Type.LABEL)
	else:
		return
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	away_line.add_child(row)
