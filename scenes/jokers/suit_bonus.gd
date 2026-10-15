class_name SuitBonus
extends Joker
## What a hand Suited in a suit is paid, GAME.md 7.3, Suits: run with the hand's own jokers as one
## more of them, see [member JokerHolder.in_play], and never a card in it. A Spades hand's bullets
## fly faster, a Hearts hand comes back holding a Shield, a Diamonds hand's chips are worth one
## more, and a Clubs hand's drift boosts pay mult. A Flush pays its suit's twice over, see
## [JokerHands]: the second faster again, one more again, and as much mult again, and the second
## of Hearts, its Shield already held, comes back with a Boost running.

## How much faster a Spades hand's bullets fly, and how much mult a Clubs hand's drift boost pays.
const BULLET_SPEED := 1.2
const DRIFT_MULT := 0.5
const SHIELD: PowerUp = preload("res://data/powerups/shield.tres")
const BOOST: PowerUp = preload("res://data/powerups/boost.tres")

## Whether this is a Flush's second of its suit's bonus.
var second := false


## The bonus of [param of_suit], one of [enum Joker.Suit] but wild, or a Flush's [param again].
static func of(of_suit: int, again := false) -> SuitBonus:
	var bonus := SuitBonus.new()
	bonus.id = StringName("suited_%s" % JokerSuits.name_of(of_suit).to_lower())
	bonus.display_name = "Flush" if again else "Suited"
	bonus.suit = of_suit as Joker.Suit
	bonus.second = again
	return bonus


func modify_cannon_stats(stats: CannonStats) -> void:
	if suit == Suit.SPADES:
		stats.bullet_speed *= BULLET_SPEED


func modify_coin_value(_kart: Kart, _chip: Chip, value: int) -> int:
	return value + 1 if suit == Suit.DIAMONDS else value


## A Hearts hand comes back holding a Shield, unless its hands are full already. The host's to
## hand out, as every item is.
func on_respawn(kart: Kart) -> void:
	if suit != Suit.HEARTS or kart.puppet:
		return
	if second:
		BOOST.activate(kart)
	elif kart.held_item == null:
		kart.hold_item(SHIELD, 0.0)


func on_drift_boost(kart: Kart) -> void:
	if suit == Suit.CLUBS:
		kart.jokers.pay_mult(self, DRIFT_MULT, &"suited")
