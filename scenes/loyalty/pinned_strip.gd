class_name PinnedStrip
extends Control
## What the player has pinned in the loyalty program, GAME.md 8.9, on a slim scrap of the map's
## paper hung by a match's clock, as the pause menu's note is (see [PinnedNote]): a pin, its name
## and how far it has come, counted live as the map is played, along a little road that fills in
## gold. Shown with one player at the screen and only while there is something pinned still to be
## had: gone once its bet is won. Always beside the clock, off the right of it and off the arena,
## past Kit's scrap that hangs there (see [NoteMark]) and short of the feed in the corner, hung from
## the screen's top as the clock is, its paper running on past the edge and torn along its foot;
## shrunk to the room there is for it and hidden where there is too little, never under the clock
## over the arena; and not at all while the payout slip is up, see [ResultsScreen], counting all the
## same. A
## click on it pauses the match as Escape does and opens the program over the room's menu at what is
## pinned, see [method open_program]; under the mouse it lifts a little to say so, as the pause
## menu's note does.

## Every strip up is in this group, for the pause menu's note to say what it says, see [PinnedNote].
const GROUP := &"pinned_strip"
## How often it looks again at what is pinned and how far it has come.
const EVERY := 0.4
## It hangs beside the clock, off the right of it, GAME.md 8.9: how wide it is at the most, the
## least it shrinks to before it is hidden instead, how far past the clock's side it starts with
## room for Kit's scrap left between them, and how far its paper runs on up past the screen's top.
const BESIDE_SIZE := Vector2(340.0, 54.0)
const LEAST_WIDE := 170.0
const BESIDE_GAP := NoteMark.GAP * 2.0 + NoteMark.SIZE.x + 6.0
const ABOVE := 12.0
## How much of the screen's right edge is kept clear of it, for the feed in the corner, [KillFeed].
const FEED_ROOM := 420.0

var match_node: Match
## What it says: the name of what is pinned and how far it has come, and its bar's share; and
## what is pinned that it says it of.
var words: Array[String] = []
var share := 0.0
var pinned := &""
## Whether it is counting what is pinned this map, shown or not: the pause menu's note says what it
## counts even where there is no room for the strip itself, see [PinnedNote].
var counting := false
## Whether what is pinned has been met in this map: its count in green with a tick, until the map
## is written down and it is won, and gone.
var won := false

var _since := EVERY
## The payout slip, which it is not shown over.
var _slip: Control
## Whether it hangs from the screen's top, beside the clock.
var _hung := false


## The strip under [param in_match]'s clock, if it has a HUD.
static func add_to(in_match: Match) -> PinnedStrip:
	if in_match == null or in_match.hud == null:
		return null
	var strip := PinnedStrip.new()
	strip.name = "PinnedStrip"
	strip.match_node = in_match
	in_match.hud.add_child(strip)
	return strip


func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_lift.bind(PinnedNote.LIFT))
	mouse_exited.connect(_lift.bind(1.0))
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	_place()
	if match_node != null and match_node.hud != null:
		_slip = match_node.hud.get_node_or_null("Results") as Control
	visible = false


func _place() -> void:
	var at := placed(get_viewport_rect().size.x)
	_hung = true
	offset_left = at.position.x
	offset_right = at.end.x
	offset_top = at.position.y
	offset_bottom = at.end.y
	# Lifted from where it hangs: the screen's top beside the clock.
	pivot_offset = Vector2(at.size.x * 0.5, 0.0)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		accept_event()
		open_program()


## The program open at what is pinned over the room's menu, the menu put up first, which pauses
## the match as Escape does, GAME.md 3.8, and online asks the room to; put away, the menu is left
## up, to resume from.
func open_program() -> void:
	var menu := get_tree().get_first_node_in_group(PauseMenu.GROUP) as PauseMenu
	if menu == null or pinned == &"":
		return
	if not menu.is_open():
		menu.set_paused(true)
	menu.open_loyalty(pinned)


func _lift(to: float) -> void:
	var lift := create_tween()
	lift.tween_property(self, "scale", Vector2.ONE * to, PinnedNote.LIFT_TIME)


## Where it hangs beside the clock, off the right of it, on a screen [param wide], GAME.md 8.9: from
## the screen's top, as wide as it fits between Kit's scrap past the clock and the room kept for the
## feed, up to [constant BESIDE_SIZE]; never under the clock, shrunk to fit and, by [method
## room_for_it], hidden where even [constant LEAST_WIDE] will not.
static func placed(wide: float) -> Rect2:
	var start := ClockBoard.TOP * 0.5 + BESIDE_GAP
	var room := wide * 0.5 - FEED_ROOM - start
	return Rect2(
		Vector2(start, 0.0), Vector2(clampf(room, LEAST_WIDE, BESIDE_SIZE.x), BESIDE_SIZE.y)
	)


func _process(delta: float) -> void:
	# Gone the frame the slip comes up, rather than at the next look.
	if visible and _slip_up():
		visible = false
	_since += delta
	if _since < EVERY:
		return
	_since = 0.0
	look()


## Whether the payout slip is up, which it is not shown over.
func _slip_up() -> bool:
	return _slip != null and is_instance_valid(_slip) and _slip.visible


## Looks again at what is pinned and how far it has come, and whether it is to be shown at all.
func look() -> void:
	if match_node == null:
		return
	var here := _the_one_here()
	var profile := MatchRecord.profile_of(here) if here != null else null
	if profile == null:
		counting = false
		visible = false
		return
	var since := MatchRecord.since_of(match_node, here)
	var said: Array = [words, share, pinned, visible, won]
	pinned = Loyalty.pinned_of(profile)
	words = Loyalty.pinned_words(profile, here, since)
	counting = not words.is_empty()
	if not counting:
		visible = false
		return
	var come := Loyalty.pinned_progress(profile, here, since)
	share = come.x / come.y if come.y > 0.0 else 0.0
	var landmark := Loyalty.map().landmark(pinned)
	won = (
		(come.y > 0.0 and come.x >= come.y)
		or (landmark != null and Loyalty.is_met_live(profile, landmark, here, since))
	)
	# Counted all the same where there is no room for it, for the pause menu's note to say.
	visible = room_for_it(get_viewport_rect().size.x) and not _slip_up()
	if visible:
		_place()
	if said != [words, share, pinned, visible, won]:
		queue_redraw()


## Whether a screen [param wide] has room for it beside the clock, GAME.md 8.9: at least [constant
## LEAST_WIDE] between Kit's scrap past the clock and the room kept for the feed, off the arena
## whatever the screen.
static func room_for_it(wide: float) -> bool:
	return wide * 0.5 - FEED_ROOM - (ClockBoard.TOP * 0.5 + BESIDE_GAP) >= LEAST_WIDE


## The one player at this screen, or none where there are more or nobody.
func _the_one_here() -> PlayerSlot:
	var found: PlayerSlot = null
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human():
			if found != null:
				return null
			found = slot
	return found


func _draw() -> void:
	draw_strip(self, size, words, share, won, ABOVE if _hung else 0.0)


## The strip drawn on [param on], [param size] big, saying [param said], its name and its count,
## along a road [param share] gold, [param met] in the map; its paper running on [param above] past
## its top, hung from the screen's. The House's first look draws a picture of it too, see
## [PinPicture].
static func draw_strip(
	on: CanvasItem, size: Vector2, said: Array[String], share: float, met: bool, above := 0.0
) -> void:
	var paper := Rect2(Vector2(0.0, -above), size + Vector2(0.0, above))
	PinnedNote.draw_scrap(on, paper, true)
	var left := 38.0
	var wide := size.x - left - 14.0
	if said.size() >= 2:
		var count := Type.LABEL - 1
		var starts := PinnedNote.draw_count(on, left + wide, 24.0, said[1], count, met)
		on.draw_string(
			Type.display_font(),
			Vector2(left, 25.0),
			said[0],
			HORIZONTAL_ALIGNMENT_LEFT,
			starts - left - 10.0,
			Type.LABEL + 3,
			PinnedNote.INK
		)
	PinnedNote.draw_road(on, Vector2(left, 37.0), Vector2(left + wide, 37.0), share, 5.0)
	LoyaltyArt.draw_pin(on, Vector2(17.0, 32.0), 30.0)
