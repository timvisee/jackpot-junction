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
## however many the hand has room for. A hand that makes a hand says so over the count, a little
## card for each suit in it and the hand under them, SUITED or FULL HOUSE, GAME.md 7.3.

## Fraction of a card hidden by the next one.
const OVERLAP := 0.35
const LIFT := 44.0
const MARGIN := 14.0
const GLIDE := 14.0
## How far the middle of a full fan rides above its ends, and how far the end cards tip away.
const ARC := 18.0
const TILT_DEG := 6.0
const DIMMED := Color(0.55, 0.55, 0.6, 0.9)
## A card going off by itself, see [method flash]: how far out of the fan it pulls, as a share of
## the lift of a card being read, how much it grows and how bright it is lit, how long it stays
## out, in seconds, and how much of the end of that it spends going back.
const FLASH_PULL := 1.6
const FLASH_GROW := 1.3
const FLASH := Color(1.3, 1.25, 1.1)
const FLASH_TIME := 1.2
const FLASH_FADE := 0.45
## The word over a card that has gone off, "GUARDED": how big, and how far clear of the card.
const FLASH_WORD_SIZE := 24
const FLASH_WORD_GAP := 8.0
## A card used up, see [method burn]: how long it shakes, framed and lit in red, and then how long
## it takes to drop out of the hand and fade, turning over to the card back worn as it goes, in
## seconds; how much of that drop the turn takes, quick, so the back is seen for the rest of it,
## the fade held back to its end; how far either way it shakes, and how far it drops, as a share
## of its height. A card gone any other way, dropped or swapped, drops and turns the same without
## the shake or the red, see [method _leave].
const BURN_SHAKE := 0.45
const BURN_DROP := 0.8
const BURN_TURN := 0.35
const BURN_WOBBLE := 7.0
const BURN_FALL := 0.9
const BURN := Color(1.35, 0.7, 0.65)
## How big the picture of the joker-menu button beside the hand is drawn.
const CAP_SIZE := 18
## A Copy Cat's card turning to the card it copies and back, GAME.md 7.3: how long it takes to show
## both once, and how long each turn takes, in seconds.
const COPY_CYCLE := 5.0
const COPY_TURN := 0.45
## How far the Suited sign stands from the count, and how much further out than the count it
## starts, clear of the last card's corner tipping toward it.
const SUITED_GAP := 2.0
## The cards of a hand just made lit one after the other: how long after the one before, and how
## long each.
const SHINE_STEP := 0.09
const SHINE_TIME := 0.55
## How far past the sign the pay table of the hands stands, and how long it takes to slide out.
const TABLE_GAP := 24.0
const TABLE_SLIDE := 0.16
## Shared between two seats: how big against one player's own, and how far it keeps from each hand.
const SHARED_TABLE := 0.85
const SHARED_GAP := 12.0
const SUITED_OUT := 10.0
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
## Whether the player is holding the key for a card's details, GAME.md 8.3.
var details := false
## The cards wearing an eye, by id, as still to be read: the tutorial's reading lesson, GAME.md
## 9.4a. Empty for none.
var unread: Array[StringName] = []
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
## How far across the hand's things reach, from and to, see [method _measure_across].
var reach_across := Vector2.ZERO

var _cards: Array[JokerCard] = []
var _ids: Array[StringName] = []
var _detail: JokerDetail
var _cap: Control
## What the cap is currently a picture of, so it is only rebuilt when the button changes.
var _cap_shown := ""
var _count_label: Label
## The Suited sign over the count.
var _suited: SuitedSign
## The pay table of the hands while the hand's key is held, with one seat at the screen.
var _table: HandsTable
## The cards of a hand just made lighting up one after the other, see [method shine_cards]: by
## place in the hand, how long since each began, from below zero while it waits its turn.
var _shine: Dictionary[int, float] = {}
## How far out from the screen's edge the pay table has slid, 0 to 1, and where across it stands.
var _table_out := 0.0
var _table_x := 0.0
## What the pane under a card says on a touch screen, so it is only built again when that changes,
## and its two buttons while it has them.
var _touch_shown := ""
## And what it says on a keyboard or a pad, the same way.
var _keys_shown := ""
## The card lifted last told to a screen reader, see [method _show_detail].
var _told := ""
var _touch_buttons: Dictionary[StringName, Button] = {}
## How far into the screen the cards come, at rest, see [method reach].
var _reach := 0.0
## The jokers lit up by [method flash], to how long each has left, and the word over each.
var _flashing: Dictionary[StringName, float] = {}
var _words: Dictionary[StringName, Label] = {}
## Cards on their way out, see [method burn] and [method _leave]: each the card, its word or null,
## how long since it went, where it was then and how big, its back once it has turned over or null,
## and whether it was used up, lit in red.
var _burning: Array[Array] = []
## Where the middle of the hand stands and how big its cards are, from the last frame, for a card
## used up that this hand no longer has to start from.
var _middle := Vector2.ZERO
var _factor := 1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail = JokerDetail.new()
	_detail.name = "Detail"
	_detail.visible = false
	add_child(_detail)
	_build_count()
	_build_suited()
	Events.joker_went_off.connect(_on_went_off)
	Events.joker_used_up.connect(_on_used_up)


func _exit_tree() -> void:
	if Events.joker_went_off.is_connected(_on_went_off):
		Events.joker_went_off.disconnect(_on_went_off)
	if Events.joker_used_up.is_connected(_on_used_up):
		Events.joker_used_up.disconnect(_on_used_up)


func card_count() -> int:
	return _cards.size()


## Sets the cards of [param id] off for a moment, GAME.md 8.3, for a joker that has just done
## something by itself, such as Guardian Angel spending the item: each pulls out of the fan,
## grows, lights up and glows round its frame, with [param word] over it, and goes back. A tucked
## hand comes up meanwhile, the way it does for a card being read.
func flash(id: StringName, word := "") -> void:
	_flashing[id] = FLASH_TIME
	if word.is_empty():
		return
	var label: Label = _words.get(id)
	if label == null:
		label = _word(word, JokerCard.GLOW)
		_words[id] = label
	label.text = word


## Sends a card of [param id] out of the hand, used up, GAME.md 8.3, for a joker that has gone by
## itself, such as the Spare Tire a death takes: the destroying kind of [method flash]. Framed and
## lit in red with [param word] over it, it shakes, then drops out of the hand and fades. The card
## is this hand's while it still has it, and the rest close up behind it; one already gone, as a
## client may hear after the host's hand has reached it, is dealt again to go.
func burn(id: StringName, word := "") -> void:
	var card: JokerCard = null
	var index := _ids.find(id)
	if index >= 0 and index < _cards.size():
		card = _cards[index]
		_cards.remove_at(index)
		_ids.remove_at(index)
	else:
		var catalog: JokerCatalog = load("res://data/jokers/catalog.tres")
		var joker := catalog.by_id(id)
		if joker == null:
			return
		card = JokerCard.create(joker)
		card.bakes = true
		card.pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, 0.0 if hangs() else JokerCard.SIZE.y)
		card.position = _middle - card.pivot_offset
		card.scale = Vector2.ONE * _factor
		add_child(card)
	card.set_highlighted(true, true)
	card.z_index = _cards.size() + 2
	var label := _word(word, JokerCard.DOOMED) if not word.is_empty() else null
	_burning.append([card, label, 0.0, card.position, card.scale, null, true])


## Sends [param card] out of the hand, gone without being used up, dropped or swapped: down out of
## the hand, turning over to the card back worn, as a used-up card goes without its shake.
func _leave(card: JokerCard) -> void:
	card.z_index = _cards.size() + 2
	_burning.append([card, null, BURN_SHAKE, card.position, card.scale, null, false])


## A word for over a card, in [param ink], see [method flash] and [method burn].
func _word(text: String, ink: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(label, Type.DISPLAY, FLASH_WORD_SIZE)
	Type.ink(label, ink)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.modulate.a = 0.0
	add_child(label)
	return label


## One frame of a card on its way out, see [method burn]. False once it has gone.
func _step_burn(going: Array, delta: float) -> bool:
	var card: JokerCard = going[0]
	var label: Label = going[1]
	var since: float = going[2] + delta
	going[2] = since
	if since >= BURN_SHAKE + BURN_DROP:
		card.queue_free()
		if label != null:
			label.queue_free()
		return false
	var drop := clampf((since - BURN_SHAKE) / BURN_DROP, 0.0, 1.0)
	var wobble := sin(since * 55.0) * BURN_WOBBLE * (1.0 - drop)
	var fall := JokerCard.SIZE.y * card.scale.y * BURN_FALL * drop * drop
	card.position = (going[3] as Vector2) + Vector2(wobble, -_inward() * fall)
	card.modulate = Color(BURN if going[6] else Color.WHITE, 1.0 - drop * drop)
	# Turning over at the start of its drop: edge-on half way through the turn, its back showing
	# after.
	var turned := clampf(drop / BURN_TURN, 0.0, 1.0)
	var base: Vector2 = going[4]
	card.scale = Vector2(base.x * maxf(absf(cos(turned * PI)), 0.02), base.y)
	if turned >= 0.5 and going[5] == null:
		var back := CardBack.new(-1, false)
		back.name = "Back"
		card.add_child(back)
		going[5] = back
	if label != null:
		_place_word(label, card, 1.0 - drop)
	return true


## Holds the word of a card that has gone off clear of it, see [method flash]: over a card standing
## on the bottom edge, under one hanging from the top, and fading as the card goes back.
func _place_word(label: Label, panel: JokerCard, glow: float) -> void:
	label.size = label.get_minimum_size()
	label.pivot_offset = label.size * 0.5
	var held := panel.position + panel.pivot_offset
	var tall := JokerCard.SIZE.y * panel.scale.y
	# Out from the card's held edge along the card itself, tipped as it is tipped in the fan, so
	# the word reads as the card's own rather than as a line laid level over a leaning card.
	var out := tall + FLASH_WORD_GAP + label.size.y * 0.5
	var along := Vector2(0.0, out if hangs() else -out).rotated(panel.rotation)
	label.position = held + along - label.pivot_offset
	label.rotation = panel.rotation
	label.modulate.a = glow


## How far out the card at [param index] still is, 1 while it is out and down to 0 as it goes back.
## Where the hand is held: the middle of its cards across, and the edge they stand on.
func held_at() -> Vector2:
	return _middle


## The cards at [param places] light up one after the other, the cards of a hand just made, GAME.md
## 7.3, see [HandFanfare].
func shine_cards(places: Array[int]) -> void:
	for k: int in places.size():
		_shine[places[k]] = -k * SHINE_STEP


## How lit the card at [param index] is by a hand just made, 0 to 1.
func _shined(index: int) -> float:
	if not _shine.has(index):
		return 0.0
	var t := _shine[index]
	return sin(PI * clampf(t / SHINE_TIME, 0.0, 1.0)) if t >= 0.0 else 0.0


func _glow(index: int) -> float:
	if index >= _ids.size():
		return 0.0
	return clampf(_flashing.get(_ids[index], 0.0) / FLASH_FADE, 0.0, 1.0)


## A card going off says so, GAME.md 8.3; one counted without a word, see [method
## Joker.went_off], does not.
func _on_went_off(slot: int, joker: StringName, word: String) -> void:
	if kart != null and kart.slot == slot and not word.is_empty():
		flash(joker, word)


func _on_used_up(slot: int, joker: StringName, word: String) -> void:
	if kart != null and kart.slot == slot:
		burn(joker, word)


## How far into the screen the cards come while none is lifted, for what has to stay clear of
## them: the tops of standing cards, the bottoms of hanging ones, or the edge with none.
func reach() -> float:
	if _cards.is_empty():
		return 0.0 if hangs() else size.y
	return _reach


## Where the cards are on the screen, all of them together, for something to frame them: nothing
## while the hand holds none.
func cards_rect() -> Rect2:
	var whole := Rect2()
	for card: JokerCard in _cards:
		var rect := card.get_global_rect()
		whole = rect if not whole.has_area() else whole.merge(rect)
	return whole


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


## Where card [param i] of [param count] sits in a fan, as a hand of cards sits in a fist: how far
## across the hand it is, from -1 at the left to 1 at the right, and how far the arc lifts it, as a
## share of [constant ARC], the middle the highest; it tips by its across times [constant TILT_DEG].
## Shared with the kart dialog's hand of card backs, see [CardFan].
static func fan_of(i: int, count: int) -> Vector2:
	var across := 0.0 if count < 2 else float(i) / float(count - 1) * 2.0 - 1.0
	return Vector2(across, 1.0 - across * across)


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
	for place: int in _shine.keys():
		_shine[place] += delta
		if _shine[place] > SHINE_TIME:
			_shine.erase(place)
	for id: StringName in _flashing.keys():
		_flashing[id] -= delta
		if _flashing[id] <= 0.0:
			_flashing.erase(id)
			if _words.has(id):
				_words[id].queue_free()
				_words.erase(id)
	var count := _cards.size()
	var picked := selected()
	if picked < 0:
		_told = ""
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
	var resting := (tucked or corner >= 0) and picked < 0 and _flashing.is_empty()
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
		_turn_copy(panel, i)
		var lifted := i == picked
		var place := fan_of(i, count)
		var across := place.x
		var arc := place.y * ARC * factor * fan
		var glow := _glow(i)
		var out := lift if lifted else lift * FLASH_PULL * glow
		var height := edge + inward * (arc + out)
		var anchor := Vector2(left + step * i + card.x * 0.5, height)
		if lifted:
			picked_anchor = anchor
		# Hanging, a card turns about its top center rather than its bottom center, so the point
		# the hand is held at stays the one it turns and shrinks about.
		panel.pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, 0.0 if hangs() else JokerCard.SIZE.y)
		panel.scale = panel.scale.lerp(Vector2.ONE * factor * lerpf(1.0, FLASH_GROW, glow), blend)
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
		panel.z_index = count + 1 if lifted or glow > 0.0 else i
		var tint := DIMMED if picked >= 0 and not lifted else Color.WHITE
		panel.modulate = panel.modulate.lerp(tint.lerp(FLASH, glow), blend)
		var shined := _shined(i)
		if glow > 0.0 and not lifted:
			panel.set_glowing(glow)
		elif shined > 0.0 and not lifted:
			panel.set_glowing(shined)
		else:
			panel.set_highlighted(lifted)
		if _words.has(_ids[i]):
			_place_word(_words[_ids[i]], panel, glow)
	var middle := edge + inward * card.y * 0.5
	_middle = Vector2(left + hand_width * 0.5, edge)
	_factor = factor
	for i: int in range(_burning.size() - 1, -1, -1):
		if not _step_burn(_burning[i], delta):
			_burning.remove_at(i)
	_place_cap(left, middle)
	_place_count(left + hand_width, middle)
	_place_suited(left + hand_width, middle)
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


func _place_count(right: float, _middle: float) -> void:
	_count_label.visible = not _cards.is_empty()
	if not _count_label.visible:
		return
	var held := _cards.size()
	var room := kart.jokers.capacity() if kart != null else JokerHolder.MAX_JOKERS
	_count_label.text = "%d / %d" % [held, room]
	Type.ink(_count_label, Palette.CHIP_GOLD if held >= room else Color(0.82, 0.82, 0.88))
	var label_size := _count_label.get_combined_minimum_size()
	_count_label.size = label_size
	# On the screen's edge the hand is held at, so it stays put as the hand opens and tucks away, and
	# the sign over it stands low beside the cards rather than up by their tops.
	var y := size.y - MARGIN - label_size.y if not hangs() else MARGIN
	_count_label.position = Vector2(right + 12.0, y)


## A Copy Cat at [param index] turning from its own face to the card it copies and back, GAME.md
## 7.3, half the time each, a sheen across it as it turns; any other card left alone.
func _turn_copy(panel: JokerCard, index: int) -> void:
	var held := kart.jokers.jokers
	var copied := held[index].standing_for if index < held.size() else null
	panel.copying(copied)
	if copied == null:
		return
	var seconds := fmod(Time.get_ticks_msec() * 0.001, COPY_CYCLE)
	var half := COPY_CYCLE * 0.5
	var amount := clampf((seconds - half) / COPY_TURN, 0.0, 1.0)
	var sheen := clampf((seconds - half) / COPY_TURN, 0.0, 1.0)
	if seconds < COPY_TURN:
		amount = 1.0 - seconds / COPY_TURN
		sheen = seconds / COPY_TURN
	elif seconds > half + COPY_TURN:
		sheen = 0.0
	panel.show_copy(amount, sheen)


## The sign that the hand is Suited, GAME.md 7.3: a little card for each suit it is Suited in and
## SUITED under them, see [SuitedSign].
func _build_suited() -> void:
	_suited = SuitedSign.new()
	_suited.name = "Suited"
	_suited.visible = false
	add_child(_suited)
	_table = HandsTable.new()
	_table.name = "Hands"
	_table.visible = false
	add_child(_table)
	var fanfare := HandFanfare.new()
	fanfare.name = "Fanfare"
	fanfare.hand = self
	add_child(fanfare)


## Stands the sign on the count, or under it for a hand hanging from the top edge.
func _place_suited(right: float, middle: float) -> void:
	var best := kart.jokers.made.best() if kart != null else -1
	# A hand lost is let go of where it stood, see [HandFanfare], whatever comes after it.
	_suited.visible = (_count_label.visible and best >= 0) or _suited.letting_go()
	if not _suited.visible:
		_place_table(right, middle)
		return
	if best >= 0:
		_suited.show_hand(kart.jokers.made.shown, JokerHands.name_of(best).to_upper())
	else:
		_suited.show_hand([], "")
	var sign_size := _suited.get_combined_minimum_size()
	_suited.size = sign_size
	var y := _count_label.position.y - SUITED_GAP - sign_size.y
	if hangs():
		y = _count_label.position.y + _count_label.size.y + SUITED_GAP
	_suited.position = Vector2(right + 12.0 + SUITED_OUT, y)
	_place_table(right, middle)


## The pay table of the hands beside the sign, GAME.md 8.3, while the hand's key is held, Tab or a
## pad's Y, with one seat at this screen; two share one between their hands, see [method
## _place_shared_table], and more have no room for it. It stands on the
## screen's edge the hand is held at and slides out from behind it, and back as the key is let go.
func _place_table(right: float, _middle: float) -> void:
	_measure_across()
	if columns == 2 and corner < 0:
		_place_shared_table()
		return
	var alone := columns <= 1 and corner < 0
	var wanted := alone and kart != null and kart.menu_open and kart.input.joker_menu
	var step := get_process_delta_time() / TABLE_SLIDE
	_table_out = move_toward(_table_out, 1.0 if wanted else 0.0, step)
	_table.visible = _table_out > 0.0
	if not _table.visible:
		return
	# Across, where it stood while the key was held: let go, the hand tucks away and narrows, and
	# the table goes down where it came up rather than sliding over with it.
	if wanted:
		_table.show_hand(kart.jokers.jokers)
		var wide := maxf(_suited.size.x, _count_label.size.x)
		_table_x = minf(
			right + 12.0 + SUITED_OUT + wide + TABLE_GAP, size.x - HandsTable.SIZE.x - MARGIN
		)
	_table.scale = Vector2.ONE
	var x := _table_x
	var tucked := (1.0 - ease(_table_out, 0.4)) * HandsTable.SIZE.y
	var y := size.y - HandsTable.SIZE.y + tucked
	if hangs():
		y = -tucked
	# On whole pixels, so its picture is drawn as sharp as it was drawn.
	_table.position = Vector2(x, y).round()


## Two seats at the screen, GAME.md 8.3: one pay table between their two hands, kept by the left
## one, up while either player holds their hand's key, a bar of each player's color by the hands
## theirs makes. Only where it fits between the two hands' things, which a big UI scale leaves it no
## room for; three seats and more keep none.
func _place_shared_table() -> void:
	var other := _other_hand()
	var holders: Array[Kart] = []
	for each: JokerHand in [self, other]:
		var held_by := each.kart if each != null else null
		if held_by != null and held_by.menu_open and held_by.input.joker_menu:
			holders.append(held_by)
	# In the middle of the room between the two hands, a little smaller than one player's own.
	var drawn := HandsTable.SIZE * SHARED_TABLE
	var gap_from := reach_across.y + SHARED_GAP
	var gap_to := other.reach_across.x - SHARED_GAP if other != null else 0.0
	var x := roundf((gap_from + gap_to - drawn.x) * 0.5)
	var fits := column == 0 and other != null and gap_to - gap_from >= drawn.x
	var wanted := fits and not holders.is_empty()
	_table_out = move_toward(
		_table_out, 1.0 if wanted else 0.0, get_process_delta_time() / TABLE_SLIDE
	)
	_table.visible = _table_out > 0.0 and column == 0
	if not _table.visible:
		return
	if wanted:
		var marks: Array = []
		for each: JokerHand in [self, other]:
			if each.kart != null and each.kart.jokers != null:
				var ink := Palette.player_color(each.kart.color_index)
				marks.append([ink, each.kart.jokers.made.hands.duplicate()])
		var next: Array = []
		if holders.size() == 1:
			next = JokerHands.next_up(holders[0].jokers.jokers)
		_table.show_shared(marks, next)
	_table.scale = Vector2.ONE * SHARED_TABLE
	var tucked := (1.0 - ease(_table_out, 0.4)) * drawn.y
	var y := size.y - drawn.y + tucked if not hangs() else -tucked
	_table.position = Vector2(x, y).round()


## The other hand at this screen, with two seats at it, or null.
func _other_hand() -> JokerHand:
	var hud := get_parent() as MatchHud
	if hud == null:
		return null
	for each: JokerHand in hud.hands():
		if each != self and each.columns == columns:
			return each
	return null


## How far across the hand's things reach, its key cap to its count and sign, for a table shared
## between two hands to keep out of.
func _measure_across() -> void:
	var from := INF
	var to := -INF
	for part: Control in _cards:
		from = minf(from, part.position.x)
		to = maxf(to, part.position.x + part.size.x * part.scale.x)
	for part: Control in [_cap, _count_label, _suited]:
		if part != null and part.visible:
			from = minf(from, part.position.x)
			to = maxf(to, part.position.x + part.size.x)
	reach_across = Vector2(from, to) if from < INF else Vector2(size.x, 0.0)


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
## Marks the cards of [param ids] as still to be read, with an eye on each, and the rest not.
func set_unread(ids: Array[StringName]) -> void:
	unread = ids.duplicate()
	for i: int in _cards.size():
		_mark_unread(_cards[i], i < _ids.size() and _ids[i] in unread)


## The eye on [param card], shown or not.
func _mark_unread(card: JokerCard, shown: bool) -> void:
	var eye := card.get_node_or_null("Unread") as Control
	if eye == null:
		if not shown:
			return
		eye = Eye.new()
		eye.name = "Unread"
		# In the middle of the card, over whatever is there: a card's corner is under the next
		# card in a fanned hand, and the eye has to be seen on every card.
		eye.position = (JokerCard.SIZE - Vector2(Eye.SIDE, Eye.SIDE)) * 0.5
		card.add_child(eye)
	eye.visible = shown


## An eye, drawn: the mark of a card still to be read.
class Eye:
	extends Control

	const SIDE := 44.0
	const INK := Palette.NEON_CYAN

	func _init() -> void:
		custom_minimum_size = Vector2(SIDE, SIDE)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var middle := Vector2(SIDE, SIDE) * 0.5
		draw_circle(middle, SIDE * 0.5, Color(0.0, 0.0, 0.0, 0.7))
		draw_arc(middle, SIDE * 0.5 - 1.0, 0.0, TAU, 40, INK, 1.5, true)
		var lid := PackedVector2Array()
		for i: int in 17:
			var t := float(i) / 16.0
			var x := lerpf(-15.0, 15.0, t)
			lid.append(middle + Vector2(x, -8.0 * sin(t * PI)))
		for i: int in 17:
			var t := float(i) / 16.0
			var x := lerpf(15.0, -15.0, t)
			lid.append(middle + Vector2(x, 8.0 * sin(t * PI)))
		draw_polyline(lid, INK, 2.2, true)
		draw_circle(middle, 5.0, INK)


func _sync_cards() -> void:
	var ids := kart.jokers.ids()
	if ids == _ids:
		return
	# A card no longer held goes, turning over, see [method _leave]; those still held are dealt
	# again.
	var held := ids.duplicate()
	for i: int in _cards.size():
		var at := held.find(_ids[i]) if i < _ids.size() else -1
		if at >= 0:
			held.remove_at(at)
			_cards[i].queue_free()
		else:
			_leave(_cards[i])
	_ids = ids
	_cards.clear()
	for joker: Joker in kart.jokers.jokers:
		var card := JokerCard.create(joker)
		card.bakes = true
		# Fresh cards slide into the hand from beyond the edge it is held at.
		var beyond := -JokerCard.SIZE.y * 2.0 if hangs() else size.y + JokerCard.SIZE.y
		card.position = Vector2(size.x * (column + 0.5) / columns, beyond)
		add_child(card)
		_cards.append(card)
		_mark_unread(card, joker.id in unread)


## What the player can do with the lifted card, which is the only part of the pane the hand has
## to say anything about.
func _show_detail(joker: Joker) -> void:
	var held := kart.jokers.ids().count(joker.id)
	_detail.show_joker(joker, held, false, details)
	# Nothing takes the cursor here, so a screen reader is told the card as it is lifted.
	var key := "%d|%s|%d" % [selected(), joker.id, held]
	if key != _told:
		_told = key
		var place := "%d of %d" % [selected() + 1, _cards.size()]
		var said := PackedStringArray([place, joker.display_name, JokerCard.told(joker, held)])
		ScreenReader.say(self, ScreenReader.line(said))
	var lead := maxi(JokerSuits.leading(kart.jokers.jokers), 0)
	_detail.show_active(kart.jokers.made, lead, details)
	if _pointed():
		_keys_shown = ""
		_show_touch_hints()
		return
	_touch_shown = ""
	var alive := kart != null and kart.alive
	var actions: Array[StringName] = [
		InputActions.STEER_LEFT,
		InputActions.STEER_RIGHT,
		InputActions.JOKER_DROP,
		InputActions.JOKER_DESTROY,
		InputActions.DETAILS,
	]
	var wanted := "%s|%s" % [alive, InputHint.stamp(actions, keyboard)]
	if wanted == _keys_shown:
		return
	_keys_shown = wanted
	var ink := JokerDetail.hint_ink()
	var size := InputHint.FONT_SIZE
	var parts: Array = [
		InputHint.pair(InputActions.STEER_LEFT, InputActions.STEER_RIGHT, keyboard, ink, size),
	]
	var line := "%s cycle"
	# A player waiting to come back can read their hand but not throw any of it away, GAME.md
	# 3.7, so the pane stops offering the two buttons that would. A hint for a button that does
	# nothing is worse than no hint: it reads as the game having stopped listening.
	if alive:
		parts.append(InputHint.glyph(InputActions.JOKER_DROP, keyboard, ink, size))
		parts.append(InputHint.glyph(InputActions.JOKER_DESTROY, keyboard, ink, size))
		line += "   %s drop   %s destroy"
	# And the key that says more of the card and of the hand, Alt or the right stick, GAME.md 8.3.
	parts.append(InputHint.glyph(InputActions.DETAILS, keyboard, ink, size))
	line += "   %s details"
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
	var wanted := (
		"%s %s %s"
		% [
			verb,
			"acting" if acting else ("pinned" if pinned else "held"),
			InputHint.stamp([InputActions.PAUSE], true),
		]
	)
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
	var ink := JokerDetail.hint_ink()
	if pinned and not TouchInput.enabled:
		# The pause key closes it as well, before it would pause, see [MouseJokers].
		var key := InputHint.glyph(InputActions.PAUSE, true, ink, InputHint.FONT_SIZE)
		column.add_child(
			InputHint.row("Click it again or %s to close it", [key], ink, InputHint.FONT_SIZE)
		)
		_detail.set_hints(column)
		return
	var line := Label.new()
	line.text = (
		"%s the card to keep it open" % verb if not pinned else "%s it again to close it" % verb
	)
	Type.text(line, InputHint.FONT_SIZE, ink)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(line)
	_detail.set_hints(column)
