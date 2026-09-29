class_name FlushTally
extends Control
## How the Royal Flush pads stand, GAME.md 3.9 and 8.3, under the clock: each pad's own card suit,
## filled in its holder's color for every pad held and faint for every pad nobody holds, so a player
## chasing the flush can see which suits they have and which they still need without looking round
## the table for four frames. The players at this screen come first, then whoever else holds most,
## and the free suits last, so a player's own count is the run of suits on the left.
##
## Up only while somebody at this screen holds a pad, and only while the match is being played: a
## row of four outlines on every screen of every match, most of the time, is four more things on
## the screen that say nothing, and after the whistle the flush is not there to be had.
##
## And while a flush a player here scored is still paying out, see [member Match.flush_lock_slot]:
## the pads have cleared and wear nobody's color, but they are theirs for a while yet, so all four
## suits are, with a bar under them that empties as the payout runs out.
##
## And on every screen, whoever there holds what, while somebody else is one pad off the flush: a
## warning rather than a count, so that player's suits pulse and an exclamation mark in their
## color stands at the end of the row. The last pad is the one to go and take off them.

## How big a suit is, how far apart two are, how thick their outline, and what a free one is
## filled with.
const SUIT := 22.0
const GAP := 4.0
const OUTLINE := 1.6
const EMPTY := Color(1.0, 1.0, 1.0, 0.28)
const RIM := Color(0.0, 0.0, 0.0, 0.55)
## How far under the suits the bar of a flush still paying hangs, and how thick it is.
const LOCK_DROP := 5.0
const LOCK_BAR := 3.0
## The warning: how fast a threatening player's suits pulse, how much they swell at the top of
## it, and how big the exclamation mark is and how far past the suits it stands.
const PULSE := 7.0
const PULSE_GROW := 1.5
const MARK_SIZE := 22
const MARK_GAP := 8.0

var match_node: Match

## The colors of the held pads, in the order they are drawn, whose they are, how many pads there
## are, and the suit of each in the order drawn: the held ones, then the free ones.
var held: Array[Color] = []
var holders: Array[int] = []
var pads := 0
var suits: Array[int] = []
## A player not at this screen who holds all the pads but one, or -1.
var threat := -1
## How much of a flush this screen's player scored is still to pay, 0 when none is.
var locked := 0.0
var _beat := 0.0


static func add_to(hud: MatchHud, drop: float) -> FlushTally:
	var tally := FlushTally.new()
	tally.name = "FlushTally"
	tally.match_node = hud.match_node
	tally.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tally.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tally.offset_top = drop
	tally.visible = false
	hud.add_child(tally)
	return tally


func _process(delta: float) -> void:
	var was := held.duplicate()
	var were := suits.duplicate()
	var count := pads
	var had := locked
	_tally()
	var shown := _held_here() or locked > 0.0 or threat >= 0
	visible = match_node != null and match_node.is_running() and shown
	if threat >= 0:
		_beat += delta
		queue_redraw()
	if held != was or suits != were or pads != count or locked != had:
		var wide := _wide()
		custom_minimum_size = Vector2(wide, SUIT)
		offset_left = -wide * 0.5
		offset_right = wide * 0.5
		queue_redraw()


## Who holds what: this screen's players first, in their slot order, then everybody else by how
## many they hold, most first.
func _tally() -> void:
	held.clear()
	holders.clear()
	suits.clear()
	pads = 0
	locked = 0.0
	threat = -1
	if match_node == null or match_node.arena == null:
		return
	var winner := match_node.flush_lock_slot
	if match_node.flush_lock_left > 0.0 and winner >= 0 and _plays_here(winner):
		pads = match_node.arena.flush_pads.size()
		for i: int in pads:
			held.append(match_node.slots[winner].color())
			holders.append(winner)
			suits.append(i)
		var lasts := maxf(match_node.rules.flush_lock_seconds, 0.001)
		locked = clampf(match_node.flush_lock_left / lasts, 0.0, 1.0)
		return
	var by_slot: Dictionary[int, Array] = {}
	var free: Array[int] = []
	for pad: FlushPad in match_node.arena.flush_pads:
		pads += 1
		if pad.owner_slot >= 0 and not pad.is_disabled():
			if not by_slot.has(pad.owner_slot):
				by_slot[pad.owner_slot] = []
			by_slot[pad.owner_slot].append(pad)
		else:
			free.append(pad.index)
	var order: Array = by_slot.keys()
	order.sort_custom(
		func(a: int, b: int) -> bool:
			var here_a := _plays_here(a)
			var here_b := _plays_here(b)
			if here_a != here_b:
				return here_a
			if here_a:
				return a < b
			return (
				by_slot[a].size() > by_slot[b].size()
				or (by_slot[a].size() == by_slot[b].size() and a < b)
			)
	)
	for slot: int in order:
		for pad: FlushPad in by_slot[slot]:
			held.append(pad.owner_color)
			holders.append(slot)
			suits.append(pad.index)
		if pads > 1 and by_slot[slot].size() == pads - 1 and not _plays_here(slot):
			threat = slot
	suits.append_array(free)


## Whether a player at this screen holds a pad.
func _held_here() -> bool:
	if match_node == null or match_node.arena == null:
		return false
	for pad: FlushPad in match_node.arena.flush_pads:
		if pad.owner_slot >= 0 and not pad.is_disabled() and _plays_here(pad.owner_slot):
			return true
	return false


func _plays_here(slot: int) -> bool:
	return slot < match_node.slots.size() and match_node.slots[slot].is_local_human()


func _wide() -> float:
	return pads * SUIT + maxf(pads - 1, 0) * GAP


func _draw() -> void:
	var swell := (0.5 + 0.5 * sin(_beat * PULSE)) if threat >= 0 else 0.0
	for i: int in mini(pads, suits.size()):
		var box := Rect2(Vector2(i * (SUIT + GAP), 0.0), Vector2(SUIT, SUIT))
		if i >= held.size():
			SuitArt.draw_into(self, box, suits[i], EMPTY, OUTLINE)
			continue
		if holders[i] == threat:
			# Swelling, with a glow of its own color round it rather than washed toward white,
			# which a pale color over a pale prop had nothing left to show.
			box = box.grow(PULSE_GROW * swell)
			SuitArt.draw_into(self, box.grow(3.0), suits[i], Color(held[i], 0.45 * swell))
		SuitArt.draw_into(self, box, suits[i], held[i], OUTLINE)
	if threat >= 0:
		_draw_warning()
	if locked > 0.0 and not held.is_empty():
		var bar := Rect2(Vector2(0.0, SUIT + LOCK_DROP), Vector2(_wide() * locked, LOCK_BAR))
		draw_rect(bar.grow(1.0), RIM)
		draw_rect(bar, held[0])


## The exclamation mark past the end of the row, in the threatening player's color, pulsing with
## their suits.
func _draw_warning() -> void:
	var font := Type.display_font()
	var at := Vector2(_wide() + MARK_GAP, SUIT * 0.5 + MARK_SIZE * 0.36)
	var color := match_node.slots[threat].color()
	var light := 0.5 + 0.5 * sin(_beat * PULSE)
	draw_string_outline(font, at, "!", HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_SIZE, 6, RIM)
	draw_string(
		font,
		at,
		"!",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		MARK_SIZE,
		color.lerp(Color.WHITE, light * 0.4)
	)
