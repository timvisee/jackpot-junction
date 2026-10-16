class_name HouseMail
extends Control
## A letter of the House's over the title, STORY.md 6.11, with the ceremony its welcome to the
## loyalty program has, see [LoyaltyWelcome]: the table dark a moment, the letter sliding in from
## below and held up a little toward the mouse, the stick or the phone, see [HeldCard], two
## spotlights flickering on over it, and one button under it, Put it away. Put away, the letter
## drops off the table as the lights go out, and is filed in Kit's folder with any the profile was
## owed before it, see [StoryLetters]. Back puts it away too; a press before the button brings it
## all at once. Put up under the warm-up's pane and started once the shaders have compiled, as the
## welcome is, and never shown in a run nobody watches.

## Put away, the letter filed.
signal put_away

const STAGE := OpeningInvitation.STAGE
## Where the letter's middle lies on the stage and how far it is turned, how big it is shown, a card
## shown bigger than a letter, and from how far below it slides in.
const LETTER_AT := Vector2(960.0, 500.0)
const LETTER_TURN := -0.02
const LETTER_SCALE := 0.84
const CARD_SCALE := 1.35
const FROM_BELOW := Vector2(120.0, 900.0)
const BUTTON_TOP := 990.0
const BUTTON_WIDE := 380.0
const LAMPS: Array[Vector2] = [Vector2(330.0, -160.0), Vector2(1600.0, -160.0)]
## How it comes on, each part from and to so many seconds after [method start], and how it goes.
const LETTER_IN := Vector2(0.45, 1.2)
const LIGHTS_UP := Vector2(1.35, 1.9)
const BUTTON_UP := Vector2(1.85, 2.25)
const LENGTH := 2.25
const DROP := 0.6
## How much of a held card's turn toward the mouse the letter follows.
const LETTER_TILT := 0.35
const DARKNESS := OpeningInvitation.DARKNESS
const WALKS := OpeningInvitation.WALKS

var profile: Profile
var key: StringName = &""
var letter: HouseLetter
var away: Button

var _stage: Control
var _beams: Node2D
var _pool: Node2D
var _letter_place: Node2D
var _held: HeldCard
var _started := false
var _time := 0.0
var _coming := true
var _gone := false


## The letter due for [param of] over [param parent], waiting for [method start], or null for none.
static func over(parent: Control, of: Profile) -> HouseMail:
	var due := StoryLetters.due(of)
	if due.is_empty():
		return null
	var mail := HouseMail.new()
	mail.name = "HouseMail"
	mail.profile = of
	mail.key = due
	parent.add_child(mail)
	return mail


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
	_beams.draw.connect(func() -> void: OpeningInvitation.draw_beams(_beams, LETTER_AT, LAMPS))
	_stage.add_child(_beams)
	_letter_place = Node2D.new()
	_letter_place.name = "LetterPlace"
	var shown := CARD_SCALE if HouseLetter.is_card(key) else LETTER_SCALE
	_letter_place.scale = Vector2.ONE * shown
	_stage.add_child(_letter_place)
	letter = HouseLetter.of(key, profile)
	letter.name = "Letter"
	# Nothing on a letter shines: its shine is a black sheet.
	var dull := ColorRect.new()
	dull.color = Color.BLACK
	dull.size = letter.size
	dull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held = HeldCard.of(letter, letter.size, dull)
	_held.name = "Held"
	_held.sharpen = 1.25
	_letter_place.add_child(_held)
	_pool = Node2D.new()
	_pool.name = "Pool"
	_pool.position = LETTER_AT
	_pool.draw.connect(func() -> void: OpeningInvitation.draw_pool(_pool))
	_stage.add_child(_pool)
	away = MenuTheme.primary(MenuTheme.button(StoryLines.MAIL_PUT_AWAY))
	away.name = "PutAway"
	away.custom_minimum_size.x = BUTTON_WIDE
	away.position = Vector2((STAGE.x - BUTTON_WIDE) * 0.5, BUTTON_TOP)
	away.pressed.connect(_put_away)
	_stage.add_child(away)
	# The cursor stays on it: there is nowhere else on this screen to go.
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		away.set_focus_neighbor(side, away.get_path())
	away.focus_next = away.get_path()
	away.focus_previous = away.get_path()
	resized.connect(_fit)
	_fit()
	_lay(0.0)


func _notification(what: int) -> void:
	ScreenReader.dialog(self, what)


## Comes on: the letter after a moment, and the rest after it, see [constant LENGTH].
func start() -> void:
	_started = true
	ScreenReader.say(self, StoryLetters.read_out(key, profile))


func _fit() -> void:
	var by := minf(minf(size.x / STAGE.x, size.y / STAGE.y), 1.0)
	_stage.scale = Vector2.ONE * by
	_stage.position = (size - STAGE * by) * 0.5


## Everything as it is [param at] seconds in, coming on.
func _lay(at: float) -> void:
	var dealt := OpeningInvitation._eased(at, LETTER_IN)
	_letter_place.position = LETTER_AT + FROM_BELOW * (1.0 - dealt)
	_letter_place.rotation = lerpf(LETTER_TURN + 0.12, LETTER_TURN, dealt)
	_letter_place.modulate.a = clampf(OpeningInvitation._along(at, LETTER_IN) * 4.0, 0.0, 1.0)
	var lit := OpeningInvitation._flicker(OpeningInvitation._along(at, LIGHTS_UP))
	_beams.modulate.a = lit
	_pool.modulate.a = lit
	var up := OpeningInvitation._eased(at, BUTTON_UP)
	away.modulate.a = up
	away.position.y = BUTTON_TOP + 24.0 * (1.0 - up)
	away.disabled = up <= 0.0


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
			away.grab_focus()
		if _time >= LENGTH:
			_coming = false
	_held.follow = (
		LETTER_TILT * OpeningInvitation._along(_time, LETTER_IN) * (0.0 if _gone else 1.0)
	)


## Everything at once, as it is once it has all come on.
func come_on_now() -> void:
	if not _coming:
		return
	_started = true
	_coming = false
	_time = LENGTH
	_lay(LENGTH)
	away.grab_focus.call_deferred()


## Whether it has come all the way on, the button up.
func is_up() -> bool:
	return _started and not _coming


func _input(event: InputEvent) -> void:
	if not _started or _gone:
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


## Back puts it away, once it is up.
func _unhandled_input(event: InputEvent) -> void:
	if not _started or _gone or not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if is_up():
		_put_away()


## Put away: filed, with any letter owed before it, and the letter dropped off the table as the
## lights go out.
func _put_away() -> void:
	if _gone:
		return
	_gone = true
	come_on_now()
	away.disabled = true
	StoryLetters.file_owed(profile)
	if not Game.is_headless():
		Game.settings.save_to_disk()
	Audio.play_sfx(&"page", -8.0, 0.05)
	var drop := create_tween()
	drop.tween_property(away, "modulate:a", 0.0, 0.2)
	drop.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	drop.tween_property(_letter_place, "position:y", LETTER_AT.y + STAGE.y * 1.3, DROP)
	drop.parallel().tween_property(_letter_place, "rotation", LETTER_TURN - 0.3, DROP)
	drop.parallel().tween_property(_beams, "modulate:a", 0.0, DROP * 0.6)
	drop.parallel().tween_property(_pool, "modulate:a", 0.0, DROP * 0.6)
	drop.tween_property(self, "modulate:a", 0.0, 0.2)
	drop.tween_callback(
		func() -> void:
			put_away.emit()
			queue_free()
	)
