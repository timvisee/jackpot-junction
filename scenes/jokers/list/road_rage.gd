extends Joker
## Road Rage: Ramming above 90% of top speed kills without Boost, but top speed is -10%.


func modify_kart_stats(stats: KartStats) -> void:
	stats.top_speed *= 0.9


func ram_kills(kart: Kart) -> bool:
	return kart.motor.speed_fraction() >= 0.9
