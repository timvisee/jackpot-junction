class_name LicenseView
extends Control
## The driver license of GAME.md 9.4a shown in full over a shade, the way a joker is shown out of
## the hand, 3.7, held up to be looked at on a [TiltedCard]: a click or a tap on the card, or the
## hand's button, turns it over, and a click or a tap beside it, Back, or Put it away under it
## puts it away. The title's, 3.8, and the License tab's of the settings, 8.5, alike.

signal put_away

## How big the card is shown.
const FULL := 1.15
## What puts the view away, by the device in hand.
const AWAY_MOUSE := "Click beside the card, or press %s, to put it away"
const AWAY_PAD := "Press %s to put it away"
const AWAY_TOUCH := "Tap beside the card to put it away"
## How long after the view comes up a press beside the card is let be: a tap comes with a mouse
## press made of it a moment later, which would put the view away as soon as the tap brought it up.
const SETTLE_MS := 150
## A stick has to be pushed this far to count as the device in hand: a keyboard with a joystick in
## it, or a pad on the desk, whispers small motions all the time.
const STICK_COUNTS := 0.5

var stand: TiltedCard
var card: LicenseCard
var away: Button
## The line under the card saying what puts it away, and whether a keyboard and mouse are in hand
## rather than a pad.
var away_line: Control
var keyboard := true

var _shown_at := 0


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
	away = MenuTheme.button("Put it away", Type.BODY)
	away.name = "Away"
	away.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	away.pressed.connect(close)
	column.add_child(away)
	# The one button, and the cursor kept on it rather than walking off to the screen under.
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		away.set_focus_neighbor(side, away.get_path())
	away.focus_next = away.get_path()
	away.focus_previous = away.get_path()
	away_line = Control.new()
	away_line.custom_minimum_size = Vector2(0.0, 24.0)
	away_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(away_line)
	say_away()
	gui_input.connect(_on_beside)
	modulate.a = 0.0
	var rise := create_tween()
	rise.tween_property(self, "modulate:a", 1.0, 0.2)
	away.grab_focus()
	Audio.play_sfx(&"joker_offer", MenuTheme.MOVE_DB, 0.0)


## The hand's button turns the card over, before the focus takes the key for walking the buttons;
## and what was pressed says which line to draw.
func _input(event: InputEvent) -> void:
	var was := keyboard
	keyboard = keyboard_after(event, keyboard)
	if was != keyboard:
		say_away()
	if event.is_action_pressed(InputActions.JOKER_MENU):
		get_viewport().set_input_as_handled()
		stand.turn_over()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		# Up over a screen, the screen under it hears nothing: no tab of the settings switches.
		get_viewport().set_input_as_handled()


## A click or a tap beside the card puts it away, once the view has settled.
func _on_beside(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed) or (touch != null and touch.pressed):
		get_viewport().set_input_as_handled()
		if Time.get_ticks_msec() - _shown_at >= SETTLE_MS:
			close()


## Put away: said, and gone.
func close() -> void:
	if is_queued_for_deletion():
		return
	put_away.emit()
	queue_free()


## The line under the card saying what puts it away, with the control drawn in for the device in
## hand: Back, Escape or B, and a click beside the card with a mouse, a tap on a touch screen.
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
