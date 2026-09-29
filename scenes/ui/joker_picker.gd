class_name JokerPicker
extends Control
## The respawn joker choice, GAME.md 3.7, as a row of cards in the middle of the screen. The card
## under the cursor lifts, grows and lights up, with a [JokerDetail] pane underneath saying what
## it does: the same pane the hand shows for a lifted card, so reading about a joker reads the
## same wherever the player is doing it. A player holding five jokers gets the same row again,
## this time of their own cards, to choose one to destroy; that card wears a red frame and a big
## red cross, so it can never be read as the one being claimed.
##
## Each local player picks inside their own share of the screen, the same share their hand of
## cards uses, so two players choosing at once never overlap.
##
## On a touch screen, GAME.md 4.2, a card is tapped to be taken and held to be read, the pane says
## so in place of naming buttons, and a button under it skips the pick, or goes back from the
## destroying to the choosing. The fingers themselves are answered by [TouchControls].
## A finger gone to the hand of jokers under the pick leaves it [member quiet].

## How far a picked card rises. It was 26 while the growing card was quietly carrying another
## twenty of it, so the number here is now the whole of the lift rather than most of it.
const LIFT := 46.0
const PICKED_SCALE := 1.12
const GAP := 18.0
## Sharing the screen, GAME.md 8.3: a pick in the middle of one player's half is a wall across
## the arena for everybody else, who are still driving in it. With somebody else on this screen
## the row shrinks and drops to the bottom of its own share, and the pane describing the card
## goes above the cards rather than below, so the table stays readable. Alone on the screen
## there is nobody to block and the pick keeps the middle.
const SHARED_SCALE := 0.72
const SHARED_BASELINE := 0.82
const LONE_BASELINE := 0.52
## How thick the bars of the destroy cross are, and how far they reach over the card.
const CROSS_WIDTH := 11.0
const CROSS_REACH := 0.82
## The least room kept over the title for the timer at the top of the screen, when the pick moves
## up to keep clear of the hand, see [member floor_y], and the least its cards shrink to when
## moving up is not enough on its own.
const TOP_ROOM := 64.0
const NARROWEST := 0.7
## How much room the title takes over the cards of a pick in a top corner, see [member corner].
const HUNG_TITLE := 52.0

## This picker takes share [member column] of [member columns] of the screen. With three or four
## players on this screen it keeps to its owner's corner instead, as the hand does, see
## [member JokerHand.corner]: [member lane] is the stretch of the screen it keeps to, from and to,
## and one for a top corner stacks down from [member ceiling_y], under the hand hanging there,
## with its pane under its cards.
var column := 0
var columns := 1
var corner := -1
var lane := Vector2.ZERO
var ceiling_y := 0.0
## Whether the control hints name keys or gamepad buttons.
var keyboard := true
## With no card picked out and no pane, while the player is reading their own hand instead on a
## touch screen, GAME.md 4.2: the pane being read is the hand's, and one card of each lifted at
## once is two things asking to be read. The title and the button under the row stay.
var quiet := false
## How far down the pick may reach, 0 for the bottom of its share: the top of the hand of cards
## under it on a touch screen, where it has a button under its pane, GAME.md 4.2. Alone on the
## screen it moves up to stay above that, as far as the top of the screen lets it.
var floor_y := 0.0

var _title: Label
var _cards: Array[JokerCard] = []
var _detail: JokerDetail
var _cross: Control
var _shown: Array[StringName] = []
var _stage := JokerOffer.Stage.DONE
## Skip or back, on a touch screen, while there is either to do.
var _touch_button: Button
## What the pane's hint row says now, so it is built again only when that changes: the HUD shows
## the offer every frame.
var _hints_shown := ""


func card_count() -> int:
	return _cards.size()


## The card under [param point], in the picker's own coordinates, or -1. The picked card still
## answers where it rose from, so a finger holding it is not left behind as it lifts.
func card_at(point: Vector2) -> int:
	if not visible:
		return -1
	var best := -1
	for i: int in _cards.size():
		var card := _cards[i]
		var face := Rect2(Vector2.ZERO, card.size)
		var under := face.has_point(card.get_transform().affine_inverse() * point)
		if not under and card.z_index > 0:
			var risen := point - Vector2(0.0, LIFT * card.scale.y)
			under = face.has_point(card.get_transform().affine_inverse() * risen)
		if not under:
			continue
		if best < 0 or card.z_index >= _cards[best].z_index:
			best = i
	return best


## The skip or back button of a touch screen, while it is up, or null.
func touch_button() -> Button:
	return _touch_button if visible and _touch_button.visible else null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_title = Label.new()
	Type.set_font(_title, Type.display_font(), Type.HEADING)
	_title.add_theme_color_override("font_color", Palette.CHIP_WHITE)
	HudText.shadowed(_title, 2)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Over the row rather than under it: the lifted card reaches up into the line the title sits
	# on, and a question with a card through the middle of it is a question nobody can read.
	_title.z_index = 3
	add_child(_title)
	_detail = JokerDetail.new()
	_detail.name = "Detail"
	add_child(_detail)
	_build_cross()
	# Drawn as a button and pressed by [TouchControls], which answers every finger on the screen
	# on its own; left to the mouse the engine makes of the first finger, it would not answer a
	# second one while a thumb is resting on the stick.
	_touch_button = MenuTheme.button("Skip")
	_touch_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_button.focus_mode = Control.FOCUS_NONE
	_touch_button.visible = false
	add_child(_touch_button)


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
	var picked := clampi(offer.selected, 0, maxi(_cards.size() - 1, 0)) if not quiet else -1
	_detail.visible = not quiet
	_title.text = (
		("Keep which joker for this map?" if offer.keeping else "Pick a joker")
		if choosing
		else "Destroy which joker for %s?" % offer.chosen.display_name
	)
	if picked >= 0 and picked < jokers.size():
		var held := kart.jokers.ids().count(jokers[picked].id)
		_detail.show_joker(jokers[picked], held, choosing)
		var actions: Array[StringName] = [
			InputActions.STEER_LEFT,
			InputActions.STEER_RIGHT,
			InputActions.FIRE,
			InputActions.JOKER_DESTROY,
		]
		var wanted := (
			"%s|%s|%s|%s"
			% [TouchInput.enabled, choosing, offer.keeping, InputHint.stamp(actions, keyboard)]
		)
		if wanted != _hints_shown:
			_hints_shown = wanted
			if TouchInput.enabled:
				_detail.set_hints(_touch_row(choosing, offer.keeping))
			else:
				_detail.set_hints(_hint_row(choosing, offer.keeping))
	# Keeping one of last map's has nothing to skip to: the rule is keep one.
	_touch_button.visible = TouchInput.enabled and not (choosing and offer.keeping)
	_touch_button.text = "Skip" if choosing else "Back"
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
	var shared := columns > 1
	var factor := SHARED_SCALE if shared else 1.0
	var baseline := size.y * (SHARED_BASELINE if shared else LONE_BASELINE)
	var detail := _detail.get_combined_minimum_size()
	var button := _touch_button.get_combined_minimum_size()
	if not shared and floor_y > 0.0:
		var under := 24.0 + detail.y + (18.0 + button.y if _touch_button.visible else 0.0)
		var tall := floor_y - under - 86.0 - TOP_ROOM
		factor = clampf(tall / JokerCard.SIZE.y, NARROWEST, factor)
		var highest := JokerCard.SIZE.y * factor + 86.0 + TOP_ROOM
		baseline = clampf(floor_y - under, minf(highest, baseline), baseline)
	var card_size := JokerCard.SIZE * factor
	var gap := GAP * factor
	var width := size.x / columns
	var center := width * (column + 0.5)
	if corner >= 0:
		width = lane.y - lane.x
		center = (lane.x + lane.y) * 0.5
	var hangs := corner == 0 or corner == 1
	if hangs:
		baseline = ceiling_y + HUNG_TITLE + LIFT * factor + card_size.y
	var row := card_size.x * count + gap * maxf(count - 1, 0.0)
	var left := center - row * 0.5
	for i: int in count:
		var card := _cards[i]
		var chosen := i == picked
		var anchor := Vector2(
			left + (card_size.x + gap) * i + card_size.x * 0.5,
			baseline - (LIFT * factor if chosen else 0.0)
		)
		var scale_to := factor * (PICKED_SCALE if chosen else 1.0)
		card.scale = card.scale.lerp(Vector2.ONE * scale_to, 0.4)
		# The pivot is the card's bottom center, so scaling already happens about that point and
		# the offset must not be scaled again. Scaling it moved the picked card left by half of
		# what it had grown by, which is the sideways drift on a row that is otherwise straight.
		card.position = anchor - card.pivot_offset
		# With none picked out none is set back behind another.
		var lit := chosen or picked < 0
		card.modulate = Color.WHITE if lit else Color(0.66, 0.66, 0.72, 0.95)
		card.z_index = 1 if chosen else 0
		card.set_highlighted(chosen, chosen and destroying)
	_cross.visible = destroying and picked >= 0 and picked < count
	if _cross.visible:
		var doomed := _cards[picked]
		_cross.scale = doomed.scale
		_cross.position = doomed.position
		_cross.z_index = 2
	_detail.size = detail
	# Sharing, everything stacks upward off the bottom of the column; alone, the pane hangs
	# under the cards where there is room for it.
	var pane_y := baseline - card_size.y - detail.y - 16.0 if shared else baseline + 24.0
	if hangs:
		pane_y = baseline + 24.0
	_detail.position = Vector2(center - detail.x * 0.5, pane_y)
	_title.size = Vector2(width, 0.0)
	var title_y := pane_y - 52.0 if shared else baseline - card_size.y - 86.0
	if hangs:
		title_y = ceiling_y
	_title.position = Vector2(center - width * 0.5, title_y)
	if _touch_button.visible:
		_touch_button.size = button
		var below := pane_y + detail.y + 18.0
		_touch_button.position = Vector2(center - button.x * 0.5, below)


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


## What a finger does with the cards, said in place of the buttons, GAME.md 4.2.
func _touch_row(choosing: bool, keeping := false) -> Control:
	var doing := "take" if choosing else "destroy"
	if keeping:
		doing = "keep"
	var line := Label.new()
	line.text = "Tap a card to %s it, hold it to read it" % doing
	Type.text(line, InputHint.FONT_SIZE, JokerDetail.hint_ink())
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


## What the player can do from here, drawn as the buttons themselves, GAME.md 8.3.
func _hint_row(choosing: bool, keeping := false) -> Control:
	var ink := JokerDetail.hint_ink()
	var size := InputHint.FONT_SIZE
	var parts: Array = [
		InputHint.pair(InputActions.STEER_LEFT, InputActions.STEER_RIGHT, keyboard, ink, size),
		# Fire takes a card as well as the item button does, and it is the one a player already
		# has a thumb on, so it is the one shown here.
		InputHint.glyph(InputActions.FIRE, keyboard, ink, size),
		InputHint.glyph(InputActions.JOKER_DESTROY, keyboard, ink, size),
	]
	var template := (
		"%s choose   %s take   %s skip" if choosing else "%s choose   %s destroy   %s back"
	)
	# Keeping one of last map's is not a card that can be turned down: the rule is keep one.
	if keeping:
		parts.pop_back()
		template = "%s choose   %s keep"
	return InputHint.row(template, parts, ink, size)
