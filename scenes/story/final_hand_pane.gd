class_name FinalHandPane
extends CanvasLayer
## The House's invitation to the Final Hand, put up in the lobby before the match settings while it
## is due, STORY.md 8.1: dealt onto the table face down, see [InvitationCard], and turned over, Take
## your seat in foil under the cursor and Not now under the card. Back is Not now. Taken, the golden
## ticket comes up from behind the card, see [GoldenTicket], is shown a moment and drops away; and
## at the door, see [method admit], it comes back and has its ADMIT ONE torn off.

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
## The ticket taken: up out from behind the card, forward over it, shown, and dropped away.
const RISE := 0.4
const FORWARD := 0.35
const SHOWN := 1.1
const DROP := 0.5
const TICKET_LEAN := -0.03
## At the door: up from below, held a moment either side of the tear.
const COME := 0.4
const BEFORE_TEAR := 0.35
const AFTER_TEAR := 0.45

var take: Button
var not_now: Button
var card: InvitationCard
var ticket: GoldenTicket

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
	add_child(card)
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
	# The card scales about its middle, so its rect is placed for where its middle lands.
	var lies := Vector2(screen.x * 0.5, top + shown.y * 0.5) - InvitationCard.SIZE * 0.5
	card.position = Vector2(lies.x, -InvitationCard.SIZE.y * 1.2)
	card.rotation = LEAN_COMING
	card.scale = Vector2.ONE * _scale
	_ways.size = Vector2(TAKE_WIDTH + 40.0, BUTTONS - 24.0)
	_ways.position = Vector2(screen.x * 0.5 - _ways.size.x * 0.5, top + shown.y + 24.0)
	var deal := create_tween()
	deal.set_parallel(true)
	deal.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	deal.tween_property(card, "position", lies, DEAL)
	deal.tween_property(card, "rotation", LEAN, DEAL)
	deal.chain().tween_callback(_turn_over)
	Audio.play_sfx(&"page", -4.0, 0.05)


func _screen() -> Vector2:
	return _shade.get_viewport_rect().size


func _turn_over() -> void:
	var over := create_tween()
	over.set_trans(Tween.TRANS_SINE)
	over.tween_method(_set_turn, 1.0, 0.0, TURN * 0.5).set_ease(Tween.EASE_IN)
	over.tween_callback(func() -> void: card.show_face(true))
	over.tween_method(_set_turn, 0.0, 1.0, TURN * 0.5).set_ease(Tween.EASE_OUT)
	over.tween_callback(_dealt_out)
	over.tween_property(_ways, "modulate:a", 1.0, 0.25)
	Audio.play_sfx(&"page", -6.0, 0.08)


func _set_turn(amount: float) -> void:
	_turn = maxf(amount, 0.001)
	card.scale = Vector2(_scale * _turn, _scale)


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


func _answer(taken: bool) -> void:
	if is_queued_for_deletion() or not _dealt or _taking:
		return
	if taken:
		_take_the_seat()
		return
	answered.emit(false)
	queue_free()


## The ticket: up out from behind the card, forward over it as the card dims, a moment to be seen,
## and dropped away with the card; then the seat is taken.
func _take_the_seat() -> void:
	_taking = true
	take.disabled = true
	not_now.disabled = true
	var screen := _screen()
	var size_on := minf(_scale, (screen.x - ROOM * 2.0) / GoldenTicket.SIZE.x)
	var middle := card.position + InvitationCard.SIZE * 0.5
	var shown := GoldenTicket.SIZE * size_on
	ticket.scale = Vector2.ONE * size_on * 0.9
	ticket.rotation = LEAN
	ticket.position = middle - GoldenTicket.SIZE * 0.5
	ticket.visible = true
	# Up until most of it shows over the card, its top kept on the screen.
	var card_top := middle.y - InvitationCard.SIZE.y * _scale * 0.5
	var risen := Vector2(middle.x, maxf(card_top - shown.y * 0.1, shown.y * 0.45 + ROOM * 0.5))
	var ahead := Vector2(screen.x * 0.5, screen.y * 0.45)
	var gone := Vector2(screen.x * 0.5, screen.y + shown.y)
	var show := create_tween()
	show.set_trans(Tween.TRANS_CUBIC)
	show.tween_property(_ways, "modulate:a", 0.0, 0.15)
	show.tween_property(ticket, "position", risen - GoldenTicket.SIZE * 0.5, RISE).set_ease(
		Tween.EASE_OUT
	)
	show.tween_callback(move_child.bind(ticket, -1))
	show.tween_property(ticket, "position", ahead - GoldenTicket.SIZE * 0.5, FORWARD).set_ease(
		Tween.EASE_IN_OUT
	)
	show.parallel().tween_property(ticket, "scale", Vector2.ONE * size_on, FORWARD)
	show.parallel().tween_property(ticket, "rotation", TICKET_LEAN, FORWARD)
	show.parallel().tween_property(card, "modulate", Color(0.45, 0.45, 0.45), FORWARD)
	show.tween_interval(SHOWN)
	show.tween_property(ticket, "position", gone - GoldenTicket.SIZE * 0.5, DROP).set_ease(
		Tween.EASE_IN
	)
	show.parallel().tween_property(ticket, "rotation", TICKET_LEAN + 0.35, DROP).set_ease(
		Tween.EASE_IN
	)
	show.parallel().tween_property(card, "modulate:a", 0.0, DROP)
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
		_answer(false)
