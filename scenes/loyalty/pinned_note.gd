class_name PinnedNote
extends Control
## What the player has pinned in the loyalty program, GAME.md 8.9, on a scrap torn off the map's
## paper and pinned under the pause menu's pane, apart from it: its name, its bet and how far it has
## come, along a little road that fills in gold. It goes where the pane goes as it is dealt and put
## away; beside it where the screen has no room under it, and not there at all with room for
## neither, or with nothing pinned. In a match it says what the strip under the clock counts, live,
## see [PinnedStrip], whether the strip is shown or, on a phone, left off the arena. A click or a
## tap on it opens the program at what is pinned, lifting it a little under the mouse to say so;
## and a pad's cursor reaches it down from the pane's last button, see [member above], lifting it
## and marking it as a button is marked, and accept opens the program as a click does.

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
## The green a bet met in the map is counted in, with a tick before it, until the map is written
## down and it is won, GAME.md 8.9.
const WON_INK := Color(0.16, 0.5, 0.24)
const CASING := Color(0.3, 0.28, 0.27)
## How deep the bites of its torn right edge go, and how many there are.
const TORN := 7.0
const BITES := 9
const SHADOW_BY := Vector2(4.0, 6.0)

## The pane it hangs under, and the pane's last button, which the cursor comes down to it from
## while it is shown.
var pane: Control
var above: Control
## What it says: what is pinned and how far it has come, its bet, and its road's share.
var words: Array[String] = []
var bet := ""
var share := 0.0
## Whether what is pinned has been met in the map, see [member PinnedStrip.won].
var won := false

var _since := 0.0


func _init(under: Control) -> void:
	pane = under
	name = "PinnedNote"
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	size = SIZE
	pivot_offset = SIZE * 0.5
	rotation = TURN


## A button to a screen reader, named for what it says, see [method look].
func _notification(what: int) -> void:
	ScreenReader.drawn(self, what)


func _ready() -> void:
	mouse_entered.connect(_lift.bind(LIFT))
	mouse_exited.connect(_lift.bind(1.0))
	focus_entered.connect(
		func() -> void:
			_lift(LIFT)
			queue_redraw()
	)
	focus_exited.connect(
		func() -> void:
			_lift(1.0)
			queue_redraw()
	)
	look()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	var left := button != null and button.button_index == MOUSE_BUTTON_LEFT
	var accepted := event.is_action_pressed(&"ui_accept") and not event.is_echo()
	if (left and button.pressed) or (touch != null and touch.pressed) or accepted:
		accept_event()
		opened.emit(Loyalty.pinned_of(Game.settings.profile))


func _lift(to: float) -> void:
	var lift := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	lift.tween_property(self, "scale", Vector2.ONE * to, LIFT_TIME)


func _process(delta: float) -> void:
	# Nothing to say while the pane is away, and said again the moment it is up.
	if pane == null or not pane.is_visible_in_tree():
		visible = false
		_link(false)
		_since = EVERY
		return
	_since += delta
	if _since >= EVERY:
		_since = 0.0
		look()
	_follow()


## Looks again at what is pinned: the strip's live words where a match has one counting what is
## pinned now, shown or not, or the profile's.
func look() -> void:
	var profile := Game.settings.profile
	var said: Array = [words, share, bet, won]
	var strip := get_tree().get_first_node_in_group(STRIPS) as Control
	var live: Array[String] = []
	if (
		strip != null
		and strip.get(&"counting")
		and strip.get(&"pinned") == Loyalty.pinned_of(profile)
	):
		live.assign(strip.get(&"words"))
	won = false
	if not live.is_empty():
		words = live
		share = float(strip.get(&"share"))
		won = bool(strip.get(&"won"))
	else:
		words = Loyalty.pinned_words(profile)
		var come := Loyalty.pinned_progress(profile)
		share = clampf(come.x / come.y, 0.0, 1.0) if come.y > 0.0 else 0.0
	bet = Loyalty.pinned_bet(profile)
	_follow()
	if said != [words, share, bet, won]:
		queue_redraw()
		ScreenReader.name(self, ScreenReader.line(words), bet)


## Under the pane, or beside it, as it is now; its own look as the pane's.
func _follow() -> void:
	var room := get_viewport_rect().size
	var shown := pane != null and pane.is_visible_in_tree() and words.size() >= 2
	if not shown:
		visible = false
		_link(false)
		return
	var rect := pane.get_global_rect()
	var at := Vector2(rect.get_center().x - SIZE.x * 0.5, rect.end.y + GAP)
	if at.y + SIZE.y > room.y - EDGE:
		at = Vector2(rect.end.x + GAP, rect.end.y - SIZE.y - GAP)
		shown = at.x + SIZE.x <= room.x - EDGE
	visible = shown
	global_position = at
	modulate.a = pane.modulate.a
	_link(shown)


## The cursor's way down to it from [member above] while it is [param shown], and back up; and none
## while it is not, the button keeping the cursor in the pane, as the drive switches leave it, see
## [DriveSwitches]. Left, right and down from it go nowhere.
func _link(shown: bool) -> void:
	if above == null or not is_instance_valid(above):
		return
	above.focus_neighbor_bottom = above.get_path_to(self if shown else above)
	if not shown and has_focus():
		above.grab_focus()
	var here := get_path_to(self)
	focus_neighbor_top = get_path_to(above)
	focus_neighbor_left = here
	focus_neighbor_right = here
	focus_neighbor_bottom = here


func _draw() -> void:
	draw_scrap(self, Rect2(Vector2.ZERO, SIZE))
	if has_focus():
		FocusMark.draw_on(self, Rect2(Vector2.ZERO, SIZE), 4.0, SIDE_LEFT)
	var left := 40.0
	var wide := SIZE.x - left - TORN - 14.0
	if words.size() < 2:
		return
	draw_string(
		Type.STRONG, Vector2(left, 22.0), MARK, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, QUIET_INK
	)
	draw_count(self, left + wide, 22.0, words[1], 15, won)
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
	var from := Vector2(left, SIZE.y - 12.0)
	draw_road(self, from, from + Vector2(wide, 0.0), share)
	LoyaltyArt.draw_pin(self, Vector2(18.0, 28.0), 36.0)


## How far a pin has come, [param said], written on [param on] in [param size] to end at
## [param right] on the line [param base]: in gold, or once its bet is met in the map in green with
## a tick before it. Gives back where it starts, tick and all.
static func draw_count(
	on: CanvasItem, right: float, base: float, said: String, size: int, won: bool
) -> float:
	var said_wide := Type.STRONG.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var left := right - said_wide
	on.draw_string(
		Type.STRONG,
		Vector2(left, base),
		said,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		WON_INK if won else GOLD_INK
	)
	if not won:
		return left
	var tall := float(size) * 0.7
	var tick := Vector2(left - tall * 1.25, base - tall * 0.5)
	(
		on
		. draw_polyline(
			PackedVector2Array(
				[
					tick + Vector2(0.0, tall * 0.05),
					tick + Vector2(tall * 0.35, tall * 0.45),
					tick + Vector2(tall * 0.95, -tall * 0.5),
				]
			),
			WON_INK,
			maxf(float(size) * 0.16, 2.0),
			true
		)
	)
	return tick.x


## A scrap of the map's paper on [param on] over [param rect], its shadow under it: straight where
## it was cut, and torn down its right side, or along its foot where [param torn_foot].
static func draw_scrap(on: CanvasItem, rect: Rect2, torn_foot := false) -> void:
	var outline := PackedVector2Array([rect.position])
	if torn_foot:
		outline.append(Vector2(rect.end.x, rect.position.y))
		var bites := maxi(roundi(rect.size.x / 26.0), 4)
		for i: int in bites + 1:
			var across := rect.end.x - rect.size.x * float(i) / bites
			outline.append(Vector2(across, rect.end.y - _bite(i)))
	else:
		for i: int in BITES + 1:
			var down := rect.position.y + rect.size.y * float(i) / BITES
			outline.append(Vector2(rect.end.x - _bite(i), down))
		outline.append(Vector2(rect.position.x, rect.end.y))
	var shadow := outline.duplicate()
	for i: int in shadow.size():
		shadow[i] += SHADOW_BY
	on.draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.35))
	on.draw_colored_polygon(outline, HouseTheme.PAPER)


## How deep the [param i]th bite of a torn edge goes.
static func _bite(i: int) -> float:
	return TORN * (0.35 + 0.65 * absf(sin(float(i) * 2.3 + 0.7)))


## How far a pinned bet has come, on [param on]: a stretch of the map's road from [param from] to
## [param to], [param wide] across, gold as far as [param share], its middle line dashed along it.
static func draw_road(
	on: CanvasItem, from: Vector2, to: Vector2, share: float, wide := 6.0
) -> void:
	on.draw_line(from, to, CASING, wide + 3.0, true)
	on.draw_line(from, to, LoyaltyMapArt.ROAD_SHUT, wide, true)
	if share > 0.0:
		on.draw_line(from, from.lerp(to, share), LoyaltyMapArt.ROAD_FILL, wide, true)
	var dash := from + Vector2(4.0, 0.0)
	while dash.x + 7.0 < to.x:
		on.draw_line(dash, dash + Vector2(7.0, 0.0), LoyaltyMapArt.CENTER, 1.2)
		dash.x += 13.0
