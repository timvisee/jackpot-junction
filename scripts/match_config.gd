class_name MatchConfig
extends RefCounted
## What the lobby hands to the match scene: who plays, how many bots, how hard, how long.

## Devices of the human players, see [DeviceInput]. One human on any device by default.
var human_devices: Array[int] = [DeviceInput.ANY]
## Color index per human, in the same order; empty means slot order.
var human_colors: Array[int] = []
## How each human dressed their kart, in the same order, as the four numbers of a [KartStyle].
var human_styles: Array = []
## What each human calls themselves, in the same order. An empty entry is handed a funny name
## when the match starts, GAME.md 3.8.
var human_names: Array[String] = []
## Which arena to play in, GAME.md 6.3. In a Grand Prix, the one the playlist is on.
var map := &"lucky_crossing"
## How many maps a Grand Prix runs, GAME.md 9.7, or 0 for a single map.
var rounds := 0
## What of their jokers each player takes on to the next map, one of [enum GrandPrix.Keep].
var keep_jokers := GrandPrix.Keep.CHOOSE
## Which sizes of map a Grand Prix deals from, see [method ArenaMaps.pool].
var normal_maps := true
var xl_maps := true
var bot_count := 3
## Seats kept for players connected from other machines, GAME.md 9.6. They are started as bots and
## taken over as the host seats everybody again on the other side of the waiting room, see 10.3,
## so they are not counted in [member bot_count]: that is the bots the host asked for, on top of
## everybody who is here.
var network_seats := 0
## The color each of those seats had in the waiting room, in the same order, so a client drives
## the arena in the color it drove the room in.
var network_colors: Array[int] = []
var difficulty := "normal"
var duration := 300.0
## 0 disables the early finish.
var target_score := 3000
## "first" for the first power-up set, "all" for every power-up.
var item_set := "first"
## Whether a kart's own shots hurt it, GAME.md 5.1.
var own_bullets_hurt := false
## Whether the clock running out goes to sudden death rather than the whistle, GAME.md 3.13.
var overtime := true
## How many jokers a hand holds, GAME.md 3.7.
var joker_slots := 5
## "", "host" or "join".
var online := ""
## Hosting a game of a dedicated server, GAME.md 9.3a: nobody plays at this machine, so it has no
## devices to seat, and every player is at another machine. Only with [member online] "host".
var dedicated := false
## Joining a game of a dedicated server that this machine has just made there, GAME.md 9.3a: the
## host's say comes with the first seat, and its maker chooses who may come in and the match the
## way a host does. Once: back in the room after a match, only the match is chosen again.
var creating := false
## Joining to watch rather than to play, GAME.md 10.3: no kart, and a seat at nobody's expense.
var watching := false
## The password to knock with, GAME.md 9.6: empty until the host has asked for one. Hosting, the
## password the door starts with, which only a tool sets: the host's own is set in the room.
var password := ""
var address := "127.0.0.1"
var port := NetSession.DEFAULT_PORT
## Joining a game of a dedicated server, GAME.md 9.3a: the server, as the address and port its list
## was read at, for the room to say where friends find the game and to go back to when it is over.
## Empty for a LAN game.
var server := ""


func inputs() -> Array[KartInput]:
	var result: Array[KartInput] = []
	for i: int in human_devices.size():
		result.append(PlayerInput.new(human_devices[i], i))
	for i: int in network_seats + bot_count:
		result.append(BotInput.new())
	return result


## Color indices for every slot: the humans' picks, then the colors the kept seats had in the
## waiting room, then the first free colors for bots. A kept color somebody here already has
## gives way to a free one, so no two karts are ever the same color.
func colors() -> Array[int]:
	var result: Array[int] = []
	for i: int in human_devices.size():
		result.append(human_colors[i] if i < human_colors.size() else i)
	for i: int in network_seats:
		var kept: int = network_colors[i] if i < network_colors.size() else -1
		result.append(kept if kept >= 0 and kept not in result else _first_free(result))
	for i: int in bot_count:
		result.append(_first_free(result))
	return result


static func _first_free(taken: Array[int]) -> int:
	var next := 0
	while next in taken:
		next += 1
	return next


## Names for every slot: what the humans gave, then nothing for the bots, which are named after
## the way they drive rather than by anybody.
func names() -> Array[String]:
	var result: Array[String] = []
	for i: int in human_devices.size():
		result.append(human_names[i] if i < human_names.size() else "")
	return result


## The dress for every slot: what the humans picked, then nothing for the bots, which drive the
## kart as it comes.
func styles() -> Array:
	var result: Array = []
	for i: int in human_devices.size():
		result.append(human_styles[i] if i < human_styles.size() else PackedInt32Array())
	return result


func rules(base: MatchRules) -> MatchRules:
	var copy: MatchRules = base.duplicate()
	copy.duration = duration
	copy.target_score = target_score if target_score > 0 else 1 << 30
	copy.own_bullets_hurt = own_bullets_hurt
	copy.overtime = overtime
	copy.joker_slots = joker_slots
	copy.map = map
	return copy


func power_ups() -> PowerUpTable:
	return load("res://data/powerups/%s.tres" % ("all" if item_set == "all" else "first_set"))


## Everybody playing at this machine in [param match_node], as the people this configuration is
## for: their devices, colors, names and dress, in slot order. A room seats them as who they were
## in the last one, GAME.md 9.6. Nobody here leaves it as it was.
func take_locals(match_node: Match) -> void:
	var devices: Array[int] = []
	var colors: Array[int] = []
	var names: Array[String] = []
	var styles: Array = []
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_local_human():
			continue
		devices.append(slot.device())
		colors.append(slot.color_index)
		names.append(slot.player_name)
		styles.append(slot.style.to_array())
	if devices.is_empty():
		return
	human_devices = devices
	human_colors = colors
	human_names = names
	human_styles = styles


static func from_settings(settings: Settings) -> MatchConfig:
	var config := MatchConfig.new()
	config.bot_count = settings.bot_count
	config.difficulty = settings.difficulty
	config.duration = float(settings.match_seconds)
	config.target_score = settings.target_score
	config.item_set = settings.item_set
	config.own_bullets_hurt = settings.own_bullets_hurt
	config.joker_slots = settings.joker_slots
	config.overtime = settings.overtime
	config.human_names = settings.player_names.duplicate()
	config.human_styles = settings.kart_styles.duplicate()
	config.map = StringName(settings.map)
	config.rounds = settings.grand_prix_maps if settings.grand_prix else 0
	config.keep_jokers = settings.grand_prix_jokers
	config.normal_maps = settings.grand_prix_normal
	config.xl_maps = settings.grand_prix_xl
	return config
