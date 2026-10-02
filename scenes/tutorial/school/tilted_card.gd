class_name TiltedCard
extends Control
## A [LicenseCard] held up to be looked at, GAME.md 3.8: the card is drawn into a picture of its
## own and shown through a shader that turns the picture a little in perspective, toward where the
## mouse goes or the way the right stick is pushed, so the card moves in the hand and the hologram
## on its back plays with it, see [member LicenseCard.tilt]; and it is turned right over on a
## click, a tap or [method turn_over], about its upright axis, the other side coming round as it
## passes edge-on. Nothing says there is a back: whoever turns it finds out.

const SHADER := preload("res://scenes/tutorial/school/card_tilt.gdshader")
## How far the card turns toward the mouse at its edge or the stick pushed all the way, in
## radians, and how much of the way left it goes each second after them.
const TURN := 0.26
const FOLLOW := 10.0
## A stick pushed less than this is resting.
const STICK_REST := 0.2
## Room round the card in its picture, in pixels of the card, for its corners as it turns, and how
## much sharper the picture is drawn than it is shown, for the small print once turned.
const PAD := 28.0
const SHARPEN := 2.0
## How long turning it over takes, and how far back the camera stands, in widths of the card.
const TURN_OVER := 0.55
const DEPTH := 2.4

## The card held.
var card: LicenseCard
## How big the card is shown, a scale on its own size.
var shown := 1.0

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
	_aim()


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and not TouchInput.enabled:
		_mouse_at = motion.global_position
		_mouse_seen = true


func _process(delta: float) -> void:
	_turn = _turn.lerp(_wanted(), 1.0 - exp(-FOLLOW * delta))
	card.tilt = _turn
	_aim()


## Where the card is turned toward: the way the right stick is pushed, or else where the mouse
## has gone about the card, all the way at its edges and beyond; nowhere on a touch screen, which
## has neither.
func _wanted() -> Vector2:
	var stick := Input.get_vector(
		InputActions.AIM_LEFT, InputActions.AIM_RIGHT, InputActions.AIM_UP, InputActions.AIM_DOWN
	)
	if stick.length() > STICK_REST:
		return stick.limit_length(1.0)
	if not _mouse_seen or size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ZERO
	var away := (_mouse_at - (global_position + size * 0.5)) / (size * 0.5)
	return away.clamp(-Vector2.ONE, Vector2.ONE)


## The picture turned as the card is: the tilt, and the turn over on top of it. In the middle of
## a turn over, the side drawn is the one the camera would see, which changes as the card passes
## edge-on, where the shader starts reading the picture mirrored.
func _aim() -> void:
	var yaw := _turn.x * TURN + _over
	if _turning:
		var back_in_view := cos(yaw) < 0.0
		if card.flipped != (_from != back_in_view):
			card.other_side()
	_material.set_shader_parameter("turn", Vector2(yaw, _turn.y * TURN))


## Turns the card right over, to its back or its front again, about its upright axis, the way
## back the way it came.
func turn_over() -> void:
	if _turning:
		return
	_turning = true
	_from = card.flipped
	var way := -1.0 if _from else 1.0
	var turn := create_tween()
	turn.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	turn.tween_method(_turn_by, 0.0, PI * way, TURN_OVER)
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
