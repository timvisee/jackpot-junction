class_name FlushTally
extends Control
## How the Royal Flush pads stand, GAME.md 3.9 and 8.3, under the clock: a block for each pad, one
## in its holder's color for every pad held and an outline for every pad nobody holds, so a player
## chasing the flush can count how close it is without looking round the table for four frames. The
## players at this screen come first, then whoever else holds most, so a player's own count is the
## run of blocks on the left.
##
## Up only while somebody at this screen holds a pad, and only while the match is being played: a
## row of four outlines on every screen of every match, most of the time, is four more things on
## the screen that say nothing, and after the whistle the flush is not there to be had.

## How big a block is, how far apart two are, and how thick an empty one's outline.
const BLOCK := 16.0
const GAP := 6.0
const OUTLINE := 2.0
const EMPTY := Color(1.0, 1.0, 1.0, 0.55)
const RIM := Color(0.0, 0.0, 0.0, 0.55)

var match_node: Match

## The colors of the held pads, in the order they are drawn, and how many pads there are.
var held: Array[Color] = []
var pads := 0


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


func _process(_delta: float) -> void:
	var was := held.duplicate()
	var count := pads
	_tally()
	visible = match_node != null and match_node.is_running() and _held_here()
	if held != was or pads != count:
		var wide := pads * BLOCK + maxf(pads - 1, 0) * GAP
		custom_minimum_size = Vector2(wide, BLOCK)
		offset_left = -wide * 0.5
		offset_right = wide * 0.5
		queue_redraw()


## Who holds what: this screen's players first, in their slot order, then everybody else by how
## many they hold, most first.
func _tally() -> void:
	held.clear()
	pads = 0
	if match_node == null or match_node.arena == null:
		return
	var by_slot: Dictionary[int, Array] = {}
	for pad: FlushPad in match_node.arena.flush_pads:
		pads += 1
		if pad.owner_slot >= 0 and not pad.is_disabled():
			if not by_slot.has(pad.owner_slot):
				by_slot[pad.owner_slot] = []
			by_slot[pad.owner_slot].append(pad.owner_color)
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
		for color: Color in by_slot[slot]:
			held.append(color)


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


func _draw() -> void:
	for i: int in pads:
		var box := Rect2(Vector2(i * (BLOCK + GAP), 0.0), Vector2(BLOCK, BLOCK))
		if i < held.size():
			draw_rect(box.grow(1.5), RIM)
			draw_rect(box, held[i])
		else:
			draw_rect(box.grow(1.0), RIM, false, OUTLINE + 1.0)
			draw_rect(box.grow(-OUTLINE * 0.5), EMPTY, false, OUTLINE)
