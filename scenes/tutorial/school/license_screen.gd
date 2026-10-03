class_name LicenseScreen
extends Control
## The end of the driving test, GAME.md 9.4a, up over the room a moment after the final exam is
## passed, on the pane the podium is cut from with the player's color along its top: YOU PASSED,
## a word from the examiner, the license itself, see [LicenseCard], with the rubber stamp hanging
## over its corner, see [RubberStamp], and a line saying to press it. Stamped, the card takes its
## mark and shakes, and the ways on come up under it with the plate for the back of the kart to
## choose: the Garage, the road, which is Play, and the title. Nothing leaves this screen without
## stamping: the stamp is the point.

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
## The room over and under the card on the desk.
const PAD := 22.0
## The plate to choose, under the congratulations: the label, and the line under the box.
const PLATE_LABEL := "Your license plate"
const PLATE_LINE := "Up to %d letters, digits, spaces and dashes, on the back of your kart."
const PLATE_AIR := 8.0
const SHAKES := 5
const SHAKE := 7.0

var card: LicenseCard
var stamp: RubberStamp
## The plate, typed into where it is, see [PlateField].
var plate_field: PlateField
## The course along the top, see [method SchoolEnrollment.course_row].
var course: HBoxContainer
## What each way on does: the scenes, unless a test says otherwise.
var ways: Dictionary[StringName, Callable] = {}
var buttons: Dictionary[StringName, Button] = {}

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
	# Taller than a phone's screen at a big UI scale, GAME.md 8.5, the pane scrolls, following the
	# cursor down to the ways on; it sits in the middle of the screen when it fits.
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var pane := MenuTheme.pane(_edge)
	center.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.custom_minimum_size = Vector2(LicenseCard.SIZE.x + STAMP_ROOM * 2.0, 0.0)
	pane.add_child(column)
	column.add_child(MenuTheme.title(TITLE, Type.TITLE))
	column.add_child(MenuTheme.subtitle(LINE, Type.BODY))
	# The course, its theory done; the driving test ticks as the pane comes up, and the license
	# as the stamp comes down.
	course = SchoolEnrollment.course_row(1)
	column.add_child(course)
	var test_done := create_tween()
	test_done.tween_interval(RISE + TICK_AFTER)
	test_done.tween_callback(SchoolEnrollment.tick.bind(course, 1))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap)
	_desk = Control.new()
	_desk.name = "Desk"
	_desk.custom_minimum_size = LicenseCard.SIZE + Vector2(0.0, PAD * 2.0)
	_desk.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_desk)
	card.position = Vector2(0.0, PAD)
	_desk.add_child(card)
	stamp = RubberStamp.create()
	stamp.position = STAMP_HANGS + Vector2(0.0, PAD)
	stamp.lands_at = STAMP_LANDS + Vector2(0.0, PAD)
	stamp.stamped.connect(_on_stamped)
	stamp.device_changed.connect(_say_how)
	_desk.add_child(stamp)
	_hint = MenuTheme.subtitle("", Type.BODY)
	column.add_child(_hint)
	_say_how()
	_foot = VBoxContainer.new()
	_foot.name = "Ways"
	_foot.add_theme_constant_override("separation", 10)
	_foot.add_child(MenuTheme.title(DONE_TITLE % card.holder_name, Type.HEADING))
	_foot.add_child(MenuTheme.subtitle(DONE_LINE, Type.BODY))
	_foot.add_child(_plate_row())
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
	column.add_child(_foot)
	modulate.a = 0.0
	var rise := create_tween()
	rise.tween_property(self, "modulate:a", 1.0, RISE)
	stamp.grab_focus()


## How the stamp is pressed, under the card, for the device in hand.
func _say_how() -> void:
	_hint.text = STAMP_LINE % stamp.press_word()


## The plate for the back of the kart, GAME.md 4.4: a box to type it into, starting from the one
## the settings suggest, with the plate as it will read beside it, kept as it is typed.
func _plate_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	plate_field = PlateField.make(Game.settings.license_plate)
	plate_field.plate_changed.connect(_on_plate_typed)
	var row := MenuTheme.row(PLATE_LABEL, plate_field)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var how := PlateField.hint(Color(0.72, 0.72, 0.78), Type.LABEL)
	how.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(how)
	box.add_child(row)
	box.add_child(MenuTheme.subtitle(PLATE_LINE % LicensePlate.MOST, Type.LABEL))
	# Air under the line, before the ways on.
	var air := Control.new()
	air.custom_minimum_size = Vector2(0.0, PLATE_AIR)
	box.add_child(air)
	return box


func _on_plate_typed(cleaned: String) -> void:
	Game.settings.license_plate = cleaned


func _on_stamped() -> void:
	card.stamp()
	_shake()
	stamped.emit()
	var license_done := create_tween()
	license_done.tween_interval(TICK_AFTER)
	license_done.tween_callback(SchoolEnrollment.tick.bind(course, 2))
	var settle := create_tween()
	settle.tween_interval(SETTLE)
	settle.tween_callback(_offer_the_ways)


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


## The ways on come up under the card, and the road has the cursor.
func _offer_the_ways() -> void:
	_hint.visible = false
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
	# The plate as it was left, kept.
	Game.settings.save_to_disk()
	chosen.emit(way)
	if ways.has(way) and (ways[way] as Callable).is_valid():
		(ways[way] as Callable).call()
