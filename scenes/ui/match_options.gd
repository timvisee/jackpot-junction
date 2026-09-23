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
##
## The first row says what is being set up, GAME.md 9.7: a Grand Prix or a quick match. It
## changes one row under it. A quick match picks its arena; a Grand Prix, whose arenas are dealt
## when it starts, asks how many maps instead, and what jokers carry between them.

## How long a map runs, in seconds. A minute is a quick one, for a Grand Prix of several maps
## as much as for a short game.
const LENGTHS: Array[int] = [60, 180, 300, 480]
## Five seconds, for a map somebody is testing rather than playing: straight through to the
## podium, to check what comes after it. Only in a debug build, because it is not a length
## anybody wants a real game to be.
const DEBUG_LENGTH := 5
const TARGETS: Array[int] = [0, 2000, 3000, 5000]
const BOTS: Array[int] = [0, 1, 2, 3]
const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]
const ITEM_SETS: Array[String] = ["first", "all"]
## Index order of the own-bullets option: off first, so it is the default.
const OWN_BULLETS: Array[bool] = [false, true]
## Index order of the overtime option: on first, so it is the default.
const OVERTIME: Array[bool] = [true, false]
## How many maps a Grand Prix can run, GAME.md 9.7.
const MAPS: Array[int] = [2, 3, 4, 5, 6]
## What of their jokers players take from one map of a Grand Prix to the next, in the order of
## [enum GrandPrix.Keep].
const KEEPS: Array[String] = ["Discard all", "Pick one to keep", "Keep one at random", "Keep all"]

var map_option: OptionButton
var minutes_option: OptionButton
var target_option: OptionButton
var bots_option: OptionButton
var difficulty_option: OptionButton
var items_option: OptionButton
var own_bullets_option: OptionButton
var overtime_option: OptionButton
## The choice between a Grand Prix and a quick match.
var mode_option: OptionButton
var maps_option: OptionButton
var jokers_option: OptionButton

## Names the room the chosen map is played in, under the arena row.
var _room_label: Label
## The rows that come and go with the choice between a Grand Prix and a single map, and the label
## of the length row, which is per map in one and for the match in the other.
var _arena_row: Control
var _maps_row: Control
var _jokers_row: Control
var _length_label: Label


## Puts the rows into [param column], each set to what [param settings] last had.
static func add_to(column: Container, settings: Settings) -> MatchOptions:
	var options := MatchOptions.new()
	options._build(column, settings)
	return options


## The map lengths on offer in seconds, shortest first. A debug build gets the five-second one
## in front of the real ones, where somebody testing will find it without hunting.
static func match_lengths() -> Array[int]:
	if not OS.is_debug_build():
		return LENGTHS
	var with_short: Array[int] = [DEBUG_LENGTH]
	with_short.append_array(LENGTHS)
	return with_short


## A length said the way the row says it: seconds under a minute, minutes from there.
static func length_words(seconds: float) -> String:
	var whole := roundi(seconds)
	return "%d s" % whole if whole < 60 else "%d min" % roundi(whole / 60.0)


## One line saying what a match is going to be: where, how long, to how many points, and how
## many bots. What somebody waiting to play it wants to know, and nothing they do not. A Grand
## Prix says how many maps rather than which, since which is not dealt until it starts.
static func describe(config: MatchConfig) -> String:
	var length := length_words(config.duration)
	var parts: PackedStringArray = [
		(
			"Grand Prix of %d maps" % config.rounds
			if config.rounds > 0
			else ArenaMaps.NAMES[ArenaMaps.index_of(config.map)]
		),
		"%s each" % length if config.rounds > 0 else length,
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
	config.rounds = MAPS[maps_option.selected] if is_grand_prix() else 0
	config.keep_jokers = jokers_option.selected as GrandPrix.Keep
	config.duration = float(match_lengths()[minutes_option.selected])
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
	settings.match_seconds = match_lengths()[minutes_option.selected]
	settings.target_score = TARGETS[target_option.selected]
	settings.bot_count = BOTS[bots_option.selected]
	settings.difficulty = DIFFICULTIES[difficulty_option.selected]
	settings.item_set = ITEM_SETS[items_option.selected]
	settings.own_bullets_hurt = OWN_BULLETS[own_bullets_option.selected]
	settings.overtime = OVERTIME[overtime_option.selected]
	settings.grand_prix_maps = MAPS[maps_option.selected]
	settings.grand_prix_jokers = jokers_option.selected
	settings.grand_prix = is_grand_prix()


## Whether these rows are setting up a Grand Prix rather than a quick match.
func is_grand_prix() -> bool:
	return mode_option.selected == 0


func _build(column: Container, settings: Settings) -> void:
	var lengths := match_lengths()
	var named: Array = []
	for seconds: int in lengths:
		named.append(length_words(seconds))
	minutes_option = MenuTheme.option(named, maxi(lengths.find(settings.match_seconds), 0))
	target_option = MenuTheme.option(_target_labels(), TARGETS.find(settings.target_score))
	bots_option = MenuTheme.option(BOTS, BOTS.find(settings.bot_count))
	difficulty_option = MenuTheme.option(
		["Easy", "Normal", "Hard"], DIFFICULTIES.find(settings.difficulty)
	)
	items_option = MenuTheme.option(["Basic items", "All items"], ITEM_SETS.find(settings.item_set))
	map_option = MenuTheme.option(ArenaMaps.NAMES, ArenaMaps.index_of(StringName(settings.map)))
	maps_option = MenuTheme.option(
		_labels(MAPS, "%d maps"), maxi(MAPS.find(settings.grand_prix_maps), 0)
	)
	mode_option = MenuTheme.option(["Grand Prix", "Quick match"], 0 if settings.grand_prix else 1)
	mode_option.item_selected.connect(func(_index: int) -> void: _show_mode())
	column.add_child(MenuTheme.row("Game", mode_option))
	_maps_row = MenuTheme.row("Maps", maps_option)
	column.add_child(_maps_row)
	# Only a Grand Prix has a next map to take anything on to.
	jokers_option = MenuTheme.option(KEEPS, clampi(settings.grand_prix_jokers, 0, KEEPS.size() - 1))
	_jokers_row = MenuTheme.row("Jokers between maps", jokers_option)
	column.add_child(_jokers_row)
	var arena := VBoxContainer.new()
	arena.add_child(MenuTheme.row("Arena", map_option))
	# Which room that map is played in, GAME.md 8.1: three of them, and a player picking a map
	# is picking a place as much as a floor plan.
	_room_label = MenuTheme.subtitle("", Type.LABEL)
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	arena.add_child(_room_label)
	_arena_row = arena
	column.add_child(_arena_row)
	map_option.item_selected.connect(func(_index: int) -> void: _show_room())
	_show_room()
	var length := MenuTheme.row("Match length", minutes_option)
	_length_label = length.get_child(0) as Label
	column.add_child(length)
	_show_mode()
	column.add_child(MenuTheme.row("Target score", target_option))
	column.add_child(MenuTheme.row("Bots", bots_option))
	column.add_child(MenuTheme.row("Bot difficulty", difficulty_option))
	column.add_child(MenuTheme.row("Items", items_option))
	own_bullets_option = MenuTheme.option(
		["Harmless", "Deadly"], OWN_BULLETS.find(settings.own_bullets_hurt)
	)
	column.add_child(MenuTheme.row("Your own bullets", own_bullets_option))
	overtime_option = MenuTheme.option(
		["Last one standing", "Match ends"], OVERTIME.find(settings.overtime)
	)
	column.add_child(MenuTheme.row("Out of time", overtime_option))


## Shows the rows that go with what is being set up: the arena for a single map, the number of
## maps for a Grand Prix, and a length that says it is per map when there are several.
func _show_mode() -> void:
	var several := is_grand_prix()
	_arena_row.visible = not several
	_maps_row.visible = several
	_jokers_row.visible = several
	_length_label.text = "Time per map" if several else "Match length"


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
