extends Joker
## Nitro Habit: Drift exit boosts and turbo pads last three times as long.


func modify_kart_stats(stats: KartStats) -> void:
	stats.drift_exit_boost_duration *= 3.0
	stats.turbo_duration *= 3.0
