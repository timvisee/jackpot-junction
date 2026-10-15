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

var _suits: Array[int] = []
var _word := "SUITED"
## When each suit's card came, on the engine's clock, for its turn.
var _came: Dictionary[int, float] = {}


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


static func _now() -> float:
	return Time.get_ticks_msec() * 0.001


func _get_minimum_size() -> Vector2:
	var cards := maxi(_suits.size(), 1)
	var wide := maxf(CARD.x + (CARD.x - OVERLAP) * (cards - 1), _word_width())
	return Vector2(wide, CARD.y + WORD_GAP + WORD_SIZE + RULE_GAP + DIAMOND)


func _process(_delta: float) -> void:
	for suit: int in _suits:
		if _now() - float(_came.get(suit, 0.0)) < TURN:
			queue_redraw()
			return


func _draw() -> void:
	var count := _suits.size()
	var wide := size.x
	var row := CARD.x + (CARD.x - OVERLAP) * (count - 1)
	var left := (wide - row) * 0.5
	for i: int in count:
		var suit := _suits[i]
		var turned := clampf((_now() - float(_came.get(suit, 0.0))) / TURN, 0.0, 1.0)
		var middle := Vector2(left + i * (CARD.x - OVERLAP) + CARD.x * 0.5, CARD.y * 0.5)
		var tilt := LEAN + FAN * (float(i) - float(count - 1) * 0.5)
		# Turning over: edge-on as it comes, the back showing first and the face once past it.
		var across := absf(cos(turned * PI)) if turned < 1.0 else 1.0
		draw_set_transform(middle, tilt, Vector2(maxf(across, 0.02), 1.0))
		var card := Rect2(-CARD * 0.5, CARD)
		var face := StyleBoxFlat.new()
		face.set_corner_radius_all(4)
		face.anti_aliasing = true
		face.set_border_width_all(1)
		face.border_color = FlushTally.EDGE
		face.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		face.shadow_size = 4
		var showing := turned >= 0.5
		face.bg_color = HouseTheme.PAPER if showing else FlushTally.FREE_FACE
		draw_style_box(face, card)
		if showing:
			var box := Rect2(-Vector2.ONE * SUIT * 0.5, Vector2.ONE * SUIT)
			SuitArt.draw_into(self, box, suit, JokerSuits.color_of(suit, true))
	draw_set_transform(Vector2.ZERO)
	_draw_word(Vector2(wide * 0.5, CARD.y + WORD_GAP))


## SUITED spaced out under the cards, centered on [param top], and the rule under it.
func _draw_word(top: Vector2) -> void:
	var font := Type.STRONG
	var across := _word_width()
	var x := top.x - across * 0.5
	var baseline := top.y + WORD_SIZE
	# A dark edge under the gold, so it reads on any floor.
	for letter: String in _word:
		var width := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x
		var at := Vector2(x, baseline)
		draw_string_outline(
			font, at, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE, 3, HudText.SHADOW
		)
		draw_string(font, at, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE, Palette.CHIP_GOLD)
		x += width + TRACKING
	var rule_y := baseline + RULE_GAP
	var gold := Color(Palette.CHIP_GOLD, 0.8)
	var half := across * 0.5
	var clear := DIAMOND + DIAMOND_GAP
	draw_line(Vector2(top.x - half, rule_y), Vector2(top.x - clear, rule_y), gold, 1.0, true)
	draw_line(Vector2(top.x + clear, rule_y), Vector2(top.x + half, rule_y), gold, 1.0, true)
	var diamond := PackedVector2Array(
		[
			Vector2(top.x, rule_y - DIAMOND),
			Vector2(top.x + DIAMOND, rule_y),
			Vector2(top.x, rule_y + DIAMOND),
			Vector2(top.x - DIAMOND, rule_y),
		]
	)
	draw_colored_polygon(diamond, Palette.CHIP_GOLD)


func _word_width() -> float:
	var font := Type.STRONG
	var across := 0.0
	for letter: String in _word:
		across += font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x
	return across + TRACKING * (_word.length() - 1)
