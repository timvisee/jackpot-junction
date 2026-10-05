class_name SeatLimit
extends RefCounted
## How many people may play at once, GAME.md 9.6 and 10.3, and turning away the one too many: the
## arena's seats, and online as many as the host's lobby lets in, whoever is sitting where. It
## held the door for somebody knocking from another machine and not for somebody at the host's own
## pressing J, which in a lobby for two sat a third player down. However many a room has seats
## for, one machine has four at most, GAME.md 9.2.

## The most players at one machine, GAME.md 9.2: a screen has four corners for their blocks,
## whatever the room has seats for. The host holds every other machine to it too, see [PeerSeats].
const MOST_HERE := 4
## What a fifth player at one machine is told, on the notice and under the ready count, GAME.md 9.6.
const HERE_FULL := "This device has room for 4 players."


## How many players [param match_node] may have: its seats, and no more than the lobby the host of
## [param session] keeps, which a client is told, see [signal Events.room_planned].
static func limit(match_node: Match, session: NetSession) -> int:
	var most := match_node.rules.max_players
	if session != null:
		most = mini(most, session.door.max_players)
	return most


## How many people are playing in [param match_node], at this machine and at every other.
static func players(match_node: Match) -> int:
	var count := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			count += 1
	return count


## Whether [param match_node] has somewhere for one more player: a bot to take over, or room for
## another kart.
static func has_seat(match_node: Match) -> bool:
	if PlayerSlot.bot_seat(match_node.slots) != null:
		return true
	return match_node.slots.size() < match_node.rules.max_players


static func full(match_node: Match, session: NetSession) -> bool:
	return players(match_node) >= limit(match_node, session)


## How many people play at this machine in [param match_node]: on a client of [param session], the
## players it has, seated or still asked for, and anywhere else the slots driven here.
static func players_here(match_node: Match, session: NetSession) -> int:
	if session != null and not session.is_host:
		return session.seats.size()
	var count := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human():
			count += 1
	return count


## Whether this machine has as many players as one may, GAME.md 9.2.
static func full_here(match_node: Match, session: NetSession) -> bool:
	return players_here(match_node, session) >= MOST_HERE


## Whether a press of join on [param device] is turned away, and told why over [param parent]:
## the game is full, or this machine has as many players as one may. A device somebody is already
## playing on is not asking for a seat, and is let through for whatever else the button does,
## since on a pad it is also the pause button.
static func turns_away(parent: Node, match_node: Match, session: NetSession, device: int) -> bool:
	for slot: PlayerSlot in match_node.slots:
		if slot.plays_on(device):
			return false
	if full(match_node, session):
		say_full(parent, limit(match_node, session))
		return true
	if full_here(match_node, session):
		say_full_here(parent)
		return true
	return false


## Says over [param parent] that the game, with room for [param most], is full.
static func say_full(parent: Node, most: int) -> void:
	NoticePane.tell(
		parent,
		"Maximum number of players reached",
		"This game has room for %d player%s." % [most, "" if most == 1 else "s"]
	)


## Says over [param parent] that this machine has as many players as one may, GAME.md 9.2.
static func say_full_here(parent: Node) -> void:
	NoticePane.tell(parent, "Maximum number of players reached", HERE_FULL)


## A press of join on [param device] at this machine, GAME.md 9.2 and 10.3: turned away while the
## game is full, and otherwise another player, sat down here or, on a client, asked of the host.
## Returns whether it was taken as somebody sitting down, which a device already playing is not.
static func join(parent: Node, match_node: Match, session: NetSession, device: int) -> bool:
	for slot: PlayerSlot in match_node.slots:
		if slot.plays_on(device):
			return false
	if turns_away(parent, match_node, session, device):
		return true
	if session != null and not session.is_host:
		if session.watching:
			return false
		session.add_seat(device)
		return true
	return match_node.join_human(device) != null
