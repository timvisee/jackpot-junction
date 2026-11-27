class_name JokerSuits
extends RefCounted
## The suits of the jokers, GAME.md 7.3, Suits: what each is called and drawn in, which suits a
## hand is Suited in, and what being Suited in each pays. The suits are the four of the Royal Flush
## pads and of the teams, in cream for Spades and Clubs and red for Hearts and Diamonds as a deck
## has them; a wild card wears a jester's hat, the joker's own. As marks they are drawings of
## GAME.md 8.3a, printed flat like type; the arena's pads draw theirs with [SuitArt].

## How many cards of a suit make a hand Suited in it, GAME.md 7.3, unless a joker says otherwise.
const SUITED := 3
## Each suit by name, shown through tr(); [method name_of] gives it in English, as the stats and the
## bonuses go by it.
const NAMES: Array[String] = ["Spades", "Hearts", "Diamonds", "Clubs", "Wild"]
## Each suit as a letter of words, where it is said rather than drawn.
const SYMBOLS: Array[String] = ["♠", "♥", "♦", "♣", "★"]
## What being Suited in each suit pays, as the pane that describes a card says it, shown through
## tr().
const PAYS: Array[String] = [
	"your bullets fly 20% faster",
	"come back holding a Shield",
	"every chip you pick up is worth one more",
	"every drift boost gives +0.5 mult",
]
## The red of Hearts and Diamonds, bright enough to read on a card's dark.
const RED := Color("#F0524F")
## Each suit's drawing, in [enum Joker.Suit] order, and the jester's in two: its points in red, then
## its band and bells in gold over them.
const PICTURES: Array[StringName] = [&"suit_spade", &"suit_heart", &"suit_diamond", &"suit_club"]
const JESTER := &"suit_jester"
const JESTER_BAND := &"suit_jester_band"
## How far a mark's outline reaches, in pixels, and in how many steps round it is drawn.
const HALO := 1.4
const HALO_STEPS := 8


## A suit drawn into a control: a card's corner, the pane's line, the hand's Suited sign.
class Mark:
	extends Control

	var suit := Joker.Suit.WILD
	var paper := false
	## An outline of this round the mark, for one set over a screen, as a card's corner is; none
	## while clear.
	var halo := Color(0.0, 0.0, 0.0, 0.0)

	func _init(of_suit: int = Joker.Suit.WILD, on_paper := false) -> void:
		suit = of_suit as Joker.Suit
		paper = on_paper
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var box := Rect2(Vector2.ZERO, size)
		if halo.a > 0.0:
			for step: int in HALO_STEPS:
				var out := Vector2.from_angle(TAU * step / HALO_STEPS) * HALO
				JokerSuits.draw_shadow(self, Rect2(box.position + out, box.size), suit, halo)
		JokerSuits.draw_mark(self, box, suit, paper)


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


## Draws [param suit] into [param box] on [param on]: the suit itself, or for a wild card a
## jester's hat, see [method draw_jester].
static func draw_mark(on: CanvasItem, box: Rect2, suit: int, paper := false) -> void:
	if suit < 0 or suit >= PICTURES.size():
		draw_jester(on, box, paper)
		return
	IconPress.draw(on, box, PICTURES[suit], color_of(suit, paper), IconPress.Ground.PAPER)


## [param suit]'s mark in [param ink] alone, its shape without its colors: what its outline is drawn
## of, see [member Mark.halo].
static func draw_shadow(on: CanvasItem, box: Rect2, suit: int, ink: Color) -> void:
	if suit < 0 or suit >= PICTURES.size():
		IconPress.draw(on, box, JESTER, ink, IconPress.Ground.PAPER, ink)
		IconPress.draw(on, box, JESTER_BAND, ink, IconPress.Ground.PAPER, ink)
		return
	IconPress.draw(on, box, PICTURES[suit], ink, IconPress.Ground.PAPER)


## A jester's hat, the wild card's mark, GAME.md 7.3, the Jokers table card's: two points in red
## flopping out and down with a cream one standing up between them, over a gold band, a gold bell
## on the end of each. On [param paper] the cream is the House's ink, as a spade is.
static func draw_jester(on: CanvasItem, box: Rect2, paper := false) -> void:
	var red := color_of(Joker.Suit.HEARTS, paper)
	var cream := color_of(Joker.Suit.SPADES, paper)
	var gold := HouseTheme.on_paper(Palette.CHIP_GOLD) if paper else Palette.CHIP_GOLD
	IconPress.draw(on, box, JESTER, red, IconPress.Ground.PAPER, cream)
	IconPress.draw(on, box, JESTER_BAND, gold, IconPress.Ground.PAPER, cream)


## What [param suit] is for in a hand, as the pane that describes a card says it after the suit
## itself: what three of it pay, the pane setting "3×" and the suit in front, or where a wild card
## goes.
static func words(suit: int) -> String:
	if suit == Joker.Suit.WILD:
		return Lang.t("Wild: joins the suit you hold most of.")
	# TRANSLATORS: After "3×" and a suit drawn, what three cards of that suit pay: ": your bullets
	# fly 20% faster."
	return Lang.t(": %s.") % Lang.t(PAYS[suit])


## How many of each suit [param jokers] holds, the wild cards left out, by [enum Joker.Suit].
static func counts(jokers: Array[Joker]) -> Array[int]:
	var counted: Array[int] = [0, 0, 0, 0]
	for joker: Joker in jokers:
		if joker.suit != Joker.Suit.WILD and not joker.contraband:
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


## The suit a pick for [param kart] leans toward, GAME.md 7.3: the one its hand holds most of, or
## -1 at a table without Suits & hands, 3.17, where a suit is only a corner of a card.
static func lean(kart: Kart) -> int:
	if kart.rules != null and not kart.rules.has_card(TableCards.Card.SUITS):
		return -1
	return leading(kart.jokers.jokers)


## The suits [param jokers] is Suited in, GAME.md 7.3: three of one, or as many as a joker in it
## says, the wild cards joining the suit held most of so that they count once.
static func suited(jokers: Array[Joker]) -> Array[int]:
	var counted := counts(jokers)
	var wild := 0
	var needed := SUITED
	for joker: Joker in jokers:
		if joker.suit == Joker.Suit.WILD and not joker.contraband:
			wild += 1
		needed = joker.modify_suited(needed)
	var lead := leading(jokers)
	counted[maxi(lead, 0)] += wild
	var result: Array[int] = []
	for suit: int in counted.size():
		if counted[suit] >= needed:
			result.append(suit)
	return result
