class_name LoyaltyCardView
extends Control
## The profile's loyalty card shown in full over the program's map, GAME.md 8.9, as the driver
## license is and laid out as it is, see [LicenseView]: held up on a [HeldCard], turned a little
## toward the mouse, the stick or the phone, its gold and its chip catching the light, and under it
## the same two buttons, turn it over and put it away, the binds of keys and pads drawn on them,
## and the line saying what the mouse or a finger does. A click or a tap on the card, the hand's
## button or accept turns it over; a click or a tap beside it, a right click or Back puts it away,
## back down onto the card in the dialog's corner it grew up off.

signal put_away

## How big it is shown: as wide as the license is in its view.
const FULL := LicenseCard.SIZE.x * LicenseView.FULL / LoyaltyCard.SIZE.x
const FLY := LicenseView.FLY
const FLY_BACK := LicenseView.FLY_BACK
const TURN := TiltedCard.TURN_OVER

var card: LoyaltyCard
var shine: LoyaltyCard
var held: HeldCard
var turn: Button
var away: Button
var away_line: Control
var keyboard := true

## The card in the corner it grew up off, hidden while it is up.
var _from: Control
## Its place in the column, and how far it has come from the corner to it, 0 to 1.
var _place: Control
var _fly := 0.0
var _shade: ColorRect
var _round: Array[CanvasItem] = []
var _shown_at := 0
var _closing := false
var _pointer := false


## [param profile]'s card, small, [param scale] of its size, for a place in a layout to grow its
## full view off: picked as a button is, by the mouse over it or the cursor moved onto it, its mark
## round it, and a click, a tap or accept calls [param shown], which shows it in full.
static func corner(
	profile: Profile, scale: float, shown: Callable, takes_cursor := true
) -> Control:
	var corner := Control.new()
	corner.name = "Card"
	corner.custom_minimum_size = LoyaltyCard.SIZE * scale
	corner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	corner.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	corner.mouse_filter = Control.MOUSE_FILTER_STOP
	corner.focus_mode = Control.FOCUS_ALL if takes_cursor else Control.FOCUS_NONE
	corner.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var card := LoyaltyCard.of(profile)
	card.scale = Vector2.ONE * scale
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.add_child(card)
	# Drawn from a picture of it once one is made, see [KeptCard]: as itself it is a score of draws.
	var kept := KeptCard.new()
	kept.name = "Kept"
	kept.card = card
	kept.custom_minimum_size = corner.custom_minimum_size
	kept.size = corner.custom_minimum_size
	corner.add_child(kept)
	var mark := Control.new()
	mark.name = "FocusMark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.draw.connect(
		func() -> void:
			if corner.has_focus():
				var whole := Rect2(Vector2.ZERO, LoyaltyCard.SIZE * scale)
				FocusMark.draw_on(mark, whole, LoyaltyCard.CORNER * scale, SIDE_LEFT)
	)
	corner.add_child(mark)
	corner.focus_entered.connect(mark.queue_redraw)
	corner.focus_exited.connect(mark.queue_redraw)
	if not TouchInput.enabled and takes_cursor:
		corner.mouse_entered.connect(corner.grab_focus)
	corner.gui_input.connect(
		func(event: InputEvent) -> void:
			var button := event as InputEventMouseButton
			var touch := event as InputEventScreenTouch
			var left := button != null and button.button_index == MOUSE_BUTTON_LEFT
			if (
				(left and button.pressed)
				or (touch != null and touch.pressed)
				or event.is_action_pressed(&"ui_accept")
			):
				corner.accept_event()
				shown.call()
	)
	return corner


## A card in its corner drawn from a picture of it, made once a run for what is printed on it and
## the screen's pixels it is shown at, see [KeptPictures]: the card itself, beside it, is drawn only
## until the picture is ready, and again should what it says change.
class KeptCard:
	extends Control

	const GROUP := &"kept_loyalty_cards"

	var card: LoyaltyCard

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_to_group(GROUP)

	func _draw() -> void:
		var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
		var pixels := Vector2i((size * scale_by).ceil())
		var printed := [card.program, card.line, card.holder, card.member, card.laps, card.back]
		var drawn := card
		var picture := KeptPictures.of(
			self,
			"loyalty_card|%s" % [printed],
			pixels,
			func() -> Control:
				var holder := Control.new()
				var copy := LoyaltyCard.new()
				for property: String in ["program", "line", "holder", "member", "laps", "back"]:
					copy.set(property, drawn.get(property))
				copy.scale = Vector2(pixels) / LoyaltyCard.SIZE
				holder.add_child(copy)
				return holder,
			GROUP
		)
		_show_card.call_deferred(picture == null)
		if picture != null:
			draw_texture_rect(picture, Rect2(Vector2.ZERO, size), false)

	func _show_card(on: bool) -> void:
		if is_instance_valid(card):
			card.visible = on


## [param profile]'s card up over [param parent], growing up off [param grows_from], its line and
## binds drawn for a keyboard and mouse when [param on_keyboard] or for a pad otherwise.
static func open(
	parent: Control, profile: Profile, grows_from: Control, on_keyboard := true
) -> LoyaltyCardView:
	var view := LoyaltyCardView.new()
	view.name = "CardView"
	view._from = grows_from
	view.keyboard = on_keyboard
	view.card = LoyaltyCard.of(profile)
	view.shine = LoyaltyCard.of(profile)
	view.shine.shine_only = true
	parent.add_child(view)
	return view


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_shown_at = Time.get_ticks_msec()
	_shade = MenuTheme.closer_shade(0.7)
	add_child(_shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	_place = Control.new()
	_place.name = "Place"
	_place.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place.custom_minimum_size = LoyaltyCard.SIZE * FULL
	column.add_child(_place)
	var row := HBoxContainer.new()
	row.name = "Buttons"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	turn = _icon_button("TurnOver", HouseArt.turning(), LicenseView.TURN_WORD, &"ui_accept")
	turn.pressed.connect(turn_over)
	row.add_child(turn)
	away = _icon_button("Away", HouseArt.cross(), LicenseView.AWAY_WORD, &"ui_cancel")
	away.pressed.connect(close)
	row.add_child(away)
	away_line = Control.new()
	away_line.name = "Away"
	away_line.custom_minimum_size = Vector2(0.0, 24.0)
	away_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(away_line)
	held = HeldCard.of(card, LoyaltyCard.SIZE, shine)
	held.name = "Held"
	held.side_changed.connect(_show_side)
	add_child(held)
	_pointer = Game.last_input_pointer
	say_away()
	_show_binds()
	gui_input.connect(_on_beside)
	_round = [_shade, row, away_line]
	_rise()
	# Nothing here takes the cursor, so whatever had it under the view lets it go.
	get_viewport().gui_release_focus()
	Audio.play_sfx(&"joker_offer", MenuTheme.MOVE_DB, 0.0)


## Up off the corner's card to its place, the shade and the buttons coming up round it, once the
## column has laid it out.
func _rise() -> void:
	held.visible = false
	for part: CanvasItem in _round:
		part.modulate.a = 0.0
	if _from != null and is_instance_valid(_from):
		_from.modulate.a = 0.0
	await get_tree().process_frame
	if _closing:
		return
	_set_fly(0.0)
	held.visible = true
	var up := create_tween().set_parallel(true)
	for part: CanvasItem in _round:
		up.tween_property(part, "modulate:a", 1.0, FLY)
	up.tween_method(_set_fly, 0.0, 1.0, FLY).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Where the corner's card is in the view: its middle and how big it is shown.
func _corner() -> Array:
	if _from == null or not is_instance_valid(_from):
		return [_rest(), FULL * 0.2]
	var rect := _from.get_global_rect()
	return [rect.get_center() - get_global_rect().position, rect.size.x / LoyaltyCard.SIZE.x]


## The middle of its place in the view.
func _rest() -> Vector2:
	return _place.get_global_rect().get_center() - get_global_rect().position


## The card between the corner and its place, [param amount] of the way.
func _set_fly(amount: float) -> void:
	_fly = amount
	var corner := _corner()
	held.position = (corner[0] as Vector2).lerp(_rest(), amount)
	held.scale = Vector2.ONE * lerpf(float(corner[1]), FULL, amount)
	held.follow = amount


func _process(_delta: float) -> void:
	# In its place, it follows the place as the room is laid out again.
	if _fly >= 1.0 and not _closing:
		held.position = _rest()


## The other side up, turned right over about its upright axis as the license is.
func turn_over() -> void:
	if not _closing:
		held.turn_over()


## The side the eye sees as the card passes edge-on, drawn: its back, or its front again.
func _show_side(back: bool) -> void:
	card.back = back
	shine.back = back
	card.queue_redraw()
	shine.queue_redraw()
	held.refresh()


## Whether the card is turning over now.
func is_turning() -> bool:
	return held.is_turning()


## Put away: said at once, so the dialog has its keys back, and gone once it is back down on the
## corner's card.
func close() -> void:
	if _closing or is_queued_for_deletion():
		return
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	put_away.emit()
	# Turned face up again on the way down, as the license is.
	if card.back and not held.is_turning():
		held.turn_over(FLY_BACK)
	var down := create_tween().set_parallel(true)
	for part: CanvasItem in _round:
		down.tween_property(part, "modulate:a", 0.0, FLY_BACK)
	down.tween_method(_set_fly, _fly, 0.0, FLY_BACK).set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_IN_OUT
	)
	down.chain().tween_callback(_gone)


func _gone() -> void:
	if _from != null and is_instance_valid(_from):
		_from.modulate.a = 1.0
	queue_free()


## A button for the mouse under the card, as the license's are: [param picture] on it, [param word]
## its tooltip, and the bind of [param action] drawn on it for keys and pads.
func _icon_button(named: String, picture: Texture2D, word: String, action: StringName) -> Button:
	var button := MenuTheme.button("", Type.BODY)
	button.name = named
	button.icon = picture
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.tooltip_text = word
	button.custom_minimum_size.x = LicenseView.ICON_WIDTH
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
	keyboard = LicenseView.keyboard_after(event, keyboard)
	_pointer = ButtonBinds.pointer_after(event, _pointer)
	if was != keyboard or was_pointer != _pointer:
		say_away()
		_show_binds()
	var click := event as InputEventMouseButton
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		turn_over()
	elif click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if Time.get_ticks_msec() - _shown_at >= LicenseView.SETTLE_MS:
			close()


func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		MenuTheme.back_sound()
		close()
	elif event is InputEventKey or event is InputEventJoypadButton:
		# Up over the map, the map under it hears nothing: no arrow drives its cursor.
		get_viewport().set_input_as_handled()


## Once the view has settled, a click or a tap on the card turns it over, and beside it puts it
## away.
func _on_beside(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	var at := Vector2.ZERO
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		at = click.position
	elif touch != null and touch.pressed:
		at = touch.position
	else:
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() - _shown_at < LicenseView.SETTLE_MS:
		return
	if on_card(at):
		turn_over()
	else:
		close()


## Whether [param at], in the view, is on the card where it is shown.
func on_card(at: Vector2) -> bool:
	var shown := LoyaltyCard.SIZE * held.scale.abs()
	return Rect2(held.position - shown * 0.5, shown).has_point(at)


## The line under the buttons saying how to turn it over and put it away with a mouse or a finger,
## as the license's; nothing with keys or a pad, whose binds are on the buttons already.
func say_away() -> void:
	if away_line == null or not is_instance_valid(away_line):
		return
	for old: Node in away_line.get_children():
		away_line.remove_child(old)
		old.queue_free()
	var row: Control
	if TouchInput.enabled:
		row = MenuTheme.subtitle(LicenseView.AWAY_TOUCH, Type.LABEL)
	elif _pointer:
		row = MenuTheme.subtitle(LicenseView.AWAY_MOUSE, Type.LABEL)
	else:
		return
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	away_line.add_child(row)
