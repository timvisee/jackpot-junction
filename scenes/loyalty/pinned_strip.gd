class_name PinnedStrip
extends Control
## What the player has pinned in the loyalty program, GAME.md 8.9, on a slim strip hung under a
## match's clock: a pin, its name and how far it has come, counted live as the map is played, with
## a thin bar along its foot. Only where there is room for it, a wide screen with one player at it,
## and only while there is something pinned still to be had: gone once its bet is won. Under the
## Royal Flush's tally while that is up, see [FlushTally].

## How big it is, how far under the clock it hangs, and how much further while the flush's tally is
## up; how wide the screen has to be for it, and how often it looks again.
const SIZE := Vector2(400.0, 32.0)
## Every strip up is in this group, for the pause menu's note to say what it says, see [PinnedNote].
const GROUP := &"pinned_strip"
const GAP := 8.0
const UNDER_TALLY := 46.0
const WIDE_ENOUGH := 1500.0
const EVERY := 0.4
const BOARD := Color(0.07, 0.07, 0.09, 0.88)

var match_node: Match
## What it says: the name of what is pinned and how far it has come, and its bar's share.
var words: Array[String] = []
var share := 0.0

var _since := EVERY
var _tally: Control


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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	_place(0.0)
	if match_node != null and match_node.hud != null:
		_tally = match_node.hud.get_node_or_null("FlushTally") as Control
	visible = false


func _place(lower: float) -> void:
	offset_left = -SIZE.x * 0.5
	offset_right = SIZE.x * 0.5
	offset_top = ClockBoard.TALL + GAP + lower
	offset_bottom = offset_top + SIZE.y


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
	words = Loyalty.pinned_words(profile, here, since)
	if words.is_empty():
		visible = false
		return
	var come := Loyalty.pinned_progress(profile, here, since)
	share = come.x / come.y if come.y > 0.0 else 0.0
	_place(UNDER_TALLY if _tally != null and _tally.visible else 0.0)
	visible = true
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
	var box := StyleBoxFlat.new()
	box.bg_color = BOARD
	box.set_corner_radius_all(7)
	box.set_border_width_all(1)
	box.border_color = Color(HouseTheme.FOIL, 0.55)
	draw_style_box(box, Rect2(Vector2.ZERO, SIZE))
	LoyaltyArt.draw_pin(self, Vector2(14.0, SIZE.y - 7.0), 20.0)
	if words.size() < 2:
		return
	var size_of := Type.LABEL
	var base := SIZE.y * 0.5 + Type.STRONG.get_ascent(size_of) * 0.36
	var right_wide := (
		Type.STRONG.get_string_size(words[1], HORIZONTAL_ALIGNMENT_LEFT, -1, size_of).x
	)
	draw_string(
		Type.STRONG,
		Vector2(30.0, base),
		words[0],
		HORIZONTAL_ALIGNMENT_LEFT,
		SIZE.x - right_wide - 52.0,
		size_of,
		HouseTheme.WORDS
	)
	draw_string(
		Type.STRONG,
		Vector2(SIZE.x - right_wide - 12.0, base),
		words[1],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size_of,
		HouseTheme.FOIL
	)
	var track := Rect2(Vector2(10.0, SIZE.y - 4.0), Vector2(SIZE.x - 20.0, 2.0))
	draw_rect(track, Color(HouseTheme.WORDS, 0.15))
	draw_rect(Rect2(track.position, Vector2(track.size.x * share, 2.0)), HouseTheme.FOIL)
