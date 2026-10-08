class_name OpeningInvitation
extends Control
## The invitation that brought the player to the tables, STORY.md 6.1a, over the title the first
## time a profile comes to it, see [method due]: put up behind the shader warm-up, so it has drawn
## everything once while the shaders compile, and started once they have, see [method start],
## before the title's own opening. The House's bulk mail on a dark table, an envelope addressed to
## the occupant, see [OpeningEnvelope], and the card out of it, see [OpeningCard], two spotlights
## coming on over it with one way on under them, Accept the invitation. The parts come on in turn,
## see [constant LENGTH], and a press before they are done brings them all at once; the card turns
## a little toward the mouse, the stick or the phone, the light catching its gold, as the license
## does. Accepted, after a beat the stub is torn off along its holes and falls, the card is held a
## moment without it, card and envelope drop off the table, and after a moment of dark the title is
## the player's. It has the screen to itself: the cursor goes nowhere else, and there is no
## declining it, Back doing nothing.
##
## Drawn once and moved: the card is drawn into a picture once, and again only as it is torn, and
## everything that moves or turns does so as a Node2D carrying what is drawn, which a turned or
## scaled Control would draw again every frame.

## Accepted and gone: the title's own opening is next.
signal accepted

## The stage it is laid out on, scaled down to fit a smaller screen, never up.
const STAGE := Vector2(1920.0, 1080.0)
## Where the middles of the envelope and the card lie on it, and how far each is turned.
const ENVELOPE_AT := Vector2(555.0, 600.0)
const ENVELOPE_TURN := -0.105
const CARD_AT := Vector2(1327.5, 469.5)
const CARD_TURN := 0.052
const BUTTON_TOP := 954.0
const BUTTON_WIDE := 510.0
## How it comes on, each part from and to so many seconds after [method start]: a moment of the
## dark table, the envelope slid in from below, a beat, the card up out of it, the spotlights
## switched on over it, and the button; and how long that all takes.
const ENVELOPE_IN := Vector2(0.5, 1.05)
const CARD_OUT := Vector2(1.3, 2.05)
const LIGHTS_UP := Vector2(2.0, 2.55)
const BUTTON_UP := Vector2(2.45, 2.85)
const LENGTH := 2.85
## How small the card is as it comes out of the envelope, and from how far below the envelope
## comes.
const OUT_OF := 0.72
const FROM_BELOW := Vector2(-260.0, 820.0)
## Accepted: the button goes and the card settles flat, a beat, the stub torn away from its left
## end first and then falling, the card held a moment without it, card and envelope dropped off
## the table as the lights go out, a moment of the dark table, and the fade into the title.
const SETTLE := 0.3
const BEFORE_TEAR := 0.3
const TEAR := 0.6
const TEAR_TURN := 0.14
const FALL := 1.1
const FALL_TURN := 0.6
const HOLD := 0.6
const DROP := 0.75
const DARK := 0.5
const FADE := 0.35
## How far the card turns toward the mouse, as a share of how far the license does, the room round
## it in its picture for its corners and its sticker as it turns, how much sharper the picture is
## drawn than it is shown, and how the light catches it: the gold brighter and tighter than the
## velvet.
const TILT := 0.6
const ROOM := 0.15
const SHARPEN := 2.0
## The room round the envelope in its picture, for its shadow.
const ENVELOPE_ROOM := 56.0
const RELIEF := 0.45
const SHEEN := 0.12
const SHEEN_TIGHT := 10.0
const FOIL := 0.7
## The room is dark round the light.
const DARKNESS := 0.62
## The two lamps, just off the top of the stage, both on the card: how wide each beam is where it
## leaves its lamp and where it lands, how far past the card's middle it reaches, how much of its
## width is its full light before its edges fade, and its light, brighter near its lamp; the glare
## of the lamps; and the pool of their light on the card and the table round it.
const LAMPS: Array[Vector2] = [Vector2(560.0, -150.0), Vector2(1830.0, -170.0)]
const BEAM_FROM := 46.0
const BEAM_TO := 360.0
const BEAM_PAST := 230.0
const BEAM_CORE := 0.45
const LIGHT := Color(1.0, 0.93, 0.78)
const BEAM_NEAR := 0.26
const BEAM_FAR := 0.09
const GLARE := 210.0
const GLARE_LIGHT := 0.75
const POOL := Vector2(520.0, 610.0)
const POOL_LIGHT := 0.15
## How the lights switch on, as how far along [constant LIGHTS_UP] and how bright: a flicker, and
## then on.
const FLICKER: Array[Vector2] = [
	Vector2(0.0, 0.0),
	Vector2(0.12, 0.0),
	Vector2(0.16, 0.75),
	Vector2(0.26, 0.15),
	Vector2(0.34, 0.95),
	Vector2(0.42, 0.35),
	Vector2(0.5, 0.8),
	Vector2(1.0, 1.0),
]
## The arrows and the like that would walk the cursor off to the title under it.
const WALKS: Array[StringName] = [
	&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"
]

## For a test, or a debug build's `++ --story-invitation`: shown whether or not it is due.
static var again := false
static var _glow: GradientTexture2D

var profile: Profile
var envelope: OpeningEnvelope
var card: OpeningCard
var accept: Button
## The stub torn off, as it falls away.
var stub: OpeningCard

var _stage: Control
var _beams: Node2D
var _pool: Node2D
## The envelope's and the card's places on the stage, carrying their turns, and the card's
## picture, see [method _hold].
var _envelope_place: Node2D
var _card_place: Node2D
var _sheet: SubViewport
var _face: TextureRect
var _material: ShaderMaterial
## Whether it has been started, how far in it is, and whether it is still coming on, or accepted.
var _started := false
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


## The invitation over [param parent], for [param of], waiting for [method start].
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


## A soft round glow, white in its middle and nothing at its edge, made once.
static func glow() -> GradientTexture2D:
	if _glow == null:
		var fade := Gradient.new()
		fade.set_color(0, Color.WHITE)
		fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		fade.add_point(0.45, Color(1.0, 1.0, 1.0, 0.55))
		_glow = GradientTexture2D.new()
		_glow.gradient = fade
		_glow.fill = GradientTexture2D.FILL_RADIAL
		_glow.fill_from = Vector2(0.5, 0.5)
		_glow.fill_to = Vector2(1.0, 0.5)
		_glow.width = 256
		_glow.height = 256
	return _glow


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	MenuTheme.background(self)
	add_child(MenuTheme.closer_shade(DARKNESS))
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.size = STAGE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	# Light laid over the dark as it is, in the canvas's own blending: a blend of its own would be a
	# shader of its own, compiled the moment the lights came on.
	_beams = Node2D.new()
	_beams.name = "Beams"
	_beams.draw.connect(_draw_beams)
	_stage.add_child(_beams)
	_envelope_place = Node2D.new()
	_envelope_place.name = "EnvelopePlace"
	_stage.add_child(_envelope_place)
	envelope = OpeningEnvelope.new()
	envelope.name = "Envelope"
	_picture(envelope, OpeningEnvelope.SIZE, Vector2.ONE * ENVELOPE_ROOM, _envelope_place)
	card = OpeningCard.new()
	card.name = "Card"
	card.number = number_for(profile.story)
	_hold(card)
	_pool = Node2D.new()
	_pool.name = "Pool"
	_pool.position = CARD_AT
	_pool.draw.connect(_draw_pool)
	_stage.add_child(_pool)
	accept = MenuTheme.button(StoryLines.OPENING_ACCEPT)
	accept.name = "Accept"
	accept.custom_minimum_size.x = BUTTON_WIDE
	accept.position = Vector2((STAGE.x - BUTTON_WIDE) * 0.5, BUTTON_TOP)
	accept.pressed.connect(_on_accept)
	_stage.add_child(accept)
	# The cursor stays on it: there is nowhere else on this screen to go.
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		accept.set_focus_neighbor(side, accept.get_path())
	accept.focus_next = accept.get_path()
	accept.focus_previous = accept.get_path()
	resized.connect(_fit)
	_fit()
	_pull = Input.get_gravity()
	_lay(0.0)


## [param drawn], [param drawn_size] big, drawn once into a picture of its own at [param place],
## its middle on the place's: sharper than it is shown and smoothed at its edges, with
## [param room] round it, and drawn again only when asked. Returns the picture and what shows it.
func _picture(drawn: Control, drawn_size: Vector2, room: Vector2, place: Node2D) -> Array:
	var picture := (drawn_size + room * 2.0).ceil()
	var sheet := SubViewport.new()
	sheet.name = "Picture"
	sheet.transparent_bg = true
	sheet.disable_3d = true
	sheet.gui_disable_input = true
	sheet.msaa_2d = Viewport.MSAA_4X
	sheet.size = Vector2i(picture * SHARPEN)
	sheet.size_2d_override = Vector2i(picture)
	sheet.size_2d_override_stretch = true
	sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	place.add_child(sheet)
	drawn.position = room
	sheet.add_child(drawn)
	var face := TextureRect.new()
	face.name = "Face"
	face.texture = sheet.get_texture()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_SCALE
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	face.position = -drawn_size * 0.5 - room
	face.size = picture
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place.add_child(face)
	return [sheet, face]


## The card held at its place on the stage, in a picture of its own, see [method _picture], with
## room round it for its corners and its sticker as it turns, shown through the shader that turns
## it.
func _hold(held: OpeningCard) -> void:
	_card_place = Node2D.new()
	_card_place.name = "CardPlace"
	_stage.add_child(_card_place)
	var room := Vector2.ONE * OpeningCard.SIZE.y * ROOM
	var made := _picture(held, OpeningCard.SIZE, room, _card_place)
	_sheet = made[0]
	_face = made[1]
	var picture := _face.size
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
	_face.material = _material


## Comes on: the envelope after a moment, and the rest after it, see [constant LENGTH].
func start() -> void:
	_started = true


## The stage as big as the screen lets it be, never bigger than it is drawn, in the middle.
func _fit() -> void:
	var by := minf(minf(size.x / STAGE.x, size.y / STAGE.y), 1.0)
	_stage.scale = Vector2.ONE * by
	_stage.position = (size - STAGE * by) * 0.5


## Everything as it is [param at] seconds in, coming on.
func _lay(at: float) -> void:
	var dealt := _eased(at, ENVELOPE_IN)
	_envelope_place.position = ENVELOPE_AT + FROM_BELOW * (1.0 - dealt)
	_envelope_place.rotation = lerpf(ENVELOPE_TURN - 0.15, ENVELOPE_TURN, dealt)
	_envelope_place.modulate.a = clampf(_along(at, ENVELOPE_IN) * 4.0, 0.0, 1.0)
	# The card up out of the envelope, from its middle, growing as it comes.
	var out := _eased(at, CARD_OUT)
	_card_place.position = _envelope_place.position.lerp(CARD_AT, out)
	_card_place.scale = Vector2.ONE * lerpf(OUT_OF, 1.0, out)
	_card_place.rotation = lerpf(ENVELOPE_TURN, CARD_TURN, out)
	_card_place.modulate.a = clampf(_along(at, CARD_OUT) * 6.0, 0.0, 1.0)
	var lit := _flicker(_along(at, LIGHTS_UP))
	_beams.modulate.a = lit
	_pool.modulate.a = lit
	var shown := _eased(at, BUTTON_UP)
	accept.modulate.a = shown
	accept.position.y = BUTTON_TOP + 24.0 * (1.0 - shown)
	accept.disabled = shown <= 0.0


## How bright the lights are [param along] the way to being on: a flicker, then on.
static func _flicker(along: float) -> float:
	for i: int in range(1, FLICKER.size()):
		if along <= FLICKER[i].x:
			var before := FLICKER[i - 1]
			var step := FLICKER[i]
			return lerpf(before.y, step.y, (along - before.x) / (step.x - before.x))
	return 1.0


## How far along [param at] is between the two ends of [param span], 0 to 1.
static func _along(at: float, span: Vector2) -> float:
	return clampf((at - span.x) / (span.y - span.x), 0.0, 1.0)


## The same, easing out, the way a thing put down slows as it lands.
static func _eased(at: float, span: Vector2) -> float:
	return 1.0 - pow(1.0 - _along(at, span), 3.0)


func _process(delta: float) -> void:
	if _started and _coming:
		var was := _time
		_time = minf(_time + delta, LENGTH)
		if was < ENVELOPE_IN.x and _time >= ENVELOPE_IN.x:
			Audio.play_sfx(&"page", -6.0, 0.05)
		if was < CARD_OUT.x and _time >= CARD_OUT.x:
			Audio.play_sfx(&"joker_offer", MenuTheme.MOVE_DB, 0.0)
		var switched := LIGHTS_UP.x + (LIGHTS_UP.y - LIGHTS_UP.x) * FLICKER[1].x
		if was < switched and _time >= switched:
			Audio.play_sfx(&"item_use", -10.0, 0.0)
		_lay(_time)
		if was < BUTTON_UP.x and _time >= BUTTON_UP.x:
			accept.grab_focus()
		if _time >= LENGTH:
			_coming = false
	# Turned toward the mouse, the stick or the phone, once it is out of the envelope.
	var pull := Input.get_gravity()
	_pull = _pull.lerp(pull, 1.0 - exp(-TiltedCard.PHONE_SETTLE * delta))
	var held := _card_place.get_global_transform()
	var shown := OpeningCard.SIZE * held.get_scale()
	var over := Rect2(held.get_origin() - shown * 0.5, shown)
	var toward := TiltedCard.wanted(over, _mouse, _pull) * TILT * _calm * _eased(_time, CARD_OUT)
	var tilt := _tilt.lerp(toward, 1.0 - exp(-TiltedCard.FOLLOW * delta))
	if not tilt.is_equal_approx(_tilt):
		_tilt = tilt
		_material.set_shader_parameter("turn", _tilt * TiltedCard.TURN)


## Everything at once, as it is once it has all come on.
func come_on_now() -> void:
	if not _coming:
		return
	_started = true
	_coming = false
	_time = LENGTH
	_lay(LENGTH)
	accept.grab_focus.call_deferred()


## It has the screen to itself once started: the cursor walks nowhere, and a press before it has
## all come on brings it all at once. The mouse is followed for the card to turn toward.
func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and not TouchInput.enabled:
		_mouse = motion.global_position
	if not _started:
		return
	for walk: StringName in WALKS:
		if event.is_action(walk):
			get_viewport().set_input_as_handled()
			return
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
	if _started and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()


## The two beams, each a core of light with edges fading out to nothing either side, so they are
## soft, and brighter near its lamp; and the glare of the lamps themselves at the top of the stage.
func _draw_beams() -> void:
	for lamp: Vector2 in LAMPS:
		var along := (CARD_AT - lamp).normalized()
		var across := Vector2(-along.y, along.x)
		var far := CARD_AT + along * BEAM_PAST
		var near := Color(LIGHT, BEAM_NEAR)
		var away := Color(LIGHT, BEAM_FAR)
		var none := Color(LIGHT, 0.0)
		# Across the beam, edge to edge: out, the core's edge, the core's other edge, out.
		var at_lamp: Array[Vector2] = []
		var at_far: Array[Vector2] = []
		for share: float in [-1.0, -BEAM_CORE, BEAM_CORE, 1.0]:
			at_lamp.append(lamp + across * BEAM_FROM * share)
			at_far.append(far + across * BEAM_TO * share)
		for i: int in 3:
			var outer_in := i == 0
			var outer_out := i == 2
			(
				_beams
				. draw_polygon(
					PackedVector2Array([at_lamp[i], at_far[i], at_far[i + 1], at_lamp[i + 1]]),
					PackedColorArray(
						[
							none if outer_in else near,
							none if outer_in else away,
							none if outer_out else away,
							none if outer_out else near,
						]
					)
				)
			)
		_beams.draw_texture_rect(
			glow(),
			Rect2(lamp - Vector2.ONE * GLARE, Vector2.ONE * GLARE * 2.0),
			false,
			Color(LIGHT, GLARE_LIGHT)
		)


## The pool of their light, on the card and the table round it.
func _draw_pool() -> void:
	_pool.draw_texture_rect(glow(), Rect2(-POOL, POOL * 2.0), false, Color(LIGHT, POOL_LIGHT))


## Accepted: kept for the profile, and after a beat the stub torn off; the card held a moment
## without it; card and envelope dropped off the table as the lights go out; a moment of the dark
## table; and the rest faded into the title.
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
	going.tween_interval(BEFORE_TEAR)
	going.tween_callback(_tear)
	going.tween_interval(TEAR + HOLD)
	going.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var down := STAGE.y * 1.3
	going.tween_property(_card_place, "position:y", _card_place.position.y + down, DROP)
	going.parallel().tween_property(_card_place, "rotation", CARD_TURN + 0.35, DROP)
	going.parallel().tween_property(
		_envelope_place, "position:y", _envelope_place.position.y + down, DROP
	)
	going.parallel().tween_property(_envelope_place, "rotation", ENVELOPE_TURN - 0.25, DROP)
	going.parallel().tween_property(_beams, "modulate:a", 0.0, DROP * 0.6)
	going.parallel().tween_property(_pool, "modulate:a", 0.0, DROP * 0.6)
	going.tween_interval(DARK)
	going.tween_callback(accepted.emit)
	going.tween_property(self, "modulate:a", 0.0, FADE)
	going.tween_callback(queue_free)


## The stub torn off along its holes, the card's edge and the stub's going ragged to match: torn
## away from its left end first, turning about its right, then let go and falling out of sight.
func _tear() -> void:
	Audio.play_sfx(&"tear", -4.0, 0.05)
	card.tear()
	card.shows_stub = false
	_sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	# The stub drawn by itself where it was, on a place of its own that turns and falls, so it is
	# not drawn again as it goes.
	var pivot := Vector2(OpeningCard.SIZE.x - OpeningCard.BITE, OpeningCard.PERFORATION)
	var going := Node2D.new()
	going.name = "StubPlace"
	going.position = pivot - OpeningCard.SIZE * 0.5
	_card_place.add_child(going)
	stub = OpeningCard.new()
	stub.name = "Stub"
	stub.number = card.number
	stub.stub_only = true
	stub.torn = true
	stub.position = -pivot
	going.add_child(stub)
	var off := create_tween()
	off.tween_property(going, "rotation", TEAR_TURN, TEAR).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	off.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	off.tween_property(going, "position:y", going.position.y + STAGE.y * 1.4, FALL)
	off.parallel().tween_property(going, "rotation", FALL_TURN, FALL)
	off.tween_callback(func() -> void: going.visible = false)
