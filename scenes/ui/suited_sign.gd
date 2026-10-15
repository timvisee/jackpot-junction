class_name SuitedSign
extends Control
## A hand that makes a hand says so beside it, GAME.md 7.3, Hands: a little playing card for each
## suit in it, as the Royal Flush pads' are under the clock, 8.3, cream with the suit in its own
## color and fanned when there are more, and the best hand it makes under them, SUITED or FULL
## HOUSE, in the house's gold, spaced out as a card's small print is, over a fine gold rule with a
## diamond at its middle. A card turns over into place as
## its suit comes, see [method show_suits]. Drawn as itself rather than of labels and boxes: a
## handful of shapes.

## The cards: how big, how much of one the next covers, how far they fan, and how big the suit is.
const CARD := Vector2(30.0, 42.0)
const OVERLAP := 12.0
const FAN := 0.14
const LEAN := -0.06
const SUIT := 20.0
## The word under them: how big, how far its letters are spaced apart, how far under the cards it
## stands, and the rule under it: how far under, and how big the diamond at its middle is and the
## gap either side of it.
const WORD_SIZE := 11
const TRACKING := 2.4
const WORD_GAP := 5.0
const RULE_GAP := 3.0
const DIAMOND := 3.5
const DIAMOND_GAP := 4.0
## How long a card takes to turn over into place, in seconds.
const TURN := 0.3
## A hand made, GAME.md 7.3: its name stamped in, from how much bigger, a shine across the sign, and
## for how long; and one lost, let go: struck through, dropping and sliding off as its cards turn
## face down, how far and for how long. See [HandFanfare].
const STAMP_GROW := 0.8
const STAMP_TIME := 0.5
const GHOST_DROP := 22.0
const GHOST_SLIDE := 26.0
const GHOST_TIME := 0.8

var _suits: Array[int] = []
var _word := "SUITED"
## When each suit's card came, on the engine's clock, for its turn.
var _came: Dictionary[int, float] = {}
## How much of a stamp is still to run, 1 to 0, and of a lost hand being let go, and what it was.
var _stamp := 0.0
var _ghost := 0.0
var _ghost_suits: Array[int] = []
var _ghost_word := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows a card for each of [param suits], by [enum Joker.Suit], a new one turning over into place,
## over [param word], the hand they make.
func show_hand(suits: Array[int], word: String) -> void:
	if suits == _suits and word == _word:
		return
	_word = word
	var now := _now()
	for suit: int in suits:
		if suit not in _suits:
			_came[suit] = now
	_suits = suits.duplicate()
	update_minimum_size()
	queue_redraw()


func suits() -> Array[int]:
	return _suits


## The hand's name stamped in, a hand just made.
func stamp() -> void:
	_stamp = 1.0
	queue_redraw()


## A hand lost, [param word] its name and [param suits] its cards, let go: struck through and
## dropping off as its cards turn face down.
func let_go(suits: Array[int], word: String) -> void:
	_ghost = 1.0
	_ghost_suits = suits.duplicate()
	_ghost_word = word
	queue_redraw()


## Whether a hand lost is still being let go, which the sign stays up for.
func letting_go() -> bool:
	return _ghost > 0.0


static func _now() -> float:
	return Time.get_ticks_msec() * 0.001


func _get_minimum_size() -> Vector2:
	var cards := maxi(_suits.size(), 1)
	var wide := maxf(CARD.x + (CARD.x - OVERLAP) * (cards - 1), _word_width())
	return Vector2(wide, CARD.y + WORD_GAP + WORD_SIZE + RULE_GAP + DIAMOND)


func _process(delta: float) -> void:
	if _stamp > 0.0 or _ghost > 0.0:
		_stamp = maxf(_stamp - delta / STAMP_TIME, 0.0)
		_ghost = maxf(_ghost - delta / GHOST_TIME, 0.0)
		queue_redraw()
		return
	for suit: int in _suits:
		if _now() - float(_came.get(suit, 0.0)) < TURN:
			queue_redraw()
			return


func _draw() -> void:
	var top := Vector2(size.x * 0.5, CARD.y + WORD_GAP)
	_draw_cards(_suits, Vector2.ZERO, 1.0, false)
	_draw_word(_word, top, 1.0, 1.0 + STAMP_GROW * _stamp * _stamp, false)
	if _stamp > 0.0:
		_draw_shine()
	if _ghost > 0.0:
		var gone := 1.0 - _ghost
		var away := Vector2(gone * GHOST_SLIDE, gone * GHOST_DROP)
		_draw_cards(_ghost_suits, away, _ghost, true)
		_draw_word(_ghost_word, top + Vector2(0.0, gone * GHOST_DROP), _ghost, 1.0, true)


## A card for each of [param suits], fanned, moved by [param by], as strong as [param alpha]; face
## down for a hand being let go.
func _draw_cards(suits: Array[int], by: Vector2, alpha: float, face_down: bool) -> void:
	var count := suits.size()
	var row := CARD.x + (CARD.x - OVERLAP) * (count - 1)
	var left := (size.x - row) * 0.5
	for i: int in count:
		var suit := suits[i]
		var turned := 1.0
		if not face_down:
			turned = clampf((_now() - float(_came.get(suit, 0.0))) / TURN, 0.0, 1.0)
		var middle := Vector2(left + i * (CARD.x - OVERLAP) + CARD.x * 0.5, CARD.y * 0.5) + by
		var tilt := LEAN + FAN * (float(i) - float(count - 1) * 0.5)
		# Turning over: edge-on as it comes, the back showing first and the face once past it.
		var across := absf(cos(turned * PI)) if turned < 1.0 else 1.0
		draw_set_transform(middle, tilt, Vector2(maxf(across, 0.02), 1.0))
		var card := Rect2(-CARD * 0.5, CARD)
		var face := StyleBoxFlat.new()
		face.set_corner_radius_all(4)
		face.anti_aliasing = true
		face.set_border_width_all(1)
		face.border_color = Color(FlushTally.EDGE, FlushTally.EDGE.a * alpha)
		face.shadow_color = Color(0.0, 0.0, 0.0, 0.35 * alpha)
		face.shadow_size = 4
		var showing := turned >= 0.5 and not face_down
		var paper := HouseTheme.PAPER if showing else FlushTally.FREE_FACE
		face.bg_color = Color(paper, paper.a * alpha)
		draw_style_box(face, card)
		if showing:
			var box := Rect2(-Vector2.ONE * SUIT * 0.5, Vector2.ONE * SUIT)
			SuitArt.draw_into(self, box, suit, JokerSuits.color_of(suit, true))
	draw_set_transform(Vector2.ZERO)


## A shine across the sign as a hand's name is stamped in.
func _draw_shine() -> void:
	var run := 1.0 - _stamp
	var x := lerpf(-24.0, size.x + 24.0, run)
	var tall := size.y
	var band := PackedVector2Array(
		[
			Vector2(x - 6.0, 0.0),
			Vector2(x + 8.0, 0.0),
			Vector2(x - 2.0, tall),
			Vector2(x - 16.0, tall)
		]
	)
	draw_colored_polygon(band, Color(1.0, 0.95, 0.75, 0.55 * sin(PI * run)))


## [param word] spaced out under the cards, centered on [param top], as strong as [param alpha]
## and [param grow] times its size, and the rule under it; [param struck] through, a hand let go.
func _draw_word(word: String, top: Vector2, alpha: float, grow: float, struck: bool) -> void:
	var font := Type.STRONG
	var across := _width_of(word)
	draw_set_transform(top + Vector2(0.0, WORD_SIZE * 0.5), 0.0, Vector2.ONE * grow)
	var x := -across * 0.5
	var baseline := WORD_SIZE * 0.5
	var gold := Color(Palette.CHIP_GOLD, alpha)
	# A dark edge under the gold, so it reads on any floor.
	for letter: String in word:
		var width := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x
		var at := Vector2(x, baseline)
		var shade := Color(HudText.SHADOW, HudText.SHADOW.a * alpha)
		draw_string_outline(font, at, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE, 3, shade)
		draw_string(font, at, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE, gold)
		x += width + TRACKING
	var half := across * 0.5
	if struck:
		var middle := baseline - WORD_SIZE * 0.35
		var red := Color(SlotPad.VOID_RED, alpha)
		draw_line(Vector2(-half - 2.0, middle), Vector2(half + 2.0, middle), red, 2.0, true)
	var rule_y := baseline + RULE_GAP
	var line := Color(Palette.CHIP_GOLD, 0.8 * alpha)
	var clear := DIAMOND + DIAMOND_GAP
	draw_line(Vector2(-half, rule_y), Vector2(-clear, rule_y), line, 1.0, true)
	draw_line(Vector2(clear, rule_y), Vector2(half, rule_y), line, 1.0, true)
	var diamond := PackedVector2Array(
		[
			Vector2(0.0, rule_y - DIAMOND),
			Vector2(DIAMOND, rule_y),
			Vector2(0.0, rule_y + DIAMOND),
			Vector2(-DIAMOND, rule_y),
		]
	)
	draw_colored_polygon(diamond, gold)
	draw_set_transform(Vector2.ZERO)


func _word_width() -> float:
	return _width_of(_word)


func _width_of(word: String) -> float:
	var font := Type.STRONG
	var across := 0.0
	for letter: String in word:
		across += font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x
	return across + TRACKING * (word.length() - 1)
