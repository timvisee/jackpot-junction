class_name OpeningInvitation
extends Control
## The invitation that brought the player to the tables, STORY.md 6.1a, over the title the first
## time a profile comes to it, after the shaders have compiled and before the title's own opening,
## see [method due]: the House's bulk mail on the table, an envelope addressed to the occupant, see
## [OpeningEnvelope], and the card out of it, see [OpeningCard], under two spotlights, with one way
## on under them, Accept the invitation. The parts come on in turn, see [constant LENGTH], and a
## press before they are done brings them all at once; the card turns a little toward the mouse, the
## stick or the phone, the light catching its gold, as the license does. Accepted, the stub is torn
## off along its holes and falls, the card and the envelope go, and the title is the player's.
## There is no declining it: Back does nothing.

## Accepted and gone: the title's own opening is next.
signal accepted

## The stage it is laid out on, scaled down to fit a smaller screen, never up.
const STAGE := Vector2(1920.0, 1080.0)
## Where the envelope and the card lie on it, their top left corners, and how far each is turned.
const ENVELOPE_AT := Vector2(135.0, 375.0)
const ENVELOPE_TURN := -0.105
const CARD_AT := Vector2(990.0, 27.0)
const CARD_TURN := 0.052
const BUTTON_TOP := 954.0
const BUTTON_WIDE := 510.0
## The two spotlights, both on the card, and the pool of their light under it.
const LIGHT_LEFT: Array[Vector2] = [
	Vector2(435.0, 0.0), Vector2(630.0, 0.0), Vector2(1515.0, 960.0), Vector2(1035.0, 960.0)
]
const LIGHT_RIGHT: Array[Vector2] = [
	Vector2(1680.0, 0.0), Vector2(1875.0, 0.0), Vector2(1575.0, 960.0), Vector2(1095.0, 960.0)
]
const LIGHT := Color(1.0, 0.925, 0.745, 0.075)
const POOL_AT := Vector2(1305.0, 855.0)
const POOL := Vector2(405.0, 150.0)
## How it comes on, each part from and to so many seconds in: the envelope slid in from below,
## the card up out of it, the spotlights, and the button; and how long that all takes.
const ENVELOPE_IN := Vector2(0.0, 0.55)
const CARD_OUT := Vector2(0.45, 1.2)
const LIGHTS_UP := Vector2(1.0, 1.6)
const BUTTON_UP := Vector2(1.4, 1.8)
const LENGTH := 1.8
## How small the card is as it comes out of the envelope, and from how far below the envelope
## comes.
const OUT_OF := 0.72
const FROM_BELOW := Vector2(-260.0, 820.0)
## Accepted: the card settles flat, the stub is torn off and falls, the card and the envelope go
## down off the table, and the rest fades into the title.
const SETTLE := 0.15
const PULL := 0.14
const FALL := 0.75
const FALL_TURN := 0.5
const AFTER_TEAR := 0.45
const AWAY := 0.5
const FADE := 0.35
## How far the card turns toward the mouse, as a share of how far the license does, the room round
## it in its picture for its corners and its sticker as it turns, and how the light catches it:
## the gold brighter and tighter than the velvet.
const TILT := 0.6
const ROOM := 0.15
const RELIEF := 0.45
const SHEEN := 0.12
const SHEEN_TIGHT := 10.0
const FOIL := 0.7

## For a test, or a debug build's `++ --story-invitation`: shown whether or not it is due.
static var again := false

var profile: Profile
var envelope: OpeningEnvelope
var card: OpeningCard
var accept: Button
## The stub torn off, as it falls away.
var stub: OpeningCard

var _stage: Control
var _lights: Control
## The card's place on the stage, carrying its turn and its picture, see [method _hold].
var _held: Control
var _face: TextureRect
var _material: ShaderMaterial
## How far in it is, and whether it is still coming on, or accepted.
var _time := 0.0
var _coming := true
var _accepted := false
## Where the card is turned toward, smoothed, and how much it follows: none once accepted.
var _tilt := Vector2.ZERO
var _calm := 1.0
var _mouse: Variant = null
var _pull := Vector3.ZERO


## Whether [param of] is to be shown it: the first time it comes to the title, with the story on,
## and never in a run nobody is watching.
static func due(of: Profile) -> bool:
	if again:
		return true
	if Game.is_headless() or Game.is_scripted():
		return false
	return owed(of)


## Whether [param of] has it still to accept: with the story on, and never accepted before.
static func owed(of: Profile) -> bool:
	return of.story.on and not of.story.invited


## The invitation over [param parent], for [param of].
static func over(parent: Control, of: Profile) -> OpeningInvitation:
	var invitation := OpeningInvitation.new()
	invitation.name = "OpeningInvitation"
	invitation.profile = of
	parent.add_child(invitation)
	return invitation


## The number on [param story]'s stub: given the first time it is shown, and kept.
static func number_for(story: StoryState) -> String:
	if story.invitation.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		story.invitation = "%04d %04d" % [rng.randi_range(0, 9999), rng.randi_range(0, 9999)]
	return story.invitation


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	MenuTheme.background(self)
	add_child(MenuTheme.closer_shade(0.35))
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.size = STAGE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_lights = Control.new()
	_lights.name = "Spotlights"
	_lights.size = STAGE
	_lights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lights.draw.connect(_draw_lights)
	_stage.add_child(_lights)
	envelope = OpeningEnvelope.new()
	envelope.name = "Envelope"
	_stage.add_child(envelope)
	card = OpeningCard.new()
	card.name = "Card"
	card.number = number_for(profile.story)
	_hold(card)
	accept = MenuTheme.button(StoryLines.OPENING_ACCEPT)
	accept.name = "Accept"
	accept.custom_minimum_size.x = BUTTON_WIDE
	accept.position = Vector2((STAGE.x - BUTTON_WIDE) * 0.5, BUTTON_TOP)
	accept.pressed.connect(_on_accept)
	_stage.add_child(accept)
	resized.connect(_fit)
	_fit()
	_pull = Input.get_gravity()
	_lay(0.0)
	Audio.play_sfx(&"page", -6.0, 0.05)


## The card held on the stage at its place: drawn into a picture of its own, with room round it for
## its corners and its sticker as it turns, and shown through the shader that turns it.
func _hold(held: OpeningCard) -> void:
	_held = Control.new()
	_held.name = "Held"
	_held.size = OpeningCard.SIZE
	_held.pivot_offset = OpeningCard.SIZE * 0.5
	_held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_held)
	var room := Vector2.ONE * OpeningCard.SIZE.y * ROOM
	var picture := (OpeningCard.SIZE + room * 2.0).ceil()
	var sharpen := clampf(get_viewport().get_final_transform().get_scale().x, 1.0, 2.0)
	var sheet := SubViewport.new()
	sheet.name = "Picture"
	sheet.transparent_bg = true
	sheet.disable_3d = true
	sheet.gui_disable_input = true
	sheet.size = Vector2i(picture * sharpen)
	sheet.size_2d_override = Vector2i(picture)
	sheet.size_2d_override_stretch = true
	sheet.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_held.add_child(sheet)
	held.position = room
	sheet.add_child(held)
	_material = ShaderMaterial.new()
	_material.shader = TiltedCard.SHADER
	_material.set_shader_parameter("extent", picture * 0.5 / OpeningCard.SIZE.x)
	_material.set_shader_parameter(
		"depth", TiltedCard.DEPTH * OpeningCard.SIZE.y / OpeningCard.SIZE.x
	)
	_material.set_shader_parameter("relief", RELIEF)
	_material.set_shader_parameter("sheen", SHEEN)
	_material.set_shader_parameter("sheen_tight", SHEEN_TIGHT)
	_material.set_shader_parameter("foil", FOIL)
	_face = TextureRect.new()
	_face.name = "Face"
	_face.texture = sheet.get_texture()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_face.position = -room
	_face.size = picture
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.material = _material
	_held.add_child(_face)


## The stage as big as the screen lets it be, never bigger than it is drawn, in the middle.
func _fit() -> void:
	var by := minf(minf(size.x / STAGE.x, size.y / STAGE.y), 1.0)
	_stage.scale = Vector2.ONE * by
	_stage.position = (size - STAGE * by) * 0.5


## Everything as it is [param at] seconds in, coming on.
func _lay(at: float) -> void:
	var dealt := _eased(at, ENVELOPE_IN)
	envelope.position = ENVELOPE_AT + FROM_BELOW * (1.0 - dealt)
	envelope.rotation = lerpf(ENVELOPE_TURN - 0.15, ENVELOPE_TURN, dealt)
	envelope.modulate.a = clampf(_along(at, ENVELOPE_IN) * 4.0, 0.0, 1.0)
	# The card up out of the envelope, from its middle, growing as it comes.
	var out := _eased(at, CARD_OUT)
	var from := envelope.position + OpeningEnvelope.SIZE * 0.5
	var to := CARD_AT + OpeningCard.SIZE * 0.5
	_held.position = from.lerp(to, out) - OpeningCard.SIZE * 0.5
	_held.scale = Vector2.ONE * lerpf(OUT_OF, 1.0, out)
	_held.rotation = lerpf(ENVELOPE_TURN, CARD_TURN, out)
	_held.modulate.a = clampf(_along(at, CARD_OUT) * 6.0, 0.0, 1.0)
	_lights.modulate.a = smoothstep(0.0, 1.0, _along(at, LIGHTS_UP))
	var shown := _eased(at, BUTTON_UP)
	accept.modulate.a = shown
	accept.position.y = BUTTON_TOP + 24.0 * (1.0 - shown)
	accept.disabled = shown <= 0.0


## How far along [param at] is between the two ends of [param span], 0 to 1.
static func _along(at: float, span: Vector2) -> float:
	return clampf((at - span.x) / (span.y - span.x), 0.0, 1.0)


## The same, easing out, the way a thing put down slows as it lands.
static func _eased(at: float, span: Vector2) -> float:
	return 1.0 - pow(1.0 - _along(at, span), 3.0)


func _process(delta: float) -> void:
	if _coming:
		var was := _time
		_time = minf(_time + delta, LENGTH)
		if was < CARD_OUT.x and _time >= CARD_OUT.x:
			Audio.play_sfx(&"joker_offer", MenuTheme.MOVE_DB, 0.0)
		if was < LIGHTS_UP.x and _time >= LIGHTS_UP.x:
			Audio.play_sfx(&"item_use", -10.0, 0.0)
		_lay(_time)
		if was < BUTTON_UP.x and _time >= BUTTON_UP.x:
			accept.grab_focus()
		if _time >= LENGTH:
			_coming = false
	# Turned toward the mouse, the stick or the phone, once it is out of the envelope.
	var pull := Input.get_gravity()
	_pull = _pull.lerp(pull, 1.0 - exp(-TiltedCard.PHONE_SETTLE * delta))
	var out := _eased(_time, CARD_OUT)
	var toward := TiltedCard.wanted(_held.get_global_rect(), _mouse, _pull) * TILT * _calm * out
	_tilt = _tilt.lerp(toward, 1.0 - exp(-TiltedCard.FOLLOW * delta))
	_material.set_shader_parameter("turn", _tilt * TiltedCard.TURN)


## Everything at once, as it is once it has all come on.
func come_on_now() -> void:
	if not _coming:
		return
	_coming = false
	_time = LENGTH
	_lay(LENGTH)
	accept.grab_focus.call_deferred()


## A press before it has all come on brings it all at once; and the mouse is followed.
func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and not TouchInput.enabled:
		_mouse = motion.global_position
	if not _coming:
		return
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (
		event.is_action_pressed(&"ui_accept")
		or (click != null and click.pressed)
		or (touch != null and touch.pressed)
	):
		get_viewport().set_input_as_handled()
		come_on_now()


## Back does nothing: it is not to be declined.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()


func _draw_lights() -> void:
	for beam: Array in [LIGHT_LEFT, LIGHT_RIGHT]:
		_lights.draw_colored_polygon(PackedVector2Array(beam), LIGHT)
	# The pool of their light, soft at its edge.
	for i: int in 6:
		var spread := 1.0 - float(i) * 0.14
		_lights.draw_set_transform(POOL_AT, 0.0, POOL * spread / POOL.x)
		_lights.draw_circle(Vector2.ZERO, POOL.x, Color(LIGHT, 0.025))
	_lights.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Accepted: kept for the profile, the stub torn off, and the rest gone into the title.
func _on_accept() -> void:
	if _accepted:
		return
	_accepted = true
	come_on_now()
	accept.disabled = true
	profile.story.invited = true
	if not Game.is_headless():
		Game.settings.save_to_disk()
	var going := create_tween()
	going.tween_property(self, "_calm", 0.0, SETTLE)
	going.parallel().tween_property(accept, "modulate:a", 0.0, SETTLE)
	going.tween_callback(_tear)
	going.tween_interval(AFTER_TEAR)
	going.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	going.tween_property(_held, "position:y", _held.position.y + STAGE.y * 1.3, AWAY)
	going.parallel().tween_property(envelope, "position:y", envelope.position.y + STAGE.y, AWAY)
	going.parallel().tween_property(_lights, "modulate:a", 0.0, AWAY)
	going.tween_property(self, "modulate:a", 0.0, FADE)
	going.tween_callback(
		func() -> void:
			accepted.emit()
			queue_free()
	)


## The stub torn off along its holes, the card's edge and the stub's going ragged to match, and the
## stub pulled away and falling out of sight.
func _tear() -> void:
	Audio.play_sfx(&"tear", -4.0, 0.05)
	card.tear()
	card.shows_stub = false
	stub = OpeningCard.new()
	stub.name = "Stub"
	stub.number = card.number
	stub.stub_only = true
	stub.torn = true
	_held.add_child(stub)
	stub.pivot_offset = Vector2(0.0, OpeningCard.PERFORATION)
	var off := create_tween()
	off.set_trans(Tween.TRANS_QUAD)
	off.tween_property(stub, "position", Vector2(-10.0, 30.0), PULL).set_ease(Tween.EASE_OUT)
	off.parallel().tween_property(stub, "rotation", -0.1, PULL).set_ease(Tween.EASE_OUT)
	off.tween_property(stub, "position:y", STAGE.y * 1.4, FALL).set_ease(Tween.EASE_IN)
	off.parallel().tween_property(stub, "rotation", -FALL_TURN, FALL).set_ease(Tween.EASE_IN)
	off.tween_callback(func() -> void: stub.visible = false)
