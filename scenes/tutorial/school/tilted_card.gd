class_name TiltedCard
extends Control
## A [LicenseCard] held up to be looked at, GAME.md 3.8: the card is drawn into a picture of its
## own and shown through a shader that turns the picture a little in perspective, toward where the
## mouse goes, the way the right stick is pushed or the way a phone is tilted from how it was held
## as the card came up, so the card moves in the hand and the hologram on its back plays with it,
## see [member LicenseCard.tilt]; and it is turned right over on a
## click, a tap or [method turn_over], about its upright axis, the other side coming round as it
## passes edge-on. Nothing says there is a back: whoever turns it finds out.

const SHADER := preload("res://scenes/tutorial/school/card_tilt.gdshader")
## How far the card turns toward the mouse at its edge or the stick pushed all the way, in
## radians, and how much of the way left it goes each second after them.
const TURN := 0.26
const FOLLOW := 10.0
## A stick pushed less than this is resting.
const STICK_REST := 0.2
## How far a phone tilts from how it was held, as a share of gravity, for the card to turn all the
## way, about a third of the way to its side; and how much of the way the held pose follows the
## phone each second, so the card settles back once the phone is held still in a new way.
const PHONE_TURN := 0.5
const PHONE_SETTLE := 0.5
## Room round the card in its picture, in pixels of the card, for its corners as it turns, and how
## much sharper the picture is drawn than it is shown, for the small print once turned.
const PAD := 28.0
const SHARPEN := 2.0
## How long turning it over takes, how far the hologram's colors run through the turn, and how
## far back the camera stands, in widths of the card.
const TURN_OVER := 0.55
const TURN_SHINE := 1.6
const DEPTH := 2.4

## The card held.
var card: LicenseCard
## How big the card is shown, a scale on its own size.
var shown := 1.0
## How much of the way it turns toward the mouse, the stick or the phone, 0 to 1: none while it is
## carried somewhere, so it does not swing about under a mouse that stays put.
var calm := 1.0

## Where the card is turned toward, -1 to 1 either way, after the mouse or the stick, smoothed.
var _turn := Vector2.ZERO
## The turn right over under way, in radians, zero while there is none, and which side was up as
## it began.
var _over := 0.0
var _turning := false
var _from := false
## Where the mouse was last seen, once it has moved at all: a card lies flat until it does.
var _mouse_at := Vector2.ZERO
var _mouse_seen := false
## Which way gravity pulls on the phone held still, following it slowly from the pull as the card
## came up; nothing on a machine with no sensor to say.
var _held := Vector3.ZERO
var _picture: SubViewport
var _shown: TextureRect
var _material: ShaderMaterial


## [param held] shown [param at] times its size, with its picture drawn round it.
static func of(held: LicenseCard, at: float) -> TiltedCard:
	var stand := TiltedCard.new()
	stand.card = held
	stand.shown = at
	return stand


func _ready() -> void:
	var picture := LicenseCard.SIZE + Vector2.ONE * PAD * 2.0
	custom_minimum_size = picture * shown
	size = picture * shown
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture = SubViewport.new()
	_picture.name = "Picture"
	_picture.transparent_bg = true
	_picture.disable_3d = true
	_picture.gui_disable_input = true
	_picture.size = Vector2i(picture * SHARPEN)
	_picture.size_2d_override = Vector2i(picture)
	_picture.size_2d_override_stretch = true
	_picture.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_picture)
	card.position = Vector2.ONE * PAD
	card.scale = Vector2.ONE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.add_child(card)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("extent", picture * 0.5 / LicenseCard.SIZE.x)
	_material.set_shader_parameter("depth", DEPTH)
	_shown = TextureRect.new()
	_shown.name = "Shown"
	_shown.texture = _picture.get_texture()
	_shown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shown.stretch_mode = TextureRect.STRETCH_SCALE
	_shown.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_shown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shown.material = _material
	_shown.mouse_filter = Control.MOUSE_FILTER_STOP
	_shown.gui_input.connect(_on_input)
	add_child(_shown)
	_held = Input.get_gravity()
	_aim()


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and not TouchInput.enabled:
		_mouse_at = motion.global_position
		_mouse_seen = true


func _process(delta: float) -> void:
	var pull := Input.get_gravity()
	if _held.is_zero_approx():
		_held = pull
	else:
		_held = _held.lerp(pull, 1.0 - exp(-PHONE_SETTLE * delta))
	_turn = _turn.lerp(_wanted() * calm, 1.0 - exp(-FOLLOW * delta))
	# The hologram sees the turn over too: its colors run through as the back comes round.
	card.tilt = _turn + Vector2(sin(_over) * TURN_SHINE, 0.0)
	_aim()


## Where the card is turned toward: the way the right stick is pushed, or else where the mouse
## has gone about the card, all the way at its edges and beyond, or else the way a phone has been
## tilted since the card came up; nowhere otherwise.
func _wanted() -> Vector2:
	return wanted(Rect2(global_position, size), _mouse_at if _mouse_seen else null, _held)


## Where a card shown over [param over] on the screen is turned toward, see [method _wanted]: the
## right stick, or else the mouse at [param mouse], null until it has moved, or else the phone's
## tilt from [param held]. Anything else held up to the eye this way turns by it too.
static func wanted(over: Rect2, mouse: Variant, held: Vector3) -> Vector2:
	var stick := Input.get_vector(
		InputActions.AIM_LEFT, InputActions.AIM_RIGHT, InputActions.AIM_UP, InputActions.AIM_DOWN
	)
	if stick.length() > STICK_REST:
		return stick.limit_length(1.0)
	if mouse is Vector2 and over.size.x > 0.0 and over.size.y > 0.0:
		var away := ((mouse as Vector2) - over.get_center()) / (over.size * 0.5)
		return away.clamp(-Vector2.ONE, Vector2.ONE)
	return tilt_of_phone(Input.get_gravity(), held)


## How far a phone pulled on by gravity [param now] has been tilted from [param held], the pull as
## the card came up, as a turn to give the card: its right edge forward as the right side of the
## phone dips, its bottom edge forward as the bottom dips, all the way at [constant PHONE_TURN]
## of gravity. Nothing for a machine with no sensor, which reads no pull at all. The pull comes
## in the screen's own axes, x across it and y up it.
static func tilt_of_phone(now: Vector3, held: Vector3) -> Vector2:
	if now.is_zero_approx() or held.is_zero_approx():
		return Vector2.ZERO
	var g := maxf(held.length(), 0.001)
	var tilted := (now - held) / g
	return (Vector2(tilted.x, -tilted.y) / PHONE_TURN).clamp(-Vector2.ONE, Vector2.ONE)


## The picture turned as the card is: the tilt, and the turn over on top of it. In the middle of
## a turn over, the side drawn is the one the camera would see, which changes as the card passes
## edge-on, where the shader starts reading the picture mirrored. The tilt up or down is carried
## round with it, see [method pitch].
func _aim() -> void:
	var yaw := _turn.x * TURN + _over
	if _turning:
		var back_in_view := cos(yaw) < 0.0
		if card.flipped != (_from != back_in_view):
			card.other_side()
	_material.set_shader_parameter("turn", Vector2(yaw, pitch(_turn.y * TURN, _over)))


## The tilt up or down, [param tilt] in radians, as drawn [param over] radians into a turn over.
## Seen from behind, a card tilted up reads tilted down, so the tilt goes over with the card, eased
## from itself to its opposite: come round, the back is drawn just as the front is once the turn is
## put back to nothing, and the card rests where the turn left it, rather than jumping.
static func pitch(tilt: float, over: float) -> float:
	return tilt * cos(over)


## Turns the card right over, to its back or its front again, about its upright axis, the way
## back the way it came, taking [param takes].
func turn_over(takes := TURN_OVER) -> void:
	if _turning:
		return
	_turning = true
	_from = card.flipped
	var way := -1.0 if _from else 1.0
	var turn := create_tween()
	turn.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	turn.tween_method(_turn_by, 0.0, PI * way, takes)
	turn.tween_callback(_turned_over)
	Audio.play_sfx(&"page", -10.0, 0.0)


func _turn_by(angle: float) -> void:
	_over = angle
	_aim()


## Round: the side up stays as it came round, and the picture reads it straight again.
func _turned_over() -> void:
	_turning = false
	_over = 0.0
	_aim()


## Whether the card is in the middle of turning over.
func is_turning() -> bool:
	return _turning


## Where the card is turned toward, -1 to 1 either way.
func turned() -> Vector2:
	return _turn


## A click or a tap on the card turns it over.
func _on_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
	):
		get_viewport().set_input_as_handled()
		turn_over()
