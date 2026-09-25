class_name JokerHand
extends Control
## A local player's jokers as a hand of overlapping cards along the bottom of the screen, GAME.md
## 8.3. Each hand takes one share of the bottom edge, or with three or four players on the screen
## keeps to its owner's corner, hanging from the top edge for a top one. Three or more cards fan
## out: the middle of the hand rides higher and the outer cards tip away, the way a hand of cards
## sits in a fist.
## While the joker menu is open the selected card straightens up and lifts out of the fan with a
## bright frame and its description above it, and the other cards dim. Cards glide into place, so
## taking, dropping or destroying a joker reads at a glance. Initials and names sit at the left
## edge, the strip of each card the next one leaves uncovered.
##
## Every card is positioned by its bottom center, which is also its pivot, so the fan tilt and the
## per-player scale both turn about the point the hand is held at. A key cap to the left of the
## hand names the button that opens the joker menu, while cards are held and the control hints
## setting is on, and a count on the other side says how many of the slots are taken, out of
## however many the hand has room for.

## Fraction of a card hidden by the next one.
const OVERLAP := 0.35
const LIFT := 44.0
const MARGIN := 14.0
const GLIDE := 14.0
## How far the middle of a full fan rides above its ends, and how far the end cards tip away.
const ARC := 18.0
const TILT_DEG := 6.0
const DIMMED := Color(0.55, 0.55, 0.6, 0.9)
## How big the picture of the joker-menu button beside the hand is drawn.
const CAP_SIZE := 18
## The least a hand shrinks to in its lane, and the room kept either side of it for the count.
const NARROWEST := 0.55
const COUNT_ROOM := 64.0
## How big a tucked hand is against its full size, the least it is ever drawn at, and how much of
## a card's height it is tucked below the bottom edge.
const TUCKED := 0.6
const TUCKED_LEAST := 0.4
const TUCK := 0.45
## The drop and destroy buttons a touch screen puts on the pane of a card tapped to keep it open,
## GAME.md 4.2: how big they are.
const TOUCH_BUTTON := Vector2(150.0, 46.0)

var kart: Kart
## This hand takes share [member column] of [member columns] of the bottom edge. With three or
## four on this screen it keeps to its owner's corner instead, GAME.md 8.3: [member corner] is
## which, numbered as the corner blocks are, or -1 for a share of the bottom edge. A hand for a top
## corner hangs from the top edge, see [method hangs], and [member lane] keeps it beside its block.
var column := 0
var columns := 1
var corner := -1
## Whether the control hints name keys or gamepad buttons.
var keyboard := true
## Screen rectangles the hand stays clear of, such as a HUD block in a bottom corner.
var avoid: Array[Rect2] = []
## The stretch of the bottom edge the hand keeps to, from and to, inside its own share; zero for
## the whole share. A hand wider than it shrinks to fit, down to [constant NARROWEST]: the touch
## screen's stick and buttons stand either side of it, GAME.md 4.2.
var lane := Vector2.ZERO
## Tucked into the bottom edge while no card of it is being read: smaller, and half below the edge,
## rising to its full size as a card is held or kept open. The touch screen's, GAME.md 4.2, where
## a hand of cards across the bottom of a phone is a hand of cards over the arena. A hand in a
## corner, see [member corner], is tucked into its own edge the same way, GAME.md 8.3: four hands
## at full size are four hands over the arena too.
var tucked := false

var _cards: Array[JokerCard] = []
var _ids: Array[StringName] = []
var _detail: JokerDetail
var _cap: Control
## What the cap is currently a picture of, so it is only rebuilt when the button changes.
var _cap_shown := ""
var _count_label: Label
## What the pane under a card says on a touch screen, so it is only built again when that changes,
## and its two buttons while it has them.
var _touch_shown := ""
var _touch_buttons: Dictionary[StringName, Button] = {}
## How far into the screen the cards come, at rest, see [method reach].
var _reach := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail = JokerDetail.new()
	_detail.name = "Detail"
	_detail.visible = false
	add_child(_detail)
	_build_count()


func card_count() -> int:
	return _cards.size()


## How far into the screen the cards come while none is lifted, for what has to stay clear of
## them: the tops of standing cards, the bottoms of hanging ones, or the edge with none.
func reach() -> float:
	if _cards.is_empty():
		return 0.0 if hangs() else size.y
	return _reach


## The card under [param point], in the hand's own coordinates, or -1. The one on top wins where
## two overlap, which is the one whose face is showing there. The lifted card still answers where
## it rose from, so a finger holding it is not left behind as it rises out from under it.
func card_at(point: Vector2) -> int:
	var best := -1
	var picked := selected()
	for i: int in _cards.size():
		var card := _cards[i]
		var face := Rect2(Vector2.ZERO, card.size)
		var local := card.get_transform().affine_inverse() * point
		var under := face.has_point(local)
		if i == picked and not under:
			var risen := point + Vector2(0.0, LIFT * card.scale.y * _inward())
			under = face.has_point(card.get_transform().affine_inverse() * risen)
		if not under:
			continue
		if best < 0 or card.z_index >= _cards[best].z_index:
			best = i
	return best


## Whether the hand hangs from the top edge rather than standing on the bottom one, as the hand of
## a player whose block is in a top corner does, see [member corner]. The cards stay upright to be
## read, but the fan bows down rather than up, the card being read drops out of it rather than
## rising, and its pane opens under it.
func hangs() -> bool:
	return corner == 0 or corner == 1


## Which way is into the screen from the edge the hand is held at: down for one hanging from the
## top, up for one standing on the bottom.
func _inward() -> float:
	return 1.0 if hangs() else -1.0


## Index of the lifted card, or -1 while the joker menu is closed.
func selected() -> int:
	if kart == null or not kart.menu_open or _cards.is_empty():
		return -1
	return clampi(kart.menu_index, 0, _cards.size() - 1)


func _process(delta: float) -> void:
	if kart == null:
		return
	_sync_cards()
	var count := _cards.size()
	var picked := selected()
	var factor := 1.0 if columns <= 2 else 0.8
	var from := size.x * column / columns
	var to := size.x * (column + 1) / columns
	if corner >= 0:
		from = size.x * 0.5 * (corner % 2)
		to = from + size.x * 0.5
	if lane != Vector2.ZERO:
		from = maxf(from, lane.x)
		to = minf(to, lane.y)
		var full := JokerCard.SIZE.x * (1.0 + (1.0 - OVERLAP) * maxf(count - 1, 0.0))
		var room := to - from - COUNT_ROOM * 2.0
		factor = clampf(room / full, NARROWEST, factor)
	var resting := (tucked or corner >= 0) and picked < 0
	if resting:
		factor = maxf(factor * TUCKED, minf(TUCKED_LEAST, factor))
	var card := JokerCard.SIZE * factor
	var lift := LIFT * factor
	var step := card.x * (1.0 - OVERLAP)
	var hand_width := card.x + step * (count - 1)
	var left := (from + to) * 0.5 - hand_width * 0.5
	var inward := _inward()
	# The edge the cards are held at: where their bottoms stand, or their tops hang from.
	var tuck := card.y * TUCK if resting else 0.0
	var edge := MARGIN - tuck if hangs() else size.y - MARGIN + tuck
	var reach := card.y + lift + ARC
	var span := Rect2(left, edge if hangs() else edge - reach, hand_width, reach)
	for rect: Rect2 in avoid:
		if not rect.intersects(span):
			continue
		edge = maxf(edge, rect.end.y + 8.0) if hangs() else minf(edge, rect.position.y - 8.0)
	# One or two cards stay flat; the fan comes in as the hand fills up.
	var fan := clampf(float(count - 2) / 3.0, 0.0, 1.0)
	# The highest of the fan is its middle, raised by the arc, or the inner corner of a card
	# tipped at its end, whichever is the higher.
	var tipped := card.x * sin(deg_to_rad(TILT_DEG)) * fan
	_reach = edge + inward * (card.y + maxf(ARC * factor * fan, tipped))
	var blend := 1.0 - exp(-GLIDE * delta)
	var picked_anchor := Vector2.ZERO
	for i: int in count:
		var panel := _cards[i]
		var lifted := i == picked
		var across := 0.0 if count < 2 else float(i) / float(count - 1) * 2.0 - 1.0
		var arc := (1.0 - across * across) * ARC * factor * fan
		var height := edge + inward * (arc + (lift if lifted else 0.0))
		var anchor := Vector2(left + step * i + card.x * 0.5, height)
		if lifted:
			picked_anchor = anchor
		# Hanging, a card turns about its top center rather than its bottom center, so the point
		# the hand is held at stays the one it turns and shrinks about.
		panel.pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, 0.0 if hangs() else JokerCard.SIZE.y)
		panel.scale = panel.scale.lerp(Vector2.ONE * factor, blend)
		# The pivot is the card's bottom center, so scaling already happens about that point and the
		# offset is not scaled again: scaled, a card smaller than its own size stood below its place
		# and to the right of it, by as much as it had shrunk.
		panel.position = panel.position.lerp(anchor - panel.pivot_offset, blend)
		# The lifted card keeps its place in the fan rather than straightening up. The cards
		# turn about their bottom corner, so un-tilting one swings its body sideways, and a card
		# picked out of the hand slid left or right as well as rising.
		# Hanging, the same tilt tips a card's bottom away rather than its top, so it is turned the
		# other way: the same fan, held from above.
		var tilt := across * deg_to_rad(TILT_DEG) * fan * -inward
		panel.rotation = lerp_angle(panel.rotation, tilt, blend)
		panel.z_index = count + 1 if lifted else i
		var tint := DIMMED if picked >= 0 and not lifted else Color.WHITE
		panel.modulate = panel.modulate.lerp(tint, blend)
		panel.set_highlighted(lifted)
	var middle := edge + inward * card.y * 0.5
	_place_cap(left, middle)
	_place_count(left + hand_width, middle)
	_detail.visible = picked >= 0
	if picked >= 0:
		_show_detail(kart.jokers.jokers[picked])
		var x := picked_anchor.x - _detail.size.x * 0.5
		if corner >= 0:
			# Kept to the lane, off the block beside it; too wide for it, it spills the other way.
			var spare := to - from - _detail.size.x
			var outer := from if corner % 2 == 0 else to - _detail.size.x
			x = clampf(x, from, to - _detail.size.x) if spare >= 0.0 else outer
		x = clampf(x, 8.0, maxf(size.x - _detail.size.x - 8.0, 8.0))
		var y := picked_anchor.y - card.y - _detail.size.y - 12.0
		if hangs():
			y = picked_anchor.y + card.y + 12.0
		_detail.position = Vector2(x, y)


## How full the hand is, in gold once there is no room left for another joker.
func _build_count() -> void:
	_count_label = Label.new()
	_count_label.visible = false
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(_count_label, Type.STRONG, Type.BODY)
	HudText.shadowed(_count_label, 2)
	add_child(_count_label)


func _place_count(right: float, middle: float) -> void:
	_count_label.visible = not _cards.is_empty()
	if not _count_label.visible:
		return
	var held := _cards.size()
	var room := kart.jokers.capacity() if kart != null else JokerHolder.MAX_JOKERS
	_count_label.text = "%d / %d" % [held, room]
	_count_label.add_theme_color_override(
		"font_color", Palette.CHIP_GOLD if held >= room else Color(0.82, 0.82, 0.88)
	)
	var label_size := _count_label.get_combined_minimum_size()
	_count_label.size = label_size
	_count_label.position = Vector2(right + 12.0, middle - label_size.y * 0.5)


## A picture of the button that opens the hand, sitting just left of it, GAME.md 8.3: a key cap
## on a keyboard and the round colored button on a pad. Rebuilt rather than relabeled, since a
## player who picks up a pad mid-match is looking at a different shape and not only a different
## word.
func _place_cap(left: float, middle: float) -> void:
	# A touch screen opens the hand by holding a card, GAME.md 4.2, so there is no button to name.
	var shown := not _cards.is_empty() and Game.settings.control_hints and not TouchInput.enabled
	var wanted := (
		InputActions.short_binding_text(InputActions.JOKER_MENU, keyboard) if shown else ""
	)
	if wanted != _cap_shown:
		_cap_shown = wanted
		if _cap != null:
			_cap.queue_free()
			_cap = null
		if shown:
			_cap = InputGlyph.of_action(
				InputActions.JOKER_MENU, keyboard, Palette.CHIP_WHITE, CAP_SIZE
			)
			if _cap != null:
				add_child(_cap)
	if _cap == null:
		return
	var cap_size := _cap.get_combined_minimum_size()
	_cap.size = cap_size
	_cap.position = Vector2(left - cap_size.x - 12.0, middle - cap_size.y * 0.5)


## Deals a fresh set of cards, sliding in from below, whenever the held jokers change.
func _sync_cards() -> void:
	var ids := kart.jokers.ids()
	if ids == _ids:
		return
	_ids = ids
	for card: JokerCard in _cards:
		card.queue_free()
	_cards.clear()
	for joker: Joker in kart.jokers.jokers:
		var card := JokerCard.create(joker)
		# Fresh cards slide into the hand from beyond the edge it is held at.
		var beyond := -JokerCard.SIZE.y * 2.0 if hangs() else size.y + JokerCard.SIZE.y
		card.position = Vector2(size.x * (column + 0.5) / columns, beyond)
		add_child(card)
		_cards.append(card)


## What the player can do with the lifted card, which is the only part of the pane the hand has
## to say anything about.
func _show_detail(joker: Joker) -> void:
	_detail.show_joker(joker)
	if _pointed():
		_show_touch_hints()
		return
	_touch_shown = ""
	var ink := JokerDetail.hint_ink()
	var size := InputHint.FONT_SIZE
	var parts: Array = [
		InputHint.pair(InputActions.STEER_LEFT, InputActions.STEER_RIGHT, keyboard, ink, size),
	]
	var line := "%s cycle"
	# A player waiting to come back can read their hand but not throw any of it away, GAME.md
	# 3.7, so the pane stops offering the two buttons that would. A hint for a button that does
	# nothing is worse than no hint: it reads as the game having stopped listening.
	if kart != null and kart.alive:
		parts.append(InputHint.glyph(InputActions.JOKER_DROP, keyboard, ink, size))
		parts.append(InputHint.glyph(InputActions.JOKER_DESTROY, keyboard, ink, size))
		line += "   %s drop   %s destroy"
	_detail.set_hints(InputHint.row(line, parts, ink, size))


## Whether the card up is a finger's or the mouse's, which the pane says how to keep open or close,
## rather than one opened with the joker menu's key.
func _pointed() -> bool:
	if TouchInput.enabled:
		return true
	return MouseJokers.pointing and MouseJokers.player != null and MouseJokers.player.kart == kart


## The drop and destroy buttons on the pane, by name, while a card tapped or clicked open has them,
## for [TouchControls], or [MouseJokers], to press. Empty otherwise.
func touch_buttons() -> Dictionary[StringName, Button]:
	if not _detail.visible:
		return {}
	return _touch_buttons


## What the pane says on a touch screen, GAME.md 4.2, or for a card the mouse is on, in place of the
## buttons it names on a keyboard or a pad. A card only held, or pointed at, is being read, and is
## told how to keep it open; one tapped or clicked open says how to close it, and while the kart is
## in play it has a button each for dropping and destroying it. A kart waiting to come back cannot
## throw any of its hand away, GAME.md 3.7.
func _show_touch_hints() -> void:
	var pinned := TouchInput.joker_pinned
	var acting := pinned and kart != null and kart.alive
	var verb := "Tap" if TouchInput.enabled else "Click"
	var wanted := "%s %s" % [verb, "acting" if acting else ("pinned" if pinned else "held")]
	if wanted == _touch_shown:
		return
	_touch_shown = wanted
	_touch_buttons.clear()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if acting:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for id: StringName in [&"drop", &"destroy"]:
			var button := MenuTheme.button(String(id).capitalize(), Type.BODY)
			button.custom_minimum_size = TOUCH_BUTTON
			# Pressed by the touch controls, which answer every finger on its own, GAME.md 4.2.
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.focus_mode = Control.FOCUS_NONE
			if id == &"destroy":
				button.add_theme_color_override("font_color", JokerCard.DOOMED)
			row.add_child(button)
			_touch_buttons[id] = button
		column.add_child(row)
	var line := Label.new()
	line.text = (
		"%s the card to keep it open" % verb if not pinned else "%s it again to close it" % verb
	)
	Type.text(line, InputHint.FONT_SIZE, JokerDetail.hint_ink())
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(line)
	_detail.set_hints(column)
