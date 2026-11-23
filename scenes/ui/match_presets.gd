class_name MatchPresets
extends RefCounted
## The presets over the match settings' columns, GAME.md 9.6: each sets every one of House rules'
## rows at once, but for what jokers a Grand Prix carries between its maps, and the cards on the
## table, 3.17, and leaves The floor alone. Nothing here is kept: which one is lit is read off the
## rows, see [method matching].

## What each preset is called, the line under its name, the face of its chip, and the rows it
## sets: how long a map runs in seconds, the target, the joker slots, whether all items rather than
## the basic set, whether a kart's own bullets hurt it, whether the clock running out plays on, and
## whether a trailing player is helped to catch up, which Cutthroat alone turns off; and the table,
## 3.17: the cards it turns face down of those opened, and whether each map deals its own.
const PRESETS: Array[Dictionary] = [
	{
		"name": "Penny table",
		"line": "3 min · power-ups only",
		"face": Color("#B8733A"),
		"seconds": 180,
		"target": 1500,
		"slots": 5,
		"all_items": false,
		"own_bullets": false,
		"overtime": false,
		"catch_up": true,
		"off": TableCards.ALL & ~TableCards.FIRST,
		"roulette": false,
	},
	{
		"name": "Standard",
		"line": "5 min · first to 3000",
		"face": Color("#F2C14E"),
		"seconds": 300,
		"target": 3000,
		"slots": 5,
		"all_items": false,
		"own_bullets": false,
		"overtime": true,
		"catch_up": true,
		"off": 0,
		"roulette": false,
	},
	{
		"name": "Roulette",
		"line": "3 cards dealt a map",
		"face": Color("#3E9B5B"),
		"seconds": 300,
		"target": 3000,
		"slots": 5,
		"all_items": false,
		"own_bullets": false,
		"overtime": true,
		"catch_up": true,
		"off": 0,
		"roulette": true,
	},
	{
		"name": "High roller",
		"line": "8 min · every card",
		"face": Color("#7A4FC4"),
		"seconds": 480,
		"target": 5000,
		"slots": 8,
		"all_items": true,
		"own_bullets": false,
		"overtime": true,
		"catch_up": true,
		"off": 0,
		"roulette": false,
	},
	{
		"name": "Cutthroat",
		"line": "No target · bullets bite",
		"face": Color("#C4453C"),
		"seconds": 300,
		"target": 0,
		"slots": 3,
		"all_items": false,
		"own_bullets": true,
		"overtime": false,
		"catch_up": false,
		"off": 0,
		"roulette": false,
	},
]
## The fifth chip, lit where the rows are set to none of them: steel, the way a switch that is off
## is.
const CUSTOM := {"name": "Custom", "line": "Set them yourself", "face": Color(0.37, 0.36, 0.42)}


## The rows of [param options] set as preset [param index] has them. All items only where the
## loyalty program has added them, GAME.md 8.9: without the row there is no other set to pick.
static func apply(options: MatchOptions, index: int) -> void:
	var preset := PRESETS[index]
	options.minutes_option.select(maxi(MatchOptions.match_lengths().find(preset["seconds"]), 0))
	options.target_option.select(maxi(MatchOptions.TARGETS.find(preset["target"]), 0))
	options.slots_option.select(maxi(MatchOptions.JOKER_SLOTS.find(preset["slots"]), 0))
	options.items_option.select(1 if preset["all_items"] and options.has_items() else 0)
	options.own_bullets_option.select(MatchOptions.OWN_BULLETS.find(preset["own_bullets"]))
	options.overtime_option.select(MatchOptions.OVERTIME.find(preset["overtime"]))
	options.catch_up_option.select(MatchOptions.CATCH_UP.find(preset["catch_up"]))
	var strip := options.table_strip
	# Turned over in a wave along the row, the cards the preset turns, GAME.md 9.6.
	strip.set_table(
		strip.opened & ~int(preset["off"]), preset["roulette"], strip.opened, strip.fresh, true
	)


## Which preset the rows of [param options] are set to, or -1 for none of them.
static func matching(options: MatchOptions) -> int:
	var config := MatchConfig.new()
	options.apply_to(config)
	for i: int in PRESETS.size():
		var preset := PRESETS[i]
		var items := "all" if preset["all_items"] and options.has_items() else "first"
		if (
			roundi(config.duration) == preset["seconds"]
			and config.target_score == preset["target"]
			and config.joker_slots == preset["slots"]
			and config.item_set == items
			and config.own_bullets_hurt == preset["own_bullets"]
			and config.overtime == preset["overtime"]
			and config.catch_up == preset["catch_up"]
			and config.roulette == preset["roulette"]
			# Roulette's cards are its deck, whichever of them the player keeps in it.
			and (
				preset["roulette"]
				or config.table == options.table_strip.opened & ~int(preset["off"])
			)
		):
			return i
	return -1
