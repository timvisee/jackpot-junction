extends Control
## The lobby from GAME.md 3.8: match length, target score, bot count and difficulty, with the
## document's values as defaults and the last choice remembered. Local joining arrives in M5.

const MINUTES: Array[int] = [3, 5, 8]
const TARGETS: Array[int] = [0, 2000, 3000, 5000]
const BOTS: Array[int] = [0, 1, 2, 3]
const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]

var minutes_option: OptionButton
var target_option: OptionButton
var bots_option: OptionButton
var difficulty_option: OptionButton
var start_button: Button


func _ready() -> void:
	MenuTheme.background(self)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	centre.add_child(column)
	column.add_child(MenuTheme.title("Lobby", 64))
	column.add_child(MenuTheme.subtitle("P1: keyboard or any gamepad"))
	var settings := Game.settings
	minutes_option = MenuTheme.option(
		_labels(MINUTES, "%d min"), MINUTES.find(settings.match_minutes)
	)
	target_option = MenuTheme.option(_target_labels(), TARGETS.find(settings.target_score))
	bots_option = MenuTheme.option(BOTS, BOTS.find(settings.bot_count))
	difficulty_option = MenuTheme.option(
		["Easy", "Normal", "Hard"], DIFFICULTIES.find(settings.difficulty)
	)
	column.add_child(MenuTheme.row("Match length", minutes_option))
	column.add_child(MenuTheme.row("Target score", target_option))
	column.add_child(MenuTheme.row("Bots", bots_option))
	column.add_child(MenuTheme.row("Bot difficulty", difficulty_option))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 24.0)
	column.add_child(spacer)
	start_button = MenuTheme.button("Start match")
	start_button.pressed.connect(_start)
	column.add_child(start_button)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(back)
	start_button.grab_focus()


## The configuration the current options describe.
func config() -> MatchConfig:
	var result := MatchConfig.new()
	result.duration = MINUTES[minutes_option.selected] * 60.0
	result.target_score = TARGETS[target_option.selected]
	result.bot_count = BOTS[bots_option.selected]
	result.difficulty = DIFFICULTIES[difficulty_option.selected]
	return result


func _start() -> void:
	var settings := Game.settings
	settings.match_minutes = MINUTES[minutes_option.selected]
	settings.target_score = TARGETS[target_option.selected]
	settings.bot_count = BOTS[bots_option.selected]
	settings.difficulty = DIFFICULTIES[difficulty_option.selected]
	settings.save_to_disk()
	Game.start_match(config())


func _labels(values: Array[int], format: String) -> Array:
	var result: Array = []
	for value: int in values:
		result.append(format % value)
	return result


func _target_labels() -> Array:
	var result: Array = ["Off"]
	for value: int in TARGETS.slice(1):
		result.append(str(value))
	return result
