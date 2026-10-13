class_name FlushTally
extends Control
## How the Royal Flush pads stand, GAME.md 3.9 and 8.3, under the clock: a little playing card for
## each pad, tucked under the clock's board so it sticks out of it, GAME.md 8.1a, a cream one with
## the pad's suit in its holder's color for every pad held and a dark one with the suit faint for
## every pad nobody holds, so a player chasing the flush can see which suits they have and which
## they still need without looking round the table for four frames. The players at this screen
## come first, then whoever else holds most, and the free suits last, so a player's own count is
## the run of cards on the left.
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
##
## A watcher's screen has nobody of its own to count for, and is there to follow the match: it
## shows the tally whenever anybody holds a pad, and whoever's flush is still paying, GAME.md 9.3.

## How big a suit is, how thick its outline, and what a free one is filled with.
const SUIT := 22.0
const OUTLINE := 0.9
const EMPTY := Color(1.0, 1.0, 1.0, 0.28)
const RIM := Color(0.0, 0.0, 0.0, 0.55)
## The cards: how big, how far apart, how much of the top of each is tucked under the board, how
## far they fan, what a held one and a free one are printed on, and their edges.
const CARD := Vector2(30.0, 42.0)
const GAP := 5.0
const TUCK := 14.0
const FAN := 0.035
const HELD_FACE := HouseTheme.PAPER
const FREE_FACE := Color(0.1, 0.095, 0.12, 0.88)
const EDGE := Color(0.0, 0.0, 0.0, 0.5)
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
	# Behind the clock's board, so the cards come out from under it.
	tally.z_index = -1
	hud.add_child(tally)
	return tally


func _process(delta: float) -> void:
	var was := held.duplicate()
	var were := suits.duplicate()
	var count := pads
	var had := locked
	_tally()
	var shown := (
		_held_here() or locked > 0.0 or threat >= 0 or (_watching() and not held.is_empty())
	)
	visible = match_node != null and match_node.is_running() and shown
	if threat >= 0:
		_beat += delta
		queue_redraw()
	if held != was or suits != were or pads != count or locked != had:
		var wide := _wide()
		custom_minimum_size = Vector2(wide, CARD.y)
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
	var ours := winner >= 0 and (_plays_here(winner) or _watching())
	var here := _pads_here()
	if match_node.flush_lock_left > 0.0 and ours:
		pads = here.size()
		for i: int in pads:
			held.append(match_node.slots[winner].color())
			holders.append(winner)
			suits.append(i)
		var lasts := maxf(match_node.rules.flush_lock_seconds, 0.001)
		locked = clampf(match_node.flush_lock_left / lasts, 0.0, 1.0)
		return
	var by_slot: Dictionary[int, Array] = {}
	var free: Array[int] = []
	for pad: FlushPad in here:
		pads += 1
		if pad.owner_slot >= 0 and not pad.is_disabled():
			var side := _side(pad.owner_slot)
			if not by_slot.has(side):
				by_slot[side] = []
			by_slot[side].append(pad)
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
	for pad: FlushPad in _pads_here():
		if pad.owner_slot >= 0 and not pad.is_disabled() and _plays_here(pad.owner_slot):
			return true
	return false


## The pads of the room the first player at this screen is in, GAME.md 3.9: every pad on a map of
## one room, which is every map but the tutorial's, and every pad on a watcher's screen.
func _pads_here() -> Array[FlushPad]:
	var all := match_node.arena.flush_pads
	var grid := match_node.arena.grid
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_local_human() or slot.kart == null:
			continue
		var room := grid.region_of(grid.cell_of(slot.kart.global_position))
		var mine: Array[FlushPad] = []
		for pad: FlushPad in all:
			if pad.group == room:
				mine.append(pad)
		return mine
	return all


## Whether [param slot]'s side plays at this screen: its player, or in team play a teammate of
## theirs, GAME.md 3.14.
func _plays_here(slot: int) -> bool:
	if slot < 0 or slot >= match_node.slots.size():
		return false
	var team := match_node.slots[slot].team
	for each: PlayerSlot in match_node.slots:
		if each.is_local_human() and (each.index == slot or Teams.same(each.team, team)):
			return true
	return false


## The slot that stands for [param slot]'s side in the tally: itself, or in team play its team's
## first seat, so a team's pads count together, GAME.md 3.14.
func _side(slot: int) -> int:
	var team := match_node.slots[slot].team if slot < match_node.slots.size() else -1
	if team < 0:
		return slot
	return Teams.members(match_node.slots, team)[0].index


## Whether this screen is a watcher's, following a match online with nobody of its own in it.
static func _watching() -> bool:
	return Net.online() and Net.session != null and Net.session.watching


func _wide() -> float:
	return pads * CARD.x + maxf(pads - 1, 0) * GAP


func _draw() -> void:
	var swell := (0.5 + 0.5 * sin(_beat * PULSE)) if threat >= 0 else 0.0
	var count := mini(pads, suits.size())
	for i: int in count:
		var free := i >= held.size()
		var middle := Vector2(i * (CARD.x + GAP) + CARD.x * 0.5, CARD.y * 0.5)
		# Fanned a little either way from the middle, as cards slid under a board are.
		draw_set_transform(middle, FAN * (float(i) - float(count - 1) * 0.5))
		var card := Rect2(-CARD * 0.5, CARD)
		var face := StyleBoxFlat.new()
		face.set_corner_radius_all(4)
		face.anti_aliasing = true
		face.set_border_width_all(1)
		face.bg_color = FREE_FACE if free else HELD_FACE
		face.border_color = Color(1.0, 1.0, 1.0, 0.18) if free else EDGE
		face.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		face.shadow_size = 4
		var threatening := not free and holders[i] == threat
		if threatening:
			# Swelling, with a glow of its own color round it rather than washed toward white,
			# which a pale color over a pale prop had nothing left to show.
			card = card.grow(PULSE_GROW * swell)
			face.shadow_color = Color(held[i], 0.6 * swell)
			face.shadow_size = roundi(4.0 + 6.0 * swell)
		draw_style_box(face, card)
		# The suit in the part of the card that sticks out from under the board.
		var shown := (CARD.y - TUCK) * 0.5 + TUCK - CARD.y * 0.5
		var box := Rect2(Vector2(-SUIT * 0.5, shown - SUIT * 0.5), Vector2(SUIT, SUIT))
		if free:
			SuitArt.draw_into(self, box, suits[i], EMPTY, OUTLINE)
		else:
			SuitArt.draw_into(self, box, suits[i], held[i], OUTLINE)
	draw_set_transform(Vector2.ZERO)
	if threat >= 0:
		_draw_warning()
	if locked > 0.0 and not held.is_empty():
		var bar := Rect2(Vector2(0.0, CARD.y + LOCK_DROP), Vector2(_wide() * locked, LOCK_BAR))
		draw_rect(bar.grow(1.0), RIM)
		draw_rect(bar, held[0])


## The exclamation mark past the end of the row, in the threatening player's color, pulsing with
## their suits.
func _draw_warning() -> void:
	var font := Type.display_font()
	var at := Vector2(_wide() + MARK_GAP, (CARD.y + TUCK) * 0.5 + MARK_SIZE * 0.36)
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
