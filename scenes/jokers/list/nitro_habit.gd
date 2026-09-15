extends Joker
## Nitro Habit: Drift exit boosts and turbo pads last twice as long.


func modify_kart_stats(stats: KartStats) -> void:
	stats.drift_exit_boost_duration *= 2.0
	stats.turbo_duration *= 2.0
