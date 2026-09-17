extends Joker
## Backfire: hold the brake and the cannon points out of the back of the kart, so a driver being
## chased can answer without turning round and losing the ground they were keeping.
##
## The aim guide follows it, so what is about to happen is never a surprise. It leaves free aim
## alone: a player pointing the Swivel Cannon by hand has already said where the shot goes.

## How firmly the brake has to be held. A brush of it while trail braking into a corner is not
## somebody asking to shoot behind themselves.
const HOLD := 0.5


func modify_aim(kart: Kart, direction: Vector3) -> Vector3:
	if kart.input.brake < HOLD or kart.cannon.current_stats().free_aim:
		return direction
	return -direction
