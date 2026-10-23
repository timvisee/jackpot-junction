class_name JokerPicker
extends Control
## The respawn joker choice, GAME.md 3.7, as a row of cards in the middle of the screen. The card
## under the cursor lifts, grows and lights up, with a [JokerDetail] pane underneath saying what
## it does: the same pane the hand shows for a lifted card, so reading about a joker reads the
## same wherever the player is doing it. A player holding five jokers gets the same row again, this
## time of their own cards, to choose one to give up for the new one; that card wears a red frame,
## with the new card floated over it and a swap arrow between, so a replace reads as a trade rather
## than a plain destroy. Sharing the screen, with no room over the row, a red cross stands over the
## card in the floated card's place.
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
## A soft dark oval drawn behind the cards, so a pick reads against the room rather than straight
## into it, the way a made hand is called on one, see [HandFanfare]: how dark it is at its middle,
## and how far past the row of cards it reaches, across and down, as a share of one card.
const BACKDROP_DARK := 0.84
const BACKDROP_MARGIN := Vector2(1.05, 0.85)
## Giving up a held joker for the new one, GAME.md 3.7: the new card floats over the doomed one,
## which keeps its red frame, with a swap arrow between them, so the trade is plain rather than a
## plain destroy. How big the new card is drawn against a card in the row, how far its foot stands
## above the doomed card's top (the arrow is bigger than this, so it laps onto both a little), how
## tall the arrow is, and how far down the row drops in this step to make the room, as a share of
## its share of the screen's height.
const SWAP_SCALE := 0.62
const SWAP_RISE := 10.0
const SWAP_ARROW := 44.0
const REPLACE_BASELINE := 0.64
## The trash can drawn over the doomed card, so what the new one costs is named on the card itself,
## how big against the card it covers.
const TRASH_SIZE := 50.0
## The gap kept between the title and the top of the highest thing under it, the lifted card or the
## card coming in, so the title clears them rather than sitting across their top.
const TITLE_GAP := 12.0
## Sharing the screen, GAME.md 8.3: a pick in the middle of one player's half is a wall across the
## arena for everybody else on this screen, who are still driving in it. With somebody else here
## the row shrinks and goes down to the foot of its own share, where the hand of jokers was, which
## steps aside for it, and the pane describing the card stands beside the cards rather than over
## them, so the whole pick is a strip along the bottom edge and the camera keeps the karts clear of
## it, see [ClearView]; where the strip is wider than the share, the pane stands over the cards.
## Alone on the screen the pick keeps the middle: the one watching is the one picking.
const SHARED_SCALE := 0.72
const SHARED_BASELINE := 0.82
const LONE_BASELINE := 0.52
## The strip, sharing: the room between its cards and its pane, and under its cards, for the small
## print; and the least its cards shrink to for the pane to stand beside them rather than over them.
const STRIP_GAP := 24.0
const STRIP_FOOT := 34.0
const STRIP_LEAST := 0.5
## And the narrowest the pane's words are set for it to stand there, see
## [method JokerDetail.set_width].
const PANE_LEAST := 260.0
## How thick the bars of the destroy cross are, and how far they reach over the card.
const CROSS_WIDTH := 11.0
const CROSS_REACH := 0.82
## The least room kept over the title for the timer at the top of the screen, when the pick moves
## up to keep clear of the hand, see [member floor_y], and the least its cards shrink to when
## moving up is not enough on its own.
const TOP_ROOM := 64.0
const NARROWEST := 0.7
## The most of its share of the screen's width a row of cards takes, the card picked out included.
const ACROSS := 0.9
## How much room the title takes over the cards of a pick in a top corner, see [member corner].
const HUNG_TITLE := 52.0
## The skip button on a touch screen: how big its words and its key are, and how much room it
## leaves round them.
const SKIP_SIZE := Type.LARGE
const SKIP_PAD := 22.0
## Off a touch screen skipping is a chip at the end of the pane's hint row, GAME.md 8.3: its key and
## its word in a thin frame of their own, brighter than the hints so a pick plainly can be turned
## down, and washed in gold as the mouse comes over it. The room round its words, its ink, its
## frame and its wash.
const CHIP_PAD := Vector2(7.0, 2.0)
const CHIP_INK := Color(0.9, 0.9, 0.94)
const CHIP_EDGE := Color(0.62, 0.62, 0.68, 0.6)
const CHIP_LIT := Color(1.0, 0.86, 0.5, 0.2)
## How far over the hand of cards a pick alone on the screen stands, the hand tucked under it.
const FLOOR_GAP := 14.0
## The House's small print under the cards, STORY.md 6.3: how big it is, how far under the row it
## sits, and how long TERMS ACCEPTED stays as a taken card flies into the hand before it fades.
const TERMS_SIZE := 13
## How tall the pencil tick under a pick of one of Kit's cards is.
const TICK_SIZE := 32.0
const TERMS_UNDER := 8.0
const ACCEPTED_HOLD := 0.55
const ACCEPTED_FADE := 0.35
## How a fresh pick's cards are dealt, GAME.md 3.7: face down in the card back of 8.9, and turned
## over one after another inside the half second nothing can be taken anyway, see [constant
## JokerOffer.SETTLE], so the wait looks like a deal rather than a delay: the first this long after
## the pick comes up, the last this much later, each taking this long to turn.
const DEAL_FIRST := 0.04
const DEAL_SPREAD := 0.18
const DEAL_TURN := 0.24

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
## Whether the player is holding the key for a card's details, GAME.md 8.3.
var details := false
## With no card picked out and no pane, while the player is reading their own hand instead on a
## touch screen, GAME.md 4.2: the pane being read is the hand's, and one card of each lifted at
## once is two things asking to be read. The title and the button under the row stay.
var quiet := false
## Whether the player is holding their hand of cards open over the pick to read it, GAME.md 3.7:
## the pick steps aside, and is back as the hand is let go. Not on a touch screen, where a finger
## on the hand reads it under the pick, see [member quiet].
var aside := false
## How far down the pick may reach, 0 for the bottom of its share: the top of the hand of cards
## under it on a touch screen, where it has a button under its pane, GAME.md 4.2. Alone on the
## screen it moves up to stay above that, as far as the top of the screen lets it.
var floor_y := 0.0

var _title: Label
## The House's line under the cards, and the offer it was last shown for, to know a card was taken
## as the pick goes, STORY.md 6.3.
var _terms: Label
var _watching: JokerOffer
var _cards: Array[JokerCard] = []
var _detail: JokerDetail
var _cross: Control
## The soft dark oval behind the cards, see [constant BACKDROP_DARK].
var _backdrop: TextureRect
## The new joker floated over the doomed card while replacing, and the swap arrow between them, see
## [constant SWAP_SCALE]. The id it is drawn for, so it is built again only when that changes.
var _incoming: JokerCard
var _swap: Control
## The trash can over the doomed card, see [constant TRASH_SIZE].
var _trash: Control
## Whether the swap arrow is shown on the card under the cursor on its own, a full hand being about
## to swap if a card is taken, see [method show_offer].
var _swap_hint := false
var _incoming_id := &""
var _shown: Array[StringName] = []
var _stage := JokerOffer.Stage.DONE
## The pick whose cards were last dealt and when, so a pick is dealt once however often its row is
## built again; each card's back while it is face down, and each card's size before it is turned,
## which the row eases toward.
var _dealt_for: JokerOffer
var _dealt_at := 0.0
## Whether the pick was last laid out as a strip along the foot of the screen, in the hand's place.
var _strip := false
## Whether this pick has the hand under it tucked into the bottom edge, see [method share_with].
var _tucked_hand := false
## The pane's hint lines and the row of hints the skip chip ends, see [method _with_chip].
var _hint_lines: VBoxContainer
var _hint_top: HBoxContainer
var _backs: Array[CardBack] = []
var _sizes: Array[Vector2] = []
## Skip or back, while there is either to do, GAME.md 8.3: a word on a touch screen, and the key
## or the pad's button that does it with the word beside it on any other, so nobody has to find
## the small print to know a pick can be turned down. What it was last built for.
var _skip_button: Button
var _skip_shown := ""
## Dealing the card under the cursor again, GAME.md 3.7: a button beside Skip on a touch screen, and
## a key in the pane's hints on any other, while the pick has a reroll to pay for. The card dealt
## again turns over from its back by itself, at [member _respun_at].
var _reroll_button: Button
var _respun := -1
var _respun_at := 0.0
var _respun_back: CardBack
## What the pane's hint row says now, so it is built again only when that changes: the HUD shows
## the offer every frame.
var _hints_shown := ""
## The card under the cursor last told to a screen reader, and the question it was asked under,
## see [method _tell].
var _told := ""
var _asked := ""


func card_count() -> int:
	return _cards.size()


## Whether the pick is up as a strip in the hand's place, see [constant STRIP_GAP]: the hand steps
## aside for it while it is.
func over_hand() -> bool:
	return visible and _strip


## Whether the pick shares the screen with somebody else's, and so has to keep out of the way of
## the karts they are watching, see [ClearView]. Alone it may take the middle.
func shared() -> bool:
	return columns > 1 or corner >= 0


## [param hand], the hand of cards under the pick, kept clear of it, GAME.md 8.3: a strip has the
## hand's place, and the hand steps aside for it; alone in the middle of the screen the pick stands
## over the hand, which tucks into the bottom edge the way a phone's does, to give it the room.
## Read instead, see [member aside], the hand is back at full size and the pick out of the way. A
## touch screen keeps its own, see [TouchControls]; nothing shows over the [param podium].
func share_with(hand: JokerHand, podium: bool) -> void:
	hand.visible = not podium and not over_hand()
	if TouchInput.enabled or shared():
		return
	# Tucked as the pick comes and back as it goes, and otherwise left as it is.
	if visible != _tucked_hand:
		_tucked_hand = visible
		hand.tucked = visible
	floor_y = hand.reach() - FLOOR_GAP if visible else 0.0


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


## The skip or back button, while it is up, or null: a finger or the mouse presses it through
## [TouchInput.press_back], see [TouchControls] and [MouseJokers].
func skip_button() -> Button:
	return _skip_button if visible and _skip_button.visible else null


func reroll_button() -> Button:
	return _reroll_button if visible and _reroll_button.visible else null


## The skip, back or reroll button at [param point] on the screen, or null.
func button_at(point: Vector2) -> Button:
	for button: Button in [skip_button(), reroll_button()]:
		if button != null and button.get_global_rect().has_point(point):
			return button
	return null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	# Behind the cards and everything else, so it darkens the room under the pick and nothing of the
	# pick itself. Laid out over the row each frame, see [method _layout].
	_backdrop = TextureRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.texture = _backdrop_shade()
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.z_index = -1
	_backdrop.visible = false
	add_child(_backdrop)
	_title = Label.new()
	Type.set_font(_title, Type.display_font(), Type.HEADING)
	# A heading in the house's foil capitals, as every heading is, GAME.md 8.1a.
	_title.uppercase = true
	_title.add_theme_color_override("font_color", HouseTheme.FOIL)
	HudText.shadowed(_title, 2)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Over the cards rather than under them, though it is laid out to clear the lifted card and the
	# card coming in, see [method _layout]: on top so a card gliding into place never crosses it.
	_title.z_index = 3
	add_child(_title)
	_terms = _small_print()
	_terms.name = "Terms"
	add_child(_terms)
	_detail = JokerDetail.new()
	_detail.name = "Detail"
	add_child(_detail)
	_build_cross()
	# The swap arrow between the new card and the doomed one, drawn rather than set in a glyph the
	# house font may not carry, see [method _draw_swap]. Over the cards, as the cross is.
	_swap = Control.new()
	_swap.name = "SwapArrow"
	_swap.size = Vector2(SWAP_ARROW, SWAP_ARROW)
	_swap.pivot_offset = _swap.size * 0.5
	_swap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swap.z_index = 3
	_swap.visible = false
	_swap.draw.connect(func() -> void: SwapMarks.draw_arrow(_swap))
	add_child(_swap)
	# A trash can over the doomed card, so what the new one costs is named on the card itself.
	_trash = Control.new()
	_trash.name = "TrashMark"
	_trash.size = Vector2(TRASH_SIZE, TRASH_SIZE)
	_trash.pivot_offset = _trash.size * 0.5
	_trash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trash.z_index = 3
	_trash.visible = false
	_trash.draw.connect(func() -> void: SwapMarks.draw_trash(_trash))
	add_child(_trash)
	# Drawn as a button and pressed by [TouchControls], which answers every finger on the screen
	# on its own; left to the mouse the engine makes of the first finger, it would not answer a
	# second one while a thumb is resting on the stick. A real mouse lights it up as it passes
	# over, and its click is [MouseJokers]'s, as a click on a card is. Off a touch screen it is a
	# chip in the pane's hint row rather than a button of its own, see [method _with_chip].
	_skip_button = MenuTheme.button("Skip") if TouchInput.enabled else _chip()
	_skip_button.name = "Skip"
	_skip_button.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE if TouchInput.enabled else Control.MOUSE_FILTER_STOP
	)
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.visible = false
	add_child(_skip_button)
	_reroll_button = MenuTheme.button("Reroll  -%d" % JokerOffer.REROLL_COST)
	_reroll_button.name = "Reroll"
	_reroll_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reroll_button.focus_mode = Control.FOCUS_NONE
	_reroll_button.visible = false
	add_child(_reroll_button)


## Shows the offer for one slot, or hides the picker when there is nothing to choose.
func show_offer(offer: JokerOffer, kart: Kart) -> void:
	if offer == null or offer.is_done():
		if visible and _watching != null and _watching.is_done() and _watching.taken != null:
			_accepted(_watching.taken)
		_watching = null
		visible = false
		_clear()
		return
	aside = not TouchInput.enabled and kart != null and kart.menu_open and kart.jokers.count() > 0
	visible = not aside
	_watching = offer
	_terms.text = terms_line()
	_terms.visible = not _terms.text.is_empty()
	var choosing := offer.stage == JokerOffer.Stage.CHOOSING
	var jokers: Array[Joker] = offer.choices if choosing else kart.jokers.jokers
	_sync(jokers, offer.stage)
	if choosing and not offer.keeping and offer != _dealt_for:
		_dealt_for = offer
		_deal()
	var picked := clampi(offer.selected, 0, maxi(_cards.size() - 1, 0)) if not quiet else -1
	_detail.visible = not quiet
	# A full hand says so in the title, GAME.md 3.7, so a pick that will cost a held joker is never a
	# surprise: picking one here moves on to choosing which of the five it takes the place of.
	var full := choosing and not offer.keeping and kart != null and kart.jokers.is_full()
	_swap_hint = full
	if choosing:
		if offer.keeping:
			_title.text = "Keep which joker for this map?"
		else:
			_title.text = "Pick a joker to swap in" if full else "Pick a joker"
	else:
		_title.text = "Replace which joker with %s?" % offer.chosen.display_name
	_show_incoming(offer.chosen if not choosing else null)
	# Skipping a keep keeps nothing of last map's, GAME.md 9.7.
	_skip_button.visible = true
	var rerolls := choosing and offer.can_reroll()
	_reroll_button.visible = rerolls and TouchInput.enabled
	_dress_skip("Skip" if choosing else "Back")
	if picked >= 0 and picked < jokers.size():
		var held := kart.jokers.ids().count(jokers[picked].id)
		_detail.show_joker(jokers[picked], held, choosing, details)
		_tell(jokers, picked, held + 1 if choosing else held)
		var actions: Array[StringName] = [
			InputActions.STEER_LEFT,
			InputActions.STEER_RIGHT,
			InputActions.FIRE,
			InputActions.JOKER_DESTROY,
			InputActions.JOKER_MENU,
			InputActions.NITRO,
		]
		var hand := kart.jokers.count() > 0
		var wanted := (
			"%s|%s|%s|%s|%s|%s|%s"
			% [
				TouchInput.enabled,
				choosing,
				offer.keeping,
				hand,
				rerolls,
				_skip_shown,
				InputHint.stamp(actions, keyboard)
			]
		)
		if wanted != _hints_shown:
			_hints_shown = wanted
			if TouchInput.enabled:
				_detail.set_hints(_touch_row(choosing, offer.keeping))
			else:
				_detail.set_hints(_with_chip(_hint_row(choosing, offer.keeping, hand, rerolls)))
	_layout(picked)


## Tells a screen reader of the card under the cursor as it comes to it, see [ScreenReader]: the
## question first where it is a new one, then which card of how many it is, its name and its words
## for [param copies]. Nothing takes the cursor here: the seat's own controls move along the row.
func _tell(jokers: Array[Joker], picked: int, copies: int) -> void:
	var key := "%s|%d|%s|%d" % [_title.text, picked, jokers[picked].id, copies]
	if key == _told:
		return
	_told = key
	var asked := _title.text if _title.text != _asked else ""
	_asked = _title.text
	var place := "%d of %d" % [picked + 1, jokers.size()]
	var joker := jokers[picked]
	var said := PackedStringArray([asked, place, joker.display_name, JokerCard.told(joker, copies)])
	ScreenReader.say(self, ScreenReader.line(said))


## Puts [param word] on the skip button, with the key or the pad's button for it in front of it
## off a touch screen, built again only when either changes.
func _dress_skip(word: String) -> void:
	var stamp := (
		"%s|%s|%s"
		% [word, TouchInput.enabled, InputHint.stamp([InputActions.JOKER_DESTROY], keyboard)]
	)
	if stamp == _skip_shown:
		return
	_skip_shown = stamp
	for old: Node in _skip_button.get_children():
		if old.name == "Keys":
			_skip_button.remove_child(old)
			old.queue_free()
	if not TouchInput.enabled:
		_dress_chip(word)
		return
	var least := MenuTheme.button_size()
	_skip_button.custom_minimum_size = least
	var key := InputHint.glyph(InputActions.JOKER_DESTROY, keyboard, Palette.CHIP_WHITE, SKIP_SIZE)
	if TouchInput.enabled or key == null:
		_skip_button.text = word
		return
	_skip_button.text = ""
	var row := InputHint.row("%s " + word, [key], Palette.CHIP_WHITE, SKIP_SIZE)
	row.name = "Keys"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_button.add_child(row)
	var inside := row.get_combined_minimum_size()
	_skip_button.custom_minimum_size = least.max(inside + Vector2(SKIP_PAD * 2.0, SKIP_PAD))
	row.size = inside
	row.position = (_skip_button.custom_minimum_size - inside) * 0.5


## The skip chip off a touch screen, see [constant CHIP_PAD]: a flat button, nothing round it until
## the mouse comes over it.
static func _chip() -> Button:
	var chip := Button.new()
	var plain := StyleBoxFlat.new()
	plain.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	plain.border_color = CHIP_EDGE
	plain.set_border_width_all(1)
	plain.set_corner_radius_all(5)
	var lit := plain.duplicate() as StyleBoxFlat
	lit.bg_color = CHIP_LIT
	lit.border_color = Color(HouseTheme.FOIL, 0.8)
	for state: StringName in [&"normal", &"focus", &"disabled"]:
		chip.add_theme_stylebox_override(state, plain)
	for state: StringName in [&"hover", &"pressed", &"hover_pressed"]:
		chip.add_theme_stylebox_override(state, lit)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return chip


## The chip's key and [param word], as small as the hints beside it and a little brighter.
func _dress_chip(word: String) -> void:
	_skip_button.text = ""
	var ink := CHIP_INK
	var size := InputHint.FONT_SIZE
	var key := InputHint.glyph(InputActions.JOKER_DESTROY, keyboard, ink, size)
	var parts: Array = [key] if key != null else []
	var template := ("%s " if key != null else "") + word.to_lower()
	var row := InputHint.row(template, parts, ink, size)
	row.name = "Keys"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_button.add_child(row)
	var inside := row.get_combined_minimum_size()
	_skip_button.custom_minimum_size = inside + CHIP_PAD * 2.0
	row.size = inside
	row.position = CHIP_PAD


## [param hints] with the skip chip at the far end of their row, taken off the row it was on.
func _with_chip(hints: Control) -> Control:
	_hint_lines = VBoxContainer.new()
	_hint_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_lines.add_theme_constant_override("separation", 2)
	_hint_top = HBoxContainer.new()
	_hint_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_top.add_child(hints)
	var spare := Control.new()
	spare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spare.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_top.add_child(spare)
	_hint_lines.add_child(_hint_top)
	var held := _skip_button.get_parent()
	if held != null:
		held.remove_child(_skip_button)
	_hint_top.add_child(_skip_button)
	return _hint_lines


## The skip chip at the end of the row of hints, or with [param below] on a line of its own under
## it, at its far end: a pane narrowed to stand beside its cards has no room for both on one line.
func _chip_below(below: bool) -> void:
	if not is_instance_valid(_hint_lines) or TouchInput.enabled:
		return
	var into: Container = _hint_lines if below else _hint_top
	var held := _skip_button.get_parent()
	if held == into:
		return
	if held != null:
		held.remove_child(_skip_button)
	into.add_child(_skip_button)
	_skip_button.size_flags_horizontal = (Control.SIZE_SHRINK_END if below else Control.SIZE_FILL)


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


## The soft dark oval behind the cards, see [constant BACKDROP_DARK]: black at its middle, fading
## out to nothing at its rim, the same half disc a made hand is called on, see [HandFanfare].
static func _backdrop_shade() -> GradientTexture2D:
	var fade := GradientTexture2D.new()
	fade.fill = GradientTexture2D.FILL_RADIAL
	fade.fill_from = Vector2(0.5, 0.5)
	fade.fill_to = Vector2(1.0, 0.5)
	fade.width = 256
	fade.height = 256
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.0, 0.0, 0.0, BACKDROP_DARK))
	ramp.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	ramp.add_point(0.55, Color(0.0, 0.0, 0.0, BACKDROP_DARK * 0.82))
	fade.gradient = ramp
	return fade


## Keeps the card floated over the doomed one showing [param joker], the new one coming in, or lets
## go of it and the swap arrow when there is none, see [constant SWAP_SCALE]. Placed in
## [method _layout]; built again only when the joker coming in changes.
func _show_incoming(joker: Joker) -> void:
	if joker == null:
		if _incoming != null:
			_incoming.visible = false
		_swap.visible = false
		_incoming_id = &""
		return
	if _incoming != null and _incoming_id == joker.id:
		return
	if _incoming != null:
		_incoming.queue_free()
	_incoming = JokerCard.create(joker)
	_incoming.name = "Incoming"
	_incoming.bakes = true
	_incoming.z_index = 2
	_incoming.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_incoming)
	_incoming_id = joker.id


func _layout(picked: int) -> void:
	var count := _cards.size()
	var destroying := _stage == JokerOffer.Stage.REPLACING
	var shared := columns > 1
	var factor := SHARED_SCALE if shared else 1.0
	# Alone, the row drops lower while replacing to make room over it for the card coming in.
	var lone_base := REPLACE_BASELINE if destroying else LONE_BASELINE
	var baseline := size.y * (SHARED_BASELINE if shared else lone_base)
	var detail := _detail.get_combined_minimum_size()
	# Off a touch screen the button is in the pane, see [method _with_chip].
	var button := _skip_button.get_combined_minimum_size()
	if not TouchInput.enabled:
		button = Vector2.ZERO
	if not shared and floor_y > 0.0:
		var under := 24.0 + detail.y + (18.0 + button.y if button.y > 0.0 else 0.0)
		var tall := floor_y - under - 86.0 - TOP_ROOM
		factor = clampf(tall / JokerCard.SIZE.y, NARROWEST, factor)
		var highest := JokerCard.SIZE.y * factor + 86.0 + TOP_ROOM
		baseline = clampf(floor_y - under, minf(highest, baseline), baseline)
	var width := size.x / columns
	var center := width * (column + 0.5)
	if corner >= 0:
		width = lane.y - lane.x
		center = (lane.x + lane.y) * 0.5
	# A long row, two Wild Cards' seven, shrinks to fit across its share of the screen.
	var across := JokerCard.SIZE.x * count + GAP * maxf(count - 1, 0.0)
	if across > 0.0:
		factor = minf(factor, width * ACROSS / across)
	var hangs := corner == 0 or corner == 1
	_strip = columns > 1 and corner < 0
	if _strip:
		factor = minf(factor, SHARED_SCALE)
		baseline = size.y - STRIP_FOOT
	# The pane beside the cards where there is room for it, the cards a little smaller for it if
	# need be and its words a little narrower, and over them where not.
	_detail.set_width(JokerDetail.WIDTH)
	_chip_below(false)
	detail = _detail.get_combined_minimum_size()
	if _strip and across > 0.0:
		var room := (
			width * ACROSS - STRIP_GAP - across * STRIP_LEAST - (detail.x - JokerDetail.WIDTH)
		)
		if room < JokerDetail.WIDTH and room >= PANE_LEAST:
			_chip_below(true)
			_detail.set_width(room)
			detail = _detail.get_combined_minimum_size()
	var row_room := width * ACROSS - STRIP_GAP - detail.x
	var pane_beside := _strip and across > 0.0 and row_room / across >= STRIP_LEAST
	if pane_beside:
		factor = minf(factor, row_room / across)
	var strip_wide := across * factor + STRIP_GAP + detail.x
	var card_size := JokerCard.SIZE * factor
	var gap := GAP * factor
	if hangs:
		baseline = ceiling_y + HUNG_TITLE + LIFT * factor + card_size.y
	var row := card_size.x * count + gap * maxf(count - 1, 0.0)
	var left := center - row * 0.5
	if _strip and pane_beside:
		left = center - strip_wide * 0.5
	for i: int in count:
		var card := _cards[i]
		var chosen := i == picked
		var anchor := Vector2(
			left + (card_size.x + gap) * i + card_size.x * 0.5,
			baseline - (LIFT * factor if chosen else 0.0)
		)
		var scale_to := factor * (PICKED_SCALE if chosen else 1.0)
		_sizes[i] = _sizes[i].lerp(Vector2.ONE * scale_to, 0.4)
		card.scale = Vector2(_sizes[i].x * _turned(i, count), _sizes[i].y)
		# The pivot is the card's bottom center, so scaling already happens about that point and
		# the offset must not be scaled again. Scaling it moved the picked card left by half of
		# what it had grown by, which is the sideways drift on a row that is otherwise straight.
		card.position = anchor - card.pivot_offset
		# With none picked out none is set back behind another.
		var lit := chosen or picked < 0
		card.modulate = Color.WHITE if lit else Color(0.66, 0.66, 0.72, 0.95)
		card.z_index = 1 if chosen else 0
		card.set_highlighted(chosen, chosen and destroying)
	# The dark oval under the row, a share of a card past it on every side, centered on the middle
	# of a card's height so it reaches up toward the title and down past the feet of the cards.
	_backdrop.visible = count > 0
	if _backdrop.visible:
		var half := Vector2(
			row * 0.5 + card_size.x * BACKDROP_MARGIN.x, card_size.y * (0.5 + BACKDROP_MARGIN.y)
		)
		_backdrop.size = half * 2.0
		_backdrop.position = Vector2(center, baseline - card_size.y * 0.5) - half
	# The card coming in floats over the doomed one, a swap arrow in the gap between, so a replace
	# reads as a trade rather than a plain destroy; in the strip, GAME.md 8.3, there is no room over
	# the row for it, so the red cross stands in its place there.
	var doomed_shown := destroying and picked >= 0 and picked < count
	var swapping := doomed_shown and not _strip and _incoming != null
	_cross.visible = doomed_shown and not swapping
	if _cross.visible:
		var doomed := _cards[picked]
		_cross.scale = doomed.scale
		_cross.position = doomed.position
		_cross.z_index = 2
	if _incoming != null:
		_incoming.visible = swapping
	_trash.visible = swapping
	# With a full hand and nothing picked out yet, the card under the cursor wears the swap arrow on
	# its own, GAME.md 3.7, so it is plain a pick here trades a held joker away before one is taken.
	var hinting := _swap_hint and not swapping and picked >= 0 and picked < count
	_swap.visible = swapping or hinting
	var picked_x := left + (card_size.x + gap) * picked + card_size.x * 0.5
	if swapping:
		var doomed_top := baseline - LIFT * factor - card_size.y * PICKED_SCALE
		var in_foot := doomed_top - SWAP_RISE * factor
		_incoming.scale = Vector2.ONE * factor * SWAP_SCALE
		_incoming.position = Vector2(picked_x, in_foot) - _incoming.pivot_offset
		_swap.scale = Vector2.ONE * factor
		_swap.position = Vector2(picked_x, (doomed_top + in_foot) * 0.5) - _swap.pivot_offset
		_swap.queue_redraw()
		_trash.scale = Vector2.ONE * factor
		_trash.position = (
			Vector2(picked_x, doomed_top + card_size.y * PICKED_SCALE * 0.5) - _trash.pivot_offset
		)
		_trash.queue_redraw()
	elif hinting:
		var middle_y := baseline - LIFT * factor - card_size.y * PICKED_SCALE * 0.5
		_swap.scale = Vector2.ONE * factor
		_swap.position = Vector2(picked_x, middle_y) - _swap.pivot_offset
		_swap.queue_redraw()
	_detail.size = detail
	if _strip:
		_lay_strip(left, row, baseline, card_size, detail, pane_beside)
		return
	# Sharing, everything stacks upward off the bottom of the column; alone, the pane hangs under
	# the cards, a little lower when there is a line of small print to keep over it, STORY.md 6.3.
	var terms_tall := _terms.get_combined_minimum_size().y if _terms.visible else 0.0
	var pane_drop := TERMS_UNDER + terms_tall + 12.0 if _terms.visible else 24.0
	var pane_y := baseline - card_size.y - detail.y - 16.0 if shared else baseline + pane_drop
	if hangs:
		pane_y = baseline + pane_drop
	_detail.position = Vector2(center - detail.x * 0.5, pane_y)
	_title.size = Vector2(width, 0.0)
	# The title clears the top of the highest thing under it rather than sitting across it: the
	# lifted card, or the card coming in over it while replacing, see [constant TITLE_GAP].
	var title_tall := _title.get_combined_minimum_size().y
	var over := baseline - LIFT * factor - card_size.y * PICKED_SCALE
	if swapping:
		over -= SWAP_RISE * factor + card_size.y * SWAP_SCALE
	var title_y := pane_y - 52.0 if shared else over - TITLE_GAP - title_tall
	if hangs:
		title_y = ceiling_y
	_title.position = Vector2(center - width * 0.5, title_y)
	# The House's line under the cards, in the room kept for it over the pane, STORY.md 6.3.
	_terms.size = Vector2(width, 0.0)
	_terms.position = Vector2(center - width * 0.5, baseline + TERMS_UNDER)
	if _skip_button.visible and button.y > 0.0:
		_skip_button.size = button
		var below := pane_y + detail.y + 18.0
		_skip_button.position = Vector2(center - button.x * 0.5, below)
		# The reroll beside it, toward the cards' start.
		var reroll := _reroll_button.get_combined_minimum_size()
		_reroll_button.size = reroll
		_reroll_button.position = _skip_button.position - Vector2(reroll.x + 12.0, 0.0)


## The strip's pane, title and small print, see [constant STRIP_GAP], round its row of cards
## [param row] wide from [param left] standing on [param baseline]: the pane beside the row, its
## foot on the cards' line; the title over the row, clear of a card lifted out of it; and the small
## print under it. With no room for the pane [param pane_beside] the cards, it stands over them,
## the title over it.
func _lay_strip(
	left: float, row: float, baseline: float, card_size: Vector2, detail: Vector2, pane_beside: bool
) -> void:
	var title_tall := _title.get_combined_minimum_size().y
	_terms.size = Vector2(row, 0.0)
	_terms.position = Vector2(left, baseline + TERMS_UNDER)
	var risen := card_size.y * PICKED_SCALE + LIFT * card_size.y / JokerCard.SIZE.y
	if not pane_beside:
		# Over the card lifted out of the row, so it covers none of the pane's hints.
		var pane := Vector2(left + (row - detail.x) * 0.5, baseline - risen - detail.y - 8.0)
		_detail.position = pane
		_title.size = Vector2(detail.x, 0.0)
		_title.position = Vector2(pane.x, pane.y - title_tall - 6.0)
		return
	var pane_x := left + row + STRIP_GAP
	_detail.position = Vector2(pane_x, baseline - detail.y)
	_title.size = Vector2(row, 0.0)
	_title.position = Vector2(left, baseline - risen - title_tall)


## Rebuilds the row when the offered jokers or the stage change, and leaves it alone otherwise so
## the cards do not flicker while the cursor moves.
func _sync(jokers: Array[Joker], stage: JokerOffer.Stage) -> void:
	var ids: Array[StringName] = []
	for joker: Joker in jokers:
		ids.append(joker.id)
	if ids == _shown and stage == _stage:
		return
	# One card changed in a row otherwise the same is a card dealt again, GAME.md 3.7.
	var respun := -1
	if stage == _stage and ids.size() == _shown.size():
		for i: int in ids.size():
			if ids[i] != _shown[i]:
				respun = i if respun < 0 else -2
	# Clearing first: it resets what is on show, so the new state has to be recorded after it.
	var dealt := _backs.duplicate()
	var dealt_sizes := _sizes.duplicate()
	_clear()
	_shown = ids
	_stage = stage
	for joker: Joker in jokers:
		var card := JokerCard.create(joker)
		card.bakes = true
		add_child(card)
		_cards.append(card)
		_sizes.append(Vector2.ONE)
	if respun >= 0:
		_sizes.assign(dealt_sizes)
		_backs.resize(dealt.size())
		_respun = respun
		_respun_at = Time.get_ticks_msec() * 0.001
		_respun_back = CardBack.new()
		_respun_back.name = "Back"
		_cards[respun].add_child(_respun_back)


## Lays the row's cards face down, to be turned over one after another, see [constant DEAL_TURN].
func _deal() -> void:
	_dealt_at = Time.get_ticks_msec() * 0.001
	_backs.clear()
	for card: JokerCard in _cards:
		var back := CardBack.new()
		back.name = "Back"
		card.add_child(back)
		_backs.append(back)


## How much of card [param index] of [param count] shows across as it is turned over: all of it once
## it has been, none of it edge-on half way, its back showing until then.
func _turned(index: int, count: int) -> float:
	if index == _respun and is_instance_valid(_respun_back):
		var spun := clampf((Time.get_ticks_msec() * 0.001 - _respun_at) / DEAL_TURN, 0.0, 1.0)
		_respun_back.visible = spun < 0.5
		return maxf(absf(cos(spun * PI)), 0.02)
	if index >= _backs.size() or _backs[index] == null:
		return 1.0
	var start := DEAL_FIRST + DEAL_SPREAD * float(index) / float(maxi(count - 1, 1))
	var now := Time.get_ticks_msec() * 0.001
	var angle := clampf((now - _dealt_at - start) / DEAL_TURN, 0.0, 1.0) * PI
	_backs[index].visible = angle < PI * 0.5
	return maxf(absf(cos(angle)), 0.02)


func _clear() -> void:
	for card: JokerCard in _cards:
		card.queue_free()
	_cards.clear()
	_backs.clear()
	_sizes.clear()
	_shown = []
	_stage = JokerOffer.Stage.DONE
	_respun = -1
	_told = ""
	_asked = ""


## The House's line under the cards for the stage this machine shows, STORY.md 6.3: nothing at the
## first stage, the candidate's terms at the Final Hand.
static func terms_line() -> String:
	if Story.final_hand_on:
		return StoryLines.PICK_FINAL_HAND
	var line: String = StoryLines.at(StoryLines.PICK, Story.stage_here())
	return StoryFill.fill(line, Game.settings.profile)


## A line of the House's small print, in its foil, as the line under the cards is drawn.
func _small_print() -> Label:
	var line := Label.new()
	Type.set_font(line, Type.micro_font(), TERMS_SIZE)
	line.add_theme_color_override("font_color", HouseTheme.FOIL)
	HudText.shadowed(line, 2)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = 3
	line.visible = false
	return line


## A card has just been taken: from the second stage the line under the cards says TERMS ACCEPTED
## where it was, for as long as the card flies into the hand, and fades, STORY.md 6.3; for one of
## Kit's cards, which is no term, a tick in Kit's pencil instead. It is hung off whatever holds the
## pick, since the pick itself goes the moment the card is taken.
## The tick in Kit's pencil on [param on], in the middle of it: two strokes, the second the longer,
## pressed a little harder where they meet.
func _draw_tick(on: Control) -> void:
	var middle := Vector2(on.size.x * 0.5, TICK_SIZE * 0.5)
	var short := PackedVector2Array(
		[middle + Vector2(-14.0, -2.0), middle + Vector2(-8.0, 4.0), middle + Vector2(-3.0, 10.0)]
	)
	var long := PackedVector2Array(
		[middle + Vector2(-3.0, 10.0), middle + Vector2(6.0, -4.0), middle + Vector2(17.0, -15.0)]
	)
	on.draw_polyline(short, KitCards.PENCIL_LIGHT, 2.6, true)
	on.draw_polyline(long, KitCards.PENCIL_LIGHT, 2.2, true)


func _accepted(taken: Joker) -> void:
	var kit := taken != null and taken.contraband
	var stage := Story.stage_here()
	if stage < StoryLines.TERMS_ACCEPTED_FROM and not Story.final_hand_on and not kit:
		return
	var holder := get_parent()
	if holder == null:
		return
	var said := _small_print()
	said.name = "TermsAccepted"
	said.text = StoryLines.TERMS_ACCEPTED
	if kit:
		said.name = "KitTick"
		said.text = ""
		said.custom_minimum_size.y = TICK_SIZE
		said.draw.connect(_draw_tick.bind(said))
	said.visible = true
	holder.add_child(said)
	said.size = _terms.size
	said.global_position = _terms.global_position
	var fade := said.create_tween()
	fade.tween_interval(ACCEPTED_HOLD)
	fade.tween_property(said, "modulate:a", 0.0, ACCEPTED_FADE)
	fade.tween_callback(said.queue_free)


## What a finger does with the cards, said in place of the buttons, GAME.md 4.2.
func _touch_row(choosing: bool, keeping := false) -> Control:
	var doing := "take" if choosing else "replace"
	if keeping:
		doing = "keep"
	var line := Label.new()
	line.text = "Tap a card to %s it, hold it to read it" % doing
	Type.text(line, InputHint.FONT_SIZE, JokerDetail.hint_ink())
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


## What the player can do from here, drawn as the buttons themselves, GAME.md 8.3.
func _hint_row(choosing: bool, keeping := false, hand := false, rerolls := false) -> Control:
	var ink := JokerDetail.hint_ink()
	var size := InputHint.FONT_SIZE
	var parts: Array = [
		InputHint.pair(InputActions.STEER_LEFT, InputActions.STEER_RIGHT, keyboard, ink, size),
		# Fire takes a card as well as the item button does, and it is the one a player already
		# has a thumb on, so it is the one shown here.
		InputHint.glyph(InputActions.FIRE, keyboard, ink, size),
	]
	# Skipping, or going back, is the chip at the end of the row, with its key on it.
	var template := "%s choose   %s take" if choosing else "%s choose   %s replace"
	if keeping:
		template = "%s choose   %s keep"
	# The hand of cards held open over the pick, to read what is already held, GAME.md 3.7.
	if hand:
		template += "   %s hand"
		parts.append(InputHint.glyph(InputActions.JOKER_MENU, keyboard, ink, size))
	# The card under the cursor dealt again, for its price, GAME.md 3.7.
	if rerolls:
		template += "   %%s reroll -%d" % JokerOffer.REROLL_COST
		parts.append(InputHint.glyph(InputActions.NITRO, keyboard, ink, size))
	return InputHint.row(template, parts, ink, size)
