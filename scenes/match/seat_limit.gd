class_name SeatLimit
extends RefCounted
## How many people may play at once, GAME.md 9.6 and 10.3, and turning away the one too many: the
## arena's seats, and online as many as the host's lobby lets in, whoever is sitting where. It
## held the door for somebody knocking from another machine and not for somebody at the host's own
## pressing J, which in a lobby for two sat a third player down.


## How many players [param match_node] may have: its seats, and no more than the lobby the host of
## [param session] keeps.
static func limit(match_node: Match, session: NetSession) -> int:
	var most := match_node.rules.max_players
	if session != null and session.is_host:
		most = mini(most, session.door.max_players)
	return most


## How many people are playing in [param match_node], at this machine and at every other.
static func players(match_node: Match) -> int:
	var count := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			count += 1
	return count


static func full(match_node: Match, session: NetSession) -> bool:
	return players(match_node) >= limit(match_node, session)


## Whether a press of join on [param device] is turned away, and told why over [param parent]:
## the game is full. A device somebody is already playing on is not asking for a seat, and is let
## through for whatever else the button does, since on a pad it is also the pause button.
static func turns_away(parent: Node, match_node: Match, session: NetSession, device: int) -> bool:
	for slot: PlayerSlot in match_node.slots:
		if slot.plays_on(device):
			return false
	if not full(match_node, session):
		return false
	var most := limit(match_node, session)
	NoticePane.tell(
		parent,
		"Maximum number of players reached",
		"This game has room for %d player%s." % [most, "" if most == 1 else "s"]
	)
	return true
