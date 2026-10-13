class_name MatchOptions
extends RefCounted
## What a match is going to be, as rows of choices, GAME.md 3.8: the arena, how long, how many
## points win it, how many bots and how hard, which items, whether a kart's own bullets hurt it,
## whether it is played in teams and whether teammates hurt each other, and what the clock running
## out does. Each starts on the last choice made, which [Settings]
## keeps between sessions.
##
## The lobby puts them in front of a local match and the waiting room of 9.6 in front of the host
## of an online one. They are the same questions with the same answers, so they are one piece
## rather than two copies that drift apart the first time one of them grows an option.
##
## The two big buttons over the rows say what is being set up, GAME.md 9.7: a Grand Prix or a
## quick match. Which of them is chosen changes the rows under them. A quick match picks its
## arena; a Grand Prix, whose arenas are dealt when it starts, asks how many maps instead, what
## jokers carry between them, and whether a tie at the end is played out, 9.7a.

## How long a map runs, in seconds. A minute is a quick one, for a Grand Prix of several maps
## as much as for a short game.
const LENGTHS: Array[int] = [60, 180, 300, 480]
## Five seconds, for a map somebody is testing rather than playing: straight through to the
## podium, to check what comes after it. Only in a debug build, because it is not a length
## anybody wants a real game to be.
const DEBUG_LENGTH := 5
const TARGETS: Array[int] = [0, 2000, 3000, 5000]
## How many bots a match may ask for, GAME.md 3.8: the row offers as many of them as the arena has
## seats for beside one player, see [method fit_seats].
const BOTS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]
const ITEM_SETS: Array[String] = ["first", "all"]
## Index order of the own-bullets option: off first, so it is the default.
const OWN_BULLETS: Array[bool] = [false, true]
## Index order of the overtime option: on first, so it is the default.
const OVERTIME: Array[bool] = [true, false]
## Index order of the friendly fire option, GAME.md 3.14: off first, so it is the default.
const FRIENDLY_FIRE: Array[bool] = [false, true]
## How many jokers a hand may hold, GAME.md 3.7: five to start with.
const JOKER_SLOTS: Array[int] = [3, 4, 5, 6, 7, 8]
## How many maps a Grand Prix can run, GAME.md 9.7.
const MAPS: Array[int] = [2, 3, 4, 5, 6]
## What of their jokers players take from one map of a Grand Prix to the next, in the order of
## [enum GrandPrix.Keep].
const KEEPS: Array[String] = ["Discard all", "Pick one to keep", "Keep one at random", "Keep all"]

## How long after the settings come up the first value is blacked out, and how long between one
## and the next, see [method redact].
const REDACT_FIRST := 0.25
const REDACT_EACH := 0.07

var map_option: OptionButton
var minutes_option: OptionButton
var target_option: OptionButton
var bots_option: OptionButton
var difficulty_option: OptionButton
var items_option: OptionButton
var own_bullets_option: OptionButton
var overtime_option: OptionButton
## Whether the match is played in teams and how many, one of [constant Teams.COUNTS], and whether
## teammates hurt each other, GAME.md 3.14: a question only while there are teams.
var teams_option: OptionButton
var friendly_fire_option: OptionButton
var slots_option: OptionButton
## The choice between a Grand Prix and a quick match.
var mode_picker: GameModePicker
var maps_option: OptionButton
var jokers_option: OptionButton
## Whether karts level on points at the end of a Grand Prix play a showdown, GAME.md 9.7a.
var tie_toggle: CheckButton
## Which sizes of map a Grand Prix deals from, GAME.md 9.7. One of the two is always on: turning
## off the last turns the other one on.
var normal_toggle: CheckButton
var xl_toggle: CheckButton
## Whether a map at the usual size is played as picked with more than four karts on it, GAME.md
## 6.3, rather than as its XL. Only a question once the arena has seats for more than four.
var small_maps_toggle: CheckButton

## The maps the arena row offers, in its order, see [method ArenaMaps.offered]: an item's index in
## the row is its index here, not in [constant ArenaMaps.IDS].
var _map_ids: Array[StringName] = []
## Names the room the chosen map is played in, under the arena row, and the XL it is played as
## with more than four karts on it.
var _room_label: Label
var _xl_label: Label
var _small_maps_row: Control
var _friendly_fire_row: Control
## How many seats the arena will have, see [method fit_seats].
var _seats := SeatLimit.SEATS
## The rows that come and go with the choice between a Grand Prix and a single map, and the label
## of the length row, which is per map in one and for the match in the other.
var _arena_row: Control
var _maps_row: Control
var _jokers_row: Control
var _tie_row: Control
var _sizes_rows: Array[Control] = []
var _length_label: Label
## How many bots were last asked for, which the row comes back to when it has room for them again,
## and how many it last showed, to tell a choice made since from one it made itself.
var _bots_wanted := 3
var _bots_shown := 3


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


## One line saying what a match is going to be: where, how long and to how many points. What
## somebody waiting to play it wants to know, and nothing they do not. A Grand Prix says how many
## maps rather than which, since which is not dealt until it starts. The bots are the ready count's
## to say, GAME.md 9.6: how many come in depends on who is in the room, which this line cannot know.
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
	if config.teams > 0:
		parts.append("%d teams" % config.teams)
	return " \u00b7 ".join(parts)


## What the rows chose for [param config], as it goes over the wire from a player hosting a game of
## a dedicated server to the server, GAME.md 9.3a.
static func to_wire(config: MatchConfig) -> Dictionary:
	return {
		"map": String(config.map),
		"rounds": config.rounds,
		"keep_jokers": config.keep_jokers,
		"normal_maps": config.normal_maps,
		"xl_maps": config.xl_maps,
		"tie_breaker": config.tie_breaker,
		"small_maps": config.small_maps,
		"duration": roundi(config.duration),
		"target_score": config.target_score,
		"bot_count": config.bot_count,
		"difficulty": config.difficulty,
		"item_set": config.item_set,
		"own_bullets_hurt": config.own_bullets_hurt,
		"overtime": config.overtime,
		"teams": config.teams,
		"friendly_fire": config.friendly_fire,
		"joker_slots": config.joker_slots,
	}


## [param plan] off the wire into [param config], as far as the rows could have said it: the other
## end sends what it likes, and a value no row offers leaves what [param config] had.
static func from_wire(config: MatchConfig, plan: Dictionary) -> void:
	var map := StringName(str(plan.get("map", "")))
	if map in ArenaMaps.IDS:
		config.map = map
	var rounds := int(plan.get("rounds", -1))
	if rounds == 0 or rounds in MAPS:
		config.rounds = rounds
	var keep := int(plan.get("keep_jokers", -1))
	if keep >= 0 and keep < KEEPS.size():
		config.keep_jokers = keep as GrandPrix.Keep
	config.normal_maps = bool(plan.get("normal_maps", config.normal_maps))
	config.xl_maps = bool(plan.get("xl_maps", config.xl_maps))
	config.tie_breaker = bool(plan.get("tie_breaker", config.tie_breaker))
	config.small_maps = bool(plan.get("small_maps", config.small_maps))
	var seconds := int(plan.get("duration", -1))
	if seconds in match_lengths():
		config.duration = float(seconds)
	var target := int(plan.get("target_score", -1))
	if target in TARGETS:
		config.target_score = target
	var bots := int(plan.get("bot_count", -1))
	if bots in BOTS:
		config.bot_count = bots
	var difficulty := str(plan.get("difficulty", ""))
	if difficulty in DIFFICULTIES:
		config.difficulty = difficulty
	var items := str(plan.get("item_set", ""))
	if items in ITEM_SETS:
		config.item_set = items
	config.own_bullets_hurt = bool(plan.get("own_bullets_hurt", config.own_bullets_hurt))
	config.overtime = bool(plan.get("overtime", config.overtime))
	var teams := int(plan.get("teams", -1))
	if teams in Teams.COUNTS:
		config.teams = teams
	config.friendly_fire = bool(plan.get("friendly_fire", config.friendly_fire))
	var slots := int(plan.get("joker_slots", -1))
	if slots in JOKER_SLOTS:
		config.joker_slots = slots


## Writes the choices into [param config]. The bots are the number asked for; how many of them
## there is room for is the caller's to say, since only it knows who else is playing.
func apply_to(config: MatchConfig) -> void:
	config.map = _map_id()
	config.rounds = MAPS[maps_option.selected] if is_grand_prix() else 0
	config.keep_jokers = jokers_option.selected as GrandPrix.Keep
	config.normal_maps = normal_toggle.button_pressed
	config.xl_maps = xl_toggle.button_pressed
	config.tie_breaker = tie_toggle.button_pressed
	config.small_maps = small_maps_toggle.button_pressed
	config.duration = float(match_lengths()[minutes_option.selected])
	config.target_score = TARGETS[target_option.selected]
	config.bot_count = BOTS[bots_option.selected]
	config.difficulty = DIFFICULTIES[difficulty_option.selected]
	config.item_set = ITEM_SETS[items_option.selected]
	config.own_bullets_hurt = OWN_BULLETS[own_bullets_option.selected]
	config.overtime = OVERTIME[overtime_option.selected]
	config.teams = Teams.COUNTS[teams_option.selected]
	config.friendly_fire = FRIENDLY_FIRE[friendly_fire_option.selected]
	config.joker_slots = JOKER_SLOTS[slots_option.selected]


## Keeps the choices for next time. Not written to disk here: the caller saves once, with
## whatever else it has to keep.
func remember(settings: Settings) -> void:
	settings.map = String(_map_id())
	settings.match_seconds = match_lengths()[minutes_option.selected]
	settings.target_score = TARGETS[target_option.selected]
	settings.bot_count = BOTS[bots_option.selected]
	settings.difficulty = DIFFICULTIES[difficulty_option.selected]
	settings.item_set = ITEM_SETS[items_option.selected]
	settings.own_bullets_hurt = OWN_BULLETS[own_bullets_option.selected]
	settings.overtime = OVERTIME[overtime_option.selected]
	settings.teams = Teams.COUNTS[teams_option.selected]
	settings.friendly_fire = FRIENDLY_FIRE[friendly_fire_option.selected]
	settings.joker_slots = JOKER_SLOTS[slots_option.selected]
	settings.grand_prix_maps = MAPS[maps_option.selected]
	settings.grand_prix_jokers = jokers_option.selected
	settings.grand_prix_normal = normal_toggle.button_pressed
	settings.grand_prix_xl = xl_toggle.button_pressed
	settings.grand_prix_tie_breaker = tie_toggle.button_pressed
	settings.small_maps = small_maps_toggle.button_pressed
	settings.grand_prix = is_grand_prix()


## Shows [param config] in the rows, as the House sets the table, STORY.md 8.1: a quick match on
## its map, which the list is given if it does not offer it yet, and the rest as it is set.
func show(config: MatchConfig) -> void:
	var map := ArenaMaps.id_at(ArenaMaps.index_of(config.map))
	if map not in _map_ids:
		_map_ids.append(map)
		map_option.add_item(ArenaMaps.NAMES[ArenaMaps.index_of(map)])
	map_option.select(_map_ids.find(map))
	choose(config.rounds > 0)
	minutes_option.select(maxi(match_lengths().find(roundi(config.duration)), 0))
	target_option.select(maxi(TARGETS.find(config.target_score), 0))
	_bots_wanted = config.bot_count
	fit_seats(_seats)
	difficulty_option.select(maxi(DIFFICULTIES.find(config.difficulty), 0))
	items_option.select(maxi(ITEM_SETS.find(config.item_set), 0))
	own_bullets_option.select(maxi(OWN_BULLETS.find(config.own_bullets_hurt), 0))
	overtime_option.select(maxi(OVERTIME.find(config.overtime), 0))
	teams_option.select(maxi(Teams.COUNTS.find(config.teams), 0))
	friendly_fire_option.select(maxi(FRIENDLY_FIRE.find(config.friendly_fire), 0))
	_show_teams()
	slots_option.select(maxi(JOKER_SLOTS.find(config.joker_slots), 0))
	small_maps_toggle.button_pressed = config.small_maps
	tie_toggle.button_pressed = config.tie_breaker
	_show_room()


## Every row shown and none of them to be changed, for a table the House has set.
func lock() -> void:
	for row: Control in [
		map_option,
		minutes_option,
		target_option,
		bots_option,
		difficulty_option,
		items_option,
		own_bullets_option,
		overtime_option,
		teams_option,
		friendly_fire_option,
		slots_option,
		maps_option,
		jokers_option,
	]:
		(row as OptionButton).disabled = true
	for toggle: CheckButton in [normal_toggle, xl_toggle, small_maps_toggle, tie_toggle]:
		toggle.disabled = true
	mode_picker.locked = true


## Every value under a black marker bar of its own, the kind of game, the map and the room it is
## played in too, drawn on one after another down the rows, STORY.md 8.1: the settings are there,
## and the player is not to know what they are. The labels are left to read.
func redact() -> void:
	var values: Array[Control] = [
		mode_picker.button(true),
		mode_picker.button(false),
		map_option,
		_room_label,
		_xl_label,
		minutes_option,
		target_option,
		bots_option,
		difficulty_option,
		items_option,
		own_bullets_option,
		overtime_option,
		teams_option,
		friendly_fire_option,
		slots_option,
		maps_option,
		jokers_option,
		tie_toggle,
		normal_toggle,
		xl_toggle,
		small_maps_toggle,
	]
	for i: int in values.size():
		RedactionBar.over(values[i], REDACT_FIRST + REDACT_EACH * float(i))


## Offers as many bots as an arena of [param seats] has seats for beside one player, GAME.md 3.8:
## up to three on one machine, and up to seven in a lobby for eight. The bots last asked for are
## chosen again as far as there is room for them.
func fit_seats(seats: int) -> void:
	if bots_option.selected != _bots_shown:
		_bots_wanted = maxi(bots_option.selected, 0)
	var most := clampi(seats - 1, 0, BOTS.size() - 1)
	if bots_option.item_count != most + 1:
		bots_option.clear()
		for count: int in BOTS.slice(0, most + 1):
			bots_option.add_item(str(count))
	_bots_shown = mini(_bots_wanted, most)
	bots_option.select(_bots_shown)
	# Whether a small map is too small is a question only a room of more than four asks.
	_seats = seats
	_small_maps_row.visible = seats > SeatLimit.SEATS
	_show_room()


## Whether these rows are setting up a Grand Prix rather than a quick match.
func is_grand_prix() -> bool:
	return mode_picker.grand_prix


## Sets up a Grand Prix, or a quick match, as pressing its button does.
func choose(grand_prix: bool) -> void:
	mode_picker.grand_prix = grand_prix
	_show_mode()


func _build(column: Container, settings: Settings) -> void:
	var lengths := match_lengths()
	var named: Array = []
	for seconds: int in lengths:
		named.append(length_words(seconds))
	minutes_option = MenuTheme.option(named, maxi(lengths.find(settings.match_seconds), 0))
	target_option = MenuTheme.option(_target_labels(), TARGETS.find(settings.target_score))
	_bots_wanted = clampi(settings.bot_count, 0, BOTS[-1])
	_bots_shown = _bots_wanted
	bots_option = MenuTheme.option(BOTS, _bots_wanted)
	difficulty_option = MenuTheme.option(
		["Easy", "Normal", "Hard"], DIFFICULTIES.find(settings.difficulty)
	)
	items_option = MenuTheme.option(["Basic items", "All items"], ITEM_SETS.find(settings.item_set))
	# House Rules only for a profile that has played the Final Hand, STORY.md 10, and the Showdown
	# only in a debug build, GAME.md 6.3.
	_map_ids = ArenaMaps.offered(Game.settings.profile)
	var offered: Array = []
	for id: StringName in _map_ids:
		offered.append(ArenaMaps.NAMES[ArenaMaps.index_of(id)])
	map_option = MenuTheme.option(offered, maxi(_map_ids.find(StringName(settings.map)), 0))
	maps_option = MenuTheme.option(
		_labels(MAPS, "%d maps"), maxi(MAPS.find(settings.grand_prix_maps), 0)
	)
	mode_picker = GameModePicker.make(settings.grand_prix)
	mode_picker.chosen.connect(func(_grand_prix: bool) -> void: _show_mode())
	column.add_child(mode_picker)
	_maps_row = MenuTheme.row("Maps", maps_option)
	column.add_child(_maps_row)
	# Only a Grand Prix has a next map to take anything on to.
	jokers_option = MenuTheme.option(KEEPS, clampi(settings.grand_prix_jokers, 0, KEEPS.size() - 1))
	_jokers_row = MenuTheme.row("Jokers between maps", jokers_option)
	column.add_child(_jokers_row)
	tie_toggle = MenuTheme.toggle(settings.grand_prix_tie_breaker)
	_tie_row = MenuTheme.row("Tie-breaker", tie_toggle)
	column.add_child(_tie_row)
	normal_toggle = MenuTheme.toggle(settings.grand_prix_normal or not settings.grand_prix_xl)
	xl_toggle = MenuTheme.toggle(settings.grand_prix_xl)
	for pair: Array in [[normal_toggle, xl_toggle], [xl_toggle, normal_toggle]]:
		var this: CheckButton = pair[0]
		var other: CheckButton = pair[1]
		this.toggled.connect(
			func(on: bool) -> void:
				if not on and not other.button_pressed:
					other.button_pressed = true
		)
	for labeled: Array in [["Normal maps", normal_toggle], ["XL maps", xl_toggle]]:
		var row := MenuTheme.row(labeled[0], labeled[1])
		_sizes_rows.append(row)
		column.add_child(row)
	var arena := VBoxContainer.new()
	arena.add_child(MenuTheme.row("Arena", map_option))
	# Which room that map is played in, GAME.md 8.1: three of them, a map and its XL in the same
	# one, and a player picking a map is picking a place as much as a floor plan.
	_room_label = MenuTheme.subtitle("", Type.LABEL)
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	arena.add_child(_room_label)
	_xl_label = MenuTheme.subtitle("", Type.LABEL)
	_xl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	arena.add_child(_xl_label)
	_arena_row = arena
	column.add_child(_arena_row)
	small_maps_toggle = MenuTheme.toggle(settings.small_maps)
	_small_maps_row = MenuTheme.row("Small maps for 5+ karts", small_maps_toggle)
	column.add_child(_small_maps_row)
	map_option.item_selected.connect(func(_index: int) -> void: _show_room())
	small_maps_toggle.toggled.connect(func(_on: bool) -> void: _show_room())
	var length := MenuTheme.row("Match length", minutes_option)
	_length_label = length.get_child(0) as Label
	column.add_child(length)
	_show_mode()
	column.add_child(MenuTheme.row("Target score", target_option))
	column.add_child(MenuTheme.row("Bots", bots_option))
	column.add_child(MenuTheme.row("Bot difficulty", difficulty_option))
	# Teams, and under them whether teammates can hurt each other, GAME.md 3.14.
	var team_names: Array = ["Off"]
	team_names.append_array(_labels(Teams.COUNTS.slice(1), "%d teams"))
	teams_option = MenuTheme.option(team_names, maxi(Teams.COUNTS.find(settings.teams), 0))
	teams_option.item_selected.connect(func(_index: int) -> void: _show_teams())
	column.add_child(MenuTheme.row("Teams", teams_option))
	friendly_fire_option = MenuTheme.option(
		["Off", "On"], FRIENDLY_FIRE.find(settings.friendly_fire)
	)
	_friendly_fire_row = MenuTheme.row("Friendly fire", friendly_fire_option)
	column.add_child(_friendly_fire_row)
	_show_teams()
	# The later set is the loyalty program's to add, GAME.md 8.9: no choice until it has added one.
	var items_row := MenuTheme.row("Items", items_option)
	items_row.visible = not Loyalty.unlocks_of(Game.settings.profile)["items"].is_empty()
	if not items_row.visible:
		items_option.select(0)
	column.add_child(items_row)
	slots_option = MenuTheme.option(
		_labels(JOKER_SLOTS, "%d jokers"), maxi(JOKER_SLOTS.find(settings.joker_slots), 0)
	)
	column.add_child(MenuTheme.row("Joker slots", slots_option))
	own_bullets_option = MenuTheme.option(
		["Harmless", "Deadly"], OWN_BULLETS.find(settings.own_bullets_hurt)
	)
	column.add_child(MenuTheme.row("Your own bullets", own_bullets_option))
	overtime_option = MenuTheme.option(
		["Last one standing", "Match ends"], OVERTIME.find(settings.overtime)
	)
	column.add_child(MenuTheme.row("Out of time", overtime_option))
	fit_seats(SeatLimit.SEATS)


## Shows the rows that go with what is being set up: the arena for a single map, the number of
## maps for a Grand Prix, and a length that says it is per map when there are several.
func _show_mode() -> void:
	var several := is_grand_prix()
	_arena_row.visible = not several
	_maps_row.visible = several
	_jokers_row.visible = several
	_tie_row.visible = several
	for row: Control in _sizes_rows:
		row.visible = several
	_length_label.text = "Time per map" if several else "Match length"


## Friendly fire is a question only a match played in teams asks, GAME.md 3.14.
func _show_teams() -> void:
	_friendly_fire_row.visible = teams_option.selected > 0


## The room behind the chosen map, named under the row that chose it, and in a room of more than
## four the XL it is played as with five karts or more on it, GAME.md 6.3.
func _show_room() -> void:
	var id := _map_id()
	var layout := ArenaMaps.layout(id)
	var room := layout.room if layout.room != null else RoomLook.fallback()
	_room_label.text = "Played in %s" % room.display_name
	var xl := ArenaMaps.xl_of(id)
	var named := ArenaMaps.NAMES[ArenaMaps.index_of(xl)]
	_xl_label.text = "With 5+ karts it plays as %s" % named
	_xl_label.visible = (
		_seats > SeatLimit.SEATS and not small_maps_toggle.button_pressed and xl != id
	)


## The map the arena row has chosen.
func _map_id() -> StringName:
	return _map_ids[clampi(map_option.selected, 0, _map_ids.size() - 1)]


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
