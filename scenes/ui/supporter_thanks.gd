class_name SupporterThanks
extends Control
## The Steam supporter pack's thank-you, GAME.md 10.8, over the title the first time a start sees
## the pack, once for each install of the game and each Steam account on it, see [method due]: the
## table dark a moment, a warm lamp coming up over it, a kraft envelope addressed by hand sliding in
## from below, see [ThankYouEnvelope], and the maker's card drawn up out of it and held up a little
## toward the mouse, the stick or the phone, its silver catching the light, see [ThankYouCard] and
## [HeldCard]. Two buttons under it: Try them on, which opens the kart dialog where the pack's
## pieces hang, and Close; Back closes it too, and a press before the buttons brings it all at once.
## Closed, card and envelope drop off the table as the lamp goes out, and it is not shown again.
## Put up under the warm-up's pane and started once the shaders have compiled, as the House's
## letters are, see [HouseMail], which it shares the title's place with.

## Closed, and gone.
signal put_away

const STAGE := OpeningInvitation.STAGE
## Where the envelope and the card lie on the stage and how far each is turned, from how far below
## they slide in, how big the card is shown, and where the buttons stand.
const ENVELOPE_AT := Vector2(1240.0, 660.0)
const ENVELOPE_TURN := 0.05
const CARD_AT := Vector2(790.0, 450.0)
const CARD_TURN := -0.035
const CARD_SCALE := 1.05
const FROM_BELOW := Vector2(120.0, 900.0)
const BUTTON_TOP := 990.0
const BUTTON_WIDE := 330.0
const BUTTON_GAP := 30.0
## The one lamp over it, just off the top of the stage.
const LAMPS: Array[Vector2] = [Vector2(790.0, -170.0)]
## How much farther on than the invitation's its beam goes, fading out: the card is still on its way
## in when the lamp comes up, so the beam's far end is seen rather than hidden behind it.
const BEAM_FADE := 360.0
## How it comes on, each part from and to so many seconds after [method start], and how it goes.
const ENVELOPE_IN := Vector2(0.4, 1.0)
const CARD_OUT := Vector2(1.2, 2.2)
const LIGHTS_UP := Vector2(0.2, 0.8)
const BUTTONS_UP := Vector2(2.1, 2.5)
const LENGTH := 2.5
const DROP := 0.6
## How much of a held card's turn toward the mouse the card follows.
const CARD_TILT := 0.6
const DARKNESS := OpeningInvitation.DARKNESS
const WALKS := OpeningInvitation.WALKS
## Of those, the ones that walk the cursor between its two buttons once they are up.
const STEPS: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]
## Its two buttons, shown through tr().
const TRY_ON := "Try them on"
const CLOSE := "Close"
## The layer the thanks for a pack just bought come up on, see [method over_all]: over the kart
## dialog, the catalog and the program's map, at 25, under the ending's last lines and the
## achievements' toasts.
const LAYER := 30

var card: ThankYouCard
var try_on: Button
var closing: Button
## Whether it is held up again, from where it is taped up in the Garage's bay, see [BayThanks]: the
## card alone, no envelope, Close its one button, and nothing kept.
var again := false
## What the thanks are up over, which Try them on opens the kart dialog over: the menu under their
## layer, see [method over_all], or else their parent.
var under: Control
## Where the card lies: beside the envelope, or in the middle when it is held up again.
var _at := CARD_AT
## The layer of their own they are up on, see [method over_all], which goes with them.
var _layer: CanvasLayer

var _stage: Control
var _beams: Node2D
var _pool: Node2D
var _envelope_place: Node2D
var _card_place: Node2D
var _held: HeldCard
var _started := false
var _time := 0.0
var _coming := true
var _gone := false


## Whether the thank-you is due here: the supporter pack owned and the card not shown yet on this
## install and Steam account; never in the demo for a booth.
static func due() -> bool:
	return Supporter.owned() and not Game.settings.supporter_thanked and not Demo.on


## The card held up again over [param parent]: the kart dialog, from where it is taped up in the
## bay, see [BayThanks], or the settings, from the Me page's supporter section, see [LicenseTab]:
## started at once.
static func again_over(parent: Node) -> SupporterThanks:
	var thanks := SupporterThanks.new()
	thanks.name = "SupporterThanks"
	thanks.again = true
	parent.add_child(thanks)
	thanks.start()
	return thanks


## The thank-you over [param parent], waiting for [method start], or null when it is not due.
static func over(parent: Control) -> SupporterThanks:
	if not due():
		return null
	var thanks := SupporterThanks.new()
	thanks.name = "SupporterThanks"
	parent.add_child(thanks)
	return thanks


## The thanks for a pack just bought while [param menu] is up, GAME.md 10.8, started at once over
## whatever is open over it, the kart dialog the pack was bought from, say, on a layer of their own;
## once they are put away the cursor goes back where it was. Null when they are not due.
static func over_all(menu: Control) -> SupporterThanks:
	if not due():
		return null
	var layer := CanvasLayer.new()
	layer.name = "SupporterThanksLayer"
	layer.layer = LAYER
	menu.add_child(layer)
	var thanks := SupporterThanks.new()
	thanks.name = "SupporterThanks"
	thanks.under = menu
	thanks._layer = layer
	layer.add_child(thanks)
	var had := menu.get_viewport().gui_get_focus_owner()
	thanks.put_away.connect(
		func() -> void:
			if is_instance_valid(had) and had.is_visible_in_tree():
				had.grab_focus()
	)
	thanks.start()
	return thanks


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if again:
		_at = Vector2(STAGE.x * 0.5, CARD_AT.y)
	MenuTheme.background(self)
	add_child(MenuTheme.closer_shade(DARKNESS))
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.size = STAGE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_beams = Node2D.new()
	_beams.name = "Beams"
	_beams.draw.connect(
		func() -> void:
			OpeningInvitation.draw_beams(_beams, _at, [Vector2(_at.x, LAMPS[0].y)], BEAM_FADE)
	)
	_stage.add_child(_beams)
	_envelope_place = Node2D.new()
	_envelope_place.name = "EnvelopePlace"
	_stage.add_child(_envelope_place)
	var envelope := ThankYouEnvelope.new()
	envelope.position = -ThankYouEnvelope.SIZE * 0.5
	_envelope_place.add_child(envelope)
	_card_place = Node2D.new()
	_card_place.name = "CardPlace"
	_card_place.scale = Vector2.ONE * CARD_SCALE
	_stage.add_child(_card_place)
	card = ThankYouCard.new()
	card.name = "Card"
	_held = HeldCard.of(card, ThankYouCard.SIZE, card.shine())
	_held.name = "Held"
	_card_place.add_child(_held)
	_pool = Node2D.new()
	_pool.name = "Pool"
	_pool.position = _at
	_pool.draw.connect(func() -> void: OpeningInvitation.draw_pool(_pool))
	_stage.add_child(_pool)
	try_on = MenuTheme.primary(MenuTheme.button(tr(TRY_ON)))
	try_on.name = "TryOn"
	try_on.pressed.connect(_close.bind(true))
	closing = MenuTheme.button(tr(CLOSE))
	closing.name = "Close"
	closing.pressed.connect(_close.bind(false))
	var left := (STAGE.x - BUTTON_WIDE * 2.0 - BUTTON_GAP) * 0.5
	for i: int in 2:
		var button: Button = [try_on, closing][i]
		button.custom_minimum_size.x = BUTTON_WIDE
		button.position = Vector2(left + float(i) * (BUTTON_WIDE + BUTTON_GAP), BUTTON_TOP)
		_stage.add_child(button)
		# The cursor stays on the two of them: there is nowhere else on this screen to go.
		for side: int in [SIDE_TOP, SIDE_BOTTOM]:
			button.set_focus_neighbor(side, button.get_path())
	try_on.set_focus_neighbor(SIDE_LEFT, try_on.get_path())
	try_on.set_focus_neighbor(SIDE_RIGHT, closing.get_path())
	closing.set_focus_neighbor(SIDE_LEFT, try_on.get_path())
	closing.set_focus_neighbor(SIDE_RIGHT, closing.get_path())
	if again:
		envelope.hide()
		try_on.hide()
		closing.position.x = (STAGE.x - BUTTON_WIDE) * 0.5
		closing.set_focus_neighbor(SIDE_LEFT, closing.get_path())
	resized.connect(_fit)
	_fit()
	_lay(0.0)


func _notification(what: int) -> void:
	ScreenReader.dialog(self, what)


## Comes on: the lamp, the envelope, the card out of it and the buttons, see [constant LENGTH].
func start() -> void:
	_started = true
	ScreenReader.say(self, ScreenReader.line([tr(ThankYouCard.HEADING), tr(ThankYouCard.NOTE)]))


func _fit() -> void:
	var by := minf(minf(size.x / STAGE.x, size.y / STAGE.y), 1.0)
	_stage.scale = Vector2.ONE * by
	_stage.position = (size - STAGE * by) * 0.5


## Everything as it is [param at] seconds in, coming on: the envelope slid in, then the card drawn
## up out of it and over to its place.
func _lay(at: float) -> void:
	var dealt := OpeningInvitation._eased(at, ENVELOPE_IN)
	_envelope_place.position = ENVELOPE_AT + FROM_BELOW * (1.0 - dealt)
	_envelope_place.rotation = lerpf(ENVELOPE_TURN - 0.1, ENVELOPE_TURN, dealt)
	_envelope_place.modulate.a = clampf(OpeningInvitation._along(at, ENVELOPE_IN) * 4.0, 0.0, 1.0)
	var drawn := OpeningInvitation._eased(at, CARD_OUT)
	var from := _envelope_place.position + Vector2(0.0, -40.0)
	var arc := Vector2(0.0, -120.0) * sin(drawn * PI)
	if again:
		from = _at + FROM_BELOW
		arc = Vector2.ZERO
	_card_place.position = from.lerp(_at, drawn) + arc
	_card_place.rotation = lerpf(ENVELOPE_TURN, CARD_TURN, drawn)
	_card_place.scale = Vector2.ONE * lerpf(CARD_SCALE * 0.7, CARD_SCALE, drawn)
	_card_place.modulate.a = clampf(OpeningInvitation._along(at, CARD_OUT) * 5.0, 0.0, 1.0)
	var lit := OpeningInvitation._flicker(OpeningInvitation._along(at, LIGHTS_UP))
	_beams.modulate.a = lit
	_pool.modulate.a = lit
	var up := OpeningInvitation._eased(at, BUTTONS_UP)
	for button: Button in [try_on, closing]:
		button.modulate.a = up
		button.position.y = BUTTON_TOP + 24.0 * (1.0 - up)
		button.disabled = up <= 0.0


func _process(delta: float) -> void:
	if _started and _coming:
		var was := _time
		_time = minf(_time + delta, LENGTH)
		if was < ENVELOPE_IN.x and _time >= ENVELOPE_IN.x:
			Audio.play_sfx(&"page", -6.0, 0.05)
		if was < CARD_OUT.x and _time >= CARD_OUT.x:
			Audio.play_sfx(&"page", -8.0, 0.05)
		_lay(_time)
		if was < BUTTONS_UP.x and _time >= BUTTONS_UP.x:
			(closing if again else try_on).grab_focus()
		if _time >= LENGTH:
			_coming = false
	_held.follow = CARD_TILT * OpeningInvitation._along(_time, CARD_OUT) * (0.0 if _gone else 1.0)


## Everything at once, as it is once it has all come on.
func come_on_now() -> void:
	if not _coming:
		return
	_started = true
	_coming = false
	_time = LENGTH
	_lay(LENGTH)
	(closing if again else try_on).grab_focus.call_deferred()


## Whether it has come all the way on, the buttons up.
func is_up() -> bool:
	return _started and not _coming


func _input(event: InputEvent) -> void:
	if not _started or _gone:
		return
	# Over the kart dialog, held up again or come at once on the pack bought there, the dialog's
	# own keys wait till it is put away.
	if _for_the_dialog(event):
		get_viewport().set_input_as_handled()
		return
	# Up, a key or a pad's button with the cursor on neither button puts it on the first, so a player
	# with a pad always has one to press and to walk from.
	if is_up() and _pressed(event) and not _holds_cursor():
		get_viewport().set_input_as_handled()
		_first().grab_focus()
		return
	for walk: StringName in WALKS:
		if event.is_action(walk):
			# Up, the cursor walks between the two buttons, whose neighbours keep it on them; the
			# Tab keys, which would walk it off to the screen under, are kept.
			if is_up() and walk in STEPS:
				return
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


## The button the cursor goes on first: Try them on, or Close where it is the only one.
func _first() -> Button:
	return closing if again else try_on


## Whether the cursor is on one of its buttons.
func _holds_cursor() -> bool:
	var on := get_viewport().gui_get_focus_owner()
	return on != null and (on == try_on or on == closing) and on.is_visible_in_tree()


## Whether [param event] is a key or a pad's button pressed, or a pad's stick pushed.
static func _pressed(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventJoypadButton:
		return event.is_pressed() and not event.is_echo()
	var stick := event as InputEventJoypadMotion
	return stick != null and absf(stick.axis_value) > 0.5


## Whether [param event] is one of the kart dialog's own keys rather than this screen's.
static func _for_the_dialog(event: InputEvent) -> bool:
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return false
	for own: StringName in [&"ui_accept", &"ui_cancel", &"ui_left", &"ui_right"]:
		if event.is_action(own):
			return false
	return true


## Back closes it, once it is up.
func _unhandled_input(event: InputEvent) -> void:
	if not _started or _gone or not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if is_up():
		_close(false)


## Closed, kept as shown, and card and envelope dropped off the table as the lamp goes out; then,
## for [param trying], the kart dialog opened over what it was put up on.
func _close(trying: bool) -> void:
	if _gone:
		return
	_gone = true
	come_on_now()
	try_on.disabled = true
	closing.disabled = true
	if not again:
		Game.settings.supporter_thanked = true
		if not Game.is_headless():
			Game.settings.save_to_disk()
	Audio.play_sfx(&"page", -8.0, 0.05)
	var drop := create_tween()
	drop.tween_property(try_on, "modulate:a", 0.0, 0.2)
	drop.parallel().tween_property(closing, "modulate:a", 0.0, 0.2)
	drop.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	drop.tween_property(_card_place, "position:y", _at.y + STAGE.y * 1.3, DROP)
	drop.parallel().tween_property(_card_place, "rotation", CARD_TURN + 0.3, DROP)
	drop.parallel().tween_property(_envelope_place, "position:y", ENVELOPE_AT.y + STAGE.y, DROP)
	drop.parallel().tween_property(_beams, "modulate:a", 0.0, DROP * 0.6)
	drop.parallel().tween_property(_pool, "modulate:a", 0.0, DROP * 0.6)
	drop.tween_property(self, "modulate:a", 0.0, 0.2)
	drop.tween_callback(
		func() -> void:
			var over := under if under != null else get_parent() as Control
			put_away.emit()
			if trying and over != null:
				# Not a second dialog over one already open, the pack bought from it.
				if over.find_children("*", "KartDialog", false, false).is_empty():
					KartDialog.open(over)
			# Their layer goes with them, where they have one.
			if _layer != null:
				_layer.queue_free()
			else:
				queue_free()
	)
