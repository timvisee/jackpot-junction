class_name JokerHand
extends Control
## A local player's jokers as a hand of overlapping cards along the bottom of the screen, GAME.md
## 8.3. Each hand takes one share of the bottom edge. Three or more cards fan out: the middle of
## the hand rides higher and the outer cards tip away, the way a hand of cards sits in a fist.
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

var kart: Kart
## This hand takes share [member column] of [member columns] of the bottom edge.
var column := 0
var columns := 1
## Whether the control hints name keys or gamepad buttons.
var keyboard := true
## Screen rectangles the hand stays clear of, such as a HUD block in a bottom corner.
var avoid: Array[Rect2] = []

var _cards: Array[JokerCard] = []
var _ids: Array[StringName] = []
var _detail: JokerDetail
var _cap: Control
## What the cap is currently a picture of, so it is only rebuilt when the button changes.
var _cap_shown := ""
var _count_label: Label


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
	var card := JokerCard.SIZE * factor
	var lift := LIFT * factor
	var step := card.x * (1.0 - OVERLAP)
	var hand_width := card.x + step * (count - 1)
	var left := size.x * (column + 0.5) / columns - hand_width * 0.5
	var bottom := size.y - MARGIN
	var span := Rect2(left, bottom - card.y - lift - ARC, hand_width, card.y + lift + ARC)
	for rect: Rect2 in avoid:
		if rect.intersects(span):
			bottom = minf(bottom, rect.position.y - 8.0)
	# One or two cards stay flat; the fan comes in as the hand fills up.
	var fan := clampf(float(count - 2) / 3.0, 0.0, 1.0)
	var blend := 1.0 - exp(-GLIDE * delta)
	var picked_anchor := Vector2.ZERO
	for i: int in count:
		var panel := _cards[i]
		var lifted := i == picked
		var across := 0.0 if count < 2 else float(i) / float(count - 1) * 2.0 - 1.0
		var arc := (1.0 - across * across) * ARC * factor * fan
		var height := bottom - arc - (lift if lifted else 0.0)
		var anchor := Vector2(left + step * i + card.x * 0.5, height)
		if lifted:
			picked_anchor = anchor
		panel.scale = Vector2.ONE * factor
		panel.position = panel.position.lerp(anchor - panel.pivot_offset * factor, blend)
		# The lifted card keeps its place in the fan rather than straightening up. The cards
		# turn about their bottom corner, so un-tilting one swings its body sideways, and a card
		# picked out of the hand slid left or right as well as rising.
		panel.rotation = lerp_angle(panel.rotation, across * deg_to_rad(TILT_DEG) * fan, blend)
		panel.z_index = count + 1 if lifted else i
		var tint := DIMMED if picked >= 0 and not lifted else Color.WHITE
		panel.modulate = panel.modulate.lerp(tint, blend)
		panel.set_highlighted(lifted)
	_place_cap(left, bottom, card)
	_place_count(left + hand_width, bottom, card)
	_detail.visible = picked >= 0
	if picked >= 0:
		_show_detail(kart.jokers.jokers[picked])
		var x := picked_anchor.x - _detail.size.x * 0.5
		x = clampf(x, 8.0, maxf(size.x - _detail.size.x - 8.0, 8.0))
		_detail.position = Vector2(x, picked_anchor.y - card.y - _detail.size.y - 12.0)


## How full the hand is, in gold once there is no room left for another joker.
func _build_count() -> void:
	_count_label = Label.new()
	_count_label.visible = false
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(_count_label, Type.STRONG, Type.BODY)
	HudText.shadowed(_count_label, 2)
	add_child(_count_label)


func _place_count(right: float, baseline: float, card: Vector2) -> void:
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
	_count_label.position = Vector2(right + 12.0, baseline - card.y * 0.5 - label_size.y * 0.5)


## A picture of the button that opens the hand, sitting just left of it, GAME.md 8.3: a key cap
## on a keyboard and the round colored button on a pad. Rebuilt rather than relabeled, since a
## player who picks up a pad mid-match is looking at a different shape and not only a different
## word.
func _place_cap(left: float, baseline: float, card: Vector2) -> void:
	var shown := not _cards.is_empty() and Game.settings.control_hints
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
	_cap.position = Vector2(left - cap_size.x - 12.0, baseline - card.y * 0.5 - cap_size.y * 0.5)


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
		# Fresh cards slide up into the hand from below the screen edge.
		card.position = Vector2(size.x * (column + 0.5) / columns, size.y + JokerCard.SIZE.y)
		add_child(card)
		_cards.append(card)


## What the player can do with the lifted card, which is the only part of the pane the hand has
## to say anything about.
func _show_detail(joker: Joker) -> void:
	_detail.show_joker(joker)
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
