class_name PinnedStrip
extends Control
## What the player has pinned in the loyalty program, GAME.md 8.9, on a slim scrap of the map's
## paper hung by a match's clock, as the pause menu's note is (see [PinnedNote]): a pin, its name
## and how far it has come, counted live as the map is played, along a little road that fills in
## gold. Only where there is room for it, a wide screen with one player at it, and only while there
## is something pinned still to be had: gone once its bet is won. Beside the clock where the screen
## is wide enough, off the arena, past Kit's scrap that hangs there (see [NoteMark]) and short of
## the feed in the corner, hung from the screen's top as the clock is, its paper running on past the
## edge and torn along its foot; under the clock otherwise, and under the Royal Flush's tally while
## that is up, see [FlushTally]. A click on it pauses the match as Escape does and opens the program
## over the room's menu at what is pinned, see [method open_program]; under the mouse it lifts a
## little to say so, as the pause menu's note does.

## How big it is, how far under the clock it hangs, and how much further while the flush's tally is
## up; how wide the screen has to be for it, and how often it looks again.
const SIZE := Vector2(360.0, 54.0)
## Every strip up is in this group, for the pause menu's note to say what it says, see [PinnedNote].
const GROUP := &"pinned_strip"
const GAP := 8.0
const UNDER_TALLY := 46.0
const WIDE_ENOUGH := 1500.0
## How wide the screen has to be for it to hang beside the clock, how wide it is there, and how far
## from the clock's side, room for Kit's scrap left between them.
const BESIDE_WIDE := 1880.0
const BESIDE_SIZE := Vector2(340.0, 54.0)
## How far its paper runs on up past the screen's top, hung from it beside the clock.
const ABOVE := 12.0
const BESIDE_GAP := NoteMark.GAP * 2.0 + NoteMark.SIZE.x + 6.0
const EVERY := 0.4

var match_node: Match
## What it says: the name of what is pinned and how far it has come, and its bar's share; and
## what is pinned that it says it of.
var words: Array[String] = []
var share := 0.0
var pinned := &""

var _since := EVERY
var _tally: Control
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
	_place(0.0)
	if match_node != null and match_node.hud != null:
		_tally = match_node.hud.get_node_or_null("FlushTally") as Control
	visible = false


func _place(lower: float) -> void:
	var at := placed(get_viewport_rect().size.x, lower)
	_hung = at.position.y <= 0.0
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


## Where it hangs from the middle of the screen's top on a screen [param wide], [param lower] down
## further under the clock for the flush's tally: beside the clock, or under it.
static func placed(wide: float, lower: float) -> Rect2:
	if wide >= BESIDE_WIDE:
		return Rect2(Vector2(ClockBoard.TOP * 0.5 + BESIDE_GAP, 0.0), BESIDE_SIZE)
	return Rect2(Vector2(-SIZE.x * 0.5, ClockBoard.TALL + GAP + lower), SIZE)


func _process(delta: float) -> void:
	_since += delta
	if _since < EVERY:
		return
	_since = 0.0
	look()


## Looks again at what is pinned and how far it has come, and whether it is to be shown at all.
func look() -> void:
	if match_node == null:
		return
	var here := _the_one_here()
	var profile := MatchRecord.profile_of(here) if here != null else null
	if profile == null or get_viewport_rect().size.x < WIDE_ENOUGH:
		visible = false
		return
	var since := MatchRecord.since_of(match_node, here)
	var said: Array = [words, share, pinned, visible]
	pinned = Loyalty.pinned_of(profile)
	words = Loyalty.pinned_words(profile, here, since)
	if words.is_empty():
		visible = false
		return
	var come := Loyalty.pinned_progress(profile, here, since)
	share = come.x / come.y if come.y > 0.0 else 0.0
	_place(UNDER_TALLY if _tally != null and _tally.visible else 0.0)
	visible = true
	if said != [words, share, pinned, visible]:
		queue_redraw()


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
	var above := ABOVE if _hung else 0.0
	var paper := Rect2(Vector2(0.0, -above), size + Vector2(0.0, above))
	PinnedNote.draw_scrap(self, paper, true)
	var left := 38.0
	var wide := size.x - left - 14.0
	if words.size() >= 2:
		var count := Type.LABEL - 1
		var said_wide := (
			Type.STRONG.get_string_size(words[1], HORIZONTAL_ALIGNMENT_LEFT, -1, count).x
		)
		draw_string(
			Type.display_font(),
			Vector2(left, 25.0),
			words[0],
			HORIZONTAL_ALIGNMENT_LEFT,
			wide - said_wide - 10.0,
			Type.LABEL + 3,
			PinnedNote.INK
		)
		draw_string(
			Type.STRONG,
			Vector2(left + wide - said_wide, 24.0),
			words[1],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			count,
			PinnedNote.GOLD_INK
		)
	PinnedNote.draw_road(self, Vector2(left, 37.0), Vector2(left + wide, 37.0), share, 5.0)
	LoyaltyArt.draw_pin(self, Vector2(17.0, 32.0), 30.0)
