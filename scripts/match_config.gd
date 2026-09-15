class_name MatchConfig
extends RefCounted
## What the lobby hands to the match scene: who plays, how many bots, how hard, how long.

## Devices of the human players, see [DeviceInput]. One human on any device by default.
var human_devices: Array[int] = [DeviceInput.ANY]
var bot_count := 3
var difficulty := "normal"
var duration := 300.0
## 0 disables the early finish.
var target_score := 3000
## "first" for the first power-up set, "all" for every power-up.
var item_set := "first"


func inputs() -> Array[KartInput]:
	var result: Array[KartInput] = []
	for device: int in human_devices:
		result.append(PlayerInput.new(device))
	for i: int in bot_count:
		result.append(BotInput.new())
	return result


func rules(base: MatchRules) -> MatchRules:
	var copy: MatchRules = base.duplicate()
	copy.duration = duration
	copy.target_score = target_score if target_score > 0 else 1 << 30
	return copy


func power_ups() -> PowerUpTable:
	return load("res://data/powerups/%s.tres" % ("all" if item_set == "all" else "first_set"))


static func from_settings(settings: Settings) -> MatchConfig:
	var config := MatchConfig.new()
	config.bot_count = settings.bot_count
	config.difficulty = settings.difficulty
	config.duration = settings.match_minutes * 60.0
	config.target_score = settings.target_score
	config.item_set = settings.item_set
	return config
