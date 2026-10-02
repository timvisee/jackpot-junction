class_name LicenseScreen
extends Control
## The end of the driving test, GAME.md 9.4a, up over the room a moment after the final exam is
## passed, on the pane the podium is cut from with the player's color along its top: YOU PASSED,
## a word from the examiner, the license itself, see [LicenseCard], with the rubber stamp hanging
## over its corner, see [RubberStamp], and a line saying to press it. Stamped, the card takes its
## mark and shakes, and the ways on come up under it: the Garage, the road, which is Play, and
## the title. Nothing leaves this screen without stamping: the stamp is the point.

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
## Where the stamp hangs, off the right edge of the card so it hides nothing on it, and where it
## lands, its top left in the card's space with its base over the mark it leaves; and the room
## kept either side of the card for it to hang in.
const STAMP_FOOT := 134.0
const STAMP_HANGS := Vector2(LicenseCard.SIZE.x - 70.0, LicenseCard.STAMP_AT.y - STAMP_FOOT)
const STAMP_LANDS := Vector2(
	LicenseCard.STAMP_AT.x - RubberStamp.SIZE.x * 0.5, LicenseCard.STAMP_AT.y - STAMP_FOOT
)
const STAMP_ROOM := 84.0
const SHAKES := 5
const SHAKE := 7.0

var card: LicenseCard
var stamp: RubberStamp
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
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var pane := MenuTheme.pane(_edge)
	center.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.custom_minimum_size = Vector2(LicenseCard.SIZE.x + STAMP_ROOM * 2.0, 0.0)
	pane.add_child(column)
	column.add_child(MenuTheme.title(TITLE, Type.TITLE))
	column.add_child(MenuTheme.subtitle(LINE, Type.BODY))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap)
	_desk = Control.new()
	_desk.name = "Desk"
	_desk.custom_minimum_size = LicenseCard.SIZE
	_desk.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_desk)
	_desk.add_child(card)
	stamp = RubberStamp.create()
	stamp.position = STAMP_HANGS
	stamp.lands_at = STAMP_LANDS
	stamp.stamped.connect(_on_stamped)
	_desk.add_child(stamp)
	var press := "Tap" if TouchInput.enabled else "Click"
	_hint = MenuTheme.subtitle(STAMP_LINE % press, Type.BODY)
	column.add_child(_hint)
	_foot = VBoxContainer.new()
	_foot.name = "Ways"
	_foot.add_theme_constant_override("separation", 10)
	_foot.add_child(MenuTheme.title(DONE_TITLE % card.holder_name, Type.HEADING))
	_foot.add_child(MenuTheme.subtitle(DONE_LINE, Type.BODY))
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


func _on_stamped() -> void:
	card.stamp()
	_shake()
	stamped.emit()
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
	chosen.emit(way)
	if ways.has(way) and (ways[way] as Callable).is_valid():
		(ways[way] as Callable).call()
