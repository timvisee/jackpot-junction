class_name Profile
extends RefCounted
## One person's save, GAME.md 8.5: who they are at this machine rather than how the machine is set
## up. The names, karts and ways to drive of its four seats, the driver license and its plate, how
## far through the driving school it got, and the servers it plays on, each profile in a file of
## its own, see [Settings]; the picture, the sound, the controls and the lobby's choices stay with
## the machine, the same whoever is playing. A profile is named for its first player.

## How many profiles a machine keeps.
const MOST := 8

## The file it is kept in, and the name of that file, which is how it is told apart.
var path := ""
var id := "1"
## Never written anywhere, wherever the settings say it is kept: the demo's, GAME.md 9.8, which is
## made afresh every time the demo starts.
var transient := false

## What each local seat calls itself, GAME.md 3.8. An empty entry is a seat that never gave a
## name and will be handed a funny one when the match starts.
var player_names: Array[String] = ["", "", "", ""]
## How each local seat dressed its kart, GAME.md 4.4: four numbers each, a paint, a hat, a flag
## and a trail.
var kart_styles: Array = [
	PackedInt32Array([0, 0, 0, 0]),
	PackedInt32Array([0, 0, 0, 0]),
	PackedInt32Array([0, 0, 0, 0]),
	PackedInt32Array([0, 0, 0, 0]),
]
## How each local seat drives, GAME.md 4.2, one of [constant Settings.DRIVE_MODES], or empty for a
## seat nobody has asked yet, which drives the advanced way until somebody does.
var drive_modes: Array[String] = ["", "", "", ""]
## Whether each local seat's simple driving works the pedals by itself, GAME.md 4.2, rather than
## leaving them to the pad's triggers or the touch screen's own gas and brake: off to start with.
## A keyboard's simple driving always does, having no gas of its own to press.
var auto_throttle: Array[bool] = [false, false, false, false]
## Each local seat's favorite color, GAME.md 3.8, as an index into [constant Palette.PLAYER_COLORS],
## or -1 for a seat with none, which takes the color its place at the table gives it. A profile
## new to this machine starts with one at random for its first seat, see [method pick_a_color].
var colors: Array[int] = [-1, -1, -1, -1]
## Whether it was not read from a file kept but made just now, a profile new to this machine.
var made_new := false
## Whether the driving test of GAME.md 9.4a has been finished.
var tutorial_done := false
## The driver license the driving test ends on, GAME.md 9.4a: its number, the day it was issued,
## who it was issued to and what they earned on the way, empty until it has been; and the plate
## they chose for the back of their kart, 4.4.
var license_number := ""
var license_date := ""
var license_holder := ""
var license_endorsements := PackedStringArray()
var license_plate := ""
## The cones the license's exam knocked over, which its back counts, and the test's time, the last
## one passed and the best, in seconds, 0 for none yet, 9.4a.
var license_cones := 0
var test_time := 0.0
var test_best := 0.0
## The LAN game last joined, and the dedicated server Play Online last connected to, GAME.md 9.3a,
## and connects to again as it comes up. Empty until there has been one.
var last_address := "127.0.0.1"
var last_port := 7777
var last_server := ""
var last_server_port := ServerArgs.PORT
## The dedicated servers kept on Play Online's list, empty to start with, see [ServerList].
var servers: Array[Dictionary] = []
## Every match it has played to the whistle, added up, see [LifetimeStats].
var stats: Dictionary[StringName, float] = {}
## How far it is through the story, STORY.md 5.2, see [Story].
var story := StoryState.new()
## Every joker and power-up it ever took, for the catalog of GAME.md 8.8.
var catalog := CatalogState.new()
## Its loyalty program, GAME.md 8.9, see [Loyalty].
var loyalty := LoyaltyState.new()
## Its achievements, GAME.md 8.10, see [Achievements].
var achievements := AchievementState.new()


## The profile kept as [param id] in [param folder], read from its file if it has one, or new.
static func at(folder: String, id_in: String) -> Profile:
	var profile := Profile.new()
	profile.id = id_in
	profile.path = folder.path_join(id_in + ".cfg") if not folder.is_empty() else ""
	profile.load_from_disk()
	return profile


## What it is called: its first player's name, or "Player" and its number before they gave one.
func display_name() -> String:
	return player_names[0] if not player_names[0].is_empty() else "Player %s" % id


## A favorite color for its first seat, one of the players' colors at random, GAME.md 3.8: given as
## it is made, so that new players are not all in the same color before they choose one.
func pick_a_color() -> void:
	colors[0] = randi_range(0, Palette.PLAYER_COLORS.size() - 1)


func load_from_disk() -> void:
	var file := ConfigFile.new()
	if path.is_empty() or SafeFile.read(file, path) != OK:
		made_new = true
		return
	var stored: Array = file.get_value("players", "names", [])
	for i: int in mini(stored.size(), player_names.size()):
		player_names[i] = PlayerNames.clean(str(stored[i]))
	var dressed: Array = file.get_value("players", "kart_styles", [])
	for i: int in mini(dressed.size(), kart_styles.size()):
		kart_styles[i] = KartStyle.from_array(dressed[i]).to_array().slice(
			0, KartStyle.CHOICES.size()
		)
	var driving: Array = file.get_value("players", "drive_modes", [])
	for i: int in mini(driving.size(), drive_modes.size()):
		var mode := str(driving[i])
		drive_modes[i] = mode if mode in Settings.DRIVE_MODES else ""
	var auto: Array = file.get_value("players", "auto_throttle", [])
	for i: int in mini(auto.size(), auto_throttle.size()):
		auto_throttle[i] = bool(auto[i])
	var picked: Array = file.get_value("players", "colors", [])
	for i: int in mini(picked.size(), colors.size()):
		var color := int(picked[i])
		colors[i] = color if color >= 0 and color < Palette.PLAYER_COLORS.size() else -1
	tutorial_done = bool(file.get_value("license", "tutorial_done", tutorial_done))
	license_number = str(file.get_value("license", "number", license_number))
	license_date = str(file.get_value("license", "date", license_date))
	license_holder = PlayerNames.clean(str(file.get_value("license", "holder", "")))
	var earned: Variant = file.get_value("license", "endorsements", PackedStringArray())
	license_endorsements = (
		PackedStringArray(earned)
		if earned is Array or earned is PackedStringArray
		else PackedStringArray()
	)
	license_plate = LicensePlate.clean(str(file.get_value("license", "plate", "")))
	license_cones = maxi(int(file.get_value("license", "cones", 0)), 0)
	test_time = maxf(float(file.get_value("license", "test_time", 0.0)), 0.0)
	test_best = maxf(float(file.get_value("license", "test_best", 0.0)), 0.0)
	last_address = str(file.get_value("online", "address", last_address))
	last_port = int(file.get_value("online", "port", last_port))
	last_server = str(file.get_value("online", "server", last_server))
	last_server_port = int(file.get_value("online", "server_port", last_server_port))
	servers = ServerList.clean(file.get_value("online", "servers", []))
	if file.has_section("stats"):
		for key: String in file.get_section_keys("stats"):
			stats[StringName(key)] = float(file.get_value("stats", key, 0.0))
	story.read(file)
	catalog.read(file)
	loyalty.read(file)
	achievements.read(file)


func save_to_disk() -> Error:
	if path.is_empty() or transient:
		return OK
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := ConfigFile.new()
	file.set_value("players", "names", player_names)
	file.set_value("players", "kart_styles", kart_styles)
	file.set_value("players", "drive_modes", drive_modes)
	file.set_value("players", "auto_throttle", auto_throttle)
	file.set_value("players", "colors", colors)
	file.set_value("license", "tutorial_done", tutorial_done)
	file.set_value("license", "number", license_number)
	file.set_value("license", "date", license_date)
	file.set_value("license", "holder", license_holder)
	file.set_value("license", "endorsements", license_endorsements)
	file.set_value("license", "plate", license_plate)
	file.set_value("license", "cones", license_cones)
	file.set_value("license", "test_time", test_time)
	file.set_value("license", "test_best", test_best)
	file.set_value("online", "address", last_address)
	file.set_value("online", "port", last_port)
	file.set_value("online", "server", last_server)
	file.set_value("online", "server_port", last_server_port)
	file.set_value("online", "servers", servers)
	for key: StringName in stats:
		file.set_value("stats", String(key), stats[key])
	story.write(file)
	catalog.write(file)
	loyalty.write(file)
	achievements.write(file)
	return SafeFile.save(file, path)
