class_name TeamArt
extends RefCounted
## How a team is drawn, GAME.md 3.14: its suit, in its color, wherever it is written, the standings,
## a kart's pennant, the payout slip and the waiting room's corners.

## Each team's suit, in the order of [constant Teams.NAMES]: Hearts, Spades, Diamonds and Clubs.
const SUITS: Array[int] = [
	Joker.Suit.HEARTS, Joker.Suit.SPADES, Joker.Suit.DIAMONDS, Joker.Suit.CLUBS
]


## [param team]'s suit, one of [enum Joker.Suit].
static func suit_of(team: int) -> int:
	return SUITS[posmod(team, SUITS.size())]


## [param team]'s suit drawn into [param box] on [param on], in its color unless [param ink] says
## otherwise, with a dark edge so it reads on any ground.
static func draw_suit(on: CanvasItem, box: Rect2, team: int, ink := Color.TRANSPARENT) -> void:
	var color := Teams.color(team) if ink.a <= 0.0 else ink
	JokerSuits.draw_outlined(on, box, suit_of(team), color, box.size.x * 0.06)
