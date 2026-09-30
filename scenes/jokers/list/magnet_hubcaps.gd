extends Joker
## Magnet Hubcaps: Pickup radius times 2. Every copy past the first doubles the ground the kart
## reaches rather than how far, so three reach four times as far rather than eight.


static func factor(copies: int) -> float:
	return 2.0 * sqrt(2.0) ** (copies - 1)


func modify_pickup_radius(radius: float) -> float:
	var copies := stacked()
	return radius * factor(copies) if copies > 0 else radius


func stack_values(copies: int) -> Dictionary:
	return {"times": figure(factor(copies))}
