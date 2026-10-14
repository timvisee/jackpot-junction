class_name DemoRun
extends RefCounted
## A run of the demo for a booth, GAME.md 9.8: a Grand Prix dealt as it starts, with the waiting
## room left out, and who sits at the demo's seats for the whole of it. Each seat is handed a funny
## name, a color nobody else at the table has, a dress drawn from everything there is and a plate,
## and its bot a way of driving; the bots are dealt as any run's are, and dressed like the seats.

## How many maps a run plays, and the banked score that ends one early.
const MAPS := 3
const TARGET := 3000
const TRAITS := "res://data/ai/traits.tres"

## The run being played, or null before the first.
static var current: DemoRun

## The way each seat's bot drives, and the plate on each seat's kart, by seat.
var traits: Array[BotTrait] = []
var plates: Array[String] = []


## Deals a run with [param rng]: its Grand Prix into [member Game.grand_prix], and the configuration
## its first map is built from.
static func deal(rng: RandomNumberGenerator) -> MatchConfig:
	var config := MatchConfig.new()
	config.human_devices.clear()
	var colors: Array[int] = []
	for color: int in Palette.PLAYER_COLORS.size():
		colors.append(color)
	for i: int in range(colors.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := colors[i]
		colors[i] = colors[j]
		colors[j] = held
	for seat: int in Demo.seats:
		config.human_devices.append(DemoInput.NO_PAD + seat)
		config.human_colors.append(colors[seat])
		config.human_names.append(PlayerNames.pick(rng, config.human_names))
		config.human_styles.append(KartStyle.dressed_up(rng).to_array())
	config.rounds = MAPS
	config.keep_jokers = GrandPrix.Keep.CHOOSE
	config.normal_maps = true
	config.xl_maps = true
	config.tie_breaker = true
	config.bot_count = Demo.bots
	config.difficulty = "normal"
	config.duration = Demo.map_seconds
	config.target_score = TARGET
	config.item_set = "all"
	config.overtime = true
	config.teams = 0
	config.seats = maxi(config.seats, config.karts())
	# A table too big for the usual size deals the XL maps alone, GAME.md 6.3.
	var maps := ArenaMaps.pool(not config.crowded(), true)
	var run := GrandPrix.start(MAPS, rng, config.keep_jokers, maps, config.tie_breaker)
	var table: BotTraitTable = load(TRAITS)
	run.deal_bots(table, config.bot_count, rng)
	for i: int in run.bot_styles.size():
		run.bot_styles[i] = KartStyle.dressed_up(rng).to_array()
	Game.grand_prix = run
	config.map = run.current_map()
	current = DemoRun.new()
	var taken: Array[BotTrait] = run.bots.duplicate()
	for seat: int in Demo.seats:
		var dealt := table.pick(rng, taken)
		taken.append(dealt)
		current.traits.append(dealt)
		var digits := "%06d" % rng.randi_range(0, 999999)
		current.plates.append(LicensePlate.suggest(config.human_names[seat], digits))
	return config


## Every kart's controls for a map of the run built from [param config]: the demo's seats, each with
## its bot's way of driving and its plate, held by whoever sat down at it, and then the bots.
static func inputs(config: MatchConfig) -> Array[KartInput]:
	var result: Array[KartInput] = []
	for seat: int in config.human_devices.size():
		var input := DemoInput.new(seat)
		if current != null and seat < current.traits.size():
			input.bot_trait = current.traits[seat]
			input.plate = current.plates[seat]
		# Whoever sat down at it plays on from the map before, GAME.md 9.8.
		if DemoSeats.held.has(seat):
			input.take(DemoSeats.held[seat])
		result.append(input)
	for i: int in config.network_seats + config.bot_count:
		result.append(BotInput.new())
	return result
