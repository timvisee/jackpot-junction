extends Joker
## Snowball: the cannon fires 10% more often for every kill in this life, up to half as often again,
## GAME.md 7.3. Counted where the kills are, the host online, and a death starts it again.

## How much more often a kill makes the cannon fire, and the most kills that count.
const PER_KILL := 0.1
const MOST_KILLS := 5

var _kills := 0


func on_victim_death(killer: Kart, _victim: Kart, _death: DeathOutcome) -> void:
	if _kills < MOST_KILLS:
		_kills += 1
		killer.rebuild_stats()


func on_death(kart: Kart) -> void:
	if _kills > 0:
		_kills = 0
		kart.rebuild_stats()


func modify_cannon_stats(stats: CannonStats) -> void:
	if _kills > 0:
		stats.fire_cooldown /= 1.0 + PER_KILL * _kills
