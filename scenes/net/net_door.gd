class_name NetDoor
extends RefCounted
## Who a host lets into its game, GAME.md 10.3, and what somebody it turns away is told. A client
## knocks with its version, whether it has come to watch, its name and a password if it has one;
## the host lets it in on a version it plays with, with a seat for it or a place in the stands for
## somebody watching, and with the lobby's password if the host has set one, GAME.md 9.6. The host
## can keep watchers out altogether, or let them in without the password. Kept apart from
## [NetSession] so that file stays about the connection rather than the door.

## Somebody knocking was turned away, [param named] as they gave it, and [param why], in the words
## they are told: for a dedicated server's log, GAME.md 9.3a.
signal turned_away(named: String, why: String)

## How many clients may play, on top of the host, and how many may watch on top of them, with no
## kart of their own. A host nobody plays at seats one more client instead, see [method clients].
const MAX_CLIENTS := 3
const MAX_WATCHERS := 4
## The most players a room can be set to, the host's own included, and the fewest.
const MOST_PLAYERS := 4
const FEWEST_PLAYERS := 2
## What an answer says about the password: asked for with none given, and given wrong.
const NEEDED := "needed"
const WRONG := "wrong"
## The longest password the lobby's box takes.
const PASSWORD_LENGTH := 64

## The host's lobby settings: how many may play in the room at most, the host's own players
## included, and the password anybody knocking has to give, empty for none.
var max_players := MOST_PLAYERS
var password := ""
## Whether anybody may come to watch, and whether they have to give the password to: somebody
## watching can only look, so a host may be happy to let anybody look at a game it keeps its seats
## to the people it told.
var watchers_allowed := true
var watchers_need_password := true
## What each client said it was called as it knocked, and for somebody watching, who has no seat
## to be named in, what the host calls them: their own name if nobody else has it, and otherwise,
## or with none given, a funny one off the watchers' list that nobody else has, GAME.md 3.8.
var names: Dictionary[int, String] = {}

var _rng := RandomNumberGenerator.new()
## The watchers' names this door has kept off the list, by who has them.
var _held: Dictionary[int, String] = {}


func _init() -> void:
	_rng.randomize()


## Gone, the watchers' names go back to the list with them.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for named: String in _held.values():
			PlayerNames.held_elsewhere.erase(named)


## Whether a game at [param theirs] can play with one at [param mine], see
## [method GameVersion.compatible].
static func compatible(mine: String, theirs: String) -> bool:
	return GameVersion.compatible(mine, theirs)


## How many clients may play: [constant MAX_CLIENTS] on top of the host's own players, or with
## nobody playing at the host, [param dedicated], a room's worth of them, GAME.md 9.3a.
static func clients(dedicated: bool) -> int:
	return MOST_PLAYERS if dedicated else MAX_CLIENTS


## What a client says about itself as it knocks: its version, whether it has come to watch, what
## it is called, which is all the host has to go on for somebody watching, and the password it was
## given, empty until the host has said there is one.
static func knock(version: String, watching: bool, named: String, given: String) -> Dictionary:
	return NetGuard.marked(
		{"version": version, "watch": watching, "name": named, "password": given}
	)


## The host's answer to [param peer], which said [param words]. [param room] says how the room
## stands: whether it has no seat left, how many clients play in it and may, how many people
## altogether, and how many watch.
func answer(version: String, peer: int, words: Dictionary, room: Dictionary) -> Dictionary:
	var playable := compatible(version, str(words.get("version", "?")))
	var watch := bool(words.get("watch", false))
	var full: bool = room["no_seat"] or room["players"] >= int(room.get("clients", MAX_CLIENTS))
	full = full or room["humans"] >= max_players
	if watch:
		full = room["watchers"] >= MAX_WATCHERS
	var closed := watch and not watchers_allowed
	var locked := ""
	var asks := not password.is_empty() and not (watch and not watchers_need_password)
	if asks and not closed:
		var given := str(words.get("password", ""))
		if given.is_empty():
			locked = NEEDED
		elif given != password:
			locked = WRONG
	var welcome := playable and not full and not closed and locked.is_empty()
	if welcome:
		names[peer] = PlayerNames.clean(str(words.get("name", "")))
		if watch:
			_name_watcher(peer, room.get("match"))
	var answered := {
		"version": version,
		"welcome": welcome,
		"full": full,
		"watch": watch,
		"locked": locked,
		"closed": closed,
	}
	if not welcome:
		var theirs := str(words.get("version", "?"))
		var why := refusal(theirs, answered)
		if wants_password(theirs, answered):
			why = "The password was wrong" if locked == WRONG else "Asked for the password"
		turned_away.emit(PlayerNames.clean(str(words.get("name", ""))), why)
	return answered


## The four lobby settings, as they go over the wire between a dedicated server and the player
## hosting at it, GAME.md 9.3a.
func to_wire() -> Dictionary:
	return {
		"max_players": max_players,
		"password": password,
		"watchers_allowed": watchers_allowed,
		"watchers_need_password": watchers_need_password,
	}


## [param state] off the wire, as far as Lobby settings could have said it.
func from_wire(state: Dictionary) -> void:
	var most := int(state.get("max_players", max_players))
	max_players = clampi(most, FEWEST_PLAYERS, MOST_PLAYERS)
	password = str(state.get("password", password)).strip_edges().left(PASSWORD_LENGTH)
	watchers_allowed = bool(state.get("watchers_allowed", watchers_allowed))
	watchers_need_password = bool(state.get("watchers_need_password", watchers_need_password))


## Whether somebody coming to watch is asked for the password, for the list of games found on the
## network to say so.
func watchers_locked() -> bool:
	return not password.is_empty() and watchers_need_password


## Somebody come to watch is called what they gave if nobody in [param match_node] or in the stands
## has it, and otherwise a funny name off the watchers' own list that nobody has, which is kept off
## the lists for anybody who comes after them.
func _name_watcher(peer: int, match_node: Match) -> void:
	var taken: Array[String] = []
	if match_node != null:
		for slot: PlayerSlot in match_node.slots:
			taken.append(slot.display_name())
	for other: int in names:
		if other != peer:
			taken.append(names[other])
	var named := names[peer]
	if named.is_empty() or named in taken:
		named = PlayerNames.pick_watcher(_rng, taken)
	names[peer] = named
	_held[peer] = named
	PlayerNames.held_elsewhere.append(named)


## [param peer] has gone, and a watcher's name goes back to the list.
func forget(peer: int) -> void:
	names.erase(peer)
	if _held.has(peer):
		PlayerNames.held_elsewhere.erase(_held[peer])
		_held.erase(peer)


## How many play at the host's own machine in [param match_node], which the lobby's limit on
## players counts as well as the clients.
static func locals(match_node: Match) -> int:
	var here := 0
	if match_node != null:
		for slot: PlayerSlot in match_node.slots:
			here += 1 if slot.is_local_human() else 0
	return here


## Everybody else in the host's game, for its Manage players: each player of each client of
## [param seats] that plays, by the name and color of their seat in [param match_node], and each
## of [param watchers] by the name it gave, once [param here] says they are all the way in. A
## client with two players at it is two rows.
##
## A watcher is let in at the host's end of the handshake a round trip before the connection is
## theirs, and one listed in that time could not be shown out. With no [param here], every one is.
func guests(
	match_node: Match,
	seats: Dictionary[int, Dictionary],
	watchers: Dictionary[int, bool],
	here: MultiplayerAPI = null
) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for peer: int in seats:
		for number: int in seats[peer]:
			var index: int = seats[peer][number]
			if match_node != null and index < match_node.slots.size():
				var slot := match_node.slots[index]
				(
					found
					. append(
						{
							"peer": peer,
							"seat": number,
							"name": slot.display_name(),
							"color": slot.color(),
						}
					)
				)
	for peer: int in watchers:
		if here != null and not here.get_peers().has(peer):
			continue
		var named: String = names.get(peer, "")
		found.append({"peer": peer, "name": named if not named.is_empty() else "Watcher"})
	return found


## Whether a client with [param version] was turned away with the host's [param words] for the
## password alone: wanting one, or not the right one. It is asked for it, not sent back.
static func wants_password(version: String, words: Dictionary) -> bool:
	var locked := str(words.get("locked", ""))
	var theirs := str(words.get("version", "?"))
	var shut: bool = words.get("full", false) or words.get("closed", false)
	return not locked.is_empty() and compatible(version, theirs) and not shut


## What a client with [param version] turned away with the host's [param words] is told.
static func refusal(version: String, words: Dictionary) -> String:
	# A dedicated server on the port a LAN game is hosted on, GAME.md 9.3a.
	if bool(words.get("server", false)):
		return "That is a dedicated server: find its games in Play Online"
	var theirs := str(words.get("version", "?"))
	if not compatible(version, theirs):
		return "Wrong version: the host has %s, you have %s" % [theirs, version]
	if bool(words.get("closed", false)):
		return "This game is not open to watchers"
	if bool(words.get("full", false)):
		if bool(words.get("watch", false)):
			return "As many are watching as the match can take"
		return "The match is full"
	return "The host turned you away"
