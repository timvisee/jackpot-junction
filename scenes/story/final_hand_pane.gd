class_name FinalHandPane
extends CanvasLayer
## The House's invitation to the Final Hand, put up in the lobby before the match settings while it
## is due, STORY.md 8.1: dealt onto the table face down, see [InvitationCard], and turned over,
## with Take your seat in foil under the cursor and Not now at its foot. Back is Not now.

## Taken, [param take] true, or put off.
signal answered(take: bool)

## How long the card takes to come down onto the table and to turn over, how far it leans as it
## comes and as it lies, and the room kept round it on a small screen.
const DEAL := 0.45
const TURN := 0.38
const LEAN_COMING := -0.26
const LEAN := -0.025
const ROOM := 48.0
const TAKE_WIDTH := 360.0

var take: Button
var not_now: Button
var card: InvitationCard

var _ways: VBoxContainer
var _dealt := false
var _scale := 1.0
var _turn := 1.0


static func add_to(parent: Node) -> FinalHandPane:
	var pane := FinalHandPane.new()
	pane.name = "FinalHandPane"
	parent.add_child(pane)
	return pane


func _ready() -> void:
	# Over the match settings and under the pause menu, as they are.
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	card = InvitationCard.new()
	card.name = "Invitation"
	card.holder = _holder()
	add_child(card)
	_ways = VBoxContainer.new()
	_ways.name = "Ways"
	_ways.alignment = BoxContainer.ALIGNMENT_CENTER
	_ways.add_theme_constant_override("separation", 12)
	_ways.size = Vector2(InvitationCard.SIZE.x, InvitationCard.BUTTONS_ROOM - 30.0)
	_ways.position = Vector2(0.0, InvitationCard.SIZE.y - InvitationCard.BUTTONS_ROOM)
	_ways.modulate.a = 0.0
	card.add_child(_ways)
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
static func _holder() -> String:
	var named := Game.settings.license_holder
	return named if not named.is_empty() else Game.settings.seat_name(0)


## Dealt from above onto the middle of the screen face down, leaning as it comes, then turned over.
func _deal() -> void:
	var screen := card.get_viewport_rect().size
	_scale = minf(1.0, (screen.y - ROOM) / InvitationCard.SIZE.y)
	var lies := screen * 0.5 - InvitationCard.SIZE * 0.5
	card.position = Vector2(lies.x, -InvitationCard.SIZE.y * 1.2)
	card.rotation = LEAN_COMING
	card.scale = Vector2.ONE * _scale
	var deal := create_tween()
	deal.set_parallel(true)
	deal.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	deal.tween_property(card, "position", lies, DEAL)
	deal.tween_property(card, "rotation", LEAN, DEAL)
	deal.chain().tween_callback(_turn_over)
	Audio.play_sfx(&"page", -4.0, 0.05)


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


func _dealt_out() -> void:
	_dealt = true
	take.disabled = false
	not_now.disabled = false
	take.grab_focus()


func _answer(taken: bool) -> void:
	if is_queued_for_deletion() or not _dealt:
		return
	answered.emit(taken)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)
