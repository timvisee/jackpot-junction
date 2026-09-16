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
## Every card is positioned by its bottom centre, which is also its pivot, so the fan tilt and the
## per-player scale both turn about the point the hand is held at. A key cap to the left of the
## hand names the button that opens the joker menu, while cards are held and the control hints
## setting is on.

## Fraction of a card hidden by the next one.
const OVERLAP := 0.35
const LIFT := 44.0
const MARGIN := 14.0
const GLIDE := 14.0
## How far the middle of a full fan rides above its ends, and how far the end cards tip away.
const ARC := 18.0
const TILT_DEG := 6.0
const DIMMED := Color(0.55, 0.55, 0.6, 0.9)

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
var _detail: PanelContainer
var _detail_text: RichTextLabel
var _cap: PanelContainer
var _cap_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail = PanelContainer.new()
	_detail.visible = false
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_text = RichTextLabel.new()
	_detail_text.bbcode_enabled = true
	_detail_text.fit_content = true
	_detail_text.scroll_active = false
	_detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_text.custom_minimum_size = Vector2(380.0, 0.0)
	_detail_text.add_theme_font_size_override("normal_font_size", 18)
	_detail_text.add_theme_font_size_override("bold_font_size", 22)
	_detail.add_child(_detail_text)
	add_child(_detail)
	_build_cap()


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
		panel.rotation = lerp_angle(
			panel.rotation, 0.0 if lifted else across * deg_to_rad(TILT_DEG) * fan, blend
		)
		panel.z_index = count + 1 if lifted else i
		var tint := DIMMED if picked >= 0 and not lifted else Color.WHITE
		panel.modulate = panel.modulate.lerp(tint, blend)
		panel.set_highlighted(lifted)
	_place_cap(left, bottom, card)
	_detail.visible = picked >= 0
	if picked >= 0:
		_detail_text.text = _detail_bbcode(kart.jokers.jokers[picked])
		var x := picked_anchor.x - _detail.size.x * 0.5
		x = clampf(x, 8.0, maxf(size.x - _detail.size.x - 8.0, 8.0))
		_detail.position = Vector2(x, picked_anchor.y - card.y - _detail.size.y - 10.0)


## A key cap beside the hand, drawn the way a key is drawn in a manual.
func _build_cap() -> void:
	_cap = PanelContainer.new()
	_cap.visible = false
	_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.16, 0.92)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.72, 0.72, 0.8)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	_cap.add_theme_stylebox_override("panel", style)
	_cap_label = Label.new()
	_cap_label.add_theme_font_size_override("font_size", 18)
	_cap_label.add_theme_color_override("font_color", Palette.CHIP_WHITE)
	_cap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cap.add_child(_cap_label)
	add_child(_cap)


## Puts the cap just left of the hand, named for the scheme the player is using.
func _place_cap(left: float, baseline: float, card: Vector2) -> void:
	_cap.visible = not _cards.is_empty() and Game.settings.control_hints
	if not _cap.visible:
		return
	_cap_label.text = InputActions.short_binding_text(InputActions.JOKER_MENU, keyboard)
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


func _detail_bbcode(joker: Joker) -> String:
	var hints := (
		"%s / %s cycle    %s drop    %s destroy"
		% [
			InputActions.binding_text(InputActions.JOKER_PREV, keyboard),
			InputActions.binding_text(InputActions.JOKER_NEXT, keyboard),
			InputActions.binding_text(InputActions.JOKER_DROP, keyboard),
			InputActions.binding_text(InputActions.JOKER_DESTROY, keyboard),
		]
	)
	return (
		"[b]%s[/b]  [color=#%s]%s[/color]\n%s\n[color=#9a9aa0]%s[/color]"
		% [
			joker.display_name,
			JokerCard.kind_color(joker).to_html(false),
			JokerCard.kind_name(joker),
			joker.description,
			hints,
		]
	)
