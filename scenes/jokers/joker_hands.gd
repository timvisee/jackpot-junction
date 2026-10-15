class_name JokerHands
extends RefCounted
## The hands a hand of jokers makes out of its suits, GAME.md 7.3, Hands, as a pay table has them,
## the best first: what each is, what it pays, and which of them a hand makes, see [method of]. The
## wild cards join the suit held most of, as they do for being Suited, see [method
## JokerSuits.suited]; a Rainbow takes a card of each suit of its own, a wild card being no suit.
## Every hand a hand makes pays at once, a Flush the Four of a Kind and the Suited inside it too.

enum Hand { FLUSH, FOUR_OF_A_KIND, FULL_HOUSE, RAINBOW, SUITED, TWO_PAIR }

const NAMES: Array[String] = [
	"Flush", "Four of a Kind", "Full House", "Rainbow", "Suited", "Two Pair"
]
## What each is, and what it pays, as the pay tables say them.
const IS: Array[String] = [
	"Five cards of one suit",
	"Four cards of one suit",
	"Three of one suit, two of another",
	"One card of every suit",
	"Three cards of one suit",
	"Two cards each of two suits",
]
const PAYS: Array[String] = [
	"Its bonus twice over",
	"A chip every 3 s",
	"Both suits' bonuses",
	"Cash-outs bank 10% more",
	"Its suit's bonus",
	"Cash-outs bank 5% more",
]
## What each pays in a few words, for a ticket's narrow line.
const SHORT: Array[String] = [
	"bonus x2", "a chip / 3 s", "both suits", "cash-out +10%", "its bonus", "cash-out +5%"
]
## The cards that show each in a pay table, by [enum Joker.Suit].
const SHOWN: Array[Array] = [
	[2, 2, 2, 2, 2], [2, 2, 2, 2], [2, 2, 2, 3, 3], [0, 1, 2, 3], [3, 3, 3], [0, 0, 1, 1]
]
## How many cards of one suit a Four of a Kind and a Flush take, and how many each of two suits a
## Two Pair takes.
const FOUR := 4
const FIVE := 5
const PAIR := 2


## What a hand makes: the hands, by [enum Hand], the best first; the suits it is Suited in, whose
## bonus is paid, a Full House's pair among them; the suit a Flush pays twice, or -1; and the suits
## its sign shows.
class Made:
	extends RefCounted

	var hands: Array[int] = []
	var suited: Array[int] = []
	var twice := -1
	var shown: Array[int] = []

	func has(hand: int) -> bool:
		return hand in hands

	## The best hand made, or -1 for none.
	func best() -> int:
		return hands[0] if not hands.is_empty() else -1


## What [param jokers] makes, GAME.md 7.3.
static func of(jokers: Array[Joker]) -> Made:
	var made := Made.new()
	var real := JokerSuits.counts(jokers)
	var counted := real.duplicate()
	var wild := 0
	var needed := JokerSuits.SUITED
	for joker: Joker in jokers:
		if joker.suit == Joker.Suit.WILD:
			wild += 1
		needed = joker.modify_suited(needed)
	var lead := maxi(JokerSuits.leading(jokers), 0)
	counted[lead] += wild
	var pairs: Array[int] = []
	for suit: int in counted.size():
		if counted[suit] >= needed:
			made.suited.append(suit)
		elif counted[suit] >= PAIR:
			pairs.append(suit)
	if counted[lead] >= FIVE:
		made.hands.append(Hand.FLUSH)
		made.twice = lead
	if counted[lead] >= FOUR:
		made.hands.append(Hand.FOUR_OF_A_KIND)
	if not made.suited.is_empty() and not pairs.is_empty():
		made.hands.append(Hand.FULL_HOUSE)
		made.suited.append_array(pairs)
		made.suited.sort()
	if real.min() >= 1:
		made.hands.append(Hand.RAINBOW)
	if not made.suited.is_empty():
		made.hands.append(Hand.SUITED)
	elif pairs.size() >= 2:
		made.hands.append(Hand.TWO_PAIR)
	made.shown = made.suited.duplicate()
	if made.best() == Hand.RAINBOW:
		made.shown.assign([0, 1, 2, 3])
	elif made.best() == Hand.TWO_PAIR:
		made.shown = pairs.slice(0, 2)
	return made


## The next hand up the suit [param jokers] holds most of that it does not make yet, Suited, Four of
## a Kind and Flush in turn: that hand, by [enum Hand], how many more cards of the suit it wants,
## and the suit; or nothing for a hand with no cards, or that makes a Flush already.
static func next_up(jokers: Array[Joker]) -> Array:
	if jokers.is_empty():
		return []
	var counted := JokerSuits.counts(jokers)
	var needed := JokerSuits.SUITED
	var wild := 0
	for joker: Joker in jokers:
		if joker.suit == Joker.Suit.WILD:
			wild += 1
		needed = joker.modify_suited(needed)
	var lead := maxi(JokerSuits.leading(jokers), 0)
	var held := counted[lead] + wild
	for step: Array in [[Hand.SUITED, needed], [Hand.FOUR_OF_A_KIND, FOUR], [Hand.FLUSH, FIVE]]:
		if held < step[1]:
			return [step[0], step[1] - held, lead]
	return []


## Which of [param jokers], by their place in it, make [param hand] of [param made]: the cards of
## its suits, the wild cards joining in, a card of each suit for a Rainbow.
static func cards_of(jokers: Array[Joker], made: Made, hand: int) -> Array[int]:
	var picked: Array[int] = []
	if hand == Hand.RAINBOW:
		var seen: Array[int] = []
		for i: int in jokers.size():
			var suit := jokers[i].suit
			if suit != Joker.Suit.WILD and suit not in seen:
				seen.append(suit)
				picked.append(i)
		return picked
	var suits := made.shown if hand == Hand.TWO_PAIR else made.suited
	for i: int in jokers.size():
		var suit := jokers[i].suit
		if suit in suits or (suit == Joker.Suit.WILD and hand != Hand.TWO_PAIR):
			picked.append(i)
	return picked


## What the hand's sign and a pay table call [param hand].
static func name_of(hand: int) -> String:
	return NAMES[clampi(hand, 0, NAMES.size() - 1)]
