class_name JokerPicker
extends Control
## The respawn joker choice, GAME.md 3.7, as a row of cards in the middle of the screen. The card
## under the cursor lifts, grows and lights up, with its description underneath. A player holding
## five jokers gets the same row again, this time of their own cards, to choose one to destroy;
## that card wears a red frame and a big red cross, so it can never be read as the one being
## claimed.
##
## Each local player picks inside their own share of the screen, the same share their hand of
## cards uses, so two players choosing at once never overlap.

const LIFT := 26.0
const PICKED_SCALE := 1.12
const GAP := 18.0
## How thick the bars of the destroy cross are, and how far they reach over the card.
const CROSS_WIDTH := 11.0
const CROSS_REACH := 0.82

## This picker takes share [member column] of [member columns] of the screen.
var column := 0
var columns := 1
## Whether the control hints name keys or gamepad buttons.
var keyboard := true

var _title: Label
var _cards: Array[JokerCard] = []
var _detail: PanelContainer
var _detail_text: RichTextLabel
var _hints: Label
var _cross: Control
var _shown: Array[StringName] = []
var _stage := JokerOffer.Stage.DONE


func card_count() -> int:
	return _cards.size()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Palette.CHIP_WHITE)
	_title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_title.add_theme_constant_override("shadow_offset_x", 2)
	_title.add_theme_constant_override("shadow_offset_y", 2)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_detail = PanelContainer.new()
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_text = RichTextLabel.new()
	_detail_text.bbcode_enabled = true
	_detail_text.fit_content = true
	_detail_text.scroll_active = false
	_detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_text.custom_minimum_size = Vector2(420.0, 0.0)
	_detail_text.add_theme_font_size_override("normal_font_size", 19)
	_detail_text.add_theme_font_size_override("bold_font_size", 23)
	_detail.add_child(_detail_text)
	add_child(_detail)
	_hints = Label.new()
	_hints.add_theme_font_size_override("font_size", 17)
	_hints.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	_hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hints)
	_build_cross()


## Shows the offer for one slot, or hides the picker when there is nothing to choose.
func show_offer(offer: JokerOffer, kart: Kart) -> void:
	if offer == null or offer.is_done():
		visible = false
		_clear()
		return
	visible = true
	var choosing := offer.stage == JokerOffer.Stage.CHOOSING
	var jokers: Array[Joker] = offer.choices if choosing else kart.jokers.jokers
	_sync(jokers, offer.stage)
	var picked := clampi(offer.selected, 0, maxi(_cards.size() - 1, 0))
	_title.text = (
		"Pick a joker" if choosing else "Destroy which joker for %s?" % offer.chosen.display_name
	)
	if picked < jokers.size():
		_detail_text.text = _describe(jokers[picked])
	_hints.text = _hint_text(choosing)
	_layout(picked)


## Two bars in a red X, laid out over a card exactly as the card itself is, so it lines up
## whatever the card's scale.
func _build_cross() -> void:
	_cross = Control.new()
	_cross.name = "DestroyCross"
	_cross.visible = false
	_cross.size = JokerCard.SIZE
	_cross.pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, JokerCard.SIZE.y)
	_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for angle: float in [45.0, -45.0]:
		var bar := ColorRect.new()
		bar.color = JokerCard.DOOMED
		bar.size = Vector2(JokerCard.SIZE.length() * CROSS_REACH, CROSS_WIDTH)
		bar.pivot_offset = bar.size * 0.5
		bar.position = JokerCard.SIZE * 0.5 - bar.size * 0.5
		bar.rotation = deg_to_rad(angle)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cross.add_child(bar)
	add_child(_cross)


func _layout(picked: int) -> void:
	var count := _cards.size()
	var destroying := _stage == JokerOffer.Stage.REPLACING
	var width := size.x / columns
	var centre := width * (column + 0.5)
	var row := JokerCard.SIZE.x * count + GAP * maxf(count - 1, 0.0)
	var left := centre - row * 0.5
	var baseline := size.y * 0.52
	for i: int in count:
		var card := _cards[i]
		var chosen := i == picked
		var anchor := Vector2(
			left + (JokerCard.SIZE.x + GAP) * i + JokerCard.SIZE.x * 0.5,
			baseline - (LIFT if chosen else 0.0)
		)
		var scale_to := PICKED_SCALE if chosen else 1.0
		card.scale = card.scale.lerp(Vector2.ONE * scale_to, 0.4)
		card.position = anchor - card.pivot_offset * card.scale
		card.modulate = Color.WHITE if chosen else Color(0.66, 0.66, 0.72, 0.95)
		card.z_index = 1 if chosen else 0
		card.set_highlighted(chosen, chosen and destroying)
	_cross.visible = destroying and picked < count
	if _cross.visible:
		var doomed := _cards[picked]
		_cross.scale = doomed.scale
		_cross.position = doomed.position
		_cross.z_index = 2
	_title.size = Vector2(width, 0.0)
	_title.position = Vector2(centre - width * 0.5, baseline - JokerCard.SIZE.y - 86.0)
	var detail := _detail.get_combined_minimum_size()
	_detail.size = detail
	_detail.position = Vector2(centre - detail.x * 0.5, baseline + 24.0)
	_hints.size = Vector2(width, 0.0)
	_hints.position = Vector2(centre - width * 0.5, baseline + 36.0 + detail.y)


## Rebuilds the row when the offered jokers or the stage change, and leaves it alone otherwise so
## the cards do not flicker while the cursor moves.
func _sync(jokers: Array[Joker], stage: JokerOffer.Stage) -> void:
	var ids: Array[StringName] = []
	for joker: Joker in jokers:
		ids.append(joker.id)
	if ids == _shown and stage == _stage:
		return
	# Clearing first: it resets what is on show, so the new state has to be recorded after it.
	_clear()
	_shown = ids
	_stage = stage
	for joker: Joker in jokers:
		var card := JokerCard.create(joker)
		add_child(card)
		_cards.append(card)


func _clear() -> void:
	for card: JokerCard in _cards:
		card.queue_free()
	_cards.clear()
	_shown = []
	_stage = JokerOffer.Stage.DONE


func _describe(joker: Joker) -> String:
	return (
		"[b]%s[/b]  [color=#%s]%s[/color]\n%s"
		% [
			joker.display_name,
			JokerCard.kind_color(joker).to_html(false),
			JokerCard.kind_name(joker),
			joker.description,
		]
	)


func _hint_text(choosing: bool) -> String:
	var left := InputActions.short_binding_text(InputActions.STEER_LEFT, keyboard)
	var right := InputActions.short_binding_text(InputActions.STEER_RIGHT, keyboard)
	var take := InputActions.short_binding_text(InputActions.USE_ITEM, keyboard)
	var back := InputActions.short_binding_text(InputActions.JOKER_DESTROY, keyboard)
	return (
		"%s / %s choose    %s %s    %s %s"
		% [
			left,
			right,
			take,
			"take" if choosing else "destroy",
			back,
			"skip" if choosing else "back"
		]
	)
