class_name JokerSuits
extends RefCounted
## The suits of the jokers, GAME.md 7.3, Suits: what each is called and drawn in, which suits a
## hand is Suited in, and what being Suited in each pays. The suits are the four of the Royal Flush
## pads and of the teams, drawn by [SuitArt], in cream for Spades and Clubs and red for Hearts and
## Diamonds as a deck has them; a wild card wears all four in its corner.

## How many cards of a suit make a hand Suited in it, GAME.md 7.3, unless a joker says otherwise.
const SUITED := 3
const NAMES: Array[String] = ["Spades", "Hearts", "Diamonds", "Clubs", "Wild"]
## What being Suited in each suit pays, as the pane that describes a card says it.
const PAYS: Array[String] = [
	"your bullets fly 20% faster",
	"come back holding a Shield",
	"every chip you pick up is worth one more",
	"every drift boost gives +0.5 mult",
]
## The red of Hearts and Diamonds, bright enough to read on a card's dark.
const RED := Color("#F0524F")
## How much of a wild card's corner each of its four small suits takes, and the air between.
const WILD_SHARE := 0.46


## A suit drawn into a control: a card's corner, the pane's line, the hand's Suited sign.
class Mark:
	extends Control

	var suit := Joker.Suit.WILD
	var paper := false

	func _init(of_suit: int = Joker.Suit.WILD, on_paper := false) -> void:
		suit = of_suit as Joker.Suit
		paper = on_paper
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		JokerSuits.draw_mark(self, Rect2(Vector2.ZERO, size), suit, paper)


static func name_of(suit: int) -> String:
	return NAMES[clampi(suit, 0, NAMES.size() - 1)]


## The color [param suit] is drawn in: red for Hearts and Diamonds, cream for the rest, the
## House's darker ink of each on [param paper].
static func color_of(suit: int, paper := false) -> Color:
	var red := suit == Joker.Suit.HEARTS or suit == Joker.Suit.DIAMONDS
	var color := RED if red else Palette.CHIP_WHITE
	if paper:
		return HouseTheme.on_paper(color) if red else HouseTheme.INK
	return color


## Draws [param suit] into [param box] on [param on]: the suit itself, or for a wild card all
## four, two by two.
static func draw_mark(on: CanvasItem, box: Rect2, suit: int, paper := false) -> void:
	if suit != Joker.Suit.WILD:
		SuitArt.draw_into(on, box, suit, color_of(suit, paper))
		return
	var side := box.size * WILD_SHARE
	var step := box.size - side
	for i: int in 4:
		var at := box.position + Vector2(step.x * (i % 2), step.y * (i >> 1))
		SuitArt.draw_into(on, Rect2(at, side), i, color_of(i, paper))


## What [param suit] is for in a hand, as the pane that describes a card says it: what three of
## it pay, or where a wild card goes.
static func words(suit: int) -> String:
	if suit == Joker.Suit.WILD:
		return "Wild: joins the suit you hold most of."
	return "Three %s: %s." % [NAMES[suit], PAYS[suit]]


## How many of each suit [param jokers] holds, the wild cards left out, by [enum Joker.Suit].
static func counts(jokers: Array[Joker]) -> Array[int]:
	var counted: Array[int] = [0, 0, 0, 0]
	for joker: Joker in jokers:
		if joker.suit != Joker.Suit.WILD:
			counted[joker.suit] += 1
	return counted


## The suit [param jokers] holds most of, the first of Spades, Hearts, Diamonds and Clubs where two
## are level, or -1 for a hand of nothing but wild cards.
static func leading(jokers: Array[Joker]) -> int:
	var counted := counts(jokers)
	var best := -1
	for suit: int in counted.size():
		if counted[suit] > 0 and (best < 0 or counted[suit] > counted[best]):
			best = suit
	return best


## The suits [param jokers] is Suited in, GAME.md 7.3: three of one, or as many as a joker in it
## says, the wild cards joining the suit held most of so that they count once.
static func suited(jokers: Array[Joker]) -> Array[int]:
	var counted := counts(jokers)
	var wild := 0
	var needed := SUITED
	for joker: Joker in jokers:
		if joker.suit == Joker.Suit.WILD:
			wild += 1
		needed = joker.modify_suited(needed)
	var lead := leading(jokers)
	counted[maxi(lead, 0)] += wild
	var result: Array[int] = []
	for suit: int in counted.size():
		if counted[suit] >= needed:
			result.append(suit)
	return result
