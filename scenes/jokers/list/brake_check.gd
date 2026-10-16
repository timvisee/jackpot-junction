extends Joker
## Brake Check, one of Kit's cards, STORY.md 6.3: a dead stop out of a run with chips in the pot
## adds 1 mult, up to 3 a life and once every 8 seconds; the kart's top speed is 10% down for it.
## "Brake on a straight now and then. It hates that."

const MULT := 1.0
const MOST := 3
const EVERY := 8.0
## How slow is stopped, how fast a run has to have been, and how lately, in meters a second and
## seconds.
const STOPPED := 0.6
const RUNNING := 5.0
const LATELY := 1.5
const SLOWER := 0.9

var _given := 0
var _wait := 0.0
var _ran := 0.0


func modify_kart_stats(stats: KartStats) -> void:
	stats.top_speed *= SLOWER


func on_step(kart: Kart, delta: float) -> int:
	_wait = maxf(_wait - delta, 0.0)
	_ran = maxf(_ran - delta, 0.0)
	var speed := absf(kart.motor.forward_speed)
	if speed >= RUNNING:
		_ran = LATELY
		return 0
	if speed > STOPPED or _ran <= 0.0 or _wait > 0.0 or _given >= MOST or kart.pot.coins <= 0:
		return 0
	_given += 1
	_wait = EVERY
	_ran = 0.0
	kart.jokers.pay_mult(self, MULT, &"brake_check")
	went_off(kart, "+1 MULT")
	return 0


func on_respawn(_kart: Kart) -> void:
	_given = 0
	_wait = 0.0
