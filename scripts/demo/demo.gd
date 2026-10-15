class_name Demo
extends RefCounted
## The demo for a booth, GAME.md 9.8: with `--demo` the game plays Grand Prix after Grand Prix on
## its own, on settings of its own and a profile made afresh in memory, for whoever walks past to
## pick up a pad and play. This is what the arguments say and what is set up before any scene; the
## demo's running part is [DemoHost], under [Game].

## The settings the demo plays on unless `--settings=` names others, and the profiles beside them.
const SETTINGS := "user://demo.cfg"
## How many seats at this machine have a corner of the HUD and a bot at the wheel, and how many
## plain bots drive beside them: four karts, a full table of the usual size.
const SEATS := 2
const BOTS := 2
## The most of each there can be: a machine's four corners of the HUD, and a room of eight karts.
const MOST_SEATS := 4
const MOST_KARTS := 8
## How long a map of the demo's runs, in seconds.
const MAP_SECONDS := 180
## What the demo's profile goes by: never a number, so it is never among the profiles kept.
const PROFILE_ID := "demo"

## Whether the game was started as the demo.
static var on := false
static var seats := SEATS
static var bots := BOTS
## How long a map runs: [constant MAP_SECONDS], or in a debug build what `--demo-map-seconds=`
## says, for a soak that wants many runs in little time.
static var map_seconds := MAP_SECONDS
## Whether a visitor has left the demo for the full game, GAME.md 9.8: everything plays as it
## always does until the demo takes over again.
static var away := false


## Reads `--demo`, `--demo-seats=<n>`, `--demo-bots=<n>` and, in a debug build,
## `--demo-map-seconds=<s>` from [param args], the game's own arguments.
static func read_arguments(args: PackedStringArray) -> void:
	on = asked(args)
	for arg: String in args:
		if arg.begins_with("--demo-seats="):
			seats = clampi(arg.get_slice("=", 1).to_int(), 1, MOST_SEATS)
		elif arg.begins_with("--demo-bots="):
			bots = maxi(arg.get_slice("=", 1).to_int(), 0)
		elif arg.begins_with("--demo-map-seconds=") and OS.is_debug_build():
			map_seconds = maxi(arg.get_slice("=", 1).to_int(), 10)
	bots = mini(bots, MOST_KARTS - seats)


## Whether [param args], the game's own arguments, ask for the demo.
static func asked(args: PackedStringArray) -> bool:
	return "--demo" in args


## Whether the demo is what is playing now: started as the demo, and nobody away in the full game.
static func playing() -> bool:
	return on and not away


## Sets [param settings] up for the demo, GAME.md 9.8, once they are read: the demo's profile in
## place of whichever the file named, and for [param fresh] settings, a file that was not there
## yet, the machine's part of the player's own at [param players_own], or with none there or none
## named the booth's defaults, kept from then on. On the demo's own file, [param own_file], every
## profile beside it is a visitor's, left behind by a game closed while they played, and goes.
static func set_up(settings: Settings, fresh: bool, players_own := "", own_file := false) -> void:
	settings.profile = profile()
	if own_file:
		for each: Profile in settings.profiles():
			settings.delete_profile(each.id)
	if not fresh:
		return
	var file := ConfigFile.new()
	if not players_own.is_empty() and SafeFile.read(file, players_own) == OK:
		settings.load_machine(file)
	else:
		settings.fullscreen = true
	settings.save_to_disk()


## The demo's profile, GAME.md 9.8, made afresh and never written anywhere: a member of the loyalty
## program with every landmark won, so the table deals everything and a kart can wear anything, its
## story off, every seat driving the simple way with Auto throttle on for whoever sits down, and the
## driving school done.
static func profile() -> Profile:
	var made := Profile.new()
	made.id = PROFILE_ID
	made.transient = true
	made.story.on = false
	made.tutorial_done = true
	for seat: int in made.drive_modes.size():
		made.drive_modes[seat] = Settings.DRIVE_SIMPLE
		made.auto_throttle[seat] = true
	made.loyalty.welcomed = true
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		made.loyalty.win(each.id)
	Loyalty.settle(made)
	return made
