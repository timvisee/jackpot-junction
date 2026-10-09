class_name PinnedNote
extends Control
## What the player has pinned in the loyalty program, GAME.md 8.9, on a scrap torn off the map's
## paper and pinned under the pause menu's pane, apart from it: its name, its bet and how far it
## has come, along a little road that fills in gold. It goes where the pane goes as it is dealt
## and put away; beside it where the screen has no room under it, and not there at all with room
## for neither, or with nothing pinned. In a match it says what the strip under the clock does,
## counted live, see [PinnedStrip]. A click or a tap on it opens the program at what is pinned,
## lifting it a little under the mouse to say so.

## Clicked or tapped: the program, open at [param id], what is pinned.
signal opened(id: StringName)

const SIZE := Vector2(330.0, 92.0)
## The strips' group, see [constant PinnedStrip.GROUP]: named here rather than through the strip,
## which would bring the whole match in with the pause menu, and the match the pause menu.
const STRIPS := &"pinned_strip"
const GAP := 16.0
const EDGE := 8.0
const TURN := -0.018
const EVERY := 0.5
## How much bigger it is under the mouse, and how quickly it gets there.
const LIFT := 1.04
const LIFT_TIME := 0.12
const MARK := "PINNED"
const INK := Color(0.15, 0.13, 0.14)
const QUIET_INK := Color(0.15, 0.13, 0.14, 0.62)
const GOLD_INK := Color(0.6, 0.41, 0.07)
const CASING := Color(0.3, 0.28, 0.27)
## How deep the bites of its torn right edge go, and how many there are.
const TORN := 7.0
const BITES := 9

## The pane it hangs under.
var pane: Control
## What it says: what is pinned and how far it has come, its bet, and its road's share.
var words: Array[String] = []
var bet := ""
var share := 0.0

var _since := 0.0


func _init(under: Control) -> void:
	pane = under
	name = "PinnedNote"
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size = SIZE
	pivot_offset = SIZE * 0.5
	rotation = TURN


func _ready() -> void:
	mouse_entered.connect(_lift.bind(LIFT))
	mouse_exited.connect(_lift.bind(1.0))
	look()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	var left := button != null and button.button_index == MOUSE_BUTTON_LEFT
	if (left and button.pressed) or (touch != null and touch.pressed):
		accept_event()
		opened.emit(Loyalty.pinned_of(Game.settings.profile))


func _lift(to: float) -> void:
	var lift := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	lift.tween_property(self, "scale", Vector2.ONE * to, LIFT_TIME)


func _process(delta: float) -> void:
	_since += delta
	if _since >= EVERY:
		_since = 0.0
		look()
	_follow()


## Looks again at what is pinned: the strip's live words where a match has one up saying what is
## pinned now, or the profile's.
func look() -> void:
	var profile := Game.settings.profile
	var strip := get_tree().get_first_node_in_group(STRIPS) as Control
	var live: Array[String] = []
	if strip != null and strip.visible and strip.get(&"pinned") == Loyalty.pinned_of(profile):
		live.assign(strip.get(&"words"))
	if not live.is_empty():
		words = live
		share = float(strip.get(&"share"))
	else:
		words = Loyalty.pinned_words(profile)
		var come := Loyalty.pinned_progress(profile)
		share = clampf(come.x / come.y, 0.0, 1.0) if come.y > 0.0 else 0.0
	bet = Loyalty.pinned_bet(profile)
	_follow()
	queue_redraw()


## Under the pane, or beside it, as it is now; its own look as the pane's.
func _follow() -> void:
	var room := get_viewport_rect().size
	var shown := pane != null and pane.is_visible_in_tree() and words.size() >= 2
	if not shown:
		visible = false
		return
	var rect := pane.get_global_rect()
	var at := Vector2(rect.get_center().x - SIZE.x * 0.5, rect.end.y + GAP)
	if at.y + SIZE.y > room.y - EDGE:
		at = Vector2(rect.end.x + GAP, rect.end.y - SIZE.y - GAP)
		shown = at.x + SIZE.x <= room.x - EDGE
	visible = shown
	global_position = at
	modulate.a = pane.modulate.a


func _draw() -> void:
	# The scrap: straight where it was cut, torn down its right side.
	var outline := PackedVector2Array([Vector2.ZERO])
	for i: int in BITES + 1:
		var down := SIZE.y * float(i) / BITES
		var bite := TORN * (0.35 + 0.65 * absf(sin(float(i) * 2.3 + 0.7)))
		outline.append(Vector2(SIZE.x - bite, down))
	outline.append(Vector2(0.0, SIZE.y))
	var shadow := outline.duplicate()
	for i: int in shadow.size():
		shadow[i] += Vector2(4.0, 6.0)
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.35))
	draw_colored_polygon(outline, HouseTheme.PAPER)
	var left := 40.0
	var wide := SIZE.x - left - TORN - 14.0
	if words.size() < 2:
		return
	var said_wide := Type.STRONG.get_string_size(words[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(
		Type.STRONG, Vector2(left, 22.0), MARK, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, QUIET_INK
	)
	draw_string(
		Type.STRONG,
		Vector2(left + wide - said_wide, 22.0),
		words[1],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		15,
		GOLD_INK
	)
	draw_string(
		Type.display_font(),
		Vector2(left, 47.0),
		words[0],
		HORIZONTAL_ALIGNMENT_LEFT,
		wide,
		Type.LARGE - 6,
		INK
	)
	draw_string(Type.TEXT, Vector2(left, 67.0), bet, HORIZONTAL_ALIGNMENT_LEFT, wide, 14, QUIET_INK)
	# How far it has come: a stretch of the map's road, gold as far as that.
	var from := Vector2(left, SIZE.y - 12.0)
	var to := from + Vector2(wide, 0.0)
	draw_line(from, to, CASING, 9.0, true)
	draw_line(from, to, LoyaltyMapArt.ROAD_SHUT, 6.0, true)
	if share > 0.0:
		draw_line(from, from.lerp(to, share), LoyaltyMapArt.ROAD_FILL, 6.0, true)
	# Its middle line, dashed along it.
	var dash := from + Vector2(4.0, 0.0)
	while dash.x + 7.0 < to.x:
		draw_line(dash, dash + Vector2(7.0, 0.0), LoyaltyMapArt.CENTER, 1.2)
		dash.x += 13.0
	LoyaltyArt.draw_pin(self, Vector2(18.0, 28.0), 36.0)
