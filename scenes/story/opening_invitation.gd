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
## dark table, the envelope slid in from below, a beat, the card drawn out of it, the spotlights
## switched on over it, and the button; and how long that all takes.
const ENVELOPE_IN := Vector2(0.5, 1.05)
const CARD_OUT := Vector2(1.3, 2.7)
const LIGHTS_UP := Vector2(2.6, 3.15)
const BUTTON_UP := Vector2(3.05, 3.45)
const LENGTH := 3.45
## The card drawn out of the envelope in two moves, each starting and stopping softly: first pulled
## up out of its top, [constant INSIDE] of its size and behind it, until it is wholly out, up to
## [constant PULLED] seconds in, [constant OUT_OF_TOP] up from the envelope's middle as it lies;
## then, after a moment, from [constant OVER] seconds in, brought to the front, clear of the
## envelope, and over it to its place along an arc [constant ARC] high, growing to its size and
## turning to its slant as it goes. And from how far below the envelope comes.
const INSIDE := 0.36
const PULLED := 1.75
const OUT_OF_TOP := 400.0
const OVER := 1.85
const ARC := 120.0
const FROM_BELOW := Vector2(-260.0, 820.0)
## Accepted: the button goes and the card settles flat, a beat, the stub torn along its holes from
## its left end to its right, the torn part leaning away from the card more the further it is from
## where the tear has got to, then let go and falling, the card held a moment without it, card and
## envelope dropped off the table as the lights go out, a moment of the dark table, and the fade
## into the title.
const SETTLE := 0.3
const BEFORE_TEAR := 0.3
const TEAR := 0.9
const TEAR_LEAN := 0.07
const FALL := 1.1
const FALL_TURN := 0.6
const HOLD := 0.6
const DROP := 0.75
const DARK := 0.5
const FADE := 0.35
## How much sharper the envelope's picture and the stub's are drawn than they are shown, as the
## card's is, see [HeldCard].
const SHARPEN := HeldCard.SHARPEN
## The room round the envelope in its picture, for its shadow.
const ENVELOPE_ROOM := 56.0
## Where the stub's picture starts, above the perforation, for its ragged edge.
const STUB_TOP := OpeningCard.PERFORATION - 12.0
## The card's shadow on the table: how far out past it, how far down, and how dark.
const SHADOW_OUT := Vector2(150.0, 170.0)
const SHADOW_DOWN := 34.0
const SHADOW := 0.7
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

## For a test, or a debug build's `++ --story-invitation`: shown whether or not it is due. And for a
## debug build's `++ --story-invitation=0`: not shown in this run even where it is due, nothing
## saved, so it is due again the next time the game starts without it.
static var again := false
static var held_off := false
static var _glow: GradientTexture2D

var profile: Profile
var envelope: OpeningEnvelope
var card: OpeningCard
var accept: Button
## The stub as it comes away, drawn once torn into a picture of its own, see [method _set_tear].
var stub: OpeningCard

var _stage: Control
var _beams: Node2D
var _pool: Node2D
## The envelope's and the card's places on the stage, carrying their turns, and the card's
## picture, see [method _hold].
var _envelope_place: Node2D
var _card_place: HeldCard
var _shadow: Node2D
## The stub's picture, and its two parts as it tears: the part still on, its holes still punched,
## and the part torn, leaning away; and where along the perforation the tear has got to.
var _stub_sheet: SubViewport
var _attached: Node2D
var _torn: Node2D
var _front := 0.0
## Whether the card is out from behind the envelope, in front of it.
var _in_front := true
## Whether it has been started, how far in it is, and whether it is still coming on, or accepted.
var _started := false
var _time := 0.0
var _coming := true
var _accepted := false
## How much the card follows the mouse, the stick or the phone: none once accepted.
var _calm := 1.0
## Where the card is turned toward, smoothed, and how much it follows: none once accepted.


## Whether [param of] is to be shown it: the first time it comes to the title, with the story on,
## and never in a run nobody is watching.
static func due(of: Profile) -> bool:
	if held_off:
		return false
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


## The card held at its place on the stage, see [HeldCard], the light catching it where a picture
## of where it shines says, see [member OpeningCard.shine_only], and its shadow under it on the
## table; and its stub drawn once torn into a picture of its own, for its tearing, see
## [method _set_tear].
func _hold(held: OpeningCard) -> void:
	var mask := OpeningCard.new()
	mask.name = "Shine"
	mask.number = held.number
	mask.shine_only = true
	_card_place = HeldCard.of(held, OpeningCard.SIZE, mask)
	_card_place.name = "CardPlace"
	_stage.add_child(_card_place)
	var shadow := Node2D.new()
	shadow.name = "Shadow"
	_shadow = shadow
	shadow.draw.connect(
		func() -> void:
			var out := OpeningCard.SIZE * 0.5 + SHADOW_OUT
			shadow.draw_texture_rect(
				glow(),
				Rect2(Vector2(-out.x, -out.y + SHADOW_DOWN), out * 2.0),
				false,
				Color(0.0, 0.0, 0.0, SHADOW)
			)
	)
	_card_place.add_child(shadow)
	_card_place.move_child(shadow, 0)
	# The stub as it will come away, torn, drawn now while nothing is moving.
	stub = OpeningCard.new()
	stub.name = "Stub"
	stub.number = held.number
	stub.stub_only = true
	stub.torn = true
	stub.position = Vector2(0.0, -STUB_TOP)
	var tall := Vector2(OpeningCard.SIZE.x, OpeningCard.SIZE.y - STUB_TOP)
	_stub_sheet = SubViewport.new()
	_stub_sheet.name = "StubPicture"
	_stub_sheet.transparent_bg = true
	_stub_sheet.disable_3d = true
	_stub_sheet.gui_disable_input = true
	_stub_sheet.msaa_2d = Viewport.MSAA_4X
	_stub_sheet.size = Vector2i(tall * SHARPEN)
	_stub_sheet.size_2d_override = Vector2i(tall)
	_stub_sheet.size_2d_override_stretch = true
	_stub_sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	_stub_sheet.add_child(stub)
	_card_place.add_child(_stub_sheet)
	_attached = Node2D.new()
	_attached.name = "Attached"
	_attached.position = -OpeningCard.SIZE * 0.5
	_attached.visible = false
	_attached.draw.connect(_draw_attached)
	_card_place.add_child(_attached)
	_torn = Node2D.new()
	_torn.name = "Torn"
	_torn.visible = false
	_torn.draw.connect(_draw_torn)
	_card_place.add_child(_torn)


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
	# The card drawn out of the envelope: pulled up out of its top as it lies, wholly out, and then
	# over it to its place, each move easing in and out.
	var from := _envelope_place.position
	var out_of := from + Vector2.UP.rotated(ENVELOPE_TURN) * OUT_OF_TOP
	var pulled := _soft(at, Vector2(CARD_OUT.x, PULLED))
	var over := _soft(at, Vector2(OVER, CARD_OUT.y))
	var arc := (out_of + CARD_AT) * 0.5 + Vector2.UP * ARC
	var on_way := out_of.lerp(arc, over).lerp(arc.lerp(CARD_AT, over), over)
	_card_place.position = from.lerp(out_of, pulled) if over <= 0.0 else on_way
	_card_place.scale = Vector2.ONE * lerpf(INSIDE, 1.0, over)
	_card_place.rotation = lerpf(ENVELOPE_TURN, CARD_TURN, over)
	_card_place.modulate.a = 1.0 if at >= CARD_OUT.x else 0.0
	# Its shadow only once it is out on the table, not round it inside the envelope.
	_shadow.modulate.a = over
	# In front of the envelope once it is wholly out of it, which nobody can see happen.
	var in_front := at >= OVER
	if in_front != _in_front:
		_in_front = in_front
		_stage.move_child(_card_place, _envelope_place.get_index() + (1 if in_front else 0))
	var lit := _flicker(_along(at, LIGHTS_UP))
	_beams.modulate.a = lit
	_pool.modulate.a = lit
	var shown := _eased(at, BUTTON_UP)
	accept.modulate.a = shown
	accept.position.y = BUTTON_TOP + 24.0 * (1.0 - shown)
	accept.disabled = shown <= 0.0


## How far along [param at] is between the two ends of [param span], easing in and out: starting
## and stopping softly.
static func _soft(at: float, span: Vector2) -> float:
	return 0.5 - 0.5 * cos(PI * _along(at, span))


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
	# Turned toward the mouse, the stick or the phone once it is out of the envelope, and settled
	# flat once accepted.
	_card_place.follow = _calm * _along(_time, CARD_OUT)


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
## all come on brings it all at once.
func _input(event: InputEvent) -> void:
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


func _draw_beams() -> void:
	draw_beams(_beams, CARD_AT)


## The two beams on [param on], both on [param target], each a core of light with edges fading out
## to nothing either side, so they are soft, and brighter near its lamp; and the glare of the lamps
## themselves at the top of the stage, [param lamps] where they hang. The loyalty program's welcome
## lights its card with them too, from lamps of its own, see [LoyaltyWelcome], and so does the
## payout slip's photo finish, see [PhotoBackdrop]. Every beam is one array of triangles.
static func draw_beams(on: CanvasItem, target: Vector2, lamps := LAMPS) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var near := Color(LIGHT, BEAM_NEAR)
	var away := Color(LIGHT, BEAM_FAR)
	var none := Color(LIGHT, 0.0)
	for lamp: Vector2 in lamps:
		var along := (target - lamp).normalized()
		var across := Vector2(-along.y, along.x)
		var far := target + along * BEAM_PAST
		# Across the beam, edge to edge: out, the core's edge, the core's other edge, out.
		var at_lamp: Array[Vector2] = []
		var at_far: Array[Vector2] = []
		for share: float in [-1.0, -BEAM_CORE, BEAM_CORE, 1.0]:
			at_lamp.append(lamp + across * BEAM_FROM * share)
			at_far.append(far + across * BEAM_TO * share)
		for i: int in 3:
			var outer_in := i == 0
			var outer_out := i == 2
			var corners: Array[Vector2] = [at_lamp[i], at_far[i], at_far[i + 1], at_lamp[i + 1]]
			var inks: Array[Color] = [
				none if outer_in else near,
				none if outer_in else away,
				none if outer_out else away,
				none if outer_out else near,
			]
			# Round a point in its middle, in the mean of its corners' light, rather than split
			# across one of its diagonals: split, a strip's fade leant one way in one beam and the
			# other way in its mirror, and two beams on one thing never looked a pair.
			var first := points.size()
			var middle := Vector2.ZERO
			var mean := Color(0.0, 0.0, 0.0, 0.0)
			for k: int in 4:
				points.append(corners[k])
				colors.append(inks[k])
				middle += corners[k] * 0.25
				mean += inks[k] * 0.25
			points.append(middle)
			colors.append(mean)
			for k: int in 4:
				indices.append_array([first + 4, first + k, first + (k + 1) % 4])
	RenderingServer.canvas_item_add_triangle_array(on.get_canvas_item(), indices, points, colors)
	for lamp: Vector2 in lamps:
		on.draw_texture_rect(
			glow(),
			Rect2(lamp - Vector2.ONE * GLARE, Vector2.ONE * GLARE * 2.0),
			false,
			Color(LIGHT, GLARE_LIGHT)
		)


func _draw_pool() -> void:
	draw_pool(_pool)


## The pool of their light on [param on], round its origin: on the card and the table round it.
static func draw_pool(on: CanvasItem) -> void:
	on.draw_texture_rect(glow(), Rect2(-POOL, POOL * 2.0), false, Color(LIGHT, POOL_LIGHT))


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


## The stub torn off along its holes, from its left end to its right: the card drawn again without
## it, its edge ragged, and in its place the stub's picture in two parts, see [method _set_tear].
func _tear() -> void:
	Audio.play_sfx(&"tear", -4.0, 0.05)
	card.tear()
	card.shows_stub = false
	var mask := _card_place.shine as OpeningCard
	mask.shows_stub = false
	mask.queue_redraw()
	_card_place.refresh()
	_set_tear(0.0)
	var going := create_tween()
	going.tween_method(_set_tear, 0.0, TEAR + FALL, TEAR + FALL)
	going.tween_callback(
		func() -> void:
			_attached.visible = false
			_torn.visible = false
	)


## The stub [param at] seconds into coming away: torn along its holes as far as [member _front],
## the part torn leaning away from the card more the further it is from there, which keeps it whole
## with the part still on; and once torn all along, let go, turning and falling out of sight.
func _set_tear(at: float) -> void:
	var torn := smoothstep(0.0, 1.0, clampf(at / TEAR, 0.0, 1.0))
	var was := _front
	_front = lerpf(OpeningCard.BITE, OpeningCard.SIZE.x - OpeningCard.BITE, torn)
	var lean := TEAR_LEAN * torn
	var leaning := Transform2D(Vector2(1.0, -lean), Vector2(0.0, 1.0), Vector2(0.0, lean * _front))
	var fall := clampf((at - TEAR) / FALL, 0.0, 1.0)
	var falling := Transform2D.IDENTITY
	if fall > 0.0:
		var pivot := Vector2(OpeningCard.SIZE.x - OpeningCard.BITE, OpeningCard.PERFORATION)
		var down := Vector2(0.0, STAGE.y * 1.4 * fall * fall)
		falling = Transform2D(FALL_TURN * fall * fall, pivot + down) * Transform2D(0.0, -pivot)
	_torn.transform = Transform2D(0.0, -OpeningCard.SIZE * 0.5) * falling * leaning
	_torn.visible = true
	_attached.visible = _front < OpeningCard.SIZE.x - OpeningCard.BITE
	if at == 0.0 or not is_equal_approx(was, _front):
		_attached.queue_redraw()
		_torn.queue_redraw()


## The part of the stub still on, from where the tear has got to on, its holes still punched.
func _draw_attached() -> void:
	var tall := OpeningCard.SIZE.y - STUB_TOP
	var wide := OpeningCard.SIZE.x - _front
	_attached.draw_texture_rect_region(
		_stub_sheet.get_texture(),
		Rect2(_front, STUB_TOP, wide, tall),
		Rect2(_front * SHARPEN, 0.0, wide * SHARPEN, tall * SHARPEN)
	)
	var x := OpeningCard.BITE + OpeningCard.HOLE_STEP * 0.75
	while x < OpeningCard.SIZE.x - OpeningCard.BITE - OpeningCard.HOLE_STEP * 0.5:
		if x > _front + OpeningCard.HOLE:
			_attached.draw_circle(
				Vector2(x, OpeningCard.PERFORATION), OpeningCard.HOLE, OpeningCard.HOLE_INK
			)
		x += OpeningCard.HOLE_STEP


## The part of the stub torn, up to where the tear has got to. Once the tear is all the way along
## the attached part is gone, see [method _set_tear], so the torn part takes in the last corner and
## its gold edge rather than leaving that strip undrawn as the stub turns and falls.
func _draw_torn() -> void:
	var tall := OpeningCard.SIZE.y - STUB_TOP
	var wide := OpeningCard.SIZE.x if _front >= OpeningCard.SIZE.x - OpeningCard.BITE else _front
	_torn.draw_texture_rect_region(
		_stub_sheet.get_texture(),
		Rect2(0.0, STUB_TOP, wide, tall),
		Rect2(0.0, 0.0, wide * SHARPEN, tall * SHARPEN)
	)
