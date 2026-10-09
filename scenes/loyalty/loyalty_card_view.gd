class_name LoyaltyCardView
extends Control
## The profile's loyalty card shown in full over the program's map, GAME.md 8.9, as the driver
## license is, see [LicenseView]: held up on a [HeldCard], turned a little toward the mouse, the
## stick or the phone, its gold and its chip catching the light. A click or a tap on it, or accept,
## turns it over; a click or a tap beside it, a right click or Back puts it away, back down onto the
## card in the dialog's corner it grew up off.

signal put_away

## How big it is shown, a share of the room's height and at most of its width; how long it takes
## to grow up off the corner and to go back down, and to turn over; and its shade.
const FULL := 0.56
const WIDEST := 0.8
const FLY := 0.32
const FLY_BACK := 0.26
const TURN := 0.26
const SHADE := Color(0.0, 0.0, 0.0, 0.62)
## Room under the card for the line saying how to turn it over and put it away.
const LINE_UNDER := 34.0

var card: LoyaltyCard
var shine: LoyaltyCard
var held: HeldCard
var away_line: Label

## The card in the corner it grew up off, hidden while it is up.
var _from: Control
var _shade: ColorRect
var _shown_at := 0
var _closing := false
var _turning := false


## [param profile]'s card up over [param parent], growing up off [param grows_from].
static func open(parent: Control, profile: Profile, grows_from: Control) -> LoyaltyCardView:
	var view := LoyaltyCardView.new()
	view.name = "CardView"
	view._from = grows_from
	view.card = LoyaltyCard.of(profile)
	view.shine = LoyaltyCard.of(profile)
	view.shine.shine_only = true
	parent.add_child(view)
	return view


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = SHADE
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	held = HeldCard.of(card, LoyaltyCard.SIZE, shine)
	held.name = "Held"
	add_child(held)
	away_line = MenuTheme.subtitle(
		LicenseView.AWAY_TOUCH if TouchInput.enabled else LicenseView.AWAY_MOUSE, Type.LABEL
	)
	away_line.name = "Away"
	away_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	away_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(away_line)
	gui_input.connect(_on_input)
	resized.connect(_lay)
	_shown_at = Time.get_ticks_msec()
	_lay()
	_rise()


## How big the card is in its place.
func _scale() -> float:
	return minf(size.y * FULL / LoyaltyCard.SIZE.y, size.x * WIDEST / LoyaltyCard.SIZE.x)


## Its place: in the middle of the room, the line under it.
func _lay() -> void:
	if not _turning and not _closing and held.scale.x > 0.0:
		held.position = size * 0.5
	var under := size.y * 0.5 + LoyaltyCard.SIZE.y * _scale() * 0.5 + 18.0
	away_line.position = Vector2(0.0, under)
	away_line.size = Vector2(size.x, LINE_UNDER)


## Where the corner's card is in the room: its middle and how big it is shown.
func _corner() -> Array:
	if _from == null or not is_instance_valid(_from):
		return [size * 0.5, _scale() * 0.2]
	var rect := _from.get_global_rect()
	var mine := get_global_rect()
	return [rect.get_center() - mine.position, rect.size.x / LoyaltyCard.SIZE.x]


func _rise() -> void:
	var corner := _corner()
	held.position = corner[0]
	held.scale = Vector2.ONE * float(corner[1])
	_shade.modulate.a = 0.0
	away_line.modulate.a = 0.0
	if _from != null and is_instance_valid(_from):
		_from.modulate.a = 0.0
	var up := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	up.tween_property(held, "position", size * 0.5, FLY)
	up.tween_property(held, "scale", Vector2.ONE * _scale(), FLY)
	up.tween_property(_shade, "modulate:a", 1.0, FLY)
	up.tween_property(away_line, "modulate:a", 1.0, FLY).set_delay(FLY * 0.5)


## The other side up: narrowed to its edge, turned, and widened again.
func turn_over() -> void:
	if _turning or _closing:
		return
	_turning = true
	Audio.play_sfx(&"page", -8.0, 0.05)
	var wide := held.scale.x
	var turning := create_tween().set_trans(Tween.TRANS_SINE)
	turning.tween_property(held, "scale:x", 0.0, TURN * 0.5).set_ease(Tween.EASE_IN)
	turning.tween_callback(_other_side)
	turning.tween_property(held, "scale:x", wide, TURN * 0.5).set_ease(Tween.EASE_OUT)
	turning.tween_callback(func() -> void: _turning = false)


func _other_side() -> void:
	card.back = not card.back
	shine.back = card.back
	card.queue_redraw()
	shine.queue_redraw()
	held.refresh()


## Put away: said at once, so the dialog has its keys back, and gone once it is back down on the
## corner's card, the front up.
func close() -> void:
	if _closing:
		return
	_closing = true
	put_away.emit()
	var corner := _corner()
	var down := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	down.tween_property(held, "position", corner[0], FLY_BACK)
	down.tween_property(held, "scale", Vector2.ONE * float(corner[1]), FLY_BACK)
	down.tween_property(_shade, "modulate:a", 0.0, FLY_BACK)
	down.tween_property(away_line, "modulate:a", 0.0, FLY_BACK * 0.5)
	down.chain().tween_callback(_gone)


func _gone() -> void:
	if _from != null and is_instance_valid(_from):
		_from.modulate.a = 1.0
	queue_free()


## A click or a tap on the card turns it over, beside it puts it away, as does a right click; none
## for a moment after it comes up, the tap that brought it up not taken for one beside it.
func _on_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	var at := Vector2.ZERO
	if button != null and button.pressed:
		if button.button_index == MOUSE_BUTTON_RIGHT:
			close()
			accept_event()
			return
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		at = button.position
	elif touch != null and touch.pressed:
		at = touch.position
	else:
		return
	accept_event()
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
