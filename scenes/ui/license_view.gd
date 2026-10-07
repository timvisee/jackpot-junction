class_name LicenseView
extends Control
## The driver license of GAME.md 9.4a shown in full over a shade, the way a joker is shown out of
## the hand, 3.7, held up to be looked at on a [TiltedCard]: a click, a tap on the card, the hand's
## button or the turning arrows under it turn it over, and a right click, a tap beside it, Back or
## the cross under it puts it away, as Kit's folder and its closer look have it, STORY.md 7.2. The
## buttons are for the mouse and never take the cursor; keys and pads have their binds drawn on
## them, see [ButtonBinds]. The title's, 3.8, and the License tab's of the settings, 8.5, alike.

signal put_away

## How big the card is shown.
const FULL := 1.15
## How to turn it over and put it away, by the device in hand, and what the buttons say to the
## mouse.
const AWAY_MOUSE := "Click to turn it over, right-click to put it away"
const AWAY_PAD := "%s turns it over, %s puts it away"
const AWAY_TOUCH := "Tap the card to turn it over, or beside it to put it away"
const TURN_WORD := "Turn over"
const AWAY_WORD := "Put it away"
const ICON_WIDTH := 136.0
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


## The license from the settings, up over [param parent], its line drawn for a keyboard and mouse
## when [param on_keyboard] or for a pad otherwise.
static func open(parent: Node, on_keyboard: bool) -> LicenseView:
	var view := LicenseView.new()
	view.name = "LicenseView"
	view.keyboard = on_keyboard
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
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
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
	column.add_child(stand)
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
	modulate.a = 0.0
	var rise := create_tween()
	rise.tween_property(self, "modulate:a", 1.0, 0.2)
	# Nothing here takes the cursor, so whatever had it under the view lets it go.
	get_viewport().gui_release_focus()
	Audio.play_sfx(&"joker_offer", MenuTheme.MOVE_DB, 0.0)


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
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		# Up over a screen, the screen under it hears nothing: no tab of the settings switches.
		get_viewport().set_input_as_handled()


## Beside the card, once the view has settled: a click turns it over, as a click on it does, and a
## tap puts it away.
func _on_beside(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed) or (touch != null and touch.pressed):
		get_viewport().set_input_as_handled()
		if Time.get_ticks_msec() - _shown_at < SETTLE_MS:
			return
		if click != null and click.button_index == MOUSE_BUTTON_LEFT:
			stand.turn_over()
		elif touch != null:
			close()


## Put away: said, and gone.
func close() -> void:
	if is_queued_for_deletion():
		return
	put_away.emit()
	queue_free()


## The line under the card saying how to turn it over and put it away, with the controls drawn in
## for the device in hand: a click and a right click with a mouse, taps on a touch screen, and the
## hand's button and Back on keys or a pad.
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
	elif _pointer:
		row = MenuTheme.subtitle(AWAY_MOUSE, Type.LABEL)
	else:
		var turns := InputGlyph.of_action(InputActions.JOKER_MENU, keyboard, ink, Type.LABEL)
		var puts := InputGlyph.of_action(&"ui_cancel", keyboard, ink, Type.LABEL)
		if turns == null or puts == null:
			row = (
				MenuTheme
				. subtitle(
					(
						AWAY_PAD
						% [
							InputActions.short_binding_text(InputActions.JOKER_MENU, keyboard),
							InputActions.short_binding_text(&"ui_cancel", keyboard),
						]
					),
					Type.LABEL
				)
			)
		else:
			row = InputHint.row(AWAY_PAD, [turns, puts], ink, Type.LABEL)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	away_line.add_child(row)
