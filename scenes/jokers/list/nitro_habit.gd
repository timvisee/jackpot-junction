extends Joker
## Nitro Habit: Drift exit boosts and turbo pads last three times as long, and once as long again
## for every copy past the first.


static func factor(copies: int) -> int:
	return 2 + copies


func modify_kart_stats(stats: KartStats) -> void:
	var copies := stacked()
	if copies > 0:
		stats.drift_exit_boost_duration *= factor(copies)
		stats.turbo_duration *= factor(copies)


func stack_values(copies: int) -> Dictionary:
	return {"times": times(factor(copies))}
