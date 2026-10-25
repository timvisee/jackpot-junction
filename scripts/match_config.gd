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
## The team each human chose in the waiting room, GAME.md 3.14, in the same order; -1, or none,
## for the smallest team.
var human_teams: Array[int] = []
## Which arena to play in, GAME.md 6.3. In a Grand Prix, the one the playlist is on.
var map := &"lucky_crossing"
## How many maps a Grand Prix runs, GAME.md 9.7, or 0 for a single map.
var rounds := 0
## What of their jokers each player takes on to the next map, one of [enum GrandPrix.Keep].
var keep_jokers := GrandPrix.Keep.CHOOSE
## Which sizes of map a Grand Prix deals from, see [method ArenaMaps.pool].
var normal_maps := true
var xl_maps := true
## Whether karts level on points at the end of a Grand Prix play a showdown, GAME.md 9.7a.
var tie_breaker := true
## Whether a map at the usual size is played as picked with more than four karts on it, GAME.md
## 6.3. Off, it is played as its XL, see [method crowded].
var small_maps := false
var bot_count := 3
## How many karts the arena has seats for, GAME.md 9.3: four, and online as many as the host's
## lobby lets play when that is more, see [method SeatLimit.seats_for].
var seats := SeatLimit.SEATS
## Seats kept for players connected from other machines, GAME.md 9.6. They are started as bots and
## taken over as the host seats everybody again on the other side of the waiting room, see 10.3,
## so they are not counted in [member bot_count]: that is the bots the host asked for, on top of
## everybody who is here.
var network_seats := 0
## The color each of those seats had in the waiting room, in the same order, so a client drives
## the arena in the color it drove the room in.
var network_colors: Array[int] = []
## And the team each of them was on there, GAME.md 3.14.
var network_teams: Array[int] = []
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
## How many teams the karts are split into, 0 for none, and whether teammates can hurt each
## other, GAME.md 3.14.
var teams := 0
var friendly_fire := false
## Whether rubber banding is on, GAME.md 3.16: players behind the leader earn coins faster, pull
## stronger items and draw a sooner bounty onto the leader. On by default, see [CatchUp].
var catch_up := true
## How many jokers a hand holds, GAME.md 3.7.
var joker_slots := 5
## Whether this is the story's Final Hand, STORY.md 8, set by the House rather than chosen, see
## [FinalHand], and the House's models of whoever it was dealt for, the player it seats the bots
## as, see [method FinalHand.dealer]: told a dedicated server in the plan of whoever has the say
## there, and every client with the rules, see [member MatchRules.final_hand].
var final_hand := false
var house := {}
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
## was read at, for the room to say where friends find the game and to go back to when it is over,
## and what it calls itself, for the room to say too. Empty for a LAN game.
var server := ""
var server_name := ""
## A dedicated server's password, GAME.md 9.3a: at a client of one of its games, the one the player
## gave the server, to knock with; at the game itself, the one its door asks for. Empty for none.
var server_password := ""
## A game over Steam's own network, GAME.md 10.8, rather than over the internet's: hosting, for
## Steam friends, every one or [member invite_only] those invited; joining, the lobby it was found
## by and the host's account to connect to, and the host's name on Steam to say.
var steam := false
var invite_only := false
var steam_lobby := 0
var steam_host := 0
var steam_name := ""


func inputs() -> Array[KartInput]:
	var result: Array[KartInput] = []
	for i: int in human_devices.size():
		result.append(PlayerInput.new(human_devices[i], i))
	for i: int in network_seats + bot_count:
		result.append(BotInput.new())
	return result


## Color indices for every slot: the humans' picks, their favorites, GAME.md 3.8, or else their
## places at the table, then the colors the kept seats had in the waiting room, then the first
## free colors for bots. A color somebody here already has gives way to a free one, so no two
## karts are ever the same color.
func colors() -> Array[int]:
	var result: Array[int] = []
	for i: int in human_devices.size():
		var picked: int = human_colors[i] if i < human_colors.size() else -1
		if picked < 0 or picked in result:
			picked = i if i not in result else first_free(result)
		result.append(picked)
	for i: int in network_seats:
		var kept: int = network_colors[i] if i < network_colors.size() else -1
		result.append(kept if kept >= 0 and kept not in result else first_free(result))
	for i: int in bot_count:
		result.append(first_free(result))
	return result


## [param count] colors, [param favorite] first, GAME.md 3.8, or the first seat's without one,
## and the first free ones after it, for a room with one player in it and the rest bots.
static func favorite_first(favorite: int, count: int) -> Array[int]:
	var result: Array[int] = [maxi(favorite, 0)]
	while result.size() < count:
		result.append(first_free(result))
	return result


static func first_free(taken: Array[int]) -> int:
	var next := 0
	while next in taken:
		next += 1
	return next


## A team for every slot, GAME.md 3.14: what the humans chose, then the teams the kept seats were
## on, and the smallest teams for everybody else, the bots last. All -1 without teams.
func team_list() -> Array[int]:
	var wanted: Array[int] = []
	for i: int in human_devices.size():
		wanted.append(human_teams[i] if i < human_teams.size() else -1)
	for i: int in network_seats:
		wanted.append(network_teams[i] if i < network_teams.size() else -1)
	return Teams.deal(wanted, teams, karts())


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
	copy.teams = teams
	copy.friendly_fire = friendly_fire
	copy.catch_up = catch_up
	copy.joker_slots = joker_slots
	copy.map = ArenaMaps.xl_of(map) if crowded() else map
	copy.max_players = seats
	copy.final_hand = final_hand
	return copy


## How many karts the arena starts with: everybody here, everybody kept a seat from elsewhere, and
## the bots.
func karts() -> int:
	return human_devices.size() + network_seats + bot_count


## Whether a map at the usual size is too small for what is to play on it, GAME.md 6.3: more than
## four karts, and the match settings did not ask for it as picked.
func crowded() -> bool:
	return karts() > SeatLimit.SEATS and not small_maps


func power_ups() -> PowerUpTable:
	return load("res://data/powerups/%s.tres" % ("all" if item_set == "all" else "first_set"))


## Everybody playing at this machine in [param match_node], as the people this configuration is
## for: their devices, colors, names, dress and teams, in slot order. A room seats them as who they
## were in the last one, GAME.md 9.6. Nobody here leaves it as it was.
func take_locals(match_node: Match) -> void:
	var devices: Array[int] = []
	var colors: Array[int] = []
	var names: Array[String] = []
	var styles: Array = []
	var chosen: Array[int] = []
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_local_human():
			continue
		devices.append(slot.device())
		colors.append(slot.color_index)
		names.append(slot.player_name)
		styles.append(slot.style.to_array())
		chosen.append(slot.team)
	if devices.is_empty():
		return
	human_devices = devices
	human_colors = colors
	human_names = names
	human_styles = styles
	human_teams = chosen


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
	config.catch_up = settings.catch_up
	config.teams = settings.teams if settings.teams in Teams.COUNTS else 0
	config.friendly_fire = settings.friendly_fire
	config.human_names = settings.seat_names()
	config.human_styles = settings.seat_styles()
	config.human_colors = settings.seat_colors()
	config.map = StringName(settings.map)
	config.rounds = settings.grand_prix_maps if settings.grand_prix else 0
	config.keep_jokers = settings.grand_prix_jokers
	config.normal_maps = settings.grand_prix_normal
	config.xl_maps = settings.grand_prix_xl
	config.tie_breaker = settings.grand_prix_tie_breaker
	config.small_maps = settings.small_maps
	return config
