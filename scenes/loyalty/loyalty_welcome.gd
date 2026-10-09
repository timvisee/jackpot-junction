class_name LoyaltyWelcome
extends Control
## The House's welcome to its loyalty program, GAME.md 8.9 and STORY.md 6.6b, over the title the
## first time it comes up after the profile playing has played a map to its whistle, see
## [method due], with the ceremony the invitation had, see [OpeningInvitation]: the table dark a
## moment, the House's letter sliding in from below, see [LoyaltyLetter], the program's card glued
## to it, see [LoyaltyCard], and the two spotlights flickering on and settling on the card, which
## turns a little toward the mouse, the stick or the phone, the light catching its foil. One button
## under it, Activate card, and no other way on: the cursor goes nowhere else and Back does nothing;
## a press before the button brings it all at once. Put up under the warm-up's pane and started
## once the shaders have compiled, as the invitation is, and never shown in a run nobody watches.
##
## Activated, the profile is a member and its program settled, so the first map is already counted;
## the card is peeled up off the letter from a corner and comes away, turning over once on its way
## to show its stripe and its signature; the letter drops off the table; and the program's map
## unfolds behind the card, see [LoyaltyDialog], which goes to its place in the map's corner, the
## cursor at the slip road and the first bets open.

## Activated, the program's map open over the title, [param dialog].
signal welcomed(dialog: LoyaltyDialog)

const STAGE := OpeningInvitation.STAGE
## Where the letter's middle lies on the stage and how far it is turned, how big it is shown, and
## from how far below it slides in.
const LETTER_AT := Vector2(960.0, 536.0)
const LETTER_TURN := -0.025
const LETTER_SCALE := 0.92
const FROM_BELOW := Vector2(140.0, 900.0)
const BUTTON_TOP := 990.0
## The two lamps over the card, as far either side of the stage's middle, where the card is, as the
## invitation's are apart, so the beams meet on it evenly, see [method card_rests_at].
const LAMPS: Array[Vector2] = [Vector2(330.0, -160.0), Vector2(1600.0, -160.0)]
const BUTTON_WIDE := 420.0
## How it comes on, each part from and to so many seconds after [method start]: a moment of the
## dark table, the letter slid in, the spotlights switched on over the card, and the button.
const LETTER_IN := Vector2(0.45, 1.2)
const LIGHTS_UP := Vector2(1.35, 1.9)
const BUTTON_UP := Vector2(1.85, 2.25)
const LENGTH := 2.25
## Activated: the button going, the card peeled up from its corner and lifted, turned over once,
## held a beat, the letter dropping off the table as the lights go out, the map unfolding and the
## card carried to its corner of it.
const SETTLE := 0.25
const PEEL := 0.55
const PEEL_LIFT := Vector2(30.0, -70.0)
const PEEL_TURN := -0.16
const PEEL_GROW := 1.08
const TURN_OVER := 0.5
const HOLD := 0.45
const DROP := 0.6
const CARRY := 0.7
const DARKNESS := OpeningInvitation.DARKNESS
const WALKS := OpeningInvitation.WALKS
## The card's shadow on the letter while it is glued and as it is lifted.
const SHADOW_OUT := Vector2(70.0, 80.0)
const SHADOW := 0.55

## For a test, or a debug build's `++ --loyalty-welcome`: shown whether or not it is due.
static var again := false

var profile: Profile
var letter: LoyaltyLetter
var card: LoyaltyCard
var activate: Button
## The map opened as the card was activated, once it has been.
var dialog: LoyaltyDialog

var _stage: Control
var _beams: Node2D
var _pool: Node2D
var _letter_place: Node2D
var _card_place: HeldCard
var _shadow: Node2D
var _started := false
var _time := 0.0
var _coming := true
var _activated := false
var _calm := 1.0
## The card's lift off the letter, 0 glued to 1 lifted away, and its turn over, 0 to 1.
var _lift := 0.0
var _turned := 0.0


## Whether [param of] is to be shown it: once it has played a map to its whistle and not been
## welcomed yet, and never in a run nobody is watching.
static func due(of: Profile) -> bool:
	if again:
		return true
	if Game.is_headless() or Game.is_scripted():
		return false
	return owed(of)


## Whether [param of] has the welcome still to see: a map played to its whistle, and not welcomed.
static func owed(of: Profile) -> bool:
	return not of.loyalty.welcomed and float(of.stats.get(&"maps", 0.0)) >= 1.0


## The number on [param of]'s card: its invitation's, the House having kept it, or one like it for
## a profile that never had one; given once and kept.
static func number_for(of: Profile) -> String:
	if of.loyalty.member.is_empty():
		var invited := of.story.invitation
		if invited.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			invited = "%04d %04d" % [rng.randi_range(0, 9999), rng.randi_range(0, 9999)]
		of.loyalty.member = invited
	return of.loyalty.member


## The welcome over [param parent], for [param of], waiting for [method start].
static func over(parent: Control, of: Profile) -> LoyaltyWelcome:
	var welcome := LoyaltyWelcome.new()
	welcome.name = "LoyaltyWelcome"
	welcome.profile = of
	parent.add_child(welcome)
	return welcome


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
	_beams = Node2D.new()
	_beams.name = "Beams"
	# Aimed at where the card comes to rest, the middle of the table, not where it is as it slides in:
	# the beams are drawn once, as the welcome comes up.
	_beams.draw.connect(
		func() -> void: OpeningInvitation.draw_beams(_beams, card_rests_at(), LAMPS)
	)
	_stage.add_child(_beams)
	_letter_place = Node2D.new()
	_letter_place.name = "LetterPlace"
	_letter_place.scale = Vector2.ONE * LETTER_SCALE
	_stage.add_child(_letter_place)
	letter = LoyaltyLetter.to_profile(profile)
	letter.name = "Letter"
	letter.position = -LoyaltyLetter.SIZE * 0.5
	_letter_place.add_child(letter)
	number_for(profile)
	card = LoyaltyCard.of(profile)
	card.name = "Card"
	var shine := LoyaltyCard.of(profile)
	shine.shine_only = true
	_card_place = HeldCard.of(card, LoyaltyCard.SIZE, shine)
	_card_place.name = "CardPlace"
	_stage.add_child(_card_place)
	_shadow = Node2D.new()
	_shadow.name = "Shadow"
	_shadow.draw.connect(_draw_shadow)
	_card_place.add_child(_shadow)
	_card_place.move_child(_shadow, 0)
	_pool = Node2D.new()
	_pool.name = "Pool"
	_pool.draw.connect(func() -> void: OpeningInvitation.draw_pool(_pool))
	_stage.add_child(_pool)
	activate = MenuTheme.primary(MenuTheme.button(StoryLines.WELCOME_ACTIVATE))
	activate.name = "Activate"
	activate.custom_minimum_size.x = BUTTON_WIDE
	activate.position = Vector2((STAGE.x - BUTTON_WIDE) * 0.5, BUTTON_TOP)
	activate.pressed.connect(_on_activate)
	_stage.add_child(activate)
	# The cursor stays on it: there is nowhere else on this screen to go.
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		activate.set_focus_neighbor(side, activate.get_path())
	activate.focus_next = activate.get_path()
	activate.focus_previous = activate.get_path()
	resized.connect(_fit)
	_fit()
	_lay(0.0)


## Comes on: the letter after a moment, and the rest after it, see [constant LENGTH].
func start() -> void:
	_started = true


## Whether it has been started and the button pressed.
func is_activated() -> bool:
	return _activated


func _fit() -> void:
	var by := minf(minf(size.x / STAGE.x, size.y / STAGE.y), 1.0)
	_stage.scale = Vector2.ONE * by
	_stage.position = (size - STAGE * by) * 0.5


## Where the card is glued on the letter, on the stage, as the letter lies now.
func _card_at() -> Vector2:
	var on_letter := (LoyaltyLetter.CARD_AT - LoyaltyLetter.SIZE * 0.5) * LETTER_SCALE
	return _letter_place.position + on_letter.rotated(_letter_place.rotation)


## Where the card's middle is on the stage once the letter has come to rest.
static func card_rests_at() -> Vector2:
	var on_letter := (LoyaltyLetter.CARD_AT - LoyaltyLetter.SIZE * 0.5) * LETTER_SCALE
	return LETTER_AT + on_letter.rotated(LETTER_TURN)


## Everything as it is [param at] seconds in, coming on.
func _lay(at: float) -> void:
	var dealt := OpeningInvitation._eased(at, LETTER_IN)
	_letter_place.position = LETTER_AT + FROM_BELOW * (1.0 - dealt)
	_letter_place.rotation = lerpf(LETTER_TURN + 0.12, LETTER_TURN, dealt)
	_letter_place.modulate.a = clampf(OpeningInvitation._along(at, LETTER_IN) * 4.0, 0.0, 1.0)
	_place_card()
	var lit := OpeningInvitation._flicker(OpeningInvitation._along(at, LIGHTS_UP))
	_beams.modulate.a = lit
	_pool.modulate.a = lit
	var shown := OpeningInvitation._eased(at, BUTTON_UP)
	activate.modulate.a = shown
	activate.position.y = BUTTON_TOP + 24.0 * (1.0 - shown)
	activate.disabled = shown <= 0.0


## The card where it is: glued on the letter, or as far lifted off it and turned over as it is.
func _place_card() -> void:
	var glued := _card_at()
	var lifted := ease(_lift, 0.5)
	_card_place.position = glued + PEEL_LIFT * lifted
	_card_place.rotation = _letter_place.rotation + PEEL_TURN * lifted
	var grow := LoyaltyLetter.CARD_SCALE * LETTER_SCALE * lerpf(1.0, PEEL_GROW, lifted)
	# Turned over once, edge on halfway, its back showing after.
	var across := absf(cos(_turned * PI))
	_card_place.scale = Vector2(grow * maxf(across, 0.02), grow)
	_card_place.modulate.a = _letter_place.modulate.a
	_pool.position = glued
	_shadow.queue_redraw()


func _draw_shadow() -> void:
	var out := LoyaltyCard.SIZE * 0.5 + SHADOW_OUT * (1.0 + _lift)
	var down := 14.0 + 50.0 * _lift
	_shadow.draw_texture_rect(
		OpeningInvitation.glow(),
		Rect2(Vector2(-out.x, -out.y + down), out * 2.0),
		false,
		Color(0.0, 0.0, 0.0, SHADOW * (1.0 - _lift * 0.4))
	)


func _process(delta: float) -> void:
	if _started and _coming:
		var was := _time
		_time = minf(_time + delta, LENGTH)
		if was < LETTER_IN.x and _time >= LETTER_IN.x:
			Audio.play_sfx(&"page", -6.0, 0.05)
		var switched := LIGHTS_UP.x + (LIGHTS_UP.y - LIGHTS_UP.x) * OpeningInvitation.FLICKER[1].x
		if was < switched and _time >= switched:
			Audio.play_sfx(&"item_use", -10.0, 0.0)
		_lay(_time)
		if was < BUTTON_UP.x and _time >= BUTTON_UP.x:
			activate.grab_focus()
		if _time >= LENGTH:
			_coming = false
	_card_place.follow = _calm * OpeningInvitation._along(_time, LETTER_IN)


## Everything at once, as it is once it has all come on.
func come_on_now() -> void:
	if not _coming:
		return
	_started = true
	_coming = false
	_time = LENGTH
	_lay(LENGTH)
	activate.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if not _started or _activated:
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


## Back does nothing: there is no declining it.
func _unhandled_input(event: InputEvent) -> void:
	if _started and not _activated and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()


## Activated: the profile a member, its program settled and kept; the card peeled off and turned
## over, the letter dropped, and the map unfolded behind the card as it goes to its corner.
func _on_activate() -> void:
	if _activated:
		return
	_activated = true
	come_on_now()
	activate.disabled = true
	join(profile)
	Audio.play_sfx(&"joker_offer", MenuTheme.MOVE_DB, 0.0)
	var going := create_tween()
	going.tween_property(self, "_calm", 0.0, SETTLE)
	going.parallel().tween_property(activate, "modulate:a", 0.0, SETTLE)
	going.tween_method(_set_lift, 0.0, 1.0, PEEL).set_trans(Tween.TRANS_SINE)
	going.tween_callback(Audio.play_sfx.bind(&"page", -8.0, 0.05))
	going.tween_method(_set_turned, 0.0, 1.0, TURN_OVER).set_trans(Tween.TRANS_SINE)
	going.tween_interval(HOLD)
	going.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var down := STAGE.y * 1.3
	going.tween_property(_letter_place, "position:y", LETTER_AT.y + down, DROP)
	going.parallel().tween_property(_letter_place, "rotation", LETTER_TURN - 0.3, DROP)
	going.parallel().tween_property(_beams, "modulate:a", 0.0, DROP * 0.6)
	going.parallel().tween_property(_pool, "modulate:a", 0.0, DROP * 0.6)
	going.tween_callback(_open_map)


## [param of] made a member of its program, GAME.md 8.9: welcomed, its card's number kept, and its
## program settled, so the first map is already counted and the slip road's bets are open; kept.
static func join(of: Profile) -> void:
	number_for(of)
	of.loyalty.welcomed = true
	Loyalty.settle(of)
	if not Game.is_headless():
		Game.settings.save_to_disk()


func _set_lift(by: float) -> void:
	_lift = by
	_place_card()


func _set_turned(by: float) -> void:
	var was_back := _turned >= 0.5
	_turned = by
	if (_turned >= 0.5) != was_back:
		card.back = _turned >= 0.5
		card.queue_redraw()
		(_card_place.shine as LoyaltyCard).back = card.back
		_card_place.shine.queue_redraw()
		_card_place.refresh()
	_place_card()


## The map unfolded behind the card, the table's dark gone from round it; the card carried to its
## corner of the map, turned back to its face on the way, over the map on a layer of its own; and
## then it is the map's, and the welcome is gone.
func _open_map() -> void:
	var parent := get_parent()
	LoyaltyDialog.stood_at = &""
	dialog = LoyaltyDialog.open(parent, true)
	var lifted := CanvasLayer.new()
	lifted.name = "CarriedCard"
	lifted.layer = LoyaltyDialog.LAYER + 1
	add_child(lifted)
	var held := _card_place.get_global_transform_with_canvas()
	_card_place.reparent(lifted, false)
	_card_place.transform = held
	# The dark table gone from round the map; the card, on its own layer, is not.
	create_tween().tween_property(self, "modulate:a", 0.0, CARRY * 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	welcomed.emit(dialog)
	var corner := dialog.card_corner
	if corner == null or not is_instance_valid(corner):
		queue_free()
		return
	corner.modulate.a = 0.0
	var target := corner.get_global_rect()
	var scale_to := target.size.x / LoyaltyCard.SIZE.x
	var carry := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	carry.tween_property(_card_place, "position", target.get_center(), CARRY)
	carry.parallel().tween_property(_card_place, "rotation", 0.0, CARRY)
	carry.parallel().tween_method(
		func(by: float) -> void:
			var across := absf(cos((1.0 + by) * PI))
			_card_place.scale = Vector2(scale_to * maxf(across, 0.02), scale_to)
			if by >= 0.5 and card.back:
				card.back = false
				card.queue_redraw()
				(_card_place.shine as LoyaltyCard).back = false
				_card_place.shine.queue_redraw()
				_card_place.refresh(),
		0.0,
		1.0,
		CARRY
	)
	carry.tween_callback(
		func() -> void:
			if is_instance_valid(corner):
				corner.modulate.a = 1.0
			queue_free()
	)
