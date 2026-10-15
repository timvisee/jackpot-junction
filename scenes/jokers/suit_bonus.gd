class_name SuitBonus
extends Joker
## What a hand Suited in a suit is paid, GAME.md 7.3, Suits: run with the hand's own jokers as one
## more of them, see [member JokerHolder.in_play], and never a card in it. A Spades hand's bullets
## fly faster, a Hearts hand comes back holding a Shield, a Diamonds hand's chips are worth one
## more, and a Clubs hand's drift boosts pay mult.

## How much faster a Spades hand's bullets fly, and how much mult a Clubs hand's drift boost pays.
const BULLET_SPEED := 1.2
const DRIFT_MULT := 0.5
const SHIELD: PowerUp = preload("res://data/powerups/shield.tres")


## The bonus of [param of_suit], one of [enum Joker.Suit] but wild.
static func of(of_suit: int) -> SuitBonus:
	var bonus := SuitBonus.new()
	bonus.id = StringName("suited_%s" % JokerSuits.name_of(of_suit).to_lower())
	bonus.display_name = "Suited"
	bonus.suit = of_suit as Joker.Suit
	return bonus


func modify_cannon_stats(stats: CannonStats) -> void:
	if suit == Suit.SPADES:
		stats.bullet_speed *= BULLET_SPEED


func modify_coin_value(_kart: Kart, _chip: Chip, value: int) -> int:
	return value + 1 if suit == Suit.DIAMONDS else value


## A Hearts hand comes back holding a Shield, unless its hands are full already. The host's to
## hand out, as every item is.
func on_respawn(kart: Kart) -> void:
	if suit == Suit.HEARTS and not kart.puppet and kart.held_item == null:
		kart.hold_item(SHIELD, 0.0)


func on_drift_boost(kart: Kart) -> void:
	if suit == Suit.CLUBS:
		kart.jokers.pay_mult(self, DRIFT_MULT, &"suited")
