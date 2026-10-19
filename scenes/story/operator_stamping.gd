class_name OperatorStamping
extends Node
## The license coming up after the ending, STORY.md 8.6, made the Operator's before the player's
## eyes: shown as it was, the House's gold rubber stamp comes in off its right edge, swings over and
## comes down by itself on its lower left corner with a thud, APPROVED there from then on, see
## [RubberStamp]; and a moment later its class and its expiry are written over as the Operator's,
## each struck through and typed in again, CLASS K · Operator and EXPIRES NEVER, in the House's
## gold drying to ink. Over the [LicenseView] that
## shows it. Put away early, it stops where it is: the card is the profile's either way.

## How long after the view has come up the stamp comes in, how long it takes to, and how long it
## hangs before it comes down.
const WAIT := 0.5
const COME_IN := 0.25
const HANG := 0.3
## How long after the stamp lands the class and the expiry are written over, and how long that
## takes, striking out, typing in and drying, see [member LicenseCard.rewritten].
const INK_AFTER := 0.6
const REWRITE := 3.2
## Where the stamp hangs off the card's right edge, and where it lands, its top left in the card's
## space with its base over the mark it leaves, as on the driving test's license, see
## [LicenseScreen].
const HANGS := Vector2(
	LicenseCard.SIZE.x - 70.0, LicenseCard.HOUSE_STAMP_AT.y - LicenseScreen.STAMP_FOOT
)
const LANDS := Vector2(
	LicenseCard.HOUSE_STAMP_AT.x - RubberStamp.SIZE.x * 0.5,
	LicenseCard.HOUSE_STAMP_AT.y - LicenseScreen.STAMP_FOOT
)

var view: LicenseView
## Where the stamp moves, laid over the card as it is shown.
var _over: Control
var _stamp: RubberStamp


## The license in [param shown_in] made the Operator's as it is looked at, where it is the
## Operator's; nothing otherwise.
static func on(shown_in: LicenseView) -> OperatorStamping:
	var stamping := OperatorStamping.new()
	stamping.name = "OperatorStamping"
	stamping.view = shown_in
	shown_in.add_child(stamping)
	return stamping


func _ready() -> void:
	var card := view.card
	if card == null or card.approved.is_empty():
		queue_free()
		return
	card.house_shown = false
	card.operator_shown = false
	_over = Control.new()
	_over.name = "StampOver"
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.modulate.a = 0.0
	view.add_child(_over)
	_stamp = RubberStamp.create()
	_stamp.by_itself = true
	_stamp.rubber = HouseTheme.FOIL
	_stamp.rubber_dark = HouseTheme.FOIL_LOW
	_stamp.position = HANGS
	_stamp.lands_at = LANDS
	_stamp.stamped.connect(_on_stamped)
	_over.add_child(_stamp)
	_lay_over()
	var steps := create_tween()
	steps.tween_interval(LicenseView.FLY + WAIT)
	steps.tween_property(_over, "modulate:a", 1.0, COME_IN)
	steps.tween_interval(HANG)
	steps.tween_callback(_stamp.slam)


func _process(_delta: float) -> void:
	_lay_over()


## Over the card as it is shown on its stand, at the stand's size, so the stamp's card space is
## the card's.
func _lay_over() -> void:
	if _over == null or not is_instance_valid(view.stand):
		return
	var stand := view.stand
	var shown := stand.get_global_transform().get_scale().x * stand.shown
	_over.scale = Vector2.ONE * shown
	_over.global_position = stand.get_global_position() + Vector2.ONE * TiltedCard.PAD * shown


## The stamp down: APPROVED on the card, and a moment later the Operator's class and expiry.
func _on_stamped() -> void:
	var card := view.card
	card.house_shown = true
	var steps := create_tween()
	steps.tween_interval(INK_AFTER)
	steps.tween_callback(_ink_the_class)
	steps.tween_method(_write, 0.0, 1.0, REWRITE)
	steps.tween_callback(_done)


func _ink_the_class() -> void:
	var card := view.card
	card.rewritten = 0.0
	card.operator_shown = true
	var said: Array[String] = [
		StoryLines.STAMP_WORD,
		"Class " + StoryLines.CLASS_AFTER,
		"Expires " + StoryLines.EXPIRES_AFTER,
	]
	ScreenReader.say(view, ScreenReader.line(said))


## The class and the expiry written over [param share] of the way, a key's tick for every letter
## typed in.
func _write(share: float) -> void:
	var card := view.card
	var before := card.letters_written()
	card.rewritten = share
	if card.letters_written() > before:
		Audio.play_sfx(&"bank_tick", -14.0, 0.15)


func _done() -> void:
	if _over != null and is_instance_valid(_over):
		_over.queue_free()
	queue_free()
