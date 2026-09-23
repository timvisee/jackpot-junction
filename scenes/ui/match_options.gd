class_name MatchOptions
extends RefCounted
## What a match is going to be, as rows of choices, GAME.md 3.8: the arena, how long, how many
## points win it, how many bots and how hard, which items, whether a kart's own bullets hurt it,
## and what the clock running out does. Each starts on the last choice made, which [Settings]
## keeps between sessions.
##
## The lobby puts them in front of a local match and the waiting room of 9.6 in front of the host
## of an online one. They are the same questions with the same answers, so they are one piece
## rather than two copies that drift apart the first time one of them grows an option.

const MINUTES: Array[int] = [3, 5, 8]
## A minute, for a match somebody is testing rather than playing: long enough to reach the
## Junction and the results screen, short enough to do it again straight away. Only in a debug
## build, because it is not a length anybody wants a real game to be.
const DEBUG_MINUTES := 1
const TARGETS: Array[int] = [0, 2000, 3000, 5000]
const BOTS: Array[int] = [0, 1, 2, 3]
const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]
const ITEM_SETS: Array[String] = ["first", "all"]
## Index order of the own-bullets option: off first, so it is the default.
const OWN_BULLETS: Array[bool] = [false, true]
## Index order of the overtime option: on first, so it is the default.
const OVERTIME: Array[bool] = [true, false]

var map_option: OptionButton
var minutes_option: OptionButton
var target_option: OptionButton
var bots_option: OptionButton
var difficulty_option: OptionButton
var items_option: OptionButton
var own_bullets_option: OptionButton
var overtime_option: OptionButton

## Names the room the chosen map is played in, under the arena row.
var _room_label: Label


## Puts the rows into [param column], each set to what [param settings] last had.
static func add_to(column: Container, settings: Settings) -> MatchOptions:
	var options := MatchOptions.new()
	options._build(column, settings)
	return options


## The match lengths on offer, shortest first. A debug build gets the one-minute match in front
## of the real ones, where somebody testing will find it without hunting.
static func match_lengths() -> Array[int]:
	if not OS.is_debug_build():
		return MINUTES
	var with_short: Array[int] = [DEBUG_MINUTES]
	with_short.append_array(MINUTES)
	return with_short


## One line saying what a match is going to be: where, how long, to how many points, and how
## many bots. What somebody waiting to play it wants to know, and nothing they do not.
static func describe(config: MatchConfig) -> String:
	var parts: PackedStringArray = [
		ArenaMaps.NAMES[ArenaMaps.index_of(config.map)],
		"%d min" % roundi(config.duration / 60.0),
		"first to %d" % config.target_score if config.target_score > 0 else "no target",
	]
	match config.bot_count:
		0:
			parts.append("no bots")
		1:
			parts.append("1 bot")
		_:
			parts.append("%d bots" % config.bot_count)
	return " \u00b7 ".join(parts)


## Writes the choices into [param config]. The bots are the number asked for; how many of them
## there is room for is the caller's to say, since only it knows who else is playing.
func apply_to(config: MatchConfig) -> void:
	config.map = ArenaMaps.id_at(map_option.selected)
	config.duration = match_lengths()[minutes_option.selected] * 60.0
	config.target_score = TARGETS[target_option.selected]
	config.bot_count = BOTS[bots_option.selected]
	config.difficulty = DIFFICULTIES[difficulty_option.selected]
	config.item_set = ITEM_SETS[items_option.selected]
	config.own_bullets_hurt = OWN_BULLETS[own_bullets_option.selected]
	config.overtime = OVERTIME[overtime_option.selected]


## Keeps the choices for next time. Not written to disk here: the caller saves once, with
## whatever else it has to keep.
func remember(settings: Settings) -> void:
	settings.map = String(ArenaMaps.id_at(map_option.selected))
	settings.match_minutes = match_lengths()[minutes_option.selected]
	settings.target_score = TARGETS[target_option.selected]
	settings.bot_count = BOTS[bots_option.selected]
	settings.difficulty = DIFFICULTIES[difficulty_option.selected]
	settings.item_set = ITEM_SETS[items_option.selected]
	settings.own_bullets_hurt = OWN_BULLETS[own_bullets_option.selected]
	settings.overtime = OVERTIME[overtime_option.selected]


func _build(column: Container, settings: Settings) -> void:
	var lengths := match_lengths()
	minutes_option = MenuTheme.option(
		_labels(lengths, "%d min"), maxi(lengths.find(settings.match_minutes), 0)
	)
	target_option = MenuTheme.option(_target_labels(), TARGETS.find(settings.target_score))
	bots_option = MenuTheme.option(BOTS, BOTS.find(settings.bot_count))
	difficulty_option = MenuTheme.option(
		["Easy", "Normal", "Hard"], DIFFICULTIES.find(settings.difficulty)
	)
	items_option = MenuTheme.option(["First set", "All items"], ITEM_SETS.find(settings.item_set))
	map_option = MenuTheme.option(ArenaMaps.NAMES, ArenaMaps.index_of(StringName(settings.map)))
	column.add_child(MenuTheme.row("Arena", map_option))
	# Which room that map is played in, GAME.md 8.1: three of them, and a player picking a map
	# is picking a place as much as a floor plan.
	_room_label = MenuTheme.subtitle("", Type.LABEL)
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(_room_label)
	map_option.item_selected.connect(func(_index: int) -> void: _show_room())
	_show_room()
	column.add_child(MenuTheme.row("Match length", minutes_option))
	column.add_child(MenuTheme.row("Target score", target_option))
	column.add_child(MenuTheme.row("Bots", bots_option))
	column.add_child(MenuTheme.row("Bot difficulty", difficulty_option))
	column.add_child(MenuTheme.row("Items", items_option))
	own_bullets_option = MenuTheme.option(
		["Stop harmlessly", "Are deadly"], OWN_BULLETS.find(settings.own_bullets_hurt)
	)
	column.add_child(MenuTheme.row("Your own bullets", own_bullets_option))
	overtime_option = MenuTheme.option(
		["Last one standing", "Match ends"], OVERTIME.find(settings.overtime)
	)
	column.add_child(MenuTheme.row("Out of time", overtime_option))


## The room behind the chosen map, named under the row that chose it.
func _show_room() -> void:
	var layout := ArenaMaps.layout(ArenaMaps.id_at(map_option.selected))
	var room := layout.room if layout.room != null else RoomLook.fallback()
	_room_label.text = "Played in %s" % room.display_name


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
