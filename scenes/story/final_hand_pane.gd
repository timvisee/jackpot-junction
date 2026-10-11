class_name FinalHandPane
extends CanvasLayer
## The House's invitation to the Final Hand, put up in the lobby before the match settings while it
## is due, STORY.md 8.1: dealt onto the table face down, see [InvitationCard], and turned over, held
## up as the opening invitation is, see [HeldCard], turning toward the mouse, the stick or the phone
## with the light on its foil, Take your seat in foil under the cursor and Not now under the card.
## Back is Not now. Taken, the golden ticket comes up from behind the card, see [GoldenTicket], is
## shown a moment and drops away; and at the door, see [method admit], it comes back and has its
## ADMIT ONE torn off.

## Taken, [param take] true, or put off.
signal answered(take: bool)
## At the door: the ticket's stub torn off, and the match to begin.
signal admitted

## How long the card takes to come down onto the table and to turn over, how far it leans as it
## comes and as it lies, the room kept round it on a small screen, and the room under it for the
## buttons.
const DEAL := 0.45
const TURN := 0.38
const LEAN_COMING := -0.26
const LEAN := -0.025
const ROOM := 48.0
const BUTTONS := 140.0
const TAKE_WIDTH := 360.0
## The ticket taken: out from behind the card, where it lies hidden, smaller than the card by
## [constant HIDDEN] of its width; forward over the card; held up long enough to read; and dropped
## away.
const HIDDEN := 0.9
## The ticket's own slant as it comes out, a few degrees off the card's, so it reads as a thing of
## its own rather than part of the card.
const REVEAL_SLANT := 0.075
const OUT := 0.5
const FORWARD := 0.4
const SHOWN := 2.8
const DROP := 0.5
## How the ticket leans held up over the card: the other way to the card's lean, a few degrees, so
## the two never line up into one thing. Nearly the card's own, it read as part of it.
const TICKET_LEAN := 0.06
## At the door: up from below, held a moment either side of the tear.
const COME := 0.4
const BEFORE_TEAR := 0.35
const AFTER_TEAR := 0.45

var take: Button
var not_now: Button
var card: InvitationCard
var ticket: GoldenTicket

## The card held, moved and turned, see [HeldCard].
var _held: HeldCard

var _shade: ColorRect
var _ways: VBoxContainer
var _dealt := false
var _taking := false
var _scale := 1.0
var _turn := 1.0
## Whether this pane is the door, the ticket alone, rather than the invitation.
var _door := false


static func add_to(parent: Node) -> FinalHandPane:
	var pane := FinalHandPane.new()
	pane.name = "FinalHandPane"
	parent.add_child(pane)
	return pane


## At the door, as the match is about to begin: the ticket alone, brought back up and torn.
static func admit(parent: Node) -> FinalHandPane:
	var pane := FinalHandPane.new()
	pane.name = "FinalHandDoor"
	pane._door = true
	parent.add_child(pane)
	return pane


func _ready() -> void:
	# Over the match settings and under the pause menu, as they are.
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shade = ColorRect.new()
	_shade.color = Color(0.0, 0.0, 0.0, 0.7)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	ticket = GoldenTicket.make(holder_name(), Game.settings.profile.license_number)
	ticket.visible = false
	add_child(ticket)
	if _door:
		_come_to_the_door()
		return
	card = InvitationCard.new()
	card.name = "Invitation"
	card.holder = holder_name()
	_held = HeldCard.of(card, InvitationCard.SIZE)
	_held.name = "Held"
	_held.follow = 0.0
	add_child(_held)
	_ways = VBoxContainer.new()
	_ways.name = "Ways"
	_ways.alignment = BoxContainer.ALIGNMENT_CENTER
	_ways.add_theme_constant_override("separation", 12)
	_ways.modulate.a = 0.0
	add_child(_ways)
	take = MenuTheme.primary(MenuTheme.button(StoryLines.TAKE_SEAT))
	take.name = "TakeSeat"
	take.custom_minimum_size.x = TAKE_WIDTH
	take.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	take.pressed.connect(_answer.bind(true))
	_ways.add_child(take)
	not_now = MenuTheme.button(StoryLines.NOT_NOW, Type.LABEL)
	not_now.name = "NotNow"
	not_now.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	not_now.pressed.connect(_answer.bind(false))
	_ways.add_child(not_now)
	for button: Button in [take, not_now]:
		var other := not_now if button == take else take
		button.focus_neighbor_top = button.get_path_to(other)
		button.focus_neighbor_bottom = button.get_path_to(other)
		button.focus_neighbor_left = button.get_path()
		button.focus_neighbor_right = button.get_path()
	take.disabled = true
	not_now.disabled = true
	_deal()


## The name the House has on file for the player: the license's, or the first seat's.
static func holder_name() -> String:
	var named := Game.settings.license_holder
	return named if not named.is_empty() else Game.settings.seat_name(0)


## Dealt from above onto the screen face down, leaning as it comes, then turned over; the buttons
## wait under where it lies.
func _deal() -> void:
	var screen := _screen()
	_scale = minf(1.0, (screen.y - ROOM - BUTTONS) / InvitationCard.SIZE.y)
	var shown := InvitationCard.SIZE * _scale
	var top := (screen.y - shown.y - BUTTONS) * 0.5
	# Held by its middle, which is where it lands.
	var lies := Vector2(screen.x * 0.5, top + shown.y * 0.5)
	_held.position = Vector2(lies.x, -InvitationCard.SIZE.y * 0.7)
	_held.rotation = LEAN_COMING
	_held.scale = Vector2.ONE * _scale
	_ways.size = Vector2(TAKE_WIDTH + 40.0, BUTTONS - 24.0)
	_ways.position = Vector2(screen.x * 0.5 - _ways.size.x * 0.5, top + shown.y + 24.0)
	var deal := create_tween()
	deal.set_parallel(true)
	deal.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	deal.tween_property(_held, "position", lies, DEAL)
	deal.tween_property(_held, "rotation", LEAN, DEAL)
	deal.chain().tween_callback(_turn_over)
	Audio.play_sfx(&"page", -4.0, 0.05)


func _screen() -> Vector2:
	return _shade.get_viewport_rect().size


func _turn_over() -> void:
	var over := create_tween()
	over.set_trans(Tween.TRANS_SINE)
	over.tween_method(_set_turn, 1.0, 0.0, TURN * 0.5).set_ease(Tween.EASE_IN)
	over.tween_callback(
		func() -> void:
			card.show_face(true)
			_held.refresh()
	)
	over.tween_method(_set_turn, 0.0, 1.0, TURN * 0.5).set_ease(Tween.EASE_OUT)
	over.tween_callback(_dealt_out)
	over.tween_property(_ways, "modulate:a", 1.0, 0.25)
	Audio.play_sfx(&"page", -6.0, 0.08)


func _set_turn(amount: float) -> void:
	_turn = maxf(amount, 0.001)
	_held.scale = Vector2(_scale * _turn, _scale)


## Whether the card is down and turned over, its buttons there to press.
func dealt() -> bool:
	return _dealt


## Whether Take your seat has been pressed and the ticket is showing.
func taking() -> bool:
	return _taking


func _dealt_out() -> void:
	_dealt = true
	take.disabled = false
	not_now.disabled = false
	take.grab_focus()
	create_tween().tween_property(_held, "follow", 1.0, 0.3)


func _answer(taken: bool) -> void:
	if is_queued_for_deletion() or not _dealt or _taking:
		return
	if taken:
		_take_the_seat()
		return
	answered.emit(false)
	queue_free()


## The ticket: out from behind the card, where it lay hidden whole, to the side clear of it;
## forward over the card, full size, as the card dims; held up long enough to read; and dropped away
## with the card. Then the seat is taken.
func _take_the_seat() -> void:
	_taking = true
	take.disabled = true
	not_now.disabled = true
	var screen := _screen()
	var size_on := minf(1.0, (screen.x - ROOM * 2.0) / GoldenTicket.SIZE.x)
	var middle := _held.position
	var card_shown := InvitationCard.SIZE * _scale
	var shown := GoldenTicket.SIZE * size_on
	# Behind the card, narrower than it, so none of it shows until it moves.
	var hidden := minf(size_on, card_shown.x * HIDDEN / GoldenTicket.SIZE.x)
	var small := GoldenTicket.SIZE * hidden
	ticket.scale = Vector2.ONE * hidden
	ticket.rotation = REVEAL_SLANT
	ticket.position = middle - GoldenTicket.SIZE * 0.5
	ticket.visible = true
	# Out to the right until it is clear of the card, as far as the screen lets it.
	var out_x := minf(
		middle.x + card_shown.x * 0.5 + small.x * 0.5 + 24.0, screen.x - small.x * 0.5 - 16.0
	)
	var out := Vector2(out_x, middle.y - card_shown.y * 0.12)
	var ahead := Vector2(screen.x * 0.5, screen.y * 0.45)
	var gone := Vector2(screen.x * 0.5, screen.y + shown.y)
	var show := create_tween()
	show.set_trans(Tween.TRANS_CUBIC)
	show.tween_property(_ways, "modulate:a", 0.0, 0.15)
	show.parallel().tween_property(_held, "follow", 0.0, 0.15)
	show.tween_property(ticket, "position", out - GoldenTicket.SIZE * 0.5, OUT).set_ease(
		Tween.EASE_OUT
	)
	show.parallel().tween_property(ticket, "rotation", REVEAL_SLANT + 0.02, OUT)
	show.tween_callback(move_child.bind(ticket, -1))
	show.tween_property(ticket, "position", ahead - GoldenTicket.SIZE * 0.5, FORWARD).set_ease(
		Tween.EASE_IN_OUT
	)
	show.parallel().tween_property(ticket, "scale", Vector2.ONE * size_on, FORWARD)
	show.parallel().tween_property(ticket, "rotation", TICKET_LEAN, FORWARD)
	show.parallel().tween_property(_held, "modulate", Color(0.45, 0.45, 0.45), FORWARD)
	show.tween_interval(SHOWN)
	show.tween_property(ticket, "position", gone - GoldenTicket.SIZE * 0.5, DROP).set_ease(
		Tween.EASE_IN
	)
	show.parallel().tween_property(ticket, "rotation", TICKET_LEAN + 0.35, DROP).set_ease(
		Tween.EASE_IN
	)
	show.parallel().tween_property(_held, "modulate:a", 0.0, DROP)
	show.parallel().tween_property(_shade, "modulate:a", 0.0, DROP)
	show.tween_callback(_seated)
	Audio.play_sfx(&"page", -4.0, 0.08)


func _seated() -> void:
	answered.emit(true)
	queue_free()


## At the door: the ticket up from below into the middle, held, its stub torn off, and held again;
## then in.
func _come_to_the_door() -> void:
	var screen := _screen()
	var size_on := minf(1.0, (screen.x - ROOM * 2.0) / GoldenTicket.SIZE.x)
	ticket.scale = Vector2.ONE * size_on
	ticket.rotation = TICKET_LEAN
	var middle := screen * 0.5 - GoldenTicket.SIZE * 0.5
	ticket.position = Vector2(middle.x, screen.y + GoldenTicket.SIZE.y)
	ticket.visible = true
	_shade.modulate.a = 0.0
	var door := create_tween()
	door.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	door.tween_property(_shade, "modulate:a", 1.0, COME)
	door.parallel().tween_property(ticket, "position", middle, COME)
	door.tween_interval(BEFORE_TEAR)
	door.tween_callback(ticket.tear.bind(_torn))
	Audio.play_sfx(&"page", -4.0, 0.08)


func _torn() -> void:
	var after := create_tween()
	after.tween_interval(AFTER_TEAR)
	after.tween_callback(
		func() -> void:
			admitted.emit()
			queue_free()
	)


func _input(event: InputEvent) -> void:
	if not _door and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		MenuTheme.back_sound()
		_answer(false)
