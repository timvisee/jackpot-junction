class_name MatchConfig
extends RefCounted
## What the lobby hands to the match scene: who plays, how many bots, how hard, how long.

## Devices of the human players, see [DeviceInput]. One human on any device by default.
var human_devices: Array[int] = [DeviceInput.ANY]
## Colour index per human, in the same order; empty means slot order.
var human_colors: Array[int] = []
var bot_count := 3
var difficulty := "normal"
var duration := 300.0
## 0 disables the early finish.
var target_score := 3000
## "first" for the first power-up set, "all" for every power-up.
var item_set := "first"
## Whether a kart's own shots hurt it, GAME.md 5.1.
var own_bullets_hurt := false
## "", "host" or "join".
var online := ""
var address := "127.0.0.1"
var port := NetSession.DEFAULT_PORT


func inputs() -> Array[KartInput]:
	var result: Array[KartInput] = []
	for device: int in human_devices:
		result.append(PlayerInput.new(device))
	for i: int in bot_count:
		result.append(BotInput.new())
	return result


## Colour indices for every slot: the humans' picks, then the first free colours for bots.
func colors() -> Array[int]:
	var result: Array[int] = []
	for i: int in human_devices.size():
		result.append(human_colors[i] if i < human_colors.size() else i)
	var next := 0
	for i: int in bot_count:
		while next in result:
			next += 1
		result.append(next)
		next += 1
	return result


func rules(base: MatchRules) -> MatchRules:
	var copy: MatchRules = base.duplicate()
	copy.duration = duration
	copy.target_score = target_score if target_score > 0 else 1 << 30
	copy.own_bullets_hurt = own_bullets_hurt
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
	config.own_bullets_hurt = settings.own_bullets_hurt
	return config
