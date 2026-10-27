class_name LicenseScreen
extends Control
## The end of the driving test, GAME.md 9.4a, up over the room a moment after the final exam is
## passed, on the pane the podium is cut from with the player's color along its top: YOU PASSED,
## a word from the examiner, the license itself, see [LicenseCard], with the rubber stamp hanging
## over its corner, see [RubberStamp], and under it a line saying to press it. Stamped, the card
## takes its mark and shakes, and is held up in full over the screen, see [LicenseView]; put away,
## a second page takes its place: the congratulations, the test's time in small type with the best
## beside it once an earlier pass was quicker, and the ways on in a row, the Garage, the road, which
## is Play, and the title. The plate for the back of the kart is chosen on the License tab, 8.5.
## Nothing leaves this screen without stamping: the stamp is the point. Either page fits the
## screen, see [method _fit].

## The stamp came down.
signal stamped
## A way on was taken: garage, play or title.
signal chosen(way: StringName)

const TITLE := "YOU PASSED"
const LINE := "The examiner found nothing to object to. Your license, then."
const STAMP_LINE := "%s the stamp to make it official"
const DONE_TITLE := "CONGRATULATIONS, %s"
const DONE_LINE := "Class K. Valid on every table. The Junction is yours."
## The ways on, in the order they stand, each its word on the button.
const WAYS: Array[Array] = [
	[&"garage", "Garage"], [&"play", "Hit the road"], [&"title", "Back to title"]
]
const WAY_WIDTH := 240.0
## How long the screen takes to come up, and how long the card is left stamped before the ways on
## come up under it.
const RISE := 0.45
## How long the first license is held up before it turns over by itself, and how long its back.
const BACK_AFTER := 1.6
const BACK_HOLD := 3.2
const SETTLE := 0.8
## How long after the pane is up, or the stamp down, the step it finishes is ticked.
const TICK_AFTER := 0.35
## Where the stamp hangs, off the right edge of the card so it hides nothing on it, and where it
## lands, its top left in the card's space with its base over the mark it leaves; and the room
## kept either side of the card for it to hang in.
const STAMP_FOOT := 134.0
const STAMP_HANGS := Vector2(LicenseCard.SIZE.x - 70.0, LicenseCard.STAMP_AT.y - STAMP_FOOT)
const STAMP_LANDS := Vector2(
	LicenseCard.STAMP_AT.x - RubberStamp.SIZE.x * 0.5, LicenseCard.STAMP_AT.y - STAMP_FOOT
)
const STAMP_ROOM := 84.0
## The room over and under the card on the desk, and kept round the pane at the screen's edges.
const PAD := 22.0
const MARGIN := 16.0
## The test's time, under the congratulations, and the best beside it once it was quicker.
const TIME_LINE := "Test time %s"
const BEST_LINE := "best %s"
const TIME_AIR := 8.0
const SHAKES := 5
const SHAKE := 7.0

var card: LicenseCard
var stamp: RubberStamp
## The test's time as said under the congratulations.
var time_line: Label
## The course along the top, see [method SchoolEnrollment.course_row].
var course: HBoxContainer
## What each way on does: the scenes, unless a test says otherwise.
var ways: Dictionary[StringName, Callable] = {}
var buttons: Dictionary[StringName, Button] = {}
## The license in full, up once it is stamped until it is put away, see [LicenseView].
var view: LicenseView
## Whether the card, held up, turns over by itself once to show its back, STORY.md 6.7: the first
## license a machine is issued, scratched.
var shows_back := false

var _pane: PanelContainer
## The first page, the card to stamp, which the plate and the ways on take the place of.
var _card_page: VBoxContainer
var _desk: Control
var _hint: Label
var _foot: VBoxContainer
var _edge := Palette.CHIP_GOLD


## The screen for [param of], up over [param layer], the card numbered [param numbered] and issued
## on [param on], the kart in [param in_color] dressed [param dressed], with [param earned] along
## its foot, the pane's edge in [param edge].
static func add_to(
	layer: CanvasLayer,
	of: String,
	numbered: String,
	on: String,
	in_color: int,
	dressed: KartStyle,
	earned: Dictionary[String, bool],
	edge: Color
) -> LicenseScreen:
	var screen := LicenseScreen.new()
	screen.name = "License"
	screen.card = LicenseCard.create(of, numbered, on, in_color, dressed, earned)
	screen._edge = edge
	layer.add_child(screen)
	return screen


func _init() -> void:
	ways = {
		&"garage": Game.go_to_garage,
		&"play": Game.go_to_lobby,
		&"title": Game.go_to_title,
	}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	# Two pages, one after the other, so either fits a phone held sideways: the card to stamp, and
	# then the plate and the ways on. Side by side they made a pane too wide, and one under the
	# other too tall. The pane is drawn smaller still on a screen smaller than it, see [method _fit].
	var center := CenterContainer.new()
	center.name = "Middle"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_pane = MenuTheme.pane(_edge)
	center.add_child(_pane)
	var pages := VBoxContainer.new()
	_pane.add_child(pages)
	_card_page = VBoxContainer.new()
	_card_page.name = "CardPage"
	_card_page.add_theme_constant_override("separation", 12)
	_card_page.custom_minimum_size = Vector2(LicenseCard.SIZE.x + STAMP_ROOM * 2.0, 0.0)
	pages.add_child(_card_page)
	_card_page.add_child(MenuTheme.title(TITLE, Type.TITLE))
	_card_page.add_child(MenuTheme.subtitle(LINE, Type.BODY))
	# The course, its theory done; the driving test ticks as the pane comes up, and the license
	# as the stamp comes down.
	course = SchoolEnrollment.course_row(1)
	_card_page.add_child(course)
	var test_done := create_tween()
	test_done.tween_interval(RISE + TICK_AFTER)
	test_done.tween_callback(SchoolEnrollment.tick.bind(course, 1))
	_desk = Control.new()
	_desk.name = "Desk"
	_desk.custom_minimum_size = LicenseCard.SIZE + Vector2(0.0, PAD * 2.0)
	_desk.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_page.add_child(_desk)
	card.position = Vector2(0.0, PAD)
	_desk.add_child(card)
	stamp = RubberStamp.create()
	stamp.position = STAMP_HANGS + Vector2(0.0, PAD)
	stamp.lands_at = STAMP_LANDS + Vector2(0.0, PAD)
	stamp.stamped.connect(_on_stamped)
	stamp.device_changed.connect(_say_how)
	_desk.add_child(stamp)
	_hint = MenuTheme.subtitle("", Type.BODY)
	_card_page.add_child(_hint)
	_say_how()
	_foot = VBoxContainer.new()
	_foot.name = "Ways"
	_foot.add_theme_constant_override("separation", 14)
	_foot.add_child(MenuTheme.title(DONE_TITLE % card.holder_name, Type.TITLE))
	_foot.add_child(MenuTheme.subtitle(DONE_LINE, Type.BODY))
	_foot.add_child(_time_row())
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for way: Array in WAYS:
		var button := MenuTheme.button(way[1], Type.LARGE)
		button.custom_minimum_size.x = WAY_WIDTH
		button.pressed.connect(_choose.bind(way[0]))
		buttons[way[0]] = button
		row.add_child(button)
	_foot.add_child(row)
	_foot.visible = false
	pages.add_child(_foot)
	resized.connect(_fit)
	_pane.minimum_size_changed.connect(_fit)
	_fit.call_deferred()
	modulate.a = 0.0
	var rise := create_tween()
	rise.tween_property(self, "modulate:a", 1.0, RISE)
	stamp.grab_focus()


## How the stamp is pressed, under the card, for the device in hand.
func _say_how() -> void:
	_hint.text = STAMP_LINE % stamp.press_word()


## The test's time, said once and quietly: small and gray, with the best beside it once an earlier
## pass was quicker, and nothing for a test with no time kept.
func _time_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	time_line = MenuTheme.subtitle(time_words(Game.settings.profile), Type.LABEL)
	time_line.name = "TestTime"
	time_line.visible = not time_line.text.is_empty()
	box.add_child(time_line)
	var air := Control.new()
	air.custom_minimum_size = Vector2(0.0, TIME_AIR)
	box.add_child(air)
	return box


## What the line says of [param profile]'s test: its time, and the best beside it where that is
## quicker; nothing for none.
static func time_words(profile: Profile) -> String:
	if profile.test_time <= 0.0:
		return ""
	var words := TIME_LINE % clock(profile.test_time)
	if profile.test_best > 0.0 and profile.test_best < profile.test_time - 0.05:
		words += "  ·  " + BEST_LINE % clock(profile.test_best)
	return words


## [param seconds] as minutes and seconds, 3:07.
static func clock(seconds: float) -> String:
	var whole := roundi(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


func _on_stamped() -> void:
	card.stamp()
	_shake()
	stamped.emit()
	# Street Legal, and Honor Roll with every endorsement, the moment the stamp comes down,
	# GAME.md 8.10.
	Achievements.arrive(Game.settings.profile)
	var license_done := create_tween()
	license_done.tween_interval(TICK_AFTER)
	license_done.tween_callback(SchoolEnrollment.tick.bind(course, 2))
	var settle := create_tween()
	settle.tween_interval(SETTLE)
	settle.tween_callback(_look_closer)


## Stamped, the license is held up in full over the screen, GAME.md 9.4a, growing up off the card on
## the desk and going back down onto it the way the title and the settings show it, to look at what
## was earned; put away, the plate and the ways on come up in the card's place, once it has settled
## back so the card is not pulled from under it, see [constant LicenseView.FLY_BACK].
func _look_closer() -> void:
	if view != null:
		return
	view = LicenseView.open(self, Game.last_input_keyboard, card)
	view.put_away.connect(
		func() -> void:
			view = null
			var settle := create_tween()
			settle.tween_interval(LicenseView.FLY_BACK)
			settle.tween_callback(_offer_the_ways)
	)
	if shows_back:
		shows_back = false
		_show_the_back()


## Held up, the first license turns over by itself after a beat, holds its back a moment so the
## scratches in its stripe are seen, and turns back, STORY.md 6.7; a card the player has turned
## themselves is left as they left it.
func _show_the_back() -> void:
	var turns := create_tween()
	turns.tween_interval(BACK_AFTER)
	turns.tween_callback(
		func() -> void:
			if view != null and is_instance_valid(view) and not view.card.flipped:
				view.stand.turn_over()
	)
	turns.tween_interval(BACK_HOLD)
	turns.tween_callback(
		func() -> void:
			if view != null and is_instance_valid(view) and view.card.flipped:
				view.stand.turn_over()
	)


## The card takes the blow: a shiver sideways and a little jump.
func _shake() -> void:
	var home := card.position
	var shake := create_tween()
	for i: int in SHAKES:
		var way := SHAKE * (1.0 - float(i) / float(SHAKES)) * (1.0 if i % 2 == 0 else -1.0)
		shake.tween_property(card, "position:x", home.x + way, 0.04)
	shake.tween_property(card, "position:x", home.x, 0.04)
	var jump := create_tween()
	jump.tween_property(card, "scale", Vector2.ONE * 1.03, 0.06)
	jump.tween_property(card, "scale", Vector2.ONE, 0.16)


## The pane drawn smaller when the screen is smaller than it, about its middle, so all of it is
## always on the screen: a phone held sideways, or a big UI scale, GAME.md 8.5.
func _fit() -> void:
	if _pane == null:
		return
	var room := size - Vector2(MARGIN, MARGIN) * 2.0
	var needed := _pane.get_combined_minimum_size()
	if needed.x <= 0.0 or needed.y <= 0.0 or room.x <= 0.0 or room.y <= 0.0:
		return
	var shrink := minf(1.0, minf(room.x / needed.x, room.y / needed.y))
	_pane.pivot_offset = needed * 0.5
	_pane.scale = Vector2.ONE * shrink


## The congratulations and the ways on come up in the card's place, and the road has the cursor.
func _offer_the_ways() -> void:
	_card_page.visible = false
	_foot.visible = true
	_foot.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(_foot, "modulate:a", 1.0, 0.3)
	buttons[&"play"].grab_focus()
	Audio.play_sfx(&"ready", -6.0, 0.0)


## Whether the ways on are up, which they are only once the card is stamped.
func offering() -> bool:
	return _foot.visible


func _choose(way: StringName) -> void:
	Game.settings.save_to_disk()
	chosen.emit(way)
	if ways.has(way) and (ways[way] as Callable).is_valid():
		(ways[way] as Callable).call()
