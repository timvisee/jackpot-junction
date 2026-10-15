class_name HandBonus
extends Joker
## What a hand made out of the suits pays besides the suits' own bonuses, GAME.md 7.3, Hands: run
## with the hand's own jokers as one more of them, as a [SuitBonus] is, and never a card in it. A
## Rainbow's and a Two Pair's cash-outs bank more, and a Four of a Kind, a Flush's among them, pays
## a chip every few seconds.

## What a Rainbow and a Two Pair make of a cash-out, and how often a Four of a Kind pays a chip.
const RAINBOW_BANK := 1.1
const TWO_PAIR_BANK := 1.05
const CHIP_EVERY := 3.0

var hand := JokerHands.Hand.SUITED
var _left := CHIP_EVERY


## The bonus of [param made], one of [enum JokerHands.Hand], or null for one that pays nothing of
## its own.
static func of(made: int) -> HandBonus:
	if (
		made
		not in [JokerHands.Hand.RAINBOW, JokerHands.Hand.TWO_PAIR, JokerHands.Hand.FOUR_OF_A_KIND]
	):
		return null
	var bonus := HandBonus.new()
	bonus.hand = made as JokerHands.Hand
	bonus.id = StringName("hand_%s" % JokerHands.name_of(made).to_lower().replace(" ", "_"))
	bonus.display_name = JokerHands.name_of(made)
	bonus.suit = Suit.WILD
	return bonus


func modify_bank_payout(_kart: Kart, multiplier: float) -> float:
	if hand == JokerHands.Hand.RAINBOW:
		return multiplier * RAINBOW_BANK
	if hand == JokerHands.Hand.TWO_PAIR:
		return multiplier * TWO_PAIR_BANK
	return multiplier


func on_step(kart: Kart, delta: float) -> int:
	if hand != JokerHands.Hand.FOUR_OF_A_KIND:
		return 0
	_left -= delta
	while _left <= 0.0:
		_left += CHIP_EVERY
		kart.jokers.pay_chips(self, 1)
	return 0
