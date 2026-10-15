extends Joker
## Echo: a joker in the hand that pays chips or mult pays it again one time in four, GAME.md 7.3:
## Payday's chip, Green Light's mult, a Clubs hand's drift boost, any of them, through [method
## JokerHolder.pay_chips] and [method JokerHolder.pay_mult], which ask it, see [method
## JokerHolder.echoes]. A wild card, so it feeds whatever the hand is built on. Its card says ECHO
## when it does, but not more than once a second and a half, so a hand paying every second is not a
## hand of a card forever going off.

## How often a payment is paid again, and how long its card keeps quiet after saying so.
const CHANCE := 0.25
const QUIET := 1.5

## How often it echoes, which a test can make every time.
var chance := CHANCE
var _said := -QUIET


## Whether it pays [param kart] again what one of its jokers has just paid it.
func echoes(kart: Kart) -> bool:
	if kart.puppet or randf() >= chance:
		return false
	var now := Time.get_ticks_msec() * 0.001
	if now - _said >= QUIET:
		_said = now
		went_off(kart, "ECHO")
	else:
		went_off(kart, "")
	return true


func went_off_words(times: int) -> String:
	return "Paid again once" if times == 1 else "Paid again %d times" % times
